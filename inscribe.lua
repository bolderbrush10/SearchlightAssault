require "searchlight-defines"

local lightEntities = {} -- not actual entites but roll with it

function InscribeStatanicPentagram(sl, surface) -- 'sl' for 'SearchLight'    
    -- Instantly find foes within the inner range
    local nearestFoe = surface.find_nearest_enemy{position = sl.position, 
                                                  max_distance = searchlightInnerRange}

    if nearestFoe ~= nil then
        local lightID = renderSpotLight_red(nearestFoe.position, sl, surface)
        lightEntities[sl.unit_number] = {lightID = lightID,
                                         position = nearestFoe.position,
                                         waypoint = nearestFoe.position,
                                         entity = nil}
        return 
    end
    
    -- If the light has gotten close enough to waypoint, make a new waypoint
    if len(lightEntities[sl.unit_number].position, 
           lightEntities[sl.unit_number].waypoint) < 5 then
        lightEntities[sl.unit_number].waypoint = makeWanderWaypoint(sl.position)
    end
            
    local newPosition = moveTowards(lightEntities[sl.unit_number].position,
                                    lightEntities[sl.unit_number].waypoint,
                                    searchlightTrackSpeed)
    
    -- kill any old target entities
    if lightEntities[sl.unit_number].entity ~= nil then
        lightEntities[sl.unit_number].entity.die()
    end
    
    -- use small-biter + high speed + die every tick to create satanic pentagrams
    lightEntities[sl.unit_number].entity = surface.create_entity{name = "small-biter", 
                                                                 position = newPosition,
                                                                 force="neutral"}
    
    -- TODO face turret towards light or use a beacon model instead
    sl.shooting_target = lightEntities[sl.unit_number].entity

    local lightID = renderSpotLight_red(newPosition, sl, surface)
    lightEntities[sl.unit_number].lightID = lightID
    lightEntities[sl.unit_number].position = newPosition
end

function makeWanderWaypoint(origin)
    -- make it easier to find the light for now
    -- x = origin.x + math.random(-searchlightOuterRange, searchlightOuterRange)
    -- y = origin.y + math.random(-searchlightOuterRange, searchlightOuterRange)
    
    local waypoint = {x = origin.x + math.random(-searchlightInnerRange, searchlightInnerRange),
                      y = origin.y + math.random(-searchlightInnerRange, searchlightInnerRange)}

    return waypoint
end

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

-- TODO trade accuracy for speed
function len(a, b)
    return math.sqrt((a.x - b.x)^2 + (a.y - b.y)^2)
end

function renderSpotLight_red(position, sl, surface)
    return rendering.draw_light{target = position,
                                orientation = sl.orientation,
                                surface = surface,
                                sprite = "spotLightSprite",
                                scale = 2,
                                intensity = 0.3,
                                time_to_live = 5,
                                color = redSpotlightColor}
end
