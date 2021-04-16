require "defines"

-- Be sure to declare functions and vars as 'local' in prototype / data*.lua files,
-- because other mods may have inadvertent access to functions at this step.

local Layer_transparent_pixel =
{
  filename = "__Searchlights__/graphics/transparent_pixel.png",
  width = 1,
  height = 1,
}

local Layer_transparent_animation =
{
  filename = "__Searchlights__/graphics/transparent_pixels.png",
  width = 8,
  height = 8,
  direction_count = 1,
}

local Light_Layer_SpotLight_NormLight =
{
  filename = "__Searchlights__/graphics/spotlight-r.png",
  width = 200,
  height = 200,
  scale = 2,
  flags = { "light" },
  shift = {0.3, 0},
}

local redTint = {r=1.0, g=0.1, b=0.1, a=1}

local Light_Layer_SpotLight_NormLight_Less = table.deepcopy(Light_Layer_SpotLight_NormLight)
Light_Layer_SpotLight_NormLight_Less.filename = "__Searchlights__/graphics/spotlight-r-less.png"

local Light_Layer_SpotLight_RimLight = table.deepcopy(Light_Layer_SpotLight_NormLight)
Light_Layer_SpotLight_RimLight.filename = "__Searchlights__/graphics/spotlight-r-rim.png"

local Light_Layer_SpotLight_DimLight = table.deepcopy(Light_Layer_SpotLight_NormLight)
Light_Layer_SpotLight_DimLight.filename = "__Searchlights__/graphics/spotlight-r-less-dim.png"

local Light_Layer_SpotLight_NormLight_Red = table.deepcopy(Light_Layer_SpotLight_NormLight)
Light_Layer_SpotLight_NormLight_Red.tint = redTint

local Light_Layer_SpotLight_RimLight_Red = table.deepcopy(Light_Layer_SpotLight_RimLight)
Light_Layer_SpotLight_RimLight_Red.tint = redTint

local Light_Layer_SpotLight_DimLight_Red = table.deepcopy(Light_Layer_SpotLight_DimLight)
Light_Layer_SpotLight_DimLight_Red.tint = redTint


local SpotlightBeamPassive =
{
  type = "beam",
  name = "spotlight-beam-passive",
  flags = {"not-on-map"},
  width = 1,
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
