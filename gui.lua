require("mod-gui")
require("util")
require("on_init")

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
    frame.style.visible = false
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
    -- frame.add(
    --     {
    --         type = "sprite-button",
    --         name = "OutpostBuilderMinerButton",
    --         sprite = ("entity/" .. conf.miner_name),
    --         style = mod_gui.button_style
    --     }
    -- )
    frame.add(
        {
            type = "sprite-button",
            name = "OutpostBuilderPoleButton",
            sprite = ("entity/" .. conf.pole_name),
            style = mod_gui.button_style
        }
    )
    frame.add(
        {
            type = "sprite-button",
            name = "OutpostBuilderPipeButton",
            sprite = ("entity/" .. conf.pipe_name),
            style = mod_gui.button_style
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
    frame.style.visible = false

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

    frame.add(
        {
            type = "label",
            name = "OutpostBuilderBlueprintExamplesLabel",
            caption = {"outpost-builder.example-blueprints-label"}
        }
    )
    local blueprint_examples_flow =
        frame.add({type = "flow", name = "OutpostBuilderBlueprintExamplesFlow", direction = "horizontal"})

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
    dummy_entities_flow.add(
        {
            type = "sprite-button",
            name = "OutpostBuilderDummyPipeButton",
            sprite = "entity/" .. conf.dummy_pipe,
            style = mod_gui.button_style,
            tooltip = {"outpost-builder.dummy-pipe-tooltip"}
        }
    )
    -- dummy_entities_flow.add(
    --     {
    --         type = "sprite-button",
    --         name = "OutpostBuilderDummyPoleButton",
    --         sprite = "entity/" .. conf.dummy_pole,
    --         style = mod_gui.button_style,
    --         tooltip = {"outpost-builder.dummy-pole-tooltip"}
    --     }
    -- )

    frame.add(
        {type = "label", name = "OutpostBuilderPoleOptionsLabel", caption = {"outpost-builder.pole-options-label"}}
    )
    local pole_options_flow = frame.add({type = "flow", name = "OutpostBuilderPoleOptions", direction = "vertical"})
    add_radio(pole_options_flow, {"simple", "intelligent", "automatic"}, "outpost-builder.pole-options-")

    frame.add(
        {
            type = "label",
            name = "OutpostBuilderBlueprintDeatilsLabel",
            caption = {"outpost-builder.blueprint-details-label"}
        }
    )
    frame.add(
        {
            type = "label",
            name = "OutpostBuilderBlueprintDeatilsFluid",
            caption = {"outpost-builder.blueprint-details-fluids-true"}
        }
    )
    frame.add(
        {
            type = "label",
            name = "OutpostBuilderBlueprintDeatilsBelt",
            caption = {"outpost-builder.blueprint-details-belt-true"}
        }
    )
    frame.add(
        {
            type = "label",
            name = "OutpostBuilderBlueprintDeatilsChest",
            caption = {"outpost-builder.blueprint-details-chest-true"}
        }
    )

    frame.add(
        {type = "label", name = "OutpostBuilderOtherLabel", caption = {"outpost-builder.blueprint-other-options-label"}}
    )
    frame.add(
        {
            type = "checkbox",
            name = "OutpostBuilderOverrideEntities",
            caption = {"outpost-builder.blueprint-other-override"},
            state = false
        }
    )
    --TODO simple_belt_placement
    -- frame.add(
    --     {
    --         type = "checkbox",
    --         name = "OutpostBuilderMirrorPoles",
    --         caption = {"outpost-builder.blueprint-mirror-poles"},
    --         state = true
    --     }
    -- )
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

function update_advanced_window(conf, player)
    local frame_flow = mod_gui.get_frame_flow(player)
    local frame = frame_flow.OutpostBuilderAdvancedWindow
    update_basic_settings(frame.OutpostBuilderBasicSettingsFlow, conf, player)

    frame.OutpostBuilderDummyEntitiesFlow.OutpostBuilderDummyPipeButton.sprite = "entity/" .. conf.dummy_pipe
    frame.OutpostBuilderDummyEntitiesFlow.OutpostBuilderDummySpaceButton.sprite =
        "entity/" .. conf.dummy_spacing_entitiy
    -- frame.OutpostBuilderDummyEntitiesFlow.OutpostBuilderDummyPoleButton.sprite = "entity/" .. conf.dummy_pole

    update_radio(frame.OutpostBuilderPoleOptions, conf.pole_options_selected)

    if conf.leaving_belts then
        frame.OutpostBuilderBlueprintDeatilsBelt.caption = {"outpost-builder.blueprint-details-belt-true"}
    else
        frame.OutpostBuilderBlueprintDeatilsBelt.caption = {"outpost-builder.blueprint-details-belt-false"}
    end

    if conf.blueprint_pipe_positions then
        frame.OutpostBuilderBlueprintDeatilsFluid.caption = {"outpost-builder.blueprint-details-fluids-true"}
    else
        frame.OutpostBuilderBlueprintDeatilsFluid.caption = {"outpost-builder.blueprint-details-fluids-false"}
    end

    if conf.use_chest then
        frame.OutpostBuilderBlueprintDeatilsChest.caption = {"outpost-builder.blueprint-details-chest-true"}
    else
        frame.OutpostBuilderBlueprintDeatilsChest.caption = {"outpost-builder.blueprint-details-chest-false"}
    end

    frame.OutpostBuilderOverrideEntities.state = conf.override_entity_settings
    --frame.OutpostBuilderMirrorPoles.state = conf.mirror_poles_at_bottom
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

    -- if frame.OutpostBuilderMinerButton then
    --     frame.OutpostBuilderMinerButton.sprite = "entity/" .. conf.miner_name
    --     frame.OutpostBuilderMinerButton.tooltip = {"entity-name." .. conf.miner_name}
    -- end

    if frame.OutpostBuilderPoleButton then
        frame.OutpostBuilderPoleButton.sprite = "entity/" .. conf.pole_name
        frame.OutpostBuilderPoleButton.tooltip = {"entity-name." .. conf.pole_name}
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
    if frame_flow.OutpostBuilderWindow.style.visible or frame_flow.OutpostBuilderAdvancedWindow.style.visible then
        frame_flow.OutpostBuilderWindow.style.visible = false
        frame_flow.OutpostBuilderAdvancedWindow.style.visible = false
    else
        frame_flow.OutpostBuilderWindow.style.visible = not conf.advanced_window_open
        frame_flow.OutpostBuilderAdvancedWindow.style.visible = conf.advanced_window_open
    end
end

local function toggle_advanced_window(event)
    local player = game.players[event.element.player_index]
    local frame_flow = mod_gui.get_frame_flow(player)
    frame_flow.OutpostBuilderWindow.style.visible = frame_flow.OutpostBuilderAdvancedWindow.style.visible
    frame_flow.OutpostBuilderAdvancedWindow.style.visible = not frame_flow.OutpostBuilderAdvancedWindow.style.visible
    set_config(player, {advanced_window_open = frame_flow.OutpostBuilderAdvancedWindow.style.visible})
end

local function belt_button_click(event)
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
        elseif place_result and (place_result.type == "container" or place_result.type == "logistic-container") then
            set_config(player, {use_chest = place_result.name})
            player.print({"outpost-builder.using-chest", {"entity-name." .. place_result.name}})
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

-- local function miner_button_click(event)
--     local player = game.players[event.element.player_index]
--     local conf = get_config(player)
--     local item_stack = player.cursor_stack
--     if item_stack and item_stack.valid and item_stack.valid_for_read then
--         local place_result = item_stack.prototype.place_result
--         if place_result and place_result.type == "mining-drill" and place_result.resource_categories["basic-solid"] then
--             set_config(player, {miner_name = place_result.name})
--             player.print({"outpost-builder.use-miner", {"entity-name." .. place_result.name}})
--         else
--             player.print({"outpost-builder.unknown-item"})
--         end
--     else
--         player.print({"outpost-builder.change-miner"})
--     end
-- end

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

local function pole_button_click(event)
    local player = game.players[event.element.player_index]
    local conf = get_config(player)
    local item_stack = player.cursor_stack
    if item_stack and item_stack.valid and item_stack.valid_for_read then
        local place_result = item_stack.prototype.place_result
        if place_result and place_result.type == "electric-pole" then
            set_config(player, {pole_name = place_result.name})
            player.print({"outpost-builder.use-pole", {"entity-name." .. place_result.name}})
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

local function strip_entities_of_type(list, type)
    return table.filter_remove(
        list,
        function(entity)
            return game.entity_prototypes[entity.name].type == type
        end
    )
end

local function strip_entities_of_name(list, name)
    return table.filter_remove(
        list,
        function(entity)
            return entity.name == name
        end
    )
end

local function shift_blueprint(entities, shift_x, shift_y)
    table.apply(
        entities,
        function(entity)
            entity.direction = entity.direction or 0
            entity.position.x = entity.position.x + shift_x
            entity.position.y = entity.position.y + shift_y
        end
    )
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

--TODO no longer needed
-- local function mirror_poles(entities, height)
--     local poles = {}

--     for k, pole in pairs(entities) do
--         local box = game.entity_prototypes[pole.name].collision_box
--         local offset = -math.ceil(box.right_bottom.y - box.left_top.y) / 2
--         if pole.position.y == offset then
--             local copy = table.deep_clone(pole)
--             copy.position.y = height + offset
--             table.insert(poles, copy)
--         end
--     end

--     return poles
-- end

local function parse_blueprint(entities, conf)
    local blueprint_data = {
        miners = {},
        poles = {},
        belts = {},
        underground_belts = {},
        splitters = {},
        pipes = {},
        fluid_dummies = {},
        leaving_belts = {},
        leaving_underground_belts = {},
        other_entities = {},
        total_entities = #entities
    }

    blueprint_data.fluid_dummies = strip_entities_of_name(entities, conf.dummy_pipe)
    blueprint_data.poles = strip_entities_of_type(entities, "electric-pole")

    local bounding_box = find_blueprint_bounding_box(entities)
    local shift_x = math.ceil((-bounding_box.left_top.x) - 0.5) + 0.5
    local shift_y = math.ceil((-bounding_box.left_top.y) - 0.5) + 0.5
    shift_blueprint(entities, shift_x, shift_y)
    shift_blueprint(blueprint_data.fluid_dummies, shift_x, shift_y)
    shift_blueprint(blueprint_data.poles, shift_x, shift_y)

    local width = math.ceil(bounding_box.right_bottom.x + shift_x)
    local height = math.ceil(bounding_box.right_bottom.y + shift_y)

    blueprint_data.width = width
    blueprint_data.height = height

    strip_entities_of_name(entities, conf.dummy_spacing_entitiy)

    local belts = strip_entities_of_type(entities, "transport-belt")
    local underground_belts = strip_entities_of_type(entities, "underground-belt")
    blueprint_data.leaving_belts = table.deep_clone(find_leaving_belts(belts, width))
    blueprint_data.leaving_underground_belts = table.deep_clone(find_leaving_underground_belts(underground_belts))
    blueprint_data.belts = belts
    blueprint_data.underground_belts = underground_belts
    blueprint_data.splitters = strip_entities_of_type(entities, "splitter")

    blueprint_data.miners = strip_entities_of_type(entities, "mining-drill")

    blueprint_data.pipes = strip_entities_of_type(entities, "pipe")

    blueprint_data.other_entities = entities

    return blueprint_data
end

function check_belt_entity(name)
    local prototype = game.entity_prototypes[name]
    if not prototype then
        return "Belt entity does not exist"
    else
        local belt_name
        if prototype.type == "transport-belt" then
            belt_name = name
        elseif prototype.type == "underground-belt" then
            belt_name = underground_to_belt(name)
        elseif prototype.type == "splitter" then
            belt_name = splitter_to_belt(name)
        end

        for k, v in ipairs(
            {
                {belt_name, "transport-belt"},
                {belt_to_underground(belt_name), "underground-belt"},
                {belt_to_splitter(belt_name), "splitter"}
            }
        ) do
            if not game.entity_prototypes[v[1]] or game.entity_prototypes[v[1]].type ~= v[2] then
                return {"outpost-builder.bad-belt", name}
            end
        end
    end
    return false
end

local function validate_blueprint(blueprint_data)
    if #blueprint_data.miners < 1 then
        return "Blueprint must contain at least one miner"
    end
    local name = blueprint_data.miners[1].name
    blueprint_data.miner_name = name
    local prototype = game.entity_prototypes[name]
    if not prototype or not prototype.type == "mining-drill" or not prototype.resource_categories["basic-solid"] then
        return "Miners invalid"
    end
    if
        not table.all(
            blueprint_data.miners,
            function(miner)
                return miner.name == name
            end
        )
     then
        return "Cannot have multiple types of miner per blueprint"
    end

    if #blueprint_data.poles > 0 then
        local name = blueprint_data.poles[1].name
        blueprint_data.pole_name = name
        local prototype = game.entity_prototypes[name]
        if not prototype or not prototype.type == "electric-pole" then
            return "Electric pole invalid"
        end
        if
            not table.all(
                blueprint_data.poles,
                function(pole)
                    return pole.name == name
                end
            )
         then
            return "Cannot have multiple types of electric pole per blueprint"
        end
    end

    if #blueprint_data.pipes > 0 then
        local name = blueprint_data.pipes[1].name
        blueprint_data.pipe_name = name
        local prototype = game.entity_prototypes[name]
        if not prototype or not prototype.type == "pipe" then
            return "Pipe invalid"
        end
        if
            not table.all(
                blueprint_data.pipes,
                function(pipe)
                    return pipe.name == name
                end
            )
         then
            return "Cannot have multiple types of pipe per blueprint"
        end
    end

    for k, v in pairs(blueprint_data.other_entities) do
        if not game.entity_prototypes[v.name] then
            return "An entity in the blueprint does not exist"
        end
    end

    for i, arr in ipairs({blueprint_data.belts, blueprint_data.underground_belts, blueprint_data.splitters}) do
        for k, v in pairs(arr) do
            local err = check_belt_entity(v.name)
            if err then
                return err
            end
        end
    end

    blueprint_data.fluid_dummies_left = {}
    blueprint_data.fluid_dummies_right = {}
    while #blueprint_data.fluid_dummies > 0 do
        local dummy = blueprint_data.fluid_dummies[1]
        local pair =
            table.filter_remove(
            blueprint_data.fluid_dummies,
            function(entity)
                return entity.position.y == dummy.position.y
            end
        )
        if #pair ~= 2 then
            return "Each fluid input/output dummy entity must have a pair on its row"
        end
        table.sort(
            pair,
            function(a, b)
                return a.position.x < b.position.x
            end
        )
        table.insert(blueprint_data.fluid_dummies_left, pair[1])
        table.insert(blueprint_data.fluid_dummies_right, pair[2])
    end
    blueprint_data.fluid_dummies = nil

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

        if event.shift then
            set_config(
                {
                    miner_name = blueprint_data.miner_name,
                    pole_name = blueprint_data.pole_name,
                    pipe_name = blueprint_data.pipe_name
                }
            )
        else
            for k, v in pairs({"miner_name", "pole_name", "pipe_name"}) do
                if
                    blueprint_data[v] and
                        not game.entity_prototypes[blueprint_data[v]].fast_replaceable_group ==
                            game.entity_prototypes[conf[v]].fast_replaceable_group
                 then
                    player.print(
                        {
                            "blueprint-settings-mismatch",
                            {"entity-name." .. blueprint_data[v]},
                            {"entity-name." .. conf[v]}
                        }
                    )
                    return
                end
            end
        end

        game.write_file("blue_out.lua", serpent.block(blueprint_data))
        game.write_file("blue_out_raw.lua", serpent.block(raw_entities))

        set_config(player, {blueprint_data = blueprint_data, blueprint_raw = raw_entities})
        player.print({"outpost-builder.blueprint-read-success"})
    else
        player.print {"outpost-builder.no-blueprint"}
        set_config(
            player,
            {blueprint_entities = false, blueprint_width = false, blueprint_height = false, leaving_belt = false}
        )
    end
end

local function pole_options_click(event)
    local player = game.players[event.element.player_index]
    set_config(player, {pole_options_selected = string.sub(event.element.name, 27)})
end

local function on_checkbox_click(event, config_key)
    local player = game.players[event.element.player_index]
    local checkbox = mod_gui.get_frame_flow(player).OutpostBuilderAdvancedWindow[event.element.name]
    set_config(player, {[config_key] = checkbox.state})
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
                return
            end
        end
    end
    player.print({"outpost-builder.change-dummy"})
end

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
            -- elseif event.element.name == "OutpostBuilderMinerButton" then
            --     miner_button_click(event)
            count_button_click(event)
        elseif event.element.name == "OutpostBuilderPoleButton" then
            pole_button_click(event)
        elseif event.element.name == "OutpostBuilderPipeButton" then
            pipe_button_click(event)
        elseif event.element.name == "OutpostBuilderBlueprintReadButton" then
            blueprint_button_click(event)
        elseif event.element.name == "OutpostBuilderToggleAdvancedButton" then
            toggle_advanced_window(event)
        elseif string.sub(event.element.name, 1, 26) == "OutpostBuilderPoleOptions#" then
            pole_options_click(event)
        elseif event.element.name == "OutpostBuilderOverrideEntities" then
            -- elseif event.element.name == "OutpostBuilderMirrorPoles" then
            --     on_checkbox_click(event, "mirror_poles_at_bottom")
            on_checkbox_click(event, "override_entity_settings")
        elseif event.element.name == "OutpostBuilderDummySpaceButton" then
            on_dummy_entity_click(event, "dummy_spacing_entitiy")
        elseif event.element.name == "OutpostBuilderDummyPipeButton" then
            on_dummy_entity_click(event, "dummy_pipe")
        -- elseif event.element.name == "OutpostBuilderDummyPoleButton" then
        --     on_dummy_entity_click(event, "dummy_pole")
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
