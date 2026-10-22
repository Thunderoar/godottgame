extends Node
## End-to-end acceptance test for the updated Tidesworn rules.
## Run as a scene so project autoloads are initialised:
##   godot --headless --path . res://tools/tide_test.tscn

var game: Node
var hud: Node
var fails := 0
var checks := 0


func _ready() -> void:
	GameState.delete_save()
	game = load("res://scenes/game.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	_check(game.title_screen != null, "title screen exists")
	_check(GameState.has_existing_save == false, "clean save state")
	_check(_has_label(game.title_screen, "SAVE THE WORLD"), "title reads Save The World")
	_check(_has_label(game.title_screen, "Created by Qayyim, Farhan and Ayiz"), "creator credit is present")
	_check(_has_label(game.title_screen, "CHOOSE YOUR ROAD"), "Choose Your Road menu is on the title screen")
	_check(CharacterDB.ids() == ["qayyim", "farhan", "ayiz"], "three male heroes are defined")
	_check(CharacterDB.weapon_style("qayyim") == "sword", "Qayyim uses a sword")
	_check(CharacterDB.weapon_style("farhan") == "hammer", "Farhan uses a hammer")
	_check(CharacterDB.weapon_style("ayiz") == "bow", "Ayiz uses a bow")
	_check(not ItemDB.exists("pet_revival"), "Pet Revival Potion is removed")

	game.call("_on_character_selected", "qayyim")
	await get_tree().process_frame
	await get_tree().process_frame
	hud = game.get("hud")
	_check(game.world is Lobby, "lobby loads after character select")
	_check(game.call("player") != null, "player exists")
	_check(get_tree().get_first_node_in_group("pet") != null, "starter pet exists")
	_check(GameState.item_count("rusty_sword") == 1, "Qayyim owns a starter sword")
	_check(GameState.equipped_item("weapon") == "rusty_sword", "starter sword equipped")
	_check(GameState.active_pet_id() == "ember", "starter pet active")
	_check(GameState.has_living_pet(), "starter pet alive")
	_check(hud.get("_health_bar").segments == 10, "player health uses 10 segments")
	_check(hud.get("_pet_bar").segments == 5, "pet health uses 5 segments")
	_check(hud.get("_minimap") == null, "no minimap exists")
	_check(hud.get("_emergency_panel") != null, "emergency HUD exists")
	_check(hud.get("_recovery_panel") != null, "recovery HUD exists")
	_check(hud.get("_joystick") != null, "touch joystick exists")
	_check(hud.get("_attack_button").action == "attack", "touch attack maps to attack action")
	_check(hud.get("_interact_button").action == "interact", "touch interact maps to interact action")
	_check(hud.get("_inventory_button").action == "open_inventory", "backpack touch action exists")
	_check(hud.get("_inventory_button").position.x < 200 and hud.get("_inventory_button").position.y < 200, "backpack sits away from movement/combat controls")
	_check(hud.get("_build_button").action == "toggle_build", "settlement Build button exists")
	_check(GameState.time_string() == "DAYTIME", "the world is locked in permanent daytime")
	_check(hud.tutorial_guide.visible, "New Journey tutorial starts on a new game")
	_check(hud.tutorial_guide.get("STEPS").size() == 8, "New Journey tutorial has eight steps")
	hud.tutorial_guide.call("_skip")
	var interactables := get_tree().get_nodes_in_group("interactable")
	_check(interactables.size() >= 10, "lobby interactions present (%d)" % interactables.size())
	_check(hud.get("_toast_box") == null, "in-game pop-up notifications are removed")
	hud.call("show_toast", "ignored")
	_check(hud.get("_toast_box") == null, "toast calls cannot create pop-up notifications")
	var xp_bar := hud.get("_xp_bar") as SegmentedBar
	var pet_xp_bar := hud.get("_pet_xp_bar") as SegmentedBar
	_check(xp_bar != null and xp_bar.maximum == int(GameState.data.xp_next), "player XP bar shows the next-level requirement")
	_check(pet_xp_bar != null and pet_xp_bar.maximum == PetDB.xp_for_level(2), "pet XP bar shows the next-level requirement")
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

	await _test_movement()
	await _test_gathering()
	await _test_shops()
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
	var forest_monsters := get_tree().get_nodes_in_group("forest_monsters")
	_check(forest_monsters.size() >= 12, "many forest monsters patrol the woodland (%d)" % forest_monsters.size())
	_check(Sfx.has_sound("tree_hit") and Sfx.has_sound("aggro"), "tree-hit and aggro sounds are generated")
	if not forest_monsters.is_empty() and game.call("player") != null:
		var forest_monster := forest_monsters[0] as Enemy
		var test_player: Player = game.call("player")
		var old_player_pos := test_player.global_position
		var old_monster_pos := forest_monster.global_position
		test_player.global_position = Vector2(34.0, 26.0)
		forest_monster.global_position = Vector2(38.0, 26.0)
		await get_tree().process_frame
		var sees_player := bool(forest_monster.call("_can_see_player"))
		forest_monster.set("_saw_player", false)
		forest_monster.call("_update_forest_target")
		_check(sees_player, "forest monsters detect the player in line of sight")
		_check(bool(forest_monster.get("_saw_player")) and bool(forest_monster.get("_charging")), "forest monsters immediately target and charge a seen player")
		test_player.global_position = old_player_pos
		forest_monster.global_position = old_monster_pos
	_check(get_tree().get_nodes_in_group("resident_house").size() >= 7, "more residents' houses stand around the village (%d)" % get_tree().get_nodes_in_group("resident_house").size())
	_check(get_tree().get_nodes_in_group("ruin_house").size() >= 3, "abandoned, damaged and destroyed houses decorate the outskirts")
	_check(get_tree().get_nodes_in_group("horses").size() >= 2, "horses live in the village")
	_check(PixelArt.animal_texture("horse") != null, "horse art generates")
	_check(get_tree().get_nodes_in_group("flowers").size() >= 50, "flower borders fill the village")
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
	var arrows := hud.get("_mission_arrows") as Array
	var visible_arrows := 0
	for arrow in arrows:
		if arrow is MissionArrow and arrow.visible:
			visible_arrows += 1
	_check(visible_arrows >= 1, "mission guidance arrows point toward objectives")
	var player := game.call("player") as Player
	_check(player != null and player.get_node_or_null("VitalHud") is PlayerVitalHud, "player has a floating Health/Mana dashboard")
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
	var poor := GameState.buy_item("mana_potion")
	_check(not bool(poor.ok) and GameState.gold() == 0, "purchase rejected with insufficient gold")
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
	var bed: Node = null
	for node in get_tree().get_nodes_in_group("interactable"):
		if node is HouseBed:
			bed = node
	_check(bed != null, "bed interaction exists")
	if bed != null:
		bed.call("interact", p)
		await get_tree().create_timer(2.3).timeout
	_check(GameState.health() == GameState.health_max(), "sleep restores full health within 2 seconds")
	_check(not p.sleeping, "sleep state ends")


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
	_check(attack.position.distance_to(Vector2(100, 500)) < 0.5 and is_equal_approx(attack.diameter, 88.0), "button positions and sizes are customizable")
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
	var pet_gate: PortalEntrance = null
	for node in get_tree().get_nodes_in_group("battle_portal"):
		if node is PortalEntrance and str(node.gate_kind) == "pet":
			pet_gate = node
	_check(pet_gate != null, "pet battle gate is interactable")
	if pet_gate != null:
		pet_gate.call("interact", game.call("player"))
		await get_tree().process_frame
	_check(hud.pet_battle_panel.visible, "pet battle portal opens the tournament")
	var panel := hud.pet_battle_panel as PetBattlePanel
	panel.close_panel()
	await get_tree().process_frame
	game.call("open_pet_battles")
	await get_tree().process_frame
	var gold_before := GameState.gold()
	var pet_before := GameState.get_active_pet()
	var pet_level_before := int(pet_before.get("level", 1))
	_check(PetBattlePanel.SKILLS.size() == 2, "pet combat has only Attack and Defend")
	var started: bool = bool(panel.start_battle("pet_duel_1"))
	_check(started, "first pet duel starts")
	_check(int(panel.get("_player_hp")) > 0 and int(panel.get("_opponent_hp")) > 0, "pet duel starts with two living combatants")
	_check(panel.get("_player_bar") != null and panel.get("_enemy_bar") != null, "pet duel displays both health bars")
	var skill_buttons := panel.get("_skill_buttons") as Array
	_check(skill_buttons.size() == 2, "the player pet has two skill buttons")
	_check(is_equal_approx(float(panel.get("_turn_timer")), 2.0), "each skill window lasts two seconds")
	_check(PetBattlePanel.SKILLS.has(str(panel.get("_enemy_choice"))), "the enemy pet chooses from Attack or Defend")
	var enemy_before := int(panel.get("_opponent_hp"))
	var player_before := int(panel.get("_player_hp"))
	panel.call("choose_skill", "attack")
	panel.set("_enemy_choice", "attack")
	panel.set("_turn_timer", 0.0)
	panel.call("_process", 0.01)
	_check(int(panel.get("_opponent_hp")) < enemy_before and int(panel.get("_player_hp")) < player_before, "both pets execute their actions simultaneously")
	var hit_fx := 0
	for child in panel.get_children():
		if child is PetHitEffect:
			hit_fx += 1
	_check(hit_fx >= 2, "pet hits create scratch/punch impact effects")
	panel.call("_process", 0.95)
	panel.set("_opponent_hp", 1)
	panel.call("choose_skill", "attack")
	panel.set("_enemy_choice", "defend")
	panel.set("_turn_timer", 0.0)
	panel.call("_process", 0.01)
	var shield_fx := false
	for child in panel.get_children():
		if child is PetHitEffect and str(child.get("kind")) == "shield":
			shield_fx = true
	_check(shield_fx, "defending creates a shield effect")
	await get_tree().process_frame
	_check(bool(GameState.pet_battle_state("pet_duel_1").get("cleared", false)), "pet duel victory is recorded")
	_check(bool(GameState.pet_battle_state("pet_duel_2").get("unlocked", false)), "pet duel victory unlocks the next level")
	_check(GameState.gold() > gold_before, "pet duel grants gold")
	var pet_after := GameState.get_active_pet()
	_check(int(pet_after.get("level", 1)) >= pet_level_before + 1, "pet duel victory levels up the companion")
	panel.close_panel()
	await get_tree().process_frame


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
	var rubbish_monster: Enemy = null
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if str(enemy.kind) == "rubbish":
			rubbish_monster = enemy
			break
	_check(rubbish_monster != null, "beached rubbish transforms into a monster")
	if rubbish_monster != null:
		var reward := int(rubbish_monster.gold_reward)
		rubbish_monster.call("take_damage", 99999, Vector2.ZERO, game.call("player"))
		await get_tree().process_frame
		_check(GameState.gold() == gold_after_catch + reward, "rubbish monster grants its own separate gold reward")


func _test_portal_combat_and_auto_loot() -> void:
	GameState.set_health(GameState.health_max())
	game.call("enter_portal", "tidebound_grotto")
	await get_tree().create_timer(0.8).timeout
	_check(game.world is Dungeon, "portal dungeon loads")
	var enemies := get_tree().get_nodes_in_group("enemies")
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
		_check(target.hp < hp_before, "sword attack damages a monster")
		target.call("take_damage", 99999, Vector2.ZERO, p)
	await get_tree().create_timer(0.7).timeout
	var loot := _find_loot(game.world)
	if loot != null:
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
	_check(not GameState.emergency_active() or raider_hp_after < raider_hp_before, "defenders help damage the raiders")
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
	var hp_before := GameState.health()
	await get_tree().create_timer(1.0).timeout
	_check(GameState.health() > hp_before, "health regenerates inside the recovery ward")
	p.global_position = Lobby.RECOVERY_CENTER + Vector2(12, 0)
	await get_tree().create_timer(0.2).timeout
	_check(p.global_position.distance_to(Lobby.RECOVERY_CENTER) <= Lobby.RECOVERY_RADIUS + 0.1, "recovery ward prevents leaving early")
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
		_check(hud.get("_boss_panel").visible, "boss bar appears during boss encounter")
		_check("DROWNED" in hud.get("_boss_label").text, "boss bar names the active boss")
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
	await _test_single_style("farhan", "smith_hammer", "hammer")
	await _test_single_style("ayiz", "reed_bow", "bow")


func _test_single_style(character_id: String, starter_weapon: String, style: String) -> void:
	GameState.new_game(character_id)
	game.call("_load_lobby", false)
	await get_tree().create_timer(0.3).timeout
	var p: Player = game.call("player")
	_check(GameState.equipped_item("weapon") == starter_weapon, "%s starts with the correct weapon" % character_id.capitalize())
	_check(GameState.character_weapon_style() == style, "%s uses the %s style" % [character_id.capitalize(), style])
	var dummy := Enemy.new()
	dummy.kind = "bogling"
	dummy.max_hp = 300
	dummy.damage = 0
	dummy.speed = 0.0
	dummy.position = p.global_position + Vector2(2.0 if style == "hammer" else 3.0, -0.65)
	game.world.add_child(dummy)
	p.facing = Vector2.RIGHT
	await get_tree().process_frame
	var hp_before := dummy.hp
	var struck: bool = bool(p.call("try_attack"))
	await get_tree().create_timer(0.35 if style == "bow" else 0.1).timeout
	_check(struck, "%s attack executes" % character_id.capitalize())
	_check(dummy.hp < hp_before, "%s %s attack damages a target" % [character_id.capitalize(), style])
	dummy.queue_free()


func _test_forest_game_over() -> void:
	if not game.world is Lobby:
		game.call("_load_lobby", false)
		await get_tree().create_timer(0.35).timeout
	var trees := get_tree().get_nodes_in_group("forest_tree")
	_check(not trees.is_empty(), "living forest trees remain before the game-over test")
	for node in trees:
		if node is ForestTree:
			var tree := node as ForestTree
			if tree.is_alive():
				tree.max_health = 10
				tree.health = 10
				tree.take_attack_damage(99)
	await get_tree().create_timer(0.35).timeout
	_check(GameState.game_over_active, "destroying every tree triggers game over")
	_check(hud.game_over_panel.visible, "game over screen appears when the forest is lost")
	_check(bool(game.get("_game_over")), "game flow enters the locked game-over state")
	game.call("return_to_title", true)
	await get_tree().create_timer(0.2).timeout
	_check(game.title_screen != null and not hud.visible, "game over returns to the title screen")


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
