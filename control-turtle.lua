require "control-common"
require "sl-defines"
require "sl-util"


function TurtleWaypointReached(unit_number)
    WanderTurtle(global.turtles[unit_number], global.turtle_to_baseSL[unit_number].position)
end


-- location is expected to be the spotlight's last shooting target,
-- if it was targeting something.
function SpawnTurtle(baseSL, attackLight, surface, location)
  if location == nil then
    -- Start in front of the turret's base, wrt orientation
    location = OrientationToPosition(baseSL.position, baseSL.orientation, 3)
  end

  local turtle = surface.create_entity{name = turtleName,
                                       position = location,
                                       force = searchlightFoe,
                                       fast_replace = true,
                                       create_build_effect_smoke = false}

  turtle.destructible = false
  attackLight.shooting_target = turtle


  -- If we set our first waypoint in the same direction, but further away,
  -- it makes a cool 'windup' effect as the searchlight is made
  local windupWaypoint = OrientationToPosition(baseSL.position,
                                               baseSL.orientation,
                                               math.random(searchlightOuterRange / 8,
                                                           searchlightOuterRange - 2))

  WanderTurtle(turtle, baseSL.position, windupWaypoint)

  return turtle
end


function WanderTurtle(turtle, origin, waypoint)
  local tun = turtle.unit_number

  if waypoint == nil then
    waypoint = MakeWanderWaypoint(origin)
  end
  turtle.speed = 0.1

  turtle.set_command({type = defines.command.go_to_location,
                      -- TODO Do we want to make it an option to allow spotting non-military foe-built structures?
                      distraction = defines.distraction.by_enemy,
                      destination = waypoint,
                      pathfind_flags = {low_priority = true,
                                        cache = false,
                                        -- prefer_straight_paths = true, -- TODO Report as bug? Does the opposite of what it says
                                        allow_destroy_friendly_entities = true,
                                        allow_paths_through_own_entities = true},
                      radius = 1
                     })
end


function MakeWanderWaypoint(origin)
  -- Since the turtle has to 'chase' foes it spots, we don't want it to wander
  -- too close to the max range of the spotlight
  local bufferedRange = searchlightOuterRange - 5
   -- 0 - 1 inclusive. If you supply arguments, math.random will return ints not floats.
  local angle = math.random()
  local distance = math.random(searchlightOuterRange/8, bufferedRange)

  return OrientationToPosition(origin, angle, distance)
end


function Turtleport(turtle, position, origin)
  -- TODO If position is too far from the origin for the searchlight to attack it,
  --      calculate a slightly-closer position with the same angle and use that

  if not turtle.teleport(position) then
    -- TODO The teleport failed for some reason, so respawn a fresh turtle and update maps
    game.print("Teleport failed")
  end
end