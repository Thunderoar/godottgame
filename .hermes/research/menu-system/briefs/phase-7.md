# PHASE 7 BRIEF — Tests, docs, final verification

Project: `/home/roku/Documents/games/tournamentgame/GAME_COMP_RPG-Godot` (Godot 4.7.2, **no git**)
Spec: `.hermes/specs/menu-system-task.md` — read fully, then obey §8 and §11. `AGENTS.md` is binding.

## Scope — ONLY phase 7. Phases 1–6 have landed; if you find a defect, fix it minimally and record it,
but do not refactor working code.

## 1. Tests — `tools/tide_test.gd`
Add `_test_menus()` and call it from `_ready()` **before** the final tally. Never hardcode `250`.
Cover at least the list in spec §8:
- Title: Continue disabled with no save / enabled with one; Settings, Credits and (non-web) Quit exist;
  the three required labels still exist; choosing a hero with an existing save requires confirmation
  and without a save does not.
- Pause: `Game.can_pause()` true in the lobby, false while a modal is open, during a transition and when
  dead; opening sets `get_tree().paused`; the pause root is `PROCESS_MODE_ALWAYS`;
  `Game._portal_elapsed` does not advance over N frames while paused (set up a dungeon expedition) and
  does advance after resume; `GameState.data.play_time` does not advance while paused; Esc while a shop
  is open closes the shop **and does not** open pause; resume clears pause.
  **The test must always leave `get_tree().paused = false`, including on failure paths**, or the rest of
  the suite stalls.
- Settings: setters clamp and persist; reset-to-defaults works; Master/SFX buses exist; mute works;
  screen-shake off makes `FollowCamera.shake()` a no-op; touch-controls `Hidden` hides
  `_joystick`/`_attack_button` and releases their actions.
- Phantom save: with no save, `Game._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)` on the title
  creates no save file.
- Return to title: ends with `title_screen != null`, `world == null`, `hud.visible == false`, the four
  reset variables zeroed/false, tree unpaused; Continue then restores the lobby (and the dungeon when an
  expedition was active).
- `GameSettings` must be pointed at a **temporary config path** for the whole suite so the real
  `settings.cfg` is never read or written. Restore it at the end.

## 2. Docs — same change, or they become false
- `AGENTS.md`: rewrite rule 15 and §3 runtime-rule 3 (a pause menu now exists; ordinary modals still do
  not pause), update §8 gotcha 2, change "Two autoloads only" → three (`GameState`, `GameSettings`,
  `Sfx`, in that order), add the new files to the §4 table, add a short **Menus** paragraph (Esc routing
  via `_unhandled_input`, never map Esc to a polled action, never save from a title-screen path,
  `return_to_title` sequence), and add the menu test group to the definition-of-done/test section.
  Keep the forest-tree baseline warning intact.
- `docs/ACCEPTANCE_TESTS.md`: a "Menus and pause" section matching the new checks.
- `docs/ARCHITECTURE.md`: pause model, `GameSettings`, `PauseMenu`/`SettingsPanel`/`ConfirmDialog`,
  layer numbers (HUD 10, pause 100, title 200).
- `README.md`: controls table (Esc = pause/close, P = pause, Menu button) and a settings summary.
Do not "fix" the forest-tree docs — that decision is still open.

## 3. Final verification (with `XDG_DATA_HOME` isolation, never `/tmp`)
```sh
cd /home/roku/Documents/games/tournamentgame/GAME_COMP_RPG-Godot
XDG_DATA_HOME=$HOME/.hermes/cache/scratch/godotuser timeout 240 godot --headless --path . --import; echo "import=$?"
XDG_DATA_HOME=$HOME/.hermes/cache/scratch/godotuser timeout 600 godot --headless --path . res://tools/tide_test.tscn > $HOME/.hermes/cache/scratch/final_suite.log 2>&1; echo "suite=$?"
grep -nE "\[FAIL\]|SCRIPT ERROR|ERROR:|WARNING:|tide test:" $HOME/.hermes/cache/scratch/final_suite.log
grep -c "^\[OK\]" $HOME/.hermes/cache/scratch/final_suite.log
```
Then confirm the owner's real save and `settings.cfg` are untouched (`sha256sum` the path under
`~/.local/share/godot/app_userdata/Save The World/`), and that the tree has no stray output files
(`shots/`, temp scripts, backups) before you finish.

## Report
Write `.hermes/research/menu-system/phase-7-report.md` (skeleton first) with: the exact commands,
the exact `[FAIL]` lines remaining, the `grep` output, the number of new `[OK]` checks, every doc line
you changed, and anything you could not verify. Then reply ≤20 lines. This report feeds the owner's
required final report format (spec §11), so be literal and honest.
