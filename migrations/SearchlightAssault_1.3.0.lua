local d = require "sl-defines"
local u = require "sl-util"

local cgui = require "control-gui"

local cg = require "control-gestalt"
local cs = require "control-searchlight"


cgui.InitTables_GUI()

global.watch_circles = nil -- Renaming
global.spotter_timeouts = {}

global.check_power = {}

global.animation_sync = {}

global.tposRenders = {}

-- It's easiest to just rebuild this from scratch
global.unum_to_g = {}

for gID, g in pairs(global.gestalts) do
  global.check_power[gID] = g

  if not g.tOldCoord then
    g.tOldCoord = {x=g.turtle.position.x, y=g.turtle.position.y}
  end

  -- Changing the prototype type for the spotter will have invalidated all existing spotters,
  -- so spawn in a new one and let the engine handle cleaning up the invalid entities
  g.spotter = cg.SpawnSpotter(g.light, g.turtle.force) -- TODO !!!!! This function moved. Also check all the other compatability files, too
  
  local c = g.signal.get_control_behavior()

  -- Just reset all the circuit signal slots so the GUI doesn't break,
  -- biters don't just squat at own positiion, etc
  c.parameters = nil

  -- If an alarm-mode light gets migrated through this, it should update its signals again next tick
  -- Don't 'update' rotation, we don't want to break existing setups
  c.set_signal(d.circuitSlots.rotateSlot,       {signal = {type="virtual", name="sl-rotation"},    count = 0})
  c.set_signal(d.circuitSlots.radiusSlot,       {signal = {type="virtual", name="sl-radius"},      count = 0})
  c.set_signal(d.circuitSlots.minSlot,          {signal = {type="virtual", name="sl-minimum"},     count = 0})
  c.set_signal(d.circuitSlots.maxSlot,          {signal = {type="virtual", name="sl-maximum"},     count = 0})
  c.set_signal(d.circuitSlots.dirXSlot,         {signal = {type="virtual", name="sl-x"},           count = 0})
  c.set_signal(d.circuitSlots.dirYSlot,         {signal = {type="virtual", name="sl-y"},           count = 0})
  c.set_signal(d.circuitSlots.alarmSlot,        {signal = {type="virtual", name="sl-alarm"},       count = 0})
  c.set_signal(d.circuitSlots.warningSlot,      {signal = {type="virtual", name="sl-warn"},        count = 0})
  c.set_signal(d.circuitSlots.foePositionXSlot, {signal = {type="virtual", name="foe-x-position"}, count = 0})
  c.set_signal(d.circuitSlots.foePositionYSlot, {signal = {type="virtual", name="foe-y-position"}, count = 0})
  c.set_signal(d.circuitSlots.ownPositionXSlot, {signal = {type="virtual", name="sl-own-x"},       count = g.signal.position.x})
  c.set_signal(d.circuitSlots.ownPositionYSlot, {signal = {type="virtual", name="sl-own-y"},       count = g.signal.position.y})

  global.unum_to_g[g.light.unit_number]   = g
  global.unum_to_g[g.signal.unit_number]  = g
  global.unum_to_g[g.turtle.unit_number]  = g
  global.unum_to_g[g.spotter.unit_number] = g

  cg.OpenWatch(g.gID)
end

-- Adjust existing rotation signals forward 90 degrees so that
-- we can all use 0/360 as "12 o'clock" and proceed clockwise
-- instead of treating the x-axis as 0/360
for _, s in pairs(game.surfaces) do
  combinators = s.find_entities_filtered{name="constant-combinator"}

  for _, c in pairs(combinators) do
    if c.valid then
      local cc = c.get_control_behavior()
      for _, p in pairs(cc.parameters) do
        if p.signal.name == "sl-rotation" then
          p.count = u.clampDeg(p.count + 90, 0, true)
          cc.set_signal(p.index, p)
        end
      end
    end
  end
end

-- Wipe out any rendering instances so we can redraw them
for _, pIndexToEpochAndRenderMap in pairs(global.slFOVRenders) do
  for _, epochAndRender in pairs(pIndexToEpochAndRenderMap) do
    for _, render in pairs(epochAndRender) do
      rendering.destroy(render)
    end
  end
end
global.slFOVRenders = {}