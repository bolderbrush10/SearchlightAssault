local picker_dollies = require "sl-picker-dollies"

local e = {} -- export functions

e.Compatability_OnInit = function()
  if remote.interfaces["PickerDollies"] then
    picker_dollies.OnInit()
  end
end

e.Compatability_OnLoad = function()
  if remote.interfaces["PickerDollies"] then
    picker_dollies.OnLoad()
  end
end

return e