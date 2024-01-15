----------------------------------------------------------------
  local r  = require "sl-relation"

  local bl = require "blocklist"

  local cf = require "control-forces"
  local cg = require "control-gestalt"
  local cu = require "control-tunion"

  local rd = require "sl-render"

  local cgui = require "control-gui"

  -- forward declarations
  local InitTables
----------------------------------------------------------------

-- In this init function, we'll declare some variables in the global table -
-- this lets the game engine track them for us across save/load cycles.
function InitTables()
  bl.InitTables_Blocklist()

  cf.InitTables_Forces()
  cg.InitTables_Gestalt()
  cu.InitTables_Turrets()
  rd.InitTables_Render()
  cgui.InitTables_GUI()
end

----------------------------------------------------------------
  local public = {}
  public.InitTables = InitTables
  return public
----------------------------------------------------------------
