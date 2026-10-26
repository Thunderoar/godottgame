class_name VillageMinimap
extends Control
## Picture-only map. Compact mode opens the larger map with mouse or touch.
signal activated
var expanded := false
var _clock := 0.0
var _tick := 0.0
var _pointer := -2

func _ready() -> void:
	custom_minimum_size = Vector2(206, 144) if not expanded else custom_minimum_size.max(Vector2(280, 240))
	mouse_filter = Control.MOUSE_FILTER_IGNORE if expanded else Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE if expanded else Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not expanded else Control.CURSOR_ARROW
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _gui_input(event: InputEvent) -> void:
	if expanded: return
	if event.is_action_pressed("ui_accept"):
		activated.emit()
		accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed: _pointer = event.index
		elif _pointer == event.index:
			_pointer = -2
			if Rect2(Vector2.ZERO, size).has_point(event.position): activated.emit()
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed: _pointer = -1
		elif _pointer == -1:
			_pointer = -2
			if Rect2(Vector2.ZERO, size).has_point(event.position): activated.emit()
		accept_event()

func _process(delta: float) -> void:
	_clock += delta
	_tick += delta
	if _tick >= 0.15:
		_tick = 0
		queue_redraw()

func _area(bounds: Rect2) -> Rect2:
	var available := (size - Vector2(16, 16)).max(Vector2.ONE)
	var factor := minf(available.x / bounds.size.x, available.y / bounds.size.y)
	var extent := bounds.size * factor
	return Rect2((size - extent) / 2, extent)

func _map(point: Vector2, bounds: Rect2) -> Vector2:
	var area := _area(bounds)
	return area.position + ((point - bounds.position) / bounds.size).clamp(Vector2.ZERO, Vector2.ONE) * area.size

func map_icons(world: Node2D) -> Array[Dictionary]:
	var icons: Array[Dictionary] = []
	if world is Lobby:
		for anchor in world._layout.anchors:
			var id := str(anchor.get("id", ""))
			var kind := str(anchor.get("kind", ""))
			var texture: Texture2D
			var priority := 1
			var theme := ""
			if kind == "shop":
				texture = PixelArt.stall_texture(id.trim_prefix("shop_"))
				priority = 3
			elif id in ["monster_portal", "pet_portal"]:
				theme = "pet" if id == "pet_portal" else "grotto"
				texture = PixelArt.portal_frame_texture(theme)
				priority = 4
			elif id == "jetty_deck":
				texture = PixelArt.dock_texture()
				priority = 3
			elif id == "house":
				texture = PixelArt.house_texture(GameState.house_level())
				priority = 3
			elif kind in ["residence", "ruin"]: texture = PixelArt.house_texture(1)
			elif kind == "garden": texture = PixelArt.garden_texture()
			if texture:
				icons.append({"id": id, "position": world._layout.position_of(id), "texture": texture, "priority": priority, "theme": theme})
		if is_instance_valid(world.ship_boarding) and is_instance_valid(world.ship_boarding.ship):
			icons.append({"id": "ship", "position": world.ship_boarding.ship.global_position, "texture": PixelArt.ship_texture(), "priority": 3, "theme": ""})
	elif world is Dungeon:
		icons.append({"id": "exit", "position": Vector2(24, 30.1), "texture": PixelArt.portal_texture("tidebound_grotto"), "priority": 3, "theme": ""})
		if is_instance_valid(world.boss) and not world.boss.dead:
			icons.append({"id": "boss", "position": world.boss.position, "texture": PixelArt.enemy_texture(world.boss.kind, true), "priority": 4, "theme": ""})
	elif world is KrakenIsland:
		icons.append({"id": "prison", "position": world.cage.position, "texture": PixelArt.icon("lock"), "priority": 3, "theme": ""})
		if is_instance_valid(world.boss) and not world.boss.dead:
			icons.append({"id": "kraken", "position": world.boss.position, "texture": CampaignArt.kraken_texture(), "priority": 4, "theme": ""})
	icons.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.priority) < int(b.priority))
	return icons

func _picture(icon: Dictionary, at: Vector2) -> void:
	var texture := icon.texture as Texture2D
	var extent := (42.0 if expanded else 15.0) * (0.65 if int(icon.priority) == 1 else 1.0)
	var dimensions := texture.get_size()
	var fitted := dimensions * extent / maxf(dimensions.x, dimensions.y)
	var rect := Rect2(at - fitted / 2, fitted)
	if int(icon.priority) >= 3: draw_circle(at, extent * 0.52, Color(0.025, 0.08, 0.10, 0.66))
	var theme := str(icon.get("theme", ""))
	if not theme.is_empty():
		var swirl := PixelArt.portal_swirl_texture(theme, 0)
		var scale := fitted / dimensions
		draw_texture_rect(swirl, Rect2(rect.position + Vector2(16, 20) * scale, swirl.get_size() * scale), false)
	draw_texture_rect(texture, rect, false)

func _draw() -> void:
	draw_style_box(GameUI.style(Color("#122c32"), Color("#73928b"), 2, 0), Rect2(Vector2.ZERO, size))
	var game := get_tree().get_first_node_in_group("game") as Game
	if not is_instance_valid(game) or not is_instance_valid(game.world): return
	var world := game.world
	var bounds: Rect2 = world.get_map_rect() if world.has_method("get_map_rect") else Rect2(0, 0, 64, 40)
	var area := _area(bounds)
	if world is Lobby or world is Dungeon:
		draw_texture_rect(world.background.texture, area, false)
	else:
		draw_rect(area, Color("#285a77"))
		if world is KrakenIsland:
			draw_rect(Rect2(_map(Vector2(1, 3), bounds), Vector2(38, 21) / bounds.size * area.size), Color("#958968"))
	for icon in map_icons(world): _picture(icon, _map(icon.position, bounds))
	if int(_clock * 4) % 2 == 0:
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(enemy) or enemy.is_queued_for_deletion() or enemy.get_parent() != world or enemy.dead: continue
			var target: Node2D = enemy.get("_target")
			if is_instance_valid(target) and enemy.global_position.distance_to(target.global_position) < 5:
				var at := _map(target.global_position, bounds)
				draw_circle(at, 6 if expanded else 4, Color("#ff5858"))
				draw_arc(at, 10 if expanded else 7, 0, TAU, 16, Color("#ff8787"), 1.5)
		if world is Lobby:
			for tree in world._forest_trees:
				if is_instance_valid(tree) and tree.burning and tree.is_alive(): draw_circle(_map(tree.global_position, bounds), 6 if expanded else 4, Color("#ff5858"))
		if GameState.emergency_active(): draw_rect(area, Color("#ff6565"), false, 2)
	var player := game.player()
	if is_instance_valid(player) and not is_instance_valid(game.home_interior):
		var at := _map(player.global_position, bounds)
		draw_arc(at, 9 if expanded else 5, 0, TAU, 16, Color("#7dffff"), 2)
		_picture({"texture": PixelArt.character_texture(str(GameState.data.get("character_id", "adam")), 0), "priority": 4, "theme": ""}, at)
