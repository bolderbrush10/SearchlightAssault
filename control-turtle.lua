require "control-common"
require "defines"
require "util"

-- location is expected to be the real spotlight's last shooting target,
-- if it was targeting something.
function SpawnTurtle(basesl, attacksl, surface, location)
    if location == nil then
        -- Start in front of the turret's base, wrt orientation
        location = OrientationToPosition(basesl.position, basesl.orientation, 3)
    end

    local turtle = surface.create_entity{name = turtleName,
                                         position = location,
                                         force = searchlightFoe,
                                         fast_replace = true,
                                         create_build_effect_smoke = false}

    turtle.destructible = false
    attacksl.shooting_target = turtle

    global.dummy_to_turtle[basesl.unit_number] = turtle

    -- If we set our first waypoint in the same direction, but further away,
    -- it makes a cool 'windup' effect as the searchlight is made
    local windupWaypoint = OrientationToPosition(basesl.position,
                                                 basesl.orientation,
                                                 math.random(searchlightInnerRange / 2,
                                                             searchlightOuterRange - 2))

    WanderTurtle(turtle, basesl.position, windupWaypoint)

    return turtle
end

function WanderTurtle(turtle, origin, waypoint)
    if not turtle.has_command()
       or global.turtle_to_waypoint[turtle.unit_number] == nil
       or lensquared(turtle.position, global.turtle_to_waypoint[turtle.unit_number])
          < square(searchlightSpotRadius) then

        if waypoint == nil then
            waypoint = MakeWanderWaypoint(origin)
        end

        global.turtle_to_waypoint[turtle.unit_number] = waypoint
        turtle.speed = searchlightWanderSpeed

        turtle.set_command({type = defines.command.go_to_location,
                            distraction = defines.distraction.none,
                            destination = waypoint,
                            pathfind_flags = {low_priority = true, cache = true,
                                              allow_destroy_friendly_entities = true,
                                              allow_paths_through_own_entities = true},
                            radius = 1
                           })
    end
end


function MakeWanderWaypoint(origin)
    local bufferedRange = searchlightOuterRange - 2
     -- 0 - 1 inclusive. If you supply arguments, math.random will return ints not floats.
    local angle = math.random()
    local distance = math.random(searchlightInnerRange/2, bufferedRange)

    return OrientationToPosition(origin, angle, distance)
end
