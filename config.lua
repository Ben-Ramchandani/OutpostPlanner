OB_CONF = {
    -- Can be changed with the in game GUI
    miner_name = "electric-mining-drill",
    electric_pole = "small-electric-pole",
    transport_belts = {"transport-belt"},
    pipe_name = "pipe",
    direction = defines.direction.east,
    output_belt_count = 4, -- The number of belts of ore leaving the set-up.
    -- Can only be changed here (if in multiplayer make sure you all have the same config or you will desync).
    place_directly = false, -- Place entities directly or use blueprints?
    drain_inventory = true, -- When placing directly, should items be removed from the player's inventory?
    place_blueprint_on_out_of_inventory = true, -- If the player does not have that item place a blueprint instead?
    place_blueprint_on_collision = true, -- When placing directly, place a blueprint if there would otherwise be a collision.
    check_for_ore = true, -- For each miner, check there is some of the correct ore underneath it.
    check_dirty_mining = true, -- For each miner, check if any other ores are present in its mining area.
    check_collision = true,
    run_over_multiple_ticks = true -- Place instantly or one at a time?
}

function get_config(player)
    local conf = table.combine(table.clone(OB_CONF), global.OB_CONF_overrides[player.index])
    conf.transport_belts = table.clone(conf.transport_belts)
    local pole_prototype = game.entity_prototypes[conf.electric_pole]
    conf.pole_width = math.ceil(math.max(pole_prototype.collision_box.right_bottom.x - pole_prototype.collision_box.left_top.y, pole_prototype.collision_box.right_bottom.x - pole_prototype.collision_box.left_top.y))
    local miner_prototype = game.entity_prototypes[conf.miner_name]
    conf.miner_width = math.ceil(math.max(miner_prototype.collision_box.right_bottom.x - miner_prototype.collision_box.left_top.y, miner_prototype.collision_box.right_bottom.x - miner_prototype.collision_box.left_top.y))
    conf.miner_area = miner_prototype.mining_drill_radius * 2
    return conf
end

function set_config(player, new_conf) -- Override the configuration file on a per save basis.
    if new_conf and type(new_conf) == "table" then
        global.OB_CONF_overrides[player.index] = table.combine(global.OB_CONF_overrides[player.index], new_conf)
    end
end

function reset_all()
    global.OB_CONF_overrides = {}
    global.AM_states = {}
end

function set_config_global(new_conf)
    if new_conf and type(new_conf) == "table" then
        for k, player in pairs(game.players) do
            global.OB_CONF_overrides[player.index] = table.combine(global.OB_CONF_overrides[player.index], new_conf)
        end
    end
end

remote.add_interface("OutpostBuilder", {reset = reset_all, config = set_config_global})

function validate_config(partialConf, player)
    if partialConf.miner_name then
        if not game.entity_prototypes[partialConf.miner_name] or (not game.entity_prototypes[partialConf.miner_name].type == "mining-drill") then
            return false
        end
    end
    if partialConf.electric_pole then
        if not game.entity_prototypes[partialConf.electric_pole] or (not game.entity_prototypes[partialConf.electric_pole].type == "electric-pole") then
            return false
        end
    end
    if partialConf.transport_belts then
        for k, belt in pairs(partialConf.transport_belts) do
            if not game.entity_prototypes[belt] or (not game.entity_prototypes[belt].type == "transport_belt") or not game.entity_prototypes[belt_to_splitter(belt)] or not (game.entity_prototypes[belt_to_splitter(belt)].type == "splitter") then
                return false
            end
        end
    end
    if partialConf.pipe_name then
        local underground_pipe = pipe_to_underground(partialConf.pipe_name)
        if not game.entity_prototypes[partialConf.pipe_name] or (not game.entity_prototypes[partialConf.pipe_name].type == "pipe") or not game.entity_prototypes[underground_pipe] or not (game.entity_prototypes[underground_pipe].type == "pipe-to-ground") then
            return false
        end
    end
    return true
end

function init_config()
    if global.OB_CONF_overrides then
        -- Check that all the entities in custom config still exist (a mod may have been removed).
        -- The entities in OB_CONF are assumed to exist (base is a dependency).
        for k, v in pairs(global.OB_CONF_overrides) do
            local player = game.players[k]
            if not validate_config(v, player) then
                global.OB_CONF_overrides[k] = {}
                player.print({"outpost-builder.bad-config"})
                update_gui(player)
            end
        end
    else
        global.OB_CONF_overrides = {}
    end
end

ON_INIT = ON_INIT or {}
table.insert(ON_INIT, init_config)
