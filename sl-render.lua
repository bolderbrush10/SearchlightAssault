local export = {}

local d = require("sl-defines")
local u = require("sl-util")


local wireFrameTTL = 240
local wireWidth = 0.04

local colorDrab = {r=0.08, g=0.04, b=0, a=0.0}
local colorVibr = {r=0.16, g=0.08, b=0, a=0.0}

-- This is the whole frame sequence length,
-- but we can speed it up by setting animation_speed,
-- or cut it short by reducing time_to_live
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


-- TODO Starting to wonder if this animation is a good idea.
--      Players are DEFINTIELY going to wonder why this initial radar pulse
--      doesn't detect enemies like the regular turtle's does.
--      Just stopping it from animating doesn't look good enough.
--      I think we'll have to desaturate it, or pick a different color,
--      or a different image entirely. Maybe empty hexagons?
local function MakeOneCellHazeParams(sl, player, force, pos, ttl)
  local t = 
  {
    --animation = d.hazeOneCellAnim,
    sprite=d.hazeOneHex,
    target = pos,
    render_layer = "lower-object-above-shadow",
    orientation_target = sl,
    surface = sl.surface,
    time_to_live = ttl,
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
      game.print("skipping outer because min & max match: " .. wParams.min) -- TODO remove
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
    return
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


-- TODO this could really use a fade-in. 
-- It'd look much nicer when continously hovering the cursor over a searchlight
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
-- Render a sparse sweep of sparkles emanating from the searchlight,
-- with a thicker 'cluster' towards the middle of the sweep, like a gradient.
-- TODO We probably need to only render 'half' of the pieces of the band in the first pass,
--      then do the other half in the next update tick while doing the intended band
--      I think we want 3 bands, with 3 density phases (none -> low -> full -> medium -> low -> none)
--      (Think, "strong radar edge")
-- TODO Maybe just don't even render this for band counts less than 5 or something?
--      Or just render the whole field?
-- TODO Starting to think splitting into tiers so lower bandcounts repeat is a good idea again
-- TODO move out constants, memoize more details?
-- TODO We should enforce a minimun linger on the last band...


-- Okay, so real talk. We had a lot of fun here.
-- But I think we need to consider axing this entirely.
-- Maybe just go with drawing a solid wedge. Sleep on it.
-- Or maybe no wedge. Just thicken up the rendered lines a little.
local function DrawGradientSweep(r_ids, sl, player, force, wParams, tick)
  local origin = sl.position

  local lightLen = 1.2
  local bandGap = 1 -- 1 tile per sprite

  local min = wParams.min + 1
  local angleStart = wParams.angleStart
  local angleEnd = angleStart + wParams.len

  local bandCount = wParams.max - min - 1
  local ticksPerBand = math.floor(wireFrameTTL / bandCount)
  -- Any "unused ticks" can be spent on the last band. They look cooler there.
  local linger = wireFrameTTL % bandCount

  if tick % ticksPerBand ~= 0 then
    return
  end

  local i = tick / ticksPerBand
  if i > bandCount then
    return
  end

  local bandDist = min + (bandGap * i)
  -- Adjust so that cells appear within the wireframe lines
  local angleStartAdj = angleStart + (0.5 / bandDist)
  local angleEndAdj = angleEnd - (0.5 / bandDist)

  local arcLen = ArcLen(bandDist, angleStartAdj, angleEndAdj)
  local lightCount = math.floor(arcLen / lightLen)
  if lightCount == 0 then -- TODO test this branch
    local angleMid = (angleEndAdj - angleStartAdj) / 2
    local pos = u.ScreenOrientationToPosition(origin, angleStartAdj + angleMid, bandDist)
    table.insert(r_ids, rendering.draw_animation(MakeOneCellHazeParams(sl, player, force, pos, ticksPerBand)))
  else
    local arcIncrement = arcLen / lightCount
    local padding = (arcLen % lightLen) / lightCount
    local angleIncrement = (arcIncrement ) / bandDist

    for j=0, lightCount do -- Starting at 0 intentional
      local pos = u.ScreenOrientationToPosition(origin, angleStartAdj + (angleIncrement*j), bandDist)

      cellParams = MakeOneCellHazeParams(sl, player, force, pos, ticksPerBand * 3)

      if i == bandCount then
        cellParams.time_to_live = cellParams.time_to_live + linger
      end

      --table.insert(r_ids, rendering.draw_animation(cellParams))
      table.insert(r_ids, rendering.draw_sprite(cellParams))
    end
  end
end


-- TODO wireframes aren't getting destroyed
local function Unrender(epochAndRenders)
  for _, render_id in pairs(epochAndRenders[2]) do
    rendering.destroy(render_id)
  end
end


local function ClearGestaltRender(gID)
  local pIndexToEpochAndRendersMap = global.slFOVRenders[gID]
  for pIndex, epochAndRenders in pairs(pIndexToEpochAndRendersMap) do
    Unrender(epochAndRenders)
  end
  global.slFOVRenders[gID] = nil
end


-- TODO Need to handle minDist == maxDist
-- TODO Need to test setting hundreds of searchlight areas at once over circuit network
-- Map: gID -> [0/playerIndex -> {originTick, [render_ids]}]
export.DrawSearchArea = function(sl, player, force, forceRedraw)
  local g = global.unum_to_g[sl.unit_number]
  if not g or not g.tAdjParams then
    return
  end

  local gID = g.gID
  local pIndex = 0
  if player then
    pIndex = player.index
  end

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
    Unrender(epochAndRenders)
  end

  epochAndRenders = {game.tick, {}}

  DrawSearchAreaWireFrame(epochAndRenders[2], sl, player, force, g.tAdjParams)
  DrawGradientSweep(epochAndRenders[2], sl, player, force, g.tAdjParams, 0)
end


-- Map: gID -> [0/playerIndex -> {originTick, [render_ids]}]
export.Update = function(tick)
  for gID, pIndexToEpochAndRendersMap in pairs(global.slFOVRenders) do
    local g = global.gestalts[gID]

    if not g or not next(pIndexToEpochAndRendersMap) then
      ClearGestaltRender(gID)
    else
      for pIndex, epochAndRenders in pairs(pIndexToEpochAndRendersMap) do
        local player = nil
        local force = nil

        if pIndex == 0 then
          force = g.light.force
        else
          player = game.players[pIndex]
        end

        local tick = game.tick - epochAndRenders[1]

        -- TODO also check if any particular player on the force was mousing over this searchlight
        -- (Can we just check game.player? Will that cause a desync or something?)
        if tick == wireFrameTTL then
          -- If the player is still mousing over this light,
          -- then keep showing its range
          if player and player.selected == g.light then
            tick = 0
            epochAndRenders[1] = game.tick
            DrawGradientSweep(epochAndRenders[2], g.light, player, force, g.tAdjParams, tick)
            DrawSearchAreaWireFrame(epochAndRenders[2], g.light, player, force, g.tAdjParams)
          else
            Unrender(epochAndRenders)
            pIndexToEpochAndRendersMap[pIndex] = nil
            -- If this just emptied the outer map, we'll clear it next tick by checking next()
          end
        else
          DrawGradientSweep(epochAndRenders[2], g.light, player, force, g.tAdjParams, tick)
        end

      end
    end

  end
end


return export