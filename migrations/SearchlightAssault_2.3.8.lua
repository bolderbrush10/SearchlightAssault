local d  = require "sl-defines"
local cg = require "control-gestalt"

for _, surface in pairs(game.surfaces) do
  local sl_s = surface.find_entities_filtered{name=d.searchlightSafeName}
  for _, e in pairs(sl_s) do
    if storage.unum_to_g[e.unit_number] == nil then
      cg.SearchlightAdded(e)
    end
  end
  local sl_a = surface.find_entities_filtered{name=d.searchlightAlarmName}
  for _, e in pairs(sl_a) do
    if storage.unum_to_g[e.unit_number] == nil then
      cg.SearchlightAdded(e)
    end
  end
  local sl_b = surface.find_entities_filtered{name=d.searchlightBaseName}
  for _, e in pairs(sl_b) do
    if storage.unum_to_g[e.unit_number] == nil then
      cg.SearchlightAdded(e)
    end
  end
end