require("PB_helper")

PB_opt_stage = {}
PlannerCore.stage_function_table.PB_opt_stage = PB_opt_stage

function PB_opt_stage.set_up_area(state)
    local start_index = state.count * state.pole_positions_per_tick
    local end_index = start_index + state.pole_positions_per_tick - 1
    for i = start_index, math.min(#state.possible_pole_positions - 1, end_index) do
        local position = state.possible_pole_positions[i + 1]
        local x = position.x - state.conf.offset - state.left
        local y = position.y - state.conf.offset - state.top
        state.area[x] = state.area[x] or {}
        state.area[x][y] = {reachable_entities = {}, x = x, y = y}
    end

    if end_index >= #state.possible_pole_positions - 1 then
        return true
    else
        return false
    end
end

function PB_opt_stage.initialise_counts(state)
    local start_index = state.count * state.entities_per_tick
    local end_index = start_index + state.entities_per_tick - 1
    for i = start_index, math.min(state.entity_count - 1, end_index) do
        local entity = state.entities[i + 1]

        local left =
            math.clamp(
            math.floor(entity.bounding_box.left_top.x - state.left - state.conf.supply_distance - state.conf.offset + 1),
            1,
            state.width
        )
        local right =
            math.clamp(
            math.ceil(
                entity.bounding_box.right_bottom.x - state.left + state.conf.supply_distance - state.conf.offset - 1
            ),
            1,
            state.width
        )
        local top =
            math.clamp(
            math.floor(entity.bounding_box.left_top.y - state.top - state.conf.supply_distance - state.conf.offset + 1),
            1,
            state.height
        )
        local bottom =
            math.clamp(
            math.ceil(
                entity.bounding_box.right_bottom.y - state.top + state.conf.supply_distance - state.conf.offset - 1
            ),
            1,
            state.height
        )

        local wrapper = {unpowered = true}

        for i = left, right do
            local column = state.area[i]
            if column then
                for j = top, bottom do
                    local pos = column[j]
                    if pos then
                        table.insert(pos.reachable_entities, wrapper)
                    end
                end
            end
        end
    end

    if end_index >= state.entity_count - 1 then
        state.possible_pole_positions = nil
        return true
    else
        return false
    end
end

function PB_opt_stage.place_initial_pole(state)
    local position = PB_helper.rel_position(state, state.initial_pole_position)
    local pos = state.area[position.x][position.y]
    PB_helper.opt_place_pole(state, pos)
    return true
end

function PB_opt_stage.place_best_pole(state)
    if state.placement_stage == "searching" then
        local max_position = PB_helper.opt_best_position(state)
        if max_position then
            PB_helper.opt_place_pole(state, max_position)
        else
            if state.entity_count == 0 then
                PB_helper.print_info(state, {"pole-builder.success"})
                return true
            else
                game.write_file("state.txt", serpent.block(state))
                state.placement_stage = "blocked"
            end
        end
    elseif state.placement_stage == "blocked" then
        local max_position = PB_helper.blocked_best_position(state)
        if max_position then
            state.aim_for_position = max_position
            state.placement_stage = "joining"
        else
            PB_helper.print_warning(state, {"pole-builder.cant-place-pole", state.entity_count})
            return true
        end
    elseif state.placement_stage == "joining" then
        if PB_helper.opt_join_networks(state) then
            if #state.reachable_list > 0 then
                state.best_distance_x = nil
                state.best_distance_y = nil
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
