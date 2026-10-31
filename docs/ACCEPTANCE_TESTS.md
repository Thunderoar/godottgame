# Acceptance Tests for AI Agents

## Village progression repairs (2026-10-29)

- Ordinary builders validate exact repair approaches before claiming work.
  Empty and stalled paths release ownership and retry after three seconds;
  geometry revisions clear backoff. They still travel physically and supply
  ten seconds of daytime labour after arrival. A failed repair cannot prevent
  a queued West Workshop job. Night, shelter, death and world retirement retain
  existing cancellation and partial-work behavior.
- The actual Twilight boss victory grants Luma and workshop eligibility while
  showing a persistent, dismissible New for BESUT reminder. Landmark surveys,
  world replacement and save/reload retain unread rewards. Got it persists via
  a defaulted, strictly sanitized `village_progression.first_clear_acknowledged`
  flag. Village plans opens the registered Missions panel, with normal control
  locking/closing; the reminder yields to modal/world ownership and does not pause.
- Both habitat bonds/legacy owned pets complete wild-companion guidance without
  manufacturing an old tournament result. No retired tournament requirement
  remains in village guidance or the NPC description of obtaining guardians.
- Level-locked passages explain exact missing player XP and preparation through
  village defense or cleared later-stage replays. Their nearby labels keep the
  level/XP requirement compact only for earned passages; sealed passages retain
  the previous-guardian prerequisite. Existing level gates and all reward/balance values
  remain unchanged; a peaceful first-realm revisit still has no repeat boss.
- `VillageProjectChecks` covers blocked repair selection, released existing
  claims, work arrival, queued civic work, stalled endpoints, geometry retries,
  night interruption and malformed notice flags. `twilight_checks.gd` covers
  the real boss/return/journal/acknowledgement path, both habitat bonds, stale
  guidance and cumulative level-threshold arithmetic. Both run in the canonical
  `tools/tide_test.gd`; the native Twilight route captures the new reward reminder.

Final verification on native Windows / Godot 4.7.2:

- Canonical isolated gameplay: **5,757 checks, PASS**, exit 0; empty stderr,
  no `[FAIL]`, `SCRIPT ERROR` or `ERROR:` markers. This includes **70 workshop
  checks**, including preservation of current schema-1 residential HP, purchased
  guns and partial repair work when the new notice default is merged.
- Native Compatibility/OpenGL Twilight reviews at **1280x720** and **832x480**:
  **83 checks, PASS** each, exit 0, empty stderr. Inspected the reminder after
  actual boss victory and on village return at both sizes. The rendered panel
  fits its content; Got it retains a 44-pixel touch target and is exercised by
  injected touch. The village-plans journal route restores controls on close.
- The initial 90-second import wrapper timed out without script errors. An
  isolated retry with a 180-second bound and explicit `--quit` passed, exit 0;
  the existing Android build-tools-directory diagnostic remains. No Android
  export, physical-device or natural player-pacing measurement is claimed.
- `git diff --check` passed. Source art/maps/bakes and normal player data were
  not changed by this repair. The separately edited Android version settings
  were preserved, outside this change's implementation scope.

Evidence: gameplay logs under
`C:/Users/LUQMAN/AppData/Local/Temp/tidesworn-tests-3b4a249d4436485c9d0297470d59ac5d/`;
successful import under
`C:/Users/LUQMAN/AppData/Local/Temp/tidesworn-tests-710e5b3fb6914267a9007d852c6525bc/`.
Focused logs and captures are under
`C:/Users/LUQMAN/AppData/Local/Temp/besut-progression-fixes-e8530d55d1544360a8f89421ec5422e7/`:
`twilight_test-4ccd739afa8a4eabb848e9cff14ab905/` (1280x720) and
`twilight_test-54caefdaa30347e78e30c02147856b50/` (832x480).

This document is the acceptance contract for automated agents and human
reviewers working on **Save The World - Tidesworn** in Godot 4.x.

## Required commands

Run from `GAME_COMP_RPG-Godot/`:

```sh
# Safe Linux gate. Uses a fresh XDG_DATA_HOME, verifies user:// before deletion,
# enforces a timeout and inspects errors as well as exit status.
./tools/test_isolated.sh

# Import/parse in separate temporary user data.
review_dir=$(mktemp -d /tmp/tidesworn-review-XXXXXXXX)
XDG_DATA_HOME="$review_dir/userdata" timeout 90 godot --headless --path . --editor --quit
XDG_DATA_HOME="$review_dir/userdata" TIDESWORN_TEST_ROOT="$review_dir" timeout 180 godot --path . res://tools/visual_review.tscn -- --shots "$review_dir/shots"

# Every rendered motion frame (AVI), plus per-physics-tick position samples.
XDG_DATA_HOME="$review_dir/movie-userdata" TIDESWORN_TEST_ROOT="$review_dir" timeout 180 godot --path . --write-movie "$review_dir/motion.avi" --fixed-fps 60 res://tools/motion_review.tscn -- --samples "$review_dir/motion.json"
```

On Windows, run `powershell -File tools/test_isolated.ps1 -Godot <absolute-console-exe>`.
Use `-ImportOnly` for the import pass. This wrapper backs up the current save,
isolates APPDATA/LOCALAPPDATA, enforces a timeout and checks the full output.
The scene refuses destructive operations unless its actual user data directory
is inside the temporary test root.
Use `-VisualReview` to render `tools/forest_review.tscn` at 1280x720. It checks
an NPC's real approach to a fire and replanting, then captures fire, water,
sapling, growth, maturity, devastation and the game-over panel in the temporary
test directory. Any host certificate-store `ERROR:` still fails the wrapper;
a passing gameplay summary alone is not a clean overall gate.
Use `-VisualReview -Review village` for the village expansion review: it checks
builder repair state, a resident entering shelter, then an actual
sea urchin destroying that shelter and defeating its exposed occupant. It also
captures the first mission, named shops and water-keeper hiring.
Use `-VisualReview -Review interaction` for actual mouse/touch shop opening, tutorial spotlight targets, house level preview buttons, manual pet turns, night/dawn and the nearby free repair action.

Forest restoration verification (2026-10-23, native Godot 4.7.2): the acceptance
scene reported **430 checks, PASS** in verified temporary Windows user data.
The rendered forest review completed all seven captures, including an NPC
walking to water and replant a tree. Captures were inspected at 1280x720.
The host emitted `ERROR: Failed to read the root certificate store`, so this
is **not a clean overall gate**. The sandbox also denied reading the live save
for backup; no live-save writes or restoration were attempted. The Windows
wrapper requires a successful backup before starting when a live save exists.

Historical village expansion verification, before free repairs and the day/night cycle (2026-10-23, native Godot 4.7.2): the updated
acceptance scene reported **482 checks, PASS**, including the stationary-house
attack regression, recruitment, all repair plans, shelter protection/loss and
persistence. `village_review.tscn` reported **PASS** after real worker travel,
timed repairs and a sea urchin destroying a shelter and killing the exposed
resident. Eight 1280x720 captures were inspected. All test saves used verified
temporary user data. The same host certificate-store error remains, so the
strict wrapper still fails; this is not a clean overall gate.

An agent must not declare success when the suite reports a failure, when the
editor import reports `SCRIPT ERROR`/warnings, or when it has not inspected the
new screenshots at 1280×720.

Historical day/night and interaction verification: the isolated acceptance scene reported **494 checks, PASS**. The native interaction review exercised actual mouse/touch shop opening, exact tutorial targets, all house preview buttons, idle/manual pet turns, visible night/dawn and free nearby repairs. The host certificate-store ERROR prevented a clean overall gate on that Windows host.

Combined Creative Studio and gameplay merge verification (2026-10-24, Linux,
Godot 4.7.2): `./tools/test_isolated.sh` reported **524 checks, PASS**, exit 0,
with no `[FAIL]`, `SCRIPT ERROR` or `ERROR:` output. The isolated Creative
Studio workflow also passed **27 checks, 0 failures** and its separate runtime
restart. Both feature sets remain covered by the combined gate.
The rendered forest, village, interaction and shop-close reviews all reported
PASS and exited 0 without failure/error markers. Screenshots were inspected,
including the tutorial focus, fire/water/growth lifecycle, night/dawn, shelter
loss, house previews and the pet-shop Close button at 1280x720 and 832x480.

All five supplied pet battle backgrounds are installed under assets/pet_battles, with one distinct path per duel in PetBattleDB. The supplied GIF is retained and its first frame is converted to PNG for Godot. Native captures verify all five backdrops.

## Acceptance checks

### 1. HUD and NPC presentation
- No `Label` child is attached to `Resident`, `ShopNPC` or `CoastalGuard`.
- `GameHUD` has no toast container and `show_toast()` creates no UI.
- Important events remain visible through persistent HUD panels and the purple question-mark mission NPC.
- Player and pet XP bars exist and their maxima match the next-level thresholds.

### 2. Two battle portals
- Exactly two nodes belong to the `battle_portal` group.
- One has `gate_kind == "monster"` and one has `gate_kind == "pet"`.
- Their positions have the same north-path Y and are less than 10 world units
  apart (side by side).
- The monster gate opens `PortalPanel`; the pet gate opens `PetBattlePanel`.

### 3. Pet tournament
- `PetBattleDB.ordered_ids()` returns at least five levels.
- Every level defines a positive opponent HP, opponent pet, damage,
  pet-level requirement and Gold/pet-XP rewards.
- Only the first duel is unlocked initially; each win unlocks the next.
- The active pet's real level and stats are used.
- A duel shows two living combatants and two health bars.
- Each pet has three powers: **Serang**, **Perisai** and **Kuasa Khas**, with separate 2/5/8-second cooldowns.
- Both pets wait indefinitely for an explicit player choice. An empty choice cannot resolve a turn, even after the former timeout.
- An available power resolves the player action first, followed by one enemy reply. The next turn waits for player input. Powers on cooldown cannot be selected; an enemy with all powers cooling down waits. The old countdown is hidden.
- Attacks create scratch/punch impact nodes; Defend creates a shield effect.
- A win records the clear, grants Gold and pet XP, unlocks the next duel and
  raises the active companion's level by at least one.
- A loss or forfeit grants no clear or level.

### 4. Pet progression and shop
- Pet Shop close repair verification (2026-10-24): the full scene reported
  490 checks, PASS. Native `tools/shop_close_review.tscn` also clicked Close
  after scrolling at 1280x720 and 832x480 with all purchasable pets owned,
  verified movement was restored and checked immediate reopen/close. Both
  captures were inspected. The existing Windows certificate-store error still
  prevents a clean overall gate; saves were verified isolated temporary data.
- With every purchasable pet owned, the Pet Shop's Close button remains inside
  both 1280x720 and 832x480 viewports. Owned-pet actions sit below each preview,
  and the card grid adapts to available width without sideways scrolling.
- Clicking Close after scrolling dismisses the panel and restores movement.
  Reopening and immediately closing cannot use freed previews or rebuild a
  hidden shop. Modal frames also refit when their viewport is resized.
- `Pet Food` is a `pet` shop item with a positive Gold price.
- Buying and feeding it consumes one item and increases pet XP.
- Player XP and pet XP bars update after combat and feeding.
- Pet levels and duel clears survive save/load.

### 5. Protected forest and monster behaviour
- The `forest_tree` group contains at least 60 living trees.
- Every mature tree is a `ForestTree` and is also a `settlement_target`.
- Every tree has independent HP and persistent health.
- `take_attack_damage()` reduces tree HP, increments feedback and plays VFX silently for fire attacks. Physical impacts retain SFX only while the tree is not burning.
- Fire monsters ignite mature trees; flames deal ongoing damage and remain
  visible at low effects quality and with reduced motion.
- Zero HP makes the tree fall, disappear and release trunk collision.
- One blue water keeper starts a new journey; Gold recruits up to five.
  Recruitment costs 80/140/200 Gold for additional keepers, rejects insufficient
  funds and duplicate purchases at the cap, and can replace a dead keeper.
  Their reduced power heals 5 HP every 1.25 seconds. They walk to fires, channel
  visible water and restore HP; full recovery extinguishes the fire. Green planters
  walk to fallen trees and spend two seconds planting replacements. Blue NPCs also fire damaging water projectiles at fire monsters.
- A replacement grows over 30 seconds of active lobby time, shows growth
  progress and cannot be targeted, damaged or ignited until mature. Its remaining
  growth time survives saves and world reconstruction; time away freezes growth.
- With no mature trees, any planted sapling still prevents game over.
- No mature trees and no planted saplings -> `GameState.game_over_active`.
- Game over animates the ground to dry orange, sea to dark green and reveals
  stranded dead fish/crabs on sand before the locked panel appears. Reduced
  motion keeps the same end state with a short fade and no camera movement.
- Game Over shows a locked panel and returns to title without a Continue save.
- At least 24 `forest_monsters` populate the woodland; raids can raise the cap to 30.
- Fire monsters choose mature trees, nearby players or exposed residents. They
  deal real damage to players and residents and do not use the forest charge.
- Each journey begins with a peaceful day. Day and night each last exactly 180 seconds; the HUD counts down. Only night creates new fire monsters or sea urchins, including beach and raid paths. Existing monsters continue attacking after sunrise. Each night replenishes the baseline population once, without duplicating surviving monsters.
- Clock phase and living home monster position/HP survive save/load and returning from a dungeon; no wave is created merely by reopening the village.
- Generated physical `tree_hit` and `aggro` sounds must exist in `Sfx`; fire attacks and burning create no tree audio.

### 6. Lively village and ruins
- At least seven `resident_house` nodes exist.
- At least three `ruin_house` nodes include abandoned, damaged and destroyed art.
- At least six `garden` nodes exist. At least four authored flower beds frame
  selected household plots; the shipped layout contains five. Random flower
  scatter is removed. Each bed must keep roads, entrances and neighbouring
  building footprints clear.
- At least two `horses` nodes exist and horse art generates.
- At least nine editable `decoration` placeables exist.
- The settlement editor still drags, clamps, saves and reloads layout.

### 7. Sea cleaning
- The coastal guard catches drifting rubbish.
- Each catch awards exactly +1 Gold and increments `GameState.data.sea_cleaned`.
- Beached rubbish remains on sand as a distance-checked Pick Up interaction;
  reaching sand grants nothing, and manual collection pays +1 Gold exactly once.
- Sea urchins damage mature trees without igniting them, fences, intact houses
  and exposed residents, as well as nearby players. Saplings remain immune.
- Sea-cleaning progress survives save/load.

### 8. Construction Shop and existing contracts
- A dedicated `shop_house` construction stall and Bram's `ShopNPC` exist.
- Clicking/touching any stall opens its shop directly, including Bram's Construction Shop. Keyboard interaction remains available. Touches used by the settlement editor or an open modal do not open a shop.
- The panel exposes clickable Levels 1-5. Each changes the design preview without spending diamonds or changing the owned house. Confirm Upgrade purchases only the next level, with diamonds.
- The cottage, seven resident homes and four fence runs have stable IDs and
  separate persistent HP. Destroyed structures collapse and release collision.
- One orange builder starts each journey. They choose separate damaged structures, walk to them and work for ten seconds in daylight. Nighttime pauses progress; unfinished repair time persists across saves. Extra builders cost Gold at the Worker Shop. Repair restores HP, appearance, collision and shelter protection.
- Residents walk into intact houses when sea urchins approach or a raid starts.
  Sheltered residents cannot be damaged; a destroyed shelter exposes them.
  Exposed residents can die, leave targeting and remain dead after save/load.
- Merchants stand behind their stall counter, interact from outside and have no
  personal name labels. Each of the five shops has its own shop-name sign.
- Title reads `SAVE THE WORLD`; credit names Qayyim, Farhan and Ayiz.
- The recovery ward heals at `GameState.sleep_recovery_seconds()` - the
  HouseDB rate for the current cottage level (10 s at Level 1 down to 2 s at
  Level 5), matching the home interior and Construction Shop panel. The old
  hardcoded 8.0 s ward clock is gone.
- Three weapons, ten monster portals, boss ability variety, Android touch
  controls, auto-loot, pet support, emergency defence, defeat/recovery and
  the three-minute day/night cycle remain intact.

### 9. Guidance, dashboard and menus
- No bottom mission notification panel or `MissionArrow` widgets are built.
  `MissionPath` draws dashed ground arrows along obstacle-aware routes in the
  lobby and dungeon, pointing to one current objective.
- Seven daytime lessons teach movement, gathering, shopping, Pack, workers, housing and pet feeding; three nighttime lessons teach fire combat, portals and a boss. Switching phase selects that phase’s next unfinished lesson. Only the current lesson’s action advances progress. Saved completed event IDs resume lessons after Continue, including migration from old numeric progress. Menu can show hidden mission tips again.
- A non-blocking spotlight dims everything except the current action, draws a gold arrow and follows changing UI layout. It highlights the joystick, a shop, the exact potion Buy button, Pack, or Attack. The tips panel moves aside from the highlighted target.
- The player owns a `PlayerVitalHud` that draws Health, XP and level above the
  player's head. Mana is removed.
- The top-right `MenuButton` opens the in-game menu.
- Settings opens from the menu.
- GUI scale persists in GameSettings, applies to independently anchored HUD elements
  and leaves HUDRoot and camera zoom unchanged. No top-right VITALS panel remains.
- Control X/Y/size changes apply immediately to the touch controls and reset to
  the default responsive layout.

### 10. Special NPC
- A yellow `UniszaStudent` belongs to the `special_npc` group.
- Interaction opens `DialoguePanel`.
- The box includes the exact lines “Welcome to Unisza” and “We are students from
  Unisza.”

## Visual & feel overhaul checks

These rules landed with the `visual-overhaul` branch and are covered by the
suite (`_test_visual_overhaul_contracts` and updated attack waits):

- **Attack timing rule change:** melee and bow damage lands on the ACTIVE
  frame of the AttackDB chain (anticipation -> active -> recovery), not on the
  button press. Sword wind-up 0.06 s, hammer 0.20 s, bow draw 0.12 s; the
  suite waits for the hit frame instead of checking on the same frame.
  `attack_cooldown` restarts at each hit frame, so per-second damage is
  unchanged.
- The Attack touch icon matches the active hero's weapon style for all three
  heroes, and the Use icon is context-sensitive (talk / door / bed / gather).
- The 32 px icon set generates for weapons, interact variants and currencies.
- Portal art (frame, sealed variant, 8 swirl frames) is generated from the
  PortalDB theme of every portal - ten distinct themes, no portal-id special
  cases.
- The companion upgrade price is read from `GameState.pet_upgrade_cost()`
  (single source; formula unchanged).
- `GameSettings` sanitises the new `effects_quality` (low/med/high) and
  `reduce_motion` keys.
- Shops refresh in place on `data_changed`: the pet shop keeps its scroll
  position across repeated updates (the sea-cleaning gold drip no longer
  resets browsing).
- Enemy attacks telegraph for at least 0.42 s (ground decal + wind-up pose)
  and deal damage only on the active frame; wind-ups can be interrupted.
- Quality tiers: `low` drops ambient life, wind sway and hit-stop; reduce
  motion disables shake, look-ahead and bending.

## Visual repair regressions

`_test_visual_repairs()` verifies tree sprite/body ownership, local/world placement
(including the small hit shake), independent damage feedback, persistent HP and
loaded-fallen collision; full water-mask coverage and eastern bounds; absence of
star placeholders; turtle sand placement; BESUT lettering metadata/art; no VITALS
and preserved PlayerVitalHud; all three quality tiers with Reduce Motion; camera
zoom limits, isotropy, interpolation, file persistence and world inheritance;
GUI min/default/max, independent scale and viewport bounds; fractional player
motion, normalized diagonals, braking, far-behind pet catch-up, enemy chase,
projectile speed and settling loot; repeated shopping state progression, busy
counter exclusion, reservation cleanup and isolated player gold/inventory.

The VITALS removal intentionally replaces its obsolete segmented-panel checks
with checks for its absence and the preserved PlayerVitalHud. Gameplay assertions
for health, health potions, pet support, combat, tree falling and game-over remain.

Fresh review captures add coast west/turtle/east, BESUT, eastern forest, all six
quality/motion combinations, GUI 75/100/130% at 1280×720 and 832×480, Settings at
both sizes, zoom 28/38/64, all shopping states, and a movement strip. Inspect actual
images and consecutive movie frames; file existence is not a visual check.

## Deep audit regressions

`DeepAuditChecks.run()` is part of the acceptance gate. It exercises joystick
local/viewport coordinate handling; input release on hide/removal; actual-size
layout reset; route invalidation and collision-clear detours; strict shop endpoint
accessibility and fear cancellation; shared actor depth; live dungeon quality
changes; VFX lifetime during deferred deletion; effects-independent simulation;
persisted GUI migration; world-scaled outlines; and home-death recovery without
inventory/currency/progression loss or duplicate transitions.

`tools/deep_audit_test.tscn` additionally checks native GUI input dispatch and
44-physical-pixel control sizes at 1280×720, 832×468 and 832×480 with GUI
75/100/130%. Resizing alone must refresh these sizes. Home defeat uses critical
HP and the existing recovery ward; it does not discard expedition loot
or replace the forest-loss game-over rule. The loot test must touch all drops,
including the randomly generated extra gem, before requiring an empty floor.

All mutating review scenes require verified `TIDESWORN_TEST_ROOT` plus isolated
`XDG_DATA_HOME`. The safe runner must reject a zero-exit engine that never prints
its PASS summary. See [DEEP_AUDIT_REPORT.md](DEEP_AUDIT_REPORT.md) for current
results, negative probes and visual evidence.

## Regression rules for agents

1. **Do not reintroduce timed toast pop-ups or floating NPC names.** Use the HUD,
   mission guide, permanent prompt or modals for state.
2. **Do not use fixed screen coordinates for new full-screen UI.** Controls must
   remain readable at 832×480 and 1280×720.
3. **Keep all rewards atomic and non-negative.** Route Gold, items and XP through
   `GameState`.
4. **Persist new progression.** Add fields to `_make_default()`, sanitize them in
   `_sanitize()`, and cover them in the save/load test.
5. **Use typed locals** where Godot's warnings-as-errors would reject inference.
6. **Update the suite and this document** when an acceptance rule changes. The
   README, QA report and capture list must stay in sync.
7. **Keep test data isolated and evidence outside the repository.** The suite deletes
   `user://tidesworn_save.json` at the start and end; preserve requested review logs/captures.

## Visual review checklist

Inspect these captures:

- `tide_title.png` - boot menu, harbour, Start Game and creator credit
- `tide_heroes.png` - separate hero-selection page after Start Game
- `tide_lobby.png` - XP bars, mission arrows, Pack/Build, lively village
- `tide_menu.png`, `tide_settings.png` - menu and settings
- `tide_dialogue.png` - exact Unisza dialogue
- `tide_lobby_portal.png` - paired Monster/Pet gates
- `tide_pet_battles.png` - five-level tournament
- `tide_pet_duel.png` - 1v1 arena waiting for an explicit player choice
- `tide_pet_resolution.png` - historical arena capture; current turns alternate
- `tide_pet_shop.png` - Pet Food and Feed controls
- `tide_house.png` - Construction Shop Level 1-5 progression
- `tide_forest.png` - dense protected woodland and tree HP impacts
- `tide_ruins.png` - abandoned/damaged/destroyed houses
- `tide_build.png` - settlement editor
- `tide_settlement_attack.png` - emergency HUD and raid
- `tide_recovery.png` - recovery ward
- `tide_game_over.png` - locked all-trees-destroyed game-over screen

No NPC name labels or toast banners should be visible in any capture.

## Creative Studio regressions

`CreativeChecks.run()` adds palette/cache, transparent pixel editing/history,
frame-duration PNG round-trip, registry atlas/diagnostics, authored map persistence,
real collision/navigation, TileMapLayer batching, imported runtime art, stable
base-tree movement, action priority/cleanup/Reduce Motion and velocity-driven
walk-cycle checks. The verified revamp gate is **438 checks, PASS**; counts remain
data-driven.

`./tools/test_creative_editor.sh` is the authoring gate. It copies the entire source
into a verified temporary root without `.godot`, imports afresh, launches the actual
editor, tests 27 native-tool workflow checks, then starts a second runtime process
to verify saved assets, edited PNG colours, the authored map and water collision.
It never imports test art into the normal project. A GUI display is provided with
Xvfb. Review emitted PNGs as well as logs; passing model checks are not a visual
review. See `docs/CREATIVE_REVAMP_QA.md` and the workflow guides.

## Monsoon Afterglow regression contract

`MonsoonChecks.run` is included in the isolated gameplay gate. It verifies every
forest ID/order/position/max-HP association against the clean main snapshot;
five unclipped tree silhouettes; exact crown/trunk pixel reconstruction; five
cottage frames/window masks; continuous presentation at day/night boundaries;
clock ownership; old palette fallback/cache invalidation; unchanged imported
pixels; imported cottage window ownership; repeated terrain reuse; and static
water under each quality tier with Reduce Motion. Existing gameplay, movement,
coastline, save/load and accessibility checks remain in the same gate.

`./tools/review_monsoon.sh /absolute/output` uses verified temporary user data
and the actual GL Compatibility renderer. It records scene/camera/time/settings
in a manifest and measures cold/cached construction plus High/Medium/Low frame
intervals, draw calls and texture memory. Combat fixtures require actual damage
and the water-keeper fixture records real watering. Read the log and inspect the
PNGs; an exit code alone is insufficient. The harness freezes residents/enemies
for equivalent environmental framing and temporarily slows combat for captures.
Its frame statistics describe that fixture, not a mobile or combat stress test.

Results and limitations are recorded in [the delivery report](MONSOON_AFTERGLOW_REPORT.md).

The Monsoon delivery adds 38 checks to the protected main baseline. These also
cover legacy `authored_tree` and forest foliage overrides, static window ownership
for imported cottages, and immediate pause/resume of the existing boat tween
when quality or Reduce Motion changes.

Final Monsoon verification (2026-10-24, Linux Godot 4.7.2): **562 checks, PASS**,
exit 0, with no failure/script/error markers. Native deep audit: **63 checks,
0 failures**. Fresh-copy editor: **27 checks, 0 failures**, separate runtime
restart PASS. The real-renderer tour captures 26 paired scenarios, with verified
coastal/dungeon damage and actual watering. Full measurements and limits are in
`MONSOON_AFTERGLOW_REPORT.md`.

### Coordinated village layout (2026-10-24)

`WorldChecks.run` is part of the isolated gameplay gate. The incoming main
snapshot has 562 checks; the spatial overhaul currently passes 720 checks.
The spatial checks use real World2D shape overlap/cast queries, exact-goal
ResidentRoutes planning, and source resources. They cover:

- Required canonical landmarks, unique IDs within each namespace, map bounds,
  connected route graph, and minimum road widths.
- Every important destination's player-sized approach and exact reachability;
  every painted route's continuous centreline clearance (including jetty planks).
- Shore/sea collision agreement, grounded turtle, sea immediately beyond the
  deck, and safe emergency/coastal/forest spawn resolution.
- Authored Water and water material collision, land-paint clipping against
  existing sea, and footprint conflicts across routes away from endpoints.
- Player layout above developer overrides above defaults; actual merchant,
  collider, workspace and recovery ownership after a source-map/save reload.
- Every original tree ID/position across customized buildings and decoration
  seed changes, plus MonsoonChecks' unchanged maximum-HP and order fixture.
- Deterministic customized re-entry, unchanged-layout terrain reuse, independent
  source copies, and schema-default loading of old maps.

Flower coverage is now a selective border-presence rule, with an additional
reservation-clearance assertion. A large minimum flower count was inappropriate
for keeping roads and entrances quiet; decoration quantity is not the design goal.

`./tools/test_creative_editor.sh` exercises 84 editor checks in a disposable
source copy, including spatial anchor dragging, native undo/redo, route width,
zone vertex edits, overlays, saving and a separate runtime restart. The restart
checks that edited service coordinates and route width actually load in gameplay.

`./tools/review_world.sh /absolute/output` captures the paired real-renderer tour
and measures cold/cached builds, frame intervals, node/draw/texture counters,
physics monitors, eight real path queries and an active-resident workload.
Run this harness unchanged against each ref, sequentially without concurrent
imports/tests. Require `WORLD_REVIEW PASS`, exit 0 and no `[FAIL]`, `SCRIPT ERROR`
or `ERROR:` markers. Day/night, effects tiers, Reduce Motion, zoom, small screens,
real movement frames and a damage-asserted combat encounter are included.
See WORLD_OVERHAUL_REPORT.md for measured evidence and limits.

## Kampung composition and spatial ownership

`KampungChecks` runs inside the isolated gameplay gate before `WorldChecks`.
It checks full building-plot overlap and minimum separation, exact player-sized work/animal/gathering
points and routes, inherited routines for older maps, independent deep copies,
undo snapshots and bounded artwork caches. All twelve ordinary residents also
walk to a real authored destination under physics: every step is bounded by
speed × delta, and arrival is required. A settlement completion hook moves the
carpenter's workpoints without teleporting the worker; saved independent prop
positions keep precedence over owner-local defaults.

District checks require five ordinary homes in the western residential polygon,
all five shops in the market, and residential/shop/garden positions inside their
declared districts. Active building plots (including portals) require 1.8 units
of edge clearance; pairs involving ruins require 1.0. Every authored accessory
and default movable decoration must clear road ribbons, approach rectangles and
neighbouring building footprints. Negative fixtures reject non-overlapping but
cramped buildings and an accessory in the arrival court. Managed flower beds
use these ground-footprint checks because maintained yards intentionally reserve
their surroundings against wild plants. Independent saved prop positions still win.

`tools/kampung_probe.tscn` is the focused spatial subset; run only with verified
`TIDESWORN_TEST_ROOT` and isolated `XDG_DATA_HOME`. It never substitutes for the
full gameplay gate. `./tools/test_creative_editor.sh` exercises activity-point
and scenery-offset controls, native undo/redo, source save/reimport and restart
in a disposable checkout. `./tools/review_world.sh /absolute/output` records
paired actual gameplay fixtures, a diagnostic overview, a zoom-64 forest view,
night districts, settings, movement, combat and software-renderer measurements.
See [DISTRICT_SPACING_REPORT.md](DISTRICT_SPACING_REPORT.md) for current results
and limits, and [KAMPUNG_REDESIGN.md](KAMPUNG_REDESIGN.md) for the first pass.

## Direct Map Studio editing

The native editor gate additionally checks direct mouse-event building movement,
an uncommitted outline preview, Escape cancellation, numeric positions, precise
keyboard nudges, Fit/Frame and canvas-only mode. It tests searchable thumbnail
placement, object duplication with distinct IDs, deletion/undo, scene filtering,
stable original-tree overrides, road bend insertion/removal, endpoint editing,
district vertex movement and a district-with-contents transaction. Workpoint
movement/add/remove, undoable layer locks/visibility, protected identity deletion,
actionable validation, save-state dirty tracking and stale document undo guards
are also covered. Paint cancellation and releasing Space before a pan's mouse
button are actual input-handler regressions.

The independently saved `editor_workbench.tres` is opened in a second gameplay
restart after the original `editor_workflow.tres` restart. The added restart checks
the actual shop owner position, new commons and road, new district vertices and
blend values, workpoint ownership, and the placed bench in the runtime scene.
Both restart markers must say PASS. These files are created only in the disposable
test project. Pixel/asset/palette/plugin recovery checks remain part of the gate.

The gameplay gate has five presentation regressions: district feather and tint
invalidate terrain caches, broader blending measurably softens generated pixels,
road feather invalidates the cache, and softened road-edge pixels keep the same
navigation ribbon. The unchanged default full-RGBA bake comparison still passes.
Current evidence and limits: [MAP_STUDIO_UPGRADE.md](MAP_STUDIO_UPGRADE.md).


## PB expansion acceptance (2026-10-24)

The earlier PB expansion run reported **496 checks, PASS, exit 0**. Its separate PB suite reported **56 checks, PASS, exit 0**. The latest HUD/battle results are recorded below. The native PB review reports **PASS, exit 0**; its fourteen checks use actual mouse/touch events and real-time construction. Captures were inspected at 1280x720. All runs use separate temporary user data and leave live progress untouched.

Commands:

```powershell
powershell -File tools/test_isolated.ps1 -Godot <console-exe>
powershell -File tools/test_pb_isolated.ps1 -Godot <console-exe>
powershell -File tools/test_pb_isolated.ps1 -Godot <console-exe> -Native -Scene res://tools/pb_review.tscn
```

- PB (Protect BESUT) replaces the title; the creator credit is permanent at the bottom. The old Permanent daytime footer is absent.
- The boot menu hides hero selection until **Start Game**. The road then slides
  in from the right while the menu leaves to the left; Back/Escape reverses the
  travel and Reduce Motion swaps instantly. The transition changes state on the
  click frame and never fades. Hero cards only
  preview a choice; **Begin Journey** starts it. Back/Escape preserves the
  pending choice without creating a world or changing saved progress.
- **Continue Journey** shows the saved hero, level and destination and resumes
  the village or active dungeon directly. A missing/unreadable save keeps the
  menu usable, displays inline feedback and leaves the file untouched.
- Starting over with an existing save requires **Replace Save & Begin**.
  **Keep Saved Journey** receives initial keyboard focus. Cancellation preserves
  the exact save bytes; repeat handoffs cannot start duplicate journeys.
- Title Settings, How to Play and Credits have mouse/touch and keyboard paths.
  Overlay focus stays within the overlay and Escape restores the page. Title
  settings persist through GameSettings without requiring a player save.
- At 1280x720 and 832x480 every complete hero card and both journey actions fit
  on screen. Narrow layouts stack hero cards inside a scrollable region while
  retaining Back/Begin; compact cards keep lock state and drop the long rescue
  paragraph (the lock overlay still explains it). Low/Reduce Motion retains the
  complete static harbour.

The title regressions are included through `TitleChecks` in the isolated game
gate. For real-renderer input and screenshot verification, run:

```sh
./tools/review_title.sh /absolute/output
```

This wrapper isolates player data, exercises actual mouse/touch/keyboard input,
and rejects script errors, failure markers and message-queue overflow even if
the scene prints PASS. Captures include the fresh/saved menu, every hero state,
settings/guide/credits, replacement confirmation, compact/narrow layouts and
failed Continue. See [TITLE_SCREEN_REDESIGN.md](TITLE_SCREEN_REDESIGN.md).

- Orange builders, blue water fighters, green planters and black swordsmen have distinct appearances and jobs. Each starts with one; hiring and worker deaths survive saves. Existing Continue saves keep their workers. Ordinary residents shelter instead of performing specialist combat.
- Every house, including former ruins, has persistent HP and a dormant rooftop gun mount. Buy one gun per intact house with Gold. The central house tier controls houses, fences, purchased gun speed and worker baseline. One diamond upgrade is charged once. Guns fire every 0.6/0.5/0.4/0.3/0.2 seconds and cannot fire from a destroyed house.
- Only the central house is enterable. Touching it opens a furnished interior, brings the companion inside and restores health using the current house tier. There is no mattress interaction. The doorway returns player and pet outside; mandatory post-defeat recovery must finish first.
- Two clickable portals sit inside the two mouths of a rocky hill. The integrated
  village resolves them from its authored sanctuary anchors; source-era fixed
  far-north coordinates do not override the current layout. Clicking opens their
  respective monster/tournament selector.
- The following pet attacks nearby enemies and carries its HP overhead. Boss HP is overhead too; the former screen boss bar is removed.
- Dungeon enemies enter a persistent chase immediately. Touching or damaging the boss alerts every survivor, with routes around dungeon obstacles.
- A clickable purple NPC with a question mark opens the current mission. The top Journal panel is removed; tutorial arrows remain available.
- Each pet fight uses a different full-arena supplied background without combatant boxes. Neither pet acts until an available power is chosen; the player acts first, followed by one enemy reply. The supplied GIF is retained and its first frame is used as the Godot background.

## HUD, phase tutorial and three-power duels (2026-10-24)

The earlier HUD/battle update passed **494 checks, exit 0**. The focused PB suite passes **86 checks, exit 0**. The native HUD/battle review passes **22 checks, exit 0**, using actual touch events at 1280×720 and 832×480. The separate native PB review passes fourteen checks, including furnished home and all five arena backgrounds. Logs contain no FAIL, SCRIPT ERROR or ERROR entries. All runs use temporary user data and preserve live progress.

```powershell
powershell -File tools/test_pb_isolated.ps1 -Godot <console-exe> -Native -Scene res://tools/hud_battle_review.tscn
```

- Two standalone portals occupy the far northern edge, with both clickable gates accessible.
- Battles fill the arena with one image; both pets have three separate cooldowns. Player action precedes the enemy reply, and idle player turns never auto-resolve.
- Only the day/night clock and Menu occupy the upper HUD. Player HP/XP and level appear overhead; pet HP/XP appear overhead. Gold and diamond balances appear in shops.
- Health-potion shortcuts are absent; Pack provides health-potion actions beside the joystick. Menu provides Build settlement and Finish building.
- The home has four visible accessories: chest, wardrobe, weapon rack and pet bed.
- New journeys grant exactly one builder, water keeper, planter and swordsman; additional workers are bought. Existing worker ownership survives Continue.
- Daytime and nighttime tutorials switch automatically and preserve each phase’s unfinished lessons.

## Village tiers, loading and picture guide (2026-10-24)

The full suite passes **494 checks, exit 0**. The focused headless scene and native touch review each pass **99 checks, exit 0**, with no FAIL, SCRIPT ERROR or ERROR entries. Native captures were inspected at 1280×720 and 832×480, including separate boss-name/HP text and readable night tutorial arrows. The retained PB suite passes 86 checks, and the native PB regression review passes fourteen checks. All runs use temporary user data.

Run the full suite, then the focused scene with and without a renderer. The focused native scene uses real touch events at 1280×720 and 832×480; the headless variant activates button signals because no display is present.

```powershell
powershell -File tools/test_pb_isolated.ps1 -Godot <console-exe> -Scene res://tools/tide_test.tscn
powershell -File tools/test_pb_isolated.ps1 -Godot <console-exe> -Scene res://tools/village_upgrade_test.tscn
powershell -File tools/test_pb_isolated.ps1 -Godot <console-exe> -Native -Scene res://tools/village_upgrade_test.tscn
```

- New Journey, Continue, portal travel, home entry/exit and return to title show a loading cover and fade. Current and newly built players stay locked until the cover leaves. Modals and pet arenas fade in.
- BESUT Field Guide opens from Menu. Its NPC pages, five monster pages and three active boss pages explain actions using sprites and visual symbols, with character names as headings. It has no explanatory paragraphs. Page turn and Close work at both landscape sizes.
- A new journey has one worker per specialist role. Main-house Levels 2-5 provide a baseline of 2-5 of each role. Hiring can add workers beyond that baseline within role limits, and ownership/deaths persist.
- One main-house upgrade charges once and synchronizes the village house, archer-hut and fence tiers. Previews show the house, hut, fence and baseline worker count for each level. A ruined main house must be repaired before upgrading.
- Purchased rooftop machine guns replace archer huts. Yellow bullets damage fire monsters and sea urchins. Missing, ruined, unaffordable and duplicate purchases fail without charging. Ownership survives save/load.
- Fences progress from wood to wood with a stone base, stone walls, fortified posts and battlements. Changing level refreshes existing fence sprites and survives save/load.
- Night lessons retain the pointer without an extra dark overlay. The level-one portal is the only portal shown during that training. Other bosses cannot complete its final lesson; defeating Shadow & Chaos Fiend ends that tutorial. All three active bosses show their distinct names above their HP.
- Continue after finishing daytime lessons retains the unfinished nighttime tutorial and activates it at the next night. Build remains in Menu.


## Combat and guardian update (2026-10-24)

The isolated gameplay gate also runs tools/combat_revamp_checks.gd:

- Adam (Malay male, sword), Mei Ling (Chinese female, bow) and Arjun (Indian male, scythe) have distinct portraits and weapon silhouettes with basic attacks only. Old qayyim/farhan/ayiz save IDs migrate to adam/arjun/mei_ling; inventory, progression and village unlocks remain. Legacy hammer item IDs are retained as scythes so existing equipment is preserved.
- The HUD keeps one basic-attack button, Use, Pack and joystick. Skill 1/2/3 buttons, keyboard actions, cooldowns and Settings rows are removed for every hero. Cancelling basic-attack touch releases its InputMap action.
- Every hero's basic attack still deals damage; arrows stop at world obstacles. Mana stats, overhead bars, character-selection MP values and mana potions are removed. Loading an older save removes retired mana fields, potions and skill control positions while preserving currency, equipment, health potions and active control customization. A second save/load keeps mana removed.
- Winning each of five pet duels recruits that named rival, unlocks its roster entry and spawns an invincible village guardian. Replays do not duplicate a guardian. Guardians path toward and damage both fire monsters and sea urchins near the settlement. Prior cleared duels recruit their rivals when an older save is loaded.
- The main-house interior has an interactable HouseBed using the existing house-tier recovery time. The automatic defeat-recovery ward remains governed by its existing rules.
- All three active portals have intimidating named bosses, a special power, colliding pillars and six repeating rune traps. Rune traps warn for one second, damage for 0.65 seconds and then become safe until the next cycle. Higher portal levels increase trap damage and shorten the cycle. Bosses activate at range after a 2.2-second arrival warning and use their existing pursuit pathfinder.
- Original procedural looping battle music starts for both monster portals and pet duels. World changes and closed/resolved pet duels stop it. The Master volume/mute controls also control music.
- Player-facing book, missions, pet duel controls/status and loading destinations are English. Creator credits retain the authors' names.

Verification results belong in docs/COMBAT_GUARDIANS_REPORT.md; a source edit is not a passing gate until stdout is clean and the isolated wrapper exits 0.

## Northern portal placement (2026-10-25)

- Both portal entrances remain side by side at the northern map edge: Monster (34.8, 6.3), Pet (41.2, 6.3). The cave artwork and its collision are removed; both portals retain full-size standalone frames.
- The portal court, sanctuary approach and stone district move with the gates; portal-owned lanterns and scenery retain their offsets. The north village gate remains connected to both entrances by clear player-sized routes.
- The default terrain bake is rebuilt and reimported after the source layout change. Existing forest identities, placement order and HP remain covered by the unchanged forest fixture.
- Player-owned settlement positions and progression remain authoritative; moving these fixed developer portals does not rewrite the player save.

Verified on Godot 4.7.2: isolated gameplay gate **993 checks, PASS, exit 0**; native world review **WORLD_REVIEW PASS, exit 0**. Both runs have no FAIL, SCRIPT ERROR or ERROR entries.

## Coastal and turtle journey update (2026-10-25)

The isolated gate also runs tools/coastal_checks.gd (focused scene: tools/coastal_test.tscn).

- Fire-monster impacts and burning mature trees are silent: no impact SFX or local fire audio player is created. Watering extinguishes fire silently; physical impacts retain their normal tree-hit sound only on unburned trees.
- Fire monsters and sea urchins can damage both the current living player and exposed residents. Sheltered/dead residents are excluded. Existing tree, sapling, structure and night-spawn rules remain. Player resolution must not retain a retiring world's player.
- Tall tree, house, shop and authored prop art fades to 25% while its opaque pixels cover the player, then restores. Collision, damage tints, windows and the forest fixture stay independent of this presentation effect.
- The full-width northern stone wall still blocks the map boundary. There is no cave sprite or hidden cave collider; ground behind the two standalone portals is accessible.
- Walking onto the indoor doorway automatically leaves the main house once recovery allows it. Duplicate/fading exits are guarded.
- Rubbish drifts from the water to sand and becomes a BeachRubbish interaction. Only a nearby, unlocked active player can collect it. Pick Up plays a net sweep and pays one cleanup Gold once. Guard catches retain their own one-Gold terminal path. Floating and beached populations are bounded.
- The yellow UNISZA ship is moored beside the walkable jetty with a distance-checked Board Ship interaction. It locks/releases world inputs, moves the ship and passenger automatically, and starts a loading fade when the ship reaches the western map boundary. Duplicate boarding is rejected.
- The ocean world owns its camera and two actions: Pick Up (E) for rubbish, Eat (F) for food. The player dives, a turtle approaches, and the player mounts automatically. Both touch buttons share the InputMap path. Food/rubbish drift faster with elapsed time, up to a bounded maximum.
- Correct rubbish gives +1 Gold once and shows the player's net animation. Correct food opens the turtle mouth and restores one turtle health, capped at five. Either wrong action costs one turtle health and gives no gold. Missed rubbish also costs one health; an empty action does not.
- Zero turtle health stops the run and offers Ride Again / Return to Shore. Retry clears old items and resets health/time/speed. Returning rebuilds the village with the player aboard the incoming ship. Controls remain locked until the ship docks and the player steps onto the jetty deck; only then are HUD, collision and movement restored. Ocean inputs are released. Cleanup Gold survives save/load; turtle-run state is transient.
- Native checks inject actual screen touches on Pick Up and Eat, and capture house/tree transparency, standalone portal/wall alignment, beach collection, ship sailing, diving, riding, net/eating animations and results.

Initial coastal verification: the isolated gameplay gate passed **1048 checks, PASS, exit 0**. Native focused runs at **1280×720 and 832×480** each pass **59 checks, exit 0**, including actual Pick Up/Eat screen touches. Final stdout/stderr are clean of FAIL, SCRIPT ERROR, ERROR and WARNING entries.

## Cave removal (2026-10-25)

- The village builds no TwinCaveHill sprite or CaveRockCollision body, and the unused cave-art generator is removed.
- Both portal anchors stay at the northern edge. Frames and swirls use their normal standalone size/placement; the tutorial refers to the left portal.
- NorthernBoundary retains the full-width stone wall and World collision. The former cave backs are clear, while the existing forest associations remain unchanged.
- The native coastal capture now shows standalone portals and the north wall.

Cave-removal verification: isolated gameplay gate **1049 checks, PASS, exit 0**; native 1280×720 feature review **60 checks, PASS, exit 0**. Logs contain no FAIL, SCRIPT ERROR or ERROR entries. The actual-renderer capture confirms both standalone portals with the northern boundary wall and no cave.

## Silent tree fire and UNISZA harbour return (2026-10-25)

- Fire attacks preserve tree damage/flames while requesting no impact or burning audio.
- The yellow hull carries original pixel UNISZA lettering and moors immediately beside the jetty.
- The ship stays opaque while carrying its passenger. The rider stands inside the deck beside the mast, with the near hull covering the legs. The passenger hull overlay hides after landing and ordinary scenery fading resumes.
- Return to Shore brings the player aboard an incoming ship, docks, then disembarks onto jetty_deck. Controls and collision resume only after landing. Duplicate boarding during arrival is rejected.
- Native screen-touch fixtures separate gestures across frames to avoid overlapping synthetic presses on slow renderers.

Current ship/fire verification: isolated gameplay gate **1055 checks, PASS, exit 0**; native 1280×720 and 832×480 focused runs each **66 checks, PASS, exit 0**, including occupied-ship opacity. The latest 1280×720 captures also verify the rider inside the deck with the near hull in front of the legs. Final logs are clear of FAIL, SCRIPT ERROR, ERROR and WARNING entries.

## Complete fire-combat silence (2026-10-25)

- Fire monsters request no alert, repeated windup, special-attack or defeat SFX. Other enemy kinds retain their cues.
- Player melee hits and rooftop-gun shots at fire monsters are silent while still dealing damage. Hits involving other enemy kinds retain their audio.
- Burning trees stay silent through burn ticks, fire hits, physical hits, watering and falling. Physical hits on unburned trees keep their usual cue.
- Coastal checks exercise real alert/windup states, player/resident damage, melee hits, defeat and ongoing burning. The full gate additionally verifies rooftop shots against both fire monsters and sea urchins.

Complete fire-silence verification: official Windows isolated gate (`tools/test_isolated.ps1`) **1073 checks, PASS, exit 0**; focused coastal audio/flow scene **76 checks, PASS, exit 0**. Both logs are clear of FAIL, SCRIPT ERROR, ERROR and WARNING entries.


## BESUT rescue campaign update (2026-10-25)

See [BESUT_STORY_CAMPAIGN.md](BESUT_STORY_CAMPAIGN.md) for the current story, sea rules and ownership. StoryChecks now runs in the isolated gameplay gate. Its focused scene is tools/story_test.tscn. The current turtle has three lives, starts at 2.5x speed, heals only from automatically collected nearby pink hearts, steers vertically and avoids moving bombs. Three 45-second routes lead to the Kraken/prison rescue. The final Monster Portal rescues Mei Ling; both friends defend BESUT and unlock the saved reunion ending. The minimap is restored, time is at the bottom, towers are purchased at the weapon shop, and real touch gestures cover NPC inspection and control dragging. Older assertions about no minimap, four controls excluding Menu, five turtle lives and healing food are superseded.

Final campaign verification: **1,114 checks, PASS, exit 0** in the complete isolated gameplay gate. Native 832×480 verification: **41 checks, PASS, exit 0**, including real screen touch and drag gestures, rendered book/tower-shop fixtures and both friend damage paths. Earlier native 1280×720 and 832×480 runs passed 39 checks before the two additional tower-refresh and archer-damage assertions. Final logs contain no [FAIL], SCRIPT ERROR, ERROR or WARNING entries.

## Clickable picture map and friend locks

Latest isolated gameplay gate: **1,132 checks, PASS, exit 0**. Focused native map/title review at 832×480: **18 checks, PASS, exit 0**. Both logs are clean. Real touches open the expanded picture map and Close releases input. Tests verify shop/portal/home/jetty/ship textures, shared map coordinates, blocked locked-card selection, separate rescue explanations, independent unlocks and save/reload persistence.

## Portal 1 tutorial completion

The full isolated gameplay gate passes 1,142 checks, exit 0, with clean error logs. Ten added regression checks cover a first-portal fight spanning night to day, immediate tutorial dismissal, unchanged later-portal rescue progression, prevention of tutorial restart at the next night, and old-save reload where Portal 1 was previously cleared. APK 1.1.2 (versionCode 4) passes signature v2/v3 and 16-KiB ZIP-alignment verification.

## Permanent Sprint, direct ship taps and marine background (1.2.1)

The isolated gameplay gate passes 1,168 checks, exit 0, with clean script/error logs. The final native 832x480 control/ocean review passes 28 checks, exit 0, including two additional checks for the monster/pet portal title suffixes. Captures were inspected for the visible permanent Sprint button, overhead stamina, four-direction turtle steering, portrait timeline, shark and marine/seabed objects. Real touches verify that Sprint never talks/boards, the yellow student opens directly, and tapping the ship boards from outside the old interaction radius. CLEARED labels are absent while saved clear flags remain intact.

ProtectBESUT-1.2.1.apk uses versionCode 7 and the original com.tidesworn.protectbesut application ID. Signature v2/v3 and 16-KiB alignment verify; the certificate matches APK 1.1.3. The stable ProtectBESUT.apk copy is updated identically.

## Automatic sea-route animations (1.2.2)

Full isolated gameplay: 1,191 checks PASS, exit 0, clean script/error logs. Native 832x480 story/rescue review: 62 checks PASS, exit 0. Route checks cover forward movement with the mounted rider, saved checkpoints during departure, hidden Next/locked controls, protection against duplicate completion or bypass, automatic entry into routes 2 and 3, and final island transition. Inspected captures show departure and both arrival animations. APK 1.2.2 (code 8) verifies signature v2/v3 and 16-KiB ZIP alignment; its certificate matches 1.2.1 for original-app updates.

## Kraken fortress, fullness and compulsory rubbish (1.3.0)

Full isolated gameplay: 1,217 checks PASS, exit 0, clean script/error logs. Native 832x480 focused review: 25 checks PASS, exit 0; inspected captures show the portal-style floor, stone pillars/runes, complete Kraken and held cage, grappling tentacle, and separate fullness/life meters. Coverage includes fish-only satiety, heart-only healing, fullness cap/drain/starvation/recovery, one penalty per missed rubbish including concurrent misses and blink immunity, no penalties for avoided hazards/fish, fatal route-end prevention, safe late spawns, physical pillar collision, dodged versus caught hooks, real pull motion blocked by a wall, and boss-gated prison release. Full story checks also verify the returning Arjun sprite retains human world scale.

## First-beat fishing illustration — 2026-10-28

Presentation-only overhaul of `StorySequence` introduction page zero. A layered
UNISZA boat, deck-grounded unarmed friends, connected rod/line/float, stepped
morning sea/sky and deterministic character/environment motion replace the flat
ship and armed walk loop. Story text, six-second timing, Next/Skip, campaign/save
rules, global ship/character art and later story drawing branches are unchanged.
See [OPENING_FISHING_REDESIGN.md](OPENING_FISHING_REDESIGN.md) for ownership and
safe reproduction commands.

Final complete isolated gameplay gate: **1,277 checks, PASS, exit 0**, with no
`[FAIL]`, `SCRIPT ERROR` or `ERROR:` markers. `OpeningFishingChecks` contributes
60 integrated checks: shared boat/actor anchors over six times, fishing geometry,
purpose-built pose progression, uniform aspect fitting, texture-cache stability,
live Reduce Motion/quality, timer handoff, non-first story isolation, Next/Skip
at 0/0.5/3/5.9 seconds and complete renderer release after Skip.

Final native focused review: **70 checks, PASS, exit 0 at each of 1280x720,
832x480 and 1600x720**. Captures at 0.5/2/3.5/5.5 seconds, Reduce Motion, low
quality and the second-beat cut were inspected. Real screen touches activate Next
and Skip and leave no held attack/sprint action. A separate actual new-journey
flow run passes **12 checks, exit 0**, observing all six automatic beats, stopped
world time during the opening, saved completion, unlocked Lobby with Ember and
the movement tutorial, and Continue bypassing an already finished introduction.

Matched baseline/modified/rollback native inputs (`intro`, page 0, 3.2 seconds,
1280x720) show the new first-beat image only in the modified run. Rollback restores
the original source SHA-256 and exact rendered pixels. All **12 other story
panels** (later intro pages, both rescues, reunion ending) are pixel-identical
across the three runs. The implementation remains applied afterward.

An expanded cleanup test initially inferred `weakref()` as Variant under strict
warning settings; it was corrected to an explicit `WeakRef` type before the final
passing runs. That failed run is retained in the external evidence ledger and is
not counted as validation. Native runs have X11 input-method and unsupported
V-Sync warnings; this is Linux Xvfb/llvmpipe evidence, not Android/Windows hardware
certification. No export or live-save test was performed. `git diff --check` passes;
pre-existing AGENTS.md, project.godot and scenes/game.tscn edits remain unchanged.

## Adam selection to opening handoff — 2026-10-28

The confirmed Begin Journey path now keeps its existing title layer visible while
a navy curtain eases in for 0.28 seconds, holds for 0.06 seconds, then reveals the
fishing illustration over 0.64 seconds. The caption fades in during the final
0.22 seconds. Only the matching departing title is removed, at full cover. The
first beat's entire six-second reading/animation clock starts after the 0.98-second
entrance has settled. No camera movement, HUD flash or premature village is added.
Reduce Motion uses a 0.28-second dissolve. Finishing/cancelling the entrance is
idempotent; live accessibility changes cannot rewind it. Seen-intro Continue and
rescue/ending stories bypass the prelude; unseen-intro Continue uses it.

Final complete isolated gameplay: **1,300 checks, PASS, exit 0**. The main harness
explicitly checks the title's retained ownership and stopped first-beat timer;
`OpeningFishingChecks` includes 21 new entrance phase, opaque retirement,
caption/timer, cancellation and live-setting checks (81 focused headless checks
total). Native focused review: **112 checks, PASS, exit 0 each at 1280x720,
832x480 and 1600x720**, including actual Begin/Next/Skip touch input, duplicate
start/continue rejection, normal and shortened reveal captures, full first-beat
reading time, safe Lobby/tutorial arrival and seen/unseen Continue branches.

Matched baseline/modified/rollback handoff probes observe **hard cut / eased title
to story / hard cut**, respectively, with exit 0 and exactly one completion each.
Rollback restores the pre-handoff source hashes and all eight sampled baseline
images exactly, retaining the improved fishing art. The eased implementation is
reapplied afterward. All 13 settled story-panel captures remain pixel-identical to
the previous fishing redesign; no later-beat artwork changed. The existing four
transaction roles are extended in place, with the earlier evidence preserved.

No failure/script/error markers occur in the final gate or native runs. Native
X11 input-method and unsupported V-Sync warnings remain; this is Linux software-
renderer evidence, not physical Android testing. Existing user edits and live saves
are untouched by this isolated validation. See `OPENING_FISHING_REDESIGN.md` for
ownership and rollback usage.

## PB loading screen in the opening handoff — 2026-10-28

Confirmed Begin Journey and unfinished-intro Continue now show the existing PB
LoadingScreen UI, labeled "Adam's Journey", between title departure and the first
fishing image. This is a local instance of the existing class, not a duplicated
brand design or a borrowed global world-transition overlay. It fades in over
0.12 seconds, remains fully readable for 0.55 seconds, then fades out over 0.18
seconds into the existing illustration reveal. Total entrance is 1.59 seconds
normally and 0.97 seconds with Reduce Motion. The first beat still receives six
full seconds after the loader is gone and its caption is readable.

Final complete isolated gameplay: **1,326 checks, PASS, exit 0**. Focused headless:
**100 checks, PASS, exit 0**. Native focused: **138 checks, PASS, exit 0 each at
1280x720, 832x480 and 1600x720**. Added coverage verifies brand/destination
visibility, the readable hold, independent ownership, absent loading tweens,
full reading time, disposal on normal reveal and early cancellation, unchanged
global world-loading state, and real Begin/Next/Skip and Continue routes.

Matched corrected native probes observe **eased entrance without loader / PB
opening loader / eased entrance without loader** for baseline/modified/rollback,
each with one completion and exit 0. The pre-loader source hashes and twelve
sampled images are restored exactly; the loader-enabled implementation is
reapplied afterward. All 13 settled story-panel images remain unchanged. The
same four artifact roles are extended again; the prior eased-handoff records are
preserved under `history/eased-handoff/`.

Final validation has no failure/script/error markers. Xvfb input-method and
unsupported V-Sync warnings remain. No physical Android/export/live-save run was
performed. Existing user edits remain byte-identical and `git diff --check` passes.

The resumed integration rerun includes the newer title-page slide changes (six
additional checks beyond the earlier 1,320 PASS run). The loader, story and Game
implementation is unchanged; its native suite again passes 138 checks at all
three resolutions. Shared fixture timing and unrelated title/document edits are
preserved, including by the generated pre-loader rollback baseline.


## Automatic turtle feeding (2026-10-28)

This supersedes the older manual Eat/F and wrong-action rules in the coastal reports.

- Pick Up/E is the only sea action button. Eat is absent from the ocean HUD, Settings rows and both sea layout editors. Existing saved control positions remain compatible.
- During RUNNING, nearby fish are eaten automatically within mouth reach without pressing a button, restore 35 fullness (capped at 100), open the mouth and resolve exactly once. Fish never heal or award rubbish Gold.
- Pink hearts are collected automatically nearby and restore one life (capped at three) without changing fullness.
- Swept relative movement catches fast fish crossing the mouth between frames; fish in another lane or outside reach remain uneaten. Settings and route transitions suspend automatic feeding.
- Rubbish still requires Pick Up. Fish/hearts cannot block picking up overlapping rubbish; Pick Up ignores edible items and hazards without a wrong-action penalty. Missed rubbish, hunger, bomb/shark damage, retry and route checkpoint rules remain intact.
- The isolated gate covers automatic feeding, range/lane/fast movement, one-time rewards, fullness and health caps, settings/transit suspension and manual rubbish pickup. Coastal native review retains real screen touches for Pick Up and captures the automatic mouth animation. Historical native Eat-button evidence predates this change.

Verification on Windows / Godot 4.7.2: the isolated gameplay gate passed 1,224 checks, exit 0, with no `[FAIL]`, `SCRIPT ERROR` or `ERROR:` output. Native 832x480 coastal review passed 77 checks, exit 0; the automatic-mouth capture was inspected and shows Pick Up with no Eat button. The first full run, overlapping the native review, reported one failure in the unchanged home-defeat recovery assertion; the sequential full rerun passed without changes to that test or recovery gameplay. Both runs used verified temporary user-data directories; live player data was not restored or overwritten.


## Fullness movement, moving Kraken and Arjun homecoming (2026-10-28)

These rules supersede the earlier starvation interval, stationary Kraken and fixed-duration Arjun return.

- All four steering directions, including reverse, use 12 world units/second while fed. At 50% fullness or above, fast steering and travel are retained; below 50%, steering and ocean scrolling both use a 0.7 multiplier. Fish can immediately restore the fast tier.
- At zero fullness the turtle immediately loses all remaining lives, stops controls and enters its existing sinking/retry sequence, regardless of hit immunity. Starvation cannot clear a route or modify earned Gold; retry restores full health/fullness and preserves checkpoints.
- KrakenKing notices Adam across the arena, actually pursues with body-sized paths around pillars, warns then deals ordinary melee damage once per swing, and automatically starts its alternating tentacle slam/hook power. It holds its position during the tentacle warning/extension so attacks remain dodgeable. Existing wall-respecting grapples and boss-gated prison rules remain covered.
- Rescued Arjun stands separately from Adam on the stern, with foot alignment, idle animation and correct world scale. He travels with the ship, disembarks as the same actor and walks along resident routes at Resident.WALK_SPEED (0.9 world units/second); there is no fixed three-second rush to his home. He joins the village once after that walk.
- ControlOceanChecks measures matching directional speeds and the fullness multiplier. KrakenHungerChecks covers immediate starvation, retry, real pursuit, pillar routing, automatic powers, warned melee and existing hook damage. StoryChecks measures Arjun's deck location, scale, continuous handoff and actual distance walked per second; native review captures the returning pair and his first steps off the jetty.

Verification: Godot 4.7.2 on Windows, full isolated gameplay gate 1,248 checks PASS, exit 0; no `[FAIL]`, `SCRIPT ERROR` or `ERROR:` entries. Sequential native 832x480 reviews passed 42 Kraken/fullness checks and 68 story checks (110 total), each exit 0 with clean logs. Inspected actual-renderer fixtures show Adam and Arjun standing separately on the returning ship, Arjun starting his resident-paced jetty walk, and the moving Kraken's tentacle warning. The live player save was backed up; all tests/captures used verified temporary user data. No APK/EXE was rebuilt.


## Ten demon rulers, shared rewards and forge upgrades (2026-10-28)

See [DEMON_REALMS.md](DEMON_REALMS.md) for the stable portal-to-demon mapping, all thirty powers and ownership. This supersedes the old boss names/single-power catalogue and two-weapon shop selection.

- Fire/urchin kills from Arjun, Mei Ling, NPCs and raids immediately credit the player Gold and 3x combat XP, once per death, without requiring floor collection.
- All regular combat kills give 3x XP. A quadratic next-level curve replaces runaway exponential requirements; saved levels and accumulated XP migrate without loss.
- Each weapon discipline has nine purchasable weapons plus a starter. Every owned weapon can be upgraded to +5 with real Gold transactions and +20% base attack per rank. Combat, shop comparison and inventory read the upgraded value. Unknown/unowned/non-weapon/cross-discipline/over-cap/unaffordable upgrades are rejected; ranks persist and sanitize from JSON floats.
- Ten ElementalBoss variants replace the portal guardians. Each rotates exactly three named, warned powers with damaging effects/projectiles, charge or living summons. Their small monsters use matching elemental art and ranged, rush, trap, wave or slam attacks. Floors, lighting, props and traps match the realm. The Abyss Monarch guards the final Mei Ling rescue; all original portal IDs/unlocks remain compatible.
- Active-world player access must return the new world's player while the old world is queued for deletion. Elemental magic validates world/caster ownership and expires when its caster dies.
- The integrated ElementalChecks exercises these transactions and all thirty real execution paths. The native focused scene captures every realm and a closer view of every boss.

Final demon-realm verification: **1,456 full isolated checks PASS, exit 0**, plus **208 native 832x480 checks PASS, exit 0**. No FAIL, SCRIPT ERROR or ERROR entries. All ten boss/realm renders and all three weapon counters were inspected; previews and logs are preserved under `docs/evidence/demon-realms-2026-10-28/` and linked from DEMON_REALMS.md. Live player data was backed up; all test saves/captures used verified temporary paths.


## Repeatable low-HP auto-potions (2026-10-28)

- Damage still applies defence and shields first. If the player remains alive at 25% HP or below and carries Health Potions, that hit automatically consumes exactly one bottle and restores up to the item-defined 45 HP.
- Later critical hits can use another bottle without first healing above 35%; one hit never spends multiple bottles even when 45 HP leaves a high-level player critically low. Above-threshold health, empty stock and already-dead players consume nothing.
- The transaction saves consumed stock and recovered HP together. A depleted Health Potion entry stays at zero so recursive save defaults cannot recreate starter potions on reload.
- The new GameState auto_potion_used signal gives only Game.player() a green recovery ring, healed-health number, bottle effect and recovery sound. No feedback depends on the disconnected toast signal; player presentation settings still apply through the existing VFX pool.
- The isolated gameplay gate tests the exact 25% boundary, above-boundary conservation, repeated low-health hits, one bottle per event, empty stock, heal capping, no resurrection, shield ordering and immediate save/load of the last consumed bottle.

Auto-potion verification: **1,464 isolated gameplay checks PASS, exit 0**. Both stdout and stderr are clean of FAIL, SCRIPT ERROR and ERROR entries. Tests used verified temporary user data; the live Protect Besut save was backed up without restoration.

## Realm presentation, sea briefing and crowded nights (2026-10-28)

- Imported boss/minion atlases provide twenty distinct alpha sprites; matching props/floors and shared spell shaders replace the flat portal presentation while keeping AssetRegistry precedence and existing gameplay timings/collisions.
- Every fresh sea visit waits at its own guide before starting route time, fullness drain or hazards. Ready starts the route; Sea Guide reopens/resumes without resetting it. Retries retain acknowledgement for that visit. No sea object has an overhead label. Pickup/E collects rubbish only; fish feed automatically and bombs/sharks remain hazards.
- Day/night tutorial waiting messages describe the next teaching phase; potion lessons explain 25% automatic use.
- Crowded-night tuning bounds village dynamic lights and throttles perception, separation and lighting work without skipping physics movement/attacks. A blocked resident cannot invalidate the shared static navigation grid; actual world edits still invalidate it.
- `presentation_checks.gd` joins the gate. Updated coastal/movement/hunger/story checks acknowledge the sea briefing; the native `presentation_review` captures spell warnings, all ten realms, sea UI and a reproducible 48-monster performance workload. See [REALM_GRAPHICS_AND_PERFORMANCE.md](REALM_GRAPHICS_AND_PERFORMANCE.md).

Final graphics/sea/night verification: **1,500 checks PASS, exit 0**, plus **34 native final-atlas checks PASS, exit 0**. Final stdout/stderr are clean. Authored atlas rectangles stay within their imported resources, the sea briefing is safe at small resolution, and the melee fixture waits for actual transition unlock. Evidence: docs/evidence/realm-graphics-2026-10-28/.

## Boss-size animation regression (2026-10-28)

Boss and minion wind-up/recovery/lunge poses use each sprite's authored rest scale and origin instead of the old 32px scale. One owned pose tween is cancelled on replacement, recovery, stagger and death; subclass art refresh cannot overwrite its transforms. All twenty elemental actors are sampled throughout the real wind-up tween, checked for bounded scale, then checked for exact recovery and interrupted-lunge cancellation. Native review captures each boss winding up. Combat timing, damage, movement and skills remain unchanged.

Boss-size fix verification: **1,520 isolated gameplay checks PASS, exit 0**, plus **54 native checks PASS, exit 0**. Clean stdout/stderr; all twenty actor pose regressions pass and all ten boss wind-up captures are preserved in docs/evidence/boss-size-fix-2026-10-28/.

## Realistic coastal presentation (2026-10-28)

Imported prerendered 3D artwork now covers the village, five house tiers, all five shops and interiors, heroes/residents, pets, marine life and home furnishings. RealisticArt keeps physical source detail while preserving each texture's original logical dimensions. Explicit AssetRegistry replacements, original WorldLayout/forest IDs, gameplay movement/collisions and presentation settings retain their contracts. Directional views share bounded cached textures; existing motion/attack transforms animate the views.

`realistic_checks.gd` is part of the isolated gate. It verifies detailed imported physical pixels at their gameplay sizes, frame reuse, five distinct homes, eight distinct pet appearances, five shop exterior/interior pairs and stable Kraken wind-up/recovery. Existing Monsoon checks enforce exact tree split pixels, transparent clearance, palette invalidation and override precedence. Native realistic_review captures village day/night, forest/coast, every shop, furnished home, a live duel, sea guide/swimming and Kraken island, including 832x480 sea UI. Arena backgrounds must fill the panel after layout.

Verification: **1,542 isolated gameplay checks PASS, exit 0**; **26 native realistic checks PASS, exit 0**, plus **54 native realm/performance checks PASS, exit 0**. All error scans are clean. Evidence and measured limits are in [REALISTIC_WORLD.md](REALISTIC_WORLD.md) and `docs/evidence/realistic-world-2026-10-28/`.

## Map opens on request (2026-10-28)

The normal HUD shows a Map button below Menu instead of an always-visible minimap. The private compact-map accessor remains hidden with processing disabled. Pressing Map opens WorldMapPanel through the existing guarded Game.open_map route, releases held controls and locks player movement/combat. Close removes the map and restores world controls. Live picture markers and warnings remain in the expanded map. The Map button keeps a minimum 44 physical pixel height and separate placement from Menu when the window scales; tutorial instructions avoid its rectangle.

MapUnlockChecks uses a real screen-touch press/release on Map and verifies hidden idle maps, live locations, input lock and restoration without a minimap. StoryChecks and the main HUD assertion follow the same contract. The native map_unlock_test also verifies mouse opening/closing at 832x480 and captures normal/expanded screens. The previous always-visible-minimap presentation is superseded by this interaction.

Verification: **1,544 isolated gameplay checks PASS, exit 0**, plus **23 native map/unlock checks PASS, exit 0**. Error scans are clean. Actual-renderer captures at 1280x720 and 832x480 and raw logs are saved under `docs/evidence/map-button-2026-10-28/`; player saves remain outside the repository.

## Opening/world-update merge integration — 2026-10-29

Merged the Adam opening/title/loading work with the incoming elemental-realm,
coastal, realistic-world and map-control update. The only textual conflict was
these independently appended acceptance records; both histories are retained.
Isolated Godot import passed with exit 0, then `./tools/test_isolated.sh` reported
**1,653 checks, PASS**, exit 0, with no `[FAIL]`, `SCRIPT ERROR` or `ERROR:` markers.
This is a fresh Linux headless integration run, not a new visual/device/export
certification. Live player data was not used. `git diff --cached --check` passed.


## Selectable art styles (2026-10-29)

Title **Settings**, in-game **Menu → Settings → Appearance**, and ocean Settings
share **Art style**: **Modern Illustrated** (default) or **Classic Pixel**.
The device setting `visual_style` lives in `user://settings.cfg`, not the journey.
A full game restart applies it; changing/reloading/resetting preferences during a
session must not rebuild worlds, change actors, or mix cached art families.
Classic restores the existing procedural art and nearest-neighbour filtering;
Modern retains the imported realistic/realm art and surface overlays. Explicit
Asset Library overrides retain precedence in both modes. This is an art-family
choice, not an old gameplay version or an exact historical UI/story rollback.
Editor source previews and authored resources stay unchanged.

`tools/visual_style_checks.gd` runs in the canonical tide gate: normalization,
invalid/missing-key fallback, persistence, selector wiring, restart latch,
world/player/journey identity, art-family routing and filtering. For real restarts
and rendered comparison, use the focused scene in a verified isolated environment:

```sh
review=$(mktemp -d /tmp/tidesworn-style-XXXXXXXX)
export XDG_DATA_HOME="$review/userdata" TIDESWORN_TEST_ROOT="$review"
# Same user data, separate processes. Selection must not flip the active family.
for style in pixel modern; do
  godot --headless --path . res://tools/visual_style_test.tscn -- --select-style="$style"
  timeout 180 godot --headless --path . res://tools/visual_style_test.tscn -- --expect-style="$style"
done
# Substitute xvfb-run -a env LIBGL_ALWAYS_SOFTWARE=1 godot --audio-driver Dummy
# for the headless verification call to capture title/in-game/ocean Settings,
# village, portal, ocean and Kraken. Also pass --resolution 832x480 for compact QA.
```

Require `--- visual style: N checks, PASS; active=STYLE ---`, exit 0, and no
`[FAIL]`, `SCRIPT ERROR`, or `ERROR:`. Rendered tests cover artwork and layout,
not physical touchscreen input or Android GPU performance. No source bake writes.

## Classic-pixel second opening beat — 2026-10-29

Intro page one now stages the caught hook before the Kraken awakens: rod tension,
a hooked pixel arm, emerging crowned mantle, opening amber eyes and a final fury
hold. Original UNISZA boat layers and unarmed friends link it to beat one. Shared
anchors keep hands/rod/line/hook/arm connected. The ship stays intact until page
two. Captions, six-second page timing, loading prelude, Next/Skip and progression
contracts are unchanged. See `OPENING_KRAKEN_REDESIGN.md` for the timeline and
safe reproduction commands.

Classic Pixel is now the device-settings default, including missing/invalid
style preferences. The existing explicit Modern Illustrated option is preserved
and remains restart-bound. The local device already selected `pixel`; normal
user settings and journey files were not rewritten.

Fresh full isolated gameplay: **1,743 checks, PASS**, exit 0. Native second-beat
review: **87 checks, PASS**, exit 0 at each of **1280x720, 832x480 and 1600x720**.
Seven timed captures plus Reduce Motion and low quality were produced at each
size; desktop/compact captures were inspected. Coverage includes ordered catch/
emergence/waking, line endpoints, deck anchors, fitting above captions, texture
reuse, live accessibility/quality, early Next/Skip and real screen-touch input.
Final runs have no `[FAIL]`, `SCRIPT ERROR` or `ERROR:` markers. Xvfb reports its
known input-method and unsupported V-Sync warnings. This is Linux llvmpipe,
not a physical phone, Windows export or hardware-performance certification.

The first native review failed only its new Skip touch fixture: the newly built
caption had not completed a layout frame before hit testing. Waiting for layout
and using the viewport's final input transform corrected the fixture; production
input/Skip code was not changed to mask it. That failed run is retained in the
external ledger, separately from the final three passing native runs.

Matched default-style baseline/modified/rollback probes observe **modern + legacy
static Kraken / pixel + staged hook awakening / modern + legacy static Kraken**,
respectively. Each exits 0, advances page one after six seconds, completes exactly
once and leaves the world unchanged. All 17 baseline file states restore exactly;
the four baseline sampled PNGs match rollback byte-for-byte. The changed patch
reapplies cleanly afterward. A separate fixed-Classic-Pixel comparison captures
all 13 story panels: **only intro page one differs; the other 12 are identical**.

Fresh isolated style/restart routes pass **25 checks each** for default Pixel and
explicit Modern opt-in. Both retain the existing fixture's **two ObjectDB instance
cleanup warnings** at exit; they are not described as warning-free. The canonical
full gate has no warnings. An initial supplemental panel-control run encountered
stale global-class metadata after restoring/reapplying the sandbox sources and
timed out (124). Reimporting each source state fixed that fixture command; no
production code was changed to conceal the error. Final panel controls exit 0.
A 72-frame, six-second 1280x720 native preview was encoded at 12 sampled fps and
decoded successfully; its rate is a preview format, not a performance benchmark.

## Classic-pixel third opening beat — 2026-10-29

Intro page two now carries beat two's final fury composition into a readable arm
wind-up, a local hull strike, three jagged pieces of the actual yellow UNISZA ship,
and three separately carried friends. The mast/nameplate remains on Arjun's centre
piece; Adam and Mei Ling retain their own stern/bow fragments. Actor feet share
each fragment's pivot and bounded rotation. Reaching/clinging unarmed poses replace
independent combat walks. Local foam/chips/currents support the action without
fullscreen flashes, camera shake or introducing later rescue/capture events.

Fresh full isolated gameplay: **1,837 checks, PASS**, exit 0. Native focused review:
**108 checks, PASS**, exit 0 at each of **1280x720, 832x480 and 1600x720**. Captures
of the preceding keyframe, wind-up, contact, fragment spread, reaching hold and
stable aftermath were produced; desktop and compact composition were inspected.
Reduce Motion holds the complete aftermath, and low quality removes only optional
chips/current marks. Real touch Next/Skip, same-frame cleanup, finite texture reuse,
unchanged captions and six-second auto advance are covered. Final gate/native logs
have no `[FAIL]`, `SCRIPT ERROR` or `ERROR:` markers. Xvfb input-method/V-Sync
warnings remain; this is Linux software rendering, not device/export certification.

An initial pixel-fragment builder had a missing indentation level. A direct syntax
check identified it; the parser was fixed before the passing tests, without changing
any assertions. Its failed import/review logs and the explicitly stopped failed
review's status are retained separately. The isolated import's unrelated Android
daemon diagnostic is also retained. All prior pending beat-two work is preserved.
See `OPENING_WRECK_REDESIGN.md` for staging, source ownership and safe review commands.

Paired story controls capture all 13 panels at the same Classic Pixel settings:
**only intro page two changes; the other 12 remain pixel-identical**. The art region
at the preceding beat's final keyframe and the new beat's time zero is also
**pixel-identical**, excluding the intentionally different caption.

Matched baseline/modified/rollback runs at intro page two and times
0/0.8/1.45/2.2/3.5/5.8 seconds observe **legacy floating rectangles / staged pixel
strike and three real fragments / legacy floating rectangles**, all with exit 0,
six-second advance and exactly one completion. The six baseline PNGs restore
byte-for-byte. All 16 baseline file states and every one of the 17 pre-existing
pending beat-two files restore exactly; the patch is reapplied afterward.

Fresh native compact regressions also pass the preserved first-beat/loading flow
(**138 checks**) and second-beat awakening (**87 checks**), exit 0. The motion
preview contains 162 native frames at 1280x720 over 6.75 encoded seconds, including
the preceding keyframe. Encode and decode both pass; sampled 24 fps describes the
preview, not a hardware-performance measurement. A supplemental comparison helper
initially needed an explicit bool type for a dynamic method result and timed out
(124); the corrected helper, not altered production assertions, passes both states.

## Illustrated coastal reference (2026-10-29)

The latest reference selects clean shaded 2.5D illustration across village houses/shops/props, characters, trees, pets, marine life, interiors, Kraken and elemental realms. The source library is `assets/authored/illustrated/`, with built-in image_gen prompts and alpha-derived region metadata. The compatibility-named RealisticArt API keeps original logical sizes and cache behavior while selecting the new art. Existing fixture/override/tree-pixel contracts remain authoritative. Elemental rectangles now come from authored metadata rather than the previous photographic atlas coordinates.

The village uses quiet olive grass, brown paths, pale beach and smooth depth-tinted water over the existing terrain geometry. No photographed grass texture is sampled. VillageMinimap's background is a child behind its live markers and shares the same material when the expanded map is opened. The HUD retains the Map button and no always-visible minimap. Tests require illustrated style routing for all twenty elemental sprites and for the existing logical-size and five-shop checks; native review additionally checks the shared map material. Gameplay/state rules do not change in this pass. See [ILLUSTRATED_COAST.md](ILLUSTRATED_COAST.md) for scope, prompts and final validation.

Final verification: **1,544 isolated gameplay checks PASS, exit 0**, **27 native illustrated-world checks PASS, exit 0** and **54 native realm/performance checks PASS, exit 0**. Final logs contain no FAIL/SCRIPT ERROR/ERROR entries. Evidence: `docs/evidence/illustrated-coast-2026-10-29/`. Atlas spacing corrections and reimport preceded the final runs; the existing forest/layout, logical-size and boss-pose regressions remain green.

## Illustrated artwork and selectable styles integration (2026-10-29)

The local illustrated coastal artwork is integrated with upstream `96c5fc3`, including the new title/opening sequences and restart-bound style selector. Classic Pixel remains the default; Modern Illustrated selects `assets/authored/illustrated/`. Modern terrain/floors/ocean/arena paths retain the style guards. The expanded map shares the active village material and uses the active family's texture filter. Both earlier acceptance histories above are preserved; their counts describe those earlier source states.

Fresh Windows Godot 4.7.2 verification used temporary user-data directories, verified isolation, process timeouts, exit-code checks and scans of stdout/stderr for `[FAIL]`, `SCRIPT ERROR` and `ERROR:`:

- Classic Pixel full gameplay gate: **1,837 checks, PASS**, exit 0.
- Modern Illustrated full gameplay gate: **1,837 checks, PASS**, exit 0.
- Native style/startup review: **32 checks, PASS** per style, exit 0, at 1280x720.
- Native Modern Illustrated world/shop/map/duel review: **27 checks, PASS**, exit 0; includes an 832x480 sea-guide capture.
- Final gameplay/native error scans and `git diff --check` are clean. Paired village captures and the modern expanded map/pet arena were visually inspected on the AMD Radeon Vega 3 Compatibility renderer.

The isolated import completed with exit 0 and no error markers; it reported `Unable to open Android 'build-tools' directory.` No Android export or physical-device validation is claimed. Test logs/captures remain outside the repository, and normal player saves/settings were not changed. The original local changes, artwork and evidence were retained in a named Git stash as a backup before committing the integration.

## Fourth opening beat: two friends captured (2026-10-29)

Intro page three now stages Arjun's imprisonment and Mei Ling's capture in two
separate pixel-art shore panels. The Kraken pulls Arjun across the open cage
threshold before the portcullis closes; the lock settles and the arm releases.
Attention then transfers to Mei Ling: two guards close her escape routes and
escort her to a ruined passage. Both living friends remain visible during the
final 1.35-second hold. Original captions, six-second timing, Next/Skip, story
completion and save rules are preserved. Adam's turtle rescue follows as before.

`OpeningCaptureChecks`, integrated through `StoryChecks`, covers ordered capture
events, cage clearance, shared arm/body contact, consecutive actor positions,
guard spacing, face visibility, uniform layout, low-quality geometry, live Reduce
Motion, page-clock preservation, early Next and idempotent Skip/cleanup. The
previous wreck assertion now verifies the new capture handoff. The focused
`opening_capture_test.tscn` adds native phase captures and actual engine-injected
touch Next / mouse Skip events. `-- --sequence` captures exact page times;
`-- --wide-review` requests and verifies a borderless 1600x720 review viewport.

Current Windows Godot **4.7.2.stable.official.ed1daf0bf**, isolated user data:

- Canonical `tools/test_isolated.ps1`: **2,370 checks, PASS**, exit 0.
- Native 1280x720: **553 checks, PASS**, exit 0.
- Native 832x480: **626 checks, PASS**, exit 0, including 73 sampled motion frames.
- Native verified 1600x720: **554 checks, PASS**, exit 0.
- Final gameplay/native logs contain no `[FAIL]`, `SCRIPT ERROR`, `ERROR:` or
  warning markers. The isolated import exits 0 without error markers, retaining
  the existing missing Android build-tools notice.
- All **12 non-target story panels** match baseline rendered pixels exactly at
  fixed page/time/viewport/settings. The fourth intro panel changes as intended.
- Rendered capture phases, accessibility/low-quality variants, compact and wide
  framing, motion contact sheet and following turtle rescue were inspected on the
  AMD Radeon Vega 3 Compatibility renderer. A six-second sampled GIF was encoded,
  decoded and duration-checked; it does not establish hardware frame rate.

See `OPENING_CAPTURE_REDESIGN.md` for source ownership, staging, reproduction,
evidence location and corrected intermediate attempts. No Android export or
physical-phone testing was performed; player saves/settings were not used.


## Mei Ling landfall bridge — 2026-10-29

The introduction now has seven six-second pages. A dedicated landfall page sits
between the three-piece wreck and the existing two-friend captivity montage.
Mei Ling remains attached to her recognizable bow fragment until it grounds,
climbs onto the same guarded ruin used by the next page, then is noticed by
already-posted sentries. The final friend/guard/fragment anchors match the
capture's right panel. Its caption explains that their ruler wants the stranger
alive for answers; no Kraken allegiance or new magical crossing is introduced.
The dimension revelation, rescue flags, loader, six-second page clock, Next/Skip
and Adam's subsequent turtle rescue retain their existing ownership.

`OpeningLandfallChecks` is integrated through `StoryChecks` into the canonical
gate. It checks drift/ground/climb/notice ordering, owned wreckage, continuity,
actor separation, transition anchors, live accessibility/quality, early exits,
renderer cleanup and absence of sampling allocations. `opening_landfall_test.tscn`
adds rendered phase captures and actual touch Next/mouse Skip. Review evidence
and current measured results are recorded in the delivery's VERIFICATION.txt;
historical six-page and previous tally entries above describe earlier revisions.

Current final verification (Linux, Godot 4.7.2): canonical isolated gate
**3,129 checks, PASS, exit 0**. Native Xvfb/software-rendered landfall review:
**651 PASS** at both 1280×720 and 832×480; capture review: **675 PASS** at both
sizes, all exit 0 with no `[FAIL]`, `SCRIPT ERROR` or `ERROR:` markers.
XIM and unsupported V-Sync warnings remain in native logs. Phase images were
visually inspected; a first-pass floating-foot/guard-post issue was corrected
and 242 visible-ground support assertions added before these final runs.
No native Windows/Android or physical-phone validation is claimed.


## Three-boss portal campaign (2026-10-29)

This supersedes the dated ten-realm roster above; historical verification counts remain historical.

- Exactly three playable portal bosses: Chaos Citadel / Shadow & Chaos Fiend (level 1), Tempest Spire / Gale Tempest Demon (level 3), Abyssal Throne / Abyss Monarch (level 5). The second unlocks the final portal directly. Both clearing and level gates still apply.
- The final encounter uses twelve level-five minions, 1,120 boss HP, 30 melee/ground damage, 15 projectile damage, a 3.8-second special cooldown and 9-damage traps on a 4.30-second cycle. Rewards: first 650 Gold / 20 diamonds / 320 XP; repeat 360 / 9 / 120.
- Portal menu and Field Guide show three active bosses. Each retains three real warned powers (nine total). Clearing Chaos still completes the tutorial and awards Luma; final victory still rescues Mei Ling. The ocean/Kraken/Arjun campaign is unchanged.
- Fresh journeys contain only three portal states. The seven removed IDs cannot be entered. Legacy second-boss clears or retired-realm progress unlock the new finale; in-flight retired expeditions redirect there without losing their bag, banked currency, rescue flags or attempt history. Repeated save/load is idempotent. Previously completed finales remain complete without duplicate rewards.
- `tools/portal_tutorial_checks.gd` exercises exact counts, UI/book, progression, gates and legacy JSON save/reload for all seven removed IDs. `tools/elemental_checks.gd` exercises all nine retained powers; `tools/story_checks.gd` enters the final rescue at level five. These run through `tools/tide_test.gd`.


## Sixth intro beat: Adam's turtle rescue — 2026-10-29

The existing seven-page opening now gives page index 5 a dedicated rescue
renderer. Adam begins on his own stern fragment; the turtle approaches and waits
for boarding, carries him to a palm/cottage shoreline, stops in the shallows and
lets him step onto sand toward a water keeper's hand and a neighbour's cloth.
The original caption and six-second clock remain unchanged; Mei Ling's landfall,
captivity, the seventh promise caption and title/world/save ownership are preserved.
The seventh page holds the completed welcome, rather than visually returning Adam
to the turtle after he has reached land.

`OpeningRescueChecks` is integrated through `StoryChecks`; `tools/tide_test.gd`
also guards the literal sixth caption. Dense consecutive samples cover support,
boarding-before-departure, stop-before-disembarkation, caption-safe bounds, live
Reduce Motion/quality and early Next/Skip cleanup. Native
`opening_rescue_test.tscn` captures timed phases and exercises real mouse/touch
Next/Skip. See OPENING_RESCUE_REDESIGN.md and the existing external delivery's
sixth-beat evidence/VERIFICATION.txt for final measured results and limitations.


Pre-merge sixth-beat verification before concurrent portal changes (historical): **4,735 checks, PASS,
exit 0** in the canonical isolated gate. Native Xvfb/software rendering: **1,701
PASS** at 1280×720 including 73 consecutive 12 Hz phase captures; **1,628 PASS**
at each of 832×480 and 1600×720. Actual mouse and touch Next/Skip were exercised.
No final run contains `[FAIL]`, `SCRIPT ERROR` or `ERROR:`. XIM and unsupported
V-Sync warnings remain in native stderr. Rendered frames were inspected for
boarding/contact, shore support, face clearance, captions and the static promise
handoff. These runs do not establish physical-phone input, native Windows/Android
validation or hardware frame rate. Prior intermediate framing/clearance corrections
and earlier results are preserved as draft evidence, not substituted for final PASS.


Final sixth-beat verification (Linux/Godot 4.7.2): **4,626 checks, PASS,
exit 0** in the canonical isolated gate. Native Xvfb/software rendering: **1,701
PASS** at 1280×720 including 73 consecutive 12 Hz phase captures; **1,628 PASS**
at each of 832×480 and 1600×720. Actual mouse and touch Next/Skip were exercised.
No final run contains `[FAIL]`, `SCRIPT ERROR` or `ERROR:`. XIM and unsupported
V-Sync warnings remain in native stderr. Rendered frames were inspected for
boarding/contact, shore support, face clearance, captions and the static promise
handoff. These runs do not establish physical-phone input, native Windows/Android
validation or hardware frame rate. Prior intermediate framing/clearance corrections
and earlier results are preserved as draft evidence, not substituted for final PASS.

## Eighth intro beat: welcome to BESUT — 2026-10-29

The intro has eight pages. Its first seven captions and renderers stay in order;
the seventh promise now offers Next into the new welcome. The eighth page starts
on the exact completed shore tableau, passes the planter's cloth into Adam's
hands, gives the water keeper space to invite him inland, and pans across a
continuous extended shore to an open cottage and a waiting villager's greeting.
Adam keeps the cloth as he walks. The turtle remains visibly safe at the shore.
The last second holds the welcome before Continue/automatic advance hands off to
the existing village and tutorial. No inventory item or house reward is granted.

See [OPENING_WELCOME.md](OPENING_WELCOME.md) for staging and source ownership.
`OpeningWelcomeChecks` joins `StoryChecks`; `tools/tide_test.gd` checks the new
caption at the real title/new-journey entry. Earlier seven-page verification
entries above remain historical records.

Final verification on native Windows, Godot **4.7.2.stable.official.ed1daf0bf**:

- Canonical `tools/test_isolated.ps1`: **5,570 checks, PASS**, exit 0, no `[FAIL]`,
  `SCRIPT ERROR`, `ERROR:` or engine warnings in the final gameplay logs.
- Native `opening_welcome_test.tscn`: **929 PASS** at actual **1280×720**, including
  73 consecutive exact-time frames; **856 PASS** at actual **832×480** and
  **1600×720**. All exit 0; native stderr files are empty.
- Inspected the cloth transfer, successive walking/pan frames, final village
  tableau, caption clearance, accessibility variants and actual Lobby handoff.
- Synthetic mouse/touch Next, Continue and Skip exercise the real story buttons.
  Continuing marks the intro seen, restores player controls and shows the existing
  village tutorial. Physical-phone input and Android export were not tested.
- The preceding promise's rendered art and welcome frame zero are pixel-identical
  above the caption (1280×536 crop SHA-256, Base64:
  `FJgT30fDR0hqMbG8WGBqzYdfsXgerTT6ndJBbdNNq84=`).
- Isolated class import passed without script/error markers. Import still reports
  `Unable to open Android 'build-tools' directory.`; Android tooling was not changed.
- `git diff --check` passed. Captures and runtime data remain outside the repository;
  normal player data was not used. No commit or push was performed.

External visual evidence:
`C:/Users/LUQMAN/.codex/visualizations/2026/10/29/01a1869c-c888-7723-b100-09df8dc6fb73/`:
`welcome-1280x720-799712a4`, `welcome-832x480-acd7cf4e`,
`welcome-1600x720-55d869f1`, and `final-gate.log`.
The final gate's isolated root is
`C:/Users/LUQMAN/AppData/Local/Temp/tidesworn-tests-0df4d09019f24de3ae988d8c763b3f8b`.
The earlier 1280 review with the planter's temporary tray-shaped empty pose is
superseded by these final captures; it is not the final visual evidence.

## First playable village arrival on the dock — 2026-10-29

Game now requests a dock arrival after a new journey's introduction, including
Skip and Continue of an unfinished intro. Lobby creates Adam at the resolved
`jetty_deck` approach; the starter companion fits beside him on the planks and the
camera begins following that player immediately. The world loader identifies the
destination as "Besut Village · Dock". Movement-lesson distance starts at the
actual arrival point, so loading into the dock does not count as walking.

The setup flag is not saved. Normal cottage/authored spawn and recovery anchors,
defender home positions, completed-intro Continue, ordinary world returns and
ship return ownership keep their existing behavior. Recovery takes precedence
even if a caller requests the dock. The eight illustrated story pages are unchanged.

Final verification on Windows / Godot 4.7.2.stable.official.ed1daf0bf:

- Canonical isolated gameplay gate: **5,580 checks, PASS**, exit 0. No failure,
  script-error, error or engine-warning markers; stderr is empty.
- Native welcome/dock review: **870 checks, PASS**, exit 0, at both **1280×720**
  and **832×480**. Both stderr files are empty. Actual touch Continue reaches the
  dock, both actors fit within its footprint, and actor-sized physics probes
  confirm a clear deck and route to `jetty_landing`.
- Inspected initial dock framing and successive held-input walking captures.
  Movement is continuous and the first lesson advances through actual walking.
- Native Continue checks cover both an unfinished intro (dock arrival after
  replay) and a completed intro (normal saved-journey arrival). Canonical checks
  additionally cover ordinary returns, cottage/defender anchor preservation and
  recovery precedence over a requested dock start.
- Isolated import completed without script errors; its existing missing Android
  build-tools diagnostic remains. No Android export or physical-phone test ran.
- `git diff --check` passed. No normal player data or source maps were changed;
  logs and captures are external to the checkout.

Evidence under
`C:/Users/LUQMAN/.codex/visualizations/2026/10/29/01a1869c-c888-7723-b100-09df8dc6fb73/`:
`dock-gate.log`, `dock-import.log`, `welcome-1280x720-c7ce6573` and
`welcome-832x480-45ac1b2c`. The isolated gate's full logs are in
`C:/Users/LUQMAN/AppData/Local/Temp/tidesworn-tests-0aa1f0e71a13437cbc8e9bb90ff162e2`.

## Compact currency and live NPC/world status strip — 2026-10-29

The former 344×48 Gold/Diamond panel is replaced by two 34-pixel-high balance
chips with a combined minimum width of 204 pixels plus a 6-pixel gap. A live strip
beside them displays NPCs alive/total, living Monsters, Trees alive/total, burning
mature trees (Fire), and intact registered Homes/total. The fresh village reports
24/24 NPCs, 0 monsters, 64/64 trees, 0 fires and 8/12 homes. Shop tint targets have
no persistent home IDs and are excluded from the denominator.

The current world owns the census. Sheltered people stay alive, fallen trees
remain in the total, protected saplings count as living, and dead/queued/retiring
actors are excluded. Dungeons and Kraken Island show local Monsters beside
balances; unavailable village statistics are hidden. Currency signals update the
balances immediately; live tallies refresh at world changes and every 0.5 seconds
while HUD is visible. The snapshot never writes GameState or changes game rules.

The strip respects GUI scaling, retains at least a 12-pixel physical font size,
wraps on narrow windows and reserves room for Menu/Map. Wrapped height moves the
emergency/build banner below it. Large balances use K/M/B with exact hover text.
Category hover descriptions explain specialist/sapling/enemy-kind subtotals.
See HUD_STATUS_STRIP.md for precise definitions and ownership.

Final verification, Windows / Godot 4.7.2.stable.official.ed1daf0bf:

- Canonical isolated gameplay: **5,606 checks, PASS**, exit 0. No failure, script
  error, error or engine-warning markers; stderr is empty.
- Native `status_strip_test.tscn`: **100 checks, PASS**, exit 0, stderr empty.
  Captures cover 1280×720, 832×480, 640×360 and 480×320, GUI 75/100/130%, day and
  threat states, narrow wrapping, large balances, a custom Menu position, and
  dungeon-only monster counts. Inspected the rendered standard desktop/compact
  views, narrow wrapping and threat states.
- The 26 integrated census checks exercise shelter/death, ignition/felling/
  replanting, home loss/repair, live/dead enemies, foreign/retiring worlds,
  data immutability, compact balances and world handoff/removal.
- Isolated final class import passed without script errors. The existing Android
  build-tools-directory diagnostic remains. No Android export or physical-phone
  test was run.
- `git diff --check` passed. Runtime data and captures stay outside the checkout;
  normal player data, source layouts and the separate village-progression drafts
  were not modified.

Final evidence under
`C:/Users/LUQMAN/.codex/visualizations/2026/10/29/01a1869c-c888-7723-b100-09df8dc6fb73/`:
`status-final-gate-verified.log`, `status-final-import.log`, and
`status-1280x720-70765fc7/` (stdout/stderr and shots). Full gate logs are in
`C:/Users/LUQMAN/AppData/Local/Temp/tidesworn-tests-c25fa6408eea4d4b83d2f4684d925033`.
Earlier draft runs retain a daytime-spawn fixture failure, a shop-inflated home
count and fixture cleanup failures; they are superseded by the final evidence.

## West Workshop story progression (2026-10-29)

The audited first village project is implemented. On a new journey, clearing
Chaos Citadel makes Bram's free **A Roof for the Workshop** commission eligible.
The existing western ruin becomes a working cottage through ten seconds of
on-site daytime labor. A builder walks to it, or the player can help by direct
tap/E. Movement, attack, damage, modal opening and focus loss cancel player
labor; night, danger and world departure suspend it without discarding accepted
work. Multiple actors/repeated submissions cannot accelerate a physics tick.
Construction does not advance during travel or offline time.

Pending project structures cannot be built through ordinary repair APIs or offer
shelter/gun installation. Completion waits for safe collision activation, restores
the cottage once, retains ordinary house/shelter/optional-gun semantics, and
licenses the entire advanced sword family at Garrick's. Weapons still cost their
catalog price. Later damage repairs normally and never revokes the license.
House upgrade eligibility, worker baselines, original forest identities and both
independent rescue branches remain unchanged. Later district projects are deferred.

The construction shop, mission journal, compact forge card, stock action states,
Rami's dialogue/routine and picture map share saved project state. Activity
overrides survive layout refresh. Runtime footprint reservations and player drag
validation preserve work access without modifying source maps or the terrain bake.
The workbench is clear of the original `forest_15` palm. One touch plus its emulated
mouse press is handled as one gesture.

Raw saves without the new schema retain legacy stock access and existing restored
houses, HP, shelter and bought guns. Their fit-out is optional. Current project
records sanitize without inventing completion; future schemas are rejected before
rewriting the file. Work ownership is runtime-only and never revives on reload.

`VillageProjectChecks` runs in the canonical tide gate and the isolated focused
`res://tools/village_project_test.tscn`. Native mode additionally captures desktop
and compact interfaces, a real touch-driven ten-second build without builders,
successive craftsman positions, map/stock completion and live low-quality/Reduce
Motion feedback. See `VILLAGE_WORKSHOP.md` for the player flow and ownership model.

Final verification, Windows / Godot `4.7.2.stable.official.ed1daf0bf`:

- Canonical isolated gate: **5,661 checks, PASS**, exit 0; no `[FAIL]`,
  `SCRIPT ERROR` or `ERROR:` markers; stderr empty.
- Native Classic Pixel: **71 checks, PASS**, exit 0; stderr empty.
- Native Modern Illustrated: **71 checks, PASS**, exit 0; stderr empty.
- The 55 integrated project checks cover transaction gates, free/idempotent
  commissioning, actual builder movement before labor, capped single-tick work,
  interruptions, world handoff, occupied-site activation, live stock updates,
  permanent licensing after damage, ordinary repair, activity/map reconciliation,
  partial/completed JSON reload, legacy entitlements and malformed/future schemas.
- Each native style adds eleven captures and actual touch-driven player labor,
  ten-second completion without builders, consecutive craftsman movement,
  compact Close placement and accessible completion feedback. Inspected the
  rendered commission, work, completion, map and forge states at 1280×720 and
  832×480 in both styles. Final sign text stays within its plaque and updates
  immediately on completion.
- Isolated import passed. It retained the existing Android build-tools-directory
  diagnostic. No authored map/bake, live player progress, Android export or
  physical-phone test was changed/performed. `git diff --check` passed.

Preserved final evidence:
`C:/Users/LUQMAN/.codex/visualizations/2026/10/29/01a186d6-db12-71a2-815d-2f832d7e3d18/workshop-implementation/`.
The directory contains canonical/import logs and `classic-pixel/` plus
`modern-illustrated/` logs and shots. Canonical raw artifacts are under
`C:/Users/LUQMAN/AppData/Local/Temp/tidesworn-tests-d6ce6d634e324d92a6c13e8fe9afab53`.
Earlier implementation drafts exposed a malformed-flag type error, a touch's
emulated mouse toggling work off, a stale-lease fixture which allowed the fresh
crew to claim work before freezing, and a sign background alignment issue. Those
draft results are superseded by the final gate and native evidence above.

## Two combined HUD sections — 2026-10-29

Gold and Diamonds now share one `CurrencySection` frame. NPCs, Monsters, Trees,
Fire and Homes share a separate `StatsSection` frame beside it. The individual
values use padding with no individual boxes. On narrow windows the whole stats
section moves below currency; its contents can wrap within that shared frame.
The width reservation includes both Menu and the wider Map button. Census data,
currency formatting, the half-second refresh and control-layout IDs are unchanged.

Verification on Windows / Godot 4.7.2.stable.official.ed1daf0bf:

- Native status-strip review in the shared working tree: **136 checks, PASS**,
  exit 0, stderr empty. This includes both shared-frame membership and full-panel
  clearance, day/threat states, GUI 75/100/130%, large balances, custom Menu,
  dungeon scope, and 1280×720, 832×480, 640×360 and 480×320 views. Inspected the
  desktop/compact panels and narrow stacked stats panel after the Map-clearance fix.
- A full shared-tree gameplay run reported **5,661 checks, 1 failure** in the
  concurrently edited village-project checks: "return rebuilds the project from
  saved work without reviving a stale lease". The grouping update does not edit
  that implementation or its tests; this is not presented as a shared-tree PASS.
- Canonical gameplay in a disposable copy of committed `b2bb16c` plus only the
  four HUD-related changed files: **5,606 checks, PASS**, exit 0. Its three code
  files matched the working files byte for byte. No failure/script-error/error
  or engine-warning markers; stderr empty. This verifies the HUD update apart
  from the concurrent village-project work without resetting that work.
- Shared-source import passed. The clean-copy import initially exceeded its
  bootstrap timeout; after reusing the imported texture/audio cache, independent
  script metadata import completed. The existing missing Android build-tools
  diagnostic remains. No Android export or physical-device test was performed.
- Scoped `git diff --check` passed. No normal player data, construction source or
  source maps were modified by this update.

Evidence under
`C:/Users/LUQMAN/.codex/visualizations/2026/10/29/01a1869c-c888-7723-b100-09df8dc6fb73/`:
`status-1280x720-46ebb2cf/` (final native logs/shots), `grouped-status-import.log`,
`grouped-status-gate.log` (shared-tree result), `grouped-status.patch`, and
`grouped-source-c7ebe6bb/import-cached.log` plus `grouped-source-c7ebe6bb/gate.log`
(scoped PASS). The scoped gate's full logs are in
`C:/Users/LUQMAN/AppData/Local/Temp/tidesworn-tests-e4ed12c164dc4de9b04826336a2f37c0`.
Earlier native grouped-panel captures with Map overlap are superseded by the
final 136-check review. The redundant source ZIP was removed after validation;
the disposable source, patch and logs remain outside the checkout.

## Twilight Wilds — unified entrance and first exploration dimension (2026-10-29)

This supersedes the earlier two-village-portal rules and the first stage's immediate
pursuit/emergency expectations. Stable campaign IDs and later legacy arena rules
remain compatible. See [TWILIGHT_WILDS.md](TWILIGHT_WILDS.md) for ownership and scope.

- One village Dimension Portal enters Twilight Wilds directly, with no destination
  list. The retired pet entrance produces no node or map icon; old layout anchors
  and the original village forest fixture remain stable.
- A connected authored route has two optional pet habitats, six local imp encounters,
  the watchpost winch/physical shortcut, a resting checkpoint and Chaos Citadel.
  Ordinary movement remains continuous. Paths to both habitats and the lantern are
  verified against physics; the opened shortcut produces a shorter valid route.
- Starter Ember can challenge Bramble Cat and Dusk Moth without tournament-order
  or purchased-level prerequisites. Duels occur in the discovered clearing, with
  manual Attack/Shield/Special buttons and keys 1/2/3. A real injected screen touch
  chooses Attack. Waiting indefinitely never spends a player turn.
- Accepted challenges suspend the realm, projectiles, hazards, companion support
  and world clock. Settings also suspends the duel. Win/loss/cancel and world
  replacement restore camera, participant positions, controls and audio ownership.
  Full-screen challenge UI is excluded from ordinary HUD-widget scaling. Live
  touch-setting changes cannot expose world controls beneath the challenge.
- First bonds commit once, recruit the stable companion/village guardian and award
  participant XP plus Gold. Duplicate callbacks fail. Friendly repeat spars give
  neither Gold nor guaranteed levels. Losing/cancelling leaves saved HP and ownership
  unharmed. Already-owned pets remain owned, including migrated duel recruits.
- Exploration persists discovered cells/landmarks, shortcut, checkpoint and realm
  presence through defaults/sanitization and save/load. Old active first-portal saves
  migrate safely; malformed destinations and duplicate/invalid records are sanitized.
  Continue reconstructs at the safe checkpoint and resets unfinished combat.
- The shared day/night clock continues during ordinary exploration. Long nighttime
  visits do not start the legacy expedition emergency. Village waves/saved attackers
  and later-stage emergencies retain their existing behavior.
- The ruler stays dormant and invulnerable until the chamber threshold. Local packs
  do not globally alert. Retreat resets boss HP, attack sequence, effects and camera
  framing. Active combat frames the entire chamber even with a close zoom preference;
  warnings remain essential at low effects/reduced motion.
- First victory banks the expedition and commits the existing first-stage rewards,
  restores terrain/light, removes hostile packs/spells, and leaves an explicitly saved
  peaceful realm visit. There is no forced victory modal. A return rift banks/ends
  the visit; cleared revisits do not duplicate boss rewards or respawn the ruler.
- Exploration maps hide undiscovered terrain and the boss marker. No ground path
  reveals an undiscovered boss. Nine physical onward passages retain the original
  later stage gates/rewards and final Mei Ling rescue; Arjun's ocean route remains
  independent. Three-dimension campaign compression is not part of this first slice.
- The Field Guide and tutorial explain the new entrance, habitats and checkpoint.
  Completed legacy pet-duel results now stop their battle track, covering the music
  cleanup path that the old active-close test missed.

Final evidence: Godot **4.7.2 stable, native Windows**. The canonical isolated gameplay
wrapper reports **4,789 checks, PASS, exit 0**, with no `[FAIL]`, `SCRIPT ERROR` or
`ERROR:`. Focused Compatibility/OpenGL rendered reviews at **1280×720** and
**832×480** each report **54 checks, PASS, exit 0**, with empty error logs. Captures
were inspected for arrival, on-location challenge controls, the complete citadel,
restored realm and discovered map. Movement checks inspect consecutive positions;
the focus checks include actual injected touch, protected Settings, navigation,
reward idempotence, checkpoint/save migration, world replacement and peaceful
post-clear revisits. `git diff --check` passed. Isolated import reported an Android
build-tools-directory warning; no Android build or physical-phone validation is claimed.

Reproduce with `tools/test_isolated.ps1 -Godot <Godot-console-executable>`; add
`-Twilight` for the focused suite, or `-Twilight -Capture -Resolution 1280x720`
(and `832x480`) for isolated rendered captures. The wrapper prints its external
artifact directory and requires the exact corresponding final PASS summary.

## Compact Twilight Wilds (2026-10-29)

- The realm footprint is 56x52 instead of 72x72: 43.8% less area. The main authored
  road measures 49.55 units instead of 65.73 (24.6% shorter). This is a geometry
  measurement, not a timed player-session or performance claim.
- Arrival/return, both habitats, watchpost winch, checkpoint, enemy homes, boundary
  collision, terrain bridge/pool and the citadel move together. Characters, movement
  speeds, path widths and the 20x20 boss arena retain their original scale.
- All nine onward passages have physics-verified complete routes. Their courtyard
  paths exclude decorative tree collisions at the entrances. The rootway remains
  a real, persistent shortcut with a shorter valid route after opening.
- The six-by-six discovery grid now uses normalized cells over the new bounds.
  Existing discovery IDs, saved checkpoint IDs, bonds, shortcuts and campaign flags
  survive; players resume at the relocated safe checkpoint. No village layout or
  forest RNG/fixture associations were changed.

Final Windows / Godot 4.7.2 verification: canonical isolated gameplay **4,803 checks,
PASS, exit 0**; actual-renderer focused reviews **68 checks, PASS, exit 0** at each
of **1280x720** and **832x480**. All final gameplay/review logs contain no FAIL,
SCRIPT ERROR or ERROR markers and their error logs are empty. Arrival, compact
exploration map and full citadel framing were inspected in rendered captures.
The import still reports the existing Android build-tools-directory warning;
no Android export or physical-device performance claim is made. `git diff --check`
passed. These results supersede the pre-compaction verification count above.

## Living Twilight Wilds — first expansion (2026-10-29)

- The map remains 56x52 and its main road remains 49.55 units. One short optional
  spur leads to a 5x4 hollow pocket; no village forest identities or RNG change.
  Physics routes reach all five new interests, with or without first opening the winch.
- Bramble Cat rests/sniffs/walks a small circuit; Dusk Moth flutters between nearby
  perches. Both stop and notice nearby Adam instead of fleeing. Consecutive movement
  samples verify slow, bounded steps. Reduce Motion uses a stable home pose.
  Pawprints, scratched timber, moonblooms and a bent marker remain static clues.
- Both habitats reserve an 8x7 tree-free duel floor. Actual injected screen taps
  challenge the moving animals. Staging uses fixed habitat anchors and cancellation
  restores the exact prior patrol positions. Existing protected manual duel and
  Settings/world-replacement checks continue. Bringing the same companion replaces
  the duplicate wild animal with a peaceful bond wreath; the API rejects self-duels.
- Wisp, the optional Waykeeper, has short context-sensitive lines for discoveries,
  bonds, all memories and restoration. E/tap never forces a quest or pauses the world.
- Exactly three stable memory IDs can be read in any order and re-read without
  currency/XP. The Field Guide appends Memories of Twilight after its existing five
  Story & Sea pages. Unknown slots conceal titles/text; read slots retain full words.
  Actual touch reads the stones and closes their owned caption. Landmark surveys
  cannot replace its text. Walking away dismisses it. It fits both reviewed sizes.
- The hollow gives exactly 25 Gold once per journey. Uncleared visits save carried
  Gold and a pending claim together; reload cannot repay. Defeat loses both and
  reopens the hollow while preserving knowledge. Banking and actual boss victory
  transfer its claim to the permanent ledger with the reward. A restored hollow
  banks immediately with or without an active expedition. Empty art loses its glint.
- Proximity alone cannot open the hollow through a physics wall, through either
  E or actual touch. Interest map markers require nearby discovery and clear view;
  revealing a terrain cell alone does not expose the cache.
- Defaults/sanitization handle old saves, unknown/duplicate content IDs, non-array
  records and pending claims already banked. Ambient states never write saves.
  All mutations remain in GameState. Campaign rescues and rewards retain their rules.
- Victory releases the encounter-active flag immediately, so memories, the Waykeeper,
  camp and friendly challenges work in the same restored visit without reloading.

Coverage lives in `tools/realm_life_checks.gd` and `tools/twilight_checks.gd`, invoked
by the canonical `tools/tide_test.gd` gate and the isolated focused scene. Native
captures also cover the two habitats, Waykeeper, memory caption, journal and hollow
alongside the existing arrival/duel/citadel/restoration/map review frames.

Final verification on **native Windows / Godot 4.7.2**: canonical isolated gameplay
**4,858 checks, PASS, exit 0**; Compatibility/OpenGL rendered focused reviews
**123 checks, PASS, exit 0** at each of **1280x720** and **832x480**. The final
gameplay and review logs contain no FAIL, SCRIPT ERROR or ERROR markers, and their
error logs are empty. Captures were inspected for both habitats, caption/journal
legibility, hollow, discovered map, challenge controls and full citadel framing.
`git diff --check` passed. The isolated import retains the existing Android
build-tools-directory warning; no Android export or physical-phone validation is
claimed. These results supersede the earlier compact-realm counts above.

## Sync integration: local village/HUD work + Twilight Wilds — 2026-10-29

Merged upstream `928b913` (including `0d93b16`) with the five local commits through
`78e3e38`. Both histories and their dated evidence are retained above. The HUD's
layout capture excludes both the owned status strip and the full-screen wild-pet
challenge. The canonical runner executes the status-strip, village-project and
Twilight suites together. The eighth opening beat, first-arrival dock and grouped
currency/status sections remain present alongside the unified exploration portal.

Final merged-tree verification on Windows / Godot 4.7.2:

- Canonical isolated gameplay: **5,729 checks, PASS**, exit 0, stderr empty.
- Native Twilight review at **832×480**: **68 checks, PASS**, exit 0, stderr empty;
  inspected the wild companion challenge and its full-size controls with the
  grouped currency/local-monster panels still correctly positioned.
- Native status-strip review: **136 checks, PASS**, exit 0, stderr empty, covering
  day/threat views, GUI scaling, narrow shared panels and dungeon scope.
- Isolated import passed; its existing Android build-tools-directory diagnostic
  remains. No Android export or physical-phone claim is made.
- Merge conflict markers and unmerged index entries are cleared, and staged
  `git diff --check` passed. Normal player data was not used by these tests.

This is a current combined-tree PASS; earlier branch-specific counts and the
previous concurrent village-project draft failure remain historical records.
Evidence: `sync-import.log`, `sync-gate.log`, `sync-twilight.log` and
`status-1280x720-076ad725/` under
`C:/Users/LUQMAN/.codex/visualizations/2026/10/29/01a1869c-c888-7723-b100-09df8dc6fb73/`.
The full isolated gate logs are in
`C:/Users/LUQMAN/AppData/Local/Temp/tidesworn-tests-85b0628541874320a9cd4e1400d4635b`;
Twilight captures/logs are in
`C:/Users/LUQMAN/AppData/Local/Temp/tidesworn-tests-b8870d4c68a14c35a2238ad462df8ff9`.

## Sync integration: living Twilight Wilds + latest village/HUD source — 2026-10-29

Merged `1d9716e` with upstream `577e2af`, preserving both histories. This combines
the living habitats, Waykeeper, memories and hollow with the eight-beat welcome,
dock arrival, workshop restoration and shared HUD panels. The test runner keeps
both the status-strip/village-project suites and the expanded Twilight checks;
both branches' historical verification notes remain above.

Current merged-tree verification on native Windows / Godot 4.7.2:

- Canonical isolated gameplay: **5,784 checks, PASS, exit 0**.
- Native Twilight reviews: **123 checks, PASS, exit 0** at each of **1280x720**
  and **832x480**, with captures inspected for HUD/caption clearance, protected
  pet challenges, journal readability, hollow and complete citadel framing.
- All three gameplay/review error logs are empty, with no FAIL, SCRIPT ERROR or
  ERROR markers. The isolated import passed with the existing Android build-tools
  directory warning; no Android export or physical-phone validation is claimed.
- Merge conflicts are resolved and the staged whitespace check passes. All 97
  pre-existing local settings/import files retain their exact pre-pull hashes;
  normal player progress was isolated from the tests.

Evidence under `C:/Users/ayiz/AppData/Local/Temp/`: full gate
`tidesworn-tests-9ca1b9f1347a4050b5e0749d648ff0a2`, 832x480 review
`tidesworn-tests-79f390442ef94c4bb718c549ebc3bf3b`, 1280x720 review
`tidesworn-tests-435fdb229b564d06bf4e852a3c48aeaa`, and import
`tidesworn-tests-0c710d0d027047a58f507898f2778530`.

## Read the Wilds — compact combat expansion (2026-10-29)

- The world remains 56x52, its main road about 49.55 units, and its boss arena
  20x20. Six regular guards retain 282 total HP, base damage/movement and ordinary
  XP/drop rules. Four Imps, one Ember Watcher and one Rune Keeper replace the six
  identical profiles; no extra wave, permanent reward or saved combat field is added.
- Authored pairs have separate engagement cores, bounded pursuit and physical
  return routes. One pair can attack; its single slot covers warnings and all
  live damaging effects. Forward/reverse handoff cannot accumulate attacking pairs.
- Imps have a real 0.65-second stationary windup before their committed rush.
  Consecutive positions verify continuous movement. The Watcher locks a three-shot
  fan, with real cover stopping its outer lane. The Keeper marks a short fixed cross
  with two collision-clear diagonal escapes. One cast contacts Adam at most once,
  including fan overlaps and the cross intersection, independently of blink immunity.
- Swept collision handles large time steps. Warning and hit geometry are clipped
  against world collision, pursuit limits and protected spaces. Entire pet stages
  plus margin, arrival, memory sites and the lantern reject incoming regular attacks.
- Retreat preserves surviving HP, cancels pending powers and returns bodies through
  refuge-aware monster grids without healing or snapping. Companion auto-targeting
  does not follow returning guards. Ordinary village/player routing remains intact.
- Weapon interruption, death, queued removal, boss ownership, defeat and world
  replacement invalidate cast tokens before delayed damage can land. Duplicate
  callbacks cannot repeat damage or ordinary kill/reward accounting.
- Actual injected touch joystick input drives the physics-backed player diagonally
  out of a cross at ordinary movement speed, then releases every movement action.
  No new combat button is added. Normal Settings keeps world combat active; the
  protected habitat duel ends pursuing casts before its deliberate world suspension.
- Essential warnings survive low effects/Reduce Motion. Field Guide monster pages
  illustrate the three silhouettes and their responses. The live HUD continues to
  count dormant living monsters rather than pretending to be an aggro counter.
- Existing discovery, pet bonds, cache banking/loss, checkpoint migration, peaceful
  post-clear revisits, workshop eligibility and both rescues retain their gates.
  Legacy elemental arenas keep their ElementDB profiles and powers.

`tools/realm_combat_checks.gd` runs inside the isolated Twilight suite and the
canonical tide gate. It supplements existing lifecycle/save/control coverage with
owned-attack timing, physical movement, real cover, interruption, protected-space,
touch-dodge and duplicate-hit cases. New render frames show the three warnings,
the reduced-motion fallback and the Watcher's Field Guide page.

Current native Windows / Godot 4.7.2 verification:

- Canonical isolated gameplay: **5,841 checks, PASS, exit 0**.
- Final rendered Twilight reviews: **180 checks, PASS, exit 0** at **1280x720**
  and **832x480**. Inspected the three attack warnings, cover, low-effects cross,
  Field Guide, protected habitats and citadel framing. The winch label yields to
  the Watcher's lanes while its nearby interaction remains available.
- The full gate and final rendered error logs are empty, with no FAIL, SCRIPT
  ERROR or ERROR markers. Earlier rendered runs intermittently reported ObjectDB
  cleanup warnings (4-9 instances); verbose diagnostic runs did not reproduce
  them. The focused runner now drains final route/visual callbacks, explicitly
  frees its fixture and drains queued deletions; the final two reviews have no
  cleanup warning. This is test teardown evidence, not a general engine leak audit.
- The isolated import passes with the existing Android build-tools directory
  warning. Rendering uses native NVIDIA Compatibility/OpenGL. No Android export,
  physical-phone input, player-comprehension or new performance figure is claimed.
- Whole-checkout `git diff --check` and new-file whitespace checks pass. Existing
  local project settings/import changes are preserved. Screenshots and isolated
  saves remain outside the repository; normal player progress was not mutated.

Evidence under `C:/Users/ayiz/AppData/Local/Temp/`: full gate
`tidesworn-tests-cd1d90a4339e49bdb29c81831fed0795`, final 1280x720 review
`tidesworn-tests-6bf52c258c7b4015a208245b9f3569bd` (verbose), final 832x480 review
`tidesworn-tests-3a1651296b0840ecbec2aa0816243b7c`, and import
`tidesworn-tests-588ff767c06a45f1949f95e599e247ef`.

## Dimension stability investigation (2026-10-30)

- Repeated elemental summons now prune freed, queued and dead references before
  applying the existing three-living-minion cap. A regression reproduces actual
  node deletion between casts, rather than checking only same-frame death flags.
- The citadel threshold starts the inherited boss notification lifecycle, which
  arms its authored special attacks. Threshold-only activation, retreat/reset and
  peaceful cleared revisits retain their existing ownership rules.
- Realm/director physics are explicitly stepped after a guard has been fully
  freed, covering the stale-object casts observed in older Windows player logs.
- `Game` owns flushed diagnostic session records independent of progression.
  Samples contain world/boss context and memory/object counts; normal shutdown
  writes an end record. Files rotate at 256 KiB and use separate process IDs.
- `tools/test_isolated.ps1 -Godot <console-executable> -Stability` adds a repeatable
  450-simulated-second run with 300 seconds of boss casting, corpse retirement,
  retreat, victory and twelve realm/village replacement cycles. `-Realtime` uses
  native rendering and wall-clock pacing at either supported `-Resolution`.
  Headless acceleration does not certify real-time rendering or ordinary play.

Verified on native Windows / Godot 4.7.2:

- Canonical isolated gameplay: **5,844 checks, PASS, exit 0**.
- Rendered Twilight at **832x480**: **182 checks, PASS, exit 0**.
- Accelerated stability and final native **832x480** real-time stability:
  **32 checks, PASS, exit 0** each. The native run lasted about 469 seconds
  including construction/transitions; it completed five uninterrupted minutes
  of boss casting and all twelve replacement cycles. The native error log is
  empty. Guard and boss casts were counted, not inferred from elapsed time.
- Additional accelerated **1280x720** rendered combat completed 360 simulated
  seconds, **781 player attacks** with companion support and **86 boss powers**,
  PASS/exit 0, with no error markers. A temporary fixture sustained the boss's HP.
- In the final native run, warmed replacement-cycle node/object counts stayed
  at 1,573/4,308, orphans at zero and video memory at 60.98 MiB. CPU allocations
  changed from 117.43 to 117.44 MiB over cycles 3–11. Boss-phase CPU memory stayed
  around 111.17 MiB; video buffers warmed and plateaued within the tested bound.
- The headless accelerated soak intermittently emits a two-instance ObjectDB
  shutdown warning; a separate verbose run identified WAV/audio-playback objects.
  The final native soak, rendered Twilight review and canonical gate error logs
  are empty. Isolated import retains the existing Android build-tools warning.
- The reported immediately disappearing window was **not reproduced**. The
  shared summon error is confirmed, but Chaos does not summon, so this alone
  does not establish the cause of a first-realm native exit. No Android or
  physical-device validation is claimed. Normal player saves were untouched.

See `docs/CRASH_INVESTIGATION_2026-10-30.md` for the evidence paths, exact limits,
diagnostic location and distinction between observed script errors and an
unproven native process-crash cause.

## Main-menu copy cleanup (2026-10-29)

The small `PB (Protect BESUT)` header, `A HOME WORTH FIGHTING FOR`,
`Between the forest and the sea, a village is counting on you.`,
`Build a home. Find a companion. Defend your shore.`, and fresh-save
`Your first chapter is waiting. Start a new journey.` text are removed.
The large two-line `PROTECT BESUT` title remains. Without a save, the empty
summary is hidden rather than reserving space. With a save, hero/level/location
details remain. Buttons, right-side scenic caption, credits and gameplay are unchanged.
`tools/tide_test.gd` explicitly checks the retained title, all five removals,
and hidden no-save summary. Prior dated title descriptions above are historical.


### Main-menu scenic-caption follow-up (2026-10-29)

Also remove `01 / THE SHORE WE CALL HOME` and
`Every great journey begins with a little hope.` from the home menu.
The earlier copy-cleanup removals remain applied. Keep the harbour artwork,
large `PROTECT BESUT` title, buttons, saved-journey details and layout unchanged.
The existing removed-copy regression list now covers all seven text elements.


## Cinematic harbour home revamp (2026-10-29)

Supersedes the earlier home layout, not its seven requested text removals.
The home now has a two-tier PROTECT / BESUT wordmark with a bundled OFL Noto
Serif display font, a translucent framed navigation rail, restrained utility
buttons, and a saved-journey portrait/details row. Continue leads when a save
exists; a fresh journey still focuses Start Game. No-save details remain hidden.
The harbour diorama uses current cached art for Adam, Ember, cottages, trees
and the UNISZA ship, layered dusk mountains, reflected sunlight, a foreground
boardwalk and lanterns. It is presentation-only and consumes no gameplay RNG.
Backdrop redraws are capped at 30 Hz. Reduce Motion and Low effects stop the
animation; static essential scenery remains. Settings changes apply live.
Desktop uses a left rail, compact landscape splits wordmark and navigation,
and portrait centres the stacked controls. Home scrolling remains available for
short windows. Overlay focus, clipped page slides, rescue locks, explicit save
replacement, corrupt-save handling and Adam's loading/story handoff remain.
The How to Play control legend now matches Sprint, Pack, Build and direct taps.
TitleChecks and the native title review cover rail containment, portable font,
fresh/saved details, Continue ordering, animated backdrop state, responsive
bounds and actual portrait touch input, in addition to prior save-safety checks.


## Cross-source synchronization — 2026-10-30

Pulled11 upstream commits and reconciled the local title/cottage and three-stage
campaign sources with the incoming dock arrival, HUD, West Workshop and Twilight
Wilds exploration/combat work. Twilight Wilds remains the first stable campaign
stage, with its authored six encounters/local guard system; the two later stages
retain the level3/5 rescue chain. Both upstream and local historical acceptance
sections above are preserved, not presented as new runs.

The combined sources passed the Linux isolated canonical gate: **5753 checks,
PASS**, exit0, with no failure/script/error markers. Native title/input review
passed **69 checks,0 failures**, exit0, including compact/portrait layouts and
corrupt-save preservation. Isolated class import and `git diff --check` passed.
Linux Xvfb/Mesa llvmpipe review retains XIM/unsupportedVSync warnings; import
reports an unavailableADB daemon. No physical-device, Windows-export or hardware
performance claim is made. Recovery snapshots and literal logs are outside the
checkout under `/tmp/tidesworn-menu-cleanup-6li7ss7s/SYNC_12_20261030`.

### Windows merge verification — 2026-10-30

Combined the three-stage campaign/title/cottage update with the boss lifecycle
fixes and crash diagnostics. The acceptance-document append conflict retains both
sets of historical notes. On the merged Windows sources, isolated import passed
(with the existing Android build-tools warning), the canonical gameplay gate
reported **5,755 checks, PASS, exit 0**, and the accelerated stability gate reported
**32 checks, PASS, exit 0**. Both gameplay/stability error logs are empty.
Evidence: `C:/Users/ayiz/AppData/Local/Temp/tidesworn-tests-823fa859e46c4f329d6e3622ac36d774`
and `tidesworn-tests-79f33910930e4cc5aa5dcc3c2103e40b`. No native visual review was
repeated for this merge. Existing local settings/import edits and player progress
were preserved.

## Habitat battles reuse the existing pet battle (2026-10-30)

Habitat taps/E now open the existing `PetBattlePanel` directly. Bramble Cat reuses
Bramble Court's background, and Dusk Moth reuses Moonlit Ring's background, with
the existing art-style override. Both use the original sprites, segmented HP,
animations, impact effects, music, three powers, cooldowns, ready-skill selection
and player-first/reply turns. The separate WildPetChallenge overlay and PetDuel
engine are removed. This supersedes older in-world duel-staging descriptions.

- The realm and shared clock suspend until the battle/result is closed. Map
  actors and camera keep their positions. Settings also suspends pending replies,
  cooldowns and battle input, and live touch preferences cannot reveal land controls.
- Habitat difficulty/rewards remain 30 HP/4 damage/25 Gold/50 XP for the cat and
  42 HP/5 damage/35 Gold/65 XP for the moth. Starter Ember still has access without
  tournament clears or purchased levels. Same-species companion visits remain peaceful.
- GameState retains the captured participant and token-guarded one-time bond.
  Habitat wins do not clear tournament levels or grant a guaranteed level. Repeat
  spars pay nothing; defeat/cancel leaves saved health and recruitment untouched.
- Shared data refresh cannot rebuild an active habitat arena or result. A late
  completion after closing cannot fall through into tournament rewards. World
  replacement cancels the session, pending reply, music and held controls.
- Arena transitions clear old hit effects. Results offer Return to the Wilds;
  the existing tournament route retains its level gates, rewards and result flow.

`tools/twilight_checks.gd`, `realm_life_checks.gd` and `realm_combat_checks.gd` cover
the shared arena, real touch buttons, both original backdrops, local HP, manual
waiting, shield/reply ordering, Settings, rewards/replays, data refresh and world
cleanup. `tools/tide_test.gd` retains direct tournament coverage as well.

Verified on the current Windows working tree based on `a72a7e5`, Godot 4.7.2:

- Canonical isolated gameplay: **5,763 checks, PASS, exit 0**.
- Native rendered Twilight reviews: **183 checks, PASS, exit 0** at each of
  **1280x720** and **832x480**. Inspected both original arena backgrounds, all
  three powers, the clean bond result and Return to the Wilds.
- The full/focused error logs are empty, with no FAIL, SCRIPT ERROR or ERROR
  markers. Isolated import passes with the existing Android build-tools warning.
  No Android export or physical-device validation is claimed.
- `git diff --check` passes. Test saves/captures stay outside the repository.
  Existing settings/import changes and concurrent dock/campaign work are preserved.

Evidence under `C:/Users/ayiz/AppData/Local/Temp/`: full gate
`tidesworn-tests-b65cc1e9b2234a7ebb1160fec6ddedfd`, native 1280x720 review
`tidesworn-tests-7dddea68ecc24fb59ff6842588aae489`, native 832x480 review
`tidesworn-tests-4348ca8ed3ae4e9481846081ebc0ba76`, and import
`tidesworn-tests-e54716a974aa4dee86fa5a60ed19b6aa`.

## Pak Rahim's dock welcome (2026-10-30)

The eight opening beats now hand off to a 12-line conversation with Pak Rahim on
the physical village dock, before movement tips begin. He offers water and a
place to recover, hears Adam's concern for Arjun and Mei Ling, and suggests
meeting the neighbours. He does not know the friends' locations or charge a debt
for helping Adam. The final original portrait has a cute, airy anime-inspired
design; a matching original pixel sprite stands beside Adam. Neither new asset
uses the existing illustrated or realistic resident atlas.

The cream dialogue box presents one complete line at a time, speaker names,
Back/Next, explicit Skip, and the transparent character portrait on the right.
There is no automatic reading timeout. E/Space/Enter and actual screen touch
advance lines. Initial arrival suspends its world and clock as a story; later
optional short chats retain normal running-simulation menu rules.

`campaign.dock_welcome_seen` is defaulted, sanitised and written through GameState.
Migration checks the raw saved campaign before merging defaults: existing saves
that finished the intro keep normal arrivals. A new interrupted opening retains
its explicit pending flag and resumes on the dock through Continue. Completion
and Skip save once; cancellation on world replacement saves no completion and
cannot restart the tutorial in another world.

`tools/dock_conversation_checks.gd` joins StoryChecks in the canonical gate and
has a focused `tools/dock_conversation_test.tscn` route. The full suite explicitly
finishes the new welcome before running village simulation checks. The focused
checks cover actual save/load migration, every line's layout, real touch/keyboard
input, frozen reading time/positions, short repeat chats, cancellation, and the
actual New Journey/Continue handoffs. Run Windows review with
`tools/test_isolated.ps1 -Godot <absolute-console-executable> -Dock`; add
`-Capture -Resolution 1280x720` or `-Capture -Resolution 832x480` for rendered shots.

Native Windows rendered reviews passed **49 checks, exit 0** at each resolution;
all four first/final-line captures were inspected. Final focused 1280x720 evidence:
`C:/Users/ayiz/AppData/Local/Temp/tidesworn-tests-c40ddf093aff4629adc4a76308c3aa5f`;
832x480 evidence: `C:/Users/ayiz/AppData/Local/Temp/tidesworn-tests-328226361e734d82bd67958099f61931`.
Both focused error logs are empty. Isolated import passes with the existing
Android build-tools warning. No export or physical-device validation is claimed.
See `docs/DOCK_WELCOME.md` for art provenance and the exact final imagegen prompt.

Final canonical isolated gameplay on this working tree: **5,814 checks, PASS,
exit 0**, with an empty error log and no FAIL/SCRIPT ERROR/ERROR markers.
Evidence: `C:/Users/ayiz/AppData/Local/Temp/tidesworn-tests-167680ae272644ecba9a702cbfa503d4`.
The dock checks also verify that the final E press is consumed before player
physics can immediately reopen the conversation, and that cancelling the actual
Continue handoff cannot enable lessons in its replacement world. `git diff --check`
passes. Saves and rendered captures remain outside the repository; existing user
changes are preserved and nothing was pushed.

### Dock dialogue fade and talking sounds (2026-10-30)

Each complete dialogue line now eases from zero to full opacity over 0.85 seconds.
During the fade Next reads Reveal; tap/E/Space/Enter first reveals the whole line,
then advances on a later press. Back restarts the prior line. Skip/Leave closes
immediately. Reduce Motion uses a 0.18-second fade and resolves an in-flight fade
immediately when enabled. Pages still never advance on a timer.

An owned AudioStreamPlayer plays quiet varied vowel murmurs only while the line
appears. Sfx caches three procedural syllables for Rahim's lower voice and three
for Adam's lighter reply. Soft PCM attack/release avoids clicks. Reveal, natural
fade completion, close and world cancellation stop the voice. Effects/master
volume and mute apply live; slow frames never queue overlapping syllables.
No saved fields, shared combat sounds or dialogue artwork changed.

Focused native Windows reviews passed **69 checks, PASS, exit 0** at both
1280x720 and 832x480, with empty error logs. Inspected matching captures at zero,
half and full opacity. Coverage includes first-tap reveal, second-tap advance,
distinct cached voices, unclipped non-silent PCM with soft edges, indefinite
silent reading, live volume/mute/Reduce Motion and stopping mid-fade.
Evidence: `C:/Users/ayiz/AppData/Local/Temp/tidesworn-tests-78759cf12e254a0a96b363a1ccd4f2a0`
(1280x720) and `C:/Users/ayiz/AppData/Local/Temp/tidesworn-tests-dc2bc47c7aa7476baede103585c0b74b`
(832x480). Native renders use the Dummy audio driver; PCM/routing/lifecycle checks
do not claim a physical speaker or phone listening test.

Canonical isolated gameplay after the fade/voice change: **5,834 checks, PASS,
exit 0**, with an empty error log and no failure/error markers. Evidence:
`C:/Users/ayiz/AppData/Local/Temp/tidesworn-tests-27057e590d284cbf94befb5ccf353723`.
`git diff --check` passes; test user data and captures remain isolated externally.

### Individual word fades and speech pacing (2026-10-30)

Dialogue now reveals whole words in order. Each word fades in over 0.16 seconds;
preceding words stay opaque and future words stay invisible. Speaking intervals
scale with word length, with progressively longer pauses at commas, sentence
endings and ellipses. The complete word layout is reserved up front, keeping
wrapping and positions fixed while opacity changes. The existing Reveal/Next,
Back, Skip, live settings and completion/cancellation ownership remain covered.

Voice syllables now follow new words. Punctuation pauses do not trigger repeated
sounds, and a slow frame only speaks its current word without a backlog. Reduce
Motion compresses the sequence to 0.18 seconds, avoiding rapid repeated audio.

Native Windows focused reviews: **74 checks, PASS, exit 0** at 1280x720 and
832x480, with empty error logs. Captures show the first word half-faded, the first
word fully readable while the second fades, and the completed sentence. Checks
also verify unchanged word positions through successive rendered frames, timing
differences for punctuation/word length, current-word-only audio after a slow
frame, all lines' layout, real keyboard/touch reveal and the existing save flow.
Evidence: `C:/Users/ayiz/AppData/Local/Temp/tidesworn-tests-804f3bd8b448425f82f15db8c3005053`
(1280x720) and `C:/Users/ayiz/AppData/Local/Temp/tidesworn-tests-b4095a05abdc4586b04aaf8a5a5a3214`
(832x480). Audio uses the Dummy driver in these reviews; no physical listening
or phone validation is claimed.

Canonical isolated gameplay after individual word pacing: **5,839 checks, PASS,
exit 0**, with an empty error log and no failure/error markers. Evidence:
`C:/Users/ayiz/AppData/Local/Temp/tidesworn-tests-f8803641f50b4741bb8398b7916fa234`.
`git diff --check` passes. No player saves, exported builds or source art were changed.


## Hide tutorial tips and trail together (2026-10-30)

While training is unfinished, **Hide tips** hides both the tutorial panel and its
world-space dashed guidance arrows. Cached arrows clear on the next process frame,
without waiting for the half-second route refresh, and stay absent across mission
and day/night updates or world changes. **Show tutorial tips** restores guidance
for the current lesson. Hiding tips never completes lessons or changes progression.
After training completes, separate campaign/project navigation remains unchanged;
Twilight Wilds retains its landmark-based exploration with no guidance trail.
`tools/tide_test.gd` checks cached-arrow removal, refresh/update suppression,
restoration and unchanged mission completion.

## Adam's original dock-dialogue portraits (2026-10-30)

Adam now appears on his own replies with three transparent expression assets:
concern while asking after his friends, surprised vulnerability at "Why help?",
and a tentative smile for his final promise. His asymmetrical forward-leaning
pose, lowered arms and sand/ochre clothing were created from a written brief
without image references. Expression edits reference only this new Adam base.
The rejected cup-bearing draft was removed. No gameplay sprite, dialogue wording,
save schema, story suspension or world-input ownership changed.

Native Windows Compatibility-renderer dialogue reviews at **1280x720** and
**832x480** each passed **90 checks, exit 0**, with empty error logs. Captures of
all three expressions were inspected for text clearance, alpha compositing and
consistent framing; compact concern/resolve captures were also inspected. The
checks cover the expression on every line, Back restoring earlier expressions,
matching transparent asset dimensions, word fades, real synthetic touch/keyboard
advance, live presentation settings and New Journey/Continue/cancellation flows.
The audio driver was Dummy; this does not establish physical-device validation
or listening quality.

Evidence: `C:/Users/LUQMAN/AppData/Local/Temp/tidesworn-tests-0b469ca243fd4cfa805ff554c4e16a57`
(1280x720), `C:/Users/LUQMAN/AppData/Local/Temp/tidesworn-tests-450ec21edd2b4d4999d217437620c037`
(832x480). Isolated import completed with exit 0, no script/error markers and the
existing Android build-tools-directory warning.

Canonical isolated gameplay with the final expression assets: **5,950 checks,
PASS, exit 0**, with an empty error log and no `[FAIL]`, `SCRIPT ERROR` or `ERROR:`
markers. Evidence:
`C:/Users/LUQMAN/AppData/Local/Temp/tidesworn-tests-be4ca5d585294c6db091581728cb714b`.
`git diff --check` passes. Player saves were isolated; no exported build was made.

## Collapsible gameplay objectives (2026-10-30)

The gameplay HUD has a left-side objective tracker below the status strip. Its
header collapses to the current goal and remembers the choice in device settings.
It remains non-modal, leaves held movement intact, and updates progress without
reopening. World-specific guidance covers village lessons, danger, workshop work,
Twilight discoveries/checkpoint/boss/peaceful revisits, later arenas and the separate
Kraken-victory/prison-rescue steps. Selection reads existing progression only.

`tools/objective_tracker_checks.gd` is included in the full gameplay gate. The
focused Windows route is `tools/test_isolated.ps1 -Godot <console-executable>
-Objectives`, with optional `-Capture`. It covers raw multi-touch, mouse/keyboard,
gesture cancellation, settings persistence/defaults, read-only updates, retiring
goals, context changes, modal/story suppression, 1280x720 and 832x480 at three UI
scales, relocated controls and first-clear-reminder clearance. See
`docs/OBJECTIVE_TRACKER.md` for ownership and behavior.

Native Windows Godot 4.7.2 focused verification: **58 checks, PASS, exit 0**, with
an empty error log and no failure/script/error markers. Expanded/collapsed village
captures at both resolutions and the realm-exploration capture were inspected;
the compact first-clear reminder no longer overlaps the tracker. Evidence:
`C:/Users/LUQMAN/AppData/Local/Temp/tidesworn-tests-51d409039d5a4d999b7cff2025efb617`.
This is native Windows renderer and synthetic-input evidence, not a physical-phone
test or a rebuilt APK. Isolated import exited 0 with the existing Android
build-tools-directory warning and no script/error markers.

The canonical isolated gameplay gate reported **6,008 checks, PASS, exit 0** with
an empty error log and no failure/script/error markers. Evidence:
`C:/Users/LUQMAN/AppData/Local/Temp/tidesworn-tests-80bf6ce829e84e688b46c0c5ddece8ec`.
This run compiled gameplay before concurrent urchin-arrival edits. The final native
review used a disposable source copy of `b2b3b104` plus the objectives changes at
`C:/Users/LUQMAN/AppData/Local/Temp/objectives-source-5e81ee9b57a74d758a92667ac75301ad/project`.
Tracker, selector, HUD, settings and focused-test sources matched the working copy
by SHA-256. These results validate objectives on that baseline; the ongoing combined
urchin changes require their own gate. The cold copy exceeded the wrapper's first
90-second import budget; completing its cache under a bounded 300-second import
finished successfully before the native review. Existing player saves and settings
were isolated throughout. No exported build was produced.

## Sea urchin shoreline animatic and poses (2026-10-30)

Implemented an original pixel-art shoreline introduction: foam, spines, land
contact, brief wobble/rattle, inland glance, allocated followers and matched
handoff. Game suspends its current Lobby/clock and releases controls for the
first safe introduction; touch Skip and keyboard Skip restore its camera/HUD.
Later shore groups use a running-world eight-second warning. Pending arrival
positions and absolute warning time persist, with defaults/sanitization and
one completion transaction. Cancelled/world-replaced previews never mark the
intro seen or become live enemies. Landing points are checked against geometry
and routes, then revalidated before delivery.

Urchin-specific cached poses cover movement, windup, active, recovery and death
over the existing Enemy FSM. Stats, attack/cooldown timing, target rules, world
collision, one-hit claims and one-payment rewards remain intact. Low effects,
live Reduce Motion and mute have focused coverage. This implements arrival
presentation on the existing dusk wave; randomized quiet/forest/shore/mixed
night profiles remain a separate plan, not shipped behavior.

Verification on native Windows / Godot 4.7.2:

- Canonical isolated gameplay: **6,058 checks, PASS, exit 0**, empty error log.
  This includes the concurrent objective tracker and sea-urchin checks.
- Native Compatibility/OpenGL rendered reviews at **1280x720** and **832x480**:
  **51 checks, PASS, exit 0** each, with empty error logs. Inspected storyboard
  samples, compact group framing, low/Reduce Motion and combat pose captures.
- Focused checks cover one/two/three-member batches, Skip at all eight storyboard
  sample times, actual touch Skip, saved survivors, reconstruction of a partially
  elapsed warning, duplicate phase/completion callbacks, blocked landings,
  malformed saved fields, world replacement and one actual hit/reward.
- The first full run exposed the final forest fixture selecting a sapling from
  a retiring world. The arrival checks now wait for retiring worlds to leave;
  the last-stand test explicitly uses its active Lobby's trees. The final run
  verifies both protected sapling survival and the actual all-trees-lost ending.
- Isolated import passed after repairing an initial parse error; the existing
  Android build-tools-directory diagnostic remains. `git diff --check` passes.
  Reviews used Dummy audio; listening quality and physical-phone operation are
  not claimed. No exported build was made.

Evidence:
`C:/Users/LUQMAN/AppData/Local/Temp/tidesworn-tests-eebfbba9a83c48af9a2b87b0edc8e641`
(full gate), `C:/Users/LUQMAN/AppData/Local/Temp/tidesworn-tests-171771c313a3455a8d0668079a856e35`
(1280x720), `C:/Users/LUQMAN/AppData/Local/Temp/tidesworn-tests-89d587ff8dcf4e939a06adf4f71e3058`
(832x480), `C:/Users/LUQMAN/AppData/Local/Temp/tidesworn-tests-f5f180c862c9487686c5a57edb3d83ec`
(successful import). `docs/SEA_URCHIN_ARRIVAL.md` records runtime ownership and
the isolated `-Urchin -Capture` review route. The optional GIF preview assembles
eight rendered storyboard samples; it is not a continuous gameplay recording.


## Objectives left-edge tab and shared Hide tips choice (2026-10-30)

The objective tracker now retracts horizontally to a narrow `›` tab flush with
its screen's left edge; expanding restores its scrollable objective cards.
Default device settings start folded. Existing explicit collapse preferences
are preserved. Folded content no longer leaves a full-width objective summary
on screen. Header input remains non-modal, supports mouse/keyboard and a separate
touch finger, and retains a minimum 44-physical-pixel target at the reviewed
sizes/scales. The tooltip tracks the immediate objective; urgent guidance also
colors the tab without reopening it.

`TutorialGuide._skip()` (Hide tips) now persists the device-level boolean
`GameSettings.tutorial_hidden`. Both the tutorial card and village objective
selection respect it. Hidden training omits lesson and wait-for-day/night rows
and falls through to eligible village work and outstanding rescue goals, while
recovery/urgent defense and world-specific exploration/boss guidance remain.
It does not complete lessons, clear portals, grant rewards or bypass project
prerequisites. Automatic startup/Continue respects the saved choice. The existing
Menu > Show current mission tips action explicitly resets it and restores both
surfaces. Defaults/sanitization include the new preference; it is not save-game
progression. Older releases did not persist Hide tips, so an unrecorded historical
choice cannot be reconstructed.

Verification:

- Canonical `./tools/test_isolated.sh` on the updated checkout: **6,076 checks,
  PASS, exit 0**, with no `[FAIL]`, `SCRIPT ERROR` or `ERROR:` markers.
  Additional art edits appeared during that run in `monsoon_art.gd`,
  `world_composition.gd`, `monsoon_checks.gd` and `docs/ART_DIRECTION.md`; they
  were preserved, and this gate does not certify their latest bytes. The focused
  objective suite was rerun on the latest checkout: **76 checks, PASS, exit 0**.
- Focused rendered objective suite: **76 checks, PASS, exit 0**, with no `[FAIL]`,
  `SCRIPT ERROR` or `ERROR:` markers. Inspected expanded/collapsed and hidden-tip
  captures, including 1280x720 and 832x480. Layout/input checks cover 75%, 100% and
  130% UI scale, customized joystick position, raw second-finger touch, mouse,
  keyboard, focus loss, held movement and modal/world changes.
- Added coverage for immediate training suppression, hidden phase-wait guidance,
  day-phase changes, persisted preference reload, automatic startup, unchanged
  journey data, retained urgent defense and the actual Menu re-enable button.
- Same-input behavioral probe before/after/rollback: baseline starts expanded and
  collapses to a 320-wide summary at x=22, still showing `lesson_move` after Hide
  tips; modified starts folded as a 64-wide tab at x=0 and shows `arjun`/`mei_ling`
  after Hide tips. Neither path completes training or mutates progression; urgent
  defense remains. Separate-copy rollback reproduces the literal baseline probe
  output and all nine original SHA-256 hashes.
- Initial regression fixtures assumed the first lesson was still movement and
  inspected Menu buttons before its deferred rebuild; corrected fixtures use the
  actual current lesson and wait for native modal layout. Two stale full-gate
  attempts were stopped on their owned test processes and are not claimed as PASS.
- Linux Godot 4.7.2 Compatibility/OpenGL via Xvfb/llvmpipe, Dummy audio. Input-method
  and unsupported V-Sync warnings remain; no physical-phone, Windows, export or
  listening-quality validation is claimed. Import retains the existing Android
  build-tools SDK fallback diagnostic. Live saves/settings remain isolated.

Evidence and verified rollback:
`/tmp/tidesworn-objectives-left-B63fCJtC/VERIFICATION.txt`.


## Main and side quest sections (2026-10-30)

The existing objective accordion now renders two explicit, counted sections:
**MAIN QUESTS** (gold) and **SIDE QUESTS** (teal). Recovery/urgent village defense
is grouped separately as **NEEDS ATTENTION** above both. The same left-edge tab,
device collapse preference, raw-touch/mouse/keyboard header handling, non-modal
input ownership and world/context visibility guards remain unchanged.

Presentation classification is explicit in each read-only entry's `section`
field (`main`, `side`, `priority`), not inferred from translated display tags.
Missing/unknown categories fall back to main for older callers. Main quests cover
current training when tips are enabled, both outstanding rescue arcs and local
expedition/realm progression. Side quests cover the eligible West Workshop,
discovered optional wild companions and peaceful restored-realm/village care.
Training and the rescue arcs can coexist; hiding tips still omits only training
and phase-wait guidance, not either rescue. Workshop eligibility, purchase gates,
pet discovery/bonding, rescue conditions and rewards remain GameState-owned.

Removed the old three-row truncation. In the concrete village fixture, danger +
workshop + both rescues previously produced `defend, workshop, arjun`, silently
dropping Mei Ling. It now produces `defend, arjun, mei_ling, workshop`, grouped as
priority/main/main/side. Stable ordering keeps urgent action first, then story,
then side work. Per-section counts exclude urgent duties. Native containers hold
cards under their correct heading, with truthful empty main/side states rather
than invented tasks. The one bounded vertical scroll retains access to lower
side quests without overlap or sideways scrolling. Folded tooltips include main
and side counts. Progress-only refreshes retain card nodes and scroll state;
changing a stable entry's category correctly reparents it.

Verification:

- Canonical `./tools/test_isolated.sh` on the current checkout: **6,151 checks,
  PASS, exit 0**, without failure/script/error markers. Script, scene and resource
  hashes remained unchanged throughout this run, including the existing art edits.
- Focused Compatibility/OpenGL objective suite: **106 checks, PASS, exit 0**,
  with no failure/script/error markers. New checks cover section membership,
  counts, card parenting, urgency without truncation, retained rescue arcs,
  empty/completed/undiscovered states, hidden training, workshop prerequisites,
  realm companion discovery/bond retirement, reclassification and read-only
  refreshes. Existing collapse, input ownership and settings checks remain.
- Inspected expanded main/side and scrolled side captures at **1280x720** and
  **832x480**. All six size/UI-scale combinations (75/100/130 percent) prove the
  side heading is reachable, panel/control separation, no horizontal scroll and
  retained 44-pixel folded-header touch targets. Linux Xvfb/llvmpipe only, with
  the existing input-method and V-Sync warnings; no phone/Windows/export claim.
- Same-input baseline/modified/rollback probe confirms the above ordered IDs,
  new explicit categories and native section containers. Hide tips mutates no
  progression and the existing collapse preference is unchanged. Separate-copy
  rollback restores all five stage-baseline SHA-256 hashes and literal output.
- This extends the previous four artifact roles in place. Earlier transaction
  records are retained under `history/left-tab`. The default `ROLLBACK.sh` now
  restores only this section change to its committed left-tab baseline;
  `--previous` retains the original left-tab rollback. The latest patch is scoped
  to the five section-change source/test/documentation files. Unrelated ongoing
  art edits are preserved and never included in that patch.

Evidence: `/tmp/tidesworn-objectives-left-B63fCJtC/VERIFICATION.txt`.


## Proximity side-quest introductions (2026-10-30)

Three concrete optional objectives currently exist: the West Workshop restoration
(`west_workshop`, introduced as `workshop`), Bramble Cat at Bramble Grove and Dusk
Moth at Moonpool Hollow. Restored-Wilds exploration and Care for BESUT are ongoing
guidance, not additional authored quest arcs.

Implemented the overheard/discovery variant, not NPC walk-up choreography. Near
Bram's actual Construction Shop counter, the player overhears his workshop idea;
near the workshop, Adam notices Bram's posted invitation. Near each unowned,
unbonded habitat companion, a short ambient discovery conversation introduces
its optional manual challenge. No introduction teleports or repositions an NPC,
starts construction, starts a pet battle, purchases equipment or grants rewards.
The actual shop/workbench/pet interactions keep their existing authority.

Game polls proximity on a bounded 0.3-second cadence and checks current world,
journey, ownership, player locks/attack/sleep, menus, story, transition, sailing,
defeat/game-over, home interior, settlement editing, recovery/emergency and local
danger. Village introductions defer at night. Nearby living threats and burning
trees defer interruption; active realm combat/boss/rest/reading ownership does
likewise. Authored world actors/positions drive detection; moved shops/workshops
are not replaced with canonical coordinates.

A discovery is an explicit story exception: Game releases held world controls,
zeros player velocity, locks the player, suspends only its current world and
holds the authoritative clock. It reuses the existing readable DialoguePanel,
including its close button, keyboard close and compact layout. Closing/early
leaving restores the original process mode and input ownership. Normal shop and
NPC dialogue menus retain their ordinary non-pausing rules. World replacement
cancels the introduction without recording it or unlocking a replacement world.

GameState alone writes `side_quest_intros_seen`: a default-empty, sanitized,
allow-listed array of three stable introduction IDs. Successful/early close
records heard status once per journey, not quest completion. Actual JSON save/load
preserves it; duplicates, unknown IDs and invalid containers are normalized. New
journeys reset it. Completed workshop work and already-owned/bonded companions
do not receive recruitment/project invitations. Existing legacy working projects
are not reintroduced as pending commissions.

Verification:

- Canonical isolated gameplay gate: **6,185 checks, PASS, exit 0**, with no
  `[FAIL]`, `SCRIPT ERROR` or `ERROR:` markers on the updated checkout.
- Focused rendered suite: **36 checks, PASS, exit 0**, including workshop/counter
  variants, real automatic proximity polling, immediate stop/held-input release,
  non-global world/clock suspension and restoration, no nested/repeated dialogue,
  no quest acceptance/rewards, actual save/load, malformed persistence, nearby
  enemies/fires, night/menus/attacks/other locks, cancelled world handoff and both
  habitat companions. Captures at 1280x720 and 832x480 were inspected.
- Ordinary acceptance fixtures explicitly disable unsolicited introduction
  polling to isolate their existing scenarios; the dedicated checks exercise the
  enabled polling path and real map actors. Existing gameplay gate includes those
  dedicated checks without capture-only layout assertions.
- Same-input baseline/modified/rollback probe: baseline/rollback do not trigger
  a proximity dialogue; modified locks the player and owns the story dialogue,
  then records only `workshop` heard status and restores controls on Close. The
  project status stays identical in all three. Four original files and seven
  originally absent paths are restored/removed by the scoped rollback.
- Linux Godot 4.7.2, Xvfb/llvmpipe and Dummy audio only. Input-method/V-Sync warnings
  remain. No voiced dialogue, native Windows, phone or export validation claimed.

The same four artifact roles are extended in place; the previous stage is saved
under `history/quest-sections`. Default rollback undoes only these introductions;
`--previous` delegates to the older section rollback. Evidence:
`/tmp/tidesworn-objectives-left-B63fCJtC/VERIFICATION.txt`.


## 2026-10-30 — Mei Ling held by Shadow & Chaos Fiend

This supersedes the earlier Abyss Monarch/final-portal rescue requirement.

- `PortalDB.MEI_LING_PORTAL` binds her captor to Chaos Citadel / `tidebound_grotto`.
  `GameState.complete_portal()` records `campaign.mei_ling_rescued` with the clear
  rewards, before saves/signals, and reports the one-time rescue in its summary.
- Defeating the actual first boss shows Mei Ling's player-paced rescue scene.
  Its close restores peaceful exploration, not a forced exit or victory modal.
  She is already saved and joins BESUT once as a bow defender on return.
- Old first-clear saves credit the moved rescue during sanitization, with no
  extra currency, XP, pets, attempts, story replay or boss respawn. Existing
  rescued flags persist. Uncleared saves do not gain a rescue.
- Later bosses retain rewards and progression gates as optional challenges;
  neither owns her rescue. Arjun still requires the Kraken/prison route.
- Dedicated isolated `tools/mei_ling_rescue_test.tscn` and its shared checks cover
  transactions, migrations, repeats, actual boss/story/input lifecycle, peaceful
  revisit, one village archer and Mei Ling-first reunion. `StoryChecks` covers
  Arjun-first reunion through the actual first-realm boss. The full gate invokes
  both; tutorial/title/guide/objective fixtures use the new rescue ownership.

Validation results are recorded after execution in the external verification ledger.

## Individual fire portals and coordinated shore/forest reveal (2026-10-30)

Every newly allocated village fire monster, including emergency additions, now
has its own small ember portal at a separately validated land position. Cached
pixel poses show ember, opening seam, core, narrow crossing, low reformation and
tree attention. Portals seal behind their individual occupants. Saved survivors
restore directly without replaying an entrance. Fire combat and burning remain
silent, with existing stats, targeting, collision, damage timing and rewards.

Game coordinates one first-arrival presentation: shore-only remains eight seconds,
fire-only lasts 10.5 seconds, and both first introductions share 14.5 seconds with
a covered shore-to-forest cut, one Skip control and one return to Adam. Both species
stay cosmetic until the final delivery. All shore followers finish landing before
handoff; fire feet, facing, rest textures and opacity match their real bodies.
Later arrivals and reinforcements use an eight-world-second environmental warning
without taking controls or camera. Mixed captions show separate species bearings
and reserve space clear of the objectives.

GameState owns independent seen flags, stable pending batch identities, fixed
numeric fire points and warning origins. The ordinary wave and emergency fire
reservations save independently. Exact-batch delivery captures survivors and
completion in one synchronous transaction. Legacy saves/pending waves migrate;
blocked points, duplicate callbacks, dawn and replaced worlds cannot duplicate
enemies or mark unsuccessful introductions seen. The historical 64-tree forest
fixture and construction RNG remain unchanged. Variable night profiles are still
a separate proposal.

The canonical gate now includes `tools/fire_arrival_checks.gd`. The Windows
`-Fire` review runs both the existing sea-urchin suite and new fire/combined checks;
`-Capture -Resolution 832x480` / `1280x720` produce consecutive storyboard samples,
the bridge, follower reveal, repeat warning, low effects and live Reduce Motion.
Coverage includes one/three/eight/24 fires, six reinforcements, Skip across both
chapters, actual file save/load, legacy/malformed records, pending reinforcement
restoration, blocked handoff, world replacement, dawn, one real ignition, continued
burning after the attacker dies, watering and exactly one death payment.

Verification results for the completed implementation are recorded below.
See `docs/FIRE_MONSTER_ARRIVAL.md` for runtime ownership and review commands.

- Canonical isolated gameplay on the combined checkout completed **6,153 checks,
  PASS, exit 0**, with an empty error log and no failure/error markers. Evidence:
  `C:/Users/ayiz/AppData/Local/Temp/tidesworn-tests-03533bc05371478294e5ca8eae39bd5f`.
  This includes the concurrent Dimension Portal origin work as well as both
  sea-urchin and fire/combined arrival suites.
- Native Windows Godot 4.7.2 Compatibility/OpenGL captures at **832x480** and
  **1280x720** each completed **111 checks, PASS, exit 0**, with empty error logs.
  Consecutive samples were inspected for the crossing, sealed lead portal,
  individually staggered followers, camera return, low/Reduce Motion and the
  nonoverlapping, separately directed repeat warning.
- Focused evidence: `C:/Users/ayiz/AppData/Local/Temp/tidesworn-tests-891d42ea69084154a181d8f114f2a09f`
  (832x480), `C:/Users/ayiz/AppData/Local/Temp/tidesworn-tests-3ead33ce2853457eafd5c28267f04c64`
  (1280x720). These runs include the final all-shore-followers-landed handoff check.
- An isolated import completed with exit 0. The existing Android build-tools
  directory diagnostic remains; no release export or physical-phone validation
  is claimed. Reviews use Dummy audio; no listening-quality claim is made.
- Initial focused attempts exposed a test type-inference error, overly exact JSON
  float comparison and an injected collider removed by suspended-parent ownership.
  Those fixtures were corrected and rerun. Render inspection also corrected the
  lead canopy overlap, warning placement/bearings and completed shore-group pose.
- Earlier full-suite runs overlapped unfinished Dimension Portal changes. After
  their compile/fixture corrections, the final run above passed. Existing village
  combat fixtures explicitly complete the new warning before examining live
  attackers; the day/night cleanup also captures its removed shore threats so a
  later fixture cannot resurrect them from an older snapshot. `git diff --check`
  passes; Git reports existing LF/CRLF conversion notices in other modified files.

## The road remembers — portal awakening (2026-10-30)

New journeys now begin with a fallen waystone instead of an already usable
Dimension Portal. Nearby tap/E records its broken road and empty lantern socket;
Rahim's contextual dock conversation lends a village lantern freely. Completing
or explicitly skipping the exchange prepares a nearby repair interaction. A
single eight-second, Game-owned reveal aligns the marker, lights its carving,
shows an answering forest road and forms the portal. Opening leaves Adam in the
village and does not start an expedition or award/spend currency, items or XP.

- Origin state is owned by GameState and saved before the presentation. Old raw
  saves without origin fields retain access. Active expeditions/realm presence
  reconcile contradictory closed flags; future numeric schemas are rejected
  without writing. Interrupted reveals leave the road usable with optional replay.
- The actual dock welcome is unchanged. Later discovery/ready/open conversations
  remain non-pausing; cancelled chats cannot grant the lantern. The reveal alone
  suspends world/clock and owns camera, HUD, overhead-vital visibility and inputs.
- Hidden gate/map pictures, discovered-waystone markers, daytime tutorial entry,
  Missions/objectives, early guide text and Wisp's first recognition agree with
  the player's discovery. E/main gate input enters after opening; optional replay
  has a separate button. Local danger and arrival ownership cannot compete with
  the reveal. No monster kill or quiet-night outcome gates this progression.
- The existing Twilight combat, manual pet arena, checkpoint, loot/defeat rules,
  peaceful restoration, later campaign arenas and both rescues remain covered.

Final Windows verification with Godot 4.7.2:

- Canonical isolated gameplay: **6,153 checks, PASS, exit 0**.
- Focused headless origin: **36 checks, PASS, exit 0**.
- Native rendered origin: **36 checks, PASS, exit 0** at each of **1280x720** and
  **832x480**. Inspected broken stones, dock dialogue, lantern, answering road,
  forming arch and completed gate. Native input covers real discovery taps and
  the actual Skip button; both modes cover nearby E, saved intermediate stages,
  cancellation, optional replay/world replacement and entry into Twilight Wilds.
- Final full/focused stderr files are empty, with no FAIL, SCRIPT ERROR or ERROR
  markers. Isolated import passes with the existing Android build-tools warning.
  git diff --check passes; existing checkout line-ending notices are unchanged.
  Player saves are isolated; no Android export or physical-device test is claimed.

Evidence below C:/Users/ayiz/AppData/Local/Temp/:

- Full gate: tidesworn-tests-cbfbbf2aad9f4db28c985aa2d731a2b3.
- Headless origin: tidesworn-tests-0f588243e4b54cb1ada260340b870bc5.
- Native 1280x720: tidesworn-tests-944f6fe6ad5e4d5f8725836a75bf7c70.
- Native 832x480: tidesworn-tests-0bc8f0816295443eb1eefa6d930c9e5d.
- Isolated import: tidesworn-tests-b8784c2b03504968bf6d601ba756c22f.

Reproduce with tools/test_isolated.ps1 -Godot <console-executable>, or add
-PortalOrigin for the focused scene and -Capture -Resolution 832x480 / 1280x720
for native review. See docs/PORTAL_AWAKENING.md for the runtime contract.

## Decorated waystone discovery cue (2026-10-30)

The fallen waystone now has a chipped pale-stone ring, moss, engraved stepping
stones curving toward the cottage gap, moonblooms and weathered wayfarer ribbons.
A small socket glimmer gives the unopened site a readable focus; it warms after
Rahim lends the lantern and retires when the road opens. The stone/flower/cloth
silhouettes and one steady glimmer remain under low effects and Reduce Motion.
The dressing adds no collision, terrain changes, gameplay RNG, progression writes,
extra light sources, rewards or new interactions.

- Native focused origin reviews: **39 checks, PASS, exit 0** at **1280x720** and
  **832x480**, including actual discovery taps, nearby E, Rahim's conversation,
  the reveal/Skip, save/reload, optional replay, world replacement and portal entry.
  Inspected the wider approach, low-motion/low-effects cue, quiet night-lighting
  fixture and completed gate. This is native Windows evidence, not a phone test.
- Focused objective tracker: **106 checks, PASS, exit 0**. Integration fixtures
  now retain waystone discovery when Hide tips removes training, reconcile legacy
  rescued-friend flags as loading does, and start rescue-only combat after the
  already-tested awakening prerequisite. Production rescue/quest rules are unchanged.
- Evidence in C:/Users/ayiz/AppData/Local/Temp/: native 1280x720
  tidesworn-tests-bf96f1f0dc0c424e80ddbb919eaab306; native 832x480
  tidesworn-tests-0bb635c6b3584cbebd9b2400011bedb0; objective tracker
  tidesworn-tests-5748be5572044e0e851289c38db79b96.
- Canonical gameplay on the combined current checkout: **6,297 checks, PASS,
  exit 0**. Evidence: tidesworn-tests-392a646fb733426785cd18dafb7199eb below the
  same external temporary directory. Final full/focused error logs are empty,
  with no FAIL, SCRIPT ERROR or ERROR markers. git diff --check passes with
  existing LF/CRLF notices. All runs isolate player data; no device export was run.

## Mei Ling - the citadel opens (2026-10-30)

Shadow & Chaos Fiend's arena now contains Mei Ling in a visible sealed stone
prison. Defeat starts seven authored shots over 24 seconds: collapse, breaking
seal, opening gate and grounded steps, Adam's reaching hand, an Arjun-aware
exchange, Mei Ling arriving in BESUT, and Adam remaining in the restored citadel.
The close shots share the prison's identity with the world scenery; the village
insert is an illustration, not an active second world.

- Rescue, clear and first rewards remain committed before presentation. Skip,
  natural completion and repeated signals cannot revoke or duplicate them.
  Old first-clear saves keep their rescue migration and peaceful revisits.
- The real world/clock suspend during the story. Game owns a single StorySequence
  and cancellation, with world/journey checks before restoring HUD and controls.
  The ordinary boss corpse is hidden while its fade tween is suspended.
- The gate clears before Mei Ling crosses it. Consecutive frames check release
  continuity and hand contact. Both rescue orders use truthful Arjun dialogue;
  he appears in the village insert only if already rescued. The normal ending
  still waits for Adam's real return to BESUT, and defender IDs remain unique.
- Essential action remains in low effects and Reduce Motion. Turning motion off
  during a shot latches composed poses until the scene completes. Mute changes
  no progression. Next/Skip require fresh input after the killing action; primary
  touch and its emulated mouse press are debounced into one beat advance.
- Stale "final portal boss" NPC copy and post-rescue Missions guidance are fixed.
  The dedicated rescue fixture now explicitly starts after portal awakening.

Validation also exposed two fixture issues: the opening art test temporarily
changes an existing story's kind, so Mei-only caption decoration must be optional;
and the full arrival suite can reach its late-return assertion before the first
idle tick. Its setup now explicitly processes that cue once, as its earlier reload
fixture already does, without changing arrival timing or weakening its checks.

Windows review uses `tools/test_isolated.ps1 -Godot <console-executable>
-MeiRescue`, with `-Capture -Resolution 832x480` or `1280x720` for actual-renderer
captures. Full gameplay and Twilight validation use the same isolated wrapper.
All review artifacts remain outside the repository; unrelated export/Android
planning and objective-tracker edits belong to the existing workspace work.

Windows Godot 4.7.2 verification:

- Canonical isolated gameplay: **6,335 checks, PASS, exit 0**. Its first attempt exposed
  the fixture issues described above; the corrected run has no failure/error markers.
- Focused rescue headless: **65 checks, PASS, exit 0**.
- Native rendered rescue: **65 checks, PASS, exit 0** at each of **832x480** and
  **1280x720**, using the Compatibility renderer on AMD Radeon Vega 3. Inspected
  captive arena placement, all seven beats, consecutive opening/step/contact/rift
  frames, reduced motion and the Arjun-present arrival insert. Real mouse, primary
  touch and focused keyboard events each advance one beat.
- Focused Twilight: **197 checks, PASS, exit 0**; focused fire arrival:
  **68 checks, PASS, exit 0**. The final full suite covers the deterministic
  late-return setup fix and the boss-corpse cleanup as well.
- Isolated import passes with the existing `Unable to open Android 'build-tools'
  directory` warning. Final rescue/full runtime stderr files are empty.
  `git diff --check` passes. This is native Windows evidence, not an Android
  export or physical-phone test.

Evidence below `C:/Users/LUQMAN/AppData/Local/Temp/`:

- Full gate: `tidesworn-tests-20cdde42238a485aac3ae624a2e9200d`.
- Rescue headless: `tidesworn-tests-17d94ab5242f4193abb47ed5351980f6`.
- Final 832x480: `tidesworn-tests-b97171e19b5a473a91182b015ade734f`.
- Final 1280x720: `tidesworn-tests-4134c56faa8d4b19b96f29e579f2dc00`.
- Twilight: `tidesworn-tests-f51c7bb2cc39454cafc994341168b66b`.
- Fire: `tidesworn-tests-69d02a0909514043b8c4b1d144bd808b`.
- Import: `tidesworn-tests-dee056d0ef64435db6cd568f1938199d`.

## Three friends, one table - reunion dialogue (2026-10-30)

The former three-caption ending is replaced by thirty named dialogue turns across
seven animatic beats: recognition, Arjun's apology, their separation, a shared
plan, thanks to BESUT, practical preparation and familiar company. An eighth,
wordless dock tag shows the moored UNISZA ship, a supply bag and the friends
checking a rope. It hints at another journey without selecting a destination.

- Readers control the pace. Text reveals gradually; Next first reveals the line
  and a fresh activation advances it. Primary touch/emulated mouse is debounced.
  Skip conversation preserves the two-second dock tag before Continue completes.
- Copied finite unarmed poses support sitting, listening, gestures, cups, rising
  and preparation. The benches remain after the group stands. Courtyard/dock day
  and night art follow the captured shared clock. Reduced motion and low effects
  retain essential events, speakers and legible text.
- The active dialogue owns its procedural voice. New turns, complete reveals,
  mute/zero volume, focus loss, Skip and cancellation stop it. No recorded voice
  acting is required; muted pictures and captions carry the complete conversation.
- Game owns a safe retry for the pending reunion. One missing friend, sailing,
  Arjun still returning, transitions, defeat/recovery, modals and nearby enemies
  prevent entry. A safe retry starts it without consuming its completion early.
- Existing `ending_seen` persistence remains. Finishing saves it; cancellation
  does not. Already-completed saves do not repeat it. The dock illustration cannot
  move live actors, board the ship, award rewards or change ocean checkpoints.
- Both rescue orders retain the shared conversation and independent defender IDs.
  Campaign/Field Guide copy now describes the reunion and next preparations rather
  than a permanent-settlement promise or THE END card.

`tools/reunion_checks.gd` is part of the canonical gameplay gate and the focused
`tools/reunion_test.tscn`. Windows uses `-Reunion`, with optional `-Capture` and
`-Resolution 832x480` / `1280x720` under `tools/test_isolated.ps1`. Review output
stays in its printed isolated temporary directory. Initial fixture input injection
was corrected to release at a stored pointer coordinate after the final button
freed itself, and to refresh button state after manually sampled dock shots.

Windows Godot 4.7.2 verification:

- Canonical isolated gameplay: **6,410 checks, PASS, exit 0**. The earlier full
  attempt exposed four fixture input failures: without captures, pointer injection
  reached the first button before its container layout settled. The helper now
  waits for that layout in both native and headless modes; the assertions remain.
- Focused reunion headless: **62 checks, PASS, exit 0**.
- Native reunion at **832x480** and **1280x720**: **62 checks, PASS, exit 0** each.
  Inspected all conversation beats, the named-speaker layout, day/night variants,
  consecutive walking/settling/rising frames and dock preparation. Real mouse,
  primary touch and keyboard events cover reveal-first and fresh-turn activation.
- Full/focused runtime stderr files are empty and contain no failure/error markers.
  The final full gate also covers the real sea disembarkation, both rescue orders,
  saved ending compatibility, unique village defenders and the citadel rescue.
- Isolated import passes, retaining the existing `Unable to open Android
  'build-tools' directory` warning. `git diff --check` passes. Captures use the
  native Windows Compatibility renderer on AMD Radeon Vega 3. No Android export,
  physical-phone validation or new sailing destination is claimed here.

Evidence below `C:/Users/LUQMAN/AppData/Local/Temp/`:

- Full gate: `tidesworn-tests-c74ae44a19934cc08d5ce19ff169dc94`.
- Headless reunion: `tidesworn-tests-93adad76d5fe4d728b8ea1449441959b`.
- Final 832x480: `tidesworn-tests-0742bacc367c4b98a44d7a2ed7241d51`.
- Final 1280x720: `tidesworn-tests-4072490838634c28a8f07fcc5c187336`.
- Import: `tidesworn-tests-0f6d007219ca4fc1ae2c11ca125d38da`.

## Two sea levels and shark introduction (2026-10-30)

The turtle journey contains exactly two 45-second levels. Level 1 supplies bombs,
rubbish, heart pickups and fish. Level 2 retains all four and adds shark hazards;
the decorative megalodon is also hidden until level 2. The shared stage count
drives checkpoint sanitation, actual onward travel, the HUD portrait timeline,
campaign objectives, the Field Guide and Arjun's locked title-card requirement.
The first completion saves checkpoint 2 before departure. The second carries
Adam straight into Kraken Island, where the boss and separate prison interaction
remain required. Lives, fullness, rubbish penalties and retry reset rules retain
their existing behavior.

`tools/ocean_levels_checks.gd` runs in the canonical gameplay gate and the focused
`tools/ocean_levels_test.tscn`. Windows supports `-OceanLevels`, with optional
`-Capture -Resolution 832x480` or `1280x720`. Coverage exercises real timer-driven
spawning in both levels, the shared shark-spawn guard, background visibility,
seven-second initial shark delay, HUD progress, automatic level travel, checkpoint
reload, retry and the actual Game-owned Kraken Island transition. An old level-3
JSON save loads at level 2 while preserving currency, pets and rescued friends.
The first review exposed a fixture comparison between pre-save integer values and
JSON-loaded numeric values; comparing normalized JSON values fixes the assertion
without altering production save handling.

Windows Godot 4.7.2 verification:

- Final canonical isolated gameplay: **6,424 checks, PASS, exit 0**, with no
  `[FAIL]`, `SCRIPT ERROR` or `ERROR:` markers and an empty runtime stderr file.
- Native focused review at **832x480** and **1280x720**: **22 checks, PASS,
  exit 0** each. Inspected the Sea Guide, level-one/four-object and
  level-two/five-object layouts, two-part progress and actual Kraken arrival.
  Both runtime stderr files are empty.
- Isolated import: **exit 0**, retaining the existing `Unable to open Android
  'build-tools' directory` warning. This is native Windows gameplay evidence;
  no new Android export or physical-phone testing is claimed.
- The first full attempt was correctly rejected despite its stdout PASS summary:
  an older presentation fixture still requested a shark at level 1 and accessed
  the rejected spawn's empty result. Presentation checks/review setups now place
  their complete five-object catalog at level 2, retaining the assertions and
  the production level-one shark guard.

Evidence below `C:/Users/LUQMAN/AppData/Local/Temp/`:

- Full gate: `tidesworn-tests-89d8ef58b80c4c7b8a8b68fb6ea9cb5d`.
- Final 832x480: `tidesworn-tests-1dbeb1439c0f435b915d66986b3bf437`.
- Final 1280x720: `tidesworn-tests-8c23f6a9736d487392e71ed8a55057f4`.
- Import: `tidesworn-tests-9d69ada5a730439491b27ce337e5c4d1`.

## Crab monsters at Kraken Island (2026-10-30)

Four KrakenCrab enemies occupy clear fixed fortress posts. They use Enemy's
movement, attack warning/active/recovery, stagger, collision, damage and loot
systems, with a skittering personality, original cached crab pixel art and an
existing illustrated crab atlas mapping. Guards have 48 HP, 7 base damage and
a 1.6-second attack interval. They cannot act against a different current world.
The Kraken's defeat makes surviving guards stop combat and retreat without kill
or loot rewards, preserving the separate unlocked-prison interaction for Arjun.
Each island visit constructs one fixed set; there is no mid-fight respawn loop.

`tools/kraken_crab_checks.gd` extends the canonical gameplay and focused
`-OceanLevels` routes with obstacle/arrival clearance, aggro/chase, warning before
damage, one hit per swing, interruptible windup, world-ownership protection,
one-payment loot, retreat cleanup and cage-state checks. A first fixture assertion
looked for Gold after a nearby Adam had already collected it; the final assertion
observes the actual drop entering the world, retaining the one-drop requirement.

Windows Godot 4.7.2 focused native review at **832x480** and **1280x720** each
reports **36 checks, PASS, exit 0**, with empty runtime stderr. The actual island
arrival and post-defeat captures were inspected at both sizes. Isolated import
exits 0 with the existing Android build-tools directory warning. No Android export
or physical-phone test was performed for this change.

Final canonical isolated gameplay: **6,438 checks, PASS, exit 0**. The wrapper
confirms no failure/error markers; runtime stderr is empty. This also exercises
the two-level sea journey, real Kraken combat, separate prison rescue, both
friend-rescue orders and reunion. `git diff --check` passes.

Evidence below `C:/Users/LUQMAN/AppData/Local/Temp/`:

- Full gate: `tidesworn-tests-f9625ae006314c52a845de854f1b4f2d`.
- Native 832x480: `tidesworn-tests-3d662f6d8b564a688887533713236890`.
- Native 1280x720: `tidesworn-tests-800b9e059a964226957b4036c7668a4d`.
- Import: `tidesworn-tests-a93b73798ad9438a8e082d2553c1149e`.

## Ten crabs and immediate Kraken arena combat (2026-10-30)

Kraken Island now constructs ten guards at fixed, obstacle-free posts. Entering
the arena immediately sets all ten crabs and the Kraken to active pursuit of the
current island player. Distant guards do not wait for a proximity trigger or
return to wandering after losing range. The Kraken begins his first tentacle
warning after 0.6 seconds; normal attack warnings, movement and dodge windows
remain. The arrival space stays clear of overlapping monsters. Existing crab
stats, loot, retreat on boss defeat and the separate prison interaction remain.
Kraken attacks now also check active-world ownership before advancing.

The focused `-OceanLevels` review checks all eleven active enemies at entry,
distant-crab pursuit, automatic opening tentacle warnings, combat, one-payment
loot, retreat and both kinds' world-ownership guards. The King's exact timing
fixture suspends crab physics while testing his melee/tentacle damage in isolation;
the combined encounter is covered by the focused crab checks.

Windows Godot 4.7.2 native focused reviews at **832x480** and **1280x720** each
report **38 checks, PASS, exit 0**, with empty runtime stderr. Both arrival
captures were inspected: ten crabs plus the King are present and the arrival
space remains clear. Isolated import exits 0 with the existing Android build-tools
directory warning. `git diff --check` passes. No Android export was performed.

Evidence below `C:/Users/LUQMAN/AppData/Local/Temp/`:

- Native 832x480: `tidesworn-tests-21bd47f8b8cc472aafc870680cbe7944`.
- Native 1280x720: `tidesworn-tests-0f7b6f74e1c34d489400ce0d1b000abf`.
- Import: `tidesworn-tests-9b5d391aef5f45f7bc001b2a321b20e0`.

The ten-crab/immediate-combat canonical gate also passed **6,440 checks, exit 0**,
with empty runtime stderr, before the subsequent sea-completion change below.
Evidence: `tidesworn-tests-5a3a1c0b0537422aa687cb13fac76b2d`.

## Sea journey closes after Arjun's rescue (2026-10-30)

Freeing Arjun permanently closes outbound ship boarding and ocean/Kraken entry
for that saved journey. `GameState.sea_journey_available()` derives eligibility
from the existing `campaign.arjun_rescued` flag; no new save field or reward is
introduced. Ship availability refreshes on progression changes and after landing.
Game's boarding/transition APIs and the low-level departure method enforce the
same rule, including stale input or callbacks. Incoming rescue sailing still
shows Arjun on deck and restores Adam's collision, controls, HUD and companion
after disembarkation. The ship stays moored as scenery afterward. Existing rescued
saves stay closed after reload. Fresh journeys reopen the route. A boss kill
without opening the prison, and rescuing Mei Ling alone, leave it available.

`tools/sea_journey_completion_checks.gd` extends `-OceanLevels` and the canonical
gameplay gate with the actual prison/story/return-ship handoff, boarding rejection,
real mouse/touch events even with stale availability, nearby cached interaction,
delayed departure/island callbacks, checkpoint protection, save/load, village
reconstruction and fresh-journey eligibility. The Field Guide and completed-island
guidance now describe return/completion rather than another Kraken challenge.

Windows Godot 4.7.2 native `-OceanLevels` reviews at **832x480** and **1280x720**
each report **54 checks, PASS, exit 0**, with empty runtime stderr. Completed-ship
captures were inspected at both sizes; real pointer tests confirm the moored hull
cannot depart. Isolated import exits 0 with the existing Android build-tools
directory warning. No Android export or physical-phone test was performed.

Evidence below `C:/Users/LUQMAN/AppData/Local/Temp/`:

- Native 832x480: `tidesworn-tests-00fb2be713c041ed867c04e7a8dd8609`.
- Native 1280x720: `tidesworn-tests-b319135194f547679ac12840b866e053`.
- Import: `tidesworn-tests-37d478c893104151915ef2773a4433db`.

Final canonical isolated gameplay: **6,456 checks, PASS, exit 0**, no failure/error
markers and empty runtime stderr. This final gate includes the ten-crab immediate
encounter, both rescue orders, reunion, real incoming ship/disembarkation and the
completed sea lock. `git diff --check` passes. Full evidence:
`tidesworn-tests-41a21660380e4c2fbd5366a1910831ff`.


## Dock waiting, deliberate Embark and final voyage (2026-10-30)

The cottage auto-ending and preparation-only dock tag are superseded. After both
rescues, Arjun and Mei Ling gather at clear dock posts as existing VillageHero
actors. Adam can keep playing; proximity reveals a contextual, tappable Embark
banner and the existing keyboard/touch prompt. E, nearby ship taps and the banner
share a guarded Game-owned entry. Distant clicks, danger, recovery, modals,
editing, arrivals and incomplete rescue returns cannot start the ending.

Thirty player-paced reunion turns are restaged at the dock. Seven departure
beats show supplies, gratitude to Rahim/villagers, an ordered gangplank crossing,
mooring release, visible sailing, all three friends at the open horizon, and the
final card. Ship hull layering and the living companion remain consistent across
boarding. Day/night palettes follow entry time; low effects, mute, live Reduce
Motion and focus loss preserve essential information. Sequence-owned warm audio
and voices are released on cancellation and exit.

GameState owns the new boolean `campaign.departure_seen`. Older completed
reunions retain `ending_seen` and gain optional dock departure. Completion sets
both flags and saves once; a file-open failure rolls back the flags and retains
the final card for retry. The covered title transition keeps the world suspended.
Completed saves offer Explore BESUT / Before departure with ordinary village
defenders. The turtle rescue route stays closed after Arjun is freed.

Fresh native Windows Godot 4.7.2 results:

- Canonical isolated gameplay: **6,527 checks, PASS, exit 0**.
- Focused ending headless: **133 checks, PASS, exit 0**.
- Native ending at **832x480** and **1280x720**: **133 checks, PASS, exit 0**
  each. Thirty captures per size include live waiting, dialogue, consecutive
  boarding/sailing positions, day/night, reduced motion, final card, and the
  actual Mei Ling-first incoming-rescue passenger handoff. Captures were inspected.
- Focused completed-sea regression: **54 checks, PASS, exit 0**. This covers
  the real prison rescue, incoming ship, all sea-entry closures and fresh journeys.
- Final isolated import: exit 0 with the existing Android build-tools directory
  warning. No script failures were present in the successful import.
- Final runtime logs contain no `[FAIL]`, `SCRIPT ERROR` or `ERROR:` markers.
  The ending/full fixtures intentionally provoke one `Could not save game: 12`
  warning by replacing only their isolated save path with a directory; successful
  rollback, final-card retry and subsequent durable reload are asserted. This is
  expected negative-test output, not a claim of warning-free logs.
- `git diff --check` passes. No player save was edited, no export was made,
  and no physical Android-device test is claimed. Pointer tests use actual Godot
  mouse/touch/key event dispatch with isolated data.

Coverage includes both rescue orders; no automatic start on proximity, reload or
cleared danger; unique live friend identities; physical walking and blocked-post
fallback; bounded local defense; nearby E/mouse/touch/banner entry; ownership
locks; unchanged world time while reading; natural progression and Skip at every
turn; cancellation in every departure phase; continuous gangplank and ship
positions; old/malformed saves; inventory, pet, structure, portal, forest and
layout preservation; real save-failure retry; title wording; and earlier-time
free play. StoryChecks and the citadel-rescue fixture now assert voluntary dock
readiness rather than the superseded auto-ending.

Final evidence under `%LOCALAPPDATA%/Temp/`:

- Full gameplay: `tidesworn-tests-b04525ef67ae4bf18c5668ca93c9c373`.
- Headless ending: `tidesworn-tests-94d2eb0fe23d461aacc8e50f70240c69`.
- Native 832x480: `tidesworn-tests-acd27fdfb55340ad8661c0f40bd06b69`.
- Native 1280x720: `tidesworn-tests-d55c00bf3cb5471ea194eb8f42cb92db`.
- Completed-sea regression: `tidesworn-tests-f05bbf9529c64bbca1b11a75426afc81`.
- Successful final import: `tidesworn-tests-4d3b9cdb8a7e4d338683722052b6835b`.

See `DOCK_DEPARTURE_ENDING_PLAN.md` for the approved flow and implementation map.


## Code-locked developer tools and protected test journeys (2026-10-30)

Settings now offers masked developer access on title, land and ocean. Only the
phrase digest is stored; unlock is not part of the journey or settings file and
locks on a new app process. Input is cleared after submission and failed attempts
have a short retry delay. The private phrase is supplied separately to the owner;
positive acceptance input comes through `PB_DEVELOPER_TEST_CODE`, never test source.

DeveloperPanel offers Travel, Scenes and Progress: village/dock, both turtle
levels, Twilight exploration, all three portal arenas, Kraken/prison, the opening
and both rescue previews, Rahim's welcome, manual dock-ending setup and the full
reunion/voyage. Additional actions restore health/supplies, mark/reset rescues,
finish the real current boss, set day/night, protect Adam and freeze the clock.
Game owns transitions and story entry; GameState owns every progression mutation.
The registered workbench explicitly suspends its current world/clock and remains
usable above the independent ocean and title HUDs.

Actions require a code-unlocked test session. GameState routes save, load,
Continue and deletion to `user://developer_test_save.json`; New Journey, game over,
rescue transactions, boss loot and ending completion stay there. End/Lock restores
the normal checkpoint and its prior autosave/save-availability state. A failed
fork cannot leave the current normal world's journey ownership invalid. Newer
normal saves written by another process are preferred on restore. An unreadable
replacement is preserved at title, with autosaving withheld until a valid Continue
or deliberate New Journey. A title-started test before any normal journey exists
cannot create a normal save on completion or focus loss.

Fresh native Windows Godot 4.7.2 validation:

- Canonical isolated gameplay: **6,615 checks, PASS, exit 0**.
- Native `-Developer -Capture` at **832x480** and **1280x720**:
  **88 checks, PASS, exit 0** each. Both use the real positive code entry and
  dispatched mouse/touch input. Four settled captures per size were inspected:
  locked Settings, Travel workbench, ocean overlay and Progress workbench.
- No `[FAIL]`, `SCRIPT ERROR` or `ERROR:` markers in the final runtime logs.
  Each developer fixture intentionally provokes one `Could not save game: 12`
  warning with a directory at its isolated test-save path, asserting rollback
  and a usable retry. The full gate also retains the ending's separate expected
  failed-save warning. These are negative-test outputs, not warning-free logs.
- Successful isolated import exits 0 with the pre-existing Android build-tools
  directory warning. `git diff --check` passes. No export or physical-device
  certification was performed.

Checks cover locked direct APIs, incorrect/empty/valid code, masking, field
clearing, non-persistence, test fork failure, clock/process restoration, health
protection, supplies, every travel family, both real friend rescues, optional
boss completion, all listed previews, the complete dock ending and title return,
new/deleted test journeys, restoration and relocking, Settings reload, newer and
unreadable normal records, repaired Continue and no-save title behavior. The normal
save is checked byte-for-byte throughout the test actions. All fixtures use
isolated user data and restore their own original fixture files.

Evidence under `%LOCALAPPDATA%/Temp/`:

- Full gate: `tidesworn-tests-faca731ffe41444d950cc1c3ed676b7d`.
- Native 832x480: `tidesworn-tests-3ad79c9743d34c7abaa10f51ee1169fc`.
- Native 1280x720: `tidesworn-tests-311e683f33f24ac0b6311137cb65efce`.
- Final import: `tidesworn-tests-62df91a7f9534082ad12ecf98aa0ff44`.

See `DEVELOPER_MODE.md` for usage, ownership and checkpoint behavior.


## 2026-10-30 - Short, playful dock ending

Replaces the 30-turn / 204-word reunion and seven manually advanced departure
pages with nine lines / 40 words on three fully readable cards. Next advances one
whole exchange; Set sail starts a continuous 17-second film. The timeline runs
boarding (0-6s), cast-off (6-9s), farewell (9-13s), then open horizon (13-17s).
There are no intermediate Continue stops, narrated departure captions or repeated
final inscriptions. The final card still requires deliberate Return to title.

Original cached salute, proud, wave and steady poses accompany the Captain Snacks
banter. Arjun reveals three leaf-wrapped lunches; Mei Ling steadies his wobbling
bag while boarding. All three and the optional living companion board before the
mooring releases. Ship motion/scale share one cumulative clock, stay continuous
across shot boundaries, and keep the receding hull on the sea. BESUT dissolves into
open water without changing the destination or the live journey's sea checkpoint.

Pause/Resume freezes film time, actors, water and owned audio. Focus loss also
freezes playback; focus return respects manual pause. Reduce Motion suppresses
bag wobble/ambient drift while preserving the essential boarding and helping
poses. Every card remains readable indefinitely, and voices never gate input.
The final card uses released fresh input plus a 0.6-second guard. Game and
GameState retain their existing world suspension, cancellation, save-failure
retry, completion flags, title handoff and Before departure free-play ownership.
Generic story previews can still inspect a different kind after constructing the
intro interface without trying to access absent ending-only controls.

Fresh Windows Godot 4.7.2 verification:

| Route | Result |
| --- | --- |
| Canonical isolated gameplay | **6,621 checks, PASS, exit 0** |
| Native Reunion / 832x480 | **144 checks, PASS, exit 0** |
| Native Reunion / 1280x720 | **144 checks, PASS, exit 0** |
| Native Developer / 832x480 | **86 checks, PASS, exit 0** |
| Native Developer / 1280x720 | **86 checks, PASS, exit 0** |

Final runtime logs have no `[FAIL]`, `SCRIPT ERROR` or `ERROR:` markers. The ending
fixture intentionally makes its isolated save path unwritable once and verifies
rollback plus retry. The developer fixture independently tests a failed test-save
fork. Those `Could not save game: 12` warnings are expected negative-test evidence;
the full gate contains both. Isolated import also succeeds with the pre-existing
Android build-tools directory warning. `git diff --check` passes.

The focused fixture covers held E/F/Enter, repeated activation, actual dispatched
mouse/touch/keyboard input, fully visible text, indefinite reading, every exchange
and shot's Skip path, manual/focus pause, live settings, muted and pet-free
presentation, 60Hz actor-path continuity, waterline continuity, cancelled/retired
worlds in every phase, stale journey ownership, both rescue orders, real incoming
Arjun docking, old completed reunions, save retry, JSON reload, completion title
and earlier-time exploration. Persistence comparisons use each story's own entry
snapshot: village repair may legitimately proceed between cancelled fixtures.
Developer reviews finish the real ending on the protected test save and verify
normal-save bytes stay unchanged.

Native captures inspected at both sizes include all three banter cards, multiple
gangplank/boarding positions, the bag/helping gesture, all-three-aboard, cast-off,
farewell, horizon and day/night final cards. Night/Reduce Motion/low-quality and
no-companion frames were also captured. The natural-reading fixture allocates
4.5 seconds per card plus 17 seconds of film (30.5 simulated seconds); this is not
a measured human reading time. No physical phone, audio-listening session or
export certification is claimed by the synthetic input/silent native reviews.

Final evidence under `%LOCALAPPDATA%/Temp/`:

- Full gate: `tidesworn-tests-a0dcbdee65144eea896d1c30b213a2d8`.
- Reunion 832x480: `tidesworn-tests-f8a5304d052c4d75a3bcb43fdfc66a23`.
- Reunion 1280x720: `tidesworn-tests-ef22787b14ca44699db4be3f8cd38c57`.
- Developer 832x480: `tidesworn-tests-3e2104c2da584c4a90f6c9cf623b5ba8`.
- Developer 1280x720: `tidesworn-tests-44bcf4afd76146d8a6f5f26c2784cfbc`.
- Final isolated import: `tidesworn-tests-509e02b46158401c9f406d8269e42c16`.

See `SHORT_FUN_DOCK_ENDING_PLAN.md` for the approved script and implemented pacing.

## 2026-10-31 — Opening logo, application icon and village song

The user clarified that the supplied logo belongs on the opening splash and
application icon. The home menu retains its original two-line PROTECT / BESUT
text wordmark, font and navigation. Its outer responsive frame is refitted after
minimum-width changes so a desktop-to-phone resize does not leave content beyond
the screen.

`assets/authored/branding/protect_besut.png` is a PNG conversion of the complete
user-supplied `LOGO GAME PROTECT BESUT.jpeg`, required because the engine boot
splash accepts PNG only. `application/boot_splash/image` selects that image,
`stretch_mode=1` selects the engine's Keep mode to preserve aspect ratio, and the
background matches the dark artwork. `icon.png` centres the same complete logo
on a square background; `icon.ico` and `tools/make_icon.gd` use the PNG for Windows
icon sizes. No runtime loading-screen or story artwork is replaced.

`assets/audio/besut_village.ogg` contains the entire approximately 179-second
stereo audio track from the user's `LAGU GAME BESUT.mp4`, converted to Ogg Vorbis
quality 5 without the video. Its tracked import enables looping. Game owns the
player: entering the village starts it; ocean, portal and title handoffs stop it.
Stories, developer suspension, game over and pet battle music pause it while
preserving position. Ordinary menus and the cottage keep it playing. Existing
Master volume and mute cover the song.

Focused Windows review, isolated from player progress:

```powershell
tools/test_isolated.ps1 -Godot <console-executable> -BrandingMusic -Capture
```

The focused fixture checks restored menu text, opening-splash path/Keep mode,
application-icon path, looping across the actual song endpoint, dock dialogue
pause/resume, Settings playback, mute, ocean handoff, village return and title
stop. Native captures check the restored menu/navigation at 1280x720, 832x480 and
360x780, plus the village. The canonical gameplay gate also verifies the restored
menu, looping import, village start, pet battle priority/resumption, portal stop
and title stop.

Final Windows Godot 4.7.2 verification:

- Focused native review: **22 checks, PASS, exit 0**. Evidence:
  `%LOCALAPPDATA%/Temp/tidesworn-tests-246cdc4a1dfe47c09141fc9615df9b11`.
- Canonical isolated gameplay: **6,628 checks, PASS, exit 0**. Evidence:
  `%LOCALAPPDATA%/Temp/tidesworn-tests-eccde952d360486fa66282ebc4db143f`.
- Neither final runtime log contains `[FAIL]`, `SCRIPT ERROR` or `ERROR:`.
  Two `Could not save game: 12` warnings are the expected developer fork and
  final-departure rollback fixtures. Isolated import succeeds with the existing
  Android build-tools-directory warning. `git diff --check` passes.

The engine's live property metadata confirms Keep=1 and PNG-only splash input.
The opening logo is checked through those settings and successful engine startup;
no direct OS capture of the brief boot frame was obtained. Captures cover the
restored menus. Native review uses Dummy audio and verifies playback state/loop
timing, not speaker listening, physical-phone behavior or exported builds.

## 2026-10-31 — Contextual Sprint / Talk / Enter / Exit

The shared land action button now follows the nearest available interaction in
the active world. Clear ground shows Sprint. Village conversations show Talk;
shops, the cottage, portals and the ship show Enter. House doorways, realm/shore
gates and island return interactions show Exit. Other interactions retain a
short Use, Sleep or Pick Up action. The existing ship voyage and ocean return
routes remain owned by Game; this does not add cancellation during sailing.
This supersedes the earlier permanent-Sprint-only touch-button description.

Inside shop, house-upgrade, portal-selection, village-service, dialogue, mission
and sea-cleaning panels, the same button becomes Exit and closes only the topmost
eligible panel. It never sends a world interaction while closing a panel. Other
modal owners, stories, developer suspension, defeat and transitions block it.
Ordinary modal Escape handling remains owned by ModalBase. In the cottage, Exit
is available near the doorway before walking through the automatic exit area.

The saved layout ID remains `interact`, retaining its position and size. The
button changes its InputMap action between sprint and interact; its caption,
icon and keyboard hint follow that action. Shift remains sprint and E remains
nearby interaction. Direct object taps remain supported. A context/action change
releases the old held action and consumes the rest of that pointer gesture;
a fresh press is required for the new function. This also prevents touch-emulated
mouse presses from reopening a panel on the same Exit tap. Hide, focus loss,
world handoff and deletion retain held-input cleanup. Retiring-world actors
cannot become the current player's interaction target.
An interaction press validates its selected target rather than silently choosing
a different nearby actor if the original target has become unavailable. A stale
ship target therefore cannot redirect the same press into the dock ending.
TutorialSpotlight also checks target validity before testing its type, so a
freed interaction handle cannot raise an error during a world handoff.

The tutorial and control-settings label now describe the shared action button.
The canonical tide gate includes the expanded ControlOceanChecks. Focused review:

```powershell
tools/test_isolated.ps1 -Godot <console-executable> -ContextControls -Capture -Resolution 832x480
tools/test_isolated.ps1 -Godot <console-executable> -ContextControls -Capture -Resolution 1280x720
```

Both final native reviews pass **56 checks, exit 0**, with no failure/error
markers. Real dispatched touch verifies Talk and panel Exit, shop Enter/Exit,
cottage Enter/Exit outside the automatic doorway footprint, actual portal travel
and realm Exit, ship Enter presentation, continued direct taps and sprint stamina.
Held Sprint context changes, focus cleanup and retired-world targets are covered.
Captures inspected include Talk, shop Exit, cottage Exit and realm Exit at both
sizes; these are Windows touch simulations, not physical-phone verification.

Focused evidence under `%LOCALAPPDATA%/Temp/`:

- 1280x720: `tidesworn-tests-38535a2b65194dd8a9f80dfbe8f12312`.
- 832x480: `tidesworn-tests-ec4dc99467bf4a5ea7973d0f9945fbaf`.
- Focused dock: **90 checks, PASS, exit 0**, `tidesworn-tests-13eef615cd5e47bf8d30812a2f4d77c4`.
- Focused ocean levels/completed sea journey: **54 checks, PASS, exit 0**,
  `tidesworn-tests-c4526b3d4457409c83ee96fd580c1a90`.
- Twilight exploration/Waykeeper Talk: **198 checks, PASS, exit 0**,
  `tidesworn-tests-729d6aff6e154eba9e6eee4877bbfb5c`.

Final canonical isolated gameplay: **6,648 checks, PASS, exit 0**, with no
`[FAIL]`, `SCRIPT ERROR` or `ERROR:` markers. Evidence:
`%LOCALAPPDATA%/Temp/tidesworn-tests-74be57f548b44c028c707708f9b46156`.
The two `Could not save game: 12` warnings are expected negative-test fixtures
for developer-session creation and final-departure rollback. Isolated import
retains the existing Android build-tools-directory warning. `git diff --check`
passes. No normal player-save restoration, export or push was performed.

## 2026-10-31 — Press a mission to show its direction

The HUD objective cards are now selectable with touch, mouse or keyboard Enter.
Selecting a card highlights it in gold and displays a compass with its current
destination and distance, plus an obstacle-aware ground arrow trail. Select a
different mission to change the route; press the same card again or the compass
cross to cancel the selection. The Missions panel also lists active missions as
direction buttons and returns to play after a choice. Its current-lesson Show
direction action works independently of tutorial-tip visibility. The existing
Menu action still explicitly restores tutorial tips.

ObjectiveNavigation resolves live targets from the current world and village
layout: yard, driftwood, shops, attackers/burning trees, cottage, waystone/Rahim,
ship, workshop, realm landmarks/lantern/citadel, discovered wild companions,
later bosses, the Kraken prison and return gates. An unopened portal routes Mei
Ling's mission through Rahim and the waystone prerequisites. Pack lessons point
to the Pack control without displaying invented world metres. Selecting a goal
does not move actors, start fights, enter portals, discover landmarks, complete
missions or grant rewards. Those actions retain their existing owners.

Selection is volatile and scoped to the current world. Completion retires its
arrow; world handoff/removal clears its ID and cached target. Freed or queued
actors cannot remain navigation targets. Moving targets are resolved again as
play continues. Explicit navigation may display its trail with tutorial tips
hidden, without changing the saved Hide tips preference. Cancelling it restores
the original automatic tutorial/campaign/project path rules. The existing
workshop Show/Hide path action also updates the shared selected direction while
retaining its original GameState-owned project-tracking transaction.

Pointer handling distinguishes a card tap from vertical scrolling, supports a
second touch while movement is held, suppresses duplicate emulated mouse presses,
and cancels pending selections on hide/focus loss. Scaled card-local input is
converted to viewport coordinates before measuring a drag. Keyboard focus still
scrolls the selected card into view. Arrow layout reserves the objective column,
map controls, first-clear notices and live arrival captions. Modal/story/travel,
settlement editing and realm reading temporarily hide the compass. Reduce Motion
keeps its direction visible without optional pulsing. Navigation changes do not
pause simulation or release held movement.

Focused Windows review uses the existing isolated objective route:

```powershell
tools/test_isolated.ps1 -Godot <console-executable> -Objectives -Capture
```

Final native review: **148 checks, PASS, exit 0**, no failure/error markers.
The fixture changes the actual window/canvas between 1280x720 and 832x480 at
75%, 100% and 130% UI scale. Selected yard, rescue and realm paths, collapsed/
expanded quest lists, arrival-warning clearance and compass layout were captured
and inspected. Real touch (finger 0 and an additional finger), mouse, Enter,
scroll-versus-tap, focus cancellation, live direction/distance, moving/freed
targets, completion, world retirement, hidden tips and read-only progression
are covered. Evidence:
`%LOCALAPPDATA%/Temp/tidesworn-tests-512ab6cc7b4746c4953f34468f16e5db`.

These are native Windows captures and synthetic input, not a physical-phone or
Android export verification.

Final canonical gameplay gate after the layout adjustment: **6,691 checks, PASS,
exit 0**, with no `[FAIL]`, `SCRIPT ERROR` or `ERROR:` markers. Evidence:
`%LOCALAPPDATA%/Temp/tidesworn-tests-e8a5ba5c944f468b98ab2b61742c89c4`.
The two `Could not save game: 12` warnings are the expected developer-fork and
final-departure rollback fixtures. Final isolated import also passes, retaining
the pre-existing Android build-tools-directory warning:
`%LOCALAPPDATA%/Temp/tidesworn-tests-0a3af74a0a5441f680925324ff6d178e`.
`git diff --check` passes; screenshots remain outside the source checkout.

## 2026-10-31 — Pak Karim's key before the portal

New journeys now show **Get the portal key** as the first village objective.
Both the automatic trail and selected mission arrow lead to Pak Karim at the
dock before any visit to the waystone. His voluntary key conversation is
available immediately after the opening welcome. Completing or explicitly
skipping it grants the free permanent quest key; cancellation and retired worlds
grant nothing. The opening welcome itself does not grant it. Ordinary dialogue
continues to run the village clock.

The objective then becomes **Unlock the Dimension Portal**, and the live arrow
redirects to the northern clearing. An early visit without the key stays locked
and sends the player back to Karim. Enter/E with the key commits opening before
the existing reveal; entering the formed portal remains a separate interaction.
Existing danger, recovery, replay and world-ownership guards remain enforced.
Receiving or using the key costs no Gold, inventory items or XP.

GameState retains the stable `portal_origin.rahim_consulted` save field as key
ownership, exposed through `portal_key_received()`. Key-only saves preserve it
without requiring prior site examination. Older completed lantern conversations
retain their key, and already opened/legacy expedition saves retain access.
Malformed records and unsupported future schemas retain their rejection rules.
The display name is Pak Karim; internal `PakRahim` and portrait/save IDs remain
stable. No new save schema or inventory item was introduced.

BESUT Field Guide now opens People with Pak Karim, his village sprite and a key
diagram. Its closed-portal Story & Sea pages, mission explanation, captions and
dialogue follow the same key-first route and update after receipt. Repeated
current-objective text is suppressed, and the shortened People description fits
the native 832x480 panel with its page controls visible. Equipment merchant and
gun-shop references match Garrick and the Equipment Shop.

Focused isolated Windows evidence under `%LOCALAPPDATA%/Temp/`:

- Portal/key route at 832x480: **47 checks, PASS, exit 0**,
  `tidesworn-tests-6d851e83d3cc41f59aaa5bca825470b7`.
- Portal/key route at 1280x720: **47 checks, PASS, exit 0**,
  `tidesworn-tests-04c613c5b08144519a7256d054c4385e`.
- Objective navigation: **148 checks, PASS, exit 0**,
  `tidesworn-tests-c5b246ec29f8425aafef69be28080064`.
- Dock conversation: **90 checks, PASS, exit 0**,
  `tidesworn-tests-64cb22b1dd3d49738830421b575829e3`.

The final canonical isolated gameplay gate passes **6,700 checks, exit 0**:
`%LOCALAPPDATA%/Temp/tidesworn-tests-ae3ce446aa104f37ab04e3b73c5da78d`.
There are no `[FAIL]`, `SCRIPT ERROR` or `ERROR:` markers. The two
`Could not save game: 12` warnings are the expected developer-session and
final-departure rollback fixtures. Final isolated import passes with the existing
Android build-tools-directory warning. Native Field Guide and key-dialogue
captures were inspected; these are Windows captures, not physical-phone/export
verification. `git diff --check` passes.

## 2026-10-31 — Harder combat and exploration before Pak Rahim

This revision supersedes the key-first order above. A fresh journey starts with
**Explore the northern clearing**. The first selected and automatic arrows lead
to the fallen waystone; no usable portal actor or portal map picture exists.
Arriving through normal proximity/current-world/line-of-sight guards discovers
the site and opens **The missing portal**, explicitly directing Adam to Pak
Rahim at the dock. A nearby tap/E can also read the clue. Talking to Rahim early
cannot grant the key. After discovery the same objective and live arrow become
**Meet Pak Rahim**; completing his follow-up story grants the key and redirects
the arrow back to **Unlock the Dimension Portal**. Awakening, separate entry,
danger checks, reveal suspension and existing opened-save access remain intact.

The clue uses the existing fitted DialoguePanel, with its title and Close button
fixed in the header. Duplicate title/bottom Close content was removed, horizontal
scrolling is disabled, and dialogue draws above tutorial cards and the HUD.
The complete clue fits without scrolling at both native review sizes. Opening
releases held controls and hides selected navigation; closing resumes the route.
Reading follows ordinary modal clock rules. The dock welcome, follow-up dialogue,
mission instructions and BESUT Field Guide all explain the new exploration-first
order and consistently name Pak Rahim. Discovery and keys survive real save/load;
previously earned key-only checkpoints and already opened roads retain access.

CombatBalance applies fixed difficulty once to all Enemy subclasses after their
authored setup: regular HP ×1.45, boss HP ×1.35, damage ×1.25 rounded up, repeated
attack intervals ×0.90. Twilight guards and elemental minions use the same faster
repeated casts. Melee, specials, ground powers and projectiles use the stronger
damage. Summoned minions derive from the boss's unscaled base damage to avoid
double multiplication. Manual tournament and habitat rivals use ×1.35 HP and
×1.25 damage while retaining player-paced choices. Equipment does not raise
enemy stats: upgrades retain their full advantage. Movement, warnings, recovery,
wave quotas, drop rewards, XP and prices retain their authored values. Turtle
route hazards/lives are unchanged. See `docs/COMBAT_DIFFICULTY.md`.

The canonical gate now exercises live constructors across ordinary monsters,
elemental families, all Twilight guard profiles, portal bosses, Kraken/crabs and
all five manual rival setups. Real equipment and upgrade transactions verify
five starter hits → three Iron Sword hits → two Iron Sword +5 hits against a
58-HP target, and Leather Vest reducing a 12-damage hit to six. Existing arrival,
swept-contact, fan/cross one-hit, reward, rescue and save-reload checks use the new
stats while retaining their safety contracts.

Final focused native Windows portal review: **53 checks, PASS, exit 0** at each
resolution, with no failure/error markers. Complete clue text, visible Close,
Field Guide updates, live arrow handoffs, real discovery/key saves and the
existing reveal/entry were captured and inspected. Isolated evidence:

- 832x480: `%LOCALAPPDATA%/Temp/tidesworn-tests-cfd6f1edfbcb4ffe9c7767a1e5772a19`.
- 1280x720: `%LOCALAPPDATA%/Temp/tidesworn-tests-90a461d7188f473caa3d4ceede5da1c6`.
- Final isolated import: exit 0,
  `%LOCALAPPDATA%/Temp/tidesworn-tests-0d1709ec93804566a9ae461274eef77d`, with
  the existing Android build-tools-directory warning.

This is native Windows and automated input evidence, not physical-phone testing
or an Android export. Screenshots remain outside the source checkout.

Final canonical isolated gameplay gate: **6,750 checks, PASS, exit 0**, with no
`[FAIL]`, `SCRIPT ERROR` or `ERROR:` markers. Evidence:
`%LOCALAPPDATA%/Temp/tidesworn-tests-45df434d5bc84bd9b6227bfdc0cbe733`.
The two `Could not save game: 12` warnings are the intentional developer-session
and final-departure rollback fixtures. `git diff --check` passes. No normal
player-save restoration, export or push was performed.
