local cgui = require "control-gui"

cgui.InitTables_GUI()

for gID, g in pairs(global.gestalts) do
  global.unum_to_g[g.signal.unit_number] = g
end