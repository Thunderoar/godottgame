# PHASE 5+6 BRIEF — Return to title, Quit, and the title main menu

Project: `/home/roku/Documents/games/tournamentgame/GAME_COMP_RPG-Godot` (Godot 4.7.2, **no git**)
Spec: `.hermes/specs/menu-system-task.md` — read fully, then obey §2, §4.1, §4.5, §5, §6, §7 steps 5–6,
§9. `AGENTS.md` is binding.

## Scope — ONLY phases 5 and 6. Tests and docs are a later agent; do not write `_test_menus()` and do
not edit any doc.

Already landed (verify, do not redo): `GameSettings`; `Sfx` bus/ALWAYS; `GameUI` helpers + themed
controls; `ConfirmDialog`; `SettingsPanel`; guarded `Game._notification`; timer fixes; `GameState`
pause guard; `PauseMenu` + `can_pause`/`open_pause`/`close_pause`, `pause_requested`, HUD Menu button,
`pause_menu` input action, Android back, focus-loss auto-pause.

## Phase 5 — `Game.return_to_title()` and Quit
Implement the exact 7-step sequence in spec §4.5, including:
- unpause **before** any `await`;
- `GameState.save_game()`;
- release touch controls, hide modals, exit build mode, clear sleep state, hide the tutorial,
  `GameState.boss_health_changed.emit(false, "", 0, 0)`;
- reset `_defeat_pending`, `_portal_elapsed`, `_emergency_triggered`, `_settlement_damage_accum`,
  `_input_locked`;
- optional fade via `hud.fade_to_black`;
- `_clear_world()`, `hud.visible = false`, free the pause menu, `_show_title()`, fade back in,
  clear `_transitioning`;
- no `Game.player()` call on a dying world without a null check.
Quit = save then `get_tree().quit()`, hidden on web, never reachable from the Android back button.
Prove lobby → title → Continue → lobby and dungeon → title → Continue → dungeon three times without
leaks or stuck input (headless assertions are fine; say exactly what you observed).

## Phase 6 — Title main menu (`scripts/ui/title_screen.gd`, heavy rewrite — snapshot it first to
`~/.hermes/cache/scratch/backups/`, never `/tmp`)
Two states in one `TitleScreen`, per spec §4.1:
- **Main state**: Continue (disabled without a save; when enabled show a summary), New Game, Settings,
  Credits, Quit (hidden on web).
- **Hero-select state**: keep the existing `CHOOSE YOUR ROAD` header Label and the three hero cards,
  add a **Back** button. Both states are built up front and toggled with `visible` so the suite's
  `_has_label` checks (exact strings `SAVE THE WORLD`, `Created by Qayyim, Farhan and Ayiz`,
  `CHOOSE YOUR ROAD`) stay true.
- **Save summary**: add a read-only `GameState.save_summary() -> Dictionary` returning display-ready
  values (hero name, level, gold, `play_time` seconds → `1h 12m`), wrapping every number in
  `int()`/`float()` because JSON returns floats. No new `data` field.
- **Overwrite confirm**: if `GameState.has_existing_save`, a hero's Choose shows a `ConfirmDialog`
  ("Start a new journey? Your current save (Qayyim, Lv 7) will be replaced.") with Cancel as default
  focus and a red **Replace Save**; emit `character_selected(id)` only on confirm. No save → emit
  immediately. **The confirm must live in `TitleScreen`, never in `Game._on_character_selected`**
  (the suite calls that handler directly — spec trap 3).
- **Corrupt save**: `GameState.continue_game()` must surface a load failure. Show an inline message
  ("Save file could not be read") plus an Erase Save affordance. Keep `continue_game()`'s signature.
- **Settings**: instantiate `SettingsPanel` (title instance, `in_title`-style flag on) parented to the
  title layer. **Credits**: small modal keeping the exact credit Label in the tree.
- Keep the animated `_draw` background, `_layout()`/compact mode under 1100×650 (must still work at
  832×480), signal names/signatures, and `save_available`.
- Keyboard: menu buttons use `focus_mode = FOCUS_ALL` with a visible GOLD focus border set per button
  (do not change the global empty focus style the HUD uses). First button grabs focus; Up/Down/Enter/
  Esc work; focus returns to the invoking button when a sub-layer closes.

## Hard constraints
As in spec §1 / AGENTS.md: tabs, typed signatures, code-built nodes, no `.tscn`, no `$Path`, no
renaming suite-touched privates, no `toast_requested`, no `/tmp`, headless only, every Godot run
prefixed with `XDG_DATA_HOME=$HOME/.hermes/cache/scratch/godotuser`. Re-import after adding any
`class_name`.

## Gate
Suite command as in spec §8: exit 1, exactly the one known `[FAIL]`, tally unchanged, no
`SCRIPT ERROR`/`ERROR:`. Plus: the three required title labels still exist; Continue disabled with no
save and enabled after one; save → return to title → Continue restores the right world.

## Report
Write `.hermes/research/menu-system/phase-5-6-report.md` (skeleton first): files, the return-to-title
sequence as implemented, title-state matrix (no save / save / corrupt save), what you proved and how,
suite output, deviations, unverified. Then reply ≤15 lines.
