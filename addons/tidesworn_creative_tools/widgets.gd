@tool
extends RefCounted

static func row(parent: Node) -> HBoxContainer:
	var result := HBoxContainer.new()
	parent.add_child(result)
	return result

static func label(parent: Node, text: String) -> Label:
	var result := Label.new()
	result.text = text
	parent.add_child(result)
	return result

static func button(parent: Node, text: String, action: Callable) -> Button:
	var result := Button.new()
	result.text = text
	result.pressed.connect(action)
	parent.add_child(result)
	return result

static func entry(parent: Node, hint: String, value := "") -> LineEdit:
	var result := LineEdit.new()
	result.placeholder_text = hint
	result.text = value
	result.custom_minimum_size.x = 150
	parent.add_child(result)
	return result

static func option(parent: Node, items: Array) -> OptionButton:
	var result := OptionButton.new()
	for item in items: result.add_item(str(item))
	parent.add_child(result)
	return result

static func number(parent: Node, title: String, value: float, minimum := 0.0, maximum := 512.0) -> SpinBox:
	label(parent, title)
	var result := SpinBox.new()
	result.step = 0.01 if not is_equal_approx(value, round(value)) or not is_equal_approx(minimum, round(minimum)) else 1.0
	result.min_value = minimum
	result.max_value = maximum
	result.value = value
	result.custom_minimum_size.x = 80
	parent.add_child(result)
	return result

static func check(parent: Node, title: String, enabled := false) -> CheckBox:
	var result := CheckBox.new()
	result.text = title
	result.button_pressed = enabled
	parent.add_child(result)
	return result

static func dialog(parent: Node, filters: PackedStringArray, save: bool, action: Callable, external := false) -> FileDialog:
	var result := FileDialog.new()
	result.access = FileDialog.ACCESS_FILESYSTEM if external else FileDialog.ACCESS_RESOURCES
	result.file_mode = FileDialog.FILE_MODE_SAVE_FILE if save else FileDialog.FILE_MODE_OPEN_FILE
	result.filters = filters
	result.size = Vector2i(800, 550)
	result.file_selected.connect(action)
	result.file_selected.connect(func(_path: String) -> void: result.queue_free())
	result.files_selected.connect(func(_paths: PackedStringArray) -> void: result.queue_free())
	result.canceled.connect(result.queue_free)
	parent.add_child(result)
	return result


static func swatch(button: Button, color: Color) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_border_width_all(1)
	box.border_color = color.lightened(0.15)
	button.add_theme_stylebox_override("normal", box)
	button.add_theme_stylebox_override("hover", box)
	button.add_theme_stylebox_override("pressed", box)
