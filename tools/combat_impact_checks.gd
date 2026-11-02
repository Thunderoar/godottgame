extends RefCounted
## Tactile presentation invariants. No live saves; canonical gate owns isolation.
class DummyEnemy extends Enemy:
	func _award_death_rewards() -> void:
		pass # Lethal presentation fixtures do not modify progression.

static func run(game: Game, check: Callable) -> void:
	var settings := GameSettings._values.duplicate(true)
	for key in ["master_volume","effects_volume"]: GameSettings.set_value(key,100,false)
	GameSettings.set_value("mute_all",false,false)
	GameSettings.set_reduce_motion(false,false)
	GameSettings.set_effects_quality("high",false)
	GameSettings.set_screen_shake(true,false)
	var world := game.world
	var fixture := Node2D.new()
	fixture.name = "CombatImpactFixture"
	world.add_child(fixture)
	var p := Player.new()
	p.position = Vector2(1200,1200)
	fixture.add_child(p)
	_freeze(p)
	var cam := FollowCamera.new()
	fixture.add_child(cam)
	cam.enabled = false
	cam.set_physics_process(false)
	var body := p._combat_motion
	var rest := p._visual.offset
	var position0 := p.position
	var hp0 := GameState.health()
	var power0 := GameState.attack_power()
	var engine_scale := Engine.time_scale
	var paused0 := game.get_tree().paused
	for direction in [Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT,Vector2.UP]:
		body.windup(direction,0.06)
		body.advance(0.05)
		check.call(body.displacement.dot(direction) < 0, "impact: wind-up loads opposite the strike " + str(direction))
		body.swing(direction)
		check.call(body.displacement.dot(direction) > 0.17, "impact: strike follows through along the aim " + str(direction))
		var before := body.age
		body.confirm_hit(0.045)
		body.advance(0.02)
		check.call(is_equal_approx(body.age,before), "impact: body contact hold affects only its visual clock " + str(direction))
		body.advance(1.0)
		check.call(body.stage == "idle" and p._visual.offset == rest and is_zero_approx(p._visual.skew), "impact: pose restores exact rest offset/skew " + str(direction))
	check.call(p.position == position0, "impact: body follow-through never moves the collision actor")
	body.recoil(Vector2.RIGHT,1.4)
	var regular_push := body.displacement.length()
	body.recoil(Vector2.RIGHT,1.4,true)
	check.call(body.displacement.length() < regular_push*0.5, "impact: bosses visually absorb more force without gaining stagger")
	body.recoil(Vector2.RIGHT,1.0)
	var first := p._visual.offset
	body.recoil(Vector2.RIGHT,1.0)
	check.call(p._visual.offset == first, "impact: repeated recoil never accumulates sprite offset drift")
	for quality in ["low","med","high"]:
		GameSettings.set_effects_quality(quality,false)
		for reduced in [false,true]:
			GameSettings.set_reduce_motion(reduced,false)
			body.swing(Vector2.RIGHT,1.45)
			body.advance(0.01)
			var should_move: bool = quality != "low" and not reduced
			check.call((body.displacement.length() > 0.0) == should_move, "impact: body motion obeys %s reduced=%s" % [quality,reduced])
			p._combat_visuals.strike(Vector2.RIGHT,"sword","lr",2.05)
			p._combat_visuals.confirm_hit(true)
			check.call((p._combat_visuals.contact_hold > 0.0) == should_move, "impact: blade hold obeys %s reduced=%s" % [quality,reduced])
	GameSettings.set_reduce_motion(false,false)
	GameSettings.set_effects_quality("high",false)
	p._combat_visuals.strike(Vector2.RIGHT,"sword","lr",2.05)
	p._combat_visuals.confirm_hit()
	var clock := p._combat_visuals.elapsed
	p._combat_visuals.advance(0.02)
	check.call(is_equal_approx(p._combat_visuals.elapsed,clock), "impact: confirmed blade locks on the contact pose")
	GameSettings.set_reduce_motion(true,false)
	p._combat_visuals.advance(0.01)
	body.advance(0)
	check.call(p._combat_visuals.contact_hold == 0 and body.displacement == Vector2.ZERO, "impact: live Reduce Motion immediately releases holds/recoil")
	GameSettings.set_reduce_motion(false,false)
	p._combat_visuals.advance(1.0)
	check.call(not p._combat_visuals.visible, "impact: large-delta animation drains hold and still expires")
	for dir in [Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT,Vector2.UP]:
		cam.clear_feedback()
		cam.punch(dir,1.0)
		cam.advance_feedback(0.025)
		check.call(cam.offset.dot(dir) > 0.01 and absf(cam.offset.cross(dir)) < 0.0001, "impact: camera kick follows contact direction " + str(dir))
		cam.advance_feedback(1.0)
		check.call(cam.offset == Vector2.ZERO and cam.impact_time == 0, "impact: camera impulse returns to exact rest " + str(dir))
	for i in 30: cam.punch(Vector2.RIGHT,100.0)
	cam.shake(100,0.2)
	cam.advance_feedback(0.025)
	check.call(cam.offset.length() <= 0.08001 and cam.impact_strength <= 1.6, "impact: simultaneous feedback remains bounded; no additive camera runaway")
	GameSettings.set_screen_shake(false,false)
	cam.advance_feedback(0)
	check.call(cam.offset == Vector2.ZERO and cam.impact_time == 0 and cam.shake_time == 0, "impact: disabling shake clears displacement immediately")
	GameSettings.set_screen_shake(true,false)
	cam.clear_feedback()
	# Same accepted swing can damage several targets, but emits ONE camera/audio accent.
	var targets: Array[Enemy] = []
	for i in 2:
		var enemy := DummyEnemy.new()
		enemy.kind = "bogling"
		enemy.max_hp = 10000
		enemy.damage = 0
		enemy.speed = 0
		enemy.spawn_shimmer = false
		enemy.position = p.position + Vector2(1.2+i*0.35,0)
		fixture.add_child(enemy)
		_freeze(enemy)
		targets.append(enemy)
	p.controls_locked = false
	p.facing = Vector2.RIGHT
	p._attack_timer = 0
	p._attack_phase = Player.AttackPhase.NONE
	var before_hp: Array[int] = [targets[0].hp,targets[1].hp]
	var cursor := Sfx._next_player
	var punches := cam.impact_count
	var damage := int(round(float(GameState.attack_power())*float(GameState.character_data().get("attack_mult",1.0))))
	check.call(p.try_attack() and targets[0].hp == before_hp[0], "impact: anticipation still cannot deal damage")
	p._update_attack_phase(0.061)
	check.call(targets[0].hp == before_hp[0]-damage and targets[1].hp == before_hp[1]-damage, "impact: each target takes the exact unmodified active-frame damage")
	check.call(cam.impact_count == punches+1 and Sfx._next_player == (cursor+1)%Sfx.PLAYER_POOL, "impact: multi-target strike emits exactly one punch and composite impact voice")
	check.call(p._combat_visuals.confirmed and is_equal_approx(p._combat_visuals.contact_hold,0.045), "impact: real contact triggers the standard blade hold")
	check.call(is_equal_approx(p._attack_timer,float(GameState.character_data().attack_cooldown)-0.001), "impact: hit confirmation does not delay or restart the attack cooldown twice")
	p._attack_step = 2
	p._begin_active_phase()
	var pool := Vfx.pool()
	check.call(p.combat_impact_weight() > 1.0 and pool._contacts.any(func(fx: CombatImpact) -> bool: return fx.visible and fx.kind == "finisher"), "impact: existing third thrust selects a heavier contact profile")
	check.call(is_equal_approx(p._combat_visuals.contact_hold,0.065), "impact: finisher has a longer visual-only contact hold")
	for e in targets: e.position += Vector2(20,0)
	punches = cam.impact_count
	p._attack_step = 0
	p._begin_active_phase()
	check.call(not p._combat_visuals.confirmed and p._combat_visuals.contact_hold == 0 and cam.impact_count == punches, "impact: whiffs have no false contact pause or camera punch")
	# Kill accent must not stack the old per-enemy death hit sounds.
	for i in targets.size():
		targets[i].position = p.position+Vector2(1.2+i*0.35,0)
		targets[i].hp = 1
	cursor = Sfx._next_player
	punches = cam.impact_count
	p._begin_active_phase()
	check.call(targets.all(func(e: Enemy) -> bool: return e.dead), "impact: lethal swing still resolves the existing deaths")
	check.call(Sfx._next_player == (cursor+1)%Sfx.PLAYER_POOL and cam.impact_count == punches+1, "impact: multi-kill retains one voice/punch, not one per corpse")
	check.call(pool._contacts.any(func(fx: CombatImpact) -> bool: return fx.visible and fx.kind == "defeat"), "impact: a lethal hit has a distinct pooled defeat accent")
	var fire := DummyEnemy.new()
	fire.kind = "fire"
	fire.max_hp = 10000
	fire.spawn_shimmer = false
	fire.position = p.position+Vector2(1.2,0)
	fixture.add_child(fire)
	_freeze(fire)
	cursor = Sfx._next_player
	p._begin_active_phase()
	check.call(fire.hp < fire.max_hp and Sfx._next_player == cursor, "impact: hitting fire monsters remains deliberately silent")
	# Dialogue keeps idle visuals alive, but no pending combat body pose should carry on.
	body.swing(Vector2.RIGHT)
	cam.punch(Vector2.RIGHT)
	cam.advance_feedback(0.025)
	var hold := game._begin_dialogue_hold(world)
	body.advance(0.01)
	cam._process(0.0)
	check.call(cam.offset == Vector2.ZERO and cam.impact_time == 0, "impact: dialogue hold cannot strand a camera kick")
	check.call(body.stage == "idle" and p._visual.offset == rest, "impact: dialogue ownership clears pending body combat presentation")
	game._end_dialogue_hold(hold)
	# World identity guards reject a retiring source, even while its nodes still exist.
	world.remove_child(fixture)
	game.add_child(fixture)
	punches = cam.impact_count
	Vfx.camera_punch(p,Vector2.RIGHT,1.0)
	check.call(cam.impact_count == punches, "impact: detached/retiring world cannot shake the current camera")
	game.remove_child(fixture)
	world.add_child(fixture)
	for sound in ["blade_swing","blade_hit","blade_finish","blade_armor","blade_defeat"]:
		var stream := Sfx._get_stream(sound)
		var peak := 0
		for i in stream.data.size()/2: peak = maxi(peak,absi(stream.data.decode_s16(i*2)))
		check.call(stream == Sfx._get_stream(sound) and peak > 1000 and peak < 32767 and stream.data.decode_s16(0) == 0 and absi(stream.data.decode_s16(stream.data.size()-2)) < 10, "impact: %s is cached, nonempty, unclipped and click-free at its edges" % sound)
	GameSettings.set_effects_volume(0,false)
	cursor = Sfx._next_player
	Sfx.play("blade_hit")
	check.call(Sfx._next_player == cursor, "impact: zero effects volume suppresses the new impact voices")
	GameSettings.set_effects_volume(100,false)
	Sfx.play("blade_hit")
	var playing := Sfx._players[(Sfx._next_player+Sfx.PLAYER_POOL-1)%Sfx.PLAYER_POOL]
	GameSettings.set_effects_volume(0,false)
	check.call(not playing.playing, "impact: live effects mute stops an already playing impact voice")
	check.call(p.position == position0 and GameState.health() == hp0 and GameState.attack_power() == power0 and Engine.time_scale == engine_scale and game.get_tree().paused == paused0, "impact: impact effects never change actor position, player health/power, time scale or global pause")
	for fx in pool._contacts: fx.advance(2.0)
	fixture.queue_free()
	await game.get_tree().process_frame
	await game.get_tree().process_frame
	if is_instance_valid(world) and world.get("camera") != null: world.camera.make_current()
	for key in ["master_volume","effects_volume","mute_all","reduce_motion","effects_quality","screen_shake"]: GameSettings.set_value(key,settings[key],false)

static func _freeze(n: Node) -> void:
	n.set_process(false)
	n.set_physics_process(false)
	for c in n.get_children(): _freeze(c)
