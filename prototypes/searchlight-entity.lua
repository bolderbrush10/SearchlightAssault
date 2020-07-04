require "searchlight-defines"

local Layer_transparent_pixel =
{
  filename = "__Searchlights__/graphics/transparent_pixel.png",
  width = 1,
  height = 1,
}

local Light_Layer_SpotLight_NormLight =
{
  filename = "__Searchlights__/graphics/spotlight-r.png",
  width = 200,
  height = 200,
  scale = 1.25,
  flags = { "light" },
  shift = {0.3, 0},
}

local Light_Layer_SpotLight_NormLight_Less = table.deepcopy(Light_Layer_SpotLight_NormLight)
Light_Layer_SpotLight_NormLight_Less.filename = "__Searchlights__/graphics/spotlight-r-less.png"

local Light_Layer_SpotLight_RimLight = table.deepcopy(Light_Layer_SpotLight_NormLight)
Light_Layer_SpotLight_RimLight.filename = "__Searchlights__/graphics/spotlight-r-rim.png"

local Light_Layer_SpotLight_DimLight = table.deepcopy(Light_Layer_SpotLight_NormLight)
Light_Layer_SpotLight_DimLight.filename = "__Searchlights__/graphics/spotlight-r-less-dim.png"

local Light_Layer_SpotLight_NormLight_Red = table.deepcopy(Light_Layer_SpotLight_NormLight)
Light_Layer_SpotLight_NormLight_Red.tint = {r=1.0, g=0.1, b=0.1, a=1}

local Light_Layer_SpotLight_RimLight_Red = table.deepcopy(Light_Layer_SpotLight_RimLight)
Light_Layer_SpotLight_RimLight_Red.tint = {r=1.0, g=0.1, b=0.1, a=1}

local Light_Layer_SpotLight_DimLight_Red = table.deepcopy(Light_Layer_SpotLight_DimLight)
Light_Layer_SpotLight_DimLight_Red.tint = {r=1.0, g=0.1, b=0.1, a=1}

local SpotlightBeamPassive =
{
    type = "beam",
    name = "spotlight-beam-passive",
    flags = {"not-on-map"},
    width = 0.5,
    damage_interval = 1,
    random_end_animation_rotation = false,
    ground_light_animations =
    {
      ending =
      {
        layers =
        {
          Light_Layer_SpotLight_NormLight,
        }
      }
    },
    ending =
    {
      layers =
      {
        Light_Layer_SpotLight_DimLight,
      }
    },
    head = Layer_transparent_pixel,
    tail = Layer_transparent_pixel,
    body = Layer_transparent_pixel,
}

local SpotlightBeamAlarm = table.deepcopy(SpotlightBeamPassive)
SpotlightBeamAlarm.name = "spotlight-beam-alarm"
SpotlightBeamAlarm.ground_light_animations =
{
  ending =
  {
    layers =
    {
      Light_Layer_SpotLight_NormLight_Red,
      Light_Layer_SpotLight_NormLight_Less,
    }
  }
}
SpotlightBeamAlarm.ending =
{
  layers =
  {
    Light_Layer_SpotLight_RimLight_Red,
    Light_Layer_SpotLight_DimLight_Red,
  }
}

data:extend{SpotlightBeamPassive, SpotlightBeamAlarm}


-- SpotLightForDummy; the primary entity which uses a lamp like a turret
-- TODO: use radar_range?
local SpotLightForDummy = table.deepcopy(data.raw["electric-turret"]["laser-turret"])
SpotLightForDummy.flags = {"hidden"}
SpotLightForDummy.name = "searchlight_dummy"
SpotLightForDummy.minable.result = "searchlight"
 -- arbitrary high number btween 5 and 500 to be 'instant'
SpotLightForDummy.rotation_speed = 50
-- Energy priority: Should be below laser turrets, same as most machines, above lamps & accumulators
SpotLightForDummy.energy_source.usage_priority = "secondary-input"
SpotLightForDummy.attack_parameters = {
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
            beam = "spotlight-beam-passive",
            max_length = searchlightOuterRange,
            duration = 40,
            source_offset = {-1, -1.31439 }
          }
        }
    }
    -- Optional properties
    -- source_direction_count
    -- source_offset
}

local SpotLightForReal = table.deepcopy(SpotLightForDummy)
SpotLightForReal.name = "searchlight"
SpotLightForReal.attack_parameters.ammo_type.action.action_delivery.beam = "spotlight-beam-alarm"

-- SpotLightHidden; a hidden entity to help swapping between the 'dummy seeking' and 'real' spotlights
local SpotLightHidden = table.deepcopy(data.raw["lamp"]["small-lamp"])

table.deepcopy(data.raw["lamp"]["small-lamp"])

SpotLightHidden.name = "searchlight-hidden"
SpotLightHidden.flags = {"placeable-off-grid", "not-on-map"}
SpotLightHidden.selectable_in_game = false
SpotLightHidden.collision_box = {{-0.0, -0.0}, {0.0, 0.0}}
SpotLightHidden.selection_box = {{-0.0, -0.0}, {0.0, 0.0}}
SpotLightHidden.collision_mask = {"not-colliding-with-itself"}

-- We don't intend to leave a corpse at all, but if the worst happens...
SpotLightHidden.corpse = "small-scorchmark"
SpotLightHidden.energy_source = {
 type = "void",
 usage_priority = "lamp"
}
-- SpotLightHidden.light = Light_Layer_SpotLight_DimLight
-- SpotLightHidden.light_when_colored = Light_Layer_SpotLight_DimLight
-- SpotLightHidden.picture_off = transparent_pixel
-- SpotLightHidden.picture_on = transparent_pixel


-- The dummy seeking spotlight's beam draws where the turtle is
local Turtle = table.deepcopy(data.raw["unit"]["small-spitter"])
Turtle.name = "searchlight_turtle"
Turtle.collision_box = {{0, 0}, {0, 0}} -- enable noclip
Turtle.collision_mask = {"not-colliding-with-itself"}
Turtle.selectable_in_game = false
Turtle.selection_box = {{-0.0, -0.0}, {0.0, 0.0}}

-- Add new definitions to game data
data:extend{SpotLightForDummy, SpotLightForReal, SpotLightHidden, Turtle}
