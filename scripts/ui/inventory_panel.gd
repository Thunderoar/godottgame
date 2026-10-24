class_name InventoryPanel
extends ModalBase
## Backpack, equipment and companion overview. All values read from GameState.

func _ready() -> void:
	_panel_size = Vector2(900, 650)
	super._ready()
	GameState.data_changed.connect(func() -> void:
		if visible:
			_rebuild())


func open_inventory() -> void:
	open_panel("Backpack & Equipment")


func _rebuild() -> void:
	_clear_content()
	add_body_text("Level %d     XP %d/%d" % [int(GameState.data.level), int(GameState.data.xp), int(GameState.data.xp_next)], GameUI.TEAL, 17)
	content.add_child(GameUI.spacer(2))
	# Equipment cards.
	add_section("EQUIPPED")
	var equip_row := HBoxContainer.new()
	equip_row.add_theme_constant_override("separation", 10)
	content.add_child(equip_row)
	for slot in ["weapon", "armor", "shield"]:
		var id := GameState.equipped_item(slot)
		var card := GameUI.panel(Color("#14262c"), Color("#30494e"))
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var box := VBoxContainer.new()
		card.add_child(box)
		box.add_child(GameUI.label(slot.capitalize(), 12, GameUI.MUTED))
		box.add_child(GameUI.label(ItemDB.name_of(id) if id != "" else "Empty", 15, GameUI.TEXT))
		if id != "":
			box.add_child(GameUI.label(ItemDB.stat_line(id), 12, GameUI.GREEN))
		equip_row.add_child(card)
	var stat_card := GameUI.panel(Color("#14262c"), Color("#30494e"))
	stat_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var stat_box := VBoxContainer.new()
	stat_card.add_child(stat_box)
	stat_box.add_child(GameUI.label("POWER", 12, GameUI.MUTED))
	stat_box.add_child(GameUI.label("ATK %d   DEF %d" % [GameState.attack_power(), GameState.defense()], 15, GameUI.GOLD))
	equip_row.add_child(stat_card)

	add_section("BAG")
	var any := false
	for item_id in (GameState.data.get("inventory", {}) as Dictionary):
		var count := GameState.item_count(str(item_id))
		if count <= 0:
			continue
		any = true
		var item := ItemDB.get_item(str(item_id))
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", GameUI.style(Color("#162a30"), Color("#324b50"), 1, 0))
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)
		row.add_child(hbox)
		hbox.add_child(GameUI.icon_rect(_icon_kind(str(item_id)), 30))
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(info)
		info.add_child(GameUI.label("%s  x%d" % [str(item.get("name", item_id)), count], 16))
		var stat := ItemDB.stat_line(str(item_id))
		if stat != "":
			info.add_child(GameUI.label(stat, 12, GameUI.GREEN))
		var actions := HBoxContainer.new()
		actions.add_theme_constant_override("separation", 8)
		hbox.add_child(actions)
		if ItemDB.is_equipment(str(item_id)):
			var equipped := GameState.equipped_item(str(item.get("slot", ""))) == str(item_id)
			var equip := GameUI.button("Equipped" if equipped else "Equip", Vector2(104, 34))
			equip.disabled = equipped
			equip.pressed.connect(func() -> void:
				var result := GameState.equip_item(str(item_id))
				if not result.ok:
					GameState.toast_requested.emit(str(result.message), "bad"))
			actions.add_child(equip)
		elif item.has("effect"):
			var use := GameUI.button("Use", Vector2(104, 34))
			use.pressed.connect(func() -> void:
				var result := GameState.consume_item(str(item_id))
				if not result.ok:
					GameState.toast_requested.emit(str(result.message), "bad"))
			actions.add_child(use)
		content.add_child(row)
	if not any:
		add_body_text("Your pack is empty.", GameUI.MUTED, 15)

	add_section("COMPANION")
	var pet := GameState.get_active_pet()
	if pet.is_empty():
		add_body_text("No companion.", GameUI.RED, 15)
	else:
		var pet_def := PetDB.get_pet(str(pet.id))
		var pet_row := PanelContainer.new()
		pet_row.add_theme_stylebox_override("panel", GameUI.style(Color("#14262c"), Color("#30494e"), 1, 0))
		var pet_h := HBoxContainer.new()
		pet_h.add_theme_constant_override("separation", 14)
		pet_row.add_child(pet_h)
		var preview := TextureRect.new()
		preview.texture = PixelArt.pet_texture(str(pet.id))
		preview.custom_minimum_size = Vector2(60, 60)
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pet_h.add_child(preview)
		var pet_info := VBoxContainer.new()
		pet_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pet_h.add_child(pet_info)
		pet_info.add_child(GameUI.label("%s  •  Lv %d  •  %s" % [pet_def.name, int(pet.level), "Alive" if bool(pet.alive) else "Fallen"], 16, GameUI.TEXT if bool(pet.alive) else GameUI.RED))
		pet_info.add_child(GameUI.label("HP %d/%d    Heal %d / Atk %d / Shield %d" % [int(pet.hp), int(pet.hp_max), PetDB.heal_amount(str(pet.id), int(pet.level)), PetDB.attack_damage(str(pet.id), int(pet.level)), PetDB.shield_amount(str(pet.id), int(pet.level))], 13, GameUI.MUTED))
		pet_info.add_child(GameUI.label("Pets support you with healing, attacks and shields. They recover automatically.", 12, GameUI.MUTED))
		content.add_child(pet_row)
	if GameState.expedition_active():
		add_section("EXPEDITION", GameUI.PURPLE)
		add_body_text(GameState.expedition_loot_summary(), GameUI.GOLD, 15)
		add_body_text("Loot is banked only when you return through the Shore Gate or defeat the boss.", GameUI.MUTED, 13)


func _icon_kind(item_id: String) -> String:
	if item_id == "health_potion":
		return "health_potion"
	if item_id == "mana_potion":
		return "mana_potion"
	if item_id == "pet_food":
		return "food"
	var item := ItemDB.get_item(item_id)
	match str(item.get("kind", "")):
		"weapon":
			return str(item.get("style", "sword"))
		"armor":
			return "armor"
		"shield":
			return "shield"
		"material":
			return "wood"
	return "spark"
