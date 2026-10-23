class_name HousePanel
extends ModalBase
## Cottage upgrade NPC. Diamonds are the only accepted currency. The preview,
## cost and recovery change are shown before a separate Confirm action.

var _band: ShopScene
var _preview_level := 1


func _ready() -> void:
	_panel_size = Vector2(940, 700)
	super._ready()
	GameState.data_changed.connect(func() -> void:
		if visible:
			_rebuild())
	GameState.house_changed.connect(func(_level: int) -> void:
		if visible:
			_rebuild())


func open_house() -> void:
	_preview_level = mini(GameState.house_level() + 1, HouseDB.max_level())
	open_panel("Bram's Construction Shop")
	if _band != null:
		_band.keeper_say(ShopLinesDB.line("house", "greeting"))


func _rebuild() -> void:
	_clear_content()
	_band = ShopScene.new()
	_band.setup("house", "Bram")
	content.add_child(_band)
	add_body_text("Repairs are free: approach a damaged house or fence and press E / Use (Betulkan). It is restored immediately.", GameUI.TEAL, 15)
	content.add_child(GameUI.spacer(2))
	var level := GameState.house_level()
	var current := HouseDB.get_level(level)
	var next := HouseDB.next_level(level)
	add_body_text("Construction Shop  •  Cottage level %d of %d  •  Diamonds %d" % [level, HouseDB.max_level(), GameState.diamonds()], GameUI.GOLD, 17)
	var progression := HBoxContainer.new()
	progression.add_theme_constant_override("separation", 6)
	for step in range(1, HouseDB.max_level() + 1):
		var color := GameUI.GOLD if step == level else (GameUI.GREEN if step < level else GameUI.BORDER_LIGHT)
		var choose := GameUI.button("LEVEL %d" % step, Vector2(108, 38))
		choose.add_theme_color_override("font_color", color)
		choose.toggle_mode = true
		choose.button_pressed = step == _preview_level
		choose.set_meta("house_preview_level", step)
		choose.pressed.connect(_select_preview.bind(step))
		progression.add_child(choose)
	content.add_child(progression)
	content.add_child(GameUI.spacer(2))
	var previews := HBoxContainer.new()
	previews.add_theme_constant_override("separation", 20)
	content.add_child(previews)
	previews.add_child(_preview_card(current, "CURRENT", level, true))
	var selected := HouseDB.get_level(_preview_level)
	previews.add_child(_preview_card(selected, "PREVIEW - LEVEL %d" % _preview_level, _preview_level, false))
	add_body_text("%s: %s" % [selected.get("name", "Cottage"), selected.get("description", "")], GameUI.TEXT, 14)
	add_body_text("Tap any level to see its design. Confirm Upgrade purchases only your next level.", GameUI.MUTED, 13)
	if next.is_empty():
		add_section("THE LANTERN HOUSE IS COMPLETE", GameUI.GOLD)
		add_body_text("Your cottage is the finest on the coast. Full health now returns in %.0f seconds." % float(current.recovery), GameUI.TEXT, 16)
		return
	add_section("UPGRADE BENEFITS", GameUI.GOLD)
	add_body_text(str(next.benefit), GameUI.TEXT, 15)
	add_body_text(str(next.description), GameUI.MUTED, 13)
	var recovery_row := HBoxContainer.new()
	recovery_row.add_theme_constant_override("separation", 28)
	recovery_row.add_child(GameUI.label("Sleep recovery", 14, GameUI.MUTED))
	recovery_row.add_child(GameUI.label("%.0fs  →  %.0fs" % [float(current.recovery), float(next.recovery)], 17, GameUI.TEAL))
	content.add_child(recovery_row)
	content.add_child(GameUI.divider(Color("#30474c")))
	var cost_row := HBoxContainer.new()
	cost_row.add_theme_constant_override("separation", 16)
	cost_row.add_child(GameUI.icon_rect("diamond", 30))
	cost_row.add_child(GameUI.label("%d diamonds" % int(next.cost), 22, GameUI.DIAMOND))
	cost_row.add_child(GameUI.label("Grounds and appearance change at every level.", 13, GameUI.MUTED))
	cost_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(cost_row)
	var confirm := GameUI.button("Confirm Upgrade  •  %d Diamonds" % int(next.cost), Vector2(400, 52))
	confirm.disabled = GameState.diamonds() < int(next.cost)
	confirm.pressed.connect(func() -> void:
		var result := GameState.upgrade_house()
		if result.ok:
			Sfx.play("equip", -8.0)
			if _band != null and is_instance_valid(_band):
				_band.keeper_say(ShopLinesDB.line("house", "buy"), "check")
		else:
			Sfx.play("deny", -10.0)
			if _band != null and is_instance_valid(_band):
				_band.keeper_say(ShopLinesDB.line("house", "deny"), "close"))
	content.add_child(confirm)
	if GameState.diamonds() < int(next.cost):
		add_body_text("You need %d more diamonds. Bosses and dungeon gems are the surest source." % (int(next.cost) - GameState.diamonds()), GameUI.RED, 13)


func _preview_card(data: Dictionary, tag: String, level: int, is_current: bool) -> Control:
	var card := GameUI.panel(Color("#14262c"), Color("#4c6c70") if is_current else Color("#8a7440"))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)
	var tag_label := GameUI.label(tag, 12, GameUI.MUTED if is_current else GameUI.GOLD)
	tag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(tag_label)
	var preview := TextureRect.new()
	preview.texture = PixelArt.house_texture(level)
	preview.custom_minimum_size = Vector2(280, 170)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preview.modulate = Color.WHITE if not is_current else Color(0.82, 0.88, 0.88)
	box.add_child(preview)
	var name_label := GameUI.label(str(data.get("name", "Cottage")), 17, GameUI.TEXT)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(name_label)
	var rec := GameUI.label("Full health in %.0fs" % float(data.get("recovery", 10.0)), 13, GameUI.TEAL)
	rec.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(rec)
	return card


func _select_preview(level: int) -> void:
	_preview_level = clampi(level, 1, HouseDB.max_level())
	_rebuild()
