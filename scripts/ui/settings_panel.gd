class_name SettingsPanel
extends ModalBase
## GUI scale and touch-control customization. Values are stored in GameState
## and applied to the live HUD immediately.

const CONTROL_ROWS := [
	["joystick", "Joystick"],
	["attack", "Strike"],
	["interact", "Use"],
	["inventory", "Pack"],
	["build", "Build"],
	["health_potion", "HP"],
	["mana_potion", "MP"],
]

var _rows: Dictionary = {}
var _scale_label: Label


func open_settings() -> void:
	open_panel("Settings")


func _rebuild() -> void:
	_clear_content()
	var hud := get_tree().get_first_node_in_group("hud") as GameHUD
	if hud == null:
		add_body_text("HUD is not available.", GameUI.RED, 16)
		return

	add_section("GUI SCALE", GameUI.GOLD)
	var scale_row := HBoxContainer.new()
	scale_row.add_theme_constant_override("separation", 12)
	scale_row.add_child(GameUI.label("Interface scale", 14, GameUI.TEXT))
	var slider := HSlider.new()
	slider.min_value = 0.75
	slider.max_value = 1.30
	slider.step = 0.05
	slider.value = hud.get_gui_scale()
	slider.custom_minimum_size = Vector2(360, 32)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scale_row.add_child(slider)
	_scale_label = GameUI.label("%d%%" % int(round(slider.value * 100.0)), 16, GameUI.GOLD)
	_scale_label.custom_minimum_size = Vector2(70, 0)
	scale_row.add_child(_scale_label)
	slider.value_changed.connect(func(value: float) -> void:
		_scale_label.text = "%d%%" % int(round(value * 100.0))
		hud.set_gui_scale(value))
	content.add_child(scale_row)

	add_section("TOUCH CONTROLS", GameUI.GOLD)
	add_body_text("Adjust X, Y and size. Changes apply immediately and are saved.", GameUI.MUTED, 13)
	var layout := hud.get_control_layout_current()
	_rows.clear()
	for row_data in CONTROL_ROWS:
		var control_id := str(row_data[0])
		var display_name := str(row_data[1])
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", GameUI.style(Color("#14262c"), Color("#30494e"), 1, 0))
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)
		row.add_child(hbox)
		var name_label := GameUI.label(display_name, 14, GameUI.TEXT)
		name_label.custom_minimum_size = Vector2(120, 0)
		hbox.add_child(name_label)
		var values: Dictionary = layout.get(control_id, {})
		var x_spin := _make_spin(float(values.get("x", 0.0)), 0.0, 1600.0, 1.0)
		var y_spin := _make_spin(float(values.get("y", 0.0)), 0.0, 1000.0, 1.0)
		var size_spin := _make_spin(float(values.get("size", 80.0)), 42.0, 260.0, 1.0)
		hbox.add_child(_spin_group("X", x_spin))
		hbox.add_child(_spin_group("Y", y_spin))
		hbox.add_child(_spin_group("Size", size_spin))
		_rows[control_id] = {"x": x_spin, "y": y_spin, "size": size_spin}
		x_spin.value_changed.connect(func(_value: float) -> void: _apply_row(control_id))
		y_spin.value_changed.connect(func(_value: float) -> void: _apply_row(control_id))
		size_spin.value_changed.connect(func(_value: float) -> void: _apply_row(control_id))
		content.add_child(row)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	content.add_child(actions)
	var reset := GameUI.button("Reset controls", Vector2(180, 42))
	reset.pressed.connect(func() -> void:
		hud.reset_control_layout()
		_rebuild())
	actions.add_child(reset)
	var back := GameUI.button("Back", Vector2(160, 42))
	back.pressed.connect(close_panel)
	actions.add_child(back)


func _make_spin(value: float, minimum: float, maximum: float, step: float) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = minimum
	spin.max_value = maximum
	spin.step = step
	spin.value = value
	spin.custom_minimum_size = Vector2(94, 34)
	spin.select_all_on_focus = true
	return spin


func _spin_group(caption: String, spin: SpinBox) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	box.add_child(GameUI.label(caption, 10, GameUI.MUTED))
	box.add_child(spin)
	return box


func _apply_row(control_id: String) -> void:
	var values: Dictionary = _rows.get(control_id, {})
	if values.is_empty():
		return
	var hud := get_tree().get_first_node_in_group("hud") as GameHUD
	if hud == null:
		return
	var x_spin := values.get("x") as SpinBox
	var y_spin := values.get("y") as SpinBox
	var size_spin := values.get("size") as SpinBox
	hud.set_control_layout(control_id, x_spin.value, y_spin.value, size_spin.value)
