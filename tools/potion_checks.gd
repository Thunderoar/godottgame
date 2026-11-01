extends RefCounted
const POTIONS := ["sprint_potion", "haste_potion", "shield_potion", "boss_revival_potion"]

static func run(game: Game, check: Callable, capture: Callable = Callable()) -> void:
	var saved := GameState.data.duplicate(true)
	var effects := GameState._potion_times.duplicate()
	var purchases := GameState._last_purchase.duplicate()
	var autosave := GameState.autosave_enabled
	var ticking := game.is_processing()
	game.set_process(false)
	game.hud.hide_modals()
	GameState.autosave_enabled = false
	GameState.clear_potion_effects()
	GameState.data = GameState._make_default("adam")
	GameState.data.gold = 5000
	GameState.data.campaign.intro_seen = true
	GameState.data.campaign.dock_welcome_seen = true
	GameState.data.portal_origin.opened = true
	GameState.data.inventory.health_potion = 0
	GameState._last_purchase.clear()
	GameState._emit_all()
	await game._load_lobby(false)
	_freeze(game.world)
	game.open_shop("potion", "Mira")
	await game.get_tree().process_frame
	await game.get_tree().process_frame
	var shop := game.hud.shop_panel
	check.call(POTIONS.all(func(id: String) -> bool: return id in ItemDB.stock_for("potion")), "Potion Shop stocks sprint, fast attack, shield and boss revival beside health potions")
	for id in POTIONS:
		var card: ItemCard
		for candidate in shop._cards:
			if candidate.item_id == id: card = candidate
		check.call(is_instance_valid(card) and card.icon_kind == id, "%s has its own stock card and flask icon" % ItemDB.name_of(id))
		if not is_instance_valid(card): continue
		var gold := GameState.gold()
		card._action_button.pressed.emit()
		check.call(GameState.item_count(id) == 1 and GameState.gold() == gold-int(ItemDB.get_item(id).price), "the actual %s Buy button charges its catalog price once" % ItemDB.name_of(id))
	if capture.is_valid():
		await capture.call("potions_01_shop")
		shop.body.scroll_vertical = int(shop.body.get_v_scroll_bar().max_value)
		await capture.call("potions_01b_shop_bottom")
	shop.close_panel()
	GameState.add_item("sprint_potion")
	GameState.add_item("shield_potion")
	GameState.add_item("boss_revival_potion",2)
	var inventory := game.hud.inventory_panel
	game.open_inventory()
	await game.get_tree().process_frame
	check.call(_use_button(inventory,"boss_revival_potion") == null and _text(inventory,"Boss fights only"), "Pack explains automatic boss revival without offering an unrestricted Use button")
	var use := _use_button(inventory,"sprint_potion")
	check.call(is_instance_valid(use), "Pack exposes a real Sprint Potion Use button")
	if is_instance_valid(use): use.pressed.emit()
	check.call(not inventory.visible and not game.player().controls_locked and GameState.potion_time("sprint") == 10 and GameState.item_count("sprint_potion") == 1, "using a sprint potion consumes one bottle and closes Pack into ten seconds of movement")
	var player := game.player()
	player.stamina = 0
	player.exhausted = true
	Input.action_release("sprint")
	Input.action_press("move_right")
	player._physics_process(0.5)
	check.call(player.sprinting and player.velocity.length() > GameState.move_speed() and not player.exhausted, "the sprint bonus starts without Shift even from exhausted empty stamina")
	var stamina := player.stamina
	player._update_stamina(1)
	check.call(player.sprinting and player.stamina >= stamina, "continuous potion sprint does not drain stamina")
	Input.action_release("move_right")
	player._update_stamina(0)
	check.call(not player.sprinting, "automatic sprint still stops when the player releases movement")
	var stock := GameState.item_count("sprint_potion")
	check.call(not bool(GameState.consume_item("sprint_potion").ok) and GameState.item_count("sprint_potion") == stock, "a duplicate active sprint cannot waste another bottle")
	game.open_settings()
	game._process(0.5)
	check.call(is_equal_approx(GameState.potion_time("sprint"),9.5), "ordinary Settings keeps the shared potion clock running")
	game._story_active = true
	game._process(2)
	game._story_active = false
	game._developer_paused = true
	game._process(2)
	game._developer_paused = false
	check.call(is_equal_approx(GameState.potion_time("sprint"),9.5), "story and developer suspension freeze the potion clock")
	game.hud.settings_panel.close_panel()
	GameState.advance_potion_effects(9.49)
	Input.action_press("move_right")
	player._update_stamina(0)
	check.call(player.sprinting, "uninterrupted potion sprint remains active just before ten seconds")
	GameState.advance_potion_effects(0.02)
	player._update_stamina(0)
	Input.action_release("move_right")
	check.call(not player.sprinting and GameState.potion_time("sprint") == 0, "the bonus expires after ten seconds and restores ordinary sprint controls")
	player._attack_phase = Player.AttackPhase.NONE
	player.attacking = false
	player._attack_timer = 0
	player.try_attack()
	var anticipation := player._phase_time
	player._attack_phase = Player.AttackPhase.NONE
	player.attacking = false
	player._attack_timer = 0
	check.call(bool(GameState.consume_item("haste_potion").ok), "Fast Attack Potion activates through the inventory transaction")
	player.try_attack()
	player._physics_process(anticipation/1.5+0.001)
	check.call(player._attack_phase == Player.AttackPhase.ACTIVE, "haste advances the real anticipation into one active hit sooner")
	player._attack_phase = Player.AttackPhase.NONE
	player.attacking = false
	player._attack_timer = 0.45
	player._physics_process(0.2)
	check.call(is_equal_approx(player._attack_timer,0.15), "haste also speeds the actual weapon cooldown by 1.5 times")
	GameState.advance_potion_effects(10)
	check.call(GameState.attack_speed_multiplier() == 1, "attack cadence returns to normal when haste ends")
	GameState.add_item("haste_potion")
	GameState.consume_item("haste_potion")
	GameState.data.character_id = "mei_ling"
	player._attack_phase = Player.AttackPhase.NONE
	player.attacking = false
	player._attack_timer = 0
	var arrows := game.world.get_children().filter(func(node: Node) -> bool: return node is Arrow).size()
	player.try_attack()
	var bow_windup := player._phase_time
	player._physics_process(bow_windup/1.5+0.001)
	var released := game.world.get_children().filter(func(node: Node) -> bool: return node is Arrow).size()
	player._physics_process(0)
	check.call(released == arrows+1 and game.world.get_children().filter(func(node: Node) -> bool: return node is Arrow).size() == released, "haste accelerates a bow's release without firing a duplicate arrow")
	for node in game.world.get_children():
		if node is Arrow: node.queue_free()
	GameState.data.character_id = "adam"
	player._attack_phase = Player.AttackPhase.NONE
	player.attacking = false
	player._attack_timer = 0
	GameState.clear_potion_effects()
	var hp := GameState.health()
	check.call(bool(GameState.consume_item("shield_potion").ok) and GameState.shield() == 60, "Shield Potion fills the shared sixty-point shield")
	var shield_stock := GameState.item_count("shield_potion")
	check.call(not bool(GameState.consume_item("shield_potion").ok) and GameState.item_count("shield_potion") == shield_stock, "full shields reject another bottle without consuming it")
	GameState.damage_player(GameState.defense()+20)
	check.call(GameState.health() == hp and GameState.shield() == 40, "potion shield absorbs a real damage event before HP")
	GameState.consume_item("sprint_potion")
	GameState.add_item("haste_potion")
	GameState.consume_item("haste_potion")
	check.call(GameState.potion_time("sprint") == 10 and GameState.potion_time("haste") == 10 and GameState.shield() == 40, "sprint, fast attack and shield can coexist without replacing one another")
	if capture.is_valid(): await capture.call("potions_04_active_boosts")
	GameState.clear_potion_effects()
	check.call(not game.boss_revival_available() and not bool(GameState.consume_item("boss_revival_potion").ok), "revival cannot be manually consumed or enabled in the village")
	var revival_stock := GameState.item_count("boss_revival_potion")
	var defeats := [0]
	var count_defeat := func() -> void: defeats[0] += 1
	GameState.player_defeated.disconnect(game._on_player_defeated)
	GameState.player_defeated.connect(count_defeat)
	GameState.damage_player(hp+GameState.defense()+1000)
	check.call(GameState.health() == 0 and defeats[0] == 1 and GameState.item_count("boss_revival_potion") == revival_stock, "a fatal village hit still requests normal defeat and leaves boss revival stock untouched")
	GameState.player_defeated.disconnect(count_defeat)
	GameState.player_defeated.connect(game._on_player_defeated)
	GameState.set_health(GameState.health_max())
	GameState.add_item("sprint_potion")
	GameState.consume_item("sprint_potion")
	GameState.advance_potion_effects(1)
	check.call(GameState.start_expedition(RealmDB.PORTAL), "potion fixture enters a real portal expedition")
	await game._load_dungeon(RealmDB.PORTAL,false)
	_freeze(game.world)
	var realm := game.world as TwilightRealm
	check.call(is_equal_approx(GameState.potion_time("sprint"),9) and not game.boss_revival_available(), "temporary sprint survives the world handoff while revival stays locked outside the boss chamber")
	realm.player.position = RealmDB.BOSS_TRIGGER.get_center()
	realm._physics_process(0.01)
	check.call(not game.boss_revival_available(), "entering the chamber before earning Citadel access cannot enable revival")
	preload("res://tools/citadel_checks.gd").prepare_fixture(realm)
	realm.boss.set_physics_process(false)
	check.call(realm._boss_arrived and game.boss_revival_available(), "the earned Citadel approach enables boss-only revival")
	GameState.data.expedition.gold = 37
	var boss_hp := realm.boss.hp
	realm.player.invulnerable = 0
	realm.player.take_damage(GameState.health_max()+GameState.defense()+1000,realm.boss.position)
	check.call(GameState.health() == maxi(1,roundi(GameState.health_max()*0.5)) and not realm.player.dead and not game._defeat_pending and GameState.item_count("boss_revival_potion") == revival_stock-1, "a portal boss fatal hit consumes one revival and restores half HP without defeat")
	check.call(GameState.expedition_active() and int(GameState.data.expedition.gold) == 37 and realm.boss.hp == boss_hp, "revival preserves expedition loot, the boss HP and the current fight")
	var after_revival := GameState.item_count("boss_revival_potion")
	realm.player.take_damage(99999,realm.boss.position)
	check.call(GameState.item_count("boss_revival_potion") == after_revival and realm.player.invulnerable >= 2, "revival protection prevents overlapping attacks from spending another bottle")
	if capture.is_valid(): await capture.call("potions_02_portal_revival")
	realm.reset_boss()
	check.call(not game.boss_revival_available(), "leaving the chamber immediately disables revival again")
	GameState.save_game()
	var bottles: Dictionary = {}
	for id in POTIONS: bottles[id] = GameState.item_count(id)
	check.call(GameState.load_game() and POTIONS.all(func(id: String) -> bool: return GameState.item_count(id) == int(bottles[id])) and GameState.potion_time("sprint") == 0, "save/load preserves remaining bottles without restoring consumed temporary boosts")
	game._clear_world()
	var ocean := OceanJourney.new()
	game.world = ocean
	game._world_holder.add_child(ocean)
	ocean.set_process(false)
	var shield_before := GameState.item_count("shield_potion")
	check.call(not game.boss_revival_available() and not bool(GameState.consume_item("shield_potion").ok) and GameState.item_count("shield_potion") == shield_before, "sea turtle play cannot use land potions or boss revival")
	game._clear_world()
	var island := KrakenIsland.new()
	game.world = island
	game._world_holder.add_child(island)
	game.hud.set_world(island)
	game.hud.show()
	_freeze(island)
	GameState.set_health(GameState.health_max())
	check.call(game.boss_revival_available(), "the live Kraken arena enables boss revival")
	island.player.invulnerable = 0
	island.player.take_damage(99999,island.boss.position)
	check.call(not island.player.dead and GameState.health() > 0 and not game._defeat_pending and GameState.item_count("boss_revival_potion") == after_revival-1, "Kraken combat revives Adam in place instead of triggering home recovery")
	if capture.is_valid(): await capture.call("potions_03_kraken_revival")
	var owns := game.world
	game.world = null
	check.call(not game.boss_revival_available(), "a retired world cannot authorize a revival")
	var before_stale := GameState.health()
	island.player.invulnerable = 0
	island.player.take_damage(99999)
	check.call(GameState.health() == before_stale, "a retired player cannot damage the new journey or consume a revival")
	game.world = owns
	island.defeated = true
	check.call(not game.boss_revival_available(), "a defeated Kraken never authorizes a late revival")
	GameState.data = saved
	GameState.clear_potion_effects()
	GameState._emit_all()
	await game._load_lobby(false)
	GameState._potion_times = effects
	GameState._last_purchase = purchases
	GameState.autosave_enabled = autosave
	game.set_process(ticking)

static func _freeze(world: Node) -> void:
	world.set_process(false)
	world.set_physics_process(false)
	for node in world.get_children():
		if node is Player or node is Enemy or node is Pet: node.set_physics_process(false)

static func _text(node: Node, needle: String) -> bool:
	if node is Label and node.text.contains(needle): return true
	for child in node.get_children():
		if _text(child,needle): return true
	return false

static func _use_button(panel: InventoryPanel, id: String) -> Button:
	for child in panel.content.get_children():
		if child is PanelContainer and _text(child,ItemDB.name_of(id)):
			return _button(child)
	return null

static func _button(node: Node) -> Button:
	if node is Button and node.text == "Use": return node
	for child in node.get_children():
		var found := _button(child)
		if found: return found
	return null
