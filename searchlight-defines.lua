-- Force names
searchlightFoe = "hddnSLFoe"
searchlightFriend = "hddnSLFnd"

-- Range at which search light auto-spots foes
searchlightInnerRange = 40

-- Max range at which search light wanders (and possibly spots foes)
-- (About the same size as the radar's continuous reveal,
--  which seems fair, since the light's built from a radar)
searchlightOuterRange = 100

-- Radius at which the spotlight beam detects foes
searchlightSpotRadius = 1.5

-- Radius at which the spotlight beam boosts the range of friends
searchlightFriendRadius = 15

-- Speed at which spotlight wanders
searchlightWanderSpeed = 0.5

-- Speed at which spotlight tracks a spotted foe
searchlightTrackSpeed = 1.5

-- Identifies range boosted versions of turrets
boostSuffix = "-sl_boosted"

-- Range boost for electric turrets
elecBoost = searchlightOuterRange

-- Range boost for ammo turrets
ammoBoost = searchlightOuterRange - 20

-- Range boost for fluid turrets
fluidBoost = searchlightOuterRange - 40
