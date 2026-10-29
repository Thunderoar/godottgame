class_name ElementalChecks
extends RefCounted
## Gameplay checks for shared rewards, weapon transactions and all thirty powers.

static func run(game: Game, check: Callable, capture: Callable = Callable()) -> void:
	var saved := GameState.data.duplicate(true)
	var autosave := GameState.autosave_enabled
	var processing := game.is_processing()
	GameState.autosave_enabled = false
	game.set_process(false)
	game.hud.hide_modals()
	GameState.data = GameState._make_default("adam")
	GameState.data.mission_step = MissionDB.STEPS.size()
	await game._load_lobby(false)
	var home := game.world as Lobby
	for actor in home.get_children():
		if actor is Enemy or actor is Resident or actor is VillageHero: actor.set_physics_process(false)
	var sources: Array[Node] = []
	for id in ["arjun","mei_ling"]:
		var friend := VillageHero.new()
		friend.hero_id = id
		friend.position = home.player.position
		home.add_child(friend)
		friend.set_physics_process(false)
		sources.append(friend)
	var resident := Resident.new()
	resident.position = home.player.position
	home.add_child(resident)
	resident.set_physics_process(false)
	sources.append(resident)
	for source in sources:
		for kind in ["fire","urchin"]:
			var enemy := Enemy.new()
			enemy.kind = kind
			enemy.max_hp = 1
			enemy.gold_reward = 13
			enemy.xp_reward = 11
			enemy.position = home.player.position+Vector2(10,0)
			home.add_child(enemy)
			enemy.set_physics_process(false)
			var gold := GameState.gold()
			var xp := _total_xp()
			enemy.take_damage(1,Vector2.ZERO,source)
			check.call(GameState.gold() == gold+13 and _total_xp() == xp+33,"%s kills credit %s Gold and tripled XP directly to the player" % [source.get_class() if source is Resident else source.hero_id,kind])
			enemy.take_damage(100,Vector2.ZERO,source)
			check.call(GameState.gold() == gold+13 and _total_xp() == xp+33,"a dead %s cannot pay allied rewards twice" % kind)
	var emergency := Enemy.new()
	emergency.kind = "fire"
	emergency.settlement_mode = true
	emergency.max_hp = 1
	emergency.xp_reward = 9
	emergency.gold_reward = 15
	home.add_child(emergency)
	emergency.set_physics_process(false)
	var emergency_xp := _total_xp()
	var emergency_gold := GameState.gold()
	emergency.take_damage(1,Vector2.ZERO,resident)
	check.call(_total_xp() == emergency_xp+27 and GameState.gold() == emergency_gold+15,"raid kills also credit player XP and Gold immediately")
	for character in ["adam","arjun","mei_ling"]:
		GameState.data = GameState._make_default(character)
		GameState.add_gold(100000)
		var stock := ItemDB.equipment_for_style(GameState.character_weapon_style())
		var weapons: Array[String] = []
		for id in stock:
			if ItemDB.get_item(id).get("kind","") == "weapon" and int(ItemDB.get_item(id).get("price",0)) > 0: weapons.append(id)
		check.call(weapons.size() >= 9,"%s has at least nine purchasable weapons" % character)
		var id := weapons[-1]
		check.call(bool(GameState.buy_item(id).ok) and bool(GameState.equip_item(id).ok),"%s can buy and equip a new endgame weapon" % character)
		for rank in range(1,6):
			var before := GameState.gold()
			var cost := GameState.weapon_upgrade_cost(id)
			var attack := GameState.attack_power()
			check.call(bool(GameState.upgrade_weapon(id).ok) and GameState.weapon_rank(id) == rank and GameState.gold() == before-cost and GameState.attack_power() > attack,"%s weapon +%d consumes the displayed cost and raises real combat attack" % [character,rank])
		check.call(not bool(GameState.upgrade_weapon(id).ok),"%s weapon cannot exceed +5" % character)
		GameState.save_game()
		check.call(GameState.load_game() and GameState.weapon_rank(id) == 5,"%s weapon upgrades survive JSON save/load" % character)
		game.hud.shop_panel.open_shop("equipment","Garrick")
		for frame in 3: await game.get_tree().process_frame
		var weapon_cards := 0
		for card in game.hud.shop_panel._cards:
			if ItemDB.get_item(card.item_id).get("kind","") == "weapon": weapon_cards += 1
		check.call(weapon_cards == 10,"%s forge shows all ten weapon cards including its upgradeable starter" % character)
		if capture.is_valid():
			game.hud.shop_panel.body.ensure_control_visible(game.hud.shop_panel._cards[0])
			await capture.call("forge_"+character)
			game.hud.shop_panel.body.ensure_control_visible(game.hud.shop_panel._cards[5])
			await capture.call("forge_choices_"+character)
		game.hud.hide_modals()
	GameState.data = GameState._make_default("adam")
	GameState.data.gold = 0
	check.call(not bool(GameState.upgrade_weapon("rusty_sword").ok) and GameState.weapon_rank("rusty_sword") == 0,"an unaffordable upgrade leaves weapon rank unchanged")
	check.call(not bool(GameState.upgrade_weapon("cloth_tunic").ok) and not bool(GameState.upgrade_weapon("monarch_slayer").ok),"non-weapons and unowned weapons cannot be upgraded")
	GameState.data.weapon_upgrades = {"rusty_sword":99.0,"missing":4,"cloth_tunic":2}
	GameState._sanitize()
	check.call(GameState.weapon_rank("rusty_sword") == 5 and GameState.data.weapon_upgrades.size() == 1,"save sanitization clamps ranks and removes invalid upgrade records")
	GameState.data.level = 10
	GameState.data.xp = 1000
	GameState.data.xp_next = 999999
	GameState._sanitize()
	check.call(int(GameState.data.level) > 10 and int(GameState.data.xp_next) == GameState.xp_for_level(int(GameState.data.level)),"legacy exponential XP thresholds migrate without discarding earned XP")
	GameState.data = GameState._make_default("adam")
	GameState.data.level = 99
	GameState.data.xp_next = GameState.xp_for_level(99)
	var seen_skills: Dictionary = {}
	var seen_art: Dictionary = {}
	for portal_id in PortalDB.ordered_ids():
		GameState.data.portals[portal_id].unlocked = true
		GameState.start_expedition(portal_id)
		await game._load_dungeon(portal_id,false)
		var world := game.world as Dungeon
		check.call(game.player() == world.player,"%s binds its own living player during world replacement" % portal_id)
		world.set_physics_process(false)
		world._boss_arrived = true
		world.pet.set_physics_process(false)
		world.player.set_physics_process(false)
		world.player.controls_locked = false
		for node in world.get_children():
			if node is Enemy or node is DungeonHazard: node.set_physics_process(false)
		await game.get_tree().physics_frame
		var boss := world.boss as ElementalBoss
		var def := PortalDB.get_portal(portal_id)
		check.call(boss != null and boss.element == str(def.element) and boss.skills.size() == 3,"%s builds its matching demon with exactly three powers" % portal_id)
		var minions := 0
		var sample: ElementalMinion
		for node in world.get_children():
			if node is ElementalMinion and node.element == boss.element:
				minions += 1
				sample = node
		check.call(minions == (6 if world is TwilightRealm else int(def.monster_count)),"%s small monsters match their ruler's element" % portal_id)
		var sample_start := sample.position
		sample._player = world.player
		sample._target = world.player
		sample.active = true
		sample._state = Enemy.State.CHASE
		sample._power_clock = 0
		sample.position = world.player.position+Vector2(4,0)
		sample._chase(0.016)
		var style := str(ElementDB.get_element(sample.element).get("minion_attack",""))
		var used_power := sample._charging
		if style in ["ranged","homing"]: sample._physics_process(0.6)
		for node in world.get_children():
			if (node is ElementalEffect or node is ElementalProjectile) and node.caster == sample: used_power = true
		check.call(used_power,"%s actually uses its %s elemental attack" % [sample.name_text(),style])
		sample._charging = false
		sample._power_clock = 99
		sample.position = sample_start
		_clear_magic(world)
		var art := boss.sprite.texture.get_image()
		seen_art[art.get_data().hex_encode().sha256_text()] = true
		boss._player = world.player
		boss._target = world.player
		boss.active = true
		boss._special_timer = 99
		boss._state = Enemy.State.CHASE
		for skill in boss.skills:
			_clear_magic(world)
			GameState.set_health(GameState.health_max())
			world.player.invulnerable = 0
			world.player.position = Vector2(24,18)
			boss._charging = false
			boss._cast_special()
			seen_skills[boss.last_skill_id] = true
			var hp := GameState.health()
			check.call(boss.last_skill_id == str(skill.id) and boss._cast_time > 0 and GameState.health() == hp,"%s warns before %s" % [boss._boss_name(),skill.name])
			boss._physics_process(0.86)
			var hit_tested := false
			for node in world.get_children():
				if node is ElementalEffect and node.caster == boss and node.damage > 0:
					world.player.position = node.position+Vector2(40,40)
					node.clock = node.windup+0.01
					node._physics_process(0.05)
					check.call(GameState.health() == hp,"%s can be avoided by leaving its warned area" % skill.id)
					world.player.position = node.position + (node.direction*node.length*0.5 if node.pattern in ["line","wave","cleave"] else (Vector2.RIGHT*node.radius if node.pattern == "ring" else Vector2.ZERO))
					node.clock = node.windup-0.1
					node._physics_process(0.05)
					check.call(GameState.health() == hp,"%s ground warning deals no early damage" % skill.id)
					node._physics_process(0.1)
					hit_tested = GameState.health() < hp
					break
				if node is ElementalProjectile and node.caster == boss:
					node.set_physics_process(false)
					world.player.position = node.position+Vector2(20,20)
					node._physics_process(0.04)
					check.call(GameState.health() == hp,"%s projectiles miss a player who dodges their path" % skill.id)
					world.player.position = node.position+node.direction*0.1
					node._physics_process(0.04)
					hit_tested = GameState.health() < hp
					break
			if str(skill.pattern) == "summon":
				hit_tested = boss._summons.size() == 3
				for summoned in boss._summons: summoned.set_physics_process(false)
			check.call(hit_tested,"%s executes real damaging magic or living summoned attackers" % skill.id)
			boss._cast_time = 0
			boss._pending = {}
			boss._charging = false
		_clear_magic(world)
		boss.position = Vector2(24,10)
		world.player.position = Vector2(24,20)
		if capture.is_valid():
			for layer in world.get_children():
				if layer is CanvasLayer: layer.visible = false
			world.camera.set_process(false)
			world.camera.set_physics_process(false)
			world.camera.global_position = Vector2(24,16)
			world.camera.zoom = Vector2.ONE*minf(world.get_viewport_rect().size.x/50.0,world.get_viewport_rect().size.y/34.0)
			await capture.call("realm_"+boss.element)
			world.camera.global_position = Vector2(24,10)
			world.camera.zoom = Vector2.ONE*28
			await capture.call("boss_"+boss.element)
		var orphan := boss._ground(world.player.position,"circle",2,1)
		boss.dead = true
		orphan._physics_process(1)
		check.call(orphan.is_queued_for_deletion(),"%s magic cancels when its caster dies" % boss.element)
	check.call(seen_skills.size() == 30 and seen_art.size() == 10,"all ten bosses have unique artwork and thirty named powers")
	GameState.data = saved
	GameState._emit_all()
	await game._load_lobby(false)
	game.set_process(processing)
	GameState.autosave_enabled = autosave

static func _clear_magic(world: Node2D) -> void:
	for node in world.get_children():
		if node is ElementalEffect or node is ElementalProjectile:
			world.remove_child(node)
			node.queue_free()

static func _total_xp() -> int:
	var total := int(GameState.data.xp)
	for level in range(1,int(GameState.data.level)): total += GameState.xp_for_level(level)
	return total
