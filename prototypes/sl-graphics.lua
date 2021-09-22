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
  filename = "__Searchlights__/graphics/transparent-pixel.png",
  width = 1,
  height = 1,
}
export["Layer_transparent_pixel"] = Layer_transparent_pixel


local Layer_transparent_animation =
{
  filename = "__Searchlights__/graphics/transparent-pixels.png",
  width = 8,
  height = 8,
  direction_count = 1,
}
export["Layer_transparent_animation"] = Layer_transparent_animation


------------------------------------------------------------
-- Spotlight Layers
local control_unit_sprite =
{
  filename = "__Searchlights__/graphics/control-test.png",
  width = 200,
  height = 200,
  scale = 0.1,
}
export["control_unit_sprite"] = control_unit_sprite


local control_unit_light =
{
  type = "basic",
  intensity = 0.8,
  size = 2,
}
export["control_unit_light"] = control_unit_light


------------------------------------------------------------
-- Signal Box Sprite


local signal_box_sprite =
{
  filename = "__Searchlights__/graphics/signal-box.png",
  width = 127,
  height = 83,
  scale = 0.5,
}
export["signal_box_sprite"] = signal_box_sprite


------------------------------------------------------------
-- Spotlight Layers


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

local redTint = {r=0.9, g=0.1, b=0.1, a=1}

-- local Light_Layer_SpotLight_NormLight_Less = table.deepcopy(Light_Layer_SpotLight_NormLight)
-- Light_Layer_SpotLight_NormLight_Less.filename = "__Searchlights__/graphics/spotlight-r-less.png"

-- local Light_Layer_SpotLight_RimLight = table.deepcopy(Light_Layer_SpotLight_NormLight)
-- Light_Layer_SpotLight_RimLight.filename = "__Searchlights__/graphics/spotlight-r-rim.png"

local Light_Layer_SpotLight_DimLight = table.deepcopy(Light_Layer_SpotLight_NormLight)
Light_Layer_SpotLight_DimLight.filename = "__Searchlights__/graphics/spotlight-r-less-dim.png"

local Light_Layer_SpotLight_NormLight_Red = table.deepcopy(Light_Layer_SpotLight_NormLight)
Light_Layer_SpotLight_NormLight_Red.tint = redTint

-- local Light_Layer_SpotLight_RimLight_Red = table.deepcopy(Light_Layer_SpotLight_RimLight)
-- Light_Layer_SpotLight_RimLight_Red.tint = redTint

local Light_Layer_SpotLight_DimLight_Red = table.deepcopy(Light_Layer_SpotLight_DimLight)
-- Light_Layer_SpotLight_DimLight_Red.tint = redTint



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


local spotlight_alarm_glow_animation = table.deepcopy(spotlight_glow_animation)
spotlight_alarm_glow_animation.filename = "__Searchlights__/graphics/spotlight-shooting-alarm.png"
spotlight_alarm_glow_animation.hr_version.filename = "__Searchlights__/graphics/hr-spotlight-shooting-alarm.png"
export["spotlight_alarm_glow_animation"] = spotlight_alarm_glow_animation

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


------------------------------------------------------------
-- Spotlight Beams


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
      -- Light_Layer_SpotLight_NormLight_Less,
    }
  }
}
SpotlightBeamAlarm.ending =
{
  layers =
  {
    -- Light_Layer_SpotLight_RimLight_Red,
    Light_Layer_SpotLight_DimLight_Red,
  }
}


data:extend{SpotlightBeamPassive, SpotlightBeamAlarm}


------------------------------------------------------------
-- Spotlight Warning Light


local SpotlightWarningLightSprite =
{
  filename = "__Searchlights__/graphics/yellow-light.png",
  name = searchlightWatchLightSpriteName,
  type = "sprite",
  blend_mode = "normal",
  width=32,
  height=32,
}


data:extend{SpotlightWarningLightSprite}



return export