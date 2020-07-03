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
