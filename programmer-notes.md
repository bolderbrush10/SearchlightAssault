## Current Task:


## Next Tasks:

- Should we plan to create & pop up our own custom gui for circuit conditions?
- What kind of entity has good circuit conditions we can steal / how to rig the connections
  - Maybe we'll need to create hidden constant-combinators / deciders and dynamically set their output in on_tick...
  - (Or maybe we don't even hide the combinators, that could be cool if they were "exposed".
     Their sprites could still just be a part of the base-searchlight's sprite)
- Should we look up if there's an event for when the player modifies a gui to read X/Y, and only read from the SL combinator then?
  (nb, we'd have to figure out how to track copy-pasted / ghost entities)

- Outputting a signal has no effect until the signal box is hooked up to a electric pole or something...
- It seems like removing a circuit connection with the signal, doesn't revert from manual mode to wander mode,
  nor does clearing an outputted signal...

- We speed up the turtle when manually moving the searchlight...
  So, we should probably make sure it gets slowed back down when it gets distracted,
  or when the manual move is complete

- Use Prototype/CustomInput and make a GUI panel option to allow taking direct control of the spotlight
  Pop up a window that shows the spotlight beam's area

- Fix blueprinting / ghosts for boosted turrets & searchlight & any control interfaces

- Test multiplayer online

- On force changed for individual entities doesn't work.. is that a problem?

- Make a kickass prison escape game mode
  Figure out how to make night time even darker? Maybe render an overlay visible-only to the guard force?
  So, we discovered that making a map doesn't come with triggers and other dynamic things
  If we want to have an elaborate pvp prisonbreak scenario, we'll have to add it into the mod
  So, custom triggers and such aren't really a thing..
  Maybe just make it a maze with a "race to the rocket" kind of deal? Maybe two teams?
  We can still have areas where players need to gather the final few rocket ingredients
  Shortcuts where people can go to dunk in science packs and finish the steel axe technology
  Lots of Big Rocks in the way as a bottle neck
  Need to build landfill to get over moat
  etc

- Make a config option to take in the names of turrets that players DON'T
  want the searchlights to boost, so they can fix mod incompatibility issues themselves

- Clean up data-updates.lua

- Animate a laser-like beam of light going from the spotlight base to the control unit.
  And/or an electrical pulse from the wires at the bottom of the searchlight that echos up the control units?

- Maybe create a little dirt-throw effect when the control unit spawns / despawns?


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


## Known Bugs:

The 'wiggle bug' where a turtle gets stuck inside a larger entity still happens occasionally.
Not sure how to prevent this...
I think the best we can do is detect when a turtle finishes a command via distraction,
and then we manually check for foes within its spot-radius and retarget the attacklight if appropriate.

Sometimes, very rarely, the searchlight will target something random in range while
the turtle is being despawned / respawned. Maybe we should disable / enable it right after its foe dies?


## Misc Notes

/c game.player.surface.daytime = 0
/c game.player.surface.daytime = 0.5

/c game.player.create_character()

- Important example
C:\Program Files (x86)\Steam\steamapps\common\Factorio\data\base\graphics\entity\laser-turret


--[[
Types/RenderLayer

The render layer specifies the order of the sprite when rendering, most of the objects have it hardcoded in the source, but some are configurable.

The value is specified as Types/string

The order of acceptable values from lowest to highest:

    lower-radius-visualization
    radius-visualization
    lower-object
    lower-object-above-shadow
    object
    higher-object-under
    higher-object-above
    projectile
    air-object
    light-effect
--]]


## Design Decisions & Discussion

-- So, obviously the balance of this mod is always going to be whack. Any meaningful amount of +Range is ridiculously powerful, no matter where we put it in the tech tree.
-- Perhaps, in addition to costing more power the more turrets a light boots, we can create an event to trigger an attack when a biter gets spotted?
-- (entity.consumption_modifier is for Car types only...)
-- (Maybe we can have a 'flash' go off when turrets energize / deenergize to hide the stuttering attack that happens when turrets are being swapped in and out?)
-- Maybe have two different 'ranges' of boost? Such that it can boost 1 turret out to X meters, and then all the rest to X - Z meters?

-- Maybe require players to connect their light with wire to the turrets they want it to affect?
-- Connect it to a beacon to have the light auto-boost in a radius?
-- Have another version that takes a beacon as an ingredient to auto-boost?
-- Have a version that takes a radar for a really big boost?
-- Nah. Honestly, imagine what the actual game devs would do. There'd just be ONE version of a turret. So don't be like this.


## TODO's


### Priority Fix: Visuals & Sprite Errors

-- TODO what the heck happened to my spotlight rendering? I think the patch misaligned some of my layers. There's some errors being reported in
C:\Users\Terci\AppData\Roaming\Factorio>factorio-current.log


### Feature: Range Boosting
-- TODO okay so we have to think about the range boost effect and the fact that turrets we boost are further than 0 pixels away from the searchlight... Just because we boost a turret's range doesn't mean it can now reach whatever the searchlight is targeting.. So maybe we need to make sure that 'amount of range boost = d.searchlightRange + boostradius'?

-- TODO preserve mining progress somehow when things are boosted / unboosted

-- TODO Are there non-energy, non-ammo, non-fluid type turrets? Should we try to fix this mod for them?


### Feature: More complicated range boosting

-- TODO Make range-boosting require users to hook up wires to the turrets that are in range
--      (Not sure if this is actually fun or not.. It'd also be hard to make a tutorial for,
--       I'm not sure if we really want one more thing to have to explain to the player...)

-- TODO Dynamic power cost for searchlight / turrets that increases exponentially per boosted turret?
--      (Don't forget to mention this in the item description texts)

-- TODO We should drastically reduce the fire rate of boosted turrets while firing on foes outside their original range
--      Or maybe only boost one turret per searchlight (Maybe a repeatable tech can boost the count of boostables per SL up to like 20?)
--      Or maybe put turrets on a cooldown after switching shooting target?


### Feature: More features in circuit network interface

-- Activate 'infrared mode' (target vehicles / player only) by sending a signal?

-- etc


### Feature: Decorate Boostable Radius / Terrain

-- TODO add a layer of animated glowing lines to boosted turrets?
-- TODO Attach some kind of neat little graphical sticker to turrets that are in boosting range

-- TODO Some kind of low-key graphical animation over boosted turrets

-- TODO Maybe instead of the boost animation thing, we create a small 'link box' entity on boosted turrets.
--      When the spotlight is boosting / controlling the turret, it can play a little laser light animation on the turret's link box and also the spotlight's link box thing

-- TODO When mousing over a turret that's boostable by a searchlight, it should highlight all the nearby searchlights
--      (Like how the game highlights powerpoles for the entities that draw power from them)


## Feature: Change spotlight colors when foes are spotted

-- TODO When a spotlight spots a foe, there's a moment where there's no light at all.
--      Maybe we could manually render some kind of 'alert flash' at the enemy location while the transition is happening

-- TODO 2-4 second "yellow light" period to allow units to hide from the spotlight before they're fully spotted


### Feature: Circuit Network Integration
-- TODO Ok, so let's think about the turtle + circuit-programmable spotlight targeting.
--      Using move-to commands is problematic because there's only a particular radius the turtle will settle for.
--      We could teleport the turtle around but that's probably not very smooth...
--      Should we wait until the mod is in a better shape before we worry about this?
--      Or should we start thinking about using something besides a hidden biter as the turtle?
--      We could make some branches to test the difference with a biter-turtle vs manually caculating interpolated target-positions...
--      Well, we're not going to let the circuit network swing the spotlight around to new positions instantly, are we?
--      So, I think that maybe we'll have the circuit network set a destination for the turtle, and people will have to have the expectation that they don't get pixel-perfect control of the turtle, and that'll be fine.

-- TODO When we're recieving coordinates from the circuit network, remember to disable turtle wandering.


### Feature: Rotate searchlight to rotate turtle waypoint

-- TODO Detect playerRotatedEntity events and swing the turtle waypoint around 90 degrees each time the player rotates the SL itself


### Feature: Traincar

-- TODO Make a train wagon type with 2-4 searchlights mounted on it
-- TODO Turret train -- put on a turret and let it wheel away
        (Did no one make this already?)
        This whole idea should probably be a whole different mod...


### Feature: Sounds & Audio

-- TODO Sounds and audio
https://wiki.factorio.com/Prototype/Entity#working_sound

- Maybe we want kind of an audible hum, like a bass-boosted flouresent light...
- And some quiet background morse-code kinda sounds...
- prototype: turtle.walking_sound to an electric hum / sizzle ?
- attack_parameters.CyclicSound: Metal-Gear-Solid style "Alert noise" for turtle ?
- attack_parameters.CyclicSound: Alarm klaxon for Alarm Mode searchlight ?


### Feature: Radar Integration

-- TODO radar integration at point-of-light


### Feature: Mod Compatability

-- TODO Maybe instead of creating & destroying range-boosted versions of turrets,
        we can ask other mod authors if it's ok to teleport back and forth from a hidden surface layer?

-- TODO Maybe we SHOULD fire those script___created/destroyed events...

-- TODO Test against the most popular mods


### Feature: Graphics Polish

-- TODO Can we copy current animation frame when boosting?

-- TODO make use of new feature from patch notes: - Added optional lamp prototype property "always_on".

-- TODO make the spotlight effect a 'heat shimmer' animation, so it looks awesome during the day

-- TODO maybe do a subtle shaft of light effect as a beam 'attack'?

-- TODO mipmaps for the searchlight item & technology icons

-- TODO Make use of graphics_variation for whatever effect we do use for the searchlight boost

-- TODO figure out how to get the attack-glow animation to stop when attackLight.active = false

-- TODO use integration_patch when we're tidying up the graphics

-- TODO would be cool if the spotlight just flickered while it was disabled and still had low power

-- TODO add onhit particle effects (for when the searchlight is damaged so little chunks fly off)

-- TODO Break up sprite into mask layer (team colors), glow layer, and base (to save on memory)

-- TODO Get the emissions layer rendered from blender to include reflections

-- TODO Draw a little glow around the base of the searchlight, like a lamp

-- TODO Test non-high resolution graphics

-- TODO Optimize file sizes better, maybe increase the file compression and see if it loads faster or slower

-- TODO Remnants

### Feature: Professionalism Polish

-- TODO clean up unused junk across all files

-- TODO So, apparently, binding variables and functions to local speeds them up.
--      We should go through all of our code and make sure that anything which can be made local, is made local.
--      DOUBLE CHECK for variables to make local inside of loops, etc

-- TODO Final sweep over README.md

```
For maximum efficiency you'll want to bind next to a local variable, e.g.,

...
local next = next
...
... if next(...) ...


    Good point on the technical correctness; in the particular cases I've been utilizing the original code, false wouldn't be an expected key so the if not worked fine, but I'll probably make a habit of comparing to nil instead in the future, just as a good habit. And yes, I've been binding common utility functions to local vars for speed. Thanks for the input though. – Amber Aug 10 '09 at 1:41

    I find it hard to agree with wrongness when the code works as intended – R.D. Alkire Sep 11 '16 at 16:26

    Why do we gain speed by doing local next? – Moberg Oct 2 '16 at 20:22

    @Moberg This is due to how LUA handles its namespace. The very dumbed down version, is it will first climb up the local tables, so if there is a local next in the current block, it will use that, then climb up to the next block, and repeat. Once out of locals, it will only then use the Global Namespace. This is a dumbed down version of it, but in the end, it definitely means the difference in regards to program speed. – ATaco Nov 29 '16 at 4:45

    @Moberg at run time a global variable requires a hash-table lookup but a local variable requires only an array lookup. – Norman Ramsey Jan 28 '18 at 19:30
```

-- TODO Add emojis / icons to the mod name (Look at how the water gun mod makes them show up in game on the infopanel)

-- TODO It would be good to create some professional diagrams and documents to explain the underlying strategies of the mod
--      We'll want to make a header / word template featuring a logo for the mod and stuff

-- TODO Mod portal page's description should mention our motivations and intended gameplay effects.
--      We can mention that the searchlight is intended to 'solve' the turret-creep strategy for early/mid-game expansion.
--      We can explain that the recipe is designed to incentive players to research & automate production
--      of items they might otherwise ignore (such as lamps and combinators)

-- TODO Polish the design decisions section in this file

-- TODO Clean up unused graphics / icons

-- TODO make function names & variables conform to lua style

-- TODO Break apart into a 'boostable turrets' mod
        Let people use mod settings to control what level the boosting is
-- TODO How to handle recipes? Just a beacon to all the regular recipes, enable it with a unique range-boosting technology?
-- TODO Or just make a stand-alone version of the mod and a non-standalone version?

-- TODO rename searchlightFriendRadius to d.searchlightRangeBoostRadius or something

-- TODO Be more meticulous in checking entity.isValid on objects before we use them (including players, characters, cursors, item stacks, etc)

-- TODO prototype: map_color and enemy_map_color (make sure turtle & hidden SL_attack entity have no color)

-- TODO implement on_entity_settings_pasted event & prototype feature "additional_pastable_entities" to let us know when people copy circuit settings between searchlights


### Feature: Mod-Uninstall Command

-- TODO should probably un-boost all turrets when a game is being saved, just in case they uninstall the mod. We can make the searchlights disappear, but it's probably unfair to also remove other random turrets.
--      So, there's not really a way to tell when this happens. And it doesn't look like the migration files will help either.
--      I think the best thing we can do is add a function that the player can call via command that 'disables' the mod so they can save & uninstall
--      And then we'll make a FAQ / User Manual to explain that if they don't want random turrets to disappear, here's the steps they need to follow


### Bugs to Report / Features to Request

-- TODO Write a bug report against the usage of trigger_type_mask and how non-turrets just totally ignore it.
--      And how it's so damn awkward to set up a blacklist for an entity that you don't want even-just-turrets to attack.

-- TODO Ask a devleoper on the forums for an 'on_save' event, or for a way in general to make sure that uninstalling our mod will give people back their original turrets.
--      (Alterntatively, ask for the simple ability to increase turret range during run time)

-- TODO Ask for a way to specify a sprite layer in radius_visualisation_specification as a big circle (instead of always square)
--      Or just give us a 'range' parameter on arbitrary entities

-- TODO Report prefer_straight_paths = true as bug? Seems to do the opposite of what it says

-- TODO energy_glow_animation on turrets flickers badly, but not when you use draw_as_light, so that's probably a bug


### Map modes / play

-- TODO Create a 'jailbreak' game mode, where 1 - 8 players are wardens manually controlling spotlights,
--      and ~100 other players are convicts.
--      Convicts try to gather resources and escape, wardens unlock more spotlights as they recapture convicts
--      (Captured convicts can play a minigame of some kind to re-escape from their cells)
--      We'll figure out the win / lose conditions later.
--      Maybe prisoners break into the warden's office and steal underpants or something.


### Advertising

-- TODO Submit mod to Xterminator, KatherineOfSky, other big modded factorio youtubers / names


### Testing
-- TODO Test compatibility for 'boosting' friendly turrets with something complicated like the water gun mod.
-- TODO Double check that no stickers of any kind can be applied to the attackentity / turtle

-- TODO So, the normal turrets infobox reflects whatever light effects (from shooting) that the turret produces.
--      Are we going to be able to (cheaply) replicate that effect?

-- TODO Get people to play test the balance

-- TODO Test blueprints construction / mass deconstruction

-- TODO enemies are stutter-stepping toward the turrets
--      (because the turrets keep getting destroyed and created by control.lua)
--      fix this
--      (possibly by having a time out between boosting and unboosting turrets
--       and swapping between the real and dummy spotlights)

-- TODO Double check to make sure that the boost turret turrets are only boosting turrets of the same force


## STRETCH GOALS
- Spotlight position & color controlled by circuit signals
- Spotlight emits detection info to circuit network
- Spotlight could possibly be set to only wander a 180degree arc around its inital placement?
- Use the 'TriggerEffect' prototype to play an alert sound if an enemy is detected? Looks like we can set it to play the sound at the 'source' aka the turret itself
    - We can also create a sticker or particle, which could be fun for making "!" float above the turret's head or something.
    - (Or Maybe cool flares could shoot out and form a '!'?)
- Mod ourselves into a couple of main-menu screens
    - Probably want a scene with an SL getting built by a robot, which enables turrets to attack a biter base
    - Probably want a scene with a jail break that succeeds
    - Probably wanta  scene with a jail break that fails
- Think about teleporting or somehow... hiding the entities we're replacing.
  It'd be nice to not have to spawn / destroy turrets all the time just because we're boosting them.




=================

## Feature request for spotlights that track enemies

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
- Prototypes/ArtilleryProjectile has one mandatory flag: reveal map
  So maybe that'd be useful

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
