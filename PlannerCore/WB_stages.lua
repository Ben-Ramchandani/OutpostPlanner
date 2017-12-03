require("util")

--[[  Placement functions  ]]
WB_stage = {}
PlannerCore.stage_function_table.WB_stage = WB_stage

function WB_stage.bounding_box(state)
    local count = state.count * state.conf.iterations_per_tick + 1
    if count <= #state.entities then
        for i = count, math.min(#state.entities, count + state.conf.iterations_per_tick) do
            local entity = state.entities[i]
            if entity.valid and entity.force == state.force then
                if entity.name == "straight-rail" then
                    local collision_box = entity.prototype.collision_box
                    if entity.direction == defines.direction.north or entity.direction == defines.direction.south then
                        state.left = math.min(state.left, entity.position.x + collision_box.left_top.x)
                        state.right = math.max(state.right, entity.position.x + collision_box.right_bottom.x)
                        if entity.position.y <= state.top + 1.5 or entity.position.y >= state.bottom - 1.5 then
                            table.insert(state.NS_rails, table.clone(entity.position))
                        end
                    elseif entity.direction == defines.direction.east or entity.direction == defines.direction.west then
                        state.top = math.min(state.top, entity.position.y + collision_box.left_top.y)
                        state.bottom = math.max(state.bottom, entity.position.y + collision_box.right_bottom.y)
                        if entity.position.x <= state.left + 1.5 or entity.position.x >= state.right - 1.5 then
                            table.insert(state.EW_rails, table.clone(entity.position))
                        end
                    end
                elseif entity.name == "curved-rail" then
                    local collision_box = {left_top = {x = -3, y = -3}, right_bottom = {x = 3, y = 3}}
                    state.top = math.min(state.top, entity.position.y + collision_box.left_top.y)
                    state.left = math.min(state.left, entity.position.x + collision_box.left_top.x)
                    state.bottom = math.max(state.bottom, entity.position.y + collision_box.right_bottom.y)
                    state.right = math.max(state.right, entity.position.x + collision_box.right_bottom.x)
                    state.entity_count = state.entity_count + 1
                else
                    state.entity_count = state.entity_count + 1
                    --TODO check for ghost
                    if entity.prototype.collision_box then
                        local collision_box = util.rotate_box(entity.prototype.collision_box, entity.direction)
                        state.top = math.min(state.top, entity.position.y + collision_box.left_top.y)
                        state.left = math.min(state.left, entity.position.x + collision_box.left_top.x)
                        state.bottom = math.max(state.bottom, entity.position.y + collision_box.right_bottom.y)
                        state.right = math.max(state.right, entity.position.x + collision_box.right_bottom.x)
                    else
                        state.top = math.min(state.top, entity.position.y)
                        state.left = math.min(state.left, entity.position.x)
                        state.bottom = math.max(state.bottom, entity.position.y)
                        state.right = math.max(state.right, entity.position.x)
                    end
                end
            end
        end
        return false
    else
        if state.entity_count == 0 then
            state.player.print("No entities found to build a wall around.")
            state.stage = 1000
            return true
        end
        return true
    end
end

function WB_stage.NS_rail_positions(state)
    if #state.NS_rails == 0 then
        return true
    end
    table.sort(
        state.NS_rails,
        function(a, b)
            return a.y < b.y
        end
    )
    local min_y = state.NS_rails[1].y
    local max_y = state.NS_rails[#state.NS_rails].y

    if min_y <= state.top + 1.5 then
        state.top_rails =
            table.map(
            table.filter(
                state.NS_rails,
                function(a)
                    return a.y == min_y
                end
            ),
            function(a)
                return a.x - 1
            end
        )
    end

    if max_y >= state.bottom - 1.5 then
        state.bottom_rails =
            table.map(
            table.filter(
                state.NS_rails,
                function(a)
                    return a.y == max_y
                end
            ),
            function(a)
                return a.x - 1
            end
        )
    end
    state.NS_rails = nil
    return true
end

function WB_stage.EW_rail_positions(state)
    if #state.EW_rails == 0 then
        return true
    end
    table.sort(
        state.EW_rails,
        function(a, b)
            return a.x < b.x
        end
    )
    local min_x = state.EW_rails[1].x
    local max_x = state.EW_rails[#state.EW_rails].x

    if min_x <= state.left + 1.5 then
        state.left_rails =
            table.map(
            table.filter(
                state.EW_rails,
                function(a)
                    return a.x == min_x
                end
            ),
            function(a)
                return a.y - 1
            end
        )
    end

    if max_x >= state.right - 1.5 then
        state.right_rails =
            table.map(
            table.filter(
                state.EW_rails,
                function(a)
                    return a.x == max_x
                end
            ),
            function(a)
                return a.y - 1
            end
        )
    end
    state.EW_rails = nil
    return true
end

function WB_stage.plan(state)
    state.left = math.floor(state.left - state.conf.clearance_tiles)
    state.top = math.floor(state.top - state.conf.clearance_tiles)
    state.right = math.ceil(state.right + state.conf.clearance_tiles)
    state.bottom = math.ceil(state.bottom + state.conf.clearance_tiles)
    state.width = state.right - state.left
    state.height = state.bottom - state.top

    -- game.print(
    --     serpent.block(
    --         {
    --             state.left,
    --             state.top,
    --             state.right,
    --             state.bottom,
    --             state.width,
    --             state.height,
    --             state.top_rails,
    --             state.bottom_rails,
    --             state.right_rails,
    --             state.left_rails
    --         }
    --     )
    -- )

    -- Move corners around to fit sections exactly.
    -- Just round to section length, TODO improve behaviour with rails

    local top_wall_sections_length = state.right - state.left
    local num_sections = math.ceil(top_wall_sections_length / state.conf.section_width)
    local difference = num_sections * state.conf.section_width - top_wall_sections_length
    local shift_both = math.floor(difference / 2)
    state.left = state.left - shift_both
    state.right = state.right + shift_both
    if difference % 2 ~= 0 then
        state.left = state.left - 1
    end

    local left_wall_sections_length = state.bottom - state.top
    num_sections = math.ceil(left_wall_sections_length / state.conf.section_width)
    difference = num_sections * state.conf.section_width - left_wall_sections_length
    shift_both = math.floor(difference / 2)
    state.top = state.top - shift_both
    state.bottom = state.bottom + shift_both
    if difference % 2 ~= 0 then
        state.top = state.top - 1
    end

    -- Assume symmetry of rail wall piece
    for k, side in pairs(
        {
            {
                left = state.left,
                right = state.right,
                rails = state.top_rails,
                sections = state.top_section_list,
                corner_position = "first"
            },
            {
                left = state.top,
                right = state.bottom,
                rails = state.left_rails,
                sections = state.left_section_list,
                corner_position = "last"
            },
            {
                left = state.left,
                right = state.right,
                rails = state.bottom_rails,
                sections = state.bottom_section_list,
                corner_position = "last"
            },
            {
                left = state.top,
                right = state.bottom,
                rails = state.right_rails,
                sections = state.right_section_list,
                corner_position = "first"
            }
        }
    ) do
        table.sort(side.rails)
        side.rails[#side.rails + 1] = side.right
        local current_x = side.left
        if side.corner_position == "first" then
            table.insert(
                side.sections,
                {
                    entities = state.conf.corner_entities,
                    offset = current_x - state.conf.corner_width,
                    width = state.conf.corner_width,
                    name = "corner"
                }
            )
        end
        for k, next_x in ipairs(side.rails) do
            local length = next_x - current_x
            local num_sections = math.floor(length / state.conf.section_width)
            local difference = length - num_sections * state.conf.section_width
            -- game.print(
            --     "Current_x: " ..
            --         current_x ..
            --             ", next_x: " ..
            --                 next_x ..
            --                     ", length: " ..
            --                         length .. ", num_sections: " .. num_sections .. ", difference: " .. difference
            -- )
            for i = 1, num_sections do
                table.insert(
                    side.sections,
                    {
                        entities = state.conf.section_entities,
                        offset = current_x,
                        width = state.conf.section_width,
                        name = "section"
                    }
                )
                current_x = current_x + state.conf.section_width
            end
            for i = 1, difference do
                table.insert(
                    side.sections,
                    {
                        entities = state.conf.filler_entities,
                        offset = current_x,
                        width = state.conf.filler_width,
                        name = "filler"
                    }
                )
                current_x = current_x + 1
            end
            table.insert(
                side.sections,
                {
                    entities = state.conf.crossing_entities,
                    offset = current_x,
                    width = state.conf.crossing_width,
                    name = "crossing"
                }
            )
            current_x = current_x + state.conf.crossing_width
        end
        if side.corner_position == "first" then
            side.sections[#side.sections] = nil
        else
            side.sections[#side.sections] = {
                entities = state.conf.corner_entities,
                offset = current_x - state.conf.crossing_width,
                width = state.conf.corner_width,
                name = "corner"
            }
        end
    end

    game.print(
        serpent.block(
            table.map(
                state.bottom_section_list,
                function(s)
                    return s.name
                end
            )
        )
    )

    state.section_master_list = {
        state.right_section_list,
        state.bottom_section_list,
        state.left_section_list,
        state.top_section_list
    }
    return true
end

local function helper_place_entity(state, data)
    if state.use_pole_builder and game.entity_prototypes[data.name].type == "electric-pole" then
        table.insert(state.pole_positions, data.position)
    else
        return OB_helper.abs_place_entity(state, data)
    end
end

local function helper_position(state, offset, entity_position, blueprint_width)
    if state.current_placement_direction == 1 then -- Right
        return {
            x = state.right + state.conf.section_height - entity_position.y,
            y = offset + entity_position.x
        }
    elseif state.current_placement_direction == 2 then -- Bottom
        return {
            x = offset + blueprint_width - entity_position.x,
            y = state.bottom + state.conf.section_height - entity_position.y
        }
    elseif state.current_placement_direction == 3 then -- Left
        return {
            x = state.left - state.conf.section_height + entity_position.y,
            y = offset + blueprint_width - entity_position.x
        }
    else -- Top
        return {
            x = offset + entity_position.x,
            y = state.top - state.conf.section_height + entity_position.y
        }
    end
end

function WB_stage.place_entity(state)
    if state.current_placement_direction > 4 then
        return true
    else
        local sections = state.section_master_list[state.current_placement_direction]
        local section = sections[state.current_section_index]
        local section_width = section.width
        local entities = section.entities
        local offset = section.offset

        if state.current_entity_index > #entities then
            state.current_section_index = state.current_section_index + 1
            state.current_entity_index = 1
            if state.current_section_index > #sections then
                state.current_placement_direction = state.current_placement_direction + 1
                state.current_section_index = 1
            end
            return false
        end

        local entity = table.deep_clone(entities[state.current_entity_index])
        state.current_entity_index = state.current_entity_index + 1
        entity.position = helper_position(state, offset, entity.position, section_width)
        util.rotate_entity(entity, state.current_placement_direction * 2)
        helper_place_entity(state, entity)
        return false
    end
end
