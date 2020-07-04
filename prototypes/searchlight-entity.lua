require "searchlight-defines"

local spotlightBeam =
{
  name = "spotlight-beam",
  type = "beam",
  damage_interval = 20,
  flags = {"not-on-map"},
  width = 0.5,
  random_target_offset = true,
  target_offset = {0.5,-0.5},
  action_triggered_automatically = false,
  random_end_animation_rotation = false,
  ground_light_animations =
  {
    tail =
    {
      -- filename = "__base__/graphics/entity/laser-turret/hr-laser-end-light.png",
      filename = "__Searchlights__/graphics/spotlight-r2.png",
      flags = { "light", "no-crop" },
      -- width = 200,
      -- height = 200,
        width = 100,
        height = 400,
        scale = 2,
    }
  },

  tail =
  {
    filename = "__Searchlights__/graphics/transparent_pixel.png",
    width = 1,
    height = 1,
  },
  body =
  {
    filename = "__Searchlights__/graphics/transparent_pixel.png",
    width = 1,
    height = 1,
  },
  head =
  {
    filename = "__Searchlights__/graphics/transparent_pixel.png",
    width = 1,
    height = 1,
  },
}

data:extend{spotlightBeam}

-- turretEntity; the primary entity which uses a lamp like a turret
local turretEntity = table.deepcopy(data.raw["electric-turret"]["laser-turret"])
turretEntity.name = "searchlight"
turretEntity.minable.result = "searchlight"
 -- arbitrary high number btween 5 and 500 to be 'instant'
turretEntity.rotation_speed = 50
-- radar_range
-- Energy priority: Should be below laser turrets, same as most machines, above lamps & accumulators
turretEntity.energy_source.usage_priority = "secondary-input"
turretEntity.attack_parameters = {
    type = "beam",
    range = searchlightOuterRange,
    cooldown = 40,
    source_direction_count = 64,
    source_offset = {0, -3.423489 / 4},
    ammo_type =
    {
      category = "laser-turret",
      action =
      {
          type = "direct",
          action_delivery =
          {
            type = "beam",
            beam = "spotlight-beam",
            max_length = 24,
            duration = 40,
            source_offset = {0, -1.31439 }
          }
        }
    }
    -- Optional properties
    -- source_direction_count
    -- source_offset
}



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
