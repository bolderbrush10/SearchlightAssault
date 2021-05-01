-- This file's job is to grab any turrets it can find and create a boosted-range version.
-- If some other mod put their turret into this data stage (or later), and we don't grab it, then too bad.

require("sl-defines")

-- Be sure to declare functions and vars as 'local' in prototype / data*.lua files,
-- because other mods may have inadvertent access to functions at this step.


local BoostAnim =
{
  filename = "__Searchlights__/graphics/boost/hr-boost.png",
  priority = "high",
  width = 138,
  height = 104,
  frame_count = 8,
  line_length = 4,
  animation_speed = 1,
  direction_count = 1,
  run_mode = "forward",
  blend_mode = "normal",
  axially_symmetrical = false,
  hr_version =
  {
    filename = "__Searchlights__/graphics/boost/hr-boost.png",
    priority = "high",
    width = 138,
    height = 104,
    frame_count = 8,
    line_length = 4,
    animation_speed = 1,
    direction_count = 1,
    run_mode = "forward",
    blend_mode = "normal",
    axially_symmetrical = false,
  }
}

local BoostSmoke =
{
  name = "range-boost-smoke",
  type = "trivial-smoke",
  animation = BoostAnim,
  duration = 255,
  affected_by_wind = false,
  show_when_smoke_off = true,
  cyclic = true,
  -- TODO glow animation? All the other properties, too
}

data:extend{BoostSmoke}


local function GetBoostName(entity, table)
  if not string.match(entity.name, boostSuffix)
     and not string.match(entity.name, "searchlight") then

    local boostedName =  entity.name .. boostSuffix

    if table[boostedName] == nil then
      return boostedName
    end

  end

  return nil
end


-- Make boosted-range versions of non search light turrets
-- (Factorio might run this entity-script multiple times, so be sure to avoid making dupes)
local function MakeBoost(currTable, newRange)
  for index, turret in pairs(currTable) do
    local boostedName = GetBoostName(turret, currTable)
    if boostedName then

      local boostCopy = table.deepcopy(currTable[turret.name])

      -- Inspired by Mooncat. Thanks, Mooncat.
      boostCopy.localised_name = {"entity-name." .. boostCopy.name}
      if {"entity-description." .. boostCopy.name} then
        boostCopy.localised_description = {"entity-description." .. boostCopy.name}
      end

      boostCopy.name = boostedName
      boostCopy.flags = {"hidden"}
      boostCopy.create_ghost_on_death = false

      if boostCopy.attack_parameters
         and boostCopy.attack_parameters.range < newRange then
        boostCopy.attack_parameters.range = newRange
      end

      if boostCopy.attack_parameters
        and boostCopy.attack_parameters.ammo_type
        and boostCopy.attack_parameters.ammo_type.action
        and boostCopy.attack_parameters.ammo_type.action.action_delivery
        and boostCopy.attack_parameters.ammo_type.action.action_delivery.max_length then
          boostCopy.attack_parameters.ammo_type.action.action_delivery.max_length = newRange
      end

      -- TODO clean this up or what?
      -- if boostCopy.base_picture then

      --   -- for index, layer in pairs(boostCopy.base_picture.layers) do

      --   --   -- layer.filenames = {}
      --   --   -- for x = 0, 8 do
      --   --   --   table.insert(layer.filenames, layer.filename)
      --   --   -- end

      --   --   -- layer.filename = nil
      --   --   layer.width = 10
      --   --   layer.height = 10

      --   --   layer.frame_count = 8
      --   --   layer.run_mode = "forward-then-backward"

      --   --   if layer.hr_version then
      --   --     layer.hr_version.frame_count = 8
      --   --     layer.hr_version.width = 10
      --   --     layer.hr_version.height = 10

      --   --     -- layer.hr_version.filenames = {}
      --   --     -- for x = 0, 8 do
      --   --     --   table.insert(layer.hr_version.filenames, layer.hr_version.filename)
      --   --     -- end
      --   --     -- layer.hr_version.filename = nil
      --   --   end
      --   -- end

      --   boostCopy.base_picture.filename = nil
      --   boostCopy.base_picture.layers = {}
      --   table.insert(boostCopy.base_picture.layers, BoostAnim)
      -- end

      -- boostCopy.created_smoke =
      -- {
      --   smoke_name = "range-boost-smoke"
      -- }

      boostCopy.energy_glow_animation = BoostAnim

      log(serpent.block(boostCopy))

      data:extend{boostCopy}

    end
  end
end

local currTable
currTable = data.raw["electric-turret"]
MakeBoost(currTable, rangeBoostAmount)

currTable = data.raw["ammo-turret"]
MakeBoost(currTable, rangeBoostAmount)

currTable = data.raw["fluid-turret"]
MakeBoost(currTable, rangeBoostAmount)
