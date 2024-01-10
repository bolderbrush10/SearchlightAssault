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


local function ReviveInterfaceGhosts(sl)
  local ghosts = sl.surface.find_entities_filtered{position = sl.position,
                                                   ghost_name = d.searchlightSignalInterfaceName,
                                                   force = sl.force,
                                                   limit = 1}

  if ghosts and ghosts[1] and ghosts[1].valid then
    ghosts[1].silent_revive{raise_revive = false}
    -- No point in returning anything, revive()'s return values never seem to work
  end
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
  ReviveInterfaceGhosts(sl)
  i = FindSignalInterfacePrebuilt(sl)
  if i then
    return i, true
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
  local i, revived = FindSignalInterface(sl)

  i.operable = false
  i.destructible = false

  local c = i.get_control_behavior()

  local slRotation = u.clampDeg(360 * sl.orientation, 0, true) -- orientation goes 0.0-1
  if not revived then
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

  -- If there's a direct waypoint set, go ahead and rotate that
  if     g.tState == ct.MOVE 
      or g.tWanderParams.radius == 360 
      or g.tWanderParams.radius == 0 then
    if g.tState == ct.MOVE then
      local distSq = u.lensquared(u.TranslateCoordinate(g, g.tCoord), light.position)

      local theta = math.atan2(g.tCoord.y, g.tCoord.x)
      newCoord = u.ScreenOrientationToPosition(light.position, theta + newRot, math.sqrt(distSq))

      local dirX = control.get_signal(d.circuitSlots.dirXSlot)
      local dirY = control.get_signal(d.circuitSlots.dirYSlot)
      dirX.count = newCoord.x - light.position.x
      dirY.count = newCoord.y - light.position.y

      control.set_signal(d.circuitSlots.dirXSlot, dirX)
      control.set_signal(d.circuitSlots.dirYSlot, dirY)
    else
      local distSq = u.lensquared(g.turtle.position, light.position)
      local theta = (g.tWanderParams.rotation*math.pi)/180

      newCoord = u.ScreenOrientationToPosition(light.position, theta, math.sqrt(distSq))

      ct.WanderTurtle(g, newCoord)
    end
  end

  local player = game.players[pIndex]
  if player and player.valid then
    cgui.Rotated(g) -- Treat rotation like it was a text input
  end
end

------------------------
-- Spawner Functions  --
------------------------


local function SpawnAlarmLight(gestalt)
  if gestalt.light.name == d.searchlightAlarmName then
    return -- Alarm already raised
  end

  local base = gestalt.light
  local raised = base.surface.create_entity{name = d.searchlightAlarmName,
                                            position = base.position,
                                            force = base.force,
                                            fast_replace = false,
                                            create_build_effect_smoke = false}

  u.CopyTurret(base, raised)
  global.unum_to_g[base.unit_number] = nil
  global.unum_to_g[raised.unit_number] = gestalt
  script.register_on_entity_destroyed(raised)

  gestalt.light = raised
  -- Note how many times we've spotted a foe, just for fun
  raised.kills = raised.kills + 1 

  base.destroy()
end


local function SpawnBaseLight(gestalt)
  if gestalt.light.name == d.searchlightBaseName then
    return -- Alarm already cleared
  end

  local base = gestalt.light
  local cleared = base.surface.create_entity{name = d.searchlightBaseName,
                                             position = base.position,
                                             force = base.force,
                                             fast_replace = false,
                                             create_build_effect_smoke = false}

  u.CopyTurret(base, cleared)
  global.unum_to_g[base.unit_number] = nil
  global.unum_to_g[cleared.unit_number] = gestalt
  script.register_on_entity_destroyed(cleared)

  gestalt.light = cleared

  base.destroy()
end


local function SpawnSafeLight(gestalt)
  if gestalt.light.name == d.searchlightSafeName then
    return -- Already in safe mode
  end

  local base = gestalt.light
  local safe = base.surface.create_entity{name = d.searchlightSafeName,
                                          position = base.position,
                                          force = base.force,
                                          fast_replace = false,
                                          create_build_effect_smoke = false}

  u.CopyTurret(base, safe)
  global.unum_to_g[base.unit_number] = nil
  global.unum_to_g[safe.unit_number] = gestalt
  script.register_on_entity_destroyed(safe)
  
  gestalt.light = safe

  base.destroy()
end


export.SpawnSpotter = function(sl, turtleForce)
  local spotter = sl.surface.create_entity{name = d.spotterName,
                                           position = sl.position,
                                           force = turtleForce,
                                           create_build_effect_smoke = false}
  spotter.destructible = false

  return spotter
end


return export
