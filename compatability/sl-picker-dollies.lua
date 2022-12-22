local d = require "sl-defines"
local r = require "sl-relation"
local u  = require "sl-util"
local cu = require "control-tunion"

require "util" -- for table.deepcopy


local export = {}


local sigOwnX    = {type="virtual", name="sl-own-x"}
local sigOwnY    = {type="virtual", name="sl-own-y"}


local function WillWiresReach(entity)
  for _, wire_type in pairs(entity.circuit_connected_entities) do
    for _, neighbour in pairs(wire_type) do
      if not entity.can_wires_reach(neighbour) then 
        return false 
      end
    end
  end

  return true
end


local function SearchlightMoved(g, e, event)
  local i = g.signal
  i.teleport(e.position)

  -- Revert the picker's teleport if the new position is invalid for our hidden entity,
  -- or if there is an active alarm
  if  (   not WillWiresReach(i) 
       or g.light.name == d.searchlightAlarmName)
       and event.start_pos then
    e.teleport(event.start_pos)
    i.teleport(event.start_pos)

    local player = game.players[event.player_index]
    if player then
      if g.light.name == d.searchlightAlarmName then
        player.create_local_flying_text{text = {"sla.sla-no-moving"}, position = e.position}
      else
        -- We'll borrow picker dollies' locale files
        player.create_local_flying_text{text = {"picker-dollies.wires-maxed"}, position = e.position}
      end
      player.play_sound{path = "utility/cannot_build", position = player.position, volume = 1} 
    end

    return
  end

  local c = i.get_control_behavior()
  c.set_signal(d.circuitSlots.ownPositionXSlot, {signal = sigOwnX,  count = i.position.x})
  c.set_signal(d.circuitSlots.ownPositionYSlot, {signal = sigOwnY,  count = i.position.y})

  g.spotter.teleport(e.position)

  local friends = e.surface.find_entities_filtered{area=u.GetBoostableAreaFromPosition(e.position),
                                                   type={"fluid-turret", "electric-turret", "ammo-turret"},
                                                   force=e.force}
  
  local displaced = table.deepcopy(r.getRelationLHS(global.GestaltTunionRelations, g.gID))
  local newNeighbors = {}
  for _, f in pairs(friends) do
    local tu = global.tun_to_tunion[f.unit_number]

    if cu.IsBoostableAndInRange(g, f) then
      if r.hasRelation(global.GestaltTunionRelations, g.gID, tu.tuID) then
        displaced[tu.tuID] = nil
      else
        table.insert(newNeighbors, f)
      end
    end
  end

  for _, n in pairs(newNeighbors) do
    cu.TurretAdded(n)
  end

  for d, _ in pairs(displaced) do
    r.removeRelation(global.GestaltTunionRelations, g.gID, d)

    if not next(r.getRelationRHS(global.GestaltTunionRelations, d)) then
      cu.TurretRemoved(global.tunions[d])
    end
  end
end


-- TODO Recalculate neighbors (have to do this even if not allowing moving while boosted)
local function TurretMoved(e, event)
  local tu = global.tun_to_tunion[e.unit_number]
  -- Revert the turret's teleport if there is an active alarm boosting it
  if tu and tu.boosted then
    e.teleport(event.start_pos)

    local player = game.players[event.player_index]
    if player then
      player.create_local_flying_text{text = {"sla.sla-no-moving"}, position = e.position}
      player.play_sound{path = "utility/cannot_build", position = player.position, volume = 1} 
    end

    return
  end

  cu.TurretRemoved(e)
  cu.TurretAdded(e)
end


--- @class EventData.PickerDollies.dolly_moved_event: EventData
--- @field player_index uint
--- @field moved_entity LuaEntity
--- @field start_pos MapPosition

local function OnMoved_PickerDollies(event)
  local e = event.moved_entity
  if not e then return end

  local g = global.unum_to_g[e.unit_number]

  if g then
    SearchlightMoved(g, e, event)
  elseif e.type == "fluid-turret" then
    TurretMoved(e, event)
  elseif e.type == "electric-turret" then
    TurretMoved(e, event)
  elseif e.type == "ammo-turret" then
    TurretMoved(e, event)
  end
end


local function BlockMoving()
  remote.call("PickerDollies", "add_blacklist_name", d.searchlightSignalInterfaceName)
  remote.call("PickerDollies", "add_blacklist_name", d.turtleName)
  remote.call("PickerDollies", "add_blacklist_name", d.spotterName)
  remote.call("PickerDollies", "add_blacklist_name", d.searchlightControllerName)
end


export.OnInit = function()
  script.on_event(remote.call("PickerDollies", "dolly_moved_entity_id"), OnMoved_PickerDollies)
  BlockMoving()
end


export.OnLoad = function()
  script.on_event(remote.call("PickerDollies", "dolly_moved_entity_id"), OnMoved_PickerDollies)
  BlockMoving()
end


return export