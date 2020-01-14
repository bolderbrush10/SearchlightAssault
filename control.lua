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
-- TODO Organize forces and turrets such that we don't get 'turret firing at enemy' alert for no good reason,
--      but we still show up in stastics under the 'P' and 'K' menus
-- TODO placement of light during 'unfolding' animation
-- TODO Wait for a small delay after turret creation to start lighting things up / remove the 'unfolding' animation so that way the turret always lines up with the light-effect from the first moment of existance

local searchLights = {}
local lightEntities = {} -- not actual entites but roll with it for now

-- TODO Maintain a map of all searchlights instead of polling for them every tick
-- (And update it w/ onEvent(building built, etc) + rebuild it on startup or use engine to save/load it)

script.on_event(defines.events.on_tick, function(event)
    -- TODO move to init function
    if game.forces[searchlightFoe] == nil then
        game.create_force(searchlightFoe)
        
        game.forces["player"].set_cease_fire(searchlightFoe, true)
        
        game.forces[searchlightFoe].set_cease_fire("player", true)
        
        if game.forces[searchlightFriend] == nil then
            game.create_force(searchlightFriend)
        end
        game.forces[searchlightFoe].set_cease_fire(searchlightFriend, true)
        game.forces[searchlightFriend].set_cease_fire(searchlightFoe, false)
        game.forces[searchlightFriend].set_friend("player", true)
    end

    for surfaceName, surface in pairs(game.surfaces) do
        searchLights = surface.find_entities_filtered{name = "searchlight"}

        for index, sl in pairs(searchLights) do
            -- TODO do this in onEntityBuilt or something. Should probably find a better technique though...
            sl.force = searchlightFriend
            
            LightUpFoes(sl, surface)
        end
    end
end)


-- TODO interpolate from wander position to nearest foe instead of snapping over, etc
-- TODO destroy hidden entities when sl is destroyed / removed etc
-- TODO spotlight should probably only wander a 180degree arc around its inital placement
-- TODO disable when no electricity / reduce range according to electric satisfaction
-- 'sl' for 'SearchLight' 
function LightUpFoes(sl, surface)
    -- Instantly find foes within the inner range
    local nearestFoe = surface.find_nearest_enemy{position = sl.position, 
                                                  max_distance = searchlightOuterRange}
    
    if nearestFoe ~= nil then
        local lightID = renderSpotLight_red(nearestFoe.position, sl, surface)
        lightEntities[sl.unit_number] = {lightID = lightID,
                                         position = nearestFoe.position,
                                         waypoint = nearestFoe.position}
        sl.shooting_target = nearestFoe
        -- TODO move light entity to this foe's location
        return 
    else
        return
    end
    
    -- If we're not directly shining on a foe, make up a random waypoint to track the light towards
    
    if lightEntities[sl.unit_number] == nil then
        local wanderPos = makeWanderWaypoint(sl.position)
        local lightID = renderSpotLight_def(wanderPos, sl, surface)
        lightEntities[sl.unit_number] = {lightID = lightID,
                                         position = makeLightStartLocation(sl),
                                         waypoint = wanderPos}
                                         
        -- flicker the spotlight at the new location so we can see what we're doing
        -- TODO remove this flicker when development is done
        renderSpotLight_red(lightEntities[sl.unit_number].waypoint, sl, surface)
        return
    end
    
    -- If the light has gotten close enough to waypoint, make a new waypoint
    -- (Using distances smaller than 3 will fail.
    --  The game engine's pathfinding for entities is a 'close enough' kind of thing)
    if len(lightEntities[sl.unit_number].position,
           lightEntities[sl.unit_number].waypoint) < 3 then
        lightEntities[sl.unit_number].waypoint = makeWanderWaypoint(sl.position)
    
        if lightEntities[sl.unit_number].entity then
            lightEntities[sl.unit_number].entity.set_command(makeMoveCommand(lightEntities[sl.unit_number].waypoint))
        end
         
        -- flicker the spotlight at the new location so we can see what we're doing
        -- TODO remove this flicker when done developing
        renderSpotLight_red(lightEntities[sl.unit_number].waypoint, sl, surface)
    end
            
    local newPosition = moveTowards(lightEntities[sl.unit_number].position,
                                    lightEntities[sl.unit_number].waypoint,
                                    searchlightTrackSpeed)
    
    if lightEntities[sl.unit_number].entity == nil then
        -- TODO invisible target w/ noclip or something
        
        -- TODO Why the heck were we doing this?
        -- Just to move ourselves out of the turret, right?
        local positionCopyTEMP = newPosition
        positionCopyTEMP.x = positionCopyTEMP.x + 4
        
        local newEnt = surface.create_entity{name = "SpotlightShine", 
                                             position = positionCopyTEMP,
                                             force = searchlightFoe}
    
        sl.shooting_target = newEnt
    
        lightEntities[sl.unit_number].entity = newEnt
        newEnt.set_command(makeMoveCommand(lightEntities[sl.unit_number].waypoint))
    end
    
    -- TODO this line crashes if the hidden entity is killed, so make sure its invulnerable and cleaned up properly
    local lightID = renderSpotLight_def(lightEntities[sl.unit_number].entity.position, sl, surface)
    lightEntities[sl.unit_number].lightID = lightID
    lightEntities[sl.unit_number].position = lightEntities[sl.unit_number].entity.position
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
