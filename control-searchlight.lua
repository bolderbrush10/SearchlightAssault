local d = require "sl-defines"

local ct = require "control-turtle"


local export = {}


local FoePositionXSlot = 1
local FoePositionYSlot = 2
local WarningSlot = 3
local AlarmSlot = 4

local signalX = {type="virtual", name="signal-X"}
local signalY = {type="virtual", name="signal-Y"}
local signalW = {type="virtual", name="signal-W"}
local signalA = {type="virtual", name="signal-A"}


--------------------
--  Helper Funcs  --
--------------------


local function FindSignalInterfaceGhosts(sl)
  local ghosts = sl.surface.find_entities_filtered{position = sl.position,
                                                   ghost_name = d.searchlightSignalInterfaceName,
                                                   force = sl.force,
                                                   limit = 1}

  if ghosts and ghosts[1] and ghosts[1].valid then
    -- The revived entity should be returned as the 2nd return value, or nil if that fails
    return ghosts[1].revive{raise_revive = false}[2]
  end

  return nil
end


local function FindSignalInterfacePrebuilt(sl)
  local prebs = sl.surface.find_entities_filtered{position = sl.position,
                                                  name = d.searchlightSignalInterfaceName,
                                                  force = sl.force,
                                                  limit = 1}

  if prebs and prebs[1] and prebs[1].valid then
    return prebs[1]
  end

  return nil
end


local function FindSignalInterface(sl)
  -- If there's already a ghost / ghost-built signal interface,
  -- just create / use it before trying to spawn a new one
  local i = FindSignalInterfaceGhosts(sl)
  if i then
    return i
  end

  i = FindSignalInterfacePrebuilt(sl)
  if i then
    return i
  end

  return sl.surface.create_entity{name = d.searchlightSignalInterfaceName,
                                  position = sl.position,
                                  force = sl.force,
                                  create_build_effect_smoke = false}
end


local function OutputCircuitSignals(g)
  if g.light.name == d.searchlightBaseName then
    export.ProcessAlarmClearSignals(g)
  else
    export.ProcessAlarmRaiseSignals(g)
  end
end


--------------------
--     Events     --
--------------------

-- Checked only a few times a second
export.CheckCircuitConditions = function()
  for gID, g in pairs(global.gestalts) do
    if     g.light.energy > 0
       and (g.signal.get_circuit_network(defines.wire_type.red)
         or g.signal.get_circuit_network(defines.wire_type.green)) then
      OutputCircuitSignals(g)
    end
  end
end


-- Called by CheckCircuitConditions, but also when an alarm is cleared
export.ProcessAlarmClearSignals = function(g)
  local i = g.signal
  local c = i.get_control_behavior()

  c.set_signal(FoePositionXSlot, {signal = signalX, count = 0})
  c.set_signal(FoePositionYSlot, {signal = signalY, count = 0})
  c.set_signal(AlarmSlot,        {signal = signalA, count = 0})
  c.set_signal(WarningSlot,      {signal = signalW, count = (g.turtle.distraction_command and 1 or 0)})

  local x = i.get_merged_signal({type="virtual", name="signal-X"})
  local y = i.get_merged_signal({type="virtual", name="signal-Y"})

  if g.tState ~= ct.FOLLOW and (x ~= 0 or y ~= 0) then
    ct.ManualTurtleMove(g, {x=x, y=y})
  elseif g.tState ~= ct.FOLLOW then
    g.tState = ct.WANDER
  end
end


-- Called by CheckCircuitConditions, but also when an alarm is raised
export.ProcessAlarmRaiseSignals = function(g)
  local i = g.signal
  local c = i.get_control_behavior()

  if g.light.shooting_target and g.light.shooting_target.valid then
    local pos = g.light.shooting_target.position
    c.set_signal(FoePositionXSlot, {signal = signalX, count = pos.x})
    c.set_signal(FoePositionYSlot, {signal = signalY, count = pos.y})
  end

  c.set_signal(AlarmSlot,        {signal = signalA, count = 1})
  c.set_signal(WarningSlot,      {signal = signalW, count = 0})
end


-- Called when a new searchlight is built
export.SpawnSignalInterface = function(sl)
  -- Attempts to find existing / ghost interfaces before spawning a new one
  local i = FindSignalInterface(sl)

  i.operable = false
  i.rotatable = false
  i.destructible = false

  i.get_control_behavior().set_signal(FoePositionXSlot, {signal = signalX, count = 0})
  i.get_control_behavior().set_signal(FoePositionYSlot, {signal = signalY, count = 0})
  i.get_control_behavior().set_signal(AlarmSlot,        {signal = signalA, count = 0})
  i.get_control_behavior().set_signal(WarningSlot,      {signal = signalW, count = 0})

  return i
end


return export
