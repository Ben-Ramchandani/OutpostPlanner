
Mine Planner
------------

Automatically build mining outposts. The tool will place the miners, power poles and belts before merging together the outgoing lanes.
To use select an ore patch with the tool.
By default the the mod will clear trees and rocks in the area selected, if shift is held then friendly entities will be deconstructed as well, keep in mind that the resulting outpost may be bigger than just the ore patch itself.

The mod includes an in-game GUI to change some settings. Alternatively the config file (`config.lua`) can be edited to change how the mod behaves. These options can also be changed for all players on a per-save basis with a command from the Lua console, e.g.

    /c remote.call("OutpostBuilder", "config", {electric_pole = "medium-electric-pole", run_over_multiple_ticks = false})
