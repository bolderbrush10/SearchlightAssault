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
  makeSignal("sl-x",           "directX",       "a-a"),
  makeSignal("sl-y",           "directY",       "a-b"),
  makeSignal("foe-x-position", "foeX",          "a-c"),
  makeSignal("foe-y-position", "foeY",          "a-d"),
  makeSignal("sl-warn",        "warn",          "a-e"),
  makeSignal("sl-alarm",       "alarm",         "a-f"),
  makeSignal("sl-radius",      "radius",        "a-g"),
  makeSignal("sl-minimum",     "min_distance",  "a-h"),
  makeSignal("sl-maximum",     "max_distance",  "a-i"),
  makeSignal("sl-rotation",    "rotate",        "a-j"),
}

data:extend(signals)