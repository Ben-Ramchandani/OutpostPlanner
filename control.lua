require("util")
require("config")
require("gui")

-- Note this mod uses its original name (OutpostBuilder) internally.

function find_ore(entities)
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
                local product_names = table.map(
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
        return dict_to_array(ore_products_to_names[max_product])
    else
        return nil
    end
end

function find_bounding_box_names(entities, names)
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
    return {left_top = {x = math.floor(left), y = math.floor(top)}, right_bottom = {x = math.ceil(right), y = math.ceil(bottom)}}
end

function place_blueprint(surface, data)
    data.inner_name = data.name
    data.name = "entity-ghost"
    data.expires = false
    surface.create_entity(data)
end



function place_entity(state, data)
    data.force = state.force
    data.position = abs_position(state, data.position)
    data.direction = abs_direction(state, data.direction)

    if state.conf.check_collision then
        -- Manual collision check to avoid destroying ghosts.
        local box = rotate_box(game.entity_prototypes[data.name].collision_box, data.direction)
        local position = data.position

        local colliding = state.surface.find_entities_filtered({area = {{position.x + box.left_top.x, position.y + box.left_top.y}, {position.x + box.right_bottom.x, position.y + box.right_bottom.y}}})
        for i, entity in ipairs(colliding) do
            local prototype = entity.prototype
            if entity.name == "entity-ghost" and entity.ghost_type ~= "tile" then
                prototype = entity.ghost_prototype
            end
            if prototype.collision_box and prototype.collision_mask and prototype.collision_mask["object-layer"] and not entity.to_be_deconstructed(state.force) and entity.name ~= "player" and entity.type ~= "car" then
                state.had_collision = true
                return 
            end
        end
        for x = math.floor(position.x + box.left_top.x), math.ceil(position.x + box.right_bottom.x - 1) do
            for y = math.floor(position.y + box.left_top.y), math.ceil(position.y + box.right_bottom.y - 1) do
                local tile_prototype = state.surface.get_tile(x, y).prototype
                if tile_prototype.collision_mask and tile_prototype.collision_mask["water-tile"] then
                    state.had_collision = true
                    return 
                end
            end
        end
    end
    
    if state.conf.place_directly then
        if state.surface.can_place_entity(data) then
            if state.conf.drain_inventory then
                if state.player.get_item_count(data.name) > 0 then
                    state.player.remove_item({name = data.name, count = 1})
                else
                    if state.conf.place_blueprint_on_out_of_inventory then
                        place_blueprint(state.surface, data)
                    end
                    return false
                end
            end
            state.surface.create_entity(data)
        elseif state.conf.place_blueprint_on_collision then
            place_blueprint(state.surface, data)
        end
    else
        place_blueprint(state.surface, data)
    end
    return true
end

function on_error(state)
    state.stage = 1000
    return nil
end

function choose_belt(state, row_details)
    if row_details.belt then
        return row_details.belt
    else
        -- Resources per sec from this row of miners
        local res_per_sec = math.max(row_details.miner_count_below, row_details.miner_count_above) * 2 * state.miner_res_per_sec
        local required_belt_speed = (res_per_sec / 7.111) / 60
        
        -- Resources required from this row to have fully compressed output
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

function register(state)
    if not global.AM_states then
        global.AM_states = {state}
    else
        table.insert(global.AM_states, state)
    end
    if #global.AM_states == 1 then
        script.on_event(defines.events.on_tick, on_tick)
    end
end

function on_tick(event)
    if #global.AM_states == 0 then
        script.on_event(defines.events.on_tick, nil)
    else
        -- Manually loop because we're removing items.
        local i = 1
        while i <= #global.AM_states do
            local state = global.AM_states[i]
            if state.stage < #state.stages then
                placement_tick(state)
                i = i + 1
            else
                table.remove(global.AM_states, i)
            end
        end
    end
end

function on_load()
    if global.AM_states and #global.AM_states > 0 then
        script.on_event(defines.events.on_tick, on_tick)
    end
end

script.on_load(on_load)

function clear_running_state()
    global.AM_states = {}
end

ON_INIT = ON_INIT or {}
table.insert(ON_INIT, clear_running_state)

stage = {}

function stage.find_ore(state)
    local ore_names = find_ore(state.event_entities)
    if ore_names == nil then
        player.print({"outpost-builder.no-ore"})
        return on_error(state)
    else
        state.ore_names = ore_names
        return true
    end
end

function stage.check_fluid(state)
    state.fluid = false
    for i, name in ipairs(state.ore_names) do
        if game.entity_prototypes[name].mineable_properties.required_fluid and conf.miner_width == 3 then
            state.fluid = true
            return true
        end
    end
    return true
end

function stage.bounding_box(state)
    local bounding_box = find_bounding_box_names(state.event_entities, state.ore_names)
    -- No longer needed, drop for garbage collection.
    state.event_entities = nil
    
    state.top = bounding_box.left_top.y
    state.left = bounding_box.left_top.x
    state.right = bounding_box.right_bottom.x
    state.bottom = bounding_box.right_bottom.y
    
    if state.conf.direction % 4 == 0 then
        -- North or South
        state.width = state.bottom - state.top
        state.height = state.right - state.left
    else
        -- East or West
        state.width = state.right - state.left
        state.height = state.bottom - state.top
    end

    state.direction_modifier = state.conf.direction - 2
    return true
end

function stage.set_up_placement_stages(state)
    if state.blueprint_entities then

    else
        state.row_height = state.conf.miner_width * 2 + state.conf.pole_width + 1
        state.num_rows = math.ceil(state.height / state.row_height) -- Number of rows of belt
        state.num_half_rows = math.ceil(2 * state.height / state.row_height) -- Number of rows of miners
        state.miners_per_row = math.ceil(state.width / state.conf.miner_width)
        state.row_length = state.miners_per_row * state.conf.miner_width

        if state.conf.use_chest then
            state.use_chest = state.conf.use_chest
            table.append_modify(state.stages, {stage.deconstruct, stage.place_miner, stage.place_pole, stage.place_chest})
            for i = 1, state.num_rows do
                state.row_details[i] = {miner_count = 0, miner_count_below = 0, miner_count_above = 0, miner_positions = {}}
            end
        else
            state.transport_belts = table.map(
                state.conf.transport_belts,
                function(belt)
                    return {name = belt, speed = game.entity_prototypes[belt].belt_speed}
                end
            )
            table.sort(
                state.transport_belts,
                function(a, b)
                    return a.speed < b.speed
                end
            )
            state.fastest_belt_speed = state.transport_belts[#state.transport_belts].speed

            -- See https://wiki.factorio.com/Mining
            local miner_prototype = game.entity_prototypes[state.conf.miner_name]
            function miner_res_per_sec_function(ore_name)
                ore_prototype = game.entity_prototypes[ore_name]
                return (1 + state.force.mining_drill_productivity_bonus) * (miner_prototype.mining_power - ore_prototype.mineable_properties.hardness) * miner_prototype.mining_speed / ore_prototype.mineable_properties.mining_time
            end
            state.miner_res_per_sec = miner_res_per_sec_function(table.max(state.ore_names, miner_res_per_sec_function))
            table.append_modify(state.stages, {stage.deconstruct, stage.place_miner, stage.place_pole, stage.place_belt, stage.remove_empty_rows, stage.merge_lanes, stage.collate_outputs})
            for i = 1, state.num_rows do
                state.row_details[i] = {miner_count = 0, miner_count_below = 0, miner_count_above = 0, end_pos = nil}
            end
        end
        
        local pole_prototype = game.entity_prototypes[state.conf.electric_pole]
        -- I'm not sure this formula is perfect, but it works for all the vanilla poles.
        if pole_prototype.max_wire_distance - 2 * pole_prototype.supply_area_distance <= state.conf.miner_width then
            state.pole_spacing = math.floor(pole_prototype.max_wire_distance)
        else
            state.pole_spacing = math.floor(math.max(state.conf.miner_width * 2, math.min(pole_prototype.max_wire_distance, math.ceil(state.conf.miner_width + 2 * pole_prototype.supply_area_distance - 1))))
        end
        state.pole_indent = math.floor(pole_prototype.supply_area_distance + state.conf.miner_width) - state.conf.pole_width / 2
        state.electric_poles_per_row = math.ceil((state.row_length - (state.pole_indent - state.pole_spacing / 2) * 2) / state.pole_spacing)
        state.place_poles_in_rows = pole_prototype.max_wire_distance < state.row_height
    end
    return true
end

function stage.deconstruct(state)
    local extra_space
    if state.use_chest then
        extra_space = 0
    else
        local number_of_merges = math.max(0, state.num_rows - state.conf.output_belt_count)
        extra_space = number_of_merges + math.min(state.conf.output_belt_count, state.num_rows)
    end
    if state.fluid then
        extra_space = extra_space + 1
    end
    local box = {left_top = {x = -2, y = -2}, right_bottom = {x = state.width + 2 + extra_space, y = math.max(state.height + 3, state.row_height * state.num_half_rows / 2 + 1)}}
    
    local entities
    if state.deconstruct_friendly then
        entities = state.surface.find_entities_filtered({area = abs_area(state, box)})
    else
        entities = state.surface.find_entities_filtered({area = abs_area(state, box), force = "neutral"})
    end
    
    for k, e in pairs(entities) do
        e.order_deconstruction(state.force)
    end
    
    return true
end

function stage.place_miner(state)
    local x = (state.count % state.miners_per_row) * state.conf.miner_width + state.conf.miner_width / 2
    local half_row = math.floor(state.count / state.miners_per_row)
    local row = math.floor(half_row / 2)
    if (half_row >= state.num_half_rows) then
        return true
    end
    local y = row * state.row_height + state.conf.miner_width / 2
    local direction
    if half_row % 2 == 0 then
        direction = defines.direction.south
    else
        direction = defines.direction.north
        y = y + state.conf.miner_width + 1
    end
    
    if state.conf.check_dirty_mining then
        local radius = state.conf.miner_area / 2
        local mining_box = {left_top = {x = x - radius, y = y - radius}, right_bottom = {x = x + radius, y = y + radius}}
        local entities = state.surface.find_entities_filtered({area = abs_area(state, mining_box), type = "resource"})
        
        for k, entity in pairs(entities) do
            if not table.contains(state.ore_names, entity.name) and entity.prototype.resource_category == "basic-solid" then
                return false
            end
        end
    end
    
    if state.conf.check_for_ore then
        local radius = state.conf.miner_width / 2 - 0.2
        local mining_box = {left_top = {x = x - radius, y = y - radius}, right_bottom = {x = x + radius, y = y + radius}}
        local entities = state.surface.find_entities_filtered({area = abs_area(state, mining_box), type = "resource"})
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
    
    local position = {x = x, y = y}
    
    if place_entity(state, {position = position, direction = direction, name = state.conf.miner_name}) then
        state.row_details[row + 1].miner_count = state.row_details[row + 1].miner_count + 1
        if direction == defines.direction.south then
            state.row_details[row + 1].last_miner_above = position
            state.row_details[row + 1].miner_count_above = state.row_details[row + 1].miner_count_above + 1
        else
            state.row_details[row + 1].last_miner_below = position
            state.row_details[row + 1].miner_count_below = state.row_details[row + 1].miner_count_below + 1
        end
        state.total_miners = state.total_miners + 1
        if state.use_chest then
            state.row_details[row + 1].miner_positions[state.count % state.miners_per_row] = true
        end
    end
    return false
end

function stage.place_pole(state)
    local row = math.floor(state.count / state.electric_poles_per_row)
    if (row > state.num_half_rows / 2) then
        return true
    end
    
    local pole_num = state.count % state.electric_poles_per_row
    
    local x = state.pole_indent + pole_num * state.pole_spacing
    if x >= state.row_length then
        x = state.row_length - state.conf.pole_width / 2
    end
    local y = row * state.row_height - state.conf.pole_width / 2
    
    if pole_num > 0 and (row >= state.num_rows or state.row_details[row + 1].miner_count_above == 0) and (row < 1 or state.row_details[row].miner_count_below == 0) then
        return false
    end
    
    place_entity(state, {position = {x, y}, name = state.conf.electric_pole})
    return false
end

function underground_pipe_bridge(state, underground_pipe, max_distance, x1, x2, y)
    if x2 - x1 > max_distance then
        local x = x1 + math.floor((x2 - x1) / 2)
        place_entity(state, {position = {x = x, y = y}, name = underground_pipe, direction = defines.direction.east})
        place_entity(state, {position = {x = x + 1, y = y}, name = underground_pipe, direction = defines.direction.west})
        underground_pipe_bridge(state, underground_pipe, max_distance, x1, x, y)
        underground_pipe_bridge(state, underground_pipe, max_distance, x + 1, x2, y)
    end
end

function stage.place_pipes(state)
    if state.count >= state.num_half_rows then
        return true
    end
    
    local is_above_row = state.count % 2 == 0
    local row = math.floor(state.count / 2)
    local x = state.row_length + 0.5
    local y = row * state.row_height + state.conf.miner_width / 2
    local direciton
    local last_miner_x = nil
    if is_above_row then
        if state.row_details[row + 1].last_miner_above then
            last_miner_x = state.row_details[row + 1].last_miner_above.x + 2
        end
    else
        y = y + state.conf.miner_width + 1
        if state.row_details[row + 1].last_miner_below then
            last_miner_x = state.row_details[row + 1].last_miner_below.x + 2
        end
    end
    
    local underground_pipe = pipe_to_underground(state.conf.pipe_name)
    place_entity(state, {position = {x = x, y = y - 1}, name = underground_pipe, direction = defines.direction.south})
    place_entity(state, {position = {x = x, y = y}, name = state.conf.pipe_name, direction = defines.direction.south})
    place_entity(state, {position = {x = x, y = y + 1}, name = underground_pipe, direction = defines.direction.north})
    
    if last_miner_x and last_miner_x ~= x then
        place_entity(state, {position = {x = last_miner_x, y = y}, name = underground_pipe, direction = defines.direction.west})
        place_entity(state, {position = {x = x - 1, y = y}, name = underground_pipe, direction = defines.direction.east})
        underground_pipe_bridge(state, underground_pipe, game.entity_prototypes[underground_pipe].max_underground_distance, last_miner_x, x - 1, y)
    end
    
    return false
end

function stage.place_chest(state)
    local row = math.floor(state.count / state.miners_per_row)
    if row >= state.num_rows then
        return true
    end
    local miner_num = state.count % state.miners_per_row
    if state.row_details[row + 1].miner_positions[miner_num] then
        local x = miner_num * state.conf.miner_width + state.conf.miner_width / 2
        local y = row * state.row_height + state.conf.miner_width + 0.5
        place_entity(state, {position = {x = x, y = y}, name = state.use_chest})
    end

    return false
end

function stage.place_belt(state)
    local row = math.floor(state.count / (state.row_length + 1))
    if row >= state.num_rows then
        return true
    end
    
    local x = (state.count % (state.row_length + 1)) + 0.5
    local y = row * state.row_height + state.conf.miner_width + 0.5
    
    if state.count % (state.row_length + 1) == 0 then
        if state.place_poles_in_rows then
            place_entity(state, {position = {x = x, y = y}, name = state.conf.electric_pole})
        end
        return false
    end
    
    if state.row_details[row + 1].miner_count == 0 then
        return false
    end
    
    if state.count % (state.row_length + 1) == state.row_length and not state.fluid then
        return false
    end
    
    local pos = {x = x, y = y}
    local belt = choose_belt(state, state.row_details[row + 1])
    place_entity(state, {position = pos, name = belt, direction = defines.direction.east})
    state.row_details[row + 1].end_pos = pos
    return false
end

function stage.remove_empty_rows(state)
    local i = 1
    while i <= #state.row_details do
        if state.row_details[i].miner_count == 0 then
            table.remove(state.row_details, i)
            state.num_rows = state.num_rows - 1
        else
            i = i + 1
        end
    end
    if state.num_rows == 0 then
        return on_error(state)
    end
    return true
end

function stage.merge_lanes(state)
    if state.num_rows <= state.conf.output_belt_count then
        return true
    end
    
    -- Merge the lanes with the fewest miners
    local min = math.huge
    local min_index = nil
    local prev = math.huge
    for i, v in ipairs(state.row_details) do
        if prev + v.miner_count < min then
            min = prev + v.miner_count
            min_index = i
        end
        prev = v.miner_count
    end
    
    local pos1 = state.row_details[min_index - 1].end_pos
    local pos2 = state.row_details[min_index].end_pos
    
    local belt1 = state.row_details[min_index - 1].belt
    local belt2 = state.row_details[min_index].belt
    
    -- If a row ends in a splitter (from a previous iteration), then its y position will be <>.0, so take the closest.
    if pos1.y % 1 == 0 then
        pos1.y = pos1.y + 0.5
    end
    if pos2.y % 1 == 0 then
        pos2.y = pos2.y - 0.5
    end
    
    while pos2.x - 1 > pos1.x do
        pos1.x = pos1.x + 1
        place_entity(state, {position = {x = pos1.x, y = pos1.y}, name = belt1, direction = defines.direction.east})
    end
    while pos1.x > pos2.x - 1 do
        pos2.x = pos2.x + 1
        place_entity(state, {position = {x = pos2.x, y = pos2.y}, name = belt2, direction = defines.direction.east})
    end
    
    pos1.x = pos1.x + 1
    while pos1.y + 1 < pos2.y do
        place_entity(state, {position = {x = pos1.x, y = pos1.y}, name = belt1, direction = defines.direction.south})
        pos1.y = pos1.y + 1
    end
    
    place_entity(state, {position = {x = pos1.x, y = pos1.y}, name = belt1, direction = defines.direction.east})
    pos1.x = pos1.x + 1
    state.row_details[min_index] = {miner_count = state.row_details[min_index].miner_count + state.row_details[min_index - 1].miner_count, miner_count_below = state.row_details[min_index].miner_count_below + state.row_details[min_index - 1].miner_count_below, miner_count_above = state.row_details[min_index].miner_count_above + state.row_details[min_index - 1].miner_count_above, end_pos = {x = pos1.x, y = pos1.y + 0.5}}
    local belt = choose_belt(state, state.row_details[min_index])
    state.row_details[min_index].belt = belt
    state.num_rows = state.num_rows - 1
    place_entity(state, {position = {x = pos1.x, y = pos1.y + 0.5}, name = belt_to_splitter(belt), direction = defines.direction.east})
    table.remove(state.row_details, min_index - 1)
end

function stage.collate_outputs(state) -- Move the outputs to be adjacent.
    local row = table.remove(state.row_details)
    if row == nil then
        return true
    end
    local belt = row.belt
    
    if #state.output_rows == 0 then
        if row.end_pos.y % 1 == 0 then
            row.end_pos.y = row.end_pos.y - 0.5
        end
        row.end_pos.x = row.end_pos.x + 1
        place_entity(state, {position = row.end_pos, name = belt, direction = defines.direction.east})
        table.insert(state.output_rows, row)
    else
        if row.end_pos.y % 1 == 0 then
            row.end_pos.y = row.end_pos.y + 0.5
        end
        
        row.end_pos.x = row.end_pos.x + 1
        local expand_to = math.max(row.end_pos.x, state.output_rows[1].end_pos.x + 1)
        
        while state.output_rows[1].end_pos.x < expand_to do
            for i, row in ipairs(state.output_rows) do
                local pos = row.end_pos
                pos.x = pos.x + 1
                place_entity(state, {position = pos, name = row.belt, direction = defines.direction.east})
            end
        end
        
        while row.end_pos.x < state.output_rows[1].end_pos.x do
            place_entity(state, {position = row.end_pos, name = belt, direction = defines.direction.east})
            row.end_pos.x = row.end_pos.x + 1
        end
        
        while row.end_pos.y + 1 < state.output_rows[#state.output_rows].end_pos.y do
            place_entity(state, {position = row.end_pos, name = belt, direction = defines.direction.south})
            row.end_pos.y = row.end_pos.y + 1
        end
        place_entity(state, {position = row.end_pos, name = belt, direction = defines.direction.east})
        table.insert(state.output_rows, row)
    end
end

function placement_tick(state)
    local res = state.stages[state.stage + 1](state)
    if res == true then
        state.stage = state.stage + 1
        state.count = 0
    elseif res then
        state.stage = res
        state.count = 0
    else
        state.count = state.count + 1
    end
end

function abs_xy(state, x, y)
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

function abs_position(state, pos)
    if pos.x then
        local x, y = abs_xy(state, pos.x, pos.y)
        return {x = x, y = y}
    else
        local x, y = abs_xy(state, pos[1], pos[2])
        return {x = x, y = y}
    end
end

function abs_area(state, area)
    local x1, y1 = abs_xy(state, area.left_top.x, area.left_top.y)
    local x2, y2 = abs_xy(state, area.right_bottom.x, area.right_bottom.y)
    return {left_top = {x = math.min(x1, x2), y = math.min(y1, y2)}, right_bottom = {x = math.max(x1, x2), y = math.max(y1, y2)}}
end

function abs_direction(state, direction)
    if direction then
        return (direction + state.direction_modifier) % 8
    else
        return nil
    end
end

function on_selected_area(event, deconstruct_friendly)
    local player = game.players[event.player_index]
    local surface = player.surface
    local force = player.force
    local conf = get_config(player)
    local stages = {stage.find_ore, stage.check_fluid, stage.bounding_box, stage.set_up_placement_stages}
    
    if not conf.used_before then
        player.print({"outpost-builder.on-first-use", {"outpost-builder.initials"}})
        set_config(player, {used_before = true})
    end

    
    local state = {
        stage = 0,
        count = 0,
        event_entities = event.entities,
        width = width,
        height = height,
        player = player,
        force = force,
        surface = surface,
        row_details = {},
        output_rows = {},
        conf = conf,
        stages = stages,
        deconstruct_friendly = deconstruct_friendly,
        total_miners = 0
    }
    
    if conf.run_over_multiple_ticks then
        register(state)
    else
        while state.stage < #state.stages do
            placement_tick(state)
        end
    end
end

script.on_event(
    defines.events.on_player_selected_area,
    function(event)
        if event.item == "outpost-builder" then
            on_selected_area(event)
        end
    end
)

script.on_event(
    defines.events.on_player_alt_selected_area,
    function(event)
        if event.item == "outpost-builder" then
            on_selected_area(event, true)
        end
    end
)

function on_init()
    if ON_INIT then
        for i, f in ipairs(ON_INIT) do
            f()
        end
    end
end
script.on_init(on_init)
script.on_configuration_changed(on_init)
