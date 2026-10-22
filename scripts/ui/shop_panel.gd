class_name ShopPanel
extends ModalBase
## One shared shop surface for potions, equipment and pet supplies. All values
## come from ItemDB / PetDB and all transactions go through GameState.

var shop_type := "potion"
var shopkeeper := "Merchant"


func _ready() -> void:
	super._ready()
	GameState.data_changed.connect(func() -> void:
		if visible:
			_rebuild())
	GameState.pet_changed.connect(func() -> void:
		if visible:
			_rebuild())


func open_shop(kind: String, keeper: String) -> void:
	shop_type = kind
	shopkeeper = keeper
	var title := "Mara's Tonics"
	if kind == "equipment":
		title = "Garrick's Ironworks"
	elif kind == "pet":
		title = "Nia's Companions"
	open_panel("%s  •  %s" % [title, keeper])


func _rebuild() -> void:
	_clear_content()
	add_body_text("Gold %d     Diamonds %d" % [GameState.gold(), GameState.diamonds()], GameUI.GOLD, 18)
	content.add_child(GameUI.spacer(2))
	match shop_type:
		"potion":
			add_section("POTIONS & CARE")
			for item_id in ItemDB.stock_for("potion"):
				_add_item_row(item_id)
			add_body_text("Health and mana potions are permanent inventory; your pack stores up to nine of each.", GameUI.MUTED, 14)
		"equipment":
			add_section("EQUIPMENT", GameUI.GOLD)
			_add_equipment_summary()
			for item_id in ItemDB.equipment_for_style(GameState.character_weapon_style()):
				if ItemDB.get_item(item_id).get("price", 0) == 0 and GameState.item_count(item_id) > 0:
					continue
				_add_item_row(item_id)
			add_body_text("This counter stocks gear for your hero's weapon discipline. Armour and shields are shared.", GameUI.MUTED, 14)
			add_section("SELL GATHERED GOODS", GameUI.TEAL)
			_add_sell_row("wood")
		"pet":
			add_section("COMPANIONS FOR SALE", GameUI.GOLD)
			for pet_id in PetDB.shop_stock():
				_add_pet_shop_row(pet_id)
			add_section("SUPPLIES", GameUI.GOLD)
			for item_id in ItemDB.stock_for("pet"):
				_add_item_row(item_id)
			add_section("YOUR COMPANIONS", GameUI.GOLD)
			for pet_id in (GameState.data.get("pets", {}) as Dictionary):
				_add_owned_pet_row(str(pet_id))
			add_body_text("Companions heal you in combat, strike nearby monsters and grant shields. Higher levels strengthen all three abilities.", GameUI.MUTED, 14)


func _add_equipment_summary() -> void:
	var panel := GameUI.panel(Color("#14262c"), Color("#30494e"))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 22)
	panel.add_child(hbox)
	var weapon := GameState.equipped_item("weapon")
	var armor := GameState.equipped_item("armor")
	var shield := GameState.equipped_item("shield")
	hbox.add_child(GameUI.label("Weapon: %s" % ("—" if weapon == "" else ItemDB.name_of(weapon)), 14, GameUI.TEXT))
	hbox.add_child(GameUI.label("Armour: %s" % ("—" if armor == "" else ItemDB.name_of(armor)), 14, GameUI.TEXT))
	hbox.add_child(GameUI.label("Shield: %s" % ("—" if shield == "" else ItemDB.name_of(shield)), 14, GameUI.TEXT))
	hbox.add_child(GameUI.label("ATK %d   DEF %d" % [GameState.attack_power(), GameState.defense()], 14, GameUI.GOLD))
	content.add_child(panel)


func _add_item_row(item_id: String) -> void:
	var item := ItemDB.get_item(item_id)
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", GameUI.style(Color("#162a30"), Color("#324b50"), 1, 0))
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	row.add_child(hbox)
	var icon := GameUI.icon_rect(_icon_kind(item_id), 35)
	hbox.add_child(icon)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 1)
	hbox.add_child(info)
	info.add_child(GameUI.label(str(item.get("name", item_id)), 17, GameUI.TEXT))
	var stat := ItemDB.stat_line(item_id)
	if stat != "":
		info.add_child(GameUI.label(stat, 13, GameUI.GREEN))
	var desc := GameUI.label(str(item.get("description", "")), 13, GameUI.MUTED)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(400, 0)
	info.add_child(desc)
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(150, 0)
	right.add_theme_constant_override("separation", 6)
	hbox.add_child(right)
	var price := int(item.get("price", 0))
	if price > 0:
		right.add_child(GameUI.label("%d gold" % price, 15, GameUI.GOLD))
	else:
		right.add_child(GameUI.label("Starter", 14, GameUI.MUTED))
	if ItemDB.is_equipment(item_id):
		if GameState.item_count(item_id) <= 0:
			var buy := GameUI.button("Buy", Vector2(130, 38))
			buy.disabled = price > GameState.gold()
			buy.pressed.connect(func() -> void:
				var result := GameState.buy_item(item_id)
				if not result.ok:
					GameState.toast_requested.emit(str(result.message), "bad"))
			right.add_child(buy)
		elif GameState.equipped_item(str(item.get("slot", ""))) == item_id:
			right.add_child(GameUI.label("Equipped", 14, GameUI.TEAL))
		else:
			var equip := GameUI.button("Equip", Vector2(130, 38))
			equip.pressed.connect(func() -> void:
				var result := GameState.equip_item(item_id)
				if not result.ok:
					GameState.toast_requested.emit(str(result.message), "bad"))
			right.add_child(equip)
	else:
		var buy := GameUI.button("Buy", Vector2(130, 38))
		buy.disabled = price > GameState.gold() or not GameState.can_add_item(item_id)
		buy.pressed.connect(func() -> void:
			var result := GameState.buy_item(item_id)
			if not result.ok:
				GameState.toast_requested.emit(str(result.message), "bad"))
		right.add_child(buy)
		right.add_child(GameUI.label("Owned %d" % GameState.item_count(item_id), 12, GameUI.MUTED))
	content.add_child(row)


func _add_sell_row(item_id: String) -> void:
	var item := ItemDB.get_item(item_id)
	var count := GameState.item_count(item_id)
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", GameUI.style(Color("#14262c"), Color("#30494e"), 1, 0))
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	row.add_child(hbox)
	hbox.add_child(GameUI.icon_rect("wood", 28))
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info)
	info.add_child(GameUI.label("%s  x%d" % [str(item.name), count], 15, GameUI.TEXT))
	info.add_child(GameUI.label("%d gold each. Garrick will take the lot." % int(item.price), 12, GameUI.MUTED))
	var sell := GameUI.button("Sell all  •  %dg" % (count * int(item.price)), Vector2(160, 38))
	sell.disabled = count <= 0
	sell.pressed.connect(func() -> void:
		var result := GameState.sell_item(item_id, GameState.item_count(item_id))
		if not result.ok:
			GameState.toast_requested.emit(str(result.message), "bad"))
	hbox.add_child(sell)
	content.add_child(row)


func _add_pet_shop_row(pet_id: String) -> void:
	var def := PetDB.get_pet(pet_id)
	var owned := not GameState.get_pet(pet_id).is_empty()
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", GameUI.style(Color("#162a30"), Color("#324b50"), 1, 0))
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	row.add_child(hbox)
	var preview := TextureRect.new()
	preview.texture = PixelArt.pet_texture(pet_id)
	preview.custom_minimum_size = Vector2(64, 64)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hbox.add_child(preview)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info)
	info.add_child(GameUI.label("%s  •  %s" % [def.name, def.species], 17, GameUI.TEXT))
	info.add_child(GameUI.label("%s   HP %d   Heal %d / Atk %d / Shield %d" % [def.focus, def.hp, def.heal, def.attack, def.shield], 13, GameUI.GREEN))
	var desc := GameUI.label(str(def.description), 13, GameUI.MUTED)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(420, 0)
	info.add_child(desc)
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(150, 0)
	hbox.add_child(right)
	if owned:
		right.add_child(GameUI.label("Owned", 14, GameUI.TEAL))
		if GameState.active_pet_id() != pet_id:
			var activate := GameUI.button("Activate", Vector2(130, 38))
			activate.pressed.connect(func() -> void:
				GameState.set_active_pet(pet_id)
				GameState.toast_requested.emit("%s joins you at the front." % def.name, "good"))
			right.add_child(activate)
	else:
		right.add_child(GameUI.label("%d gold" % int(def.cost), 15, GameUI.GOLD))
		var buy := GameUI.button("Adopt", Vector2(130, 38))
		buy.disabled = GameState.gold() < int(def.cost)
		buy.pressed.connect(func() -> void:
			var result := GameState.purchase_pet(pet_id)
			if not result.ok:
				GameState.toast_requested.emit(str(result.message), "bad"))
		right.add_child(buy)
	content.add_child(row)


func _add_owned_pet_row(pet_id: String) -> void:
	var pet := GameState.get_pet(pet_id)
	var def := PetDB.get_pet(pet_id)
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", GameUI.style(Color("#14262c"), Color("#30494e"), 1, 0))
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	row.add_child(hbox)
	var icon := TextureRect.new()
	icon.texture = PixelArt.pet_texture(pet_id)
	icon.custom_minimum_size = Vector2(48, 48)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(icon)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info)
	var active := GameState.active_pet_id() == pet_id
	info.add_child(GameUI.label("%s  Lv %d%s" % [def.name, int(pet.get("level", 1)), "  • ACTIVE" if active else ""], 16, GameUI.TEXT if active else GameUI.MUTED))
	info.add_child(GameUI.label("HP %d/%d   Heal %d / Atk %d / Shield %d   %s" % [int(pet.get("hp", 0)), int(pet.get("hp_max", 0)), PetDB.heal_amount(pet_id, int(pet.get("level", 1))), PetDB.attack_damage(pet_id, int(pet.get("level", 1))), PetDB.shield_amount(pet_id, int(pet.get("level", 1))), "Ready" if bool(pet.get("alive", false)) else "Recovering"], 13, GameUI.GREEN if bool(pet.get("alive", false)) else GameUI.RED))
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	var feed := GameUI.button("Feed", Vector2(78, 34))
	feed.disabled = GameState.item_count("pet_food") <= 0 or int(pet.get("level", 1)) >= PetDB.MAX_LEVEL
	feed.pressed.connect(func() -> void: GameState.feed_pet(pet_id))
	buttons.add_child(feed)
	var upgrade_cost := 45 + int(pet.get("level", 1)) * 35
	var upgrade := GameUI.button("Upgrade  %dg" % upgrade_cost, Vector2(150, 34))
	upgrade.disabled = int(pet.get("level", 1)) >= PetDB.MAX_LEVEL or GameState.gold() < upgrade_cost
	upgrade.pressed.connect(func() -> void:
		var result := GameState.upgrade_pet(pet_id)
		if not result.ok:
			GameState.toast_requested.emit(str(result.message), "bad"))
	buttons.add_child(upgrade)
	if GameState.active_pet_id() != pet_id:
		var activate := GameUI.button("Activate", Vector2(90, 34))
		activate.pressed.connect(func() -> void: GameState.set_active_pet(pet_id))
		buttons.add_child(activate)
	hbox.add_child(buttons)
	content.add_child(row)


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
			var style := str(item.get("style", "sword"))
			return style
		"armor":
			return "armor"
		"shield":
			return "shield"
		"material":
			return "wood"
	return "spark"
