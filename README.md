# Outpost Planner v0.4.1

Automatically build mining outposts. The tool will place the miners, power poles and belts before merging together the outgoing lanes.
To use select an ore patch with the tool.
By default the the mod will clear trees and rocks in the area selected, if shift is held then friendly entities will be deconstructed as well, keep in mind that the resulting outpost may be bigger than just the ore patch itself.

![OP example image](http://i.imgur.com/tUoPH24.png)

[Link to Factorio mod website](https://mods.factorio.com/mods/bob809/OutpostPlanner)

[More pictures](http://imgur.com/a/w0vgh)


## Basic settings

The mod includes an in-game GUI to change some settings which can be accessed via a small button in the top left of the screen 'OP'.


![OP settings](http://imgur.com/sf5Jrtv.png)

From the left:

* Open the advanced settings window
* Change the direction of the output belts (N, E, S, W).
* Change the maximum number of output belts. If there are more rows of miners than this number then the extra rows will be merged together.
If you click this button with an item in your hand then the number of items in the stack is read.
* Change the electric pole used (click with one in your hand).
* Change the pipe used for e.g. Uranium mining (click with one in your hand).
* Change the transport belt used. The mod supports use of multiple transport belts, using faster ones only when necessary to maintain throughput.
To start using a new transport belt click the button with it in your hand, it will appear to the right of the button.
To stop using a transport belt click again with it in hand or click on its icon in the list.  
For example, starting from the default (just normal transport belt), if you want the mod to use express belt only, you should click once with express belt in hand (to add it) and then
click once with yellow belt in hand (to remove it).  
You can instead click on this button with a chest and that will be used instead (for bot-based mining).

## Advanced settings

This mod has a system for custom blueprints to alter the layout used.

![OP advanced settings](http://i.imgur.com/AIbiusm.png)

Click on the read blueprint button with a blueprint in your hand and the mod will parse and use that blueprint.
Several example blueprints are provided, either to be used as they are or as a starting point for your own custom one.
Looking at these examples in-game is likely the best way to understand this mod, but further explanation is provided below.


### Mod mechanics

When an area is selected with the tool the ores are sorted by the product(s) of mining them and the ore(s) with the most common product(s) are selected.
The mod then proceeds to place the current blueprint in rows over the ore.

Miners are only placed when:
* There is no foreign ore in their mining area
* There is valid ore in their collision box

Belts are only placed when miners have already been placed in that row.
Electric poles are (by default, see below) placed later only as neccesary to power all blueprint entities.
Other entities (chests e.t.c.) are (again by default) placed when miners are placed from that blueprint.

### Blueprints

The following constraints are placed on blueprints:
* Must contain at least one miner
* Must have exactly one type of miner
* Must have at most one type of electric pole

Additionally for pipes to be placed when fluid mining (Uranium)
* The miner must have a 3x3 collision box (information about pipe connections is not available to the Lua API at runtime)
* All miners must be facing North or South

For smart transport belt selection:
* There must be one or more transport belts leaving the blueprint on the East side
* The blueprint may not have any underground belts leaving it

For determining the size of the blueprint Electric poles are ignored. A dummy entity (Wooden Chest by default) can be used to increase the size of the blueprint.

### Electric pole placement

There are currently three options for electric pole placement:
* Always: place every electric pole.
* Simple: Place electric poles at regular intervals, determined by the supply area and maximum wire distance of the poles used. For example a meduim electric pole might be placed every three blueprints.
* Smart: As above, but electric poles are placed last and only as required to power all entities.

If non-miner entities in the blueprint require power (e.g. Lamps) then Electric poles will always be placed in simple mode.


## Other settings


Alternatively the config file (`config.lua`) can be edited to change how the mod behaves (this *must* be the same between players in multiplayer). These options can also be changed for all existing players (multiplayer-safe) on a per-save basis with a command from the Lua console, e.g.

    /c remote.call("OutpostBuilder", "config", {pole_name = "medium-electric-pole", run_over_multiple_ticks = false})

## Changelog

0.4.1

* Added setting to change the container used in blueprints that have chests in.

0.3.2

* Changed Factorio version in `info.json` to 0.15 from 0.15.0.

0.3.1

* Added messege when dummy entity is changed. Removed Experimental warning.

0.3.0

* Rewrite of the mod to use custom blueprints.

0.2.0

* Pipes are now placed in gaps in rows of miners when fluid mining (Uranium).
* I'm now considering the mod stable. I'm working on a rewrite to allow for fully custom blueprints and I'm not planning any more updates until then except bug fixes.

0.1.9

* Belts are no longer placed before the first miner in a row.

0.1.8

* Ghosts are now considered colliding.
* Fix bug with collision for rotated entities.
* Fix deconstruction bug present with large numbers of output belts.
* The output belt count button now only reads item stacks that have a maximum stack size greater than 1.

0.1.7

* Added support for mining into chests (click on the transport belt button with a chest in hand).

0.1.6

* Fix crash on save load with the mod running.
* Fix placement bug in South and West directions.

0.1.5

* Added support for ores that produce the same product (e.g. Angel's infinite ores).

0.1.4

* Fix crash in config validation.
* Poles are no longer placed in rows with no miners.

0.1.3

* Name change to Outpost Planner.
* Added support for fluid mining (Uranium).

0.1.2

* Extra Small electric poles will be placed in rows to fully connect them.

0.1.1

* Fixed Locale typos.
* Removed hint on researching Logistics 2.

0.1.0

* First version.
