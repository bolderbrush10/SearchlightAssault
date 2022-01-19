local export = {}

local d = require("sl-defines")
local u = require("sl-util")


local wireFrameTTL = 240
local wireWidth = 0.04

local colorDrab = {r=0.08, g=0.04, b=0, a=0.0}
local colorVibr = {r=0.16, g=0.08, b=0, a=0.0}

local hazeAnimationTime = 60


-- TODO Migration file?
-- These maps organize things so we limit redraws for a given searchlight UI
export.InitTables_Render = function()
  -- Map: gID -> [0/playerIndex -> {originTick, [render_ids]}]
  global.slFOVRenders = {}
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


-- TODO Need to handle radius == 360
-- TODO Need to handle radius == 0
-- TODO Need to handle minDist == maxDist
-- TODO Need to test setting hundreds of searchlight areas at once over circuit network
-- Map: gID -> [0/playerIndex -> {originTick, [render_ids]}]
export.DrawSearchArea = function(sl, player, force, forceRedraw)
  local g = global.unum_to_g[sl.unit_number]
  if not g or not g.tAdjParams then
    return
  end

  local gID = g.gID
  local pIndex = player or 0

  if not global.slFOVRenders[gID] then
    global.slFOVRenders[gID] = {}
  end

  local pIndexToEpochAndRendersMap = global.slFOVRenders[gID]

  -- If the whole force just saw this area, no need to redraw for just one of its players
  -- (Which would case a double-draw and render it twice as bright as intended)
  if  not forceRedraw 
      and (pIndexToEpochAndRendersMap[pIndex] or pIndexToEpochAndRendersMap[0]) then
    return
  else
    pIndexToEpochAndRendersMap[pIndex] = {game.tick, {}}
  end

  local epochAndRenders = pIndexToEpochAndRendersMap[pIndex]

  if forceRedraw then
    for _, render_id in pairs(epochAndRenders[2]) do
      rendering.destroy(render_id)
    end
  end

  epochAndRenders = {game.tick, {}}

  DrawSearchAreaWireFrame(epochAndRenders[2], sl, player, force, g.tAdjParams)
  DrawGradientSweep(epochAndRenders[2], sl, player, force, g.tAdjParams, nil)
end


-- Map: gID -> [0/playerIndex -> {originTick, [render_ids]}]
-- TODO sloppy... clean this up
export.Update = function(tick)
  for gID, pIndexToEpochAndRendersMap in pairs(global.slFOVRenders) do
    local g = global.gestalts[gID]

    if g then
      for pIndex, epochAndRenders in pairs(pIndexToEpochAndRendersMap) do
        local player = players[pIndex]
        local force = nil

        local tick = game.tick - epochAndRenders[1]

        if tick == wireFrameTTL then          
          if player and player.selected == g.light then
            tick = 0
            epochAndRenders[1] = game.tick
          else
            pIndexToEpochAndRendersMap[pIndex] = nil
            -- TODO clean up outer map if this just emptied it
            return
          end
        end

        if not player then
          force = g.light.force
        end

        -- TODO pop on last update tick, unless a player is mousing over this searchlight
        -- (in that case, just reset origin tick)
        DrawGradientSweep(epochAndRenders[2], sl, player, force, g.tAdjParams, tick)
      end
    else
      -- Destroy all renders for this gestalt
      for pIndex, epochAndRenders in pairs(pIndexToEpochAndRendersMap) do
        for _, render_id in pairs(epochAndRenders[2]) do
          rendering.destroy(render_id)
        end
      end
      global.slFOVRenders[gID] = nil
    end

  end
end


return export