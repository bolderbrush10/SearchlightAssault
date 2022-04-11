local d  = require "sl-defines"
local cgui = require "control-gui"
local cg = require "control-gestalt"
local cs = require "control-searchlight"


cgui.InitTables_GUI()

global.watch_circles = nil -- Renaming
global.spotter_timeouts = {}

global.animation_sync = {}

global.check_power = {}

-- It's easiest to just rebuild this from scratch
global.unum_to_g = {}

for gID, g in pairs(global.gestalts) do
  global.check_power[gID] = g

  -- Changing the prototype type for the spotter will have invalidated all existing spotters,
  -- so spawn in a new one and let the engine handle cleaning up the invalid entities
  g.spotter = cg.SpawnSpotter(g.light, g.turtle.force)

  if g.signal then
    g.signal.destroy()
  end

  -- Just reset all the circuit signal slots so the GUI doesn't break,
  -- biters don't just squat at own positiion, etc
  g.signal = cs.SpawnSignalInterface(g.light)

  global.unum_to_g[g.light.unit_number] = g
  global.unum_to_g[g.signal.unit_number] = g
  global.unum_to_g[g.turtle.unit_number] = g
  global.unum_to_g[g.spotter.unit_number] = g

  cg.OpenWatch(g.gID)
end
