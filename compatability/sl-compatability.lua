----------------------------------------------------------------
  local picker_dollies = require "sl-picker-dollies"

  -- forward declarations
  local Compatability_OnInit
  local Compatability_OnLoad
----------------------------------------------------------------

function Compatability_OnInit()
  if remote.interfaces["PickerDollies"] then
    picker_dollies.OnInit()
  end
end

function Compatability_OnLoad()
  if remote.interfaces["PickerDollies"] then
    picker_dollies.OnLoad()
  end
end

----------------------------------------------------------------
  local public = {}
  public.Compatability_OnInit = Compatability_OnInit
  public.Compatability_OnLoad = Compatability_OnLoad
  return public
----------------------------------------------------------------
