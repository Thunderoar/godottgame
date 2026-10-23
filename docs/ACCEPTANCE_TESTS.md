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

On Windows with the portable console binary, use the equivalent path to
`Godot_v4.7.2-stable_win64_console.exe`.

An agent must not declare success when the suite reports a failure, when the
editor import reports `SCRIPT ERROR`/warnings, or when it has not inspected the
new screenshots at 1280×720.

## Acceptance checks

### 1. HUD and NPC presentation
- No `Label` child is attached to `Resident`, `ShopNPC` or `CoastalGuard`.
- `GameHUD` has no toast container and `show_toast()` creates no UI.
- Important events remain visible through persistent HUD panels and the journal.
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
- Combat has exactly two mechanics: **Attack** and **Defend**.
- The player has a two-second choice window; the enemy selects Attack or Defend.
- When the timer expires, both actions execute simultaneously.
- Attacks create scratch/punch impact nodes; Defend creates a shield effect.
- A win records the clear, grants Gold and pet XP, unlocks the next duel and
  raises the active companion's level by at least one.
- A loss or forfeit grants no clear or level.

### 4. Pet progression and shop
- `Pet Food` is a `pet` shop item with a positive Gold price.
- Buying and feeding it consumes one item and increases pet XP.
- Player XP and pet XP bars update after combat and feeding.
- Pet levels and duel clears survive save/load.

### 5. Protected forest and monster behaviour
- The `forest_tree` group contains at least 60 living trees.
- Every tree is a `ForestTree` and is also a `settlement_target`.
- Every tree has independent HP and persistent health.
- `take_attack_damage()` reduces tree HP, increments feedback and plays VFX/SFX.
- Tree HP reaches zero -> tree falls; all trees dead -> `GameState.game_over_active`.
- Game Over shows a locked panel and returns to title without a Continue save.
- At least twelve `forest_monsters` patrol the woodland; emergencies add four more.
- Forest monsters attack nearby trees at a faster cadence without needing the
  player nearby.
- A clear line of sight to the player immediately sets the player as target,
  starts a charge and triggers the aggro sound.
- Generated `tree_hit` and `aggro` sounds must exist in `Sfx`.

### 6. Lively village and ruins
- At least seven `resident_house` nodes exist.
- At least three `ruin_house` nodes include abandoned, damaged and destroyed art.
- At least six `garden` nodes and 50 `flowers` nodes exist.
- At least two `horses` nodes exist and horse art generates.
- At least nine editable `decoration` placeables exist.
- The settlement editor still drags, clamps, saves and reloads layout.

### 7. Sea cleaning
- The coastal guard catches drifting rubbish.
- Each catch awards exactly +1 Gold and increments `GameState.data.sea_cleaned`.
- Beached dangerous rubbish becomes a monster and grants no catch reward.
- Rubbish-monster kills grant their own separate Gold.
- Sea-cleaning progress survives save/load.

### 8. Construction Shop and existing contracts
- A dedicated `shop_house` construction stall and Bram's `ShopNPC` exist.
- Interacting with Bram opens the house panel, branded as the Construction Shop.
- The panel exposes Levels 1-5 and only accepts diamonds.
- Title reads `SAVE THE WORLD`; credit names Qayyim, Farhan and Ayiz.
- The recovery ward heals at `GameState.sleep_recovery_seconds()` - the
  HouseDB rate for the current cottage level (10 s at Level 1 down to 2 s at
  Level 5), matching the bed and the Construction Shop panel. The old
  hardcoded 8.0 s ward clock is gone.
- Three weapons, ten monster portals, boss ability variety, Android touch
  controls, auto-loot, pet support, emergency defence, defeat/recovery and
  permanent daytime remain intact.

### 9. Guidance, dashboard and menus
- The HUD has three `MissionArrow` nodes; at least one is visible in the lobby.
- Mission arrows point toward Monster Portal, Pet Duel, Construction Shop or an
  emergency target and display distance.
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
   journal, permanent prompt or modals for state.
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

- `tide_title.png` - title, credit and responsive character cards
- `tide_lobby.png` - XP bars, mission arrows, Pack/Build, lively village
- `tide_menu.png`, `tide_settings.png` - menu and settings
- `tide_dialogue.png` - exact Unisza dialogue
- `tide_lobby_portal.png` - paired Monster/Pet gates
- `tide_pet_battles.png` - five-level tournament
- `tide_pet_duel.png` - 1v1 arena during the two-second choice window
- `tide_pet_resolution.png` - simultaneous turn, impact and shield effects
- `tide_pet_shop.png` - Pet Food and Feed controls
- `tide_house.png` - Construction Shop Level 1-5 progression
- `tide_forest.png` - dense protected woodland and tree HP impacts
- `tide_ruins.png` - abandoned/damaged/destroyed houses
- `tide_build.png` - settlement editor
- `tide_settlement_attack.png` - emergency HUD and raid
- `tide_recovery.png` - recovery ward
- `tide_game_over.png` - locked all-trees-destroyed game-over screen

No NPC name labels or toast banners should be visible in any capture.
