-- Since we added hero-turrets as a hidden optional dependency,
-- force regeneration of the boostInfo table

local cu = require "control-tunion"

cu.UpdateBlockList()