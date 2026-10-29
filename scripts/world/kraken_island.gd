class_name KrakenIsland
extends Node2D
## Portal-style fortress arena on the Kraken King's island.
var zone_name := "Kraken King's Island"
var player: Player
var camera: Camera2D
var boss: KrakenKing
var cage: RescueCage
var background: Sprite2D
var canvas_modulate: CanvasModulate
var defeated := false
var _rescuing := false
var _hint: Label
var _rune_clock := 0.0
var _monster_routes: ResidentRoutes
const RUNES := [Vector2(6,4.5),Vector2(34,4.5),Vector2(10,14.5),Vector2(30,14.5)]

func _ready() -> void:
	texture_filter=VisualStyle.texture_filter()
	add_to_group("world")
	Vfx.ensure_pool(self)
	_build_arena()
	for edge in [Rect2(0,1,40,1),Rect2(0,1,1,24),Rect2(39,1,1,24),Rect2(0,24,40,1)]:
		var body := StaticBody2D.new()
		body.collision_layer = 1
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = edge.size
		shape.shape = rect
		body.position = edge.get_center()
		body.add_child(shape)
		add_child(body)
	player = Player.new()
	player.position = Vector2(17.5,20.8)
	add_child(player)
	camera = Camera2D.new()
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	camera.position = Vector2(20,12.5)
	add_child(camera)
	camera.make_current()
	_fit_camera()
	get_viewport().size_changed.connect(_fit_camera)
	boss = KrakenKing.new()
	boss.position = Vector2(21,9.3)
	boss.boss_finished.connect(_on_kraken_defeated)
	add_child(boss)
	cage = RescueCage.new()
	cage.name = "ArjunPrison"
	cage.island = self
	cage.position = Vector2(32,8)
	cage.prompt = "Free Arjun"
	cage.available = false
	cage.interact_radius = 2.6
	add_child(cage)
	boss.prison = cage
	var exit := IslandExit.new()
	exit.position = Vector2(5,22)
	exit.prompt = "Return to BESUT"
	add_child(exit)
	var shore := Sprite2D.new()
	shore.texture = CoastalArt.turtle_texture()
	shore.scale = Vector2.ONE * PixelArt.PX
	shore.position = Vector2(4,22.4)
	add_child(shore)
	_build_hint()
	if bool(GameState.campaign().get("arjun_rescued",false)):
		cage.opened = true
		cage.friend.visible = false
		_hint.text = "Arjun is safe in BESUT. Challenge the Kraken King or return to shore."
	Sfx.start_battle_music("kraken_island")

func _build_arena() -> void:
	var painter := Dungeon.new()
	painter.portal_id = "kraken_reference_arena"
	painter.map_rect = get_map_rect()
	painter._definition = {"theme":"grotto"}
	background = Sprite2D.new()
	background.name = "PortalStoneFloor"
	background.texture = painter._make_dungeon_texture()
	background.centered = false
	background.scale = Vector2.ONE * PixelArt.PX
	background.z_as_relative = false
	background.z_index = -1000
	add_child(background)
	if not VisualStyle.is_pixel():
		var floor_art := Sprite2D.new()
		floor_art.name="KrakenStoneFloor"
		floor_art.texture=load("res://assets/authored/realms/basalt-floor-v2.png") as Texture2D
		floor_art.position=Vector2(20,13)
		floor_art.scale=Vector2(37,22)/floor_art.texture.get_size()
		floor_art.z_as_relative=false
		floor_art.z_index=-999
		var floor_material := RealmPresentation.floor_material("water")
		floor_material.set_shader_parameter("motion",false)
		floor_art.material=floor_material
		add_child(floor_art)
	painter.free()
	canvas_modulate = CanvasModulate.new()
	canvas_modulate.name = "FortressDarkness"
	canvas_modulate.color = Color("#7d84a0").lightened(0.18)
	add_child(canvas_modulate)
	for at in [Vector2(6,8),Vector2(34,8),Vector2(10,18),Vector2(30,18)]:
		var holder := Node2D.new()
		holder.name = "ArenaPillar"
		holder.position = at
		add_child(holder)
		var sprite := Sprite2D.new()
		sprite.texture = ElementalArt.pillar_texture("water")
		sprite.centered = false
		var extent := sprite.texture.get_size()
		sprite.offset = Vector2(-extent.x*0.5,-extent.y)
		sprite.scale = Vector2.ONE * PixelArt.PX * 64.0/extent.y * 1.3
		sprite.modulate = Color("#bac3d2")
		holder.add_child(sprite)
		var body := StaticBody2D.new()
		body.collision_layer = 1
		var collision := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 0.55
		collision.shape = circle
		collision.position.y = -0.3
		body.add_child(collision)
		holder.add_child(body)
	for at in RUNES:
		var glow := PointLight2D.new()
		glow.texture = PixelArt.light_texture()
		glow.texture_scale = 0.05
		glow.energy = 0.22
		glow.color = Color("#ae85d3")
		glow.position = at
		glow.enabled = GameSettings.effects_at_least("med")
		add_child(glow)

func _build_hint() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	_hint = GameUI.label("Defeat the Kraken King, then tap Arjun's prison.",16,GameUI.GOLD)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_hint.add_theme_color_override("font_shadow_color",Color.BLACK)
	_hint.add_theme_constant_override("shadow_offset_x",1)
	_hint.add_theme_constant_override("shadow_offset_y",2)
	_hint.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_hint.offset_left = 24
	_hint.offset_right = 354
	_hint.offset_top = 82
	_hint.offset_bottom = 150
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_hint)

func get_player() -> Player:
	return player

func get_map_rect() -> Rect2:
	return Rect2(0,0,40,25)

func monster_path(from: Vector2, destination: Vector2) -> PackedVector2Array:
	if _monster_routes == null:
		_monster_routes = ResidentRoutes.new(self, get_map_rect())
		_monster_routes.clearance = boss.body_radius + 0.15
	return _monster_routes.path(from, destination)

func get_guidance_targets() -> Array:
	return [{"label":"FREE ARJUN" if defeated else "KRAKEN KING","position":cage.position if defeated else boss.position,"color":GameUI.GOLD}]

func _on_kraken_defeated(_enemy: Enemy) -> void:
	if defeated: return
	defeated = true
	cage.available = not bool(GameState.campaign().get("arjun_rescued",false))
	_hint.text = "The Kraken King is defeated! Approach and tap Arjun's prison." if cage.available else "The Kraken King is defeated. Arjun is safe in BESUT; return to shore."
	var drop := cage.create_tween()
	drop.tween_property(cage,"position:y",cage.position.y+0.45,0.45).set_trans(Tween.TRANS_BOUNCE)
	Sfx.stop_battle_music()

func free_arjun() -> void:
	if not defeated or _rescuing or not is_instance_valid(player) or bool(GameState.campaign().get("arjun_rescued",false)): return
	_rescuing = true
	player.controls_locked = true
	cage.opened = true
	cage.available = false
	GameState.rescue_friend("arjun")
	var game := get_tree().get_first_node_in_group("game") as Game
	if is_instance_valid(game):
		game._arjun_returning = true
		await game.play_story("arjun")
		if is_instance_valid(game) and game.world == self: game.return_from_ocean()

func _process(delta: float) -> void:
	if not GameSettings.reduce_motion(): _rune_clock += delta
	queue_redraw()

func _draw() -> void:
	for at in RUNES:
		var rune := Color("#9f72c3")
		rune.a = 0.8 + sin(_rune_clock*1.3+at.x)*0.07
		draw_arc(at,2.1,0,TAU,48,rune,0.075)
		for i in 8:
			var axis := Vector2.from_angle(TAU*i/8.0)
			draw_line(at+axis*0.85,at+axis*1.12,rune,0.055)

func _fit_camera() -> void:
	var view := get_viewport_rect().size
	camera.zoom = Vector2.ONE * minf(view.x/42.0,view.y/27.6)

class RescueCage extends Interactable:
	var island: KrakenIsland
	var opened := false
	var friend: Sprite2D
	func _ready() -> void:
		z_index = 7
		super._ready()
		friend = Sprite2D.new()
		friend.texture = PixelArt.character_texture("arjun",0)
		friend.scale = Vector2.ONE * PixelArt.PX * 1.4
		friend.position.y = -1.1
		friend.show_behind_parent = true
		add_child(friend)
		var glow := PointLight2D.new()
		glow.texture = PixelArt.light_texture()
		glow.texture_scale = 0.045
		glow.energy = 0.3
		glow.color = Color("#e9c98d")
		glow.position = Vector2(0,-1.3)
		add_child(glow)
	func _process(delta: float) -> void:
		super._process(delta)
		queue_redraw()
	func _draw() -> void:
		draw_texture_rect(KrakenArt.prison_texture(opened),Rect2(-1.75,-3.8,3.5,4.125),false)
	func interact(actor: Node) -> void:
		if available and is_instance_valid(actor) and actor.global_position.distance_to(global_position) <= interact_radius: island.free_arjun()

class IslandExit extends Interactable:
	func interact(_actor: Node) -> void:
		var game := get_tree().get_first_node_in_group("game") as Game
		if is_instance_valid(game): game.return_from_ocean()
