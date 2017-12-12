require("util")
require("OB_helper")

OB_stage = {}
PlannerCore.stage_function_table.OB_stage = OB_stage

function OB_stage.find_ore(state)
    local ore_names = OB_helper.find_ore(state.event_entities)
    if ore_names == nil then
        state.player.print({"outpost-builder.no-ore"})
        return OB_helper.on_error(state)
    else
        state.ore_names = ore_names
        return true
    end
end

function OB_stage.check_fluid(state)
    state.fluid = false
    for i, name in ipairs(state.ore_names) do
        if game.entity_prototypes[name].mineable_properties.required_fluid and state.conf.miner_width == 3 then
            state.fluid = true
            return true
        end
    end
    return true
end

function OB_stage.bounding_box(state)
    local bounding_box = OB_helper.find_bounding_box_names(state.event_entities, state.ore_names)
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

function OB_stage.set_up_placement_stages(state)
    state.blueprint_data = state.conf.blueprint_data
    state.blueprint_width = state.blueprint_data.width
    state.blueprint_height = state.blueprint_data.height
    state.blueprints_per_row = math.ceil(state.width / state.blueprint_width)
    state.num_rows = math.ceil((state.height - 1) / state.blueprint_height)
    state.row_length = state.blueprints_per_row * state.blueprint_width
    state.total_height = state.num_rows * state.blueprint_height
    state.entities_per_blueprint = state.blueprint_data.total_entities
    state.entities_per_row = state.entities_per_blueprint * state.blueprints_per_row
    state.placed_entities = {}

    local pole_prototype = game.entity_prototypes[state.conf.pole_name]
    local pole_spacing
    -- I'm not sure this formula is perfect, but it works for all the vanilla poles.
    if pole_prototype.max_wire_distance - 2 * pole_prototype.supply_area_distance <= state.conf.miner_width then
        pole_spacing = math.floor(pole_prototype.max_wire_distance)
    else
        pole_spacing =
            math.floor(
            math.max(
                state.conf.miner_width * 2,
                math.min(
                    pole_prototype.max_wire_distance,
                    math.ceil(state.conf.miner_width + 2 * pole_prototype.supply_area_distance - 1)
                )
            )
        )
    end

    state.pole_spacing_blueprint = math.floor(pole_spacing / state.blueprint_width)
    state.pole_indent_blueprint = math.floor(state.pole_spacing_blueprint / 2)
    state.pole_indent_blueprint_end = state.pole_indent_blueprint
    if pole_prototype.max_wire_distance < state.blueprint_height + 1 then
        state.pole_indent_blueprint = 0
    end

    table.append_modify(state.stages, {"place_blueprint_entity"})

    if state.fluid and state.conf.enable_pipe_placement then
        table.append_modify(state.stages, {"place_end_pipes"})
    end

    if state.conf.enable_belt_collate then
        if #state.blueprint_data.leaving_belts > 0 and #state.blueprint_data.leaving_underground_belts > 0 then
            table.append_modify(
                state.stages,
                {"leaving_belts", "leaving_underground_belts", "merge_lanes", "collate_outputs"}
            )
        elseif #state.blueprint_data.leaving_belts > 0 then
            table.append_modify(state.stages, {"leaving_belts", "merge_lanes", "collate_outputs"})
        elseif #state.blueprint_data.leaving_underground_belts > 0 then
            table.append_modify(state.stages, {"leaving_underground_belts", "merge_lanes", "collate_outputs"})
        end
    end

    if #state.blueprint_data.poles > 0 then
        if state.conf.pole_options_selected == "intelligent" or state.conf.pole_options_selected == "automatic" then
            state.use_pole_builder = true
            table.append_modify(state.stages, {"pole_builder_invoke"})
            state.possible_pole_positions = {}
            state.top_right_pole_position = {x = -math.huge, y = math.huge}
        end
    end

    state.transport_belts =
        table.map(
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
    if #state.ore_names == 1 and not game.entity_prototypes[state.ore_names[1]].infinite_resource then
        -- See https://wiki.factorio.com/Mining
        local miner_prototype = game.entity_prototypes[state.conf.miner_name]
        local mining_speed = miner_prototype.mining_speed
        local ore_prototype = game.entity_prototypes[state.ore_names[1]]
        if state.blueprint_data.miners[1].items then
            local speed_modifier = 1
            local productivity_modifier = 1
            for k, v in pairs(state.blueprint_data.miners[1].items) do
                if game.item_prototypes[k] and game.item_prototypes[k].type == "module" then
                    if game.item_prototypes[k].module_effects.speed then
                        speed_modifier = speed_modifier + (game.item_prototypes[k].module_effects.speed.bonus * v)
                    end
                    if game.item_prototypes[k].module_effects.productivity then
                        productivity_modifier =
                            productivity_modifier + (game.item_prototypes[k].module_effects.productivity.bonus * v)
                    end
                end
            end
            mining_speed = mining_speed * speed_modifier * productivity_modifier
        end
        state.miner_res_per_sec =
            (1 + state.force.mining_drill_productivity_bonus) *
            (miner_prototype.mining_power - ore_prototype.mineable_properties.hardness) *
            mining_speed /
            ore_prototype.mineable_properties.mining_time
    end

    for i = 1, state.num_rows do
        table.insert(
            state.row_details,
            {miner_count = 0, miner_count_above = 0, miner_count_below = 0, last_miner_x_by_y = {}}
        )
    end

    return true
end

blueprint_place = {}

function blueprint_place.miners(state, entity, column, row)
    local position = table.clone(entity.position)
    local direction = entity.direction
    entity.name = state.conf.miner_name
    if OB_helper.place_miner(state, entity) then
        local row_details = state.row_details[row + 1]
        row_details.last_miner_column = column
        row_details.belt = nil
        row_details.miner_count = row_details.miner_count + 1
        if direction ~= defines.direction.north then
            row_details.miner_count_above = row_details.miner_count_above + 1
        end
        if direction ~= defines.direction.south then
            row_details.miner_count_below = row_details.miner_count_below + 1
        end
        if state.fluid then
            if row_details.last_miner_x_by_y[position.y] then
                OB_helper.pipe_connect_miners(state, row_details.last_miner_x_by_y[position.y], position.x, position.y)
            end
            row_details.last_miner_x_by_y[position.y] = position.x
        end
    end
    return false
end

function blueprint_place.poles(state, entity, column, row)
    local position = entity.position
    local is_last_column = column == state.blueprints_per_row - 1
    if entity.place_only_with_small_poles and state.conf.pole_name ~= "small-electric-pole" then
        return
    end

    if state.conf.pole_options_selected == "always" then
        OB_helper.place_entity(state, {position = position, name = state.conf.pole_name})
    else
        local index = (column - state.pole_indent_blueprint) % state.pole_spacing_blueprint
        if
            index == 0 or is_last_column and index > state.pole_indent_blueprint_end or
                state.blueprint_data.other_electric_entities
         then
            if state.use_pole_builder then
                local abs_position = OB_helper.abs_position(state, position)
                if OB_helper.collision_check(state, {position = abs_position, name = state.conf.pole_name}) then
                    table.insert(state.possible_pole_positions, abs_position)
                    if position.y <= state.top_right_pole_position.y and position.x > state.top_right_pole_position.x then
                        state.top_right_pole_position = position
                        state.top_right_pole_index = #state.possible_pole_positions
                    end
                end
            else
                OB_helper.place_entity(state, {position = position, name = state.conf.pole_name})
            end
        end
    end
end

function blueprint_place.place_belt_like(state, entity, row, name_function)
    local row_details = state.row_details[row + 1]
    if row_details.miner_count > 0 then
        if state.conf.smart_belt_placement then
            local belt = OB_helper.choose_belt(state, row_details)
            entity.name = name_function(belt)
        end
        OB_helper.place_entity(state, entity)
    else
        return "skip"
    end
end

function blueprint_place.belts(state, entity, column, row)
    return blueprint_place.place_belt_like(state, entity, row, id)
end

function blueprint_place.underground_belts(state, entity, column, row)
    return blueprint_place.place_belt_like(state, entity, row, belt_to_underground)
end

function blueprint_place.splitters(state, entity, column, row)
    return blueprint_place.place_belt_like(state, entity, row, belt_to_splitter)
end

function blueprint_place.chests(state, entity, column, row)
    entity.name = state.conf.chest_name
    if state.row_details[row + 1].last_miner_column == column then
        return OB_helper.place_entity(state, entity)
    end
end

function blueprint_place.place_other(state, entity, column, row)
    local entity_settings = state.conf.other_entity_settings[entity.name]
    if not entity_settings.with_miners or state.row_details[row + 1].last_miner_column == column then
        if column % entity_settings.every_x == 0 then
            OB_helper.place_entity(state, entity)
        end
    end
end

blueprint_place.other_entities = blueprint_place.place_other

blueprint_place.order = {"miners", "poles", "belts", "underground_belts", "splitters", "chests", "other_entities"}

function OB_stage.place_blueprint_entity(state)
    local row = math.floor(state.count / state.entities_per_row)
    if row >= state.num_rows then
        return true
    end

    local count_in_row = state.count % state.entities_per_row
    local column = math.floor(count_in_row / state.entities_per_blueprint)
    local count_in_blueprint = count_in_row % state.entities_per_blueprint

    local x = column * state.blueprint_width
    local y = row * state.blueprint_height

    for k, v in ipairs(blueprint_place.order) do
        if count_in_blueprint >= #state.blueprint_data[v] then
            count_in_blueprint = count_in_blueprint - #state.blueprint_data[v]
        else
            local entity = table.deep_clone(state.blueprint_data[v][count_in_blueprint + 1])
            entity.position.x = entity.position.x + x
            entity.position.y = entity.position.y + y
            if blueprint_place[v](state, entity, column, row) == "skip" then
                state.count =
                    state.count + (state.entities_per_blueprint - (count_in_row % state.entities_per_blueprint)) - 1
            end
            return false
        end
    end

    return false
end

function OB_stage.pole_builder_invoke(state)
    remote.call(
        "PlannerCoreInvoke",
        "PoleBuilder",
        {
            player = state.player,
            entities = state.placed_entities,
            pole = state.conf.pole_name,
            initial_pole_index = state.top_right_pole_index,
            possible_pole_positions = state.possible_pole_positions,
            surpress_info = true,
            conf = {run_over_multiple_ticks = state.conf.run_over_multiple_ticks}
        }
    )
    return true
end

function OB_stage.place_end_pipes(state)
    if state.count < state.num_rows then
        local end_x = state.row_length + 0.5
        local last_miner_positions = {}
        for y, x in pairs(state.row_details[state.count + 1].last_miner_x_by_y) do
            table.insert(last_miner_positions, {x = x, y = y})
        end
        table.sort(
            last_miner_positions,
            function(a, b)
                return a.y < b.y
            end
        )

        for k, pos in ipairs(last_miner_positions) do
            if state.last_end_pipe_y then
                OB_helper.pipe_connect(state, state.last_end_pipe_y + 1, pos.y - 1, end_x, true)
            end
            OB_helper.pipe_connect(state, pos.x + 2, end_x - 1, pos.y)
            OB_helper.place_entity(state, {name = state.conf.pipe_name, position = {x = end_x, y = pos.y}})
            state.last_end_pipe_y = pos.y
        end
        return false
    else
        return true
    end
end

function OB_stage.leaving_belts(state)
    return OB_helper.blueprint_leaving_belt(state, state.blueprint_data.leaving_belts)
end

function OB_stage.leaving_underground_belts(state)
    return OB_helper.blueprint_leaving_belt(state, state.blueprint_data.leaving_underground_belts, true)
end

function OB_stage.merge_lanes(state)
    if #state.belt_row_details <= state.conf.output_belt_count then
        return true
    end

    -- Merge the lanes with the fewest miners
    local min = math.huge
    local min_index = nil
    local prev = math.huge
    for i, v in ipairs(state.belt_row_details) do
        if prev + v.miner_count < min then
            min = prev + v.miner_count
            min_index = i
        end
        prev = v.miner_count
    end

    local pos1 = state.belt_row_details[min_index - 1].end_pos
    local pos2 = state.belt_row_details[min_index].end_pos

    local belt1 = state.belt_row_details[min_index - 1].belt
    local belt2 = state.belt_row_details[min_index].belt

    -- If a row ends in a splitter (from a previous iteration), then its y position will be <>.0, so take the closest.
    if pos1.y % 1 == 0 then
        pos1.y = pos1.y + 0.5
    end
    if pos2.y % 1 == 0 then
        pos2.y = pos2.y - 0.5
    end

    while pos2.x - 1 > pos1.x do
        pos1.x = pos1.x + 1
        OB_helper.place_entity(
            state,
            {position = {x = pos1.x, y = pos1.y}, name = belt1, direction = defines.direction.east}
        )
    end
    while pos1.x > pos2.x - 1 do
        pos2.x = pos2.x + 1
        OB_helper.place_entity(
            state,
            {position = {x = pos2.x, y = pos2.y}, name = belt2, direction = defines.direction.east}
        )
    end

    pos1.x = pos1.x + 1
    while pos1.y + 1 < pos2.y do
        OB_helper.place_entity(
            state,
            {position = {x = pos1.x, y = pos1.y}, name = belt1, direction = defines.direction.south}
        )
        pos1.y = pos1.y + 1
    end

    OB_helper.place_entity(
        state,
        {position = {x = pos1.x, y = pos1.y}, name = belt1, direction = defines.direction.east}
    )
    pos1.x = pos1.x + 1
    local new_miner_count_below =
        state.belt_row_details[min_index].miner_count_below + state.belt_row_details[min_index - 1].miner_count_below
    local new_miner_count_above =
        state.belt_row_details[min_index].miner_count_above + state.belt_row_details[min_index - 1].miner_count_above
    state.belt_row_details[min_index] = {
        miner_count = state.belt_row_details[min_index].miner_count + state.belt_row_details[min_index - 1].miner_count,
        miner_count_below = new_miner_count_below,
        miner_count_above = new_miner_count_above,
        end_pos = {x = pos1.x, y = pos1.y + 0.5}
    }
    local belt = OB_helper.choose_belt(state, state.belt_row_details[min_index])
    state.belt_row_details[min_index].belt = belt
    OB_helper.place_entity(
        state,
        {position = {x = pos1.x, y = pos1.y + 0.5}, name = belt_to_splitter(belt), direction = defines.direction.east}
    )
    table.remove(state.belt_row_details, min_index - 1)
end

function OB_stage.collate_outputs(state) -- Move the outputs to be adjacent.
    local row = table.remove(state.belt_row_details)
    if row == nil then
        return true
    end
    local belt = row.belt

    if #state.output_rows == 0 then
        if row.end_pos.y % 1 == 0 then
            row.end_pos.y = row.end_pos.y - 0.5
        end
        row.end_pos.x = row.end_pos.x + 1
        OB_helper.place_entity(state, {position = row.end_pos, name = belt, direction = defines.direction.east})
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
                OB_helper.place_entity(state, {position = pos, name = row.belt, direction = defines.direction.east})
            end
        end

        while row.end_pos.x < state.output_rows[1].end_pos.x do
            OB_helper.place_entity(state, {position = row.end_pos, name = belt, direction = defines.direction.east})
            row.end_pos.x = row.end_pos.x + 1
        end

        while row.end_pos.y + 1 < state.output_rows[#state.output_rows].end_pos.y do
            OB_helper.place_entity(state, {position = row.end_pos, name = belt, direction = defines.direction.south})
            row.end_pos.y = row.end_pos.y + 1
        end
        OB_helper.place_entity(state, {position = row.end_pos, name = belt, direction = defines.direction.east})
        table.insert(state.output_rows, row)
    end
end
