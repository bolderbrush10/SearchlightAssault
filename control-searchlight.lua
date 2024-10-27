local d = require "sl-defines"
local u = require "sl-util"

local ct = require "control-turtle"
local rd = require "sl-render"

local cgui = require "control-gui"


local export = {}

-- TODO Will be able to simpifly signals in the future
-- https://forums.factorio.com/viewtopic.php?t=116334

-- hardcoded name lookup below for an ever-so-slight speedup
local sigDirectX = {type="virtual", quality="normal", name="sl-x"}
local sigDirectY = {type="virtual", quality="normal", name="sl-y"}
local sigFoeX    = {type="virtual", quality="normal", name="foe-x-position"}
local sigFoeY    = {type="virtual", quality="normal", name="foe-y-position"}
local sigWarn    = {type="virtual", quality="normal", name="sl-warn"}
local sigAlarm   = {type="virtual", quality="normal", name="sl-alarm"}
local sigOwnX    = {type="virtual", quality="normal", name="sl-own-x"}
local sigOwnY    = {type="virtual", quality="normal", name="sl-own-y"}
local sigRadius  = {type="virtual", quality="normal", name="sl-radius"}
local sigMin     = {type="virtual", quality="normal", name="sl-minimum"}
local sigMax     = {type="virtual", quality="normal", name="sl-maximum"}
local sigRotate  = {type="virtual", quality="normal", name="sl-rotation"}

local rwire = defines.wire_connector_id.circuit_red
local gwire = defines.wire_connector_id.circuit_green


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
  if oldDir == 12 and newDir == 0 then
    return 45
  end
  if oldDir == 14 and newDir == 2 then
    return 45
  end

  -- Detect counter-clockwise looparound
  if oldDir == 0 and newDir == 12 then
    return -45
  end
  if oldDir == 2 and newDir == 14 then
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
  local c = i.get_control_behavior().sections[1]

  local connected = (i.get_circuit_network(rwire)
                  or i.get_circuit_network(gwire))
  local rad = 0
  local rot = 0
  local min = 0
  local max = 0

  if connected then
    rad = i.get_signal(sigRadius, rwire, gwire)
    rot = i.get_signal(sigRotate, rwire, gwire)
    min = i.get_signal(sigMin   , rwire, gwire)
    max = i.get_signal(sigMax   , rwire, gwire)
  else
    rad = c.get_slot(d.circuitSlots.radiusSlot).min
    rot = c.get_slot(d.circuitSlots.rotateSlot).min
    min = c.get_slot(d.circuitSlots.minSlot).min
    max = c.get_slot(d.circuitSlots.maxSlot).min
  end

  ct.UpdateWanderParams(g, rad, rot, min, max)
end


-- Checked only a few times a second
export.CheckCircuitConditions = function()
  local tick = game.tick
  for gID, g in pairs(storage.check_power) do
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
  local c = i.get_control_behavior().sections[1]

  local warning = 0
  -- Do I want to use d.searchlightSafeTime? A constant 2 seconds seems good...
  if g.lastSpotted and (tick - g.lastSpotted) < 120 then
    warning = 1
  end

  -- TODO It turns out that setting signals every nth tick is pretty expensive. (reads are fairly cheap)
  c.set_slot(d.circuitSlots.foePositionXSlot, {value = sigFoeX,  min = 0})
  c.set_slot(d.circuitSlots.foePositionYSlot, {value = sigFoeY,  min = 0})
  c.set_slot(d.circuitSlots.alarmSlot,        {value = sigAlarm, min = 0})
  c.set_slot(d.circuitSlots.warningSlot,      {value = sigWarn,  min = warning})

  local connected = (i.get_circuit_network(defines.wire_connector_id.circuit_red)
                  or i.get_circuit_network(defines.wire_connector_id.circuit_green))
  local x = 0
  local y = 0

  if connected then
    x = i.get_signal({type="virtual", name="sl-x"}, rwire, gwire)
    y = i.get_signal({type="virtual", name="sl-y"}, rwire, gwire)
  else
    x = c.get_slot(d.circuitSlots.dirXSlot).min
    y = c.get_slot(d.circuitSlots.dirYSlot).min
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
  local c = i.get_control_behavior().sections[1]

  if g.light.shooting_target and g.light.shooting_target.valid then
    local pos = g.light.shooting_target.position
    c.set_slot(d.circuitSlots.foePositionXSlot, {value = sigFoeX, min = pos.x})
    c.set_slot(d.circuitSlots.foePositionYSlot, {value = sigFoeY, min = pos.y})
  end

  c.set_slot(d.circuitSlots.alarmSlot,        {value = sigAlarm, min = 1})
  c.set_slot(d.circuitSlots.warningSlot,      {value = sigWarn,  min = 0})  
end


export.ProcessSafeSignals = function(g)
  local i = g.signal
  local c = i.get_control_behavior().sections[1]

  c.set_slot(d.circuitSlots.alarmSlot,        {value = sigAlarm, min = 0})
  c.set_slot(d.circuitSlots.warningSlot,      {value = sigWarn,  min = 0})
end

-- Called when a new searchlight is built
export.SpawnSignalInterface = function(sl)
  -- Attempts to find existing / ghost interfaces before spawning a new one
  local i, revived = FindSignalInterface(sl)

  i.operable = false
  i.destructible = false

  local c = i.get_control_behavior().sections[1]

  local slRotation = u.clampDeg(360 * sl.orientation, 0, true) -- orientation goes 0.0-1
  if not revived then
    c.set_slot(d.circuitSlots.radiusSlot, {value = sigRadius,  min = 0})
    c.set_slot(d.circuitSlots.rotateSlot, {value = sigRotate,  min = slRotation})
    c.set_slot(d.circuitSlots.minSlot,    {value = sigMin,     min = 0})
    c.set_slot(d.circuitSlots.maxSlot,    {value = sigMax,     min = 0})
    c.set_slot(d.circuitSlots.dirXSlot,   {value = sigDirectX, min = 0})
    c.set_slot(d.circuitSlots.dirYSlot,   {value = sigDirectY, min = 0})
  else
    local oldRotation = c.get_slot(d.circuitSlots.rotateSlot).min
    local diff = oldRotation - slRotation
    local newRot = u.clampDeg(oldRotation - diff, 0, true)
    c.set_slot(d.circuitSlots.rotateSlot, {value = sigRotate,  min = newRot})
  end

  c.set_slot(d.circuitSlots.ownPositionXSlot, {value = sigOwnX,  min = i.position.x})
  c.set_slot(d.circuitSlots.ownPositionYSlot, {value = sigOwnY,  min = i.position.y})
  c.set_slot(d.circuitSlots.alarmSlot,        {value = sigAlarm, min = 0})
  c.set_slot(d.circuitSlots.warningSlot,      {value = sigWarn,  min = 0})
  c.set_slot(d.circuitSlots.foePositionXSlot, {value = sigFoeX,  min = 0})
  c.set_slot(d.circuitSlots.foePositionYSlot, {value = sigFoeY,  min = 0})

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

  local control = g.signal.get_control_behavior().sections[1]
  local sig = control.get_slot(d.circuitSlots.rotateSlot)

  -- We'll clamp the value down here so we don't try to factor in circuit signals
  sig.min = u.clampDeg(sig.min + newRot, 0, true)
  control.set_slot(d.circuitSlots.rotateSlot, sig)

  -- If there's a direct waypoint set, go ahead and rotate that
  if     g.tState == ct.MOVE 
      or g.tWanderParams.radius == 360 
      or g.tWanderParams.radius == 0 then
    if g.tState == ct.MOVE then
      local distSq = u.lensquared(u.TranslateCoordinate(g, g.tCoord), light.position)

      local theta = math.atan2(g.tCoord.y, g.tCoord.x)
      newCoord = u.ScreenOrientationToPosition(light.position, theta + newRot, math.sqrt(distSq))

      local dirX = control.get_slot(d.circuitSlots.dirXSlot)
      local dirY = control.get_slot(d.circuitSlots.dirYSlot)
      dirX.min   = newCoord.x - light.position.x
      dirY.min   = newCoord.y - light.position.y

      control.set_slot(d.circuitSlots.dirXSlot, dirX)
      control.set_slot(d.circuitSlots.dirYSlot, dirY)
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


return export
