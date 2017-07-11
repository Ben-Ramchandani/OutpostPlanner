require("mod-gui")
require("util")
require("on_init")

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
    local advanced_button = frame.add({type = "button", name = "OutpostBuilderToggleAdvancedButton", style = mod_gui.button_style, caption = {"outpost-builder.advanced-button-caption"}, tooltip = {"outpost-builder.advanced-button-tooltip"}})
    add_basic_settings_buttons(frame, conf)
end

function add_basic_settings_buttons(frame, conf)
    frame.add({type = "button", name = "OutpostBuilderDirectionButton", style = mod_gui.button_style, tooltip = {"outpost-builder.output-direction"}})
    frame.add({type = "button", name = "OutpostBuilderOutputRowsButton", style = mod_gui.button_style, tooltip = {"outpost-builder.output-belts"}})
    frame.add({type = "sprite-button", name = "OutpostBuilderMinerButton", sprite = ("entity/" .. conf.miner_name), style = mod_gui.button_style})
    frame.add({type = "sprite-button", name = "OutpostBuilderPoleButton", sprite = ("entity/" .. conf.electric_pole), style = mod_gui.button_style})
    frame.add({type = "sprite-button", name = "OutpostBuilderPipeButton", sprite = ("entity/" .. conf.pipe_name), style = mod_gui.button_style})
    frame.add({type = "sprite-button", name = "OutpostBuilderBeltButton", sprite = "item/transport-belt", style = mod_gui.button_style, tooltip = {"outpost-builder.belt-button"}})
end

function create_advanced_window(conf, player)
    local frame_flow = mod_gui.get_frame_flow(player)
    if frame_flow.OutpostBuilderAdvancedWindow then
        frame_flow.OutpostBuilderAdvancedWindow.destroy()
    end
    
    local frame = frame_flow.add({type = "frame", name = "OutpostBuilderAdvancedWindow", direction = "vertical", style = mod_gui.frame_style})
    frame.style.visible = false
    
    frame.add({type = "label", name = "OutpostBuilderBasicSettingsLabel", caption = {"outpost-builder.basic-settings-label"}})
    local basic_settings_flow = frame.add({type = "flow", name = "OutpostBuilderBasicSettingsFlow", direction = "horizontal"})
    basic_settings_flow.add({type = "button", name = "OutpostBuilderToggleAdvancedButton", style = mod_gui.button_style, caption = {"outpost-builder.close-advanced-button-caption"}})
    add_basic_settings_buttons(basic_settings_flow, conf)
    
    frame.add({type = "label", name = "OutpostBuilderBlueprintReadLabel", caption = {"outpost-builder.read-blueprint-label"}})
    local blueprint_read_flow = frame.add({type = "flow", name = "OutpostBuilderBlueprintReadFlow", direction = "horizontal"})
    blueprint_read_flow.add({type = "sprite-button", name = "OutpostBuilderBlueprintReadButton", sprite = "miner-blueprint", style = mod_gui.button_style, tooltip = {"outpost-builder.mining-blueprint-read-tooltip"}})
    
    frame.add({type = "label", name = "OutpostBuilderBlueprintExamplesLabel", caption = {"outpost-builder.example-blueprints-label"}})
    local blueprint_examples_flow = frame.add({type = "flow", name = "OutpostBuilderBlueprintExamplesFlow", direction = "horizontal"})
    
    frame.add({type = "label", name = "OutpostBuilderDummyEntitiesLabel", caption = {"outpost-builder.dummy-entities-label"}})
    local dummy_entities_flow = frame.add({type = "flow", name = "OutpostBuilderDummyEntitiesFlow", direction = "horizontal"})
    dummy_entities_flow.add({type = "sprite-button", name = "OutpostBuilderDummySpaceButton", sprite = "entity/" .. conf.dummy_spacing_entitiy, style = mod_gui.button_style, tooltip = {"outpost-builder.dummy-space-tooltip"}})
    dummy_entities_flow.add({type = "sprite-button", name = "OutpostBuilderDummyPipeButton", sprite = "entity/" .. conf.dummy_pipe, style = mod_gui.button_style, tooltip = {"outpost-builder.dummy-pipe-tooltip"}})

    frame.add({type = "label", name = "OutpostBuilderPoleOptionsLabel", caption = {"outpost-builder.pole-options-label"}})
    local pole_options_flow = frame.add({type = "flow", name = "OutpostBuilderPoleOptions", direction = "vertical"})
    add_radio(pole_options_flow, {"simple", "intelligent", "automatic"}, "outpost-builder.pole-options-")
    --frame.add({type = "radiobutton", name = "OutpostBuilderPoleOptions#simple", caption = {"outpost-builder.pole-options-simple"}, state = false})
end

function add_radio(frame, optionsList, caption_base)
    local name = frame.name

    for i, v in ipairs(optionsList) do
        frame.add({type = "radiobutton", name = name .. "#" .. v, caption = {caption_base .. v}, state = false})
    end
end

function update_radio(frame, selected)
    local name = frame.name
    for k, v in pairs(frame.children) do 
        v.state = string.gsub(v.name, name .. "%#(%w+)", "%1") == selected
    end
end

function update_advanced_window(conf, player)
    local frame_flow = mod_gui.get_frame_flow(player)
    local frame = frame_flow.OutpostBuilderAdvancedWindow
    update_basic_settings(frame.OutpostBuilderBasicSettingsFlow, conf, player)

    frame.OutpostBuilderDummyEntitiesFlow.OutpostBuilderDummyPipeButton.sprite = "entity/" .. conf.dummy_pipe
    frame.OutpostBuilderDummyEntitiesFlow.OutpostBuilderDummySpaceButton.sprite = "entity/" .. conf.dummy_spacing_entitiy

    update_radio(frame.OutpostBuilderPoleOptions, conf.pole_options_selected)
end


function update_basic_settings(frame, conf, player)
    if frame.OutpostBuilderDirectionButton then
        frame.OutpostBuilderDirectionButton.caption = gui.directions[math.floor(conf.direction / 2) + 1]
    end
    
    if frame.OutpostBuilderOutputRowsButton then
        local belt_count_string
        if conf.output_belt_count >= 100 then
            belt_count_string = "∞"
        else
            belt_count_string = tostring(conf.output_belt_count)
        end
        frame.OutpostBuilderOutputRowsButton.caption = belt_count_string
        frame.OutpostBuilderOutputRowsButton.enabled = not conf.use_chest
    end
    
    if frame.OutpostBuilderMinerButton then
        frame.OutpostBuilderMinerButton.sprite = "entity/" .. conf.miner_name
        frame.OutpostBuilderMinerButton.tooltip = {"entity-name." .. conf.miner_name}
    end
    
    if frame.OutpostBuilderPoleButton then
        frame.OutpostBuilderPoleButton.sprite = "entity/" .. conf.electric_pole
        frame.OutpostBuilderPoleButton.tooltip = {"entity-name." .. conf.electric_pole}
    end
    
    if frame.OutpostBuilderPipeButton then
        frame.OutpostBuilderPipeButton.sprite = "entity/" .. conf.pipe_name
        frame.OutpostBuilderPipeButton.tooltip = {"entity-name." .. conf.pipe_name}
    end
    
    local i = 1
    while i <= #frame.children do
        element = frame.children[i]
        if string.sub(element.name, 1, 24) == "OutpostBuilderBeltSprite" then
            element.destroy()
        else
            i = i + 1
        end
    end
    
    if frame.OutpostBuilderBeltButton then
        if conf.use_chest then
            frame.OutpostBuilderBeltButton.sprite = "entity/" .. conf.use_chest
            frame.OutpostBuilderBeltButton.tooltip = {"entity-name." .. conf.use_chest}
        else
            local transport_belts = conf.transport_belts
            frame.OutpostBuilderBeltButton.sprite = "item/transport-belt"
            frame.OutpostBuilderBeltButton.tooltip = {"outpost-builder.belt-button"}
            for j, belt in ipairs(transport_belts) do
                local sprite = frame.add({type = "sprite", name = "OutpostBuilderBeltSprite-" .. j, sprite = "entity/" .. belt, tooltip = {"entity-name." .. belt}})
                sprite.style.minimal_height = 34
                sprite.style.top_padding = 2
            end
        end
    end
end

function update_gui(player)
    create_button(player)
    local conf = get_config(player)
    local frame_flow = mod_gui.get_frame_flow(player)
    local frame = frame_flow.OutpostBuilderWindow
    update_basic_settings(frame, conf, player)
    update_advanced_window(conf, player)
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
    create_advanced_window(conf, player)
    update_gui(player)
end

function toggle_settings_window(event)
    local player = game.players[event.element.player_index]
    local conf = get_config(player)
    local frame_flow = mod_gui.get_frame_flow(player)
    if frame_flow.OutpostBuilderWindow.style.visible or frame_flow.OutpostBuilderAdvancedWindow.style.visible then
        frame_flow.OutpostBuilderWindow.style.visible = false
        frame_flow.OutpostBuilderAdvancedWindow.style.visible = false
    else
        frame_flow.OutpostBuilderWindow.style.visible = not conf.advanced_window_open
        frame_flow.OutpostBuilderAdvancedWindow.style.visible = conf.advanced_window_open
    end
end

function toggle_advanced_window(event)
    local player = game.players[event.element.player_index]
    local frame_flow = mod_gui.get_frame_flow(player)
    frame_flow.OutpostBuilderWindow.style.visible = frame_flow.OutpostBuilderAdvancedWindow.style.visible
    frame_flow.OutpostBuilderAdvancedWindow.style.visible = not frame_flow.OutpostBuilderAdvancedWindow.style.visible
    set_config(player, {advanced_window_open = frame_flow.OutpostBuilderAdvancedWindow.style.visible})
end

function belt_button_click(event)
    local player = game.players[event.element.player_index]
    local conf = get_config(player)
    local item_stack = player.cursor_stack
    if item_stack and item_stack.valid and item_stack.valid_for_read then
        local place_result = item_stack.prototype.place_result
        if place_result and place_result.type == "transport-belt" then
            local name = place_result.name
            if conf.use_chest then
                set_config(player, {use_chest = false})
                player.print {"outpost-builder.using-belt"}
                update_gui(player)
                return 
            end
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
        elseif place_result and (place_result.type == "container" or place_result.type == "logistic-container") then
            set_config(player, {use_chest = place_result.name})
            player.print({"outpost-builder.using-chest", {"entity-name." .. place_result.name}})
            update_gui(player)
        else
            player.print({"outpost-builder.unknown-item"})
        end
    else
        player.print({"outpost-builder.change-belt"})
        player.print({"outpost-builder.change-belt-1"})
        player.print({"outpost-builder.change-belt-2"})
        player.print({"outpost-builder.change-belt-3"})
    end
end

function miner_button_click(event)
    local player = game.players[event.element.player_index]
    local conf = get_config(player)
    local item_stack = player.cursor_stack
    if item_stack and item_stack.valid and item_stack.valid_for_read then
        local place_result = item_stack.prototype.place_result
        if place_result and place_result.type == "mining-drill" and place_result.resource_categories["basic-solid"] then
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
                player.print {"outpost-builder.no-underground-pipe"}
                return 
            end
            set_config(player, {pipe_name = place_result.name})
            player.print({"outpost-builder.use-pipe", {"entity-name." .. place_result.name}})
            local frame_flow = mod_gui.get_frame_flow(player)
            frame_flow.OutpostBuilderAdvancedWindow.OutpostBuilderPipeButton.sprite = "entity/" .. place_result.name
            frame_flow.OutpostBuilderAdvancedWindow.OutpostBuilderPipeButton.tooltip = {"entity-name." .. place_result.name}
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
    if item_stack and item_stack.valid and item_stack.valid_for_read and item_stack.prototype.stack_size > 1 then
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

function blueprint_button_click(event)
    local player = game.players[event.element.player_index]
    local item_stack = player.cursor_stack
    if item_stack and item_stack.valid and item_stack.valid_for_read and item_stack.name == "blueprint" and item_stack.is_blueprint_setup() then
        local entities = item_stack.get_blueprint_entities()
        local bounding_box = find_blueprint_bounding_box(entities)
        local shift_x = math.ceil((-bounding_box.left_top.x) - 0.5) + 0.5
        local shift_y = math.ceil((-bounding_box.left_top.y) - 0.5) + 0.5
        table.apply(
            entities,
            function(entity)
                entity.direction = entity.direction or 0
                entity.position.x = entity.position.x + shift_x
                entity.position.y = entity.position.y + shift_y
            end
        )
        local width = math.ceil(bounding_box.right_bottom.x + shift_x)
        local height = math.ceil(bounding_box.right_bottom.y + shift_y)
        height = height - overlap_by_y(entities, height)
        table.remove_all(
            entities,
            function(e)
                return e.name == "wooden-chest"
            end
        )
        local leaving_belt = find_leaving_belt(entities, width)
        if leaving_belt and game.entity_prototypes[leaving_belt.name].type == "underground-belt" and not game.entity_prototypes[underground_to_belt(leaving_belt.name)] then
            leaving_belt = nil
        end
        if not leaving_belt then
            leaving_belt = false
        end
        set_config(player, {blueprint_entities = entities, blueprint_width = width, blueprint_height = height, leaving_belt = leaving_belt})
    else
        player.print {"outpost-builder.no-blueprint"}
        set_config(player, {blueprint_entities = false, blueprint_width = false, blueprint_height = false, leaving_belt = false})
    end
end

script.on_event(
    defines.events.on_gui_click,
    function(event)
        if event.element.name == "OutpostBuilder" then
            toggle_settings_window(event)
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
        elseif event.element.name == "OutpostBuilderBlueprintReadButton" then
            blueprint_button_click(event)
        elseif event.element.name == "OutpostBuilderToggleAdvancedButton" then
            toggle_advanced_window(event)
        end
    end
)

script.on_event(
    defines.events.on_player_joined_game,
    function(event)
        init_gui_player(game.players[event.player_index])
    end
)

table.insert(ON_INIT, init_gui)
