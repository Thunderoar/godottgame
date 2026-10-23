extends Node
## Fixed-seed, isolated graphical comparison. No FPS claims about Android.
func _ready() -> void:
	if not TestEnvironment.require_isolation(): get_tree().quit(1); return
	var game := load("res://scenes/game.tscn").instantiate() as Game
	add_child(game)
	await get_tree().process_frame
	var start := Time.get_ticks_usec()
	game.call("_on_character_selected", "qayyim")
	var build_ms := float(Time.get_ticks_usec() - start) / 1000.0
	game.hud.tutorial_guide.call("_skip")
	for frame in 60: await get_tree().process_frame
	var intervals: Array[float] = []
	var draw_calls := 0.0
	var physics_ms := 0.0
	var previous := Time.get_ticks_usec()
	for frame in 180:
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		intervals.append(float(now - previous) / 1000.0)
		previous = now
		draw_calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		physics_ms += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	intervals.sort()
	var result := {"build_ms": build_ms, "frame_ms_mean": intervals.reduce(func(a: float, b: float) -> float: return a + b, 0.0) / intervals.size(), "frame_ms_p95": intervals[int(intervals.size() * 0.95)], "draw_calls_mean": draw_calls / intervals.size(), "physics_ms_mean": physics_ms / intervals.size(), "nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT), "texture_bytes": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED), "procedural_cache_entries": PixelArt.CACHE.size(), "renderer": RenderingServer.get_rendering_device() != null}
	print("CREATIVE_BENCHMARK ", JSON.stringify(result))
	game.queue_free()
	await get_tree().process_frame
	get_tree().quit()
