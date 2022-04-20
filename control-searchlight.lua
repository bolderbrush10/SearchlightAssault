local d = require "sl-defines"
local u = require "sl-util"

local ct = require "control-turtle"
local rd = require "sl-render"

local cgui = require "control-gui"


local export = {}

-- hardcoded name lookup below for an ever-so-slight speedup
local sigDirectX = {type="virtual", name="sl-x"}
local sigDirectY = {type="virtual", name="sl-y"}
local sigFoeX    = {type="virtual", name="foe-x-position"}
local sigFoeY    = {type="virtual", name="foe-y-position"}
local sigWarn    = {type="virtual", name="sl-warn"}
local sigAlarm   = {type="virtual", name="sl-alarm"}
local sigOwnX    = {type="virtual", name="sl-own-x"}
local sigOwnY    = {type="virtual", name="sl-own-y"}
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


local function OutputCircuitSignals(g, tick)
  if g.light.name == d.searchlightAlarmName then
    export.ProcessAlarmRaiseSignals(g)
  else
    export.ProcessAlarmClearSignals(g, tick)
  end  
end


-- valid directions: 0 - 7
-- Normally, players rotate things in increments of 2 (90 degrees),
-- so we'll roll that back by one unit to get 45 degree changes.
-- We can compare oldDir to the current direction to figure out
-- whether the player is rotating clockwise or counterclockwise.
local function RotateDirByOne(g, light, oldDir)
  local newDir = light.direction

  -- Detect clockwise looparound
  if oldDir == 6 and newDir == 0 then
    return 45
  end
  if oldDir == 7 and newDir == 1 then
    return 45
  end

  -- Detect counter-clockwise looparound
  if oldDir == 0 and newDir == 6 then
    return -45
  end
  if oldDir == 1 and newDir == 7 then
    return -45
  end

  -- Detect clockwise procession
  if oldDir < newDir then
    return 45
  end

  -- counterclockwise is the only remaining case
  return -45
end


--------------------
--     Events     --
--------------------

export.ReadWanderParameters = function(g, i, c)
  local i = g.signal
  local c = i.get_control_behavior()

  local connected = (i.get_circuit_network(defines.wire_type.red)
                  or i.get_circuit_network(defines.wire_type.green))
  local rad = 0
  local rot = 0
  local min = 0
  local max = 0

  if connected then
    rad = i.get_merged_signal(sigRadius)
    rot = i.get_merged_signal(sigRotate)
    min = i.get_merged_signal(sigMin)
    max = i.get_merged_signal(sigMax)
  else
    rad = c.get_signal(d.circuitSlots.radiusSlot).count
    rot = c.get_signal(d.circuitSlots.rotateSlot).count
    min = c.get_signal(d.circuitSlots.minSlot).count
    max = c.get_signal(d.circuitSlots.maxSlot).count
  end

  ct.UpdateWanderParams(g, rad, rot, min, max)
end


-- Checked only a few times a second
export.CheckCircuitConditions = function()
  local tick = game.tick
  for gID, g in pairs(global.check_power) do
    if g.light.valid and g.signal.valid then
      if g.light.energy > 0 then
        OutputCircuitSignals(g, tick)
      end
    -- else
      -- Something nuked our mod's searchlight, we'll clean up in the next on_tick()
    end
  end
end


-- Called by CheckCircuitConditions, but also when an alarm is cleared
export.ProcessAlarmClearSignals = function(g, tick)
  local i = g.signal
  local c = i.get_control_behavior()

  local warning = 0
  -- Do I want to use d.searchlightSafeTime? A constant 2 seconds seems good...
  if g.lastSpotted and (tick - g.lastSpotted) < 120 then
    warning = 1
  end

  -- TODO It turns out that setting signals every nth tick is pretty expensive. (reads are fairly cheap)
  c.set_signal(d.circuitSlots.foePositionXSlot, {signal = sigFoeX,  count = 0})
  c.set_signal(d.circuitSlots.foePositionYSlot, {signal = sigFoeY,  count = 0})
  c.set_signal(d.circuitSlots.alarmSlot,        {signal = sigAlarm, count = 0})
  c.set_signal(d.circuitSlots.warningSlot,      {signal = sigWarn,  count = warning})

  local x = i.get_merged_signal({type="virtual", name="sl-x"})
  local y = i.get_merged_signal({type="virtual", name="sl-y"})

  if g.tState ~= ct.FOLLOW and (x ~= 0 or y ~= 0) then
    ct.ManualTurtleMove(g, {x=x, y=y})
  elseif g.tState ~= ct.FOLLOW then
    g.tState = ct.WANDER
  end

  -- TODO This is another expensive function
  export.ReadWanderParameters(g, i, c)  
end


-- Called by CheckCircuitConditions, but also when an alarm is raised
export.ProcessAlarmRaiseSignals = function(g)
  local i = g.signal
  local c = i.get_control_behavior()

  if g.light.shooting_target and g.light.shooting_target.valid then
    local pos = g.light.shooting_target.position
    c.set_signal(d.circuitSlots.foePositionXSlot, {signal = sigFoeX, count = pos.x})
    c.set_signal(d.circuitSlots.foePositionYSlot, {signal = sigFoeY, count = pos.y})
  end

  c.set_signal(d.circuitSlots.alarmSlot,        {signal = sigAlarm, count = 1})
  c.set_signal(d.circuitSlots.warningSlot,      {signal = sigWarn, count = 0})  
end


export.ProcessSafeSignals = function(g)
  local i = g.signal
  local c = i.get_control_behavior()

  c.set_signal(d.circuitSlots.alarmSlot,        {signal = sigAlarm, count = 0})
  c.set_signal(d.circuitSlots.warningSlot,      {signal = sigWarn,  count = 0})
end


-- Called when a new searchlight is built
export.SpawnSignalInterface = function(sl)
  -- Attempts to find existing / ghost interfaces before spawning a new one
  local i = FindSignalInterface(sl)

  i.operable = false
  i.destructible = false

  i.get_control_behavior().set_signal(d.circuitSlots.radiusSlot, {signal = sigRadius,  count = 0})
  i.get_control_behavior().set_signal(d.circuitSlots.rotateSlot, {signal = sigRotate,  count = 0})
  i.get_control_behavior().set_signal(d.circuitSlots.minSlot,    {signal = sigMin,     count = 0})
  i.get_control_behavior().set_signal(d.circuitSlots.maxSlot,    {signal = sigMax,     count = 0})
  i.get_control_behavior().set_signal(d.circuitSlots.dirXSlot,   {signal = sigDirectX, count = 0})
  i.get_control_behavior().set_signal(d.circuitSlots.dirYSlot,   {signal = sigDirectY, count = 0})

  i.get_control_behavior().set_signal(d.circuitSlots.ownPositionXSlot, {signal = sigOwnX,  count = i.position.x})
  i.get_control_behavior().set_signal(d.circuitSlots.ownPositionYSlot, {signal = sigOwnY,  count = i.position.y})
  i.get_control_behavior().set_signal(d.circuitSlots.alarmSlot,        {signal = sigAlarm, count = 0})
  i.get_control_behavior().set_signal(d.circuitSlots.warningSlot,      {signal = sigWarn,  count = 0})
  i.get_control_behavior().set_signal(d.circuitSlots.foePositionXSlot, {signal = sigFoeX,  count = 0})
  i.get_control_behavior().set_signal(d.circuitSlots.foePositionYSlot, {signal = sigFoeY,  count = 0})

  return i
end


export.Rotated = function(g, light, oldDir, pIndex)
  if not g.tWanderParams then
    g.tWanderParams = {}
  end
  if not g.tWanderParams.rotation then
    g.tWanderParams.rotation = 0
  end

  local newRot = RotateDirByOne(g, light, oldDir)

  ct.UpdateWanderParams(g, g.tWanderParams.radius, g.tWanderParams.rotation + newRot, 
                        g.tWanderParams.min, g.tWanderParams.max)
  rd.DrawSearchArea(g.light, nil, g.light.force)

  local control = g.signal.get_control_behavior()
  local sig = control.get_signal(d.circuitSlots.rotateSlot)

  -- We'll clamp the value down here so we don't try to factor in circuit signals
  sig.count = u.clampDeg(sig.count + newRot, 0, true)
  control.set_signal(d.circuitSlots.rotateSlot, sig)

  local player = game.players[pIndex]
  if player and player.valid then
    cgui.Rotated(g) -- Treat rotation like it was a text input
  end
end


return export
