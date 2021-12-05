# Searchlights

## Welcome:
```
-> The interesting & easy tweaks to make are in sl-defines.lua
-> The interesting behaviors are mostly in control-searchlight.lua
```

### Uninstallation

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


### Features

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
- New coop-multiplayer scenario map to challenge you and your friends
- Vehicles can be used to distract searchlights

### Turret boost block list

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

## Details for other modders

#### Map Editor Quirks

#### Don't use the Entities tool for searchlights & turrets

Using the Tools->Entities tab to add / remove searchlights and turrets may result in the mod breaking.
Entities built or removed through that tab don't fire on_created / on_destroyed events, which this mod relies on.

### Technical Terms

#### Turtle

Usage of the term "Turtle" is a reference to the rendering mechanism of some old, beginner-friendly programming languages (such as 'Logo', from 1960's).

The idea is to imagine a turtle with a marker held in its tail, and wherever this turtle goes, it leaves behind a line. You'd write a program specifiying distances & directions for the turtle to follow. And thus, you'd control the turtle to control rendering a picture.

And in this mod, our turtle, instead of drawing a line, will render a searchlight effect.

#### Gestalt

A gestalt is an aggregation of units which together are more capable than by the sum of their individual parts.

In this mod, a 'gestalt' refers to the collection of a Searchlight, the list of turrets it may range-boost,
and several hidden entities which each are essential to making features work.


### Contact

You are welcome to contact me via email: bolderbrush10@gmail.com
I am willing to consider releasing this software under alternate licenses,
if the present one is somehow not permissive enough for your purpose.


### Technical Details

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


### File Guide:

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
