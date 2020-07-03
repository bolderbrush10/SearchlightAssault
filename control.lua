require "searchlight-defines"

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
