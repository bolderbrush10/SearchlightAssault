----------------------------------------------------------------
  local d = require("sl-defines")
  local u = require("sl-util")

  -- forward declarations
  local ClearGestaltRender
  local Unrender
  local Render
  local MakeLineParams
  local MakeEdgeParams
  local MakeArcParams
  local FinishParams
  local Update
  local DrawSearchArea
  local DrawTurtlePos
  local InitTables_Render
----------------------------------------------------------------


local wireFrameTTL = 240

local colorDrab = {r=0.08, g=0.04, b=0, a=0.0}
local colorVibr = {r=235/255, g=150/255, b=50/255, a=1.0}
local colorVive = {r=0/255, g=235/255, b=50/255, a=1.0}

local twoPi = 2 * math.pi

local EDGE_LEFT  = 1
local EDGE_RIGHT = 2
local EDGE_INNER = 3
local EDGE_OUTER = 4


-- The map helps limit UI redraws for a given searchlight
function InitTables_Render()
  -- Map: gID -> 0/playerIndex -> {epochTick, {render_id}}
  global.slFOVRenders = {}

  -- Map: playerIndex -> {g, {render_id}}
  global.tposRenders = {}
end


function FinishParams(target, player, force, t)
  t.target = target.position
  t.surface = target.surface
  t.time_to_live = 0 -- live until destroyed
  t.draw_on_ground = true

  if player then
    t.players = {player}
  end

  if force then
    t.forces = {force}
  end

  return t
end


-- angles: {min,   max,   start,   len}
--          tiles, tiles, radians, radians
function MakeArcParams(sl, player, force, wParams)
  local t =
  {
    color = colorDrab,
    min_radius = wParams.min, -- tiles
    max_radius = wParams.max, -- tiles
    start_angle= wParams.angleStart, -- radians
    angle = wParams.len, -- radians
  }

  if t.min_radius == t.max_radius then
    t.max_radius = t.min_radius - 0.2
    t.min_radius = t.max_radius + 0.2
  end

  return FinishParams(sl, player, force, t)
end


-- angles: {min,   max,   start,   len}
--          tiles, tiles, radians, radians
function MakeEdgeParams(sl, player, force, wParams, edgeType)
  local t =
  {
    color = colorVibr,
    start_angle= wParams.angleStart, -- radians
    angle = wParams.len, -- radians
  }

  if edgeType == EDGE_INNER then
    t.min_radius = wParams.min
    t.max_radius = wParams.min
  else
    t.min_radius = wParams.max
    t.max_radius = wParams.max
  end

  t.min_radius = t.min_radius - 0.05
  t.max_radius = t.max_radius + 0.05

  return FinishParams(sl, player, force, t)
end


function MakeLineParams(sl, player, force, wParams, edgeType)
  local t =
  {
    color = colorVibr,
    width = 3, -- pixels
  }

  local angle = 0
  if edgeType == EDGE_LEFT then
    angle = wParams.angleStart
  else
    angle = wParams.angleStart + wParams.len
  end

  t.to   = u.ScreenOrientationToPosition(sl.position, angle, wParams.min - 0.05)
  t.from = u.ScreenOrientationToPosition(sl.position, angle, wParams.max + 0.05)

  return FinishParams(sl, player, force, t)
end


function Render(g, player, force, wParams)
  local sl = g.light
  local ids = {}

  ids[1] = rendering.draw_arc(MakeArcParams(sl, player, force, wParams))
  ids[2] = rendering.draw_arc(MakeEdgeParams(sl, player, force, wParams, EDGE_INNER))
  ids[3] = rendering.draw_arc(MakeEdgeParams(sl, player, force, wParams, EDGE_OUTER))

  if wParams.len < (math.pi*2) then
    ids[4] = rendering.draw_line(MakeLineParams(sl, player, force, wParams, EDGE_LEFT))
    ids[5] = rendering.draw_line(MakeLineParams(sl, player, force, wParams, EDGE_RIGHT))
  end

  return ids
end


function Unrender(epochAndRender)
  if epochAndRender and epochAndRender[2] then
    for _, rID in pairs(epochAndRender[2]) do
      rendering.destroy(rID)
    end
    epochAndRender[2] = nil 
  end
end


function ClearGestaltRender(gID)
  local pIndexToEpochAndRenderMap = global.slFOVRenders[gID]
  for pIndex, epochAndRender in pairs(pIndexToEpochAndRenderMap) do
    Unrender(epochAndRender)
  end
  global.slFOVRenders[gID] = nil
end


function DrawTurtlePos(player, g)
  if not global.tposRenders[player.index] then
    local rID = rendering.draw_sprite{sprite  = "utility/shoot_cursor_green", 
                                      target  = g.turtle, 
                                      surface = g.turtle.surface,
                                      players = {player},
                                      x_scale = 0.4,
                                      y_scale = 0.48,}

    global.tposRenders[player.index] = {g, rID}
  end
end


function DrawSearchArea(sl, player, force, forceRedraw)
  local g = global.unum_to_g[sl.unit_number]
  if not g or not g.tAdjParams then
    return
  end

  -- Don't show radius for default-params light unless moused over, it's too big & annoying
  -- (Unless the radius was just set from something else _to_ the default-params)
  local params = g.tAdjParams
  if  not forceRedraw
      and params.len == twoPi
      and params.min == 1
      and params.max == d.searchlightRange then
    return
  end

  local gID = g.gID

  if not global.slFOVRenders[gID] then
    global.slFOVRenders[gID] = {}
  end

  -- If the whole force just saw this area, no need to redraw for just one of its players
  -- (which would cause a double-draw and render it twice as bright as intended)
  if player and not global.slFOVRenders[gID][0] then
    local pIndex = player.index
    Unrender(global.slFOVRenders[gID][pIndex])
    global.slFOVRenders[gID][pIndex] = {game.tick, Render(g, player, force, params)}
  elseif force then
    for index, _ in pairs(global.slFOVRenders[gID]) do
      Unrender(global.slFOVRenders[gID][index])
    end

    global.slFOVRenders[gID][0] = {game.tick, Render(g, player, force, params)}
  end
end


function Update(tick)
  local added = {}

  for gID, pIndexToEpochAndRenderMap in pairs(global.slFOVRenders) do
    local g = global.gestalts[gID]

    if not g or not next(pIndexToEpochAndRenderMap) then
      ClearGestaltRender(gID)
    else
      for pIndex, epochAndRender in pairs(pIndexToEpochAndRenderMap) do
        local player = nil
        local force = nil

        if pIndex == 0 and (game.tick - epochAndRender[1]) == wireFrameTTL then
          local force = g.light.force

          -- If a player is still mousing over this light, or has its GUI open,
          -- then keep showing its range for that player
          for _, p in pairs(force.players) do
            local gAndGUI = global.pIndexToGUI[p.index]
            if     (p.selected == g.light or p.selected == g.signal)
                or (gAndGUI and gAndGUI[1] == g.gID) then
              -- Unsafe to add to map while iterating it, 
              -- so push back to a temp variable and add later
              table.insert(added, {g = g, p = p})
            end
          end

          Unrender(epochAndRender)
          pIndexToEpochAndRenderMap[pIndex] = nil
          -- If this just emptied the outer map, we'll clear it next tick by checking next()

        elseif pIndex > 0 and game.players[pIndex] and game.players[pIndex].selected ~= g.light then          
          local gAndGUI = global.pIndexToGUI[pIndex]
          -- Keep delaying the Unrender while the player has the GUI open
          if not gAndGUI or gAndGUI[1] ~= g.gID then
            Unrender(epochAndRender)
            pIndexToEpochAndRenderMap[pIndex] = nil
            -- If this just emptied the outer map, we'll clear it next tick by checking next()

          end
        end
      end
    end

  end

  for _, entry in pairs(added) do
    local g = entry.g
    local p = entry.p
    Unrender(entry)
    global.slFOVRenders[g.gID][p.index] = {game.tick, Render(g, p, nil, g.tAdjParams)}
  end

  -- Finally, update turtle position rendering for players
  -- who are mousing over a searchlight or have its GUI open
  for pIndex, gAndRID in pairs(global.tposRenders) do
    if game.players[pIndex] then
      local g = gAndRID[1]

      if g and g.light and g.light.valid and g.turtle and g.turtle.valid
           and game.players[pIndex].selected == g.light then
        if rendering.is_valid(gAndRID[2]) then
          rendering.set_target(gAndRID[2], g.turtle)
        else
          global.tposRenders[pIndex] = nil
          export.DrawTurtlePos(game.players[pIndex], g)
        end
      else
        rendering.destroy(gAndRID[2])
        global.tposRenders[pIndex] = nil
      end
    else
      rendering.destroy(gAndRID[2])
      global.tposRenders[pIndex] = nil
    end
  end
end

----------------------------------------------------------------
  local public = {}
  public.ClearGestaltRender = ClearGestaltRender
  public.Unrender = Unrender
  public.Render = Render
  public.MakeLineParams = MakeLineParams
  public.MakeEdgeParams = MakeEdgeParams
  public.MakeArcParams = MakeArcParams
  public.FinishParams = FinishParams
  public.Update = Update
  public.DrawSearchArea = DrawSearchArea
  public.DrawTurtlePos = DrawTurtlePos
  public.InitTables_Render = InitTables_Render
  return public
----------------------------------------------------------------
