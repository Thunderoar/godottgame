extends RefCounted
class Target extends Enemy:
	func _award_death_rewards() -> void: pass

static func run(game: Game, check: Callable) -> void:
	var old_style := GameSettings._active_visual_style
	var old_motion := GameSettings.reduce_motion()
	var world := game.world
	var fixture := Node2D.new()
	world.add_child(fixture)
	var p := Player.new()
	p.position = Vector2(1200,1200)
	fixture.add_child(p)
	_freeze(p)
	p.controls_locked = false
	p.combat_trace_enabled = true
	for action in ["attack","move_left","move_right","move_up","move_down"]: Input.action_release(action)
	# Source-authored durations are unchanged; only discarded elapsed remainders
	# and numerical-boundary overshoot are corrected.
	for hz in [30,60,120]:
		for step in 3:
			_reset(p)
			p.try_attack()
			p._attack_step = step
			var spec := AttackDB.step("sword",step)
			p._phase_time = float(spec.anticipation)
			var elapsed := 0.0
			while p._attack_phase != Player.AttackPhase.NONE and elapsed < 2.0:
				p._physics_process(1.0/float(hz))
				elapsed += 1.0/float(hz)
			var expected := float(spec.anticipation)+float(spec.active)+float(spec.recovery)
			check.call(elapsed >= expected-0.000001 and elapsed-expected <= 1.0/float(hz)+0.000001,"evolution: step %d at %d Hz preserves authored duration within one tick" % [step,hz])
			check.call(p.combat_trace.filter(func(row: Dictionary) -> bool: return row.event == "active").size() == 1,"evolution: each step has one ACTIVE boundary at %d Hz" % hz)
	_reset(p)
	p.try_attack()
	p._update_attack_phase(0.5)
	check.call(p._attack_phase == Player.AttackPhase.NONE and p._attack_timer == 0,"evolution: 500ms phase delta drains one attack and its cooldown, not just anticipation")
	check.call(p.combat_trace.filter(func(row: Dictionary) -> bool: return row.event == "active").size() == 1,"evolution: large delta cannot duplicate ACTIVE callbacks")
	_reset(p)
	p._attack_timer = 0.06
	var serial := p.attack_serial
	check.call(p.request_attack(Vector2.LEFT) and p.has_queued_attack() and p.attack_serial == serial,"evolution: early request is acknowledged without an illegal immediate attack")
	Input.action_release("attack")
	p._physics_process(0.02)
	p._physics_process(0.02)
	p._physics_process(0.02)
	check.call(p.attack_serial == serial+1 and p._attack_phase == Player.AttackPhase.ANTICIPATION and p._attack_dir == Vector2.LEFT and not p.has_queued_attack(),"evolution: buffered tap executes once on the first legal tick using its intended aim")
	p._physics_process(0.6)
	check.call(p.attack_serial == serial+1,"evolution: releasing or holding an edge does not generate an automatic attack chain")
	_reset(p)
	p._attack_timer = 0.2
	p.request_attack()
	p._physics_process(0.11)
	p._physics_process(0.2)
	check.call(p._attack_phase == Player.AttackPhase.NONE and not p.has_queued_attack(),"evolution: expired requests never fire late after a stall")
	for reason in ["lock","focus","dialogue","touch_cancel","journey"]:
		_reset(p)
		p._attack_timer = 0.06
		p.request_attack()
		match reason:
			"lock": p.controls_locked = true
			"focus": p._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
			"dialogue":
				p._visual.begin_attack(Vector2.RIGHT,0,"sword",0.06)
				var hold := game._begin_dialogue_hold(world)
				check.call(p._visual.attack_stage.is_empty(),"evolution: dialogue clears the committed combat pose while idle presentation stays alive")
				game._end_dialogue_hold(hold)
			"touch_cancel": p.clear_attack_request()
			"journey": p._request_journey -= 1
		check.call(not p.has_queued_attack(),"evolution: %s revokes pending combat intent" % reason)
		p.controls_locked = false
	_reset(p)
	p._attack_timer = 0.08
	p.request_attack(Vector2.LEFT)
	p.request_attack(Vector2.UP)
	p._attack_timer = 0
	p._consume_attack_request()
	check.call(p._attack_dir == Vector2.UP,"evolution: newer distinct intent replaces the single pending slot")
	_reset(p)
	serial = p.attack_serial
	p.submit_attack_input()
	p.submit_attack_input()
	check.call(p.attack_serial == serial+1 and not p.has_queued_attack(),"evolution: event and synthetic edge cannot double-queue one press")
	# The actual existing touch control must both submit and revoke, not rely on
	# action_press magically invoking a keyboard event callback.
	var real_player := game.player()
	real_player.clear_attack_request()
	var button := game.hud._attack_button
	var was_visible := button.visible
	button.show()
	real_player._input_edge_seen = false
	var was_locked := real_player.controls_locked
	real_player.controls_locked = false
	real_player._attack_timer = 0.08
	button._press()
	check.call(real_player.has_queued_attack(),"evolution: actual touch button submits a buffered attack through the shared owner")
	button._release()
	check.call(real_player.has_queued_attack(),"evolution: normal touch release preserves an already acknowledged tap")
	button.cancel()
	check.call(not real_player.has_queued_attack() and not Input.is_action_pressed("attack"),"evolution: touch cancellation revokes intent and releases InputMap")
	button.visible = was_visible
	real_player.controls_locked = was_locked
	real_player._attack_timer = 0
	# Every pose key genuinely selects a different sprite image in both art modes;
	# idle/walk requests cannot replace committed attack facing or frame selection.
	for style in ["pixel","illustrated"]:
		GameSettings._active_visual_style = style
		for dir in [0,1,2]:
			for step in 3:
				var images: Array[Texture2D] = []
				for key in 4:
					var tex := CombatPoseArt.texture("adam",dir,step,key)
					images.append(tex)
					check.call(tex.get_size() == Vector2(32,48) and tex.get_meta("combat_pose") == Vector3i(dir,step,key),"evolution: %s pose %d/%d/%d preserves actor dimensions and frame identity" % [style,dir,step,key])
				check.call(images[0] != images[1] and images[1] != images[2] and images[2] != images[3],"evolution: %s step %d facing %d has four cached distinct pose keys" % [style,step,dir])
	GameSettings._active_visual_style = old_style
	p._visual.begin_attack(Vector2.RIGHT,0,"sword",0.06)
	p._visual.strike_attack(Vector2.RIGHT,0,"sword")
	var attack_texture := p._visual.texture
	p._visual.set_facing(3,true)
	p._visual.set_motion(Vector2.LEFT,4.0)
	check.call(p._visual.texture == attack_texture and not p._visual.flip_h,"evolution: moving the other way cannot erase committed sword facing")
	p._visual.confirm_attack(0.045)
	p._visual.advance_attack(0.02)
	check.call(p._visual.attack_key == 1 and p._visual.attack_age == 0,"evolution: complete contact pose holds, not just the body's position offset")
	p._visual.advance_attack(0.2)
	check.call(p._visual.attack_key == 2,"evolution: overshoot follows the held contact key")
	p._visual.end_attack()
	check.call(p._visual.attack_stage.is_empty(),"evolution: recovery releases the attack-pose owner")
	p._visual.begin_attack(Vector2.RIGHT,0,"sword",0.06)
	p._visual.play_pose(PlayerSprite.Pose.HURT,0.2)
	check.call(p._visual.attack_stage.is_empty() and p._visual.pose == PlayerSprite.Pose.HURT,"evolution: hurt has priority over attack animation")
	p._visual.play_pose(PlayerSprite.Pose.IDLE)
	# Resolve actual accepted/rejected/lethal hits and verify all consumers agree.
	var target := Target.new()
	target.kind = "urchin"
	target.max_hp = 1000
	target.spawn_shimmer = false
	target.position = p.position+Vector2(1.4,0)
	fixture.add_child(target)
	_freeze(target)
	var before := target.hp
	var result := CombatHit.apply(target,13,Vector2.RIGHT,p)
	check.call(result.accepted and result.damage_applied == 13 and result.hp_before == before and result.hp_after == before-13 and result.world == world and result.material == "stone","evolution: accepted contact returns actual damage, material and world identity")
	check.call(result.position.x < target.global_position.x and result.position.distance_to(target.global_position) < 2,"evolution: side impact is anchored to a clamped visible surface, not the target center")
	var pool := Vfx.pool(world)
	check.call(pool._contacts.any(func(fx: CombatImpact) -> bool: return fx.visible and fx.global_position.is_equal_approx(result.position)),"evolution: pooled contact uses the same resolved anchor")
	var children := fixture.get_child_count()
	var arrow := Arrow.new()
	arrow.position = target.position-Vector2(0.5,0)
	arrow.direction = Vector2.RIGHT
	arrow.source = p
	arrow.damage = 5
	fixture.add_child(arrow)
	arrow.set_physics_process(false)
	arrow._physics_process(0.03)
	check.call(target.hp == before-18 and arrow.is_queued_for_deletion() and fixture.get_child_count() == children+1,"evolution: swept arrow hit uses one accepted result and allocates no extra impact sprite")
	for fx in pool._contacts: fx.advance(1.0)
	for i in VfxPool.CONTACT_COUNT: pool.contact(Vector2.ZERO,Vector2.RIGHT,Color.WHITE,"normal")
	var identities := pool._contacts.map(func(fx: CombatImpact) -> int: return fx.serial)
	pool.contact(Vector2.ZERO,Vector2.RIGHT,Color.WHITE,"material_stone")
	check.call(pool._contacts.map(func(fx: CombatImpact) -> int: return fx.serial) == identities,"evolution: saturated decoration cannot steal essential contact slots")
	for fx in pool._contacts: fx.advance(1.0)
	var hold := game._begin_dialogue_hold(world)
	before = target.hp
	var denied := CombatHit.apply(target,13,Vector2.RIGHT,p)
	check.call(not denied.accepted and target.hp == before,"evolution: protected targets yield a rejected result without success feedback")
	game._end_dialogue_hold(hold)
	for sound in ["blade_hit","blade_finish","blade_armor","blade_defeat","blade_stone"]:
		var first := Sfx._get_stream(sound)
		var alternate := Sfx._get_stream(sound+"_v1")
		check.call(first != alternate and first.data != alternate.data and first.data.size() == alternate.data.size(),"evolution: %s has two finite prewarmed material variants" % sound)
	world.remove_child(fixture)
	game.add_child(fixture)
	var stale := CombatHit.apply(target,13,Vector2.RIGHT,p)
	check.call(not stale.accepted and CombatHit.world_of(target) == null,"evolution: a retiring world cannot apply another accepted contact")
	game.remove_child(fixture)
	world.add_child(fixture)
	fixture.queue_free()
	await game.get_tree().process_frame
	await game.get_tree().process_frame
	GameSettings.set_reduce_motion(old_motion,false)
	GameSettings._active_visual_style = old_style

static func _reset(p: Player) -> void:
	p.clear_attack_request()
	p._input_edge_seen = false
	p._attack_phase = Player.AttackPhase.NONE
	p._attack_timer = 0
	p._idle_clock = 0
	p._combo_expire = -1
	p._attack_step = 0
	p.facing = Vector2.RIGHT
	p.attacking = false
	p.combat_trace.clear()
	p._visual.end_attack()

static func _freeze(node: Node) -> void:
	node.set_process(false)
	node.set_physics_process(false)
	for child in node.get_children(): _freeze(child)
