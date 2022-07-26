-- Since we added hero-turrets as a hidden optional dependency,
-- force regeneration of the boostInfo table

global.remoteBlock = {}

local cb = require "control-blocklist"

cb.UpdateBlockList()