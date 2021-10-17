local d = require "sl-defines"
local u = require "sl-util"

local cf = require "control-forces"


local export = {}


-- tState states
export.WANDER = 0
export.FOLLOW = 1


------------------------
--  Helper Functions  --
------------------------


local function makeMoveOrders(target, followingEntity, ignoreFoes)
  local distraction = defines.distraction.by_enemy

  if ignoreFoes then
    distraction = defines.distraction.none
  end

  local command = {type = defines.command.go_to_location,
                   distraction = distraction,
                   pathfind_flags = {low_priority = true,
                                     cache = false,
                                     allow_destroy_friendly_entities = true,
                                     allow_paths_through_own_entities = true},
                   radius = 1 -- TODO Try making this a lot smaller,
                  }

  if followingEntity then
    command.destination_entity = target
  else
    command.destination = target
  end

  return command
end


local function IssueFollowCommand(turtle, entity, ignoreFoes)
  turtle.set_command(makeMoveOrders(entity, true, ignoreFoes))
end


local function IssueMoveCommand(turtle, waypoint, ignoreFoes)
  turtle.set_command(makeMoveOrders(waypoint, false, ignoreFoes))
end


local function MakeWanderWaypoint(origin)
  -- Since the turtle has to 'chase' foes it spots, we don't want it to wander
  -- too close to the max range of the searchlight
  local bufferedRange = d.searchlightRange - 5
   -- 0 - 1 inclusive. If you supply arguments, math.random will return ints not floats.
  local angle = math.random()
  local distance = math.random(d.searchlightRange/8, bufferedRange)

  return u.OrientationToPosition(origin, angle, distance)
end


local function Turtleport(turtle, origin, position)
  if not position then
    return
  end

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
    local newT = SpawnTurtle(g.light, g.light, g.light.surface)

    g.turtle = newT
    global.unum_to_g[newT.unit_number] = g
    global.unum_to_g[turtle.unit_number] = nil

    log("[Searchlights Mod] Error! Please report to mod author with before & after saves. " ..
        "Teleport of hidden entity failed. Old Unit Number: " ..
        turtle.unit_number .. " New Unit Number: " .. newT.unit_number ..
        " Target Position: " .. position.x .. ", " .. position.y)

    turtle.destroy()
  end
end


------------------------
--  Aperiodic Events  --
------------------------


export.TurtleWaypointReached = function(g)
  if g.tState == export.WANDER then
    export.WanderTurtle(g)
    g.light.shooting_target = g.turtle -- retarget turtle just in case something happened
  elseif g.tState == export.FOLLOW and g.tCoord.speed then
    export.TurtleChase(g, g.tCoord)
  elseif g.tState == export.FOLLOW then
    g.turtle.set_command({type = defines.command.stop,
                          distraction = defines.distraction.none,
                         })
  else
    g.turtle.set_command({type = defines.command.stop,
                          distraction = defines.distraction.by_enemy,
                         })
  end
end


export.ResumeTurtleDuty = function(gestalt, turtlePositionToResume)
  local turtle = gestalt.turtle

  Turtleport(turtle, gestalt.light.position, turtlePositionToResume)

  if gestalt.tOldState and type(gestalt.tOldState) == "table" then
    export.ManualTurtleMove(gestalt, gestalt.tOldState)
  else
    export.WanderTurtle(gestalt)
  end
end


-- location is expected to be the searchlight's last shooting target,
-- if it was targeting something.
export.SpawnTurtle = function(sl, surface, location)
  if location == nil then
    -- Start in front of the turret's base, wrt orientation
    location = u.OrientationToPosition(sl.position, sl.orientation, 3)
  end

  local turtle = surface.create_entity{name = d.turtleName,
                                       position = location,
                                       force = cf.PrepareTurtleForce(sl.force),
                                       fast_replace = true,
                                       create_build_effect_smoke = false}

  turtle.destructible = false

  return turtle
end


------------------------
--  Turtle Commands   --
------------------------


-- If we set our first waypoint in the same direction as the searchlight orientation,
-- but further away, it makes the searchlight appear to "start up"
export.WindupTurtle = function(gestalt, turtle)
  local windupWaypoint = u.OrientationToPosition(gestalt.light.position,
                                                 gestalt.light.orientation,
                                                 math.random(d.searchlightRange / 8,
                                                             d.searchlightRange - 2))

  export.WanderTurtle(gestalt, windupWaypoint)
end


export.WanderTurtle = function(gestalt, waypoint)
  gestalt.tState    = export.WANDER
  gestalt.tCoord    = export.WANDER
  gestalt.tOldState = export.WANDER

  if waypoint == nil then
    waypoint = MakeWanderWaypoint(gestalt.light.position)
  end
  gestalt.turtle.speed = d.searchlightWanderSpeed

  IssueMoveCommand(gestalt.turtle, waypoint, false)
end


export.ManualTurtleMove = function(gestalt, coord)
  if gestalt.tState ~= export.FOLLOW
      and type(gestalt.tCoord) == "table"
      and gestalt.tCoord.x == coord.x
      and gestalt.tCoord.y == coord.y then
    return -- Already servicing this coordinate
  end

  local turtle = gestalt.turtle

  -- Don't interrupt a turtle that's trying to attack a foe
  if turtle.distraction_command then
    return
  end

  gestalt.tCoord    = coord
  gestalt.tOldState = coord

  local bufferedRange = d.searchlightRange - 5

  -- Clamp excessive ranges so the turtle doesn't go past the searchlight max radius
  if u.lensquared(coord, {x=0, y=0}) > u.square(bufferedRange) then
    local old = coord
    coord = u.ClampCoordToDistance(coord, bufferedRange)
  end

  local translatedCoord = coord
  translatedCoord.x = translatedCoord.x + gestalt.light.position.x
  translatedCoord.y = translatedCoord.y + gestalt.light.position.y

  if type(gestalt.tState) ~= "table"
     or translatedCoord.x ~= gestalt.tState.x
     or translatedCoord.y ~= gestalt.tState.y then

    gestalt.tState = translatedCoord

    turtle.speed = d.searchlightRushSpeed
    IssueMoveCommand(turtle, gestalt.tState, false)
  end
end


export.TurtleChase = function(gestalt, entity)
  gestalt.turtle.speed = entity.speed or d.searchlightRushSpeed
  gestalt.tState = export.FOLLOW
  gestalt.tCoord = entity

  IssueFollowCommand(gestalt.turtle, entity, true)
end


return export
