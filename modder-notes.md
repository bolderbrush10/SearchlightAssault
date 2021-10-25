## Current Task:


## Next Tasks:

- Uphold that promise about the multiplayer map from the mod description

- Prepare FAQ: explain potential mod incompatibility, workarounds, uninstall command, performance (only use ~1 - 2 thousand searchlights), etc


## Design Decisions & Discussion

- What if we just draw a searchlight effect ourselves and manually move & search around it every tick?

  This is extremely performance intensive, after a few dozen of these you noticably lose fps.
  It's vastly more efficient to have the game create an entity, shoot at it,
  and let the engine do pathfinding and rendering calls for us.
  (Even with all the rigmarole associated with maintaining that entity...)


- What if we used TargetMasks to protect turtles from being attacked,
  instead of giving them their own force?

  Unfortunately, capsule robots and other non-turret entities
  don't seem to respect the TargetMasks.


- What if we required players to connect their light with wire to the turrets they want it to affect?
  Connect searchlights to a beacon to have the light auto-boost in a radius?
  Have another version that takes a beacon as an ingredient to auto-boost?
  Have a version that takes a radar / rocket control unit for a really big boost?

  Imagine what the wube devs would do:
  There'd just be ONE version of a turret, and it'd be straightforward to use.


- Should we indicate the boostable radius / decorate terrain of boostable region?

  No longer necessary, decided to just boost adjacent turrets.
  It was very painful to try to figure out a way to get turret range and
  radius_visualization to coexist.


## Known Bugs:

- [Mitigated] Players right clicking to destroy a ghost searchlight can leave behind ghost signal-interfaces

- [Mitigated] It's possible to 'fake out' the turtle near the edge of the searchlight range
  and desync the searchlight from attacking its turtle or make the turtle "lock up"

- [Cheat Mode] Mass-deconstructing alarm-mode searchlights and boosted turrets at
  the same exact time causes the searchlights to re-boost turrets as they die,
  causing boosted versions of that turret to be spawned in and avoid being mass-deconstructed.

- Boosted turrets have trouble shooting at something if it has its force set every tick

- Two searchlights have trouble targeting each other at the same time
  (Probably because of raise / clear alarm "destroying" their targets)


## TODO's

### Feature: Professionalism Polish

- Collect more in-game screenshots and gifs for the mod portal page

- It would be good to create some professional diagrams and documents to explain the underlying strategies of the mod
- We'll want to make a header / word template featuring a logo for the mod and stuff

- Port this file into the bottom of the readme when complete

- Final sweep over README.md


### Bugs to Report / Mod Interface Features to Request

- [DONE] energy_glow_animation on turrets flickers badly, so that's probably a bug
         Dev responded and agreed to solve:
         https://forums.factorio.com/viewtopic.php?f=7&t=100260&p=554307#p554307

- OnPowerLost/Restored event mod interface request (So we don't have to check power manually in onTick)

- Write up how non-turrets just totally ignore trigger_type_mask
  And how it's seemingly-impossible to set up a blocklist for an entity that you don't want even-just-turrets to attack.

- 'on_save' event, or a way in general to make sure that uninstalling our mod will give people back their original turrets.
  (Alternatively, ask for the simple ability to increase turret range during run time)

- Report prefer_straight_paths = true as bug? Seems to do the opposite of what it says

- When editing an already-saved blueprint's contents by selecting a new area,
  the on_player_setup_blueprint event is fired,
  but the replacement contents don't show up in the player's blueprint or cursor blueprint stack
  (cursor_stack.is_blueprint is true, but is_blueprint_setup() is false,
   get_blueprint_entities() returns nothing, and get_blueprint_entity_count() is zero)
  Where it does show up is in the blueprint from the player's inventory,
  which means you have to iterate through the whole inventory
  and hope you can find the right blueprint,
  AND also deal with the problem of the blueprint being nested in a book...
  Related? https://forums.factorio.com/viewtopic.php?t=99845


### Map modes / play

- Create a 'jailbreak' game mode, where 1 - 8 players are wardens manually controlling searchlights,
  and ~100 other players are convicts.
  Convicts try to gather resources and escape, wardens unlock more searchlights as they recapture convicts
  (Captured convicts can play a minigame of some kind to re-escape from their cells)
  We'll figure out the win / lose conditions later.
  Maybe prisoners break into the warden's office and steal underpants or something.

- Figure out how to make night time even darker? Maybe render an overlay visible-only to the guard force?
  So, we discovered that making a map doesn't come with triggers and other dynamic things
  If we want to have an elaborate pvp prisonbreak scenario, we'll have to add it into the mod
  So, custom triggers and such aren't really a thing..
  Maybe just make it a maze with a "race to the rocket" kind of deal? Maybe two teams?
  We can still have areas where players need to gather the final few rocket ingredients
  Shortcuts where people can go to dunk in science packs and finish the steel axe technology
  Lots of Big Rocks in the way as a bottle neck
  Need to build landfill to get over moat
  etc

- I'm starting to think it'd be easier to just have the searchlights entirely under NPC control
  Maybe we'll start with that, then make a VS version later

- Maybe there's a part where players have to break through a wall, and this somehow triggers
  a wave of construction bots to add combinators / new searchlights

- When time runs out, an unstoppable wave of biters should surge and chase everyone down
  Maybe just make some offshore pollution machines to slowly ramp up their evolution lol
  And make an indestrucible one by the rocket

- There should be a rocket launcher and ammo you can craft to shoot searchlights / turrets
  (Just bear in mind, those same searchlights will also be helping fend off the biter swarms,
   costing you time if you destroy them)


### Advertising

- Submit mod to Xterminator, KatherineOfSky, other big modded factorio youtubers / names


## Stretch Goals

- Spawn metal & dirt particles when spawning / despawning control units

- Further crop the mask sprite, figure out the offset it needs

- Optimize file sizes better, maybe increase the file compression and see if it loads faster or slower

- Make a little 'dirt estucheon' for where wires reach into the ground

- Re-render everything with some kind of smudge / blur post-processing effect
  so it can blend in better with the base game

- water_reflection

- Searchlight color controlled by circuit signals

- 'Infrared mode' (target vehicles / player only) activated via circuit signal

- Searchlight could possibly be set to only wander a 180 degree arc around its inital placement?

- Don't show searchlights in the turret coverage map mode

- Detect playerRotatedEntity events and swing the turtle waypoint around 90 degrees each time the player rotates the SL itself.
  So, the playerRotatedEntity event doesn't fire for this. We'll have to add a custom input event and check if the player
  has a searchlight selected. Maybe play a little UI sound.

- Create more main-menu simulations
  (Unfortunately, control.lua doesn't work in main-menu simulations, so we have to work around that...)
    - We can probably chain the turtle to follow another turtle to give its tragetory more of a curve...
      Also probably want to vary up the grass a bit
    - Actually, it looks like we can do some real magic in menu-simulations.lua init,
      registering stuff to happen in on_nth_tick. "Chase" is a great example.
      Let's make use of that.
    - (Maybe even launch something at the turtle so the spotlight will "fire" when the turtle dies?)
    - Probably want a scene with a jail break that succeeds (tank that busts through wall, bunch of people on foot follow)
    - Probably want a scene with a jail break that fails (car crashes into wall, explodes, people spill out get caught)
    - There's probably a good few default ones that would suit being changed to night time and having
      some searchlights thrown into

- Shadow layer cleanup:
  I think I need to go into photoshop or blender and rig it so that any pixels from the base layer
  exclude pixels from the shadow layer

- Mod compatability setting feature: \nWildcard matching possible with asterisk *

- Look more into teleporting or somehow... hiding the entities we're replacing.
  It'd be nice to not have to spawn / destroy turrets all the time just because we're boosting them.
  Initial research doesn't look promising.

- Break apart into a 'boostable turrets' mod
  Let people use mod settings to control what level the boosting is
  How to handle recipes? Just a beacon to all the regular recipes, enable it with a unique range-boosting technology?
  Or just make a stand-alone version of the mod and a non-standalone version?
