-- Force names
searchlightFoe = "hddnSLFoe"
searchlightFriend = "hddnSLFnd"

-- Range at which search light auto-spots foes
--searchlightInnerRange = 40
searchlightInnerRange = 10

-- Max range at which search light wanders (and possibly spots foes)
-- (About the same size as the radar's continuous reveal, 
--  which seems fair, since the light's built from a radar)
--searchlightOuterRange = 100
searchlightOuterRange = 40

-- Speed at which spotlight wanders
searchlightWanderSpeed = 0.07

-- Speed at which spotlight tracks a spotted foe
searchlightTrackSpeed = 0.8

icon =
{
    filename = "__Searchlights__/graphics/terrible2.png",
    icon_size = 82
}

yellowSpotlightColor = {r = 0.7, g = 0.7, b = 0, a = 0.8}
redSpotlightColor = {r = 1, g = 0.2, b = 0.2, a = 1}