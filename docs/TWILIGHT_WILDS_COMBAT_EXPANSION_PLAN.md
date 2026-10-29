# Read the Wilds: compact combat expansion specification

Date: 2026-10-29. Planning baseline: `dd103c8`, including the living habitats and
synced village/story/HUD work. Status: implemented; verification is recorded in
[ACCEPTANCE_TESTS.md](ACCEPTANCE_TESTS.md#read-the-wilds--compact-combat-expansion-2026-10-29).
This is **milestone 2, Combat expansion**, from the four-stage player-facing plan.
The engineering work-order list in the parent document is a separate breakdown.

Presentation update, 2026-10-30: habitat battles now use the existing PetBattlePanel
arena and manual turns. The protected clearings and pre-duel cast cancellation
remain, while the camera and map actors no longer move into in-world duel staging.

## 1. What this update should achieve

Give the existing walk three distinct combat decisions: step aside from a rush,
find a projectile gap or use cover, and leave a marked intersection. The citadel
then combines attack language the player has already encountered.

Keep the world **56x52**, the main road about **49.55 units**, the boss arena
**20x20**, the two **8x7** pet stages, and six regular enemies. Add neither a longer
walk nor more guards. Paths, checkpoint, winch, rifts, memories, hollow, pet bonds,
nine onward passages and both rescue branches keep their existing purposes.

Recommended combat limits: **one active pair, two attack-capable regular guards,
one committed attack at a time within that pair**. The earlier ceiling of three
simultaneous attackers remains a ceiling, not a target. The boss is a separate
encounter and never overlaps an attacking regular pair.

Enemy kills are not an entrance requirement. Players may retreat, explore a side
loop or run past guards. No sealed arenas, completion checklist, payment, new
equipment requirement or camera lock is added to the route.

## 2. Planning-baseline findings that shaped the design

These observations describe `dd103c8` before this implementation, rather than the
current guard/director code.

- `RealmDB.MINIONS` currently places all six guards close together. For example,
  the independent 6.5-unit activation circles overlap for five homes at (31,30).
  This is a calculation from source, not a new engine/playtest measurement.
- `TwilightRealm._physics_process()` manages each actor independently. It has
  retreat/safe-position checks, but no shared encounter owner or attack budget.
- Its pack reset stops processing, moves the actor home and clears effects. It
  does not explicitly reset `Enemy._charging` or ElementalMinion's pending shot
  clock. New attack types require an explicit cancellation contract.
- `Enemy._begin_charge()` enables charge movement immediately. Its 0.38-second
  clock is the charge duration, not a guaranteed warning period. A ring displayed
  during that movement must not be mistaken for a separate readable windup.
- `ElementalMinion` chooses its power from the shared elemental catalog. Changing
  the chaos catalog would also change other chaos actors outside this update.
- `ElementalProjectile` already uses a swept world ray; its current lifetime,
  radius and optional homing are too broad to copy blindly into a small teaching fight.
- `ElementalEffect` checks ground shapes against the player, without clipping
  those shapes against static walls or protected clearings. Existing safe-position
  checks alone therefore cannot guarantee safety from a newly added ranged attack.
- The boss already uses fan/dash/cross powers. Its cross spans 14 units; a regular
  guard needs a much smaller version. This update does not rebalance the boss.
- Ordinary guards grant XP on death and produce ordinary loot drops. Gold drops
  follow expedition collection/banking; XP is not described as losable carried loot.
- The merged HUD counts living enemies, including dormant ones and the boss.
  Encounter activation must not make that census silently hide living guards.

## 3. Exact content and health budget

| Pair | Composition | Starting HP allocation | Lesson |
|---|---|---|---|
| Rootbound patrol | Two Darkfire Imps | 42 + 44 | Read a rush, step aside, counter |
| Watchpost guard | Darkfire Imp + Ember Watcher | 46 + 48 | Use a gap, cover or a close approach |
| Ashen sentries | Darkfire Imp + Rune Keeper | 50 + 52 | Leave the cross and use a safe quadrant |

That is **four Imps, one Watcher and one Rune Keeper**, not six new enemies in
addition to the old six. Total starting HP remains **282**. Keep initial base
damage **7**, base movement **1.7**, XP **14 per guard**, and configured Gold
**7 per guard**, subject to the existing drop variation/collection rules.
This preserves the nominal reward budget; it does not promise identical difficulty.

No extra diamonds, supplies, caches, pet recruits, permanent combat bonuses or
completion reward are introduced by this milestone. The existing 25-Gold hollow
and its pending/banked claim rules stay unchanged.

## 4. Spatial plan: replace overlaps with small, readable fights

All coordinates below are **provisional reservations**, not validated collision
placements. Keep the current road polylines and landmarks as the reference.

| Pair | Proposed homes | Spatial treatment |
|---|---|---|
| Rootbound patrol | Imp (31,38.2), Imp (34.6,37.4) | Dry ground north of the main bridge; room to move sideways, with a clear retreat south |
| Watchpost guard | Imp (34.8,33), Watcher (37.2,30.8) | Existing watchpost bend; one off-road cover remnant and distinct winch access |
| Ashen sentries | Imp (24.1,27.4), Keeper (28.4,28.1) | Existing scorched approach, south of the lantern refuge; a clear route north into safety |

Starting fight envelopes for the planning diagram are approximately (28.5,35.7,
10,4), (30.5,29.8,9.2,5.7), and (22.6,26,8.4,5.6). These are space budgets, not
final leash rectangles. The last pad borders the root escarpment; test its west
edge against the actual barrier and routes before accepting any actor placement.

Use small authored engagement cores, larger pursuit polygons and physical return
routes. Do not replace six overlapping circles with three equally broad circles.
Small overlaps between pursuit areas are allowed only because ownership is singular.

The crossing pair should be seen before its first charge. The Watcher should face
the walking line from a visible platform, with the Imp offset to another lane.
The Keeper should stand far enough from the lantern that its entire readable
pattern and an escape route can fit outside the refuge. If that does not fit,
adjust homes/decoration inside the existing bounds; do not shrink the refuge.

### Protected space and clearance

- Keep both full 8x7 pet stages protected, including a body-clearance margin and
  the current safe circles. Protection is anchored to habitats, not moving pets.
- Preserve the lantern's current 3.5-unit refuge. Reserve the arrival/rift approach
  and Wisp's nearby reading space as peaceful space as well.
- Regular guards and their attacks never enter the boss chamber or onward court.
- Keep approaches to the winch, all memory stones, rifts and hollow physically open.
  No new enemy is placed inside a reading site or directly on an interaction target.
- Keep at least a proposed **1.8-unit clear passage** around any cover piece,
  measured between collision edges, and enough turning room for the companion.
- Start with one low cover remnant near the watchpost's outer flank, approximately
  (38.4,35). Recheck its full sprite/collision, the winch's interaction approach,
  the moth clue trail and the road. Remove it if it compromises those uses.
- Shortened paths or an open rootway must not create a new aggro route through a
  safe clearing. Choosing a side loop remains a valid way to bypass a fight.

## 5. The three attack profiles

These are initial playtest values, not claimed final tuning. Walking at the
starter Adam's configured speed must be enough to escape every first warning;
Sprint helps but is never required. Preserve current weapon and stamina pacing.

### Darkfire Imp: commit to the rush

Keep the existing chaos dash identity and damage budget. Give the charge one clear
directional windup, then commit to that direction rather than steering into Adam.
Only one Imp can commit at once. A wall or encounter boundary stops the rush.
Afterward the Imp recovers visibly, giving Adam a useful counterattack opening.

Start with a real **0.65 s stationary windup**, the existing **0.38 s** charge
duration and **0.60 s** recovery. Preserve the initial speed multiplier and one-hit
7-damage budget. Start motion only after the warning completes, and use swept hit
resolution rather than only distance at the final position. Keep the initial
3.6-second power interval; these values may change only after frame-based review.
This deliberately changes the warning contract, not player attack pacing, and
does not promise identical difficulty to the existing immediate charge.

### Ember Watcher: a narrow fan with readable gaps

- A distinct lantern/staff silhouette, rather than only a differently tinted Imp.
- Proposed warning **0.90 s**, locking its aim when the warning begins.
- Three non-homing shots at approximately **-25°, 0°, +25°**.
- Start at **5.0 units/s**, radius **0.18**, travel distance at most **6 units**.
- Do not begin a fan at point-blank range; use a proposed minimum of **2.8 units**.
  Approaching it is a valid response. It must not kite endlessly around the map.
- A three-ray floor cue shows the committed lanes before release. Clear gaps,
  cover, or a close side approach are alternatives; none requires a new button.
- A volley can damage Adam only once, for the initial **7 damage** budget, even
  if multiple shots intersect his body. Do not rely solely on blink immunity.
- Proposed recovery **0.65 s**, cast interval at least **3.6 s**, measured from
  commitment rather than accidentally restarted every chase frame.
- Shots hit real cover and disappear at protected-space or encounter boundaries.

Its lantern visibly dims during recovery. The player should recognize when it is
safe to close in. Ordinary close-range melee, if retained, uses the same attack
ownership/cooldown contract and cannot land simultaneously with the fan.

### Rune Keeper: a short cross that leaves escape quadrants

- A squat rune-bearing silhouette, visibly different from the Watcher's staff.
- Proposed warning **1.05 s**, fixed at Adam's position when the cast begins.
- Two world-aligned perpendicular strips, initially **3.6 units long each** and
  **0.70 units wide**, with a short **0.30 s** active interval.
- One shared damage result for the whole cross, initially **7 damage maximum**.
  The intersection never causes two payments of damage from two component shapes.
- Proposed recovery **0.80 s**, minimum cast interval **4.5 s**.
- No tracking warning, rotation surprise, slow, pull, lingering pool or aftershock.
- The displayed shape and damaging shape use the same clipped geometry. Walls,
  protected space and the permitted attack area trim both, consistently.
- Start a cast only when its warning can be read and there are at least two
  collision-clear escape directions. Reject or defer an invalid placement.

The lesson is to move diagonally into a clear quadrant, not race through a long
beam or spend stamina escaping a hidden area. Test edge-of-pad casts as carefully
as a cast at the centre. A warning does not imply that all four arms must be equally
long after a wall clips them.

## 6. Encounter ownership and pursuit rules

Use stable runtime encounter IDs: `rootbound_patrol`, `watchpost_guard`, and
`ashen_sentries`. Each has its two members, homes, engagement core, pursuit polygon,
return anchors and a deterministic priority. Do not save these nodes or timers.

1. **Resting:** living guards remain visible at home; they do not cast, chase or
   receive remote companion/ranged damage while their encounter is dormant.
2. **Notice:** Adam enters the core with a valid view/reachable approach. The pair
   gives a brief notice before committing its first attack; no invisible activation
   through the root ridge or scenery.
3. **Engaged:** the director owns one pair. Both may position, but only one can
   own a committed melee/dash/cast at once. Start with a **0.35 s** separation
   after an attack resolves; do not synchronize every enemy cooldown on activation.
   Hold the slot through its warning and all live damaging effects, including
   travelling fan shots. An early caster recovery does not release it prematurely.
4. **Returning:** leaving the pursuit area, entering a refuge, crossing into a
   new encounter core, or starting the boss cancels that pair's attack ownership.
   Living guards return physically along valid routes; they cannot attack or cast.
5. **Resting again:** settle at home with fresh readable warnings on re-engagement.
   Keep surviving HP for this visit. Guards already killed do not respawn on leash reset.
6. **Cleared for this visit:** both members are dead. No replacement wave or reward
   trigger is spawned. A later fresh uncleared visit uses the existing world-reset policy.

At an encounter handoff, cancel old attacks **before** granting the new pair attack
ownership. Returning actors may still be processing movement, so distinguish
"processing actors" from "attack-capable guards." The active-attack cap concerns
the latter; a returning actor must never retain a damage-capable charge.
If its return route becomes invalid, it waits safely and retries route resolution;
it does not resume a charge, snap through terrain or count as a cleared encounter.

Keep ordinary damage rules for an already engaged/returning living actor, with no
return healing or new payout. A hit does not activate another dormant group or
override the active-pair budget. Companion auto-targeting should not drag it after
a returning actor beyond its own player's valid combat area. Drop invalid targets
and let the companion return normally, without position snapping.

Encounter boundaries are not walls for Adam. Treat engagement changes consistently
from every approach, including the open rootway. Use small hysteresis at shared
edges to prevent alternating ownership every frame. It must not create an
invisible damage strip outside the visible warning.

## 7. Every cast needs a complete cancellation contract

Each committed action carries its current-world identity, encounter ID and runtime
generation token. Check ownership at commitment, release and damage resolution.
Invalidating a generation immediately disables its effects before queued deletion.
Protection, movement permission and attack ownership are checked every physics
step; neither the slower landmark survey nor the HUD census is a safety timer.

Cancel on caster death, windup interruption, leash return, protected-area entry,
pair handoff, boss ownership, player defeat, world replacement and journey change.
Clear charge flags/hit latches, velocity, pending shot/cast clocks, warning nodes,
owned projectiles/hazards, attack-slot ownership and transient pose tweens together.
Reset the next cast's initial warning instead of releasing a frozen old attack.

A wild-pet challenge is different: it deliberately **suspends** the world and its
existing effects. Do not advance cast clocks during the duel or during duel Settings.
When it closes, validate ownership again; entry from a protected habitat should
already have ended any pursuing pair. No deferred cast may strike the staged pets.

Ordinary menus retain their existing non-pausing rules. Opening the Field Guide
is not a new combat pause. Critical warnings take priority over optional captions,
whose complete memory text remains saved in the journal.

## 8. Damage and collision guarantees

- Use swept movement for shots/charges, including large-delta tests. Keep the
  established World=1, Player=2, Enemy=4 bit values and collision-mask contracts.
- Check protected-space intersection along travel, not just the final point. An
  orb cannot skip across a small refuge between two frames.
- Clear effects from the appropriate regular caster/encounter, not every effect
  in the world indiscriminately. Boss spells keep their own ownership.
- At boss entry, end regular attack ownership before enabling the ruler. Preserve
  threshold activation, all-direction retreat, effect cleanup and full arena framing.
- On victory, remove all surviving regular actors/effects and retain the peaceful
  visit. Missed pets, memories and the hollow must still work immediately.
- Preserve existing minion target rules. This update does not silently add pet HP
  damage, resident targeting, friendly fire, fire propagation or new status effects.
- Keep movement continuous and physics-backed. A leash does not teleport Adam,
  the companion or a charging guard through a pillar.

## 9. Persistence, rewards and compatibility

Prefer **no new saved gameplay fields** for this milestone. Encounter membership,
HP/reset state, active ownership, attack slots and cast tokens are runtime data.
Continue keeps the existing safe checkpoint and reconstructs unfinished ordinary
combat. A saved cleared portal still reconstructs a peaceful realm.

Do not alter existing cache ledgers, memory IDs, bonds, discovery cells, shortcut,
campaign rescues, workshop eligibility, stock licenses or village simulation.
Do not turn learning all three attacks into a new boss or workshop prerequisite.
The workshop remains unlocked by the existing first-portal clear and its own project.

XP and drops keep the existing ordinary-enemy policy. A boundary reset cannot
create another death/reward callback. Fresh-visit repeat rewards are existing game
behavior, not a newly promised once-per-journey enemy reward system.

In the future restoration milestone, a permanent ward may remember completion.
That is a separate saved activity. Do not add saved per-enemy HP now or spend two
extra guards on that future ward without revisiting the six-actor budget.

## 10. Presentation and touch

Keep one visual identity per attack: directional rush, separated fan lanes, and
two joined ground strips. Silhouette/shape and timing communicate the difference;
colour or sound alone never carries an essential rule.

Warnings remain readable on low effects, Reduce Motion and muted audio. Essential
warning outlines, active shapes and recovery states remain; optional embers and
camera motion may be reduced. Do not add repeated screen shake or full-screen flashes.

Normal camera follow remains in regular fights. Reserve enough visible room around
the pair and use a bounded local framing adjustment only if actual compact renders
prove necessary. Restore preferred follow/zoom on retreat, duels and world changes.
Keep the boss's existing arena framing separate.

Do not add combat buttons. WASD/joystick, Attack and Sprint already provide all
responses. Existing E/direct-tap services remain reachable. The live monster tally
counts all living guards, not only the active two; avoid calling it an aggro counter.

One brief optional Field Guide explanation can teach these shapes. Do not add an
on-screen kill checklist, permanent encounter panel, tutorial modal or forced
Waykeeper lecture. His existing memory/bond/restoration responses retain priority.

## 11. Narrow implementation ownership

- `RealmCombatDB` (proposed): profiles, pair IDs, spawn homes, zones, timing and
  small health/reward allocations. Keep `RealmDB`'s map/landmark authority intact.
- `RealmEncounterDirector` (proposed): current pair, attack-slot arbitration,
  approach/return decisions, protected-space queries and generation invalidation.
- `RealmGuard extends Enemy` (proposed): explicit dash/fan/cross profiles using
  the existing Enemy FSM/damage/death contracts. Reuse art helpers where appropriate.
  Avoid inheriting ElementalMinion's automatic chaos dash in a new caster and
  accidentally executing both powers via a `super` call.
- Narrow owned projectile/cross components: reuse swept/caster rules, add shared
  per-cast hit ownership and clipped geometry without changing all legacy spells.
- `TwilightRealm`: construct/integrate the director; retain world transitions,
  boss/rest/duel ownership and existing `wildlife`, `_packs`, player/camera APIs.
- GameState: existing progression/loot owner; no runtime cast state written to saves.
- WorldTally/HUD: continue working through the Enemy type and live HP/dead state.

Preserve test-accessed members or provide compatible adapters while migrating the
old per-actor activation loop. No broad Enemy FSM rewrite or global ElementDB edit.

## 12. Build order and acceptance

1. Define zones and the director around the existing six dash guards. Prove caps,
   safe spaces, return paths, boss handoff and full cancellation first.
2. Substitute the single Watcher. Verify fan spacing, fixed aim, one-hit volleys,
   real cover, swept collision and protected-area clipping.
3. Substitute the single Keeper. Verify shared cross damage, clipped warning/hit
   geometry, ordinary-walk escape and edge-of-zone cast rejection.
4. Reserve floor/cover clearances, then add distinct silhouettes and recovery poses.
   Recheck animal stages, winch, memory approaches and all nine onward routes.
5. Update the Field Guide, focused combat checks, tide_test and ACCEPTANCE_TESTS
   together; run the isolated full gate and actual-render reviews.

Required focused cases include:

- Approach each pair from the main road, side loops and open/closed rootway.
- Sprint through all three in sequence and reverse direction at shared edges;
  never exceed one active pair or one committed regular attack.
- Retreat during every windup and after release; re-enter and confirm no old
  charge/volley/cross resumes. Repeat during death, defeat and world replacement.
- Enter each refuge with a shot already in flight; no warnings, hits or pursuing
  bodies intrude into either entire 8x7 stage or lantern/arrival protection.
- Interrupt casters; kill at release; test duplicate callbacks and a large delta.
  A fan volley and cross each damage at most once per cast.
- Sample consecutive walking/dodging positions; verify collisions and attack timing
  from frames, not only a final screenshot or manually called damage function.
- Start/cancel/win/lose a wild challenge while another region has pending effects;
  preserve Settings suspension, camera restoration and all held-action releases.
- Continue old saves at either checkpoint, leave with loot, suffer defeat, clear
  the boss and revisit peacefully. Existing memories/hollow/workshop/rescues survive.
- Inspect 1280x720 and 832x480, including live GUI scale/camera settings, real injected
  touch, low effects, Reduce Motion and mute. Keep the shared HUD/warnings distinct.

## 13. Playtest decisions and stop conditions

Use starter Adam and Ember first. Observe whether a new player can describe each
attack's response without reading a guide, see both opponents before damage, step
away without Sprint, and return to a pet clearing without being followed by hazards.

Measure actual engagement overlap, time spent waiting on enemy invulnerability,
camera visibility, escape success and companion stalls. Do not invent success
rates, visit durations or frame-rate figures during planning.

If an encounter needs a bigger map to function, shorten/reposition that attack or
remove cover. If a warning needs to overlap a memory or safe stage, move the combat
pad. If two attackers remain hard to read, keep them sequential rather than add
more indicators. If the final pair cannot fit safely south of the camp, revise its
local footprint and cast length before implementing it.

Milestone 3 still owns the footbridge, grove ward, mirrors and their rewards.
Milestone 2 is complete when the same short journey supports three readable,
different fights with dependable retreat and unchanged exploration freedoms.

## Implementation record

The implementation uses `RealmCombatDB`, `RealmEncounterDirector`, `RealmGuard`,
`RealmGuardAttack`, `RealmGuardRoutes` and `RealmCombatArt`. The realm integrates
these owners without changing ElementDB or the other nine elemental arenas.
Field Guide entries teach each response. The winch remains usable during combat,
while its floating label yields to the Watcher's warning lanes.

The two Rootbound homes were moved onto dry ground at (31,37) and (34.6,36.8),
and the Watcher home was moved away from the winch to (38.3,30.2). The current
definitions in `scripts/data/realm_combat_db.gd` own exact coordinates and timing;
earlier coordinates in this design remain planning history. Collision-backed
checks verify the homes, continuous charges, physical return, cover, clipped
attacks and an actual injected touch dodge. No save schema or reward is added.

Milestones 3 and 4 remain separate work. Automated correctness and inspected
captures establish the implemented contracts; they do not establish first-time
player comprehension, Android performance or physical-phone input usability.

## Original planning evidence limits

The original plan was based on the baseline RealmDB/RealmContentDB, TwilightRealm,
ElementalMinion, ElementalBoss, ElementalEffect, ElementalProjectile, Enemy,
ResidentRoutes, Pet, WorldTally and the synced workshop documentation. Current
coordinates and budgets are distinguished from proposed replacements above.
At that planning stage no gameplay source was changed, no engine checks were
rerun, and no proposed encounter polygon, timing value or cover position was
claimed as playtested. The implementation and new evidence are recorded above
and in ACCEPTANCE_TESTS.md.
The accompanying selectable planning diagram was checked in a browser for working
selection, script errors and layout at 736- and 360-pixel widths; that is presentation
verification only, not proof of in-game collision, difficulty or phone controls.
