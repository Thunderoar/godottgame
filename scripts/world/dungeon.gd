class_name Dungeon
extends Node2D
## One reusable dark dungeon. PortalDB controls the monster count, boss stats,
## theme, level requirement and rewards; this scene builds whichever portal the
## player entered. Every visit is a fresh instance, so an unfinished portal is
## naturally reset after defeat.

const SPAWN := Vector2(24.0, 28.0)

var portal_id := "tidebound_grotto"
var zone_name := "Tidebound Grotto"
var map_rect := Rect2(0, 0, 48, 32)
var player: Player
var pet: Pet
var camera: FollowCamera
var boss: Enemy
var canvas_modulate: CanvasModulate
var background: Sprite2D

var _definition: Dictionary = {}
var _markers: Array[Dictionary] = []
var _boss_defeated := false
var _rng := RandomNumberGenerator.new()


func setup(id: String) -> void:
	portal_id = id
	var def := PortalDB.get_portal(portal_id)
	zone_name = str(def.get("name", "Portal"))
	_definition = def


func _ready() -> void:
	add_to_group("world")
	add_to_group("dungeon")
	y_sort_enabled = true
	if _definition.is_empty():
		setup(str(GameState.expedition_portal()) if GameState.expedition_portal() != "" else "tidebound_grotto")
	_rng.seed = 9941 + portal_id.hash()
	_build_lighting()
	_build_ground()
	_build_bounds()
	_build_decor()
	_build_player_and_pet()
	_build_monsters()
	_build_exit()
	_build_camera()
	GameState.player_defeated.connect(_on_player_defeated)
	GameState.boss_health_changed.connect(_on_boss_health_changed)
	GameState.toast_requested.emit("%s Your companion fights beside you." % str(_definition.get("lore", "Darkness closes in.")), "info")


# ------------------------------------------------------------------ building

func _build_lighting() -> void:
	canvas_modulate = CanvasModulate.new()
	canvas_modulate.name = "DungeonDarkness"
	# Dungeons remain moody, but no longer depend on a pet light. Torches plus
	# this ambient tint keep navigation readable without the companion.
	canvas_modulate.color = Color("#737b90") if str(_definition.get("theme", "grotto")) == "grotto" else Color("#6d7a8f")
	add_child(canvas_modulate)


func _build_ground() -> void:
	background = Sprite2D.new()
	background.name = "DungeonGround"
	background.texture = _make_dungeon_texture()
	background.centered = false
	background.scale = Vector2(PixelArt.PX, PixelArt.PX)
	background.z_as_relative = false
	background.z_index = -1000
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(background)


func _make_dungeon_texture() -> Texture2D:
	var key := "dungeon_%s" % portal_id
	if PixelArt.CACHE.has(key):
		return PixelArt.CACHE[key]
	var w := int(map_rect.size.x * 32.0)
	var h := int(map_rect.size.y * 32.0)
	var img := PixelArt.image(w, h)
	var stone_tex := load("res://assets/textures/TX Tileset Stone Ground.png") as Texture2D
	var src := stone_tex.get_image()
	var origins := [
		Vector2i(0, 0), Vector2i(32, 0), Vector2i(64, 0),
		Vector2i(0, 32), Vector2i(32, 32), Vector2i(64, 32),
		Vector2i(0, 64), Vector2i(32, 64), Vector2i(64, 64),
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 8812 + portal_id.hash()
	for gy in int(map_rect.size.y):
		for gx in int(map_rect.size.x):
			var tile: Vector2i = origins[rng.randi_range(0, origins.size() - 1)]
			img.blit_rect(src, Rect2i(tile, Vector2i(32, 32)), Vector2i(gx * 32, gy * 32))
	# Darken and tint the floor into a cold dungeon palette.
	for y in range(0, h, 4):
		for x in range(0, w, 4):
			var c := img.get_pixel(x, y)
			var tint := Color("#42515a") if portal_id == "tidebound_grotto" else Color("#3a4b55")
			c = c.lerp(tint, 0.28)
			img.fill_rect(Rect2i(x, y, 4, 4), c)
	# Border walls.
	for edge in 3:
		var depth := 56
		if edge == 0:
			img.fill_rect(Rect2i(0, 0, w, depth), Color("#20262b"))
			img.fill_rect(Rect2i(0, depth - 12, w, 12), Color("#101518"))
		elif edge == 1:
			img.fill_rect(Rect2i(0, h - depth, w, depth), Color("#20262b"))
			img.fill_rect(Rect2i(0, h - depth, w, 12), Color("#101518"))
		elif edge == 2:
			img.fill_rect(Rect2i(0, 0, depth, h), Color("#20262b"))
			img.fill_rect(Rect2i(0, 0, depth, h), Color("#151b1e"))
	# Right wall.
	img.fill_rect(Rect2i(w - 56, 0, 56, h), Color("#20262b"))
	# Cracks and water stains.
	for i in 70:
		var x := rng.randi_range(60, w - 60)
		var y := rng.randi_range(60, h - 60)
		var n := rng.randi_range(4, 18)
		for j in n:
			if x + j * 2 < w - 4 and y + int(sin(j * 0.7) * 2) < h - 4:
				img.set_pixel(x + j * 2, y + int(sin(j * 0.7) * 2), Color("#2d3440"))
	# Puddles.
	for i in 14:
		var p := Vector2(rng.randi_range(100, w - 100), rng.randi_range(90, h - 100))
		_blend_ellipse(img, int(p.x), int(p.y), rng.randi_range(14, 42), rng.randi_range(5, 14), Color("#2d5863"), 0.5)
	# Glowing spores.
	for i in 90:
		var x := rng.randi_range(70, w - 70)
		var y := rng.randi_range(70, h - 70)
		var col := Color("#5fbcb3") if i % 4 else Color("#9a79c9")
		img.set_pixel(x, y, col)
		if i % 9 == 0:
			img.set_pixel(x + 1, y + 1, col.darkened(0.25))
	var tex := ImageTexture.create_from_image(img)
	PixelArt.CACHE[key] = tex
	return tex


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


func _build_bounds() -> void:
	var walls := StaticBody2D.new()
	walls.name = "DungeonBounds"
	walls.collision_layer = 1
	add_child(walls)
	_add_box(walls, Vector2(24, 1.0), Vector2(48, 1.6))
	_add_box(walls, Vector2(24, 31.0), Vector2(48, 1.6))
	_add_box(walls, Vector2(0.8, 16), Vector2(1.6, 32))
	_add_box(walls, Vector2(47.2, 16), Vector2(1.6, 32))
	# Pillars break up line of sight and give the arena a shape.
	for p in [Vector2(10, 20), Vector2(38, 20), Vector2(10, 10), Vector2(38, 10), Vector2(16, 15), Vector2(32, 15)]:
		_add_pillar(p)


func _add_box(body: StaticBody2D, at: Vector2, size: Vector2) -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = at
	body.add_child(shape)


func _add_pillar(at: Vector2) -> void:
	var holder := Node2D.new()
	holder.name = "Pillar"
	holder.position = at
	add_child(holder)
	var art := Sprite2D.new()
	art.texture = load("res://assets/sprites/TX Props__TX Props Pillar.tres")
	art.centered = false
	var sz := art.texture.get_size()
	art.offset = Vector2(-sz.x * 0.5, -sz.y)
	art.scale = Vector2(PixelArt.PX, PixelArt.PX) * 1.3
	art.modulate = Color(0.72, 0.78, 0.8)
	holder.add_child(art)
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 0.55
	shape.shape = circle
	shape.position = Vector2(0, -0.3)
	body.add_child(shape)
	holder.add_child(body)


func _build_decor() -> void:
	var skulls := [
		"res://assets/sprites/TX Props__TX Props Gravestone A.tres",
		"res://assets/sprites/TX Props__TX Props Gravestone B.tres",
	]
	for i in 10:
		var x := _rng.randf_range(3.5, 44.5)
		var y := _rng.randf_range(3.5, 29.0)
		if Vector2(x, y).distance_to(Vector2(24, 7)) < 4.0 or Vector2(x, y).distance_to(SPAWN) < 3.0:
			continue
		var sprite := Sprite2D.new()
		sprite.texture = load(skulls[i % skulls.size()])
		sprite.centered = false
		var sz := sprite.texture.get_size()
		sprite.offset = Vector2(-sz.x * 0.5, -sz.y)
		sprite.scale = Vector2(PixelArt.PX, PixelArt.PX)
		sprite.position = Vector2(x, y)
		sprite.modulate = Color(0.55, 0.62, 0.66)
		add_child(sprite)
	# Torch lights keep the dungeon readable without a pet light.
	for p in [Vector2(6, 5), Vector2(42, 5), Vector2(6, 24), Vector2(42, 24)]:
		var lamp := PointLight2D.new()
		lamp.texture = PixelArt.light_texture()
		lamp.texture_scale = 0.45
		lamp.energy = 0.33
		lamp.color = Color("#63c7c6") if portal_id == "tidebound_grotto" else Color("#9d77d8")
		lamp.position = p
		add_child(lamp)
		var fixture := Sprite2D.new()
		fixture.texture = PixelArt.icon("portal")
		fixture.scale = Vector2(0.045, 0.045)
		fixture.position = p
		fixture.modulate = lamp.color
		add_child(fixture)
	# Boss warning haze.
	var boss_glow := PointLight2D.new()
	boss_glow.texture = PixelArt.light_texture()
	boss_glow.texture_scale = 1.2
	boss_glow.energy = 0.26
	boss_glow.color = Color("#a06fdd") if portal_id == "tidebound_grotto" else Color("#5bd6c8")
	boss_glow.position = Vector2(24, 7)
	add_child(boss_glow)


func _build_player_and_pet() -> void:
	player = Player.new()
	player.name = "Player"
	player.position = SPAWN
	add_child(player)
	pet = Pet.new()
	pet.name = "Pet"
	pet.player = player
	pet.position = SPAWN + Vector2(-1, 0.6)
	add_child(pet)
	player.hurt_flash.connect(func() -> void:
		if camera:
			camera.shake(0.18, 0.24))


func _build_monsters() -> void:
	var count := maxi(10, int(_definition.get("monster_count", 12)))
	var level := int(_definition.get("monster_level", 1))
	var kind := str(_definition.get("monster_kind", "bogling"))
	var spots: Array[Vector2] = [
		Vector2(9, 24), Vector2(16, 21), Vector2(34, 24), Vector2(39, 21),
		Vector2(13, 16), Vector2(34, 16), Vector2(20, 12), Vector2(28, 12),
		Vector2(9, 9), Vector2(17, 8), Vector2(31, 8), Vector2(40, 9),
		Vector2(23, 18), Vector2(25, 22),
	]
	for i in count:
		var p := spots[i % spots.size()]
		if i >= spots.size():
			p += Vector2(_rng.randf_range(-2.0, 2.0), _rng.randf_range(-2.0, 2.0))
		var enemy := Enemy.new()
		enemy.kind = kind
		enemy.monster_level = level
		enemy.max_hp = 38 + level * 12 + i * 2
		enemy.damage = 7 + level * 2
		enemy.speed = 1.65 + level * 0.12
		enemy.xp_reward = 14 + level * 5
		enemy.gold_reward = 7 + level * 3
		enemy.diamond_chance = 0.09 + level * 0.01
		enemy.position = p
		add_child(enemy)
	# Exactly one boss.
	var boss_def := PortalDB.get_portal(portal_id)
	boss = Enemy.new()
	boss.name = "Boss"
	boss.kind = str(boss_def.get("boss_id", "grotto_warden"))
	boss.is_boss = true
	boss.monster_level = level + 2
	boss.max_hp = int(boss_def.get("boss_hp", 420))
	boss.damage = int(boss_def.get("boss_damage", 18))
	boss.speed = float(boss_def.get("boss_speed", 1.7))
	boss.boss_ability = str(boss_def.get("boss_ability", "punch"))
	boss.boss_ability_name = str(boss_def.get("boss_ability_name", "Heavy Strike"))
	boss.special_damage = int(boss_def.get("boss_damage", 18))
	boss.special_cooldown = float(boss_def.get("boss_special_cooldown", 3.8))
	boss.projectile_damage = int(boss_def.get("boss_projectile_damage", 12))
	boss.body_radius = 1.0
	boss.gold_reward = 0
	boss.diamond_chance = 0.0
	boss.position = Vector2(24, 7)
	boss.boss_finished.connect(_on_boss_finished)
	add_child(boss)
	_markers.append({"position": Vector2(24, 7), "color": Color("#d75a58"), "size": 5.0, "shape": "disc"})


func _build_exit() -> void:
	var exit := PortalExit.new()
	exit.name = "ShoreGate"
	exit.position = Vector2(24, 30.1)
	add_child(exit)
	_markers.append({"position": exit.position, "color": Color("#8fe8f7"), "size": 4.0, "shape": "arch"})


func _build_camera() -> void:
	camera = FollowCamera.new()
	camera.name = "Camera"
	camera.target = player
	camera.bounds = map_rect
	camera.global_position = SPAWN
	add_child(camera)


# ------------------------------------------------------------------ outcomes

func _on_boss_finished(_enemy: Enemy) -> void:
	if _boss_defeated:
		return
	_boss_defeated = true
	player.controls_locked = true
	var summary := GameState.complete_portal(portal_id)
	var game := get_tree().get_first_node_in_group("game")
	if game != null and game.has_method("show_victory"):
		game.call("show_victory", summary, portal_id)


func exit_to_lobby(bank_loot: bool) -> void:
	if bank_loot:
		GameState.leave_portal_safely()
	var game := get_tree().get_first_node_in_group("game")
	if game != null and game.has_method("return_to_lobby"):
		game.call("return_to_lobby", false)


func _on_player_defeated() -> void:
	if not GameState.expedition_active():
		return
	player.controls_locked = true
	player.die()
	GameState.boss_health_changed.emit(false, "", 0, 0)
	var game := get_tree().get_first_node_in_group("game")
	if game != null and game.has_method("handle_portal_defeat"):
		game.call("handle_portal_defeat")


func _on_boss_health_changed(active: bool, name: String, value: int, maximum: int) -> void:
	if active and _boss_defeated:
		GameState.boss_health_changed.emit(false, name, 0, 0)


# ------------------------------------------------------------------ API

func get_guidance_targets() -> Array:
	if is_instance_valid(boss) and not bool(boss.dead):
		return [{"label": "BOSS", "position": boss.global_position, "color": Color("#e15b58")}]
	return [{"label": "SHORE GATE", "position": Vector2(24, 30.1), "color": Color("#8fe8f7")}]


func get_map_rect() -> Rect2:
	return map_rect


func minimap_base_color() -> Color:
	return Color("#22333d") if portal_id == "tidebound_grotto" else Color("#202f3b")


func minimap_markers() -> Array:
	return _markers.duplicate()


func get_spawn_position() -> Vector2:
	return SPAWN
