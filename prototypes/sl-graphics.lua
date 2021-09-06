require "sl-defines"

-- Be sure to declare functions and vars as 'local' in prototype / data*.lua files,
-- because other mods may have inadvertent access to functions at this step.

-- If another file wants things from this file, they can reference exported items like so:
-- local g = require "graphics"
-- myEntity.animation = g[someAnimation]

-- TODO Lua macros are a lost cause. Figure out how to use C macros
--      to simply declare local items for export as opposed to the current method

local export = {}

local Layer_transparent_pixel =
{
  filename = "__Searchlights__/graphics/transparent_pixel.png",
  width = 1,
  height = 1,
}
export["Layer_transparent_pixel"] = Layer_transparent_pixel

local Layer_transparent_animation =
{
  filename = "__Searchlights__/graphics/transparent_pixels.png",
  width = 8,
  height = 8,
  direction_count = 1,
}
export["Layer_transparent_animation"] = Layer_transparent_animation

local Light_Layer_SpotLight_NormLight =
{
  filename = "__Searchlights__/graphics/spotlight-r.png",
  width = 200,
  height = 200,
  scale = 2,
  flags = { "light" },
  shift = {0.3, 0},
}
export["Light_Layer_SpotLight_NormLight"] = Light_Layer_SpotLight_NormLight

-- local redTint = {r=1.0, g=0.1, b=0.1, a=1}

-- local Light_Layer_SpotLight_NormLight_Less = table.deepcopy(Light_Layer_SpotLight_NormLight)
-- Light_Layer_SpotLight_NormLight_Less.filename = "__Searchlights__/graphics/spotlight-r-less.png"

-- local Light_Layer_SpotLight_RimLight = table.deepcopy(Light_Layer_SpotLight_NormLight)
-- Light_Layer_SpotLight_RimLight.filename = "__Searchlights__/graphics/spotlight-r-rim.png"

local Light_Layer_SpotLight_DimLight = table.deepcopy(Light_Layer_SpotLight_NormLight)
Light_Layer_SpotLight_DimLight.filename = "__Searchlights__/graphics/spotlight-r-less-dim.png"

-- local Light_Layer_SpotLight_NormLight_Red = table.deepcopy(Light_Layer_SpotLight_NormLight)
-- Light_Layer_SpotLight_NormLight_Red.tint = redTint

-- local Light_Layer_SpotLight_RimLight_Red = table.deepcopy(Light_Layer_SpotLight_RimLight)
-- Light_Layer_SpotLight_RimLight_Red.tint = redTint

-- local Light_Layer_SpotLight_DimLight_Red = table.deepcopy(Light_Layer_SpotLight_DimLight)
-- Light_Layer_SpotLight_DimLight_Red.tint = redTint



-- local SpotlightBeamAlarm = table.deepcopy(SpotlightBeamPassive)
-- SpotlightBeamAlarm.name = "spotlight-beam-alarm"
-- SpotlightBeamAlarm.ground_light_animations =
-- {
--   ending =
--   {
--     layers =
--     {
--       Light_Layer_SpotLight_NormLight_Red,
--       Light_Layer_SpotLight_NormLight_Less,
--     }
--   }
-- }
-- SpotlightBeamAlarm.ending =
-- {
--   layers =
--   {
--     Light_Layer_SpotLight_RimLight_Red,
--     Light_Layer_SpotLight_DimLight_Red,
--   }
-- }

local radius_visualisation_specification =
{
  distance = searchlightFriendRadius,
  sprite =
  {
    layers =
    {
      {
        filename = "__Searchlights__/graphics/circleish-radius-visualizat.png",
        priority = "extra-high-no-scale",
        width = 10,
        height = 10,
        scale = 8,
        tint = {0.8, 0.2, 0.2, 0.8}
      }
    }
  }
}
export["radius_visualisation_specification"] = radius_visualisation_specification


local spotlight_glow_animation =
{
  filename = "__Searchlights__/graphics/spotlight-shooting.png",
  line_length = 8,
  width = 60,
  height = 72,
  frame_count = 1,
  direction_count = 64,
  blend_mode = "additive",
  draw_as_glow = true,
  shift = util.by_pixel(0, -18),
  hr_version =
  {
    filename = "__Searchlights__/graphics/hr-spotlight-shooting.png",
    line_length = 8,
    width = 125,
    height = 150,
    frame_count = 1,
    direction_count = 64,
    blend_mode = "additive",
    draw_as_glow = true,
    shift = util.by_pixel(0, -18),
    scale = 0.5
  }
}
export["spotlight_glow_animation"] = spotlight_glow_animation


local spotlight_dim_animation =
{
  filename = "__Searchlights__/graphics/spotlight-dim.png",
  line_length = 8,
  width = 60,
  height = 72,
  frame_count = 1,
  direction_count = 64,
  shift = util.by_pixel(0, -18),
  hr_version =
  {
    filename = "__Searchlights__/graphics/hr-spotlight-dim.png",
    line_length = 8,
    width = 125,
    height = 150,
    frame_count = 1,
    direction_count = 64,
    shift = util.by_pixel(0, -18),
    scale = 0.5
  }
}
export["spotlight_dim_animation"] = spotlight_dim_animation


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


-- data:extend{SpotlightBeamPassive, SpotlightBeamAlarm}
data:extend{SpotlightBeamPassive}

return export