local e = {} -- export functions

e.onTick = function(event)
  local tick = event.tick

  -- Run seperate loops for gestalts vs turrets since they
  -- could possibly be in seperate electric networks
  cg.CheckElectricNeeds()
  cu.CheckAmmoElectricNeeds()

  cg.CheckGestaltFoes()

  if global.spotter_timeouts[tick] then
    cg.CloseWatch(global.spotter_timeouts[tick])
    global.spotter_timeouts[tick] = nil
  end

  for syncTick, list in pairs(global.animation_sync) do
    if tick == syncTick then
      cg.SyncReady(list)
      -- Should be safe to remove from table while iterating in lua      
      global.animation_sync[tick] = nil
    else
      cg.CheckSync(list)
    end
  end

  for pIndex, gAndGUI in pairs(global.pIndexToGUI) do
    local gID = gAndGUI[1]
    if cgui.validatePlayerAndLight(pIndex, gID) and cgui.validateGUI(gAndGUI[2]) then
      local g = global.gestalts[gID]
      cgui.updateOnTick(g, gAndGUI[2])
      -- Update the wander parameters, just in case this searchlight is in safe mode
      cs.ReadWanderParameters(g, g.signal, g.signal.get_control_behavior())
    else
      -- Should be safe to remove from table while iterating in lua
      cgui.CloseSearchlightGUI(pIndex)
    end
  end

  rd.Update(event.tick)
end

return e



-- On Tick
script.on_event(defines.events.on_tick, ot.onTick)


-- TODO Move into control-tick.lua
-- Run twice a second (at 60 updates per second)
script.on_nth_tick(30,
function(event)

  cs.CheckCircuitConditions()

end)
