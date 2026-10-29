class_name Lobby
extends Node2D
## Seaside home hub. Environment art is composed from the original Cainos
## atlas, while the cottage, stalls and portal frames come from PixelArt.

const MAP_RECT := Rect2(0, 0, 64, 40)
# Historical exclusions are frozen ONLY to preserve the seeded forest identities.
# Runtime building placement is owned by village_layout.tres.
const FOREST_HOUSE_EXCLUSIONS := [Vector2(48.1, 18.4), Vector2(14, 18.1), Vector2(39.4, 31.4), Vector2(25, 8), Vector2(11, 12), Vector2(54.5, 33), Vector2(29, 33)]
const FOREST_RUIN_EXCLUSIONS := [Vector2(17.8, 13.6), Vector2(52, 33.2), Vector2(22.5, 32.4), Vector2(55.5, 7.8)]
const SPAWN := Vector2(34.0, 24.3)
const HOUSE_BASE := Vector2(34.0, 21.4)
# Legacy gate coordinates preserve forest exclusions; authored anchors place portals.
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
var ship_boarding: ShipDeparture
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
var _decor_rng := RandomNumberGenerator.new()
const LEGACY_FOREST_PREFIX_DRAWS := 160
const SPAWN_SEARCH_RINGS := 9
const SPAWN_SEARCH_DIRECTIONS := 16
const SPAWN_SEARCH_STEP := 0.55
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
const LIGHT_UPDATE_SECONDS := 0.12
const MAX_VISIBLE_LIGHTS := 4
var _light_update_clock := 0.0
var _tree_positions: Array[Vector2] = []
var _forest_trees: Array[ForestTree] = []
var _authored_map: AuthoredMap
var _layout: WorldLayout
var _house_positions: Array[Vector2] = []
var _ruin_positions: Array[Vector2] = []
var _tree_serial := 0
var _emergency_fire: Sprite2D
var _emergency_wall_toast := 0.0

const RECOVERY_CENTER := Vector2(34.0, 23.7)
const RECOVERY_RADIUS := 4.3


func _ready() -> void:
	texture_filter = VisualStyle.texture_filter()
	journey_serial = GameState.journey_serial
	add_to_group("world")
	y_sort_enabled = true
	_rng.seed = 7319
	_decor_rng.seed = 88103
	_house_positions.assign(FOREST_HOUSE_EXCLUSIONS)
	_ruin_positions.assign(FOREST_RUIN_EXCLUSIONS)
	var authored := AuthoredMapRenderer.selected_map()
	_authored_map = authored
	_layout = authored.resolved_layout(GameState.data.get("settlement_layout", {})) if authored else WorldLayout.village().resolved([], GameState.data.get("settlement_layout", {}))
	WorldPalette.select_for_map(authored.palette if authored else null)
	_build_background()
	_build_bounds()
	_build_house()
	_build_shops()
	_build_special_npc()
	var mission_guide := MissionNPC.new()
	mission_guide.position = Vector2(29.0, 26.0)
	add_child(mission_guide)
	_build_residential_life()
	_build_portals()
	_build_gathering()
	_build_dock_and_ship()
	_build_street_lamps()
	# Preserve the historical RNG state without letting flowers own tree IDs.
	for i in LEGACY_FOREST_PREFIX_DRAWS: _rng.randf()
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
	_sync_village_pets()
	_sync_rescued_friends()
	GameState.pet_changed.connect(_sync_village_pets)
	var authored_layer := AuthoredMapRenderer.new()
	authored_layer.name = "AuthoredMap"
	authored_layer.definition = authored
	add_child(authored_layer)
	_build_camera()
	var occlusion := WorldOcclusion.new()
	occlusion.name = "WorldOcclusion"
	add_child(occlusion)
	if not GameState.data.get("settlement_layout", {}).is_empty(): call_deferred("_resolve_custom_routes")
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
	background.texture_filter = VisualStyle.texture_filter()
	var terrain_override := AssetRegistry.get_texture("terrain_village_layout_%d_%d" % [WorldPalette.generation,_layout.signature()])
	if not VisualStyle.is_pixel() and terrain_override == null and ResourceLoader.exists("res://assets/authored/realistic/surfaces.png"):
		var terrain_material := ShaderMaterial.new()
		terrain_material.shader = preload("res://assets/shaders/realistic_terrain.gdshader")
		terrain_material.set_shader_parameter("materials",load("res://assets/authored/realistic/surfaces.png"))
		background.material = terrain_material
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
	return WorldTerrain._make_terrain_texture(_layout)


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
		Vfx.pop(_recovery_center + Vector2(randf_range(-1.6, 1.6), -randf_range(0.4, 2.2)), "heart", Color(0.7, 1.0, 0.85, 0.8))


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
	var points := PackedVector2Array()
	for x in range(0, OCEAN_WIDTH_PIXELS, 16):
		var shore := float(_coast_pixel_y(x)) * PixelArt.PX + 0.18
		points.append(Vector2(float(x) * PixelArt.PX, minf(40.0, shore)))
		if shore >= 40.0:
			break
	points.append(Vector2(0, 40))
	var deck := _layout.world_footprint("jetty_deck")
	var cut := PackedVector2Array([deck.position, Vector2(deck.end.x, deck.position.y), deck.end, Vector2(deck.position.x, deck.end.y)])
	for contour in Geometry2D.clip_polygons(points, cut):
		var poly := CollisionPolygon2D.new()
		poly.polygon = contour
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
	house.position = _layout.position_of("house", HOUSE_BASE)
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
	var entrance := HomeEntrance.new()
	entrance.name = "EnterHome"
	entrance.position = Vector2(0, 0.9)
	house.add_child(entrance)
	_markers.append({"position": _house_position, "color": Color("#e4c571"), "size": 6.0, "shape": "square"})
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
	if art.texture.has_meta("realistic_art"):
		windows.texture=art.texture
		var authored_glow := ShaderMaterial.new()
		authored_glow.shader=preload("res://assets/shaders/realistic_windows.gdshader")
		windows.material=authored_glow
	else:
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
	for entry in _layout.anchors:
		if entry.get("kind", "") == "shop":
			_add_shop(str(entry.id).trim_prefix("shop_"), entry.position, str(entry.get("merchant", "Neighbour")), entry.get("lamp_color", Color.WHITE))


func _add_shop(kind: String, at: Vector2, npc_name: String, color: Color) -> void:
	var shop := SettlementPlaceable.new()
	shop.name = "%sShop" % kind.capitalize()
	shop.placeable_id = "shop_%s" % kind
	shop.category = "shop"
	shop.z_index = 6
	shop.y_sort_enabled = false
	shop.selection_size = Vector2(4.3, 4.7)
	shop.position = _layout.position_of(shop.placeable_id, at)
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
	sign.text = {"potion": "Potion Shop", "equipment": "Equipment Shop", "pet": "Pet Shop", "house": "Construction Shop", "services": "Worker Shop"}.get(kind, "Shop")
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
	student.position = _layout.activity_points(_layout.activity("student"))[0]
	add_child(student)


# ------------------------------------------------------------------ portals

func _build_portals() -> void:
	NorthernBoundary.build_north_wall(self)
	# The two gates stand side by side on the north path: campaign monsters on
	# the left, companion duels on the right.
	var first := PortalEntrance.new()
	first.name = "MonsterBattlePortal"
	first.portal_id = "tidebound_grotto"
	first.gate_kind = "monster"
	first.gate_title = "Monster Battle Portal"
	first.position = _layout.position_of("monster_portal", MONSTER_GATE)
	add_child(first)
	_markers.append({"position": first.position, "color": Color("#a47be0"), "size": 4.0, "shape": "arch"})
	var second := PortalEntrance.new()
	second.name = "PetBattlePortal"
	second.portal_id = "pet_duel_1"
	second.gate_kind = "pet"
	second.gate_title = "Pet Battle Portal"
	second.position = _layout.position_of("pet_portal", PET_GATE)
	add_child(second)
	_markers.append({"position": second.position, "color": Color("#58d6cf"), "size": 4.0, "shape": "arch"})


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
		monster.position = safe_spawn(p + Vector2(_rng.randf_range(-0.6, 0.6), _rng.randf_range(-0.5, 0.5)), monster.body_radius)
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
	var focus := player.global_position if is_instance_valid(player) else SPAWN
	var nearby: Array[PointLight2D] = []
	for lamp in _local_lights:
		if is_instance_valid(lamp) and lamp.global_position.distance_squared_to(focus) < 24.0*24.0: nearby.append(lamp)
	nearby.sort_custom(func(a: PointLight2D,b: PointLight2D) -> bool: return a.global_position.distance_squared_to(focus) < b.global_position.distance_squared_to(focus))
	var budget := MAX_VISIBLE_LIGHTS if GameSettings.effects_at_least("high") else 2
	nearby.resize(mini(budget,nearby.size()))
	for lamp in _local_lights:
		if not is_instance_valid(lamp): continue
		if not lamp.has_meta("day_energy"): lamp.set_meta("day_energy", lamp.energy)
		lamp.energy = float(lamp.get_meta("day_energy")) * strength
		lamp.enabled = GameSettings.effects_at_least("med") and strength > 0.02 and lamp in nearby
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
	monster.position = at if restoring else safe_spawn(at, monster.body_radius)
	add_child(monster)
	if raid:
		_emergency_monsters.append(monster)
	return monster


func _build_gathering() -> void:
	for entry in _layout.activity_records():
		if entry.get("kind", "") != "gathering": continue
		var points := _layout.activity_points(entry)
		if points.is_empty(): continue
		var p := points[0]
		var pile := ResourcePile.new()
		pile.name = "Driftwood"
		pile.position = p
		add_child(pile)


# ------------------------------------------------------------------ dock & ship

func _build_street_lamps() -> void:
	var points: Array[Vector2] = []
	for route in _layout.routes:
		var path := _layout.route_points(route)
		if path.size() < 2: continue
		var middle := path[path.size() / 2] + Vector2(1.1,0.3)
		if points.any(func(at: Vector2) -> bool: return at.distance_to(middle) < 4.5): continue
		points.append(middle)
		if points.size() >= 12: break
	for at in points:
		var post := StreetLamp.new()
		post.position = at
		add_child(post)
		_local_lights.append(post.light)


func _build_dock_and_ship() -> void:
	var dock := Sprite2D.new()
	dock.name = "Jetty"
	dock.texture = PixelArt.dock_texture()
	dock.centered = false
	dock.offset = Vector2(-128, -96)
	dock.scale = Vector2(PixelArt.PX, PixelArt.PX)
	dock.position = _layout.position_of("harbour", WorldLayout.village().position_of("harbour"))
	dock.z_index = 2
	add_child(dock)
	var rope := Line2D.new()
	rope.position = dock.position
	rope.points = PackedVector2Array([Vector2(-1.2, -0.8), Vector2(-0.8, -0.2), Vector2(-1, 0.7)])
	rope.width = PixelArt.PX * 2
	rope.default_color = WorldPalette.color("wood_shadow")
	rope.z_index = 3
	add_child(rope)
	var ship := Sprite2D.new()
	ship.name = "MooredShip"
	ship.texture = PixelArt.ship_texture()
	ship.centered = false
	ship.offset = Vector2(-104, -112)
	ship.scale = Vector2(PixelArt.PX, PixelArt.PX)
	ship.position = _layout.activity_points(_layout.activity("boat"))[0]
	ship.z_index = 3
	add_child(ship)
	# One owned optional tween responds even when settings change after loading.
	ship.add_to_group("ambient_boat")
	var bob := ship.create_tween().set_loops()
	bob.set_parallel(true)
	bob.tween_property(ship, "position:y", ship.position.y + 0.05, 2.1).set_trans(Tween.TRANS_SINE)
	bob.tween_property(ship, "rotation", 0.008, 2.1).set_trans(Tween.TRANS_SINE)
	bob.chain().tween_property(ship, "position:y", ship.position.y - 0.05, 2.1).set_trans(Tween.TRANS_SINE)
	bob.parallel().tween_property(ship, "rotation", -0.008, 2.1).set_trans(Tween.TRANS_SINE)
	ship.set_meta("ambient_tween", bob)
	var boarding := ShipDeparture.new()
	boarding.name = "ShipBoarding"
	boarding.ship = ship
	boarding.position = _layout.approach("jetty_deck")
	ship_boarding = boarding
	add_child(boarding)
	# Lamps on the jetty.
	for x in [-5.6, 4.5]:
		var lamp := PointLight2D.new()
		lamp.texture = PixelArt.light_texture()
		lamp.texture_scale = 0.024
		lamp.energy = 0.12
		lamp.color = Color("#ffd483")
		lamp.position = dock.position + Vector2(x, 1)
		add_child(lamp)
		_local_lights.append(lamp)
	# A few crates for life.
	for offset in [Vector2(2.8, -0.7), Vector2(3.7, -0.3)]:
		var p: Vector2 = dock.position + offset
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
	# Plot-edge shrubs follow authored compounds, rather than detached world points.
	for id in ["house", "ResidentHouseWest", "ResidentHouseWestNorth", "ResidentHouseNorth", "ResidentHouseEast", "ResidentHouseSouth", "garden_walk"]:
		var plot := _layout.world_footprint(id)
		var p := Vector2(plot.position.x - 0.6, plot.end.y - 0.3)
		_add_wind_decor(bush_paths[_decor_rng.randi_range(0, bush_paths.size() - 1)], p, 1.0, 4)
	# Grass "rumput2": clustered MultiMesh fields (a handful of draw calls for
	# hundreds of tufts) instead of one sprite per tuft. A dedicated seeded RNG
	# keeps this fully deterministic and never touches the tree-id sequence.
	_build_grass_fields(grass_paths)
	# Moveable decorations near the cottage.
	_add_decor_placeable("barrel_1", "res://assets/sprites/TX Props__TX Props Barrel.tres", Vector2(28.8, 23.8), 1.0, 5, Vector2(1.2, 1.4))
	_add_decor_placeable("barrel_2", "res://assets/sprites/TX Props__TX Props Barrel.tres", Vector2(40.2, 22.8), 1.0, 5, Vector2(1.2, 1.4))
	_add_decor_placeable("signpost", "res://assets/sprites/TX Props__TX Props Road Sign W.tres", Vector2(25.7, 22.1), 1.0, 5, Vector2(1.3, 1.5))


func _build_monsoon_scenery() -> void:
	WorldComposition.build(self, _layout)


func _add_decor_sprite(path: String, at: Vector2, scale_mul: float, z: int) -> Sprite2D:
	if _layout and ("TX Bush" in path or "Flower" in path) and not WorldComposition.allowed(self, _layout, at, 0.5): return null
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
	group.position = GameState.placeable_position(id, _layout.position_of(id, at))
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
		if _layout and not WorldComposition.allowed(self, _layout, p, 0.3): continue
		var zone := _layout.zone_record(p)
		if _grass_rng.randf() > float(zone.get("density", 0.35)): continue
		var variant := _grass_rng.randi_range(0, grass_paths.size() - 1)
		# Forest pinnae, garden hibiscus, coastal blades; quiet maintained centre.
		if _layout.zone_at(p) in ["forest_edge", "forest_interior"]: variant = 0 if i % 3 else 2
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
		field.texture_filter = VisualStyle.texture_filter()
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
	_sync_rescued_friends()


func _on_pet_changed() -> void:
	pass


# ------------------------------------------------------------------ residential life

func _build_residential_life() -> void:
	_build_fences()
	for entry in _layout.anchors:
		match str(entry.get("kind", "")):
			"residence": _add_resident_house(str(entry.id), entry.position, int(entry.get("level", 1)))
			"ruin": _add_ruin_house(str(entry.id), entry.position, str(entry.get("state", "destroyed")))
			"garden": _add_garden(str(entry.id), entry.position)
	# All occupational and animal locations are authored relative to real places.
	for entry in _layout.activity_records():
		var points := _layout.activity_points(entry)
		if points.is_empty(): continue
		match str(entry.get("kind", "")):
			"animal": _add_animal(str(entry.get("species", "chicken")), points[0], float(entry.get("scale", 1.25)))
			"resident":
				_add_resident(str(entry.get("id", "Resident")), str(entry.get("role", "resident")), str(entry.get("activity", "At work")), points[0], points, _house_position + Vector2(0, 1.8), bool(entry.get("combat", false)), int(entry.get("damage", 8)), float(entry.get("distance", 4.2)))
				_residents[-1].set_meta("activity_id", str(entry.id))
	_add_decor_placeable("crate_1", "res://assets/sprites/TX Props__TX Props Crate.tres", _layout.position_of("house") + Vector2(-4.8, 0.4), 1.0, 5, Vector2(1.4, 1.5))
	_add_decor_placeable("barrel_3", "res://assets/sprites/TX Props__TX Props Barrel.tres", _layout.position_of("shop_house") + Vector2(2.7, -1.2), 1.0, 5, Vector2(1.2, 1.4))
	_add_decor_placeable("crate_2", "res://assets/sprites/TX Props__TX Props Crate Small.tres", _layout.position_of("garden_5") + Vector2(-1.6, -0.8), 1.0, 5, Vector2(1.2, 1.3))


func _add_resident_house(house_name: String, at: Vector2, level: int, ruined: bool = false) -> void:
	var holder := Node2D.new()
	holder.name = house_name
	holder.z_index = 6
	holder.position = _layout.position_of(house_name, at)
	holder.set_meta("layout_anchor", house_name)
	holder.add_to_group("resident_house")
	if ruined:
		holder.add_to_group("ruin_house")
	add_child(holder)
	var art := Sprite2D.new()
	art.name = "ResidentHouseArt"
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
	target.starts_ruined = ruined
	target.target_name = str(_layout.anchor(house_name).get("label", house_name.trim_prefix("ResidentHouse") + " cottage"))
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
	_markers.append({"position": at, "color": Color("#e4c571"), "size": 3.5, "shape": "square"})


func _add_ruin_house(house_name: String, at: Vector2, _state: String) -> void:
	_add_resident_house(house_name, at, 1, true)

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
	group.position = GameState.placeable_position(id, _layout.position_of(id, at))
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
	for entry in _layout.anchors:
		if entry.get("kind", "") != "fence": continue
		var at: Vector2 = entry.position
		var span: Vector2 = entry.get("span", Vector2.ZERO)
		var packed: PackedVector2Array = entry.get("gaps", PackedVector2Array())
		var gaps: Array[Vector2] = []
		for gap in packed: gaps.append(gap + Vector2.ONE * (at.x if entry.get("axis", "horizontal") == "horizontal" else at.y))
		if entry.get("axis", "horizontal") == "horizontal":
			_add_fence_horizontal(str(entry.id), at.x + span.x, at.x + span.y, at.y, gaps)
		else:
			_add_fence_vertical(str(entry.id), at.x, at.y + span.x, at.y + span.y, gaps)


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
			fence.texture = PixelArt.fence_texture(GameState.house_level())
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
			fence.texture = PixelArt.fence_texture(GameState.house_level())
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


func _add_resident(resident_name: String, role: String, activity: String, start: Vector2, points: Array, shelter: Vector2, _combat: bool = false, damage: int = 8, distance: float = 4.2) -> void:
	var resident := Resident.new()
	resident.resident_name = resident_name
	resident.role = role
	resident.activity = activity
	resident.position = start
	resident.shelter = shelter
	resident.set_meta("home_shelter_offset", shelter - _house_position)
	resident.combat_enabled = false
	# Specialist blue/black workers own combat; other residents seek shelter.
	resident.combat_damage = damage
	resident.combat_range = distance
	var typed_points: Array[Vector2] = []
	for p in points:
		typed_points.append(p)
	resident.waypoints = typed_points
	add_child(resident)
	_residents.append(resident)


func _build_water_keepers() -> void:
	_build_workers()

func _build_workers() -> void:
	var origins := {"water": _layout.activity_points(_layout.activity("keeper_0"))[0], "builder": _layout.approach("shop_house") + Vector2(2, 1), "planter": _layout.position_of("garden_walk"), "fighter": _layout.position_of("market") + Vector2(0, 2.3)}
	var appearances := {"water": "water_keeper", "builder": "construction_worker", "planter": "tree_planter", "fighter": "swordsman"}
	for worker_role in ["water", "builder", "planter", "fighter"]:
		for i in GameState.worker_count(worker_role):
			var worker_name := GameState.worker_name(worker_role, i)
			var exists := false
			for resident in _residents:
				if is_instance_valid(resident) and resident.resident_name == worker_name:
					exists = true
			if exists:
				continue
			var worker := Resident.new()
			worker.resident_name = worker_name
			worker.worker_role = worker_role
			worker.role = str(appearances[worker_role])
			worker.water_power = worker_role == "water"
			worker.combat_enabled = worker_role in ["water", "fighter"]
			var origin: Vector2 = origins[worker_role]
			worker.position = origin + Vector2((i % 3) * 1.4, int(i / 3) * 1.3)
			worker.waypoints = [worker.position, worker.position + Vector2(1, 0.5)]
			add_child(worker)
			_residents.append(worker)

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
	_coastal_guard.position = _layout.activity_points(_layout.activity("guard"))[0]
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
	_light_update_clock -= delta
	if _light_update_clock <= 0.0:
		_light_update_clock = LIGHT_UPDATE_SECONDS
		_update_daylight()
	var game := get_tree().get_first_node_in_group("game") as Game
	if (not is_instance_valid(game) or not is_instance_valid(game.home_interior)) and is_instance_valid(player) and GameState.mission_step() == 0 and player.position.distance_to(_mission_walk_origin) >= 3.0:
		GameState.record_mission_event("move")
	if GameState.recovery_active() and is_instance_valid(player) and (not is_instance_valid(game) or not is_instance_valid(game.home_interior)):
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
	_settlement_editor.building_area = Rect2(18.2, 10.5, 27.4, 19.9)
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
				destination = _layout.approach("monster_portal")
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
	if monster_pending and not bool(GameState.campaign().get("mei_ling_rescued", false)):
		targets.append({"label": "RESCUE MEI LING" if GameState.tutorial_complete() else "MONSTER", "position": _layout.approach("monster_portal"), "color": Color("#b08cff")})
	if not bool(GameState.pet_battle_state("pet_duel_1").get("cleared", false)):
		targets.append({"label": "PET DUEL", "position": _layout.approach("pet_portal"), "color": Color("#5bd6cf")})
	if GameState.house_level() < HouseDB.max_level():
		targets.append({"label": "BUILD", "position": _shop_customer_position("house", CONSTRUCTION_SHOP), "color": Color("#f2c45a")})
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
	turtle.position = _layout.position_of("beach_turtle", Vector2(float(coast_x) * PixelArt.PX, float(_coast_pixel_y(coast_x)) * PixelArt.PX - 1.3))
	add_child(turtle)
	var sign := Node2D.new()
	sign.name = "BesutSign"
	sign.position = _layout.position_of("besut", Vector2(29.5, 28.3))
	sign.z_index = 6
	sign.add_to_group("besut_sign")
	add_child(sign)
	var art := Sprite2D.new()
	art.texture = PixelArt.besut_sign_texture()
	art.scale = Vector2.ONE * PixelArt.PX
	art.offset = Vector2(0, -25)
	sign.add_child(art)
	if art.texture.has_meta("realistic_art"):
		var nameplate := Label.new()
		nameplate.text="BESUT"
		nameplate.scale=Vector2.ONE*PixelArt.PX
		nameplate.position=Vector2(-0.74,-1.65)
		nameplate.add_theme_font_size_override("font_size",14)
		nameplate.add_theme_color_override("font_color",Color("#fff0cf"))
		nameplate.add_theme_color_override("font_outline_color",Color("#36271b"))
		nameplate.add_theme_constant_override("outline_size",2)
		sign.add_child(nameplate)
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


func refresh_spatial_layout() -> void:
	# Called on drag completion, never per frame. Source map stays immutable.
	var saved: Dictionary = GameState.data.get("settlement_layout", {})
	_layout = _authored_map.resolved_layout(saved) if _authored_map else WorldLayout.village().resolved([], saved)
	for placeable in _placeables:
		if placeable.placeable_id == "house":
			_house_position = placeable.position
			_recovery_center = _house_position + Vector2(0, 2.3)
			_player_spawn = _house_position + Vector2(0, 2.9)
			if is_instance_valid(_recovery_ward): _recovery_ward.position = _recovery_center
	for placeable in _placeables:
		var entry := _layout.anchor(placeable.placeable_id)
		if not str(entry.get("relative_to", "")).is_empty(): placeable.position = _layout.position_of(placeable.placeable_id)
	for resident in _residents:
		if is_instance_valid(resident) and resident.has_meta("home_shelter_offset"):
			resident.shelter = _house_position + resident.get_meta("home_shelter_offset")
		if is_instance_valid(resident) and resident.has_meta("activity_id"):
			resident.waypoints = _layout.activity_points(_layout.activity(str(resident.get_meta("activity_id"))))
	background.texture = WorldTerrain._make_terrain_texture(_layout)
	invalidate_resident_routes()
	call_deferred("_resolve_custom_routes")


var _resolving_routes := false
func _resolve_custom_routes() -> void:
	if _resolving_routes: return
	_resolving_routes = true
	await get_tree().physics_frame
	await get_tree().physics_frame
	if is_queued_for_deletion(): return
	var planner := ResidentRoutes.new(self, MAP_RECT)
	planner.clearance = WorldLayout.ACTOR_CLEARANCE
	var changed := false
	for route in _layout.routes:
		var points := _layout.route_points(route)
		var clear := true
		for i in points.size() - 1:
			if not planner.segment_clear(points[i], points[i + 1]): clear = false; break
		if clear: continue
		var path := planner.path(points[0], points[-1], false)
		if path.is_empty(): continue # Preserve user placements; editor validation reports obstructions.
		path.resize(maxi(0, path.size() - 1))
		route.via = path
		changed = true
	if changed:
		_layout._prepared = false
		background.texture = WorldTerrain._make_terrain_texture(_layout)
	for node in get_tree().get_nodes_in_group("flowers"):
		if is_ancestor_of(node): node.visible = WorldComposition.allowed(self, _layout, node.global_position, 0.5)
	WorldComposition.refresh(self, _layout)
	_resolving_routes = false


func safe_spawn(at: Vector2, radius: float = 0.45) -> Vector2:
	var query := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius + 0.08
	query.shape = circle
	query.collision_mask = 1
	for ring in SPAWN_SEARCH_RINGS:
		for step in (1 if ring == 0 else SPAWN_SEARCH_DIRECTIONS):
			var candidate := at + Vector2.from_angle(float(step) * TAU / float(SPAWN_SEARCH_DIRECTIONS)) * float(ring) * SPAWN_SEARCH_STEP
			if not MAP_RECT.grow(-radius).has_point(candidate) or WorldTerrain.is_sea(candidate): continue
			if _authored_map and (_authored_map.water_cell(Vector2i(candidate.floor())) or not _authored_map.cell("Collision", Vector2i(candidate.floor())).is_empty()): continue
			var blocked := false
			for tree in _forest_trees:
				if is_instance_valid(tree) and tree.is_alive() and candidate.distance_to(tree.position + Vector2(0, -0.2)) < radius + 0.6:
					blocked = true; break
			if blocked: continue
			for entry in _layout.anchors:
				if entry.get("kind", "") not in ["house", "shop", "residence", "ruin"]: continue
				if _layout.world_footprint(str(entry.id)).grow(radius).has_point(candidate): blocked = true; break
			if blocked: continue
			query.transform = Transform2D(0.0, candidate)
			if get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty(): return candidate
	return at


func _sync_village_pets() -> void:
	for id in GameState.data.get("village_pets", []):
		var exists := false
		for child in get_children():
			if child is VillagePet and child.pet_id == str(id):
				exists = true
		if exists:
			continue
		var guardian := VillagePet.new()
		guardian.pet_id = str(id)
		var slot: int = GameState.data.get("village_pets", []).find(id)
		guardian.home = _player_spawn + Vector2((slot % 3 - 1) * 1.8, 2.0 + floorf(slot / 3.0))
		guardian.position = guardian.home
		add_child(guardian)


func _sync_rescued_friends() -> void:
	if not is_node_ready(): return
	var story := GameState.campaign()
	for id in ["arjun", "mei_ling"]:
		if not bool(story.get(id + "_rescued", false)): continue
		var game := get_tree().get_first_node_in_group("game") as Game
		if id == "arjun" and is_instance_valid(game) and game._arjun_returning: continue
		var exists := false
		for child in get_children():
			if child is VillageHero and child.hero_id == id: exists = true
		if exists: continue
		var friend := VillageHero.new()
		friend.hero_id = id
		friend.home = _house_position + Vector2(-3 if id == "arjun" else 3, 3)
		friend.position = friend.home
		add_child(friend)
