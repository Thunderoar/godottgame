class_name ObjectiveTracker
extends PanelContainer
## Non-modal objective accordion. Only its visible rectangle receives pointer input.

const BODY_FONT := 14
var _header: Button
var _summary: Label
var _scroll: ScrollContainer
var _rows: VBoxContainer
var _box: VBoxContainer
var _entries: Array[Dictionary] = []
var _cards: Array[Dictionary] = []
var _height_limit := 320.0
var _compact := false
var _touch_id := -1

func _ready() -> void:
	name = "ObjectiveTracker"
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override("panel", GameUI.style(Color(0.035, 0.08, 0.09, 0.94), GameUI.BORDER, 1, 0))
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 8)
	add_child(_box)
	_header = GameUI.button("", Vector2(0, 44))
	_header.name = "ToggleObjectives"
	_header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_header.focus_mode = Control.FOCUS_ALL
	_header.add_theme_font_size_override("font_size", 15)
	_header.add_theme_stylebox_override("focus", GameUI.style(Color.TRANSPARENT, GameUI.TEAL, 2))
	_header.pressed.connect(func() -> void:
		GameSettings.set_value("objectives_collapsed", not collapsed()))
	_header.gui_input.connect(_on_header_input)
	_box.add_child(_header)
	_summary = GameUI.label("", BODY_FONT, GameUI.TEXT)
	_summary.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_summary.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(_summary)
	_scroll = ScrollContainer.new()
	_scroll.name = "ObjectiveScroll"
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	_box.add_child(_scroll)
	var scrollbar := _scroll.get_v_scroll_bar()
	scrollbar.custom_minimum_size.x = 5
	for style_name in ["scroll", "grabber", "grabber_highlight", "grabber_pressed"]:
		var style := GameUI.style(Color("#33534f") if style_name == "scroll" else GameUI.TEAL.darkened(0.25), Color.TRANSPARENT, 0)
		for edge in ["left", "right", "top", "bottom"]: style.set("content_margin_" + edge, 0)
		scrollbar.add_theme_stylebox_override(style_name, style)
	_rows = VBoxContainer.new()
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override("separation", 12)
	_scroll.add_child(_rows)
	_rows.minimum_size_changed.connect(_fit_body)
	GameSettings.changed.connect(_on_setting_changed)
	visibility_changed.connect(func() -> void:
		if not is_visible_in_tree(): _touch_id = -1)
	_sync_expansion()
	hide()

func collapsed() -> bool:
	return bool(GameSettings.get_value("objectives_collapsed"))

func set_entries(entries: Array[Dictionary]) -> void:
	if _entries == entries: return
	var old_ids: Array = _entries.map(func(row: Dictionary) -> String: return str(row.id))
	var new_ids: Array = entries.map(func(row: Dictionary) -> String: return str(row.id))
	_entries = entries.duplicate(true)
	if old_ids != new_ids:
		for child in _rows.get_children():
			_rows.remove_child(child)
			child.queue_free()
		_cards.clear()
		_scroll.scroll_vertical = 0
		for entry in _entries:
			var card := VBoxContainer.new()
			card.add_theme_constant_override("separation", 3)
			card.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_rows.add_child(card)
			var tag := _label("", 11, GameUI.TEAL, card)
			var title := _label("", 17, GameUI.TEXT, card)
			var detail := _label("", BODY_FONT, GameUI.MUTED, card)
			var bar := ProgressBar.new()
			bar.custom_minimum_size.y = 5
			bar.max_value = 1.0
			bar.show_percentage = false
			bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.add_child(bar)
			_cards.append({"tag": tag, "title": title, "detail": detail, "bar": bar})
	for i in _entries.size():
		var entry: Dictionary = _entries[i]
		var card: Dictionary = _cards[i]
		var pct := float(entry.get("progress", -1.0))
		card.tag.text = str(entry.tag) + ("  ·  %d%%" % roundi(pct * 100.0) if pct >= 0 else "")
		card.tag.add_theme_color_override("font_color", GameUI.RED.lightened(0.3) if bool(entry.get("urgent", false)) else GameUI.TEAL)
		card.title.text = str(entry.title)
		card.detail.text = str(entry.detail)
		card.bar.visible = pct >= 0
		card.bar.value = maxf(0, pct)
	_summary.text = str(_entries[0].title) if not _entries.is_empty() else "No active objectives"
	_summary.tooltip_text = str(_entries[0].detail) if not _entries.is_empty() else ""
	_summary.add_theme_color_override("font_color", GameUI.RED.lightened(0.3) if not _entries.is_empty() and bool(_entries[0].get("urgent", false)) else GameUI.TEXT)
	_sync_expansion()

func _label(text: String, font_size: int, color: Color, parent: Control) -> Label:
	var label := GameUI.label(text, font_size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func fit(width: float, height: float, zoom: float, display_scale: float) -> void:
	scale = Vector2.ONE * zoom
	_height_limit = height / zoom
	size.x = width / zoom
	_header.custom_minimum_size.y = maxf(40.0, 44.0 / maxf(0.1, zoom * display_scale))
	_compact = _height_limit < _header.custom_minimum_size.y + 100.0
	_sync_expansion()
	call_deferred("_fit_body")

func _sync_expansion() -> void:
	if not is_instance_valid(_header): return
	_header.text = "OBJECTIVES  %s" % ("+" if collapsed() else "−")
	_header.tooltip_text = "Expand objectives" if collapsed() else "Collapse objectives"
	_summary.visible = collapsed() or _compact
	_scroll.visible = not collapsed() and not _compact
	_fit_body()

func _fit_body() -> void:
	if not is_instance_valid(_rows): return
	var chrome := _header.get_combined_minimum_size().y + 24.0
	var height := minf(_rows.get_combined_minimum_size().y, maxf(1, _height_limit - chrome))
	if not is_equal_approx(_scroll.custom_minimum_size.y, height):
		_scroll.custom_minimum_size.y = height
	size.y = 0 # Allow the container to shrink after a goal completes or collapses.

func _on_setting_changed(key: String) -> void:
	if key == "objectives_collapsed": _sync_expansion()

func _on_header_input(event: InputEvent) -> void:
	# Handle raw touches as well as mouse/keyboard, including a second finger
	# while the joystick is held. BaseButton mouse emulation only covers finger 0.
	if event is InputEventScreenTouch and event.pressed and _touch_id < 0:
		_touch_id = event.index
		_header.accept_event()

func _input(event: InputEvent) -> void:
	if not is_instance_valid(_header): return
	if event is InputEventMouseButton and event.device == InputEvent.DEVICE_ID_EMULATION and is_visible_in_tree():
		var local: Vector2 = _header.get_global_transform().affine_inverse() * event.position
		if Rect2(Vector2.ZERO, _header.size).has_point(local):
			get_viewport().set_input_as_handled()
	if event is InputEventScreenTouch and not event.pressed and event.index == _touch_id:
		_touch_id = -1
		var local: Vector2 = _header.get_global_transform().affine_inverse() * event.position
		if is_visible_in_tree() and Rect2(Vector2.ZERO, _header.size).has_point(local):
			_header.pressed.emit()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT: _touch_id = -1
