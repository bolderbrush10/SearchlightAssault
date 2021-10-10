local d = require "sl-defines"


local function SwapToBaseEntityType(itemStack)
  -- Step 1: Swap the items
  local old = itemStack.get_blueprint_entities()
  local new = {}

  for index, e in pairs(old) do
    if e.name == d.searchlightAlarmName  then
      e.name = d.searchlightBaseName
    elseif e.name:sub(-#d.boostSuffix) == d.boostSuffix then
      e.name = e.name:gsub(d.boostSuffix, "")
    end
    table.insert(new, e)
  end

  itemStack.set_blueprint_entities(old)

  -- Step 2: Swap the icons
  local oldi = itemStack.blueprint_icons
  local newi = {}
  for index, icon in pairs(oldi) do
    if icon.signal.type == "item" and icon.signal.name then
      if icon.signal.name == d.searchlightAlarmName then
        icon.signal.name = d.searchlightItemName
      -- A neat trick to see if a string ends with a given suffix
      elseif icon.signal.name:sub(-#d.boostSuffix) == d.boostSuffix then
        icon.signal.name = icon.signal.name:gsub(d.boostSuffix, "")
      end
    end
    table.insert(newi, icon)
  end

  itemStack.blueprint_icons = newi
end


-- Since the on_player_setup_blueprint event doesn't point you to the actual blueprint
-- which has been setup, we have to trawl all of the player's blueprints recursively.
local function SeekBlueprints(inventory)
  for index = 1, #inventory - inventory.count_empty_stacks() do
    local item = inventory[index]
    if item.valid_for_read and item.name == "blueprint" and item.is_blueprint_setup() then
      SwapToBaseEntityType(item)
    elseif item.valid_for_read and item.name == "blueprint-book" then
      -- Currently, the game prevents you from making a blueprint book that contains itself somewhere.
      SeekBlueprints(item.get_inventory(defines.inventory.item_main))
    end
  end
end


function ScanBP_StacksAndSwapToBaseType(event)
  local player = game.players[event.player_index]
  local cstack = player.cursor_stack
  local pstack = player.blueprint_to_setup

  if cstack and cstack.valid_for_read and cstack.is_blueprint_setup() then
    SwapToBaseEntityType(cstack)
  elseif pstack and pstack.valid_for_read and pstack.is_blueprint_setup() then
    SwapToBaseEntityType(pstack)
  else
    SeekBlueprints(player.get_main_inventory())
  end
end
