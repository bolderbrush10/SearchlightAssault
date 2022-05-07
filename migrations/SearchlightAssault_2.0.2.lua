local copy = {}

for tID, tu in pairs(global.boosted_to_tunion) do
  copy[tu.tuID] = tu
  tu.turret.active = true
end

global.boosted_to_tunion = copy