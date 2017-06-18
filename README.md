
Outpost Builder
---------------

Automatically build mining outposts. The tool will place the miners, power poles and belts before merging together the outgoing lanes.
To use select an ore patch with the tool.
Holding shift whilst using the tool puts it in a different mode, deleting ghosts and ordering the deconstruction of miners which have run out of ore.

The config file (`config.lua`) can be edited to change how the mod behaves. These options can also be changed on a per-save basis with a command from the Lua console, e.g.

    /c remote.call("OutpostBuilder", "config", {electric_pole_spacing = 9, run_over_multiple_ticks = false})

