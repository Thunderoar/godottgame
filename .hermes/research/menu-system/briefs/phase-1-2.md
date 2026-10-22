# PHASE 1+2 BRIEF — Foundations + bug fixes

Project: `/home/roku/Documents/games/tournamentgame/GAME_COMP_RPG-Godot` (Godot 4.7.2, **no git**)
Spec: `.hermes/specs/menu-system-task.md` — read it fully, then obey §1, §2, §3 (D1/D2), §4.3, §6, §7 steps 1–2, §9.
Also read `AGENTS.md` (project root).

## Scope — ONLY phases 1 and 2. Nothing else.
Later phases (SettingsPanel, PauseMenu, title menu, return-to-title, tests/docs) are other agents'
work. Do not start them, do not stub them, do not "prepare" them.

### Phase 1 — foundation
1. **`scripts/core/game_settings.gd`** → autoload `GameSettings`, per spec D2:
   `ConfigFile` at `user://settings.cfg`, a **test-overridable `config_path` var**, load/validate/clamp/
   apply/persist, `changed(key: String)` signal, `reset_to_defaults()`.
   Keys (choose sane defaults and document them in the file header):
   `master_volume` (0–100), `effects_volume` (0–100), `mute_all` (bool), `fullscreen` (bool),
   `ui_scale` (75–130 int, default 100), `touch_controls` (`"auto"|"always"|"hidden"`, default `"always"`),
   `screen_shake` (bool), `auto_pause_on_focus_loss` (bool, default true).
   Register it in `project.godot [autoload]` **between** `GameState` and `Sfx` (spec D2).
2. **`scripts/autoload/sfx.gd`**: create an `"SFX"` bus at runtime in `_ready` (`AudioServer.add_bus`,
   send → Master, no `.tres`), point the player pool at it, apply `GameSettings` volumes with
   `linear_to_db` (0 → muted, never `-inf`), set `process_mode = PROCESS_MODE_ALWAYS`, and re-apply on
   `GameSettings.changed`.
3. **`scripts/core/ui_theme.gd`**: add `slider_row(...)` and `toggle_row(...)` helpers plus theme
   entries for `HSlider` (track/grabber/grabber_highlight), `CheckButton`, `CheckBox`,
   `OptionButton`, `PopupMenu`, `HScrollBar` — all in the existing palette. Extend `GameUI`, no
   one-off styles.
4. **`scripts/ui/confirm_dialog.gd`** → `class_name ConfirmDialog`, per spec §4.6:
   `ask(title, body, confirm_text, danger := false)`, signals `confirmed` / `cancelled`, Esc and Cancel
   cancel, **Cancel has default focus**, `PROCESS_MODE_ALWAYS`, stacks above its opener, themed like the
   existing panels. Follow `modal_base.gd`'s look, but it must work on the title and under pause.

### Phase 2 — bug fixes
5. **`scripts/game/game.gd`**: `_notification` must save **only when a run is active**
   (`world != null` and not on the title). No saving `GameState` call may run from a title-screen path.
   Also `create_timer(0.7, false)` for the defeat panel (spec D1).
6. **`scripts/player/player.gd`** `create_timer(0.12, false)`; **`scripts/combat/enemy.gd`**
   `create_timer(0.55, false)` — the three timers listed in spec D1.
7. **`scripts/autoload/game_state.gd`**: `_process` early-returns while `get_tree().paused` so
   `play_time` stops. **Nothing else in this file in this phase.** No new `data` fields.
8. Verify the phantom-save bug is actually gone (spec §2): with no save file, a
   `NOTIFICATION_APPLICATION_FOCUS_OUT` while on the title must create no save.

## Hard constraints
- Tabs, `snake_case`, typed signatures, `:=` locals, `_build_*`/`_on_*`/`_add_*`, `# ---- section ----`
  banners, tuning numbers as file-level `const`.
- Build nodes in code. No new `.tscn`. No `$Path`, no `get_node()`.
- Do not rename anything the suite touches by name (list in spec §1).
- Never `change_scene_to_file`; never run `tools/convert.gd`, `tools/setup_input.gd`,
  `tools/tide_capture.tscn`; never hand-edit `scenes/main.tscn`.
- Do not use `/tmp`. Scratch goes to `~/.hermes/cache/scratch/`.
- After adding a `class_name`, run `--import` so the class cache knows it.
- Leave the tree parseable at all times: never leave a half-written script on disk.

## Environment facts you must respect
- **The owner's Godot editor and a running game instance are open on this project.** Do not run GUI
  Godot. Headless only.
- **The real save must never be touched.** Every Godot run must be prefixed with
  `XDG_DATA_HOME=$HOME/.hermes/cache/scratch/godotuser` — that isolates `user://` completely
  (verified: `OS.get_user_data_dir()` then points inside the scratch dir).

## Gate (must pass before you report)
```sh
cd /home/roku/Documents/games/tournamentgame/GAME_COMP_RPG-Godot
XDG_DATA_HOME=$HOME/.hermes/cache/scratch/godotuser timeout 240 godot --headless --path . --import; echo "import=$?"
XDG_DATA_HOME=$HOME/.hermes/cache/scratch/godotuser timeout 480 godot --headless --path . res://tools/tide_test.tscn > ~/.hermes/cache/scratch/p12_suite.log 2>&1; echo "suite=$?"
grep -nE "\[FAIL\]|SCRIPT ERROR|ERROR:" ~/.hermes/cache/scratch/p12_suite.log
grep -n "tide test:" ~/.hermes/cache/scratch/p12_suite.log
```
Expected: exit 1, **exactly one** `[FAIL] forest trees are invulnerable to structural damage`, tally
`250 checks, 1 FAILURE(S)`, 249 `[OK]`. Nothing else may match the grep.

## Report
Write `.hermes/research/menu-system/phase-1-2-report.md` **skeleton first, then fill** — files
added/edited (one line each), the exact commands + their real output, deviations from the spec, and
anything you could not verify. Then reply with a short summary (≤15 lines).
