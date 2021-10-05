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
  filename = "__Searchlights__/graphics/transparent-pixel.png",
  width = 1,
  height = 1,
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
-- Spotlight Model & Glow

export.spotlightBaseLayer =
{
  filename = "__Searchlights__/graphics/sl-base.png",
  priority = "high",
  axially_symmetrical = false,
  width = 75,
  height = 53,
  shift = util.by_pixel(0, 14),
  scale = 0.64,
  hr_version =
  {
    filename = "__Searchlights__/graphics/sl-base-hr.png",
    priority = "high",
    axially_symmetrical = false,
    width = 150,
    height = 107,
    scale = 0.32,
    shift = util.by_pixel(0, 14),
  }
}


local modelW = 60
local modelH = 71
local maskFlags = { "mask", "low-object" }


-- args:
-- filename, (optional) flags, (optional) drawAsGlow, (optional) runtimeTint
local function make_spotlight(inputs)
return
{
  filename = "__Searchlights__/graphics/" .. inputs.filename .. ".png",
  priority = "high",
  flags = (inputs.flags or {}),
  apply_runtime_tint = (inputs.runtimeTint or false),
  line_length = 8,
  width = modelW,
  height = modelH,
  frame_count = 1,
  direction_count = 64,
  draw_as_glow = (inputs.drawAsGlow or false),
  shift = util.by_pixel(0, -20),
  hr_version =
  {
    filename = "__Searchlights__/graphics/" .. inputs.filename .. "-hr.png",
    priority = "high",
    flags = (inputs.flags or {}),
    apply_runtime_tint = (inputs.runtimeTint or false),
    line_length = 8,
    width = modelW*2,
    height = modelH*2,
    frame_count = 1,
    direction_count = 64,
    draw_as_glow = (inputs.drawAsGlow or false),
    shift = util.by_pixel(0, -20),
    scale = 0.5,
  }
}
end


export.spotlightHeadAnimation = make_spotlight{filename="sl-head"}
export.spotlightGlowAnimation = make_spotlight{filename="sl-glow", flags={"light"}, drawAsGlow=true}
export.spotlightAlarmGlowAnimation = make_spotlight{filename="sl-alarm", flags={"light"}, drawAsGlow=true}
export.spotlightMaskAnimation = make_spotlight{filename="sl-mask", flags=maskFlags, runtimeTint=true}


------------------------------------------------------------
-- Spotlight Beam Layers

local Light_Layer_SpotLight_NormLight =
{
  filename = "__Searchlights__/graphics/spotlight-r.png",
  width = 200,
  height = 200,
  scale = 2,
  flags = { "light" },
}


local redTint = {r=0.9, g=0.1, b=0.1, a=1}

local Light_Layer_SpotLight_StartLight = table.deepcopy(Light_Layer_SpotLight_NormLight)
Light_Layer_SpotLight_StartLight.scale = 0.6

local Light_Layer_SpotLight_DimLight = table.deepcopy(Light_Layer_SpotLight_NormLight)
Light_Layer_SpotLight_DimLight.filename = "__Searchlights__/graphics/spotlight-r-less-dim.png"

local Light_Layer_SpotLight_NormLight_Red = table.deepcopy(Light_Layer_SpotLight_NormLight)
Light_Layer_SpotLight_NormLight_Red.tint = redTint

local Light_Layer_SpotLight_StartLight_Red = table.deepcopy(Light_Layer_SpotLight_NormLight)
Light_Layer_SpotLight_StartLight_Red.scale = 0.6
Light_Layer_SpotLight_StartLight_Red.tint = redTint

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
    start =
    {
      layers =
      {
        Light_Layer_SpotLight_StartLight,
      }
    },
    ending =
    {
      layers =
      {
        Light_Layer_SpotLight_NormLight,
        Light_Layer_SpotLight_DimLight,
      }
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
  start =
  {
    layers =
    {
      Light_Layer_SpotLight_StartLight_Red,
    }
  },
  ending =
  {
    layers =
    {
      Light_Layer_SpotLight_NormLight_Red,
      Light_Layer_SpotLight_DimLight_Red,
    }
  }
}


data:extend{SpotlightBeamPassive, SpotlightBeamAlarm}


return export