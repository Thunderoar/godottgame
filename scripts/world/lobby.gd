class_name Lobby
extends Node2D
## Seaside home hub. Environment art is composed from the original Cainos
## atlas, while the cottage, stalls and portal frames come from PixelArt.

const MAP_RECT := Rect2(0, 0, 64, 40)
const SPAWN := Vector2(34.0, 24.3)
const HOUSE_BASE := Vector2(34.0, 21.4)
const MONSTER_GATE := Vector2(30.8, 11.3)
const PET_GATE := Vector2(37.2, 11.3)
const CONSTRUCTION_SHOP := Vector2(41.2, 16.2)

var zone_name := "Seaside Home"
var player: Player
var pet: Pet
var camera: FollowCamera
var background: Sprite2D
var house_sprite: Sprite2D
var house_glow: PointLight2D
var _house_origin := Vector2.ZERO
var _house_position := HOUSE_BASE
var _player_spawn := SPAWN
var _recovery_center := RECOVERY_CENTER
var _markers: Array[Dictionary] = []
var _decor_root: Node2D
var _rng := RandomNumberGenerator.new()
var _recovery_ward: RecoveryWard
var _settlement_editor: SettlementEditor
var _placeables: Array[SettlementPlaceable] = []
var _recovery_heal_accum := 0.0
var _rubbish_system: RubbishSystem
var _coastal_guard: CoastalGuard
var _residents: Array[Resident] = []
var _emergency_monsters: Array[Enemy] = []
var _forest_monsters: Array[Enemy] = []
var _shop_stalls: Array[Sprite2D] = []
var _tree_positions: Array[Vector2] = []
var _forest_trees: Array[ForestTree] = []
var _house_positions: Array[Vector2] = []
var _ruin_positions: Array[Vector2] = []
var _tree_serial := 0
var _emergency_fire: Sprite2D
var _emergency_wall_toast := 0.0

const RECOVERY_CENTER := Vector2(34.0, 23.7)
const RECOVERY_RADIUS := 4.3


func _ready() -> void:
	add_to_group("world")
	y_sort_enabled = true
	_rng.seed = 7319
	_build_background()
	_build_bounds()
	_build_house()
	_build_shops()
	_build_special_npc()
	_build_residential_life()
	_build_portals()
	_build_gathering()
	_build_dock_and_ship()
	_build_beached_turtle()
	_build_forest()
	_build_forest_monsters()
	_build_scatter()
	_build_coastal_system()
	_build_ambient_life()
	_build_recovery_ward()
	_build_settlement_editor()
	_build_player_and_pet()
	_build_camera()
	call_deferred("_check_forest_game_over")
	Vfx.ensure_pool(self)
	Shaders.apply_default_breeze()
	GameState.house_changed.connect(_on_house_upgraded)
	GameState.data_changed.connect(_on_data_changed)
	GameState.pet_changed.connect(_on_pet_changed)
	GameState.emergency_changed.connect(_on_emergency_changed)
	if GameState.recovery_active():
		_recovery_ward.set_active(true)
	if GameState.emergency_active():
		_apply_emergency_damage(GameState.emergency_damage())
		call_deferred("_spawn_emergency_monsters", GameState.emergency_monsters())
	if not bool(GameState.data.get("tutorial_seen", false)):
		GameState.data.tutorial_seen = true
		GameState.save_game()
		GameState.toast_requested.emit("Your cottage is waiting. Shops cluster inside the fence; the grotto lies north.", "info")


# ------------------------------------------------------------------ terrain art

func _build_background() -> void:
	background = Sprite2D.new()
	background.name = "Terrain"
	background.texture = _make_terrain_texture()
	background.centered = false
	background.scale = Vector2(PixelArt.PX, PixelArt.PX)
	background.z_as_relative = false
	background.z_index = -1000
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Daylight grade. The old neon look was actually the PointLight2Ds being
	# ~13x oversized (one 128px light covered the entire map); with correctly
	# sized lights the baked terrain needs only a gentle sunny lift.
	background.modulate = Color(1.0, 1.0, 0.97)
	add_child(background)
	var grade := CanvasModulate.new()
	grade.name = "DaylightGrade"
	grade.color = Color(1.04, 1.08, 1.0)
	add_child(grade)
	_build_water_layer()


func _make_terrain_texture() -> Texture2D:
	var key := "terrain_lobby_v3"
	if PixelArt.CACHE.has(key):
		return PixelArt.CACHE[key]
	var w := int(MAP_RECT.size.x * 32.0)
	var h := int(MAP_RECT.size.y * 32.0)
	var img := PixelArt.image(w, h)
	var grass_tex := load("res://assets/textures/TX Tileset Grass.png") as Texture2D
	var src := grass_tex.get_image()
	var tile_origins := [
		Vector2i(0, 0), Vector2i(32, 0), Vector2i(64, 0),
		Vector2i(0, 32), Vector2i(32, 32), Vector2i(64, 32),
		Vector2i(0, 64), Vector2i(32, 64), Vector2i(64, 64),
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 4771
	for gy in int(MAP_RECT.size.y):
		for gx in int(MAP_RECT.size.x):
			var tile: Vector2i = tile_origins[rng.randi_range(0, tile_origins.size() - 1)]
			img.blit_rect(src, Rect2i(tile, Vector2i(32, 32)), Vector2i(gx * 32, gy * 32))
	# Broad moss / sun-bleached patches.
	for i in 34:
		var c := Vector2(rng.randf_range(0, w), rng.randf_range(0, h))
		var col := Color("#5e7040") if i % 2 == 0 else Color("#7e8a4e")
		_blend_ellipse(img, int(c.x), int(c.y), rng.randi_range(40, 135), rng.randi_range(26, 80), col, 0.09)
	# Path network.
	_paint_path(img, [Vector2(34, 24), Vector2(30, 23.2), Vector2(27, 22.6), Vector2(23.8, 22.2)], 0.72)
	_paint_path(img, [Vector2(33.2, 23.5), Vector2(31.5, 20.5), Vector2(29.5, 16.5), Vector2(27, 12.2), Vector2(24, 10.2)], 0.62)
	_paint_path(img, [Vector2(34, 24), Vector2(29, 25.8), Vector2(23, 28), Vector2(17, 30.2), Vector2(11, 31.8)], 0.62)
	_paint_path(img, [Vector2(23.8, 22.2), Vector2(21.5, 20.8), Vector2(21.3, 20.5)], 0.52)
	_paint_path(img, [Vector2(23.8, 22.2), Vector2(25.5, 19.7), Vector2(26.8, 18.8)], 0.52)
	# House clearing.
	_blend_ellipse(img, 34 * 32, 23 * 32, 150, 105, Color("#bcaa7c"), 0.11)
	_paint_path(img, [Vector2(39.4, 22.0), Vector2(42.8, 15.8), Vector2(43.4, 10.7)], 0.4)
	# Coast and sea.
	_paint_coast(img, rng)
	# A few stone patches around the house.
	for p in [Vector2(31.5, 22.5), Vector2(37, 23.4), Vector2(33.2, 25.4)]:
		_blend_ellipse(img, int(p.x * 32), int(p.y * 32), 26, 15, Color("#a69f82"), 0.25)
	# Grass fringe and tiny flowers.
	for i in 460:
		var x := rng.randi_range(2, w - 3)
		var y := rng.randi_range(2, h - 3)
		var shore := _coast_pixel_y(x)
		if y > shore - 7:
			continue
		var color := Color("#5f7940") if i % 5 != 0 else Color("#d8c268")
		img.set_pixel(x, y, color)
		if i % 7 == 0:
			img.set_pixel(x + 1, y, color.lightened(0.1))
	var tex := ImageTexture.create_from_image(img)
	PixelArt.CACHE[key] = tex
	return tex


func _coast_pixel_y(x: int) -> int:
	var u := clampf(float(x) / (25.0 * 32.0), 0.0, 1.0)
	var world_y := lerpf(21.0, 37.0, smoothstep(0.0, 1.0, u)) + sin(float(x) / 31.0) * 0.55
	return int(world_y * 32.0)


func _paint_coast(img: Image, rng: RandomNumberGenerator) -> void:
	var water_near := Color("#6ea8a5")
	var water_far := Color("#3c7a86")
	var sand := Color("#d8c49a")
	var sand_dark := Color("#bea77c")
	var foam := Color("#dbe8df")
	var max_x := int(25.2 * 32.0)
	for x in range(0, max_x, 2):
		var shore := _coast_pixel_y(x)
		if shore >= img.get_height():
			continue
		var sand_top := maxi(0, shore - 94)
		img.fill_rect(Rect2i(x, sand_top, 2, shore - sand_top), sand)
		img.fill_rect(Rect2i(x, shore, 2, img.get_height() - shore), water_near)
		# A second darker water band further out.
		var deep_start := mini(img.get_height() - 1, shore + 96)
		img.fill_rect(Rect2i(x, deep_start, 2, img.get_height() - deep_start), water_far)
		# Wet sand line.
		img.fill_rect(Rect2i(x, shore - 4, 2, 4), sand_dark)
		# Dithered grass-to-sand transition band above the wet line.
		for band in 7:
			var by := shore - 5 - band
			if by < 0:
				continue
			if (x + band * 3) % (band + 2) != 0:
				img.set_pixel(x, by, Color("#8f9a58").darkened(0.05 * float(band)))
		# Ragged foam.
		if (x / 2) % 7 != 0:
			img.set_pixel(x, shore, foam)
			if x % 6 == 0:
				img.set_pixel(x, shore + 1, foam)
	# Pebbles on the sand.
	for i in 180:
		var x := rng.randi_range(0, max_x)
		var shore := _coast_pixel_y(x)
		var top := maxi(0, shore - 90)
		var y := rng.randi_range(top, maxi(top + 1, shore - 5))
		img.set_pixel(x, y, sand_dark if i % 2 == 0 else Color("#e7d7b1"))
	# Wave highlights.
	for i in 260:
		var x := rng.randi_range(0, max_x)
		var shore := _coast_pixel_y(x)
		if shore >= img.get_height() - 8:
			continue
		var y := rng.randi_range(shore + 12, img.get_height() - 2)
		var length := rng.randi_range(2, 9)
		var col := Color("#b1d3c8") if i % 3 else Color("#8ec0b8")
		for xx in length:
			if x + xx < img.get_width():
				img.set_pixel(x + xx, y, col)
	# Reeds at the water edge.
	for i in 38:
		var x := rng.randi_range(0, max_x)
		var shore := _coast_pixel_y(x)
		if shore <= 30 or shore >= img.get_height() - 5:
			continue
		var height := rng.randi_range(6, 17)
		var col := Color("#587b4e") if i % 2 == 0 else Color("#78935e")
		for yy in height:
			img.set_pixel(x, shore - 4 - yy, col)
		img.set_pixel(x - 1, shore - 10, col.darkened(0.15))


func _paint_path(img: Image, points: Array, width_units: float) -> void:
	var px_points: Array[Vector2] = []
	for p in points:
		px_points.append(Vector2(p.x * 32.0, p.y * 32.0))
	var width_px := width_units * 32.0
	var base := Color("#b39b70")
	var edge := Color("#8c7a57")
	var light := Color("#cbb486")
	for i in px_points.size() - 1:
		var a := px_points[i]
		var b := px_points[i + 1]
		var bounds := Rect2(a, Vector2.ZERO).expand(b).grow(int(width_px) + 4)
		for y in range(int(bounds.position.y), int(bounds.position.y + bounds.size.y)):
			if y < 0 or y >= img.get_height():
				continue
			for x in range(int(bounds.position.x), int(bounds.position.x + bounds.size.x)):
				if x < 0 or x >= img.get_width():
					continue
				var p := Vector2(x, y)
				var d := _distance_to_segment(p, a, b)
				var edge_noise := sin(float(x) * 0.31 + float(y) * 0.12) * 2.5
				if d <= width_px * 0.5 + edge_noise:
					img.set_pixel(x, y, base)
					if d > width_px * 0.5 - 4:
						img.set_pixel(x, y, edge)
					elif (x * 7 + y * 13) % 29 == 0:
						img.set_pixel(x, y, light)


static func _distance_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(0.001, ab.length_squared()), 0.0, 1.0)
	return p.distance_to(a + ab * t)


func _blend_ellipse(img: Image, cx: int, cy: int, rx: int, ry: int, color: Color, alpha: float) -> void:
	for y in range(-ry, ry + 1):
		var span := int(round(float(rx) * sqrt(maxf(0.0, 1.0 - pow(float(y) / float(maxi(1, ry)), 2.0)))))
		for x in range(-span, span + 1):
			var px := cx + x
			var py := cy + y
			if px < 0 or py < 0 or px >= img.get_width() or py >= img.get_height():
				continue
			var existing := img.get_pixel(px, py)
			img.set_pixel(px, py, existing.lerp(color, alpha))


func _build_water_layer() -> void:
	# Animated sea on top of the baked terrain: a half-resolution water mask
	# drives the shape; the shared water shader supplies the moving bands, foam
	# crests and sparkle. Bobbing props keep their own sprites above this.
	if not GameSettings.effects_at_least("med") or GameSettings.reduce_motion():
		return
	var mask := _make_water_mask_texture()
	var water := Sprite2D.new()
	water.name = "WaterLayer"
	water.texture = mask
	water.centered = false
	water.scale = Vector2(PixelArt.PX * 2.0, PixelArt.PX * 2.0)
	water.z_as_relative = false
	water.z_index = -999
	water.material = Shaders.water_material()
	add_child(water)


func _make_water_mask_texture() -> Texture2D:
	var key := "water_mask_lobby_v2"
	if PixelArt.CACHE.has(key):
		return PixelArt.CACHE[key]
	var w := 1024
	var h := 640
	var img := PixelArt.image(w, h)
	img.fill(Color(0, 0, 0, 0))
	# Terrain coast art only paints sea through x=25.2 world units. Keep the
	# rest of this full-map mask transparent so the shader never covers land.
	var water_width := mini(w, int(25.2 * 16.0))
	for x in water_width:
		var shore := _coast_pixel_y(x * 2) / 2.0
		for y in h:
			if float(y) < shore:
				continue
			var depth := clampf((float(y) - shore) / 90.0, 0.0, 1.0)
			var a := 0.55 + depth * 0.45
			if float(y) - shore < 3.0:
				a = 0.75
			img.set_pixel(x, y, Color(1, 1, 1, a))
	var tex := ImageTexture.create_from_image(img)
	PixelArt.CACHE[key] = tex
	return tex


func _update_ambient(delta: float) -> void:
	# Wind benders (player + pet) for the grass shader, falling forest leaves
	# and recovery-ward motes. All gated above by quality + reduce-motion.
	_wind_push_timer -= delta
	if _wind_push_timer <= 0.0:
		_wind_push_timer = 0.12
		var benders: Array = []
		if is_instance_valid(player):
			benders.append(player.global_position)
		if is_instance_valid(pet):
			benders.append(pet.global_position)
		Shaders.push_benders(benders)
	_leaf_timer -= delta
	if _leaf_timer <= 0.0:
		_leaf_timer = randf_range(0.8, 1.9)
		if not _forest_trees.is_empty():
			var tree: ForestTree = _forest_trees[randi() % _forest_trees.size()]
			if is_instance_valid(tree) and tree.is_alive():
				Vfx.leaves(tree.global_position + Vector2(randf_range(-0.4, 0.4), -randf_range(1.6, 2.6)), 2)
	_ward_mote_timer -= delta
	if _ward_mote_timer <= 0.0 and GameState.recovery_active():
		_ward_mote_timer = 0.7
		Vfx.pop(RECOVERY_CENTER + Vector2(randf_range(-1.6, 1.6), -randf_range(0.4, 2.2)), "heart", Color(0.7, 1.0, 0.85, 0.8))


func _build_ambient_life() -> void:
	# Cloud shadows, pollen, butterflies, forest light shafts, the eastern
	# danger grade and chimney smoke. Everything is a handful of sprites and
	# one capped CPU particle emitter; low quality drops the whole layer.
	if not GameSettings.effects_at_least("med") or GameSettings.reduce_motion():
		return
	var holder := Node2D.new()
	holder.name = "AmbientLife"
	add_child(holder)
	# Drifting cloud shadows over the meadow.
	for i in 3:
		var cloud := Sprite2D.new()
		cloud.texture = PixelArt.light_texture()
		cloud.modulate = Color(0.16, 0.22, 0.26, 0.10)
		cloud.scale = Vector2(0.55 + float(i) * 0.2, 0.3)
		cloud.z_as_relative = false
		cloud.z_index = 1
		cloud.position = Vector2(randf_range(4.0, 50.0), randf_range(8.0, 30.0))
		holder.add_child(cloud)
		var drift := cloud.create_tween().set_loops()
		drift.tween_property(cloud, "position:x", cloud.position.x + randf_range(14.0, 22.0), randf_range(30.0, 46.0)).set_trans(Tween.TRANS_SINE)
		drift.tween_property(cloud, "position:x", cloud.position.x, randf_range(30.0, 46.0)).set_trans(Tween.TRANS_SINE)
	# Pollen motes over the meadow.
	var pollen := CPUParticles2D.new()
	pollen.amount = 12
	pollen.lifetime = 5.0
	pollen.preprocess = 2.5
	pollen.texture = PixelArt.light_texture()
	pollen.scale_amount_min = 0.18
	pollen.scale_amount_max = 0.35
	pollen.color = Color(1.0, 0.95, 0.75, 0.28)
	pollen.direction = Vector2(0.4, -0.2)
	pollen.spread = 180.0
	pollen.gravity = Vector2.ZERO
	pollen.initial_velocity_min = 0.4
	pollen.initial_velocity_max = 1.2
	pollen.position = Vector2(32.0, 22.0)
	pollen.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	pollen.emission_rect_extents = Vector2(26.0, 16.0)
	pollen.z_as_relative = false
	pollen.z_index = 680
	holder.add_child(pollen)
	# Butterflies fluttering near the flower borders.
	for i in 3:
		var butterfly := Sprite2D.new()
		butterfly.texture = PixelArt.cached_texture("ambient_butterfly_16", func() -> Image:
			var img := PixelArt.image(16, 12)
			PixelArt.ellipse(img, 4, 4, 3, 3, Color("#f2d68c"))
			PixelArt.ellipse(img, 11, 4, 3, 3, Color("#a9dfe0"))
			PixelArt.ellipse(img, 4, 8, 2, 2, Color("#e8b2cb"))
			PixelArt.ellipse(img, 11, 8, 2, 2, Color("#f0e2a5"))
			PixelArt.line(img, 7, 3, 8, 9, Color("#43534a"))
			return img)
		butterfly.scale = Vector2(0.022, 0.022)
		butterfly.modulate = [Color("#ffd47b"), Color("#a8e8ff"), Color("#ffb0c8")][i]
		butterfly.z_index = 8
		butterfly.position = Vector2(randf_range(18.0, 44.0), randf_range(16.0, 30.0))
		holder.add_child(butterfly)
		var flutter := butterfly.create_tween().set_loops()
		for j in 4:
			var to := butterfly.position + Vector2(randf_range(-2.5, 2.5), randf_range(-1.4, 1.4))
			flutter.tween_property(butterfly, "position", to, randf_range(1.4, 2.4)).set_trans(Tween.TRANS_SINE)
	# Light shafts through the eastern canopy.
	for i in 2:
		var shaft := Sprite2D.new()
		shaft.texture = PixelArt.light_texture()
		shaft.modulate = Color(1.0, 0.95, 0.7, 0.09)
		shaft.scale = Vector2(0.30, 0.85)
		shaft.rotation = 0.5
		shaft.z_as_relative = false
		shaft.z_index = 2
		shaft.position = Vector2(51.0 + float(i) * 4.5, 16.0 + float(i) * 6.0)
		holder.add_child(shaft)
		var breathe := shaft.create_tween().set_loops()
		breathe.tween_property(shaft, "modulate:a", 0.13, 2.2).set_trans(Tween.TRANS_SINE)
		breathe.tween_property(shaft, "modulate:a", 0.08, 2.2).set_trans(Tween.TRANS_SINE)
	# Eastern danger grade: the woodland reads darker toward the horizon.
	var grade := Sprite2D.new()
	grade.texture = PixelArt.light_texture()
	grade.modulate = Color(0.08, 0.12, 0.18, 0.16)
	grade.scale = Vector2(1.1, 1.0)
	grade.z_as_relative = false
	grade.z_index = 2
	grade.position = Vector2(56.5, 20.0)
	holder.add_child(grade)
	# Chimney smoke once the cottage has one (level 3+).
	if GameState.house_level() >= 3:
		var smoke := CPUParticles2D.new()
		smoke.amount = 8
		smoke.lifetime = 3.2
		smoke.preprocess = 1.5
		smoke.texture = PixelArt.light_texture()
		smoke.scale_amount_min = 0.10
		smoke.scale_amount_max = 0.22
		smoke.color = Color(0.75, 0.8, 0.8, 0.16)
		smoke.direction = Vector2(0.15, -1)
		smoke.spread = 12.0
		smoke.gravity = Vector2.ZERO
		smoke.initial_velocity_min = 0.3
		smoke.initial_velocity_max = 0.7
		smoke.position = _house_position + Vector2(2.3, -3.6)
		holder.add_child(smoke)


# ------------------------------------------------------------------ physical bounds

func _build_bounds() -> void:
	var walls := StaticBody2D.new()
	walls.name = "WorldBounds"
	walls.collision_layer = 1
	walls.collision_mask = 0
	add_child(walls)
	_add_box(walls, Vector2(32, -0.5), Vector2(70, 1))
	_add_box(walls, Vector2(32, 40.5), Vector2(70, 1))
	_add_box(walls, Vector2(-0.5, 20), Vector2(1, 44))
	_add_box(walls, Vector2(64.5, 20), Vector2(1, 44))
	# Sea polygon: closes the lower-left coast.
	var sea := StaticBody2D.new()
	sea.name = "SeaCollision"
	sea.collision_layer = 1
	add_child(sea)
	var poly := CollisionPolygon2D.new()
	var points := PackedVector2Array()
	points.append(Vector2(0, 21.0))
	for x in range(0, 805, 32):
		points.append(Vector2(float(x) / 32.0, float(_coast_pixel_y(x)) / 32.0 + 0.18))
	points.append(Vector2(25.2, 40))
	points.append(Vector2(0, 40))
	poly.polygon = points
	sea.add_child(poly)


func _add_box(body: StaticBody2D, at: Vector2, size: Vector2) -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = at
	body.add_child(shape)


# ------------------------------------------------------------------ cottage

func _build_house() -> void:
	var house := SettlementPlaceable.new()
	house.name = "Cottage"
	house.placeable_id = "house"
	house.category = "house"
	house.selection_size = Vector2(10.2, 7.2)
	house.position = GameState.placeable_position("house", HOUSE_BASE)
	add_child(house)
	_placeables.append(house)
	_house_origin = house.position
	_house_position = house.position
	_player_spawn = _house_position + Vector2(0, 2.9)
	_recovery_center = _house_position + Vector2(0, 2.3)
	house_sprite = Sprite2D.new()
	house_sprite.name = "HouseArt"
	house_sprite.texture = PixelArt.house_texture(GameState.house_level())
	house_sprite.centered = false
	house_sprite.offset = Vector2(-112, -176)
	house_sprite.scale = Vector2(PixelArt.PX, PixelArt.PX) * 1.3
	house_sprite.z_index = 8
	house.add_child(house_sprite)
	house_glow = PointLight2D.new()
	house_glow.texture = PixelArt.light_texture()
	house_glow.texture_scale = 0.052
	house_glow.energy = 0.32
	house_glow.color = Color("#ffc970")
	house_glow.position = Vector2(0.4, -1.7)
	house.add_child(house_glow)
	var body := StaticBody2D.new()
	body.name = "HouseSolid"
	body.collision_layer = 1
	house.add_child(body)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(7.4, 2.0)
	shape.shape = rect
	shape.position = Vector2(0, -1.15)
	body.add_child(shape)
	# Bedroll on the west porch, still adjacent to the house.
	var building_target := SettlementTarget.new()
	building_target.name = "CottageTarget"
	building_target.target_name = "Cottage"
	building_target.damage_scale = 0.5
	house.add_child(building_target)
	_emergency_fire = Sprite2D.new()
	_emergency_fire.texture = PixelArt.icon("spark")
	_emergency_fire.scale = Vector2(0.08, 0.08)
	_emergency_fire.modulate = Color("#ff8f47")
	_emergency_fire.position = Vector2(1.9, -2.3)
	_emergency_fire.visible = false
	_emergency_fire.z_index = 9
	house.add_child(_emergency_fire)
	var bed := HouseBed.new()
	bed.name = "Bed"
	bed.position = Vector2(-5.0, 0.55)
	house.add_child(bed)
	_markers.append({"position": HOUSE_BASE, "color": Color("#e4c571"), "size": 6.0, "shape": "square"})
	_markers.append({"position": Vector2(38, 15), "color": Color("#8ac36b"), "size": 3.0, "shape": "disc"})


func _on_house_upgraded(level: int) -> void:
	if house_sprite == null:
		return
	house_sprite.texture = PixelArt.house_texture(level)
	house_sprite.modulate = Color(1.25, 1.2, 1.05)
	var tween := create_tween()
	tween.tween_property(house_sprite, "modulate", Color.WHITE, 0.65)
	if level >= 4:
		house_glow.texture_scale = 0.9
		house_glow.energy = 0.38
	var game := get_tree().get_first_node_in_group("game")
	if game != null and game.has_method("refresh_world_ui"):
		game.call("refresh_world_ui")


# ------------------------------------------------------------------ shops

func _build_shops() -> void:
	_add_shop("potion", Vector2(23.8, 22.2), "Mara", Color("#5c8767"))
	_add_shop("equipment", Vector2(21.2, 19.2), "Garrick", Color("#8a5a42"))
	_add_shop("pet", Vector2(26.8, 17.8), "Nia", Color("#735b92"))
	# Dedicated construction shop for the five-level cottage progression.
	_add_shop("house", CONSTRUCTION_SHOP, "Bram", Color("#8f8060"))


func _add_shop(kind: String, at: Vector2, npc_name: String, color: Color) -> void:
	var shop := SettlementPlaceable.new()
	shop.name = "%sShop" % kind.capitalize()
	shop.placeable_id = "shop_%s" % kind
	shop.category = "shop"
	shop.selection_size = Vector2(4.3, 4.7)
	shop.position = GameState.placeable_position(shop.placeable_id, at)
	add_child(shop)
	_placeables.append(shop)
	var stall := Sprite2D.new()
	stall.name = "%sStall" % kind.capitalize()
	stall.texture = PixelArt.stall_texture(kind)
	stall.centered = false
	stall.offset = Vector2(-56, -96)
	stall.scale = Vector2(PixelArt.PX, PixelArt.PX)
	stall.z_index = 5
	shop.add_child(stall)
	_shop_stalls.append(stall)
	var target := SettlementTarget.new()
	target.name = "%sTarget" % kind.capitalize()
	target.target_name = "%s stall" % kind.capitalize()
	target.position = Vector2(0, -0.5)
	shop.add_child(target)
	var npc := ShopNPC.new()
	npc.name = npc_name
	npc.shop_type = kind
	npc.npc_kind = "builder" if kind == "house" else kind
	npc.npc_name = npc_name
	npc.position = Vector2(0, 1.35)
	shop.add_child(npc)
	# A small warm lamp under each awning.
	var lamp := PointLight2D.new()
	lamp.texture = PixelArt.light_texture()
	lamp.texture_scale = 0.34
	lamp.energy = 0.22
	lamp.color = color.lightened(0.35)
	lamp.position = Vector2(0, -1.3)
	shop.add_child(lamp)


func _build_special_npc() -> void:
	var student := UniszaStudent.new()
	student.name = "UniszaStudent"
	student.position = Vector2(36.4, 23.2)
	add_child(student)


# ------------------------------------------------------------------ portals

func _build_portals() -> void:
	# The two gates stand side by side on the north path: campaign monsters on
	# the left, companion duels on the right.
	var first := PortalEntrance.new()
	first.name = "MonsterBattlePortal"
	first.portal_id = "tidebound_grotto"
	first.gate_kind = "monster"
	first.gate_title = "Monster Battle Portal"
	first.position = MONSTER_GATE
	add_child(first)
	_markers.append({"position": first.position, "color": Color("#a47be0"), "size": 4.0, "shape": "arch"})
	var second := PortalEntrance.new()
	second.name = "PetBattlePortal"
	second.portal_id = "pet_duel_1"
	second.gate_kind = "pet"
	second.gate_title = "Pet Battle Portal"
	second.position = PET_GATE
	add_child(second)
	_markers.append({"position": second.position, "color": Color("#58d6cf"), "size": 4.0, "shape": "arch"})
	# Warning stones tie the paired gates together.
	for p in [Vector2(28.4, 12.1), Vector2(39.6, 12.1), Vector2(34.0, 9.9)]:
		var ruin := Sprite2D.new()
		ruin.texture = load("res://assets/sprites/TX Props__TX Props - Stone 03.tres")
		ruin.centered = false
		var sz := ruin.texture.get_size()
		ruin.offset = Vector2(-sz.x * 0.5, -sz.y)
		ruin.scale = Vector2(PixelArt.PX, PixelArt.PX)
		ruin.position = p
		ruin.z_index = 3
		add_child(ruin)


func _on_forest_tree_felled(_tree: ForestTree) -> void:
	GameState.save_game()
	_check_forest_game_over()


func _check_forest_game_over() -> void:
	if GameState.game_over_active or _forest_trees.is_empty():
		return
	var alive := 0
	for tree in _forest_trees:
		if is_instance_valid(tree) and tree.is_alive():
			alive += 1
	if alive <= 0:
		GameState.trigger_game_over("All forest trees have fallen. The village is lost.")


func forest_alive_count() -> int:
	var alive := 0
	for tree in _forest_trees:
		if is_instance_valid(tree) and tree.is_alive():
			alive += 1
	return alive


func _build_forest_monsters() -> void:
	_spawn_forest_monsters(12)


func _spawn_forest_monsters(count: int) -> void:
	var forest_spots := [
		Vector2(47.4, 8.8), Vector2(50.8, 14.2), Vector2(49.0, 21.2),
		Vector2(53.2, 26.0), Vector2(57.2, 18.0), Vector2(46.2, 30.2),
		Vector2(54.0, 33.0), Vector2(59.0, 10.2), Vector2(51.8, 31.4),
		Vector2(56.0, 6.7), Vector2(47.0, 15.0), Vector2(58.6, 27.0),
	]
	var offset := _forest_monsters.size()
	for i in count:
		var p: Vector2 = forest_spots[(offset + i) % forest_spots.size()]
		var monster := Enemy.new()
		monster.kind = "raider" if i % 2 == 1 else "bogling"
		monster.monster_level = 2
		monster.forest_mode = true
		monster.sight_range = 11.5
		monster.attack_interval = 0.62
		monster.max_hp = 54
		monster.damage = 6
		monster.speed = 1.62
		monster.xp_reward = 9
		monster.gold_reward = 6
		monster.diamond_chance = 0.0
		monster.body_radius = 0.4
		monster.position = p + Vector2(_rng.randf_range(-0.6, 0.6), _rng.randf_range(-0.5, 0.5))
		add_child(monster)
		_forest_monsters.append(monster)


func _build_gathering() -> void:
	for p in [Vector2(5.0, 21.4), Vector2(12.0, 26.4), Vector2(18.2, 31.1)]:
		var pile := ResourcePile.new()
		pile.name = "Driftwood"
		pile.position = p
		add_child(pile)


# ------------------------------------------------------------------ dock & ship

func _build_dock_and_ship() -> void:
	var dock := Sprite2D.new()
	dock.name = "Jetty"
	dock.texture = PixelArt.dock_texture()
	dock.centered = false
	dock.offset = Vector2(-128, -96)
	dock.scale = Vector2(PixelArt.PX, PixelArt.PX)
	dock.position = Vector2(9.0, 28.5)
	dock.z_index = 2
	add_child(dock)
	var ship := Sprite2D.new()
	ship.name = "MooredShip"
	ship.texture = PixelArt.ship_texture()
	ship.centered = false
	ship.offset = Vector2(-104, -112)
	ship.scale = Vector2(PixelArt.PX, PixelArt.PX)
	ship.position = Vector2(7.5, 32.0)
	ship.z_index = 3
	add_child(ship)
	# Gentle bobbing so the harbour feels alive.
	if GameSettings.effects_at_least("med") and not GameSettings.reduce_motion():
		var bob := ship.create_tween().set_loops()
		bob.tween_property(ship, "position:y", 32.05, 2.1).set_trans(Tween.TRANS_SINE)
		bob.tween_property(ship, "position:y", 31.95, 2.1).set_trans(Tween.TRANS_SINE)
		var sway := ship.create_tween().set_loops()
		sway.tween_property(ship, "rotation", 0.008, 3.1).set_trans(Tween.TRANS_SINE)
		sway.tween_property(ship, "rotation", -0.008, 3.1).set_trans(Tween.TRANS_SINE)
	# Lamps on the jetty.
	for x in [3.4, 13.5]:
		var lamp := PointLight2D.new()
		lamp.texture = PixelArt.light_texture()
		lamp.texture_scale = 0.024
		lamp.energy = 0.22
		lamp.color = Color("#ffd483")
		lamp.position = Vector2(x, 29.5)
		add_child(lamp)
	# A few crates for life.
	for p in [Vector2(11.8, 27.8), Vector2(12.7, 28.2)]:
		var crate := Sprite2D.new()
		crate.texture = load("res://assets/sprites/TX Props__TX Props Crate Small.tres")
		crate.centered = false
		var sz := crate.texture.get_size()
		crate.offset = Vector2(-sz.x * 0.5, -sz.y)
		crate.scale = Vector2(PixelArt.PX, PixelArt.PX)
		crate.position = p
		crate.z_index = 5
		add_child(crate)
	_markers.append({"position": Vector2(8, 30), "color": Color("#77aeb5"), "size": 3.0, "shape": "disc"})


func _build_beached_turtle() -> void:
	var turtle := Node2D.new()
	turtle.name = "BeachedTurtle"
	turtle.position = Vector2(7.8, 23.3)
	turtle.add_to_group("beached_turtle")
	add_child(turtle)
	var shadow := Sprite2D.new()
	shadow.name = "Shadow"
	shadow.texture = PixelArt.light_texture()
	shadow.scale = Vector2(0.014, 0.007)
	shadow.modulate = Color(0.02, 0.03, 0.03, 0.24)
	shadow.position = Vector2(0.06, 0.08)
	shadow.z_index = -1
	turtle.add_child(shadow)
	var shell := Sprite2D.new()
	shell.name = "TurtleArt"
	shell.texture = PixelArt.cached_texture("beached_turtle_32x24", func() -> Image:
		var img := PixelArt.image(32, 24)
		PixelArt.ellipse(img, 15, 12, 10, 7, Color("#314b31"))
		PixelArt.ellipse(img, 15, 11, 8, 5, Color("#819c52"))
		PixelArt.line(img, 10, 7, 10, 15, Color("#506b3d"))
		PixelArt.line(img, 15, 6, 15, 16, Color("#506b3d"))
		PixelArt.line(img, 20, 8, 20, 15, Color("#506b3d"))
		PixelArt.line(img, 10, 11, 20, 11, Color("#506b3d"))
		PixelArt.ellipse(img, 26, 12, 4, 3, Color("#8ead62"))
		PixelArt.ellipse(img, 9, 6, 3, 2, Color("#67884b"))
		PixelArt.ellipse(img, 9, 17, 3, 2, Color("#67884b"))
		PixelArt.ellipse(img, 21, 17, 3, 2, Color("#67884b"))
		PixelArt.ellipse(img, 21, 6, 3, 2, Color("#67884b"))
		PixelArt.px(img, 27, 11, Color("#1c2c25"))
		PixelArt.px(img, 28, 11, Color("#f4e9bd"))
		return img)
	shell.centered = true
	shell.scale = Vector2(PixelArt.PX, PixelArt.PX)
	shell.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	shell.z_index = 1
	turtle.add_child(shell)
	if not GameSettings.reduce_motion():
		var breathe := turtle.create_tween().set_loops()
		breathe.tween_property(shell, "rotation", 0.025, 1.8).set_trans(Tween.TRANS_SINE)
		breathe.tween_property(shell, "rotation", -0.025, 1.8).set_trans(Tween.TRANS_SINE)


# ------------------------------------------------------------------ forest

func _build_forest() -> void:
	var tree_data := [
		["T1", "res://assets/sprites/TX Plant__TX Tree T1 Upper.tres", "res://assets/sprites/TX Plant__TX Tree T1 Lower.tres"],
		["T2", "res://assets/sprites/TX Plant__TX Tree T2 Upper.tres", "res://assets/sprites/TX Plant__TX Tree T2 Lower.tres"],
		["T3", "res://assets/sprites/TX Plant__TX Tree T3 Upper.tres", "res://assets/sprites/TX Plant__TX Tree T3 Lower.tres"],
	]
	var positions: Array[Vector2] = []
	# Curated tree line framing the forest to the east.
	for y in [6.8, 10.2, 13.6, 17.2, 20.7, 24.0, 27.6, 31.2, 34.8]:
		positions.append(Vector2(_rng.randf_range(50.0, 62.0), y))
	# Top woodland.
	for x in [4.0, 9.0, 14.0, 19.0, 25.0, 31.0, 37.0, 47.0, 54.0, 60.0]:
		positions.append(Vector2(x + _rng.randf_range(-1.0, 1.0), _rng.randf_range(3.4, 6.8)))
	# Scattered western trees.
	positions.append(Vector2(5.0, 12.8))
	positions.append(Vector2(8.2, 7.2))
	positions.append(Vector2(2.7, 18.2))
	positions.append(Vector2(45.8, 26.8))
	for i in positions.size():
		var p := positions[i]
		if _too_close_to_landmarks(p):
			continue
		var data: Array = tree_data[i % tree_data.size()]
		_add_tree(p, data[1], data[2], 1.0 + _rng.randf_range(-0.05, 0.08))
	# Framing trees inside the starting camera view so the house does not sit in
	# an empty field. Keep them clear of doors, stalls and the central path.
	var framing := [
		Vector2(45.2, 24.8), Vector2(46.4, 20.6), Vector2(43.2, 28.8),
		Vector2(39.8, 31.2), Vector2(29.6, 14.5), Vector2(20.6, 15.4),
		Vector2(19.0, 24.4), Vector2(44.6, 15.7), Vector2(38.2, 14.2),
		Vector2(27.2, 27.5),
	]
	for i in framing.size():
		var p: Vector2 = framing[i]
		var blocked := false
		for shop in [Vector2(23.8, 22.2), Vector2(21.2, 19.2), Vector2(26.8, 17.8), CONSTRUCTION_SHOP]:
			if p.distance_to(shop) < 2.6:
				blocked = true
		if p.distance_to(MONSTER_GATE) < 3.2 or p.distance_to(PET_GATE) < 3.2 or p.distance_to(SPAWN) < 2.2:
			blocked = true
		if blocked:
			continue
		var data: Array = tree_data[(i + 1) % tree_data.size()]
		_add_tree(p, data[1], data[2], 0.95 + _rng.randf_range(-0.04, 0.1))
	# A dense eastern woodland. These are all attackable ForestTree nodes, so the
	# player has a real forest to defend during raids.
	for gy in 9:
		for gx in 7:
			var p := Vector2(
				47.2 + float(gx) * 2.35 + _rng.randf_range(-0.75, 0.75),
				3.8 + float(gy) * 3.75 + _rng.randf_range(-0.8, 0.8))
			if _too_close_to_landmarks(p) or _tree_too_close(p, 1.55):
				continue
			if p.distance_to(Vector2(48.2, 17.5)) < 3.8:
				continue
			var data: Array = tree_data[(gx + gy) % tree_data.size()]
			_add_tree(p, data[1], data[2], 0.82 + _rng.randf_range(-0.04, 0.2))


func _tree_too_close(p: Vector2, distance: float) -> bool:
	for existing in _tree_positions:
		if p.distance_to(existing) < distance:
			return true
	return false


func _too_close_to_landmarks(p: Vector2) -> bool:
	if p.distance_to(HOUSE_BASE) < 12.0:
		return true
	for house_at in _house_positions:
		if p.distance_to(house_at) < 4.2:
			return true
	for ruin_at in _ruin_positions:
		if p.distance_to(ruin_at) < 4.2:
			return true
	for shop in [Vector2(23.8, 22.2), Vector2(21.2, 19.2), Vector2(26.8, 17.8), CONSTRUCTION_SHOP]:
		if p.distance_to(shop) < 4.2:
			return true
	if p.distance_to(MONSTER_GATE) < 3.8:
		return true
	if p.distance_to(PET_GATE) < 3.8:
		return true
	if p.distance_to(Vector2(34.0, 10.4)) < 2.5:
		return true
	if p.distance_to(SPAWN) < 5.2:
		return true
	return false


func _add_tree(at: Vector2, upper_path: String, lower_path: String, scale_mul: float) -> void:
	var holder := ForestTree.new()
	holder.name = "ForestTree"
	holder.tree_id = "forest_%d" % _tree_serial
	holder.max_health = 100 + (_tree_serial % 3) * 15
	holder.tree_name = "Forest tree"
	holder.position = at
	_tree_serial += 1
	holder.felled.connect(_on_forest_tree_felled)
	add_child(holder)
	_forest_trees.append(holder)
	_tree_positions.append(at)
	var upper := load(upper_path) as Texture2D
	var lower := load(lower_path) as Texture2D
	var upper_size := upper.get_size()
	var lower_size := lower.get_size()
	var total_h := upper_size.y + lower_size.y
	var shadow := Sprite2D.new()
	shadow.name = "Shadow"
	shadow.texture = PixelArt.light_texture()
	shadow.scale = Vector2(0.021 * scale_mul, 0.011 * scale_mul)
	shadow.modulate = Color(0, 0, 0, 0.33)
	shadow.position = Vector2(0, -0.03)
	shadow.z_index = -1
	holder.add_child(shadow)
	var lower_sprite := Sprite2D.new()
	lower_sprite.name = "LowerSprite"
	lower_sprite.texture = lower
	lower_sprite.centered = false
	lower_sprite.offset = Vector2(-lower_size.x * 0.5, -lower_size.y)
	lower_sprite.scale = Vector2(PixelArt.PX, PixelArt.PX) * scale_mul
	lower_sprite.modulate = Color(0.76, 0.9, 0.74)
	lower_sprite.z_index = 3
	holder.add_child(lower_sprite)
	var upper_sprite := Sprite2D.new()
	upper_sprite.name = "UpperSprite"
	upper_sprite.texture = upper
	upper_sprite.material = Shaders.wind_material() if GameSettings.effects_at_least("med") else null
	upper_sprite.centered = false
	upper_sprite.offset = Vector2(-upper_size.x * 0.5, -total_h)
	upper_sprite.scale = Vector2(PixelArt.PX, PixelArt.PX) * scale_mul
	upper_sprite.modulate = Color(0.76, 0.9, 0.74)
	upper_sprite.z_index = 3
	holder.add_child(upper_sprite)
	holder.register_visual(lower_sprite)
	holder.register_visual(upper_sprite)
	var body := StaticBody2D.new()
	body.name = "Body"
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 0.45
	shape.shape = circle
	shape.position = Vector2(0, -0.2)
	body.add_child(shape)
	holder.add_child(body)


func _build_scatter() -> void:
	var bush_paths := [
		"res://assets/sprites/TX Plant__TX Bush T1.tres",
		"res://assets/sprites/TX Plant__TX Bush T2.tres",
		"res://assets/sprites/TX Plant__TX Bush T3.tres",
		"res://assets/sprites/TX Plant__TX Bush T5.tres",
	]
	var grass_paths := [
		"res://assets/sprites/TX Plant__TX Plant - Grass 01.tres",
		"res://assets/sprites/TX Plant__TX Plant - Grass 03.tres",
		"res://assets/sprites/TX Plant__TX Plant - Grass 07.tres",
		"res://assets/sprites/TX Plant__TX Plant - Grass 13.tres",
	]
	var flower_paths := [
		"res://assets/sprites/TX Plant__TX Plant - Flower 01.tres",
	]
	# Bushes around the house and forest edge.
	for p in [
		Vector2(29.2, 22.4), Vector2(39.0, 23.4), Vector2(41.2, 21.0),
		Vector2(15.1, 20.1), Vector2(21.9, 21.7), Vector2(14.8, 14.7),
		Vector2(22.3, 13.2), Vector2(47.0, 18.0), Vector2(49.5, 24.5),
		Vector2(26.0, 26.9), Vector2(20.0, 26.0), Vector2(11.0, 19.8),
	]:
		_add_wind_decor(bush_paths[_rng.randi_range(0, bush_paths.size() - 1)], p, 1.0 + _rng.randf_range(-0.12, 0.18), 4)
	# Grass "rumput2": clustered MultiMesh fields (a handful of draw calls for
	# hundreds of tufts) instead of one sprite per tuft. A dedicated seeded RNG
	# keeps this fully deterministic and never touches the tree-id sequence.
	_build_grass_fields(grass_paths)
	# Flower clumps.
	for i in 34:
		var p := Vector2(_rng.randf_range(2, 60), _rng.randf_range(4, 35))
		if _too_close_to_landmarks(p) and _rng.randf() > 0.2:
			continue
		var shore := float(_coast_pixel_y(int(p.x * 32))) / 32.0
		if p.y > shore - 0.5:
			continue
		for j in _rng.randi_range(2, 5):
			_add_wind_decor(flower_paths[0], p + Vector2(_rng.randf_range(-0.5, 0.5), _rng.randf_range(-0.35, 0.35)), 0.9, 3)
	# Moveable decorations near the cottage.
	_add_decor_placeable("barrel_1", "res://assets/sprites/TX Props__TX Props Barrel.tres", Vector2(28.8, 23.8), 1.0, 5, Vector2(1.2, 1.4))
	_add_decor_placeable("barrel_2", "res://assets/sprites/TX Props__TX Props Barrel.tres", Vector2(40.2, 22.8), 1.0, 5, Vector2(1.2, 1.4))
	_add_decor_placeable("signpost", "res://assets/sprites/TX Props__TX Props Road Sign W.tres", Vector2(25.7, 22.1), 1.0, 5, Vector2(1.3, 1.5))


func _add_decor_sprite(path: String, at: Vector2, scale_mul: float, z: int) -> Sprite2D:
	var tex := load(path) as Texture2D
	if tex == null:
		return null
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.centered = false
	var sz := tex.get_size()
	sprite.offset = Vector2(-sz.x * 0.5, -sz.y)
	sprite.scale = Vector2(PixelArt.PX, PixelArt.PX) * scale_mul
	sprite.position = at
	sprite.z_index = z
	if "Flower" in path:
		sprite.add_to_group("flowers")
	add_child(sprite)
	return sprite


func _add_decor_placeable(id: String, path: String, at: Vector2, scale_mul: float, z: int, selection: Vector2) -> void:
	var tex := load(path) as Texture2D
	if tex == null:
		return
	var group := SettlementPlaceable.new()
	group.name = id.capitalize()
	group.placeable_id = id
	group.category = "decoration"
	group.selection_size = selection
	group.position = GameState.placeable_position(id, at)
	add_child(group)
	_placeables.append(group)
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.centered = false
	var sz := tex.get_size()
	sprite.offset = Vector2(-sz.x * 0.5, -sz.y)
	sprite.scale = Vector2(PixelArt.PX, PixelArt.PX) * scale_mul
	sprite.z_index = z
	group.add_child(sprite)
	if id == "signpost":
		var sign_text := Label.new()
		sign_text.name = "BesutSignText"
		sign_text.add_to_group("besut_sign")
		sign_text.text = "BESUT"
		sign_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sign_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		sign_text.add_theme_font_size_override("font_size", 8)
		sign_text.add_theme_color_override("font_color", Color("#f7e5ad"))
		sign_text.add_theme_color_override("font_outline_color", Color("#26342c"))
		sign_text.add_theme_constant_override("outline_size", 2)
		sign_text.size = Vector2(64, 16)
		sign_text.position = Vector2(-1.0, -1.8)
		sign_text.scale = Vector2(PixelArt.PX, PixelArt.PX)
		sign_text.z_index = z + 5
		sign_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		group.add_child(sign_text)


func _add_wind_decor(path: String, at: Vector2, scale_mul: float, z: int) -> void:
	# Scatter sprite that joins the shared wind sway (med quality and above).
	var sprite := _add_decor_sprite(path, at, scale_mul, z)
	if sprite != null and GameSettings.effects_at_least("med"):
		sprite.material = Shaders.wind_material()


var _grass_rng := RandomNumberGenerator.new()


func _build_grass_fields(grass_paths: Array) -> void:
	# Noise-clustered meadows: ~14 patch centres each seeding a gaussian
	# cluster, over a sparse uniform background. Instances render through one
	# MultiMesh per texture variant, with per-instance colour jitter and a
	# custom-data phase seed for the wind shader.
	if not GameSettings.effects_at_least("low"):
		return
	_grass_rng.seed = 20531
	var clusters: Array[Vector2] = []
	for i in 14:
		clusters.append(Vector2(_grass_rng.randf_range(3.0, 61.0), _grass_rng.randf_range(4.0, 36.0)))
	var count := 520 if GameSettings.effects_at_least("med") else 260
	var placements: Array[Transform2D] = []
	var colors: Array[Color] = []
	var variants: Array = []
	for i in count:
		var p := Vector2.ZERO
		if _grass_rng.randf() < 0.72:
			var c: Vector2 = clusters[_grass_rng.randi_range(0, clusters.size() - 1)]
			p = c + Vector2(_grass_rng.randfn(0.0, 2.6), _grass_rng.randfn(0.0, 1.7))
		else:
			p = Vector2(_grass_rng.randf_range(2.0, 62.0), _grass_rng.randf_range(3.0, 38.0))
		var shore := float(_coast_pixel_y(int(p.x * 32))) / 32.0
		if p.y > shore - 0.45 or p.x < 0.5 or p.x > 63.5 or p.y < 1.0 or p.y > 39.0:
			continue
		if _too_close_to_landmarks(p) and _grass_rng.randf() > 0.3:
			continue
		var variant := _grass_rng.randi_range(0, grass_paths.size() - 1)
		var mul := 0.75 + _grass_rng.randf_range(-0.15, 0.35)
		variants.append(variant)
		placements.append(Transform2D(0.0, Vector2(mul, mul), 0.0, p))
		var tint := 0.62 + _grass_rng.randf() * 0.24
		colors.append(Color(tint, tint * (0.98 + _grass_rng.randf() * 0.08), tint * 0.82))
	for vi in grass_paths.size():
		var tex := load(str(grass_paths[vi])) as Texture2D
		if tex == null:
			continue
		var mesh := QuadMesh.new()
		mesh.size = tex.get_size()
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_2D
		mm.use_colors = true
		mm.use_custom_data = true
		var instance_count := 0
		for i in placements.size():
			if variants[i] == vi:
				instance_count += 1
		if instance_count == 0:
			continue
		mm.instance_count = instance_count
		var write := 0
		for i in placements.size():
			if variants[i] != vi:
				continue
			var xf: Transform2D = placements[i]
			var s := PixelArt.PX * xf.get_scale().x
			# QuadMesh is centred; shift so the base of the tuft sits on the point.
			var origin := xf.origin - Vector2(0.0, tex.get_size().y * 0.5 * s)
			mm.set_instance_transform_2d(write, Transform2D(0.0, Vector2(s, s), 0.0, origin))
			mm.set_instance_color(write, colors[i])
			# Custom data carries a per-instance phase seed for the wind shader.
			mm.set_instance_custom_data(write, Color(_grass_rng.randf() * 10.0, 0.0, 0.0, 0.0))
			write += 1
		var field := MultiMeshInstance2D.new()
		field.name = "GrassField%d" % vi
		field.multimesh = mm
		field.texture = tex
		field.z_index = 2
		field.material = Shaders.wind_material() if GameSettings.effects_at_least("med") else null
		field.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(field)


# ------------------------------------------------------------------ actors

func _build_player_and_pet() -> void:
	player = Player.new()
	player.name = "Player"
	player.position = _player_spawn
	add_child(player)
	pet = Pet.new()
	pet.name = "Pet"
	pet.player = player
	pet.position = _player_spawn + Vector2(-1.2, 0.5)
	add_child(pet)
	player.sleep_changed.connect(_on_sleep_changed)
	player.hurt_flash.connect(func() -> void:
		if camera:
			camera.shake(0.12, 0.18)
		var hud := get_tree().get_first_node_in_group("hud")
		if hud != null and hud.has_method("flash_hurt"):
			hud.call("flash_hurt"))


func _build_camera() -> void:
	camera = FollowCamera.new()
	camera.name = "Camera"
	camera.target = player
	camera.bounds = MAP_RECT
	camera.global_position = player.global_position + Vector2(0, -0.8)
	add_child(camera)


func _on_sleep_changed(active: bool, progress: float, label: String) -> void:
	var game := get_tree().get_first_node_in_group("game")
	if game != null and game.has_method("set_sleep_state"):
		game.call("set_sleep_state", active, progress, label)


func _on_data_changed() -> void:
	pass


func _on_pet_changed() -> void:
	pass


# ------------------------------------------------------------------ residential life

func _build_residential_life() -> void:
	_build_fences()
	# Neighbour cottages beyond the fence line make the settlement feel lived in.
	_add_resident_house("ResidentHouseEast", Vector2(48.1, 18.4), 2)
	_add_resident_house("ResidentHouseWest", Vector2(14.0, 18.1), 1)
	_add_resident_house("ResidentHouseSouth", Vector2(39.4, 31.4), 3)
	_add_resident_house("ResidentHouseNorth", Vector2(25.0, 8.0), 2)
	_add_resident_house("ResidentHouseWestNorth", Vector2(11.0, 12.0), 1)
	_add_resident_house("ResidentHouseEastSouth", Vector2(54.5, 33.0), 2)
	_add_resident_house("ResidentHouseSouthWest", Vector2(29.0, 33.0), 1)
	# Abandoned and battle-damaged homes make the village feel lived-in and at risk.
	_add_ruin_house("AbandonedHouse", Vector2(17.8, 13.6), "abandoned")
	_add_ruin_house("DamagedHouse", Vector2(52.0, 33.2), "damaged")
	_add_ruin_house("DestroyedHouse", Vector2(22.5, 32.4), "destroyed")
	_add_ruin_house("RuinedHouse", Vector2(55.5, 7.8), "destroyed")
	# Garden beds.
	_add_garden("garden_1", Vector2(39.4, 24.7))
	_add_garden("garden_2", Vector2(41.8, 24.7))
	_add_garden("garden_3", Vector2(44.2, 24.7))
	_add_garden("garden_4", Vector2(36.4, 27.8))
	_add_garden("garden_5", Vector2(19.2, 27.0))
	_add_garden("garden_6", Vector2(44.3, 20.0))
	# A small animal corner plus the village horses.
	_add_animal("chicken", Vector2(41.6, 28.0))
	_add_animal("chicken", Vector2(42.7, 28.3))
	_add_animal("goat", Vector2(43.7, 28.0))
	_add_animal("chicken", Vector2(40.4, 27.5))
	_add_animal("goat", Vector2(44.4, 27.3))
	_add_animal("horse", Vector2(36.8, 31.1), 1.55)
	_add_animal("horse", Vector2(16.2, 22.5), 1.5)
	# A few more movable decorations close to the cottages.
	_add_decor_placeable("crate_1", "res://assets/sprites/TX Props__TX Props Crate.tres", Vector2(31.9, 25.1), 1.0, 5, Vector2(1.4, 1.5))
	_add_decor_placeable("barrel_3", "res://assets/sprites/TX Props__TX Props Barrel.tres", Vector2(45.0, 18.8), 1.0, 5, Vector2(1.2, 1.4))
	_add_decor_placeable("crate_2", "res://assets/sprites/TX Props__TX Props Crate Small.tres", Vector2(22.4, 28.6), 1.0, 5, Vector2(1.2, 1.3))
	# More flower borders around the gardens, cottages and new homes.
	for p in [
		Vector2(38.4, 23.8), Vector2(39.0, 26.0), Vector2(42.7, 23.6),
		Vector2(44.8, 25.3), Vector2(36.8, 24.8), Vector2(28.0, 24.6),
		Vector2(31.8, 22.5), Vector2(35.8, 25.2), Vector2(43.8, 26.2),
		Vector2(46.8, 19.8), Vector2(47.0, 18.6), Vector2(12.9, 19.0),
		Vector2(15.2, 18.7), Vector2(37.8, 30.0), Vector2(40.8, 30.8),
		Vector2(23.8, 9.3), Vector2(26.3, 9.4), Vector2(34.4, 25.9),
		Vector2(18.3, 26.1), Vector2(45.2, 20.9),
	]:
		for i in 4:
			_add_decor_sprite("res://assets/sprites/TX Plant__TX Plant - Flower 01.tres", p + Vector2(_rng.randf_range(-0.55, 0.55), _rng.randf_range(-0.35, 0.35)), 0.9, 3)
	# Daily-activity residents.
	_add_resident("Sami", "fisher", "Fishing the shallows", Vector2(12.6, 26.0), [Vector2(12.6, 26.0), Vector2(14.0, 25.5), Vector2(11.3, 26.7)], Vector2(33.8, 23.4))
	_add_resident("Hana", "gardener", "Tending the garden", Vector2(40.3, 25.8), [Vector2(40.3, 25.8), Vector2(42.0, 25.8), Vector2(39.1, 25.1)], Vector2(33.6, 23.2))
	_add_resident("Rami", "carpenter", "Repairing the cottage", Vector2(37.2, 22.6), [Vector2(37.2, 22.6), Vector2(38.7, 23.1), Vector2(36.4, 23.4)], Vector2(33.2, 23.0), true)
	_add_resident("Daud", "woodcutter", "Hauling forest wood", Vector2(44.8, 27.0), [Vector2(44.8, 27.0), Vector2(41.0, 26.7), Vector2(37.0, 26.2)], Vector2(34.2, 23.5), true)
	_add_resident("Noor", "keeper", "Feeding the animals", Vector2(43.2, 28.5), [Vector2(43.2, 28.5), Vector2(42.0, 28.2), Vector2(44.0, 28.2)], Vector2(33.4, 23.1))
	_add_resident("Bilal", "farmer", "Harvesting crops", Vector2(42.9, 25.8), [Vector2(42.9, 25.8), Vector2(44.4, 25.4), Vector2(41.2, 25.9)], Vector2(33.5, 23.3))
	_add_resident("Yusuf", "trader", "Trading village goods", Vector2(29.1, 21.0), [Vector2(29.1, 21.0), Vector2(27.2, 22.0), Vector2(25.2, 23.5)], Vector2(34.5, 23.2))
	_add_resident("Tomas", "defender", "Watching the sea gate", Vector2(20.2, 25.7), [Vector2(20.2, 25.7), Vector2(22.3, 26.4)], Vector2(26.5, 25.5), true, 11, 4.8)
	_add_resident("Sora", "defender", "Watching the forest gate", Vector2(44.4, 20.2), [Vector2(44.4, 20.2), Vector2(42.2, 21.4)], Vector2(39.5, 22.0), true, 11, 4.8)
	_add_resident("Amir", "stablehand", "Tending the horses", Vector2(36.8, 30.2), [Vector2(36.8, 30.2), Vector2(38.2, 30.7), Vector2(35.7, 30.7)], Vector2(33.8, 23.4))
	_add_resident("Laila", "gardener", "Watering the new gardens", Vector2(36.4, 27.0), [Vector2(36.4, 27.0), Vector2(44.0, 20.8), Vector2(19.8, 27.4)], Vector2(33.5, 23.2))
	_add_resident("Zara", "resident", "Visiting the west cottages", Vector2(15.0, 19.4), [Vector2(15.0, 19.4), Vector2(23.0, 23.0), Vector2(30.5, 24.5)], Vector2(34.0, 23.2))
	# Shoppers pause with a coin cue; they do not alter player currency or stock.
	_add_resident("Mira", "trader", "Browsing the village shops", Vector2(22.8, 24.0), [Vector2(22.8, 24.0), Vector2(23.8, 23.7), Vector2(22.0, 21.0)], Vector2(33.8, 23.4), false, 8, 4.2, true)
	_add_resident("Fikri", "trader", "Buying village goods", Vector2(27.0, 20.4), [Vector2(27.0, 20.4), Vector2(27.4, 18.9), Vector2(26.0, 17.8)], Vector2(33.8, 23.4), false, 8, 4.2, true)


func _add_resident_house(house_name: String, at: Vector2, level: int) -> void:
	var holder := Node2D.new()
	holder.name = house_name
	holder.position = at
	holder.add_to_group("resident_house")
	add_child(holder)
	var art := Sprite2D.new()
	art.texture = PixelArt.house_texture(level)
	art.centered = false
	art.offset = Vector2(-112, -176)
	art.scale = Vector2(PixelArt.PX, PixelArt.PX) * 0.78
	art.z_index = 7
	add_child(art)
	var glow := PointLight2D.new()
	glow.texture = PixelArt.light_texture()
	glow.texture_scale = 0.4
	glow.energy = 0.2
	glow.color = Color("#ffd58c")
	glow.position = Vector2(0, -1.2)
	add_child(glow)
	var target := SettlementTarget.new()
	target.name = "ResidentHouseTarget"
	target.target_name = "Resident cottage"
	target.damage_scale = 0.25
	target.position = Vector2(0, -0.8)
	add_child(target)
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(4.8, 1.1)
	shape.shape = rect
	shape.position = Vector2(0, -0.55)
	body.add_child(shape)
	add_child(body)
	_house_positions.append(at)
	_markers.append({"position": at, "color": Color("#e4c571"), "size": 3.5, "shape": "square"})


func _add_ruin_house(house_name: String, at: Vector2, state: String) -> void:
	var holder := Node2D.new()
	holder.name = house_name
	holder.position = at
	holder.add_to_group("ruin_house")
	add_child(holder)
	var art := Sprite2D.new()
	art.texture = PixelArt.house_texture(2 if state == "abandoned" else 1)
	art.centered = false
	art.offset = Vector2(-112, -176)
	art.scale = Vector2(PixelArt.PX, PixelArt.PX) * 0.74
	art.z_index = 6
	add_child(art)
	match state:
		"abandoned":
			art.modulate = Color(0.58, 0.58, 0.52)
			art.rotation = -0.07
		"damaged":
			art.modulate = Color(0.74, 0.64, 0.56)
			art.rotation = 0.08
			_add_smoke(holder, Vector2(0.3, -3.0))
		"destroyed":
			art.modulate = Color(0.45, 0.4, 0.36, 0.92)
			art.scale.y *= 0.42
			art.rotation = 0.2
			for i in 4:
				var rubble := Sprite2D.new()
				rubble.texture = PixelArt.icon("wood")
				rubble.scale = Vector2(0.055, 0.055)
				rubble.rotation = randf_range(-0.8, 0.8)
				rubble.position = Vector2(randf_range(-2.0, 2.0), randf_range(-0.4, 0.3))
				rubble.modulate = Color("#8a6a47")
				add_child(rubble)
			_add_smoke(holder, Vector2(0.0, -2.0))
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(4.6, 1.0) if state != "destroyed" else Vector2(3.8, 0.6)
	shape.shape = rect
	shape.position = Vector2(0, -0.5)
	body.add_child(shape)
	add_child(body)
	_ruin_positions.append(at)
	_markers.append({"position": at, "color": Color("#8b7b62"), "size": 3.0, "shape": "square"})


func _add_smoke(holder: Node2D, at: Vector2) -> void:
	for i in 3:
		var smoke := Sprite2D.new()
		smoke.texture = PixelArt.light_texture()
		smoke.scale = Vector2(0.012, 0.012)
		smoke.modulate = Color(0.45, 0.43, 0.4, 0.35)
		smoke.position = at + Vector2(float(i) * 0.25, 0)
		smoke.z_index = 7
		add_child(smoke)
		var tween := smoke.create_tween().set_loops()
		tween.tween_property(smoke, "position:y", smoke.position.y - 1.2, 2.4 + float(i) * 0.2)
		tween.parallel().tween_property(smoke, "modulate:a", 0.0, 2.4)
		tween.tween_callback(func() -> void:
			smoke.position = at + Vector2(float(i) * 0.25, 0)
			smoke.modulate = Color(0.45, 0.43, 0.4, 0.35))


func _add_garden(id: String, at: Vector2) -> void:
	var group := SettlementPlaceable.new()
	group.name = id.capitalize()
	group.placeable_id = id
	group.category = "decoration"
	group.selection_size = Vector2(2.4, 1.4)
	group.position = GameState.placeable_position(id, at)
	add_child(group)
	group.add_to_group("garden")
	_placeables.append(group)
	var garden := Sprite2D.new()
	garden.texture = PixelArt.garden_texture()
	garden.centered = false
	garden.offset = Vector2(-32, -16)
	garden.scale = Vector2(PixelArt.PX, PixelArt.PX)
	garden.z_index = 3
	group.add_child(garden)


func _build_fences() -> void:
	# Decorative boundary with gates aligned to the paths. Each run is one
	# editable group so players can reposition the fence without moving it
	# segment-by-segment.
	_add_fence_horizontal("fence_south", 18.5, 45.2, 29.8, [Vector2(22.5, 30.5)])
	_add_fence_horizontal("fence_north", 18.5, 45.2, 13.8, [Vector2(22.0, 26.0), Vector2(40.5, 45.3)])
	_add_fence_vertical("fence_west", 18.5, 14.5, 29.0, [Vector2(21.0, 24.0)])
	_add_fence_vertical("fence_east", 45.4, 14.5, 29.0, [Vector2(19.0, 22.5)])


func _add_fence_horizontal(id: String, x0: float, x1: float, y: float, gaps: Array[Vector2]) -> void:
	var centre := Vector2((x0 + x1) * 0.5, y)
	var group := SettlementPlaceable.new()
	group.name = id.capitalize()
	group.placeable_id = id
	group.category = "fence"
	group.selection_size = Vector2(x1 - x0, 1.5)
	group.position = GameState.placeable_position(id, centre)
	add_child(group)
	_placeables.append(group)
	var x := x0
	while x < x1:
		var skip := false
		for gap in gaps:
			if x >= gap.x and x <= gap.y:
				skip = true
		if not skip:
			var fence := Sprite2D.new()
			fence.texture = PixelArt.fence_texture()
			fence.centered = false
			fence.offset = Vector2(-24, -32)
			fence.scale = Vector2(PixelArt.PX, PixelArt.PX)
			fence.position = Vector2(x - centre.x, 0)
			fence.z_index = 4
			group.add_child(fence)
		x += 1.55


func _add_fence_vertical(id: String, x: float, y0: float, y1: float, gaps: Array[Vector2]) -> void:
	var centre := Vector2(x, (y0 + y1) * 0.5)
	var group := SettlementPlaceable.new()
	group.name = id.capitalize()
	group.placeable_id = id
	group.category = "fence"
	group.selection_size = Vector2(1.5, y1 - y0)
	group.position = GameState.placeable_position(id, centre)
	add_child(group)
	_placeables.append(group)
	var y := y0
	while y < y1:
		var skip := false
		for gap in gaps:
			if y >= gap.x and y <= gap.y:
				skip = true
		if not skip:
			var fence := Sprite2D.new()
			fence.texture = PixelArt.fence_texture()
			fence.centered = true
			fence.scale = Vector2(PixelArt.PX, PixelArt.PX)
			fence.rotation = PI * 0.5
			fence.position = Vector2(0, y - centre.y)
			fence.z_index = 4
			group.add_child(fence)
		y += 1.55


func _add_animal(kind: String, at: Vector2, animal_scale: float = 1.25) -> void:
	var animal := Sprite2D.new()
	animal.name = kind.capitalize()
	animal.texture = PixelArt.animal_texture(kind)
	animal.scale = Vector2(PixelArt.PX, PixelArt.PX) * animal_scale
	animal.position = at
	animal.z_index = 6
	animal.add_to_group("animals")
	if kind == "horse":
		animal.add_to_group("horses")
	add_child(animal)
	var tween := animal.create_tween().set_loops()
	tween.tween_property(animal, "position:y", at.y - 0.08, 0.8).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(animal, "position:y", at.y, 0.8).set_ease(Tween.EASE_IN_OUT)


func _add_resident(resident_name: String, role: String, activity: String, start: Vector2, points: Array, shelter: Vector2, combat: bool = false, damage: int = 8, distance: float = 4.2, shopper: bool = false) -> void:
	var resident := Resident.new()
	resident.resident_name = resident_name
	resident.role = role
	resident.activity = activity
	resident.position = start
	resident.shelter = shelter
	resident.combat_enabled = combat
	resident.combat_damage = damage
	resident.combat_range = distance
	resident.shops_at_waypoints = shopper
	var typed_points: Array[Vector2] = []
	for p in points:
		typed_points.append(p)
	resident.waypoints = typed_points
	add_child(resident)
	_residents.append(resident)


# ------------------------------------------------------------------ coast guard & rubbish

func _build_coastal_system() -> void:
	_coastal_guard = CoastalGuard.new()
	_coastal_guard.name = "CoastalGuard"
	_coastal_guard.position = Vector2(11.2, 27.0)
	add_child(_coastal_guard)
	_rubbish_system = RubbishSystem.new()
	_rubbish_system.name = "RubbishSystem"
	_rubbish_system.guard = _coastal_guard
	add_child(_rubbish_system)


# ------------------------------------------------------------------ recovery / emergency

func _build_recovery_ward() -> void:
	_recovery_ward = RecoveryWard.new()
	_recovery_ward.name = "RecoveryWard"
	_recovery_ward.position = _recovery_center
	_recovery_ward.radius = RECOVERY_RADIUS
	add_child(_recovery_ward)


var _wind_push_timer := 0.0
var _leaf_timer := 1.4
var _ward_mote_timer := 0.0


func _process(delta: float) -> void:
	if GameState.recovery_active() and is_instance_valid(player):
		_tick_recovery(delta)
	if _emergency_fire and _emergency_fire.visible:
		_emergency_fire.modulate.a = 0.65 + sin(Time.get_ticks_msec() * 0.009) * 0.25
	if _emergency_wall_toast > 0.0:
		_emergency_wall_toast = maxf(0.0, _emergency_wall_toast - delta)
	if GameSettings.effects_at_least("med") and not GameSettings.reduce_motion():
		_update_ambient(delta)


func _tick_recovery(delta: float) -> void:
	if not GameState.recovery_active():
		if _recovery_ward:
			_recovery_ward.set_active(false)
		return
	if _recovery_ward:
		_recovery_ward.set_active(true)
	var distance := player.global_position.distance_to(_recovery_center)
	if distance > RECOVERY_RADIUS:
		var direction := (player.global_position - _recovery_center).normalized()
		player.global_position = _recovery_center + direction * RECOVERY_RADIUS
		if _emergency_wall_toast <= 0.0:
			_emergency_wall_toast = 3.0
			GameState.toast_requested.emit("The recovery ward holds you until your health is fully restored.", "info")
	# One clock everywhere: the ward heals at the HouseDB rate for the current
	# cottage level (GameState.sleep_recovery_seconds), matching the bed and the
	# Construction Shop panel instead of a local hardcoded constant.
	_recovery_heal_accum += float(GameState.health_max()) / GameState.sleep_recovery_seconds() * delta
	var heal_amount := int(floor(_recovery_heal_accum))
	if heal_amount > 0:
		_recovery_heal_accum -= float(heal_amount)
		GameState.heal(heal_amount)
	if GameState.health() >= GameState.health_max():
		_recovery_heal_accum = 0.0
		_recovery_ward.set_active(false)
		GameState.finish_recovery()


func _on_emergency_changed(active: bool, remaining: int, damage: int) -> void:
	if active:
		# Raid presentation: a rumble and an ominous halo over the village.
		if camera:
			camera.shake(0.1, 0.5)
		Vfx.ring(Vector2(30.0, 22.0), 5.5, Color(0.9, 0.35, 0.3, 0.5), 0.8)
	if active:
		_spawn_emergency_monsters(remaining)
	else:
		_clear_emergency_monsters()
	_apply_emergency_damage(damage)
	for resident in _residents:
		if is_instance_valid(resident):
			resident.set_process(true)


func _spawn_emergency_monsters(count: int) -> void:
	if _emergency_monsters.size() > 0:
		return
	var spots := [
		Vector2(12.2, 25.8),   # sea approach
		Vector2(16.2, 29.0),   # beach approach
		Vector2(46.8, 25.2),   # forest approach
		Vector2(45.8, 18.0),   # forest trail
		Vector2(24.0, 24.2),
		Vector2(41.5, 23.4),
	]
	for i in maxi(1, count):
		var p: Vector2 = spots[i % spots.size()]
		var monster := Enemy.new()
		monster.kind = "raider"
		monster.settlement_mode = true
		monster.max_hp = 60
		monster.damage = 9
		monster.speed = 1.75
		monster.xp_reward = 10
		monster.gold_reward = 12
		monster.diamond_chance = 0.0
		monster.body_radius = 0.42
		monster.position = p + Vector2(_rng.randf_range(-0.7, 0.7), 0.0)
		add_child(monster)
		_emergency_monsters.append(monster)
	# A raid also drives more woodland monsters into the tree line. They attack
	# trees with impact effects but do not count toward the emergency kill quota.
	var live_forest := 0
	for monster in _forest_monsters:
		if is_instance_valid(monster):
			live_forest += 1
	if live_forest < 16:
		_spawn_forest_monsters(mini(4, 16 - live_forest))


func _clear_emergency_monsters() -> void:
	for monster in _emergency_monsters:
		if is_instance_valid(monster):
			monster.queue_free()
	_emergency_monsters.clear()


func _apply_emergency_damage(damage: int) -> void:
	var severity := clampf(float(damage) / 100.0, 0.0, 0.55)
	if house_sprite:
		house_sprite.modulate = Color(1.0 - severity * 0.4, 1.0 - severity * 0.3, 1.0 - severity * 0.3)
	for stall in _shop_stalls:
		if is_instance_valid(stall):
			stall.modulate = Color(1.0 - severity * 0.35, 1.0 - severity * 0.25, 1.0 - severity * 0.25)
	if _emergency_fire:
		_emergency_fire.visible = damage > 0 and GameState.emergency_active()
	if damage <= 0 and house_sprite:
		house_sprite.modulate = Color.WHITE


func _build_settlement_editor() -> void:
	_settlement_editor = SettlementEditor.new()
	_settlement_editor.name = "SettlementEditor"
	_settlement_editor.building_area = Rect2(18.2, 13.0, 27.4, 17.4)
	add_child(_settlement_editor)
	for placeable in _placeables:
		_settlement_editor.register(placeable)


func toggle_build_mode() -> bool:
	if _settlement_editor == null:
		return false
	return _settlement_editor.toggle()


# ------------------------------------------------------------------ API for HUD / Game

func get_guidance_targets() -> Array:
	var targets: Array = []
	if GameState.emergency_active() and not _emergency_monsters.is_empty():
		var raider := _emergency_monsters[0]
		if is_instance_valid(raider):
			targets.append({"label": "DEFEND", "position": raider.global_position, "color": Color("#e15b58")})
	var monster_pending := false
	for portal_id in PortalDB.ordered_ids():
		if not bool(GameState.portal_state(portal_id).get("cleared", false)):
			monster_pending = true
			break
	if monster_pending:
		targets.append({"label": "MONSTER", "position": MONSTER_GATE, "color": Color("#b08cff")})
	if not bool(GameState.pet_battle_state("pet_duel_1").get("cleared", false)):
		targets.append({"label": "PET DUEL", "position": PET_GATE, "color": Color("#5bd6cf")})
	if GameState.house_level() < HouseDB.max_level():
		targets.append({"label": "BUILD", "position": CONSTRUCTION_SHOP, "color": Color("#f2c45a")})
	if targets.is_empty():
		targets.append({"label": "FOREST", "position": Vector2(51.0, 21.0), "color": Color("#8ac36b")})
		targets.append({"label": "GUARD", "position": Vector2(11.2, 27.0), "color": Color("#8fe8f7")})
	return targets.slice(0, 3)


func get_map_rect() -> Rect2:
	return MAP_RECT


func minimap_base_color() -> Color:
	return Color("#2e4b32")


func minimap_markers() -> Array:
	return _markers.duplicate()


func get_spawn_position() -> Vector2:
	return _player_spawn


func get_player() -> Player:
	return player


func refresh_house() -> void:
	if house_sprite:
		house_sprite.texture = PixelArt.house_texture(GameState.house_level())
