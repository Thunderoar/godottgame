class_name Lobby
extends Node2D
## Seaside home hub. Environment art is composed from the original Cainos
## atlas, while the cottage, stalls and portal frames come from PixelArt.

const MAP_RECT := Rect2(0, 0, 64, 40)
const SPAWN := Vector2(34.0, 24.3)
const HOUSE_BASE := Vector2(34.0, 21.4)
const MONSTER_GATE := Vector2(30.8, 11.3)
const PET_GATE := Vector2(37.2, 11.3)
const OCEAN_WIDTH_PIXELS := 806
const CONSTRUCTION_SHOP := Vector2(41.2, 16.2)
const WATER_SHOP := Vector2(32.5, 28.2)
const FIRE_MONSTER_COUNT := 24
const FIRE_MONSTER_LIMIT := 30
const NIGHT_URCHIN_COUNT := 6
const URCHIN_LIMIT := 18
const DAY_GRADE := MonsoonLighting.DAY
const NIGHT_GRADE := MonsoonLighting.NIGHT
var _grade: CanvasModulate
var _phase_tween: Tween
var journey_serial := 0
var _mission_walk_origin := SPAWN
const DEVASTATION_SECONDS := 4.0
var devastation_progress := 0.0
var _devastation_started := false

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
var _resident_routes: ResidentRoutes
var _emergency_monsters: Array[Enemy] = []
var _forest_monsters: Array[Enemy] = []
var _shop_stalls: Array[Sprite2D] = []
var _local_lights: Array[PointLight2D] = []
var _tree_positions: Array[Vector2] = []
var _forest_trees: Array[ForestTree] = []
var _authored_map: AuthoredMap
var _house_positions: Array[Vector2] = []
var _ruin_positions: Array[Vector2] = []
var _tree_serial := 0
var _emergency_fire: Sprite2D
var _emergency_wall_toast := 0.0

const RECOVERY_CENTER := Vector2(34.0, 23.7)
const RECOVERY_RADIUS := 4.3


func _ready() -> void:
	journey_serial = GameState.journey_serial
	add_to_group("world")
	y_sort_enabled = true
	_rng.seed = 7319
	var authored := AuthoredMapRenderer.selected_map()
	_authored_map = authored
	WorldPalette.select_for_map(authored.palette if authored else null)
	_build_background()
	_build_bounds()
	_build_house()
	_build_shops()
	_build_special_npc()
	_build_residential_life()
	_build_portals()
	_build_gathering()
	_build_dock_and_ship()
	_build_forest()
	_build_water_keepers()
	_build_beach_landmarks()
	_build_forest_monsters()
	_build_scatter()
	_build_monsoon_scenery()
	_build_coastal_system()
	_build_recovery_ward()
	_build_settlement_editor()
	if authored:
		for marker in authored.objects:
			if marker.get("kind", "") == "spawn" and marker.get("metadata", {}).get("primary", false) and not GameState.recovery_active():
				_player_spawn = marker.get("position", SPAWN)
	_build_player_and_pet()
	var authored_layer := AuthoredMapRenderer.new()
	authored_layer.name = "AuthoredMap"
	authored_layer.definition = authored
	add_child(authored_layer)
	_build_camera()
	var guide := MissionPath.new()
	add_child(guide)
	call_deferred("_on_data_changed")
	call_deferred("_check_forest_game_over")
	Vfx.ensure_pool(self)
	_on_presentation_changed("")
	GameState.house_changed.connect(_on_house_upgraded)
	GameState.data_changed.connect(_on_data_changed)
	GameState.pet_changed.connect(_on_pet_changed)
	GameState.emergency_changed.connect(_on_emergency_changed)
	GameState.day_phase_changed.connect(_on_day_phase_changed)
	_on_day_phase_changed(GameState.is_night(), true)
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
	background.modulate = Color.WHITE
	add_child(background)
	var grade := CanvasModulate.new()
	grade.name = "DaylightGrade"
	grade.color = Color(1.0, 1.0, 1.0)
	add_child(grade)
	_grade = grade
	_build_water_layer()


func _make_terrain_texture() -> Texture2D:
	return WorldTerrain._make_terrain_texture()


func _coast_pixel_y(x: int) -> int:
	return WorldTerrain._coast_pixel_y(x)


func _build_water_layer() -> void:
	var water := Sprite2D.new()
	water.name = "WaterLayer"
	water.texture = _make_water_mask_texture()
	water.centered = false
	water.scale = Vector2.ONE * PixelArt.PX
	water.z_as_relative = false
	water.z_index = -999
	water.material = Shaders.water_material()
	add_child(water)
	GameSettings.changed.connect(_on_presentation_changed)
	_on_presentation_changed("")


func _make_water_mask_texture() -> Texture2D:
	return PixelArt.cached_texture("water_mask_lobby_v3", func() -> Image:
		var img := PixelArt.image(int(MAP_RECT.size.x / PixelArt.PX), int(MAP_RECT.size.y / PixelArt.PX))
		for x in OCEAN_WIDTH_PIXELS:
			# Painted coast uses two-art-pixel columns. Sample the same column.
			var shore := _coast_pixel_y(x - x % 2)
			for y in range(shore, img.get_height()):
				var depth := clampf(float(y - shore) / 96.0, 0.0, 1.0)
				img.set_pixel(x, y, Color(depth, 0.0, 0.0, 1.0))
		return img)


func _on_presentation_changed(_key: String) -> void:
	if _key not in ["", "effects_quality", "reduce_motion"]:
		return
	for group in ["ambient_smoke", "animals", "ambient_boat"]:
		for node in get_tree().get_nodes_in_group(group):
			if not is_ancestor_of(node) or not node.has_meta("ambient_tween"):
				continue
			var motion: Tween = node.get_meta("ambient_tween")
			var enabled: bool = not GameSettings.reduce_motion() and (group == "animals" or GameSettings.effects_at_least("med" if group == "ambient_boat" else "high"))
			if group == "ambient_smoke":
				node.visible = enabled
			if enabled:
				motion.play()
			else:
				motion.pause()
	_update_daylight()
	var water := get_node_or_null("WaterLayer") as Sprite2D
	if water:
		water.visible = GameSettings.effects_at_least("med") and not GameSettings.reduce_motion()
	Shaders.set_wind(Vector2(1.0, 0.12), 0.45 if GameSettings.effects_at_least("med") and not GameSettings.reduce_motion() else 0.0)
	if not GameSettings.effects_at_least("med") or GameSettings.reduce_motion():
		Shaders.clear_benders()
	var ambient := get_node_or_null("AmbientLife")
	if ambient:
		remove_child(ambient)
		ambient.queue_free()
	if is_node_ready() or is_instance_valid(house_sprite):
		_build_ambient_life()


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
	_ward_mote_timer -= delta
	if _ward_mote_timer <= 0.0 and GameState.recovery_active():
		_ward_mote_timer = 0.7
		Vfx.pop(RECOVERY_CENTER + Vector2(randf_range(-1.6, 1.6), -randf_range(0.4, 2.2)), "heart", Color(0.7, 1.0, 0.85, 0.8))


func _build_ambient_life() -> void:
	# Cloud shadows, pollen, butterflies, forest light shafts, the eastern
	# danger grade and chimney smoke. Everything is a handful of sprites and
	# one capped CPU particle emitter; low quality drops the whole layer.
	if not GameSettings.effects_at_least("high") or GameSettings.reduce_motion() or GameState.house_level() < 3:
		return
	var holder := Node2D.new()
	holder.name = "AmbientLife"
	add_child(holder)
	# Chimney smoke once the cottage has one (level 3+).
	if GameState.house_level() >= 3:
		var smoke := CPUParticles2D.new()
		smoke.amount = 4
		smoke.lifetime = 3.2
		smoke.preprocess = 1.5
		smoke.texture = PixelArt.light_texture()
		smoke.scale_amount_min = 0.003
		smoke.scale_amount_max = 0.007
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
	for x in range(0, OCEAN_WIDTH_PIXELS, 16):
		var shore := float(_coast_pixel_y(x)) * PixelArt.PX + 0.18
		points.append(Vector2(float(x) * PixelArt.PX, minf(40.0, shore)))
		if shore >= 40.0:
			break
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
	house.z_index = 6
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
	_add_window_lights(house_sprite, GameState.house_level())
	house_glow = PointLight2D.new()
	house_glow.texture = PixelArt.light_texture()
	house_glow.texture_scale = 0.052
	house_glow.energy = 0.42
	house_glow.color = Color("#ffc970")
	house_glow.position = Vector2(0.4, -1.7)
	house.add_child(house_glow)
	_local_lights.append(house_glow)
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
	building_target.structure_id = "cottage"
	building_target.max_health = 300
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


func _add_window_lights(art: Sprite2D, level: int) -> void:
	var windows := art.get_node_or_null("WarmWindows") as Sprite2D
	# Independent house replacements retain their own pixels and window layout.
	if AssetRegistry.get_texture("house_%d" % level) != null:
		if windows: windows.visible = false
		return
	if windows == null:
		windows = Sprite2D.new()
		windows.name = "WarmWindows"
		windows.centered = false
		windows.offset = art.offset
		windows.add_to_group("monsoon_windows")
		var unshaded := CanvasItemMaterial.new()
		unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		windows.material = unshaded
		art.add_child(windows)
	windows.visible = true
	windows.texture = PixelArt.cached_texture("monsoon/windows/%d" % level, func() -> Image: return MonsoonArt.house(level, true))
	windows.modulate.a = MonsoonLighting.lantern_strength(float(GameState.data.get("world_time", 0.0))) * 0.85


func _on_house_upgraded(level: int) -> void:
	if house_sprite == null:
		return
	house_sprite.texture = PixelArt.house_texture(level)
	_add_window_lights(house_sprite, level)
	house_sprite.modulate = Color(1.25, 1.2, 1.05)
	var tween := create_tween()
	tween.tween_property(house_sprite, "modulate", Color.WHITE, 0.65)
	if level >= 4:
		house_glow.texture_scale = 0.04
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
	_add_shop("services", WATER_SHOP, "Amina", Color("#467fc1"))


func _add_shop(kind: String, at: Vector2, npc_name: String, color: Color) -> void:
	var shop := SettlementPlaceable.new()
	shop.name = "%sShop" % kind.capitalize()
	shop.placeable_id = "shop_%s" % kind
	shop.category = "shop"
	shop.z_index = 6
	shop.y_sort_enabled = false
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
	stall.z_index = 2
	shop.add_child(stall)
	_shop_stalls.append(stall)
	var counter := StaticBody2D.new()
	counter.name = "CounterBody"
	counter.collision_layer = 1
	var counter_shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(3.2, 0.65)
	counter_shape.shape = rect
	counter_shape.position = Vector2(0, -0.4)
	counter.add_child(counter_shape)
	shop.add_child(counter)
	var target := SettlementTarget.new()
	target.name = "%sTarget" % kind.capitalize()
	target.target_name = "%s stall" % kind.capitalize()
	target.position = Vector2(0, -0.5)
	shop.add_child(target)
	var npc := ShopNPC.new()
	npc.name = npc_name
	npc.shop_type = kind
	npc.npc_kind = "builder" if kind in ["house", "services"] else kind
	npc.npc_name = npc_name
	npc.position = Vector2(0, -0.65)
	npc.z_index = 1
	npc.interact_radius = 2.8
	shop.add_child(npc)
	var sign := Label.new()
	sign.text = {"potion": "Potion Shop", "equipment": "Equipment Shop", "pet": "Pet Shop", "house": "Construction Shop", "services": "Water Shop"}.get(kind, "Shop")
	sign.add_theme_font_size_override("font_size", 12)
	sign.add_theme_color_override("font_color", Color("#ffe0a3"))
	sign.add_theme_color_override("font_shadow_color", Color("#172329"))
	sign.add_theme_constant_override("shadow_offset_x", 1)
	sign.add_theme_constant_override("shadow_offset_y", 1)
	sign.custom_minimum_size = Vector2(150, 22)
	sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sign.scale = Vector2.ONE * PixelArt.PX
	sign.position = Vector2(-2.35, -3.5)
	sign.z_index = 3
	sign.add_to_group("shop_signs")
	shop.add_child(sign)
	# A small warm lamp under each awning.
	var lamp := PointLight2D.new()
	lamp.texture = PixelArt.light_texture()
	lamp.texture_scale = 0.028
	lamp.energy = 0.12
	lamp.color = color.lightened(0.35)
	lamp.position = Vector2(0, -1.3)
	shop.add_child(lamp)
	_local_lights.append(lamp)


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
	call_deferred("invalidate_resident_routes")
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
	for record in GameState.data.get("home_monsters", []):
		var monster: Enemy
		if str(record.get("kind", "")) == "fire":
			_spawn_forest_monsters(1, true)
			monster = _forest_monsters.back()
		else:
			monster = spawn_sea_urchin(Vector2(float(record.get("x", 17)), float(record.get("y", 29))), bool(record.get("raid", false)), true)
		if is_instance_valid(monster):
			monster.position = Vector2(float(record.get("x", 47)), float(record.get("y", 24)))
			monster.hp = clampi(int(record.get("hp", monster.max_hp)), 1, monster.max_hp)


func _spawn_forest_monsters(count: int, restoring: bool = false) -> void:
	if not restoring and (not GameState.is_night() or GameState.game_over_active):
		return
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
		monster.kind = "fire"
		monster.monster_level = 2
		monster.forest_mode = true
		monster.sight_range = 11.5
		monster.attack_interval = 1.6
		monster.tutorial_raider = (offset + i) < 6
		monster.max_hp = 40
		monster.damage = 3
		monster.speed = 1.62
		monster.xp_reward = 9
		monster.gold_reward = 6
		monster.diamond_chance = 0.0
		monster.body_radius = 0.4
		monster.position = p + Vector2(_rng.randf_range(-0.6, 0.6), _rng.randf_range(-0.5, 0.5))
		add_child(monster)
		_forest_monsters.append(monster)


func capture_monsters() -> Array:
	var records: Array = []
	for child in get_children():
		if child is Enemy and not child.dead and not child.is_queued_for_deletion() and child.kind in ["fire", "urchin"]:
			records.append({"kind": child.kind, "x": child.position.x, "y": child.position.y, "hp": child.hp, "raid": child.settlement_mode})
	return records


func forget_monster(monster: Enemy) -> void:
	_forest_monsters.erase(monster)
	_emergency_monsters.erase(monster)


func _update_daylight() -> void:
	if not is_instance_valid(_grade) or _devastation_started: return
	var clock := float(GameState.data.get("world_time", 0.0))
	_grade.color = MonsoonLighting.grade(clock)
	var strength := MonsoonLighting.lantern_strength(clock)
	for lamp in _local_lights:
		if not is_instance_valid(lamp): continue
		if not lamp.has_meta("day_energy"): lamp.set_meta("day_energy", lamp.energy)
		lamp.energy = float(lamp.get_meta("day_energy")) * strength
		lamp.enabled = GameSettings.effects_at_least("med") and strength > 0.02
	for window in get_tree().get_nodes_in_group("monsoon_windows"):
		if is_ancestor_of(window): window.modulate.a = strength * 0.85


func _on_day_phase_changed(night: bool, _immediate: bool = false) -> void:
	if is_queued_for_deletion() or GameState.game_over_active or journey_serial != GameState.journey_serial:
		return
	_update_daylight()
	# Dawn changes only the light. Living enemies keep their HP, targets and AI.
	if not night or int(GameState.data.get("home_wave", -1)) >= GameState.night_number():
		return
	var fires := 0
	var urchins := 0
	for record in capture_monsters():
		if str(record.get("kind", "")) == "fire":
			fires += 1
		else:
			urchins += 1
	_spawn_forest_monsters(maxi(0, FIRE_MONSTER_COUNT - fires))
	for i in maxi(0, NIGHT_URCHIN_COUNT - urchins):
		spawn_sea_urchin(Vector2(15.0 + i * 1.2, 27.0 + (i % 3) * 1.5))
	GameState.mark_home_wave()
	if GameState.emergency_active():
		_spawn_emergency_monsters(GameState.emergency_monsters())
	GameState.store_home_monsters(capture_monsters())


func spawn_sea_urchin(at: Vector2, raid: bool = false, restoring: bool = false) -> Enemy:
	if not restoring:
		if not GameState.is_night() or GameState.game_over_active:
			return null
		var count := 0
		for record in capture_monsters():
			if str(record.get("kind", "")) == "urchin":
				count += 1
		if count >= URCHIN_LIMIT:
			return null
	var monster := Enemy.new()
	monster.kind = "urchin"
	monster.settlement_mode = raid
	monster.max_hp = 60 if raid else 30
	monster.damage = 9 if raid else 6
	monster.speed = 1.75 if raid else 1.35
	monster.xp_reward = 10 if raid else 5
	monster.gold_reward = 12 if raid else 7
	monster.diamond_chance = 0.0
	monster.body_radius = 0.42
	monster.position = at
	add_child(monster)
	if raid:
		_emergency_monsters.append(monster)
	return monster


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
	# One owned optional tween responds even when settings change after loading.
	ship.add_to_group("ambient_boat")
	var bob := ship.create_tween().set_loops()
	bob.set_parallel(true)
	bob.tween_property(ship, "position:y", 32.05, 2.1).set_trans(Tween.TRANS_SINE)
	bob.tween_property(ship, "rotation", 0.008, 2.1).set_trans(Tween.TRANS_SINE)
	bob.chain().tween_property(ship, "position:y", 31.95, 2.1).set_trans(Tween.TRANS_SINE)
	bob.parallel().tween_property(ship, "rotation", -0.008, 2.1).set_trans(Tween.TRANS_SINE)
	ship.set_meta("ambient_tween", bob)
	# Lamps on the jetty.
	for x in [3.4, 13.5]:
		var lamp := PointLight2D.new()
		lamp.texture = PixelArt.light_texture()
		lamp.texture_scale = 0.024
		lamp.energy = 0.12
		lamp.color = Color("#ffd483")
		lamp.position = Vector2(x, 29.5)
		add_child(lamp)
		_local_lights.append(lamp)
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


func _add_tree(at: Vector2, _upper_path: String, _lower_path: String, scale_mul: float) -> void:
	var holder := ForestTree.new()
	holder.name = "ForestTree"
	holder.tree_id = "forest_%d" % _tree_serial
	holder.max_health = 100 + (_tree_serial % 3) * 15
	holder.tree_name = "Forest tree"
	holder.position = at
	_tree_serial += 1
	holder.felled.connect(_on_forest_tree_felled)
	_forest_trees.append(holder)
	_tree_positions.append(at)
	# The ID is already assigned. Visual families consume no placement RNG.
	var species := MonsoonArt.family(holder.tree_id, at)
	holder.set_meta("visual_family", species)
	var upper := AssetRegistry.get_texture("foliage/" + _upper_path)
	var lower := AssetRegistry.get_texture("foliage/" + _lower_path)
	if upper == null: upper = MonsoonArt.tree_texture(species, "upper")
	if lower == null: lower = MonsoonArt.tree_texture(species, "lower")
	var upper_size := upper.get_size()
	var lower_size := lower.get_size()
	var total_h := upper_size.y + lower_size.y
	var shadow := Sprite2D.new()
	shadow.texture = MonsoonArt.tree_shadow(species)
	shadow.scale = Vector2.ONE * PixelArt.PX * scale_mul
	shadow.position = Vector2(0.25, 0.05)
	shadow.z_index = -1
	holder.add_child(shadow)
	var lower_sprite := Sprite2D.new()
	lower_sprite.texture = lower
	lower_sprite.centered = false
	lower_sprite.offset = Vector2(-lower_size.x * 0.5, -lower_size.y)
	lower_sprite.scale = Vector2(PixelArt.PX, PixelArt.PX) * scale_mul
	lower_sprite.modulate = Color.WHITE
	lower_sprite.z_index = 0
	holder.add_child(lower_sprite)
	var upper_sprite := Sprite2D.new()
	upper_sprite.texture = upper
	upper_sprite.material = Shaders.wind_material()
	upper_sprite.centered = false
	upper_sprite.offset = Vector2(-upper_size.x * 0.5, -total_h)
	upper_sprite.scale = Vector2(PixelArt.PX, PixelArt.PX) * scale_mul
	upper_sprite.modulate = Color.WHITE
	upper_sprite.z_index = 0
	holder.add_child(upper_sprite)
	holder.register_visual(lower_sprite)
	holder.register_visual(upper_sprite)
	var body := StaticBody2D.new()
	body.name = "Body"
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 0.45 * scale_mul
	shape.shape = circle
	shape.position = Vector2(0, -0.2)
	body.add_child(shape)
	holder.add_child(body)
	add_child(holder)


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
		if _authored_map:
			var edited := false
			for layer in ["Terrain", "Paths", "Water", "Shore"]:
				if not _authored_map.cell(layer, Vector2i(p.floor())).is_empty(): edited = true
			if edited: continue
		var shore := float(_coast_pixel_y(int(p.x * 32))) / 32.0
		if p.y > shore - 0.5:
			continue
		for j in _rng.randi_range(2, 5):
			_add_wind_decor(flower_paths[0], p + Vector2(_rng.randf_range(-0.5, 0.5), _rng.randf_range(-0.35, 0.35)), 0.9, 3)
	# Moveable decorations near the cottage.
	_add_decor_placeable("barrel_1", "res://assets/sprites/TX Props__TX Props Barrel.tres", Vector2(28.8, 23.8), 1.0, 5, Vector2(1.2, 1.4))
	_add_decor_placeable("barrel_2", "res://assets/sprites/TX Props__TX Props Barrel.tres", Vector2(40.2, 22.8), 1.0, 5, Vector2(1.2, 1.4))
	_add_decor_placeable("signpost", "res://assets/sprites/TX Props__TX Props Road Sign W.tres", Vector2(25.7, 22.1), 1.0, 5, Vector2(1.3, 1.5))


func _build_monsoon_scenery() -> void:
	# Curated resident workspaces. Independent of _rng and all tree identities.
	for entry in [["fishing_net", Vector2(11.3, 25.5)], ["baskets", Vector2(13.5, 26.5)], ["timber", Vector2(43.0, 17.5)], ["bucket", Vector2(46.2, 18.6)], ["lantern", Vector2(28.3, 12.0)], ["lantern", Vector2(39.6, 12.0)]]:
		var sprite := Sprite2D.new()
		sprite.name = "Monsoon_" + str(entry[0])
		sprite.texture = MonsoonArt.prop(entry[0])
		sprite.centered = false
		sprite.offset = Vector2(-32, -64)
		sprite.scale = Vector2.ONE * PixelArt.PX
		sprite.position = entry[1]
		sprite.z_index = 5
		add_child(sprite)
	for placeable in _placeables:
		if not placeable.placeable_id.begins_with("shop_"): continue
		var basket := Sprite2D.new()
		basket.texture = MonsoonArt.prop("planter" if placeable.placeable_id == "shop_potion" else "baskets")
		basket.scale = Vector2.ONE * PixelArt.PX * 0.65
		basket.position = Vector2(-1.25, -0.05)
		basket.offset = Vector2(0, -32)
		basket.z_index = 0
		placeable.add_child(basket)


func _add_decor_sprite(path: String, at: Vector2, scale_mul: float, z: int) -> Sprite2D:
	var tex: Texture2D
	if "TX Bush" in path or "Flower" in path:
		var variant := 3 if "Flower" in path else posmod(absi(path.hash()), 3)
		tex = PixelArt.cached_texture("monsoon/undergrowth/%d" % variant, func() -> Image: return MonsoonArt.undergrowth(variant))
	else:
		tex = load(path) as Texture2D
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


func _add_wind_decor(path: String, at: Vector2, scale_mul: float, z: int) -> void:
	# Scatter sprite that joins the shared wind sway (med quality and above).
	var sprite := _add_decor_sprite(path, at, scale_mul, z)
	if sprite != null:
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
	var count := 520 # Base artwork is identical at every effects tier.
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
		# Forest pinnae, garden hibiscus, coastal blades; quiet maintained centre.
		if p.x > 45.0: variant = 0 if i % 3 else 2
		elif p.y > shore - 3.7: variant = 5
		elif p.distance_to(SPAWN) < 7.0: variant = 4
		elif i % 5 == 0: variant = 3
		var mul := 0.75 + _grass_rng.randf_range(-0.15, 0.35)
		variants.append(variant)
		placements.append(Transform2D(0.0, Vector2(mul, mul), 0.0, p))
		var tint := 0.94 + _grass_rng.randf() * 0.1
		colors.append(Color(tint, tint * (0.98 + _grass_rng.randf() * 0.08), tint * 0.96))
	for vi in 6:
		var tex := PixelArt.coastal_grass(vi)
		if tex == null:
			continue
		var mesh := QuadMesh.new()
		mesh.size = tex.get_size()
		var mm := MultiMesh.new()
		mm.mesh = mesh
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
		field.material = Shaders.wind_material()
		field.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(field)


# ------------------------------------------------------------------ actors

func _build_player_and_pet() -> void:
	_mission_walk_origin = _player_spawn
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
	if not is_node_ready() or GameState.game_over_active:
		return
	_build_water_keepers()


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


func _add_resident_house(house_name: String, at: Vector2, level: int) -> void:
	var holder := Node2D.new()
	holder.name = house_name
	holder.z_index = 6
	holder.position = at
	holder.add_to_group("resident_house")
	add_child(holder)
	var art := Sprite2D.new()
	art.texture = PixelArt.house_texture(level)
	art.centered = false
	art.offset = Vector2(-112, -176)
	art.scale = Vector2(PixelArt.PX, PixelArt.PX) * 0.78
	art.z_index = 0
	holder.add_child(art)
	_add_window_lights(art, level)
	var glow := PointLight2D.new()
	glow.texture = PixelArt.light_texture()
	glow.texture_scale = 0.026
	glow.energy = 0.18
	glow.color = Color("#ffd58c")
	glow.position = Vector2(0, -1.2)
	holder.add_child(glow)
	_local_lights.append(glow)
	var target := SettlementTarget.new()
	target.name = "ResidentHouseTarget"
	target.target_name = house_name.trim_prefix("ResidentHouse") + " cottage"
	target.structure_id = "home_" + house_name.to_snake_case()
	target.damage_scale = 0.25
	target.position = Vector2(0, -0.8)
	holder.add_child(target)
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(4.8, 1.1)
	shape.shape = rect
	shape.position = Vector2(0, -0.55)
	body.add_child(shape)
	holder.add_child(body)
	_house_positions.append(at)
	_markers.append({"position": at, "color": Color("#e4c571"), "size": 3.5, "shape": "square"})


func _add_ruin_house(house_name: String, at: Vector2, state: String) -> void:
	var holder := Node2D.new()
	holder.name = house_name
	holder.z_index = 6
	holder.position = at
	holder.add_to_group("ruin_house")
	add_child(holder)
	var art := Sprite2D.new()
	art.texture = PixelArt.house_texture(2 if state == "abandoned" else 1)
	art.centered = false
	art.offset = Vector2(-112, -176)
	art.scale = Vector2(PixelArt.PX, PixelArt.PX) * 0.74
	art.z_index = 0
	holder.add_child(art)
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
				holder.add_child(rubble)
			_add_smoke(holder, Vector2(0.0, -2.0))
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(4.6, 1.0) if state != "destroyed" else Vector2(3.8, 0.6)
	shape.shape = rect
	shape.position = Vector2(0, -0.5)
	body.add_child(shape)
	holder.add_child(body)
	_ruin_positions.append(at)
	_markers.append({"position": at, "color": Color("#8b7b62"), "size": 3.0, "shape": "square"})


func _add_smoke(holder: Node2D, at: Vector2) -> void:
	for i in 2:
		var smoke := Sprite2D.new()
		smoke.texture = PixelArt.light_texture()
		smoke.scale = Vector2(0.004, 0.004)
		smoke.modulate = Color(0.45, 0.43, 0.4, 0.16)
		smoke.position = at + Vector2(float(i) * 0.25, 0)
		smoke.z_index = 7
		holder.add_child(smoke)
		smoke.add_to_group("ambient_smoke")
		var tween := smoke.create_tween().set_loops()
		tween.tween_property(smoke, "position:y", smoke.position.y - 1.2, 2.4 + float(i) * 0.2)
		tween.parallel().tween_property(smoke, "modulate:a", 0.0, 2.4)
		tween.tween_callback(func() -> void:
			smoke.position = at + Vector2(float(i) * 0.25, 0)
			smoke.modulate = Color(0.45, 0.43, 0.4, 0.16))
		smoke.set_meta("ambient_tween", tween)


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
			_add_fence_body(group, fence.position, Vector2(1.4, 0.3))
		x += 1.55
	_add_fence_target(group, id)


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
			_add_fence_body(group, fence.position, Vector2(0.3, 1.4))
		y += 1.55
	_add_fence_target(group, id)


func _add_fence_body(holder: Node2D, at: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = at
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	shape.shape = rectangle
	body.add_child(shape)
	holder.add_child(body)


func _add_fence_target(holder: Node2D, id: String) -> void:
	var target := SettlementTarget.new()
	target.structure_id = id
	target.structure_kind = "fence"
	target.target_name = id.capitalize()
	target.max_health = 120
	holder.add_child(target)


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
	animal.set_meta("ambient_tween", tween)


func _add_resident(resident_name: String, role: String, activity: String, start: Vector2, points: Array, shelter: Vector2, combat: bool = false, damage: int = 8, distance: float = 4.2) -> void:
	var resident := Resident.new()
	resident.resident_name = resident_name
	resident.role = role
	resident.activity = activity
	resident.position = start
	resident.shelter = shelter
	resident.combat_enabled = combat
	resident.combat_damage = damage
	resident.combat_range = distance
	var typed_points: Array[Vector2] = []
	for p in points:
		typed_points.append(p)
	resident.waypoints = typed_points
	add_child(resident)
	_residents.append(resident)


func _build_water_keepers() -> void:
	# No world RNG calls here: existing tree IDs and generation order stay stable.
	var starts := [Vector2(46, 10), Vector2(49, 15), Vector2(46, 23), Vector2(50, 29), Vector2(55, 22)]
	for i in GameState.water_keeper_count():
		var already_exists := false
		for resident in _residents:
			if is_instance_valid(resident) and resident.resident_name == "Water Keeper %d" % (i + 1):
				already_exists = true
		if already_exists:
			continue
		var keeper := Resident.new()
		keeper.resident_name = "Water Keeper %d" % (i + 1)
		keeper.role = "water_keeper"
		keeper.water_power = true
		keeper.position = starts[i]
		keeper.waypoints = [starts[i], starts[i] + Vector2(1.2, 0.5)]
		keeper.activity = "Protecting and replanting the forest"
		add_child(keeper)
		_residents.append(keeper)


func begin_devastation() -> void:
	if _devastation_started:
		return
	_devastation_started = true
	for enemy in get_children():
		if enemy is Enemy:
			enemy.set_physics_process(false)
	if is_instance_valid(_rubbish_system):
		_rubbish_system.set_process(false)
		_rubbish_system.set_physics_process(false)
	# Grade the actual terrain so the ruined world remains visible behind UI.
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; uniform float decay = 0.0; void fragment(){ vec4 c = texture(TEXTURE, UV); float lightness = dot(c.rgb, vec3(0.3, 0.59, 0.11)); vec3 dry = vec3(0.91, 0.39, 0.09) * (0.45 + lightness); COLOR = vec4(mix(c.rgb, dry, decay), c.a); }"
	var material := ShaderMaterial.new()
	material.shader = shader
	background.material = material
	var water := Sprite2D.new()
	water.name = "PoisonedSea"
	water.texture = _make_water_mask_texture()
	water.centered = false
	water.scale = Vector2.ONE * PixelArt.PX
	water.z_index = -998
	water.z_as_relative = false
	var sea_shader := Shader.new()
	sea_shader.code = "shader_type canvas_item; void fragment(){ float alpha = COLOR.a; vec4 mask = texture(TEXTURE, UV); COLOR = vec4(mix(vec3(0.16, 0.31, 0.06), vec3(0.035, 0.14, 0.025), mask.r), alpha); }"
	var sea_material := ShaderMaterial.new()
	sea_material.shader = sea_shader
	water.material = sea_material
	water.modulate.a = 0.0
	add_child(water)
	var remains := Node2D.new()
	remains.name = "StrandedSeaLife"
	remains.z_index = 8
	remains.modulate.a = 0.0
	add_child(remains)
	for i in 20:
		var x := 48 + i * 37
		var animal := Sprite2D.new()
		animal.texture = _dead_sea_life_texture(i % 2)
		animal.scale = Vector2.ONE * PixelArt.PX * (1.2 if i % 3 == 0 else 0.8)
		animal.position = Vector2(float(x), float(_coast_pixel_y(x - x % 2) - 18 - (i % 3) * 16)) * PixelArt.PX
		animal.rotation = float(i % 5 - 2) * 0.18
		remains.add_child(animal)
	var duration := 0.15 if GameSettings.reduce_motion() else DEVASTATION_SECONDS
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "devastation_progress", 1.0, duration)
	tween.tween_method(func(value: float) -> void: material.set_shader_parameter("decay", value), 0.0, 1.0, duration)
	tween.tween_property(water, "modulate:a", 1.0, duration)
	tween.tween_property(remains, "modulate:a", 1.0, duration)
	for child in get_children():
		if child is MultiMeshInstance2D:
			tween.tween_property(child, "modulate", Color("#d16a27"), duration)
	if camera and not GameSettings.reduce_motion():
		camera.set_physics_process(false)
		tween.tween_property(camera, "global_position", MAP_RECT.get_center(), duration)
		tween.tween_property(camera, "zoom", Vector2(17, 17), duration)


func _dead_sea_life_texture(kind: int) -> Texture2D:
	return PixelArt.cached_texture("stranded_sea_life_%d" % kind, func() -> Image:
		var img := PixelArt.image(32, 20)
		if kind == 0:
			PixelArt.ellipse(img, 17, 10, 10, 5, Color("#b8b7a0"))
			PixelArt._fill_polygon(img, [Vector2i(8, 10), Vector2i(1, 4), Vector2i(1, 16)], Color("#85876c"))
			PixelArt.line(img, 21, 7, 25, 11, Color("#434c38"))
			PixelArt.line(img, 25, 7, 21, 11, Color("#434c38"))
			PixelArt.hline(img, 10, 13, 10, Color("#e2dac0"))
		else:
			PixelArt.ellipse(img, 16, 11, 7, 5, Color("#9c6946"))
			for i in 3:
				PixelArt.line(img, 10, 9 + i * 3, 4, 6 + i * 5, Color("#865139"))
				PixelArt.line(img, 22, 9 + i * 3, 28, 6 + i * 5, Color("#865139"))
			PixelArt.rect(img, 12, 7, 2, 2, Color("#3e3b2c"))
			PixelArt.rect(img, 19, 7, 2, 2, Color("#3e3b2c"))
		return img)


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
var _ward_mote_timer := 0.0


func _process(delta: float) -> void:
	_update_daylight()
	if is_instance_valid(player) and GameState.mission_step() == 0 and player.position.distance_to(_mission_walk_origin) >= 3.0:
		GameState.record_mission_event("move")
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
	if not GameState.is_night() or GameState.game_over_active:
		return
	_clear_emergency_monsters()
	if not _emergency_monsters.is_empty():
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
		spawn_sea_urchin(p + Vector2(_rng.randf_range(-0.7, 0.7), 0.0), true)
	# A raid also drives more woodland monsters into the tree line. They attack
	# trees with impact effects but do not count toward the emergency kill quota.
	var live_forest := 0
	for monster in _forest_monsters:
		if is_instance_valid(monster) and not monster.dead:
			live_forest += 1
	if live_forest < FIRE_MONSTER_LIMIT:
		_spawn_forest_monsters(mini(6, FIRE_MONSTER_LIMIT - live_forest))


func _clear_emergency_monsters() -> void:
	# Ending a raid must never despawn living enemies.
	for i in range(_emergency_monsters.size() - 1, -1, -1):
		if not is_instance_valid(_emergency_monsters[i]) or _emergency_monsters[i].dead:
			_emergency_monsters.remove_at(i)


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
	var lesson := MissionDB.step(GameState.mission_step())
	if not lesson.is_empty():
		var destination := _player_spawn + Vector2(3.5, 0)
		match str(lesson.get("target", "")):
			"yard":
				pass
			"wood":
				destination = Vector2(18.2, 31.1)
			"potion", "pet", "services", "house":
				destination = _shop_customer_position(str(lesson.get("target", "potion")), SPAWN)
			"fire":
				var best := INF
				for enemy in _forest_monsters:
					if not is_instance_valid(enemy) or enemy.dead:
						continue
					var distance := player.global_position.distance_to(enemy.global_position)
					if distance < best:
						best = distance
						destination = enemy.global_position
			"portal", "boss":
				destination = MONSTER_GATE + Vector2(0, 1)
			_:
				return []
		return [{"position": destination, "label": lesson.get("title", "Mission")}]
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
	return targets.slice(0, 1)


func _shop_customer_position(kind: String, fallback: Vector2) -> Vector2:
	for shop in get_tree().get_nodes_in_group("ambient_shop"):
		if is_instance_valid(shop) and shop.get_parent().get_parent() == self and shop.shop_type == kind:
			return shop.customer_position()
	return fallback


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
		_add_window_lights(house_sprite, GameState.house_level())


func resident_path(from: Vector2, to: Vector2, allow_nearest_goal: bool = true) -> PackedVector2Array:
	if _resident_routes == null:
		_resident_routes = ResidentRoutes.new(self, MAP_RECT)
	return _resident_routes.path(from, to, allow_nearest_goal)


func _build_beach_landmarks() -> void:
	var turtle := BeachTurtle.new()
	turtle.name = "BeachTurtle"
	# Use the same two-art-pixel coastline columns as terrain and mask.
	var coast_x := 14 * 32
	turtle.position = Vector2(float(coast_x) * PixelArt.PX, float(_coast_pixel_y(coast_x)) * PixelArt.PX - 1.3)
	add_child(turtle)
	var sign := Node2D.new()
	sign.name = "BesutSign"
	sign.position = Vector2(29.5, 28.3)
	sign.z_index = 6
	sign.add_to_group("besut_sign")
	add_child(sign)
	var art := Sprite2D.new()
	art.texture = PixelArt.besut_sign_texture()
	art.scale = Vector2.ONE * PixelArt.PX
	art.offset = Vector2(0, -25)
	sign.add_child(art)
	sign.set_meta("text", "BESUT")


func resident_routes_revision() -> int:
	return _resident_routes.revision if _resident_routes != null else 0


func invalidate_resident_routes() -> void:
	if _resident_routes != null:
		_resident_routes.invalidate()


func _fresh_foliage(path: String) -> Texture2D:
	return PixelArt.cached_texture("foliage/" + path, func() -> Image:
		var img := (load(path) as Texture2D).get_image().duplicate() as Image
		for y in img.get_height():
			for x in img.get_width():
				var col := img.get_pixel(x, y)
				if col.a > 0.0 and col.g > col.r * 0.88 and col.g > col.b * 1.15:
					var light := col.get_luminance()
					var fresh := WorldPalette.color("grass_shadow").lerp(WorldPalette.color("grass_light"), clampf(light * 1.18 - 0.17, 0.0, 0.88))
					fresh.a = col.a
					img.set_pixel(x, y, fresh)
		return img)
