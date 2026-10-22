# Agent A — Runtime Architecture & Core Systems

Scope: `project.godot`, `scenes/`, `scripts/game/`, `scripts/autoload/`, `scripts/core/`, `scripts/player/`, `scripts/pets/`, `scripts/combat/`, and the loose root-level scripts. Read in full: `game_state.gd` (1287 lines), `game.gd`, `sfx.gd`, `player.gd`, `enemy.gd`, `pet.gd`, `arrow.gd`, `boss_projectile.gd`, `follow_camera.gd`, `ui_theme.gd`, all nine loose scripts, and `scenes/main.tscn` structurally (4298-line scene, read via node/script index). `pixel_art.gd` read by API surface (40+ static builders), not line-by-line body.

Measured size: **61 `.gd` files / 11,139 lines under `scripts/`**, plus 8 tool scripts under `tools/`; `scenes/game.tscn` is 6 lines, `scenes/main.tscn` is 4298 lines. (The brief's "~80 scripts / 14,556 lines" does not match the tree as measured — see Open questions.)

Every claim below cites `path:line`. Anything I could not verify in-engine (Godot runtime behaviour, not code) is marked `UNVERIFIED:`.

| File | Lines | Role |
|---|---|---|
| `scripts/autoload/game_state.gd` | 1287 | single global state + save/load |
| `scripts/autoload/sfx.gd` | 136 | procedural SFX bus |
| `scripts/game/game.gd` | 307 | top-level flow controller |
| `scripts/core/pixel_art.gd` | 1106 | procedural art, static cache |
| `scripts/core/ui_theme.gd` | 130 | palette + theme factory |
| `scripts/core/follow_camera.gd` | 38 | live world camera |
| `scripts/player/player.gd` | 390 | player controller |
| `scripts/player/player_sprite.gd` | 53 | directional sprite + bob |
| `scripts/player/arrow.gd` | 65 | ranged projectile |
| `scripts/pets/pet.gd` | 167 | companion follower |
| `scripts/combat/enemy.gd` | 439 | monster + boss |
| `scripts/combat/boss_projectile.gd` | 66 | boss orb |

---

## 1. Boot path

**Autoload order and main scene.** `config_version=5` (`project.godot:9`), project name `"Save The World"` (`project.godot:13`), main scene `res://scenes/game.tscn` (`project.godot:15`), features `4.7` + `GL Compatibility` (`project.godot:16`). Exactly two autoloads, in this order (`project.godot:21-22`):

1. `GameState` → `res://scripts/autoload/game_state.gd`
2. `Sfx` → `res://scripts/autoload/sfx.gd`

Both are `*`-prefixed (enabled singletons). There are no other autoloads anywhere in the repo, and no other files in `scripts/autoload/`.

**Sequence.**

1. `GameState._ready()` — sets `process_mode = PROCESS_MODE_ALWAYS` (`scripts/autoload/game_state.gd:39`), probes `FileAccess.file_exists(SAVE_PATH)` into `has_existing_save` (`:40`), then either `load_game()` (`:42`) or `data = _make_default(DEFAULT_CHARACTER)` (`:44`). This runs **before** the main scene, so `Game._ready` can already read `GameState.has_existing_save`.
2. `Sfx._ready()` — builds an 8-player `AudioStreamPlayer` pool (`scripts/autoload/sfx.gd:15-21`).
3. `scenes/game.tscn` instantiates one `Node2D` named `Game` with `scripts/game/game.gd` attached (`scenes/game.tscn:5-6`). **The entire game below this node is built in code — the scene has no children.**
4. `Game._ready()`: `add_to_group("game")` (`scripts/game/game.gd:24`); creates `WorldHolder` (`:25-27`); creates `GameHUD` and adds it, hidden (`:28-31`); `_connect_hud()` (`:32`); connects `GameState.player_defeated` (`:33`); `_show_title()` (`:34`).
5. `GameHUD._ready()`: `layer = 10` (`scripts/ui/game_hud.gd:72`), builds every panel, connects `data_changed`, `pet_changed`, `boss_health_changed`, `expedition_changed`, `emergency_changed` (`:83-87`), `refresh_all()` (`:89`).
6. `_show_title()`: new `CanvasLayer` named `TitleLayer`, `layer = 200` (`scripts/game/game.gd:65-68`), then `TitleScreen.new()` with `save_available = GameState.has_existing_save` (`:69-70`), connecting `character_selected` → `_on_character_selected` and `continue_requested` → `_on_continue_requested` (`:71-72`). Title screen itself is a full-rect `Control` that builds its own UI (`scripts/ui/title_screen.gd:27-35`).
7. **Character select is not a separate scene** — it is part of `TitleScreen` ("CHOOSE YOUR ROAD", `scripts/ui/title_screen.gd:68`); each card's button emits `character_selected` (`:114`). Continue button emits `continue_requested` (`:63`) and is disabled unless `save_available` (`:61-62`).
8. `Game._on_character_selected(character_id)` (`scripts/game/game.gd:76`): `GameState.new_game(character_id)` (`:79`) → `_remove_title()` (`:80`) → `hud.visible = true` (`:81`) → `_load_lobby(false)` (`:82`, no fade) → `hud.start_tutorial()` (`:83`).
9. `Game._load_lobby(transition)` (`:116`): guards `_transitioning` (`:117-118`), locks input (`:120`), optional `await hud.fade_to_black(0.25)` (`:121-122`), `_clear_world()` (`:123`), `hud.set_build_mode(false)` (`:124`), `Lobby.new()` → named `"Lobby"` → assigned to `world` → `_world_holder.add_child` (`:125-128`), `hud.set_world(lobby)` (`:129`), resets health if `<= 0` (`:131-132`), unlocks (`:133-134`), optional fade in (`:135-136`).
10. `Lobby._ready()` builds the whole hub: terrain, bounds, house, shops, residents, portals, dock, forest, forest monsters, scatter, coastal system, recovery ward, settlement editor, then `_build_player_and_pet()` and `_build_camera()` (`scripts/world/lobby.gd:47-65`), connects `house_changed`, `data_changed`, `pet_changed`, `emergency_changed` (`:68-71`), restores recovery/emergency state from the save (`:72-76`), and flips `tutorial_seen` + saves on first ever lobby (`:77-80`).
11. Portal interaction: `PortalEntrance.interact` calls `game.open_portals(portal_id)` (`scripts/world/portal_entrance.gd:79-88`); the Enter button in `PortalPanel` calls `game.enter_portal(portal_id)` (`scripts/ui/portal_panel.gd:79-82`).
12. `Game.enter_portal(portal_id)` (`scripts/game/game.gd:163`): `GameState.portal_clear_reason` (`:164`), toast on failure (`:165-167`), `GameState.start_expedition` (`:168`), resets `_defeat_pending`, `_portal_elapsed`, `_emergency_triggered`, `_settlement_damage_accum` (`:170-173`), `_load_dungeon(portal_id, true)` (`:174`).
13. `_load_dungeon` (`:140`): fade (`:146`), `_clear_world` (`:147`), `Dungeon.new()` → `dungeon.setup(portal_id)` **before** `add_child` (`:149-153`) so `_ready` sees `_definition`, then `hud.set_world(dungeon)` (`:154`). `Dungeon._ready` builds lighting, ground, bounds, decor, player+pet, monsters, exit, camera, then connects `player_defeated` and `boss_health_changed` (`scripts/world/dungeon.gd:33-50`).
14. Back to lobby: `PortalExit.interact` → `dungeon.exit_to_lobby(true)` (`scripts/world/portal_exit.gd:35-38`) → `GameState.leave_portal_safely()` then `game.return_to_lobby(false)` (`scripts/world/dungeon.gd:339-344`) → `_load_lobby(true)` (`scripts/game/game.gd:177-186`).
15. Victory: boss dies → `Enemy._die` emits `boss_finished` (`scripts/combat/enemy.gd:380`) → `Dungeon._on_boss_finished` calls `GameState.complete_portal` and `game.show_victory(summary, portal_id)` (`scripts/world/dungeon.gd:328-336`) → `Game.show_victory` opens `hud.victory_panel` (`scripts/game/game.gd:211-212`); the panel's return button calls `game.return_to_lobby(true)` (`scripts/ui/victory_panel.gd:58-63`).
16. Defeat: `GameState.damage_player` emits `player_defeated` at 0 HP (`scripts/autoload/game_state.gd:434-435`) → `Game.handle_portal_defeat` (`scripts/game/game.gd:189`) → `player().die()`, `GameState.defeat_in_portal()`, then after 0.7 s shows `defeat_panel` (`:193-203`) → its button calls `game.return_to_lobby(true)` (`scripts/ui/defeat_panel.gd:32-36`).
17. Continue from title: `Game._on_continue_requested` (`:86`) → `GameState.continue_game()` (`:87`) → if `GameState.expedition_active()` reload the saved dungeon (`:91-93`) else lobby (`:94-95`).

**Notable:** no `change_scene_to_file` / `change_scene_to_packed` / `reload_current_scene` exists anywhere in `scripts/` (verified by grep); scene switching is entirely manual node creation/freeing (§6).

---

## 2. Autoload singletons

### GameState (`scripts/autoload/game_state.gd`)

Signals (`:8-18`): `data_changed` `:8`, `toast_requested(text, tone)` `:9`, `pet_changed` `:10`, `house_changed(level)` `:11`, `portal_completed(portal_id)` `:12`, `player_defeated` `:13`, `expedition_changed` `:14`, `boss_health_changed(active, name, value, maximum)` `:15`, `recovery_changed(active, progress)` `:16`, `emergency_changed(active, remaining, damage)` `:17`, `game_over_triggered(reason)` `:18`.

Constants (`:20-25`): `SAVE_PATH := "user://tidesworn_save.json"` `:20`, `SAVE_VERSION := 6` `:21`, `INVENTORY_STACK_DEFAULT := 9` `:22`, `DEFAULT_CHARACTER := "qayyim"` `:23`, `AUTO_HEAL_RATIO := 0.10` `:24`, `AUTO_HEAL_REARM_RATIO := 0.35` `:25`.

Public vars (`:27-30`): `data: Dictionary` `:27`, `has_existing_save: bool` `:28`, `autosave_enabled := true` `:29`, `game_over_active := false` `:30`. Private: `_clock_accum` `:32` (declared, **never used**), `_last_purchase` `:33`, `_purchase_serial` `:34` (incremented at `:222`, never read), `_auto_heal_armed` `:35`.

Lifecycle: `_ready` `:38-44`, `_process` `:47-51` (adds `delta` to `data.play_time` every frame, `:51`).

Creation / save root: `_make_default` `:56-136`, `new_game` `:139-145`, `continue_game` `:148-153`, `_emit_all` `:156-162`.

Economy: `gold` `:167`, `diamonds` `:171`, `add_gold` `:175`, `add_diamonds` `:182`, `buy_item` `:190-227` (rate-limits per item to 280 ms, `:195-199`; refuses duplicate equipment `:201-202`; single-unit clamp `:203-205`; validates funds then mutates `:207-221`), `can_add_item` `:230`, `sell_item` `:239-254`, `add_item` `:257-267`, `remove_item` `:270-289` (also clears a matching equipped slot, `:282-287`), `item_count` `:292`, `consume_item` `:296-334`, `equip_item` `:337-355` (enforces weapon discipline `:346-348`), `equipped_item` `:358`, `character_weapon_style` `:362`, `character_data` `:366`.

Derived stats: `attack_power` `:370-377` (`4 + level*2 + character.attack + equipment`), `defense` `:380-387`, `move_speed` `:390`, `health` `:395`, `health_max` `:399`, `mana` `:403`, `mana_max` `:407`, `shield` `:411`, `add_shield` `:415-419` (caps at 60), `damage_player` `:422-435`, `_try_auto_heal` `:438-449`, `heal` `:452-458`, `set_health` `:461-465`, `spend_mana` `:468-473`.

XP/level: `grant_xp` `:478-496` (loop `:483-491`; `xp_next *= 1.45` `:486`; `hp_max += 10`, `mana_max += 4` `:487-488`; full refill on level `:489-490`).

Pets: `get_active_pet` `:501`, `get_pet` `:509`, `active_pet_id` `:513`, `has_living_pet` `:517`, `set_active_pet` `:522`, `purchase_pet` `:532-558`, `upgrade_pet` `:561-580` (cost `45 + level*35`, `:568`), `_give_pet_xp` `:583-595`, `pet_xp_progress` `:598`, `feed_active_pet` `:612`, `feed_pet` `:616-638`, `pet_battle_state` `:641`, `pet_battle_clear_reason` `:652`, `complete_pet_battle` `:668-703`, `register_rubbish_cleaned` `:706-712`.

Forest/settings: `forest_tree_health` `:717`, `set_forest_tree_health` `:722`, `trigger_game_over` `:728-732`, `gui_scale` `:735`, `set_gui_scale` `:740`, `control_layout` `:748`, `set_control_layout` `:754`, `reset_control_layout` `:764`, `pet_ability_summary` `:772`, `revive_active_pet` `:785-792`, `damage_pet` `:795-805`.

House: `house_level` `:810`, `upgrade_house` `:814-827` (diamond cost from `HouseDB`, `:818-821`), `sleep_recovery_seconds` `:830`.

Portals / expedition: `portal_state` `:836`, `portal_clear_reason` `:840-854` (unknown `:842-843`, locked `:845-846`, level gate `:847-849`, blocks during emergency `:850-851` and recovery `:852-853`), `can_enter_portal` `:857`, `start_expedition` `:861-877`, `expedition_active` `:880`, `expedition_portal` `:884`, `expedition_loot` `:888`, `add_expedition_loot` `:892-906`, `expedition_loot_summary` `:909-920`, `bank_expedition_loot` `:923-940`, `lose_expedition_loot` `:943`, `_clear_expedition` `:950`, `complete_portal` `:960-1008`, `defeat_in_portal` `:1011-1023`, `leave_portal_safely` `:1026`, `kills` `:1032`, `register_kill` `:1036`.

Recovery / emergency / layout: `recovery_active` `:1043`, `recovery_progress` `:1047` (HP fraction, not a timer), `finish_recovery` `:1051-1060`, `placeable_position` `:1063-1070`, `set_placeable_position` `:1073-1078`, `emergency_active` `:1081`, `emergency_monsters` `:1085`, `emergency_damage` `:1089`, `start_emergency` `:1093-1102`, `damage_settlement` `:1105-1110` (clamped 0..100), `register_emergency_kill` `:1113-1127`.

Time / save: `time_string` `:1132` (always `"DAYTIME"`), `objective_lines` `:1136-1153`, `save_game` `:1156`, `_save_if_needed` `:1160-1162`, `_save_now` `:1165-1175`, `load_game` `:1178-1201`, `delete_save` `:1204-1207`, `_merge` `:1210-1218`, `_sanitize` `:1221-1287`.

**Authoritative source of truth** is the single `data: Dictionary` (`:27`). Keys created in `_make_default` (`:77-136`) and their owners:

| Domain | Keys | Where written |
|---|---|---|
| Identity | `character_id`, `character_name`, `character_title` | `_make_default:79-81`, `_sanitize:1259-1261` (name/title always re-derived from `CharacterDB`) |
| Vitals | `hp`, `hp_max`, `mana`, `mana_max`, `shield` | `damage_player:422`, `heal:452`, `set_health:461`, `grant_xp:487-490`, `_sanitize:1224-1228` |
| Progression | `level`, `xp`, `xp_next` | `grant_xp:481-486` |
| Currency | `gold`, `diamonds` | `add_gold:175`, `add_diamonds:182`, `buy_item:215-219`, `sell_item:250`, `bank_expedition_loot:930-931`, `complete_portal:975-976` |
| Inventory | `inventory` (id → count), `equipped` (weapon/armor/shield) | `add_item:257`, `remove_item:270`, `equip_item:337` |
| Pets | `pets` (id → {id,level,xp,hp,hp_max,alive,owned}), `active_pet` | `purchase_pet:544`, `_give_pet_xp:585-593`, `_sanitize:1266-1273` |
| House | `house_level` | `upgrade_house:822` |
| Portals | `portals` (id → {unlocked, cleared, attempts}) | `start_expedition:865-866`, `complete_portal:977-985` |
| Expedition | `expedition` {active, portal_id, gold, diamonds, items} | `start_expedition:867-873`, `add_expedition_loot:895-904`, `_clear_expedition:951-957` |
| Emergency | `emergency_active`, `emergency_monsters`, `emergency_damage` | `start_emergency:1096-1098`, `register_emergency_kill:1116-1119` |
| Recovery | `recovery_active` | `defeat_in_portal:1017`, `finish_recovery:1054` |
| Settlement | `settlement_layout` (placeable_id → [x, y]) | `set_placeable_position:1073-1076` |
| Misc | `kills`, `bosses`, `deaths`, `sea_cleaned`, `forest_health`, `pet_battles`, `settings`, `play_time`, `tutorial_seen`, `version` | see `_make_default:119-135` |

`data` is public and **bypassed** in a few places: `player.gd:65` (read `character_id`), `game_hud.gd:586,591` (read identity/xp), `inventory_panel.gd:19,47`, `portal_panel.gd:23`, `sea_cleaning_panel.gd:13`, `shop_panel.gd:59`, and one **write**: `lobby.gd:78` sets `data.tutorial_seen = true` then calls `save_game()` at `:79`.

### SFX (`scripts/autoload/sfx.gd`)

Vars: `_cache: Dictionary` `:10`, `_players: Array[AudioStreamPlayer]` `:11`, `_next_player` `:12`. Consts: `MIX_RATE := 22050` `:7`, `PLAYER_POOL := 8` `:8`.
Functions: `_ready` `:15-21`, `_exit_tree` `:24-30` (stops and nulls streams, clears both cache and pool), `play(kind, volume_db = -7.0)` `:33-43` (round-robin over the pool), `has_sound` `:46-47` (**no callers**), `_get_stream` `:50-57`, `_build_stream` `:60-136`.

Sound kinds synthesised: `tree_hit`, `aggro`, `charge`, `skill_attack`, `skill_guard`, `skill_recover`, `victory`, `select`, plus a default (`:65-110`). Synthesis is brute-force per-sample in GDScript (`:116-130`) — one-off, cached per kind, never evicted. Call sites: `enemy.gd:235,281`, `forest_tree.gd:63`, `pet_battle_panel.gd:207,277,279,281,419`. No audio assets, no `[audio]` section in `project.godot`, all players on `"Master"` (`:18`).

---

## 3. Signal map

No signal is wired in any `.tscn` — `grep '^\[connection'` returns nothing across `scenes/` and `tools/`. **All connections are code.**

### GameState signals

| Signal | Emitted at | Connected at | Status |
|---|---|---|---|
| `data_changed` | 36 sites in `game_state.gd` (e.g. `:179,224,252,288,419,433,458,495,1005`) | `game_hud.gd:83`, `house_panel.gd:9`, `inventory_panel.gd:8`, `pet_battle_panel.gd:51`, `portal_panel.gd:11`, `shop_panel.gd:12`, `lobby.gd:69`, `portal_entrance.gd:50` | live, firehose |
| `toast_requested` | 45 sites (`game_state.gd`, `enemy.gd:370,375`, `game.gd:166,280,283`, `player.gd:386`, `pet.gd:76`, UI panels, world scripts) | **none** | **dead by design — HUD's `show_toast(_text, _tone)` is an empty stub (`game_hud.gd:692-695`, comment: "In-world notifications are intentionally disabled")** |
| `pet_changed` | `:158,527,576,594,690,791,804,1022` | `pet.gd:25`, `game_hud.gd:84`, `shop_panel.gd:15`, `lobby.gd:70` | live |
| `house_changed` | `:159,825` | `house_panel.gd:12`, `house_bed.gd:24`, `lobby.gd:68` | live |
| `portal_completed` | `:1006` | **none** | **dead (emitted, never connected)** |
| `player_defeated` | `:435,1020` | `game.gd:33`, `dungeon.gd:48` | live, double-listener |
| `expedition_changed` | `:160,875,905,937,947,1007` | `game_hud.gd:86` | live |
| `boss_health_changed` | `enemy.gd:148,163,354,379`, `game.gd:183,200`, `dungeon.gd:352,360` | `game_hud.gd:85`, `dungeon.gd:49` | live, everyone emits it |
| `recovery_changed` | `:161,1023,1059` | **none** | **dead (HUD polls instead)** |
| `emergency_changed` | `:162,1101,1110,1122,1127` | `game_hud.gd:87`, `lobby.gd:71`, `resident.gd:30` | live |
| `game_over_triggered` | `:732` | **none** | **dead (see gotchas)** |

### Entity signals

| Signal | Defined | Emitted | Connected |
|---|---|---|---|
| `Player.sleep_changed(active, progress, label)` | `player.gd:8` | `player.gd:139,144,371,381` | `lobby.gd:807` |
| `Player.nearby_changed(interactable)` | `player.gd:9` | `player.gd:299` | **none — HUD reads `player.nearby` directly (`game_hud.gd:548`)** |
| `Player.hurt_flash` | `player.gd:10` | `player.gd:326` | `lobby.gd:808`, `dungeon.gd:255` |
| `Enemy.boss_started(enemy)` | `enemy.gd:7` | `enemy.gd:147` | **none** |
| `Enemy.boss_finished(enemy)` | `enemy.gd:8` | `enemy.gd:380` | `dungeon.gd:304` |
| `ModalBase.closed` | `modal_base.gd:6` | `modal_base.gd:87` | 8 panels → `game.gd:52-59` |
| `GameHUD.inventory_requested` / `build_mode_requested` | `game_hud.gd:5-6` | `game_hud.gd:541-543` | `game.gd:60-61` |
| `TitleScreen.character_selected` / `continue_requested` | `title_screen.gd:6-7` | `:114` / `:63` | `game.gd:71-72` |

Completeness check: all 22 `signal` declarations in `scripts/` are emitted at least once, so there is no defined-but-never-emitted signal. The only signal outside this slice is `ForestTree.felled` (`scripts/world/forest_tree.gd:6`, emitted `:97`, connected `lobby.gd:661`). The dead cases are all emitted-but-never-connected, listed above.

Cross-entity communication that is **not** signal-based (important): combat is duck-typed through groups — `has_method("take_damage")` + `call()` (`player.gd:176-184`, `arrow.gd:40-44`, `pet.gd:119-121`, `enemy.gd:157-160`), and cross-world commands go through the `"game"` group with `has_method` (`dungeon.gd:334-336,342-344,353-355`, `portal_entrance.gd:80-88`, `portal_exit.gd:36-38`, `shop_npc.gd:33`, `coastal_guard.gd:33`, `defeat_panel.gd:33-36`, `victory_panel.gd:58-63`).

---

## 4. Persistence

**Path.** `SAVE_PATH := "user://tidesworn_save.json"` (`scripts/autoload/game_state.gd:20`). With `config/name="Save The World"` (`project.godot:13`) this resolves on Linux to `~/.local/share/godot/app_userdata/Save The World/tidesworn_save.json` — verified on this machine, file exists (3114 bytes), `version: 6`, 35 top-level keys, 10 portal ids.

**Format.** Plain JSON via `JSON.stringify(data, "\t")`, UTF-8 text, one file, no backup/atomic-rename (`:1169-1174`). Failure to open only pushes a warning (`:1170-1172`).

**Serialized keys** — exactly the `_make_default` dictionary (`:77-136`): `version, character_id, character_name, character_title, level, xp, xp_next, hp, hp_max, mana, mana_max, shield, gold, diamonds, inventory, equipped, pets, active_pet, house_level, portals, expedition, kills, bosses, deaths, recovery_active, emergency_active, emergency_monsters, emergency_damage, settlement_layout, pet_battles, sea_cleaned, forest_health, settings{gui_scale, control_layout}, play_time, tutorial_seen`.

**When saves happen.** (all line numbers in this list are `scripts/autoload/game_state.gd` unless marked)
- Autosave on nearly every transactional mutation: `buy_item:223`, `sell_item:251`, `consume_item:331`, `equip_item:352`, `grant_xp:496`, `purchase_pet:555`, `upgrade_pet:577`, `feed_pet:631`, `complete_pet_battle:694`, `register_rubbish_cleaned:712`, `start_expedition:874`, `bank_expedition_loot:935`, `lose_expedition_loot:945`, `complete_portal:1004`, `defeat_in_portal:1019`, `finish_recovery:1057`, `set_placeable_position:1077`, `start_emergency:1099`, `register_emergency_kill:1120,1125`, plus settings setters (`:745,761,769`).
- `new_game` saves immediately (`:144`).
- `Game._notification` saves on `WM_CLOSE_REQUEST`, `APPLICATION_PAUSED`, `APPLICATION_FOCUS_OUT` (`scripts/game/game.gd:305-307`) — i.e. also on alt-tab. `UNVERIFIED:` whether Godot delivers `WM_CLOSE_REQUEST` before the process exits in this project's configuration (no `auto_accept_quit=false` is set anywhere).
- `autosave_enabled` is `true` and **never set false** (`:29`, only read at `:1161`), so `_save_if_needed` always writes.
- Not saved on: `add_gold`, `add_diamonds`, `add_expedition_loot`, `damage_player`, `heal`, `set_health`, `add_item` — these only emit `data_changed`. Gold picked up from `LootDrop` (`scripts/world/loot_drop.gd:65`) is therefore in memory only until the next saving action.

**Load + migration.** `load_game` (`:1178-1201`): existence check (`:1179`), read text (`:1181-1185`), `JSON.parse_string` (`:1186`), dictionary check (`:1187-1188`), character-id validation with fallback to `DEFAULT_CHARACTER` (`:1191-1193`), `data = _merge(_make_default(loaded_id), loaded)` (`:1194-1195`), `_sanitize()` (`:1196`), arms auto-heal, clears game-over (`:1197-1198`), `_emit_all()` (`:1200`).

- `_merge` (`:1210-1218`) is a **recursive dictionary merge where the fresh default is the base and the save wins** — that is the entire "migration" mechanism: new keys appear with defaults, removed keys disappear.
- `SAVE_VERSION` is written (`:1168`) but **never read** — there is no version comparison anywhere; `data.version` is decorative.
- `_sanitize` (`:1221-1287`) clamps: gold/diamonds ≥ 0 (`:1222-1223`), `hp_max ≥ 1` (`:1224`), hp/mana clamped (`:1225-1227`), shield 0..60 (`:1228`), house level 1..`HouseDB.max_level()` (`:1229`), level ≥ 1 (`:1230`), dictionary-type guards for inventory/pets/portals/settlement_layout/pet_battles/forest_health (`:1231-1243`), `settings.gui_scale` clamped 0.75..1.3 (`:1247`), clears a stale expedition when `active=false` (`:1249-1250`), clamps emergency/recovery (`:1251-1254`), re-derives character name/title (`:1255-1261`), deletes retired `pet_revival` item (`:1262-1264`), re-grants `ember` and a non-empty `active_pet` (`:1266-1273`), revives all pets (`:1274-1278`), and re-equips a discipline-legal starter weapon if the saved one is wrong (`:1279-1287`).

**Type coercion caveat:** Godot's JSON parser returns every number as `float`. The on-disk file proves it: `portals.tidebound_grotto.attempts` is `0.0`, `xp` is `62.0`, `xp_next` is `126.0`. Every read therefore goes through `int(...)` (e.g. `:168,396,483,848`). New code must do the same; `maxi()/mini()` called with these floats relies on GDScript's numeric coercion.

**What is NOT saved:** live player position/facing/HP beyond the `hp` field, active enemies and boss HP, the current modal, camera state, the SFX cache and `PixelArt.CACHE` (process-lifetime only, `pixel_art.gd:12`), `_last_purchase`/`_purchase_serial` (anti-spam state, `:33-34`), `_auto_heal_armed` (`:35`, re-armed on load), `game_over_active` (`:30`, reset on load), `autosave_enabled`, and `has_existing_save` (recomputed at `:40`). Also not saved: which portal the *player* is standing in — resumption relies solely on `expedition.active` + `expedition.portal_id` (`game.gd:91-93`), so a save made inside a dungeon and then a defeat can resume into a dungeon whose loot was already cleared.

**Settlement layout persistence.** Stored under `settlement_layout` as `placeable_id → [x, y]` floats (`:1075`), read with a fallback (`:1063-1070`), written on every drop (`:1073-1078` → `_save_if_needed`). Only positions are persisted — rotation/level/state of placeables is not. Default is `{}` (`:126`), and non-dictionary values are replaced in `_sanitize` (`:1237-1238`).

---

## 5. Combat / entity contract

### Entity table

| Entity | Script | Base | Groups | Collision layer / mask | Finds others by |
|---|---|---|---|---|---|
| Player | `scripts/player/player.gd` | `CharacterBody2D` | `player` (`:35`) | layer `2`, mask `5` (`:36-37`) | `get_nodes_in_group("enemies")` `:173,192,210`; `get_nodes_in_group("interactable")` `:287` |
| Enemy / boss | `scripts/combat/enemy.gd` | `CharacterBody2D` | `enemies` (`:55`), + `forest_monsters` if `forest_mode` (`:56-57`) | layer `4`, mask `1` (`:58-59`); set to `0` on death (`:382,388`) | `get_first_node_in_group("player")` `:61,128`; `forest_tree` `:308`; `settlement_target` `:325` |
| Pet | `scripts/pets/pet.gd` | `Node2D` | `pet` (`:22`) | none (no body) | `get_first_node_in_group("player")` `:65`; `enemies` `:132` |
| Arrow | `scripts/player/arrow.gd` | `Node2D` | `projectile` (`:17`) | none | `enemies` `:37` |
| BossProjectile | `scripts/combat/boss_projectile.gd` | `Node2D` | none | none | `get_first_node_in_group("player")` `:40` |
| Camera | `scripts/core/follow_camera.gd` | `Camera2D` | `camera` (`:15`) | n/a | direct `target` field (`:6,27`) |
| Interactable | `scripts/world/interactable.gd` | `Area2D` | `interactable` (`:16`) | layer `0`, mask `0`, `monitoring=false`, `monitorable=false` (`:17-20`) | found by player distance, not physics |

Layer names in `project.godot:100-102`: `World`=1, `Player`=2, `Enemy`=3 (these are **layer indices**; the code writes the bitmask values 1, 2, 4).

Consequence: `Player.mask 5` = World(1)|Enemy(4), so `move_and_slide` blocks the player against enemy bodies; `Enemy.mask 1` = World only, so enemies walk through the player and through each other. `Player` collision shape is a capsule r=0.26 h=0.62 at y=-0.12, built in `_build_body` (`player.gd:43-51`); `Enemy` uses a circle of `body_radius` at y=-radius/2 (`enemy.gd:88-94`).

### Damage contract (duck-typed, no interfaces)

- **Anything that can be hit** must expose `take_damage(amount: int, from_dir: Vector2 = ZERO, source: Node = null)`. `Enemy.take_damage` matches (`enemy.gd:344`), `Player.take_damage(amount, from)` takes two args (`player.gd:321`), pet projectiles/arrows pass three (`arrow.gd:44`, `pet.gd:121`), so the third arg is silently dropped by `Player`.
- Player → enemy: group scan, range check `attack_range + enemy.body_radius`, facing dot-product gate for swords (`player.gd:173-186`), no gate for hammers (`:188-203`), bow picks the nearest enemy in a 8.5-unit cone and spawns an `Arrow` (`:206-232`).
- Enemy → player: `_target.call("take_damage", damage, global_position)` (`enemy.gd:158`), or `take_attack_damage` for residents (`:159-160`). Boss specials: punch `:193-200`, area slam with 0.55 s telegraph `:203-212`, charge `:227-253`, projectile `:215-224`; ability chosen by `boss_ability` string `:176-190`.
- Player damage path: `Player.take_damage` gives 0.55 s i-frames (`player.gd:324`), calls `GameState.damage_player` (`:325`), emits `hurt_flash` (`:326`), pushes back 0.18 units (`:327-329`), flashes (`:330-333`), and calls `die()` at 0 HP (`:334-335`). `GameState.damage_player` subtracts `defense()` with a floor of 1 (`game_state.gd:425`), spends shield first (`:426-429`), then HP, then attempts auto-heal (`:432`), emits `data_changed` and `player_defeated` (`:433-435`).
- Enemy death: `_die` (`enemy.gd:360-392`) awards XP (or gold + `register_emergency_kill` in settlement mode, `:367-370`), spawns loot for non-boss (`:376-377`, `:395-414`), emits `boss_health_changed(false,…)` + `boss_finished` for bosses (`:378-380`), then tweens out and `queue_free`s (`:383-392`).
- Boss HP bar: the boss itself pushes `GameState.boss_health_changed` every physics frame while aggroed (`enemy.gd:162-163`) and on every hit (`:354`); `Enemy.boss_started` is emitted once (`:147`) but has no listener.
- Pet abilities: only while an enemy is within 7 units (`pet.gd:103-106`); heal/attack/shield on independent timers driven by `PetDB` (`:112-126`); shield goes to `GameState.add_shield` (`:125`). `GameState.damage_pet` exists (`game_state.gd:795`) but **has no caller** — pets cannot currently lose HP.
- Projectiles are pure distance checks in `_physics_process` (`arrow.gd:37-46`, `boss_projectile.gd:40-46`); neither is an `Area2D`, so collision layers are irrelevant to them.
- Interactables: player scans the `interactable` group each physics frame, skips `is_interactable_available() == false`, reads `interact_radius` (default 1.8), picks nearest (`player.gd:284-299`), and `try_interact` calls `nearby.interact(self)` (`:277-281`). `Interactable` deliberately disables all physics monitoring (`interactable.gd:17-20`).

---

## 6. Lifecycle / ownership

**Owners.**
- `Game` owns two long-lived children: `WorldHolder` (`game.gd:25-27`) and `HUD` (`:28-30`), plus a transient `TitleLayer` (`:65-68`).
- Each world owns its own player, pet, camera, enemies, props: `Lobby._build_player_and_pet` (`lobby.gd:798-806`), `_build_camera` (`:814-819`); `Dungeon._build_player_and_pet` (`dungeon.gd:246-254`), `_build_camera` (`:318-323`), `_build_monsters` (`:260-305`), `_build_exit` (`:309-313`).
- Effects are parented to `get_parent()` — i.e. the world node, sibling of the player: arrows (`player.gd:230`), damage labels (`:270`), enemy bursts (`enemy.gd:264`), pet icons (`pet.gd:154`), boss projectiles (`enemy.gd:223`), loot (`enemy.gd:408,414` via `call_deferred`).
- HUD owns all 8 modal panels (`game_hud.gd:9-17`, built in `_build_modals` `:477-493`) and never frees them; `ModalBase._clear_content` frees only panel body children (`modal_base.gd:94-98`).

**Scene switching.** Manual only:
- `_clear_world()` does `world.queue_free()` + `world = null` + `hud.set_world(null)` (`game.gd:109-113`).
- `_load_lobby` / `_load_dungeon` construct the new world and add it under `_world_holder` (`:125-128`, `:149-153`).
- Because `queue_free` is deferred, **old and new world coexist for the remainder of the frame** (`game.gd:123` then `:128`). Group-first lookups (`get_first_node_in_group("player")` used by `pet.gd:65`, `enemy.gd:61,128`, `game_hud.gd:238,547`, `loot_drop.gd:42`) can therefore resolve to the outgoing player. `Game.player()` avoids this by preferring `world.get_player()` (`game.gd:297-302`), but nothing else does.
- Re-entrancy is guarded by `_transitioning` (`:117-118`, `:141-142`) and `_defeat_pending` (`:190-192`).

**Pause / modal interplay.** The tree is **never paused** — no `get_tree().paused` anywhere in `scripts/`. Modals are a `Control` overlay with a full-screen dim `ColorRect` on `MOUSE_FILTER_STOP` (`modal_base.gd:25-29`) plus:
- `Game._input_locked` set on open (`game.gd:233,241,249,257,265,273`), cleared in `_on_modal_closed` only when `hud.any_modal_open()` is false (`:215-219`).
- `_apply_input_lock` pushes that into `player.controls_locked` (`:222-225`), which the player honours in `_physics_process` (`player.gd:101-105`) and in `try_attack`/`try_interact` (`:149,278`).
- Time keeps running: `Game._process` (`:37-48`), `GameState._process` (`game_state.gd:47-51`), `Lobby._process` (`lobby.gd:1071-1077`), enemies, and the recovery tick all continue while a panel is open. `open_inventory` is the only modal with **no** `world is Dungeon` guard (`game.gd:270-275`) versus `open_shop`/`open_house`/`open_portals`/`open_pet_battles`/`open_sea_cleaning` which all bail in a dungeon (`:231-232,239-240,247-248,255-256,263-264`).

**Death and respawn.** Defeat is handled only inside a dungeon (`game.gd:206-208` → `handle_portal_defeat`). In the lobby, `player_defeated` has no listener, so a player killed at home stays `dead` with `controls_locked` until the world is reloaded. `UNVERIFIED:` whether an enemy can actually land the killing blow in the lobby given enemy `mask=1` and the player's own i-frames — the code path exists (`enemy.gd:158` is called for `_target = _player` at `:134` when `settlement_mode` is false and no forest target is closer).

---

## 7. Frame / tick model

**`_process` users (24 scripts):** `game_state.gd:47`, `game.gd:37`, `core/follow_camera.gd:26`, `player/player_sprite.gd:29`, `pets/pet.gd:63`, `ui/game_hud.gd:518`, `ui/pet_battle_panel.gd:162`, `ui/title_screen.gd:144`, `ui/touch_action_button.gd:72`, `world/interactable.gd:25`, `world/lobby.gd:1071`, `world/portal_entrance.gd:54`, `world/portal_exit.gd:30`, `world/recovery_ward.gd:34`, `world/forest_tree.gd:52`, `world/resident.gd:53`, `world/resource_pile.gd:34`, `world/rubbish_piece.gd:33`, `world/rubbish_system.gd:47`, `world/settlement_editor.gd:56`, plus demo scripts `camera_follow.gd:19`, `player_visual.gd:75`, `props_altar.gd:27`, `sprite_color_animation.gd:17`. Trap when grepping: `player.gd` has `_process_sleep`, `pet.gd` has `_process_abilities`, `enemy.gd` has `_process_charge` — none are engine callbacks, so a naive `grep "func _process"` over-counts by three.

**`_physics_process` users (6):** `player.gd:82`, `enemy.gd:97`, `arrow.gd:29`, `boss_projectile.gd:30`, `loot_drop.gd`, and demo `point_and_click_controller.gd:56`.

**Authoritative per-frame work:**
- `GameState._process` — unconditional `data.play_time += delta` via `float(data.get(...))`, a dictionary read+write every frame, in `PROCESS_MODE_ALWAYS` (`game_state.gd:39,47-51`).
- `Game._process` — checks `world is Dungeon and GameState.expedition_active()` (`game.gd:38`); accumulates `_portal_elapsed` and fires `GameState.start_emergency(3)` at `EMERGENCY_DELAY := 14.0` (`:19,39-43`); then every `SETTLEMENT_DAMAGE_TICK := 5.0` calls `GameState.damage_settlement(5)` (`:20,44-48`).
- `GameHUD._process` — rewrites the clock label every frame (`game_hud.gd:521-522`), `_refresh_recovery()` every frame (`:531`), `_update_prompt()` every frame (`:532` → `get_first_node_in_group("player")` at `:547`), loot refresh at 4 Hz (`:523-526`), mission arrows at 5 Hz (`:527-530`), and polls the hotkeys (`:533-542`).
- `Player._physics_process` — input, `move_and_slide`, then `_update_nearby()` which allocates a fresh array from `get_nodes_in_group("interactable")` every physics tick (`player.gd:124,287`).
- `Enemy._physics_process` — sprite frame swap, hit-flash, aggro logic, and `queue_redraw()` **every tick** (`enemy.gd:170`) even though `_draw` returns immediately at full HP (`:428-429`).
- `Pet._process` — full follower lerp plus `_nearest_enemy` array allocation every tick (`pet.gd:63-99,129-141`).
- `Arrow` / `BossProjectile` — array allocation per projectile per tick (`arrow.gd:37`, `boss_projectile.gd:40` uses group lookup only).

**Timers.** `Tween` is the norm: attack pose (`player.gd:243-249`), damage numbers (`:271-274`), death fades (`enemy.gd:383-392`), loot/pickup, UI fades (`game_hud.gd:722+`), modal popup (`welcome_popup.gd:60-69`). `await get_tree().create_timer(...)` appears only three times: `enemy.gd:206` (0.55 s slam telegraph), `game.gd:202` (0.7 s before the defeat panel), `player.gd:253` (0.12 s attack-pose reset). No global tick/clock service; `GameState.time_string()` always returns `"DAYTIME"` (`game_state.gd:1132-1133`), so there is no day/night simulation despite the name.

---

## 8. Dead code / duplication

| Item | Status | Evidence |
|---|---|---|
| `scripts/core/follow_camera.gd` (`FollowCamera`) | **LIVE** | instantiated in `lobby.gd:814` and `dungeon.gd:318` |
| `scripts/camera_follow.gd` (`CameraFollow` port, no `class_name`) | **DEMO-ONLY** | attached only to `scenes/main.tscn:396` (`target_path = "../../PF Player"` at `:397`) |
| `scripts/player/player_sprite.gd` (`PlayerSprite`) | **LIVE** | `player.gd:63` |
| `scripts/player_visual.gd` | **DEMO-ONLY** | `scenes/main.tscn:156,4247` |
| `scripts/point_and_click_controller.gd` | **DEMO-ONLY** | `scenes/main.tscn:155,4234` |
| `scripts/chest_interact.gd` | **DEMO-ONLY** | `scenes/main.tscn:149,1902` (its popup path `../../../../ChestPopupCanvas/Panel` at `:1909`) |
| `scripts/props_altar.gd` | **DEMO-ONLY** | `scenes/main.tscn:145,1185` |
| `scripts/sprite_color_animation.gd` | **DEMO-ONLY** | `scenes/main.tscn:150,2011,2045` |
| `scripts/stairs_layer_trigger.gd` | **DEMO-ONLY** | `scenes/main.tscn:144` + 6 instances (`:693,2274,2318,2586,3155,3437`) |
| `scripts/welcome_popup.gd` | **DEMO-ONLY** | `scenes/main.tscn:157,4280` |
| `scripts/control_mode.gd` (`ControlModePrefs`) | **FULLY DEAD** | only self-reference; `grep ControlModePrefs` finds no other file; writes `user://unisza.cfg` (`:11`) |
| `scenes/main.tscn` (4298 lines) | **DEMO-ONLY** | main scene is `game.tscn` (`project.godot:15`); `main.tscn` is referenced only by `tools/convert.gd:38` (as output), `tools/play_test.gd:10`, `tools/smoke_test.gd:9`. It still ships: `export_filter="all_resources"`, `exclude_filter="tools/*, docs/*"` (`export_presets.cfg:12-14`) |
| `Player._sword` + `_update_sword` + `_sword` cleanup | **DEAD** | `_sword` declared `player.gd:29`, never assigned anywhere (grep: only reads at `:164,303-312`), so `_update_sword` returns at `:303-304` and the hide at `:164-165` is a no-op |
| `GameState.toast_requested` + `GameHUD.show_toast` | **DEAD BY DESIGN** | 45 emit sites; no `connect` anywhere; `show_toast` body is `pass` (`game_hud.gd:692-695`), `_update_toast_layout` is `pass` (`:657-659`) |
| `GameState.portal_completed` | **DEAD SIGNAL** | emitted `game_state.gd:1006`, no `connect` |
| `GameState.recovery_changed` | **DEAD SIGNAL** | emitted `:161,1023,1059`, no `connect`; HUD polls instead (`game_hud.gd:531,673-682`) |
| `GameState.game_over_triggered` | **DEAD SIGNAL** | emitted `:732`; producer `trigger_game_over` called only from `lobby.gd:473`; no listener anywhere |
| `Player.nearby_changed` | **DEAD SIGNAL** | emitted `player.gd:299`, no `connect` |
| `Enemy.boss_started` | **DEAD SIGNAL** | emitted `enemy.gd:147`, no `connect` |
| `GameState.damage_pet` | **UNCALLED** | only `game_state.gd:795` |
| `GameState.gui_scale/set_gui_scale/control_layout/set_control_layout/reset_control_layout` | **UNCALLED** | definitions `:735,740,748,754,764`; no call sites (only `_sanitize` touches the raw dict at `:1245-1247`) |
| `GameState.pet_ability_summary`, `feed_active_pet` | **UNCALLED** | `:772`, `:612` |
| `Player.revive_at`, `Player.get_facing_angle` | **UNCALLED** | `player.gd:348`, `:389` |
| `GameState._clock_accum`, `_purchase_serial` | **UNUSED VARS** | `:32` never touched; `:34` incremented `:222`, never read |
| `Sfx.has_sound` | **UNCALLED** | `sfx.gd:46-47` |

Duplication worth naming: two camera scripts, two player-visual scripts, two input/controller scripts (`Player` vs `PointAndClickController`), and two "port" naming conventions (`// Port of Cainos'/Unisza'` headers in the demo scripts, no such headers in gameplay scripts).

---

## Conventions observed

- **File layout by role**, not by feature: `scripts/autoload`, `core`, `data`, `game`, `player`, `pets`, `combat`, `world`, `ui`, plus root-level "ported demo" scripts that belong to none of these. `class_name` is declared for every gameplay script; of the nine loose root-level scripts only `control_mode.gd` declares one (`ControlModePrefs`), the other eight do not.
- **Tabs for indentation, `snake_case` members, `PascalCase` classes/`class_name`, SCREAMING_SNAKE constants.** Example: `const INTERACT_RANGE := 2.0` (`player.gd:12`), `var controls_locked := false` (`player.gd:14`).
- **Typed signatures everywhere, partially typed members.** Every `func`/`static func` declares an explicit return type (0 declarations in `scripts/` omit `->`); most parameters are typed too, and locals use `:=`. Member vars are typed only ~46% of the time (165 `var x:` of 360 `var` declarations in `scripts/`) — e.g. `var hud: GameHUD` (`game.gd:7`) but `var _portal_elapsed := 0.0` (`game.gd:15`).
- **Nodes are built in code and found by group, not path.** No `$Path`, no `get_node()` in any gameplay script — only `get_tree().get_nodes_in_group(...)` and `get_first_node_in_group(...)` (`player.gd:173,287`, `enemy.gd:61,308,325`). Exported `NodePath`s + `get_node_or_null` exist only in the demo scripts (`chest_interact.gd:12-14,32-34`).
- **Duck typing over inheritance across systems**: `has_method("take_damage")` then `call(...)` (`player.gd:176-184`), `has_method("get_player")` (`game.gd:300-301`), `has_method("toggle_build_mode")` (`game.gd:285`).
- **Error handling is return-dictionaries, not exceptions**: `{"ok": bool, "message"|"reason": String}` (`game_state.gd:193,211,655,846`; `buy_item`, `portal_clear_reason`).
- **Comments are explanatory prose with a "why", and section banners** like `# --------------------------------------------------------------- economy` (`game_state.gd:165`). Demo scripts carry conversion notes, e.g. `## Port of Cainos' CameraFollow.cs` (`camera_follow.gd:2`) and `## Unity used Input.GetKeyDown, i.e. the press edge, not "is held".` (`chest_interact.gd:44`).
- **Magic numbers live as file-level consts only sometimes**: `EMERGENCY_DELAY`/`SETTLEMENT_DAMAGE_TICK` (`game.gd:19-20`), `RECOVERY_RADIUS/SECONDS` (`lobby.gd:41-43`), `AUTO_HEAL_*` (`game_state.gd:24-25`) — but dungeon geometry is inline (`SPAWN := Vector2(24.0, 28.0)` `dungeon.gd:8`, boss at `Vector2(24, 7)` `:303`) and combat stats are inline in `_build_monsters` (`:277-282`).

---

## Gotchas / footguns

1. **`GameState.data` is public and one place mutates it directly.** `lobby.gd:78` writes `data.tutorial_seen` then saves; all other writers are `GameState` methods. Any new field written from outside will skip `_sanitize`/`_merge` guarantees and may desync the HUD (`data_changed` is not emitted there — `lobby.gd:78-79` saves silently).
2. **No pause anywhere.** Modals only lock player input (`game.gd:222-225`); enemies, the 14 s emergency timer, and settlement damage keep running behind an open panel (`game.gd:37-48`). Opening the inventory inside a dungeon (`game.gd:270-275` has no dungeon guard) can therefore start an emergency while the player is reading their bag.
3. **Emergency is triggered by a *dungeon* timer but resolved in the *lobby*.** `game.gd:43` hardcodes 3 monsters; `lobby.gd:1116-1149` spawns `remaining` settlement monsters plus up to 3 extra forest monsters. Monster count in the save (`emergency_monsters`) is the quota, and `register_emergency_kill` ends it at 0 (`game_state.gd:1113-1127`).
4. **Autosave writes the whole JSON on nearly every transaction.** `grant_xp` saves (`game_state.gd:496`), so every kill in a dungeon rewrites the file; `add_gold`/`add_expedition_loot` do **not** save, so loot picked up between kills is lost on a crash. There is no debounce, no temp-file/rename, and a failed open only logs (`:1170-1172`).
5. **Save format is coupled to `_make_default` forever.** Adding a key requires adding it there (`:77-136`) or the merge will not materialise it; removing one silently drops it. `SAVE_VERSION` is written but never read (`:1168`); there is no version branch to hang a real migration on.
6. **JSON numbers return as floats.** On-disk `xp: 62.0`, `attempts: 0.0` (verified in the live save file). Code compensates with `int()` on every read; a new comparison like `if data.level >= 5` works by coercion, but `str(data.level)` prints `5.0` unless wrapped.
7. **`_clear_world` is deferred (`queue_free`), so two worlds coexist for a frame.** `game.gd:109-113` then `:125-128`/`:149-153`. Every `get_first_node_in_group("player")` (pet, enemies, HUD, loot) can bind to the dying player during a transition. `Game.player()` is the only safe accessor (`:297-302`).
8. **`player_defeated` has two listeners and is emitted twice per portal defeat.** `Game` (`game.gd:33`) and `Dungeon` (`dungeon.gd:48`) both connect; `GameState.defeat_in_portal` emits again at `:1020`. It only works because `_defeat_pending` short-circuits (`game.gd:190-192`) and because the expedition was already cleared so `Dungeon._on_player_defeated` returns at `:348-349`. Reordering those two steps breaks it.
9. **Death at home is unhandled.** Only `Game` (dungeon check at `:207`) and `Dungeon` listen; a lobby death leaves a dead, locked player (`player.gd:338-345`) with no respawn path.
10. **`return_to_lobby(true)` is used for victory too** (`victory_panel.gd:58-63`), so the `from_defeat` parameter is a lie. Currently harmless because its body is `GameState.set_health(GameState.health())` (`game.gd:184-185`), but it will bite anyone who adds logic there.
11. **Equipment discipline is enforced in two places** — `equip_item` (`game_state.gd:346-348`) and `_sanitize` (`:1279-1287`), which silently injects a starter weapon into `data.inventory` on load. Editing `CharacterDB.weapon_style` or `ItemDB.style` changes save-migration behaviour.
12. **`_sword` is never created.** `player.gd:29` declares it; nothing assigns it, so `_update_sword` (`:302-312`) and the hide at `:164-165` are dead. Don't assume a separate sword node exists when changing the attack pose.
13. **Enemies do not collide with the player** (`enemy.gd:58-59`, `mask=1`). If you add `2` to the enemy mask, enemies will start body-blocking the player and each other — a gameplay change, not a bugfix.
14. **Interactables are not physics triggers.** `Area2D` with `monitoring=false`, `monitorable=false`, `layer=0`, `mask=0` (`interactable.gd:17-20`); pickup is by distance in `Player._update_nearby` (`player.gd:287-296`). Adding a scene-authored `body_entered` connection to an `Interactable` will never fire.
15. **Projectiles and `LootDrop` likewise ignore physics** (`arrow.gd:37-46`, `boss_projectile.gd:40-46`, `loot_drop.gd:19-20`).
16. **`PixelArt.CACHE` is a `static var` on a `RefCounted`** (`pixel_art.gd:12`) — it survives world reloads and is never cleared. Every new texture variant is permanent for the process; keys must be stable and unique (`:26-33`).
17. **All world art is generated at ~32 px per unit (`PixelArt.PX = 1/32`, `pixel_art.gd:10`)** and every sprite sets scale to that or a multiple. Hardcoding `0.03125` instead of `PixelArt.PX` appears in the demo scene (`main.tscn` everywhere) and will drift if `PX` changes.
18. **The demo scene and its scripts ship.** `export_presets.cfg:12-14` excludes only `tools/*` and `docs/*`; `scenes/main.tscn` pulls in `point_and_click_controller`, `player_visual`, `chest_interact`, `props_altar`, `stairs_layer_trigger`, `sprite_color_animation`, `welcome_popup`, `camera_follow`. Deleting them requires editing `main.tscn` (or deleting it and the three tool scripts that load it).
19. **Groups are the API.** Renaming `"enemies"`, `"player"`, `"interactable"`, `"camera"`, `"dungeon"`, `"game"`, `"settlement_target"`, `"forest_tree"` silently breaks combat/AI/UI with no compile error.
20. **Every user-facing message is silent.** `toast_requested` has 45 emit sites and zero listeners; `GameHUD.show_toast` is a deliberate no-op (`game_hud.gd:692-695`). Feedback such as "Purchased X", "EMERGENCY!", "Loot banked" and "Level 2 reached" is written into the void — do not add UI that waits for those toasts.
21. **Group arrays are rebuilt per frame** (`player.gd:287`, `pet.gd:132`, `arrow.gd:37`) — with 12+ monsters and many interactables this is the main per-frame allocation source, and `enemy.gd:170` forces a redraw every tick.
22. **`GameHUD` reads `player.get("nearby")`** and calls `world.get_guidance_targets()` if present (`game_hud.gd:548`, `:243-244`). Renaming the `nearby` property or the guidance method on `Lobby`/`Dungeon` breaks the prompt/mission arrows without a type error.
23. **Tab/`ui_cancel` is the only built-in action used** (`modal_base.gd:116`); `open_inventory` is bound to both `I` and `Tab` (`project.godot:75-80`), so Tab both opens the pack and (inside a modal) closes it — handled only because the HUD early-returns when a modal is open (`game_hud.gd:533-535`).
24. **Input map has keyboard only** — no gamepad or mouse bindings in `project.godot:41-95`; touch is synthesised via `Input.action_press` (`virtual_joystick.gd:88-91`, `touch_action_button.gd:60,68`). The demo scene's click-to-move is not part of the shipped input model.
25. **`GameState.time_string()` always returns `"DAYTIME"` and `_process` only accumulates `play_time`** (`game_state.gd:47-51,1132-1133`). Any code that assumes day/night is wrong.
26. **`NOTIFICATION_APPLICATION_FOCUS_OUT` triggers a save** (`game.gd:306`) — every alt-tab writes the file; if the save is mid-write on a slow disk this is the most likely corruption window (no atomic rename).
27. **`autosave_enabled` is dead configuration** — always true, never toggled (`game_state.gd:29,1161`). Turning it off disables *all* persistence except explicit `save_game()` calls (`game.gd:307`, `game_state.gd:745,761,769`).

---

## AGENTS.md candidate rules

1. Treat `GameState.data` as the only source of truth for player state; read via `GameState` accessors, never mutate `data` from UI/world code.
2. Never call `change_scene_to_file`; new worlds are created by `Game._load_lobby`/`_load_dungeon` and freed by `_clear_world` (`game.gd:109-160`).
3. When adding a state field, add it to `_make_default` (`game_state.gd:56`) and clamp it in `_sanitize` (`:1221`), or it will not survive a save/load.
4. Never branch on `data.version`; there is no version check — migrate by merging with defaults (`game_state.gd:1194-1216`).
5. Call `_save_if_needed()` only from transactional `GameState` methods, never from `_process` or `_physics_process`.
6. Emit `data_changed` after any mutation the HUD shows; UI panels only refresh from that signal (`game_hud.gd:83`).
7. Add lobby-only modals behind a `world is Dungeon` guard, as `open_shop`/`open_portal` do (`game.gd:231-267`).
8. Do not pause the tree; modal input blocking is `_input_locked` + `player.controls_locked` (`game.gd:222-225`).
9. Reset `_portal_elapsed`, `_emergency_triggered`, `_settlement_damage_accum` whenever the world changes (`game.gd:170-173,180-182`).
10. Make every damageable node join a group and expose `take_damage(amount: int, from_dir: Vector2, source: Node)` — combat is duck-typed (`player.gd:176-184`).
11. Guard every group lookup with `is_instance_valid()` and `is_queued_for_deletion()`; dead nodes linger for a tween duration (`enemy.gd:383-392`).
12. Extend `Interactable` (`interactable.gd`) for anything the player can use; it registers the group, the prompt and the distance-based interaction.
13. Keep collision layers as declared: 1 = World, 2 = Player, 3/bit 4 = Enemy (`project.godot:100-102`, `player.gd:36-37`, `enemy.gd:58-59`); pets and projectiles stay body-less.
14. Build UI/entity nodes in code with `GameUI` helpers; do not add exported `NodePath`s to gameplay scripts (`ui_theme.gd:55-129`).
15. Type public members and all function signatures; use `:=` for locals and `-> void` for actions.
16. Return `{"ok": bool, "message"/"reason": String}` from gameplay transactions instead of asserting (`game_state.gd:189-227`, `:840-854`).
17. Wrap every save-derived number in `int(...)`/`float(...)`; JSON parsing returns floats.
18. Route cross-world calls through the `"game"` group with `has_method` (`dungeon.gd:334-336`), never through a stored reference.
19. Generate textures through `PixelArt.cached_texture` with a stable key; the cache is process-global and never evicted (`pixel_art.gd:12-33`).
20. Use `PixelArt.PX` for world scale instead of literal `0.03125` (`pixel_art.gd:10`).
21. Delete a signal listener when you delete its emitter; `toast_requested`, `portal_completed`, `recovery_changed`, `nearby_changed`, `boss_started`, `game_over_triggered` are currently emitted with no consumers.
22. Give any new portal an entry in `PortalDB`; default save state is generated from `PortalDB.ordered_ids()` (`game_state.gd:62-67`).
23. Do not add autoloads that `GameState._ready` depends on — it resolves `CharacterDB`/`PetDB`/`PortalDB` as `class_name` statics at boot (`game_state.gd:38-44,57-60`).
24. Keep `scenes/main.tscn` and its root-level scripts out of gameplay changes; they are the Unity-port demo loaded only by `tools/*.gd`.
25. When touching `Game`/`Dungeon` defeat handling, preserve the `_defeat_pending` guard and the `expedition_active()` early-out or the double `player_defeated` emission will double-fire (`game.gd:189-203`, `dungeon.gd:347-355`).

---

## Open questions

1. **Size mismatch.** The brief says ~14,556 lines across ~80 scripts; I measure 61 `.gd` files / 11,139 lines under `scripts/` plus 8 tool scripts. Either the brief counted `tools/`, docs or assets, or files were removed. Settling it: `find . -name '*.gd' -not -path './.godot/*' | wc -l` in the repo root.
2. **Is the Unity-port demo (`scenes/main.tscn` + 9 loose scripts) meant to be deleted?** Nothing in the game loads it; it ships because the export filter is `all_resources`. Only the project owner can say whether it is a reference harness or leftover.
3. **Was `Player._sword` intended to exist?** It is declared, read and never assigned (`player.gd:29,164,302-312`). Was a sword sprite dropped in favour of drawing it into `PixelArt.character_texture`, or is the swing visual missing?
4. **Is lobby death supposed to respawn?** `player_defeated` has no lobby listener and `Player.die()` has no counterpart outside `Dungeon`/`Game`. Confirming requires a design answer, not code.
5. **Was pausing ever intended for modals?** There is no pause plumbing at all, yet the emergency timer runs in the background. Either the design accepts real-time menus or this is an unfinished feature.
6. **Are `gui_scale` / `control_layout` settings abandoned?** Five accessors and a save block exist (`game_state.gd:735-769,1244-1248`) with zero call sites; presumably an accessibility menu was planned.
7. **Is pet damage deliberately disabled?** `GameState.damage_pet` (`:795`) has no caller, so `pet.alive == false` is unreachable except by a hand-edited save. The `Pet` script still renders a "down" state and self-revives after 5 s (`pet.gd:69-79`).
8. **What is the intended emergency cadence?** `game.gd:19,43` fires one emergency 14 s into *any* expedition with a hardcoded 3 monsters; `lobby.gd:1116-1149` spawns `remaining` plus forest monsters. Whether the 14 s clock should reset per portal, per attempt, or per session is not expressed in code.
9. **`UNVERIFIED:` whether `NOTIFICATION_WM_CLOSE_REQUEST` reaches `Game._notification` before process exit** in this project (no `auto_accept_quit` override). If it does not, closing the window loses everything since the last transactional save.
10. **`UNVERIFIED:` whether the user-facing save dir name changes on export** — `user://` is derived from `config/name="Save The World"`, so renaming the project renames the save folder and orphans existing saves.
