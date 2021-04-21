require "control-common"


-- The idea here is to create two special forces.
-- The 'foe' force exists to create an imaginary target (The 'Turtle') for the spotlights to 'shoot at' while they scan around for enemy units.
-- But we don't want the player's normal turrets to shoot at that imaginary target...
-- ...So we make a 'friend' force, which we'll assign to spotlights while they shoot at the turtle.
function InitForces()

  game.create_force(searchlightFoe)
  game.create_force(searchlightFriend)

  for F in pairs(game.forces) do
    SetCeaseFires(F)
  end

  game.forces[searchlightFriend].set_friend("player", true) -- TODO Is this appropriate in multiplayer?
  game.forces[searchlightFriend].set_cease_fire(searchlightFoe, false)
  game.forces[searchlightFoe].set_cease_fire("enemy", false)

end


function SetCeaseFires(F)

  game.forces[searchlightFoe].set_cease_fire(F, true)
  game.forces[searchlightFriend].set_cease_fire(F, true)

  game.forces[F].set_cease_fire(searchlightFoe, true)
  game.forces[F].set_cease_fire(searchlightFriend, true)

end
