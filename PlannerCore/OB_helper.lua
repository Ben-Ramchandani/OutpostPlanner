OB_helper = OB_helper or {}

function OB_helper.find_ore(entities)
    -- Find the most common ore in the area, or ores if they have the same product.
    local ore_counts_name = {}
    local ore_counts_by_product = {}
    local ore_products_to_names = {}
    for k, entity in pairs(entities) do
        if entity.valid and entity.prototype.resource_category == "basic-solid" then
            local name
            if #entity.prototype.mineable_properties.products == 1 then
                name = entity.prototype.mineable_properties.products[1].name
            else
                local product_names =
                    table.map(
                    entity.prototype.mineable_properties.products,
                    function(product)
                        return product.name
                    end
                )
                table.sort(product_names)
                name = table.concat(product_names, "|")
            end
            if ore_counts_by_product[name] then
                ore_counts_by_product[name] = ore_counts_by_product[name] + 1
            else
                ore_counts_by_product[name] = 0
            end
            ore_products_to_names[name] = ore_products_to_names[name] or {}
            ore_products_to_names[name][entity.name] = true
        end
    end

    local max_count = 0
    local max_product = nil
    for product, count in pairs(ore_counts_by_product) do
        if count > max_count then
            max_product, max_count = product, count
        end
    end

    if max_product then
        return util.dict_to_array(ore_products_to_names[max_product])
    else
        return nil
    end
end

function OB_helper.find_bounding_box_names(entities, names)
    local top = math.huge
    local left = math.huge
    local right = -math.huge
    local bottom = -math.huge

    for k, entity in pairs(entities) do
        if entity.valid and table.contains(names, entity.name) then
            top = math.min(top, entity.position.y)
            left = math.min(left, entity.position.x)
            bottom = math.max(bottom, entity.position.y)
            right = math.max(right, entity.position.x)
        end
    end
    return {
        left_top = {x = math.floor(left), y = math.floor(top)},
        right_bottom = {x = math.ceil(right), y = math.ceil(bottom)}
    }
end

function OB_helper.place_blueprint(surface, data)
    data.inner_name = data.name
    data.name = "entity-ghost"
    data.expires = false
    local entity = surface.create_entity(data)
    if entity and data.items then
        entity.item_requests = data.items
    end
    return entity
end

function OB_helper.collision_check(state, abs_data)
    local box = util.rotate_box(game.entity_prototypes[abs_data.name].collision_box, abs_data.direction)
    local position = abs_data.position

    for x = math.floor(position.x + box.left_top.x), math.ceil(position.x + box.right_bottom.x - 1) do
        for y = math.floor(position.y + box.left_top.y), math.ceil(position.y + box.right_bottom.y - 1) do
            local tile_prototype = state.surface.get_tile(x, y).prototype
            if tile_prototype.collision_mask and tile_prototype.collision_mask["water-tile"] then
                return false
            end
        end
    end

    local colliding =
        state.surface.find_entities_filtered(
        {
            area = {
                {position.x + box.left_top.x, position.y + box.left_top.y},
                {position.x + box.right_bottom.x, position.y + box.right_bottom.y}
            }
        }
    )
    for i, entity in ipairs(colliding) do
        local prototype = entity.prototype
        if entity.name == "entity-ghost" and entity.ghost_type ~= "tile" then
            prototype = entity.ghost_prototype
        end
        if
            prototype.collision_box and prototype.collision_mask and prototype.collision_mask["object-layer"] and
                not entity.to_be_deconstructed(state.force) and
                entity.name ~= "player" and
                entity.type ~= "car"
         then
            if
                not ((entity.force.name == "neutral" or state.deconstruct_friendly) and
                    entity.order_deconstruction(state.force))
             then
                return false
            end
        end
    end
    return true
end

function OB_helper.abs_place_entity(state, data)
    data.force = state.force
    local name = data.name

    if state.conf.check_collision and not OB_helper.collision_check(state, data) then
        state.had_collision = true
        return false
    end

    local entity
    if state.conf.place_directly then
        if state.surface.can_place_entity(data) then
            if state.conf.drain_inventory then
                if state.player.get_item_count(data.name) > 0 then
                    state.player.remove_item({name = data.name, count = 1})
                else
                    if state.conf.place_blueprint_on_out_of_inventory then
                        entity = OB_helper.place_blueprint(state.surface, data)
                    else
                        return nil
                    end
                end
            end
            entity = state.surface.create_entity(data)
        elseif state.conf.place_blueprint_on_collision then
            entity = OB_helper.place_blueprint(state.surface, data)
        end
    else
        entity = OB_helper.place_blueprint(state.surface, data)
    end

    if entity and state.use_pole_builder and game.entity_prototypes[name].electric_energy_source_prototype then
        table.insert(
            state.placed_entities,
            {
                name = name,
                position = data.position,
                direction = data.direction,
                bounding_box = table.deep_clone(entity.bounding_box)
            }
        )
    end

    return entity
end

function OB_helper.place_entity(state, data)
    data.position = OB_helper.abs_position(state, data.position)
    util.rotate_entity(data, state.direction_modifier)
    return OB_helper.abs_place_entity(state, data)
end

function OB_helper.on_error(state)
    state.stage = 1000
    return nil
end

function OB_helper.choose_belt(state, row_details)
    if row_details.belt then
        return row_details.belt
    else
        local required_belt_speed = math.huge
        -- Resources per sec from this row of miners
        if state.miner_res_per_sec then
            local res_per_sec =
                math.max(row_details.miner_count_below, row_details.miner_count_above) * 2 * state.miner_res_per_sec
            required_belt_speed = (res_per_sec / 7.111) / 60
        end

        -- Resources required from this row to have fully compressed output
        -- This doesn't work so well because belts start being placed before miners have finished being placed
        local maximum_possible_output = state.conf.output_belt_count * state.fastest_belt_speed
        local output_required_from_row = maximum_possible_output * row_details.miner_count / state.total_miners

        -- 1.1 is a fudge factor to account for partial compression
        local belt_speed = math.min(output_required_from_row, required_belt_speed) * 1.1

        local best_belt = nil
        for i, v in ipairs(state.transport_belts) do
            best_belt = v.name
            if v.speed > belt_speed then
                break
            end
        end

        row_details.belt = best_belt
        return best_belt
    end
end

function OB_helper.place_miner(state, data)
    local x = data.position.x
    local y = data.position.y
    local prototype = game.entity_prototypes[data.name]

    if state.conf.check_dirty_mining then
        local radius = prototype.mining_drill_radius
        local mining_box = {
            left_top = {x = x - radius, y = y - radius},
            right_bottom = {x = x + radius, y = y + radius}
        }
        local entities =
            state.surface.find_entities_filtered({area = OB_helper.abs_area(state, mining_box), type = "resource"})

        for k, entity in pairs(entities) do
            if not table.contains(state.ore_names, entity.name) and entity.prototype.resource_category == "basic-solid" then
                return false
            end
        end
    end

    if state.conf.check_for_ore then
        local radius = (prototype.collision_box.right_bottom.x - prototype.collision_box.left_top.x) / 2 - 0.1
        local mining_box = {
            left_top = {x = x - radius, y = y - radius},
            right_bottom = {x = x + radius, y = y + radius}
        }
        local entities =
            state.surface.find_entities_filtered({area = OB_helper.abs_area(state, mining_box), type = "resource"})
        local found_ore = false
        for k, entity in pairs(entities) do
            if table.contains(state.ore_names, entity.name) then
                found_ore = true
                break
            end
        end
        if not found_ore then
            return false
        end
    end

    return OB_helper.place_entity(state, data)
end

function OB_helper.pipe_connect_miners(state, x1, x2, y, pos_flip)
    OB_helper.pipe_connect(state, x1 + 2, x2 - 2, y, pos_flip)
end

function OB_helper.flip_x_y(pos)
    return {x = pos.y, y = pos.x}
end

function OB_helper.pipe_connect(state, x1, x2, y, pos_flip)
    local pos_func = id
    local dir_offset = 0
    if pos_flip then
        pos_func = OB_helper.flip_x_y
        dir_offset = 2
    end
    local minimum_underground_distance = 2
    if x1 <= x2 then
        if (x2 - x1) < minimum_underground_distance then
            for x = x1, x2 do
                OB_helper.place_entity(state, {name = state.conf.pipe_name, position = pos_func({x = x, y = y})})
            end
        else
            local underground_name = pipe_to_underground(state.conf.pipe_name)
            local max_distance = game.entity_prototypes[underground_name].max_underground_distance

            OB_helper.place_entity(
                state,
                {
                    position = pos_func({x = x1, y = y}),
                    name = underground_name,
                    direction = (defines.direction.west + dir_offset) % 8
                }
            )
            OB_helper.place_entity(
                state,
                {
                    position = pos_func({x = x2, y = y}),
                    name = underground_name,
                    direction = defines.direction.east + dir_offset
                }
            )

            OB_helper.underground_pipe_bridge(state, underground_name, max_distance, x1, x2, y, pos_flip)
        end
    end
end

function OB_helper.underground_pipe_bridge(state, underground_pipe, max_distance, x1, x2, y, pos_flip)
    if x2 - x1 > max_distance then
        local pos_func = id
        local dir_offset = 0
        if pos_flip then
            pos_func = OB_helper.flip_x_y
            dir_offset = 2
        end
        local x = x1 + math.floor((x2 - x1) / 2)
        OB_helper.place_entity(
            state,
            {
                position = pos_func({x = x, y = y}),
                name = underground_pipe,
                direction = defines.direction.east + dir_offset
            }
        )
        OB_helper.place_entity(
            state,
            {
                position = pos_func({x = x + 1, y = y}),
                name = underground_pipe,
                direction = (defines.direction.west + dir_offset) % 8
            }
        )
        OB_helper.underground_pipe_bridge(state, underground_pipe, max_distance, x1, x, y, pos_flip)
        OB_helper.underground_pipe_bridge(state, underground_pipe, max_distance, x + 1, x2, y, pos_flip)
    end
end

function OB_helper.abs_xy(state, x, y)
    if state.conf.direction == defines.direction.east then
        return x + state.left, y + state.top
    elseif state.conf.direction == defines.direction.south then
        return state.right - y, state.top + x
    elseif state.conf.direction == defines.direction.west then
        return state.right - x, state.bottom - y
    elseif state.conf.direction == defines.direction.north then
        return y + state.left, state.bottom - x
    end
end

function OB_helper.abs_position(state, pos)
    if pos.x then
        local x, y = OB_helper.abs_xy(state, pos.x, pos.y)
        return {x = x, y = y}
    else
        local x, y = OB_helper.abs_xy(state, pos[1], pos[2])
        return {x = x, y = y}
    end
end

function OB_helper.abs_area(state, area)
    local x1, y1 = OB_helper.abs_xy(state, area.left_top.x, area.left_top.y)
    local x2, y2 = OB_helper.abs_xy(state, area.right_bottom.x, area.right_bottom.y)
    return {
        left_top = {x = math.min(x1, x2), y = math.min(y1, y2)},
        right_bottom = {x = math.max(x1, x2), y = math.max(y1, y2)}
    }
end

function OB_helper.set_up_leaving_belt(state, row_details, belt, is_underground)
    local position = table.clone(belt.position)
    position.y = position.y + state.count * state.blueprint_height
    position.x = state.row_length - 0.5
    local belt_details = {
        end_pos = position,
        miner_count_above = row_details.miner_count_above,
        miner_count_below = -row_details.miner_count_below,
        belt = row_details.belt,
        miner_count = row_details.miner_count
    }
    if state.conf.smart_belt_placement then
        belt_details.belt = OB_helper.choose_belt(state, belt_details)
    else
        if is_underground then
            belt_details.belt = underground_to_belt(belt.name)
        else
            belt_details.belt = belt.name
        end
    end
    if is_underground then
        if state.fluid then
            position.x = position.x + 1
        end
        position.x = position.x + 1
        OB_helper.place_entity(
            state,
            {
                name = belt_to_underground(belt_details.belt),
                position = position,
                direction = defines.direction.west,
                type = output
            }
        )
    elseif state.fluid then
        position.x = position.x + 1
        OB_helper.place_entity(
            state,
            {name = belt_details.belt, position = position, direction = defines.direction.east}
        )
    end
    table.insert(state.belt_row_details, belt_details)
end

function OB_helper.blueprint_leaving_belt(state, leaving_belts, is_underground)
    if state.count < #state.row_details then
        local details = state.row_details[state.count + 1]
        if details.miner_count > 0 then
            for k, belt in pairs(leaving_belts) do
                OB_helper.set_up_leaving_belt(state, details, belt, is_underground)
            end
        end
        return false
    else
        table.sort(
            state.belt_row_details,
            function(a, b)
                return a.end_pos.y < b.end_pos.y
            end
        )
        return true
    end
end
