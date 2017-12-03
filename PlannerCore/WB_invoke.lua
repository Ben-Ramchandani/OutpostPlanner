function PC_WB_invoke(entities, player, conf)
    local force = player.force
    local surface = player.surface

    local state = {
        surface = surface,
        player = player,
        force = force,
        top = math.huge,
        bottom = -math.huge,
        left = math.huge,
        right = -math.huge,
        entities = entities,
        stages = {"bounding_box", "NS_rail_positions", "EW_rail_positions", "plan", "place_entity"},
        stage_namespace = "WB_stage",
        stage = 0,
        count = 0,
        entity_count = 0,
        conf = conf,
        NS_rails = {},
        EW_rails = {},
        top_rails = {},
        bottom_rails = {},
        left_rails = {},
        right_rails = {},
        top_section_list = {},
        bottom_section_list = {},
        left_section_list = {},
        right_section_list = {},
        placed_entities = {},
        pole_positions = {},
        current_placement_direction = 1,
        current_section_index = 1,
        current_entity_index = 1
    }

    if conf.run_over_multiple_ticks then
        remote.call("PlannerCore", "register", state)
    else
        remote.call("PlannerCore", "run_immediately", state)
    end
end

PlannerCore.remote_invoke.WallBuilder = PC_WB_invoke
