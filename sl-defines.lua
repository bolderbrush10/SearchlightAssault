-- Be sure to declare functions and vars as 'local' in prototype / data*.lua files,
-- because other mods may have inadvertent access to functions at this step.

-- TODO Should I worry about other mods interfering with these non-local vars?
--      How can I prevent it while letting files share...
--      Maybe say "defines = {}" and "return defines"

--------------------------------
-- Performance-related tweaks --
--------------------------------

-- Tweak how frequently searchlights run a search for nearby enemies
-- (0 means run search every tick,
--  60 means run search once every 60 ticks (aka once a second),
--  etc)
ticksBetweenFoeSearches = 60


-----------------------------
-- Gameplay-related tweaks --
-----------------------------

-- Max range at which search light beam wanders
-- (About the same size as the radar's continuous reveal,
--  since the search light is built from a radar)
-- TODO rename to just 'searchlightRange'
searchlightOuterRange = 100

-- Radius at which the spotlight boosts the range of same-force turrets
-- TODO rework this to use a range based on a square-grid of tiles
searchlightFriendRadius = 15

-- Range boost given to electric turrets
-- TODO Consider making all the boosts at the max range
--      so that it makes sense to be spotted and then get shot at
elecBoost = searchlightOuterRange

-- Range boost given to ammo turrets
ammoBoost = searchlightOuterRange - 20

-- Range boost given to fluid turrets
fluidBoost = searchlightOuterRange - 40

-- Capacitor size (electric energy buffer) for the searchlight
-- (The searchlight requires a half-full buffer to start operating, and turns back off when the buffer is below the cutoff)
-- ((We use this to reduce pathological "flickering" cases when a factory is in low power,
--   and we'd otherwise need to constantly enable / disable the hidden entities that make the searchlight work))
searchlightCapacitorSize    =  "5MJ"
searchlightCapacitorCutoff     = 250000 -- joules
searchlightCapacitorStartable = 2500000 -- joules

-- How much electricity the searchlight consumes
searchlightEnergyUsage = "305kW"

-------------------------------------------------
-- Things that aren't interesting to mess with --
-------------------------------------------------

-- Radius at which the spotlight beam detects foes
-- Setting vision distance too low can cause turtles to get stuck in their foes
searchlightSpotRadius = 3

-- Speed at which spotlight beam wanders
-- There is a maximum speed which you cannot exceed or else the turtle
-- has a high chance to run inside the collision box of an enemy before
-- it has a chance to fire its attack. This results in the turtle getting
-- 'stuck' without attacking, and thus results in us having to rely on the
-- ai_command_complete event fired when the distraction attack-event is done
-- (which is a process that is seemingly-impossible to speed up).
searchlightWanderSpeed = 0.2

-- Speed at which spotlight beam tracks a spotted foe
-- The player character moves at running_speed = 0.15,
-- so ideally we want to be just a tad slower than that
-- so there's a chance they can escape
searchlightTrackSpeed = 1.3

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

searchlightBaseName = "searchlight-base"
searchlightAttackName = "searchlight-attack"
turtleName = "searchlight-turtle"

spottedEffectID = "searchlight-spotted-effect"

-- Force names
searchlightFoe = "hddnSLFoe"
searchlightFriend = "hddnSLFnd"

-- Trigger Target Mask names
turtleMaskName = "spotlight-turtle"

-- Identifies range boosted versions of turrets
boostSuffix = "-sl_boosted"
