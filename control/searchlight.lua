----------------------------------------------------------------
  local b = require "bidirmap"

  local d = require "sl-defines"
  local u = require "sl-util"

  -- forward declarations
  local spawnSpotter
  local spawnSignalInterface
  local findSignalInterface
  local reviveInterfaceGhosts
  local findSignalInterfacePrebuilt
  local regLight
  local deregLight
  local spawnWarnLight
  local spawnAlarmLight
  local spawnSafeLight
  local CheckCircuitConditions
----------------------------------------------------------------


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


-- The spotter exists to keep an eye out for enemies in the general vicinity.
-- If the spotter can't find anything, we can put our searchlight to 'sleep'
-- and save a ton of CPU usage.
function spawnSpotter(sl, turtleForce)
  local spotter = sl.surface.create_entity{name = d.spotterName,
                                           position = sl.position,
                                           force = turtleForce,
                                           create_build_effect_smoke = false}
  spotter.destructible = false

  return spotter
end


function spawnSignalInterface(sl)
  -- Attempts to find existing / ghost interfaces before spawning a new one
  local i, revived = findSignalInterface(sl)

  i.operable = false
  i.destructible = false

  local c = i.get_control_behavior()

  local slRotation = u.clampDeg(360 * sl.orientation, 0, true) -- orientation goes 0.0-1
  if not revived then
    -- TODO Maybe don't reset these values?
    --      If something blew up a searchlight, we'd probably want it to keep
    --      its settings when a bot rebuilds it.
    c.set_signal(d.circuitSlots.radiusSlot, {signal = sigRadius,  count = 0})
    c.set_signal(d.circuitSlots.rotateSlot, {signal = sigRotate,  count = slRotation})
    c.set_signal(d.circuitSlots.minSlot,    {signal = sigMin,     count = 0})
    c.set_signal(d.circuitSlots.maxSlot,    {signal = sigMax,     count = 0})
    c.set_signal(d.circuitSlots.dirXSlot,   {signal = sigDirectX, count = 0})
    c.set_signal(d.circuitSlots.dirYSlot,   {signal = sigDirectY, count = 0})
  else
    local oldRotation = c.get_signal(d.circuitSlots.rotateSlot).count
    local diff = oldRotation - slRotation
    local newRot = u.clampDeg(oldRotation - diff, 0, true)
    c.set_signal(d.circuitSlots.rotateSlot, {signal = sigRotate,  count = newRot})
  end

  c.set_signal(d.circuitSlots.ownPositionXSlot, {signal = sigOwnX,  count = i.position.x})
  c.set_signal(d.circuitSlots.ownPositionYSlot, {signal = sigOwnY,  count = i.position.y})
  c.set_signal(d.circuitSlots.alarmSlot,        {signal = sigAlarm, count = 0})
  c.set_signal(d.circuitSlots.warningSlot,      {signal = sigWarn,  count = 0})
  c.set_signal(d.circuitSlots.foePositionXSlot, {signal = sigFoeX,  count = 0})
  c.set_signal(d.circuitSlots.foePositionYSlot, {signal = sigFoeY,  count = 0})

  return i
end


function findSignalInterface(sl)
  -- If there's already a ghost / ghost-built signal interface,
  -- just create / use it before trying to spawn a new one
  reviveInterfaceGhosts(sl)
  i = findSignalInterfacePrebuilt(sl)
  if i then
    return i, true
  end

  return sl.surface.create_entity{name = d.searchlightSignalInterfaceName,
                                  position = sl.position,
                                  force = sl.force,
                                  create_build_effect_smoke = false}
end


function reviveInterfaceGhosts(sl)
  local ghosts = sl.surface.find_entities_filtered{position = sl.position,
                                                   ghost_name = d.searchlightSignalInterfaceName,
                                                   force = sl.force,
                                                   limit = 1}

  if ghosts and ghosts[1] and ghosts[1].valid then
    ghosts[1].silent_revive{raise_revive = false}
    -- No point in returning anything, revive()'s return values never seem to work
  end
end


function findSignalInterfacePrebuilt(sl)
  local prebs = sl.surface.find_entities_filtered{position = sl.position,
                                                  name = d.searchlightSignalInterfaceName,
                                                  force = sl.force,
                                                  limit = 1}

  if prebs and prebs[1] and prebs[1].valid then
    return prebs[1]
  end

  return nil
end


function spawnWarnLight(g)
  if g.light.name == d.searchlightBaseName then
    return -- Alarm already at Warn
  end

  local old = g.light
  local warn = old.surface.create_entity{name = d.searchlightBaseName,
                                         position = old.position,
                                         force = old.force,
                                         create_build_effect_smoke = false}

  u.CopyTurret(old, warn)

  deregLight(g, old)
  regLight(g, warn)

  old.destroy()
end


function spawnAlarmLight(g)
  if g.light.name == d.searchlightAlarmName then
    return -- Alarm already raised
  end

  local old = g.light
  local alarm = old.surface.create_entity{name = d.searchlightAlarmName,
                                          position = old.position,
                                          force = old.force,
                                          create_build_effect_smoke = false}

  u.CopyTurret(old, alarm)

  deregLight(g, old)
  regLight(g, warn)

  old.destroy()

  -- Note how many times we've spotted a foe, just for fun
  alarm.kills = alarm.kills + 1
end


function spawnSafeLight(g)
  if g.light.name == d.searchlightSafeName then
    return -- Already in safe mode
  end

  local old = g.light
  local safe = old.surface.create_entity{name = d.searchlightSafeName,
                                         position = old.position,
                                         force = old.force,
                                         create_build_effect_smoke = false}

  u.CopyTurret(old, safe)

  deregLight(g, old)
  regLight(g, warn)

  old.destroy()
end


-- Checked only a few times a second
function CheckCircuitConditions()
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


function OutputCircuitSignals(g, tick)
  if g.light.name == d.searchlightAlarmName then
    ProcessAlarmRaiseSignals(g)
  else
    ProcessAlarmClearSignals(g, tick)
  end  
end


-- Called by CheckCircuitConditions, but also when an alarm is cleared
function ProcessAlarmClearSignals(g, tick)
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

  local connected = (i.get_circuit_network(defines.wire_type.red)
                  or i.get_circuit_network(defines.wire_type.green))
  local x = 0
  local y = 0

  if connected then
    x = i.get_merged_signal({type="virtual", name="sl-x"})
    y = i.get_merged_signal({type="virtual", name="sl-y"})
  else
    x = c.get_signal(d.circuitSlots.dirXSlot).count
    y = c.get_signal(d.circuitSlots.dirYSlot).count
  end

  -- TODO
  -- if g.tState ~= ct.FOLLOW and (x ~= 0 or y ~= 0) then
  --   ct.ManualTurtleMove(g, {x=x, y=y})
  -- elseif g.tState ~= ct.FOLLOW then
  --   g.tState = ct.WANDER
  -- end

  -- TODO This is another expensive function
  ReadWanderParameters(g, i, c)  
end

function ReadWanderParameters(g, i, c)
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

  -- TODO
  -- ct.UpdateWanderParams(g, rad, rot, min, max)
end


-- Called by CheckCircuitConditions, but also when an alarm is raised
function ProcessAlarmRaiseSignals(g)
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


function ProcessSafeSignals(g)
  local i = g.signal
  local c = i.get_control_behavior()

  c.set_signal(d.circuitSlots.alarmSlot,        {signal = sigAlarm, count = 0})
  c.set_signal(d.circuitSlots.warningSlot,      {signal = sigWarn,  count = 0})
end



----------------------------------------------------------------
  local public = {}
  public.spawnSpotter = spawnSpotter
  public.spawnSignalInterface = spawnSignalInterface
  public.regLight = regLight
  public.spawnWarnLight = spawnWarnLight
  public.spawnAlarmLight = spawnAlarmLight
  public.spawnSafeLight = spawnSafeLight
  public.CheckCircuitConditions = CheckCircuitConditions  
  return public
----------------------------------------------------------------
