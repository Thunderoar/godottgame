# AGENTS.md — PB (Protect BESUT) / Tidesworn

2D pixel-art survival action-RPG in **Godot 4.7.2**. Created by Qayyim, Farhan & Ayiz.
The project/application name is still **Save The World**; the player-facing title is
**PB (Protect BESUT)**. Tidesworn is also the name of the editor workspace.

**2026-10-29 runtime update:** the current Windows configuration names the application
`Protect Besut`. One village Dimension Portal now enters `TwilightRealm`, a `Dungeon`
subclass for the stable first-stage ID `tidebound_grotto`. First-realm exploration,
protected in-world pet challenges, discovery/checkpoint persistence, threshold-only
boss activation and peaceful post-clear revisits supersede the older paired-portal,
first-arena pursuit and first-expedition emergency descriptions below. Later legacy
stages and both rescue paths remain intact through physical onward passages. Read
`docs/TWILIGHT_WILDS.md` and the newest acceptance section for current ownership/rules.
Windows focused review: `tools/test_isolated.ps1 -Godot <console-executable> -Twilight`
with optional `-Capture -Resolution 832x480` (or `1280x720`). Normal menus still run
the simulation; an accepted wild challenge explicitly suspends its realm until closed.

## 1. Ground truth and scope

- This checkout is `/home/roku/Documents/ChatGPT/game`; `project.godot` is at its root.
  Other tournamentgame/godottgame/GDT2 checkouts are independent repositories.
- Inspected on **2026-10-27**, source commit **76b5357**, branch **main**. These are
  observations, not instructions to switch branches. Run `git rev-parse --show-toplevel`
  and `git status --short --branch` before edits. Preserve user changes; never reset
  or replace a repair branch with main. Do not push unless requested.
- `/usr/bin/godot --version` currently reports `4.7.2.stable.arch_linux.ed1daf0bf`.
  Match export templates to the actual engine, not an older report.
- `project.godot` runs `res://scenes/game.tscn`: one Node2D with `Game` attached.
  Runtime worlds and UI are constructed in GDScript, not assembled in that scene.
- Autoload order: **GameState → Sfx → GameSettings**. No Creative Studio autoload.
- At inspection: 136 GDScript files under `scripts/`, 53 under `tools/`, 12 under
  `addons/`. Counts and line numbers drift: use the symbols below as entry points.

**Authority:** current source/resource data → current tests and observed logs →
feature-specific documentation → historical completion reports. Older docs and
`.hermes/research/agents-md/` describe earlier milestones, not current contracts.
Do not revive obsolete Qayyim/Farhan/Ayiz hero selection, invulnerable trees,
permanent day, mana, five turtle lives, fish healing, or the cave over the portals.

## 2. Safe run, bootstrap and validation

Run these commands from the confirmed repository root:

```sh
set -eu
# Refresh imports/global class metadata on a fresh OR newly updated checkout.
# Import can initialise autoload settings: isolate its user data too.
bootstrap=$(mktemp -d /tmp/tidesworn-bootstrap-XXXXXXXX)
XDG_DATA_HOME="$bootstrap/userdata" TIDESWORN_TEST_ROOT="$bootstrap" \
  timeout 120 godot --headless --path . --import >"$bootstrap/import.log" 2>&1
cat "$bootstrap/import.log"
# Treat any match as failure, even if Godot returned 0.
if rg -n 'SCRIPT ERROR|ERROR:' "$bootstrap/import.log"; then exit 1; fi

# Canonical gameplay gate: wrapper creates/prints its own isolated test root.
./tools/test_isolated.sh

# Editor/import/save/bake changes: disposable SOURCE and user-data copy.
./tools/test_creative_editor.sh

git diff --check

# Interactive player session; this intentionally uses normal user data.
godot --path .
```

**Never run the destructive acceptance scene against normal user data.**
`tools/tide_test.gd` calls `GameState.delete_save()` before and after the suite.
Copying the project directory alone does NOT isolate `user://`: the application
name still selects `~/.local/share/godot/app_userdata/Save The World/`.
Tests must set both `XDG_DATA_HOME` and `TIDESWORN_TEST_ROOT` before Godot starts.
`TestEnvironment.require_isolation()` checks the actual user-data path before the
harness mutates it; autoloads initialise earlier, so do not rely on that guard alone.
Back up live progress before risky manual testing; never restore an old backup over
progress from a concurrent player session. Do not stop unrelated Godot processes.

`test_isolated.sh` uses `timeout 600`, preserves Godot's pipeline exit status, rejects
`[FAIL]`, `SCRIPT ERROR`, `ERROR:`, and requires the exact final summary pattern:
`--- tide test: N checks, PASS ---`, plus exit 0. A partial stream of `[OK]` is not PASS.
A stale `.godot/global_script_class_cache.cfg` can omit newly added classes and hang
at parse errors; refresh imports before changing gameplay to fix those errors.
`--editor --quit` and legacy `smoke_test.gd` are not substitutes for the gate.
Warnings are not automatically failures in the Linux wrapper; inspect and report
warnings rather than describing a warning-bearing log as completely clean.

Dated verification results for this update are recorded at the end of this file.
Do not hardcode a permanent check tally or reuse an old PASS as current evidence.

## 3. Runtime ownership and world lifecycle

```text
GameState  persistent progression, campaign, village simulation state, transactions
Sfx        procedural effects + generated battle music; audio bus owner
GameSettings  device preferences in user://settings.cfg

Game (scripts/game/game.gd)
├── TitleLayer → TitleScreen + TitleBackdrop (preview/menu, no preview save writes)
├── WorldHolder → ONE current world
│   ├── Lobby (64 × 40): village, forest, coast, shops, workers, portals, ship
│   │   └── HomeInterior (temporary child at an off-map position)
│   ├── Dungeon: selected Monster Portal level, enemies, boss, hazards, shore exit
│   ├── OceanJourney: turtle route state machine, own camera/UI/controls
│   └── KrakenIsland: fortress arena, KrakenKing, RescueCage, return interaction
├── GameHUD: combat/village HUD, minimap, modal panels, tutorial, touch controls
├── LoadingScreen + NpcInfo
└── StorySequence (temporary illustrated story overlay)
```

- **Game owns transitions.** Use `_load_lobby()`, `_load_dungeon()`, `enter_home()`,
  `board_ship()`, `enter_ocean()`, `return_from_ocean()`, `enter_kraken_island()` and
  `play_story()`. There is no `change_scene_to_file()` / scene reload flow.
- `_clear_world()` saves current village monsters when the world's `journey_serial`
  matches GameState, resets portal/emergency accumulators and sailing, stops battle
  music, queues the old world for deletion, and detaches it from HUD ownership.
  Old and new nodes can coexist for a frame. **Use `Game.player()`**, which asks the
  current world's `get_player()`, rather than taking the first global player.
- Keep `_transitioning`, `_defeat_pending`, `_portal_fx_active`, `_sailing`,
  `_story_active`, world-identity and validity guards. After any `await`, verify
  that the same world/actor still owns the operation before changing its state.
- **Normal menus do not pause simulation.** They lock `Player.controls_locked` via
  `Game._input_locked` / `_apply_input_lock()`. `_on_modal_closed()` unlocks only
  when no modal, story, transition, sailing or ocean ownership remains.
- **Story is a deliberate exception:** `play_story()` disables the current world's
  process mode, stops the world clock through `_story_active`, releases controls,
  then restores world mode/HUD. Ocean's local Settings panel suspends `_update_run()`;
  it does not globally pause the SceneTree. Do not wire in the orphan PauseMenu.
- Lobby-only actions need explicit context guards, not just proximity. Existing
  `open_shop()` and several older routes exclude Dungeon only; newer services and
  missions require Lobby. Do not assume all open methods are globally safe.

## 4. Source navigation by change type

| Change | Primary owner / related code |
|---|---|
| Saves, currency, XP, house, workers, forest state, missions, rescue flags | `scripts/autoload/game_state.gd`: `_make_default()`, transactional methods, `load_game()`, `_sanitize()`, `_sanitize_campaign()` |
| Title/continue/new journey/rescue locks | `scripts/ui/title_screen.gd`, `scripts/ui/title_backdrop.gd`, `scripts/game/game.gd` |
| Village construction, wave restore, world services, spatial refresh | `scripts/world/lobby.gd` |
| Map topology, coast, authored overlays, scenery | `scripts/creative/world_layout.gd`, `scripts/creative/world_terrain.gd`, `scripts/creative/world_composition.gd`, `scripts/creative/map_renderer.gd` |
| Movement, stamina, phased weapon attacks, aim, sleep | `scripts/player/player.gd`, `scripts/data/attack_db.gd`, `scripts/player/player_vitals.gd` |
| Monster targeting/FSM, special attacks, damage/rewards | `scripts/combat/enemy.gd`, `scripts/world/dungeon.gd`, `scripts/world/dungeon_hazard.gd` |
| Fire, tree HP/growth, specialist tasks, physical routes | `scripts/world/forest_tree.gd`, `scripts/world/resident.gd`, `scripts/world/resident_routes.gd` |
| House/fence targets, timed repair, shelter, rooftop weapons | `scripts/world/settlement_target.gd`, `scripts/world/house_defense.gd`, `scripts/world/home_interior.gd` |
| Companion support, recruited guardians, rescued allies | `scripts/pets/pet.gd`, `scripts/pets/village_pet.gd`, `scripts/world/village_hero.gd` |
| Ship ownership/deck/harbour return | `scripts/world/ship_departure.gd`, Game's `board_ship()` / `finish_ship_return()` |
| Turtle routes, life/fullness/item rules, marine visuals | `scripts/world/ocean_journey.gd`, `scripts/world/ocean_scenery.gd`, `scripts/ui/ocean_progress.gd` |
| Kraken tentacle/slam/drag, fortress, prison release | `scripts/combat/kraken_king.gd`, `scripts/world/kraken_island.gd`, `scripts/core/kraken_art.gd` |
| HUD, maps, modal routing and control placement | `scripts/ui/game_hud.gd`, `scripts/ui/village_minimap.gd`, `scripts/ui/world_map_panel.gd`, `scripts/ui/settings_panel.gd`, `scripts/ui/control_layout_editor.gd` |
| Shop transactions and presentation / manual pet duels | `scripts/ui/shop_panel.gd`, `scripts/ui/shop_scene.gd`, `scripts/ui/pet_battle_panel.gd` |
| Tutorial, event guidance, illustrated field guide/story | `scripts/data/mission_db.gd`, `scripts/ui/tutorial_guide.gd`, `scripts/data/field_guide_db.gd`, `scripts/ui/story_sequence.gd` |
| Pixel generation, imported overrides, quality/VFX/audio | `scripts/core/pixel_art.gd`, `scripts/creative/asset_registry.gd`, `scripts/core/game_settings.gd`, `scripts/core/vfx.gd`, `scripts/autoload/sfx.gd` |
| Developer authoring UI, history, save/import | `addons/tidesworn_creative_tools/` (editor only) |

`scenes/main.tscn` and the loose legacy scripts are the converted Unity demo, NOT
this game's runtime. Never hand-edit the generated scene or run `tools/convert.gd`
(its input points at an obsolete Windows Unity path). `scripts/control_mode.gd`
is unused. `scripts/ui/pause_menu.gd` and `scripts/ui/confirm_dialog.gd` form an
uninstantiated legacy feature; no `pause_menu` InputMap action exists.
Do not run `tools/setup_input.gd` (rewrites project config) or
`tools/tide_capture.tscn` (unguarded save deletion/source screenshots) in automation.

## 5. Persistence and transaction rules

1. **GameState is the only production writer of `data`.** UI/world call its methods
   and check their bool or `{"ok": bool, "message"|"reason": String}` result before
   presenting success. Existing direct `Lobby` tutorial_seen assignment is a legacy
   exception, not a pattern to copy. Tests intentionally manipulate fixture state.
2. New saved fields require defaults AND load sanitisation. `SAVE_VERSION` is **6**;
   migration is recursive `_merge()` with defaults plus explicit normalisation,
   not branching on version. Cast all save-derived numbers through `int()`/`float()`.
3. `campaign()` and many DB getters return copies; mutate through GameState APIs.
   Not every getter does: `get_pet()` exposes owned pet data. Verify the particular
   accessor instead of assuming all dictionaries are either live or copied.
4. Persist stable IDs and numeric positions, never nodes. Saved world state includes
   `forest_health`, `forest_growth`, `resident_health`, `structures`, `roof_guns`,
   `worker_counts`, `water_keeper_count`, `home_monsters`, `home_wave`, `world_time`,
   `settlement_layout`, portal/duel/mission/campaign progress and expedition loot.
   The old claim that only expedition/layout persist is false.
5. `home_monsters` captures living fire/urchin kinds, positions, HP and raid flags.
   `_save_now()` captures a ready current Lobby only when its `journey_serial`
   matches. A new journey increments the serial so retiring worlds cannot save
   old enemies into it. Dungeon enemy/boss HP and mid-route turtle state are NOT saved.
6. Emit the owning signals (`data_changed`, `pet_changed`, `house_changed`, etc.)
   after accepted mutations; panels often rebuild from these, gated on visibility.
   Do not add per-frame disk writes; follow existing transaction save boundaries.
7. `continue_game()` must reject unreadable saves without overwriting them. Merely
   previewing title cards must not create/reset progression. New Journey deliberately
   calls `new_game("adam")`, carries saved control settings, and replaces progression
   only after the title's confirmation when a save exists.
8. Separate **device** preferences (`GameSettings`, `user://settings.cfg`: volume,
   UI scale, camera zoom, touch mode, reduce motion, effects quality, fullscreen)
   from journey `settings.control_layout` (village and ocean control positions).
   `GameState.gui_scale()` delegates to GameSettings. New Game carries layout;
   deleting a save does not delete device settings. Use live-setting signals.
9. `CharacterDB.canonical_id()` maps old IDs: qayyim→adam, farhan→arjun,
   ayiz→mei_ling. However, `load_game()` currently validates the raw saved ID against
   `CharacterDB.ids()` before `_sanitize()` canonicalises it: an unrecognised raw ID
   falls back to Adam. Do not promise legacy discipline preservation without testing
   that exact load path. Catalog helper mapping alone is not save migration proof.

## 6. Gameplay contracts to preserve

### Campaign, portals and defeat

- New journeys play **Adam (sword)**. Arjun (scythe) and Mei Ling (bow) are missing
  friends, not alternative new-game starts. Title cards remain locked until their
  independent rescue flags are set, then describe **village defenders**. Even an
  unlocked friend preview does not change the Adam story start.
- `campaign` owns `intro_seen`, `ocean_stage`, `arjun_rescued`, `mei_ling_rescued`,
  `ending_seen`. Defaults + `_sanitize_campaign()` preserve older progression.
  Three 45-second ocean routes lead to Vorath, the Kraken King. Kill the boss,
  then separately approach/tap the prison through `free_arjun()`; a kill alone
  does not rescue him. Arjun returns visibly aboard the ship, then joins the village.
- Mei Ling is rescued after Abyss Monarch in `drowned_throne`, the final Monster Portal.
  Both flags trigger a one-time saved reunion ending; normal village play continues.
  Replays must not duplicate friends, rewards or rescue transitions.
- Three active Monster Portal definitions live in PortalDB (Chaos Citadel → Tempest Spire → Abyssal Throne, levels 1/3/5). Prerequisites and attempts go
  through `portal_clear_reason()` / `start_expedition()`. Unbanked expedition loot
  is separate from banked inventory; victory/safe exit banks it, defeat discards it.
- Portal defeat intentionally emits through multiple paths: preserve
  `_defeat_pending` and expedition guards. Home defeat preserves banked progression,
  restores 10% HP, revives the companion and starts recovery; island defeat reuses
  home recovery. Recovery follows `sleep_recovery_seconds()` / HouseDB (10→2 s).
  Only the main cottage is enterable; its interior is a Lobby child, not another scene.
- Ten tutorial events are phase-aware (`MissionDB.DAY_STEPS` / `NIGHT_STEPS`).
  `tutorial_complete()` also recognises Portal 1 already cleared in an old save.
  Portal-entry/boss events survive a clock-phase change during the fight. Clearing
  Tidebound Grotto ends training immediately; Portals 2–3 are Mei Ling's rescue arc.
  Tutorial Skip hides the overlay; do not assume it completes progression.

### Village ecology, enemies and defenses

- One authoritative clock: **180 s day + 180 s night**. New journeys begin peacefully
  by day. Night spawns fire monsters/urchins; dawn changes lighting, NOT surviving
  enemies or their HP/AI. `home_wave` prevents repeat spawning on re-entry/reload.
- The original forest fixture contains **64 trees**, not the historical 73 claim.
  `tools/fixtures/monsoon_forest.json` binds each ID/order/position/max HP.
  `_rng.seed = 7319`, frozen exclusion coordinates and **160** pre-forest RNG draws
  preserve those associations. Never insert an earlier gameplay RNG call or reorder
  tree creation for decoration. Scenery/visual families use separate deterministic streams.
- Trees keep HP, ignite/burn, fall at zero, lose collision and can be replanted.
  Water keepers extinguish/heal; planters produce protected, nonblocking **30 s**
  saplings. Caretaker/builder claims must be released on death/unreachable tasks.
  All trees lost triggers irreversible game over, devastation, and save deletion.
  Do not restore tree invulnerability or confuse growing trees with attackable ones.
- Fire monsters and urchins can attack a nearby living player/exposed resident;
  intact houses shelter residents. Fire also attacks mature trees; urchins attack
  structures/trees physically. Active-world ownership and dead/sheltered filters matter.
  Fire-monster combat/burning are intentionally silent; physical hits on unburned
  trees and other enemy kinds retain their own audio rules.
- Four specialists: water (fires), planter (fallen trees), builder (day repairs),
  fighter/swordsman (urchins). Hiring may replace a dead slot; counts scale at least
  with house tier. Builders must arrive before spending **10 s** working; night
  pauses construction, and partial work persists. Nearby manual repair is free.
- House tier is the shared level source for structures/workers/fences/purchased
  rooftop guns, not independent building progression. House upgrades cost diamonds;
  workers and optional rooftop guns cost Gold. Guns are sold by the **Equipment Shop**,
  require an intact house, and shoot fire/urchins only. Use GameState cost methods.
- Cleared pet duels recruit rivals into owned pets and `village_pets`; rebuild
  VillagePet guardians and rescued VillageHero allies once per stable ID. Pet
  support/revival and house-tier defender scaling must remain consistent with saves.
- The dungeon emergency starts after 14 s **and at night**, with a 5 s settlement
  damage accumulator. The numeric `emergency_damage` tint is cosmetic; spawned
  attackers still do real HP/structure damage. Menus are not a safe pause.

### Movement, combat, input and presentation

- Preserve continuous `Input.get_vector()` + acceleration/braking + `move_and_slide()`;
  do not substitute grid movement or position snapping. Sprint is 1.7× speed with
  stamina drain/exhaustion/recovery; stamina is displayed under overhead HP.
- A health potion can auto-consume at nonzero HP ≤10%; the auto-heal latch rearms
  after healing to ≥35%. Lethal damage does not auto-resurrect the player. Mana and
  revival-potion items are retired; load sanitisation removes them. Pets recover
  through existing revival/load rules, not permanent-death or paid-revival additions.
- Attacks are `ANTICIPATION → ACTIVE → RECOVERY` using AttackDB. Damage/projectiles
  happen at the active frame and cooldown restarts there. Keep combo windows,
  discipline/range, bow aim, collision and damage pacing intact when changing art.
  Enemy FSM: spawn/wander/alert/chase/windup/attack/recover/stagger/dead.
- Collision **bit values**: World=1, Player=2, Enemy=4 (editor layers 1/2/3).
  Enemy mask deliberately excludes Player. Never add player collision as a cosmetic fix.
- Damage APIs are duck-typed through groups/`has_method()`. Enemies and settlement
  targets generally expose `take_damage(amount, from_dir, source)`; Player's signature
  differs. Match the actual callee. Guard validity, deletion and world ownership.
- Land controls: WASD/arrows, Shift=sprint, F=attack, E=nearby interaction, I/Tab=Pack,
  B=settlement build. Current touch HUD has joystick, Attack, **Sprint**, Pack, Menu.
  **`_interact_button` and saved layout ID `interact` now mean `sprint`**, not Use.
  Tap nearby interactables directly; ship's own direct-tap route permits remote boarding
  but retains world/activity guards. Do not reintroduce Talk/Use/Board touch buttons.
- Interactable is a distance/group API with physics monitoring disabled, plus direct
  touch/mouse handling. `body_entered` cannot implement its interaction contract.
  Every synthetic action needs release on pointer-up, hide, focus loss and exit.
  Use `hud.release_world_controls()` during world/story/sailing changes.
- Gold/diamonds are top-left; picture minimap top-right opens WorldMapPanel; clock
  is bottom-centre; player/pet health/XP are overhead. Portal CLEARED captions are
  intentionally hidden WITHOUT clearing saved flags. No old VITALS/quest/boss HUD box.
- `GameHUD.show_toast()` is deliberately a no-op and toast_requested is not a reliable
  feedback channel. Put important results in owned persistent UI, not a new toast.
- Set `ModalBase._panel_size` BEFORE `super._ready()`. Register any new modal with
  creation, close routing, `any_modal_open()` AND `hide_modals()`. Existing rebuilds
  can reset scroll/hover during `data_changed`; pet battle has its own active guard.
- PetBattlePanel is **manual**: `choose_skill()` starts the player's choice, the rival
  replies afterward, and cooldowns tick while the panel is active. No automatic
  player timeout turn. Preserve `_turn_timer` and other test-accessed members.
- Gold/diamond drops magnetise nearby; other loot collects by contact. Use the
  active current-world player and preserve one-payment/queued-deletion guards.

### Ship, turtle and Kraken

- Game owns sailing locks/HUD visibility; ShipDeparture owns deck placement and
  departure/return motion. Yellow UNISZA ship docks before passenger disembarkation.
  Preserve collision restoration, pet repositioning and held-action cleanup.
- Ocean phases: `DIVE → RESCUE → RUNNING → TRAVELLING → ARRIVING` for routes 1/2;
  route 3 travels into KrakenIsland. `FINISHED` is the death/retry state, not a
  successful Next-button stop. Save the next route checkpoint before departure;
  retries/shore return retain completed-route checkpoints and earned cleanup Gold.
- Ocean uses normalised four-direction steering, its own camera/settings/joystick,
  Pick Up/E (`ocean_pickup`) and Eat/F (`ocean_eat`). The combat HUD is hidden.
  Village/ocean layouts are independently editable; saved pixel positions are
  viewport-clamped and must not drift when GUI scale changes.
- **Three lives** and a distinct fullness meter. `FULLNESS_DRAIN=3` per second,
  `FISH_FULLNESS=35`, cap 100. Fish restore fullness, NEVER lives; pink hearts heal
  one life capped at three. At zero fullness, `STARVATION_SECONDS=5` costs a life.
- Pick Up rubbish pays one Gold exactly once through `register_rubbish_cleaned()`.
  Each missed/wrongly eaten/end-of-route leftover rubbish costs a life, even during
  blink immunity. Fatal penalties prevent checkpoint advance. Skipped fish or
  avoided hazards do not incur rubbish penalties. Keep late-spawn travel margins.
- Bomb/shark contact uses swept collision and 1.4 s hit immunity; rubbish/starvation
  penalties deliberately bypass it. Fatal damage sinks/flips rider+turtle before
  showing Ride Again. Retry/new route resets lives, fullness and missed counters.
- KrakenKing alternates telegraphed slam/hook/drag; the other arm grips the cage.
  Pull uses `move_and_collide()`, never teleporting through arena pillars. Boss death
  unlocks, but does not itself open, RescueCage. Preserve separate tap-to-free and
  repeat-rescue guards, full arena/cage framing, and human-scale returning Arjun.

## 7. Content edits and coding conventions

- Follow the surrounding indentation (mostly tabs; some existing core files use
  spaces). `snake_case` functions/members, `PascalCase` classes, typed function
  signatures, `:=` where inference is safe; file-level tuning constants. Avoid
  unrelated reformatting and private-member renames: tests call internals directly.
- Data catalogs use static accessors, not DB instances. Inspect copy/live semantics;
  do not mutate const catalog records. Prefer `.get(key, default)` for optional UI data.
- **Items:** edit `scripts/data/item_db.gd` / `ITEMS`. Supply name/kind/price/currency/
  stack/description/shop; equipment also needs slot/style/stats. Shop filter is
  `equipment|potion|pet`; empty means not sold. Current styles: sword/scythe/bow;
  legacy `smith_hammer` IDs are scythes now. Blank style bypasses discipline filters,
  so specify it for weapons. Vendor sale needs explicit `sellable: true` (wood).
- **Portals:** update `scripts/data/portal_db.gd` / `PORTALS` AND `ordered_ids()`,
  predecessor `unlocks`, requirements/rewards, art/guide/tests. Last ordered portal
  owns Mei Ling's rescue; changing order affects campaign code, not just menus.
- **House:** `scripts/data/house_db.gd` / ordered LEVELS, level/index alignment,
  diamond costs and recovery. **Pets:** `scripts/data/pet_db.gd` / PETS + LEVEL_XP;
  duel LEVELS + ORDER in `scripts/data/pet_battle_db.gd`. Keep unique backdrop paths.
  `GameState.pet_upgrade_cost()` is the shared upgrade price, not a UI formula copy.
- **Missions:** update STEPS, day/night index arrays, event callers, guidance/spotlight
  and old-save completion handling together. **Campaign:** defaults/sanitizer,
  rescue APIs, title locks, guide and transition checks move together.
- Do not add state writes to UI/world or editor APIs to gameplay. Groups are a
  cross-system API: renaming a group/method may silently break duck-typed callers.

## 8. Creative Studio, map and asset contracts

**Route:** Godot → **Tidesworn** workspace → **Map Studio**. If absent, enable
**Tidesworn Creative Studio** in Project Settings → Plugins. Other tabs are
Asset Library, Pixel & Animation, World Palette.

- Default sources: `data/maps/village.tres`, `data/maps/village_layout.tres`,
  `data/palettes/monsoon_afterglow.tres`, `data/asset_registry/library.tres`.
  Map Studio supports anchors/buildings, routes, polygon districts, scenery,
  activity workpoints, authored objects, undo/redo, validation, Save As and preview.
  Read `docs/MAP_STUDIO_GUIDE.md` and `docs/MAP_STUDIO_UPGRADE.md` for actual tools.
- Developer authoring and player settlement layout are separate. In-game **Menu →
  Build settlement** or B edits player placements. Use Map Studio to edit source.
  Preview runs with its own data. Never "fix" developer defaults by clearing a save.
- Resolve **player layout > developer base override > canonical anchor** on copies;
  do not mutate source resources during runtime resolution. AuthoredMap v1 falls
  back to compatible WorldLayout defaults; v2 can reference/embed its layout.
  House-relative arrival/recovery, approaches, collision, resident workpoints and
  camera spawn need to move coherently, not just a building sprite.
- Establish topology/clearance/reachability before decoration. ResidentRoutes is
  physics-backed AStar; edited layouts invalidate routes and update service access.
  Water paint creates collision; land paint cannot reclaim sea. Only the visible
  `jetty_deck` footprint is removed from the shared coast collision polygon.
- Preserve all original forest fixture associations. New authored trees use their
  authored stable IDs. Existing tree base overrides move nodes after ID assignment.
  Developer placement, gameplay RNG and decorative RNG must not become coupled.
- Runtime art loads imported Texture2D resources through AssetRegistry. Optional
  missing art falls back; required missing art emits an error and diagnostic checker.
  Explicit overrides (including `authored_tree` and legacy foliage keys) win.
  Generate through stable `PixelArt.cached_texture()` keys; use `PixelArt.PX`.
  Duplicate shared image data before destructive resize/recolour/preview transforms.
- MonsoonArt owns reproducible trees/cottage/props and editable exports under
  `assets/authored/monsoon/`. Imported house art owns its windows: do not overlay
  a procedural window mask on it. Coastal/Campaign/Ocean/KrakenArt own newer visuals.
- WorldTerrain uses a geometry/palette-hash-validated imported terrain bake; edits
  invalidate it. `tools/bake_village.tscn` writes source ONLY with
  `--write-village-bake` AND verified isolation. Isolation of user data alone does
  not protect source files: bake/import/save tests belong in a disposable checkout.
- Palette changes invalidate generated caches; unchanged inputs reuse terrain.
  MonsoonLighting derives from GameState time; no second clock or spawn logic.
  Reduce Motion/low quality retain essential readable terrain, flame/health/state
  feedback; respect the current quality gates rather than asserting every overlay
  remains visible. Test live setting changes and tween ownership.
- Editor recovery drafts stay under `user://tidesworn_studio_recovery`; explicit
  Save is required to overwrite source art/maps. Plugin build blocks unsaved work.
  `addons/tidesworn_creative_tools/` stays editor-only.

## 9. Verification routes and evidence limits

The full gate integrates DeepAuditChecks, CreativeChecks, WorldChecks, MonsoonChecks,
KampungChecks, TitleChecks, combat/coastal/portal-tutorial/control-ocean/kraken-hunger,
StoryChecks and MapUnlockChecks. Older standalone fixtures may lag current flow;
read their setup before running (some still await a story without dismissing it).

| Affected area | Additional route |
|---|---|
| Authoring/import/source save, map workbench, bake | `tools/test_creative_editor.sh`: disposable import + bake + reimport, editor UI checks, creative restart AND workbench restart |
| World composition/movement/render configuration | `tools/review_world.sh` with an absolute external output directory |
| Monsoon art/palette/performance | `tools/review_monsoon.sh` with an absolute external output directory |
| Title/menu/input | `tools/review_title.sh` with an absolute external output directory; inspect for older title expectations |
| Coastal/ship/shore ownership | `tools/coastal_test.tscn` |
| Campaign/rescue/ending/touch layout | `tools/story_test.tscn` |
| Minimap/picture map/friend locks | `tools/map_unlock_test.tscn` |
| Sprint/direct ship tap/ocean controls | `tools/control_ocean_test.tscn` |
| Kraken arena/drag/fullness/missed rubbish | `tools/kraken_hunger_test.tscn` |

Focused scenes do not isolate the environment for you. Example, after import:

```sh
set -eu
review=$(mktemp -d /tmp/tidesworn-review-XXXXXXXX)
XDG_DATA_HOME="$review/userdata" TIDESWORN_TEST_ROOT="$review" \
  timeout 180 xvfb-run -a -s '-screen 0 1280x720x24' \
  env LIBGL_ALWAYS_SOFTWARE=1 godot --audio-driver Dummy --path . \
  res://tools/kraken_hunger_test.tscn -- --small-screen \
  >"$review/review.log" 2>&1
cat "$review/review.log"
if rg -n '\[FAIL\]|SCRIPT ERROR|ERROR:' "$review/review.log"; then exit 1; fi
rg -q '^--- kraken hunger: [0-9]+ checks, PASS ---$' "$review/review.log"
# Inspect the generated shots as well as the exit status and PASS summary.
```

Use `tools/test_isolated.ps1` for Windows, with the correct Godot console executable;
read its `-ImportOnly` / `-VisualReview` options rather than copying Linux commands.
For visual/input changes, inspect actual rendered captures at 1280×720 and compact
832×480 as relevant. Headless PASS proves neither appearance nor phone input.
For movement, inspect consecutive positions/frames, not just endpoints. Paired
static captures disable follow-camera processing and use identical camera state.
Do not claim new performance figures from old fixtures or native Windows/Android
validation from Linux llvmpipe, Xvfb or Wine.

**Definition of done:** requested implementation completed; affected tests added;
`tools/tide_test.gd` and `docs/ACCEPTANCE_TESTS.md` updated together if a game rule
changes; safe gate final PASS + exit 0 + no error/failure markers; relevant editor/
render/restart evidence; truthful limits and warnings; `git diff --check`; scoped
source diff, no stray screenshots/bakes/builds or player-save changes. For documentation
only, verify the cited paths/symbols and distinguish source inspection from tests
actually rerun. Do not modify gameplay merely to make the documentation true.

## 10. Exports and deeper references

- `export_presets.cfg` is **tracked**, not ignored, and currently defines **only Android**:
  `com.tidesworn.protectbesut`, PB (Protect BESUT), ARMv7+ARM64, version **1.3.0**,
  **versionCode 9**. Excludes tools/docs/addons/build and the legacy main scene.
  Do not assume a Windows preset exists or silently alter package ID/signing key.
- Matching `4.7.2.stable` Android and Windows templates are installed on this host;
  this alone does not prove SDK/JDK/keystore configuration or export success.
  Read current presets, credentials/configuration and output before packaging.
  `build/` is ignored/generated; previous APK hashes/reports do not certify this source.
- Android delivery requires the real requested export, package/version/architectures,
  signing-certificate continuity, APK signature and alignment verification. A
  development-signed direct-install APK is not a Play Store release. No physical
  phone test may be claimed without doing one.
- Runtime reference: `docs/ARCHITECTURE.md` (older scope); acceptance:
  `docs/ACCEPTANCE_TESTS.md` (includes chronological, superseded milestones).
  Current campaign/sea progression: `docs/BESUT_STORY_CAMPAIGN.md` (read through
  the latest Kraken/fullness section, not just its original description).
  Combat/guardians: `docs/COMBAT_GUARDIANS_REPORT.md`; coast/ship:
  `docs/COASTAL_JOURNEY_REPORT.md` (initial five-life/fish-heal rules superseded).
- Spatial/art ownership: `docs/WORLD_LAYOUT.md`, `docs/WORLD_OVERHAUL_REPORT.md`,
  `docs/ART_DIRECTION.md`, `docs/MONSOON_AFTERGLOW_REPORT.md`,
  `docs/ASSET_WORKFLOW.md`. Editor: `docs/MAP_STUDIO_GUIDE.md`,
  `docs/PIXEL_EDITOR_GUIDE.md`. Title: `docs/TITLE_SCREEN_REDESIGN.md` predates
  Adam-only campaign start. `docs/GDT2_INTEGRATION.md` records integration history.
  Old QA/completion/conversion reports are historical, not a current green build.

### Observed validation for this documentation update — 2026-10-27

- First gameplay attempt encountered missing global class metadata in the stale
  local import cache. It was stopped and failed the wrapper (exit 1). No gameplay
  code was changed to mask the error. Isolated `--import` completed with exit 0;
  the subsequent full gameplay gates before and after this guidance update each
  reported **1,217 checks, PASS**, exit 0, without `[FAIL]`, `SCRIPT ERROR` or `ERROR:`.
- Disposable Creative Studio workflow reported **84 checks, 0 failures** and both
  `creative restart: PASS` / `workbench restart: PASS`, exit 0. Xvfb emitted input-
  method and unsupported V-Sync warnings; these are not hidden or gameplay failures.
- Focused actual-renderer Kraken/fullness review at **832×480** reported **25 checks,
  PASS**, exit 0; ocean/fullness and fortress/grapple captures were inspected.
  The same two Xvfb warning types occurred. This is Linux llvmpipe evidence, not
  a physical-device or native Windows certification. No release export was rerun.
- This update changes guidance only; gameplay/resources and live saves were not
  edited. Documentation paths and selected current-contract coverage were checked;
  a reconstruction patch and executable pristine-byte rollback were verified.
