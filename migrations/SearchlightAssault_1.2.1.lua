-- Since we added hero-turrets as a hidden optional dependency,
-- force regeneration of the boostInfo table

storage.remoteBlock = {}

local cb = require "control-blocklist"

cb.UpdateBlockList()