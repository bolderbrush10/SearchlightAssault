# Searchlights

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
- Animated graphics including remnants, custom light effects, and high-res integration
- Custom audio effects
- Optimized to allow running several thousand searchlights
- Searchlights can be connected to the circuit network
  - Takes inputs of coordinates to search
  - Outputs position data of spotted foes
  - Outputs signals for when a foe is suspected / spotted
- Mod settings
  - Option to list turrets which shouldn't be boosted
  - Option to provide a clean Uninstall
- Vehicles can be used to distract searchlights

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

## Contact

You are welcome to contact me via email: bolderbrush10@gmail.com

I am willing to consider releasing this software under alternate licenses,
if the present one is somehow not permissive enough for your purpose.

If you have any feedback or footage featuring my mod, please share with me!

## Technical Details / Details for other Modders

### Known Bugs:

- [Mitigated] Players right clicking to destroy a ghost searchlight can leave behind ghost signal-interfaces

- [Mitigated] It's possible to 'fake out' the turtle near the edge of the searchlight range
  and desync the searchlight from attacking its turtle or make the turtle "lock up"

- [Cheat Mode] Mass-deconstructing alarm-mode searchlights and boosted turrets at
  the same exact time causes the searchlights to re-boost turrets as they die,
  causing boosted versions of that turret to be spawned in and avoid being mass-deconstructed.

- [Feature?] You can sit in a car / tank somewhere to distract a spotlight indefinitely if it notices you in it

- Boosted turrets have trouble shooting at something if it has its force set every tick

- Two searchlights have trouble targeting each other at the same time
  (Probably because of raise/clearAlarm() "destroying" their targets and creating a new entity of the alarm / base type)

### Map Editor Quirks

#### Don't use the Clone / Entities tool for searchlights & turrets

Using the Tools->Entities tab or Clone tab to add / remove searchlights and turrets may result in the mod breaking.
Entities built or removed through those tabs don't fire on_created / on_destroyed events, which this mod relies on.

### Terms

#### Gestalt

A gestalt is an aggregation of things which together are more capable than by the sum of their individual parts.

In this mod, a 'gestalt' refers to the collection of a Searchlight, the list of turrets it may range-boost,
and several hidden entities which each are essential to making features work.

#### Turtle

The term "Turtle" is a reference to the rendering concept of some old, beginner-friendly programming languages (such as 'Logo', from 1960's).

The idea is to imagine a turtle with a marker held in its tail, and wherever this turtle goes, it leaves behind a line. You'd write a program specifiying distances & directions for the turtle to follow. And thus, you'd control the turtle to control rendering a picture.

And in this mod, our turtle, instead of drawing a line, will render a searchlight effect.


#### Primary issues inflating SLOC:
While I enjoyed the challenge of making this mod with as few changes to the base game as possible,
it is undeniable that this codebase would be drastically smaller if these issues weren't in place:

0. No mechanism in the API to modify shooting range during runtime
0. API doesn't provide some info in on_player_setup_blueprint event for some blueprint use cases
0. Unsophisticated technique to "fire" the searchlight effect when
    no enemies present by creating a dummy entity in a dummy force (turtle)
0. No mechanism in the API to blacklist units from being attacked by artilery, capsule robots, etc
    (TargetMasks seems to only affect turrets)
0. Attacks fail if a unit enters its target's hitbox
0. Vehicles don't count as an entity_with_force, so you can't set their shooting target to one manually,
   even though turrets _can and do_ attack vehicles
0. Command complete events don't fire right when a distraction occurs,
   you have to wait for the distraction to be over to know if your command was interrupted


#### File Guide:

_sl-defines.lua_          - miscellaneous static definitions such as turret range, colors, etc. Shared between most files.

_control.lua_             - handles event registrations & filtering, calls behavior from the control-*.lua files
_control-searchlight.lua_ - controls foe seeking behavior, range-boosting behavior, etc. Interacts with other control-* files.
_control-turtle.lua_      - behaviors for the dummy-entity that the searchlight "attacks" to render a light at surface locations
_control-forces.lua_      - sets up the forces assigned to hidden entities and handles force migrations
_control-items.lua_       - converts items in blueprints to the base versions of boosted turrets
_control-common.lua_      - data structures to be shared across control-* files and functions for maintaining them

_sl-util.lua_             - math functions, copying functions, and other miscellaneous functions

_info.json_        - information to display in the mod portal webpage, plus version / mod dependency information
_data.lua_         - lists which files the mod manager should read to build & modify prototypes
_data-updates.lua_ - reads what turrets OTHER MODS have put into the game and generates extended-range versions of their prototypes
                    (this allows a searchlight to "boost" any given turret's range)
                    If another mod creates its own turrets in its own data-updates.lua or data-final-fixes.lua files,
                    then searchlights are probably not going to be able to boost that mod's turrets.


Prototypes contain the definitions for a unit's graphics, animations, and stats (such as max health, range, and damage)

_prototypes/sl-entities.lua_       - prototypes for the searchlight and the turtle
_prototypes/sl-graphics.lua_       - pictures, lights, spirites, and animations
_prototypes/sl-techItemRecipe.lua_ - details for how to research and craft a searchlight

_modder-notes.md_ - Useful notes for modders detailing design decisions, known bugs, and TODOs


#### Design Decisions & Discussion

- What if we just manually call render for a searchlight effect and move & search around it every tick ourselves?

  This is extremely performance intensive, after a few dozen searchlights like this you noticably lose fps.
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

- Write up how non-turrets just totally ignore trigger_type_mask
  And how it's seemingly-impossible to set up a blocklist for an entity that you don't want even-just-turrets to attack.

- 'on_save' event, or a way in general to make sure that uninstalling our mod will give people back their original turrets.
  (Alternatively, ask for the simple ability to increase turret range during run time)

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
- Waves of biters attack the rocket pad every few minutes on higher difficulties

- Make another lab facility to show off the indestructible power poles 
  (complex furance setup, testing area with lots of destruction, power poles in varying states of distress, but most in perfect condition,
  wall of power poles to protect from biters with a few turrets behind)
  Special recipe: Steel, copper cable, and depleted uranium all go into a furnace, then into another furance, then into an assembler

- Create more main-menu simulations
  (Unfortunately, control.lua doesn't work in main-menu simulations, so we have to work around that...)
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

### Code:
- Handle cloning entities / brush cloning map areas

- Searchlight brightness decreases during brownout

- Searchlight color controlled by circuit signals

- Searchlight could possibly be set to only wander a 180 degree arc around its initial placement?

- Don't show searchlights in the turret coverage map mode

- Detect playerRotatedEntity events and swing the turtle waypoint around 90 degrees each time the player rotates the SL itself.
  So, the playerRotatedEntity event doesn't fire for this. We'll have to add a custom input event and check if the player
  has a searchlight selected. Maybe play a little UI sound.

- Mod compatability setting feature: \nWildcard matching possible with asterisk *

- Look more into teleporting or somehow... hiding the entities we're replacing.
  It'd be nice to not have to spawn / destroy turrets all the time just because we're boosting them.
  Initial research doesn't look promising.

- Break apart into a 'boostable turrets' mod
  Let people use mod settings to control what level the boosting is
  How to handle recipes? Just a beacon to all the regular recipes, enable it with a unique range-boosting technology?
  Or just make a stand-alone version of the mod and a non-standalone version?

### Art:
- Further crop the mask sprite, figure out the offset it needs

- Optimize file sizes better, maybe increase the file compression and see if it loads faster or slower

- Make a dirt estucheon for where wires reach into the ground

- Re-render everything with some kind of smudge / blur post-processing effect
  so it can blend in better with the base game

- water_reflection

- Shadow layer cleanup:
  I think I need to go into photoshop or blender and rig it so that any pixels from the base layer
  exclude pixels from the shadow layer
