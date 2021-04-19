require "control-common"
require "defines"
require "util"

-- location is expected to be the spotlight's last shooting target,
-- if it was targeting something.
function SpawnTurtle(baseSL, attackSL, surface, location)
  if location == nil then
    -- Start in front of the turret's base, wrt orientation
    location = OrientationToPosition(baseSL.position, baseSL.orientation, 1)
  end

  local turtle = surface.create_entity{name = turtleName,
                                       position = location,
                                       force = searchlightFoe,
                                       fast_replace = true,
                                       create_build_effect_smoke = false}

  turtle.destructible = false
  attackSL.shooting_target = turtle

  global.tun_to_baseSL[turtle.unit_number] = baseSL
  global.baseSL_to_turtle[baseSL.unit_number] = turtle

  -- If we set our first waypoint in the same direction, but further away,
  -- it makes a cool 'windup' effect as the searchlight is made
  -- TODO Somehow pause the turtle before it leaves / sync it with the searchlight capacitor filling up
  -- use defines.command.compound to chain commands, along with defines.command.wander + ticks_to_wait + radius
  local windupWaypoint = OrientationToPosition(baseSL.position,
                                               baseSL.orientation,
                                               math.random(searchlightOuterRange / 8,
                                                           searchlightOuterRange - 2))

  WanderTurtle(turtle, baseSL.position, windupWaypoint)

  return turtle
end


function WanderTurtle(turtle, origin, waypoint)
  local tun = turtle.unit_number

  if not turtle.has_command()
     or global.turtle_to_waypoint[tun] == nil
     or doesPositionMatch(turtle.position,
                          global.turtle_to_waypoint[tun],
                          searchlightSpotRadius) then

      if waypoint == nil then
        waypoint = MakeWanderWaypoint(origin)
      end
      global.turtle_to_waypoint[tun] = waypoint
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
end


function MakeWanderWaypoint(origin)
  -- Since the turtle has to 'chase' foes it spots, we don't want it to wander
  -- too close to the max range of the spotlight
  local bufferedRange = searchlightOuterRange - 5
   -- 0 - 1 inclusive. If you supply arguments, math.random will return ints not floats.
  local angle = math.random()
  local distance = math.random(searchlightInnerRange/2, bufferedRange)

  return OrientationToPosition(origin, angle, distance)
end
