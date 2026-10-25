class_name HousePanel
extends ModalBase
## Cottage upgrade NPC. Diamonds are the only accepted currency. The preview,
## cost and recovery change are shown before a separate Confirm action.

var _band: ShopScene
var _preview_level := 1
var _structure_id := "cottage"
var _message := ""
var _gun_house := "cottage"


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
	_structure_id = "cottage"
	_message = ""
	_preview_level = mini(GameState.house_level() + 1, HouseDB.max_level())
	open_panel("Bram's Construction Shop")
	if _band != null:
		_band.keeper_say(ShopLinesDB.line("house", "greeting"))


func _rebuild() -> void:
	_clear_content()
	_band = ShopScene.new()
	_band.setup("house", "Bram")
	content.add_child(_band)
	add_body_text("Orange builders repair damaged buildings by day. Work takes 10 seconds after arrival. Hire extra builders at the Worker Shop.", GameUI.TEAL, 15)
	if not _message.is_empty():
		add_body_text(_message, GameUI.GOLD, 14)
	_add_roof_gun_shop()
	_structure_id = "cottage"
	content.add_child(GameUI.spacer(2))
	var level := GameState.structure_level(_structure_id)
	var current := HouseDB.get_level(level)
	var next := HouseDB.next_level(level)
	add_body_text("Main house / village - level %d of %d  •  Diamonds %d" % [level, HouseDB.max_level(), GameState.diamonds()], GameUI.GOLD, 17)
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
	add_body_text("One upgrade improves the whole village: houses, purchased rooftop machine guns, fences and worker baseline. Extra workers can still be hired.", GameUI.MUTED, 13)
	if next.is_empty():
		add_section("THE LANTERN HOUSE IS COMPLETE", GameUI.GOLD)
		add_body_text(("Your main house restores full health in %.0f seconds." % float(current.recovery)) if _structure_id == "cottage" else "All purchased rooftop machine guns and stone fences are at maximum level.", GameUI.TEXT, 16)
		return
	add_section("UPGRADE BENEFITS", GameUI.GOLD)
	add_body_text(str(next.benefit), GameUI.TEXT, 15)
	add_body_text(str(next.description), GameUI.MUTED, 13)
	var recovery_row := HBoxContainer.new()
	recovery_row.add_theme_constant_override("separation", 28)
	recovery_row.add_child(GameUI.label("Home recovery" if _structure_id == "cottage" else "Rooftop gun", 14, GameUI.MUTED))
	recovery_row.add_child(GameUI.label(("%.0fs  →  %.0fs" % [float(current.recovery), float(next.recovery)]) if _structure_id == "cottage" else ("%.2fs / shot" % float(HouseDefense.INTERVALS[level])), 17, GameUI.TEAL))
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
	confirm.disabled = GameState.diamonds() < int(next.cost) or int(GameState.structure_state(_structure_id).get("health", 0)) <= 0
	confirm.pressed.connect(func() -> void:
		var result := GameState.upgrade_structure(_structure_id)
		_message = str(result.get("message", ""))
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
	var rec := GameUI.label("Machine gun: %.2fs / shot" % float(HouseDefense.INTERVALS[level - 1]), 13, GameUI.TEAL)
	rec.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(rec)
	var linked := HBoxContainer.new()
	linked.alignment = BoxContainer.ALIGNMENT_CENTER
	for texture in [PixelArt.roof_gun_texture(level), PixelArt.fence_texture(level)]:
		var picture := TextureRect.new()
		picture.texture = texture
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.custom_minimum_size = Vector2(90, 90)
		linked.add_child(picture)
	box.add_child(linked)
	box.add_child(GameUI.label("%d × each worker type" % level, 14, GameUI.GOLD))
	return card


func _select_preview(level: int) -> void:
	_preview_level = clampi(level, 1, HouseDB.max_level())
	_rebuild()


func _add_house_picker() -> void:
	var houses := OptionButton.new()
	houses.custom_minimum_size = Vector2(400, 42)
	var structures: Dictionary = GameState.data.get("structures", {})
	for id in structures:
		var entry := GameState.structure_state(str(id))
		if str(entry.get("kind", "")) != "house":
			continue
		var index := houses.item_count
		houses.add_item("%s - Level %d%s" % [entry.get("name", id), GameState.structure_level(str(id)), " (repair needed)" if int(entry.get("health", 0)) <= 0 else ""])
		houses.set_item_metadata(index, str(id))
		if str(id) == _structure_id:
			houses.select(index)
	houses.item_selected.connect(func(index: int) -> void:
		_structure_id = str(houses.get_item_metadata(index))
		_preview_level = mini(GameState.structure_level(_structure_id) + 1, 5)
		_message = ""
		_rebuild())
	content.add_child(houses)


func _add_roof_gun_shop() -> void:
	add_section("ROOFTOP MACHINE GUNS", GameUI.GOLD)
	add_body_text("Buy one for each house. Guns target fire monsters and sea urchins; house upgrades improve their fire rate.", GameUI.MUTED, 13)
	var picker := OptionButton.new()
	picker.custom_minimum_size = Vector2(0, 42)
	var structures: Dictionary = GameState.data.get("structures", {})
	for id in structures:
		var entry := GameState.structure_state(str(id))
		if str(entry.get("kind", "")) != "house":
			continue
		var index := picker.item_count
		picker.add_item("%s%s" % [entry.get("name", "House"), " - Installed" if GameState.has_roof_gun(str(id)) else ""])
		picker.set_item_metadata(index, str(id))
		if str(id) == _gun_house:
			picker.select(index)
	picker.item_selected.connect(func(index: int) -> void:
		_gun_house = str(picker.get_item_metadata(index))
		_rebuild())
	content.add_child(picker)
	var installed := GameState.has_roof_gun(_gun_house)
	var button := GameUI.button("Machine gun installed" if installed else ("Buy rooftop machine gun - %d gold" % GameState.roof_gun_cost()), Vector2(0, 44))
	button.disabled = installed or GameState.gold() < GameState.roof_gun_cost() or int(GameState.structure_state(_gun_house).get("health", 0)) <= 0
	button.pressed.connect(_buy_roof_gun.bind(_gun_house))
	content.add_child(button)

func _buy_roof_gun(id: String) -> void:
	var result := GameState.buy_roof_gun(id)
	_message = str(result.get("message", ""))
	Sfx.play("equip" if bool(result.get("ok", false)) else "deny", -10.0)
	_rebuild()
