local d = require "sl-defines"
local u = require "sl-util"

local ct = require "control-tunion"

-- forward declarations
local UpdateBoostInfo
local concatKeys
local remove_from_blocklist
local add_to_blocklist
local UnboostBlockedTurrets
local UpdateBlockList
local InitTables_Blocklist




remote.add_interface("sl_blocklist", {add = add_to_blocklist, remove = remove_from_blocklist})


InitTables_Blocklist = function()
  -- Map: turret name -> true
  global.remoteBlock = {}

  -- Map: turret name -> true
  global.blockList = {}

  -- Initialize blockList & boostInfo
  export.UpdateBlockList()
end


add_to_blocklist = function(turretName)
  local protos = game.get_filtered_entity_prototypes{{filter = "turret"}}

  if not protos[turretName] then
    log("Searchlight Assault: Turret prototype name specified by remote call not found: " .. turretName)
    return
  end

  log("Searchlight Assault: Blocking " .. turretName .. " from searchlight interaction.")

  global.remoteBlock[turretName] = true
  export.UpdateBlockList(true)
  export.UnboostBlockedTurrets()
end


remove_from_blocklist = function(turretName)
  if global.remoteBlock[turretName] then
    log("Searchlight Assault: Unblocking " .. turretName .. "; interaction now allowed.")
  end

  global.remoteBlock[turretName] = nil
  export.UpdateBlockList(true)
  export.UnboostBlockedTurrets()
end


concatKeys = function(table)
  local result = ""

  -- factorio API guarantees deterministic iteration
  for key, value in pairs(table) do
    result = result .. key
  end

  return result
end


-- Breaking out a seperate function like this allows us to easily
-- note changes to the block list and output them to game.print()
UpdateBoostInfo = function(blockList)
  local protos = game.get_filtered_entity_prototypes{{filter = "turret"}}

  for _, turret in pairs(protos) do
    if blockList[turret.name] then
      global.boostInfo[turret.name] = ct.bInfo.BLOCKED

      if not global.blockList[turret.name] then
        game.print("Searchlight Assault: Now ignoring " .. turret.name)
      end
    elseif global.remoteBlock[turret.name] then
      global.boostInfo[turret.name] = ct.bInfo.BLOCKED
    elseif game.entity_prototypes[turret.name .. d.boostSuffix] then
      global.boostInfo[turret.name] = ct.bInfo.UNBOOSTED
    elseif u.EndsWith(turret.name, d.boostSuffix) then
      global.boostInfo[turret.name] = ct.bInfo.BOOSTED
    else
      global.boostInfo[turret.name] = ct.bInfo.NOT_BOOSTABLE
    end
  end
end


UpdateBlockList = function(calledByRemote)
  if not calledByRemote then
    calledByRemote = false
  end

  local settingStr = settings.global[d.ignoreEntriesList].value
  local newBlockList = {}

  -- Tokenize semi-colon delimited strings
  for token in string.gmatch(settingStr, "[^;]+") do
    local trim = token:gsub("%s+", "")

    if game.entity_prototypes[trim] then
      newBlockList[trim] = true
    elseif not calledByRemote then
      local result = "Unable to add misspelled or nonexistent turret " ..
                     "name to Searchlight Assault ignore list: " .. token

      game.print(result)
    end
  end

  -- Quick & dirty way to compare table equality for our use case
  if not calledByRemote and next(global.blockList) and concatKeys(global.blockList) == concatKeys(newBlockList) then
    game.print("Searchlight Assault: No turrets affected by settings change")

    return
  end

  UpdateBoostInfo(newBlockList)

  global.blockList = newBlockList
end


UnboostBlockedTurrets = function()
  for tuID, tu in pairs(global.tunions) do
    if tu.boosted and global.boostInfo[tu.turret.name:gsub(d.boostSuffix, "")] == ct.bInfo.BLOCKED then
      ct.UnBoost(tu)
    end
  end
end

local public = {}
public.UpdateBoostInfo = UpdateBoostInfo
public.concatKeys = concatKeys
public.remove_from_blocklist = remove_from_blocklist
public.add_to_blocklist = add_to_blocklist
public.UnboostBlockedTurrets = UnboostBlockedTurrets
public.UpdateBlockList = UpdateBlockList
public.InitTables_Blocklist = InitTables_Blocklist
return public
