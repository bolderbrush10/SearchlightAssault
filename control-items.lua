local d = require "sl-defines"
local u = require "sl-util"


local export = {}


local function SwapToBaseEntityType(itemStack)
  -- Step 1: Swap the items
  local old = itemStack.get_blueprint_entities()

  if not old then
    return
  end

  local new = {}

  for index, e in pairs(old) do
    if e.name == d.searchlightAlarmName  then
      e.name = d.searchlightBaseName
    elseif e.name == d.searchlightSafeName  then
      e.name = d.searchlightBaseName
    elseif u.EndsWith(e.name, d.boostSuffix) then
      e.name = e.name:gsub(d.boostSuffix, "")
    end

    -- Step 1-A: Resort the items so the signal interface ghost stops appearing on top
    if e.name == d.searchlightSignalInterfaceName then
      table.insert(new, 1, e)
    else
      table.insert(new, e)
    end
  end

  itemStack.set_blueprint_entities(new)

  -- Step 2: Swap the icons
  local oldi = itemStack.blueprint_icons
  local newi = {}
  for _, icon in pairs(oldi) do
    if icon.signal.type == "item" and icon.signal.name then
      if icon.signal.name == d.searchlightAlarmName then
        icon.signal.name = d.searchlightItemName
      elseif icon.signal.name == d.searchlightSafeName then
        icon.signal.name = d.searchlightItemName
      elseif u.EndsWith(icon.signal.name, d.boostSuffix) then
        icon.signal.name = icon.signal.name:gsub(d.boostSuffix, "")
      end
    end
    table.insert(newi, icon)
  end

  if next(newi) then -- protect against deleted icons
    itemStack.blueprint_icons = newi
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
  for index = 1, #inventory - inventory.count_empty_stacks() do
    local item = inventory[index]
    if item.valid_for_read and item.name == "blueprint" and item.is_blueprint_setup() then
      SwapToBaseEntityType(item)
      CheckForSignalSearchlightParity(item)
    elseif item.valid_for_read and item.name == "blueprint-book" then
      -- Currently, the game prevents you from making a blueprint book that contains itself somewhere.
      SeekBlueprints(item.get_inventory(defines.inventory.item_main))
    end
  end
end


export.ScanBP_StacksAndSwapToBaseType = function(event)
  local player = game.players[event.player_index]
  local cstack = player.cursor_stack
  local pstack = player.blueprint_to_setup

  if cstack and cstack.valid_for_read and cstack.is_blueprint and cstack.is_blueprint_setup() then
    SwapToBaseEntityType(cstack)
    CheckForSignalSearchlightParity(cstack)
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


return export
