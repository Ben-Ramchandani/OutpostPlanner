require "mod-gui"

function create_button(player)
    local button_flow = mod_gui.get_button_flow(player)
    if not button_flow.OutpostBuilder then
        local button = button_flow.add({type = "button", name = "OutpostBuilder", caption = {"outpost-builder.initials"}, style = mod_gui.button_style, tooltip = {"outpost-builder.name"}})
    end
end

gui = {directions = {"N", "E", "S", "W"}, output_counts = {1, 2, 4, 8}}

function create_settings_window(conf, player)
    local frame_flow = mod_gui.get_frame_flow(player)
    if frame_flow.OutpostBuilderWindow then
        frame_flow.OutpostBuilderWindow.destroy()
    end
    
    local frame = frame_flow.add {type = "frame", name = "OutpostBuilderWindow", direction = "horizontal", style = mod_gui.frame_style}
    frame.style.visible = false
    local direction_button = frame.add({type = "button", name = "OutpostBuilderDirectionButton", style = mod_gui.button_style, tooltip = {"outpost-builder.output-direction"}})
    local output_rows_button = frame.add({type = "button", name = "OutpostBuilderOutputRowsButton", style = mod_gui.button_style, tooltip = {"outpost-builder.output-belts"}})
    local miner_entity_button = frame.add({type = "sprite-button", name = "OutpostBuilderMinerButton", sprite = ("entity/" .. conf.miner_name), style = mod_gui.button_style})
    local pole_entity_button = frame.add({type = "sprite-button", name = "OutpostBuilderPoleButton", sprite = ("entity/" .. conf.electric_pole), style = mod_gui.button_style})
    local pipe_entity_button = frame.add({type = "sprite-button", name = "OutpostBuilderPipeButton", sprite = ("entity/" .. conf.pipe_name), style = mod_gui.button_style})
    local belt_button = frame.add({type = "sprite-button", name = "OutpostBuilderBeltButton", sprite = "item/transport-belt", style = mod_gui.button_style, tooltip = {"outpost-builder.belt-button"}})
    update_gui(player)
end

function update_gui(player)
    create_button(player)
    local conf = get_config(player)
    local frame_flow = mod_gui.get_frame_flow(player)
    if not frame_flow.OutpostBuilderWindow then
        create_settings_window(conf, player)
    end
    local frame = frame_flow.OutpostBuilderWindow
    frame.OutpostBuilderDirectionButton.caption = gui.directions[math.floor(conf.direction / 2) + 1]
    local belt_count_string
    if conf.output_belt_count >= 100 then
        belt_count_string = "∞"
    else
        belt_count_string = tostring(conf.output_belt_count)
    end
    frame.OutpostBuilderOutputRowsButton.caption = belt_count_string
    frame.OutpostBuilderMinerButton.sprite = "entity/" .. conf.miner_name
    frame.OutpostBuilderMinerButton.tooltip = {"entity-name." .. conf.miner_name}
    frame.OutpostBuilderPoleButton.sprite = "entity/" .. conf.electric_pole
    frame.OutpostBuilderPoleButton.tooltip = {"entity-name." .. conf.electric_pole}
    frame.OutpostBuilderPipeButton.sprite = "entity/" .. conf.pipe_name
    frame.OutpostBuilderPipeButton.tooltip = {"entity-name." .. conf.pipe_name}
    local transport_belts = conf.transport_belts
    local i = 1
    while i <= #frame.children do
        element = frame.children[i]
        if string.sub(element.name, 1, 24) == "OutpostBuilderBeltSprite" then
            element.destroy()
        else
            i = i + 1
        end
    end
    for j, belt in ipairs(transport_belts) do
        local sprite = frame.add({type = "sprite", name = "OutpostBuilderBeltSprite-" .. j, sprite = "entity/" .. belt, tooltip = {"entity-name." .. belt}})
        sprite.style.minimal_height = 34
        sprite.style.top_padding = 2
    end
end

function init_gui()
    for k, player in pairs(game.players) do
        init_gui_player(player)
    end
end

function init_gui_player(player)
    if player.gui.top.OutpostBuilder then
        player.gui.top.OutpostBuilder.destroy()
    end
    local conf = get_config(player)
    create_button(player)
    create_settings_window(conf, player)
end

function toggle_settings_window(player)
    local frame_flow = mod_gui.get_frame_flow(player)
    if frame_flow.OutpostBuilderWindow then
        frame_flow.OutpostBuilderWindow.style.visible = not frame_flow.OutpostBuilderWindow.style.visible
    end
end

function belt_button_click(event)
    local player = game.players[event.element.player_index]
    local conf = get_config(player)
    local item_stack = player.cursor_stack
    if item_stack and item_stack.valid and item_stack.valid_for_read then
        local place_result = item_stack.prototype.place_result
        if place_result and place_result.type == "transport-belt" then
            local name = place_result.name
            local index = table.contains(conf.transport_belts, name)
            if index then
                if #conf.transport_belts > 1 then
                    player.print({"outpost-builder.forgetting-about", {"entity-name." .. name}})
                    table.remove(conf.transport_belts, index)
                else
                    player.print({"outpost-builder.no-belt"})
                    return
                end
            else
                if game.entity_prototypes[belt_to_splitter(name)] then
                    player.print({"outpost-builder.know-about", {"entity-name." .. name}})
                    table.insert(conf.transport_belts, name)
                else
                    player.print({"outpost-builder.no-splitter"})
                end
            end
            set_config(player, {transport_belts = conf.transport_belts})
            update_gui(player)
        else
            player.print({"outpost-builder.unknown-item"})
        end
    else
        player.print({"outpost-builder.change-belt"})
        player.print({"outpost-builder.change-belt-1"})
        player.print({"outpost-builder.change-belt-2"})
    end
end

function miner_button_click(event)
    local player = game.players[event.element.player_index]
    local conf = get_config(player)
    local item_stack = player.cursor_stack
    if item_stack and item_stack.valid and item_stack.valid_for_read then
        local place_result = item_stack.prototype.place_result
        if place_result and place_result.type == "mining-drill" then
            set_config(player, {miner_name = place_result.name})
            player.print({"outpost-builder.use-miner", {"entity-name." .. place_result.name}})
            local frame_flow = mod_gui.get_frame_flow(player)
            frame_flow.OutpostBuilderWindow.OutpostBuilderMinerButton.sprite = "entity/" .. place_result.name
            frame_flow.OutpostBuilderWindow.OutpostBuilderMinerButton.tooltip = {"entity-name." .. place_result.name}
        else
        player.print({"outpost-builder.unknown-item"})
        end
    else
        player.print({"outpost-builder.change-miner"})
    end
end

function pipe_button_click(event)
    local player = game.players[event.element.player_index]
    local conf = get_config(player)
    local item_stack = player.cursor_stack
    if item_stack and item_stack.valid and item_stack.valid_for_read then
        local place_result = item_stack.prototype.place_result
        if place_result and place_result.type == "pipe" then
            local underground_pipe = pipe_to_underground(place_result.name)
            if not game.entity_prototypes[underground_pipe] or not (game.entity_prototypes[underground_pipe].type == "pipe-to-ground") then
                player.print{"outpost-builder.no-underground-pipe"}
                return
            end
            set_config(player, {pipe_name = place_result.name})
            player.print({"outpost-builder.use-pipe", {"entity-name." .. place_result.name}})
            local frame_flow = mod_gui.get_frame_flow(player)
            frame_flow.OutpostBuilderWindow.OutpostBuilderPipeButton.sprite = "entity/" .. place_result.name
            frame_flow.OutpostBuilderWindow.OutpostBuilderPipeButton.tooltip = {"entity-name." .. place_result.name}
        else
        player.print({"outpost-builder.unknown-item"})
        end
    else
        player.print({"outpost-builder.change-pipe"})
    end
end

function pole_button_click(event)
    local player = game.players[event.element.player_index]
    local conf = get_config(player)
    local item_stack = player.cursor_stack
    if item_stack and item_stack.valid and item_stack.valid_for_read then
        local place_result = item_stack.prototype.place_result
        if place_result and place_result.type == "electric-pole" then
            set_config(player, {electric_pole = place_result.name})
            player.print({"outpost-builder.use-pole", {"entity-name." .. place_result.name}})
            local frame_flow = mod_gui.get_frame_flow(player)
            frame_flow.OutpostBuilderWindow.OutpostBuilderPoleButton.sprite = "entity/" .. place_result.name
            frame_flow.OutpostBuilderWindow.OutpostBuilderPoleButton.tooltip = {"entity-name." .. place_result.name}
        else
            player.print({"outpost-builder.unknown-item"})
        end
    else
        player.print({"outpost-builder.change-pole"})
    end
end

function direction_button_click(event)
    local player = game.players[event.element.player_index]
    local frame_flow = mod_gui.get_frame_flow(player)
    local direction_button = frame_flow.OutpostBuilderWindow.OutpostBuilderDirectionButton
    local conf = get_config(player)
    local new_direction = (conf.direction + 2) % 8
    set_config(player, {direction = new_direction})
    direction_button.caption = gui.directions[math.floor(new_direction / 2) + 1]
end

function count_button_click(event)
    local player = game.players[event.element.player_index]
    local conf = get_config(player)
    local frame_flow = mod_gui.get_frame_flow(player)
    local count_button = frame_flow.OutpostBuilderWindow.OutpostBuilderOutputRowsButton
    local item_stack = player.cursor_stack
    local new_count
    if item_stack and item_stack.valid and item_stack.valid_for_read then
        new_count = item_stack.count
    else
        local index = table.contains(gui.output_counts, conf.output_belt_count)
        if index then
            new_count = gui.output_counts[(index % #gui.output_counts) + 1]
        else
            new_count = gui.output_counts[1]
        end
    end
    set_config(player, {output_belt_count = new_count})
    local belt_count_string
    if new_count >= 100 then
        belt_count_string = "∞"
    else
        belt_count_string = tostring(new_count)
    end
    count_button.caption = belt_count_string
end

script.on_event(
    defines.events.on_gui_click,
    function(event)
        if event.element.name == "OutpostBuilder" then
            local player = game.players[event.element.player_index]
            toggle_settings_window(player)
        elseif event.element.name == "OutpostBuilderBeltButton" then
            belt_button_click(event)
        elseif event.element.name == "OutpostBuilderDirectionButton" then
            direction_button_click(event)
        elseif event.element.name == "OutpostBuilderOutputRowsButton" then
            count_button_click(event)
        elseif event.element.name == "OutpostBuilderMinerButton" then
            miner_button_click(event)
        elseif event.element.name == "OutpostBuilderPoleButton" then
            pole_button_click(event)
        elseif event.element.name == "OutpostBuilderPipeButton" then
            pipe_button_click(event)
        end
    end
)

script.on_event(
    defines.events.on_player_joined_game,
    function(event)
        init_gui_player(game.players[event.player_index])
    end
)

ON_INIT = ON_INIT or {}
table.insert(ON_INIT, init_gui)
