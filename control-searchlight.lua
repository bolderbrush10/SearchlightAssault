local d = require "sl-defines"

local ct = require "control-turtle"
local rd = require "sl-render"


local export = {}


local FoePositionXSlot = 1
local FoePositionYSlot = 2
local WarningSlot = 3
local AlarmSlot = 4
local OwnPositionXSlot = 5
local OwnPositionYSlot = 6

-- hardcoded name lookup below for an ever-so-slight speedup
-- local sigDirectX = {type="virtual", name="signal-X"}
-- local sigDirectY = {type="virtual", name="signal-Y"}
local sigFoeX    = {type="virtual", name="foe-x-position"}
local sigFoeY    = {type="virtual", name="foe-y-position"}
local sigWarn    = {type="virtual", name="sl-warn"}
local sigAlarm   = {type="virtual", name="sl-alarm"}
local sigOwnX    = {type="virtual", name="signal-O"}
local sigOwnY    = {type="virtual", name="signal-P"}
local sigRadius  = {type="virtual", name="sl-radius"}
local sigMin     = {type="virtual", name="sl-minimum"}
local sigMax     = {type="virtual", name="sl-maximum"}
local sigRotate  = {type="virtual", name="sl-rotation"}

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


-- valid directions: 0 - 7
-- Players rotate things in increments of 2 (90 degrees),
-- so roll that back by one unit to get 45 degree changes.
-- We can compare oldDir to the current direction to figure out
-- whether the player is rotating clockwise or counterclockwise.
local function RotateDirByOne(g, light, oldDir)
  local newDir = light.direction

  -- Detect clockwise looparound
  if oldDir == 6 and newDir == 0 then
    g.tWanderParams.rotation = g.tWanderParams.rotation + 45
    light.direction = 7
    return
  end
  if oldDir == 7 and newDir == 1 then
    g.tWanderParams.rotation = g.tWanderParams.rotation + 45
    light.direction = 0
    return
  end


  -- Detect counter-clockwise looparound
  if oldDir == 0 and newDir == 6 then
    g.tWanderParams.rotation = g.tWanderParams.rotation - 45
    light.direction = 7
    return
  end
  if oldDir == 1 and newDir == 7 then
    g.tWanderParams.rotation = g.tWanderParams.rotation - 45
    light.direction = 0
    return
  end

  -- Detect clockwise procession
  if oldDir < newDir then
    g.tWanderParams.rotation = g.tWanderParams.rotation + 45
    light.direction = light.direction - 1
    return
  end

  -- counterclockwise is the only remaining case
  g.tWanderParams.rotation = g.tWanderParams.rotation - 45
  light.direction = light.direction + 1
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

  c.set_signal(FoePositionXSlot, {signal = sigFoeX, count = 0})
  c.set_signal(FoePositionYSlot, {signal = sigFoeY, count = 0})
  c.set_signal(AlarmSlot,        {signal = sigAlarm, count = 0})
  c.set_signal(WarningSlot,      {signal = sigWarn, count = (g.turtle.distraction_command and 1 or 0)})

  local x = i.get_merged_signal({type="virtual", name="sl-x"})
  local y = i.get_merged_signal({type="virtual", name="sl-y"})

  if g.tState ~= ct.FOLLOW and (x ~= 0 or y ~= 0) then
    ct.ManualTurtleMove(g, {x=x, y=y})
  elseif g.tState ~= ct.FOLLOW then
    g.tState = ct.WANDER

    local rad = i.get_merged_signal(sigRadius)
    local rot = i.get_merged_signal(sigRotate)
    local min = i.get_merged_signal(sigMin)
    local max = i.get_merged_signal(sigMax)

    ct.UpdateWanderParams(g, rad, rot, min, max)
  end
end


-- Called by CheckCircuitConditions, but also when an alarm is raised
export.ProcessAlarmRaiseSignals = function(g)
  local i = g.signal
  local c = i.get_control_behavior()

  if g.light.shooting_target and g.light.shooting_target.valid then
    local pos = g.light.shooting_target.position
    c.set_signal(FoePositionXSlot, {signal = sigFoeX, count = pos.x})
    c.set_signal(FoePositionYSlot, {signal = sigFoeY, count = pos.y})
  end

  c.set_signal(AlarmSlot,        {signal = sigAlarm, count = 1})
  c.set_signal(WarningSlot,      {signal = sigWarn, count = 0})
end


-- Called when a new searchlight is built
export.SpawnSignalInterface = function(sl)
  -- Attempts to find existing / ghost interfaces before spawning a new one
  local i = FindSignalInterface(sl)

  i.operable = false
  i.rotatable = false
  i.destructible = false

  i.get_control_behavior().set_signal(FoePositionXSlot, {signal = sigFoeX, count = 0})
  i.get_control_behavior().set_signal(FoePositionYSlot, {signal = sigFoeY, count = 0})
  i.get_control_behavior().set_signal(AlarmSlot,        {signal = sigAlarm, count = 0})
  i.get_control_behavior().set_signal(WarningSlot,      {signal = sigWarn, count = 0})

  i.get_control_behavior().set_signal(OwnPositionXSlot, {signal = sigOwnX, count = i.position.x})
  i.get_control_behavior().set_signal(OwnPositionYSlot, {signal = sigOwnY, count = i.position.y})

  return i
end


export.Rotated = function(g, light, oldDir)
  if not g.tWanderParams then
    g.tWanderParams = {}
  end
  if not g.tWanderParams.rotation then
    g.tWanderParams.rotation = 0
  end

  RotateDirByOne(g, light, oldDir)
  ct.UpdateWanderParams(g, g.tWanderParams.radius, g.tWanderParams.rotation, 
                        g.tWanderParams.min, g.tWanderParams.max)
  rd.DrawSearchArea(g.light, nil, g.light.force, true)
end


return export
