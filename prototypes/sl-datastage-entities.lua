require "util" -- for table.deepcopy and util.empty_sprite(animation_length)

-- Be sure to declare functions and vars as 'local' in prototype / data*.lua files,
-- because other mods may have inadvertent access to functions at this step.


local t_s = table.deepcopy(data.raw["corpse"]["small-scorchmark-tintable"])
t_s.name = "sl-tiny-scorchmark-tintable"
t_s.time_before_removed = 1000
t_s.ground_patch.sheet.scale = 0.2
t_s.ground_patch_higher.sheet.scale = 0.1
t_s.ground_patch.sheet.hr_version.scale = 0.2
t_s.ground_patch_higher.sheet.hr_version.scale = 0.1

-- Add new definitions to game data
data:extend{t_s}