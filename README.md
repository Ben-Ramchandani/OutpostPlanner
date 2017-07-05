## Outpost Planner v0.1.8

Automatically build mining outposts. The tool will place the miners, power poles and belts before merging together the outgoing lanes.
To use select an ore patch with the tool.
By default the the mod will clear trees and rocks in the area selected, if shift is held then friendly entities will be deconstructed as well, keep in mind that the resulting outpost may be bigger than just the ore patch itself.

![OP example image](http://i.imgur.com/tUoPH24.png)

[Link to Factorio mod website](https://mods.factorio.com/mods/bob809/OutpostPlanner)

[More pictures](http://imgur.com/a/w0vgh)

#### In-game GUI

The mod includes an in-game GUI to change some settings which can be accessed via a small button in the top left of the screen 'OP'.

![OP settings](http://i.imgur.com/k51RABn.png)

From the left:

* Change the direction of the output belts (N, E, S, W).
* Change the maximum number of output belts. If there are more rows of miners than this number then the extra rows will be merged together.
If you click this button with an item in your hand then the number of items in the stack is read.
* Change the mining drill used (click with one in your hand).
* Change the electric pole used (click with one in your hand).
* Change the pipe used for e.g. Uranium mining (click with one in your hand).
* Change the transport belt used. The mod supports use of multiple transport belts, using faster ones only when necessary to maintain throughput.
To start using a new transport belt click the button with it in your hand, it will appear to the right of the button.
To stop using a transport belt click again with it in hand.
For example, starting from the default (just normal transport belt), if you want the mod to use express belt only, you should click once with express belt in hand (to add it) and then
click once with yellow belt in hand (to remove it).


#### Other settings


Alternatively the config file (`config.lua`) can be edited to change how the mod behaves (this *must* be the same between players in multiplayer). These options can also be changed for all existing players (multiplayer-safe) on a per-save basis with a command from the Lua console, e.g.

    /c remote.call("OutpostBuilder", "config", {electric_pole = "medium-electric-pole", run_over_multiple_ticks = false})

