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
	var guide := MissionPath.new()
	add_child(guide)
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
	call_deferred("alert_intruders")
	Vfx.ensure_pool(self)
	Shaders.apply_default_breeze()
	GameState.player_defeated.connect(_on_player_defeated)
	GameState.boss_health_changed.connect(_on_boss_health_changed)
	GameState.toast_requested.emit("%s Your companion fights beside you." % str(_definition.get("lore", "Darkness closes in.")), "info")


# ------------------------------------------------------------------ building

func _theme() -> String:
	return str(_definition.get("theme", "grotto"))


func _build_lighting() -> void:
	canvas_modulate = CanvasModulate.new()
	canvas_modulate.name = "DungeonDarkness"
	# Moody but readable: each theme tints the whole canvas differently.
	var ambient := {
		"grotto": Color("#7d84a0"), "crypt": Color("#7f96a8"), "reef": Color("#a08a80"),
		"brine": Color("#84a094"), "kelp": Color("#7ca07e"), "bone": Color("#a89f8c"),
		"storm": Color("#7e88ac"), "coral": Color("#a0868e"), "abyss": Color("#6e6e94"),
		"throne": Color("#a09a84"),
	}.get(_theme(), Color("#7d84a0")) as Color
	canvas_modulate.color = ambient.lightened(0.18)
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
	# One coherent floor per dungeon: a single base tile blitted everywhere
	# (no random per-cell tile soup -> no visible grid maze), sparse accent
	# tiles, smooth large-scale shading, and real wall faces with depth. The
	# per-theme palette comes from PixelArt.portal_theme_palette.
	var key := "dungeon_v2_%s" % portal_id
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
	var palette := PixelArt.portal_theme_palette(_theme())
	# A deterministic base tile keeps the floor seamless; accents stay rare.
	var base: Vector2i = origins[(portal_id.hash() + 3) % origins.size()]
	var accent: Vector2i = origins[(portal_id.hash() + 7) % origins.size()]
	for gy in int(map_rect.size.y):
		for gx in int(map_rect.size.x):
			var tile := base
			if rng.randf() < 0.06:
				tile = accent
			img.blit_rect(src, Rect2i(tile, Vector2i(32, 32)), Vector2i(gx * 32, gy * 32))
	# Smooth, large-scale light variation instead of per-block tinting. Kept
	# very soft so it never reads as circular smudges on the floor.
	var glow: Color = palette["glow"]
	for i in 6:
		var c := Vector2(rng.randf_range(90, w - 90), rng.randf_range(130, h - 130))
		var col: Color = glow.darkened(0.55) if i % 2 == 0 else Color("#2d3440")
		_blend_ellipse(img, int(c.x), int(c.y), rng.randi_range(90, 170), rng.randi_range(60, 120), col, 0.05)
	# Wall band with a brick face, inner shadow and a walkable lip.
	var wall := Color("#20262b").lerp(glow.darkened(0.72), 0.25)
	var wall_face := Color("#39424b").lerp(glow.darkened(0.6), 0.2)
	var depth := 44
	# Top wall (tall face).
	img.fill_rect(Rect2i(0, 0, w, depth), wall)
	for y in range(8, depth - 8, 10):
		for x in range(0 + ((y / 10) % 2) * 12, w, 24):
			img.fill_rect(Rect2i(x + 1, y + 1, 21, 8), wall_face)
	img.fill_rect(Rect2i(0, depth, w, 6), Color("#10151a"))
	# Bottom wall (short face so the play area stays readable).
	img.fill_rect(Rect2i(0, h - depth + 18, w, depth - 18), wall)
	img.fill_rect(Rect2i(0, h - depth + 18, w, 5), Color("#0d1216"))
	# Left and right walls.
	img.fill_rect(Rect2i(0, 0, depth - 12, h), wall)
	img.fill_rect(Rect2i(w - depth + 12, 0, depth - 12, h), wall)
	for y in range(0, h, 12):
		img.fill_rect(Rect2i(2, y + 1, depth - 18, 9), wall_face)
		img.fill_rect(Rect2i(w - depth + 16, y + 1, depth - 18, 9), wall_face)
	img.fill_rect(Rect2i(depth - 12, 0, 5, h), Color("#0d1216"))
	img.fill_rect(Rect2i(w - depth + 8, 0, 5, h), Color("#0d1216"))
	# Cracks (sparse, away from walls).
	for i in 26:
		var x := rng.randi_range(depth, w - depth)
		var y := rng.randi_range(depth + 10, h - depth)
		var n := rng.randi_range(4, 14)
		for j in n:
			if x + j * 2 < w - 8 and y + int(sin(j * 0.7) * 2) < h - 8:
				img.set_pixel(x + j * 2, y + int(sin(j * 0.7) * 2), Color("#2b323e"))
	# Theme-tinted puddles / sheen.
	var puddle := glow.darkened(0.35)
	for i in 10:
		var pt := Vector2(rng.randi_range(90, w - 90), rng.randi_range(100, h - 100))
		_blend_ellipse(img, int(pt.x), int(pt.y), rng.randi_range(14, 40), rng.randi_range(5, 12), puddle, 0.35)
	# Glowing spores in the theme mote colour.
	var mote: Color = palette["mote"]
	for i in 70:
		var x := rng.randi_range(60, w - 60)
		var y := rng.randi_range(60, h - 60)
		img.set_pixel(x, y, mote)
		if i % 9 == 0:
			img.set_pixel(x + 1, y + 1, mote.darkened(0.25))
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


var _flicker_lamps: Array[PointLight2D] = []
var _ambient: CPUParticles2D
var _flicker_time := 0.0


func _build_decor() -> void:
	var palette := PixelArt.portal_theme_palette(_theme())
	var glow: Color = palette["glow"]
	var theme := _theme()
	# Base prop set: gravestones read as bone piles under a bone tint, the
	# plant sprites become kelp / coral growths, road signs become storm rods.
	var prop_pool: Array = {
		"bone": [
			"res://assets/sprites/TX Props__TX Props Gravestone A.tres",
			"res://assets/sprites/TX Props__TX Props Gravestone B.tres",
			"res://assets/sprites/TX Props__TX Props - Stone 02.tres",
		],
		"kelp": [
			"res://assets/sprites/TX Plant__TX Plant - Grass 05.tres",
			"res://assets/sprites/TX Plant__TX Plant - Grass 09.tres",
			"res://assets/sprites/TX Plant__TX Bush T2.tres",
		],
	}.get(theme, [
		"res://assets/sprites/TX Props__TX Props Gravestone A.tres",
		"res://assets/sprites/TX Props__TX Props Gravestone B.tres",
	])
	var prop_count := 14
	for i in prop_count:
		var x := _rng.randf_range(3.5, 44.5)
		var y := _rng.randf_range(3.5, 29.0)
		if Vector2(x, y).distance_to(Vector2(24, 7)) < 4.0 or Vector2(x, y).distance_to(SPAWN) < 3.0:
			continue
		var sprite := Sprite2D.new()
		sprite.texture = load(str(prop_pool[i % prop_pool.size()]))
		sprite.centered = false
		var sz := sprite.texture.get_size()
		sprite.offset = Vector2(-sz.x * 0.5, -sz.y)
		sprite.scale = Vector2(PixelArt.PX, PixelArt.PX) * (1.0 if theme != "kelp" else 1.3)
		sprite.position = Vector2(x, y)
		sprite.modulate = glow.darkened(0.15).lerp(Color(0.55, 0.62, 0.66), 0.4)
		if theme in ["kelp", "reef", "coral"]:
			# Growth clusters get the theme hue so biomes read at a glance.
			sprite.modulate = glow.lerp(Color(0.5, 0.65, 0.5), 0.35)
		add_child(sprite)
	# Torch lights keep the dungeon readable; each flickers independently.
	for p in [Vector2(6, 5), Vector2(42, 5), Vector2(6, 24), Vector2(42, 24)]:
		var lamp := PointLight2D.new()
		lamp.texture = PixelArt.light_texture()
		lamp.texture_scale = 0.034
		lamp.energy = 0.33
		lamp.color = glow.lightened(0.1)
		lamp.position = p
		add_child(lamp)
		_flicker_lamps.append(lamp)
		var fixture := Sprite2D.new()
		fixture.texture = PixelArt.icon("portal")
		fixture.scale = Vector2(0.045, 0.045)
		fixture.position = p
		fixture.modulate = lamp.color
		add_child(fixture)
	# Boss warning haze (kept: it doubles as the arena's mood light).
	var boss_glow := PointLight2D.new()
	boss_glow.texture = PixelArt.light_texture()
	boss_glow.texture_scale = 0.09
	boss_glow.energy = 0.26
	boss_glow.color = glow
	boss_glow.position = Vector2(24, 7)
	add_child(boss_glow)
	# Boss arena identity: theme emblem on the floor + brazier ring (sprite
	# only; the light budget stays at the existing count).
	var emblem := Sprite2D.new()
	emblem.texture = PixelArt.portal_emblem_texture(theme)
	emblem.scale = Vector2(PixelArt.PX * 1.5, PixelArt.PX * 1.5)
	emblem.position = Vector2(24, 7.4)
	emblem.modulate = Color(glow.r, glow.g, glow.b, 0.55)
	emblem.z_index = 1
	add_child(emblem)
	for i in 6:
		var a := TAU * float(i) / 6.0
		var brazier := Sprite2D.new()
		brazier.texture = PixelArt.mote_texture()
		brazier.scale = Vector2(0.05, 0.05)
		brazier.position = Vector2(24 + cos(a) * 4.2, 7.4 + sin(a) * 2.0)
		brazier.modulate = glow.lightened(0.2)
		brazier.z_index = 2
		add_child(brazier)
	set_process(true)


func _build_ambient() -> void:
	var glow: Color = PixelArt.portal_theme_palette(_theme())["glow"]
	# Created lazily so low -> high applies without re-entering the world.
	if _ambient == null:
		_ambient = CPUParticles2D.new()
		_ambient.amount = 6
		_ambient.lifetime = 4.0
		_ambient.preprocess = 2.0
		_ambient.texture = PixelArt.mote_texture()
		_ambient.scale_amount_min = 0.025
		_ambient.scale_amount_max = 0.04
		_ambient.color = Color(glow.r, glow.g, glow.b, 0.35)
		_ambient.direction = Vector2(0.3, -1)
		_ambient.spread = 180.0
		_ambient.gravity = Vector2.ZERO
		_ambient.initial_velocity_min = 1.0
		_ambient.initial_velocity_max = 3.0
		_ambient.position = Vector2(24, 16)
		_ambient.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		_ambient.emission_rect_extents = Vector2(22, 14)
		add_child(_ambient)


func _process(_delta: float) -> void:
	var ambient_enabled := GameSettings.effects_at_least("high") and not GameSettings.reduce_motion()
	if ambient_enabled and _ambient == null:
		_build_ambient()
	if _ambient:
		_ambient.visible = ambient_enabled
		_ambient.emitting = GameSettings.effects_at_least("high") and not GameSettings.reduce_motion()
	# Independent torch flicker: cheap sine mix, no RNG churn.
	_flicker_time += _delta
	for i in _flicker_lamps.size():
		var lamp := _flicker_lamps[i]
		if lamp != null and is_instance_valid(lamp):
			lamp.energy = 0.22 + (absf(sin(_flicker_time * (2.0 + float(i) * 0.3))) * 0.025 if not GameSettings.reduce_motion() else 0.0)


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
			camera.shake(0.18, 0.24)
		var hud := get_tree().get_first_node_in_group("hud")
		if hud != null and hud.has_method("flash_hurt"):
			hud.call("flash_hurt"))


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
	Sfx.play("portal_out", -8.0)
	# A short surge back into the gate before the return flow takes over.
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if p != null and not GameSettings.reduce_motion():
		var visual: CanvasItem = p.get_node_or_null("Sprite")
		if visual != null:
			var tween := visual.create_tween().set_parallel(true)
			tween.tween_property(visual, "scale", Vector2(PixelArt.PX * 0.25, PixelArt.PX * 0.25), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tween.tween_property(visual, "rotation", -3.0, 0.22)
			tween.tween_property(visual, "modulate:a", 0.15, 0.22)
			await tween.finished
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


func alert_intruders(include_boss: bool = false) -> void:
	if not is_instance_valid(player):
		return
	for enemy in get_children():
		if not enemy is Enemy or enemy.dead or (enemy.is_boss and not include_boss):
			continue
		enemy.dungeon_alerted = true
		enemy._player = player
		enemy._target = player
		enemy.active = true
		enemy._enter(Enemy.State.CHASE)

func _physics_process(_delta: float) -> void:
	if is_instance_valid(boss) and not boss.dead and is_instance_valid(player) and boss.global_position.distance_to(player.global_position) <= boss.body_radius + 0.7:
		alert_intruders(true)


var _monster_routes: ResidentRoutes

func monster_path(from: Vector2, destination: Vector2) -> PackedVector2Array:
	if _monster_routes == null:
		_monster_routes = ResidentRoutes.new(self, map_rect)
	return _monster_routes.path(from, destination)
