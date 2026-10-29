class_name TwilightLandscape
extends RefCounted
## Deterministic realm terrain; decorative randomness never touches Lobby RNG.

static func terrain(restored: bool) -> Texture2D:
	return PixelArt.cached_texture("twilight_terrain_v1_%s" % restored, func() -> Image:
		var img := PixelArt.image(864, 864)
		img.fill(Color("#334d49") if restored else Color("#303a49"))
		var rng := RandomNumberGenerator.new()
		rng.seed = 86037
		for i in 16000:
			var at := Vector2i(rng.randi_range(1, 860), rng.randi_range(1, 860))
			img.fill_rect(Rect2i(at, Vector2i(2, 1)), Color("#3d5652") if restored else Color("#3d4657"))
		# Deep forest beds surround, rather than obstruct, the readable paths.
		for i in 60:
			var p := Vector2(rng.randf_range(4, 68), rng.randf_range(4, 68))
			if RealmDB.path_distance(p) > 5:
				PixelArt.ellipse(img, int(p.x * 12), int(p.y * 12), 36, 24, Color("#293e3e") if restored else Color("#292f43"))
		for edge in [true, false]:
			for path in RealmDB.PATHS:
				for j in range(1, path.size()):
					var a: Vector2 = path[j - 1] * 12
					var b: Vector2 = path[j] * 12
					var steps := maxi(1, ceili(a.distance_to(b) / 10))
					for i in steps + 1:
						var p := a.lerp(b, float(i) / steps)
						PixelArt.ellipse(img, int(p.x), int(p.y), 35 if edge else 27, 30 if edge else 23, Color("#55565e") if edge else Color("#787077"))
		# A shallow runnel crosses under the old stone footbridge.
		for x in range(36, 820):
			var y := 596 + int(sin(float(x) / 95) * 13)
			img.fill_rect(Rect2i(x, y, 1, 18), Color("#233d58"))
			img.fill_rect(Rect2i(x, y + 3, 1, 3), Color("#729eae"))
		img.fill_rect(Rect2i(485, 566, 64, 62), Color("#a39788"))
		for i in 5: img.fill_rect(Rect2i(488, 569 + i * 12, 58, 2), Color("#6d666f"))
		PixelArt.ellipse(img, 59 * 12, 27 * 12, 28, 21, Color("#223c61"))
		PixelArt.ellipse_outline(img, 59 * 12, 27 * 12, 29, 22, Color("#92b8c2"))
		# Citadel apron and quiet preparation platform.
		img.fill_rect(Rect2i(27 * 12, 3 * 12, 18 * 12, 14 * 12), Color("#4a4258"))
		for y in range(42, 200, 12):
			for x in range(330, 538, 24):
				img.fill_rect(Rect2i(x + ((y / 12) % 2) * 8, y, 21, 9), Color("#65596b"))
		PixelArt.ellipse_outline(img, 36 * 12, 10 * 12, 56, 38, Color("#bd8eaa") if restored else Color("#cf718e"))
		return img)

static func decorate(world: Node2D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 340912
	for i in 190:
		var p := Vector2(rng.randf_range(3, 69), rng.randf_range(5, 69))
		if RealmDB.path_distance(p) < 4.4 or p.distance_to(RealmDB.BOSS) < 11: continue
		var tree := Sprite2D.new()
		tree.texture = PixelArt.authored_tree_texture()
		tree.position = p + Vector2(0, -1.9)
		tree.scale = Vector2.ONE * PixelArt.PX * rng.randf_range(0.65, 0.9)
		tree.modulate = Color("#9da4cc") if i % 3 else Color("#c4a2c7")
		tree.texture_filter = VisualStyle.texture_filter()
		world.add_child(tree)
		var body := StaticBody2D.new()
		body.position = p
		body.collision_layer = 1
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 0.38
		shape.shape = circle
		body.add_child(shape)
		world.add_child(body)
	# Stone fragments, animal tracks and pool lights reward looking closely.
	for path in RealmDB.PATHS:
		for j in range(1, path.size()):
			var a: Vector2 = path[j - 1]
			var b: Vector2 = path[j]
			for k in range(0, int(a.distance_to(b)), 2):
				var stone := Polygon2D.new()
				stone.polygon = PackedVector2Array([Vector2(-0.32,-0.13),Vector2(0.25,-0.16),Vector2(0.35,0.12),Vector2(-0.2,0.18)])
				stone.position = a.move_toward(b, float(k)) + Vector2(0.45 if k % 4 else -0.45, 0)
				stone.color = Color("#9a8b91")
				stone.z_index = -1
				world.add_child(stone)
