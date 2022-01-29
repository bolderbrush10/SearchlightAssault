local d = require "sl-defines"
local a = require "audio.sl-audio"

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
  filename = "__SearchlightAssault__/graphics/transparent-pixel.png",
  width = 1,
  height = 1,
}

export.layerTransparentAnimation = table.deepcopy(export.layerTransparentPixel)
export.layerTransparentAnimation.direction_count = 1

-- Builder for the searchlight framesequence
local slFrameCount = 60
local slStaticFrameSeq = {}

for index = 1, slFrameCount do
  table.insert(slStaticFrameSeq, 1)
end

export.layerTransparentAnimation_Seq =
{
  filename = "__SearchlightAssault__/graphics/transparent-pixel.png",
  width = 1,
  height = 1,
  direction_count = 1,
  frame_count = slFrameCount,
  frame_sequence = slStaticFrameSeq,
}


------------------------------------------------------------
-- Control Unit Sprite and Light

-- Using using ~200 of a maximum of 255 animation frames absolutely necessary?
-- Probably not. Looks cool though.
local controlFrameSeq = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
                         1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
                         1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
                         2,3,4,5,6,7,8,9,
                         10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,
                         10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,
                         10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,
                         10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,
                         9,9,9,9,7,7,7,1}

export.controlUnitSprite =
{
  filename = "__SearchlightAssault__/graphics/sl-control.png",
  priority = "high",
  axially_symmetrical = false,
  frame_count = 10,
  frame_sequence = controlFrameSeq,
  line_length = 5,
  width = 45,
  height = 60,
  scale = 0.4,
  hr_version =
  {
    filename = "__SearchlightAssault__/graphics/sl-control-hr.png",
    priority = "high",
    axially_symmetrical = false,
    frame_count = 10,
    frame_sequence = controlFrameSeq,
    line_length = 5,
    width = 90,
    height = 120,
    scale = 0.2,
  }
}


export.controlUnitLight =
{
  type = "basic",
  intensity = 0.8,
  size = 2,
}


------------------------------------------------------------
-- Searchlight Model & Glow

local baseFrameSeq = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
                      1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
                      1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
                      1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
                      2,2,3,3,4,4,5,5,6,6,7,7,8,}


export.searchlightBaseLayer =
{
  filename = "__SearchlightAssault__/graphics/sl-base.png",
  priority = "high",
  axially_symmetrical = false,
  frame_count = 1,
  line_length = 4,
  width = 75,
  height = 53,
  scale = 0.66,
  shift = util.by_pixel(0, 15),
  hr_version =
  {
    filename = "__SearchlightAssault__/graphics/sl-base-hr.png",
    priority = "high",
    axially_symmetrical = false,
    frame_count = 1,
    line_length = 4,
    width = 150,
    height = 107,
    scale = 0.33,
    shift = util.by_pixel(0, 15),
  }
}


export.searchlightBaseAnimated = table.deepcopy(export.searchlightBaseLayer)
export.searchlightBaseAnimated.frame_count = 8
export.searchlightBaseAnimated.frame_sequence = baseFrameSeq
export.searchlightBaseAnimated.hr_version.frame_count = 8
export.searchlightBaseAnimated.hr_version.frame_sequence = baseFrameSeq


export.searchlightShadowLayer =
{
  filename = "__SearchlightAssault__/graphics/sl-shadow.png",
  priority = "high",
  axially_symmetrical = false,
  draw_as_shadow = true,
  frame_count = 1,
  direction_count = 64,
  line_length = 8,
  width = 142,
  height = 53,
  scale = 0.64,
  shift = util.by_pixel(22, 28),
  hr_version =
  {
    filename = "__SearchlightAssault__/graphics/sl-shadow-hr.png",
    priority = "high",
    axially_symmetrical = false,
    draw_as_shadow = true,
    frame_count = 1,
    direction_count = 64,
    line_length = 8,
    width = 285,
    height = 107,
    scale = 0.32,
    shift = util.by_pixel(22, 28),
  }
}


local modelW = 60
local modelH = 71
local maskFlags = { "mask", "low-object" }


-- args:
-- filename, (optional) flags, (optional) drawAsGlow, (optional) runtimeTint
local function make_searchlight(inputs)
return
{
  filename = "__SearchlightAssault__/graphics/" .. inputs.filename .. ".png",
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
    filename = "__SearchlightAssault__/graphics/" .. inputs.filename .. "-hr.png",
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


export.searchlightHeadAnimation = make_searchlight{filename="sl-head"}
export.searchlightGlowAnimation = make_searchlight{filename="sl-glow", flags={"light"}, drawAsGlow=true}
export.searchlightAlarmGlowAnimation = make_searchlight{filename="sl-alarm", flags={"light"}, drawAsGlow=true}
export.searchlightMaskAnimation = make_searchlight{filename="sl-mask", flags=maskFlags, runtimeTint=true}


------------------------------------------------------------
-- Searchlight Remants

export.searchlightRemnants = {layers =
{{
  filename = "__SearchlightAssault__/graphics/sl-remnants.png",
  priority = "high",
  axially_symmetrical = false,
  direction_count = 1,
  width = 85,
  height = 112,
  scale = 0.66,
  shift = util.by_pixel(0, -5),
  hr_version =
  {
    filename = "__SearchlightAssault__/graphics/sl-remnants-hr.png",
    priority = "high",
    axially_symmetrical = false,
    direction_count = 1,
    width = 170,
    height = 224,
    scale = 0.33,
    shift = util.by_pixel(0, -5),
  }
},
{
  filename = "__SearchlightAssault__/graphics/sl-remnants-shadow.png",
  priority = "high",
  draw_as_shadow = true,
  axially_symmetrical = false,
  direction_count = 1,
  width = 137,
  height = 52,
  scale = 0.64,
  shift = util.by_pixel(22, 25),
  hr_version =
  {
    filename = "__SearchlightAssault__/graphics/sl-remnants-shadow-hr.png",
    priority = "high",
    draw_as_shadow = true,
    axially_symmetrical = false,
    direction_count = 1,
    width = 273,
    height = 104,
    scale = 0.32,
    shift = util.by_pixel(22, 25),
  }
}}}


------------------------------------------------------------
-- Searchlight Beam Layers

local Light_Layer_Searchlight_DayHaze =
{
  filename = "__SearchlightAssault__/graphics/searchlight-haze.png",
  line_length = 2,
  frame_count = slFrameCount,
  frame_sequence = {
                    1,1,1,1,1,1,1,1,1,1,1,1,
                    2,2,2,2,2,2,2,2,2,2,2,2,
                    3,3,3,3,3,3,3,3,3,3,3,3,
                    4,4,4,4,4,4,4,4,4,4,4,4,
                    2,2,2,2,2,2,2,2,2,2,2,2,
                    },
  width = 200,
  height = 200,
  scale = 1,
  blend_mode = "additive",
  tint = {r=230/255, g=150/255, b=0, a=0.1},
}

local Light_Layer_Searchlight_AlarmHaze = table.deepcopy(Light_Layer_Searchlight_DayHaze)
Light_Layer_Searchlight_AlarmHaze.tint = {r=150/255, g=0, b=0, a=1}


local Light_Layer_Searchlight_OneCellHaze =
{
  filename = "__SearchlightAssault__/graphics/searchlight-haze-onecell.png",
  line_length = 2,
  frame_count = slFrameCount,
  frame_sequence = {
                    1,1,1,1,1,1,1,1,1,1,1,1,
                    2,2,2,2,2,2,2,2,2,2,2,2,
                    3,3,3,3,3,3,3,3,3,3,3,3,
                    4,4,4,4,4,4,4,4,4,4,4,4,
                    2,2,2,2,2,2,2,2,2,2,2,2,
                    },
  width = 200,
  height = 200,
  scale = 0.7,
  blend_mode = "additive",
  tint = {r=230/255, g=115/255, b=0, a=1.0},
}

local OneCellHazeAnim = 
{
  name = d.hazeOneCellAnim,
  type = "animation",
  layers = {Light_Layer_Searchlight_OneCellHaze},
}

local OneHexSprite =
{
  filename = "__SearchlightAssault__/graphics/searchlight-haze-onehex.png",
  type = "sprite",
  name = d.hazeOneHex,
  width = 50,
  height = 50,
  scale = 0.4,
  blend_mode = "additive",
  tint = {r=230/255, g=115/255, b=0, a=0.8},
}

local Light_Layer_Searchlight_NormLight =
{
  filename = "__SearchlightAssault__/graphics/searchlight-r.png",
  width = 200,
  height = 200,
  scale = 2.2,
  frame_count = slFrameCount,
  frame_sequence = slStaticFrameSeq,
  flags = { "light" },
}


local redTint = {r=0.9, g=0.1, b=0.1, a=1}

local Light_Layer_Searchlight_StartLight = table.deepcopy(Light_Layer_Searchlight_NormLight)
Light_Layer_Searchlight_StartLight.scale = 0.6

local Light_Layer_Searchlight_DimLight = table.deepcopy(Light_Layer_Searchlight_NormLight)
Light_Layer_Searchlight_DimLight.filename = "__SearchlightAssault__/graphics/searchlight-r-less-dim.png"

local Light_Layer_Searchlight_NormLight_Red = table.deepcopy(Light_Layer_Searchlight_NormLight)
Light_Layer_Searchlight_NormLight_Red.tint = redTint

local Light_Layer_Searchlight_StartLight_Red = table.deepcopy(Light_Layer_Searchlight_NormLight)
Light_Layer_Searchlight_StartLight_Red.scale = 0.6
Light_Layer_Searchlight_StartLight_Red.tint = redTint

local Light_Layer_Searchlight_DimLight_Red = table.deepcopy(Light_Layer_Searchlight_DimLight)

------------------------------------------------------------
-- Searchlight Beams

local SearchlightBeamPassive =
{
  type = "beam",
  name = "searchlight-beam-passive",
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
        Light_Layer_Searchlight_StartLight,
      }
    },
    ending =
    {
      layers =
      {
        Light_Layer_Searchlight_NormLight,
        Light_Layer_Searchlight_DimLight,
      }
    }
  },
  ending = Light_Layer_Searchlight_DayHaze,
  tail = export.layerTransparentAnimation_Seq,
  head = export.layerTransparentAnimation_Seq,
  body = export.layerTransparentAnimation_Seq,
}


local SearchlightBeamAlarm = table.deepcopy(SearchlightBeamPassive)
SearchlightBeamAlarm.name = "searchlight-beam-alarm"
SearchlightBeamAlarm.ending = Light_Layer_Searchlight_AlarmHaze
SearchlightBeamAlarm.ground_light_animations =
{
  start =
  {
    layers =
    {
      Light_Layer_Searchlight_StartLight_Red,
    }
  },
  ending =
  {
    layers =
    {
      Light_Layer_Searchlight_NormLight_Red,
      Light_Layer_Searchlight_DimLight_Red,
    }
  }
}


data:extend{SearchlightBeamPassive, SearchlightBeamAlarm, OneCellHazeAnim, OneHexSprite}


return export
