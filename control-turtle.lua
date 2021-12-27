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


local function MakeWanderWaypoint(g)
  local origin = g.light.position

  local angle = nil
  local minDist = 1
  local maxDist = bufferedRange

  -- tAdjParams = .angleStart, .angleEnd, .min, .max
  -- Validated & bounds-checked in UpdateWanderParams()
  if g.tAdjParams then
    if g.tAdjParams.angleStart ~= g.tAdjParams.angleEnd then
      angle = math.random()
    end

    -- math.random doesn't play nice with floats
    local angleA = math.floor(g.tAdjParams.angleStart * 100)
    local angleB = math.floor(g.tAdjParams.angleEnd * 100)
    if angleA == angleB then
      angle = angleA / 100
    else
      if angleA < angleB then
        angle = math.random(angleA, angleB) / 100
      else
        -- If we have to wrap around, do a coinflip to decide
        -- between sides, weighted by the angle of each wrap-around.
        local weight = 0
        if angleA ~= 0 then -- angleA = 0 shouldn't be possible here, but let's be safe
          weight = angleB / angleA
        end
        if math.random(0, 1) > weight then
          angle = math.random(angleA, 100) / 100
        else
          angle = math.random(0, angleB) / 100
        end
      end
    end

    local min = g.tAdjParams.min
    local max = g.tAdjParams.max

    if min then
      minDist = min
    end

    if max then
      maxDist = max
    end
  end

  if not angle then
    -- 0 - 1 inclusive. If you supply args, math.random returns ints, not floats.
    angle = math.random()
  end

  if minDist < maxDist then
    distance = math.random(minDist, maxDist)
  else
    distance = minDist
  end

  return u.OrientationToPosition(origin, angle, distance)
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


-- tWanderParams = .radius, .rotation, .min, .max
-- tAdjParams = .angleStart, .angleEnd, .min, .max
local function ValidateAndSet(g, new)
  -- Cleared in IsChanged
  g.tAdjParams = {}

  -- Blueprints ignore orientation data,
  -- so just ignore orientations
  -- TODO default rotation needs to point downward to show off searchlight's "face"
  local rot = clamp(g.tWanderParams.rotation, 0, 360, 0)
  local rad = clamp(g.tWanderParams.radius, 0, 360, 360)

  if rad == 360 then
    g.tAdjParams.angleStart = 0
    g.tAdjParams.angleEnd = 1
  else
    -- Need to get to 2 decimal places for random() calculations above
    -- ([1,2,3] / 360 = 0.00x)
    if rad == 1 or rad == 2 or rad ==3 then
      rad = 4
    end

    -- Need to wrap around the unit circle and drop decimal places
    -- (math.random doesn't like floats)
    local angleA = math.floor(rot - (rad / 2))
    if angleA < 0 then
      angleA = angleA + 360
    end
    
    local angleB = math.floor(rot + (rad / 2))
    if angleB > 360 then
      angleB = angleB - 360
    end

    g.tAdjParams.angleStart = angleA / 360
    g.tAdjParams.angleEnd   = angleB / 360
  end

  local min = clamp(g.tWanderParams.min, 1, bufferedRange, 1)
  local max = clamp(g.tWanderParams.max, 1, bufferedRange, bufferedRange)

  if min > max then
    max = min
  end

  g.tAdjParams.min = min
  g.tAdjParams.max = max

  game.print("params: " .. serpent.block(g.tAdjParams))
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


-- These parameters will be read in MakeWanderWaypoint
export.UpdateWanderParams = function(g, rad, rot, min, max)
  if  g.tWanderParams
      and (rad == 0) and (rot == 0) and (min == 0) and (max == 0) then
    g.tWanderParams = nil
    g.tAdjParams = nil -- TODO handle this in sl-render    
    -- no need to call export.WanderTurtle(g);
    -- we can let it finish whatever it's currently doing
    rd.DrawSearchArea(g.light, nil, g.light.force, true)
    return
  end
  
  local change = false
  if not oldT then
    g.tWanderParams = {}
    change = true
  end

  local new = {radius = rad, rotation = rot, min = min, max = max}
  for key, item in pairs(g.tWanderParams) do
    if item ~= new[key] then
      g.tWanderParams[key] = item
      change = true
    end
  end

  if change then
    ValidateAndSet(g, new)
    export.WanderTurtle(g)
    rd.DrawSearchArea(g.light, nil, g.light.force, true)  
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
