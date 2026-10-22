# PHASE 4 BRIEF — Pause menu + Game plumbing

Project: `/home/roku/Documents/games/tournamentgame/GAME_COMP_RPG-Godot` (Godot 4.7.2, **no git**)
Spec: `.hermes/specs/menu-system-task.md` — read fully, then obey §3 (D1, D3, D4), §4.2, §4.3, §5,
§6, §7 step 4, §9. `AGENTS.md` is binding except where D1 is an owner-approved override.

## Scope — ONLY phase 4. Not the title menu, not return-to-title (phases 5–6 are a later agent).

Already landed (verify, do not redo): `GameSettings` autoload + `settings.cfg`; `Sfx` `"SFX"` bus,
`PROCESS_MODE_ALWAYS`, volume application; `GameUI` slider/toggle helpers + themed controls;
`ConfirmDialog`; `SettingsPanel` (a `ModalBase`) with every row working; guarded `Game._notification`;
`create_timer(t, false)` in `game.gd`/`player.gd`/`enemy.gd`; `GameState._process` pause guard;
`GameHUD.release_touch_controls()` and `virtual_joystick.cancel()`.

## Deliverable
1. **`scripts/ui/pause_menu.gd`** → `class_name PauseMenu`, a **`CanvasLayer` at layer 100**
   (`process_mode = ALWAYS`), built in code, dim ≈0.62, title **PAUSED**, context line (zone via
   `world.zone_name`, hero name/level), and buttons exactly per spec §4.2 table: Resume (default
   focus), Settings, Controls, Save Game, Main Menu, Quit Game (hidden on web).
   - Save Game writes `GameState.save_game()` then an **inline** "Saved hh:mm:ss" line — never a toast.
   - Main Menu / Quit go through `ConfirmDialog`.
   - Controls is a read-only list from `InputMap` + touch hints, with "Replay tutorial".
   - If `GameState.expedition_active()`, show a warning line whose text you derive from the **actual**
     code in `game_state.gd` (`expedition_*`, `defeat_in_portal`, `complete_portal`): say plainly
     whether loot is banked or lost and what Continue does. Do not guess.
2. **`scripts/game/game.gd`**: `can_pause()`, `open_pause()`, `close_pause()` and all five entry points
   (spec §4.2): Esc through `_unhandled_input` (`ui_cancel`, `not is_echo()`, and it must not double-fire
   with `ModalBase`'s own Esc handling), `P` via the new `pause_menu` action polled in `GameHUD._process`
   → new `pause_requested` signal connected in `_connect_hud`, the HUD Menu button, Android
   `NOTIFICATION_WM_GO_BACK_REQUEST`, and focus-loss auto-pause when
   `GameSettings.auto_pause_on_focus_loss`.
   Esc inside the pause stack closes only the topmost layer (confirm → settings → resume).
   **Never map Esc to the `pause_menu` action** (spec D4, trap 1).
3. **`scripts/ui/game_hud.gd`**: `_menu_button` (`TouchActionButton`, caption "Menu",
   `action = "pause_menu"`, diameter 64, at about `Vector2(168, 160)` — keep Pack's position under 200
   for the suite), the `pause_requested` signal, poll `pause_menu` in `_process` next to the other
   actions, and wire touch-controls visibility / UI-scale hooks if phase 3 left any TODO.
4. **`project.godot`**: add `[input] pause_menu` = **P only**, hand-copying the exact serialisation of
   an existing block (never run `tools/setup_input.gd`); add `config/quit_on_go_back=false` under
   `[application]`.
5. **`scripts/core/pixel_art.gd`**: a procedural `"gear"` (or `"menu"`) icon under a stable cache key,
   or reuse an existing kind if drawing one is disproportionate — say which in your report.

## Mechanics checklist — every line must hold and be stated in your report
- On pause: release synthetic touch input, then `get_tree().paused = true`, then show the menu and give
  Resume focus. On resume: hide, then unpause. No stuck movement, **no phantom attack if F was held**
  when pausing.
- The pause layer, its children and the in-pause SettingsPanel run `PROCESS_MODE_ALWAYS`; `Game`, HUD and
  worlds stay `PAUSABLE`.
- Pausing is blocked while `_transitioning` (a paused fade tween deadlocks the `await`),
  `_defeat_pending`, dead player, `hud.any_modal_open()`, no world, title up, or already paused.
- Ordinary modals (shop/inventory/portal...) still **do not** pause. Do not change that.
- Verify by reasoning + headless assertions where possible that enemies, projectiles, pets, residents,
  the 14 s emergency clock, `_settlement_damage_accum`, recovery-ward healing and sleep progress all
  freeze and resume. State which of these you could actually observe.
- Pause is never persisted.

## Gate
Suite command as in spec §8 (with `XDG_DATA_HOME=$HOME/.hermes/cache/scratch/godotuser`): exit 1,
exactly one `[FAIL]`, tally unchanged, no `SCRIPT ERROR`/`ERROR:`. If you add throwaway verification
code, remove it before reporting.

## Report
Write `.hermes/research/menu-system/phase-4-report.md` (skeleton first): files, entry points proven,
mechanics checklist result line by line, suite output, deviations, unverified. Then reply ≤15 lines.
