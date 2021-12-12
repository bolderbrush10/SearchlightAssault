## Current Task:

-- Testing
Observe biter progress at 5 / 10 / 30 / 60 marks on various difficulties

Personal play test


-- Final / Cleanup tasks

Make all warden-owned objects unminable
Make all warden-owned medium & large powerpoles and substations with 4+ adjacent concrete invulnerable (but not small powerpoles)
/c local p = "big-electric-pole"; local s = game.surfaces[1];
for _, p in pairs(s.find_entities_filtered{name=p}) do 
if #(s.find_entities_filtered{name="wall", position=p.position, radius=2}) > 4 then p.destructible = false end
end

Unlock warden laser & ammo speed / damage technologies at the last minute so that players have to actually worry about getting shot by warden turrets
(Actually, maybe we just want to do the first couple ranks, then have the later ranks unlock based on difficulty?)

Chart only select chunks on wardens (labs, walls, bases, etc)
(Maybe use a script to do this, 'for every entity in their force, chart the chunk its in' -kind of thing)

Unchart all chunks on player force
force.clear_chart(surface)

Reset the last-user on all entities to Gaia


## Next Tasks:

- Prepare FAQ: explain potential mod incompatibility, workarounds, uninstall command, performance (only use ~1 - 2 thousand searchlights), etc
- Add localization for the searchlight technology itself
  "A support turret which integrates combinator & radar technology to allow spotting foes from great distance."


### Professionalism Polish

- Collect more in-game screenshots and gifs for the mod portal page

- It would be good to create some professional diagrams and documents to explain the underlying strategies of the mod
- We'll want to make a header / word template featuring a logo for the mod and stuff

- Port this file into the bottom of the readme when complete

- Final sweep over README.md


### Advertising

- Submit mod to Xterminator, KatherineOfSky, Trupen, The Spiffing Brit, Noobert, AmbiguousAmphibian, PBL, other big modded factorio youtubers / names
