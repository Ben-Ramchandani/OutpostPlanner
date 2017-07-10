require("util")


PB_stage = {}
PlannerCore.stage_function_table.PB_stage = PB_stage

PB_helper = {}


function PB_helper.can_place_pole(state, position)
    position = PB_helper.abs_position(state, position)
    -- Assume pole is square
    local left = position.x + state.conf.prototype.collision_box.left_top.x
    local right = position.x + state.conf.prototype.collision_box.right_bottom.x
    local top = position.y + state.conf.prototype.collision_box.left_top.y
    local bottom = position.y + state.conf.prototype.collision_box.right_bottom.y
    for i = math.floor(left), math.ceil(right - 1) do
        for j = math.floor(top), math.ceil(bottom - 1) do
            local tile_prototype = state.surface.get_tile(i, j).prototype
            if tile_prototype.collision_mask and tile_prototype.collision_mask["water-tile"] then
                return false
            end
        end
    end
    local entities = state.surface.find_entities_filtered({area = {{left, top}, {right, bottom}}})
    for i, entity in ipairs(entities) do
        local prototype = entity.prototype
        if entity.name == "entity-ghost" and entity.ghost_type ~= "tile" then
            prototype = entity.ghost_prototype
        end
        if not entity.to_be_deconstructed(state.force) and prototype.collision_box and prototype.collision_mask and prototype.collision_mask["object-layer"] and entity.name ~= "player" and entity.type ~= "car" then
            return false
        end
    end
    return true
end

function PB_helper.place_blueprint(surface, data)
    data.inner_name = data.name
    data.name = "entity-ghost"
    data.expires = false
    surface.create_entity(data)
end

function PB_helper.abs_position(state, position)
    return {x = position.x + state.left + state.conf.offset, y = position.y + state.top + state.conf.offset}
end


-- Not used
function PB_helper.rel_position(state, position)
    return {x = position.x - state.left - state.conf.offset, y = position.y - state.top - state.conf.offset}
end

function PB_helper.rel_position_true(state, position)
    return {x = position.x - state.left, y = position.y - state.top}
end

function PB_helper.print_info(state, info)
    if not state.surpress_info then
        state.player.print({"pole-builder.info", info})
    end
end

function PB_helper.print_warning(state, warning)
    if not state.surpress_warnings then
        state.player.print({"pole-builder.warn", warning})
    end
end

function PB_helper.place_pole_enitity_counts(state, position)
    for i, wrapper in ipairs(state.area[position.x][position.y].reachable_entities) do
        if wrapper.unpowered then
            wrapper.unpowered = nil
            state.entity_count = state.entity_count - 1
        end
    end
end

function PB_helper.place_pole_collision_adjustment(state, position)
    for i = math.max(state.conf.collision_left + position.x, 1), math.min(state.conf.collision_right + position.x, state.width) do
        for j = math.max(state.conf.collision_top + position.y, 1), math.min(state.conf.collision_bottom + position.y, state.height) do
            state.area[i][j] = false
        end
    end
end

function PB_helper.reachability_any_pole(state, rel_position, wire_distance)
    wire_distance = math.floor(wire_distance)
    local left = math.floor(math.max(rel_position.x - wire_distance, 1))
    local top = math.floor(math.max(rel_position.y - wire_distance, 1))
    local right = math.ceil(math.min(rel_position.x + wire_distance, state.width))
    local bottom = math.ceil(math.min(rel_position.y + wire_distance, state.height))
    for i = left, right do
        for j = top, bottom do
            if state.area[i][j] and PB_helper.distance(rel_position.x, rel_position.y, i, j) <= wire_distance then
                state.area[i][j].reachable = true
            end
        end
    end
end

function PB_helper.place_pole_reachability(state, position)
    PB_helper.reachability_any_pole(state, position, state.conf.wire_distance)
end

function PB_helper.place_pole(state, position)
    local data = {name = state.conf.pole, position = PB_helper.abs_position(state, position), force = state.force}
    
    PB_helper.place_blueprint(state.surface, data)
    
    PB_helper.place_pole_enitity_counts(state, position)
    PB_helper.place_pole_collision_adjustment(state, position)
    PB_helper.place_pole_reachability(state, position)
    
    table.insert(state.pole_positions, position)
    return true
end

function PB_helper.connected(pole_position, pole_radius, entity_bounding_box)
    return entity_bounding_box.left_top.x < pole_position.x + pole_radius and entity_bounding_box.right_bottom.x > pole_position.x - pole_radius and entity_bounding_box.left_top.y < pole_position.y + pole_radius and entity_bounding_box.right_bottom.y > pole_position.y - pole_radius
end

function PB_stage.set_up_area(state)
    if state.count < state.width then
        table.insert(state.area, {})
        local i = state.count + 1
        for j = 1, state.height do
            table.insert(state.area[i], {reachable_entities = {}})
        end
        return false
    else
        return true
    end
end

function PB_stage.filter_entities(state)
    local powered_entities = {}
    for k, entity in pairs(state.entities) do
        if entity.valid and entity.prototype.electric_energy_source_prototype then
            table.insert(powered_entities, {bounding_box = entity.bounding_box})
        elseif entity.valid and entity.type == "electric-pole" and not entity.to_be_deconstructed(state.force) then
            table.insert(state.initial_poles, {prototype = entity.prototype, abs_position = entity.position})
        elseif entity.valid and entity.name == "entity-ghost" and entity.ghost_type ~= "tile" then
            if entity.ghost_prototype.electric_energy_source_prototype then
                table.insert(powered_entities, {bounding_box = entity.bounding_box})
            elseif entity.ghost_type == "electric-pole" then
                table.insert(state.initial_poles, {prototype = entity.ghost_prototype, abs_position = entity.position})
            end
        end
    end
    if #powered_entities == 0 then
        PB_helper.print_info(state, {"pole-builder.no-entities"})
        state.stage = 1000
    end
    state.entities = powered_entities
    state.entity_count = #powered_entities
    return true
end

function PB_stage.initial_poles(state)
    if state.count < #state.initial_poles then
        local position = state.initial_poles[state.count + 1].abs_position
        local prototype = state.initial_poles[state.count + 1].prototype
        local x = position.x
        local y = position.y
        local i = 1
        while i <= #state.entities do
            if PB_helper.connected(position, prototype.supply_area_distance, state.entities[i].bounding_box) then
                table.remove(state.entities, i)
                state.entity_count = state.entity_count - 1
            else
                i = i + 1
            end
        end
        local rel_position = PB_helper.rel_position_true(state, position)
        PB_helper.reachability_any_pole(state, rel_position, math.min(prototype.max_wire_distance, state.conf.wire_distance))
        table.insert(state.pole_positions, rel_position)
        return false
    else
        if state.entity_count == 0 then
            PB_helper.print_info(state, {"pole-builder.already-powered"})
            state.stage = 1000
        end
        return true
    end
end

function PB_stage.initialise_counts(state)
    if state.count < #state.entities then
        local entity = state.entities[state.count + 1]
        
        local left = math.clamp(math.floor(entity.bounding_box.left_top.x - state.left - state.conf.supply_distance - state.conf.offset + 1), 1, state.width)
        local right = math.clamp(math.ceil(entity.bounding_box.right_bottom.x - state.left + state.conf.supply_distance - state.conf.offset - 1), 1, state.width)
        local top = math.clamp(math.floor(entity.bounding_box.left_top.y - state.top - state.conf.supply_distance - state.conf.offset + 1), 1, state.height)
        local bottom = math.clamp(math.ceil(entity.bounding_box.right_bottom.y - state.top + state.conf.supply_distance - state.conf.offset - 1), 1, state.height)
        
        local wrapper = {unpowered = true}
        
        for i = left, right do
            for j = top, bottom do
                local pos = state.area[i][j]
                if pos then
                    table.insert(pos.reachable_entities, wrapper)
                end
            end
        end
        return false
    else
        return true
    end
end

function PB_stage.collision_check(state)
    if state.count < state.width then
        for j = 1, state.height do
            if not PB_helper.can_place_pole(state, {x = state.count + 1, y = j}) then
                state.area[state.count + 1][j] = false
            end
        end
        return false
    else
        return true
    end
end

function PB_helper.count_entities(state, reachable_entities)
    local i = 1
    local count = 0
    while i <= #reachable_entities do
        if reachable_entities[i].unpowered then
            count = count + 1
            i = i + 1
        else
            table.remove(reachable_entities, i)
        end
    end
    return count
end

function PB_stage.place_initial_pole(state)
    if #state.pole_positions == 0 then
        local max_position = PB_helper.find_best_position(state, true)
        if max_position then
            PB_helper.place_pole(state, max_position)
        else
            state.stage = 1000
            PB_helper.print_warning(state, {"pole-builder.cant-place-pole", state.entity_count})
        end
    end
    return true
end

function PB_helper.distance(x1, y1, x2, y2)
    return math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2))
end

function PB_helper.distance_position(pos1, pos2)
    return PB_helper.distance(pos1.x, pos1.y, pos2.x, pos2.y)
end

function PB_helper.find_best_position(state, ignore_reachable)
    local max_count = 0
    local max_position = nil
    for x, v in ipairs(state.area) do
        for y, pos in ipairs(v) do
            if pos and (pos.reachable or ignore_reachable) then
                if #pos.reachable_entities > max_count then
                    local count = PB_helper.count_entities(state, pos.reachable_entities)
                    if count > max_count then
                        max_count = count
                        max_position = {x = x, y = y}
                    end
                end
            end
        end
    end
    return max_position
end

function PB_helper.find_closest_position(state, position)
    local best_dist = math.huge
    local best_position = nil
    for x, v in ipairs(state.area) do
        for y, cell in ipairs(v) do
            if cell and cell.reachable then
                local cell_pos = {x = x, y = y}
                local dist = PB_helper.distance_position(cell_pos, position)
                if dist < best_dist then
                    best_position = cell_pos
                    best_dist = dist
                end
            end
        end
    end
    return best_position
end

function PB_helper.find_smallest_distance(from_list, to)
    local closest_distance = math.huge
    for i, pos in ipairs(from_list) do
        local dist = PB_helper.distance_position(to, pos)
        if dist < closest_distance then
            closest_distance = dist
        end
    end
    return closest_distance
end

function PB_helper.join_networks(state)
    if not state.best_distance then
        state.best_distance = PB_helper.find_smallest_distance(state.pole_positions, state.aim_for_position)
    end
    
    local best_position = PB_helper.find_closest_position(state, state.aim_for_position)
    if best_position then
        local dist = PB_helper.distance_position(best_position, state.aim_for_position)
        if dist < state.best_distance then
            PB_helper.place_pole(state, best_position)
            state.best_distance = dist
            return true
        else
            return false
        end
    else
        return false
    end
end

function PB_stage.place_best_pole(state)
    if state.placement_stage == "searching" then
        local max_position = PB_helper.find_best_position(state, false)
        if max_position then
            PB_helper.place_pole(state, max_position)
        else
            if state.entity_count == 0 then
                PB_helper.print_info(state, {"pole-builder.success"})
                return true
            else
                state.placement_stage = "blocked"
            end
        end
    elseif state.placement_stage == "blocked" then
        local max_position = PB_helper.find_best_position(state, true)
        if max_position then
            state.aim_for_position = max_position
            state.placement_stage = "joining"
        else
            PB_helper.print_warning(state, {"pole-builder.cant-place-pole", state.entity_count})
            return true
        end
    elseif state.placement_stage == "joining" then
        if PB_helper.join_networks(state) then
            if state.best_distance <= state.conf.wire_distance then
                state.best_distance = nil
                state.aim_for_position = nil
                state.placement_stage = "searching"
            end
        else
            PB_helper.print_warning(state, {"pole-builder.cant-join", state.entity_count})
            return true
        end
    end
    return false
end
