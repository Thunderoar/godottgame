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
- BESUT Field Guide opens from Menu. Its NPC pages, five monster pages and ten boss pages explain actions using sprites and visual symbols, with character names as headings. It has no explanatory paragraphs. Page turn and Close work at both landscape sizes.
- A new journey has one worker per specialist role. Main-house Levels 2-5 provide a baseline of 2-5 of each role. Hiring can add workers beyond that baseline within role limits, and ownership/deaths persist.
- One main-house upgrade charges once and synchronizes the village house, archer-hut and fence tiers. Previews show the house, hut, fence and baseline worker count for each level. A ruined main house must be repaired before upgrading.
- Purchased rooftop machine guns replace archer huts. Yellow bullets damage fire monsters and sea urchins. Missing, ruined, unaffordable and duplicate purchases fail without charging. Ownership survives save/load.
- Fences progress from wood to wood with a stone base, stone walls, fortified posts and battlements. Changing level refreshes existing fence sprites and survives save/load.
- Night lessons retain the pointer without an extra dark overlay. The level-one portal is the only portal shown during that training. Other bosses cannot complete its final lesson; defeating Shadow & Chaos Fiend ends that tutorial. All ten bosses show their distinct names above their HP.
- Continue after finishing daytime lessons retains the unfinished nighttime tutorial and activates it at the next night. Build remains in Menu.


## Combat and guardian update (2026-10-24)

The isolated gameplay gate also runs tools/combat_revamp_checks.gd:

- Adam (Malay male, sword), Mei Ling (Chinese female, bow) and Arjun (Indian male, scythe) have distinct portraits and weapon silhouettes with basic attacks only. Old qayyim/farhan/ayiz save IDs migrate to adam/arjun/mei_ling; inventory, progression and village unlocks remain. Legacy hammer item IDs are retained as scythes so existing equipment is preserved.
- The HUD keeps one basic-attack button, Use, Pack and joystick. Skill 1/2/3 buttons, keyboard actions, cooldowns and Settings rows are removed for every hero. Cancelling basic-attack touch releases its InputMap action.
- Every hero's basic attack still deals damage; arrows stop at world obstacles. Mana stats, overhead bars, character-selection MP values and mana potions are removed. Loading an older save removes retired mana fields, potions and skill control positions while preserving currency, equipment, health potions and active control customization. A second save/load keeps mana removed.
- Winning each of five pet duels recruits that named rival, unlocks its roster entry and spawns an invincible village guardian. Replays do not duplicate a guardian. Guardians path toward and damage both fire monsters and sea urchins near the settlement. Prior cleared duels recruit their rivals when an older save is loaded.
- The main-house interior has an interactable HouseBed using the existing house-tier recovery time. The automatic defeat-recovery ward remains governed by its existing rules.
- All ten portals have intimidating named bosses, a special power, colliding pillars and six repeating rune traps. Rune traps warn for one second, damage for 0.65 seconds and then become safe until the next cycle. Higher portal levels increase trap damage and shorten the cycle. Bosses activate at range after a 2.2-second arrival warning and use their existing pursuit pathfinder.
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
