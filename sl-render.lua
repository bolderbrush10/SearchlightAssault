local export = {}

local d = require("sl-defines")
local u = require("sl-util")

local wireFrameTTL = 240

local colorDrab = {r=0.08, g=0.04, b=0, a=0.0}
local colorVibr = {r=0.16, g=0.08, b=0, a=0.0}


-- TODO test with old save from user
-- TODO Migration file to add this global variable?


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

  if player then
    t.players = {player}
  end

  if force then
    t.forces = {force}
  end

  return t
end


-- TODO Need to handle minDist == maxDist
local function Render(sl, player, force, wParams)
  return rendering.draw_arc(MakeArcParams(sl, player, force, wParams))
end


local function Unrender(epochAndRender)
  if epochAndRender[2] then
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


-- TODO Don't render for players on enemy force
-- TODO Stop showing radius for default-params light unless moused over, it's too big & annoying
--      (Unless the radius was just set from something else _to_ the default-params)
-- TODO Need to test setting hundreds of searchlight areas at once over circuit network
-- TODO creating a searchlight and immediately giving it circuit conditions
--      causes it to forever render its initial, default search area...
-- Map: gID -> 0/playerIndex -> {epochTick, render_id}
export.DrawSearchArea = function(sl, player, force, forceRedraw)
  game.print("Draw search area: " .. game.tick .. ": " .. sl.unit_number .. " " .. serpent.block(player) .. " " .. serpent.block(force) .. " " .. serpent.block(forceRedraw))

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

  local pIndexToEpochAndRenderMap = global.slFOVRenders[gID]

  -- If the whole force just saw this area, no need to redraw for just one of its players
  -- (Which would case a double-draw and render it twice as bright as intended)
  if  not forceRedraw
      and (pIndexToEpochAndRenderMap[pIndex] or pIndexToEpochAndRenderMap[0]) then
    return
  else
    pIndexToEpochAndRenderMap[pIndex] = {game.tick, nil}
  end

  Unrender(pIndexToEpochAndRenderMap[pIndex])

  pIndexToEpochAndRenderMap[pIndex] = {game.tick, Render(sl, player, force, g.tAdjParams)}
end


-- Map: gID -> 0/playerIndex -> {epochTick, render_id}
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

        if pIndex == 0 then
          force = g.light.force
        else
          player = game.players[pIndex]
        end

        if force and (game.tick - epochAndRender[1]) == wireFrameTTL then
          -- If a player is still mousing over this light,
          -- then keep showing its range for that player
          -- TODO Does this make sense in multiplayer?
          for _, p in pairs(force.players) do
            if p.selected == g.light then
              -- Unsafe to add to map while iterating it
              table.insert(added, {p = p, g = g})
            end
          end

          Unrender(epochAndRender)
          pIndexToEpochAndRenderMap[pIndex] = nil
          -- If this just emptied the outer map, we'll clear it next tick by checking next()
        elseif player and player.selected ~= g.light then
          Unrender(epochAndRender)
          pIndexToEpochAndRenderMap[pIndex] = nil
          -- If this just emptied the outer map, we'll clear it next tick by checking next()
        end

      end
    end

  end

  for _, entry in pairs(added) do
    local g = entry.g
    local p = entry.p
    global.slFOVRenders[g.gID][p.index] = {game.tick, Render(g.light, p, nil, g.tAdjParams)}
  end
end


return export