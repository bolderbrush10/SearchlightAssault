-- Be sure to declare functions and vars as 'local' in prototype / data*.lua files,
-- because other mods may have inadvertent access to functions at this step.

-- TODO Should I worry about other mods interfering with these non-local vars?
--      How can I prevent it while letting files share...
--      Maybe say "defines = {}" and "return defines"

-----------------------------
-- Gameplay-related tweaks --
-----------------------------

-- Max range at which search light beam wanders
-- (About the same size as the radar's continuous reveal,
--  since the searchlight is built from a radar)
searchlightRange = 100

-- Max distance at which the spotlight boosts the range of same-force turrets (using a square grid)
-- At 1.5, this range is virtually 'adjacent-only'
searchlightBoostEffectRange = 1.5

-- Range boost effect provided to friendly turrets so they can attack the distant foe the searchlight spotted
-- (Should equal the maximum spotting radius + maximum distance of a boostable friend from the searchlight.
--  Since the maximum distance a boostable friend can be might not be a whole number, thanks to trigonometry,
--  we'll just double that factor to keep it simple. (If we care, we can use something like:
--   math.ceil(squareroot(square(searchlightBoostEffectRange) + square(searchlightBoostEffectRange)))
--  to get a more accurate figure)
rangeBoostAmount = searchlightRange + searchlightBoostEffectRange*2

-- Capacitor size (electric energy buffer) for the searchlight
-- (The searchlight requires a partial-buffer to start operating, and turns back off when the buffer is below the cutoff)
-- ((We use this to reduce pathological "flickering" cases when a factory is in low power,
--   and we'd otherwise need to constantly enable / disable the hidden entities that make the searchlight work))
searchlightCapacitorSize      = "5MJ"
searchlightCapacitorCutoff    =   250000 -- joules
searchlightCapacitorStartable =  2500000 -- joules

-- How much electricity the searchlight consumes
-- (I think it's cute to have its usage be the sum of its parts)
searchlightEnergyUsage = "327kW"

-------------------------------------------------
-- Things that aren't interesting to mess with --
-------------------------------------------------

-- Radius at which the spotlight beam detects foes
-- Setting vision distance too low can cause turtles to get stuck in their foes
-- Actual search radius will be reduced to 80% to make moving foes slightly harder to spot
searchlightSpotRadius = 3

-- Speed at which spotlight beam wanders
-- There is a maximum speed which you cannot exceed or else the turtle
-- has a high chance to run inside the collision box of an enemy before
-- it has a chance to fire its attack. This results in the turtle getting
-- 'stuck' without attacking, and thus results in us having to rely on the
-- ai_command_complete event fired when the distraction attack-event is done
-- (which is a process that is seemingly-impossible to speed up)
searchlightWanderSpeed = 0.2

-- Amount of time in milliseconds from when a spotlight becomes suspicious
-- until the spotlight confirms it has spotted a foe
searchlightSpotTime_ms = 1.5 * 60

-- Delay in ticks between boosting and unboosting friends
-- (game runs at 60 ticks per second)
boostDelay = 3 * 60

-------------------------------------------------
-- Really boring stuff                         --
-------------------------------------------------

-- Effect, Entity, item, recipe names
-- (These need to copied manually into the locale files as far as I can tell)
searchlightItemName = "searchlight"
searchlightRecipeName = "searchlight"
searchlightTechnologyName = "searchlight"

searchlightBaseName = "searchlight-base"
searchlightAlarmName = "searchlight-alarm"
searchlightControllerName = "searchlight-control"
turtleName = "searchlight-turtle"

searchlightWatchLightSpriteName = "SpotlightWarningLightSprite"

spottedEffectID = "searchlight-spotted-effect"

-- Force names (To be appended to the name of the force that owns a spotlight)
turtleForceSuffix = "_SLTurtle"

-- Trigger Target Mask names
turtleMaskName = "spotlight-turtle"

-- Identifies range boosted versions of turrets
boostSuffix = "-sl_boosted"
