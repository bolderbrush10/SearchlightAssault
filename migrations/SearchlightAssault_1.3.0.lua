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

-- Adjust existing rotation signals back 90 degrees so that
-- we can all use 0/360 as "12 o'clock" and proceed clockwise
-- instead of treating the x-axis as 0/360
for _, s in pairs(game.surfaces) do
  combinators = s.find_entities_filtered{name="constant-combinator"}

  for _, c in pairs(combinators) do
    if c.valid then
      local cc = c.get_control_behavior()
      for _, p in pairs(cc.parameters) do
        if p.signal.name == "sl-rotation" then
          p.count = p.count - 90
          cc.set_signal(p.index, p)
        end
      end
    end
  end
end