local export = {}

local d = require("sl-defines")
local u = require("sl-util")

local wireFrameTTL = 240

local colorDrab = {r=0.08, g=0.04, b=0, a=0.0}
local colorVibr = {r=0.16, g=0.08, b=0, a=0.0}

local twoPi = 2 * math.pi


-- The map helps limit UI redraws for a given searchlight
export.InitTables_Render = function()
  -- Map: gID -> 0/playerIndex -> {epochTick, render_id}
  global.slFOVRenders = {}
end


-- angles: {min,   max,   start,   len}
--          tiles, tiles, radians, radians
local function MakeArcParams(sl, player, force, wParams)
  local t =
  {
    color = colorDrab,
    min_radius = wParams.min, -- tiles
    max_radius = wParams.max, -- tiles
    start_angle= wParams.angleStart, -- radians
    angle = wParams.len, -- radians
    target = sl.position,
    surface = sl.surface,
    time_to_live = 0, -- live until destroyed
    draw_on_ground = true,
  }

  if t.min_radius == t.max_radius then
    t.max_radius = t.min_radius - 0.2
    t.min_radius = t.max_radius + 0.2
  end

  if player then
    t.players = {player}
  end

  if force then
    t.forces = {force}
  end

  return t
end


local function Render(sl, player, force, wParams)
  return rendering.draw_arc(MakeArcParams(sl, player, force, wParams))
end


local function Unrender(epochAndRender)
  if epochAndRender and epochAndRender[2] then
    rendering.destroy(epochAndRender[2])
  end
end


local function ClearGestaltRender(gID)
  local pIndexToEpochAndRenderMap = global.slFOVRenders[gID]
  for pIndex, epochAndRender in pairs(pIndexToEpochAndRenderMap) do
    Unrender(epochAndRender)
  end
  global.slFOVRenders[gID] = nil
end


export.DrawSearchArea = function(sl, player, force, forceRedraw)
  local g = global.unum_to_g[sl.unit_number]
  if not g or not g.tAdjParams then
    return
  end

  -- Don't show radius for default-params light unless moused over, it's too big & annoying
  -- (Unless the radius was just set from something else _to_ the default-params)
  local params = g.tAdjParams
  if  not forceRedraw
      and params.angleStart == 0
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
    global.slFOVRenders[gID][pIndex] = {game.tick, Render(sl, player, force, params)}
  elseif force then
    for index, _ in pairs(global.slFOVRenders[gID]) do
      Unrender(global.slFOVRenders[gID][index])
    end

    global.slFOVRenders[gID][0] = {game.tick, Render(sl, player, force, params)}
  end
end


export.Update = function(tick)
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
    global.slFOVRenders[g.gID][p.index] = {game.tick, Render(g.light, p, nil, g.tAdjParams)}
  end
end


return export
