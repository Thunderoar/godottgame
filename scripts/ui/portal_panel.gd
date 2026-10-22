class_name PortalPanel
extends ModalBase
## Lists both portal gates, their level/unlock requirements and boss details.
## Entry is blocked here for clarity and validated again by GameState.

var selected := "tidebound_grotto"


func _ready() -> void:
	super._ready()
	GameState.data_changed.connect(func() -> void:
		if visible:
			_rebuild())


func open_portals(focus_id: String = "tidebound_grotto") -> void:
	selected = focus_id
	open_panel("Monster Battle Portal")


func _rebuild() -> void:
	_clear_content()
	add_body_text("Level %d  •  Gold %d  •  Diamonds %d" % [int(GameState.data.level), GameState.gold(), GameState.diamonds()], GameUI.GOLD, 16)
	add_body_text("Your companion supports you with healing, attacks and shields. Level gates and boss unlocks control entry.", GameUI.MUTED, 13)
	content.add_child(GameUI.spacer(2))
	for portal_id in PortalDB.ordered_ids():
		_add_portal_card(portal_id)


func _add_portal_card(portal_id: String) -> void:
	var def := PortalDB.get_portal(portal_id)
	var state := GameState.portal_state(portal_id)
	var reason: Dictionary = GameState.portal_clear_reason(portal_id)
	var cleared := bool(state.get("cleared", false))
	var unlocked := bool(state.get("unlocked", false))
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", GameUI.style(Color("#152a31") if unlocked else Color("#141d20"), Color("#3e5c62") if unlocked else Color("#2a353a"), 2, 0))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 18)
	card.add_child(hbox)
	var icon := TextureRect.new()
	icon.texture = PixelArt.icon("portal", 32)
	icon.custom_minimum_size = Vector2(70, 70)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Theme-tinted per portal (from PortalDB), gold once cleared.
	var theme_palette := PixelArt.portal_theme_palette(str(def.get("theme", "grotto")))
	if cleared:
		icon.modulate = Color("#ffd88a")
	elif unlocked:
		icon.modulate = theme_palette["glow_light"]
	else:
		icon.modulate = Color(0.35, 0.4, 0.42)
	hbox.add_child(icon)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 3)
	hbox.add_child(info)
	var title_line := "%s%s" % [str(def.name), "  •  CLEARED" if cleared else ""]
	info.add_child(GameUI.label(title_line, 20, GameUI.GOLD if cleared else GameUI.TEXT))
	info.add_child(GameUI.label("%s   •   Level %d+" % [str(def.subtitle), int(def.level_required)], 13, GameUI.MUTED))
	var lore := GameUI.label(str(def.lore), 13, GameUI.MUTED)
	lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore.custom_minimum_size = Vector2(470, 0)
	info.add_child(lore)
	var details := "Boss: %s  •  %s    Monsters: %d" % [str(def.boss_name), str(def.get("boss_ability_name", "Heavy Strike")), int(def.monster_count)]
	info.add_child(GameUI.label(details, 13, GameUI.TEAL))
	var rewards: Dictionary = def.rewards_repeat if cleared else def.rewards_first
	var bits: Array[String] = []
	if int(rewards.get("gold", 0)) > 0:
		bits.append("%d gold" % int(rewards.gold))
	if int(rewards.get("diamonds", 0)) > 0:
		bits.append("%d diamonds" % int(rewards.diamonds))
	if str(rewards.get("pet", "")) != "":
		bits.append("%s companion" % PetDB.name_of(str(rewards.pet)))
	info.add_child(GameUI.label("Reward: " + ", ".join(bits), 13, GameUI.GOLD))
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(160, 0)
	right.add_theme_constant_override("separation", 8)
	hbox.add_child(right)
	if reason.ok:
		var enter := GameUI.button("Enter", Vector2(150, 44))
		enter.pressed.connect(func() -> void:
			var game := get_tree().get_first_node_in_group("game")
			if game and game.has_method("enter_portal"):
				close_panel()
				game.call("enter_portal", portal_id))
		right.add_child(enter)
	else:
		right.add_child(GameUI.chip("LOCKED", GameUI.RED))
		var why := GameUI.label(str(reason.reason), 12, GameUI.MUTED)
		why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		why.custom_minimum_size = Vector2(150, 0)
		right.add_child(why)
	content.add_child(card)
