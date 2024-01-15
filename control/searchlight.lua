----------------------------------------------------------------
  local b = require "bidirmap"

  local d = require "../sl-defines"
  local u = require "../sl-util"

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
  regSupport(spotter)

  return spotter
end


function spawnSignalInterface(sl)
  -- Attempts to find existing / ghost interfaces before spawning a new one
  local i, revived = findSignalInterface(sl)

  i.operable = false
  i.destructible = false
  regSupport(i)

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


function regSupport(g, e)
  global.unum_to_g[e.unit_number] = g
  b.add(g.unum_x_reg, e.unit_number, script.register_on_entity_destroyed(e), g)
end


function regLight(g, sl)
  global.unum_to_g[sl.unit_number] = g
  b.add(g.unum_x_reg, sl.unit_number, script.register_on_entity_destroyed(sl), g)

  g.light = sl
end


function deregLight(g, sl)
  global.unum_to_g[sl.unit_number] = nil
  b.removeLHS(g.unum_x_reg, sl.unit_number)
end


----------------------------------------------------------------
  local public = {}
  public.spawnSpotter = spawnSpotter
  public.spawnSignalInterface = spawnSignalInterface
  public.regLight = regLight
  public.spawnWarnLight = spawnWarnLight
  public.spawnAlarmLight = spawnAlarmLight
  public.spawnSafeLight = spawnSafeLight
  return public
----------------------------------------------------------------
