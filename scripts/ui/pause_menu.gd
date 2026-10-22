class_name PauseMenu
extends CanvasLayer
## The game's one real pause surface (spec 4.2, decision D3).
##
## A `CanvasLayer` at layer 100 - above the HUD (10) and below the title (200) -
## created and owned by `Game`. The tree pause is set by `Game`, never here:
## this node draws the menu and reports intent through signals.
##
## It is deliberately **not** a `ModalBase` and **not** part of
## `GameHUD.any_modal_open()`: a real pause already stops world input, so the
## modal input lock would be redundant. `SettingsPanel` and every confirm dialog
## are parented to this layer, which is what keeps them usable while the tree is
## paused (`PROCESS_MODE_ALWAYS` is inherited from the layer root).
##
## Esc handling: the layer is the topmost pause surface, so it owns Esc while it
## is open. `ModalBase` children consume Esc first and close themselves, which is
## how "Esc closes only the topmost layer" falls out of the tree order.

signal resume_requested
signal tutorial_requested

const LAYER := 100
## Spec 4.2 asks for ~0.62 so the frozen world stays readable behind the menu.
const DIM_ALPHA := 0.62
const PANEL_SIZE := Vector2(560, 470)
const PANEL_MIN_SIZE := Vector2(320, 300)
const BUTTON_SIZE := Vector2(0, 48)
const BUTTON_SEPARATION := 6
const ROW_MIN_HEIGHT := 34
const NAME_WIDTH := 150
const TOUCH_WIDTH := 130
const DANGER_FILL := Color("#2a1518")
const DANGER_HOVER := Color("#3d1d22")
const FRAME_FILL := Color("#101f24")
const FRAME_BORDER := Color("#4c6c70")

## One row per gameplay action, read out of `InputMap` each time the page is
## shown so a rebind or a new event can never leave this list stale (spec 4.4).
## Deliberately mirrors the settings panel's table; the two pages have different
## layouts (this one is a full page, that one is a section), so the table stays
## small and local rather than shared.
const CONTROL_ROWS := [
	{"label": "Move", "actions": ["move_up", "move_left", "move_down", "move_right"], "touch": "Left joystick", "pairs": true},
	{"label": "Strike", "actions": ["attack"], "touch": "Strike button"},
	{"label": "Use", "actions": ["interact"], "touch": "Use button"},
	{"label": "Backpack", "actions": ["open_inventory"], "touch": "Pack button"},
	{"label": "Build", "actions": ["toggle_build"], "touch": "Build button"},
	{"label": "Health potion", "actions": ["use_health_potion"], "touch": "HP button"},
	{"label": "Mana potion", "actions": ["use_mana_potion"], "touch": "MP button"},
	{"label": "Pause", "actions": ["pause_menu"], "touch": "Menu button / Esc"},
]

var _root: Control
var _dim: ColorRect
var _panel: PanelContainer
var _context_label: Label
var _expedition_label: Label
var _status_label: Label

var _buttons_scroll: ScrollContainer
var _buttons_box: VBoxContainer
var _controls_scroll: ScrollContainer
var _controls_box: VBoxContainer
var _control_rows_box: VBoxContainer

var _resume_button: Button
var _settings_button: Button
var _controls_button: Button
var _save_button: Button
var _main_menu_button: Button
var _quit_button: Button

var _settings: SettingsPanel
var _confirm: ConfirmDialog
var _controls_open := false
var _last_focus: Control


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_set_open(false)
	if not GameSettings.changed.is_connected(_on_setting_changed):
		GameSettings.changed.connect(_on_setting_changed)
	if get_viewport() != null:
		get_viewport().size_changed.connect(_apply_scale)


# --------------------------------------------------------------- construction

func _build() -> void:
	_root = Control.new()
	_root.name = "PauseRoot"
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.theme = GameUI.theme()
	add_child(_root)

	_dim = ColorRect.new()
	_dim.name = "PauseDim"
	_dim.color = Color(0.01, 0.02, 0.03, DIM_ALPHA)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_dim)

	_panel = PanelContainer.new()
	_panel.name = "PausePanel"
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.add_theme_stylebox_override("panel", GameUI.style(FRAME_FILL, FRAME_BORDER, 2, 0))
	_root.add_child(_panel)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", BUTTON_SEPARATION)
	_panel.add_child(outer)

	var title := GameUI.title("PAUSED", 30, GameUI.TEXT)
	title.name = "PauseTitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(title)

	_context_label = GameUI.label("", 15, GameUI.MUTED)
	_context_label.name = "PauseContext"
	_context_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(_context_label)

	_expedition_label = GameUI.label("", 13, GameUI.GOLD)
	_expedition_label.name = "PauseExpedition"
	_expedition_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_expedition_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_expedition_label.visible = false
	outer.add_child(_expedition_label)

	outer.add_child(GameUI.divider(Color("#38545a")))
	_build_buttons_page(outer)
	_build_controls_page(outer)

	_status_label = GameUI.label("", 13, GameUI.TEAL)
	_status_label.name = "PauseStatus"
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer.add_child(_status_label)

	_settings = SettingsPanel.new()
	_settings.name = "PauseSettings"
	_settings.in_title = false
	_root.add_child(_settings)
	_settings.closed.connect(_on_settings_closed)

	_apply_scale()


func _build_buttons_page(host: VBoxContainer) -> void:
	_buttons_scroll = _make_scroll("PauseButtons")
	host.add_child(_buttons_scroll)
	_buttons_box = VBoxContainer.new()
	_buttons_box.add_theme_constant_override("separation", BUTTON_SEPARATION)
	_buttons_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_buttons_scroll.add_child(_buttons_box)

	_resume_button = _add_button(_buttons_box, "Resume", GameUI.TEXT)
	_resume_button.name = "ResumeButton"
	_resume_button.pressed.connect(_on_resume)

	_settings_button = _add_button(_buttons_box, "Settings", GameUI.TEXT)
	_settings_button.pressed.connect(_on_settings_pressed)

	_controls_button = _add_button(_buttons_box, "Controls", GameUI.TEXT)
	_controls_button.pressed.connect(_on_controls_pressed)

	_save_button = _add_button(_buttons_box, "Save Game", GameUI.TEAL)
	_save_button.pressed.connect(_on_save_pressed)

	_main_menu_button = _add_button(_buttons_box, "Main Menu", GameUI.GOLD)
	_main_menu_button.pressed.connect(_on_main_menu_pressed)

	_quit_button = _add_button(_buttons_box, "Quit Game", GameUI.RED)
	_quit_button.pressed.connect(_on_quit_pressed)
	# Web cannot quit (trap 16): hide instead of shipping a dead button.
	_quit_button.visible = not OS.has_feature("web")


func _build_controls_page(host: VBoxContainer) -> void:
	_controls_scroll = _make_scroll("PauseControls")
	_controls_scroll.visible = false
	host.add_child(_controls_scroll)
	_controls_box = VBoxContainer.new()
	_controls_box.add_theme_constant_override("separation", 4)
	_controls_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_controls_scroll.add_child(_controls_box)

	var back := _add_button(_controls_box, "Back", GameUI.TEXT)
	back.custom_minimum_size = Vector2(0, 44)
	back.pressed.connect(_show_buttons_page)

	_controls_box.add_child(GameUI.spacer(2))
	_controls_box.add_child(GameUI.label("Keyboard and touch share the same bindings.", 12, GameUI.MUTED))
	for entry: Dictionary in CONTROL_ROWS:
		_controls_box.add_child(_control_row(entry))

	_controls_box.add_child(GameUI.spacer(4))
	_controls_box.add_child(GameUI.divider(Color("#2a4046")))
	var replay_row := HBoxContainer.new()
	replay_row.add_theme_constant_override("separation", 12)
	_controls_box.add_child(replay_row)
	var replay_note := GameUI.label("Restarts the first-run tutorial in this run.", 12, GameUI.MUTED)
	replay_note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	replay_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	replay_note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	replay_row.add_child(replay_note)
	var replay := _add_button(replay_row, "Replay tutorial", GameUI.TEAL)
	replay.custom_minimum_size = Vector2(180, 44)
	replay.pressed.connect(_on_replay_tutorial)


func _make_scroll(node_name: String) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.name = node_name
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	# Keyboard users must see the row their focus moved to.
	scroll.follow_focus = true
	return scroll


func _add_button(host: Container, text: String, color: Color) -> Button:
	var button := GameUI.button(text, BUTTON_SIZE, color)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_stylebox_override("focus", GameUI.style(Color(0, 0, 0, 0), GameUI.GOLD, 2, 0))
	host.add_child(button)
	return button


func _control_row(entry: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.custom_minimum_size = Vector2(0, ROW_MIN_HEIGHT)
	var name_label := GameUI.label(str(entry.get("label", "")), 15, GameUI.TEXT)
	name_label.custom_minimum_size = Vector2(NAME_WIDTH, 0)
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(name_label)
	var keys := GameUI.label(_keys_text(entry), 14, GameUI.GOLD)
	keys.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	keys.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	keys.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(keys)
	var touch := GameUI.label(str(entry.get("touch", "")), 12, GameUI.MUTED)
	touch.custom_minimum_size = Vector2(TOUCH_WIDTH, 0)
	touch.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	touch.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(touch)
	return row


func _keys_text(entry: Dictionary) -> String:
	var actions: Array = entry.get("actions", [])
	var pairs := bool(entry.get("pairs", false))
	var parts: Array[String] = []
	for action in actions:
		var action_name := str(action)
		if not InputMap.has_action(action_name):
			continue
		var keys: Array[String] = []
		for event in InputMap.action_get_events(action_name):
			var key_name := _event_name(event)
			if key_name != "" and not keys.has(key_name):
				keys.append(key_name)
		if keys.is_empty():
			continue
		parts.append("/".join(keys) if pairs else ", ".join(keys))
	if parts.is_empty():
		return "Not bound"
	return "    ".join(parts)


func _event_name(event: InputEvent) -> String:
	if event is InputEventKey:
		var key := event as InputEventKey
		var code := key.keycode if key.keycode != KEY_NONE else key.physical_keycode
		if code == KEY_NONE:
			return ""
		return OS.get_keycode_string(code)
	if event is InputEventMouseButton:
		return "Mouse %d" % int((event as InputEventMouseButton).button_index)
	if event is InputEventJoypadButton:
		return "Pad %d" % int((event as InputEventJoypadButton).button_index)
	if event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		return "Stick %d%s" % [int(motion.axis), "+" if motion.axis_value > 0.0 else "-"]
	return ""


# --------------------------------------------------------------- sizing / scale

## Mirrors the HUD's ui-scale trick: the layer root is scaled *and* resized, so
## anchors still resolve inside the visible viewport (trap 10). The menu is on
## its own canvas layer, so nothing else does this for it.
func _apply_scale() -> void:
	if _root == null or get_viewport() == null:
		return
	var factor := clampf(float(GameSettings.ui_scale()) / 100.0, 0.75, 1.3)
	var view := get_viewport().get_visible_rect().size
	if view.x <= 0.0 or view.y <= 0.0:
		view = Vector2(1280, 720)
	_root.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_root.position = Vector2.ZERO
	_root.size = view / factor
	_root.scale = Vector2(factor, factor)
	_fit_panel()


func _available_size() -> Vector2:
	if _root != null and _root.size.x > 0.0 and _root.size.y > 0.0:
		return _root.size
	return get_viewport().get_visible_rect().size


## Fitted on every open: a 832x480 window must show the whole panel.
func _fit_panel() -> void:
	if _panel == null:
		return
	var available := _available_size()
	var fitted := Vector2(
		minf(PANEL_SIZE.x, maxf(PANEL_MIN_SIZE.x, available.x - 24.0)),
		minf(PANEL_SIZE.y, maxf(PANEL_MIN_SIZE.y, available.y - 24.0)))
	_panel.offset_left = -fitted.x * 0.5
	_panel.offset_top = -fitted.y * 0.5
	_panel.offset_right = fitted.x * 0.5
	_panel.offset_bottom = fitted.y * 0.5


# --------------------------------------------------------------- open / close

func _set_open(value: bool) -> void:
	visible = value
	if _root != null:
		_root.visible = value


func is_open() -> bool:
	return _root != null and _root.visible


## Called by `Game.open_pause()` after the tree is paused: shows the menu, fills
## the context line and puts the focus on Resume (spec 4.2).
func open(zone_name: String) -> void:
	_set_open(true)
	_show_buttons_page()
	_close_confirm()
	_set_status("", GameUI.TEAL)
	_refresh_context(zone_name)
	_apply_scale()
	_fit_panel()
	if _resume_button != null:
		_resume_button.grab_focus()


## Called by `Game.close_pause()` before the tree is unpaused.
func close_menu() -> void:
	_close_confirm()
	if _settings != null and _settings.visible:
		_settings.close_panel()
	_show_buttons_page()
	_set_status("", GameUI.TEAL)
	_set_open(false)


## Closes only the topmost sub-layer. Returns true when something was closed
## (the menu therefore stays open); false when the menu itself is next.
func close_top_layer() -> bool:
	if _confirm_open():
		_confirm.close_panel()
		return true
	if _settings != null and _settings.visible:
		_settings.close_panel()
		return true
	if _controls_open:
		_show_buttons_page()
		return true
	return false


# --------------------------------------------------------------- context

func _refresh_context(zone_name: String) -> void:
	var hero := str(GameState.data.get("character_name", "Hero"))
	var level := int(GameState.data.get("level", 1))
	_context_label.text = "%s  •  %s  Lv %d" % [zone_name, hero, level]
	_expedition_label.text = expedition_text()
	_expedition_label.visible = GameState.expedition_active()


## Read from the real expedition code in `game_state.gd`:
##   * `add_expedition_loot` parks gold/diamonds/items in `data.expedition`,
##   * only `bank_expedition_loot()` moves them into the purse
##     (`complete_portal` -> on a clear, `leave_portal_safely` -> paid exit),
##   * `defeat_in_portal` calls `lose_expedition_loot()`, which empties the
##     whole record: unbanked loot is destroyed, not kept,
##   * `Game._on_continue_requested` reloads the dungeon while
##     `expedition_active()`, so Continue walks straight back into the portal.
func expedition_text() -> String:
	if not GameState.expedition_active():
		return ""
	var summary := GameState.expedition_loot_summary().replace("Unbanked: ", "")
	if summary == "No unbanked loot":
		summary = ""
	var lead := "No loot collected yet."
	if summary != "":
		lead = "Unbanked: %s." % summary
	return "%s Loot is banked only when you clear the portal; falling inside destroys it. Continue re-enters the portal." % lead


func context_text() -> String:
	return _context_label.text if _context_label != null else ""


func expedition_line_visible() -> bool:
	return _expedition_label != null and _expedition_label.visible


func status_text() -> String:
	return _status_label.text if _status_label != null else ""


func controls_open() -> bool:
	return _controls_open


func settings_open() -> bool:
	return _settings != null and _settings.visible


# --------------------------------------------------------------- pages

func _show_buttons_page() -> void:
	_controls_open = false
	if _controls_scroll != null:
		_controls_scroll.visible = false
	if _buttons_scroll != null:
		_buttons_scroll.visible = true


func _show_controls_page() -> void:
	_controls_open = true
	_refresh_controls()
	if _buttons_scroll != null:
		_buttons_scroll.visible = false
	if _controls_scroll != null:
		_controls_scroll.visible = true
	_controls_scroll.scroll_vertical = 0
	var first := _controls_box.get_child(0) as Control
	if first != null:
		first.grab_focus()


func _refresh_controls() -> void:
	# Keys are read live from InputMap, so rebuilding the rows here is right:
	# the page is only built when it is shown, never per frame.
	for child in _controls_box.get_children():
		if child is HBoxContainer and child.custom_minimum_size.y == ROW_MIN_HEIGHT:
			_controls_box.remove_child(child)
			child.queue_free()
	var insert_at := 3
	for entry: Dictionary in CONTROL_ROWS:
		_controls_box.add_child(_control_row(entry))
		_controls_box.move_child(_controls_box.get_child(_controls_box.get_child_count() - 1), insert_at)
		insert_at += 1


# --------------------------------------------------------------- handlers

func _on_resume() -> void:
	resume_requested.emit()


func _on_settings_pressed() -> void:
	_last_focus = _settings_button
	_settings.open_panel("Settings")


func _on_settings_closed() -> void:
	if not is_open():
		return
	_grab_last_focus()


func _on_controls_pressed() -> void:
	_last_focus = _controls_button
	_show_controls_page()


func _on_save_pressed() -> void:
	GameState.save_game()
	_set_status("Saved  %s" % Time.get_time_string_from_system(), GameUI.TEAL)


func _on_main_menu_pressed() -> void:
	_last_focus = _main_menu_button
	_ask(
		"Main menu",
		"Return to the title screen? Your progress is saved first; unbanked expedition loot stays unbanked and Continue re-enters the portal.",
		"Main menu",
		false,
		_on_main_menu_confirmed)


func _on_main_menu_confirmed() -> void:
	var game := _game()
	if game == null:
		return
	if not game.has_method("return_to_title"):
		# Phase 5 lands `Game.return_to_title()`; until then say so instead of
		# calling a method that does not exist.
		_set_status("Returning to the title is not available yet.", GameUI.MUTED)
		return
	game.call("return_to_title")


func _on_quit_pressed() -> void:
	_last_focus = _quit_button
	_ask(
		"Quit game",
		"Save and leave Save The World? Unbanked expedition loot stays in the save and Continue re-enters the portal.",
		"Save and quit",
		true,
		_on_quit_confirmed)


func _on_quit_confirmed() -> void:
	GameState.save_game()
	get_tree().quit()


func _on_replay_tutorial() -> void:
	tutorial_requested.emit()


func _on_setting_changed(key: String) -> void:
	if key != "ui_scale" or not is_open():
		return
	_apply_scale()


# --------------------------------------------------------------- status / confirm

func _set_status(text: String, color: Color) -> void:
	if _status_label == null:
		return
	_status_label.text = text
	_status_label.add_theme_color_override("font_color", color)


func _ask(title: String, body: String, confirm_text: String, danger: bool, on_confirm: Callable) -> void:
	_close_confirm()
	var dialog := ConfirmDialog.new()
	dialog.process_mode = Node.PROCESS_MODE_ALWAYS
	_root.add_child(dialog)
	_confirm = dialog
	dialog.confirmed.connect(func() -> void:
		_close_confirm()
		if on_confirm.is_valid():
			on_confirm.call())
	dialog.closed.connect(_on_confirm_closed)
	dialog.ask(title, body, confirm_text, danger)


func _on_confirm_closed() -> void:
	_close_confirm()
	if is_open():
		_grab_last_focus()


func _close_confirm() -> void:
	if _confirm != null and is_instance_valid(_confirm):
		_confirm.queue_free()
	_confirm = null


func _confirm_open() -> bool:
	return _confirm != null and is_instance_valid(_confirm) and _confirm.visible


func _grab_last_focus() -> void:
	if _last_focus != null and is_instance_valid(_last_focus) and _last_focus.visible:
		_last_focus.grab_focus()
		return
	if _resume_button != null:
		_resume_button.grab_focus()


func _game() -> Node:
	return get_tree().get_first_node_in_group("game")


# --------------------------------------------------------------- input

## Esc closes exactly one layer: the confirm dialog, then the settings panel,
## then the controls page, then the pause itself. `ModalBase` children consume
## the event before this runs, so the guard below is belt and braces.
func _unhandled_input(event: InputEvent) -> void:
	if not is_open():
		return
	if not _is_cancel(event):
		return
	if close_top_layer():
		get_viewport().set_input_as_handled()
		return
	resume_requested.emit()
	get_viewport().set_input_as_handled()


func _is_cancel(event: InputEvent) -> bool:
	if event is InputEventKey and event.is_echo():
		return false
	return event.is_action_pressed("ui_cancel")
