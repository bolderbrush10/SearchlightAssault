Current dillema:
0) On top of all this is the problem of how to have the spotlight shoot at a turtle which regular turrets ignore...
A) Do we make turrets out of two entities and swap between them like we currently do?
B) Or can we have the two entities exist at the same time to simplify things?
 -- Is there a way to disable an entity?
 -- Sort of; entity.active :: boolean [Read-Write] Deactivating an entity will stop all its operations (car will stop moving, inserters will stop working, etc).
 -- Entities still show their range (desired)
 -- But entities stop consuming electricity (undesired)
 -- Entities show an icon on their info panel stated 'disabled by script' (undesired)
 -- Entities cannot be destroyed, just set to 0hp (undesired)
C) Can we make a turret use multiple attack types so we can swap searchlight colors in real time?
   (like how tanks have different attacks)
-- entity.selected_gun_index :: uint [RW]  Index of the currently selected weapon slot of this character, car, or spidertron, or nil if the car/spidertron doesn't have guns.
-- Maybe that means I would have to make the hidden searchlight entity a car? I guess that's ok lol
D) Rework the graphics to support the searchlight being effectively made of two entities?
-- There could be a short-range "radar beacon" piece in the middle that autodetects close foes and the longer-range searchlight on top of it
-- I don't know if I like that idea... Wouldn't we want the non-dummy entity to still actually attack at that long range?
E) We drop the whole 'two entites' thing entirely and just have one fully-script controlled turret
F) Stop automatically detecting close-range foes. Isn't the whole point of 'sneaking past searchlights' supposed to be a thing you can do under the guard's nose?

Sadly, alert_when_attacking is a part of the turret entity prototype, read-only at runtime, and not part of the attack itself.
I think we can get away with just making alerts a circuit network output...

G) Still two entities, but no swapping between them and only the hidden entity does any work.
I think we still want the structure of the turret to belong to the player force.. Maybe we have it spawn a hidden entity that does all the actual attacking?
The hidden entity can inherit the messy forces, and the "real" turret does nothing but suck up electricity.


Crash testing:
Action at time:
Made a TON of searchlights, some near a biter nest.
A bunch of biters swarmed, and some worms were spitting at the lights.


Did it again.
Action at time:

Just made like 50 searchlights really close together really quickly.



Strings which would be first-class types in a real programming language:

"small-searchlight"
etc


-- Important example
C:\Program Files (x86)\Steam\steamapps\common\Factorio\data\base\graphics\entity\laser-turret


-- Patch notes to consider:

  https://forums.factorio.com/viewtopic.php?f=3&t=91657

  New item flag "spawnable", every item has to have that flag to be creatable through the shortcuts directly.

  Added direction to SimpleEntityWithOwner and SimpleEntityWithForce.

  Renamed on_put_item to on_pre_build, as it is much more precise name for that event. It fires when anything is used for building: item, blueprint, blueprint record or ghost cursor.

  Added LuaEntity::can_wires_reach().


-- Important search function:
  find_units{area=…, force=…, condition=…} → array of LuaEntity

  Find units (entities with type "unit") of a given force and force condition within a given area.

  Parameters
  Table with the following fields:

      area :: BoundingBox: Box to find units within.
      force :: LuaForce or string: Force performing the search.
      condition :: ForceCondition: Only forces which meet the condition will be included in the search.

  Note: This is more efficient than LuaSurface::find_entities.
  Example
  Find friendly units to "player" force
  local friendly_units = game.player.surface.find_units({area = {{-10, -10},{10, 10}}, force = "player", condition = "friend")
  Example
  Find units of "player" force
  local units = game.player.surface.find_units({area = {{-10, -10},{10, 10}}, force = "player", condition = "same"})


-- TODO huge performance problem with ~100 spotlights, even if there are no turtles spawned
        Presently losing 10 ups at 150 spotlights. Best results when you pace out how slowly you spawn them.
        Made a save file in the game to test performace with 150, and a commit here in git.

        Tried doing a version of searchlights no find_entity calls, still dropped 5 ups around 180 searchlights.
        Doing literally 2000 just entites (no lights) had no performance impact, so there's some real questions to be had.

        Maybe experimenting with only running checks every n ticks is worthwhile?


        !! Maybe what we need to do is divide the world up into grids, group up all the turrets in a grid location,
           then just search the 9 tiles for that turret gride for stuff to consider before we focus on an individual turret.


-- TODO okay so we have to think about the range boost effect and the fact that turrets we boost are further than 0 pixels away from the searchlight... Just because we boost a turret's range doesn't mean it can now reach whatever the searchlight is targeting.. So maybe we need to make sure that 'amount of range boost = searchlightRange + boostradius'?
-- TODO We also could use some thinking about how to make sure that turrets don't get to keep that range-boost and target things that no searchlight has spotted yet


-- TODO Sounds and audio
https://wiki.factorio.com/Prototype/Entity#working_sound

-- TODO So the shooting_target [rw] thing didn't work out but apparently you can use
update_selected_entity(position)
-- and
entity.shooting_state = {
   state = defines.shooting.shooting_enemies,
   position = position
}
-- or something like that

-- TODO what the hell happened to my spotlight rendering? I think the patch misaligned some of my layers. There's some errors being reported in
C:\Users\Terci\AppData\Roaming\Factorio>factorio-current.log

-- TODO Use the new decorations thing to spawn in crap around the boostable radius
-- spawn_decorations() Triggers spawn_decoration actions defined in the entity prototype or does nothing if entity is not "turret" or "unit-spawner".


-- TODO What if instead of having a "range" as turrets do, we create a custom "spotting range" property and then make our own graphics.draw() calls to highlight the radius of the spotlight on mouseover / item in hand / on map? (This could be useful for showing ranges of boostable friends, too. (And we could use the terrain decoration to show that after construction))

-- TODO dead dummy seeking searchlights need to leave ghosts for real searchlights
-- TODO also need to handle construction ghosts for boosted turrets, etc

-- TODO Attach some kind of neat little graphical sticker to turrets that are in boosting range


-- TODO delay un-boosting boosted turrets until they finish their folding animation
--      (but also somehow prevent them from using their expanded range in the meanwhile)


-- TODO 2-4 second "yellow light" period to allow units to hide from the spotlight before they're fully spotted


-- TODO energy cost
-- TODO make use of new feature from patch notes: - Added optional lamp prototype property "always_on".

-- TODO gun turrets should get a much smaller boost than electric, and fluid turrets even less so
-- TODO radar integration

-- TODO should probably un-boost all turrets when a game is being saved, just in case they uninstall the mod. We can make the searchlights disappear, but it's probably unfair to also remove other random turrets.

-- TODO Update recipe for searchlight


-- TODO Are the on_event filters faster if we just filter on names instead of looking at things by type as well?


-- TODO Maybe instead of the boost animation thing, we create a small 'link box' entity on boosted turrets.
--      When the spotlight is boosting / controlling the turret, it can play a little laser light animation on the turret's link box and also the spotlight's link box thing

-- TODO make the spotlight effect a 'heat shimmer' animation, so it looks awesome during the day

-- TODO Get people to play test the balance

-- TODO Dynamic power cost for searchlight that increases exponentially per boosted turret?
--      (Don't forget to mention this in the item description texts)

-- So, obviously the balance of this mod is always going to be whack. Any meaningful amount of +Range is ridiculously powerful, no matter where we put it in the tech tree.
-- Perhaps, in addition to costing more power the more turrets a light boots, we can create an event to trigger an attack when a biter gets spotted?
-- (Maybe we can have a 'flash' go off when turrets energize / deenergize to hide the stuttering attack that happens when turrets are being swapped in and out?)
-- Maybe have two different 'ranges' of boost? Such that it can boost 1 turret out to X meters, and then all the rest to X - Z meters?

-- Maybe require players to connect their light with wire to the turrets they want it to affect?
-- Connect it to a beacon to have the light auto-boost in a radius?
-- Have another version that takes a beacon as an ingredient to auto-boost?
-- Have a version that takes a radar for a really big boost?
-- Nah. Honestly, imagine what the actual game devs would do. There'd just be ONE version of a turret. So don't be like this.



-- TODO add a layer of animated glowing lines to boosted turrets?
-- TODO Recipe should probably require something power related (an accumulator?) regardless of if we with the seperate-recipe using a beacon idea


-- TODO Can we copy current animation frame when boosting?

-- TODO Maintain a map of all searchlights instead of polling for them every tick
-- (And update it w/ onEvent(building built, etc) + rebuild it on startup or use engine to save/load it)

-- TODO preserve mining progress somehow when things are boosted unboosted

-- TODO when a spot light dies, make sure to unboost all nearby friends

-- TODO Are there non-energy, non-ammo, non-fluid type turrets? Should we try to fix this mod for them?

-- TODO When a spotlight spots a foe, there's a moment where there's no light at all.
--      Maybe we could manually render some kind of 'alert flash' at the enemy location while the transition is happening

-- Might want to figure out how to use the 'alert_when_attacking' characteristic such that we alert when real foes are present, and not imaginary ones
-- also look into:
--  allow_turning_when_starting_attack
--  attack_from_start_frame

-- TODO can probably make smarter use of forces throughout control.lua

-- TODO Need to make a ghost for the searchlight.
--      And also double check that everything works properly with construction robots in the on_event functions.
--      Right now, if a real searchlight is destroyed, it puts up a ghost. But not the dummy light. And a bunch of other issues.


-- TODO Make use of graphics_variation for whatever effect we do use for the searchlight boost


-- TODO enemies are stutter-stepping toward the turrets
--      (because the turrets keep getting destroyed and created by control.lua)
--      fix this
--      (possibly by having a time out between boosting and unboosting turrets
--       and swapping between the real and dummy spotlights)

function makeLightStartLocation(sl)
    -- TODO get the orientation of the light and stick this slightly in front
    --      also figure out how to deal with the unfolding animation


-- TODO spawn turtle in general direction turret is pointing at


-- TODO clean up unused crap across all files

-- TODO Double check to make sure that the boost turret turrets are only boosting turrets of the same force

-- TODO deconstruction planner doesn't affect dummy turrets, but it should

-- TODO check if it's more efficent to just filter by one category (name?) than by type then name, etc


-- TODO Make the searchlight effect during the daytime a heat haze glimmer kinda thing


-- TODO Use the on_nth_tick(tick, f) to handle timer checking at a more reasonable, albiet less accurate rate (like, for checking if we should unboost turrets)

on_nth_tick(tick, f)

Register a handler to run every nth tick(s). When the game is on tick 0 it will trigger all registered handlers.

Parameters
tick :: uint or array of uint: The nth-tick(s) to invoke the handler on. Passing nil as the only parameter will unregister all nth-tick handlers.
f :: function(NthTickEvent): The handler to run. Passing nil will unregister the handler for the provided ticks.

-- TODO ask on forums about saving / loading events, so we can restore turrets on save, recalculate unimportant tables on load, etc


-- TODO Break apart into a 'boostable turrets' mod
        Let people use mod settings to control what level the boosting is
-- TODO How to handle recipes? Just a beacon to all the regular recipes, enable it with a unique range-boosting technology?
-- TODO Or just make a stand-alone version of the mod and a non-standalone version?


-- TODO Organize control.lua into a couple more files (like, boostrange.lua), etc


-- TODO Ask a devleoper on the forums for an 'on_save' event, or for a way in general to make sure that uninstalling our mod will give people back their original turrets.


-- TODO disable when no electricity / reduce range according to electric satisfaction

-- Possibly can use this attack type to do cool stuff?
-- https://wiki.factorio.com/Types/TriggerDelivery#target_effects
-- https://wiki.factorio.com/Types/ScriptTriggerEffectItem

-- STRETCH GOALS
-- Spotlight position & color controlled by circuit signals
-- Spotlight emits detection info to circuit network
-- Spotlight could possibly be set to only wander a 180degree arc around its inital placement?
-- Use the 'TriggerEffect' prototype to play an alert sound if an enemy is detected? Looks like we can set it to play the sound at the 'source' aka the turret itself
    -- We can also create a sticker or particle, which could be fun for making "!" float above the turret's head or something.
    -- (Or Maybe cool flares could shoot out and form a '!'?)



=================

Feature request for spotlights that track enemies



Or just write a mod to do it, yourself

- Steal code from this other mod? [MOD 0.10.x] Advanced Illumination - 0.2.0 [BETA]
  https://forums.factorio.com/viewtopic.php?f=14&t=4872


Features:

- Alternate idea: Has a massive sight range, and a moderate effect range.
  Allows all turrets within effect range to fire at 1/8th fire rate (like, once per second) at anything within its sight range.

- Changes from white -> yellow -> infrared as it spots an enemy and 'locks on'
  (Be sure to have a cool 'lock on effect' when this finally happens)

- Half the range of the radar's 'discovery' range
  (or like, 2x as far as the active sight range)

- Gives radar-like map "remote vision" on targeted area

- Very high power cost
  (Maybe like 10x solar panels' worth per?
   Then again, we want to be an early-game alternative for night vision goggles...)

- Pretty large - maybe should appear to be on a tower light the large electric pole?

- Multiple spotlights prefer to target different enemies

- Checkbox to allow 'patrol mode' pattern when no enemies in range are known
  (Recreate your favorite prison-break movie / game! Like WindWaker!)

- Infrared-seeking mode that only targets players & vehicles
  (Implies that biters are endothermic, which is neat)

- Built from 5x lamp + 1x Radar (since it's able to target things)
  - Finally gives an incentive to automate lamp production for non-peaceful players

