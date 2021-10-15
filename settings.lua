local d = require "sl-defines"

data:extend({{
  type = "string-setting",
  name = d.ignoreEntriesList,
  localised_name = {"name.searchlight-setting-ignore-entries-list"},
  localised_description = {"description.searchlight-setting-ignore-entries-list"},
  setting_type = "runtime-global",
  default_value = "",
  auto_trim = true,
  allow_blank = true,
}})
