## Current Task:
So. We're in the middle of a HUGE refactor.  
Our goal is to break things down so that there's objects (like a searchlight, the turtle, tunions, etc), and _features_ that act on those objects when an  event fires. (Files named control-____.lua are where the features live)  

So far, we've been doing a poor job at this. I think we were initially going to do our best to rewrite everything "from scratch" as much as possible. But, we've been slacking on that, for the sake of just getting things to run again.  

We need to go back, and have some deep thinking about where we want things to live.  

We need to really crack down on moving "event"-like code into the control-____.lua files, and make the various objects more passive. All the "brains" should be in the control.

The goal is to move as much coupling as possible between different objects into the control-____.lua files.

### Advertising

- Submit mod to Xterminator, KatherineOfSky, Trupen, The Spiffing Brit, Noobert, AmbiguousAmphibian, PBL, other big modded factorio youtubers / names
