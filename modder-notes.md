## Current Task:

TODO Setting operable to false/whatever doesn't effect players in editor.
     That's probably for the best, so they can mess with flags and stuff.
     We should probably just check if the player is in editor mode,
     then move the GUI out of the way or something.

TODO An entity that has been marked for deconstruction was still able to get boosted and then un-marked for deconstruction... 
     I fixed that real quick, but I still need to figure out what to do about marked for upgrades etc

TODO Look into using "fast_replaceable_group" in the prototype stage
     between regular and boosted versions of turrets, various searchlights, etc

TODO Decals now support draw_as_light and draw_as_glow 
    Did this fix draw as glow for beams??

TODO Do a more thorough pass for blueprints

TODO New blueprint system: https://forums.factorio.com/viewtopic.php?p=661598#p661598

TODO Target tracking tends to break, requiring searchlights to be rebuilt,
     even though the searchlight has started targeting a foe instead of the turtle..
     Not often, but not never

TODO Gui is showing stale values for a newly built searchlight, based on some old searchlight I built i guess

TODO The graphics_set base_visualization is loading each of my layers pointing north..
	   But energy_glow_animation points east...
	   Can we get a min viable mod to show this repro from old vs new factorio versions?

TODO fix searchlight spotlight's rotation when targeting enemies run around (bug?)
		 it also affects the light at the base of the turret... bug report / min viable demo?
		 
TODO quality in searchlights, quality for boosted prototype generation
TODO checkout placeable_position_visualization / StatelessVisualisation

TODO tile blocked graphic doesn't match regular turrets when trying to build over a searchlight

TODO Whatever we doing before to cleanup blueprints so they always have the base version of a searchlight isn't working anymore

TODO Searchlight turret GUI still pops up for safe lights

TODO  CTRL+X drag looses wires

TODO Added LuaEntity::minable_flag read/write. Write to LuaEntity::minable is now deprecated.
    - Added LuaCustomEventPrototype::event_id read.
    - Added LuaCustomInputPrototype::event_id read.
    - Added LuaBootstrap::get_event_id.
    - Unified parsing of event types into LuaEventType. Made it possible to specify custom events and custom inputs by providing prototype instance.
    - Custom events and custom inputs defined by prototypes are given constants inside of defines.events.

    - Renamed WorkingSound::max_sounds_per_type to WorkingSound::max_sounds_per_prototype. The limit is now applied per prototype.
    - Removed WorkingSound::apparent_volume.
    - Removed WorkingSound::audible_distance_modifier, MainSound::audible_distance_modifier and SoundAccent::audible_distance_modifier. Sound::audible_distance_modifier is used instead.
    - Removed PlaySoundTriggerEffectItem::volume_modifier and PlaySoundTriggerEffectItem::audible_distance_modifier.


TODO searchlight should probably freeze on aquilo

### Advertising

- Submit mod to Xterminator, KatherineOfSky, Trupen, The Spiffing Brit, Noobert, AmbiguousAmphibian, PBL, other big modded factorio youtubers / names
