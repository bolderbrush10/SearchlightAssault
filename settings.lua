local d = require "sl-defines"

data:extend({{
  type = "string-setting",
  name = d.ignoreEntriesList,
  localised_name        = {"name.searchlight-assault-setting-ignore-entries-list"},
  localised_description = {"description.searchlight-assault-setting-ignore-entries-list"},
  setting_type = "runtime-global",
  default_value = "",
  auto_trim = true,
  allow_blank = true,
}})

data:extend({{
  type = "bool-setting",
  name = d.uninstallMod,
  localised_name        = {"name.searchlight-assault-uninstall"},
  localised_description = {"description.searchlight-assault-uninstall"},
  setting_type = "runtime-global",
  default_value = false,
}})

data:extend({{
  type = "bool-setting",
  name = d.overrideAmmoRange,
  localised_name        = {"name.searchlight-assault-override-ammo-range"},
  localised_description = {"description.searchlight-assault-override-ammo-range"},
  setting_type = "runtime-global",
  default_value = true,
}})

data:extend({{
  type = "double-setting",
  name = d.lightRadiusSetting,
  localised_name        = {"name.searchlight-assault-setting-light-radius"},
  localised_description = {"description.searchlight-assault-setting-light-radius"},
  setting_type = "startup",
  default_value = d.defaultSearchlightSpotRadius,
  minimum_value = 0.1,
  maximum_value = 50,
}})