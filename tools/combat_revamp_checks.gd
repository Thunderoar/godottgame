extends RefCounted
## Behavioral checks executed inside the gate's verified temporary user data.

static func run(game: Game, check: Callable) -> void:
	var snapshot := GameState.data.duplicate(true)
	var was_processing := game.is_processing()
	var autosave := GameState.autosave_enabled
	game.set_process(false)
	GameState.autosave_enabled = false
	for hero in CharacterDB.ids():
		GameState.new_game(hero)
		game._load_lobby(false)
		_freeze(game.world)
		await game.get_tree().process_frame
		await game.get_tree().process_frame
		_freeze(game.world)
		game.hud.tutorial_guide._skip()
		var player := game.player()
		player.controls_locked = false
		player.facing = Vector2.RIGHT
		var dummy := Enemy.new()
		dummy.max_hp = 10000
		dummy.speed = 0.0
		dummy.damage = 0
		dummy.position = player.position + Vector2(2, 0)
		game.world.add_child(dummy)
		dummy.set_physics_process(false)
		check.call(game.hud._control_nodes.size() == 4 and game.hud._control_nodes.has("attack"), "%s keeps basic attack, Use, Pack and joystick" % hero)
		check.call(not player.has_method("try_skill") and not player.has_method("skill_cooldown"), "%s has no player skill casting or cooldowns" % hero)
		check.call(not GameState.data.has("mana") and not GameState.data.has("mana_max") and not GameState.character_data().has("mana"), "%s has no mana stat" % hero)
		for action in ["skill_1", "skill_2", "skill_3", "use_mana_potion"]:
			check.call(not InputMap.has_action(action) and not game.hud._control_nodes.has(action), "%s removes obsolete %s from keyboard and touch" % [hero, action])
		var before := dummy.hp
		check.call(player.try_attack(), "%s basic attack still activates" % hero)
		player._update_attack_phase(1.0)
		await game.get_tree().create_timer(0.3).timeout
		check.call(dummy.hp < before, "%s basic attack still deals real damage" % hero)
		var button := game.hud._attack_button
		button._press()
		check.call(Input.is_action_pressed("attack"), "%s basic touch attack uses InputMap" % hero)
		button.cancel()
		check.call(not Input.is_action_pressed("attack"), "%s cancelling basic attack releases InputMap" % hero)
	# Simulate an older save, including saved control positions for retired skills.
	var gold := GameState.gold()
	var weapon := GameState.equipped_item("weapon")
	GameState.data.mana = 12.0
	GameState.data.mana_max = 65.0
	GameState.data.inventory.mana_potion = 4.0
	GameState.data.settings.control_layout.skill_1 = {"x": 100.0, "y": 200.0, "size": 76.0}
	GameState.data.settings.control_layout.inventory = {"x": 240.0, "y": 600.0, "size": 64.0}
	GameState.save_game()
	check.call(GameState.load_game() and not GameState.data.has("mana") and not GameState.data.has("mana_max") and GameState.item_count("mana_potion") == 0, "legacy saves discard retired mana stats and potions")
	check.call(GameState.gold() == gold and GameState.equipped_item("weapon") == weapon and GameState.item_count("health_potion") == 2, "mana migration preserves currency, weapon and health potions")
	check.call(not GameState.control_layout().has("skill_1") and GameState.control_layout().has("inventory"), "mana migration removes retired controls and keeps active customization")
	GameState.save_game()
	check.call(GameState.load_game() and not GameState.data.has("mana"), "mana removal survives a second save and load")
	GameState.new_game("adam")
	game._load_lobby(false)
	await game.get_tree().process_frame
	await game.get_tree().process_frame
	_freeze(game.world)
	for duel in PetBattleDB.ordered_ids():
		var result := GameState.complete_pet_battle(duel)
		var rival := str(PetBattleDB.get_level(duel).get("opponent_pet", ""))
		check.call(bool(result.get("ok", false)) and bool(GameState.get_pet(rival).get("owned", false)), "winning %s grants the actual rival pet" % duel)
		var count: int = GameState.data.village_pets.size()
		GameState.complete_pet_battle(duel)
		check.call(GameState.data.village_pets.size() == count, "replaying %s does not duplicate its guardian" % duel)
	await game.get_tree().process_frame
	check.call(game.get_tree().get_nodes_in_group("village_pets").size() == 5, "five won rivals spawn as village guardians")
	var guardian: VillagePet = game.get_tree().get_first_node_in_group("village_pets")
	guardian.set_physics_process(false)
	for kind in ["fire", "urchin"]:
		var threat := Enemy.new()
		threat.kind = kind
		threat.max_hp = 100
		threat.position = guardian.position + Vector2(1, 0)
		game.world.add_child(threat)
		threat.set_physics_process(false)
		guardian._route_timer = 0.0
		guardian._attack_timer = 0.0
		guardian._physics_process(0.01)
		check.call(threat.hp < threat.max_hp, "recruited pet attacks %s monsters near residents" % kind)
		threat.queue_free()
		await game.get_tree().process_frame
	var gun: HouseDefense
	for candidate in game.get_tree().get_nodes_in_group("roof_guns"):
		if candidate.structure.structure_id == "cottage":
			gun = candidate
	gun._process(0.0)
	check.call(not gun.visible and not GameState.has_roof_gun("cottage"), "new homes have no free rooftop gun")
	GameState.data.gold = 0
	var balance := GameState.gold()
	check.call(not GameState.buy_roof_gun("cottage").ok and GameState.gold() == balance, "insufficient gold cannot install a gun")
	GameState.add_gold(1000)
	balance = GameState.gold()
	var cost := GameState.roof_gun_cost()
	check.call(GameState.buy_roof_gun("cottage").ok and GameState.gold() == balance - cost, "buying a rooftop gun charges its exact gold cost")
	balance = GameState.gold()
	check.call(not GameState.buy_roof_gun("cottage").ok and GameState.gold() == balance, "duplicate gun purchases never charge twice")
	check.call(not GameState.buy_roof_gun("missing_house").ok, "unknown houses cannot receive a gun")
	for kind in ["fire", "urchin"]:
		var target := Enemy.new()
		target.kind = kind
		target.max_hp = 100
		target.position = gun.global_position + Vector2(3, 0)
		game.world.add_child(target)
		target.set_physics_process(false)
		gun._cooldown = 0.0
		var sound_cursor := Sfx._next_player
		gun._process(0.01)
		check.call((Sfx._next_player == sound_cursor) if kind == "fire" else (Sfx._next_player != sound_cursor), "roof gun firing at %s follows its combat audio policy" % kind)
		await game.get_tree().create_timer(0.3).timeout
		check.call(gun.visible and target.hp < target.max_hp, "purchased rooftop gun damages %s with a bullet" % kind)
		target.queue_free()
		await game.get_tree().process_frame
	GameState.save_game()
	check.call(GameState.load_game() and GameState.has_roof_gun("cottage") and GameState.data.village_pets.size() == 5, "gun purchases and recruited defenders survive save/load")
	GameState.data.character_id = "farhan"
	GameState.save_game()
	check.call(GameState.load_game() and GameState.data.character_id == "arjun" and GameState.character_weapon_style() == "scythe", "legacy hammer hero migrates to Arjun without losing progress")
	check.call(GameState.has_roof_gun("cottage") and GameState.data.village_pets.size() == 5, "legacy hero migration preserves village unlocks")
	await game.enter_home()
	check.call(is_instance_valid(game.home_interior) and game.get_tree().get_nodes_in_group("home_beds").size() == 1, "the main house contains an interactable bed")
	var bed: HouseBed = game.get_tree().get_first_node_in_group("home_beds")
	bed.interact(game.player())
	check.call(game.player().sleeping, "the indoor bed starts the existing sleep recovery")
	game.player().cancel_sleep()
	await game.leave_home()
	GameState.start_expedition("tidebound_grotto")
	game._load_dungeon("tidebound_grotto", false)
	await game.get_tree().process_frame
	await game.get_tree().process_frame
	var dungeon := game.world as Dungeon
	_freeze(dungeon)
	var initial_distance := dungeon.boss.global_position.distance_to(dungeon.player.global_position)
	dungeon._physics_process(Dungeon.BOSS_ARRIVAL_SECONDS)
	check.call(initial_distance > 15 and dungeon.boss.dungeon_alerted and dungeon.boss.active, "boss awakens and pursues without needing a close approach")
	check.call(game.get_tree().get_nodes_in_group("dungeon_hazards").size() == 6, "portal contains six telegraphed rune traps")
	check.call(Sfx.battle_track == "tidebound_grotto" and Sfx._music.playing and Sfx._music.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "entering a monster portal starts looping battle music")
	var trap: DungeonHazard = game.get_tree().get_first_node_in_group("dungeon_hazards")
	dungeon.player.global_position = trap.global_position
	dungeon.player.controls_locked = false
	dungeon.player.invulnerable = 0.0
	GameState.data.shield = 0
	var hp := GameState.health()
	trap.clock = 0.0
	trap._physics_process(0.5)
	check.call(GameState.health() == hp, "rune warning gives time to escape before damage")
	trap._physics_process(0.51)
	check.call(GameState.health() < hp, "standing in an active rune deals damage")
	GameState.leave_portal_safely()
	game._load_lobby(false)
	await game.get_tree().process_frame
	check.call(Sfx.battle_track.is_empty() and not Sfx._music.playing, "returning home stops portal music")
	game.hud.pet_battle_panel.open_pet_battles()
	check.call(game.hud.pet_battle_panel.start_battle("pet_duel_1") and Sfx.battle_track == "pet_duel_1", "pet portal starts its own battle track")
	game.hud.pet_battle_panel.close_panel()
	check.call(Sfx.battle_track.is_empty(), "closing a pet battle stops its music")
	GameState.data = snapshot
	GameState._emit_all()
	game._load_lobby(false)
	await game.get_tree().process_frame
	GameState.autosave_enabled = autosave
	game.set_process(was_processing)

static func _freeze(node: Node) -> void:
	node.set_process(false)
	node.set_physics_process(false)
	for child in node.get_children():
		_freeze(child)
