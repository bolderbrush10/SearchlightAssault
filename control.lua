require "searchlight-defines"

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

local searchLights = {}

-- TODO Maintain a map of all searchlights instead of polling for them every tick
-- (And update it w/ onEvent(building built, etc) + rebuild it on startup or use engine to save/load it)

script.on_event(defines.events.on_tick, function(event)
    -- for surfaceName, surface in pairs(game.surfaces) do
    --     searchLights = surface.find_entities_filtered{name = "searchlight"}
    -- 
    --     for index, sl in pairs(searchLights) do            
    --         LightUpFoes(sl, surface)
    --     end
    -- end
end)


-- 'sl' for 'SearchLight' 
function LightUpFoes(sl, surface)
    -- Instantly find foes within the inner range
    local nearestFoe = surface.find_nearest_enemy{position = sl.position, 
                                                  max_distance = searchlightInnerRange}
    
    if nearestFoe ~= nil then
        local lightID = renderSpotLight_red(nearestFoe.position, sl, surface)
        
        sl.shooting_target = nearestFoe
        return 
    end
    
    -- If we're not directly shining on a foe, make up a random waypoint to track the light towards
    
    local wanderPos = makeWanderWaypoint(sl.position)
    local lightID = renderSpotLight_def(wanderPos, sl, surface)
end

function makeLightStartLocation(sl)
    -- TODO get the orientation of the light and stick this slightly in front
    --      also figure out how to deal with the unfolding animation
    return sl.position
end

function makeWanderWaypoint(origin)
    -- make it easier to find the light for now
    -- x = origin.x + math.random(-searchlightOuterRange, searchlightOuterRange)
    -- y = origin.y + math.random(-searchlightOuterRange, searchlightOuterRange)
    
    local waypoint = {x = origin.x + math.random(-searchlightInnerRange, searchlightInnerRange),
                      y = origin.y + math.random(-searchlightInnerRange, searchlightInnerRange)}

    return waypoint
end

-- TODO Test speed on this vs engine pathfinder w/ noclip
-- TODO This seems buggy as heck, test it
function moveTowards(currPos, destPos, speed)
    local vec = {x = destPos.x - currPos.x,
                 y = destPos.y - currPos.y}
                 
    local distance = len(currPos, destPos)
    
    local norm = {x = 0, y = 0}
    
    if distance ~= 0 then
        norm.x = vec.x / distance
        norm.y = vec.y / distance
    end
    
    -- TODO stop overshooting
    local newPos = {x = currPos.x + (speed * norm.x),
                    y = currPos.y + (speed * norm.y)}
    
    return newPos
end

function makeMoveCommand(destination)
    local newCommand = defines.command
    newCommand.type = defines.command.go_to_location
    newCommand.destination = destination
    return newCommand
end

-- TODO trade accuracy for speed
function len(a, b)
    return math.sqrt((a.x - b.x)^2 + (a.y - b.y)^2)
end

-- 'def' for 'default color'
function renderSpotLight_def(position, sl, surface)
    return renderSpotLight(position, sl, surface, nil)
end

function renderSpotLight_yel(position, sl, surface)
    return renderSpotLight(position, sl, surface, yellowSpotlightColor)
end

function renderSpotLight_red(position, sl, surface)
    return renderSpotLight(position, sl, surface, redSpotlightColor)
end

function renderSpotLight(position, sl, surface, colorparam)
    return rendering.draw_light{target = position,
                                orientation = sl.orientation,
                                surface = surface,
                                sprite = "spotLightSprite",
                                scale = 2,
                                intensity = 0.3,
                                time_to_live = 5,
                                color = colorparam}
end
