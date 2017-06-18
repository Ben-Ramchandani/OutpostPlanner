require("config")
require("util")
require("remote")

--[[  Helper funtions  ]]--

function find_ore(ores, entities)
    -- Find the most common ore in the area
    local ore_counts = {}
    for i, ore in ipairs(ores) do
        ore_counts[ore] = 0
    end
    for k, entity in pairs(entities) do
        if entity.valid and ore_counts[entity.name] then
            ore_counts[entity.name] = ore_counts[entity.name] + 1
        end
    end
    local max_count = 0
    local max_ore = nil
    for ore, count in pairs(ore_counts) do
        if count > max_count then
            max_ore, max_count = ore, count
        end
    end
    return max_ore
end

function find_bounding_box(entities, name)
    local top = math.huge
    local left = math.huge
    local right = -math.huge
    local bottom = -math.huge
    
    for k, entity in pairs(entities) do
        if entity.valid and entity.name == name then
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

--[[  On tick  ]]--

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
            if state.stage < #stages then
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

--[[  Placement functions  ]]--

function place_miner(state)
    local x = state.left + (state.count % state.miners_per_row) * state.conf.miner_width + math.floor(state.conf.miner_width / 2)
    local half_row = math.floor(state.count / state.miners_per_row)
    local row = math.floor(half_row / 2)
    if (half_row >= state.num_half_rows) then
        state.stage = 1
        state.count = 0
        return 
    end
    local y = state.top + math.floor(state.conf.miner_width / 2) + half_row * state.row_height / 2
    local direction = (half_row % 2 == 0) and defines.direction.south or defines.direction.north
    
    if state.conf.check_dirty_mining then
        local radius = state.conf.miner_area / 2
        local mining_box = {{x - radius, y - radius}, {x + radius, y + radius}}
        local entities = state.surface.find_entities_filtered({area = mining_box, force = "neutral"})
        
        for k, entity in pairs(entities) do
            if contains(state.other_ores, entity.name) then
                state.count = state.count + 1
                return 
            end
        end
    end

    if state.conf.check_for_ore then
        local radius = state.conf.miner_width / 2
        local mining_box = {{x - radius, y - radius}, {x + radius, y + radius}}
        local entities = state.surface.find_entities_filtered({area = mining_box, force = "neutral"})
        local found_ore = false
        for k, entity in pairs(entities) do
            if entity.name == state.ore then
                found_ore = true
            end
        end
        if not found_ore then
            state.count = state.count + 1
            return 
        end
    end
    
    if place_entity(state, {position = {x, y}, direction = direction, name = state.conf.miner_name}) then
        state.row_details[row + 1].miner_count = state.row_details[row + 1].miner_count + 1
    end
    state.count = state.count + 1
end

function place_pole(state)
    local row = math.floor(state.count / state.electric_poles_per_row)
    if (row > state.num_half_rows / 2) then
        state.stage = 2
        state.count = 0
        return 
    end
    
    local x = state.left + state.conf.electric_pole_indent + (state.count % state.electric_poles_per_row) * state.conf.electric_pole_spacing
    if x > state.right then
        x = state.right
    end
    local y = state.top + row * state.row_height - 1
    
    place_entity(state, {position = {x, y}, name = state.conf.electric_pole})
    state.count = state.count + 1
end

function place_belt(state)
    local x = state.left + (state.count % (state.row_length - 1)) + 1
    local row = math.floor(state.count / (state.row_length - 1))
    if row >= state.num_rows then
        state.stage = 3
        state.count = 0
        return 
    end
    local y = state.top + row * state.row_height + state.conf.miner_width
    
    local pos = {x = x, y = y}
    place_entity(state, {position = pos, name = state.conf.transport_belt_miners, direction = defines.direction.east})
    state.row_details[row + 1].end_pos = pos
    state.count = state.count + 1
end

function merge_lanes(state)
    if state.num_rows <= state.conf.output_belt_count then
        state.stage = 4
        return 
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
    
    local pos2 = state.row_details[min_index].end_pos
    local pos1 = state.row_details[min_index - 1].end_pos
    
    -- If a row ends in a splitter (from a previous iteration), then its y position will be <>.5, so take the closest.
    if pos1.y % 1 == 0.5 then
        pos1.y = pos1.y + 0.5
    end
    if pos2.y % 1 == 0.5 then
        pos2.y = pos2.y - 0.5
    end
    
    while pos2.x - 1 > pos1.x do
        pos1.x = pos1.x + 1
        place_entity(state, {position = {x = pos1.x, y = pos1.y}, name = state.conf.transport_belt_join, direction = defines.direction.east})
    end
    while pos1.x > pos2.x - 1 do
        pos2.x = pos2.x + 1
        place_entity(state, {position = {x = pos2.x, y = pos2.y}, name = state.conf.transport_belt_join, direction = defines.direction.east})
    end
    
    pos1.x = pos1.x + 1
    while pos1.y + 1 < pos2.y do
        place_entity(state, {position = {x = pos1.x, y = pos1.y}, name = state.conf.transport_belt_join, direction = defines.direction.south})
        pos1.y = pos1.y + 1
    end
    
    place_entity(state, {position = {x = pos1.x, y = pos1.y}, name = state.conf.transport_belt_join, direction = defines.direction.east})
    pos1.x = pos1.x + 1
    place_entity(state, {position = {x = pos1.x, y = pos1.y + 0.5}, name = state.conf.splitter_join, direction = defines.direction.east})
    
    state.row_details[min_index] = {miner_count = state.row_details[min_index].miner_count + state.row_details[min_index - 1].miner_count, end_pos = {x = pos1.x, y = pos1.y + 0.5}}
    table.remove(state.row_details, min_index - 1)
    state.num_rows = state.num_rows - 1
    state.num_half_rows = nil
end

function collate_outputs(state) -- Move the outputs to be adjacent.
    local row = table.remove(state.row_details)
    if row == nil then
        state.stage = 5
        return 
    end

    if #state.output_row_positions == 0 then
        if row.end_pos.y % 1 == 0.5 then
            row.end_pos.y = row.end_pos.y - 0.5
        end
        row.end_pos.x = row.end_pos.x + 1
        place_entity(state, {position = row.end_pos, name = state.conf.transport_belt_join, direction = defines.direction.east})
        table.insert(state.output_row_positions, row.end_pos)
    else
        if row.end_pos.y % 1 == 0.5 then
            row.end_pos.y = row.end_pos.y + 0.5
        end
        
        row.end_pos.x = row.end_pos.x + 1
        local expand_to = math.max(row.end_pos.x, state.output_row_positions[1].x + 1)

        while state.output_row_positions[1].x < expand_to do
            for i, pos in ipairs(state.output_row_positions) do
                pos.x = pos.x + 1
                place_entity(state, {position = pos, name = state.conf.transport_belt_join, direction = defines.direction.east})
            end
        end

        while row.end_pos.x < state.output_row_positions[1].x do
            place_entity(state, {position = row.end_pos, name = state.conf.transport_belt_join, direction = defines.direction.east})
            row.end_pos.x = row.end_pos.x + 1
        end

        while row.end_pos.y + 1 < state.output_row_positions[#state.output_row_positions].y do
            place_entity(state, {position = row.end_pos, name = state.conf.transport_belt_join, direction = defines.direction.south})
            row.end_pos.y = row.end_pos.y + 1
        end
        place_entity(state, {position = row.end_pos, name = state.conf.transport_belt_join, direction = defines.direction.east})
        table.insert(state.output_row_positions, row.end_pos)
    end
end

stages = {place_miner, place_pole, place_belt, merge_lanes, collate_outputs}

function placement_tick(state)
    stages[state.stage + 1](state)
end

--[[  Main funtions  ]]--

function on_alt_selected_area(event) -- Destroy ghosts and deconstruct empty miners
    local player = game.players[event.player_index]
    local surface = player.surface
    local force = player.force

    if not global.OB_CONF then
        global.OB_CONF = table.clone(OB_CONF)
    end
    
    for k, entity in pairs(event.entities) do
        if entity and entity.valid then
            if entity.name == "entity-ghost" then
                entity.destroy()
            elseif entity.name == global.OB_CONF.miner_name and entity.mining_target == nil then
                entity.order_deconstruction(force)
            end
        end
    end
end

function on_selected_area(event) -- Build an outpost
    local player = game.players[event.player_index]
    local surface = player.surface
    local force = player.force

    if not global.OB_CONF then
        global.OB_CONF = table.clone(OB_CONF)
    end
    local conf = global.OB_CONF


    local ore = find_ore(conf.ores, event.entities)
    if ore == nil then
        player.print("No ore found in selected area.")
        return
    end

    for k, entity in pairs(event.entities) do
        if entity and entity.valid then
            entity.order_deconstruction(force)
        end
    end
    
    local bounding_box = find_bounding_box(event.entities, ore)
    
    local top = bounding_box.left_top.y
    local left = bounding_box.left_top.x
    local right = bounding_box.right_bottom.x
    local bottom = bounding_box.right_bottom.y
    
    local row_height = conf.miner_width * 2 + 2
    local num_rows = math.ceil((bottom - top) / row_height) -- Number of rows of belt
    local num_half_rows = math.ceil(2 * (bottom - top) / row_height) -- Number of rows of miners
    
    local miners_per_row = math.ceil((right - left) / conf.miner_width)
    local row_length = miners_per_row * conf.miner_width
    local electric_poles_per_row = math.ceil(row_length / conf.electric_pole_spacing)
    
    local other_ores = nil
    if conf.check_dirty_mining then
        other_ores = table.array_clone(conf.ores)
        local index = contains(other_ores, ore)
        table.remove(other_ores, index)
    end

    local state = {
        stage = 0,
        count = 0,
        player = player,
        force = force,
        surface = surface,
        top = top,
        left = left,
        bottom = bottom,
        right = right,
        row_length = row_length,
        row_height = row_height,
        num_rows = num_rows,
        num_half_rows = num_half_rows,
        row_details = {},
        output_row_positions = {},
        miners_per_row = miners_per_row,
        electric_poles_per_row = electric_poles_per_row,
        ore = ore,
        other_ores = other_ores,
        conf = table.clone(conf)
    }
    
    for i = 1, num_rows do
        state.row_details[i] = {miner_count = 0, end_pos = nil}
    end
    
    if conf.run_over_multiple_ticks then
        register(state)
    else
        while state.stage < #stages do
            placement_tick(state)
        end
    end
end

--[[  Register events  ]]--

-- Build outpost
script.on_event(
    defines.events.on_player_selected_area,
    function(event)
        if event.item == "outpost-builder" then
            on_selected_area(event)
        end
    end
)

-- Clear ghosts and deconstruct empty miners
script.on_event(
    defines.events.on_player_alt_selected_area,
    function(event)
        if event.item == "outpost-builder" then
            on_alt_selected_area(event)
        end
    end
)
