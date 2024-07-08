----------------------------------------------------------------
  local gui = require "gui"

  local gs = require "gestalt"
  local rd = require "render"
  local sl = require "searchlight"
  local tt = require "turret"
  -- forward declarations
  local onTick
----------------------------------------------------------------


-- On Tick
script.on_event(defines.events.on_tick, onTick)

-- Run twice a second (at 60 updates per second)
script.on_nth_tick(30, function(event)
  sl.CheckCircuitConditions()
end)


function onTick(event)
  -- Tiny optimization, reduces calls to global table
  local pairs = pairs
  local tick = event.tick

  -- Run seperate loops for gestalts vs turrets since they
  -- could possibly be in seperate electric networks
  gs.CheckElectricNeeds()
  tt.CheckAmmoElectricNeeds()

  gs.CheckGestaltFoes()

  if global.spotter_timeouts[tick] then
    gs.CloseWatch(global.spotter_timeouts[tick])
    global.spotter_timeouts[tick] = nil
  end

  for syncTick, list in pairs(global.animation_sync) do
    if tick == syncTick then
      gs.SyncReady(list)
      -- Should be safe to remove from table while iterating in lua      
      global.animation_sync[tick] = nil
    else
      gs.CheckSync(list)
    end
  end

  for pIndex, gAndGUI in pairs(global.pIndexToGUI) do
    local gID = gAndGUI[1]
    if gui.validatePlayerAndLight(pIndex, gID) and gui.validateGUI(gAndGUI[2]) then
      local g = global.gestalts[gID]
      gui.updateOnTick(g, gAndGUI[2])
      -- Update the wander parameters, just in case this searchlight is in safe mode
      sl.ReadWanderParameters(g, g.signal, g.signal.get_control_behavior())
    else
      -- Should be safe to remove from table while iterating in lua
      gui.CloseSearchlightGUI(pIndex)
    end
  end

  rd.Update(event.tick)
end

----------------------------------------------------------------
  local public = {}
  public.onTick = onTick
  return public
----------------------------------------------------------------
