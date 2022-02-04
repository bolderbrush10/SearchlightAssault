local ct = require "control-turtle"
global.slFOVRenders = {}

for gID, g in pairs(global.gestalts) do
  ct.SetDefaultWanderParams(g)
end
