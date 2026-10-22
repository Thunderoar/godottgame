class_name ModalBase
extends Control
## Full-screen dim + framed content used by shops, inventory, portals and the
## victory screen. It blocks world input while open and always has a close path.

signal closed

var content: VBoxContainer
var header_label: Label
var body: ScrollContainer
var panel: PanelContainer
var _title := "Panel"
var _panel_size := Vector2(860, 590)
var _close_button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build_shell()


func _build_shell() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.015, 0.03, 0.04, 0.76)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	# Keep every large modal inside the current window, including 832x480 test
	# captures and narrow landscape phone layouts.
	var view_size := get_viewport_rect().size
	var fitted := Vector2(
		minf(_panel_size.x, maxf(320.0, view_size.x - 32.0)),
		minf(_panel_size.y, maxf(300.0, view_size.y - 32.0)))
	panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -fitted.x * 0.5
	panel.offset_top = -fitted.y * 0.5
	panel.offset_right = fitted.x * 0.5
	panel.offset_bottom = fitted.y * 0.5
	panel.add_theme_stylebox_override("panel", GameUI.style(Color("#101f24"), Color("#4c6c70"), 2, 0))
	add_child(panel)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	panel.add_child(outer)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	outer.add_child(header)
	header_label = GameUI.title(_title, 26, GameUI.TEXT)
	header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_label)
	var close := GameUI.button("Close", Vector2(92, 40))
	close.pressed.connect(close_panel)
	header.add_child(close)
	_close_button = close
	outer.add_child(GameUI.divider(Color("#38545a")))
	body = ScrollContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(body)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	body.add_child(content)


func open_panel(title: String = "") -> void:
	if title != "":
		_title = title
		if header_label:
			header_label.text = title
	visible = true
	move_to_front()
	if is_inside_tree():
		# Modal panels need a moment to lay out before we measure content.
		await get_tree().process_frame
	_rebuild()


func close_panel() -> void:
	visible = false
	_clear_content()
	closed.emit()


func _rebuild() -> void:
	pass


func _clear_content() -> void:
	if content == null:
		return
	for child in content.get_children():
		child.queue_free()


func add_section(text: String, color: Color = GameUI.GOLD) -> void:
	var label := GameUI.label(text, 14, color)
	content.add_child(label)


func add_body_text(text: String, color: Color = GameUI.MUTED, size: int = 15) -> void:
	var label := GameUI.label(text, size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(label)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close_panel()
		get_viewport().set_input_as_handled()
