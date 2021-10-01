local d = require "sl-defines"
local u = require "sl-util"

require "control-common"
require "control-forces"


-- TODO Account for commandFailed
function TurtleWaypointReached(unit_number, commandFailed)
  local g = global.unum_to_g[unit_number]

  if g.turtleCoord == nil then
    WanderTurtle(g.turtle, g.base.position)
    g.base.shooting_target = g.turtle -- retarget turtle just in case something happened
  else
    g.turtle.set_command({type = defines.command.stop,
                          distraction = defines.distraction.by_anything,
                         })
  end
end

function TurtleDistracted(unit_number, commandFailed)
  -- TODO if a turtle gets distracted, re-issue it's goto command n times,
  --      or figure out what entity it was trying to attack and manually fire the
  --      attack_trigger event there and remove the turtle

  -- TODO Start tracking the turtle in global[] + count of failed commands
  --      We'll want to check every tick in control-searchlight
  --      if it's left its searchlight radius,
  --      and we'll want to check if we need to manually-kick off a WatchCircle
end


-- location is expected to be the spotlight's last shooting target,
-- if it was targeting something.
function SpawnTurtle(baseSL, surface, location)
  if location == nil then
    -- Start in front of the turret's base, wrt orientation
    location = u.OrientationToPosition(baseSL.position, baseSL.orientation, 3)
  end

  local turtle = surface.create_entity{name = d.turtleName,
                                       position = location,
                                       force = PrepareTurtleForce(baseSL.force),
                                       fast_replace = true,
                                       create_build_effect_smoke = false}

  turtle.destructible = false
  baseSL.shooting_target = turtle

  -- If we set our first waypoint in the same direction, but further away,
  -- it makes the searchlight appear to "start up"
  local windupWaypoint = u.OrientationToPosition(baseSL.position,
                                               baseSL.orientation,
                                               math.random(d.searchlightRange / 8,
                                                           d.searchlightRange - 2))

  WanderTurtle(turtle, baseSL.position, windupWaypoint)

  return turtle
end


function WanderTurtle(turtle, origin, waypoint)
  local tun = turtle.unit_number

  if waypoint == nil then
    waypoint = MakeWanderWaypoint(origin)
  end
  turtle.speed = d.searchlightWanderSpeed

  turtle.set_command({type = defines.command.go_to_location,
                      -- TODO Do we want to make it an option to allow spotting non-military foe-built structures?
                      distraction = defines.distraction.by_enemy,
                      destination = waypoint,
                      pathfind_flags = {low_priority = true,
                                        cache = false,
                                        allow_destroy_friendly_entities = true,
                                        allow_paths_through_own_entities = true},
                      radius = 1
                     })
end


function MakeWanderWaypoint(origin)
  -- Since the turtle has to 'chase' foes it spots, we don't want it to wander
  -- too close to the max range of the spotlight
  local bufferedRange = d.searchlightRange - 5
   -- 0 - 1 inclusive. If you supply arguments, math.random will return ints not floats.
  local angle = math.random()
  local distance = math.random(d.searchlightRange/8, bufferedRange)

  return u.OrientationToPosition(origin, angle, distance)
end


function Turtleport(turtle, position, origin)
  local bufferedRange = d.searchlightRange - 2

  -- If position is too far from the origin for the searchlight to attack it,
  -- calculate a slightly-closer position with the same angle and use that
  if not u.WithinRadius(position, origin, bufferedRange) then
    local vecOriginPos = {x = position.x - origin.x,
                          y = position.y - origin.y}

    local theta = math.atan2(vecOriginPos.y, vecOriginPos.x)
    position = u.ScreenOrientationToPosition(origin, theta, bufferedRange)
  end

  if not turtle.teleport(position) then
    -- The teleport failed for some reason, so respawn a fresh turtle and update maps

    local g = global.turtle_to_gestalt[turtle.unit_number]
    local newT = SpawnTurtle(g.base, g.base, g.base.surface)

    maps_updateTurtle(turtle, newT)

    log("[Searchlights Mod] Error! Please report to mod author with before & after saves. " ..
        "Teleport of hidden entity failed. Old Unit Number: " ..
        turtle.unit_number .. " New Unit Number: " .. newT.unit_number ..
        " Target Position: " .. position.x .. ", " .. position.y)

    turtle.destroy()
  end
end


function ManualTurtleMove(gestalt, coord)
  local bufferedRange = d.searchlightRange - 5

  -- Clamp excessive ranges so the turtle doesn't go past the searchlight max radius
  if u.lensquared(coord, {x=0, y=0}) > u.square(bufferedRange) then
    local old = coord
    coord = u.ClampCoordToDistance(coord, bufferedRange)
  end

  local translatedCoord = coord
  translatedCoord.x = translatedCoord.x + gestalt.base.position.x
  translatedCoord.y = translatedCoord.y + gestalt.base.position.y

  -- TODO Could probably keep an 'original coord' to compare against to save cycles
  if gestalt.turtleCoord == nil
     or translatedCoord.x ~= gestalt.turtleCoord.x
     or translatedCoord.y ~= gestalt.turtleCoord.y then

    gestalt.turtleCoord = translatedCoord

    gestalt.turtle.speed = d.searchlightRushSpeed
    gestalt.turtle.set_command({type = defines.command.go_to_location,
                                distraction = defines.distraction.by_enemy,
                                destination = gestalt.turtleCoord,
                                pathfind_flags = {low_priority = true,
                                                  cache = false,
                                                  allow_destroy_friendly_entities = true,
                                                  allow_paths_through_own_entities = true},
                                radius = 1
                               })
  end
end
