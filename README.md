# Searchlights

###Welcome:
```
-> The interesting tweaks for you to make are in defines.lua
-> The interesting behaviors are in control-searchlight.lua
```

### Turtle
Usage of the term "Turtle" is a reference to the rendering mechanism of some old, beginner-friendly programming languages (such as 'Logo', from 1960's).

The idea is to imagine a turtle with a marker held in its tail, and wherever this turtle goes, it leaves behind a line. You'd write a program specifiying distances & directions for the turtle to follow. And thus, you'd control the turtle to control rendering a picture.

And in this mod, our turtle, instead of drawing a line, will render a spotlight effect.


###Primary issues inflating SLOC:
0. My brain has been poisoned by nearly a decade of working nigh-exclusively in C++
0. No mechanism in the API to modify shooting range during runtime
0. No mechanism in the API to blacklist units from being attacked (except in very narrow cases)
0. Unsophisticated technique to "fire" the spotlight effect when
    no enemies present by creating a dummy entity in a dummy force (turtle)


###File Guide:

sl-defines.lua - miscellaneous static definitions such as turret range, colors, etc. Shared between most files.

control.lua             - handles event registrations & filtering, calls behavior from the control-*.lua files

control-searchlight.lua - controls foe seeking behavior, range-boosting behavior, etc. Interacts with other control-* files.
control-turtle.lua      - behaviors for the dummy-entity that the spotlight "attacks" to render a light at surface locations
control-grid.lua        - optimizies searches for foes and spotlights by breaking apart the world into 'grid' units
control-forces          - sets up the forces assigned to hidden entities
control-common          - data structures to be shared across control-* files

render.lua  - details on how to render lights, useful for debugging sometimes TODO remove
sl-util.lua - math functions, copying functions, and other miscellaneous functions

data.lua         - information for the mod manager
data-updates.lua - reads what turrets OTHER MODS have put into the game and generates extended-range versions of their prototypes
                   (this allows a searchlight to "boost" any given turret's range)
                   If another mod creates its own turrets in its own data-updates.lua or data-final-fixes.lua files,
                   then searchlights are probably not going to be able to boost that mod's turrets.
info.json        - information for the mod manager


Prototypes contain the definitions for a unit's graphics, animations, and stats (like max health, range, and damage)

prototypes/sl-entities.lua       - prototypes for the searchlight and the turtle
prototypes/sl-graphics.lua       - pictures, lights, spirites, and animations
prototypes/sl-techItemRecipe.lua - details for how to research and craft a searchlight
