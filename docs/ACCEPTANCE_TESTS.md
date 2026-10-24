# Acceptance Tests for AI Agents

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
- `take_attack_damage()` reduces tree HP, increments feedback and plays VFX/SFX.
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
- Fire monsters only choose mature trees. They cannot damage the player even if
  handed a stale player target, and never charge a player in line of sight.
- Each journey begins with a peaceful day. Day and night each last exactly 180 seconds; the HUD counts down. Only night creates new fire monsters or sea urchins, including beach and raid paths. Existing monsters continue attacking after sunrise. Each night replenishes the baseline population once, without duplicating surviving monsters.
- Clock phase and living home monster position/HP survive save/load and returning from a dungeon; no wave is created merely by reopening the village.
- Generated `tree_hit` and `aggro` sounds must exist in `Sfx`.

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
- At night, beached dangerous rubbish becomes a spiked sea urchin (`kind == "urchin"`)
  and grants no catch reward. Its kill grants separate Gold exactly once.
- Sea urchins damage mature trees without igniting them, fences, intact houses
  and exposed residents. Saplings remain immune.
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
- A non-blocking spotlight dims everything except the current action, draws a gold arrow and follows changing UI layout. It highlights the joystick, a shop, the exact potion Buy button, Pack, or Strike. The tips panel moves aside from the highlighted target.
- The player owns a `PlayerVitalHud` that draws only Health and Mana above the
  player's head.
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
- The Strike touch icon matches the active hero's weapon style for all three
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
for health/mana, potions, pet support, combat, tree falling and game-over remain.

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
HP/half mana and the existing recovery ward; it does not discard expedition loot
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
- The boot menu hides hero selection until **Start Game**. Hero cards only
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
  retaining Back/Begin. Low/Reduce Motion retains the complete static harbour.

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
- Every house, including former ruins, has persistent HP and an archer hut. One main-house upgrade controls the whole village tier (houses, archer huts, fences and specialist worker baseline). The main house must be intact and diamond cost is charged once. Arrow intervals are 2.1/1.7/1.3/1.0/0.7 seconds; destroyed houses disable their archers.
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

- Cave entrances occupy the far northern edge, with both clickable portals accessible.
- Battles fill the arena with one image; both pets have three separate cooldowns. Player action precedes the enemy reply, and idle player turns never auto-resolve.
- Only the day/night clock and Menu occupy the upper HUD. Player HP/MP/XP and level appear overhead; pet HP/XP appear overhead. Gold and diamond balances appear in shops.
- HP/mana potion shortcuts are absent; Pack provides the potion actions beside the joystick. Menu provides Build settlement and Finish building.
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
- Buku BESUT opens from Menu. Its 23 NPC pages, five monster pages and ten boss pages explain actions using sprites and visual symbols, with character names as headings. It has no explanatory paragraphs. Page turn and Close work at both landscape sizes.
- A new journey has one worker per specialist role. Main-house Levels 2-5 provide a baseline of 2-5 of each role. Hiring can add workers beyond that baseline within role limits, and ownership/deaths persist.
- One main-house upgrade charges once and synchronizes the village house, archer-hut and fence tiers. Previews show the house, hut, fence and baseline worker count for each level. A ruined main house must be repaired before upgrading.
- NPC archer huts replace roof machine guns; arrows visibly damage fire monsters and sea urchins. The shared home tier controls their fire interval, damage and range. Destroyed houses disable their archers.
- Fences progress from wood to wood with a stone base, stone walls, fortified posts and battlements. Changing level refreshes existing fence sprites and survives save/load.
- Night lessons retain the pointer without an extra dark overlay. The level-one portal is the only portal shown during that training. Other bosses cannot complete its final lesson; defeating The Grotto Warden ends that tutorial. All ten bosses show their distinct names above their HP.
- Continue after finishing daytime lessons retains the unfinished nighttime tutorial and activates it at the next night. Build remains in Menu.
