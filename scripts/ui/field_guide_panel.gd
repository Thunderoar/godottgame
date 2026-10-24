class_name FieldGuidePanel
extends ModalBase
var _category := 0
var _page := 0

func _ready() -> void:
	_panel_size = Vector2(1000, 660)
	super._ready()

func open_book() -> void:
	open_panel("Buku BESUT")

func _rebuild() -> void:
	_clear_content()
	var tabs := HBoxContainer.new()
	for i in 3:
		var button := GameUI.button(["NPC", "Monster", "Boss"][i], Vector2(130, 44))
		button.toggle_mode = true
		button.button_pressed = _category == i
		button.pressed.connect(func() -> void:
			_category = i
			_page = 0
			_rebuild())
		tabs.add_child(button)
	content.add_child(tabs)
	var entries := FieldGuideDB.entries(_category)
	_page = clampi(_page, 0, entries.size() - 1)
	var entry: Dictionary = entries[_page]
	var name_label := GameUI.label(str(entry.get("name", "")), 23, GameUI.GOLD)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(name_label)
	var illustration := GuideIllustration.new()
	illustration.entry = entry
	illustration.custom_minimum_size.y = clampf(get_viewport_rect().size.y - 300, 180, 320)
	content.add_child(illustration)
	var navigation := HBoxContainer.new()
	navigation.alignment = BoxContainer.ALIGNMENT_CENTER
	var previous := GameUI.button("‹", Vector2(75, 44))
	previous.disabled = _page == 0
	previous.pressed.connect(_turn.bind(-1))
	navigation.add_child(previous)
	var count := GameUI.label("%d / %d" % [_page + 1, entries.size()], 18, GameUI.TEXT)
	count.custom_minimum_size.x = 110
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	navigation.add_child(count)
	var next := GameUI.button("›", Vector2(75, 44))
	next.disabled = _page == entries.size() - 1
	next.pressed.connect(_turn.bind(1))
	navigation.add_child(next)
	content.add_child(navigation)

func _turn(direction: int) -> void:
	_page = clampi(_page + direction, 0, FieldGuideDB.entries(_category).size() - 1)
	_rebuild()
