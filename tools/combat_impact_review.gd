extends Node
## Same deterministic input for pristine / modified / restored projects.
var game: Game
var fails := 0
var checks := 0
var upgraded := false
var impactful := false
var output := ""

func _ready() -> void:
	if not TestEnvironment.require_isolation():
		get_tree().quit(1)
		return
	output = OS.get_environment("TIDESWORN_TEST_ROOT").path_join("shots")
	DirAccess.make_dir_recursive_absolute(output)
	GameState.autosave_enabled = false
	GameState.new_game("adam")
	game = load("res://scenes/game.tscn").instantiate() as Game
	add_child(game)
	await get_tree().process_frame
	game.set_process(false)
	game._load_lobby(false)
	await get_tree().process_frame
	await get_tree().process_frame
	game.title_screen.hide()
	game.hud.show()
	game.hud.tutorial_guide._skip()
	_freeze(game.world)
	var p := game.player()
	p.position = Vector2(35,33.5)
	p.controls_locked = false
	p.facing = Vector2.RIGHT
	game.world.camera.position = p.position + Vector2(0,-0.5)
	game.world.camera.zoom = Vector2.ONE * 68
	game.world.camera.reset_smoothing()
	game.world.camera.force_update_scroll()
	var target := Enemy.new()
	target.kind = "urchin"
	target.max_hp = 10000
	target.damage = 0
	target.spawn_shimmer = false
	target.position = p.position + Vector2(1.65,0)
	game.world.add_child(target)
	_freeze(target)
	var hp0 := target.hp
	var fx: Node = p.get_node_or_null("Slash")
	upgraded = fx != null and fx.has_method("strike")
	impactful = fx.has_method("confirm_hit")
	print("IMPACT_PIPELINE=", "contact-hold+body-recoil+directional-punch" if impactful else "layered-ribbons-only")
	print("VISUAL_PIPELINE=", "layered-ribbon+pooled-contact" if upgraded else "legacy-sprite+sparks")
	_check(p.try_attack(), "attack accepted")
	_check(p._attack_phase == Player.AttackPhase.ANTICIPATION, "attack starts with anticipation")
	_check(target.hp == hp0, "anticipation causes no damage")
	await _shot("01_anticipation")
	var damage := int(round(float(GameState.attack_power()) * float(GameState.character_data().get("attack_mult",1.0))))
	p._update_attack_phase(0.061)
	_check(target.hp == hp0-damage, "active frame deals exact existing sword damage")
	_check(is_equal_approx(p._attack_timer,float(GameState.character_data().attack_cooldown)), "cooldown restarts at active frame")
	_check(p.get_node("Slash").visible, "legacy slash compatibility remains visible")
	if impactful:
		var elapsed_before: float = fx.get("elapsed")
		fx.call("advance",0.01)
		_check(is_equal_approx(float(fx.get("elapsed")),elapsed_before), "confirmed contact holds blade animation without holding the attack phase")
		var motion: Node = p.get_node("CombatBodyMotion")
		print("CONTACT_HOLD=",fx.get("contact_hold")," BODY_HOLD=",motion.get("hold"))
	var camera: Node = game.world.camera
	if camera.has_method("advance_feedback"):
		camera.call("advance_feedback",0.025)
		print("DIRECTIONAL_PUNCH=",camera.get("offset")," COUNT=",camera.get("impact_count"))
		camera.set("offset",Vector2.ZERO)
	await _shot("02_first_cut_contact")
	await _shot("02a_cut_progression")
	await _shot("02b_cut_follow_through")
	p._update_attack_phase(0.081)
	p._update_attack_phase(0.141)
	_check(not p.attacking, "recovery returns to idle")
	for step in [1,2]:
		_settle()
		p._attack_timer = 0
		p._attack_step = step
		p._chain_style = "sword"
		p._chain = AttackDB.chain("sword")
		p._attack_dir = Vector2.RIGHT
		p._begin_active_phase()
		await _shot("03_reverse_cut" if step == 1 else "04_finisher_thrust")
	_settle()
	# Confirmed heavy contacts use an authored finisher, not a new damage multiplier.
	if impactful:
		var pool: Node = Vfx.pool()
		print("FINISHER_STYLE=",pool.get("_contacts").any(func(n: Node) -> bool: return n.get("kind") == "finisher"))
	var original_hp := target.hp
	target.is_boss = true
	target.take_damage(1,Vector2.RIGHT,p)
	_check(target.hp == original_hp-1, "armored cue does not block damage")
	await _shot("05_armored_contact")
	_settle()
	HitFeedback.impact(target,Vector2.RIGHT,42,{"crit":true,"shake":0.0})
	await _shot("06_critical_presentation")
	_settle()
	p.invulnerable = 0
	p.take_damage(1,p.global_position-Vector2(1,0))
	await _shot("07_player_hurt")
	_settle()
	GameSettings.set_reduce_motion(true,false)
	GameSettings.set_effects_quality("low",false)
	p._show_slash("lr")
	HitFeedback.impact(target,Vector2.RIGHT,7,{})
	await _shot("08_low_reduced_motion")
	_check(not GameSettings.screen_shake() or game.world.camera.shake_time == 0 or not game.world.camera.is_physics_processing(), "fixture uses a fixed camera")
	GameSettings.set_reduce_motion(false,false)
	GameSettings.set_effects_quality("high",false)
	for style in ["scythe","bow"]:
		_settle()
		p._chain_style = style
		p._show_slash("shot" if style == "bow" else "lr")
		await _shot("09_"+style)
	_settle()
	p._chain_style = "sword"
	p._chain = AttackDB.chain("sword")
	p._attack_step = 0
	p._attack_timer = 0
	target.position += Vector2(20,0)
	var punches_before: int = int(game.world.camera.get("impact_count")) if impactful else 0
	p._begin_active_phase()
	if impactful:
		_check(is_equal_approx(float(fx.get("contact_hold")),0.0), "missed swing has no contact hold")
		_check(int(game.world.camera.get("impact_count")) == punches_before, "missed swing has no camera punch")
	await _shot("10_whiff_no_contact")
	if upgraded:
		for quality in ["low","med","high"]:
			GameSettings.set_effects_quality(quality,false)
			for reduced in [false,true]:
				GameSettings.set_reduce_motion(reduced,false)
				for style in ["sword","scythe","bow","hammer"]:
					for dir in [Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT,Vector2.UP]:
						for arc in ["lr","rl","thrust","slam","shot"]:
							fx.call("strike",dir,style,arc,2.05)
							fx.call("advance",0.035)
							await RenderingServer.frame_post_draw
		print("DRAW_MATRIX=480 weapon variants rendered")
	print("BEHAVIOR damage=", damage, " cooldown=", GameState.character_data().attack_cooldown, " phases=anticipation>active>recovery>idle")
	print("--- combat impact: %d checks, %s ---" % [checks,"PASS" if fails == 0 else "FAIL"])
	# Stop paused capture tweens, then let queued frees drain through a rendered frame.
	for pending in get_tree().get_processed_tweens(): pending.kill()
	game.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	# Drain short-lived scene timers and render-resource release after freeing the world.
	await get_tree().create_timer(0.4).timeout
	# Do not tear down the engine inside RenderingServer's signal callback.
	get_tree().call_deferred("quit",0 if fails == 0 else 1)

func _shot(id: String) -> void:
	# Freeze presentation at a reproducible early-contact sample, not wall-clock time.
	for t in get_tree().get_processed_tweens():
		t.pause()
		t.custom_step(0.035)
	for n in get_tree().get_nodes_in_group("combat_visual_effects"):
		n.set_process(false)
		n.call("advance",0.035)
	# Paired captures keep camera framing identical; punch is sampled separately.
	game.world.camera.offset = Vector2.ZERO
	game.world.camera.force_update_scroll()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	if DisplayServer.get_name() != "headless":
		get_viewport().get_texture().get_image().save_png(output.path_join(id+".png"))
	print("FRAME=",id)

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: fails += 1
	print("[%s] %s" % ["OK" if ok else "FAIL",label])

func _freeze(n: Node) -> void:
	n.set_process(false)
	n.set_physics_process(false)
	for c in n.get_children(): _freeze(c)

func _settle() -> void:
	for tween in get_tree().get_processed_tweens(): tween.custom_step(2.0)
	for node in get_tree().get_nodes_in_group("combat_visual_effects"): node.call("advance",2.0)
