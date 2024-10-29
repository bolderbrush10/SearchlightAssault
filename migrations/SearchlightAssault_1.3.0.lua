local d = require "sl-defines"
local u = require "sl-util"

local cgui = require "control-gui"

local cg = require "control-gestalt"
local cs = require "control-searchlight"


cgui.InitTables_GUI()

storage.watch_circles = nil -- Renaming
storage.spotter_timeouts = {}

storage.check_power = {}

storage.animation_sync = {}

storage.tposRenders = {}

-- It's easiest to just rebuild this from scratch
storage.unum_to_g = {}

for gID, g in pairs(storage.gestalts) do
  storage.check_power[gID] = g

  if not g.tOldCoord then
    g.tOldCoord = {x=g.turtle.position.x, y=g.turtle.position.y}
  end

  -- Changing the prototype type for the spotter will have invalidated all existing spotters,
  -- so spawn in a new one and let the engine handle cleaning up the invalid entities
  g.spotter = cg.SpawnSpotter(g.light, g.turtle.force)
  
  local c = g.signal.get_control_behavior().sections[1]

  -- Just reset all the circuit signal slots so the GUI doesn't break,
  -- biters don't just squat at own positiion, etc
  c.filters = nil

  -- If an alarm-mode light gets migrated through this, it should update its signals again next tick
  -- Don't 'update' rotation, we don't want to break existing setups
  c.set_slot(d.circuitSlots.rotateSlot,       {value = {type="virtual", quality="normal", name="sl-rotation"},    min = 0})
  c.set_slot(d.circuitSlots.radiusSlot,       {value = {type="virtual", quality="normal", name="sl-radius"},      min = 0})
  c.set_slot(d.circuitSlots.minSlot,          {value = {type="virtual", quality="normal", name="sl-minimum"},     min = 0})
  c.set_slot(d.circuitSlots.maxSlot,          {value = {type="virtual", quality="normal", name="sl-maximum"},     min = 0})
  c.set_slot(d.circuitSlots.dirXSlot,         {value = {type="virtual", quality="normal", name="sl-x"},           min = 0})
  c.set_slot(d.circuitSlots.dirYSlot,         {value = {type="virtual", quality="normal", name="sl-y"},           min = 0})
  c.set_slot(d.circuitSlots.alarmSlot,        {value = {type="virtual", quality="normal", name="sl-alarm"},       min = 0})
  c.set_slot(d.circuitSlots.warningSlot,      {value = {type="virtual", quality="normal", name="sl-warn"},        min = 0})
  c.set_slot(d.circuitSlots.foePositionXSlot, {value = {type="virtual", quality="normal", name="foe-x-position"}, min = 0})
  c.set_slot(d.circuitSlots.foePositionYSlot, {value = {type="virtual", quality="normal", name="foe-y-position"}, min = 0})
  c.set_slot(d.circuitSlots.ownPositionXSlot, {value = {type="virtual", quality="normal", name="sl-own-x"},       min = g.signal.position.x})
  c.set_slot(d.circuitSlots.ownPositionYSlot, {value = {type="virtual", quality="normal", name="sl-own-y"},       min = g.signal.position.y})

  storage.unum_to_g[g.light.unit_number]   = g
  storage.unum_to_g[g.signal.unit_number]  = g
  storage.unum_to_g[g.turtle.unit_number]  = g
  storage.unum_to_g[g.spotter.unit_number] = g

  cg.OpenWatch(g.gID)
end

-- Adjust existing rotation signals forward 90 degrees so that
-- we can all use 0/360 as "12 o'clock" and proceed clockwise
-- instead of treating the x-axis as 0/360
for _, s in pairs(game.surfaces) do
  combinators = s.find_entities_filtered{name="constant-combinator"}

  for _, c in pairs(combinators) do
    if c.valid and c.get_control_behavior() then
      for i=1, c.get_control_behavior().sections_count do
        local cc = c.get_control_behavior().sections[i]
        for _, p in pairs(cc.filters) do
          if p.value and p.value.name == "sl-rotation" then
            p.min = u.clampDeg(p.min + 90, 0, true)
            cc.set_slot(p.index, p)
          end
        end
      end
    end
  end
end

-- Wipe out any rendering instances so we can redraw them
for _, pIndexToEpochAndRenderMap in pairs(storage.slFOVRenders) do
  for _, epochAndRender in pairs(pIndexToEpochAndRenderMap) do
    for _, render in pairs(epochAndRender) do
      render.destroy()
    end
  end
end
storage.slFOVRenders = {}