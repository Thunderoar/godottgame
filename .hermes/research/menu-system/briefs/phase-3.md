# PHASE 3 BRIEF — SettingsPanel

Project: `/home/roku/Documents/games/tournamentgame/GAME_COMP_RPG-Godot` (Godot 4.7.2, **no git**)
Spec: `.hermes/specs/menu-system-task.md` — read fully, then obey §4.4, §5, §6, §7 step 3, §9.
`AGENTS.md` at the project root is binding.

## Scope — ONLY phase 3 (the SettingsPanel and the live application of every setting it exposes).
Phase 1+2 already landed: `GameSettings` autoload, `Sfx` SFX bus + `PROCESS_MODE_ALWAYS`, `GameUI`
`slider_row`/`toggle_row` + themed slider/toggle/option controls, `ConfirmDialog`, guarded
`Game._notification`, the three `create_timer(t, false)` fixes, `GameState._process` pause guard.
Verify they exist before you build on them; do not redo them.

## Deliverable
**`scripts/ui/settings_panel.gd`** → `class_name SettingsPanel extends ModalBase`.
- Set `_panel_size` **before** `super._ready()`.
- Build the rows **once** in `_rebuild()`; update widget values in place. **Never** rebuild on a
  slider tick and **never** subscribe to `GameState.data_changed` (spec §4.4, gotcha 10).
- Sections/rows exactly per spec §4.4:
  - **Audio**: master volume, effects volume, mute all. No music slider. Play `Sfx.play("select")`
    on slider release.
  - **Display** (hidden on web and Android): fullscreen toggle via `DisplayServer`. Do not touch the
    project's `canvas_items` + `expand` stretch.
  - **Interface**: UI scale 75–130 %, touch controls `Auto/Always/Hidden`, screen shake on/off,
    "pause when window loses focus" on/off.
  - **Help**: read-only controls list built **from `InputMap` at open time**
    (`InputMap.action_get_events`), grouped Move/Strike/Use/Backpack/Build/Health potion/Mana potion/
    Pause, with human-readable key names plus the touch equivalents as text. "Replay tutorial"
    (only when a run is active) closes menus, unpauses and calls `hud.start_tutorial()`; it must not
    write `data.tutorial_seen`.
  - **Data** (title instance only — expose an `in_title := false`-style flag or equivalent so the
    pause instance hides it): Erase save with a `ConfirmDialog`, then `GameState.delete_save()`,
    update `has_existing_save`, refresh the title's Continue state.
  - **Footer**: Reset to defaults (settings only, with confirm). Must not touch the save.

## Live application (this is the part that must actually work)
- `ui_scale`: scale the HUD root **and resize it to `viewport_size / scale`** — anchors resolve
  against the parent, so naively scaling an anchored root pushes right/bottom panels off screen.
  `ModalBase` fits to `get_viewport_rect().size`; make it use the scaled root size so big panels still
  fit (spec §4.4 + §6 `modal_base.gd` edit). Apply live; verify numerically at 1280×720 and 832×480
  (assert every HUD panel's rect stays inside the scaled root — you cannot see the screen).
- `touch_controls`: `Auto` = `DisplayServer.is_touchscreen_available()`, `Always` = today's
  behaviour (default), `Hidden` hides the joystick + touch buttons. **Call
  `hud.release_touch_controls()` first** if it exists; if phase 4 has not added it yet, add the
  `GameHUD.release_touch_controls()` method now (it calls `cancel()` on every `TouchActionButton`
  and on the joystick — add a public `cancel()` wrapper to `virtual_joystick.gd`).
- `screen_shake`: guard `FollowCamera.shake()` (`scripts/core/follow_camera.gd`, called through the
  `"camera"` group) — off = no-op.
- `auto_pause_on_focus_loss` is consumed later by phase 4; just persist it.
- `fullscreen`: `DisplayServer.window_set_mode`, guarded to desktop.

## Hard constraints
As in the spec §1 and AGENTS.md: tabs, typed signatures, code-built nodes, no `.tscn`, no `$Path`,
no renaming of suite-touched privates, no `toast_requested`, no `/tmp`, headless only, every Godot run
prefixed with `XDG_DATA_HOME=$HOME/.hermes/cache/scratch/godotuser`.

## Gate
Same suite command as phase 1+2 (spec §8): exit 1, exactly the one known `[FAIL]`, tally unchanged,
no `SCRIPT ERROR`/`ERROR:`. Additionally prove each setting applies live and persists: change it,
read it back through `GameSettings`, reload the config, and confirm the applied effect (bus volume,
camera shake no-op, HUD scale numbers, touch visibility). Restore defaults afterwards.

## Report
Write `.hermes/research/menu-system/phase-3-report.md` (skeleton first): files added/edited, the live
application proof for each setting, suite output, deviations, unverified items. Then reply ≤15 lines.
