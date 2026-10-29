# Compact balances and live world tallies

The top-left HUD now starts with two smaller balance chips, followed by live
status counters. Gold and Diamonds use 18-pixel icons and 34-pixel-high chips;
their combined minimum width is 204 pixels plus the gap, replacing the previous
344×48 currency panel. Large amounts use K/M/B notation from 10,000 onward;
desktop hover text retains the exact balance.

| Counter | Meaning |
| --- | --- |
| NPC | Living people / people currently belonging to this world. Includes ambient residents, all specialist workers, merchants, the mission guide, student, coastal guard and rescued village friends. Sheltered people remain alive; the player and pets are excluded. |
| Monsters | Living enemies in the current world, including bosses and newly spawned threats. Dead, queued and retiring-world actors are excluded. |
| Trees | Living trees / all replantable tree sites, including fallen trees. Protected growing saplings count as living. |
| Fire | Mature living trees currently burning. This is separate from the fire-monster count. |
| Homes | Intact registered houses / all registered house sites, including the main cottage and ruins. Shop tint targets and fences are excluded. The default village starts at 8/12. |

NPC losses and live monsters use red; burning trees use amber. Names and numeric
values remain visible so the information does not depend on colour alone.
Hover descriptions explain the categories and include specialist, enemy-kind and
sapling subtotals. In a dungeon or Kraken arena, only the local monster counter
is shown beside balances. Village counters are hidden rather than displaying
misleading zeroes for a village that is not currently loaded. Ocean keeps its
existing dedicated HUD.

## Ownership and refresh

`scripts/ui/world_tally.gd` takes a read-only snapshot of the explicitly supplied
world subtree. It checks deletion state, visits each owned node once, and uses
actual life/state APIs. It does not rely on visibility or count all global groups:
hidden sheltered residents are alive, and fallen trees leave their live-tree
group while remaining repairable nodes. Only nonempty persistent structure IDs
participate in Homes; the five shop tint targets have no registered home ID.

`scripts/ui/hud_status_strip.gd` owns chip presentation and responsive flow.
`GameHUD` refreshes currency through the existing data signal, refreshes tallies
immediately on world handoff, and polls live counts every 0.5 seconds while its
HUD is visible. Ordinary currency/HP notifications do not trigger a full census.
The snapshot creates no progression fields, save writes, rewards, spawn changes
or simulation pause. Its collection is scoped to one world even when old and new
nodes coexist during transitions.

The strip follows GUI scale with a minimum 12 physical pixels for its text.
It wraps before Menu/Map rather than compressing the labels indefinitely.
Wrapped height moves the emergency/build banner down when needed. A custom Menu
position leaving too little horizontal space moves the strip below the edge
controls. Existing control-layout IDs and placement persistence are unchanged.

## Verification

`StatusStripChecks` runs in `tools/tide_test.gd`. It covers a fresh census,
shelter/death, ignition, falling/replanting, house destruction/repair, live/dead
enemy counts, unrelated and retiring worlds, data immutability, large balances,
dungeon scope and immediate world removal.

The isolated `res://tools/status_strip_test.tscn` adds rendered day and threat
states at 1280×720, 832×480, 640×360 and 480×320, with GUI scales 75%, 100% and 130%.
It checks bounds, non-overlap with edge controls/emergency UI, physical text size
and smaller currency dimensions, then captures large balances, custom Menu
placement and dungeon scope.
Current measured results and external evidence paths are in ACCEPTANCE_TESTS.md.
