# Searchlights

-> All the interesting behaviors happen in searchlight-control.lua

Primary issues inflating SLOC:
0 My brain has been poisoned by nearly a decade of working nigh-exclusively in C++
0 No mechanism in the API to modify shooting range during runtime
0 Unsophisticated technique to "fire" the spotlight effect when
    no enemies present by creating a dummy entity in a dummy force (turtle)
    and a dummy spotlight in its own dummy force to shoot at the turtle


File Guide:

control.lua - handles event registrations

searchlight-control.lua - controls foe seeking behavior, turret-boosting behavior, etc
searchlight-defines.lua - miscellaneous static definitions such as turret range, colors, etc. Is shared between the prototype and control files.
searchlight-grid.lua    - optimizies searches for foes and spotlights by breaking apart the world into 'grid' units
searchlight-render.lua  - details on how to render lights, useful for debugging sometimes TODO remove
searchlight-util.lua    - math functions, copying functions, and other miscellaneous functions

data.lua         - information for the mod manager
data-updates.lua - reads what turrets OTHER MODS have put into the game and generates extended-range versions of their prototypes
                   (this allows a searchlight to "boost" any given turret's range)
                   If another mod creates its own turrets in its own data-updates.lua or data-final-fixes.lua files,
                   then searchlights are probably not going to be able to boost that mod's turrets.
info.json        - information for the mod manager


Prototypes contain the definitions for a unit's graphics, animations, and base stats (like max health, range, and damage)

prototypes/searchlight-entity.lua - prototypes for the searchlight and the turtle
prototypes/searchlight-techItemRecipe.lua - details for how to research and craft a searchlight


