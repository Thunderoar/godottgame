# West Workshop: the first village progression loop

Implemented 29 October 2026 from the audited
[progression plan](VILLAGE_PROGRESSION_PLAN.md). This implements the complete
first workshop slice. Later residential, harbour, forest, production and
population proposals remain deferred; existing rescue and house-upgrade rules
are unchanged.

## Playing the loop

1. Start a journey with basic swords, armour, shields, potions, companion care
   and all four starter specialists available. The ruined western cottage is
   marked **West Workshop** in the village and on the picture map.
2. Defeat the first portal guardian in Chaos Citadel. Its victory panel explains
   the new opportunity; the saved clear flag also reveals it on later loads.
3. Visit Bram's Construction Shop, open Missions, or approach the site to
   commission **A Roof for the Workshop**. This first commission is free.
4. A builder physically travels to the workbench and performs ten seconds of
   daytime work. Alternatively, stand near the bench and tap it or press E to
   help yourself. Movement, attack, damage, opening a menu or losing application
   focus stops player work. Tap again to stop deliberately. No held action is
   synthesized.
5. Work pauses at night, near monsters, during a raid, while sailing/in a story,
   or outside the active village. Accepted progress persists at save boundaries.
   If someone stands inside the future building collision, completion waits for
   them to step clear.
6. Completion restores the cottage and licenses all advanced swords at Garrick's,
   starting with Tideblade for 240 Gold. Buying a sword is a separate transaction;
   completion does not grant an item. Rami uses the workshop if alive; otherwise
   a living builder receives the routine. Nobody is resurrected.

Use **Show path** in a project card for ground guidance; existing tutorial tasks
and emergency defense take priority. The world sign, map ring and live cards
show locked, available, working and completed states. The completed shelter can
accept an optional purchased rooftop gun. Later damage uses ordinary repairs
and never removes the permanent stock license.

Advanced sword family: Tideblade, Emberfang, Glacial Edge, Tempest Saber,
Thorncrown Blade, Stormbreaker, Soulrender and Monarch Slayer. Their existing
prices, stats and owned +5 upgrade rules remain unchanged. Both rescue branches
remain independent; the workshop is not required for boarding the ship or
entering an otherwise eligible portal.

## Ownership and integration

- `VillageProjectDB` defines stable project/anchor/structure IDs, the ten-second
  duration, free cost and explicit advanced-stock family.
- GameState alone writes `village_progression` and structure HP. It derives plot
  eligibility from the existing portal record, enforces purchase gates, starts
  commissions once and commits completion once.
- `VillageProjectSite` owns a runtime weak worker lease. Work submissions require
  the active world/journey, valid living actor, on-site proximity, safe daytime
  conditions and at most one capped physics-tick contribution. Stalled routes,
  death, damage, shelter, focus loss and world retirement release ownership.
- Builders call this job from their normal continuous-movement loop. Ordinary
  repair selection and APIs exclude the pending new-journey site. Project labor
  does not also decrement the ordinary damage-repair timer.
- Lobby reconciles activity destinations after state changes and layout refresh.
  Future building/yard space is reserved on the resolved runtime layout, leaving
  source resources and the terrain-bake identity unchanged. Dragging cannot
  overlap that reservation; commissioning rechecks edited layouts and routes.
- The workbench sits west of the original palm (`forest_15`); its ID, position,
  HP, collision and forest RNG are preserved. No new building footprint replaces
  or relocates a gameplay tree.
- `VillageProjectCard` is shared by construction, journal and forge interfaces.
  Its live progress updates in place; the forge uses a compact version. Stock
  cards show concrete locked reasons, and GameState rechecks purchase access.
- A touch followed by its emulated mouse press is one interaction, preventing
  the same gesture from starting and immediately stopping work.

Saved schema, in addition to existing `structures` and `portals`:

```text
village_progression:
  schema: 1
  legacy_access: false
  tracked_project: "" | "west_workshop"
  projects:
    west_workshop:
      state: "not_started" | "working" | "complete"
      remaining: 0..10
```

No actor, runtime lease, second world clock or duplicate portal milestone is
saved. No offline construction runs. Partial work is saved at commissioning,
interruption, completion and existing transaction/transition boundaries, rather
than per frame. An abrupt termination can lose work since the last save; the
existing save writer is not claimed to provide crash-safe transactions.

## Existing and malformed saves

Raw saves without `village_progression` receive a legacy entitlement before
default merging. Existing stock access, purchased weapons, worker counts,
house tier, cottage HP, shelter, gun ownership and placement are retained.
An already repaired cottage can receive an optional workshop fit-out after
the first clear without being demolished. The entitlement persists on normal
save/reload and does not invent a portal clear or rescue.

Current records sanitize types, known project IDs, state and finite remaining
time. Invalid legacy flags do not grant access, and work/completion records
without the prerequisite reset safely. Unsupported future numeric schemas are
rejected before replacing current state or rewriting their file. Ordinary
unreadable-save handling remains intact.

## Validation

`VillageProjectChecks` is integrated in `tools/tide_test.gd`. The focused scene
is `res://tools/village_project_test.tscn`; all runs must use verified isolated
user data before autoload initialization. Its native route additionally checks
real screen-touch commissioning, a full ten-second player build without workers,
consecutive craftsman movement, compact Close placement and live accessibility
settings, with captures at 1280×720 and 832×480.

Measured final results and evidence locations are recorded in
[ACCEPTANCE_TESTS.md](ACCEPTANCE_TESTS.md). These fixtures validate the feature's
rules and integration; they do not establish natural first-boss difficulty,
Android behavior or performance measurements. The separate late-campaign XP gap
identified in the audit is unchanged.
