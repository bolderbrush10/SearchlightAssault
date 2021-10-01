local d = require "sl-defines"

require "util" -- for table.deepcopy

-- Be sure to declare functions and vars as 'local' in prototype / data*.lua files,
-- because other mods may have inadvertent access to functions at this step.

-- If another file wants things from this file, they can reference exported items like so:
-- local g = require "graphics"
-- myEntity.animation = g[someAnimation]


local export = {}


------------------------------------------------------------
-- Misc

export.layerTransparentPixel =
{
  filename = "__Searchlights__/graphics/transparent-pixel.png",
  width = 1,
  height = 1,
}


export.layerTransparentAnimation =
{
  filename = "__Searchlights__/graphics/transparent-pixels.png",
  width = 8,
  height = 8,
  direction_count = 1,
}


------------------------------------------------------------
-- Control Unit Sprite and Light

export.controlUnitSprite =
{
  filename = "__Searchlights__/graphics/control-test.png",
  width = 200,
  height = 200,
  scale = 0.1,
}


export.controlUnitLight =
{
  type = "basic",
  intensity = 0.8,
  size = 2,
}


------------------------------------------------------------
-- Signal Box Sprite

export.signalBoxSprite =
{
  filename = "__Searchlights__/graphics/signal-box.png",
  width = 127,
  height = 83,
  scale = 0.5,
}


------------------------------------------------------------
-- Spotlight Model & Glow

export.spotlightGlowAnimation =
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


export.spotlightAlarmGlowAnimation = table.deepcopy(export.spotlightGlowAnimation)
export.spotlightAlarmGlowAnimation.filename = "__Searchlights__/graphics/spotlight-shooting-alarm.png"
export.spotlightAlarmGlowAnimation.hr_version.filename = "__Searchlights__/graphics/hr-spotlight-shooting-alarm.png"


export.spotlightDimAnimation =
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


------------------------------------------------------------
-- Spotlight Beam Layers

local Light_Layer_SpotLight_NormLight =
{
  filename = "__Searchlights__/graphics/spotlight-r.png",
  width = 200,
  height = 200,
  scale = 2,
  flags = { "light" },
  shift = {0.3, 0},
}


local redTint = {r=0.9, g=0.1, b=0.1, a=1}

local Light_Layer_SpotLight_DimLight = table.deepcopy(Light_Layer_SpotLight_NormLight)
Light_Layer_SpotLight_DimLight.filename = "__Searchlights__/graphics/spotlight-r-less-dim.png"

local Light_Layer_SpotLight_NormLight_Red = table.deepcopy(Light_Layer_SpotLight_NormLight)
Light_Layer_SpotLight_NormLight_Red.tint = redTint

local Light_Layer_SpotLight_DimLight_Red = table.deepcopy(Light_Layer_SpotLight_DimLight)


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
  head = export.layerTransparentPixel,
  tail = export.layerTransparentPixel,
  body = export.layerTransparentPixel,
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


return export