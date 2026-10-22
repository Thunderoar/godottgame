class_name ShopPanel
extends ModalBase
## One shared shop surface for potions, equipment and pet supplies. All values
## come from ItemDB / PetDB and all transactions go through GameState.
##
## Overhaul (3A): an illustrated storefront band with an animated shopkeeper,
## stock as cards (see ItemCard) instead of table rows, a detail pane with
## before/after stat compare, and feedback that lives INSIDE the panel (coin
## arc, currency tick, card pop, keeper reaction) instead of dead toast calls.
## Cards refresh in place on data_changed so the scroll position and hover
## survive the sea-cleaning gold drip; a full rebuild only happens when the set
## of cards itself changes.

var shop_type := "potion"
var shopkeeper := "Merchant"

var _band: ShopScene
var _gold_label: Label
var _diamond_label: Label
var _cards: Array[ItemCard] = []
var _selected_card: ItemCard = null
var _signature := ""
var _detail_name: Label
var _detail_desc: Label
var _detail_stats: Label
var _detail_hint: Label
var _pet_animate_timer := 0.0
var _pet_frame := 0
var _sale_pens: Dictionary = {}
var _owned_pens: Dictionary = {}
var _currency_root: Control


func _ready() -> void:
	_panel_size = Vector2(940, 660)
	super._ready()
	GameState.data_changed.connect(func() -> void:
		if visible:
			_refresh_or_rebuild())
	GameState.pet_changed.connect(func() -> void:
		if visible:
			_refresh_or_rebuild())
	set_process(true)


func open_shop(kind: String, keeper: String) -> void:
	shop_type = kind
	shopkeeper = keeper
	var title := "Mara's Tonics"
	if kind == "equipment":
		title = "Garrick's Ironworks"
	elif kind == "pet":
		title = "Nia's Companions"
	open_panel("%s  •  %s" % [title, keeper])
	if _band != null:
		_band.keeper_say(ShopLinesDB.line(kind, "greeting"))


func _process(delta: float) -> void:
	# Animate every pet pen preview from one timer (cheap, no per-pen nodes).
	if not visible:
		return
	_pet_animate_timer += delta
	if _pet_animate_timer >= 0.34:
		_pet_animate_timer = 0.0
		_pet_frame = 1 - _pet_frame
		for pen in _sale_pens.values():
			var frame_rect: TextureRect = pen.get("preview")
			if frame_rect != null:
				frame_rect.texture = PixelArt.pet_texture(str(pen.get("id")), _pet_frame)
		for pen in _owned_pens.values():
			var frame_rect: TextureRect = pen.get("preview")
			if frame_rect != null:
				frame_rect.texture = PixelArt.pet_texture(str(pen.get("id")), _pet_frame)


# ------------------------------------------------------------------ structure

func _refresh_or_rebuild() -> void:
	if _current_signature() != _signature:
		_rebuild()
	else:
		_refresh_in_place()


func _current_signature() -> String:
	var parts: Array[String] = [shop_type]
	match shop_type:
		"potion":
			for item_id in ItemDB.stock_for("potion"):
				parts.append(item_id)
		"equipment":
			parts.append(GameState.character_weapon_style())
			for item_id in ItemDB.equipment_for_style(GameState.character_weapon_style()):
				parts.append(item_id)
			parts.append("wood:%d" % mini(1, GameState.item_count("wood")))
		"pet":
			for pet_id in PetDB.shop_stock():
				parts.append(pet_id)
			for pet_id in (GameState.data.get("pets", {}) as Dictionary):
				parts.append("own_%s" % pet_id)
			for item_id in ItemDB.stock_for("pet"):
				parts.append(item_id)
	return "|".join(parts)


func _rebuild() -> void:
	_clear_content()
	_signature = _current_signature()
	_cards.clear()
	_sale_pens.clear()
	_owned_pens.clear()
	_selected_card = null

	_band = ShopScene.new()
	_band.setup(shop_type, shopkeeper)
	content.add_child(_band)
	content.add_child(GameUI.spacer(2))

	_currency_root = HBoxContainer.new()
	_currency_root.add_theme_constant_override("separation", 16)
	content.add_child(_currency_root)
	var gold_row := HBoxContainer.new()
	gold_row.add_theme_constant_override("separation", 6)
	_currency_root.add_child(gold_row)
	gold_row.add_child(GameUI.icon_rect("gold", 22))
	_gold_label = GameUI.label("%d" % GameState.gold(), 19, GameUI.GOLD)
	gold_row.add_child(_gold_label)
	var diamond_row := HBoxContainer.new()
	diamond_row.add_theme_constant_override("separation", 6)
	_currency_root.add_child(diamond_row)
	diamond_row.add_child(GameUI.icon_rect("diamond", 21))
	_diamond_label = GameUI.label("%d" % GameState.diamonds(), 19, GameUI.DIAMOND)
	diamond_row.add_child(_diamond_label)
	var keeper_hint := GameUI.label(ShopLinesDB.line(shop_type, "greeting"), 13, GameUI.MUTED)
	keeper_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	keeper_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	keeper_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_currency_root.add_child(keeper_hint)

	_build_detail_pane()

	match shop_type:
		"potion":
			add_section("POTIONS & CARE")
			_add_stock_grid(ItemDB.stock_for("potion"))
			add_body_text("Health and mana potions are permanent inventory; your pack stores up to nine of each.", GameUI.MUTED, 13)
		"equipment":
			add_section("EQUIPMENT  •  %s discipline" % GameState.character_weapon_style().capitalize(), GameUI.GOLD)
			_add_stock_grid(_equipment_stock(), true)
			add_body_text("This counter stocks gear for your hero's weapon discipline. Armour and shields are shared.", GameUI.MUTED, 13)
			add_section("SELL GATHERED GOODS", GameUI.TEAL)
			_add_sell_card()
		"pet":
			add_section("COMPANIONS FOR SALE", GameUI.GOLD)
			_add_pet_sale_pens()
			add_section("SUPPLIES", GameUI.GOLD)
			_add_stock_grid(ItemDB.stock_for("pet"))
			add_section("YOUR COMPANIONS", GameUI.GOLD)
			_add_owned_pet_pens()
			add_body_text("Companions heal you in combat, strike nearby monsters and grant shields. Higher levels strengthen all three abilities.", GameUI.MUTED, 13)

	_refresh_in_place()


func _equipment_stock() -> Array[String]:
	var out: Array[String] = []
	for item_id in ItemDB.equipment_for_style(GameState.character_weapon_style()):
		if ItemDB.get_item(item_id).get("price", 0) == 0 and GameState.item_count(item_id) > 0:
			continue
		out.append(item_id)
	return out


func _add_stock_grid(item_ids: Array[String], summary := false) -> void:
	if summary:
		var panel := GameUI.framed_panel("iron", 7)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 20)
		panel.add_child(hbox)
		var weapon := GameState.equipped_item("weapon")
		var armor := GameState.equipped_item("armor")
		var shield := GameState.equipped_item("shield")
		hbox.add_child(GameUI.label("Weapon: %s" % ("—" if weapon == "" else ItemDB.name_of(weapon)), 13, GameUI.TEXT))
		hbox.add_child(GameUI.label("Armour: %s" % ("—" if armor == "" else ItemDB.name_of(armor)), 13, GameUI.TEXT))
		hbox.add_child(GameUI.label("Shield: %s" % ("—" if shield == "" else ItemDB.name_of(shield)), 13, GameUI.TEXT))
		hbox.add_child(GameUI.label("ATK %d   DEF %d" % [GameState.attack_power(), GameState.defense()], 13, GameUI.GOLD))
		content.add_child(panel)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(grid)
	for item_id in item_ids:
		var card := ItemCard.new()
		card.setup(item_id, _icon_kind(item_id))
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.action_pressed.connect(_on_card_action)
		card.selected.connect(_on_card_selected)
		grid.add_child(card)
		_cards.append(card)


func _build_detail_pane() -> void:
	var detail := GameUI.framed_panel("stone", 8)
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(detail)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	detail.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	box.add_child(head)
	_detail_name = GameUI.label("Select an item to inspect it", 16, GameUI.GOLD)
	_detail_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_detail_name)
	_detail_stats = GameUI.label("", 14, GameUI.TEAL)
	_detail_stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	head.add_child(_detail_stats)
	_detail_desc = GameUI.label("Prices, stats and your currency update live while you browse.", 13, GameUI.MUTED)
	_detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_detail_desc)
	_detail_hint = GameUI.label("", 12, GameUI.MUTED)
	box.add_child(_detail_hint)


func _add_sell_card() -> void:
	var item := ItemDB.get_item("wood")
	var card := GameUI.framed_panel("parchment", 7)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	card.add_child(hbox)
	hbox.add_child(GameUI.icon_rect("wood", 34))
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info)
	var name_label := GameUI.label("%s" % str(item.name), 16, GameUI.TEXT)
	info.add_child(name_label)
	var count_label := GameUI.label("", 13, GameUI.GREEN)
	info.add_child(count_label)
	var sell := GameUI.button("Sell all", Vector2(150, 38))
	sell.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(sell)
	var burst := GameUI.label("", 16, GameUI.GOLD)
	burst.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	burst.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	burst.custom_minimum_size = Vector2(90, 0)
	hbox.add_child(burst)
	sell.pressed.connect(func() -> void:
		var result := GameState.sell_item("wood", GameState.item_count("wood"))
		if result.ok:
			Sfx.play("coin", -8.0)
			burst.text = "Sold!"
			count_label.text = "%s  x0" % str(item.name)
			sell.disabled = true
			if not GameSettings.reduce_motion():
				var pop := create_tween()
				burst.modulate = Color(1.4, 1.2, 0.7)
				pop.tween_property(burst, "modulate", Color.WHITE, 0.8)
				pop.tween_callback(func() -> void: burst.text = "")
			_keeper_react("sell", "gold")
			_coin_arc(sell.global_position, _gold_label.global_position)
		else:
			Sfx.play("deny", -10.0)
			_keeper_react("deny", "close"))
	content.add_child(card)
	card.set_meta("wood_count_label", count_label)
	card.set_meta("wood_sell_button", sell)


func _add_pet_sale_pens() -> void:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(grid)
	for pet_id in PetDB.shop_stock():
		var def := PetDB.get_pet(pet_id)
		var pen := GameUI.card("parchment")
		pen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 3)
		pen.add_child(box)
		var preview := TextureRect.new()
		preview.texture = PixelArt.pet_texture(pet_id)
		preview.custom_minimum_size = Vector2(64, 64)
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		box.add_child(preview)
		var name_label := GameUI.label("%s  •  %s" % [def.name, def.species], 15, GameUI.TEXT)
		box.add_child(name_label)
		var stats := HBoxContainer.new()
		stats.add_theme_constant_override("separation", 6)
		box.add_child(stats)
		stats.add_child(_stat_pill("heart", "H%d" % int(def.get("heal", 0))))
		stats.add_child(_stat_pill("spark", "A%d" % int(def.get("attack", 0))))
		stats.add_child(_stat_pill("shield", "S%d" % int(def.get("shield", 0))))
		var price_label := GameUI.label("", 14, GameUI.GOLD)
		box.add_child(price_label)
		var adopt := GameUI.button("Adopt", Vector2(120, 34))
		adopt.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		box.add_child(adopt)
		adopt.pressed.connect(func() -> void:
			var result := GameState.purchase_pet(pet_id)
			if result.ok:
				Sfx.play("coin", -8.0)
				_keeper_react("buy", "heart")
			else:
				Sfx.play("deny", -10.0)
				_keeper_react("deny", "close"))
		var owned_row := GameUI.label("", 13, GameUI.TEAL)
		owned_row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(owned_row)
		grid.add_child(pen)
		_sale_pens[pet_id] = {"id": pet_id, "preview": preview, "price": price_label, "adopt": adopt, "owned": owned_row}


func _add_owned_pet_pens() -> void:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(grid)
	for pet_id in (GameState.data.get("pets", {}) as Dictionary):
		var pen := GameUI.card("wood")
		pen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)
		pen.add_child(hbox)
		var preview := TextureRect.new()
		preview.texture = PixelArt.pet_texture(str(pet_id))
		preview.custom_minimum_size = Vector2(56, 56)
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		preview.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hbox.add_child(preview)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 2)
		hbox.add_child(info)
		var name_label := GameUI.label("", 16, GameUI.TEXT)
		info.add_child(name_label)
		var stats := HBoxContainer.new()
		stats.add_theme_constant_override("separation", 6)
		info.add_child(stats)
		var hp_pill := _stat_pill("heart", "")
		var atk_pill := _stat_pill("spark", "")
		var shield_pill := _stat_pill("shield", "")
		stats.add_child(hp_pill)
		stats.add_child(atk_pill)
		stats.add_child(shield_pill)
		var xp_bar := SegmentedBar.new()
		xp_bar.setup("XP", GameUI.PURPLE, 10, true)
		info.add_child(xp_bar)
		var buttons := HBoxContainer.new()
		buttons.add_theme_constant_override("separation", 8)
		hbox.add_child(buttons)
		var feed := GameUI.button("Feed", Vector2(84, 34))
		buttons.add_child(feed)
		var upgrade := GameUI.button("Upgrade", Vector2(150, 34))
		buttons.add_child(upgrade)
		var activate := GameUI.button("Activate", Vector2(100, 34))
		buttons.add_child(activate)
		feed.pressed.connect(func() -> void:
			var result := GameState.feed_pet(str(pet_id))
			if result.ok:
				Sfx.play("coin", -8.0)
				_keeper_react("buy", "heart")
			else:
				Sfx.play("deny", -10.0)
				_keeper_react("deny", "close"))
		upgrade.pressed.connect(func() -> void:
			var result := GameState.upgrade_pet(str(pet_id))
			if result.ok:
				Sfx.play("equip", -8.0)
				_keeper_react("equip", "check")
			else:
				Sfx.play("deny", -10.0)
				_keeper_react("deny", "close"))
		activate.pressed.connect(func() -> void:
			GameState.set_active_pet(str(pet_id))
			Sfx.play("equip", -10.0)
			_keeper_react("equip", "check"))
		grid.add_child(pen)
		_owned_pens[str(pet_id)] = {
			"id": str(pet_id), "preview": preview, "name": name_label, "hp": hp_pill,
			"atk": atk_pill, "shield": shield_pill, "xp": xp_bar, "feed": feed,
			"upgrade": upgrade, "activate": activate,
		}


func _stat_pill(kind: String, text: String) -> PanelContainer:
	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override("panel", GameUI.style(Color(0.03, 0.07, 0.08, 0.85), GameUI.BORDER, 1, 6))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	pill.add_child(row)
	var icon := GameUI.icon_rect(kind, 14)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var label := GameUI.label(text, 12, GameUI.TEXT)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(label)
	pill.set_meta("label", label)
	return pill


# ------------------------------------------------------------------ refresh

func _refresh_in_place() -> void:
	# Everything mutable updates in place: currencies, card states, pet pens.
	# No children are freed here, so scroll and hover survive data_changed.
	if _gold_label != null:
		_gold_label.text = "%d" % GameState.gold()
		_diamond_label.text = "%d" % GameState.diamonds()
	for card in _cards:
		card.refresh()
	_refresh_sell_card()
	_refresh_pet_pens()
	if _selected_card != null and is_instance_valid(_selected_card):
		_show_detail(_selected_card.item_id)


func _refresh_sell_card() -> void:
	for child in content.get_children():
		if child.has_meta("wood_count_label"):
			var count_label: Label = child.get_meta("wood_count_label")
			var sell: Button = child.get_meta("wood_sell_button")
			var count := GameState.item_count("wood")
			var item := ItemDB.get_item("wood")
			count_label.text = "%s  x%d" % [str(item.name), count]
			sell.disabled = count <= 0
			sell.text = "Sell all  •  %dg" % (count * int(item.price))


func _refresh_pet_pens() -> void:
	for pet_id in _sale_pens:
		var pen: Dictionary = _sale_pens[pet_id]
		var def := PetDB.get_pet(str(pet_id))
		var owned := not GameState.get_pet(str(pet_id)).is_empty()
		var adopt: Button = pen.get("adopt")
		var price_label: Label = pen.get("price")
		var owned_row: Label = pen.get("owned")
		if owned:
			price_label.visible = false
			adopt.visible = false
			owned_row.visible = true
			owned_row.text = "Owned%s" % ("  •  ACTIVE" if GameState.active_pet_id() == str(pet_id) else "")
		else:
			price_label.visible = true
			price_label.text = "%d gold" % int(def.get("cost", 0))
			adopt.visible = true
			adopt.disabled = GameState.gold() < int(def.get("cost", 0))
			owned_row.visible = false
	for pet_id in _owned_pens:
		var pen: Dictionary = _owned_pens[pet_id]
		var pet := GameState.get_pet(str(pet_id))
		if pet.is_empty():
			continue
		var level := int(pet.get("level", 1))
		var name_label: Label = pen.get("name")
		name_label.text = "%s  Lv %d%s" % [PetDB.name_of(str(pet_id)), level, "  •  ACTIVE" if GameState.active_pet_id() == str(pet_id) else ""]
		(pen.get("hp") as PanelContainer).get_meta("label").text = "HP %d" % int(pet.get("hp_max", 0))
		(pen.get("atk") as PanelContainer).get_meta("label").text = "Atk %d" % PetDB.attack_damage(str(pet_id), level)
		(pen.get("shield") as PanelContainer).get_meta("label").text = "Sh %d" % PetDB.shield_amount(str(pet_id), level)
		var xp_bar: SegmentedBar = pen.get("xp")
		var progress := GameState.pet_xp_progress_for(str(pet_id))
		if bool(progress.get("max", false)):
			xp_bar.set_caption("XP MAX")
			xp_bar.set_values(1, 1)
		else:
			xp_bar.set_caption("XP")
			xp_bar.set_values(int(progress.get("xp", 0)), int(progress.get("next", 1)))
		var feed: Button = pen.get("feed")
		feed.disabled = GameState.item_count("pet_food") <= 0 or level >= PetDB.MAX_LEVEL
		var upgrade: Button = pen.get("upgrade")
		var cost := GameState.pet_upgrade_cost(level)
		upgrade.text = "Upgrade  %dg" % cost
		upgrade.disabled = level >= PetDB.MAX_LEVEL or GameState.gold() < cost
		var activate: Button = pen.get("activate")
		activate.visible = GameState.active_pet_id() != str(pet_id)


# ------------------------------------------------------------------ interactions

func _on_card_action(card: ItemCard) -> void:
	var item := ItemDB.get_item(card.item_id)
	if ItemDB.is_equipment(card.item_id) and GameState.item_count(card.item_id) > 0:
		var result := GameState.equip_item(card.item_id)
		if result.ok:
			Sfx.play("equip", -8.0)
			card.pop()
			_keeper_react("equip", "check")
		else:
			Sfx.play("deny", -10.0)
			card.flash_error()
			_keeper_react("deny", "close")
		return
	var result := GameState.buy_item(card.item_id)
	if result.ok:
		Sfx.play("coin", -8.0)
		card.pop()
		_coin_arc(card.global_position + card.size * 0.5, _gold_label.global_position)
		_tick_currency()
		_keeper_react("buy", "heart")
	else:
		Sfx.play("deny", -10.0)
		card.flash_error()
		_keeper_react("deny", "close")


func _on_card_selected(card: ItemCard) -> void:
	if _selected_card != null and is_instance_valid(_selected_card):
		_selected_card.mark_selected(false)
	_selected_card = card
	card.mark_selected(true)
	_show_detail(card.item_id)


func _show_detail(item_id: String) -> void:
	if _detail_name == null:
		return
	var item := ItemDB.get_item(item_id)
	_detail_name.text = str(item.get("name", item_id))
	_detail_desc.text = str(item.get("description", ""))
	var stats := ItemDB.stat_line(item_id)
	var slot := str(item.get("slot", ""))
	if slot != "" and ItemDB.is_equipment(item_id):
		# Before/after compare against what is currently equipped in that slot.
		var equipped_id := GameState.equipped_item(slot)
		var equipped_item := ItemDB.get_item(equipped_id) if equipped_id != "" else {}
		var is_attack := int(item.get("attack", 0)) > 0
		var mine := int(equipped_item.get("attack", 0)) if is_attack else int(equipped_item.get("defense", 0))
		var theirs := int(item.get("attack", 0)) if is_attack else int(item.get("defense", 0))
		var base := GameState.attack_power() if is_attack else GameState.defense()
		var delta := theirs - mine
		var label := "ATK" if is_attack else "DEF"
		stats = "%s  %d → %d  (%+d)" % [label, base, base + delta, delta]
		_detail_stats.add_theme_color_override("font_color", GameUI.GREEN if delta > 0 else (GameUI.RED if delta < 0 else GameUI.MUTED))
	else:
		_detail_stats.add_theme_color_override("font_color", GameUI.TEAL)
	_detail_stats.text = stats
	var afford := int(item.get("price", 0)) <= GameState.gold()
	var owned_line := ""
	if not ItemDB.is_equipment(item_id) and GameState.item_count(item_id) > 0:
		owned_line = "  •  You carry x%d." % GameState.item_count(item_id)
	_detail_hint.text = "%s%s" % ["You can afford this." if afford else "Not enough gold yet.", owned_line]
	_detail_hint.add_theme_color_override("font_color", GameUI.MUTED if afford else GameUI.RED)


func _keeper_react(mood: String, emote: String) -> void:
	if _band != null and is_instance_valid(_band):
		_band.keeper_say(ShopLinesDB.line(shop_type, mood), emote)


func _tick_currency() -> void:
	if _gold_label == null or GameSettings.reduce_motion():
		return
	var tween := create_tween()
	_gold_label.scale = Vector2(1.25, 1.25)
	tween.tween_property(_gold_label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _coin_arc(from: Vector2, to: Vector2) -> void:
	# A small coin flies from the purchase point to the in-panel gold readout.
	if GameSettings.reduce_motion() or not is_inside_tree():
		return
	var coin := TextureRect.new()
	coin.texture = PixelArt.icon("gold", 32)
	coin.custom_minimum_size = Vector2(22, 22)
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	coin.z_index = 50
	add_child(coin)
	var start := from - global_position
	var end := to - global_position + Vector2(40, 10)
	coin.position = start
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_method(func(t: float) -> void:
		var arc := Vector2(0, -60.0 * sin(PI * t))
		coin.position = start.lerp(end, t) + arc, 0.0, 1.0, 0.55)
	tween.tween_property(coin, "modulate:a", 0.1, 0.55)
	tween.chain().tween_callback(coin.queue_free)


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
