
-- On Player Rotated
script.on_event(defines.events.on_player_rotated_entity,
function(event)
  local e = event.entity
  local tu = global.tun_to_tunion[e.unit_number]
  local g = global.unum_to_g[e.unit_number]

  if tu and tu.boosted then
    -- Detect if a player rotated a turret with an arc (eg, a flame turret)
    -- and check if it can still hit that foe.
    -- If it can target something in its new direction, it'll get reboosted in a moment.
    if not e.shooting_target then
      cu.UnBoost(tu)
    end
  elseif g then
    cs.Rotated(g, e, event.previous_direction, event.player_index)
  end
end)


----------------------------------------------------------------
  local public = {}
  return public
----------------------------------------------------------------
