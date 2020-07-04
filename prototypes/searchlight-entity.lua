require "searchlight-defines"

local spotlightBeam =
{
    type = "beam",
    name = "spotlight-beam",
    flags = {"not-on-map"},
    width = 0.5,
    damage_interval = 1,
    random_end_animation_rotation = false,
    ground_light_animations =
    {
      ending =
      {
        filename = "__Searchlights__/graphics/spotlight-r.png",
        width = 200,
        height = 200,
        scale = 1.25,
        flags = { "light" },
        shift = {0.5, 0},
        blend_mode = beam_blend_mode,
      },
    },
    head =
    {
      filename = "__Searchlights__/graphics/transparent_pixel.png",
      width = 1,
      height = 1,
    },
    tail =
    {
      filename = "__Searchlights__/graphics/transparent_pixel.png",
      width = 1,
      height = 1,
    },
    body =
    {
      {
        filename = "__Searchlights__/graphics/transparent_pixel.png",
        width = 1,
        height = 1,
      },
    }
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
            source_offset = {-1, -1.31439 }
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
