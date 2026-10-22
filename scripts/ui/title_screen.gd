class_name TitleScreen
extends Control
## Title, credits, Continue and the three-hero CHOOSE YOUR ROAD menu.
## The screen uses containers so it stays readable on small landscape windows.

signal character_selected(character_id: String)
signal continue_requested

var save_available := false
var _time := 0.0
var _margin: MarginContainer
var _title_label: Label
var _kicker: Label
var _credit: Label
var _blurb: Label
var _hint: Label
var _choose_header: Label
var _continue_button: Button
var _cards: HBoxContainer
var _card_descriptions: Array[Label] = []
var _card_stats: Array[Label] = []
var _card_portraits: Array[TextureRect] = []
var _footer: Label
var _compact := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = GameUI.theme()
	set_process(true)
	_build()
	resized.connect(_layout)
	call_deferred("_layout")


func _build() -> void:
	_margin = MarginContainer.new()
	_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_margin.add_theme_constant_override("margin_left", 38)
	_margin.add_theme_constant_override("margin_right", 38)
	_margin.add_theme_constant_override("margin_top", 28)
	_margin.add_theme_constant_override("margin_bottom", 18)
	add_child(_margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	_margin.add_child(column)

	_kicker = GameUI.label("A SEASIDE SURVIVAL TALE", 13, GameUI.TEAL)
	column.add_child(_kicker)
	_title_label = GameUI.title("SAVE THE WORLD", 58, GameUI.TEXT)
	_title_label.add_theme_constant_override("outline_size", 4)
	_title_label.add_theme_color_override("font_outline_color", Color(0.03, 0.07, 0.08, 0.9))
	column.add_child(_title_label)
	_credit = GameUI.label("Created by Qayyim, Farhan and Ayiz", 16, GameUI.GOLD)
	column.add_child(_credit)
	_blurb = GameUI.label("Keep the cottage. Raise a companion. Shop, build and defend the settlement from what comes from the sea and the forest.", 15, Color("#d9e6d8"))
	_blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_blurb)
	_continue_button = GameUI.button("Continue", Vector2(230, 44))
	_continue_button.disabled = not save_available
	_continue_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_continue_button.pressed.connect(func() -> void: continue_requested.emit())
	column.add_child(_continue_button)
	_hint = GameUI.label("Keyboard: WASD move, F attack, E interact, B build.   Touch: joystick left, actions right, Pack and Build top-left.", 12, GameUI.MUTED)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_hint)

	_choose_header = GameUI.label("CHOOSE YOUR ROAD", 20, GameUI.GOLD)
	_choose_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_choose_header)

	_cards = HBoxContainer.new()
	_cards.add_theme_constant_override("separation", 12)
	_cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_cards)
	for character in CharacterDB.CHARACTERS:
		_cards.add_child(_character_card(character))

	_footer = GameUI.label("Permanent daytime  •  mobile touch HUD  •  ten-portal campaign  •  village defence", 11, Color(0.86, 0.9, 0.84, 0.72))
	column.add_child(_footer)


func _character_card(character: Dictionary) -> Control:
	var accent: Color = character.accent
	accent = accent.lightened(0.32)
	var card := GameUI.panel(Color(0.035, 0.08, 0.09, 0.91), Color("#4d6a69"))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	card.add_child(box)
	var portrait := TextureRect.new()
	portrait.texture = PixelArt.portrait(str(character.id), 96)
	portrait.custom_minimum_size = Vector2(0, 90)
	portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	box.add_child(portrait)
	_card_portraits.append(portrait)
	box.add_child(GameUI.label(str(character.name), 24, GameUI.TEXT))
	box.add_child(GameUI.label(str(character.title), 12, accent))
	box.add_child(GameUI.label("Weapon: %s" % str(character.weapon), 12, GameUI.TEAL))
	var desc := GameUI.label(str(character.description), 12, GameUI.MUTED)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(desc)
	_card_descriptions.append(desc)
	var stats := GameUI.label("HP %d  MP %d\nATK %d  DEF %d  SPD %.1f" % [int(character.hp), int(character.mana), int(character.attack), int(character.defense), float(character.speed)], 12, GameUI.TEAL)
	box.add_child(stats)
	_card_stats.append(stats)
	var choose := GameUI.button("Choose %s" % str(character.name), Vector2(0, 38))
	choose.pressed.connect(func() -> void: character_selected.emit(str(character.id)))
	box.add_child(choose)
	return card


func _layout() -> void:
	var w := size.x
	var h := size.y
	_compact = w < 1100.0 or h < 650.0
	var margin := 20 if _compact else 38
	_margin.add_theme_constant_override("margin_left", margin)
	_margin.add_theme_constant_override("margin_right", margin)
	_margin.add_theme_constant_override("margin_top", 18 if _compact else 28)
	_margin.add_theme_constant_override("margin_bottom", 12 if _compact else 18)
	_title_label.add_theme_font_size_override("font_size", 42 if _compact else 58)
	_credit.add_theme_font_size_override("font_size", 13 if _compact else 16)
	_blurb.visible = not _compact
	_hint.visible = not _compact
	_footer.visible = not _compact
	_choose_header.add_theme_font_size_override("font_size", 17 if _compact else 20)
	_continue_button.custom_minimum_size = Vector2(190 if _compact else 230, 36 if _compact else 44)
	for i in _card_portraits.size():
		_card_portraits[i].custom_minimum_size = Vector2(0, 52 if _compact else 112)
	for desc in _card_descriptions:
		desc.visible = not _compact
	for stats in _card_stats:
		stats.add_theme_font_size_override("font_size", 11 if _compact else 12)
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	for i in 20:
		var t := float(i) / 19.0
		var c := Color("#5da9bb").lerp(Color("#d7dfb3"), t)
		draw_rect(Rect2(0, h * t * 0.50, w, h * 0.028 + 1), c)
	draw_circle(Vector2(w * 0.82, h * 0.16), 45, Color(1.0, 0.93, 0.63, 0.18))
	draw_circle(Vector2(w * 0.82, h * 0.16), 30, Color("#ffe6a1"))
	for p in [Vector2(w * 0.15, h * 0.13), Vector2(w * 0.48, h * 0.08), Vector2(w * 0.68, h * 0.21)]:
		draw_rect(Rect2(p.x, p.y, 78, 10), Color(0.92, 0.95, 0.86, 0.45))
		draw_rect(Rect2(p.x + 16, p.y - 6, 42, 8), Color(0.95, 0.97, 0.9, 0.55))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, h * 0.46), Vector2(w * 0.14, h * 0.36), Vector2(w * 0.29, h * 0.45),
		Vector2(w * 0.45, h * 0.37), Vector2(w * 0.62, h * 0.46), Vector2(w, h * 0.38),
		Vector2(w, h), Vector2(0, h),
	]), Color("#284939"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, h * 0.52), Vector2(w * 0.2, h * 0.45), Vector2(w * 0.4, h * 0.52),
		Vector2(w * 0.6, h * 0.46), Vector2(w, h * 0.51), Vector2(w, h), Vector2(0, h),
	]), Color("#315840"))
	draw_rect(Rect2(0, h * 0.57, w, h * 0.43), Color("#2f6d7b"))
	for i in 15:
		var y := h * 0.59 + float(i) * 17.0
		var offset := sin(_time * 0.5 + float(i)) * 22.0
		draw_line(Vector2(0, y), Vector2(w, y + sin(float(i)) * 3.0), Color(0.52, 0.78, 0.76, 0.16), 2.0)
		for j in 4:
			var x := fmod(float(j) * 340.0 + offset + float(i * 63), w)
			draw_line(Vector2(x, y), Vector2(x + 54, y), Color(0.68, 0.88, 0.83, 0.16), 2.0)
	var base := h * 0.60
	draw_colored_polygon(PackedVector2Array([
		Vector2(w * 0.30, h), Vector2(w * 0.34, base), Vector2(w * 0.48, base - 30),
		Vector2(w * 0.67, base - 18), Vector2(w * 0.82, base - 28), Vector2(w, base - 4),
		Vector2(w, h),
	]), Color("#4c7144"))
	_draw_cottage(Vector2(w * 0.48, base - 12), 0.8)
	_draw_cottage(Vector2(w * 0.60, base - 18), 0.65)
	_draw_cottage(Vector2(w * 0.70, base - 10), 0.55)
	_draw_cottage(Vector2(w * 0.79, base - 20), 0.72)
	var jy := base + 26
	draw_rect(Rect2(w * 0.52, jy, w * 0.28, 5), Color("#8a6138"))
	for px in range(int(w * 0.54), int(w * 0.78), 40):
		draw_rect(Rect2(px, jy - 10, 4, 30), Color("#5b3f27"))
	_draw_boat(Vector2(w * 0.46, jy + 40), 0.55)
	_draw_boat(Vector2(w * 0.83, jy + 62), 0.65)
	draw_rect(Rect2(0, 0, w, h), Color(0.02, 0.05, 0.06, 0.22))
	draw_rect(Rect2(0, 0, w, 3), Color(0, 0, 0, 0.45))
	draw_rect(Rect2(0, h - 3, w, 3), Color(0, 0, 0, 0.45))


func _draw_cottage(pos: Vector2, s: float) -> void:
	var w := 70.0 * s
	var body_h := 46.0 * s
	draw_rect(Rect2(pos.x - w * 0.5, pos.y - body_h, w, body_h), Color("#d6bd8a"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(pos.x - w * 0.62, pos.y - body_h + 2),
		Vector2(pos.x, pos.y - body_h - 28.0 * s),
		Vector2(pos.x + w * 0.62, pos.y - body_h + 2),
	]), Color("#7a4b34"))
	draw_rect(Rect2(pos.x - 6, pos.y - 20 * s, 12, 20 * s), Color("#4b3222"))
	draw_rect(Rect2(pos.x + w * 0.18, pos.y - 32 * s, 10 * s, 10 * s), Color("#ffd67d"))
	draw_rect(Rect2(pos.x - w * 0.38, pos.y - 30 * s, 9 * s, 9 * s), Color("#ffd67d"))


func _draw_boat(pos: Vector2, s: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(pos.x - 45 * s, pos.y), Vector2(pos.x + 45 * s, pos.y),
		Vector2(pos.x + 30 * s, pos.y + 13 * s), Vector2(pos.x - 30 * s, pos.y + 13 * s),
	]), Color("#6e492e"))
	draw_rect(Rect2(pos.x - 2 * s, pos.y - 55 * s, 4 * s, 55 * s), Color("#4b3322"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(pos.x + 2 * s, pos.y - 52 * s), Vector2(pos.x + 38 * s, pos.y - 34 * s),
		Vector2(pos.x + 2 * s, pos.y - 20 * s),
	]), Color("#e7dcc0"))
