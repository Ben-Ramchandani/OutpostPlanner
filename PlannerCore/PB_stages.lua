require("util")
require("PB_helper")

PB_stage = {}
PlannerCore.stage_function_table.PB_stage = PB_stage

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
        PB_helper.reachability_any_pole(
            state,
            rel_position,
            math.min(prototype.max_wire_distance, state.conf.wire_distance)
        )
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
