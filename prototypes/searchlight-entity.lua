require "searchlight-defines"

-- turretEntity; the primary entity which uses a lamp like a turret
local turretEntity = table.deepcopy(data.raw["electric-turret"]["laser-turret"])
turretEntity.name = "searchlight"
turretEntity.minable.result = "searchlight"
 -- arbitrary high number btween 5 and 500 to be 'instant'
turretEntity.rotation_speed = 50
-- Energy priority: Should be below laser turrets, same as most machines, above lamps & accumulators
turretEntity.energy_source.usage_priority = "secondary-input"


-- spotLightSprite; A simple sprite with a directional light effect
local spotLightSprite = {
    type = "sprite",
    name = "spotLightSprite",
    filename = "__Searchlights__/graphics/spotlight.png",
    priority = "extra-high",
    width = 200, 
    height = 200
}

local dummyEnt = table.deepcopy(data.raw["unit"]["small-biter"])
dummyEnt.name = "DummyEntity"
dummyEnt.collision_box = {{0, 0}, {0, 0}} -- enable noclip
dummyEnt.collision_mask = {"not-colliding-with-itself"}
dummyEnt.selectable_in_game = false
dummyEnt.selection_box = {{-0.0, -0.0}, {0.0, 0.0}}

-- Add new definitions to game data
data:extend{turretEntity, spotLightSprite, dummyEnt}
