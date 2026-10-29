# Individual ember portals and the shared first-night reveal

Implemented 2026-10-30. This connects presentation to the existing village night
wave and later-dungeon reinforcements. Variable quiet/forest/shore/mixed profiles
in `NIGHT_ENCOUNTER_PLAN.md` remain a separate proposal.

## What happens

Each newly allocated fire monster has a separate small ember tear at its reserved
land position. One ember holds, stretches into a dark vertical opening with an
amber lip, and admits a pale core and narrow flame body. The creature gathers low,
reforms, looks toward a real mature tree, and the opening seals. Nearby allocated
members repeat the crossing at different visual phases. The final preview uses
the same cached rest texture, scale and foot position as the real Enemy.

The full fire-only introduction lasts 10.5 seconds. When both species need their
first introduction, the existing shore chapter runs first, a brief covered camera
cut moves to the forest, and a condensed fire chapter follows. Total duration is
14.5 seconds, with one final camera return and one Skip control. An introduced
species never acquires a second full chapter. Shore-only introductions retain
their eight-second duration.

Game owns the story suspension, input release, HUD and previous camera. Both
species remain cosmetic previews throughout a combined scene; real attacks cannot
run unseen during either chapter. Skip reaches the same final authorized batch.
The normal 0.35-second SPAWN settle and existing melee windup remain. Revealed
fires begin opaque so they do not fade in again after crossing the portal.

During later arrivals, an eight-world-second environmental warning leaves normal
controls and simulation running. Sparse embers become small portals in its final
1.4 seconds; real bodies arrive at the saved shared deadline. Reinforcements use
the same warning, with no full story takeover. The direction caption yields to
modals/interiors and never relies on the no-op toast API.

Fire and portal effects remain silent. Ordinary shoreline foley stops before the
forest chapter. Existing dusk lighting follows the authoritative world clock,
which remains suspended during a full story; no artificial night grade is added.
Reduce Motion uses still crossing poses/direct framing without changing delivery
times. Low effects retains the rim, dark opening, body, eyes and contact shadow.

## Geography, saves and combat

Allocation uses independent deterministic candidates around the forest anchors,
without consuming the historical forest-construction RNG. Positions avoid sea,
authored collision, mature tree trunks, building footprints, recovery space,
nearby actors, other live fires and other reserved fire batches. Bodies reserve
at least 1.3 world units between entries and require a traversable forest route.
The lead shot prefers visible ground outside tree-canopy rectangles. Invalid
points are discarded on final validation rather than moving their creature to
an unrelated unchecked fallback.

GameState owns defaulted and sanitized `campaign.fire_intro_seen`, stable batch
IDs, numeric fire points and absolute warning start times. Ordinary allocations
use `home_arrival`; additional fire reinforcements use `home_fire_arrival`.
Completion captures surviving real monsters, clears its exact pending batch and
records the applicable species flags in one synchronous save transaction.
Duplicate callbacks cannot duplicate members. The fire safety ceiling remains 30.

Save/load reconstructs pending warnings against their original clock. A legacy
count-only pending wave gets explicit fire points once, preserving its start time.
An older save containing fire survivors migrates as already introduced. Saved
survivors restore their positions/HP without portals. Cancellation or blocked
delivery does not mark the fire reveal seen. Dawn rejects new delivery while
retaining actual survivors and burning trees. World/journey replacement cancels
presentation and rejects stale completion/camera callbacks.

Real fires retain 40 HP, damage 3, speed 1.62, 1.6-second attack interval and world-
only body collision. The existing FSM owns 0.42-second windup, 0.14-second active
phase, 0.50-second recovery, targeting, one-hit claims and one-payment rewards.
The cinematic does not script a tree ignition: normal combat does that afterward.
Burning continues after the attacker dies; Water Keepers still extinguish it.
Portals have no interaction, collision, damage, loot or persistent terrain effect.

## Owners and review

- `scripts/core/fire_art.gd`: bounded cached original pixel portal/body poses.
- `scripts/world/fire_arrival.gd`: sampleable cosmetic forest chapter.
- `scripts/world/urchin_arrival.gd`: shared chapter timeline, camera, Skip and cues.
- `scripts/game/game.gd`: full-story eligibility and ownership restoration.
- `scripts/world/lobby.gd`: reservation, validation, spawning and survivor restore.
- `scripts/autoload/game_state.gd`: migration, pending records and atomic delivery.
- `tools/fire_arrival_checks.gd`: functional/capture checks in the canonical gate.

Windows focused route:

```powershell
tools/test_isolated.ps1 -Godot <console-executable> -Fire
tools/test_isolated.ps1 -Godot <console-executable> -Fire -Capture -Resolution 832x480
```

`-Fire` runs existing shore checks and the new fire/combined checks. Capture samples
include the shore-to-forest bridge, ember, seam, crossing, tree attention, follower
portals, final return, repeat warning and low/Reduce Motion. See the newest
acceptance entry for actual completed validation and its limits.
