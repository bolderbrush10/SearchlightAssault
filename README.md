# Searchlights

###Welcome:
```
-> The interesting tweaks for you to make are in defines.lua
-> The interesting behaviors are in control-searchlight.lua
```

###Primary issues inflating SLOC:
0. My brain has been poisoned by nearly a decade of working nigh-exclusively in C++
0. No mechanism in the API to modify shooting range during runtime
0. No mechanism in the API to blacklist units from being attacked (except in very narrow cases)
0. Unsophisticated technique to "fire" the spotlight effect when
    no enemies present by creating a dummy entity in a dummy force (turtle)
    and a dummy spotlight in its own dummy force to shoot at the turtle

###File Guide:

defines.lua - miscellaneous static definitions such as turret range, colors, etc. Shared between most files.

control.lua - handles event registrations & filtering, calls behavior from the control-*.lua files

control-searchlight.lua - controls foe seeking behavior, turret-boosting behavior, etc
control-grid.lua        - optimizies searches for foes and spotlights by breaking apart the world into 'grid' units
control-turtle.lua      - behaviors for the dummy-entity that the spotlight "attacks" to render a light at surface locations

render.lua  - details on how to render lights, useful for debugging sometimes TODO remove
util.lua    - math functions, copying functions, and other miscellaneous functions

data.lua         - information for the mod manager
data-updates.lua - reads what turrets OTHER MODS have put into the game and generates extended-range versions of their prototypes
                   (this allows a searchlight to "boost" any given turret's range)
                   If another mod creates its own turrets in its own data-updates.lua or data-final-fixes.lua files,
                   then searchlights are probably not going to be able to boost that mod's turrets.
info.json        - information for the mod manager


Prototypes contain the definitions for a unit's graphics, animations, and base stats (like max health, range, and damage)

prototypes/entities.lua - prototypes for the searchlight and the turtle
prototypes/techItemRecipe.lua - details for how to research and craft a searchlight
