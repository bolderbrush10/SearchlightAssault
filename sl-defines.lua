-- Be sure to declare functions and vars as 'local' in prototype / data*.lua files,
-- because other mods may have inadvertent access to functions at this step.

-- It's not strictly necessary to declare functions locally like this, outside the data stage...
-- But, using local reduces the amount of calls to the global table lua has to perform,
-- speeding up performance greatly (Sometimes as much as ~30%, per lua.org/gems/sample.pdf)
-- So, throughout this codebase we'll use this convention to export local values as a matter of habit.

local d = {}


-----------------------------
-- Gameplay-related tweaks --
-----------------------------


-- Max range at which search light beam wanders
-- (About the same size as the radar's continuous reveal,
--  since the searchlight is built from a radar)
d.searchlightRange = 100

-- Max distance at which the searchlight looks for same-force turrets to boost the range of
-- This should mostly only be able to capture adjacent turrets of up to 3x3 size
-- We can try making this bigger to capture bigger / non-square turrets
d.searchlightMaxNeighborDistance = 3

-- Range boost effect provided to friendly turrets & their ammo so they can attack the distant foe the searchlight spotted
-- (Should equal the maximum spotting radius + maximum distance of a boostable friend from the searchlight.
--  Since the maximum distance a boostable friend can be might not be a whole number, thanks to trigonometry,
--  we'll just double that factor to keep it simple. (If we care, we can use something like:
--   math.ceil(squareroot(square(d.searchlightMaxNeighborDistance) + square(d.searchlightMaxNeighborDistance)))
--  to get a more accurate figure)
d.rangeBoostAmount = d.searchlightRange + d.searchlightMaxNeighborDistance*2

-- Range-boosted turrets fire this many times slower
d.attackCooldownPenalty = 30

-- Electric energy buffer size for the searchlight
d.searchlightCapacitorSize      = "1MJ"

-- How much electricity the searchlight consumes
-- (I think it's cute to have its usage be the sum of its parts)
d.searchlightEnergyUsage = "332kW"
d.searchlightControlEnergyUsage = "900kW"

-------------------------------------------------
-- Things that aren't interesting to mess with --
-------------------------------------------------

d.lightRadiusSetting = "searchlight-assault-setting-light-radius"

-- Radius at which the searchlight beam detects foes
-- Setting vision distance too low can cause turtles to get stuck in their foes
d.defaultSearchlightSpotRadius = 4
d.searchlightSpotRadius = d.defaultSearchlightSpotRadius

if settings then -- Have to have this check for when this file is used prior to prototype stage
  d.searchlightSpotRadius = settings.startup[d.lightRadiusSetting].value
end

-- Speeds at which searchlight beam wanders / responds to circuit commands
-- There is a maximum speed which you cannot exceed or else the turtle
-- has a high chance to run inside the collision box of an enemy before
-- it has a chance to fire its attack. (About 0.4 is too fast)
-- This results in the turtle getting 'stuck' without attacking,
-- and thus results in us having to rely on the
-- ai_command_complete event fired when the distraction attack-event is done
-- (which is a process that is seemingly-impossible to speed up)
d.searchlightWanderSpeed = 0.1

d.searchlightRushSpeed = 0.13  -- Just barely slower than base player speed

-- Ticks until a searchlight stops being suspicious and goes back to its search pattern
d.searchlightSpotTime = 1.5 * 60

-- Ticks from when a searchlight becomes suspicious
-- until the searchlight can confirm it has spotted a foe.
-- This timeout can't be too short or else the game won't 
-- be able to process the landmine arming fast enough,
-- and players won't get a chance to get away.
-- It can't be too long or else it's easy to just run straight 
-- through the spotlight without getting spotted.
d.searchlightArmTime = 20


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
d.hazeOneCellAnim = "searchlight-haze-onecell-animation"
d.hazeOneHex = "searchlight-haze-onehex"

-- Force name-suffix, to be appended to the name of the force that owns a searchlight
d.turtleForceSuffix = "_SLATurtle"

-- Identifies range boosted versions of turrets
d.boostSuffix = "-sla_boosted"

-- Mod settings keys
-- d.lightRadiusSetting = defined above
d.ignoreEntriesList = "searchlight-assault-setting-ignore-entries-list"
d.uninstallMod = "searchlight-assault-uninstall"
d.overrideAmmoRange = "searchlight-assault-override-ammo-range"

return d
