## Current Task:

-- Sounds and audio

-- So, trying to get the scanner noise to stick with the actual unit there
   has been a challenge. Trying to use nested effects in the searchlight beam
   just results in the sound only being played once.
   So, using a 'working sound' seems ideal.
   Almost all entities, even beam itself! have a working sound.
   Unfortunately, the beam plays it's working sound at its center.

   Maybe we want to create a sticker effect and put it on the entity being scanned,
   and play a working sound from there?
   We'll have to figure out how to remove the sticker as targets are switched...
   So, stickers can't stick to buildings.. I guess that's not the biggest loss,
   but still a dissapointment

   Maybe we'll just assign the turtle to follow the target and keep its working sound on...
   The problem with that is the biter's pathfinding to follow entities really sucks.
   It'll follow whatever crazy path you take unless it can see you...
   I guess if we set its max speed to ~110% of the target's max speed though, it can't be too bad.
   Maybe we'll even try using prefer_straight_paths and see how that does

   Note that if we run out of power, and disable the turtle, we'll need to make sure that
   if it's been commanded to follow an entity, that it won't still want to chase that entity
   out of range when the power comes back on


-- TODO remember that we removed the 'warning' circuit signal

-- TODO Thinking about doing another big refactor
        I think what I want is to have more .lua files for each entity,
        and make an sl-gestalt to tie them together properly.
        control.lua should do all the work through that,
        instead of talking to sl-turtle and sl-searchlight individually
        We might wind up removing control-common, and I'm ok with that.
        This might also make it easier to make a gestalt array for each force
        and stuff like that.


-- TODO A working sound for the spotter?


## Next Tasks:

- There's still issues with distracted biters and circuit signals
- I think the biter's vision range is still too big, too

- In save test-20, if you make a searchlight target a searchlight, then deconstruct that searchlight,
  the script crashes inside TrackSpottedFoes (about to call ResumeTargetingTurtle)
  Probably because the foe with the foe position is no longer valid.
  (We should consider refactoring the whole logical layout of tracking foes)
- I'm pretty sure this is because onFoeDied doesn't get called when someone deconstructs their buildings.
  Should probably fix that. (Also note that radars will need to be checked for, too)

- Fix the click in sl-scan.ogg (probably just needs a fade-in & fade-out)

- Test vs other mods

- So, apparently, binding variables and even functions to local speeds them up.
- We should go through all of our code and make sure that anything which can be made local, is made local.
- DOUBLE CHECK for variables to make local inside of loops, etc

- Even binding next() increases performance, eg, local next = next
- So be sure to bind any functions called in repetitive places

- Prepare FAQ: explain potential mod incompatibility, workarounds, uninstall command, performance (only use ~1 - 2 thousand searchlights), etc

- Final sweep on other TODOs

- Uphold that promise about the multiplayer map from the mod description

- Use curves to deepen the lines on the sl-glow


## Design Decisions & Discussion

- What if we just draw a searchlight effect ourselves and manual move & search around it every tick?

  This is extremely performance intensive.
  It's vastly more efficient to have the game create an entity, shoot at it,
  and let the engine do pathfinding and rendering calls for us.


- What if we used TargetMasks to protect turtles from being attacked,
  instead of giving them their own force?

  Unfortunately, capsule robots and other non-turret entities
  don't seem to respect the TargetMasks.


- What if we required players to connect their light with wire to the turrets they want it to affect?
  Connect searchlights to a beacon to have the light auto-boost in a radius?
  Have another version that takes a beacon as an ingredient to auto-boost?
  Have a version that takes a radar / rocket control unit for a really big boost?

  Nah. Imagine what the wube devs would do.
  There'd just be ONE version of a turret, and it'd be straightforward to use.


- Indicate boostable radius / decorate terrain of boostable region?

  No longer necessary, decided to just boost adjacent turrets.
  It was very painful to try to figure out a way to get turret range and
  radius_visualization to coexist.


## Known Bugs:

- [Cheat Mode] Mass-deconstructing alarm-mode searchlights and boosted turrets at
  the same exact time causes the searchlights to re-boost turrets as they die,
  causing boosted versions of that turret to be spawned in and avoid being mass-deconstructed.

- Boosted turrets have trouble shooting at something if it has its force set every tick

- Changing mod settings from the main menu instead of during runtime doesn't really stick


## TODO's


### Testing

- Test multiplayer online, even if just against yourself

- Get people to play test the balance


### Feature: Mod Compatability

- Test compatibility for 'boosting' friendly turrets with something complicated like the water gun mod.

- Maybe instead of creating & destroying range-boosted versions of turrets,
  we can ask other mod authors if it's ok to teleport back and forth from a hidden surface layer?

- Maybe we SHOULD fire those script___created/destroyed events...

- Test against the most popular mods (bobs, angels, Rampant, sort by popular on the website)


### Feature: Professionalism Polish

- Collect more in-game screenshots and gifs for the mod portal page

- It would be good to create some professional diagrams and documents to explain the underlying strategies of the mod
- We'll want to make a header / word template featuring a logo for the mod and stuff

- Port this file into the bottom of the readme when complete

- Final sweep over README.md


### Bugs to Report / Mod Interface Features to Request

- Write up how non-turrets just totally ignore trigger_type_mask
- And how it's seemingly-impossible to set up a blocklist for an entity that you don't want even-just-turrets to attack.

- 'on_save' event, or a way in general to make sure that uninstalling our mod will give people back their original turrets.
- (Alternatively, ask for the simple ability to increase turret range during run time)

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

-- DONE energy_glow_animation on turrets flickers badly, so that's probably a bug
        Related? https://forums.factorio.com/viewtopic.php?p=421477
                 https://forums.factorio.com/viewtopic.php?p=522051
        Dev responded and agreed to solve:
        https://forums.factorio.com/viewtopic.php?f=7&t=100260&p=554307#p554307


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

- Make a little 'dirt estucheon' for where the wires reach the ground

- Maybe re-render everything with some kind of smudge / blur post-processing effect (transparent pixels locked, use obj data)

- water_reflection

- Searchlight color controlled by circuit signals

- 'Infrared mode' (target vehicles / player only) activated via circuit signal

- Searchlight could possibly be set to only wander a 180 degree arc around its inital placement?

- Detect playerRotatedEntity events and swing the turtle waypoint around 90 degrees each time the player rotates the SL itself
  So, the playerRotatedEntity event doesn't fire for this. We'll have to add a custom input event and check if the player
  has a searchlight selected, I guess. Maybe play a little UI sound.

- Create more main-menu simulations
  (Unfortunately, control.lua doesn't work in main-menu simulations, so we have to work around that...)
    - Probably want a scene with a jail break that succeeds (tank that busts through wall, bunch of people on foot follow)
    - Probably want a scene with a jail break that fails (car crashes into wall, explodes, people spill out get caught)
    - There's probably a good few default ones that would suit being changed to night time and having
      some searchlights thrown into

- Mod compatability setting feature: \nWildcard matching possible with asterisk *

- Think about teleporting or somehow... hiding the entities we're replacing.
  It'd be nice to not have to spawn / destroy turrets all the time just because we're boosting them.

- Break apart into a 'boostable turrets' mod
  Let people use mod settings to control what level the boosting is
  How to handle recipes? Just a beacon to all the regular recipes, enable it with a unique range-boosting technology?
  Or just make a stand-alone version of the mod and a non-standalone version?


## Performance reports:

A
```
Huge performance problem with ~100 searchlights, even if there are no turtles spawned

Presently losing 10 ups at 150 searchlights. Best results when you pace out how slowly you spawn them.
Made a save file in the game to test performace with 150, and a commit here in git.

Tried doing a version of searchlights no find_entity calls, still dropped 5 ups around 180 searchlights.
Doing literally 2000 just entites (no lights) had no performance impact, so there's some real questions to be had.

Maybe experimenting with only running checks every n ticks is worthwhile?

!! Maybe what we need to do is divide the world up into grids, group up all the turrets in a grid location,
   then just search the 9 tiles for that turret gride for stuff to consider before we focus on an individual turret.
```

B
```
Just got the framework rewrite in place to give turtles an attack to let us spot foes and it's looking great.

Only start to notice a drop of about 5fps once we hit ~5k searchlights.

We still need to put in a lot more logic to handle what to do when the foe is actually spotted, and to retask-turtles after they reach initial waypoints, but I'm very happy.
```

C
```
Done with the full enemy detection & retasking logic rework.
At 4.5k searchlights, we're seeing an average of 36 fps (while running youtube and a bunch of other background processes)
No drop noticable until almost 3k searchlights deep.
Seems pretty good to me.
```
