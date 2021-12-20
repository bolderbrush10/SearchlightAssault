-- Be sure to declare functions and vars as 'local' in prototype / data*.lua files,
-- because other mods may have inadvertent access to functions & variables at this step.

require("prototypes.sl-entities")
require("prototypes.sl-techItemRecipe")

local d = require("sl-defines")
local u = require("sl-util")


-- Since some other mods mess with the health of entities 
-- in a later data stage than they probably should;
-- try to make sure our copies of their turrets match their health
local function MatchHealth(currTable)
  for index, turret in pairs(currTable) do
    if u.EndsWith(turret.name, d.boostSuffix) then
	  local originalT = turret.name:sub(1, #turret.name - #d.boostSuffix)

	  turret.max_health = currTable[originalT].max_health
	end
  end
end


MatchHealth(data.raw["ammo-turret"])
MatchHealth(data.raw["fluid-turret"])
MatchHealth(data.raw["electric-turret"])
