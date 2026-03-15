local d = require "sl-defines"
local u = require "sl-util"


local export = {}

local function lookupBaseName(name)
    -- Get the base searchlight/turret name of alarm/safe/boosted versions
    if name == d.searchlightAlarmName  then
     return d.searchlightBaseName
    elseif name == d.searchlightSafeName  then
      return d.searchlightBaseName
    elseif u.EndsWith(name, d.boostSuffix) then
      return name:gsub(d.boostSuffix, "")
    end

    return name
end


-- We can't figure out what's causing the crashes, but maybe we can at least reduce them
-- by checking if we even need to call the line that's crashing
-- ( SwapToBaseEntityType(itemStack)::itemStack.set_blueprint_entities(new) )
local function needsBaseEntitySwappedIn(itemStack)
  local old = itemStack.get_blueprint_entities()

  if not old then
    return false
  end

  local new = {}

  for index, e in pairs(old) do
    if e.name ~= lookupBaseName(e.name) then
      return true
    end
  end

  return false
end


local function SwapToBaseEntityType(itemStack)
  -- Step 1: Swap the items
  local old = itemStack.get_blueprint_entities()

  if not old then
    return
  end

  local new = {}
  local tags = {}

  for index, e in pairs(old) do
    -- TODO Is this indexing bad & what's causing the crashes?
    tags[index] = itemStack.get_blueprint_entity_tags(index)

    e.name = lookupBaseName(e.name)

    -- Resort the items so the signal interface ghost stops appearing on top
    if e.name == d.searchlightSignalInterfaceName then
      table.insert(new, 1, e)
    else
      table.insert(new, e)
    end
  end

  itemStack.set_blueprint_entities(new)

  -- Tentative, no idea if this will work since most other mods
  -- I've tested against don't seem to use tags
  for index, tag in pairs(tags) do
    itemStack.set_blueprint_entity_tags(index, tag)
  end
end


-- Check that any deleted searchlights have their
-- corresponding interface also deleted
-- (If someone somehow deletes just an interface from a blueprint,
--  I guess it's okay if we still keep the light?)
local function CheckForSignalSearchlightParity(itemStack)
  local old = itemStack.get_blueprint_entities()

  if not old then
    return
  end

  local new = {}

  local sigPositions = {}
  local lightPositions = {}

  for index, e in pairs(old) do
    if e.name == d.searchlightSignalInterfaceName then
      table.insert(sigPositions, index, e.position)
    elseif e.name == d.searchlightBaseName then
      table.insert(lightPositions, index, e.position)
      table.insert(new, e)
    else
      table.insert(new, e)
    end
  end

  for sigIndex, sigPos in pairs(sigPositions) do
    for lightIndex, lightPos in pairs(lightPositions) do
      if sigPos.x == lightPos.x and sigPos.y == lightPos.y then
        table.insert(new, 1, old[sigIndex])
      end
    end
  end

  itemStack.set_blueprint_entities(new)
end


-- Since the on_player_setup_blueprint event doesn't point you to the actual blueprint
-- which has been setup, we have to trawl all of the player's blueprints recursively.
local function SeekBlueprints(inventory)
  if not inventory then
    return
  end

  for index = 1, #inventory - inventory.count_empty_stacks() do
    local item = inventory[index]
    if item.valid_for_read and item.name == "blueprint" and item.is_blueprint_setup() and needsBaseEntitySwappedIn(item) then
      SwapToBaseEntityType(item)
      CheckForSignalSearchlightParity(item)
    elseif item.valid_for_read and item.name == "blueprint-book" and needsBaseEntitySwappedIn(item) then
      -- Currently, the game prevents you from making a blueprint book that contains itself somewhere.
      SeekBlueprints(item.get_inventory(defines.inventory.item_main))
    end
  end
end


-- TODO would it be be more efficient to just leave boosted turrets and stuff inside of player's blueprints,
-- and only bother updating them when a blueprint/ghost is placed?
-- We'd still want to use the uninstall feature to scan blueprints for boosted things and downgrade them there
-- (maybe add a progress bar in that case)
export.ScanBP_StacksAndSwapToBaseType = function(event)
  local player = game.players[event.player_index]
  local cstack = player.cursor_stack
  local pstack = player.blueprint_to_setup

  if cstack and cstack.valid_for_read and cstack.is_blueprint and cstack.is_blueprint_setup() then
    -- The player has very likely used either cut or copy.
    -- If we mess with the item stack here while the player
    -- has cut wire-connected entities, the wires will be dropped,
    -- and the player will be very disappointed.
    -- We'll work around that by checking the ghost in SwapGhostToBaseType
    SeekBlueprints(player.get_main_inventory())
  elseif pstack and pstack.valid_for_read and pstack.is_blueprint and pstack.is_blueprint_setup() then
    SwapToBaseEntityType(pstack)
    CheckForSignalSearchlightParity(pstack)
  else
    SeekBlueprints(player.get_main_inventory())
  end
end


-- It's possible for the player to right click to destroy a searchlight ghost,
-- but leave behind the signal interface ghost from a blueprint.
-- The best we can do is detect when such ghosts are built and destroy them
-- after the fact, since there doesn't seem to be an event to detect when
-- the player manually clears a ghost via right click.
export.CheckSignalInterfaceHasSearchlight = function(i)
  local sLight = i.surface.find_entities_filtered{name={d.searchlightBaseName,d.searchlightAlarmName},
                                                  position = i.position}

  local slGhost = i.surface.find_entities_filtered{ghost_name={d.searchlightBaseName},
                                                   position = i.position}

  if not ((sLight  and sLight[1])
       or (slGhost and slGhost[1])) then
    i.destroy()
  end
end


export.SwapGhostToBaseType = function(entity)
  local newInnerName = lookupBaseName(entity.ghost_name)
  if newInnerName == entity.ghost_name then
    return
  end

  local s = entity.surface

  local params = {
    name = entity.name,
    position = entity.position,
    direction = entity.direction,
    quality = entity.quality,
    force = entity.force,
    tags = entity.tags,
    inner_name = newInnerName,
    create_build_effect_smoke = false,
    raise_built = true,
  }

  entity.destroy({raise_destroy=true})
  s.create_entity(params)
end


return export
