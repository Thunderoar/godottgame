# TASK: Build the full menu system for "Save The World — Tidesworn" (Godot 4.7.2)

You are working in the repo `Thunderoar/godottgame` (commit `d24e326` when this prompt was
written; line numbers below may drift by a few lines, so grep before you edit). Read
`AGENTS.md` first and obey it. This prompt extends it, and where this prompt says
"owner-approved override" it deliberately overrides the named AGENTS.md rule.

## 0. Mission

The game today has **no menu layer at all**: a title screen with one Continue button and three
hero cards, an Esc key that only closes shop panels, no pause, no settings, no quit, no way back
to the title. Deliver all of this, in the game's existing style and architecture:

1. **Title main menu**: Continue (with save summary), New Game (hero select, overwrite
   warning), Settings, Credits, Quit.
2. **Pause menu**: Resume, Settings, Controls/Help, Save Game, Main Menu, Quit. A real pause
   (`get_tree().paused`), opened by Esc, P, a HUD button, the Android back button and
   (optionally) window focus loss.
3. **Settings panel** reachable from both title and pause: audio, display, interface scale,
   touch controls, screen shake, tutorial replay, read-only controls list, erase save.
4. **Confirm dialog** for every destructive action.
5. **Return-to-title flow** that tears down the running world cleanly, and a **Quit** flow.
6. Tests in `tools/tide_test.gd`, doc updates, and an honest final report.

"Change hero" means **New Game -> hero select**. Do **not** implement swapping the hero inside an
existing save (see Non-goals).

---

## 1. Ground rules (binding)

- Tabs, `snake_case`, typed signatures (`-> T`), locals with `:=`, `_build_*` / `_on_*` / `_add_*`
  naming, `# ---- section ----` banners in big files, tuning numbers as file-level `const`.
- Build every node in code. No new `.tscn`, no `$Path`, no `get_node()`. Find things by group
  or by the references the owner object already holds.
- `GameState` is the only writer of `GameState.data`. UI calls its methods.
- **Player-facing feedback must NOT use `toast_requested` / `show_toast()`** (45 emitters, zero
  listeners, deliberately empty). Use inline labels inside the panel (e.g. a "Saved" line).
- Never `change_scene_to_file` / `reload_current_scene`. Worlds are built by
  `Game._load_lobby` / `_load_dungeon`.
- Use `Game.player()`, never `get_first_node_in_group("player")`, across transitions.
- Textures only via `PixelArt.cached_texture` with a stable unique key. World scale via
  `PixelArt.PX`.
- Do not rename any private member the test suite touches by name (`hud._toast_box`,
  `_health_bar`, `_attack_button`, `_inventory_button`, `_build_button`, `_joystick`,
  `_interact_button`, `_emergency_panel`, `_recovery_panel`, `_boss_panel`, `_boss_label`,
  `_build_mode_panel`, `_xp_bar`, `_pet_bar`, `_pet_xp_bar`, `tutorial_guide._skip`,
  `game._load_lobby`, `game._on_character_selected`, `game.player`, `panel._turn_timer`,
  `forest_monster._can_see_player`). Adding is fine; renaming is a breaking change.
- Never run `tools/convert.gd`, `tools/setup_input.gd`, `tools/tide_capture.tscn`.
  Never hand-edit `scenes/main.tscn`.
- No git history exists locally in the owner's tree. Copy a file to `/tmp` before any large
  rewrite (`title_screen.gd` will be heavily rewritten).

### Baseline is red (do not "fix" it, do not make it worse)

`tools/tide_test.tscn` currently ends `250 checks, 1 FAILURE(S)`, exit 1. The single failure is
`forest trees are invulnerable to structural damage`. That is an **unresolved product decision**
(AGENTS.md §2), not part of this task. Your gate is therefore:

> The suite shows **exactly that one `[FAIL]` line and no other**, no `SCRIPT ERROR`, no
> `ERROR:` in stdout, and all of your new checks print `[OK]`.

Tell the owner in your report that a literal `0 FAILURE(S)` is impossible until that decision is
made.

### Back up user data before every suite run

The suite calls `GameState.delete_save()`. Before running it, copy the whole
`~/.local/share/godot/app_userdata/Save The World/` directory (save **and** the new
`settings.cfg`) somewhere safe, and restore it afterwards. Make your new tests unable to clobber
the real `settings.cfg` (see §8).

---

## 2. Verified facts about the current code (do not rediscover wrongly)

These come from reading the code. Re-verify the ones you depend on.

**Title / flow (`scripts/game/game.gd`, `scripts/ui/title_screen.gd`)**
- `Game._show_title()` builds `TitleLayer` (CanvasLayer, layer 200) + `TitleScreen`, called only
  from `Game._ready()`. **No function returns to the title.** `_remove_title()` frees both.
- `TitleScreen` emits only `character_selected(id)` and `continue_requested`. The Continue
  button is `_continue_button`, disabled when `save_available` is false. The hero cards are
  always visible together under the label "CHOOSE YOUR ROAD". There is no Settings, Quit,
  Credits or Back.
- `TitleScreen._layout()` switches to a compact layout under 1100x650 (hides blurb, hint, footer,
  card descriptions). Keep that behaviour; the menu must also work at 832x480.
- `Game._on_character_selected` calls `GameState.new_game(id)` **immediately**, which calls
  `_make_default` and `_save_now()`: **picking a hero silently overwrites an existing save.**
- `Game._on_continue_requested` -> `GameState.continue_game()`; if an expedition is active it
  loads the dungeon directly, else the lobby.
- `Game._notification` (bottom of `game.gd`) calls `GameState.save_game()` on
  `NOTIFICATION_WM_CLOSE_REQUEST`, `NOTIFICATION_APPLICATION_PAUSED` and
  `NOTIFICATION_APPLICATION_FOCUS_OUT`. **There is no "a run is active" guard.**
- Test dependencies: `tide_test.gd:18-22` requires a Label with exact text `SAVE THE WORLD`,
  `Created by Qayyim, Farhan and Ayiz` and `CHOOSE YOUR ROAD` somewhere in the
  `game.title_screen` subtree (`_has_label` checks existence, not visibility). Line 29 calls
  `game.call("_on_character_selected", "qayyim")` directly (bypassing the title UI entirely), and
  the later hero tests call `GameState.new_game(...)` directly. So **the overwrite confirmation
  must live in `TitleScreen`, never in `Game._on_character_selected`**: that handler stays
  unconditional and the tests keep working.

**Existing bugs that touch this feature (fix them as part of this task)**
- **Phantom save.** `GameState._ready()` creates a default Qayyim `data` when no save exists, and
  `_save_now()` only refuses when `data.is_empty()`. So the `FOCUS_OUT`/`CLOSE_REQUEST` handler
  above can write a save file for a game nobody started, which makes Continue appear on next
  launch. The same applies to the existing `set_gui_scale` / `set_control_layout` /
  `reset_control_layout`, which call `save_game()`. Fix: `Game._notification` saves only when a
  run is active (e.g. `world != null`, i.e. after hero select/continue and not while on the
  title). Never call a saving `GameState` method from a title-screen code path.
- **Silent Continue failure.** `continue_game()` ignores the result of `load_game()`. If the file
  exists but fails to parse and `data` is still empty, the Continue button simply does nothing.
  Surface this: show an inline message on the title ("Save file could not be read") and offer
  Erase Save.

**Settings backend that already exists but is unused**
- `GameState.data.settings = {gui_scale, control_layout}` exists in `_make_default`, is clamped in
  `_sanitize`, and has accessors `gui_scale()`, `set_gui_scale()`, `control_layout()`,
  `set_control_layout()`, `reset_control_layout()`. **Zero call sites.** They are per-save,
  `new_game()` replaces `data` wholesale (so these reset on a new game), and the setters call
  `save_game()` (phantom-save risk on the title). See decision D2.

**Modals (`scripts/ui/modal_base.gd`, `scripts/ui/game_hud.gd`)**
- `ModalBase`: full-screen dim + centered framed panel + header + `Close` + `ScrollContainer`
  body; subclasses override `_rebuild()`; set `_panel_size` **before** `super._ready()`; it closes
  itself on `ui_cancel` in `_unhandled_input` and calls `set_input_as_handled()`. It is the only
  thing in the game that reads Esc.
- `GameHUD.any_modal_open()` and `hide_modals()` each hard-code the same list of 8 panels, and
  `_build_modals()` builds them. `Game._connect_hud()` wires each panel's `closed` signal to
  `_on_modal_closed`. A new `ModalBase` that is not added to **all** of those places is ignored by
  input-locking.
- `GameHUD._process` polls `Input.is_action_just_pressed(...)` for `open_inventory`,
  `toggle_build`, `use_health_potion`, `use_mana_potion`, and returns early while a modal is open.
- Touch controls are `TouchActionButton`s bound to InputMap actions; they have a `cancel()`.
  The top-left row currently holds Pack at (24,160) and Build at (96,160), both 64 px.
  `tide_test.gd:49` requires Pack's `position.x < 200 and position.y < 200`.

**Theme (`scripts/core/ui_theme.gd`)**
- `GameUI.theme()` styles Label, Panel, PanelContainer, Button, RichTextLabel, LineEdit,
  VScrollBar only. **No HSlider, CheckButton, CheckBox, OptionButton or HScrollBar styling**, so
  any such control will render in default Godot grey and clash.
- `GameUI.button()` sets `focus_mode = FOCUS_NONE` and the theme's `focus` stylebox is
  `StyleBoxEmpty`. Keyboard menu navigation therefore does not work and would be invisible even if
  enabled.

**Audio (`scripts/autoload/sfx.gd`)**
- Eight `AudioStreamPlayer`s on the `"Master"` bus, procedural WAV streams, no music, no bus
  layout resource. A `"select"` blip exists. `Sfx` has default process mode (pauses with the tree).

**Pause**
- Nothing in the game uses `get_tree().paused`. `GameState` is `PROCESS_MODE_ALWAYS` and its
  `_process` adds `delta` to `play_time` every frame, so it would keep counting during a pause.
- `get_tree().create_timer(t)` defaults to `process_always = true`, so these keep running through a
  pause unless you pass `false`: `game.gd` (0.7 s defeat delay), `player.gd` (0.12 s),
  `enemy.gd` (0.55 s). Node-bound tweens (`create_tween()` on a node) pause with the node.
- `Game._process` runs the 14 s emergency clock and settlement damage from `delta`, so it freezes
  correctly under a real pause.
- `settlement_editor.gd` sets `player.controls_locked` directly (not through `Game._input_locked`).
- No wall-clock timers matter (only a purchase debounce and a cosmetic flicker).

**Input map (`project.godot`)**
`move_*` (WASD + arrows), `interact` E, `attack` F, `open_inventory` I + Tab, `use_health_potion` Q,
`use_mana_potion` R, `toggle_build` B. No pause action. Esc is only the built-in `ui_cancel`.
No joypad events are mapped.

---

## 3. Decisions (treat as approved unless you find a hard blocker)

**D1: Real pause. Owner-approved override of AGENTS.md Hard Rule 15 and §3 runtime-rule 3.**
The owner explicitly asked for a pause menu. Implement with `get_tree().paused = true`. The
alternative (a soft freeze through `_input_locked` plus a flag every enemy/timer must check) is far
more invasive and error-prone. You must therefore:
- Set `process_mode = PROCESS_MODE_ALWAYS` on the pause UI root, on `Sfx`, and guard
  `GameState._process` (`if get_tree().paused: return`) so play time does not accumulate.
- Change the three `create_timer` calls listed above to `create_timer(t, false)`.
- **Do not** pause when ordinary modals (shops, inventory...) open. That would change raid balance
  and tests; it is explicitly out of scope. Only the pause menu pauses.
- Rewrite AGENTS.md rule 15, §3 runtime-rule 3 and §8 gotcha 2 to describe the new behaviour
  (pause menu pauses; shop/inventory modals still do not).

**D2: Where settings live.**
Create a **third autoload `GameSettings`** (register in `project.godot` `[autoload]` **after**
`GameState` and **before** `Sfx`), backed by `ConfigFile` at `user://settings.cfg`. It is
**device-level, independent of any save**, so it works on the title before any save exists, and
survives New Game and `GameState.delete_save()`. It exposes getters, setters (which validate, clamp,
apply and persist) and a `changed(key: String)` signal. Do **not** call
`GameState.set_gui_scale` / `set_control_layout`; leave them alone (dead code, may be removed in a
separate change). Update AGENTS.md "Two autoloads only". If you have a strong technical reason to
use a static class instead, say so in the report, but keep the same behaviour and file location.

**D3: Pause is a separate CanvasLayer, not a `ModalBase`.**
`PauseMenu` is a `CanvasLayer` (layer 100: above the HUD at 10, below the title at 200) created by
`Game` in code, `process_mode = ALWAYS`. It is **not** in `GameHUD.any_modal_open()`'s list, because
the real pause makes input-locking unnecessary. `SettingsPanel` **is** a `ModalBase` subclass and is
instantiated separately in the title layer and inside the pause layer (two instances of one class).
Neither instance is connected to `Game._on_modal_closed`.

**D4: Esc routing (this prevents a double-fire bug).**
- Esc opens/closes pause **only through `_unhandled_input`** on the pause controller (`Game`),
  checking `event.is_action_pressed("ui_cancel")` and `not event.is_echo()`. Because `ModalBase`
  consumes Esc with `set_input_as_handled()` when a modal is open, the same keypress cannot both
  close a shop and open pause.
- The new `pause_menu` InputMap action is mapped to **P only** (and is what the touch button
  presses). **Do not map Esc to it**: `GameHUD._process` polls actions after events are handled, so
  an Esc-mapped polled action would fire in the same frame a modal just closed.
- Inside the pause menu: Esc closes the topmost layer only (confirm dialog -> settings -> resume).

**D5: "Change hero" = New Game.** Hero select remains the existing three cards, shown as a second
state of the title screen with a Back button. Overwrite warning if a save exists.

---

## 4. Feature specification

### 4.1 Title screen main menu (`scripts/ui/title_screen.gd`)

Two states in one `TitleScreen`:

**Main state** (default): vertical button stack under the credit line:
- **Continue**: disabled if no save. When enabled the button (or a label under it) shows a save
  summary from `GameState.data`: hero name, level, gold, play time (`play_time` seconds ->
  `1h 12m`). Add a read-only helper in `GameState` (e.g. `save_summary() -> Dictionary`) that
  returns display-ready values, using `int()` / `float()` on every number (JSON returns floats).
  If a save exists but could not be loaded, show the inline error from §2 instead.
- **New Game**: switches to the hero-select state.
- **Settings**: opens a `SettingsPanel` instance parented to `TitleScreen`.
- **Credits**: small modal: the existing credit line plus the three names. Keep the exact
  string `Created by Qayyim, Farhan and Ayiz` as a Label that always exists in the tree.
- **Quit**: `get_tree().quit()`. **Hide on web** (`OS.has_feature("web")`). Do not save here.

**Hero-select state**: the existing `CHOOSE YOUR ROAD` header and three cards (keep the header
Label and the card construction code), plus a **Back** button. The main-state widgets and the
hero-select widgets are both built up front; toggle `visible`. This keeps the `_has_label` test
checks true.

**Overwrite confirm**: if `GameState.has_existing_save` when a hero card's Choose button is pressed,
show a `ConfirmDialog` ("Start a new journey? Your current save (Qayyim, Lv 7) will be replaced.")
with Cancel (default focus) and a red **Replace Save** button; emit `character_selected(id)` only on
confirm. No save -> emit immediately (this keeps the headless test path intact).

Keep: signal names/signatures `character_selected(character_id: String)` and `continue_requested`,
the animated background `_draw`, `_layout()`/compact mode, and `save_available`. Add signals only as
needed (`quit_requested` is fine, but `get_tree().quit()` directly is also fine).

### 4.2 Pause menu (`scripts/ui/pause_menu.gd`, `class_name PauseMenu`)

Centered panel on a dim (alpha ~0.62 so the frozen game stays visible). Title **PAUSED**. Buttons,
top to bottom:

| Button | Behaviour |
|---|---|
| **Resume** | Unpause. Default focus. |
| **Settings** | Opens the `SettingsPanel` inside the pause layer. |
| **Controls** | Read-only list built from `InputMap` (see 4.4 row "Controls") plus touch hints. Offer "Replay tutorial" which closes the menu, unpauses and calls `hud.start_tutorial()`. |
| **Save Game** | `GameState.save_game()` then an **inline** line "Saved  hh:mm:ss" in the panel. Never a toast. |
| **Main Menu** | ConfirmDialog -> `Game.return_to_title()` (4.5). |
| **Quit Game** | ConfirmDialog -> save, then `get_tree().quit()`. Hidden on web. |

Under the title also show a one-line context: current zone (`world.zone_name`), hero name/level.
If `GameState.expedition_active()`, add a warning line stating what leaving does. Read
`expedition_*` and `defeat_in_portal` in `game_state.gd` and write this text from what the code
**actually** does (is loot banked or lost? does Continue re-enter the portal?). Do not guess.

**When pausing is allowed** (`Game.can_pause() -> bool`): a run is active (`world != null` and
`title_screen == null`), not `_transitioning`, not `_defeat_pending`, the player is not dead, not
`hud.any_modal_open()`, and the tree is not already paused. Sleeping, recovery ward and build mode
are allowed.

**Entry points**
1. Esc via `Game._unhandled_input` (see D4). Same key resumes.
2. **P** via the `pause_menu` action, polled in `GameHUD._process` next to the other actions
   (emit a new `pause_requested` signal; `Game` connects it in `_connect_hud`).
3. **HUD button**: a `TouchActionButton` (caption "Menu", `action = "pause_menu"`, diameter 64) at
   top-left position about `Vector2(168, 160)`, next to Build. Keep it `_menu_button` on the HUD.
   Needs an icon kind: add a procedural `"gear"` (or `"menu"`) icon to `PixelArt.icon` under a
   stable cache key, or reuse an existing kind if drawing one is out of proportion.
4. **Android back**: in `project.godot` `[application]` set `config/quit_on_go_back=false`; handle
   `NOTIFICATION_WM_GO_BACK_REQUEST` in `Game._notification`: if paused -> resume (or close the top
   layer); else if `can_pause()` -> open pause; else do nothing. Never quit on back.
5. **Focus loss** (setting `auto_pause_on_focus_loss`, default on, desktop + mobile): on
   `NOTIFICATION_APPLICATION_FOCUS_OUT` and `NOTIFICATION_APPLICATION_PAUSED`, open pause if
   `can_pause()`. Keep the existing save behaviour (now guarded, see §2).

### 4.3 Pause mechanics checklist (all must hold)

- On pause: `hud.release_touch_controls()` (new `GameHUD` method that calls `cancel()` on every
  `TouchActionButton` and on the joystick; **Hard Rule 20**). `TouchActionButton` already has a
  public `cancel()`; `TouchJoystick` (`virtual_joystick.gd`) only has a private
  `_release_actions()` at about line 94, so add a small public `cancel()` wrapper to it. Then `get_tree().paused = true`,
  then show the menu and give the first button focus.
- On resume: hide the menu, `get_tree().paused = false`. No stuck input, **no phantom attack if F
  was held while pausing** (test by hand reasoning and document it).
- `PauseMenu`, its children and the in-pause `SettingsPanel` run under `PROCESS_MODE_ALWAYS`; the
  rest of `Game`, `HUD`, worlds stay `PAUSABLE`.
- `Sfx.process_mode = ALWAYS` so menu clicks are audible while paused. World SFX stop with the tree
  (acceptable).
- `GameState._process` guarded as in D1.
- The three `create_timer` calls now pass `false` as the second argument.
- Pausing is blocked during fades/transitions (`_transitioning`), because a paused fade tween
  would deadlock the `await`.
- Verify (and state the result): enemies, projectiles, pets, residents, the 14 s emergency clock,
  `_settlement_damage_accum`, recovery-ward healing and the sleep progress bar all freeze, and all
  resume cleanly.
- If the process is killed while paused, nothing is lost beyond the last save, and next launch
  must not start paused (it cannot, since pause is not persisted. Do not persist it).

### 4.4 Settings panel (`scripts/ui/settings_panel.gd`, `class_name SettingsPanel extends ModalBase`)

Set `_panel_size` before `super._ready()`. Rebuild is cheap, but **do not rebuild on every slider
tick** (the framework's rebuild-on-`data_changed` pattern wipes scroll and hover: gotcha 11).
Build the rows once in `_rebuild()` and update widget values in place. Do **not** subscribe to
`GameState.data_changed`.

Sections and rows (show only rows that make sense on the platform):

**Audio**
- Master volume (0-100 %), Effects volume (0-100 %), Mute all. There is **no music** in the game, so
  **do not add a Music slider**. Create an `"SFX"` bus at runtime in `Sfx._ready` (no
  `default_bus_layout.tres` exists), send it to Master, point the player pool at it, and drive both
  buses from `GameSettings` with `linear_to_db` (treat 0 as muted; avoid `-inf` issues).
- Play `Sfx.play("select")` when a volume slider is released so the user hears the level.

**Display** (hide the whole section on web and Android)
- Fullscreen toggle (`DisplayServer.window_set_mode`). The project's stretch is
  `canvas_items` + `expand`; do not change that.

**Interface**
- **UI scale** 75-130 % (matches the existing clamp 0.75-1.3). Implement by scaling the HUD root
  while resizing it to `viewport_size / scale` (anchors resolve against the parent size, so naively
  scaling an anchored root pushes right/bottom-anchored panels off screen). `ModalBase` fits itself
  to `get_viewport_rect().size`; make it use the scaled root size so large panels still fit.
  Apply live to the HUD and to open panels on next open; verify at 1280x720 and 832x480.
- **Touch controls**: Auto / Always / Hidden. Auto = visible when
  `DisplayServer.is_touchscreen_available()`. Today they are always visible, so default to
  **Always** to preserve current behaviour. Toggle `visible` on the existing nodes (the tests hold
  references to them) and call `release_touch_controls()` first.
- **Screen shake**: On/Off. Guard `FollowCamera.shake()` (`scripts/core/follow_camera.gd`), which
  is called through the `"camera"` group.
- **Pause when window loses focus**: On/Off (4.2 entry 5).

**Help**
- **Controls** (read-only): one row per gameplay action, built **from `InputMap`** at open time
  (`InputMap.action_get_events`) so it can never go stale, with human-readable key names. Group:
  Move, Strike, Use, Backpack, Build, Health potion, Mana potion, Pause. Also show the touch
  equivalents as text.
- **Replay tutorial** (only when a run is active): closes menus/unpauses and calls
  `hud.start_tutorial()`. Do not write `data.tutorial_seen`.

**Data** (title instance only)
- **Erase save**: ConfirmDialog with a clear warning, then `GameState.delete_save()`, update
  `has_existing_save`, refresh the title's Continue state. Not available from in-game.

**Footer**: **Reset to defaults** (settings only, with confirm). It must not touch the save.

Stretch (only after everything else is green; skip if tight): keyboard rebinding via `InputMap`
persisted in `settings.cfg` (rules: every action keeps >=1 event, conflict detection, per-action
and global reset, and touch buttons keep working because they share the InputMap). Applying
`control_layout` / a drag editor for touch buttons is **not** part of this task.

### 4.5 Return to title and Quit (`Game`)

Add `Game.return_to_title()`. Required sequence (mirror `return_to_lobby`'s hygiene):

1. Guard: ignore if `_transitioning`. Set `get_tree().paused = false` **before** any `await`.
2. `GameState.save_game()` (a run is active by definition).
3. `hud.release_touch_controls()`, `hud.hide_modals()`, `hud.set_build_mode(false)`,
   `hud.set_sleep_state(false, 0.0, "")`, hide the tutorial if visible, and
   `GameState.boss_health_changed.emit(false, "", 0, 0)`.
4. **Reset `_defeat_pending`, `_portal_elapsed`, `_emergency_triggered`,
   `_settlement_damage_accum` and `_input_locked`** (Hard Rule 9).
5. Optional fade to black via the existing `hud.fade_to_black`.
6. `_clear_world()` (it `queue_free`s the world and calls `hud.set_world(null)`), then
   `hud.visible = false`, free the pause menu, and call `_show_title()`. `_show_title()` already
   reads `GameState.has_existing_save`, so Continue will be enabled.
7. After a fade, fade back in. Clear `_transitioning`.

Nothing may call `Game.player()` on the dying world afterwards without a null check. Pressing
Continue after returning must reload from disk (it already does) and land in the correct world
(portal vs lobby).

**Quit Game**: save, then `get_tree().quit()`. **Hidden on web.** On Android it is allowed but the
back button must never reach it directly.

### 4.6 `ConfirmDialog` (`scripts/ui/confirm_dialog.gd`)

Reusable: `ask(title, body, confirm_text, danger := false) -> void` plus signals `confirmed` and
`cancelled`. Esc and the Cancel button cancel; **Cancel is the default focus** for destructive
asks. Works under pause (`ALWAYS`) and on the title. Stacks above whatever opened it.

---

## 5. UI / UX requirements

- Reuse `GameUI.theme()`, `GameUI.panel/button/label/title/divider/spacer`, the palette
  constants (`TEXT, MUTED, GOLD, TEAL, RED, GREEN`...) and the pixel-art frame style used by
  `ModalBase`. The menu must look like it belongs to the shop/inventory panels.
- Extend `GameUI` (not new one-off styles): add `slider_row(label, value, on_change)` and
  `toggle_row(label, value, on_change)` helpers and theme entries for `HSlider` (track, grabber,
  grabber_highlight), `CheckButton`/`CheckBox` and `OptionButton`/`PopupMenu` if used.
- **Keyboard navigation**: menu buttons must use `focus_mode = FOCUS_ALL` with a visible focus
  style (override the `focus` stylebox per button with a GOLD border; do not change the global
  empty focus style used by HUD buttons). First button grabs focus on open; focus returns to the
  invoking button when a sub-layer closes. Up/Down/Enter/Esc all work.
- Mouse hover and touch must work; minimum button height 44 px (title) / 48 px (touch).
- Layouts must fit 1280x720 and 832x480 (the test capture size) and narrow landscape phones. Use
  containers and a `ScrollContainer` for the settings body.
- All strings are plain English, short, written in the existing voice. No emojis.
- Visual verification: if a display is available run `godot --path .` and look at the title, pause,
  settings (both instances), confirm dialog, at both window sizes. **Do not** use
  `tide_capture.tscn`. If you cannot see it, say "not visually verified" in the report.

---

## 6. Files to add / touch

New:
- `scripts/core/game_settings.gd`: autoload `GameSettings` (D2)
- `scripts/ui/pause_menu.gd`: `class_name PauseMenu`
- `scripts/ui/settings_panel.gd`: `class_name SettingsPanel`
- `scripts/ui/confirm_dialog.gd`: `class_name ConfirmDialog`

Edit:
- `project.godot`: `[autoload]` add `GameSettings`; `[application]` add
  `config/quit_on_go_back=false`; `[input]` add `pause_menu` (P) **by hand, copying the exact
  serialisation of an existing block** (do not run `tools/setup_input.gd`).
- `scripts/game/game.gd`: `can_pause()`, `open_pause()`, `close_pause()`, `return_to_title()`,
  Esc `_unhandled_input`, back-button/focus-loss handling, guarded `_notification`, `create_timer`
  fix, connect `hud.pause_requested`.
- `scripts/ui/game_hud.gd`: `_menu_button`, `pause_requested`, `release_touch_controls()`, poll
  `pause_menu` in `_process`, touch-controls visibility and UI-scale hooks. Do not rename anything
  the tests reference.
- `scripts/ui/title_screen.gd`: two-state menu, Back, overwrite confirm, Settings/Credits/Quit,
  save summary, corrupt-save message.
- `scripts/ui/modal_base.gd`: size fitting against the scaled root (keep `_panel_size`-before-
  `super._ready()` contract).
- `scripts/core/ui_theme.gd`: slider/toggle helpers and theme entries.
- `scripts/core/follow_camera.gd`: shake setting guard.
- `scripts/autoload/sfx.gd`: SFX bus, `process_mode = ALWAYS`, volume application.
- `scripts/autoload/game_state.gd`: `_process` pause guard, read-only `save_summary()`; nothing
  else. **If you add any new `data` field, it must be in both `_make_default` and `_sanitize`
  (Hard Rule 2); you should not need to.**
- `scripts/player/player.gd`, `scripts/combat/enemy.gd`: the `create_timer(t, false)` fixes.
- `scripts/core/pixel_art.gd`: optional `"gear"` icon (stable cache key).
- Docs: see §8.

After adding any `class_name` script, re-import (`godot --headless --path . --import`) so the
global class cache knows it, and keep the generated `.gd.uid` files (the repo commits them).

---

## 7. Implementation order (stop and verify at each exit)

1. **Foundations**: `GameSettings` autoload (load/save/validate/apply), `Sfx` bus + ALWAYS,
   `GameUI` slider/toggle helpers + theme entries, `ConfirmDialog`.
   *Exit*: project parses (`--import`), suite still shows only the one known `[FAIL]`.
2. **Bug fixes**: guarded `_notification` (phantom save), `create_timer` fixes, `GameState`
   pause guard. *Exit*: suite unchanged.
3. **SettingsPanel** (all rows) hooked into a temporary debug call. *Exit*: each setting applies
   live, persists to `settings.cfg`, and survives a restart; Reset to defaults works.
4. **Pause menu + Game plumbing** (all five entry points, `can_pause`, mechanics checklist, release
   touch controls). *Exit*: manual pause/resume in lobby, dungeon, build mode, sleeping, recovery,
   during an emergency.
5. **Return to title + Quit**. *Exit*: lobby -> title -> Continue and dungeon -> title -> Continue
   both land correctly, repeated three times without leaks or stuck input.
6. **Title main menu** (two states, summary, overwrite confirm, corrupt-save message, Erase Save).
7. **Tests, docs, AGENTS.md** (§8). Run the suite with data backed up.

Do not start a phase until the previous one is green. Do not batch everything into one diff.

---

## 8. Tests and docs

Add `_test_menus()` to `tools/tide_test.gd` (and call it from `_ready()` before the final tally).
Do not hardcode `250` anywhere. Cover at least:

- Title: `Continue` is disabled with no save and enabled once a save exists; Settings, Credits and
  (non-web) Quit exist; the three required labels still exist; choosing a hero with an existing
  save requires confirmation, and with no save does not.
- Pause: `Game.can_pause()` is true in the lobby and false while a modal is open, during a
  transition and when dead; opening sets `get_tree().paused`; the pause UI root has
  `process_mode == PROCESS_MODE_ALWAYS`; `Game._portal_elapsed` does not advance over N frames
  while paused (set up a dungeon expedition) and does advance after resume; `GameState.data.play_time`
  does not advance while paused; Esc while a shop is open closes the shop **and does not** open the
  pause menu; resume releases pause; **the test must always leave `get_tree().paused = false`**,
  including on failure paths, or the rest of the suite stalls.
- Settings: setters clamp and persist; reset-to-defaults works; the Master/SFX buses exist; mute
  works; screen-shake off makes `FollowCamera.shake()` a no-op; touch-controls Hidden hides
  `_joystick`/`_attack_button` **and releases their actions**.
- Phantom save: with no save, `Game._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)` on the title
  creates no save file.
- Return to title: `Game.return_to_title()` ends with `title_screen != null`, `world == null`,
  `hud.visible == false`, the four reset variables zeroed/false, tree unpaused; Continue then
  restores the lobby (and the dungeon when an expedition was active).
- `GameSettings` must take a test-overridable config path (e.g. `config_path` var) so the suite
  writes to a temp file and never touches the real `settings.cfg`.

Docs to update **in the same change** (they would otherwise become false):
- `AGENTS.md`: rule 15 and §3 runtime-rule 3 (pause now exists), gotcha 2, autoload count, §4 file
  table, a new "menus" paragraph (Esc routing, never map Esc to a polled action, never save from the
  title path), and the new test section.
- `docs/ACCEPTANCE_TESTS.md`: a "Menus and pause" section matching the new checks.
- `docs/ARCHITECTURE.md`: pause model, `GameSettings`, new classes, layer numbers (HUD 10, pause
  100, title 200).
- `README.md`: controls table (Esc = pause / close, P = pause, Menu button) and settings summary.

Run, with data backed up:

```sh
godot --headless --path . --import
timeout 600 godot --headless --path . res://tools/tide_test.tscn 2>&1 | tee /tmp/tide_out.txt ; echo "EXIT=${PIPESTATUS[0]}"
grep -nE "\[FAIL\]|SCRIPT ERROR|ERROR:|WARNING:" /tmp/tide_out.txt
```

Expected: exactly one `[FAIL]` (the forest-tree line), exit code 1, nothing else matched, every
new check `[OK]`. Never trust the exit code alone; always grep stdout.

---

## 9. Traps (each of these has a concrete failure mode in this codebase)

1. Mapping Esc to a polled action: fires in the same frame a modal closes, so one keypress closes
   the shop **and** opens pause.
2. Calling any saving `GameState` method (or `Game._notification`) while the title is up: creates
   a phantom Qayyim save.
3. Putting the overwrite confirm in `Game._on_character_selected`: the suite calls it directly
   (`tide_test.gd:29`), so a modal dialog there can stall the headless run. Keep the confirm in
   `TitleScreen`.
4. Forgetting `create_timer(t, false)`: the defeat panel, hit-flash and enemy attack timers fire
   during pause.
5. Pausing during a fade: the `await tween.finished` never resolves.
6. Leaving `get_tree().paused = true` before `await`s in `return_to_title()`: deadlock.
7. Not releasing synthetic inputs on pause/hide/return: stuck movement (Hard Rule 20).
8. Rebuilding the settings panel on every slider change or on `data_changed`: wipes scroll/hover.
9. Using un-themed `HSlider`/`CheckButton`: default grey widgets in a themed UI.
10. Scaling an anchored HUD root without resizing it: right/bottom panels leave the screen.
11. Adding a `ModalBase` panel without updating `any_modal_open()`, `hide_modals()`,
    `_build_modals()` and `Game._connect_hud()` (only relevant if you deviate from D3).
12. Dot-access on dictionary records in UI (`rec.key`): use `.get(key, default)`.
13. Adding a `class_name` without re-importing: the project will not parse in headless runs.
14. Leaving the player's save/settings overwritten after running the suite.
15. Persisting node references or the paused flag. Persist plain values only.
16. Showing a Quit button on web, where `get_tree().quit()` does nothing. This project targets
    desktop and Android (and possibly web), so gate Quit on `not OS.has_feature("web")`.

---

## 10. Non-goals (do not do these; mention them as follow-ups if relevant)

- Multiple save slots, cloud saves, or changing `SAVE_PATH` / `delete_save` semantics.
- Switching hero inside an existing save (weapon-style gating in `equip_item`, `_sanitize`
  and inventory makes it a gameplay redesign).
- Making ordinary modals (shop/inventory/portal) pause the game, or "fixing" the raid-while-
  shopping behaviour.
- Music, ambient audio, new SFX beyond using the existing `"select"` blip.
- Resolving the forest-tree invulnerability decision, or touching `forest_tree.gd`.
- A touch-control drag editor / applying `control_layout`.
- Gamepad support, localisation, export/build work.

---

## 11. Final report format (required)

Reply with, in this order:
1. **What changed**: files added/edited, one line each.
2. **Verification**: the exact commands you ran, the exact `[FAIL]` lines remaining (should be the
   single known one), the `grep` output, and the number of new `[OK]` checks.
3. **Not verified**: anything you could not run or see (no display, no Godot, no touch device,
   Android back button, focus loss, web). Be explicit; do not imply coverage you did not have.
4. **Decisions and deviations**: anything you changed from D1-D5 and why.
5. **Bugs found/fixed**: confirm or refute the phantom-save and silent-Continue findings with what
   you observed.
6. **Docs updated**: list.
7. **Follow-ups** worth the owner's attention.