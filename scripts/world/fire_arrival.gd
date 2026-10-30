class_name FireArrival
extends Node2D
## Pure, sampleable presentation. No enemies, damage, timers, rewards or saves.
var home: Lobby
var points := PackedVector2Array()
var full_intro := false
var elapsed := 0.0
var offsets: Array = []
var resolved: Array = []
var _portals: Array[Sprite2D] = []
var _bodies: Array[Sprite2D] = []
var _rims: Array[Sprite2D] = []
var _roots: Array[Node2D] = []
var _targets := PackedVector2Array()
var _pools: Array[Sprite2D] = []

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for at in points:
		var target := at + Vector2(1, 0)
		var distance := INF
		for tree in home._forest_trees:
			if not is_instance_valid(tree) or not tree.is_attackable(): continue
			var d := at.distance_squared_to(tree.position)
			if d < distance:
				distance = d
				target = tree.position
		_targets.append(target)
		# A local root groups each member's seam, body and foreground rim.
		var root := Node2D.new()
		root.position = home.to_global(at)
		add_child(root)
		_roots.append(root)
		var pool := Sprite2D.new()
		pool.texture = PixelArt.light_texture()
		pool.position = Vector2(0, -0.1)
		pool.scale = Vector2(0.012, 0.005)
		pool.modulate = Color(1.0, 0.46, 0.16, 0.12)
		pool.light_mask = 0
		root.add_child(pool)
		_pools.append(pool)
		var portal := Sprite2D.new()
		portal.position = Vector2(0, -0.76)
		portal.scale = Vector2.ONE * PixelArt.PX
		portal.light_mask = 0
		root.add_child(portal)
		_portals.append(portal)
		var body := Sprite2D.new()
		body.position = Vector2(0, -0.5)
		body.scale = Vector2.ONE * PixelArt.PX
		body.light_mask = 0
		root.add_child(body)
		_bodies.append(body)
		var rim := Sprite2D.new()
		rim.position = portal.position
		rim.scale = portal.scale
		rim.light_mask = 0
		root.add_child(rim)
		_rims.append(rim)
	sample(-1)

func focus() -> Vector2:
	if points.is_empty(): return home.player.global_position
	return home.to_global(points[0] + (_targets[0] - points[0]).limit_length(1.2) * 0.5) + Vector2(0, -0.65)

func sample(time: float) -> void:
	elapsed = time
	var reduced := GameSettings.reduce_motion()
	for i in _roots.size():
		var local_time := time - (float(offsets[i]) if not full_intro and i < offsets.size() else 0.0)
		var t := local_time
		if full_intro and i > 0:
			t = -1.0 # Followers arrive later during play, outside the lead's story.
		elif not full_intro:
			t = 0.8 + local_time * 0.1 if local_time < 6.6 else 1.8 + (local_time - 6.6) / 1.4 * 3.6
		_roots[i].visible = local_time >= 0 and t >= 0.8 and i not in resolved
		var phase := 0
		if t >= 1.8: phase = clampi(1 + int((t - 1.8) / 0.3), 1, 4)
		if t >= 4.2: phase = clampi(5 + int((t - 4.2) / 0.4), 5, 7)
		_portals[i].visible = t < 5.4
		_pools[i].visible = _portals[i].visible and GameSettings.effects_at_least("med")
		_portals[i].texture = FireArt.portal(phase)
		# A second narrow rim in front of the crossing gives the body a threshold.
		_rims[i].visible = t >= 3.0 and t < 4.2
		_rims[i].texture = FireArt.portal(1)
		_rims[i].position.x = 0.18
		var body := _bodies[i]
		body.visible = t >= 3.0
		var pose := "core" if t < 3.35 else ("cross" if t < 4.2 else ("settle" if t < 4.65 else ("notice" if t < 6.6 else "rest")))
		body.texture = FireArt.body(pose)
		body.position = Vector2(0, -0.5)
		body.rotation = 0
		body.flip_h = _targets[i].x < points[i].x
		if t >= 3 and t < 4.2 and not reduced:
			body.position.x = lerpf(-0.08, 0.14, smoothstep(3, 4.2, t))
		if t >= 5.4 and t < 6.6 and not reduced: body.rotation = -0.035 if body.flip_h else 0.035
		# The final pose is exactly Enemy's rest texture, scale and foot position.
		if (time if full_intro else local_time) >= (9.2 if full_intro else 8.0): body.texture = FireArt.body()
	queue_redraw()

func _draw() -> void:
	for i in _roots.size():
		if not _roots[i].visible: continue
		var at := _roots[i].position
		if _bodies[i].visible:
			var shadow := PackedVector2Array()
			for n in 12: shadow.append(at + Vector2(cos(n * TAU / 12) * 0.34, sin(n * TAU / 12) * 0.10))
			draw_colored_polygon(shadow, Color(0.05, 0.04, 0.06, 0.35))
		if GameSettings.effects_at_least("med") and _portals[i].visible:
			for n in 3:
				var drift := 0.0 if GameSettings.reduce_motion() else sin(elapsed * 2 + n + i) * 0.06
				draw_rect(Rect2(at + Vector2((n - 1) * 0.21 + drift, -0.5 - n * 0.27), Vector2.ONE * PixelArt.PX), Color("#df8c43"))
