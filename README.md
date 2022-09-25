## Searchlights


## Welcome:
```
-> The interesting & easy tweaks to make are in sl-defines.lua
-> The interesting behaviors are mostly in control-gestalt.lua
```

## Uninstallation

If a turret is being range-boosted by a searchlight when this mod is uninstalled, it may be lost when the save is reloaded.

To avoid the risk of random turrets disappearing:
- Load your save
- Pause the game, and enter the Settings menu
- Enter the Mod Settings menu, then the Map tab
- Locate the SearchlightAssault mod settings option "Prepare to uninstall mod" and activate it
- Confirm changes and exit the pause menu
- Resume playing for at least 1 second
- Save your game
- Uninstall the mod

This will destroy all searchlights and hidden entities used by this mod, and prevent the loss of other turrets.


## Features

- New coop-multiplayer scenario map to challenge you and your friends

- Searchlights automatically scan their territory for foes
- Searchlights may boost the range of neighboring turrets and direct them to snipe spotted foes
- Custom animated graphics, plus remnants, custom light effects, and high-res integration
- Custom audio effects for the searchlight, its light effect, and when spotting a foe
- Optimized to allow running several thousand searchlights
- Searchlights can be connected to the circuit network
  - Takes inputs of coordinates to search
  - Outputs position data of spotted foes
  - Outputs own-position data
  - Outputs signals for when a foe is suspected / spotted
- Mod settings
  - Option to list turrets which shouldn't be boosted
  - Option to provide a clean Uninstall


## Turret boost block list

In the event that another mod's turrets are incompatible with SearchlightAssault trying to boost their range, the block list can be used to prevent issues.

It is advised to add incompatible turrets to the blocklist before placing any searchlights nearby.

To add one or more turrets to the block list:
- Look up the name of the incompatible turret
  - You can either check the mod's .lua files for the entity prototype, or try using this simple in-game command while hovering your mouse over the turret in question:
  - /c game.print(game.player.selected.name)
- Load your game
- Pause the game, and enter the Settings menu
- Enter the Mod Settings menu, then the Map tab
- Locate the SearchlightAssault mod settings option "Ignore turrets matching these semi-colon separated names:"
- Write the entity / prototype name exactly, including hypens (-), etc
- To add more turrets, put a semicolon (;) between each entry
- Confirm changes and exit the pause menu
- Resume playing

Note that changes made in the mod settings menu will be lost unless you save your game.

Some turrets may not be boostable to begin with, and are automatically ignored by this mod.


## FAQ

- Hero Turrets mod compatibility: Mod Settings -> Startup -> Hero Turrets -> Create in updates: True

- Potential Mod Incompatibility: Any mod which uses highly scripted turrets that interact with their own hidden entities, or turrets that are populated into a global table.

- Workarounds: Add turrets from incompatible mods into the turret-boost block list. (See above section)

- Remote Interface: Other mods may add or remove their own turrets from the blocklist using the remote interface. Results of these calls are noted in factorio-current.log. Example of use:
```
Your mod's control.lua:
remote.call("sl_blocklist", "add", "laser-turret")
remote.call("sl_blocklist", "remove", "laser-turret")
remote.call("sl_blocklist", "add", "lazur_turett")

  factorio-current.log:
Script @__SearchlightAssault__/control-blocklist.lua:30: Searchlight Assault: Blocking laser-turret from searchlight interaction.
Script @__SearchlightAssault__/control-blocklist.lua:40: Searchlight Assault: Unblocking laser-turret; interaction now allowed.
Script @__SearchlightAssault__/control-blocklist.lua:26: Searchlight Assault: Turret prototype name specified by remote call not found: lazur_turett
```
For more information: https://lua-api.factorio.com/latest/LuaRemote.html


## Contact

You are welcome to contact me via email: bolderbrush10@gmail.com

If you have any feedback or footage featuring my mod, please share with me! I would love to know what people think.


## Technical Details / Details for other Modders

### Known Issues:

- [Mitigated] It's possible to 'fake out' the turtle near the edge of the searchlight range
  and desync the searchlight from attacking its turtle or make the turtle "lock up"

- [Cheat Mode] Mass-deconstructing alarm-mode searchlights and boosted turrets at
  the same exact time causes the searchlights to re-boost turrets as they die,
  causing boosted versions of that turret to be spawned in and avoid being mass-deconstructed

- [Feature?] Spidertrons can only distract searchlights, not be targeted by them

- Boosted turrets have trouble shooting at something if it has its force set every tick

- Two searchlights have trouble targeting each other at the same time
  (Probably because of raise/clearAlarm() "destroying" their targets and creating a new entity of the alarm / base type)


### Terms

#### Gestalt

A gestalt is an aggregation of things which together are more capable than by the sum of their individual parts.

In this mod, a 'gestalt' refers to the collection of a Searchlight, the list of turrets it may range-boost,
and several hidden entities which each are essential to making features work.


#### Turtle

The term "Turtle" is a reference to the rendering concept of some old, beginner-friendly programming languages (such as 'Logo', from 1960's).

The idea is to imagine a turtle with a marker held in its tail, and wherever this turtle goes, it leaves behind a line. You'd write a program specifiying distances & directions for the turtle to follow. And thus, you could control the turtle to control rendering a picture.

And in this mod, our turtle, instead of drawing a line, will help render a searchlight effect.


#### Primary issues inflating SLOC:
I enjoyed the challenge of making this mod with as few changes to the base game as possible,
but this codebase would be drastically smaller if these issues weren't in place:

0. Developers have stated that they won't allow modifying shooting range during runtime
   https://forums.factorio.com/viewtopic.php?f=221&t=101902
0. No mechanism in the API to modify ammo max range during runtime
0. API doesn't provide some info in on_player_setup_blueprint event for some blueprint use cases
0. Unsophisticated technique to "fire" the searchlight effect when
    no enemies present by creating a dummy entity in a dummy force (turtle)
0. No mechanism in the API to blacklist units from being attacked by artilery, capsule robots, etc
    (TargetMasks seems to only affect turrets)
0. Vehicles don't count as an entity_with_force, so you can't set their shooting target to one manually,
   even though turrets _can and do_ attack vehicles
   (One must detect the vehicle, then check for a driver inside it and target the driver)
0. Command complete events don't fire right when a distraction occurs,
   you have to wait for the distraction to be over to know if your command was interrupted
0. The mod editor doesn't fire events while creating / destroying from some tabs.
0. Developers have repeatedly stated they won't do an OnCircuitConnected/Disconnected
   https://forums.factorio.com/viewtopic.php?p=369587#p369587
   https://forums.factorio.com/viewtopic.php?p=509912#p509912
0. Wires also don't trigger OnEntityCreated/Destroyed.
   


#### File Guide:

_sl-defines.lua_          - miscellaneous static definitions such as turret range, colors, etc. Shared between most files.  
  
_control.lua_             - handles event registrations & filtering, calls behavior from the control-\*.lua files  
_control-gestalt.lua_     - controls foe seeking behavior, range-boosting behavior, etc. Interacts with other control-\* files  
_control-searchlight.lua_ - behaviors for the searchlight itself when created / alarms are raised, etc  
_control-tunion.lua_      - behaviors for range-boosting turrets  
_control-turtle.lua_      - behaviors for the dummy-entity that the searchlight "attacks" to render a light at surface locations  
_control-forces.lua_      - sets up the forces assigned to hidden entities and handles force migrations  
_control-gui.lua_         - Graphical User Interface controls, for displaying windows allowing control of searchlights to players  
_control-items.lua_       - converts items in blueprints to the base versions of boosted turrets  
_control-blocklist.lua_   - controls for filtering incompatible turrets per mod settings and remote interfaces  
_control-common.lua_      - data structures to be shared across control-* files and functions for maintaining them  
  
_sl-relation.lua_         - a simple matrix to help track relations between turrets, foes, and searchlights  
_sl-render.lua_           - displays the searchlight's search area  
_sl-util.lua_             - math functions, copying functions, and other miscellaneous functions  
  
_info.json_            - information to display in the mod portal webpage, plus version / mod dependency information  
_settings.lua_         - prototypes for the settings that can be configured for this mod  
_data.lua_             - lists which files the mod manager should read to build & modify prototypes  
_data-updates.lua_     - reads what turrets OTHER MODS have put into the game
                         and generates extended-range versions of their prototypes
                         (this allows a searchlight to "boost" any given turret's range).
                         If another mod creates its own turrets in its own data-updates.lua or data-final-fixes.lua files,
                         then searchlights are probably not going to be able to boost that mod's turrets.  
_data-final-fixes.lua_ - Double checks that any boosted turrets have the correct health,
                         since other mods have been discovered to change vanilla turrets in data-updates.
                         Generates extended-range versions of ammo prototypes, since other mods have
                         been observed modifying vanilla ammo in data-updates.
                         Also declares our own entities here, so other mods will stop messing with them.  
  

Prototypes contain the definitions for a unit's graphics, animations, and stats (such as max health, range, and damage)  
  
_prototypes/sl-entities.lua_       - prototypes for the searchlight, hidden entities such as the turtle, etc
_prototypes/sl-datastage-entities.lua_  - prototypes for entites that rely on basegame entity data
_prototypes/sl-graphics.lua_       - pictures, lights, spirites, and animations  
_prototypes/sl-gui.lua_            - defines GUI styles for later use in control-gui.lua  
_prototypes/sl-shortcuts.lua_      - defines / modifies in game hotkeys (used to open the searchlight GUI)  
_prototypes/sl-signals.lua_        - virtual signals for refined control over searchlights  
_prototypes/sl-techItemRecipe.lua_ - details for how to research and craft a searchlight  
  
_locale/*_ - Translations of the various in-game strings displayed to the player  
  
_menu-simulations/*_ - Contains small demos that run during the game's main menu, on a random rotation  
  
_scenarios/*_ - The latest revision of the Prison Break game mode. Of note are the files _sl_silobreak.py_ and _sl_prisonbreak.py_, which contain scenario-specific logic, events, and win conditions.  


#### Design Decisions & Discussion

- What if we just manually call render for a searchlight effect and move & search around it every tick ourselves?

  This is extremely performance intensive, noticably costing fps after only a few dozen searchlights.
  It's vastly more efficient to have the game create an entity, shoot at it,
  and let the engine do pathfinding and rendering calls for us.
  (Even with all the rigmarole associated with maintaining that entity...)
  Plus, we get to have the searchlight effect 'rotate' around the turret at no extra cost.


- What if we used TargetMasks to protect turtles from being attacked,
  instead of giving them their own force?

  Unfortunately, capsule robots and other non-turret entities
  don't seem to respect the TargetMasks.


- What if we required players to connect their light with wire to the turrets they want it to affect?
  Connect searchlights to a beacon to have the light auto-boost in a radius?
  Have another version that takes a beacon as an ingredient to auto-boost?
  Have a version that takes a radar / rocket control unit for a really big boost?

  Imagine what the wube devs would do:
  There'd just be ONE version of a turret, and it'd be straightforward to use.


- How can we indicate the boostable radius / decorate terrain of boostable region?

  No longer necessary, decided to just boost adjacent turrets.
  It was very painful to try to figure out a way to get turret range and
  radius_visualization to coexist.


#### Mod Interface Features / Issues to Request / Report

- [DONE] energy_glow_animation on turrets flickers badly
         Dev responded and agreed to solve:
         https://forums.factorio.com/viewtopic.php?f=7&t=100260&p=554307#p554307

- OnPowerLost/Restored event mod interface request (So we don't have to check power manually in onTick)

- Write up how non-turrets just totally ignore trigger_type_mask...
  And how it's seemingly-impossible to set up a blocklist for an entity that you don't want even-just-turrets to attack.

- 'on_save' event, or a way in general to make sure that uninstalling our mod will give people back their original turrets.

- Report prefer_straight_paths = true as bug? Seems to do the opposite of what it says

- When editing an already-saved blueprint's contents by selecting a new area,
  the on_player_setup_blueprint event is fired,
  but the replacement contents don't show up in the player's blueprint or cursor blueprint stack
  (cursor_stack.is_blueprint is true, but is_blueprint_setup() is false,
   get_blueprint_entities() returns nothing, and get_blueprint_entity_count() is zero)
  Where it does show up is in the blueprint from the player's inventory,
  which means you have to iterate through the whole inventory
  and hope you can find the right blueprint,
  AND also deal with the problem of the blueprint being nested in a book...
  Related? https://forums.factorio.com/viewtopic.php?t=99845


## Stretch Goals

### Map Editing:
- Create more main-menu simulations, update existing sim.
  (Unfortunately, the mod's control.lua doesn't work in main-menu simulations, so we have to work around that...)
    - We can probably chain the turtle to follow another turtle to give its tragetory more of a curve...
    - Actually, it looks like we can do some real magic in menu-simulations.lua init,
      registering stuff to happen in on_nth_tick. "Chase" is a great example.
      Let's make use of that.
    - (Maybe even launch something at the turtle so the spotlight will "fire" when the turtle dies?)
    - Probably want a scene with a jail break that succeeds (tank that busts through wall, bunch of people on foot follow)
    - Probably want a scene with a jail break that fails (car crashes into wall, explodes, people spill out get caught)
    - There's probably a good few default ones that would suit being changed to night time and having
      some searchlights thrown into
    - Also probably want to vary up the grass a bit, add some decoratives on the existing map

- Retune prisonbreak scenario difficulty
    - Easy difficulty shouldn't drop biter pods until after players start building a rocket

- Victory screen prints out what difficulty you were on 
  (with a percentage of playtime since reaching that difficulty)
  and hint how you can increase the difficulty level


### Code:
- Tips & Tricks integration

- Handle cloning entities / brush cloning map areas

- Searchlight brightness decreases during brownout

- Searchlight color controlled by circuit signals

- Mod compatability setting feature: \nWildcard matching possible with asterisk *

- Look more into teleporting or somehow... hiding the entities we're replacing.
  It'd be nice to not have to spawn / destroy turrets all the time just because we're boosting them.
  Initial research doesn't look promising.

- Break apart into a 'boostable turrets' mod.
  Let people use mod settings to control what level the boosting is.
  How to handle recipes? Just a beacon to all the regular recipes, enable it with a unique range-boosting technology?
  Or just make a stand-alone version of the mod and a non-standalone version?


### Art:

- Re-render everything with some kind of smudge / blur post-processing effect
  so it can blend in better with the base game

- Shadow layer cleanup:
  I think I need to go into photoshop or blender and rig it so that any pixels from the base layer
  exclude pixels from the shadow layer
