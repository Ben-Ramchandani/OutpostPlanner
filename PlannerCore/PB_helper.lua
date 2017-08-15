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
        if
            not entity.to_be_deconstructed(state.force) and prototype.collision_box and prototype.collision_mask and
                prototype.collision_mask["object-layer"] and
                entity.name ~= "player" and
                entity.type ~= "car"
         then
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

function PB_helper.place_pole_enitity_counts(state, reachable_entities)
    for i, wrapper in ipairs(reachable_entities) do
        if wrapper.unpowered then
            wrapper.unpowered = nil
            state.entity_count = state.entity_count - 1
        end
    end
end

function PB_helper.place_pole_collision_adjustment(state, position)
    for i = math.max(state.conf.collision_left + position.x, 1), math.min(
        state.conf.collision_right + position.x,
        state.width
    ) do
        for j = math.max(state.conf.collision_top + position.y, 1), math.min(
            state.conf.collision_bottom + position.y,
            state.height
        ) do
            state.area[i][j] = false
        end
    end
end

function PB_helper.opt_reachability(state, rel_position)
    local wire_distance = math.floor(state.conf.wire_distance)
    local left = math.floor(math.max(rel_position.x - wire_distance, 1))
    local top = math.floor(math.max(rel_position.y - wire_distance, 1))
    local right = math.ceil(math.min(rel_position.x + wire_distance, state.width))
    local bottom = math.ceil(math.min(rel_position.y + wire_distance, state.height))
    local found_good_pole = false
    for i = left, right do
        local column = state.area[i]
        if column then
            for j = top, bottom do
                local pos = column[j]
                if
                    pos and not pos.reachable and
                        PB_helper.distance(rel_position.x, rel_position.y, i, j) <= wire_distance
                 then
                    pos.reachable = true
                    if PB_helper.count_entities(state, pos.reachable_entities) == 0 then
                        table.insert(state.reachable_zero_list, pos)
                    else
                        table.insert(state.reachable_list, pos)
                    end
                end
            end
        end
    end
end

function PB_helper.opt_place_pole(state, position)
    local data = {name = state.conf.pole, position = PB_helper.abs_position(state, position), force = state.force}

    PB_helper.place_blueprint(state.surface, data)

    PB_helper.place_pole_enitity_counts(state, position.reachable_entities)
    state.area[position.x][position.y] = nil
    PB_helper.opt_reachability(state, position)

    table.insert(state.pole_positions, position)

    return true
end

function PB_helper.opt_best_position(state)
    local max_count = 0
    local max_position = nil
    local max_index = nil
    local i = 1
    while i <= #state.reachable_list do
        local pos = state.reachable_list[i]
        local count = #pos.reachable_entities
        if count > max_count then
            count = PB_helper.count_entities(state, pos.reachable_entities)
        end
        if count > max_count then
            max_count = count
            max_position = pos
            max_index = i
            i = i + 1
        elseif count == 0 then
            table.remove(state.reachable_list, i)
            table.insert(state.reachable_zero_list, pos)
        else
            i = i + 1
        end
    end
    if max_index then
        table.remove(state.reachable_list, max_index)
    end
    return max_position
end

function PB_helper.blocked_best_position(state)
    local max_count = 0
    local max_position = nil
    for x, v in pairs(state.area) do
        for y, pos in pairs(v) do
            if pos and not pos.reachable then
                if #pos.reachable_entities > max_count then
                    local count = PB_helper.count_entities(state, pos.reachable_entities)
                    if count > max_count then
                        max_count = count
                        max_position = pos
                    end
                end
            end
        end
    end
    return max_position
end

function PB_helper.opt_join_networks(state)
    state.best_distance_x = state.best_distance_x or math.huge
    state.best_distance_y = state.best_distance_y or math.huge

    local best_position = nil
    local best_index = nil
    local best_distance = math.huge
    if #state.reachable_zero_list == 1 then
        best_position = state.reachable_zero_list[1]
        best_index = 1
    else
        for i, pos in ipairs(state.reachable_zero_list) do
            if
                math.abs(state.aim_for_position.x - pos.x) <= state.best_distance_x or
                    math.abs(state.aim_for_position.y - pos.y) <= state.best_distance_y
             then
                local distance = PB_helper.distance_position(state.aim_for_position, pos)
                if distance < best_distance then
                    best_distance = distance
                    best_position = pos
                    best_index = i
                end
            end
        end
    end

    if best_position then
        PB_helper.opt_place_pole(state, best_position)
        state.best_distance = best_distance
        table.remove(state.reachable_zero_list, best_index)
        return true
    else
        return false
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

    PB_helper.place_pole_enitity_counts(state, state.area[position.x][position.y].reachable_entities)
    PB_helper.place_pole_collision_adjustment(state, position)
    PB_helper.place_pole_reachability(state, position)

    table.insert(state.pole_positions, position)
    return true
end

function PB_helper.connected(pole_position, pole_radius, entity_bounding_box)
    return entity_bounding_box.left_top.x < pole_position.x + pole_radius and
        entity_bounding_box.right_bottom.x > pole_position.x - pole_radius and
        entity_bounding_box.left_top.y < pole_position.y + pole_radius and
        entity_bounding_box.right_bottom.y > pole_position.y - pole_radius
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
