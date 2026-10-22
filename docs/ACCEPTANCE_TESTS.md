# Acceptance Tests for AI Agents

This document is the acceptance contract for automated agents and human
reviewers working on **Save The World - Tidesworn** in Godot 4.x.

## Required commands

Run from `GAME_COMP_RPG-Godot/`:

```sh
# Parse/import every script and report warnings as failures.
godot --headless --path . --editor --quit

# Full acceptance suite. Expect: 250 checks, PASS.
godot --headless --path . res://tools/tide_test.tscn

# Visual capture harness (writes PNGs).
godot --path . res://tools/tide_capture.tscn -- --shots C:/path/to/shots
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
- Both pets have exactly three skills: Attack, Guard and Recover.
- The player has a two-second choice window; the enemy selects from the same
  three skills.
- When the timer expires, both actions execute simultaneously.
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
- Trees are invulnerable: `take_attack_damage()` must leave health unchanged,
  must not fell the tree and must not damage the settlement.
- Tree hits must still increment the feedback counter and play VFX/SFX.
- At least eight `forest_monsters` patrol the woodland; emergencies add more.
- Forest monsters attack nearby trees at a faster cadence without needing the
  player nearby.
- A clear line of sight to the player immediately sets the player as target,
  starts a charge and triggers the aggro sound.
- Generated `tree_hit` and `aggro` sounds must exist in `Sfx`.

### 6. Lively village
- At least four `resident_house` nodes exist.
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
- Three weapons, ten monster portals, boss ability variety, Android touch
  controls, auto-loot, pet support, emergency defence, defeat/recovery and
  permanent daytime remain intact.

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
7. **Delete test saves and temporary logs** before handoff. The suite deletes
   `user://tidesworn_save.json` at the start and end.

## Visual review checklist

Inspect these captures:

- `tide_title.png` - title, credit and responsive character cards
- `tide_lobby.png` - XP bars, Pack/Build, lively village
- `tide_lobby_portal.png` - paired Monster/Pet gates
- `tide_pet_battles.png` - five-level tournament
- `tide_pet_duel.png` - 1v1 arena during the two-second choice window
- `tide_pet_resolution.png` - simultaneous turn result and both health bars
- `tide_pet_shop.png` - Pet Food and Feed controls
- `tide_house.png` - Construction Shop Level 1-5 progression
- `tide_forest.png` - dense protected woodland and monster impacts
- `tide_build.png` - settlement editor
- `tide_settlement_attack.png` - emergency HUD and raid
- `tide_recovery.png` - recovery ward

No NPC name labels or toast banners should be visible in any capture.
