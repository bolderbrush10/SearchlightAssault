local export = {}

local d = require("sl-defines")
local u = require("sl-util")

-- Only redraw for a given searchlight every few seconds
-- Maps: 
--  [player.index .. "p" .. sl.unit_number] -> {game.tick, [render_ids]}
--  [ force.index .. "f" .. sl.unit_number] -> {game.tick, [render_ids]}
local slFOVRenders = {}

local wireFrameTTL = 240
local wireWidth = 0.04

local colorDrab = {r=0.08, g=0.04, b=0, a=0.0}
local colorVibr = {r=0.16, g=0.08, b=0, a=0.0}

local hazeAnimationTime = 60


local function append_table(a, b)
  table.move(b, 1, table_size(b), table_size(tableA)+1, tableA)
end


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


local function MakeOneCellHazeParams(sl, player, force, pos)
  local t = 
  {
    animation = d.hazeOneCellAnim,
    target = pos,
    render_layer = "lower-object-above-shadow", --"radius-visualization", -- TODO does this actually work?
    orientation_target = sl,
    surface = sl.surface,
    time_to_live = hazeAnimationTime, -- TODO this is the whole frame sequence length,
                                      -- but we can speed that up by setting animation_speed
  }

  if player then
    t.players = {player}
  end

  if force then
    t.forces = {force}
  end

  return t
end


-- tAdjParams = .angleStart, .angleEnd, .min, .max
local function DrawOuterArc(r_ids, sl, player, force, wParams)
  local dist = wParams.max
  if wParams.min == wParams.max then
      game.print("skipping outer because min & max match: " .. wParams.min)
      return -- We can skip drawing two arcs in the same place
  end

  local angle = {min=dist, 
                 max=dist + wireWidth, 
                 start=wParams.angleStart,
                 len=wParams.len
                }

  table.insert(r_ids, rendering.draw_arc(MakeArcParams(sl, player, force, false, angle, colorVibr, wireFrameTTL - 6)))
  table.insert(r_ids, rendering.draw_arc(MakeArcParams(sl, player, force, false, angle, colorVibr, wireFrameTTL - 5)))
  table.insert(r_ids, rendering.draw_arc(MakeArcParams(sl, player, force, false, angle, colorVibr, wireFrameTTL - 4)))
  table.insert(r_ids, rendering.draw_arc(MakeArcParams(sl, player, force, false, angle, colorVibr, wireFrameTTL)))
end 


local function DrawInnerArc(r_ids, sl, player, force, wParams)
  local dist = wParams.min

  local angle = {min=dist, 
                 max=dist + wireWidth, 
                 start=wParams.angleStart,
                 len=wParams.len
                }

  table.insert(r_ids, rendering.draw_arc(MakeArcParams(sl, player, force, false, angle, colorVibr, wireFrameTTL - 6)))
  table.insert(r_ids, rendering.draw_arc(MakeArcParams(sl, player, force, false, angle, colorVibr, wireFrameTTL - 5)))
  table.insert(r_ids, rendering.draw_arc(MakeArcParams(sl, player, force, false, angle, colorVibr, wireFrameTTL - 4)))
  table.insert(r_ids, rendering.draw_arc(MakeArcParams(sl, player, force, false, angle, colorVibr, wireFrameTTL)))
end


local function DrawEdgesArc(r_ids, sl, player, force, wParams)
  local origin = sl.position

  if wParams.len == (math.pi * 2) then  
    -- TODO draw 4 lines each 90degrees apart, starting from 45deg offset, around the sl
    game.print("360 detected")
  end

  local lines = {a={}, b={}}

  local angleEnd = wParams.angleStart + wParams.len
  lines.a.p1 = u.ScreenOrientationToPosition(origin, wParams.angleStart, wParams.min)
  lines.a.p2 = u.ScreenOrientationToPosition(origin, wParams.angleStart, wParams.max)

  lines.b.p1 = u.ScreenOrientationToPosition(origin, angleEnd, wParams.min)
  lines.b.p2 = u.ScreenOrientationToPosition(origin, angleEnd, wParams.max)

  for _, l in pairs(lines) do
    table.insert(r_ids, rendering.draw_line(MakeLineParams(sl, player, force, l.p1, l.p2, nil, colorVibr, wireFrameTTL - 6)))
    table.insert(r_ids, rendering.draw_line(MakeLineParams(sl, player, force, l.p1, l.p2, nil, colorVibr, wireFrameTTL - 5)))
    table.insert(r_ids, rendering.draw_line(MakeLineParams(sl, player, force, l.p1, l.p2, nil, colorVibr, wireFrameTTL - 4)))
    table.insert(r_ids, rendering.draw_line(MakeLineParams(sl, player, force, l.p1, l.p2, nil, colorVibr, wireFrameTTL)))
  end
end


local function DrawSearchAreaWireFrame(r_ids, sl, player, force, wParams)
  DrawInnerArc(r_ids, sl, player, force, wParams)
  DrawOuterArc(r_ids, sl, player, force, wParams)
  DrawEdgesArc(r_ids, sl, player, force, wParams)
end


-- Tiles, Radians, Radians
local function ArcLen(radius, angleStart, angleEnd)
  return radius * math.abs(angleEnd - angleStart)
end


-- TODO So, what do we want to do here?
-- I think we want to render a sparse sweep of sparkles emanating from the searchlight,
-- with a thicker 'cluster' towards the middle of the sweep, like a gradient.
-- How do we want to do this?
-- Well, we could make a few and set_position them at some tick count,
-- but I think it'd be cleaner to just ask the renderer to make new ones every time.
-- We can start by calculating "bands" for the sweep to populate,
-- make up some population density levels for the current band,
-- and caculate positions within the band based on the wParams.radius
-- We also need to figure out
-- A) How many ticks we want to spend per band.
--    I think we want the bands to all begin and end in sync with the wireframe's time to live
-- B) How to hook into control.lua on_(nth_)tick() (and with what n value)
local function DrawGradientSweep(r_ids, sl, player, force, wParams, tick)
  local origin = sl.position

  local min = wParams.min + 1
  local bandCount = wParams.max - min - 1
  local lightLen = 1.2
  local bandGap = 1 -- 1 tile per sprite

  local angleStart = wParams.angleStart
  local angleEnd = angleStart + wParams.len

  for i=0, bandCount do -- Starting at 0 intentional
    local bandDist = min + (bandGap * i)
    -- Adjust so that cells appear within the wireframe lines
    local angleStartAdj = angleStart + (0.5 / bandDist)
    local angleEndAdj = angleEnd - (0.5 / bandDist)

    local arcLen = ArcLen(bandDist, angleStartAdj, angleEndAdj)
    local lightCount = math.floor(arcLen / lightLen)
    if lightCount == 0 then
      local angleMid = (angleEndAdj - angleStartAdj) / 2
      local pos = u.ScreenOrientationToPosition(origin, angleStartAdj + angleMid, bandDist)
      table.insert(r_ids, rendering.draw_animation(MakeOneCellHazeParams(sl, player, force, pos)))
    else
      local arcIncrement = arcLen / lightCount
      local padding = (arcLen % lightLen) / lightCount
      local angleIncrement = (arcIncrement ) / bandDist

      for j=0, lightCount do -- Starting at 0 intentional
        local pos = u.ScreenOrientationToPosition(origin, angleStartAdj + (angleIncrement*j), bandDist)
        table.insert(r_ids, rendering.draw_animation(MakeOneCellHazeParams(sl, player, force, pos)))
      end
    end
  end
end


export.InitTables_Render = function()
  -- Map: Tick -> {gestalt, startTick}
  global.render_draw = {}

  -- Map: Tick -> [RenderID]
  global.render_pop = {}
end


-- TODO This is gonna leak memory like crazy.
--      We need to clean up those map entries after their tick expires.
-- TODO Need to handle radius == 360
-- TODO Need to handle radius == 0
-- TODO Need to handle minDist == maxDist
-- TODO Maybe set up the time to live so wireframes fade-in fast
-- TODO Maybe keep the wireframes alive until the player stops mousing over them?
-- TODO Need to test setting hundreds of searchlight areas at once over circuit network
export.DrawSearchArea = function(sl, player, force, forceRedraw)
  local g = global.unum_to_g[sl.unit_number]
  if not g or not g.tAdjParams then
    return
  end

  local lastDraw = nil
  local updatePlayerTick = true
  local forceIndex = nil

  if player then
    forceIndex = player.force.index
    -- If the whole force just saw this radius, no need to redraw for one of its players
    -- (Which would case a double-draw and render it twice as bright as intended)
    local forceDraw = slFOVRenders[forceIndex .. "f" .. sl.unit_number]
    local playerDraw = slFOVRenders[player.index .. "p" .. sl.unit_number]
    if forceDraw and forceDraw[1] then
      lastDraw = forceDraw
      updatePlayerTick = false
    elseif playerDraw and playerDraw[1] then
      lastDraw = playerDraw
    end
  else
    forceIndex = force.index
    lastDraw = slFOVRenders[forceIndex .. "f" .. sl.unit_number]
    updatePlayerTick = false
  end


  if forceRedraw and lastDraw and lastDraw[2] then
    for _, render_id in pairs(lastDraw[2]) do
      rendering.destroy(render_id)
    end
  elseif lastDraw and lastDraw[1] and lastDraw[1] + wireFrameTTL > game.tick then
    return
  end

  local render_ids = {}
  DrawSearchAreaWireFrame(render_ids, sl, player, force, g.tAdjParams)
  DrawGradientSweep(render_ids, sl, player, force, g.tAdjParams)

  if updatePlayerTick then
    slFOVRenders[player.index .. "p" .. sl.unit_number] = {game.tick, render_ids}
  else
    slFOVRenders[forceIndex .. "f" .. sl.unit_number] = {game.tick, render_ids}
  end
end


export.UpdateSearchArea = function()
  for _, fov in pairs(slFOVRenders) do
    -- TODO
  end
end


return export