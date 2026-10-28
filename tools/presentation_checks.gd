extends RefCounted
## Save-safe checks for authored realms, readable sea lessons and bounded lights.
static func run(game: Game, check: Callable) -> void:
	var snapshot := GameState.data.duplicate(true)
	var autosave := GameState.autosave_enabled
	var quality := GameSettings.effects_quality()
	GameState.autosave_enabled = false
	var hashes := {}
	for element in RealmPresentation.ORDER:
		for boss in [true,false]:
			var texture := RealmPresentation.actor_texture(element,boss)
			check.call(texture is AtlasTexture and Rect2(Vector2.ZERO,texture.atlas.get_size()).encloses(texture.region) and texture.get_image().detect_alpha() != Image.ALPHA_NONE,"%s %s uses bounded imported transparent game art" % [element,"boss" if boss else "minion"])
			hashes[texture.get_image().get_data().hex_encode().sha256_text()] = true
	check.call(hashes.size() == 20,"all bosses and minions use twenty distinct authored sprites")
	for element in RealmPresentation.ORDER:
		for boss in [true,false]:
			var actor: Enemy = ElementalBoss.new() if boss else ElementalMinion.new()
			actor.set("element",element)
			game.world.add_child(actor)
			actor.set_physics_process(false)
			var rest := actor._sprite_rest_scale()
			actor._enter(Enemy.State.WINDUP)
			var windup := actor._pose_tween
			var bounded := true
			for step in [0.04,0.05,0.08,0.1]:
				windup.custom_step(step)
				actor.call("_update_art")
				var ratio := actor.sprite.scale/rest
				bounded = bounded and ratio.x <= 1.13 and ratio.y <= 1.13 and ratio.x > 0.85 and ratio.y > 0.85
			actor._enter(Enemy.State.RECOVER)
			bounded = bounded and actor.sprite.scale.is_equal_approx(rest) and not windup.is_valid()
			actor._lunge(Vector2.RIGHT)
			var lunge := actor._pose_tween
			lunge.custom_step(0.1)
			actor._enter(Enemy.State.STAGGER)
			bounded = bounded and actor.sprite.scale.is_equal_approx(rest) and actor.sprite.position.is_equal_approx(actor._sprite_rest_position()) and not lunge.is_valid()
			check.call(bounded,"%s %s stays at authored size throughout windup, recovery and interrupted lunge" % [element,"boss" if boss else "minion"])
			actor.queue_free()
	await game._load_lobby(false)
	await game.get_tree().process_frame
	var home := game.world as Lobby
	GameState.data.world_time = 240.0
	GameSettings.set_effects_quality("high",false)
	home._update_daylight()
	var lit := 0
	for lamp in home._local_lights:
		if is_instance_valid(lamp) and lamp.enabled: lit += 1
	check.call(lit > 0 and lit <= Lobby.MAX_VISIBLE_LIGHTS,"night keeps local lighting within its render budget")
	GameSettings.set_effects_quality("low",false)
	home._update_daylight()
	lit = 0
	for lamp in home._local_lights:
		if is_instance_valid(lamp) and lamp.enabled: lit += 1
	check.call(lit == 0,"low quality retains the night grade while disabling dynamic lights")
	var resident := Resident.new()
	home.add_child(resident)
	resident.set_physics_process(false)
	resident.safe_margin = 0.001
	resident.position = home.safe_spawn(Vector2(30,22),0.3)
	var destination := resident.position+Vector2(2,0)
	home.resident_path(resident.position,destination)
	var obstacle := StaticBody2D.new()
	obstacle.position = resident.position+Vector2(0.271,0)
	var body := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(0.1,2)
	body.shape = rectangle
	obstacle.add_child(body)
	home.add_child(obstacle)
	await game.get_tree().physics_frame
	var revision := home.resident_routes_revision()
	resident._path_goal = destination
	resident._path = PackedVector2Array([destination])
	resident._path_revision = revision
	resident._stuck_time = 1.0
	resident._walk_to(destination,1.0,0.1)
	check.call(resident._path_goal.x == INF and home.resident_routes_revision() == revision,"a physically blocked resident retries without invalidating the whole village navigation grid")
	obstacle.queue_free()
	resident.queue_free()
	game._clear_world()
	var ocean := OceanJourney.new()
	game.world = ocean
	game._world_holder.add_child(ocean)
	await game.get_tree().process_frame
	game.hud.set_world(ocean)
	ocean.set_process(false)
	ocean._process(4)
	check.call(ocean.phase == OceanJourney.Phase.BRIEFING and ocean._sea_guide.visible,"ocean entry waits for the sea lesson before gameplay")
	var fullness := ocean.fullness
	ocean._process(2)
	check.call(ocean.elapsed == 0 and ocean.fullness == fullness and ocean.items.is_empty(),"reading the sea guide cannot drain fullness or create hazards")
	check.call(not ocean.choose_action("pickup"),"briefing cannot accidentally consume an item")
	ocean.dismiss_sea_guide()
	for kind in ["food","trash","heart","bomb","shark"]:
		var item := ocean.spawn_item(kind,30)
		check.call(item.node.get_child_count() == 0,"%s has no floating instruction label" % kind)
	ocean.show_sea_guide()
	check.call(ocean.phase == OceanJourney.Phase.BRIEFING and ocean._sea_guide.visible,"Sea Guide can reopen safely during a route")
	ocean.dismiss_sea_guide()
	check.call(ocean.phase == OceanJourney.Phase.RUNNING and not ocean._sea_guide.visible,"Ready resumes the same route without resetting progress")
	GameSettings.set_effects_quality(quality,false)
	GameState.data = snapshot
	GameState._emit_all()
	await game._load_lobby(false)
	await game.get_tree().process_frame
	GameState.autosave_enabled = autosave
