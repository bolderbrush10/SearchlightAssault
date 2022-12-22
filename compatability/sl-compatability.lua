local picker_dollies = require "sl-picker-dollies"

local export = {}

export.Compatability_OnInit = function()
  if remote.interfaces["PickerDollies"] then
    picker_dollies.OnInit()
  end
end

export.Compatability_OnLoad = function()
  if remote.interfaces["PickerDollies"] then
    picker_dollies.OnLoad()
  end
end

return export