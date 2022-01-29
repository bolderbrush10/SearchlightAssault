local d = require "sl-defines"
local u = require "sl-util"

local cf = require "control-forces"
local rd = require "sl-render"


local export = {}


-- tState states
export.MOVE = 0
export.WANDER = 1
export.FOLLOW = 2

-- Since the turtle has to 'chase' foes it spots, we don't want it to wander
-- too close to the max range of the searchlight
local bufferedRange = d.searchlightRange - 5

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
                                     allow_paths_through_own_entities = true,
                                     prefer_straight_paths = false,},
                   radius = 0.2
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


local function clamp(value, min, max, default)
  if not value then
    return default
  else
    if value < min then
      return min
    elseif value > max then
      return max
    end
  end

  return value
end


-- Clamps values to 1 - 360, treating 0 as 360
-- (rendering.draw_arc creates beautiful but glitchy lines
--  when given negative or excessive values)
local function clampDeg(value, default)
  if not value then
    return default
  end

  if value == 0 or value == 360 then
    return 360
  elseif value > 0 then
    return value % 360
  else
    -- return 360 - (value % 360)
    -- Believe it or not, but factorio's version of lua acts like the above for negatives
    -- (version 5.4.3 does not, and requires that line above)
    return value % 360
  end
end


-- TODO Need to treat wanderParam values of 0 as unset / default
-- tWanderParams = .radius, .rotation, .min, .max
-- tAdjParams = .angleStart, .len, .min, .max
local function ValidateAndSetParams(g)
  g.tAdjParams = {} -- init / reset

  -- Blueprints ignore orientation,
  -- so we will ignore orientation
  local rot = clampDeg(g.tWanderParams.rotation, 0)
  local rad = clampDeg(g.tWanderParams.radius, 360)

  if rad == 360 then
    g.tAdjParams.angleStart = 0
    g.tAdjParams.len = math.pi * 2
  else
    local angleLHS = rot - (rad / 2)
    -- Need to wrap around the unit circle
    if angleLHS < 0 then
      angleLHS = angleLHS + 360
    end

    -- Convert from degrees to radians
    g.tAdjParams.angleStart = (angleLHS / 180) * math.pi
    g.tAdjParams.len = (rad / 180) * math.pi
  end

  local min = clamp(g.tWanderParams.min, 1, bufferedRange, 1)
  local max = bufferedRange
  if g.tWanderParams.max ~= 0 then
    max = clamp(g.tWanderParams.max, 1, bufferedRange, bufferedRange)
  end

  if min > max then
    max = min
  end

  g.tAdjParams.min = min
  g.tAdjParams.max = max

  -- Show new search area
  rd.DrawSearchArea(g.light, nil, g.light.force, true)  
end


local function MakeWanderWaypoint(g)
  if not g.tAdjParams then
    ValidateAndSetParams(g)
  end

  -- tAdjParams = .angleStart, .len, .min, .max

  -- math.random doesn't like floats, so, multiply by 100 and floor it
  local angle = nil
  local start = math.floor(g.tAdjParams.angleStart * 100)
  local len = math.floor(g.tAdjParams.len * 100)
  if len == 0 then
    angle = start / 100
  else
    angle = math.random(start, start + len) / 100
  end

  local min = g.tAdjParams.min
  local max = g.tAdjParams.max
  if min < max then
    distance = math.random(min, max)
  else
    distance = min
  end

  return u.ScreenOrientationToPosition(g.light.position, angle, distance)
end


local function TranslateCoordinate(gestalt, coord)
  local translatedCoord = {x=coord.x, y=coord.y}

  -- Clamp excessive ranges so the turtle doesn't go past the searchlight max radius
  if u.lensquared(coord, {x=0, y=0}) > u.square(bufferedRange) then
    translatedCoord = u.ClampCoordToDistance(translatedCoord, bufferedRange)
  end

  translatedCoord.x = translatedCoord.x + gestalt.light.position.x
  translatedCoord.y = translatedCoord.y + gestalt.light.position.y

  return translatedCoord
end


local function RespawnTurtle(turtle, position)
  local g = global.unum_to_g[turtle.unit_number]
  local newT = export.SpawnTurtle(g.light, g.light.surface, position)

  g.turtle = newT
  global.unum_to_g[newT.unit_number] = g
  global.unum_to_g[turtle.unit_number] = nil

  if g.light.shooting_target == turtle then
    g.light.shooting_target = newT
  end

  turtle.destroy()

  return g
end


local function Turtleport(turtle, origin, position)
  if not position then
    return
  end

  local tpBufferRange = d.searchlightRange - 3

  -- If position is too far from the origin for the searchlight to attack it,
  -- calculate a slightly-closer position with the same angle and use that
  if not u.WithinRadius(position, origin, tpBufferRange) then
    local vecOriginPos = {x = position.x - origin.x,
                          y = position.y - origin.y}

    local theta = math.atan2(vecOriginPos.y, vecOriginPos.x)
    position = u.ScreenOrientationToPosition(origin, theta, tpBufferRange)
  end

  if not turtle.teleport(position) then
    -- The teleport failed for some reason, so respawn
    RespawnTurtle(turtle, nil)
  end
end


------------------------
--  Aperiodic Events  --
------------------------


export.CheckForTurtleEscape = function(g)
  if not u.WithinRadius(g.turtle.position, g.light.position, d.searchlightRange - 0.2) then
    -- If the searchlight started attacking something else while the turtle was distracted and out of range,
    -- then we may as well sic the turtle on it, too
    if g.light.shooting_target ~= nil then
      g.turtle.teleport(g.light.shooting_target.position)
    else
      Turtleport(g.turtle, g.light.position, g.turtle.position)
    end
  end

  if g.light.name == d.searchlightBaseName then
    g.light.shooting_target = g.turtle
  end
end


export.TurtleWaypointReached = function(g)
  if g.tState == export.WANDER then
    export.WanderTurtle(g)
    -- retarget turtle just in case something happened
    g.light.shooting_target = g.turtle
  elseif g.tState == export.FOLLOW and g.tCoord.speed then
    -- If the foe can move, keep chasing it
    export.TurtleChase(g, g.tCoord)
  elseif g.tState == export.FOLLOW then
    -- (If the foe can't move, then we can probably stop ordering the turtle around)
    g.turtle.set_command({type = defines.command.stop,
                          distraction = defines.distraction.none,
                         })
  else
    g.turtle.set_command({type = defines.command.stop,
                          distraction = defines.distraction.by_enemy,
                         })
  end
end


-- If a turtle fails a command, respawn it and reissue its current command
export.TurtleFailed = function(turtle)
  local g = RespawnTurtle(turtle, turtle.position)

  if g.tState == export.MOVE then
    local translatedCoord = TranslateCoordinate(g, g.tCoord)
    IssueMoveCommand(turtle, translatedCoord, false)
  elseif g.tState == export.FOLLOW then
    export.TurtleChase(g, g.tCoord)
  else
    export.WanderTurtle(g)
  end
end


export.ResumeTurtleDuty = function(gestalt, turtlePositionToResume)
  local turtle = gestalt.turtle

  Turtleport(turtle, gestalt.light.position, turtlePositionToResume)

  if gestalt.tOldState == export.MOVE then
    export.ManualTurtleMove(gestalt, gestalt.tOldCoord)
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
                                       fast_replace = false,
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

  ValidateAndSetParams(gestalt)
end


export.WanderTurtle = function(gestalt, waypoint)
  gestalt.tState    = export.WANDER
  gestalt.tCoord    = export.WANDER

  if waypoint == nil then
    waypoint = MakeWanderWaypoint(gestalt)
  end
  gestalt.turtle.speed = d.searchlightWanderSpeed

  IssueMoveCommand(gestalt.turtle, waypoint, false)
end


export.SetDefaultWanderParams = function(g)
  g.tWanderParams =
  {
    radius = 360,
    rotation = 0,
    min = 0,
    max = d.searchlightRange
  }
end


-- These parameters will be read in MakeWanderWaypoint
export.UpdateWanderParams = function(g, rad, rot, min, max)
  -- TODO won't this get called constantly if everything is unset? 
  -- We were initially thinking we'd set tWanderParams to null to indicate none are set,
  -- but that seems infeasible now.. 
  -- We realized it's going to have to always be set to something.
  if  g.tWanderParams 
      and (rad == 0) and (rot == 0) and (min == 0) and (max == 0) then
    export.SetDefaultWanderParams(g)
    ValidateAndSetParams(g)
    -- No need to call export.WanderTurtle(g);
    -- we can let it finish whatever it's currently doing
    return
  end
  
  local change = false
  if not g.tWanderParams then
    g.tWanderParams = {}
    change = true
  end

  local new = {radius = rad, rotation = rot, min = min, max = max}
  for key, item in pairs(g.tWanderParams) do
    if item ~= new[key] then
      g.tWanderParams[key] = new[key]
      change = true
    end
  end

  if change then
    ValidateAndSetParams(g)
    export.WanderTurtle(g)
  end
end


export.ManualTurtleMove = function(gestalt, coord)
  if      gestalt.tState == export.MOVE
      and gestalt.tCoord.x == coord.x
      and gestalt.tCoord.y == coord.y then
    return -- Already servicing this coordinate
  end

  local turtle = gestalt.turtle

  -- Don't interrupt a turtle that's trying to attack a foe
  if turtle.distraction_command then
    return
  end

  local translatedCoord = TranslateCoordinate(gestalt, coord)

  if gestalt.tState == export.MOVE then    
    local trans_tCoord = TranslateCoordinate(gestalt, gestalt.tCoord)

    if      trans_tCoord.x == translatedCoord.x
        and trans_tCoord.y == translatedCoord.y then
      return -- Already servicing this coordinate
    end
  end

  gestalt.tState = export.MOVE
  gestalt.tCoord = coord

  turtle.speed = d.searchlightRushSpeed
  IssueMoveCommand(turtle, translatedCoord, false)
end


export.TurtleChase = function(gestalt, entity)
  if gestalt.tState == export.MOVE then
    gestalt.tOldState = export.MOVE
    gestalt.tOldCoord = {x=gestalt.tCoord.x, y=gestalt.tCoord.y}
  elseif gestalt.tState == export.WANDER then
    gestalt.tOldState = export.WANDER
    gestalt.tOldCoord = export.WANDER
  end

  gestalt.tState = export.FOLLOW
  gestalt.tCoord = entity

  gestalt.turtle.speed = entity.speed or d.searchlightRushSpeed

  IssueFollowCommand(gestalt.turtle, entity, true)
end


return export
