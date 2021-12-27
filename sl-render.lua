local export = {}

local d = require("sl-defines")
local u = require("sl-util")

-- Only redraw for a given searchlight every few seconds
-- Maps: 
--  [player.index .. "p" .. sl.unit_number] -> game.tick
--  [force.index  .. "f" .. sl.unit_number] -> game.tick
-- TODO -> {game.tick, [render_objects]} so we can kill old ones & redraw on change
local slFOVRenders = {}

local wireFrameTTL = 240
local wireWidth = 0.04

local colorDrab = {r=0.08, g=0.04, b=0, a=0.0}
local colorVibr = {r=0.16, g=0.08, b=0, a=0.0}


-- angles: {min,   max,   start,   len}
--          tiles, tiles, radians, radians
local function MakeArcParams(sl, player, force, draw_g, angles, color, ttl)
  local t = 
  {
    color = color, 
    min_radius = angles.min, -- tiles 
    max_radius = angles.max, -- tiles  
    start_angle= angles.start, -- radians 
    angle = angles.len, -- radians
    target = sl.position, 
    surface = sl.surface, 
    time_to_live = ttl,
    draw_on_ground = draw_g,
  }

  if player then
    t.players = {player}
  end

  if force then
    t.forces = {force}
  end

  return t
end


local function MakeLineParams(sl, player, force, pos1, pos2, dashLen, color, ttl)
  local t = 
  {
    color = color, 
    width = 1.28, -- in pixels (32 px per tile) (0.04 * 32 == 1.28)
    from = pos1, 
    to = pos2, 
    surface = sl.surface, 
    time_to_live = ttl,
    draw_on_ground = false,
  }

  if player then
    t.players = {player}
  end

  if force then
    t.forces = {force}
  end

  -- lengths in tiles
  if dashLen then
    -- TODO
  end

  return t
end


local function MakeArcSweep(sl, player, force, wParams)
  local angle = {min=3, max=10, start=0, len=math.pi / 2}

  rendering.draw_arc(MakeArcParams(sl, player, force, true, angle, colorDrab, wireFrameTTL - 5))
  rendering.draw_arc(MakeArcParams(sl, player, force, true, angle, colorDrab, wireFrameTTL))

end


-- tAdjParams = .angleStart, .angleEnd, .min, .max
local function DrawOuterArc(sl, player, force, wParams)
  local dist = wParams.max
  if wParams.min == wParams.max then
      game.print("skipping outer because min & max match: " .. wParams.min)
      return -- We can skip drawing two arcs in the same place
  end

  local angle = {min=dist, 
                 max=dist + wireWidth, 
                 start=(wParams.angleStart * 2 * math.pi) - math.pi/2,
                 len=((wParams.angleEnd - wParams.angleStart) * 2 * math.pi)
                }

  rendering.draw_arc(MakeArcParams(sl, player, force, false, angle, colorVibr, wireFrameTTL - 6))
  rendering.draw_arc(MakeArcParams(sl, player, force, false, angle, colorVibr, wireFrameTTL - 5))
  rendering.draw_arc(MakeArcParams(sl, player, force, false, angle, colorVibr, wireFrameTTL - 4))
  rendering.draw_arc(MakeArcParams(sl, player, force, false, angle, colorVibr, wireFrameTTL))
end 


-- TODO I think I desperately want to store wParams as angleStart + length
--      It wouldn't hurt MakeWanderWaypoint() to say, "math.rand(angleStart, angleStart+len)"
--      In fact, it'd make a lot of things simpler here and there
local function DrawInnerArc(sl, player, force, wParams)
  local dist = wParams.min

  game.print("drawing inner at dist " .. dist)
  local angle = {min=dist, 
                 max=dist + wireWidth, 
                 start=(wParams.angleStart * 2 * math.pi) - math.pi/2,
                 len=(math.abs(wParams.angleEnd - wParams.angleStart) * 2 * math.pi)
                }

  game.print(serpent.block(angle))

  -- rendering.draw_arc(MakeArcParams(sl, player, force, false, angle, colorVibr, wireFrameTTL - 6))
  -- rendering.draw_arc(MakeArcParams(sl, player, force, false, angle, colorVibr, wireFrameTTL - 5))
  -- rendering.draw_arc(MakeArcParams(sl, player, force, false, angle, colorVibr, wireFrameTTL - 4))
  rendering.draw_arc(MakeArcParams(sl, player, force, false, angle, colorVibr, wireFrameTTL))

  -- TODO remove
  --local tempAng = {min = 2, max = 10,
  --                 start = 0, len = math.pi / 2,}
  --rendering.draw_arc(MakeArcParams(sl, player, force, false, tempAng, {r=1}, wireFrameTTL))
end


-- TODO probably also want to render short spiky ruler-marks every 15 degrees or so from the base and outer edge
local function DrawEdgesArc(sl, player, force, wParams)
  local origin = sl.position

  if angle and angle == 360 then  
    -- TODO draw 4 lines each 90degrees apart, starting from 45deg offset, around the sl
  end

  local lines = {a={}, b={}}

  lines.a.p1 = u.OrientationToPosition(origin, wParams.angleStart, wParams.min)
  lines.a.p2 = u.OrientationToPosition(origin, wParams.angleStart, wParams.max)

  lines.b.p1 = u.OrientationToPosition(origin, wParams.angleEnd, wParams.min)
  lines.b.p2 = u.OrientationToPosition(origin, wParams.angleEnd, wParams.max)

  for _, l in pairs(lines) do
    game.print("drawing edges")
    rendering.draw_line(MakeLineParams(sl, player, force, l.p1, l.p2, nil, colorVibr, wireFrameTTL - 6))
    rendering.draw_line(MakeLineParams(sl, player, force, l.p1, l.p2, nil, colorVibr, wireFrameTTL - 5))
    rendering.draw_line(MakeLineParams(sl, player, force, l.p1, l.p2, nil, colorVibr, wireFrameTTL - 4))
    rendering.draw_line(MakeLineParams(sl, player, force, l.p1, l.p2, nil, colorVibr, wireFrameTTL))
  end
end


local function DrawGradientSweep()

end


-- TODO rotation value of 0 or 360 and anything seems busted
-- TODO rotation value of 360 & radius 45 is making a parallelogram instead of an arc
--      kinda neat, but not what we intended
-- TODO rotation value of 360 & distance 100 isn't rendering the outer arc at all at high zoom levels,
--      and the sides look like a parallelogram
local function DrawSearchAreaWireFrame(sl, player, force, wParams)
  local lastDraw = nil
  local updatePlayerTick = true
  local forceIndex = nil
  if player then
    forceIndex = player.force.index
    -- If the whole force just saw this radius, no need to redraw
    local forceDraw = slFOVRenders[forceIndex .. "f" .. sl.unit_number]
    if forceDraw then
      lastDraw = forceDraw
      updatePlayerTick = false
    else
      lastDraw = slFOVRenders[player.index .. "p" .. sl.unit_number]
    end
  else
    forceIndex = force.index
    lastDraw = slFOVRenders[forceIndex .. "f" .. sl.unit_number]
    updatePlayerTick = false
  end

  if lastDraw and lastDraw + wireFrameTTL > game.tick  then
    return
  end

  if updatePlayerTick then
    slFOVRenders[player.index .. "p" .. sl.unit_number] = game.tick
  else
    slFOVRenders[forceIndex .. "f" .. sl.unit_number] = game.tick
  end

  DrawInnerArc(sl, player, force, wParams)
  DrawOuterArc(sl, player, force, wParams)
  DrawEdgesArc(sl, player, force, wParams)
  MakeArcSweep(sl, player, force, wParams)

end


export.DrawSearchArea = function(sl, player, force, forceRedraw)
  local g = global.unum_to_g[sl.unit_number]
  if not g then
    game.print("not rendering g")
    return
  end
  local wParams = g.tAdjParams
  if not wParams then
    game.print("not rendering w")
    -- TODO draw 360 with decoration
    return
  end

  if forceRedraw then
    -- TODO kill old objects with rendering.destroy(id)
  end

  game.print("rendering")

  DrawSearchAreaWireFrame(sl, player, force, wParams)
  DrawGradientSweep()
end


export.UpdateSearchArea = function()
  for _, fov in pairs(slFOVRenders) do
    -- TODO
  end
end


return export