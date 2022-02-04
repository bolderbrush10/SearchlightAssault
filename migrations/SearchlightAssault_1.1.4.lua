local ct = require "control-turtle"
global.slFOVRenders = {}

local OwnPositionXSlot = 5
local OwnPositionYSlot = 6

local sigOwnX    = {type="virtual", name="sl-own-x"}
local sigOwnY    = {type="virtual", name="sl-own-y"}

for gID, g in pairs(global.gestalts) do
  ct.SetDefaultWanderParams(g)

  local i = g.signal
  local c = i.get_control_behavior()
  c.set_signal(OwnPositionXSlot, {signal = sigOwnX, count = i.position.x})
  c.set_signal(OwnPositionYSlot, {signal = sigOwnY, count = i.position.y})
end
