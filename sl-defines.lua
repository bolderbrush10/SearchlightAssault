-- Be sure to declare functions and vars as 'local' in prototype / data*.lua files,
-- because other mods may have inadvertent access to functions at this step.

local d = {}


-----------------------------
-- Gameplay-related tweaks --
-----------------------------


-- Max range at which search light beam wanders
-- (About the same size as the radar's continuous reveal,
--  since the searchlight is built from a radar)
d.searchlightRange = 100

-- Max distance at which the searchlight boosts the range of same-force turrets (using a square grid)
-- At 3, this range is virtually 'adjacent-only'
d.searchlightMaxNeighborDistance = 3

-- Range boost effect provided to friendly turrets so they can attack the distant foe the searchlight spotted
-- (Should equal the maximum spotting radius + maximum distance of a boostable friend from the searchlight.
--  Since the maximum distance a boostable friend can be might not be a whole number, thanks to trigonometry,
--  we'll just double that factor to keep it simple. (If we care, we can use something like:
--   math.ceil(squareroot(square(d.searchlightMaxNeighborDistance) + square(d.searchlightMaxNeighborDistance)))
--  to get a more accurate figure)
d.rangeBoostAmount = d.searchlightRange + d.searchlightMaxNeighborDistance*2

-- Range-boosted turrets fire this many times slower
d.attackCooldownPenalty = 50

-- Capacitor size (electric energy buffer) for the searchlight
-- (The searchlight requires a partial-buffer to start operating, and turns back off when the buffer is below the cutoff)
-- ((We use this to reduce pathological "flickering" cases when a factory is in low power,
--   and we'd otherwise need to constantly enable / disable the hidden entities that make the searchlight work))
d.searchlightCapacitorSize      = "5MJ"
d.searchlightCapacitorCutoff    =   250000 -- joules
d.searchlightCapacitorStartable =  2500000 -- joules

-- How much electricity the searchlight consumes
-- (I think it's cute to have its usage be the sum of its parts)
d.searchlightEnergyUsage = "332kW"
d.searchlightControlEnergyUsage = "900kW"

-------------------------------------------------
-- Things that aren't interesting to mess with --
-------------------------------------------------

-- Radius at which the searchlight beam detects foes
-- Setting vision distance too low can cause turtles to get stuck in their foes
-- Actual search radius will be increased by 10% to make detection more reliable
d.searchlightSpotRadius = 3

-- Speed at which searchlight beam wanders
-- There is a maximum speed which you cannot exceed or else the turtle
-- has a high chance to run inside the collision box of an enemy before
-- it has a chance to fire its attack. (About 0.3 is too fast)
-- This results in the turtle getting 'stuck' without attacking,
-- and thus results in us having to rely on the
-- ai_command_complete event fired when the distraction attack-event is done
-- (which is a process that is seemingly-impossible to speed up)
d.searchlightWanderSpeed = 0.1

d.searchlightRushSpeed = 0.15

-- Amount of time in milliseconds from when a searchlight becomes suspicious
-- until the searchlight confirms it has spotted a foe
-- (Setting this too low will cause conflicts with landmine arming-time)
-- (game runs at 60 ticks per second)
d.searchlightSpotTime_ms = 0.8 * 60


-------------------------------------------------
-- Really boring stuff                         --
-------------------------------------------------

-- Player-Visible entity, item, recipe names
-- Any updates to these names must be reflected in the locale config.cfg files
d.searchlightItemName = "searchlight-assault"
d.searchlightRecipeName = "searchlight-assault"
d.searchlightTechnologyName = "searchlight-assault"

d.searchlightBaseName = "searchlight-assault-base"
d.searchlightAlarmName = "searchlight-assault-alarm"
d.searchlightSignalInterfaceName = "searchlight-assault-signal-interface"
d.searchlightControllerName = "searchlight-assault-control"

-- Non-Visible entity / effect names
d.spotterName = "searchlight-assault-spotter"
d.turtleName = "searchlight-assault-turtle"
d.remnantsName = "searchlight-assault-remnants"
d.spottedEffectID = "searchlight-assault-spotted-effect"
d.confirmedSpottedEffectID = "searchlight-assault-confirm-spotted-effect"

-- Force name-suffix, to be appended to the name of the force that owns a searchlight
d.turtleForceSuffix = "_SLATurtle"

-- Identifies range boosted versions of turrets
d.boostSuffix = "-sla_boosted"

-- Mod settings keys
d.ignoreEntriesList = "searchlight-assault-setting-ignore-entries-list"
d.uninstallMod = "searchlight-assault-uninstall"

return d
