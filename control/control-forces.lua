local d = require "sl-defines"
local u = require "sl-util"

-- forward declarations
local MigrateTurtleForces
local UpdateTForceRelationships
local PrepareTurtleForce
local InitTables_Forces


-- On Force Relationship Changed
for index, e in pairs
({
  defines.events.on_force_cease_fire_changed,
  defines.events.on_force_friends_changed,
}) do
  script.on_event(e,
  function(event)

    cf.UpdateTForceRelationships(event.force)

  end)
end


-- On Force About To Be Merged
script.on_event(defines.events.on_forces_merging,
function(event)

  cf.MigrateTurtleForces(event.source, event.destination)

end)


local export = {}


InitTables_Forces = function()

  -- Map: Turtle Force Name -> true
  global.sl_force_init = {}

end


-- The 'turtle' force exists to hold an imaginary target (The 'Turtle')
-- for searchlights to 'shoot' while they scan around for enemy units.

-- This turtle force also needs to 'attack' any foes of the searchlight's owner
-- to trigger a function call that will let us know we've spotted an enemy.

-- For multiplayer compatiblity, we create a turtle force for any force
-- that builds a searchlight and update relationships accordingly.


-- Called when a new searchlight is created
PrepareTurtleForce = function(SearchlightForce)
  local turtleForceName = SearchlightForce.name .. d.turtleForceSuffix

  if global.sl_force_init[turtleForceName] or game.forces[turtleForceName] then
    return turtleForceName -- We've already initialized this force, nothing to do
  end

  game.create_force(turtleForceName)
  global.sl_force_init[turtleForceName] = true

  export.UpdateTForceRelationships(SearchlightForce)

  return turtleForceName
end


-- When something (another mod, most likely) creates a new force,
-- or updates a relationship, reflect those relations in the turtle force.
-- The turtle force should ignore the searchlight's friends and attack its enemies.
-- Only the searchlight owner should have cease_fire = false with its turtle.
-- Everyone else should ignore it.
UpdateTForceRelationships = function(SearchlightForce)

  if u.EndsWith(SearchlightForce.name, d.turtleForceSuffix) then
    return -- Don't recurse
  end

  local turtleForceName = SearchlightForce.name .. d.turtleForceSuffix

  if global.sl_force_init[turtleForceName] == nil then
    return -- Don't recurse
  end

  local tForce = game.forces[turtleForceName]

  -- The owner force needs to have cease_fire == false toward the turtle force.
  -- Otherwise, searchlights won't target turtles under any circumstances
  -- (Make the turtle itself invulnerable and things will ignore it by default,
  --  then we can use .set_shooting_target to get the searchlight to attack)
  SearchlightForce.set_cease_fire(tForce, false)
  SearchlightForce.set_friend(tForce, false)
  -- Turtles, naturally, shouldn't attack their searchlight-owner force
  tForce.set_cease_fire(SearchlightForce, true)
  tForce.set_friend(SearchlightForce, false)

  for _, f in pairs(game.forces) do

    if f.name == turtleForceName then
      ;
    elseif f.name == SearchlightForce.name then
      ;
    elseif u.EndsWith(f.name, d.turtleForceSuffix) then
      -- Turtles should always ignore other turtles
      -- (Otherwise, two turtles from allied forces might fight in the middle of nowhere)
      f.set_cease_fire(tForce, true)
      f.set_friend(tForce, false)

      tForce.set_cease_fire(f, true)
      tForce.set_friend(f, false)
    else

      f.set_cease_fire(tForce, true)
      f.set_friend(tForce, false)

      -- Since friend relationships overrule cease_fire = false,
      -- we need to mirror them as well.
      tForce.set_friend(f, SearchlightForce.get_friend(f))
      tForce.set_cease_fire(f, SearchlightForce.get_cease_fire(f))

    end

  end

end


MigrateTurtleForces = function(oldSLForce, newSLForce)
  -- Don't recurse when we migrate turtles
  if u.EndsWith(oldSLForce.name, d.turtleForceSuffix) then
    return
  end

  local oldtForceName = oldSLForce.name .. d.turtleForceSuffix

  -- If there's no associated turtle force, nothing to do
  if global.sl_force_init[oldtForceName] == nil then
    return
  end

  global.sl_force_init[oldtForceName] = nil
  local newtForceName = export.PrepareTurtleForce(newSLForce)

  -- The API says nested merge_forces will happen next tick,
  -- but that should be fine, I think...
  game.merge_forces(oldtForceName, newtForceName)
end

local public = {}
public.MigrateTurtleForces = MigrateTurtleForces
public.UpdateTForceRelationships = UpdateTForceRelationships
public.PrepareTurtleForce = PrepareTurtleForce
public.InitTables_Forces = InitTables_Forces
return public
