local ct = require "control-turtle"
storage.slFOVRenders = {}

local OwnPositionXSlot = 5
local OwnPositionYSlot = 6

local sigOwnX    = {type="virtual", quality="normal", name="sl-own-x"}
local sigOwnY    = {type="virtual", quality="normal", name="sl-own-y"}

for gID, g in pairs(storage.gestalts) do
  ct.SetDefaultWanderParams(g)

  local i = g.signal
  local c = i.get_control_behavior().sections[1]
  c.set_slot(OwnPositionXSlot, {value = sigOwnX, min = i.position.x})
  c.set_slot(OwnPositionYSlot, {value = sigOwnY, min = i.position.y})
end
