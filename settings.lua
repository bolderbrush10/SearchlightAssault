local d = require "sl-defines"

data:extend({{
  type = "bool-setting",
  name = d.enableBoostGlow,
  localised_name        = {"name.searchlight-assault-enable-boost-glow"},
  localised_description = {"description.searchlight-assault-enable-boost-glow"},
  setting_type = "runtime-global",
  default_value = true,
}})

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
  order="ad",
  localised_name        = {"name.searchlight-assault-setting-light-radius"},
  localised_description = {"description.searchlight-assault-setting-light-radius"},
  setting_type = "startup",
  default_value = d.defaultSearchlightSpotRadius,
  minimum_value = 0.1,
  maximum_value = 50,
}})

data:extend({{
  type = "double-setting",
  name = d.maxNeighborDistanceSetting,
  order="ae",
  localised_name        = {"name.searchlight-assault-max-neighbor-boost-distance"},
  localised_description = {"description.searchlight-assault-max-neighbor-boost-distance"},
  setting_type = "startup",
  default_value = d.defaultSearchlightMaxNeighborDistance,
  minimum_value = 0.0,
  maximum_value = 200,
}})

data:extend({{
  type = "bool-setting",
  name = d.enableLightAnimation,
  order="ca",
  localised_name        = {"name.searchlight-assault-enable-light-animation"},
  localised_description = {"description.searchlight-assault-enable-light-animation"},
  setting_type = "startup",
  default_value = true,
}})

data:extend({{
  type = "string-setting",
  name = d.warnColorDefault,
  order="cf",
  localised_name        = {"name.searchlight-assault-warn-color"},
  localised_description = {"description.searchlight-assault-warn-color"},
  setting_type = "startup",
  default_value = d.warnColorDefault,
  auto_trim = true,
  allow_blank = true,
}})

data:extend({{
  type = "string-setting",
  name = d.alarmColorDefault,
  order="cg",
  localised_name        = {"name.searchlight-assault-alarm-color"},
  localised_description = {"description.searchlight-assault-alarm-color"},
  setting_type = "startup",
  default_value = d.alarmColorDefault,
  auto_trim = true,
  allow_blank = true,
}})

data:extend({{
  type = "string-setting",
  name = d.safeColorDefault,
  order="ch",
  localised_name        = {"name.searchlight-assault-safe-color"},
  localised_description = {"description.searchlight-assault-safe-color"},
  setting_type = "startup",
  default_value = d.safeColorDefault,
  auto_trim = true,
  allow_blank = true,
}})
