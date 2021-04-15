-- TODO Should I worry about other mods interfering with these non-local vars?

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

-- Range at which search light turret auto-spots foes
searchlightInnerRange = 40

-- Max range at which search light beam wanders (and possibly spots foes)
-- (About the same size as the radar's continuous reveal,
--  which seems fair, since the light's built from a radar)
searchlightOuterRange = 100

-- Radius at which the spotlight turret boosts the range of friends
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
searchlightCapacitorSize     = "9500kJ"
searchlightCapacitorCutoff     = 500000 -- joules
searchlightCapacitorStartable = 4750000 -- joules

-- How much electricity the searchlight consumes
searchlightEnergyUsage = "305kW"

-------------------------------------------------
-- Things that aren't interesting to mess with --
-------------------------------------------------

-- Radius at which the spotlight beam detects foes
searchlightSpotRadius = 1.5

-- Speed at which spotlight beam wanders
searchlightWanderSpeed = 0.2

-- Speed at which spotlight beam tracks a spotted foe
searchlightTrackSpeed = 1.3

-- Force names
searchlightFoe = "hddnSLFoe"
searchlightFriend = "hddnSLFnd"

-- Trigger Target Mask names
turtleMaskName = "spotlight-turtle"

-- Identifies range boosted versions of turrets
boostSuffix = "-sl_boosted"

-- Delay in ticks between boosting and unboosting friends
-- (game runs at 60 ticks per second)
boostDelay = 3 * 60
