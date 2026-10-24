extends Node

var game: Game
var checks := 0
var failures := 0

func _ready() -> void:
	if not TestEnvironment.require_isolation():
		get_tree().quit(1)
		return
	GameState.delete_save()
	game = load("res://scenes/game.tscn").instantiate() as Game
	add_child(game)
	await get_tree().process_frame
	_check(_labels(game.title_screen).contains("PB (Protect BESUT)"), "PB title")
	_check(_labels(game.title_screen).contains("Created by Qayyim, Farhan & Ayiz"), "permanent creator footer")
	_check(not _labels(game.title_screen).contains("Permanent daytime"), "obsolete footer removed")
	await game._on_character_selected("qayyim")
	await get_tree().process_frame
	await get_tree().process_frame
	game.hud.tutorial_guide._skip()
	var lobby := game.world as Lobby
	_freeze(lobby)
	await preload("res://tools/hud_battle_checks.gd").run(game, _check)
	_check(game.hud._objective_panel == null and game.hud._boss_panel == null, "journal and screen boss bar removed")
	_check(get_tree().get_nodes_in_group("mission_npc").size() == 1, "one purple question-mark mission NPC")
	_check(lobby.get_node_or_null("TwinCaveHill") != null and get_tree().get_nodes_in_group("battle_portal").size() == 2, "two portals stand in twin hillside caves")
	_check(not get_tree().get_nodes_in_group("interactable").any(func(n: Node) -> bool: return n is HouseBed), "porch mattress removed")
	_check(get_tree().get_nodes_in_group("interactable").filter(func(n: Node) -> bool: return n is HomeEntrance).size() == 1, "only the main house is enterable")
	for role in ["builder", "water", "planter", "fighter"]:
		_check(GameState.worker_count(role) == 1, "one starting %s worker" % role)
		_check(lobby._residents.filter(func(n: Resident) -> bool: return n.worker_role == role).size() == 1, "live %s population matches state" % role)
	GameState.add_gold(10000)
	for role in ["builder", "water", "planter", "fighter"]:
		var before := GameState.gold()
		var cost := GameState.worker_hire_cost(role)
		_check(GameState.hire_worker(role).ok and GameState.worker_count(role) == 2 and GameState.gold() == before - cost, "%s hiring charges once and adds worker" % role)
	_freeze(lobby)
	for structure in get_tree().get_nodes_in_group("structures"):
		if not structure.is_intact():
			GameState.repair_structure(structure.structure_id)
	var house: SettlementTarget
	for structure in get_tree().get_nodes_in_group("structures"):
		if structure.structure_id == "cottage":
			house = structure
	var builder := _worker(lobby, "builder")
	house.take_attack_damage(9999)
	builder._build_target = house
	house.builder = builder
	builder.global_position = house.shelter_position() + Vector2(0, 0.5)
	builder._repair_buildings(9.9)
	_check(not house.is_intact() and float(GameState.structure_state("cottage").get("repair_remaining", 0)) > 0, "builder cannot repair before ten seconds")
	builder._repair_buildings(0.11)
	_check(house.is_intact(), "builder restores house after ten seconds of work")
	house.take_attack_damage(9999)
	GameState.start_structure_work("cottage")
	GameState.work_structure("cottage", 3.0)
	var remaining := float(GameState.structure_state("cottage").get("repair_remaining", 0))
	GameState.advance_world_clock(180)
	_freeze(lobby)
	_check(GameState.is_night() and not GameState.work_structure("cottage", 10) and is_equal_approx(float(GameState.structure_state("cottage").get("repair_remaining", 0)), remaining), "construction pauses at night")
	GameState.advance_world_clock(180)
	_check(not GameState.is_night(), "day returns after three minutes")
	GameState.save_game()
	_check(GameState.load_game() and is_equal_approx(float(GameState.structure_state("cottage").get("repair_remaining", 0)), remaining), "partial repair persists across save/load")
	_check(GameState.work_structure("cottage", remaining) and house.is_intact(), "daytime repair resumes remaining work")
	for enemy in lobby.get_children():
		if enemy is Enemy:
			enemy.queue_free()
	await get_tree().process_frame
	var blue := _worker(lobby, "water")
	blue.global_position = Vector2(42, 26)
	var fire := _enemy(lobby, "fire", blue.global_position + Vector2(2, 0))
	blue._attack_timer = 0
	_check(blue._fight_kind("fire", 0.01, true), "blue NPC chooses a fire monster")
	await get_tree().create_timer(0.3).timeout
	_check(fire.hp < fire.max_hp, "blue water projectile damages fire monster")
	var black := _worker(lobby, "fighter")
	black.global_position = Vector2(23, 26)
	var urchin := _enemy(lobby, "urchin", black.global_position + Vector2(0.8, 0))
	black._attack_timer = 0
	_check(black._fight_kind("urchin", 0.01, false) and urchin.hp < urchin.max_hp, "black NPC strikes sea urchin with sword")
	var tree := lobby._forest_trees[0]
	tree.take_attack_damage(20)
	blue.global_position = tree.global_position + Vector2(0, 1.5)
	blue._tree_task = tree
	tree.caretaker = blue
	var hp := tree.health
	blue._care_for_forest(Resident.WATER_INTERVAL)
	_check(tree.health > hp, "blue water restores burning tree HP")
	blue._release_tree_task()
	tree.take_attack_damage(9999)
	_check(not blue._accept_tree(tree), "water workers do not take planting jobs")
	var green := _worker(lobby, "planter")
	green.global_position = tree.global_position + Vector2(0, 1.5)
	green._tree_task = tree
	tree.caretaker = green
	green._care_for_forest(Resident.PLANT_SECONDS)
	_check(not tree.fallen and tree.growth_remaining == 30 and not tree.is_attackable(), "green NPC plants a protected thirty-second sapling")
	fire.queue_free()
	urchin.queue_free()
	await get_tree().process_frame
	var home_guns := get_tree().get_nodes_in_group("house_defenses")
	_check(home_guns.size() == get_tree().get_nodes_in_group("structures").filter(func(n: Node) -> bool: return n.structure_kind == "house").size(), "every house has an archer hut")
	var gun: HouseDefense
	for node in home_guns:
		if node.structure == house:
			gun = node
	var dummy := _enemy(lobby, "urchin", gun.global_position + Vector2(3, 0))
	gun._cooldown = 0
	gun._process(0.01)
	await get_tree().create_timer(0.3).timeout
	_check(dummy.hp < dummy.max_hp, "archer hut fires a damaging arrow")
	GameState.add_diamonds(1000)
	var neighbour := "home_resident_house_east"
	var own_level := GameState.house_level()
	var balance := GameState.diamonds()
	_check(GameState.upgrade_structure(neighbour).ok and GameState.structure_level(neighbour) == 2 and GameState.house_level() == own_level + 1 and GameState.diamonds() == balance - HouseDB.upgrade_cost(1), "house upgrade raises the whole village for one payment")
	for i in 3:
		_check(GameState.upgrade_structure(neighbour).ok, "house advances through weapon tier %d" % (i + 3))
	_check(not GameState.upgrade_structure(neighbour).ok and HouseDefense.INTERVALS[4] < HouseDefense.INTERVALS[0], "five levels cap upgrades and accelerate archery")
	_check(lobby.pet.get_node_or_null("PetHealth") is WorldHealthBar, "companion health floats overhead")
	lobby.pet.global_position = dummy.global_position + Vector2(0.8, 0)
	lobby.pet._attack_timer = 100
	var dummy_hp := dummy.hp
	lobby.pet._process_abilities(0.1, GameState.get_active_pet())
	_check(dummy.hp < dummy_hp, "following companion attacks nearby monsters")
	dummy.queue_free()
	GameState.set_health(10)
	await game.enter_home()
	_check(is_instance_valid(game.home_interior) and game.player().global_position.x > 64, "main house opens a separate furnished interior")
	_check(get_tree().get_nodes_in_group("home_accessories").size() == 4, "home contains chest, clothes, weapon rack and pet bed")
	var health := GameState.health()
	game.home_interior._process(1)
	_check(GameState.health() > health, "being inside home regenerates health")
	await game.leave_home()
	_check(not is_instance_valid(game.home_interior) and game.player().global_position.x < 64, "doorway returns player to village")
	game.open_missions()
	await get_tree().process_frame
	_check(game.hud.mission_panel.visible and game._input_locked, "purple guide opens mission panel")
	game.hud.mission_panel.close_panel()
	_check(not game._input_locked, "closing mission panel restores controls")
	var paths := {}
	for id in PetBattleDB.ordered_ids():
		var path := str(PetBattleDB.get_level(id).get("background", ""))
		_check(ResourceLoader.exists(path), "%s supplied background imports" % id)
		paths[path] = true
	_check(paths.size() == 5, "each pet battle has its own supplied background")
	GameState.save_game()
	_check(GameState.load_game() and GameState.structure_level(neighbour) == 5 and GameState.worker_count("builder") == 5, "house levels and recruited specialists persist")
	GameState.set_health(GameState.health_max())
	GameState.start_expedition("tidebound_grotto")
	game._load_dungeon("tidebound_grotto", false)
	await get_tree().process_frame
	await get_tree().process_frame
	var dungeon := game.world as Dungeon
	var guards := []
	for child in dungeon.get_children():
		if child is Enemy:
			child.set_physics_process(false)
			if not child.is_boss:
				guards.append(child)
	_check(guards.size() >= 10 and guards.all(func(n: Enemy) -> bool: return n.active and n._target == dungeon.player), "dungeon monsters pursue immediately on entry")
	_check(dungeon.boss.get_node_or_null("BossHealth") is WorldHealthBar, "boss health floats above the boss")
	for guard in guards:
		guard.active = false
		guard._enter(Enemy.State.WANDER)
	dungeon.player.global_position = dungeon.boss.global_position
	dungeon._physics_process(0.01)
	_check(guards.all(func(n: Enemy) -> bool: return n.active and n._target == dungeon.player), "touching boss calls every living monster to defend it")
	print("--- PB test: %d checks, %s ---" % [checks, "PASS" if failures == 0 else "%d FAILURE(S)" % failures])
	get_tree().quit(0 if failures == 0 else 1)

func _freeze(lobby: Lobby) -> void:
	for child in lobby.get_children():
		if child is Enemy or child is Resident or child is Pet:
			child.set_physics_process(false)
	for gun in get_tree().get_nodes_in_group("house_defenses"):
		gun.set_process(false)
	lobby._rubbish_system.set_process(false)

func _worker(lobby: Lobby, role: String) -> Resident:
	for worker in lobby._residents:
		if worker.worker_role == role:
			return worker
	return null

func _enemy(lobby: Lobby, kind: String, at: Vector2) -> Enemy:
	var enemy := Enemy.new()
	enemy.kind = kind
	enemy.max_hp = 200
	enemy.position = at
	lobby.add_child(enemy)
	enemy.set_physics_process(false)
	return enemy

func _labels(node: Node) -> String:
	var result: String = node.text if node is Label else ""
	for child in node.get_children():
		result += "\n" + _labels(child)
	return result

func _check(ok: bool, message: String) -> void:
	checks += 1
	print("[OK] " if ok else "[FAIL] ", message)
	if not ok:
		failures += 1
