require("mod-gui")
require("util")
require("on_init")
require("example_blueprints")

function create_button(player)
    local button_flow = mod_gui.get_button_flow(player)
    if not button_flow.OutpostBuilder then
        local button =
            button_flow.add(
            {
                type = "button",
                name = "OutpostBuilder",
                caption = {"outpost-builder.initials"},
                style = mod_gui.button_style,
                tooltip = {"outpost-builder.name"}
            }
        )
    end
end

gui = {directions = {"N", "E", "S", "W"}, output_counts = {1, 2, 4, 8}}

function create_settings_window(conf, player)
    local frame_flow = mod_gui.get_frame_flow(player)
    if frame_flow.OutpostBuilderWindow then
        frame_flow.OutpostBuilderWindow.destroy()
    end

    local frame =
        frame_flow.add {
        type = "frame",
        name = "OutpostBuilderWindow",
        direction = "horizontal",
        style = mod_gui.frame_style
    }
    frame.visible = false
    local advanced_button =
        frame.add(
        {
            type = "button",
            name = "OutpostBuilderToggleAdvancedButton",
            style = mod_gui.button_style,
            caption = {"outpost-builder.advanced-button-caption"},
            tooltip = {"outpost-builder.advanced-button-tooltip"}
        }
    )
    add_basic_settings_buttons(frame, conf)
end

function add_basic_settings_buttons(frame, conf)
    frame.add(
        {
            type = "button",
            name = "OutpostBuilderDirectionButton",
            style = mod_gui.button_style,
            tooltip = {"outpost-builder.output-direction"}
        }
    )
    frame.add(
        {
            type = "button",
            name = "OutpostBuilderOutputRowsButton",
            style = mod_gui.button_style,
            tooltip = {"outpost-builder.output-belts"}
        }
    )
    frame.add(
        {
            type = "sprite-button",
            name = "OutpostBuilderBeltButton",
            sprite = "item/transport-belt",
            style = mod_gui.button_style,
            tooltip = {"outpost-builder.belt-button"}
        }
    )
end

function create_advanced_window(conf, player)
    local frame_flow = mod_gui.get_frame_flow(player)
    if frame_flow.OutpostBuilderAdvancedWindow then
        frame_flow.OutpostBuilderAdvancedWindow.destroy()
    end

    local frame =
        frame_flow.add(
        {type = "frame", name = "OutpostBuilderAdvancedWindow", direction = "vertical", style = mod_gui.frame_style}
    )
    frame.visible = false

    -- Basic settings
    frame.add(
        {type = "label", name = "OutpostBuilderBasicSettingsLabel", caption = {"outpost-builder.basic-settings-label"}}
    )
    local basic_settings_flow =
        frame.add({type = "flow", name = "OutpostBuilderBasicSettingsFlow", direction = "horizontal"})
    basic_settings_flow.add(
        {
            type = "button",
            name = "OutpostBuilderToggleAdvancedButton",
            style = mod_gui.button_style,
            caption = {"outpost-builder.close-advanced-button-caption"}
        }
    )
    add_basic_settings_buttons(basic_settings_flow, conf)

    -- Entity settings
    frame.add(
        {type = "label", name = "OutpostBuilderEntitiesLabel", caption = {"outpost-builder.entity-settings-label"}}
    )
    local entities_flow = frame.add({type = "flow", name = "OutpostBuilderEntitiesFlow", direction = "horizontal"})

    entities_flow.add(
        {
            type = "sprite-button",
            name = "OutpostBuilderPoleButton",
            sprite = ("entity/" .. conf.pole_name),
            style = mod_gui.button_style
        }
    )
    entities_flow.add(
        {
            type = "sprite-button",
            name = "OutpostBuilderPipeButton",
            sprite = ("entity/" .. conf.pipe_name),
            style = mod_gui.button_style
        }
    )
    entities_flow.add(
        {
            type = "sprite-button",
            name = "OutpostBuilderMinerButton",
            sprite = ("entity/" .. conf.miner_name),
            style = mod_gui.button_style
        }
    )
    entities_flow.add(
        {
            type = "sprite-button",
            name = "OutpostBuilderChestButton",
            sprite = ("entity/" .. conf.chest_name),
            style = mod_gui.button_style
        }
    )

    -- Blueprint read
    frame.add(
        {type = "label", name = "OutpostBuilderBlueprintReadLabel", caption = {"outpost-builder.read-blueprint-label"}}
    )
    local blueprint_read_flow =
        frame.add({type = "flow", name = "OutpostBuilderBlueprintReadFlow", direction = "horizontal"})
    blueprint_read_flow.add(
        {
            type = "sprite-button",
            name = "OutpostBuilderBlueprintReadButton",
            sprite = "miner-blueprint",
            style = mod_gui.button_style,
            tooltip = {"outpost-builder.mining-blueprint-read-tooltip"}
        }
    )

    -- Example blueprints
    frame.add(
        {
            type = "label",
            name = "OutpostBuilderBlueprintExamplesLabel",
            caption = {"outpost-builder.example-blueprints-label"}
        }
    )
    local blueprint_examples_flow =
        frame.add({type = "flow", name = "OutpostBuilderBlueprintExamplesFlow", direction = "horizontal"})

    for k, v in pairs(example_blueprints.raw) do
        blueprint_examples_flow.add(
            {
                type = "button",
                name = "OutpostBuilderBlueprintExample-" .. k,
                style = mod_gui.button_style,
                caption = {"outpost-builder.example-blueprint_" .. k}
            }
        )
    end

    blueprint_examples_flow.add(
        {
            type = "sprite-button",
            name = "OutpostBuilderBlueprintWriteButton",
            sprite = "miner-blueprint",
            style = mod_gui.button_style,
            tooltip = {"outpost-builder.mining-blueprint-write-tooltip"}
        }
    )

    -- Dummy entity
    frame.add(
        {type = "label", name = "OutpostBuilderDummyEntitiesLabel", caption = {"outpost-builder.dummy-entities-label"}}
    )
    local dummy_entities_flow =
        frame.add({type = "flow", name = "OutpostBuilderDummyEntitiesFlow", direction = "horizontal"})
    dummy_entities_flow.add(
        {
            type = "sprite-button",
            name = "OutpostBuilderDummySpaceButton",
            sprite = "entity/" .. conf.dummy_spacing_entitiy,
            style = mod_gui.button_style,
            tooltip = {"outpost-builder.dummy-space-tooltip"}
        }
    )

    -- Electric pole options
    frame.add(
        {type = "label", name = "OutpostBuilderPoleOptionsLabel", caption = {"outpost-builder.pole-options-label"}}
    )
    local pole_options_flow = frame.add({type = "flow", name = "OutpostBuilderPoleOptions", direction = "vertical"})
    add_radio(
        pole_options_flow,
        {"always", "simple", "intelligent" --[[, "automatic"--]]},
        "outpost-builder.pole-options-"
    )

    -- Other options
    frame.add(
        {type = "label", name = "OutpostBuilderOtherLabel", caption = {"outpost-builder.blueprint-other-options-label"}}
    )
    frame.add(
        {
            type = "checkbox",
            name = "OutpostBuilderFluidCheckbox",
            caption = {"outpost-builder.enable-fluid-checkbox"},
            state = false
        }
    )
    frame.add(
        {
            type = "checkbox",
            name = "OutpostBuilderBeltCheckbox",
            caption = {"outpost-builder.enable-belt-checkbox"},
            state = false
        }
    )
    frame.add(
        {
            type = "checkbox",
            name = "OutpostBuilderSmartBeltCheckbox",
            caption = {"outpost-builder.smart-belt-checkbox"},
            state = false
        }
    )

    -- Other entities
    refresh_other_entities_list(player)
end

function add_radio(frame, optionsList, caption_base)
    local name = frame.name

    for i, v in ipairs(optionsList) do
        frame.add({type = "radiobutton", name = name .. "#" .. v, caption = {caption_base .. v}, state = false})
    end
end

local function update_radio(frame, selected)
    local name = frame.name
    for k, v in pairs(frame.children) do
        v.state = string.gsub(v.name, name .. "%#(%w+)", "%1") == selected
    end
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
        local transport_belts = conf.transport_belts
        frame.OutpostBuilderBeltButton.sprite = "item/transport-belt"
        frame.OutpostBuilderBeltButton.tooltip = {"outpost-builder.belt-button"}
        for j, belt in ipairs(transport_belts) do
            local sprite =
                frame.add(
                {
                    type = "sprite",
                    name = "OutpostBuilderBeltSprite-" .. j,
                    sprite = "entity/" .. belt,
                    tooltip = {"entity-name." .. belt}
                }
            )
            sprite.style.minimal_height = 34
            sprite.style.top_padding = 2
        end
    end
end

local function update_entity_settings(frame, conf)
    if frame.OutpostBuilderPoleButton then
        frame.OutpostBuilderPoleButton.sprite = "entity/" .. conf.pole_name
        frame.OutpostBuilderPoleButton.tooltip = {"entity-name." .. conf.pole_name}
    end

    if frame.OutpostBuilderPipeButton then
        frame.OutpostBuilderPipeButton.sprite = "entity/" .. conf.pipe_name
        frame.OutpostBuilderPipeButton.tooltip = {"entity-name." .. conf.pipe_name}
    end

    if frame.OutpostBuilderMinerButton then
        frame.OutpostBuilderMinerButton.sprite = "entity/" .. conf.miner_name
        frame.OutpostBuilderMinerButton.tooltip = {"entity-name." .. conf.miner_name}
    end

    if frame.OutpostBuilderChestButton then
        frame.OutpostBuilderChestButton.sprite = "entity/" .. conf.chest_name
        frame.OutpostBuilderChestButton.tooltip = {"entity-name." .. conf.chest_name}
    end
end

function update_advanced_window(conf, player)
    local frame_flow = mod_gui.get_frame_flow(player)
    local frame = frame_flow.OutpostBuilderAdvancedWindow
    update_basic_settings(frame.OutpostBuilderBasicSettingsFlow, conf, player)
    update_entity_settings(frame.OutpostBuilderEntitiesFlow, conf)

    frame.OutpostBuilderDummyEntitiesFlow.OutpostBuilderDummySpaceButton.sprite =
        "entity/" .. conf.dummy_spacing_entitiy

    update_radio(frame.OutpostBuilderPoleOptions, conf.pole_options_selected)

    frame.OutpostBuilderBeltCheckbox.state = conf.enable_belt_collate

    frame.OutpostBuilderFluidCheckbox.state = conf.enable_pipe_placement

    frame.OutpostBuilderSmartBeltCheckbox.state = conf.smart_belt_placement
end

function refresh_other_entities_list(player, conf)
    local conf = conf or get_config(player)
    local frame_flow = mod_gui.get_frame_flow(player)
    local frame = frame_flow.OutpostBuilderAdvancedWindow
    if frame.OutpostBuilderOtherFlow then
        frame.OutpostBuilderOtherFlow.destroy()
    end
    local flow = frame.add({type = "flow", name = "OutpostBuilderOtherFlow", direction = "vertical"})
    name_table = {}
    for k, v in pairs(conf.blueprint_data.other_entities) do
        name_table[v.name] = true
    end
    local new_entity_settings = table.deep_clone(conf.other_entity_settings)
    for k, v in pairs(name_table) do
        new_entity_settings[k] = new_entity_settings[k] or {with_miners = true, every_x = 1}
        local inner_flow = flow.add({type = "flow", name = "OutpostBuilderOtherFlow-" .. k, direction = "horizontal"})
        inner_flow.add(
            {
                type = "sprite",
                name = "OutpostBuilderOtherSprite",
                sprite = "item/" .. k
            }
        )
        inner_flow.add(
            {
                type = "label",
                name = "OutpostBuilderOtherLabel",
                caption = {"entity-name." .. k}
            }
        )
        local options_flow =
            inner_flow.add({type = "flow", name = "OutpostBuilderOtherOptions" .. k, direction = "vertical"})
        options_flow.add(
            {
                type = "checkbox",
                name = "OutpostBuilderOtherWithMiners-" .. k,
                caption = {"outpost-builder.with-miners"},
                state = new_entity_settings[k].with_miners
            }
        )

        local place_every =
            options_flow.add(
            {
                type = "flow",
                name = "OutpostBuilderOtherPlaceEvery",
                direction = "horizontal"
            }
        )

        place_every.add(
            {
                type = "label",
                name = "OutpostBuilderPlaceLabel",
                caption = {"outpost-builder.place-every"}
            }
        )

        place_every.add(
            {
                type = "drop-down",
                name = "OutpostBuilderDropDown-" .. k,
                items = {"1", "2", "3", "4", "5"},
                selected_index = new_entity_settings[k].every_x
            }
        )
        place_every.add(
            {
                type = "label",
                name = "OutpostBuilderXBlueprintsLabel",
                caption = {"outpost-builder.x-blueprints"}
            }
        )
    end
    set_config(player, {other_entity_settings = new_entity_settings})
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

local function toggle_settings_window(event)
    local player = game.players[event.element.player_index]
    local conf = get_config(player)
    local frame_flow = mod_gui.get_frame_flow(player)
    if (not(frame_flow.OutpostBuilderWindow and frame_flow.OutpostBuilderAdvancedWindow)) then
        l.warn("Settings window has been destroyed, rebuilding")
        init_gui_player(player)
    end
    if frame_flow.OutpostBuilderWindow.visible or frame_flow.OutpostBuilderAdvancedWindow.visible then
        frame_flow.OutpostBuilderWindow.visible = false
        frame_flow.OutpostBuilderAdvancedWindow.visible = false
    else
        frame_flow.OutpostBuilderWindow.visible = not conf.advanced_window_open
        frame_flow.OutpostBuilderAdvancedWindow.visible = conf.advanced_window_open
    end
end

local function toggle_advanced_window(event)
    local player = game.players[event.element.player_index]
    local frame_flow = mod_gui.get_frame_flow(player)
    frame_flow.OutpostBuilderWindow.visible = frame_flow.OutpostBuilderAdvancedWindow.visible
    frame_flow.OutpostBuilderAdvancedWindow.visible = not frame_flow.OutpostBuilderAdvancedWindow.visible
    set_config(player, {advanced_window_open = frame_flow.OutpostBuilderAdvancedWindow.visible})
end

local function belt_button_click(event)
    local player = game.players[event.element.player_index]
    local conf = get_config(player)
    local item_stack = player.cursor_stack
    if item_stack and item_stack.valid and item_stack.valid_for_read then
        local place_result = item_stack.prototype.place_result
        if place_result and place_result.type == "transport-belt" then
            local name = place_result.name
            local transport_belts = table.deep_clone(conf.transport_belts)
            local index = table.contains(transport_belts, name)
            if index then
                if #transport_belts > 1 then
                    player.print({"outpost-builder.forgetting-about", {"entity-name." .. name}})
                    table.remove(transport_belts, index)
                else
                    player.print({"outpost-builder.no-belt"})
                    return
                end
            else
                if game.entity_prototypes[belt_to_splitter(name)] then
                    player.print({"outpost-builder.know-about", {"entity-name." .. name}})
                    table.insert(transport_belts, name)
                else
                    player.print({"outpost-builder.no-splitter"})
                end
            end
            set_config(player, {transport_belts = transport_belts})
        else
            player.print({"outpost-builder.unknown-item"})
        end
    else
        player.print({"outpost-builder.change-belt"})
        player.print({"outpost-builder.change-belt-1"})
        player.print({"outpost-builder.change-belt-2"})
    end
end

local function belt_sprite_click(event, num)
    local index = tonumber(num)
    local player = game.players[event.element.player_index]
    local conf = get_config(player)
    local transport_belts = table.deep_clone(conf.transport_belts)
    if #transport_belts > 1 then
        player.print({"outpost-builder.forgetting-about", {"entity-name." .. transport_belts[index]}})
        table.remove(transport_belts, index)
        set_config(player, {transport_belts = transport_belts})
    else
        player.print({"outpost-builder.no-belt"})
    end
end

local function miner_button_click(event)
    local player = game.players[event.element.player_index]
    local conf = get_config(player)
    local item_stack = player.cursor_stack
    if item_stack and item_stack.valid and item_stack.valid_for_read then
        local place_result = item_stack.prototype.place_result
        if place_result and place_result.type == "mining-drill" then
            local old_prototype = game.entity_prototypes[conf.miner_name]
            if table.deep_compare(place_result.collision_box, old_prototype.collision_box) then
                if
                    (not old_prototype.module_inventory_size) or
                        (place_result.module_inventory_size and
                            place_result.module_inventory_size >= old_prototype.module_inventory_size)
                 then
                    set_config(player, {miner_name = place_result.name})
                    player.print({"outpost-builder.use-miner", {"entity-name." .. place_result.name}})
                else
                    player.print({"outpost-builder.module-inventory-downsize"})
                end
            else
                player.print(
                    {
                        "outpost-builder.bad-fast-replace",
                        {"entity-name." .. place_result.name},
                        {"entity-name." .. conf.miner_name}
                    }
                )
            end
        else
            player.print({"outpost-builder.unknown-item"})
        end
    else
        player.print({"outpost-builder.change-miner"})
    end
end

local function pipe_button_click(event)
    local player = game.players[event.element.player_index]
    local conf = get_config(player)
    local item_stack = player.cursor_stack
    if item_stack and item_stack.valid and item_stack.valid_for_read then
        local place_result = item_stack.prototype.place_result
        if place_result and place_result.type == "pipe" then
            local underground_pipe = pipe_to_underground(place_result.name)
            if
                not game.entity_prototypes[underground_pipe] or
                    not (game.entity_prototypes[underground_pipe].type == "pipe-to-ground")
             then
                player.print {"outpost-builder.no-underground-pipe"}
                return
            end
            set_config(player, {pipe_name = place_result.name})
            player.print({"outpost-builder.use-pipe", {"entity-name." .. place_result.name}})
        else
            player.print({"outpost-builder.unknown-item"})
        end
    else
        player.print({"outpost-builder.change-pipe"})
    end
end

local function chest_button_click(event)
    local player = game.players[event.element.player_index]
    local conf = get_config(player)
    local item_stack = player.cursor_stack
    if item_stack and item_stack.valid and item_stack.valid_for_read then
        local place_result = item_stack.prototype.place_result
        if place_result and (place_result.type == "container" or place_result.type == "logistic-container") then
            if table.deep_compare(place_result.collision_box, game.entity_prototypes[conf.chest_name].collision_box) then
                set_config(player, {chest_name = place_result.name})
                player.print({"outpost-builder.use-chest", {"entity-name." .. place_result.name}})
            else
                player.print(
                    {
                        "outpost-builder.bad-fast-replace",
                        {"entity-name." .. place_result.name},
                        {"entity-name." .. conf.blueprint_data.chest_name}
                    }
                )
            end
        else
            player.print({"outpost-builder.unknown-item"})
        end
    else
        player.print({"outpost-builder.change-chest"})
    end
end

local function pole_button_click(event)
    local player = game.players[event.element.player_index]
    local conf = get_config(player)
    local item_stack = player.cursor_stack
    if item_stack and item_stack.valid and item_stack.valid_for_read then
        local place_result = item_stack.prototype.place_result
        if place_result and place_result.type == "electric-pole" then
            if
                not conf.blueprint_data.pole_name or
                    table.deep_compare(
                        place_result.collision_box,
                        game.entity_prototypes[conf.blueprint_data.pole_name].collision_box
                    )
             then
                set_config(player, {pole_name = place_result.name})
                player.print({"outpost-builder.use-pole", {"entity-name." .. place_result.name}})
            else
                player.print(
                    {
                        "outpost-builder.bad-fast-replace",
                        {"entity-name." .. place_result.name},
                        {"entity-name." .. conf.blueprint_data.pole_name}
                    }
                )
            end
        else
            player.print({"outpost-builder.unknown-item"})
        end
    else
        player.print({"outpost-builder.change-pole"})
    end
end

local function direction_button_click(event)
    local player = game.players[event.element.player_index]
    local conf = get_config(player)
    local new_direction = (conf.direction + 2) % 8
    set_config(player, {direction = new_direction})
end

local function count_button_click(event)
    local player = game.players[event.element.player_index]
    local conf = get_config(player)
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
end

local function find_leaving_belts(entities, width)
    local list = {}
    for k, entity in pairs(entities) do
        if game.entity_prototypes[entity.name].type == "transport-belt" then
            if entity.direction == defines.direction.east and entity.position.x > width - 1 then
                table.insert(list, entity)
            end
        end
    end
    return list
end

local function find_leaving_underground_belts(entities)
    local list = {}
    for k, entity in pairs(entities) do
        if
            game.entity_prototypes[entity.name].type == "underground-belt" and
                game.entity_prototypes[underground_to_belt(entity.name)]
         then
            if
                entity.direction == defines.direction.east and entity.type == "input" and
                    not table.find(
                        list,
                        function(e)
                            return e.y == entity.y
                        end
                    )
             then
                table.insert(list, entity)
            end
        end
    end
    return list
end

local function parse_blueprint(entities, conf)
    local blueprint_data = {
        miners = {},
        poles = {},
        chests = {},
        belts = {},
        underground_belts = {},
        splitters = {},
        leaving_belts = {},
        leaving_underground_belts = {},
        other_entities = {},
        total_entities = #entities
    }

    blueprint_data.poles = util.strip_entities_of_type(entities, "electric-pole")

    local bounding_box = util.find_blueprint_bounding_box(entities)
    local shift_x = math.ceil((-bounding_box.left_top.x) - 0.5) + 0.5
    local shift_y = math.ceil((-bounding_box.left_top.y) - 0.5) + 0.5
    util.shift_blueprint(entities, shift_x, shift_y)
    util.shift_blueprint(blueprint_data.poles, shift_x, shift_y)

    local width = math.ceil(bounding_box.right_bottom.x + shift_x)
    local height = math.ceil(bounding_box.right_bottom.y + shift_y)

    blueprint_data.width = width
    blueprint_data.height = height

    util.strip_entities_of_name(entities, conf.dummy_spacing_entitiy)

    local belts = util.strip_entities_of_type(entities, "transport-belt")
    local underground_belts = util.strip_entities_of_type(entities, "underground-belt")
    blueprint_data.leaving_belts = table.deep_clone(find_leaving_belts(belts, width))
    blueprint_data.leaving_underground_belts = table.deep_clone(find_leaving_underground_belts(underground_belts))
    blueprint_data.belts = belts
    blueprint_data.underground_belts = underground_belts
    blueprint_data.splitters = util.strip_entities_of_type(entities, "splitter")
    blueprint_data.chests =
        table.append_modify(
        util.strip_entities_of_type(entities, "container"),
        util.strip_entities_of_type(entities, "logistic-container")
    )

    blueprint_data.miners = util.strip_entities_of_type(entities, "mining-drill")

    blueprint_data.other_entities = entities

    return blueprint_data
end

function validate_blueprint(blueprint_data)
    if #blueprint_data.miners < 1 then
        return {"outpost-builder.validate-one-miner"}
    end
    local name = blueprint_data.miners[1].name
    blueprint_data.miner_name = name
    local prototype = game.entity_prototypes[name]
    if not prototype or not prototype.type == "mining-drill" or not prototype.resource_categories["basic-solid"] then
        return {"outpost-builder.miners-invalid"}
    end
    blueprint_data.supports_fluid = true
    local multiple_miner_types = false
    for k, miner in pairs(blueprint_data.miners) do
        if miner.direction ~= defines.direction.north and miner.direction ~= defines.direction.south then
            blueprint_data.supports_fluid = false
        end
        if miner.name ~= name then
            multiple_miner_types = true
        end
    end
    if multiple_miner_types then
        return {"outpost-builder.validate-multiple-miners"}
    end

    if #blueprint_data.poles > 0 then
        local name = blueprint_data.poles[1].name
        blueprint_data.pole_name = name
        local prototype = game.entity_prototypes[name]
        if not prototype or not prototype.type == "electric-pole" then
            return {"outpost-builder.electric-pole-invalid"}
        end
        if
            not table.all(
                blueprint_data.poles,
                function(pole)
                    return pole.name == name
                end
            )
         then
            return {"outpost-builder.validate-multiple-poles"}
        end
    end

    if #blueprint_data.chests > 0 then
        local name = blueprint_data.chests[1].name
        blueprint_data.chest_name = name
        local prototype = game.entity_prototypes[name]
        if not prototype or (prototype.type ~= "container" and prototype.type ~= "logistic-container") then
            return {"outpost-builder.container-invalid"}
        end
        if
            not table.all(
                blueprint_data.chests,
                function(chest)
                    return chest.name == name
                end
            )
         then
            return {"outpost-builder.validate-multiple-chests"}
        end
    end

    blueprint_data.other_electric_entities = false
    for k, v in pairs(blueprint_data.other_entities) do
        if not game.entity_prototypes[v.name] then
            return {"outpost-builder.validate-bad-entity"}
        end
        if game.entity_prototypes[v.name].electric_energy_source_prototype then
            blueprint_data.other_electric_entities = true
        end
    end

    for i, arr in ipairs({blueprint_data.belts, blueprint_data.underground_belts, blueprint_data.splitters}) do
        for k, v in pairs(arr) do
            local err = util.check_belt_entity(v.name)
            if err then
                return err
            end
        end
    end

    return false
end

local function blueprint_button_click(event)
    local player = game.players[event.element.player_index]
    local conf = get_config(player)
    local item_stack = player.cursor_stack
    if
        item_stack and item_stack.valid and item_stack.valid_for_read and item_stack.name == "blueprint" and
            item_stack.is_blueprint_setup()
     then
        -- Check whether it's compatible with current settings
        local entities = item_stack.get_blueprint_entities()
        local raw_entities = table.deep_clone(entities)
        local blueprint_data = parse_blueprint(entities, conf)

        local err = validate_blueprint(blueprint_data)
        if err then
            player.print({"outpost-builder.blueprint-invalid", err})
            return
        end

        if not event.shift then
            set_config(
                player,
                {
                    pole_name = blueprint_data.pole_name,
                    chest_name = blueprint_data.chest_name,
                    miner_name = blueprint_data.miner_name
                }
            )
        else
            for k, v in pairs({"pole_name", "chest_name", "miner_name"}) do
                if blueprint_data[v] then
                    local blueprint_prototype = game.entity_prototypes[blueprint_data[v]]
                    local conf_prototype = game.entity_prototypes[conf[v]]
                    if
                        not table.deep_compare(blueprint_prototype.collision_box, conf_prototype.collision_box) or
                            (conf_prototype.module_inventory_size and
                                ((not blueprint_prototype.module_inventory_size) or
                                    blueprint_prototype.module_inventory_size < conf_prototype.module_inventory_size))
                     then
                        player.print(
                            {
                                "outpost-builder.blueprint-settings-mismatch",
                                {"entity-name." .. blueprint_data[v]},
                                {"entity-name." .. conf[v]}
                            }
                        )
                        return
                    end
                end
            end
        end

        --game.write_file("blue_out.lua", serpent.block(blueprint_data))
        --game.write_file("blue_out_raw.lua", serpent.block(raw_entities))

        set_config(
            player,
            {
                blueprint_data = blueprint_data,
                blueprint_raw = raw_entities,
                smart_belt_placement = #blueprint_data.leaving_underground_belts == 0,
                enable_pipe_placement = blueprint_data.supports_fluid,
                enable_belt_collate = #blueprint_data.leaving_belts > 0 or #blueprint_data.leaving_underground_belts > 0
            }
        )
        refresh_other_entities_list(player)
        player.print({"outpost-builder.blueprint-read-success"})
    else
        player.print {"outpost-builder.no-blueprint"}
    end
end

local function pole_options_click(event)
    local player = game.players[event.element.player_index]
    set_config(player, {pole_options_selected = string.sub(event.element.name, 27)})
end

local function on_checkbox_click(event, config_key, enabled_function, disabled_message)
    local player = game.players[event.element.player_index]
    local conf = get_config(player)
    if enabled_function and not enabled_function(conf) then
        player.print(disabled_message)
    else
        set_config(player, {[config_key] = event.element.state})
    end
end

local function on_dummy_entity_click(event, config_key)
    local player = game.players[event.element.player_index]
    local conf = get_config(player)
    local item_stack = player.cursor_stack
    if item_stack and item_stack.valid and item_stack.valid_for_read then
        local place_result = item_stack.prototype.place_result
        if place_result and place_result.collision_box then
            local box = place_result.collision_box
            if
                math.ceil(box.right_bottom.x - box.left_top.x) == 1 and
                    math.ceil(box.right_bottom.y - box.left_top.y) == 1
             then
                set_config(player, {[config_key] = place_result.name})
                player.print({"outpost-builder.change-dummy-" .. config_key, {"entity-name." .. place_result.name}})
                return
            end
        end
    end
    player.print({"outpost-builder.change-dummy"})
end

local function write_blueprint_to_player(player, entities)
    local item_stack = player.cursor_stack
    if item_stack and item_stack.valid then
        if not item_stack.valid_for_read then
            item_stack.set_stack({name = "blueprint"})
        end
        if item_stack.type == "blueprint" and not item_stack.is_blueprint_setup() then
            item_stack.set_blueprint_entities(entities)
        else
            player.print({"outpost-builder.need-empty-blueprint"})
        end
    end
end

local function example_blueprint_read(event, key)
    local player = game.players[event.element.player_index]
    write_blueprint_to_player(player, example_blueprints.raw[key])
end

local function blueprint_write_click(event)
    local player = game.players[event.element.player_index]
    local conf = get_config(player)
    write_blueprint_to_player(player, conf.blueprint_raw)
end

local function other_entities_miner_checkbox(event, entity_name)
    global.OB_CONF_overrides[event.element.player_index].other_entity_settings[entity_name].with_miners =
        event.element.state
end

script.on_event(
    defines.events.on_gui_selection_state_changed,
    function(event)
        if string.sub(event.element.name, 1, 23) == "OutpostBuilderDropDown-" then
            local entity_name = string.sub(event.element.name, 24)
            global.OB_CONF_overrides[event.element.player_index].other_entity_settings[entity_name].every_x =
                event.element.selected_index
        end
    end
)

script.on_event(
    defines.events.on_gui_checked_state_changed,
    function(event)
        if not string.sub(event.element.name, 1, 14) == "OutpostBuilder" then
            return
        end
        if event.element.name == "OutpostBuilderFluidCheckbox" then
            on_checkbox_click(
                event,
                "enable_pipe_placement",
                function(conf)
                    return conf.blueprint_data.supports_fluid
                end,
                {"outpost-builder.fluid-not-supported"}
            )
        elseif event.element.name == "OutpostBuilderBeltCheckbox" then
            on_checkbox_click(
                event,
                "enable_belt_collate",
                function(conf)
                    return #conf.blueprint_data.leaving_belts > 0 or #conf.blueprint_data.leaving_underground_belts > 0
                end,
                {"outpost-builder.no-leaving-belts"}
            )
        elseif event.element.name == "OutpostBuilderSmartBeltCheckbox" then
            on_checkbox_click(
                event,
                "smart_belt_placement",
                function(conf)
                    return #conf.blueprint_data.leaving_underground_belts == 0
                end,
                {"outpost-builder.no-smart-belt"}
            )
        elseif string.sub(event.element.name, 1, 30) == "OutpostBuilderOtherWithMiners-" then
            other_entities_miner_checkbox(event, string.sub(event.element.name, 31))
        elseif string.sub(event.element.name, 1, 26) == "OutpostBuilderPoleOptions#" then
            pole_options_click(event)
        else
            l.warn("GUI checkbox change element name '" .. event.element.name .. "' not recognised.")
            return
        end
        update_gui(game.players[event.player_index])
    end
)

script.on_event(
    defines.events.on_gui_click,
    function(event)
        if not string.sub(event.element.name, 1, 14) == "OutpostBuilder" then
            return
        end
        if event.element.name == "OutpostBuilder" then
            toggle_settings_window(event)
        elseif event.element.name == "OutpostBuilderBeltButton" then
            belt_button_click(event)
        elseif event.element.name == "OutpostBuilderDirectionButton" then
            direction_button_click(event)
        elseif event.element.name == "OutpostBuilderOutputRowsButton" then
            count_button_click(event)
        elseif event.element.name == "OutpostBuilderPoleButton" then
            pole_button_click(event)
        elseif event.element.name == "OutpostBuilderPipeButton" then
            pipe_button_click(event)
        elseif event.element.name == "OutpostBuilderMinerButton" then
            miner_button_click(event)
        elseif event.element.name == "OutpostBuilderChestButton" then
            chest_button_click(event)
        elseif event.element.name == "OutpostBuilderBlueprintReadButton" then
            blueprint_button_click(event)
        elseif event.element.name == "OutpostBuilderToggleAdvancedButton" then
            toggle_advanced_window(event)
        elseif event.element.name == "OutpostBuilderDummySpaceButton" then
            on_dummy_entity_click(event, "dummy_spacing_entitiy")
        elseif event.element.name == "OutpostBuilderBlueprintWriteButton" then
            blueprint_write_click(event)
        elseif string.sub(event.element.name, 1, 31) == "OutpostBuilderBlueprintExample-" then
            example_blueprint_read(event, string.sub(event.element.name, 32))
        elseif string.sub(event.element.name, 1, 25) == "OutpostBuilderBeltSprite-" then
            belt_sprite_click(event, string.sub(event.element.name, 26))
        else
            l.debug("GUI click element name '" .. event.element.name .. "' not recognised.")
            return
        end
        update_gui(game.players[event.player_index])
    end
)

script.on_event(
    defines.events.on_player_joined_game,
    function(event)
        init_gui_player(game.players[event.player_index])
    end
)

table.insert(ON_INIT, init_gui)
