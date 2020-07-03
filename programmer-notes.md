Strings which would be first-class types in a real programming language:

"small-searchlight"


-- Plan: 
-- Leave the searchlight 'on' until it wanders over an enemy
-- Set the turret prepare range to max distance when it finds an enemy,
-- set its target to that enemy
-- (Enables the 'yellow light' prepare animation)
-- Slow down wandering significantly
-- Set the spotlight entity to yellow
-- After 2 seconds, set the turret range to max
-- (Enables the 'red light' attack animation)
-- Set the spotlight entity to red


-- TODO energy cost
-- TODO make use of new feature from patch notes: - Added optional lamp prototype property "always_on".

-- TODO Maintain a map of all searchlights instead of polling for them every tick
-- (And update it w/ onEvent(building built, etc) + rebuild it on startup or use engine to save/load it)

-- Might want to figure out how to use the 'alert_when_attacking' characteristic such that we alert when real foes are present, and not imaginary ones
-- also look into:
--  allow_turning_when_starting_attack
--  attack_from_start_frame


function makeLightStartLocation(sl)
    -- TODO get the orientation of the light and stick this slightly in front
    --      also figure out how to deal with the unfolding animation

    
-- TODOOOOOOOOOOOOOO
-- use the 'target_type' : position parameter and work from that.
-- (How will rotating the turret work? Will we still need a hidden entity for the turret to target?)

-- TODO Append data to 'global' to have the game save / load data for us
-- TODO placement of light during 'unfolding' animation
-- TODO Wait for a small delay after turret creation to start lighting things up / remove the 'unfolding' animation so that way the turret always lines up with the light-effect from the first moment of existance
-- TODO interpolate from wander position to nearest foe instead of snapping over, etc
-- TODO disable when no electricity / reduce range according to electric satisfaction
-- TODO Use the beam prototype's ground_light_animations and light_animations 'start / ending / head / tail / body' effects

-- STRETCH GOALS
-- Spotlight position & color controlled by circuit signals
-- Spotlight emits detection info to circuit network
-- Spotlight could possibly be set to only wander a 180degree arc around its inital placement?
-- Use the 'TriggerEffect' prototype to play an alert sound if an enemy is detected? Looks like we can set it to play the sound at the 'source' aka the turret itself
    -- We can also create a sticker or particle, which could be fun for making "!" float above the turret's head or something.
    -- (Or Maybe cool flares could shoot out and form a '!'?)



=================

Feature request for spotlights that track enemies



Or just write a mod to do it, yourself

- Steal code from this other mod? [MOD 0.10.x] Advanced Illumination - 0.2.0 [BETA]
  https://forums.factorio.com/viewtopic.php?f=14&t=4872


Features:

- Alternate idea: Has a massive sight range, and a moderate effect range.
  Allows all turrets within effect range to fire at 1/8th fire rate (like, once per second) at anything within its sight range.
  
- Changes from white -> yellow -> infrared as it spots an enemy and 'locks on'
  (Be sure to have a cool 'lock on effect' when this finally happens)

- Half the range of the radar's 'discovery' range 
  (or like, 2x as far as the active sight range)
  
- Gives radar-like map "remote vision" on targeted area

- Very high power cost 
  (Maybe like 10x solar panels' worth per? 
   Then again, we want to be an early-game alternative for night vision goggles...)
   
- Pretty large - maybe should appear to be on a tower light the large electric pole?

- Multiple spotlights prefer to target different enemies

- Checkbox to allow 'patrol mode' pattern when no enemies in range are known
  (Recreate your favorite prison-break movie / game! Like WindWaker!)

- Infrared-seeking mode that only targets players & vehicles
  (Implies that biters are endothermic, which is neat)
  
- Built from 5x lamp + 1x Radar (since it's able to target things)
  - Finally gives an incentive to automate lamp production for non-peaceful players

