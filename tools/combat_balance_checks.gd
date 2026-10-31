extends RefCounted
## Exercise live enemy constructors and real upgrade/mitigation transactions.
static func run(game: Game, check: Callable) -> void:
	var saved := GameState.data.duplicate(true)
	var autosave := GameState.autosave_enabled
	GameState.autosave_enabled = false
	var fixture := Node2D.new()
	game.add_child(fixture)
	for kind in ["bogling", "drowned", "rubbish", "raider", "fire", "urchin"]:
		var enemy := Enemy.new()
		enemy.kind = kind
		fixture.add_child(enemy)
		enemy.set_physics_process(false)
		check.call(enemy.max_hp == 61 and enemy.hp == 61 and enemy.damage == 10 and is_equal_approx(enemy.attack_interval, 1.215), "tougher live regular enemy: " + kind)
		enemy._enter(Enemy.State.WINDUP)
		check.call(enemy._state_time == 0.42 and enemy.collision_mask == 1 and enemy.gold_reward == 9, "difficulty preserves warning, collision and reward: " + kind)
	for element in ElementDB.ELEMENTS:
		var minion := ElementalMinion.new()
		minion.element = str(element)
		fixture.add_child(minion)
		minion.set_physics_process(false)
		check.call(minion.hp == 61 and minion.damage == 10 and minion.special_damage == 10, "elemental minion melee and power damage are tuned once: " + str(element))
	for profile in RealmCombatDB.PROFILES:
		var guard := RealmGuard.new()
		guard.profile = str(profile)
		fixture.add_child(guard)
		guard.set_physics_process(false)
		check.call(guard.hp == 61 and guard.damage == 10, "Twilight guard inherits the same fixed difficulty: " + str(profile))
	for id in PortalDB.ordered_ids():
		var definition := PortalDB.get_portal(id)
		var boss := ElementalBoss.new()
		boss.element = str(definition.element)
		boss.max_hp = int(definition.boss_hp)
		boss.damage = int(definition.boss_damage)
		boss.special_damage = int(definition.boss_damage)
		boss.projectile_damage = int(definition.boss_projectile_damage)
		fixture.add_child(boss)
		boss.set_physics_process(false)
		check.call(boss.hp > int(definition.boss_hp) and boss.damage > int(definition.boss_damage) and boss.special_damage == boss.damage and boss.projectile_damage > int(definition.boss_projectile_damage), "portal ruler health, melee, ground powers and projectiles all increase: " + id)
	var kraken := KrakenKing.new()
	fixture.add_child(kraken)
	kraken.set_physics_process(false)
	var crab := KrakenCrab.new()
	fixture.add_child(crab)
	crab.set_physics_process(false)
	check.call(kraken.hp == 972 and kraken.damage == 20 and kraken.special_damage == 28 and crab.hp == 70 and crab.damage == 9, "Kraken and all fortress crab guards are tougher")
	check.call(KrakenKing.WARNING_SECONDS == 0.9 and KrakenKing.EXTEND_SECONDS == 0.4 and crab.gold_reward == 6, "fortress telegraphs and collectible rewards retain their contracts")
	GameState.data = GameState._make_default("adam")
	GameState.data.gold = 10000
	GameState.data.equipped.armor = ""
	GameState.data.equipped.shield = ""
	var starter := _hits(fixture, GameState.attack_power())
	GameState.add_item("iron_sword",1,false)
	check.call(bool(GameState.equip_item("iron_sword").ok), "the first shop sword is equipable before workshop progression")
	var iron := _hits(fixture, GameState.attack_power())
	for rank in 5:
		check.call(bool(GameState.upgrade_weapon("iron_sword").ok), "real Gold upgrade transaction succeeds: iron sword +%d" % (rank+1))
	var upgraded := _hits(fixture, GameState.attack_power())
	check.call(starter == 5 and iron == 3 and upgraded == 2, "a tougher 58-HP target takes five starter hits, three iron hits or two iron +5 hits")
	GameState.data.hp = 100
	GameState.data.shield = 0
	GameState.damage_player(12)
	var unarmoured := 100-GameState.health()
	GameState.add_item("leather_vest",1,false)
	GameState.equip_item("leather_vest")
	GameState.data.hp = 100
	GameState.damage_player(12)
	check.call(unarmoured == 12 and 100-GameState.health() == 6, "purchased armour halves a stronger emergency urchin's hit")
	var arena := game.hud.pet_battle_panel
	for id in PetBattleDB.ordered_ids():
		var definition := PetBattleDB.get_level(id)
		arena._start_battle(GameState.get_active_pet(),definition,id)
		check.call(arena._opponent_max > int(definition.hp) and arena._enemy_damage > int(definition.damage), "manual rival battle also uses tougher health and damage: " + id)
		arena._battle_active = false
	Sfx.stop_battle_music()
	check.call(PetDB.attack_damage("ember",3) > PetDB.attack_damage("ember",1) and PetDB.max_health("ember",3) > PetDB.max_health("ember",1), "companion levels still improve offence and survivability without adaptive enemy scaling")
	fixture.queue_free()
	await game.get_tree().process_frame
	GameState.data = saved
	GameState.autosave_enabled = autosave
	GameState._emit_all()

static func _hits(parent: Node2D, power: int) -> int:
	var target := Enemy.new()
	target.max_hp = 40
	parent.add_child(target)
	target.set_physics_process(false)
	var hits := 0
	# Stay above zero on all but the last measured hit to avoid rewards in this fixture.
	while target.hp > power:
		target.take_damage(power)
		hits += 1
	target.queue_free()
	return hits+1
