extends RefCounted
## Presentation-only regression suite. Called inside the isolated canonical gate.
static func run(game: Game, check: Callable) -> void:
	var settings := GameSettings._values.duplicate(true)
	var pool := Vfx.pool()
	check.call(pool != null and pool._contacts.size() == VfxPool.CONTACT_COUNT, "combat visuals: world preallocates bounded contact pool")
	var player := game.player()
	var fx := player.get_node("Slash") as CombatVisuals
	check.call(fx != null, "combat visuals: legacy Slash node owns the new ribbon renderer")
	var position_before := player.position
	var hp_before := GameState.health()
	var power := GameState.attack_power()
	var contact_children := pool.get_child_count()
	for quality in ["low","med","high"]:
		GameSettings.set_effects_quality(quality,false)
		for reduced in [false,true]:
			GameSettings.set_reduce_motion(reduced,false)
			for style in ["sword","scythe","bow","hammer"]:
				for dir in [Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT,Vector2.UP]:
					fx.anticipate(dir,style,"lr",0.06,2.05)
					fx.advance(0.03)
					check.call(fx.visible and fx.stage == "anticipation" and fx.direction == dir, "combat visuals: %s/%s reduced=%s aim=%s has anticipation" % [style,quality,reduced,dir])
					for arc in ["lr","rl","thrust","slam","shot"]:
						fx.strike(dir,style,arc,2.05)
						fx.advance(0.035)
						fx.queue_redraw()
						fx.advance(0.5)
						check.call(not fx.visible and fx.stage == "idle", "combat visuals: %s/%s reduced=%s %s clears %s" % [style,quality,reduced,dir,arc])
	for i in range(VfxPool.CONTACT_COUNT*4+3):
		pool.contact(player.global_position,Vector2.LEFT,Color.CYAN,"critical" if i%2 == 0 else "armor")
	check.call(pool.get_child_count() == contact_children, "combat visuals: saturated pool never allocates per-hit nodes")
	check.call(pool._contacts.all(func(n: CombatImpact) -> bool: return n.visible and n.age == 0 and n.direction == Vector2.LEFT), "combat visuals: reused slots reset age, visibility and direction")
	var next := pool._contacts[pool._contact_cursor]
	pool.contact(player.global_position,Vector2.ZERO,Color.RED,"hurt")
	check.call(next.kind == "hurt" and next.tint == Color.RED and next.direction == Vector2.RIGHT and is_equal_approx(next.duration,0.2), "combat visuals: reuse resets variant, tint, duration and zero direction")
	next.advance(1.0)
	check.call(not next.visible and not next.is_processing(), "combat visuals: contact releases its process callback after expiry")
	for reduced in [false,true]:
		GameSettings.set_reduce_motion(reduced,false)
		for quality in ["low","med","high"]:
			GameSettings.set_effects_quality(quality,false)
			for variant in ["normal","critical","armor","hurt"]:
				next.play(player.global_position,Vector2.RIGHT,Color.GOLD,variant)
				next.advance(0.04)
				next.queue_redraw()
				check.call(next.visible, "combat visuals: %s reduced=%s %s retains contact cue" % [variant,reduced,quality])
				next.advance(1.0)
	# Two rapid flashes must not let the old tween erase the newer hit.
	var item := Sprite2D.new()
	game.world.add_child(item)
	HitFeedback.flash_white(item)
	var first: Tween = item.get_meta("hit_flash_tween")
	HitFeedback.flash_white(item)
	check.call(not first.is_valid() and item.get_meta("hit_flash_tween") != first, "combat visuals: rapid flashes kill the superseded tween")
	item.queue_free()
	fx.anticipate(Vector2.ZERO,"sword","lr",0,2)
	check.call(fx.direction == Vector2.RIGHT, "combat visuals: zero aim has a safe visual fallback")
	fx.cancel()
	check.call(not fx.visible and fx.stage == "idle", "combat visuals: cancellation clears held wind-up")
	check.call(player.position == position_before and GameState.health() == hp_before and GameState.attack_power() == power, "combat visuals: rendering never changes position, health or damage")
	for n in pool._contacts: n.advance(1.0)
	GameSettings._values = settings
	GameSettings.changed.emit("reduce_motion")
	GameSettings.changed.emit("effects_quality")
