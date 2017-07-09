require("config")
require("gui")
require("planner-core")

-- Note this mod uses its original name (OutpostBuilder) internally.

function on_selected_area(event, deconstruct_friendly)
    local player = game.players[event.player_index]
    local surface = player.surface
    local force = player.force
    local conf = get_config(player)
    local stages = {"find_ore", "check_fluid", "bounding_box", "set_up_placement_stages"}
    
    if not conf.used_before then
        player.print({"outpost-builder.on-first-use", {"outpost-builder.initials"}})
        set_config(player, {used_before = true})
    end
    
    local state = {
        stage = 0,
        count = 0,
        event_entities = event.entities,
        player = player,
        force = force,
        surface = surface,
        row_details = {},
        output_rows = {},
        conf = conf,
        stages = stages,
        stage_namespace = "OB_stage",
        deconstruct_friendly = deconstruct_friendly,
        total_miners = 0
    }
    
    if conf.run_over_multiple_ticks then
        remote.call("PlannerCore", "register", state)
    else
        remote.call("PlannerCore", "run_immediately", state)
    end
end

script.on_event(
    defines.events.on_player_selected_area,
    function(event)
        if event.item == "outpost-builder" then
            on_selected_area(event)
        end
    end
)

script.on_event(
    defines.events.on_player_alt_selected_area,
    function(event)
        if event.item == "outpost-builder" then
            on_selected_area(event, true)
        end
    end
)
