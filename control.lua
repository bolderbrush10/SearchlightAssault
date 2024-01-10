-- These files are required but not referenced.
-- This will allow them to register themselves with factorio API script.on_* calls.
require "control/control-blueprintitems"
require "control/control-foespotted"
require "control/control-forces"
require "control/control-gui"
require "control/control-modsettingschange"
require "control/control-rotated"
require "control/control-samsara"
require "control/control-seekfoes"
require "control/control-selectionchanged"
require "control/control-settingspasted"
require "control/control-tick"

-- Any script.on_* calls that must be shared between features will be negotiated here.
local t = require "control/control-tables"
local c = require "compatability/sl-compatability"

script.on_init(
function(event)

  t.InitTables()
  c.Compatability_OnInit()

end)

-- I would like to do more with this,
-- but on_load doesn't provide access to game.* functions,
-- and mod settings changed at the main menu don't seem to persist
-- onto already-created games...
-- The most we can really do is handle mod-comapability
script.on_load(
function()
  c.Compatability_OnLoad()
end)
