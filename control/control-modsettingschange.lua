local bl = require "blocklist.lua"

-- forward declarations
local handleModSettingsChanges
local handleUninstall
local handleConfigurationChanged



-- On Mod Settings Changed
script.on_event(defines.events.on_runtime_mod_setting_changed, ms.handleModSettingsChanges)
-- (Doesn't handle runtime changes or changes from the main menu, unless another mod is enabled/diabled)
script.on_configuration_changed(ms.handleConfigurationChanged)


handleUninstall = function()
  if settings.global[d.uninstallMod].value then
    for _, g in pairs(global.gestalts) do
      local b = g.light;
      cg.SearchlightRemoved(b.unit_number);
      b.destroy()
    end

    -- The above loop SHOULD have cleaned this out,
    -- but it can't hurt to be careful
    for _, tID in pairs(global.boosted_to_tunion) do
      cu.UnBoost(global.tunions[tID])
    end

    global.boosted_to_tunion = {}
    global.tunions = {}
  end
end


handleModSettingsChanges = function(event)
  -- In case this mod was updated, close any open windows
  -- so we don't have to worry about obsolete GUI
  -- elements being available
  for pIndex, _ in pairs(game.players) do
    cgui.CloseSearchlightGUI(pIndex)
  end

  if not event or event.setting == d.ignoreEntriesList then
    cb.UpdateBlockList()
    cb.UnboostBlockedTurrets()
  end

  if event and event.setting == d.overrideAmmoRange then
    if not settings.global[d.overrideAmmoRange].value then
      cu.RespectMaxAmmoRange()
    end
  end

  handleUninstall()
  cb.UpdateBlockList()
end


handleConfigurationChanged = function(event)
  for _, force in pairs(game.forces) do
    cf.UpdateTForceRelationships(force)
  end

  handleModSettingsChanges(event)
end

local public = {}
public.handleModSettingsChanges = handleModSettingsChanges
public.handleUninstall = handleUninstall
public.handleConfigurationChanged = handleConfigurationChanged
return public
