class_name ControlLayoutEditor
extends CanvasLayer
signal closed
var _root: Control
var _handles: Dictionary = {}
var _selected := "attack"
var _size_slider: HSlider
var _label: Label
var _hud: GameHUD
var _sea := false

func _ready() -> void:
	layer = 380
	_hud = get_tree().get_first_node_in_group("hud") as GameHUD
	var game := get_tree().get_first_node_in_group("game") as Game
	_sea = is_instance_valid(game) and game.world is OceanJourney
	if not is_instance_valid(_hud): queue_free(); return
	_hud.release_world_controls()
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var backdrop := ColorRect.new()
	backdrop.color = Color("#17353f")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(backdrop)
	var caption := GameUI.label("DRAG CONTROLS · Select a button, drag anywhere, adjust its size, then Done.", 18, GameUI.TEXT)
	caption.position = Vector2(24, 20)
	_root.add_child(caption)
	var toolbar := GameUI.panel(Color("#10252f"), GameUI.GOLD)
	toolbar.position = Vector2(24, 65)
	toolbar.custom_minimum_size = Vector2(330, 160)
	_root.add_child(toolbar)
	var box := VBoxContainer.new()
	toolbar.add_child(box)
	_label = GameUI.label("", 16, GameUI.GOLD)
	box.add_child(_label)
	_size_slider = HSlider.new()
	_size_slider.min_value = 44
	_size_slider.max_value = 260
	_size_slider.step = 2
	_size_slider.custom_minimum_size = Vector2(300, 35)
	_size_slider.value_changed.connect(_resize_selected)
	box.add_child(_size_slider)
	var actions := HBoxContainer.new()
	box.add_child(actions)
	var reset := GameUI.button("Reset", Vector2(92, 42))
	reset.pressed.connect(func() -> void:
		_hud.reset_control_layout()
		_build_handles())
	actions.add_child(reset)
	var switch_mode := GameUI.button("Village" if _sea else "Sea", Vector2(92, 42))
	switch_mode.pressed.connect(func() -> void:
		_sea = not _sea
		switch_mode.text = "Village" if _sea else "Sea"
		_build_handles())
	actions.add_child(switch_mode)
	var done := GameUI.button("Done", Vector2(92, 42))
	done.pressed.connect(func() -> void:
		_commit_all()
		closed.emit()
		queue_free())
	actions.add_child(done)
	_build_handles()

func _build_handles() -> void:
	for handle in _handles.values():
		_root.remove_child(handle)
		handle.queue_free()
	_handles.clear()
	var layout := _hud.get_control_layout_current()
	var ids := ["ocean_joystick", "ocean_pickup", "ocean_eat"] if _sea else ["joystick", "attack", "interact", "inventory", "menu"]
	for id in ids:
		var values: Dictionary = layout.get(id, {})
		var handle := DragHandle.new()
		handle.editor = self
		handle.control_id = id
		handle.label = str(id).replace("ocean_", "").replace("_", " ").capitalize()
		var extent := float(values.get("size", 90))
		if not _sea and _hud._control_nodes.has(id):
			var real := _hud._control_nodes[id] as Control
			values = {"x": real.position.x, "y": real.position.y}
			extent = real.size.x * real.scale.x
		handle.size = Vector2.ONE * extent
		handle.position = Vector2(float(values.get("x", 24)), float(values.get("y", 400)))
		_root.add_child(handle)
		_handles[id] = handle
		move_handle(id, handle.position)
	_select(str(ids[0]))

func _select(id: String) -> void:
	_selected = id
	var handle := _handles[id] as DragHandle
	_size_slider.set_value_no_signal(handle.size.x)
	_label.text = "%s · %d px" % [handle.label, roundi(handle.size.x)]
	for other in _handles.values():
		other.selected = other == handle
		other.queue_redraw()

func move_handle(id: String, at: Vector2) -> void:
	var handle := _handles[id] as Control
	handle.position = at.clamp(Vector2(6, 6), (_root.get_viewport_rect().size - handle.size - Vector2(6, 6)).max(Vector2(6, 6)))

func _resize_selected(value: float) -> void:
	if not _handles.has(_selected): return
	var handle := _handles[_selected] as DragHandle
	handle.size = Vector2.ONE * value
	move_handle(_selected, handle.position)
	_label.text = "%s · %d px" % [handle.label, roundi(value)]
	handle.queue_redraw()

func _commit_all() -> void:
	for id in _handles:
		var handle := _handles[id] as Control
		var factor := 1.0 if str(id).begins_with("ocean_") else _hud.get_gui_scale() * minf(1.0, minf(_root.size.x / 1280.0, _root.size.y / 720.0))
		_hud.set_control_layout(id, handle.position.x, handle.position.y, handle.size.x / maxf(factor, 0.1))

class DragHandle extends Control:
	var editor: ControlLayoutEditor
	var control_id := ""
	var label := ""
	var selected := false
	var dragging := false
	var pointer := -2
	var offset := Vector2.ZERO
	func _gui_input(event: InputEvent) -> void:
		var press := false
		var release := false
		var move := false
		var at := Vector2.ZERO
		var index := -1
		if event is InputEventScreenTouch:
			press = event.pressed
			release = not event.pressed
			at = event.position
			index = event.index
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			press = event.pressed
			release = not event.pressed
			at = event.position
		elif event is InputEventScreenDrag:
			move = true
			at = event.position
			index = event.index
		elif event is InputEventMouseMotion:
			move = true
			at = event.position
		if press and not dragging:
			editor._select(control_id)
			dragging = true
			pointer = index
			offset = at
		if move and dragging and pointer == index:
			editor.move_handle(control_id, position + at - offset)
		if release and dragging and pointer == index:
			dragging = false
		accept_event()
	func _draw() -> void:
		var radius := size.x * 0.5 - 3
		draw_circle(size / 2, radius, Color("#395b65"))
		draw_arc(size / 2, radius, 0, TAU, 40, GameUI.GOLD if selected else GameUI.TEAL, 3)
		draw_string(ThemeDB.fallback_font, Vector2(4, size.y / 2 + 5), label, HORIZONTAL_ALIGNMENT_CENTER, size.x - 8, 13, GameUI.TEXT)
