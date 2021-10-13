## Current Task:



## Next Tasks:

- Test multiplayer online

- Make a config option to take in the names of turrets that players DON'T
  want the searchlights to boost, so they can fix mod incompatibility issues themselves

- Mod ourselves into a couple of main-menu screens
    - Probably want a scene with several SLs getting built by robot, which enables turrets to attack a far biter base
    - Probably want a scene with a jail break that succeeds (tank that busts through wall, bunch of people on foot follow)
    - Probably want a scene with a jail break that fails (car crashes into wall, explodes, people spill out get caught)

- Move "A neat trick to see if a string ends with a given suffix" somewhere common

- Spotlight emits detection info to circuit network

- Uphold that promise about the multiplayer map from the mod description


## Known Bugs:

- [Cheat Mode] Mass-deconstructing alarm-mode spotlights and boosted turrets at
  the same exact time causes the spotlights to re-boost turrets as they die,
  causing duplicates of that turret to be spawned in and avoid being mass-deconstructed.

## Design Decisions & Discussion

- Maybe require players to connect their light with wire to the turrets they want it to affect?
  Connect it to a beacon to have the light auto-boost in a radius?
  Have another version that takes a beacon as an ingredient to auto-boost?
  Have a version that takes a radar for a really big boost?

  Nah. Imagine what the wube devs would do.
  There'd just be ONE version of a turret, and it'd be straightforward to use.


- Indicate / Decorate Boostable Radius / Terrain?

  No longer necessary, decided to just boost adjacent turrets


## TODO's



### Feature: Rotate searchlight to rotate turtle waypoint

- Detect playerRotatedEntity events and swing the turtle waypoint around 90 degrees each time the player rotates the SL itself
  So, the playerRotatedEntity event doesn't fire for this. We'll have to add a custom input event and check if the player
  has a searchlight selected, I guess. Maybe play a little UI sound.

- Spotlight could possibly be set to only wander a 180 degree arc around its inital placement?



### Feature: Sounds & Audio

-- TODO Sounds and audio
https://wiki.factorio.com/Prototype/Entity#working_sound

- Maybe we want kind of an audible hum, like a bass-boosted flouresent light...
- And some quiet background morse-code kinda sounds...
- prototype: turtle.walking_sound to an electric hum / sizzle ?
- attack_parameters.CyclicSound: Metal-Gear-Solid style "Alert noise" for turtle ?
- attack_parameters.CyclicSound: Alarm klaxon for Alarm Mode searchlight ?


### Testing

-- TODO Get people to play test the balance

-- TODO Test blueprints construction / mass deconstruction


### Feature: Mod Compatability

-- TODO Test compatibility for 'boosting' friendly turrets with something complicated like the water gun mod.

-- TODO Maybe instead of creating & destroying range-boosted versions of turrets,
        we can ask other mod authors if it's ok to teleport back and forth from a hidden surface layer?

-- TODO Maybe we SHOULD fire those script___created/destroyed events...

-- TODO Test against the most popular mods (bobs, angels, sort by popular on the website)


### Feature: Graphics Polish

-- TODO add onhit particle effects (for when the searchlight is damaged so little chunks fly off)

-- TODO Spawn metal & dirt particles when spawning / despawning control units

-- TODO Leave remnants when destroyed (doesn't even have to be custom, pick another entity's if you must)

-- TODO Test non-high resolution graphics

-- TODO Optimize file sizes better, maybe increase the file compression and see if it loads faster or slower


### Feature: Professionalism Polish

-- TODO Collect more in-game screenshots and gifs for the mod portal page

-- TODO clean up unused junk across all files

-- TODO So, apparently, binding variables and functions to local speeds them up.
--      We should go through all of our code and make sure that anything which can be made local, is made local.
--      DOUBLE CHECK for variables to make local inside of loops, etc

-- TODO Even binding next() increases performance, eg, local next = next
--      So be sure to bind any functions called in repetitive places

-- TODO Final sweep over README.md

-- TODO It would be good to create some professional diagrams and documents to explain the underlying strategies of the mod
--      We'll want to make a header / word template featuring a logo for the mod and stuff

-- TODO Port this file into the bottom of the readme when complete


### Feature: Mod-Uninstall Command

-- TODO should probably un-boost all turrets when a game is being saved, just in case they uninstall the mod. We can make the searchlights disappear, but it's probably unfair to also remove other random turrets.
--      So, there's not really a way to tell when this happens. And it doesn't look like the migration files will help either.
--      I think the best thing we can do is add a function that the player can call via command that 'disables' the mod so they can save & uninstall
--      And then we'll make a FAQ / User Manual to explain that if they don't want to risk random turrets disappearing, here's the steps they need to follow
--      Don't forget to update the mod description and readme to mention the uninstall command


### Bugs to Report / Features to Request

-- TODO Write a bug report against the usage of trigger_type_mask and how non-turrets just totally ignore it.
--      And how it's seemingly-impossible to set up a blacklist for an entity that you don't want even-just-turrets to attack.

-- TODO Ask a developer on the forums for an 'on_save' event, or for a way in general to make sure that uninstalling our mod will give people back their original turrets.
--      (Alternatively, ask for the simple ability to increase turret range during run time)

-- TODO Report prefer_straight_paths = true as bug? Seems to do the opposite of what it says

-- TODO energy_glow_animation on turrets flickers badly, but not when you use draw_as_light, so that's probably a bug
        Related? https://forums.factorio.com/viewtopic.php?p=421477
                 https://forums.factorio.com/viewtopic.php?p=522051

-- TODO When editing an already-saved blueprint's contents by selecting a new area,
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

-- TODO Create a 'jailbreak' game mode, where 1 - 8 players are wardens manually controlling spotlights,
--      and ~100 other players are convicts.
--      Convicts try to gather resources and escape, wardens unlock more spotlights as they recapture convicts
--      (Captured convicts can play a minigame of some kind to re-escape from their cells)
--      We'll figure out the win / lose conditions later.
--      Maybe prisoners break into the warden's office and steal underpants or something.

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

- There should be a rocket launcher and ammo you can craft to shoot spotlights / turrets
  (Just bear in mind, those same spotlights will also be helping fend off the biter swarms,
   costing you time if you destroy them)


### Advertising

-- TODO Submit mod to Xterminator, KatherineOfSky, other big modded factorio youtubers / names


## STRETCH GOALS

- Spotlight color controlled by circuit signals

- Activate 'infrared mode' (target vehicles / player only) by sending a signal

- Think about teleporting or somehow... hiding the entities we're replacing.
  It'd be nice to not have to spawn / destroy turrets all the time just because we're boosting them.

- Can we possibly fix copy/paste/pipette on boosted turrets?

- Further crop the mask sprite, figure out the offset it needs

- Maybe create a little dirt-throw effect when the control unit spawns / despawns?

- Maybe re-render everything with some kind of smudge / blur post-processing effect (transparent pixels locked, use obj data)

- Make a little 'dirt estucheon' for where the wires reach the ground

-- TODO Break apart into a 'boostable turrets' mod
        Let people use mod settings to control what level the boosting is
        How to handle recipes? Just a beacon to all the regular recipes, enable it with a unique range-boosting technology?
        Or just make a stand-alone version of the mod and a non-standalone version?


### STRETCH Feature: Traincar

-- TODO Make a train wagon type with 2-4 searchlights mounted on it
-- TODO Turret train -- put on a turret and let it wheel away
        (Did no one make this already?)
        This whole idea should probably be a whole different mod...


## Performance reports:

A
```
Huge performance problem with ~100 spotlights, even if there are no turtles spawned

Presently losing 10 ups at 150 spotlights. Best results when you pace out how slowly you spawn them.
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
