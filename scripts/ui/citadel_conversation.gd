class_name CitadelConversation
extends CanvasLayer
## Game-owned, player-paced local dialogue. No progression writes or automatic pages.
signal completed
var mode := "entry"
var pages: Array = []
var page := 0
var accepted := false
var cancelled := false
var _done := false
var _guard := 0.3
var _armed := false
var _focused := true
var _words: Label
var _next: Button
var _skip: Button
var _panel: PanelContainer
var _root: Control

func _ready() -> void:
	layer = 320
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", GameUI.style(Color("#132635f5"), Color("#c5ae78"), 2, 16))
	_root.add_child(_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	_panel.add_child(column)
	column.add_child(GameUI.label("THE ROAD TO CHAOS CITADEL", 16, GameUI.GOLD))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	_words = GameUI.label("", 18, GameUI.TEXT)
	_words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_words)
	var row := HBoxContainer.new()
	column.add_child(row)
	_skip = GameUI.button("Not yet" if mode == "entry" else "Skip", Vector2(132, 48))
	_skip.focus_mode = Control.FOCUS_ALL
	_skip.pressed.connect(_on_skip)
	row.add_child(_skip)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	_next = GameUI.button("", Vector2(186, 48))
	_next.focus_mode = Control.FOCUS_ALL
	_next.pressed.connect(advance)
	row.add_child(_next)
	_root.resized.connect(_fit)
	_fit()
	_show_page()

func _fit() -> void:
	_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_left = 20
	_panel.offset_right = -20
	_panel.offset_top = -minf(258, _root.size.y-48)
	_panel.offset_bottom = -20
	var display_scale := float(get_window().size.y)/maxf(1,get_viewport().get_visible_rect().size.y) if DisplayServer.get_name() != "headless" else 1.0
	_next.custom_minimum_size.y = maxf(48,44/maxf(0.1,display_scale))
	_skip.custom_minimum_size.y = _next.custom_minimum_size.y
	_words.add_theme_font_size_override("font_size",maxi(18,ceili(16/maxf(0.1,display_scale))))

func _show_page() -> void:
	_words.text = str(pages[page])
	_next.text = "Enter the citadel" if mode == "entry" else ("Face the fiend" if mode == "intro" and page == pages.size()-1 else ("Continue" if page < pages.size()-1 else "Return to the road"))
	_armed = false
	_guard = 0.22
	_next.disabled = true
	_skip.disabled = true

func _process(delta: float) -> void:
	if _done or not _focused: return
	_guard -= delta
	if not _armed and _guard <= 0 and not Input.is_anything_pressed():
		_armed = true
		_next.disabled = false
		_skip.disabled = false
		_next.grab_focus()

func advance() -> void:
	if not _armed or not _focused or _done: return
	if page < pages.size()-1:
		page += 1
		_show_page()
	else: finish(true)

func _on_skip() -> void:
	if _armed and _focused: finish(mode != "entry")

func finish(result: bool = true) -> void:
	if _done: return
	_done = true
	accepted = result
	hide()
	completed.emit()
	queue_free()

func cancel() -> void:
	cancelled = true
	finish(false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_focused = false
		_armed = false
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_focused = true
		_guard = 0.25
