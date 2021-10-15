# Searchlights

### Welcome:
```
-> The interesting & easy tweaks to make are in sl-defines.lua
-> The interesting behaviors are mostly in control-searchlight.lua
```

### Turtle
Usage of the term "Turtle" is a reference to the rendering mechanism of some old, beginner-friendly programming languages (such as 'Logo', from 1960's).

The idea is to imagine a turtle with a marker held in its tail, and wherever this turtle goes, it leaves behind a line. You'd write a program specifiying distances & directions for the turtle to follow. And thus, you'd control the turtle to control rendering a picture.

And in this mod, our turtle, instead of drawing a line, will render a searchlight effect.


### Primary issues inflating SLOC:
0. No mechanism in the API to modify shooting range during runtime
0. Missing details in on_player_setup_blueprint event for some blueprint use cases
0. Unsophisticated technique to "fire" the searchlight effect when
    no enemies present by creating a dummy entity in a dummy force (turtle)
0. No mechanism in the API to blacklist units from being attacked by artilery, capsule robots, etc
    (TargetMasks seems to only affect turrets)
0. "Melee" attacks against non-colliding entities frequently fail


### File Guide:

_sl-defines.lua_ - miscellaneous static definitions such as turret range, colors, etc. Shared between most files.

_control.lua_             - handles event registrations & filtering, calls behavior from the control-*.lua files

_control-searchlight.lua_ - controls foe seeking behavior, range-boosting behavior, etc. Interacts with other control-* files.
_control-turtle.lua_      - behaviors for the dummy-entity that the searchlight "attacks" to render a light at surface locations
_control-forces.lua_      - sets up the forces assigned to hidden entities and handles force migrations
_control-items.lua_       - converts items in blueprints to the base versions of boosted turrets
_control-common.lua_      - data structures to be shared across control-* files and functions for maintaining them

_sl-util.lua_ - math functions, copying functions, and other miscellaneous functions

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
