local ca = require "control-ammo"

local d = require "sl-defines"
local u = require "sl-util"

global.ammoAudit = {}

for tID, tu in pairs(global.boosted_to_tunion) do
  local turret = tu.turret

  local ammoCount = 0
  local inv = turret.get_inventory(defines.inventory.turret_ammo)
  if inv then
    for index=1, #inv do
      if      inv[index]
          and inv[index].valid
          and inv[index].valid_for_read then
        if u.EndsWith(inv[index].name, d.boostSuffix) then
          ammoCount = ammoCount + inv[index].count
        end
      end
    end
  end

  global.ammoAudit[turret.unit_number] = ammoCount
end
