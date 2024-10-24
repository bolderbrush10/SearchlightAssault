local copy = {}

for tID, tu in pairs(storage.boosted_to_tunion) do
  copy[tu.tuID] = tu
  tu.turret.active = true
end

storage.boosted_to_tunion = copy