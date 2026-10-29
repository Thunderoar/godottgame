extends Node
## End-to-end acceptance test for the updated Tidesworn rules.
## Run as a scene so project autoloads are initialised:
##   godot --headless --path . res://tools/tide_test.tscn

var game: Node
var hud: Node
var fails := 0
var checks := 0


func _ready() -> void:
	if not TestEnvironment.require_isolation():
		get_tree().quit(1)
		return
	GameState.delete_save()
	game = load("res://scenes/game.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	_check(game.title_screen != null, "title screen exists")
	_check(GameState.has_existing_save == false, "clean save state")
	_check(_has_label(game.title_screen, "PB (Protect BESUT)"), "title reads PB (Protect BESUT)")
	_check(_has_label(game.title_screen, "Created by Qayyim, Farhan & Ayiz"), "creator credit is present")
	_check(not game.title_screen._heroes.is_visible_in_tree(), "Choose Your Road stays hidden until Start Game")
	_check(CharacterDB.ids() == ["adam", "arjun", "mei_ling"], "Adam, Arjun and Mei Ling are defined")
	_check(CharacterDB.weapon_style("adam") == "sword", "Adam uses a sword")
	_check(CharacterDB.weapon_style("arjun") == "scythe", "Arjun uses a scythe")
	_check(CharacterDB.weapon_style("mei_ling") == "bow", "Mei Ling uses a bow")
	_check(not ItemDB.exists("pet_revival"), "Pet Revival Potion is removed")
	_check(not ItemDB.exists("mana_potion") and not ItemDB.stock_for("potion").has("mana_potion"), "mana potion is removed from the item catalogue and shop")
	_check(not GameState.data.has("mana") and not GameState.data.has("mana_max"), "new journeys have no mana resource")

	await TitleChecks.run(game, _check)
	game.title_screen._begin_button.pressed.emit()
	var opening_story: StorySequence
	for scene in game.get_children():
		if scene is StorySequence: opening_story = scene
	_check(opening_story != null and opening_story._arrival_active and game.title_screen != null, "Adam handoff keeps the title until a covered transition replaces it")
	_check(opening_story != null and opening_story._page_time == 0 and not game.hud.visible, "opening arrival hides HUD and preserves the first beat's reading time")
	_check(opening_story != null and opening_story.include_loading_screen and opening_story.opening_loader() != game.loading_screen, "Adam opening owns the existing loading-screen UI independently of world transitions")
	await get_tree().process_frame
	for scene in game.get_children():
		if scene is StorySequence: scene.finish()
	for frame in 100:
		if is_instance_valid(game.world) and not game._transitioning:
			break
		await get_tree().create_timer(0.05).timeout
	await get_tree().process_frame
	await get_tree().process_frame
	hud = game.get("hud")
	_check(game.world is Lobby, "lobby loads after character select")
	_check(game.call("player") != null, "player exists")
	_check(get_tree().get_first_node_in_group("pet") != null, "starter pet exists")
	var village_layout: WorldLayout = game.world._layout
	var monster_gate := village_layout.position_of("monster_portal")
	var pet_gate := village_layout.position_of("pet_portal")
	_check(monster_gate.is_equal_approx(Vector2(34.8, 6.3)) and pet_gate.is_equal_approx(Vector2(41.2, 6.3)), "both portals stand side by side at the northern map edge")
	_check(game.world.get_node_or_null("TwinCaveHill") == null and game.world.get_node_or_null("CaveRockCollision") == null, "cave artwork and cave collision are removed")
	_check(GameState.item_count("rusty_sword") == 1, "Qayyim owns a starter sword")
	_check(GameState.equipped_item("weapon") == "rusty_sword", "starter sword equipped")
	_check(GameState.active_pet_id() == "ember", "starter pet active")
	_check(GameState.has_living_pet(), "starter pet alive")
	_check(GameState.water_keeper_count() == 1, "new journeys start with one water keeper")
	_check(game.call("player").get_node_or_null("VitalHud") is PlayerVitalHud, "player keeps its world HP/XP indicator")
	_check(not _has_label(hud, "VITALS") and hud.get("_health_bar") == null and hud.get("_pet_bar") == null, "obsolete top-right VITALS construction is removed")
	_check(hud.get("_minimap") is VillageMinimap, "live minimap exists at the top right")
	_check(hud.get("_emergency_panel") != null, "emergency HUD exists")
	_check(hud.get("_recovery_panel") != null, "recovery HUD exists")
	_check(hud.get("_joystick") != null, "touch joystick exists")
	_check(hud.get("_attack_button").action == "attack", "touch attack maps to attack action")
	_check(hud.get("_interact_button").action == "sprint", "permanent touch Sprint maps to sprint action")
	_check(hud.get("_inventory_button").action == "open_inventory", "backpack touch action exists")
	_check(hud.get("_inventory_button").position.x > 210, "Pack sits beside the joystick away from combat controls")
	_check(hud.get("_build_button") == null, "Build lives in Menu rather than the world HUD")
	_check(not GameState.is_night() and GameState.time_string().begins_with("DAY"), "new journeys begin with a peaceful three-minute day")
	_check(game.world.capture_monsters().is_empty(), "no home monsters spawn on the first day")
	_check(hud.tutorial_guide.visible, "New Journey tutorial starts on a new game")
	_check(hud.tutorial_guide.get("STEPS").size() == 10, "New Journey teaches ten sequential actions")
	hud.tutorial_guide.call("_skip")
	var interactables := get_tree().get_nodes_in_group("interactable")
	_check(interactables.size() >= 10, "lobby interactions present (%d)" % interactables.size())
	_check(hud.get("_toast_box") == null, "in-game pop-up notifications are removed")
	hud.call("show_toast", "ignored")
	_check(hud.get("_toast_box") == null, "toast calls cannot create pop-up notifications")
	var xp_bar := hud.get("_xp_bar") as SegmentedBar
	var pet_xp_bar := hud.get("_pet_xp_bar") as SegmentedBar
	_check(xp_bar == null and game.player().get_node_or_null("VitalHud") != null, "player XP is displayed overhead")
	_check(pet_xp_bar == null and game.world.pet.get_node_or_null("PetHealth") != null, "pet XP is displayed overhead")
	await KampungChecks.run(game, _check)
	await WorldChecks.run(game, _check)
	await MonsoonChecks.run(game, _check)
	await _test_day_night()
	await _test_settlement_expansion()
	var resident_count := 0
	var defender_count := 0
	for node in get_tree().get_nodes_in_group("settlement_target"):
		if node is Resident:
			resident_count += 1
			if bool(node.get("combat_enabled")):
				defender_count += 1
	_check(resident_count >= 8, "residents populate the settlement (%d)" % resident_count)
	_check(defender_count >= 2, "capable residents are available for defence (%d)" % defender_count)

	var portal_ids := PortalDB.ordered_ids()
	_check(portal_ids.size() >= 10, "portal campaign has at least ten levels")
	var abilities := {}
	for portal_id in portal_ids:
		var def := PortalDB.get_portal(portal_id)
		_check(int(def.get("monster_count", 0)) >= 10, "%s has at least ten regular monsters" % portal_id)
		_check(str(def.get("boss_ability", "")) != "", "%s defines a boss ability" % portal_id)
		_check(PixelArt.enemy_texture(str(def.get("boss_id", "")), true) != null, "%s boss art generates" % portal_id)
		abilities[str(def.get("boss_ability", ""))] = true
	_check(abilities.size() >= 4, "boss abilities cover punches, projectiles, charges and area attacks")
	_check(ItemDB.get_item("pet_food").shop == "pet" and int(ItemDB.get_item("pet_food").price) > 0, "Pet Food is sold in the Pet Shop for Gold")
	# Keep the periodic rubbish spawner quiet until the dedicated rubbish test.
	var system := get_tree().get_first_node_in_group("rubbish_system") as RubbishSystem
	if system != null:
		system.spawn_interval = 99999.0
		system.set("_timer", 0.0)

	await _test_visual_repairs()
	await DeepAuditChecks.run(game, _check)
	await CreativeChecks.run(game, _check)
	await _test_movement()
	await _test_gathering()
	await _test_shops()
	await _test_visual_overhaul_contracts()
	await _test_house_and_sleep()
	await _test_menu_and_settings()
	await _test_auto_heal_and_shield()
	await _test_pet_support()
	await _test_pet_battle_portal()
	await _test_rubbish_system()
	await _test_portal_combat_and_auto_loot()
	await _test_emergency_attack()
	await _test_defeat_and_recovery()
	await _test_boss_and_progression()
	await _test_second_portal()
	await _test_save_load()
	await _test_build_editor()
	await _test_character_styles()
	await _test_village_systems()
	await _test_forest_restoration()
	await _test_pet_shop_close()
	await preload("res://tools/combat_revamp_checks.gd").run(game, _check)
	await preload("res://tools/coastal_checks.gd").run(game, _check)
	await preload("res://tools/portal_tutorial_checks.gd").run(game, _check)
	await preload("res://tools/control_ocean_checks.gd").run(game, _check)
	await preload("res://tools/kraken_hunger_checks.gd").run(game, _check)
	await StoryChecks.run(game, _check)
	await MapUnlockChecks.run(game, _check)
	await _test_forest_game_over()

	GameState.delete_save()
	print("--- tide test: %d checks, %s ---" % [checks, "PASS" if fails == 0 else "%d FAILURE(S)" % fails])
	get_tree().quit(0 if fails == 0 else 1)


func _test_movement() -> void:
	var p: Player = game.call("player")
	var start := p.global_position
	Input.action_press("move_right")
	await get_tree().create_timer(0.35).timeout
	Input.action_release("move_right")
	await get_tree().create_timer(0.1).timeout
	_check(p.global_position.x > start.x + 0.2, "keyboard/action movement works")
	p.global_position = Lobby.SPAWN
	await get_tree().process_frame


func _test_day_night() -> void:
	for gun in get_tree().get_nodes_in_group("house_defenses"):
		gun.set_process(false)
	game.set_process(false)
	var lobby := game.world as Lobby
	for gun in game.get_tree().get_nodes_in_group("house_defenses"):
		gun.set_process(false)
	GameState.advance_world_clock(179.0 - float(GameState.data.get("world_time", 0.0)))
	_check(not GameState.is_night() and lobby.capture_monsters().is_empty(), "first day stays peaceful before 180 seconds")
	lobby._spawn_forest_monsters(5)
	lobby._spawn_emergency_monsters(3)
	lobby._rubbish_system.on_rubbish_beached(null)
	_check(lobby.spawn_sea_urchin(Vector2(17, 29)) == null and lobby.capture_monsters().is_empty(), "all fire, beach and emergency spawn paths reject daytime")
	GameState.advance_world_clock(1.0)
	_check(GameState.is_night() and GameState.time_string() == "NIGHT 3:00", "night begins exactly at three minutes")
	_check(lobby._forest_monsters.size() == Lobby.FIRE_MONSTER_COUNT, "night spawns twenty-four fire monsters")
	_check(lobby.capture_monsters().size() == Lobby.FIRE_MONSTER_COUNT + Lobby.NIGHT_URCHIN_COUNT, "night also spawns sea urchins at the beach")
	for enemy in lobby.get_children():
		if enemy is Enemy:
			enemy.set_physics_process(false)
	var fire := lobby._forest_monsters[0]
	fire.hp = 11
	var count := lobby.capture_monsters().size()
	GameState.advance_world_clock(180.0)
	_check(not GameState.is_night() and GameState.time_string() == "DAY 3:00", "day returns after three minutes of night")
	_check(is_instance_valid(fire) and fire.hp == 11 and lobby.capture_monsters().size() == count, "dawn preserves living monsters and their HP")
	var tree := lobby._forest_trees[0]
	var hp_before := tree.health
	fire._target = tree
	fire.global_position = tree.global_position + Vector2(0.7, 0)
	fire._hit_dealt = false
	fire._attack_active(0.0)
	_check(tree.health < hp_before, "surviving fire monsters continue attacking trees in daytime")
	tree.water(tree.max_health)
	GameState.save_game()
	_check(GameState.load_game() and not GameState.is_night(), "day/night phase survives save/load")
	game.call("_load_lobby", false)
	await get_tree().process_frame
	await get_tree().process_frame
	lobby = game.world as Lobby
	_check(lobby.capture_monsters().size() == count and lobby._forest_monsters[0].hp == 11, "returning home in daytime restores survivors without a new wave")
	for enemy in lobby.get_children():
		if enemy is Enemy:
			enemy.set_physics_process(false)
	lobby._forest_monsters[0].take_damage(99999)
	_check(lobby.capture_monsters().size() == count - 1, "killed monsters stay absent during the day")
	GameState.advance_world_clock(180.0)
	_check(GameState.is_night() and lobby.capture_monsters().size() == count, "the next night replenishes killed monsters")
	lobby._on_day_phase_changed(true, true)
	_check(lobby.capture_monsters().size() == count, "a night wave cannot spawn twice during the same night")
	# Remove this test's sea threats before the separate peaceful shopping fixtures.
	for enemy in lobby.get_children():
		if enemy is Enemy and enemy.kind == "urchin":
			enemy.queue_free()
	await get_tree().process_frame
	for enemy in lobby.get_children():
		if enemy is Enemy:
			enemy.set_physics_process(false)
	for gun in get_tree().get_nodes_in_group("house_defenses"):
		gun.set_process(false)
	game.set_process(true)


func _test_settlement_expansion() -> void:
	var monster_gate: PortalEntrance = null
	var pet_gate: PortalEntrance = null
	for node in get_tree().get_nodes_in_group("battle_portal"):
		if node is PortalEntrance:
			if str(node.gate_kind) == "pet":
				pet_gate = node
			else:
				monster_gate = node
	_check(monster_gate != null and pet_gate != null, "monster and pet battle portals exist")
	_check(get_tree().get_nodes_in_group("battle_portal").size() == 2, "the two battle portals are paired")
	if monster_gate != null and pet_gate != null:
		_check(absf(monster_gate.position.y - pet_gate.position.y) < 0.2 and absf(monster_gate.position.x - pet_gate.position.x) < 10.0, "monster and pet portals stand side by side")

	var trees := get_tree().get_nodes_in_group("forest_tree")
	_check(trees.size() >= 60, "the forest contains many protected trees (%d)" % trees.size())
	if not trees.is_empty():
		var tree := trees[0] as ForestTree
		var tree_hp := tree.health
		var hits_before := tree.hit_count
		tree.take_attack_damage(12)
		_check(tree.health < tree_hp, "forest trees lose HP when monsters attack")
		_check(tree.hit_count == hits_before + 1, "tree attacks still play visual feedback")
		_check(not tree.fallen, "a damaged tree remains standing until its HP reaches zero")
	var forest_monsters := get_tree().get_nodes_in_group("forest_monsters").filter(func(node: Node) -> bool: return is_instance_valid(node) and node is Enemy and not node.dead and not node.is_queued_for_deletion() and node.get_parent() == game.world)
	_check(forest_monsters.size() >= 12, "many forest monsters patrol the woodland (%d)" % forest_monsters.size())
	_check(Sfx.has_sound("tree_hit") and Sfx.has_sound("aggro"), "physical-tree-hit and aggro sounds are generated")
	if not forest_monsters.is_empty() and game.call("player") != null:
		var forest_monster := forest_monsters[0] as Enemy
		var test_player: Player = game.call("player")
		var old_player_pos := test_player.global_position
		var old_monster_pos := forest_monster.global_position
		test_player.global_position = (game.world as Lobby)._layout.position_of("arrival")
		test_player.velocity = Vector2.ZERO
		forest_monster.global_position = test_player.global_position + Vector2(0.8, 0)
		forest_monster.velocity = Vector2.ZERO
		await get_tree().physics_frame
		await get_tree().physics_frame
		var sees_player := bool(forest_monster.call("_can_see_player"))
		forest_monster.set("_saw_player", false)
		forest_monster.call("_update_forest_target")
		_check(sees_player, "fire monsters can see nearby players")
		_check(forest_monster.get("_target") != null and not bool(forest_monster.get("_charging")), "fire monsters choose a nearby actor or tree without a player charge")
		test_player.global_position = old_player_pos
		forest_monster.global_position = old_monster_pos
	_check(get_tree().get_nodes_in_group("resident_house").size() >= 7, "more residents' houses stand around the village (%d)" % get_tree().get_nodes_in_group("resident_house").size())
	_check(get_tree().get_nodes_in_group("ruin_house").size() >= 3, "abandoned, damaged and destroyed houses decorate the outskirts")
	_check(get_tree().get_nodes_in_group("horses").size() >= 2, "horses live in the village")
	_check(PixelArt.animal_texture("horse") != null, "horse art generates")
	_check(get_tree().get_nodes_in_group("flowers").size() >= 4, "authored flower beds frame selected household plots")
	_check(get_tree().get_nodes_in_group("garden").size() >= 6, "more gardens fill the village")
	var decoration_count := 0
	for node in get_tree().get_nodes_in_group("placeable"):
		if node is SettlementPlaceable and str(node.category) == "decoration":
			decoration_count += 1
	_check(decoration_count >= 9, "decorative props are placed around the village (%d)" % decoration_count)

	var npc_label_count := 0
	for node in get_tree().get_nodes_in_group("settlement_target"):
		if node is Resident:
			npc_label_count += _count_labels(node)
	for node in get_tree().get_nodes_in_group("interactable"):
		if node is ShopNPC or node is CoastalGuard:
			npc_label_count += _count_labels(node)
	_check(npc_label_count == 0, "NPC name labels are removed")

	var duel_ids := PetBattleDB.ordered_ids()
	_check(duel_ids.size() >= 5, "pet battle portal has multiple levels")
	for level_id in duel_ids:
		var def := PetBattleDB.get_level(level_id)
		_check(not def.is_empty() and int(def.get("hp", 0)) > 0, "%s defines a 1v1 opponent" % level_id)
	_check(bool(GameState.pet_battle_state(duel_ids[0]).get("unlocked", false)), "first pet duel is available")
	_check(not bool(GameState.pet_battle_state(duel_ids[1]).get("unlocked", false)), "later pet duels unlock in order")
	await get_tree().process_frame
	hud.call("_update_mission_guide")
	_check(hud.get("_mission_panel") == null and hud.get("_mission_arrows").is_empty(), "bottom mission notifications are removed")
	_check(game.world.get_children().any(func(node: Node) -> bool: return node is MissionPath), "dashed mission path lives in the world")
	var player := game.call("player") as Player
	_check(player != null and player.get_node_or_null("VitalHud") is PlayerVitalHud, "player has a floating Health/XP dashboard")
	var special_npc: UniszaStudent = null
	for node in get_tree().get_nodes_in_group("special_npc"):
		if node is UniszaStudent:
			special_npc = node
	_check(special_npc != null, "yellow Unisza NPC exists")
	if special_npc != null:
		special_npc.call("interact", player)
		await get_tree().process_frame
		_check(hud.dialogue_panel.visible, "yellow NPC opens a dialogue box")
		_check(_has_label(hud.dialogue_panel, "“Welcome to Unisza”"), "dialogue contains the Welcome to Unisza line")
		_check(_has_label(hud.dialogue_panel, "“We are students from Unisza.”"), "dialogue contains the Unisza students line")
		hud.hide_modals()
		await get_tree().process_frame
	for monster in forest_monsters:
		if is_instance_valid(monster):
			monster.set_physics_process(false)


func _test_gathering() -> void:
	var pile: ResourcePile = null
	for node in get_tree().get_nodes_in_group("interactable"):
		if node is ResourcePile:
			pile = node
			break
	_check(pile != null, "driftwood gathering point exists")
	if pile == null:
		return
	var gold_before := GameState.gold()
	var wood_before := GameState.item_count("wood")
	pile.call("interact", game.call("player"))
	_check(GameState.item_count("wood") == wood_before + 2, "gathering yields driftwood")
	var sale := GameState.sell_item("wood", GameState.item_count("wood"))
	_check(bool(sale.ok), "driftwood can be sold")
	_check(GameState.gold() == gold_before + 8, "selling driftwood grants gold")


func _test_shops() -> void:
	var gold_before := GameState.gold()
	var count_before := GameState.item_count("health_potion")
	var result := GameState.buy_item("health_potion")
	_check(bool(result.ok), "health potion purchase succeeds")
	_check(GameState.gold() == gold_before - 25, "potion deducts 25 gold")
	_check(GameState.item_count("health_potion") == count_before + 1, "potion added to inventory")

	GameState.data.gold = 0
	var poor := GameState.buy_item("leather_vest")
	_check(not bool(poor.ok) and str(poor.get("message", "")) == "Not enough gold." and GameState.gold() == 0, "purchase rejected with insufficient gold")
	GameState.data.gold = 500

	var treat_before := GameState.item_count("pet_food")
	var first := GameState.buy_item("pet_food")
	var rapid := GameState.buy_item("pet_food")
	_check(bool(first.ok), "first rapid treat tap succeeds")
	_check(not bool(rapid.ok), "repeat tap is debounced")
	_check(GameState.item_count("pet_food") == treat_before + 1, "debounced tap buys only one item")
	var pet_before := GameState.get_active_pet()
	var pet_xp_before := int(pet_before.get("xp", 0))
	var fed := GameState.feed_active_pet()
	_check(bool(fed.ok), "pet food can be fed to the active companion")
	var pet_after := GameState.get_active_pet()
	_check(int(pet_after.get("xp", 0)) > pet_xp_before or int(pet_after.get("level", 1)) > int(pet_before.get("level", 1)), "feeding pet food grants pet XP")

	var sword := GameState.buy_item("iron_sword")
	_check(bool(sword.ok), "equipment purchase succeeds")
	var equipped := GameState.equip_item("iron_sword")
	_check(bool(equipped.ok), "equipment can be equipped")
	_check(GameState.equipped_item("weapon") == "iron_sword", "equipped weapon updates")
	var styles := ItemDB.equipment_for_style("sword")
	_check("iron_sword" in styles and not ("reed_bow" in styles), "equipment counter filters by weapon discipline")

	game.call("open_shop", "potion", "Mara")
	await get_tree().create_timer(0.2).timeout
	_check(hud.shop_panel.visible, "shop panel opens")
	hud.hide_modals()
	await get_tree().process_frame


func _test_visual_overhaul_contracts() -> void:
	# 3C: Strike icon follows the active hero's weapon discipline.
	_check(str(hud.get("_attack_button").icon_kind) == GameState.character_weapon_style(), "strike icon follows the hero's weapon")
	# 3C: the detailed 32px icon set generates for the key kinds.
	for kind in ["sword", "scythe", "bow", "talk", "door", "bed", "gather", "chest", "gold", "diamond", "close", "pet"]:
		_check(PixelArt.icon(kind, 32) != null, "32px icon generates for %s" % kind)
	# 3E: portal art is driven by PortalDB themes, never portal ids.
	var themes := {}
	for portal_id in PortalDB.ordered_ids():
		var theme := str(PortalDB.get_portal(portal_id).get("theme", ""))
		themes[theme] = true
		_check(PixelArt.portal_frame_texture(theme, false) != null and PixelArt.portal_frame_texture(theme, true) != null, "%s frame art generates (live and sealed)" % theme)
		_check(PixelArt.portal_swirl_texture(theme, 0) != null and PixelArt.portal_swirl_texture(theme, 7) != null, "%s swirl frames generate" % theme)
	_check(themes.size() >= 10, "all ten portal themes are distinct (%d)" % themes.size())
	# 3A: upgrade price has a single source of truth.
	_check(GameState.pet_upgrade_cost(1) == 80 and GameState.pet_upgrade_cost(3) == 150 and GameState.pet_upgrade_cost(5) == 220, "pet upgrade price comes from GameState.pet_upgrade_cost")
	# Quality settings sanitise on write.
	GameSettings.set_effects_quality("bogus")
	_check(GameSettings.effects_quality() == "high", "unknown effects quality falls back to high")
	GameSettings.set_effects_quality("low")
	_check(GameSettings.effects_quality() == "low", "effects quality accepts low")
	GameSettings.set_effects_quality("high")
	GameSettings.set_reduce_motion(true)
	_check(GameSettings.reduce_motion(), "reduce motion stores")
	GameSettings.set_reduce_motion(false)
	# 3A: shops refresh in place, so the scroll position survives data_changed
	# (including the sea-cleaning gold drip).
	game.call("open_shop", "pet", "Nia")
	await get_tree().create_timer(0.3).timeout
	_check(hud.shop_panel.visible, "shop opens for the scroll test")
	var scroll := hud.shop_panel.body as ScrollContainer
	scroll.scroll_vertical = 999999
	await get_tree().process_frame
	var before := scroll.scroll_vertical
	_check(before > 0, "shop content is long enough to scroll (%d)" % before)
	GameState.data_changed.emit()
	await get_tree().create_timer(0.1).timeout
	_check(scroll.scroll_vertical == before, "shop keeps its scroll position on data_changed")
	GameState.data_changed.emit()
	await get_tree().create_timer(0.1).timeout
	_check(scroll.scroll_vertical == before, "shop keeps its scroll position across repeated updates")
	hud.hide_modals()
	await get_tree().process_frame


func _test_house_and_sleep() -> void:
	var builder: ShopNPC = null
	for node in get_tree().get_nodes_in_group("interactable"):
		if node is ShopNPC and str(node.shop_type) == "house":
			builder = node
	_check(builder != null, "dedicated construction shop keeper exists")
	var construction_shop := _find_placeable(game.world, "shop_house")
	_check(construction_shop != null and str(construction_shop.category) == "shop", "dedicated construction shop building exists")
	if builder != null:
		builder.call("interact", game.call("player"))
		await get_tree().process_frame
		_check(hud.house_panel.visible, "construction shop opens the house upgrade panel")
		_check("Construction" in hud.house_panel.header_label.text, "house panel is branded as the construction shop")
		hud.hide_modals()
		await get_tree().process_frame
	GameState.data.gold = 9999
	GameState.data.diamonds = 0
	var fail := GameState.upgrade_house()
	_check(not bool(fail.ok), "house rejects gold-only upgrade")
	GameState.data.diamonds = 500
	for i in 4:
		var result := GameState.upgrade_house()
		_check(bool(result.ok), "house upgrade %d succeeds" % (i + 2))
	_check(GameState.house_level() == 5, "house reaches level 5")
	_check(is_equal_approx(GameState.sleep_recovery_seconds(), 2.0), "level 5 recovery is 2 seconds")
	GameState.set_health(10)
	var p: Player = game.call("player")
	var entrance: HomeEntrance
	for node in get_tree().get_nodes_in_group("interactable"):
		if node is HomeEntrance:
			entrance = node
	_check(entrance != null, "main-house entrance replaces the bed")
	entrance.interact(p)
	await get_tree().create_timer(2.3).timeout
	_check(GameState.health() == GameState.health_max(), "home interior restores health at the house level rate")
	await game.leave_home()
	_check(not is_instance_valid(game.home_interior), "home doorway returns the player outside")


func _test_menu_and_settings() -> void:
	var menu_button := hud.get("_menu_button") as Button
	_check(menu_button != null and menu_button.anchor_left >= 0.99, "Menu button sits in the top-right corner")
	game.call("open_menu")
	await get_tree().process_frame
	_check(hud.menu_panel.visible, "Menu button opens the in-game menu")
	hud.menu_panel.close_panel()
	await get_tree().process_frame
	game.call("open_settings")
	await get_tree().process_frame
	_check(hud.settings_panel.visible, "Settings can be opened from the menu system")
	var old_scale := float(hud.get_gui_scale())
	hud.call("set_gui_scale", 1.10)
	_check(is_equal_approx(hud.get_gui_scale(), 1.10) and is_equal_approx(GameState.gui_scale(), 1.10), "GUI scale setting applies and persists")
	hud.call("set_control_layout", "attack", 100.0, 500.0, 88.0)
	var attack := hud.get("_attack_button") as TouchActionButton
	_check(attack.get_global_rect().position.distance_to(Vector2(100, 500)) < 0.5 and is_equal_approx(attack.diameter, 88.0), "button positions and sizes are customizable")
	hud.call("set_gui_scale", old_scale)
	hud.call("reset_control_layout")
	hud.settings_panel.close_panel()
	await get_tree().process_frame


func _test_auto_heal_and_shield() -> void:
	if GameState.item_count("health_potion") == 0:
		GameState.add_item("health_potion", 2, true)
	GameState.set_health(int(round(GameState.health_max() * 0.10)) + 1)
	GameState.data.shield = 0
	var potions := GameState.item_count("health_potion")
	GameState.damage_player(6)
	_check(GameState.health() > int(round(GameState.health_max() * 0.10)), "critical health triggers an automatic potion")
	_check(GameState.item_count("health_potion") == potions - 1, "auto-heal consumes one health potion")

	GameState.set_health(GameState.health_max())
	GameState.add_shield(20)
	var hp_before := GameState.health()
	GameState.damage_player(10)
	_check(GameState.health() == hp_before, "pet shield absorbs damage before health")
	_check(GameState.shield() < 20, "shield value decreases when hit")


func _test_pet_support() -> void:
	GameState.data.gold = 5000
	var heal_before := PetDB.heal_amount("ember", 1)
	var attack_before := PetDB.attack_damage("ember", 1)
	var shield_before := PetDB.shield_amount("ember", 1)
	var up := GameState.upgrade_pet("ember")
	_check(bool(up.ok), "pet level upgrade succeeds")
	_check(PetDB.heal_amount("ember", 2) > heal_before, "pet healing grows with level")
	_check(PetDB.attack_damage("ember", 2) > attack_before, "pet attack grows with level")
	_check(PetDB.shield_amount("ember", 2) > shield_before, "pet shield grows with level")
	var pet: Pet = get_tree().get_first_node_in_group("pet")
	_check(pet.get_node_or_null("PortalLight") == null, "pet no longer emits portal light")
	GameState.revive_active_pet()
	_check(GameState.has_living_pet(), "pet can always be restored without a revival item")


func _test_pet_battle_portal() -> void:
	var pet_gate: PortalEntrance
	for node in get_tree().get_nodes_in_group("battle_portal"):
		if node is PortalEntrance and node.gate_kind == "pet":
			pet_gate = node
	_check(pet_gate != null, "pet battle gate is interactable")
	pet_gate.interact(game.player())
	await get_tree().process_frame
	await get_tree().process_frame
	var panel := hud.pet_battle_panel as PetBattlePanel
	_check(panel.visible, "pet portal opens tournament")
	var gold_before := GameState.gold()
	var level_before := int(GameState.get_active_pet().get("level", 1))
	_check(panel.start_battle("pet_duel_1"), "first duel starts")
	_check(PetBattlePanel.SKILLS.size() == 3 and panel._skill_buttons.size() == 3, "three manual powers are available")
	var hp := panel._player_hp
	var enemy_hp := panel._opponent_hp
	panel._process(30)
	_check(panel._player_hp == hp and panel._opponent_hp == enemy_hp, "duel waits indefinitely for player input")
	panel._enemy_choice = "attack"
	panel.choose_skill("attack")
	_check(panel._opponent_hp < enemy_hp and panel._player_hp == hp, "player acts before opponent")
	panel._process(0.71)
	_check(panel._player_hp < hp and float(panel._enemy_cooldowns.attack) > 0, "enemy replies on its own turn and cooldown")
	panel._process(0.61)
	enemy_hp = panel._opponent_hp
	panel.choose_skill("attack")
	_check(panel._turn_active and panel._opponent_hp == enemy_hp, "cooling-down power is blocked")
	panel._enemy_choice = "burst"
	panel.choose_skill("defend")
	panel._process(0.71)
	_check(panel.get_children().any(func(n: Node) -> bool: return n is PetHitEffect and n.kind == "shield"), "shield power has visible defense effect")
	panel._process(0.61)
	panel._opponent_hp = 1
	panel.choose_skill("burst")
	await get_tree().process_frame
	_check(GameState.pet_battle_state("pet_duel_1").get("cleared", false), "pet duel victory is recorded")
	_check(GameState.pet_battle_state("pet_duel_2").get("unlocked", false), "victory unlocks next duel")
	_check(GameState.gold() > gold_before and int(GameState.get_active_pet().get("level", 1)) > level_before, "victory grants Gold and pet level")
	panel.close_panel()

func _test_rubbish_system() -> void:
	var system := get_tree().get_first_node_in_group("rubbish_system") as RubbishSystem
	_check(system != null, "rubbish system exists")
	if system == null:
		return
	var guard := system.guard
	_check(guard != null, "coastal guard exists")
	var caught_before := system.caught_count
	var beached_before := system.beached_count
	var cleaned_before := int(GameState.data.get("sea_cleaned", 0))
	var gold_before := GameState.gold()
	var caught_piece := system.spawn_piece(0)
	caught_piece.global_position = guard.global_position + Vector2(0.15, 0.0)
	await get_tree().create_timer(0.15).timeout
	_check(system.caught_count == caught_before + 1, "coastal guard catches rubbish")
	_check(GameState.gold() == gold_before + 1, "caught rubbish grants exactly +1 gold")
	_check(int(GameState.data.get("sea_cleaned", 0)) == cleaned_before + 1, "sea-cleaning progress is recorded")
	_check(hud.get("_toast_box") == null, "sea cleaning does not create pop-up notifications")
	guard.call("interact", game.call("player"))
	await get_tree().process_frame
	_check(hud.sea_cleaning_panel.visible, "Coastal Guard opens a persistent sea-cleaning report")
	hud.hide_modals()
	await get_tree().process_frame

	var gold_after_catch := GameState.gold()
	var beached_piece := system.spawn_piece(1)
	beached_piece.global_position = beached_piece.target + Vector2(0.05, 0.0)
	await get_tree().create_timer(0.15).timeout
	_check(system.beached_count == beached_before + 1, "uncaught rubbish reaches the beach")
	_check(GameState.gold() == gold_after_catch, "beached rubbish does not grant the +1 catch reward")
	var beach_piece: BeachRubbish = get_tree().get_first_node_in_group("beach_rubbish") as BeachRubbish
	_check(is_instance_valid(beach_piece), "beached rubbish remains on the sand for manual collection")
	if is_instance_valid(beach_piece):
		var player := game.player() as Player
		var old_position := player.global_position
		player.global_position = beach_piece.global_position
		beach_piece.interact(player)
		beach_piece.interact(player)
		_check(GameState.gold() == gold_after_catch + 1, "manual beach pickup grants exactly one gold even on repeated interaction")
		player.global_position = old_position



func _test_portal_combat_and_auto_loot() -> void:
	GameState.set_health(GameState.health_max())
	game.call("enter_portal", "tidebound_grotto")
	await get_tree().create_timer(0.8).timeout
	_check(game.world is Dungeon, "portal dungeon loads")
	_check(game.world.camera.zoom.distance_to(Vector2.ONE * GameSettings.camera_zoom()) < 0.1, "dungeon inherits saved camera zoom")
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		enemy.set_physics_process(false)
	var boss_count := 0
	for enemy in enemies:
		if enemy.get("is_boss"):
			boss_count += 1
	_check(enemies.size() >= 11, "dungeon has at least 10 regular monsters plus boss (%d)" % enemies.size())
	_check(boss_count == 1, "dungeon has exactly one main boss")
	var pet: Pet = get_tree().get_first_node_in_group("pet")
	_check(pet.get_node_or_null("PortalLight") == null, "dungeon does not depend on a pet light")
	_check(get_tree().get_first_node_in_group("world") is Dungeon, "dungeon world active")
	var canvas_mod := game.world.get_node_or_null("DungeonDarkness") as CanvasModulate
	_check(canvas_mod != null, "dungeon ambient lighting exists")

	# Freeze one enemy for a controlled melee check.
	var target: Enemy = null
	for enemy in enemies:
		if not enemy.get("is_boss"):
			target = enemy
			break
	if target != null:
		var p: Player = game.call("player")
		target.speed = 0.0
		target.damage = 0
		target.global_position = p.global_position + Vector2(1.0, 0)
		p.facing = Vector2.RIGHT
		var hp_before := target.hp
		var strike: bool = bool(p.call("try_attack"))
		_check(strike, "sword attack executes")
		# Damage lands on the ACTIVE frame after the wind-up (AttackDB).
		await get_tree().create_timer(0.25).timeout
		_check(target.hp < hp_before, "sword attack damages a monster")
		target.call("take_damage", 99999, Vector2.ZERO, p)
	await get_tree().create_timer(0.7).timeout
	# A defeated monster can drop gold AND a random gem. Touch each drop;
	# collecting only the first made the floor-clear assertion RNG-dependent.
	for pickup in 16:
		var loot := _find_loot(game.world)
		if loot == null:
			break
		var p_loot: Player = game.call("player")
		p_loot.global_position = loot.global_position
		await get_tree().create_timer(0.2).timeout
	_check(int(GameState.expedition_loot().gold) > 0, "loot is auto-collected on touch without a collect button")
	await get_tree().process_frame
	_check(_find_loot(game.world) == null, "auto-collected loot disappears from the floor")

	# Pet healing, attack and shield during a frozen combat encounter.
	var p2: Player = game.call("player")
	p2.global_position = Vector2(24, 24)
	GameState.set_health(50)
	GameState.data.shield = 0
	var dummy: Enemy = null
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.speed = 0.0
		enemy.damage = 0
		if not enemy.get("is_boss") and dummy == null:
			dummy = enemy
	if dummy != null:
		dummy.max_hp = 500
		dummy.hp = 500
		dummy.global_position = p2.global_position + Vector2(1.5, 0)
		pet.global_position = p2.global_position + Vector2(-0.95, 0.5)
		pet.set("_heal_timer", 0.0)
		pet.set("_attack_timer", 0.0)
		pet.set("_shield_timer", 99.0)
		var dummy_hp := dummy.hp
		var hp_before := GameState.health()
		await get_tree().create_timer(3.3).timeout
		_check(GameState.health() > hp_before, "pet heals the player gradually in combat")
		_check(dummy.hp < dummy_hp, "pet attacks nearby monsters")
		_check(GameState.shield() > 0, "pet grants a shield during combat")


func _test_emergency_attack() -> void:
	# The player is still inside the portal. Force the emergency timer close to
	# completion and verify the dungeon keeps running.
	game.set("_portal_elapsed", 13.9)
	await get_tree().create_timer(0.35).timeout
	_check(GameState.emergency_active(), "emergency starts while exploring a portal")
	_check(hud.get("_toast_box") == null, "emergency uses the persistent HUD instead of pop-ups")
	_check(game.world is Dungeon, "emergency does not teleport the player out")
	_check(not get_tree().get_nodes_in_group("enemies").is_empty(), "portal battle is not forcibly interrupted")
	_check(hud.get("_emergency_panel").visible, "emergency HUD banner appears")
	GameState.damage_settlement(12)
	_check(GameState.emergency_damage() >= 12, "settlement damage is recorded")
	var old_level := int(GameState.data.level)
	GameState.data.level = 10
	_check(not GameState.can_enter_portal("sunken_crypt"), "portals are blocked while the settlement is under attack")
	GameState.data.level = old_level

	var dungeon: Dungeon = game.world
	dungeon.call("exit_to_lobby", true)
	await get_tree().create_timer(1.0).timeout
	_check(game.world is Lobby, "player can leave through the Shore Gate during an emergency")
	var attackers: Array[Enemy] = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if bool(enemy.get("settlement_mode")):
			attackers.append(enemy)
	_check(attackers.size() >= 3, "settlement attackers appear in the residential area")
	var from_sea := false
	var from_forest := false
	for attacker in attackers:
		if attacker.global_position.x < 18.0:
			from_sea = true
		if attacker.global_position.x > 43.0:
			from_forest = true
	_check(from_sea, "raiders can approach from the sea")
	_check(from_forest, "raiders can approach from the forest")
	var frightened := false
	var defenders := 0
	for node in get_tree().get_nodes_in_group("settlement_target"):
		if node is Resident:
			if bool(node.get("_frightened")):
				frightened = true
			if bool(node.get("combat_enabled")):
				defenders += 1
	_check(frightened, "residents react by fleeing to shelter")
	_check(defenders >= 2, "village defenders and capable residents are present")
	var gold_before := GameState.gold()
	var raider_hp_before := 0
	for attacker in attackers:
		raider_hp_before += attacker.hp
	await get_tree().create_timer(1.4).timeout
	var raider_hp_after := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if bool(enemy.get("settlement_mode")):
			raider_hp_after += enemy.hp
	_check(game.world._residents.any(func(npc: Resident) -> bool: return npc.sheltered or npc._frightened), "residents seek houses instead of fighting sea urchins")
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if bool(enemy.get("settlement_mode")):
			enemy.call("take_damage", 99999, Vector2.ZERO, game.call("player"))
	await get_tree().create_timer(0.35).timeout
	_check(not GameState.emergency_active(), "defeating all attackers completes the emergency")
	_check(not hud.get("_emergency_panel").visible, "emergency banner clears when the settlement is safe")
	_check(GameState.gold() > gold_before, "emergency monsters grant gold")


func _test_defeat_and_recovery() -> void:
	GameState.set_health(GameState.health_max())
	game.call("enter_portal", "tidebound_grotto")
	await get_tree().create_timer(0.8).timeout
	_check(game.world is Dungeon, "can re-enter portal after the emergency")
	game.call("handle_portal_defeat")
	await get_tree().create_timer(1.1).timeout
	_check(not GameState.expedition_active(), "defeat clears unbanked expedition")
	_check(GameState.has_living_pet(), "pet is not permanently killed by defeat")
	_check(GameState.recovery_active(), "defeat activates the recovery system")
	_check(hud.defeat_panel.visible, "defeat screen appears")
	_check(GameState.health() <= int(round(GameState.health_max() * 0.12)), "player respawns at critical health")
	var pet_was_alive := GameState.has_living_pet()
	game.call("return_to_lobby", true)
	await get_tree().create_timer(1.0).timeout
	_check(game.world is Lobby, "defeat returns the player home")
	var p: Player = game.call("player")
	_check(p.global_position.distance_to(Lobby.SPAWN) < 0.6, "player respawns at the cottage")
	_check(GameState.recovery_active(), "recovery remains active at home")
	_check(pet_was_alive, "pet remains available after respawn")
	# Check containment while recovery is active, before a level-five ward can
	# finish its two-second heal during the subsequent rate measurement.
	p.global_position = Lobby.RECOVERY_CENTER + Vector2(12, 0)
	game.world._tick_recovery(0.0)
	_check(p.global_position.distance_to(Lobby.RECOVERY_CENTER) <= Lobby.RECOVERY_RADIUS + 0.1, "recovery ward prevents leaving early")
	var hp_before := GameState.health()
	await get_tree().create_timer(1.0).timeout
	_check(GameState.health() > hp_before, "health regenerates inside the recovery ward")
	# Regression: the ward must heal at the HouseDB rate for the current house
	# level (level 5 = 2 s -> ~50% of max per second), not the old hardcoded
	# 8.0 s clock (~12.5% per second). Respawn health is <= 12% of max, so a
	# full second of healing gains at least 25% of max only under the fixed rate.
	_check(GameState.health() - hp_before >= int(GameState.health_max() * 0.25), "recovery ward heals at the HouseDB rate for the cottage level")
	GameState.set_health(GameState.health_max())
	await get_tree().create_timer(0.3).timeout
	_check(not GameState.recovery_active(), "full health releases the player from recovery")
	_check(not hud.get("_recovery_panel").visible, "recovery HUD hides when complete")


func _test_boss_and_progression() -> void:
	game.call("enter_portal", "tidebound_grotto")
	await get_tree().create_timer(0.8).timeout
	_check(game.world is Dungeon, "re-entered portal after recovery")
	var boss: Enemy = null
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.get("is_boss"):
			boss = enemy
			break
	_check(boss != null, "boss instance exists")
	if boss == null:
		return
	boss.call("take_damage", 999999, Vector2.ZERO, game.call("player"))
	await get_tree().create_timer(0.8).timeout
	_check(GameState.portal_state("tidebound_grotto").cleared, "boss victory permanently clears portal")
	_check(GameState.portal_state("sunken_crypt").unlocked, "boss victory unlocks next portal")
	_check(not GameState.get_pet("luma").is_empty(), "first clear grants unique companion")
	_check(hud.victory_panel.visible, "victory panel is shown")
	var saved_level := int(GameState.data.level)
	GameState.data.level = 1
	var level_reason := GameState.portal_clear_reason("sunken_crypt")
	_check(not bool(level_reason.ok) and str(level_reason.reason).contains("level"), "under-levelled portal entry is blocked")
	GameState.data.level = saved_level
	var gold_after := GameState.gold()
	game.call("return_to_lobby", true)
	await get_tree().create_timer(0.9).timeout
	_check(game.world is Lobby, "victory returns to lobby")
	_check(game.world.camera.zoom.distance_to(Vector2.ONE * GameSettings.camera_zoom()) < 0.1, "returning lobby inherits saved camera zoom")
	_check(GameState.gold() >= gold_after, "boss rewards retained after return")


func _test_second_portal() -> void:
	GameState.data.level = maxi(3, int(GameState.data.level))
	GameState.set_health(GameState.health_max())
	game.call("enter_portal", "sunken_crypt")
	await get_tree().create_timer(0.8).timeout
	_check(game.world is Dungeon, "second portal loads once requirements are met")
	var enemies := get_tree().get_nodes_in_group("enemies")
	var boss: Enemy = null
	for enemy in enemies:
		if enemy.get("is_boss"):
			boss = enemy
	_check(enemies.size() >= 15, "second portal meets monster count (14 + boss)")
	_check(boss != null and str(boss.kind) == "drowned_king", "second portal spawns its own boss")
	if boss != null:
		var p: Player = game.call("player")
		p.global_position = boss.global_position + Vector2(0, 3.5)
		await get_tree().create_timer(0.35).timeout
		_check(boss.get_node_or_null("BossHealth") != null, "boss health appears overhead")
		_check("DROWNED" in boss._boss_name().to_upper(), "overhead bar belongs to the active boss")
	var dungeon: Dungeon = game.world
	dungeon.call("exit_to_lobby", true)
	await get_tree().create_timer(0.9).timeout
	_check(game.world is Lobby, "Shore Gate banks loot and returns home")
	_check(not GameState.expedition_active(), "leaving through Shore Gate closes the expedition")


func _test_save_load() -> void:
	GameState.save_game()
	var saved_gold := GameState.gold()
	var saved_house := GameState.house_level()
	var saved_clear := bool(GameState.portal_state("tidebound_grotto").cleared)
	var saved_pet_level := int(GameState.get_active_pet().level)
	var saved_pet_duel := bool(GameState.pet_battle_state("pet_duel_1").get("cleared", false))
	var saved_sea_cleaned := int(GameState.data.get("sea_cleaned", 0))
	GameState.data.gold = 0
	GameState.data.diamonds = 0
	GameState.data.house_level = 1
	GameState.portal_state("tidebound_grotto").cleared = false
	var loaded := GameState.load_game()
	_check(loaded, "save file loads")
	_check(GameState.gold() == saved_gold, "gold survives save/load")
	_check(GameState.house_level() == saved_house, "house level survives save/load")
	_check(bool(GameState.portal_state("tidebound_grotto").cleared) == saved_clear, "portal progress survives save/load")
	_check(int(GameState.get_active_pet().level) == saved_pet_level, "pet level survives save/load")
	_check(bool(GameState.pet_battle_state("pet_duel_1").get("cleared", false)) == saved_pet_duel, "pet duel progress survives save/load")
	_check(int(GameState.data.get("sea_cleaned", 0)) == saved_sea_cleaned, "sea-cleaning progress survives save/load")


func _test_build_editor() -> void:
	var p: Player = game.call("player")
	_check(not p.controls_locked, "player controls are free before building")
	game.call("toggle_build_mode")
	await get_tree().create_timer(0.2).timeout
	var editor := game.world.get_node_or_null("SettlementEditor") as SettlementEditor
	_check(editor != null and editor.active, "settlement editor toggles on")
	_check(hud.get("_build_mode_panel").visible, "settlement editor HUD appears")
	_check(p.controls_locked, "movement is locked while editing")
	var house := _find_placeable(game.world, "house")
	_check(house != null, "cottage is editable")
	if house != null:
		var before := house.global_position
		editor.call("_press", house.global_position)
		editor.call("_drag", house.global_position + Vector2(1.1, 0.6))
		editor.call("_release")
		_check(house.global_position.distance_to(before) > 0.4, "dragging repositions a settlement building")
		var saved := GameState.placeable_position("house", Vector2.ZERO)
		_check(saved.distance_to(house.global_position) < 0.01, "edited position is saved to GameState")
	game.call("toggle_build_mode")
	await get_tree().create_timer(0.2).timeout
	_check(not editor.active, "settlement editor toggles off")
	_check(not p.controls_locked, "movement is restored after editing")
	var saved_house_pos := GameState.placeable_position("house", Lobby.HOUSE_BASE)
	game.call("_load_lobby", false)
	await get_tree().create_timer(0.35).timeout
	var moved_house := _find_placeable(game.world, "house")
	_check(moved_house != null and moved_house.global_position.distance_to(saved_house_pos) < 0.01, "layout survives a lobby reload")


func _test_character_styles() -> void:
	await _test_single_style("arjun", "smith_hammer", "scythe")
	await _test_single_style("mei_ling", "reed_bow", "bow")


func _test_single_style(character_id: String, starter_weapon: String, style: String) -> void:
	GameState.new_game(character_id)
	game.call("_load_lobby", false)
	await get_tree().create_timer(0.3).timeout
	var p: Player = game.call("player")
	_check(GameState.equipped_item("weapon") == starter_weapon, "%s starts with the correct weapon" % character_id.capitalize())
	_check(str(hud.get("_attack_button").icon_kind) == style, "%s strike icon matches the weapon style" % character_id.capitalize())
	_check(GameState.character_weapon_style() == style, "%s uses the %s style" % [character_id.capitalize(), style])
	var dummy := Enemy.new()
	dummy.kind = "bogling"
	dummy.max_hp = 300
	dummy.damage = 0
	dummy.speed = 0.0
	dummy.position = p.global_position + Vector2(2.0 if style == "scythe" else 3.0, -0.65)
	game.world.add_child(dummy)
	p.facing = Vector2.RIGHT
	await get_tree().process_frame
	var hp_before := dummy.hp
	var struck: bool = bool(p.call("try_attack"))
	# Weapon wind-ups (AttackDB) delay the hit frame; bows add flight time.
	await get_tree().create_timer(0.5 if style == "bow" else 0.32).timeout
	_check(struck, "%s attack executes" % character_id.capitalize())
	_check(dummy.hp < hp_before, "%s %s attack damages a target" % [character_id.capitalize(), style])
	dummy.queue_free()


func _test_pet_shop_close() -> void:
	var window := get_window()
	var original_scale := window.content_scale_size
	var original_size := window.size
	GameState.add_gold(10000)
	for id in PetDB.shop_stock():
		if GameState.get_pet(id).is_empty():
			GameState.purchase_pet(id)
	for dimensions in [Vector2i(1280, 720), Vector2i(832, 480)]:
		window.content_scale_size = dimensions
		window.size = dimensions
		await get_tree().create_timer(0.1).timeout
		game.open_shop("pet", "Nia")
		await get_tree().create_timer(0.2).timeout
		var shop := hud.shop_panel as ShopPanel
		var close_rect := shop._close_button.get_global_rect()
		_check(get_viewport().get_visible_rect().encloses(close_rect), "pet shop Close stays on screen at %dx%d with every purchasable pet owned" % [dimensions.x, dimensions.y])
		_check(not shop.body.get_h_scroll_bar().visible, "pet cards fit without sideways scrolling")
		shop.body.scroll_vertical = 999999
		await get_tree().process_frame
		for pressed in [true, false]:
			var click := InputEventMouseButton.new()
			click.position = close_rect.get_center()
			click.button_index = MOUSE_BUTTON_LEFT
			click.pressed = pressed
			Input.parse_input_event(click)
			await get_tree().process_frame
		_check(not shop.visible and not game.player().controls_locked, "clicking Close after scrolling dismisses the pet shop and unlocks movement")
		game.open_shop("pet", "Nia")
		shop.close_panel()
		await get_tree().process_frame
		await get_tree().process_frame
		_check(not shop.visible and shop.content.get_child_count() == 0, "fast reopen and close cannot rebuild a closed pet shop")
	window.content_scale_size = original_scale
	window.size = original_size
	await get_tree().process_frame


func _test_forest_game_over() -> void:
	if not game.world is Lobby:
		game.call("_load_lobby", false)
		await get_tree().create_timer(0.35).timeout
	var trees := get_tree().get_nodes_in_group("forest_tree")
	var lobby := game.world as Lobby
	for gun in game.get_tree().get_nodes_in_group("house_defenses"):
		gun.set_process(false)
	for resident in lobby._residents:
		resident.set_physics_process(false)
	for enemy in lobby._forest_monsters:
		if is_instance_valid(enemy):
			enemy.set_physics_process(false)
	_check(not trees.is_empty(), "living forest trees remain before the game-over test")
	var sapling := trees[0] as ForestTree
	sapling._process(ForestTree.GROW_SECONDS)
	sapling.take_attack_damage(9999)
	_check(sapling.replant(), "last-stand sapling can be planted while other trees survive")
	for node in trees:
		if node is ForestTree:
			var tree := node as ForestTree
			if tree == sapling:
				continue
			if tree.is_alive():
				tree._process(ForestTree.GROW_SECONDS)
				tree.max_health = 10
				tree.health = 10
				tree.take_attack_damage(99)
	_check(not GameState.game_over_active, "a planted sapling prevents game over even with no mature trees")
	sapling._process(ForestTree.GROW_SECONDS)
	sapling.take_attack_damage(9999)
	_check(GameState.game_over_active, "losing all mature trees and saplings triggers game over")
	await get_tree().create_timer(Lobby.DEVASTATION_SECONDS + 0.3).timeout
	_check(lobby.devastation_progress >= 0.99, "game over animates the orange dry terrain to completion")
	_check(lobby.get_node_or_null("PoisonedSea") != null, "game over adds the dark green poisoned sea")
	_check(lobby.get_node("StrandedSeaLife").get_child_count() == 20, "dead fish and crabs appear on the sand")
	_check(hud.game_over_panel.visible, "game over screen appears when the forest is lost")
	_check(bool(game.get("_game_over")), "game flow enters the locked game-over state")
	game.call("return_to_title", true)
	await get_tree().create_timer(0.2).timeout
	_check(game.title_screen != null and not hud.visible, "game over returns to the title screen")


func _test_village_systems() -> void:
	if not GameState.is_night():
		GameState.advance_world_clock(GameState.DAY_PHASE_SECONDS)
	var lobby := game.world as Lobby
	for gun in game.get_tree().get_nodes_in_group("house_defenses"):
		gun.set_process(false)
	for enemy in lobby._forest_monsters:
		if is_instance_valid(enemy):
			enemy.set_physics_process(false)
	for npc in lobby._residents:
		npc.set_physics_process(false)
	_check(lobby._forest_monsters.size() >= 24, "forest has at least twenty-four fire monsters")
	_check(float(Resident.WATER_HEAL) / Resident.WATER_INTERVAL <= 4.0, "water power is reduced to four HP per second")
	_check(get_tree().get_nodes_in_group("shop_signs").size() == 5, "all five shops have shop-name signs")
	var merchants_inside := true
	for merchant in get_tree().get_nodes_in_group("ambient_shop"):
		merchants_inside = merchants_inside and merchant.position.y < 0.0 and merchant.interact_radius >= 2.5
	_check(merchants_inside, "merchants stand inside stalls and remain reachable from the counter")
	var original_mission := GameState.mission_step()
	hud.tutorial_guide._advance()
	_check(GameState.mission_step() == original_mission, "Next cannot bypass a mission's required action")
	var wrong_event := "move" if original_mission != 0 else "boss"
	GameState.record_mission_event(wrong_event)
	_check(GameState.mission_step() == original_mission, "out-of-order actions do not advance the lesson")
	for phase in 2:
		while GameState.mission_step() < MissionDB.STEPS.size():
			var before := GameState.completed_mission_count()
			GameState.record_mission_event(str(MissionDB.step(GameState.mission_step()).get("event", "")))
			_check(GameState.completed_mission_count() == before + 1, "current phase lesson advances exactly one action")
		GameState.advance_world_clock(180)
	_check(GameState.completed_mission_count() == MissionDB.STEPS.size(), "both day and night lessons complete")
	GameState.add_gold(-GameState.gold())
	_check(not GameState.hire_water_keeper().ok and GameState.water_keeper_count() == 1, "unaffordable recruitment does not add a keeper")
	GameState.add_gold(2500)
	for count in [2, 3, 4, 5]:
		_check(GameState.hire_water_keeper().ok and GameState.water_keeper_count() == count, "paid recruitment adds keeper %d" % count)
	var balance := GameState.gold()
	_check(not GameState.hire_water_keeper().ok and GameState.gold() == balance, "keeper cap rejects purchase without charging")
	for npc in lobby._residents:
		npc.set_physics_process(false)
	var fire := lobby._forest_monsters[0]
	GameState.set_health(GameState.health_max())
	GameState.data.shield = 0
	lobby.player.invulnerable = 0
	fire.global_position = lobby.player.global_position + Vector2(0.8, 0)
	var player_hp := GameState.health()
	fire._target = lobby.player
	fire._hit_dealt = false
	fire._attack_active(0.0)
	_check(GameState.health() < player_hp, "fire attack damages a nearby living player")
	fire._update_forest_target()
	_check(fire._target == lobby.player, "fire can target a nearby player as well as trees")
	var fence: SettlementTarget
	var house: SettlementTarget
	for node in get_tree().get_nodes_in_group("structures"):
		if node.structure_kind == "fence":
			fence = node
		elif node.structure_id == "cottage":
			house = node
	_check(fence != null and house != null, "fences and houses have individual damage targets")
	fence.take_attack_damage(9999)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(not fence.is_intact(), "sea damage can completely destroy a fence")
	var collider_disabled := true
	for child in fence.get_parent().get_children():
		if child is StaticBody2D:
			collider_disabled = collider_disabled and child.collision_layer == 0
	_check(collider_disabled, "destroyed fence releases its collision bodies")
	var repair: StructureRepairPoint
	for point in get_tree().get_nodes_in_group("structure_repairs"):
		if point.target == fence:
			repair = point
			break
	_check(repair != null and repair.is_interactable_available(), "damaged fence has a nearby Betulkan interaction")
	if GameState.is_night():
		GameState.advance_world_clock(180)
	var gold_before := GameState.gold()
	var p := game.player() as Player
	p.global_position = repair.global_position + Vector2(5, 0)
	repair.interact(p)
	_check(not fence.is_intact(), "distant repair interaction cannot restore the fence")
	p.global_position = repair.global_position + Vector2(0, 0.4)
	repair.interact(p)
	_check(not fence.is_intact() and GameState.gold() == gold_before and float(GameState.structure_state(fence.structure_id).get("repair_remaining", 0)) == 10, "nearby repair requests ten seconds of builder work for free")
	_check(not GameState.work_structure(fence.structure_id, 9.9) and not fence.is_intact(), "fence repair cannot finish early")
	_check(GameState.work_structure(fence.structure_id, 0.2) and fence.is_intact(), "builder repairs fence after ten seconds")
	_check(not repair.is_interactable_available() and not GameState.repair_structure(fence.structure_id).ok, "intact structures hide repairs and reject duplicate work")
	house.take_attack_damage(10)
	_check(GameState.repair_structure(house.structure_id).ok and house.is_intact() and GameState.gold() == gold_before, "partially damaged houses can also be repaired without payment")
	var urchin := Enemy.new()
	urchin.kind = "urchin"
	urchin.position = fence.attack_position(Vector2.ZERO)
	lobby.add_child(urchin)
	urchin.set_physics_process(false)
	_check(urchin._choose_urchin_target() == fence, "sea urchin chooses a nearby intact fence")
	urchin._target = house
	urchin.global_position = house.shelter_position() + Vector2(0, 1.05)
	urchin._state = Enemy.State.CHASE
	urchin._attack_timer = 0.0
	urchin._chase(1.0 / 60.0)
	_check(urchin._state == Enemy.State.WINDUP, "sea urchin attacks a stationary house from the approach band instead of stalling")
	var tree := lobby._forest_trees[0]
	if tree.fallen:
		tree.replant()
	if tree.growth_remaining > 0.0:
		tree._process(ForestTree.GROW_SECONDS)
	tree.water(tree.max_health)
	var hp := tree.health
	urchin.global_position = tree.global_position + Vector2(0.8, 0)
	urchin._target = tree
	urchin._hit_dealt = false
	urchin._attack_active(0.0)
	_check(tree.health < hp and not tree.burning, "sea urchin damages a mature tree without igniting it")
	var resident := lobby._residents[0]
	resident.global_position = house.shelter_position()
	resident._shelter_house = house
	urchin.global_position = resident.global_position + Vector2(1, 0)
	resident._seek_shelter(0.02)
	_check(resident.sheltered and not resident.visible, "resident enters an intact house when a sea urchin approaches")
	var resident_hp := GameState.resident_health(resident.resident_name)
	resident.take_attack_damage(999)
	_check(GameState.resident_health(resident.resident_name) == resident_hp, "intact shelter protects resident health")
	for node in get_tree().get_nodes_in_group("structures"):
		if node.structure_kind == "house":
			node.take_attack_damage(9999)
	resident._seek_shelter(0.02)
	_check(not resident.sheltered and resident.visible, "destroyed houses leave residents exposed")
	resident.take_attack_damage(999)
	_check(resident.dead and not resident.is_in_group("settlement_target"), "an exposed resident can die and leaves combat targeting")
	urchin.queue_free()
	for node in get_tree().get_nodes_in_group("structures"):
		if not node.is_intact():
			GameState.repair_structure(node.structure_id)
	GameState.save_game()
	GameState.load_game()
	_check(GameState.water_keeper_count() == 5 and GameState.resident_health(resident.resident_name) == 0 and GameState.mission_step() == MissionDB.STEPS.size(), "purchased keepers, resident death and mission progress survive save/load")
	_check(house.is_intact() and fence.is_intact(), "repaired structures survive save/load")
	await get_tree().process_frame


func _test_forest_restoration() -> void:
	var lobby := game.world as Lobby
	for gun in game.get_tree().get_nodes_in_group("house_defenses"):
		gun.set_process(false)
	var keepers: Array[Resident] = []
	for resident in lobby._residents:
		resident.set_physics_process(false)
		resident._release_tree_task()
		if resident.water_power:
			keepers.append(resident)
	_check(keepers.size() == GameState.water_keeper_count(), "water keeper population matches purchased capacity")
	_check(keepers.all(func(npc: Resident) -> bool: return npc.role == "water_keeper" and npc._sprite.texture == PixelArt.npc_texture("water_keeper")), "water keepers wear distinct blue clothes")
	for enemy in lobby._forest_monsters:
		if is_instance_valid(enemy):
			enemy.set_physics_process(false)
	_check(lobby._forest_monsters.all(func(enemy: Enemy) -> bool: return not is_instance_valid(enemy) or enemy.kind == "fire"), "woodland attackers are fire monsters")
	var tree := lobby._forest_trees[0]
	if tree.growth_remaining > 0.0:
		tree._process(ForestTree.GROW_SECONDS)
	if tree.fallen:
		tree.replant()
		tree._process(ForestTree.GROW_SECONDS)
	var attacker := lobby._forest_monsters[0]
	var attacker_position := attacker.position
	attacker.global_position = tree.global_position + Vector2(0.8, 0)
	attacker._target = tree
	var fire_sound_cursor := Sfx._next_player
	attacker._enter(Enemy.State.ALERT)
	attacker._enter(Enemy.State.WINDUP)
	attacker._hit_dealt = false
	attacker._attack_active(0.0)
	_check(Sfx._next_player == fire_sound_cursor, "fire alert, windup and tree attack are silent")
	_check(tree.burning and tree.health < tree.max_health, "fire monster's active attack frame damages and ignites a mature tree")
	tree.water(tree.max_health)
	attacker.position = attacker_position
	tree.take_attack_damage(35)
	_check(tree.burning and tree.health < tree.max_health, "attacking a mature tree ignites it and reduces HP")
	var hp := tree.health
	tree._process(ForestTree.BURN_INTERVAL)
	_check(tree.health == hp - ForestTree.BURN_DAMAGE, "fire continues damaging an unwatered tree")
	var keeper := keepers[0]
	keeper.global_position = tree.global_position + Vector2(0, 1.5)
	keeper._tree_task = tree
	tree.caretaker = keeper
	keeper._care_for_forest(Resident.WATER_INTERVAL)
	_check(tree.health > hp and keeper._watering, "nearby blue NPC channels water and restores tree HP")
	for i in 10:
		keeper._care_for_forest(Resident.WATER_INTERVAL)
	_check(tree.health == tree.max_health and not tree.burning, "watering extinguishes fire after restoring full HP")
	keeper._release_tree_task()
	tree.take_attack_damage(9999)
	_check(tree.fallen and not tree.burning, "zero HP fells the tree and stops its fire")
	keeper = lobby._residents.filter(func(npc: Resident) -> bool: return npc.worker_role == "planter")[0]
	keeper.global_position = tree.global_position + Vector2(0, 1.5)
	keeper._tree_task = tree
	tree.caretaker = keeper
	keeper._care_for_forest(Resident.PLANT_SECONDS)
	_check(not tree.fallen and tree.growth_remaining == 30.0, "green NPC plants a replacement with exactly 30 seconds of growth")
	var sapling_hp := tree.health
	tree.take_attack_damage(99)
	attacker.global_position = tree.global_position + Vector2(0.8, 0)
	attacker._target = tree
	attacker._hit_dealt = false
	attacker._attack_active(0.0)
	attacker.position = attacker_position
	_check(tree.health == sapling_hp and not tree.burning and not tree.is_attackable(), "growing saplings reject fire attacks and ignition")
	var monster := lobby._forest_monsters[0]
	_check(monster._nearest_forest_tree() != tree, "fire monster targeting skips growing saplings")
	GameState.save_game()
	GameState.load_game()
	_check(GameState.forest_tree_growth(tree.tree_id) > 29.0, "sapling growth survives save and load")
	var restored := ForestTree.new()
	restored.tree_id = tree.tree_id
	lobby.add_child(restored)
	_check(not restored.is_attackable() and restored.growth_remaining > 29.0, "reconstructed sapling retains its protected growth phase")
	restored.queue_free()
	tree._process(29.0)
	_check(not tree.is_attackable() and tree.growth_remaining > 0.0, "sapling stays protected before the full 30 seconds")
	tree._process(1.1)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(tree.is_attackable() and tree.is_in_group("settlement_target") and tree.get_node("Body").collision_layer == 1, "mature tree regains targeting and trunk collision after 30 seconds")
	tree.take_attack_damage(1)
	_check(tree.burning, "a fully grown replacement can burn again")


func _find_loot(root: Node) -> LootDrop:
	if root is LootDrop:
		return root
	for child in root.get_children():
		var found := _find_loot(child)
		if found != null:
			return found
	return null


func _find_placeable(root: Node, placeable_id: String) -> SettlementPlaceable:
	if root is SettlementPlaceable and str(root.placeable_id) == placeable_id:
		return root
	for child in root.get_children():
		var found := _find_placeable(child, placeable_id)
		if found != null:
			return found
	return null


func _has_label(root: Node, text: String) -> bool:
	if root is Label and str(root.text) == text:
		return true
	for child in root.get_children():
		if _has_label(child, text):
			return true
	return false


func _count_labels(root: Node) -> int:
	var count := 1 if root is Label else 0
	for child in root.get_children():
		count += _count_labels(child)
	return count


func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		fails += 1
	print("[%s] %s" % ["OK" if condition else "FAIL", label])


func _test_visual_repairs() -> void:
	var lobby := game.world as Lobby
	for gun in game.get_tree().get_nodes_in_group("house_defenses"):
		gun.set_process(false)
	var p := game.call("player") as Player
	var pet := lobby.pet
	var trees: Array[ForestTree] = lobby._forest_trees
	var ids := {}
	var hierarchy_ok := true
	var coordinates_ok := true
	for tree in trees:
		ids[tree.tree_id] = tree.position
		var body := tree.get_node_or_null("Body") as StaticBody2D
		hierarchy_ok = hierarchy_ok and body != null and tree._visuals.size() == 2
		for visual in tree._visuals:
			hierarchy_ok = hierarchy_ok and visual.get_parent() == tree
			coordinates_ok = coordinates_ok and visual.global_position.distance_to(tree.global_position) < 0.08
		if body:
			coordinates_ok = coordinates_ok and body.global_position.distance_to(tree.global_position) < 0.01
	_check(hierarchy_ok, "every tree owns its actual sprites and trunk body")
	_check(coordinates_ok, "tree sprites and collision inherit their holder world positions")
	_check(ids.size() == trees.size(), "tree persistence IDs remain unique")
	var tree := trees[0]
	var other := trees[1]
	var other_hp := other.health
	tree.take_attack_damage(1)
	_check(tree._visuals[0].modulate.r > 1.0 and other.health == other_hp, "tree hit flashes its own visual without damaging neighbours")
	_check(GameState.forest_tree_health(tree.tree_id, tree.max_health) == tree.health, "tree damage persists under its original ID")
	# Load an already-fallen tree with its body present before ready.
	var fallen := ForestTree.new()
	fallen.tree_id = "repair_fallen_fixture"
	fallen.position = Vector2(59, 38)
	var body := StaticBody2D.new()
	body.name = "Body"
	fallen.add_child(body)
	GameState.set_forest_tree_health(fallen.tree_id, 0, 100)
	lobby.add_child(fallen)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(fallen.fallen and body.collision_layer == 0, "persisted fallen tree disables its own collider at startup")
	fallen.queue_free()
	var mask := lobby._make_water_mask_texture().get_image()
	var mask_ok := true
	for x in range(0, mask.get_width(), 13):
		var shore := lobby._coast_pixel_y(x - x % 2)
		for y in range(0, mask.get_height(), 17):
			var wet := x < Lobby.OCEAN_WIDTH_PIXELS and y >= shore
			mask_ok = mask_ok and (mask.get_pixel(x, y).a > 0.0) == wet
	_check(mask_ok, "water mask matches the painted sea and is transparent beyond its eastern edge")
	var water := lobby.get_node("WaterLayer") as Sprite2D
	_check(water.position == Vector2.ZERO and water.scale.is_equal_approx(Vector2.ONE * PixelArt.PX), "water mask origin and art scale align with terrain")
	_check(not Shaders.WATER_CODE.contains("sparkle"), "water shader contains no random sparkle term")
	_check(lobby.get_node_or_null("AmbientLife") == null, "ordinary lobby has no star pollen or butterfly placeholders")
	var turtle := get_tree().get_first_node_in_group("beach_turtle") as Node2D
	_check(turtle != null, "beach turtle exists")
	if turtle:
		var shore := float(lobby._coast_pixel_y(roundi(turtle.position.x / PixelArt.PX))) * PixelArt.PX
		_check(turtle.position.x < float(Lobby.OCEAN_WIDTH_PIXELS) * PixelArt.PX and turtle.position.y < shore - 0.5 and turtle.position.y > shore - 2.5, "turtle is grounded on dry beach sand")
	var sign := get_tree().get_first_node_in_group("besut_sign")
	_check(sign != null and sign.get_meta("text", "") == "BESUT", "village sign has exact readable BESUT lettering")
	_check(not _has_label(hud, "VITALS"), "removed VITALS panel is absent")
	_check(p.get_node_or_null("VitalHud") is PlayerVitalHud, "world-space player HP/XP HUD remains")
	var old_quality := GameSettings.effects_quality()
	var old_motion := GameSettings.reduce_motion()
	for quality in ["low", "med", "high"]:
		GameSettings.set_effects_quality(quality, false)
		GameSettings.set_reduce_motion(false, false)
		_check(water.visible == (quality != "low"), "%s quality applies water visibility immediately" % quality)
		GameSettings.set_reduce_motion(true, false)
		_check(not water.visible, "%s reduce motion uses stable painted water fallback" % quality)
	GameSettings.set_effects_quality(old_quality, false)
	GameSettings.set_reduce_motion(old_motion, false)
	var old_zoom := GameSettings.camera_zoom()
	var old_scale: float = hud.get_gui_scale()
	for zoom_value in [GameSettings.CAMERA_ZOOM_MIN, GameSettings.CAMERA_ZOOM_DEFAULT, GameSettings.CAMERA_ZOOM_MAX]:
		GameSettings.set_camera_zoom(zoom_value, false)
		await get_tree().create_timer(0.6).timeout
		_check(absf(lobby.camera.zoom.x - zoom_value) < 0.2 and is_equal_approx(lobby.camera.zoom.x, lobby.camera.zoom.y), "camera smoothly approaches isotropic zoom %d" % zoom_value)
		_check(is_equal_approx(hud.get_gui_scale(), old_scale), "camera zoom leaves GUI scale unchanged")
	GameSettings.set_camera_zoom(-99, false)
	_check(GameSettings.camera_zoom() == GameSettings.CAMERA_ZOOM_MIN, "zoom clamps below minimum")
	GameSettings.set_camera_zoom(999, false)
	_check(GameSettings.camera_zoom() == GameSettings.CAMERA_ZOOM_MAX, "zoom clamps above maximum")
	GameSettings.set_camera_zoom(44, true)
	GameSettings.load_settings()
	_check(GameSettings.camera_zoom() == 44, "zoom survives settings file reload")
	for gui in [0.75, 1.0, 1.3]:
		hud.set_gui_scale(gui, false)
		await get_tree().process_frame
		_check(is_equal_approx(GameSettings.ui_scale() / 100.0, gui) and is_equal_approx(GameState.gui_scale(), gui), "GUI scale %.2f has one authoritative value" % gui)
		_check(hud.get("_root").scale == Vector2.ONE, "HUD root remains unscaled at %.2f" % gui)
		var in_bounds := true
		var screen := Rect2(Vector2.ZERO, hud.get("_root").size)
		for control: Control in hud.get("_control_nodes").values():
			in_bounds = in_bounds and screen.encloses(control.get_global_rect())
		_check(in_bounds, "touch controls stay inside viewport at GUI %.2f" % gui)
		_check(GameSettings.camera_zoom() == 44, "GUI scaling leaves camera zoom unchanged")
	hud.set_gui_scale(old_scale, true)
	GameSettings.set_camera_zoom(old_zoom, true)
	# Preserve normal monsters/routines while using a controlled movement fixture.
	for monster in lobby._forest_monsters:
		monster.set_physics_process(false)
	for resident in lobby._residents:
		resident.set_physics_process(false)
		resident._end_visit()
	var start := p.global_position
	# Keep this movement fixture clear of the new water-keeper shop counter.
	p.global_position = Vector2(32, 25)
	p.reset_physics_interpolation()
	p.velocity = Vector2.ZERO
	var previous := p.global_position
	var continuous := true
	var fractional_samples := 0
	var max_step := 0.0
	Input.action_press("move_right")
	Input.action_press("move_down")
	for i in 24:
		await get_tree().physics_frame
		var step := p.global_position.distance_to(previous)
		max_step = maxf(max_step, step)
		continuous = continuous and step < GameState.move_speed() / Engine.physics_ticks_per_second * 1.2
		if not is_equal_approx(p.global_position.x * 32.0, roundf(p.global_position.x * 32.0)):
			fractional_samples += 1
		previous = p.global_position
	Input.action_release("move_right")
	Input.action_release("move_down")
	_check(continuous and max_step > 0.001 and fractional_samples > 8, "player diagonal movement traverses bounded fractional intermediate positions")
	_check(p.velocity.length() <= GameState.move_speed() + 0.01, "diagonal input has no speed advantage")
	await get_tree().create_timer(0.3).timeout
	_check(p.velocity.length() < 0.01, "player decelerates to rest")
	# Catch-up fixture deliberately begins beyond the old teleport threshold.
	pet.global_position = p.global_position + Vector2(-8, 0)
	pet._follow_velocity = Vector2.ZERO
	pet.reset_physics_interpolation()
	var distance_before := pet.global_position.distance_to(p.global_position)
	previous = pet.global_position
	var pet_continuous := true
	for i in 60:
		await get_tree().physics_frame
		pet_continuous = pet_continuous and pet.global_position.distance_to(previous) < 0.17
		previous = pet.global_position
	_check(pet_continuous and pet.global_position.distance_to(p.global_position) < distance_before - 1.0, "far-behind pet catches up continuously without leash teleport")
	var mover := Enemy.new()
	mover.position = p.global_position + Vector2(0, -3)
	mover.damage = 0
	mover.speed = 1.8
	lobby.add_child(mover)
	mover.set_physics_process(false)
	mover._target = p
	mover._player = p
	previous = mover.global_position
	var enemy_continuous := true
	var enemy_travel := 0.0
	for i in 25:
		await get_tree().physics_frame
		mover._chase(1.0 / float(Engine.physics_ticks_per_second))
		var step := mover.global_position.distance_to(previous)
		enemy_continuous = enemy_continuous and step < 0.05
		enemy_travel += step
		previous = mover.global_position
	_check(enemy_continuous and enemy_travel > 0.15, "enemy chase traverses bounded intermediate positions with collision movement")
	mover.queue_free()
	var drop := LootDrop.new()
	drop.position = Vector2(4, 4)
	drop.pop_velocity = Vector2(1.3, -1.5)
	lobby.add_child(drop)
	previous = drop.global_position
	var loot_continuous := true
	for i in 36:
		await get_tree().physics_frame
		loot_continuous = loot_continuous and drop.global_position.distance_to(previous) < 0.05
		previous = drop.global_position
	_check(loot_continuous and drop.pop_velocity == Vector2.ZERO, "loot pop remains continuous and settles instead of drifting forever")
	drop.queue_free()
	var arrow := Arrow.new()
	arrow.position = Vector2(3, 3)
	lobby.add_child(arrow)
	previous = arrow.global_position
	var arrow_continuous := true
	var arrow_travel := 0.0
	for i in 12:
		await get_tree().physics_frame
		var step := arrow.global_position.distance_to(previous)
		arrow_continuous = arrow_continuous and step < arrow.speed / float(Engine.physics_ticks_per_second) * 1.1
		arrow_travel += step
		previous = arrow.global_position
	_check(arrow_continuous and arrow_travel > 1.0, "projectile preserves intentional speed through continuous positions")
	arrow.queue_free()
	var gold_before := GameState.gold()
	var inventory_before: Dictionary = GameState.data.inventory.duplicate(true)
	var shops := get_tree().get_nodes_in_group("ambient_shop")
	var shop := shops[0] as ShopNPC
	var customer := Resident.new()
	customer.resident_name = "Regression shopper"
	customer.position = shop.customer_position() + Vector2(0, 1.4)
	customer.waypoints = [customer.position]
	lobby.add_child(customer)
	# Select the first shop reproducibly while still exercising begin_shop_visit.
	for seed_value in 100:
		var random := RandomNumberGenerator.new()
		random.seed = seed_value
		random.randf_range(24.0, 50.0)
		if random.randi_range(0, shops.size() - 1) == 0:
			customer._shopping_rng.seed = seed_value
			break
	var sales_before := shop.ambient_sales
	_check(customer.begin_shop_visit(), "resident reserves an accessible shop")
	_check(not customer._shop.reserve_customer(lobby._residents[0]), "busy counters reject a simultaneous customer")
	var states := {}
	previous = customer.global_position
	var shopper_continuous := true
	for i in 720:
		await get_tree().physics_frame
		states[customer.shopping_state] = true
		shopper_continuous = shopper_continuous and customer.global_position.distance_to(previous) < 0.06
		previous = customer.global_position
		if customer.shopping_visits > 0 and customer.shopping_state == Resident.Shopping.ROUTINE:
			break
	_check(shopper_continuous, "shopper walks through intermediate positions without state-change snaps")
	_check(states.has(Resident.Shopping.BROWSE) and states.has(Resident.Shopping.PURCHASE) and states.has(Resident.Shopping.LEAVE), "shopping explicitly browses, purchases and leaves")
	_check(customer.shopping_visits == 1 and shop.ambient_sales == sales_before + 1, "shopping completes one exchange and returns to routine")
	_check(GameState.gold() == gold_before and GameState.data.inventory == inventory_before, "ambient shopping leaves player gold and inventory unchanged")
	_check(not hud.shop_panel.visible, "ambient customer never opens player shop UI")
	for seed_value in 100:
		var random := RandomNumberGenerator.new()
		random.seed = seed_value
		random.randf_range(24.0, 50.0)
		if random.randi_range(0, shops.size() - 1) == 0:
			customer._shopping_rng.seed = seed_value
			break
	_check(customer.begin_shop_visit(), "customer can reserve a counter for another visit")
	for i in 720:
		await get_tree().physics_frame
		if customer.shopping_visits == 2 and customer.shopping_state == Resident.Shopping.ROUTINE:
			break
	_check(customer.shopping_visits == 2 and GameState.gold() == gold_before and GameState.data.inventory == inventory_before, "repeated shopping completes without player economy changes")
	customer.queue_free()
	await get_tree().process_frame
	_check(shop._customer == null or shop._customer.get_ref() == null, "customer frees its counter reservation")
	p.global_position = start
	p.reset_physics_interpolation()
	for monster in lobby._forest_monsters:
		monster.set_physics_process(true)
	for resident in lobby._residents:
		resident.set_physics_process(true)
