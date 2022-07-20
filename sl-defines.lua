-- Be sure to declare functions and vars as 'local' in prototype / data*.lua files,
-- because other mods may have inadvertent access to functions at this step.

-- It's not strictly necessary to declare functions locally like this, outside the data stage...
-- But, using local reduces the amount of calls to the global table lua has to perform,
-- speeding up performance greatly (Sometimes as much as ~30%, per lua.org/gems/sample.pdf)
-- So, throughout this codebase we'll use this convention to export local values as a matter of habit.

local d = {}

-------------------------------------------------
-- Things controlled by mod settings options   --
-------------------------------------------------

-- Radius at which the searchlight beam detects foes
d.lightRadiusSetting = "searchlight-assault-setting-light-radius"
d.defaultSearchlightSpotRadius = 4
d.searchlightSpotRadius = d.defaultSearchlightSpotRadius

-- Max distance at which the searchlight looks for same-force turrets to boost the range of
-- This should mostly only be able to capture adjacent turrets of up to 3x3 size
-- We can try making this bigger to capture bigger / non-square turrets
-- (Or users can use the mod settings option to set it themselves)
d.maxNeighborDistanceSetting = "searchlight-assault-max-neighbor-boost-distance"
d.defaultSearchlightMaxNeighborDistance = 1
d.searchlightMaxNeighborDistance = d.defaultSearchlightMaxNeighborDistance


-- This check is necessary for when this file gets referenced prior to prototype stage
if settings then 
  d.searchlightSpotRadius = settings.startup[d.lightRadiusSetting].value
  d.searchlightMaxNeighborDistance = settings.startup[d.maxNeighborDistanceSetting].value
end


-----------------------------
-- Gameplay-related tweaks --
-----------------------------

-- Max range at which search light beam wanders
-- (About the same size as the radar's continuous reveal,
--  since the searchlight is built from a radar)
d.searchlightRange = 100

-- Distance from foes at which the searchlight leaves 'safe' mode and starts looking for foes
d.searchlightSafeRange = d.searchlightRange + 10

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

-- If a searchlight's spotter doesn't fire by this many ticks,
-- we'll put that searchlight back into safe mode
d.searchlightSafeTime = 5 * 60


-------------------------------------------------
-- Things that aren't easy to mess with --
-------------------------------------------------

-- Speeds at which searchlight beam wanders / responds to circuit commands
d.searchlightWanderSpeed = 0.1

d.searchlightRushSpeed = 0.13  -- Just barely slower than base player speed

-- How slow the searchlight spins while in safe mode (idle)
d.idleSpinRate = 0.125
d.spinFrames = 64
d.spinFactor = (d.spinFrames/d.idleSpinRate)
-- If spinFactor is set too low (less than 21), Safe Mode might fail to be entered


-------------------------------------------------
-- Really boring stuff                         --
-------------------------------------------------

-- Player-Visible entity, item, recipe names
-- Any updates to these names must be reflected in the locale config.cfg files
d.searchlightItemName = "searchlight-assault"
d.searchlightRecipeName = "searchlight-assault"
d.searchlightTechnologyName = "searchlight-assault"

d.searchlightBaseName = "searchlight-assault-base"
d.searchlightSafeName = "searchlight-assault-safe"
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
d.boostHaze = "searchlight-boost-haze"

-- Force name-suffix, to be appended to the name of the force that owns a searchlight
d.turtleForceSuffix = "_SLATurtle"

-- Identifies range boosted versions of turrets
d.boostSuffix = "-sla_boosted"

-- Mod settings keys
-- d.lightRadiusSetting = defined above
d.ignoreEntriesList = "searchlight-assault-setting-ignore-entries-list"
d.uninstallMod      = "searchlight-assault-uninstall"
d.overrideAmmoRange = "searchlight-assault-override-ammo-range"
d.enableLightAnimation = "searchlight-assault-enable-light-animation"
d.enableBoostGlow   = "searchlight-assault-enable-boost-glow"
d.alarmColorDefault = "searchlight-assault-alarm-color"
d.warnColorDefault  = "searchlight-assault-warn-color"
d.safeColorDefault  = "searchlight-assault-safe-color"

-- Shortcut/Custom Input/GUI keys
d.openSearchlightGUI = "sla_gui_open_shortcut"
d.closeSearchlightGUI = "sla_gui_close_shortcut"
d.closeSearchlightGUIalt = "sla_gui_close_shortcut_alt"
d.guiName = "sla_sl_gui_main"
d.guiClose = "sla_sl_gui_close"

-- Default color settings
d.warnColorDefault  = "250,190,0,230"
d.alarmColorDefault = "230,25,25,230"
d.safeColorDefault  = "20,230,20,230"


-- The circuit network slots are used in the hidden-combinator entity 
-- to express which signals map to which concepts.
d.circuitSlots = {
  radiusSlot = 1,
  rotateSlot = 2,
  minSlot    = 3,
  maxSlot    = 4,
  dirXSlot   = 5,
  dirYSlot   = 6,

  ownPositionXSlot = 11,
  ownPositionYSlot = 12,
  warningSlot      = 13,
  alarmSlot        = 14,
  foePositionXSlot = 15,
  foePositionYSlot = 16,
}

return d
