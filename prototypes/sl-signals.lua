local function makeSignal(name, icon, order)
return 
{
  type = "virtual-signal",
  name = name,
  icon = "__SearchlightAssault__/graphics/signals/signal_" .. icon .. ".png",
  icon_size = 64, icon_mipmaps = 4,
  subgroup = "SLA-signal",
  order = order,
}
end


-- Extend our signal category
data:extend({
{
  type = "item-subgroup",
  name = "SLA-signal",
  group = "signals",
  order = "sla0[SLA-signal]"
}
})

-- Then extend our signals
local signals = {
  makeSignal("sl-own-x",       "ownX",          "a-a"),
  makeSignal("sl-own-y",       "ownY",          "a-b"),
  makeSignal("sl-x",           "directX",       "a-c"),
  makeSignal("sl-y",           "directY",       "a-d"),
  makeSignal("foe-x-position", "foeX",          "a-e"),
  makeSignal("foe-y-position", "foeY",          "a-f"),
  makeSignal("sl-warn",        "warn",          "a-g"),
  makeSignal("sl-alarm",       "alarm",         "a-h"),
  makeSignal("sl-radius",      "radius",        "a-i"),
  makeSignal("sl-minimum",     "min_distance",  "a-j"),
  makeSignal("sl-maximum",     "max_distance",  "a-k"),
  makeSignal("sl-rotation",    "rotate",        "a-l"),
}

data:extend(signals)