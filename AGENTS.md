# AGENTS.md — Save The World (Tidesworn)

2D pixel-art survival action-RPG vertical slice for **Godot 4.7.2**.
Authors: Qayyim, Farhan and Ayiz.

- Project root: `GAME_COMP_RPG-Godot/` (this directory)
- Engine on this machine: `/usr/bin/godot` → `4.7.2.stable.arch_linux.ed1daf0bf` (exact match)
- ~15,400 lines GDScript: 64 files / ~12,000 lines under `scripts/`, 8 tools / ~3,600 lines under `tools/`
- Main scene: `res://scenes/game.tscn` (`project.godot:15`) — **6 lines, one root node, everything else built in code**
- Branch layout: `main` is the pre-overhaul baseline; `visual-overhaul-merge-2` carries the
  visual overhaul **and the repair pass** described below. The repair fixed a reparenting
  regression (tree/house visuals), oversized effect scales, the water mask, star clutter,
  camera zoom, GUI scale, the VITALS panel, movement smoothness, and added the turtle,
  the BESUT sign and ambient NPC shopping.
- Three autoloads: `GameState`, `Sfx`, then `GameSettings` (`project.godot:21-23`). GameSettings owns device prefs (`user://settings.cfg`) incl. reduce_motion, effects_quality, ui_scale and camera_zoom.

Deep research backing this document (read on demand, not by default):
`.hermes/research/agents-md/agent-a-architecture.md` (runtime),
`agent-b-world-economy-ui.md` (gameplay/data/UI),
`agent-c-tooling-tests-docs.md` (tests/build/docs).

---

## 1. Quick start

```sh
# Run the game (opens a window)
godot --path .                 # or open project.godot in Godot 4.7.2 and press F5

# Bootstrap a fresh checkout ONCE — without this the project cannot even parse
godot --headless --path . --import

# The only real gate
timeout 600 godot --headless --path . res://tools/tide_test.tscn ; echo "EXIT=$?"
```

**BASELINE ON `visual-overhaul-merge-2` after the repair pass: GREEN. `361 checks,
PASS`, exit 0.** The tree decision was resolved by the owner: trees have persistent
HP, fall at zero and all-dead triggers a locked game-over; the suite,
ACCEPTANCE_TESTS and the README all agree. Attack-timing checks wait for the
active frame (AttackDB wind-ups), which is a documented rule change, not a
weakened assertion.

A clean run must end `PASS` and exit 0. Nothing else is a green build.

**The suite deletes the player's save** (`tools/tide_test.gd:13,109` →
`GameState.delete_save()`), and `user://` is keyed on `config/name`, so running it from a
*copy* of the project destroys the same real save at
`~/.local/share/godot/app_userdata/Save The World/tidesworn_save.json`. Back it up first.

---

## 2. The tree product decision (RESOLVED) and the hierarchy rule

Docs and one test used to say forest trees are invulnerable; the code says otherwise:

- `scripts/world/forest_tree.gd` → `health = maxi(0, health - maxi(1, amount))`, fells at 0.
- The suite damages and fells a tree and asserts persistence (`_test_visual_repair_regressions`).

**Hierarchy rule (learned the hard way):** every `ForestTree`, resident house and ruin
must parent its shadow, art, targets and collision body **to the holder node**, with
holder-relative local coordinates. The overhaul briefly reparented them to the lobby,
which stacked ~73 trees' sprites and colliders at the lobby origin and made the fall
tween rotate an empty holder. The regression suite now asserts `_visuals` parents and
positions on every tree (`tools/tide_test.gd`, `_test_visual_repair_regressions`), so a
reintroduction fails the gate.

---

## 3. Architecture in one screen

```
GameState (autoload)  ← single source of truth: data, economy, saves, XP, pets,
      ↑                 house, portals, expedition, emergency, recovery, layout
      │ signals
Game (scenes/game.tscn)  ← flow controller: title → lobby ⇄ dungeon, HUD owner,
      │                     modal routing, emergency clock
      ├── WorldHolder ──► Lobby  (hub: shops, residents, 73 trees, editor, raids,
      │                │            turtle, BESUT sign, ambient shopping)
      │                └► Dungeon (10 portal levels, monsters, boss, exit)
      ├── GameHUD (layer 10) ── 8 modal panels + touch controls + tutorial
      └── TitleLayer ──► TitleScreen (character select lives here too)
```

Rules of the runtime that shape every change:

1. **Nothing is in the scene file.** `Lobby`, `Dungeon`, `GameHUD` and all panels are
   `new()`-ed in GDScript (`game.gd`, `game_hud.gd`). There are no exported `NodePath`s
   or scene connections to wire — do not look for them.
2. **There is no scene switching.** Zero `change_scene_to_file` / `reload_current_scene`
   calls. `Game._load_lobby` / `_load_dungeon` build a world; `Game._clear_world`
   `queue_free`s the previous one. Because `queue_free` is deferred, **two worlds coexist
   for one frame** — every `get_first_node_in_group("player")` can bind to the dying
   player. `Game.player()` is the only safe accessor.
3. **There is no pause.** No `get_tree().paused` anywhere. Modals only set
   `Game._input_locked` → `player.controls_locked`, so enemies, the 14 s emergency
   timer and settlement damage keep running behind an open panel.
4. **Groups are the API.** Combat and cross-world calls are duck-typed:
   `has_method("take_damage")` + `call()`, and `has_method("get_player"|"open_shop"|…)`
   through the `"game"` group. Renaming a group member or method breaks gameplay with **no
   compile error**.
5. **Only two properties of the world persist**: `expedition.active/portal_id` and
   `settlement_layout`. Re-entering a dungeon does not restore monster/boss HP.
6. **Camera zoom is a device setting**, not a world property: every `FollowCamera` reads
   `GameSettings.camera_zoom()` (percent of `FollowCamera.DEFAULT_ZOOM = 40`) each frame
   and eases toward it, so lobby and dungeon cameras always agree with the Settings
   panel without any cross-world wiring.

---

## 4. Where things live

| Path | Lines | What it owns |
|---|---|---|
| `scripts/autoload/game_state.gd` | 1314 | **Everything stateful.** Economy, XP, pets, house, portals, expedition, emergency, recovery, save/load, sanitise |
| `scripts/autoload/sfx.gd` | 136 | Procedural SFX synthesis (no audio assets exist) |
| `scripts/game/game.gd` | 423 | Flow, world construction, modal routing, emergency clock |
| `scripts/world/lobby.gd` | ~1700 | **Hottest file** — the whole hub, 73 trees, raid spawning, recovery ward, water mask, ambient life, beach landmarks, shopping scheduler |
| `scripts/world/beached_turtle.gd` | 44 | Resting turtle scenery (breathing idle, collider, coast-derived placement) |
| `scripts/world/besut_sign.gd` | 34 | Village-entry BESUT road sign (5×7 pixel font, collider) |
| `scripts/world/resident.gd` | ~290 | Route AI, emergency flee/fight, **ambient shopping state machine** (TO_SHOP→BROWSE→BUY→LEAVE) |
| `scripts/world/dungeon.gd` | 378 | Portal level build, boss, exit, defeat |
| `scripts/world/*.gd` (20 files) | — | Residents, forest trees, rubbish/sea, settlement editor, portals, loot, shops |
| `scripts/ui/*.gd` (16 files) | — | HUD, 8 modal panels, joystick, touch buttons, tutorial |
| `scripts/data/*.db.gd` (6 files) | — | Content tables: items, characters, portals, pets, houses, pet duels |
| `scripts/core/pixel_art.gd` | ~1600 | **All art is procedural** — every texture comes from here, cached forever; also the interaction chevron, butterfly, leaf, dot, turtle and BESUT sign textures |
| `scripts/core/icon_art.gd` | ~660 | Detailed 32px icon set (incl. the `marker` chevron) |
| `scripts/core/follow_camera.gd` | 92 | Follow + look-ahead + shake + user zoom (eased, adaptive pixel snapping) |
| `scripts/core/shaders.gd` | 165 | Wind + water shader code (water reads depth from the mask's RED channel) |
| `scripts/core/vfx.gd` / `vfx_pool.gd` | 86/240 | Pooled combat/ambient feedback, calibrated against the 128px light texture |
| `scripts/core/ui_theme.gd` | 130 | Palette + `GameUI` widget helpers |
| `scripts/player/`, `pets/`, `combat/` | — | Player controller, arrows, companion, monsters/bosses/projectiles |
| `scripts/*.gd` (9 loose files) | — | **Unity-port demo only** — loaded by `scenes/main.tscn`, not by the game |
| `tools/` | ~3600 | Acceptance suite, screenshot tour, legacy tests, converters |

`scenes/main.tscn` (4298 lines) is a **converted Unity demo**, not the game. Only
`tools/convert.gd`, `play_test.gd` and `smoke_test.gd` reference it. It still ships
(`export_presets.cfg:12-14` excludes only `tools/*, docs/*`). `scripts/control_mode.gd`
is referenced by nothing at all. The same is true of `scripts/ui/pause_menu.gd`
(615 lines) and `scripts/ui/confirm_dialog.gd`: nothing instantiates them and
there is no `pause_menu` InputMap action. They are orphaned half-built
features — do not wire them in without an owner decision.

---

## 5. Content edits — the canonical recipes

All content is a `const` table + `static func` accessors in `scripts/data/`. Never
instantiate a DB; every getter returns `.duplicate(true)`, so do not mutate the result.

**New item** — 1 file, 1 insertion: add a record to `ItemDB.ITEMS`
(`scripts/data/item_db.gd:9-221`). Required keys: `name, kind, price, currency, stack,
description, shop`. Then:

- Sold in a shop? `shop` must be `"equipment"|"potion"|"pet"` — that field *is* the
  filter (`item_db.gd:236-241`). `shop:""` = never sold.
- Weapon? `style` must equal a hero's `weapon_style` (`sword|hammer|bow`) or it is invisible
  to that hero (`item_db.gd:248-256`) and rejected by `equip_item` (`game_state.gd:346-348`).
- Sellable to vendors? Set `"sellable": true` explicitly — the default is **false**
  (`game_state.gd:241`; only `wood` opts in).

**New portal** — 2 files, order matters: add the record to `PortalDB.PORTALS` **and**
append its id to the hand-maintained `ordered_ids()` (`scripts/data/portal_db.gd:234-246`).
Forgetting step 2 makes the level unreachable with no error. New portal ids also get
default save state from `ordered_ids()` at `game_state.gd:62-67`.

**New house tier** — `HouseDB.LEVELS` is ordered and index-aligned with its `level` field;
`next_level()` indexes by current level (`house_db.gd:57-60`). Costs are **diamonds**.

**New pet / duel** — `PetDB.PETS` + `LEVEL_XP` (`pet_db.gd:59`) / `PetBattleDB.LEVELS` +
`ORDER` (`pet_battle_db.gd:89-91`). Duel order is a manual array like `PortalDB`.

**Persisted per-instance things need stable ids.** Tree health is keyed `forest_%d` from a
counter assigned in RNG-dependent creation order (`lobby.gd`); inserting a tree or
adding an earlier `_rng` call rebinds every saved tree's health. Do not repeat that pattern.

---

## 6. Conventions

- **Indentation: tabs.** `snake_case` members, `PascalCase` classes, `SCREAMING_SNAKE` consts.
- **Typed signatures everywhere:** every `func` declares `-> T`; locals use `:=`. Members
  are typed ~half the time — follow the surrounding file.
- **Nodes are found by group, never by path.** Gameplay scripts contain no `$Path` and no
  `get_node()` in logic (the Lobby's named children like `BeachedTurtle`/`BesutSign` are
  test anchors, not gameplay wiring). Build nodes in code; use `get_tree().get_nodes_in_group(...)`.
- **`GameState` is the only writer of `data`.** UI and world call its transactional
  methods and check the result: `{"ok": bool, "message"|"reason": String}`
  (`game_state.gd:189-227,840-854`). The one exception in the codebase is
  `lobby.gd:78` (writes `data.tutorial_seen`) — do not add a second.
- **Device prefs live in `GameSettings`** (`user://settings.cfg`): volumes, fullscreen,
  `ui_scale` (the ONLY GUI-scale authority — the HUD migrates a legacy save-file value
  once and never reads it again), `camera_zoom`, touch mode, shake, reduce motion,
  effects quality. Never store these in the save file.
- **UI refreshes by full rebuild on a signal, guarded by `visible`:**
  ```gdscript
  GameState.data_changed.connect(func() -> void:
        if visible:
                _rebuild())
  ```
  and `_rebuild()` starts with `_clear_content()` (`portal_panel.gd:11-14`).
- **Signals live on GameState**; world objects do not emit to UI — they `call()` `Game` as
  a router (`shop_npc.gd:32-41`). `Resident.purchase_made` is the one world→world
  exception (customer → lobby keeper reaction) and stays VFX-only by design.
- **Construction naming:** `_build_*` for builders, `_on_<signal>` for handlers, `_add_*`
  for single-child appenders. Large files use `# ---- section ----` banners.
- **Error handling is return-dicts, not asserts.** Keep player-facing strings out of
  `push_error`.
- **Tuning constants go in a file-level `const`/`@export`**, not inline in `_process`.

---

## 7. Hard rules

**State & saves**
1. Never mutate `GameState.data` outside `game_state.gd`; call the method and check `.ok`.
2. Adding a state field means adding it to `_make_default` **and** clamping it in
   `_sanitize`, or it will not survive a save/load.
3. Emit `data_changed` after any mutation the HUD shows; panels refresh from that signal only.
4. Call `_save_if_needed()` only from transactional `GameState` methods — never from
   `_process`/`_physics_process`. Autosave already fires per kill (`grant_xp`).
5. Never branch on `data.version`; `SAVE_VERSION` is written and never read.
   Migration *is* the recursive merge with defaults.
6. Wrap every save-derived number in `int(...)`/`float(...)` — Godot's JSON parser returns
   all numbers as floats.
7. Persist ids/positions only — never node references.

**World & flow**
8. Never call `change_scene_to_file`; create worlds via `_load_lobby`/`_load_dungeon`.
9. Reset `_portal_elapsed`, `_emergency_triggered`, `_settlement_damage_accum` on every
   world change (`game.gd`).
10. Use `Game.player()`, not `get_first_node_in_group("player")`, across a transition.
11. Guard group lookups with `is_instance_valid()`; dead nodes linger for a tween.
12. Keep collision layers as declared: bit 1 = World, bit 2 = Player, bit 4 = Enemy.
    Enemies deliberately do **not** collide with the player; adding bit 2 to the enemy
    mask is a gameplay change, not a bugfix.
13. Anything the player can use extends `Interactable` — a distance check with all physics
    monitoring off. `body_entered` will never fire. Its marker is the shared
    **chevron** texture (`PixelArt.marker_texture()`), never a spark icon.
14. Any damageable node joins a group and exposes
    `take_damage(amount: int, from_dir: Vector2 = ZERO, source: Node = null)`.
15. **Holder hierarchy:** tree/house/ruin/smoke/turtle/sign visuals and colliders are
    children of their holder with holder-relative coordinates (see §2). The suite
    asserts this.
16. **Movement is continuous, never grid-locked:** logical positions stay `float Vector2`;
    physics bodies move in `_physics_process` with delta-based velocity (player) or
    bounded delta stepping (ambient NPCs via `Resident._walk_to`); direct position
    assignment is only for spawn/respawn/world transitions/scripted teleports and test
    scaffolding. The pet catch-up is a bounded spring (max 9 u/s) — there is **no**
    distance-threshold teleport anymore, and the suite asserts per-frame step bounds.

**UI**
17. Do not pause the tree. Lock input with `Game._input_locked` + `player.controls_locked`
    and unlock only through `_on_modal_closed`.
18. Gate lobby-only modals behind a `world is Dungeon` guard, as `open_shop`/`open_portals`
    do (`game.gd:231-267`). `open_inventory` currently lacks that guard.
19. In a `ModalBase` subclass, set `_panel_size` **before** `super._ready()`.
20. Use `.get(key, default)` on dictionary records in UI — dot access errors the frame.
21. **Do not rely on `toast_requested`.** 45 emit sites, zero listeners, and
    `GameHUD.show_toast()` is deliberately empty. Any feedback you route through it is
    silently discarded.
22. Release every `Input.action_press` in `_release()`; a stuck synthetic action survives
    scene changes. Touch and keyboard must share the one InputMap path.
23. **Camera zoom and GUI scale are independent by contract.** Zoom lives in
    `GameSettings.camera_zoom` (applied by every `FollowCamera`); GUI scale lives in
    `GameSettings.ui_scale` (applied by `GameHUD._apply_gui_scale`, which scales the root
    from its top-left corner and divides its layout rect so edge anchors stay glued to
    the real screen at 75–130%). The suite asserts both directions of independence.
24. There is **no top-right VITALS panel** (removed by owner decision). Health/mana/pet-HP
    float above the player in `PlayerVitalHud`; XP/pet-XP/currency stay top-left. Do not
    recreate the corner panel.

**Art & effects**
25. Generate textures via `PixelArt.cached_texture` with a stable unique key — the cache is
    process-global and never evicted. **Change the key when you change the art**, or stale
    caches (including in long-running test sessions) keep the old pixels.
26. Use `PixelArt.PX` for world scale (1/32); never a literal `0.03125`.
27. **`light_texture()` is 128 px.** Any Sprite2D/CPUParticles2D/PointLight2D scale must be
    calibrated against 128: a lamp pool of ~5 world units is `texture_scale ≈ 0.05`, a
    cloud shadow ~13 units is `scale ≈ 0.10`, a dust puff ~1 unit is `scale ≈ 0.008`.
    The overhaul's "neon" look was exactly this miscalibration; `VfxPool` ring/dust math
    divides by 128 for the same reason.
28. **No star/sparkle clutter.** Ambient life uses real artwork (butterflies =
    `PixelArt.butterfly_texture` two-frame `AnimatedTexture`, pollen = `dot_texture`,
    falling leaves = `leaf_texture`); the water shader has no sparkle term; the downed pet
    is a quiet dazed pose; interaction cues are chevrons. `PixelArt.icon("spark")`
    survives only for genuine combat impact feedback and the emergency fire indicator.
29. **The water overlay is mask-driven.** `_make_water_mask_texture()` writes alpha = sea
    shape (zero beyond the painted ocean, terrain x < 25.2·32) and RED = shore distance;
    `Shaders.WATER_CODE` derives depth, wave bands and the foam lip from that RED channel.
    If you move the coast, regenerate the mask (new cache key) — never hand-edit the
    shader's gradient logic.

**Tests & tooling**
30. `tools/tide_test.tscn` is the only gate. Require `0 FAILURE(S)` and exit 0.
31. Never trust an exit code alone: grep stdout for `[FAIL]`, `SCRIPT ERROR`, `ERROR:`.
    `--editor --quit` exits 0 with parse errors; `smoke_test.gd` always exits 0.
32. Wrap headless runs in `timeout` — a broken parse makes the process hang, not fail.
33. The suite calls **private members by name** (`hud.get("_root")`,
    `resident.set("_shop_timer", …)`, `game.call("_load_lobby", …)`,
    `forest_monster.call("_can_see_player")`). Renaming privates in `game_hud.gd`,
    `pet_battle_panel.gd`, `game.gd`, `forest_tree.gd`, `resident.gd` or `lobby.gd`
    (`_make_water_mask_texture`, `_coast_pixel_y`, `_residents`) is a breaking change.
34. Update `tools/tide_test.gd` and `docs/ACCEPTANCE_TESTS.md` together when a rule changes.
35. Never edit `scenes/main.tscn` by hand — it is generated by `tools/convert.gd:1957`.
36. Never run `tools/convert.gd` (dead `C:/Users/LUQMAN/…` input, `:35`),
    `tools/setup_input.gd` (rewrites `project.godot:27`), or `tools/tide_capture.tscn`
    in automation (needs a window, writes `res://shots`, deletes the save).
37. Do not hardcode the check tally in docs or assertions — it is data-driven and drifts
    when catalogue data changes. (Current: 361.)
38. `tools/visual_review.tscn` is the non-destructive screenshot tour (title → lobby →
    shops → dungeon → HUD at 832×480 → coast/turtle → BESUT sign → forest → NPC shopping
    → zoom out/in → quality tiers → GUI scales). Run under Xvfb with
    `LIBGL_ALWAYS_SOFTWARE=1`; it writes to `/home/z/my-project/shots` and never touches
    the save.

---

## 8. Highest-value gotchas

1. **Every user-facing message is silent** — see rule 21. Purchases, level-ups,
   "EMERGENCY!", tutorial skip: written into the void.
2. **No pause** means opening a shop mid-raid is a control-locked death (`game.gd:37-48`).
3. **The recovery ward heals at the HouseDB rate** — `GameState.sleep_recovery_seconds()`
   (per cottage level, 10→2 s), the same clock as `house_bed.gd` and the `HousePanel`
   progression. The suite asserts the ward's heal rate follows HouseDB.
4. **`upgrade_pet` cost has a single source** — `GameState.pet_upgrade_cost(level)`
   (`45 + level*35`).
5. **`emergency_damage` is cosmetic.** `_apply_emergency_damage` only tints sprites;
   nothing is destroyed and the run cannot fail from it. It also only resets at the
   *next* raid.
6. **Death in the lobby is unhandled** — `player_defeated` has listeners only for the
   dungeon path, so a player killed at home stays dead and locked with no respawn.
7. **`player_defeated` is emitted twice per portal defeat** and has two listeners. It only
   works because of the `_defeat_pending` guard and an `expedition_active()` early-out.
   Preserve both.
8. **Six signals are emitted but never connected**: `toast_requested`,
   `portal_completed`, `recovery_changed`, `nearby_changed`, `boss_started`,
   `game_over_triggered`. The HUD polls instead of listening to `recovery_changed`.
9. **`CharacterDB.get_character` silently falls back to Qayyim** for an unknown id,
   so a typo'd hero id loads the sword hero instead of failing.
10. **A weapon with no `style` passes both gates and is equipable by every hero**
    (`item_db.gd:253` treats `""` as "any").
11. **Panel rebuilds wipe scroll and hover** on *any* `data_changed` — including the 1-gold
    sea-cleaning drip every ~8.5 s while a shop is open.
12. **`build/` is stale by definition**. Nothing regenerates it; there is no Makefile or CI.
13. **`.godot/` hides breakage**: a deleted source PNG still "passes" from the cached
    `.ctex`. Re-import before trusting a green run after an asset change.
14. **`.gitignore:4` ignores `export_presets.cfg`** — that is the only record of both
    presets. Remove that line before any `git init`, or the build config is lost.
15. **Export is currently impossible on this host**: no 4.7.2 export templates
    (`~/.local/share/godot/export_templates/` empty) and the configured debug keystore
    `/home/roku/.local/share/godot/keystores/debug.keystore` does not exist.
16. **New scripts need an import pass.** A freshly added `.gd` with a `class_name` is
    invisible to other scripts until `godot --headless --path . --import` regenerates
    `.godot/global_script_class_cache.cfg` — the parse error is "Could not find type X".
17. **`AnimatedTexture` frames are property paths.** Set them with
    `set("frame_0/texture", tex)` / `set("frame_0/duration", t)` — attribute-style
    access (`frame_0.texture`) is a runtime error in 4.7.
18. **Ambient NPC shopping is VFX-only by contract.** `Resident.begin_shopping_trip` must
    never call a `GameState` transaction; the suite asserts the player's gold and
    inventory are byte-identical across a full trip and that no shop panel opens.

---

## 9. Docs: trust ranking

Read in this order; older docs lie in a consistent direction ("250 checks, PASS",
"invulnerable trees").

| Rank | File | State |
|---|---|---|
| 1 | `docs/ARCHITECTURE.md` | Best doc; matches code except the tree claim (resolved) |
| 2 | `docs/ACCEPTANCE_TESTS.md` | Rules are substantively correct; synced with the 361-check suite |
| 3 | `README.md` | Good orientation; verification claim updated |
| 4 | `docs/VISUAL_OVERHAUL.md` | Design doc; §2 zoom decision superseded by the adjustable setting (default 40) |
| 5 | `docs/QA_REPORT.md` | Historical |
| 6 | `docs/COMPLETION_REPORT.md` | Changelog |
| 7 | `docs/ANDROID_BUILD.md` | Quoted config block does not exist in `project.godot`; preset already exists |
| 8 | `docs/LEGACY_CONVERSION.md` | Wrongly names `main.tscn` as the run scene; false exit-code promise |
| 9 | `CONVERSION.md`, `docs/LEGACY_CONVERSION_NOTES.md` | Byte-identical generated converter logs, not documentation |

---

## 10. Definition of done

1. `godot --headless --path . --import` ran (fresh checkout only).
2. `timeout 600 godot --headless --path . res://tools/tide_test.tscn` → `0 FAILURE(S)`, exit 0.
3. Stdout grepped for `[FAIL]`, `SCRIPT ERROR`, `ERROR:` — clean.
4. Any doc you made false is updated in the same change; if the change alters a game rule,
   `tools/tide_test.gd` and `docs/ACCEPTANCE_TESTS.md` changed together.
5. Visual changes were reviewed through `tools/visual_review.tscn` screenshots (both
   window sizes, low/high quality), not assumed from code.
6. Working tree has no stray output (`res://shots`, rebuilt `build/`) unless intended.
7. The player's save was backed up before running the suite and restored after.
