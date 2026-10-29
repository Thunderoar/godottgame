# Variable night encounters — design proposal

2026-10-30. Inspected source baseline: `b2b3b10` on `main`.
Status: planning only; no gameplay changes or new validation results.

## Intent

Night should create uncertainty, with some quiet nights, some forest trouble,
some shoreline trouble and occasional mixed pressure. Clearing enemies should
buy real breathing room. Nightfall must not automatically refill both species.
This is an in-game world-clock schedule, not a real-time or calendar schedule.

## Source audit

- `Lobby._on_day_phase_changed()` currently replenishes living counts to 24 fire
  monsters and 6 ordinary sea urchins immediately at dusk. `home_wave` prevents a
  second replenishment during the same night.
- Survivors are saved with position, HP and raid membership in `home_monsters`.
  Dawn does not remove or disable them. A quiet spawn schedule therefore cannot
  promise that the village contains no enemies.
- `Game._process()` can start a separate guaranteed emergency after 14 seconds
  in a later dungeon at night. TwilightRealm is explicitly exempt. Emergency
  restoration can spawn stronger urchins and up to six additional fire monsters.
- The current RubbishSystem leaves collectible rubbish on the beach; it does not
  spawn sea urchins. Do not revive an obsolete rubbish-to-monster rule.
- The tutorial's pending `fire_kill` lesson expects a real target. Without one,
  Lobby guidance currently falls back to a yard position. A quiet night needs
  honest alternative guidance, rather than a fabricated target or completed kill.
- Existing tests explicitly require 24 fires plus 6 urchins at dusk and refill
  next night. Those assumptions must change with the feature, rather than forcing
  the new scheduler to recreate the old behavior for tests.

## Recommended first version

Choose exactly one night profile using a separate, saved journey seed and the
absolute night index. Resolve it once and persist the result. Never repeatedly
roll until an attack happens; never roll again on returning home or loading.

| Profile | Initial weight | New arrivals allowed |
| --- | --- | --- |
| Quiet | 35% | Neither species |
| Forest activity | 30% | Fire monsters only |
| Shore activity | 25% | Sea urchins only |
| Mixed activity | 10% | Both species, spaced apart |

For the first two nights, move the mixed profile's 10 percentage points into
quiet: 45% quiet, 30% forest, 25% shore. A first night can be quiet too. Do not
force a spawn for the tutorial or guarantee an attack after a quiet streak.
These are proposed tuning values, not measured balance or player-pacing results.

Use shared arrival windows measured from the start of the existing 180-second
night: 25–40, 55–70, 85–100, 115–130 and 145–160 seconds. Choose exact times up
front, with at least 20 seconds between scheduled batches. A forest profile uses
up to three windows; shore uses up to two; mixed interleaves at most five. There
is no routine arrival in the first 20 seconds or final 20 seconds of night.

Start with the existing ordinary ceilings as budget limits: at most 24 fire
monsters and 6 ordinary sea urchins, divided into groups of at most 8 and 3.
Subtract existing living same-species enemies when allocating a night's budget.
These are limits, not counts that the game repeatedly tries to restore.
Killing a batch never schedules its replacement. If a batch is blocked by live
pressure or invalid geography, discard its blocked remainder rather than queueing
an accumulating debt. Retain the existing absolute fire/urchin safety limits.

This deliberately changes encounter frequency first, without simultaneously
changing monster HP, damage, movement, rewards or house-tier scaling. Even with
unchanged ceilings, reduced encounter frequency lowers average combat income;
that consequence needs balance review rather than being hidden.

## Persistence and ownership

Introduce a versioned `night_encounters` dictionary owned entirely by GameState:
journey seed, absolute night index, selected profile and a bounded list of batch
records. Each record has a stable ID, species, due time, expiry time, allocated
count, entry region and disposition (pending, delivered, skipped).

- `NightEncounterDB` holds profile weights, time windows and tuning constants.
- GameState creates/validates plans, records resolutions and owns saves/signals.
- Game coordinates the clock and world eligibility, including later expeditions.
- Lobby restores survivors and materializes permitted ordinary batches through
  existing physical spawn/targeting APIs.
- HUD/tutorial consume status; neither writes saved encounter data directly.

Use a saved 32-bit seed suitable for JSON round trips and a dedicated RNG. Do not
use Lobby's forest RNG, decorative RNG, global random state, or runtime-only
journey_serial as the persistent seed. Preserve the original 64 forest identities.

Resolve a batch and capture its resulting living monster records in one
GameState save transaction. There must be no await between materialization and
commit. Reload must restore the same survivors and batch dispositions together.
Persist the empty/quiet outcome as carefully as an attack outcome. Do not save
per frame; use plan creation, batch resolution and existing save boundaries.

Migration preserves existing `home_wave` and `home_monsters`. A legacy save whose
current night was already processed gets no fresh arrivals that night; start the
new schedule next night. Do not reinterpret its survivors or refill it again.
Provide defaults plus strict sanitization for malformed seeds, profile IDs,
duplicate events, counts, timing, night indices and dispositions. Missing seeds
on older saves need a stable migration default, not a fresh roll on every load.

## World changes and missed windows

Use absolute GameState time. Ordinary menus continue world time. Stories and
accepted habitat challenges suspend it through their existing owners.

Ordinary arrivals require the active Lobby and matching journey. While the player
is at sea or in a realm, ordinary batches whose windows expire are skipped. On
return, deliver only still-valid future batches; never spawn a missed night's
entire roster around Adam. A large delta must not release several batches in a
single frame. Deliver at most one eligible current batch and expire older windows.

Existing survivors still restore with their HP and positions, including by day.
At dawn, discard pending ordinary batches without despawning live monsters or
extinguishing fires. Recovery suppresses new arrivals and skips due batches;
it does not freeze the normal clock or erase existing danger.

## Later-dungeon emergencies

Convert the current unconditional 14-second emergency trigger into eligibility
for an already-selected attack opportunity. It must not start a fresh probability
roll on every dungeon visit. Quiet nights do not create automatic emergencies.
TwilightRealm keeps its existing exemption.

A due shore/mixed opportunity can become a later-dungeon emergency only if the
player has spent 14 seconds in that expedition and no emergency is already
active. A forest-only profile cannot introduce emergency urchins. A shore-only
profile cannot introduce emergency fire monsters.
Conversion consumes that opportunity and cancels the remaining ordinary batches
for the night. Reserve up to three stronger urchins within the remaining urchin
budget, and optionally up to six fires only within a mixed profile's remaining
fire budget; existing survivors and delivered batches still count. Emergency
code must not add its old unconditional fire top-up.
An already-active legacy emergency remains active and restores through existing
save/recovery rules; changing schedules cannot erase it.

The emergency remains a separate saved event after activation, with its existing
kill ownership and damage accumulator. Do not repeatedly issue it on re-entry,
on dawn, on a kill signal or while the same event is already materialized.

## Readability, tutorial and progression

Give committed arrivals a brief visual cue around 8 seconds beforehand: treeline
movement for fire groups, shoreline disturbance for urchins. Use an owned HUD
status or in-world marker, not `show_toast()` (currently a no-op). Avoid a global
combat lock or modal warning. Cues must remain readable with reduced effects and
Reduce Motion. Keep fire-monster combat/burning silent.

Do not label a quiet night SAFE: old attackers and burning trees may remain.
If there is no actual fire target, the pending defense lesson should explain the
quiet forest and offer the actual Dimension Portal/exploration route. Keep
`fire_kill` pending until a real eligible kill; never fabricate completion. The
existing first-realm clear still ends training. Remove the fallback arrow to an
empty yard, and update the tutorial/field guide's guarantee-like wording.

Review XP availability before release: a complete first-realm route supplies XP,
but a boss-only first clear can leave Adam short of the next level gate. After
that clear, the first realm is peaceful. Fewer village attacks can extend that
wait. Measure this exact case and revise preparation guidance truthfully. If it
is too restrictive, design a separately player-initiated patrol at the coastal
guard; do not secretly force an ambient attack or change XP thresholds to hide
the problem. That opt-in encounter is a follow-up decision, not implicit scope
for the first scheduler implementation.

## Implementation and acceptance sequence

1. Implement the pure deterministic plan builder, defaults and migration.
2. Replace dusk replenishment with bounded batch dispatch and atomic resolution.
3. Gate the later-dungeon emergency through the same saved plan.
4. Adapt tutorial target availability and add nonmodal visual arrival cues.
5. Replace old fixed-population tests with injected deterministic fixtures.
6. Run balance probes, the canonical isolated gate and native rendered reviews.

Required acceptance coverage:

- A quiet night produces neither species; each single-species profile never
  introduces the other, and mixed arrivals obey spacing and budgets.
- First-night quiet is valid; no hidden tutorial or emergency override forces it.
- Repeated ticks, kills, night signals, transitions and save/reload do not reroll
  or duplicate batches. Saving before/after a window restores consistent state.
- No daytime arrivals; dawn retains survivors, burning and actual targeting.
- Existing pressure, recovery and unsafe geometry cannot accumulate deferred
  batches or bypass caps. World/journey replacement rejects stale operations.
- Off-world missed windows, late returns, multiple missed nights, large deltas
  and later-dungeon emergencies follow the explicit eligibility rules.
- Old saves and malformed schedules preserve progress without granting a second
  current-night wave. The original forest fixture remains exactly unchanged.
- Tutorial guidance works when no fire target exists, without invented progress.
- Seeded many-night probes report profile frequencies, arrivals, longest quiet
  streak, damage, combat income and the boss-only level-gate preparation case.
  Assert invariants and use broad distribution checks, not flaky exact frequencies.
- Inspect warning-to-arrival sequences at 1280x720 and 832x480, with low effects
  and Reduce Motion. Run the isolated full gameplay gate and `git diff --check`.

Do not claim these checks have passed until the implementation exists and the
routes have actually been run. No engine run was needed for this planning document.
