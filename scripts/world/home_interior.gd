class_name HomeInterior
extends Node2D

var game: Game
var _heal := 0.0
var _exit: Interactable
var _status: Label
var _leaving := false
var _floor_texture: Texture2D
const EXIT_FOOTPRINT := Rect2(-1.3, 3.7, 2.6, 1.5)

func _ready() -> void:
	texture_filter=VisualStyle.texture_filter()
	if not VisualStyle.is_pixel() and ResourceLoader.exists("res://assets/authored/illustrated/wood-floor.png"):
		_floor_texture=load("res://assets/authored/illustrated/wood-floor.png") as Texture2D
	z_index = 0
	position = Vector2(96, 24)
	var walls := StaticBody2D.new()
	walls.collision_layer = 1
	add_child(walls)
	for box in [Rect2(-7, -5, 14, 0.5), Rect2(-7, -5, 0.5, 10), Rect2(6.5, -5, 0.5, 10), Rect2(-7, 4.5, 5.4, 0.5), Rect2(1.6, 4.5, 5.4, 0.5)]:
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = box.size
		shape.shape = rectangle
		shape.position = box.get_center()
		walls.add_child(shape)
	_exit = HomeExit.new()
	_exit.position = Vector2(0, 4)
	add_child(_exit)
	_status = Label.new()
	_status.text = "HOME\nRest here to recover"
	_status.position = Vector2(-3.25, -4.0)
	_status.scale = Vector2.ONE * PixelArt.PX
	_status.size = Vector2(208, 48)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_font_size_override("font_size", 14)
	_status.add_theme_color_override("font_color", Color("#ffdda0"))
	add_child(_status)
	var accessories := {"chest": Vector2(-4.7, -1.3), "wardrobe": Vector2(4.7, -1.3), "weapons": Vector2(4.7, 2.0), "pet_bed": Vector2(-4.7, 3.2)}
	for kind in accessories:
		var decoration := Sprite2D.new()
		decoration.name = "Home_" + str(kind)
		decoration.texture = PixelArt.home_accessory_texture(str(kind))
		decoration.scale = Vector2.ONE * PixelArt.PX * 1.25
		decoration.position = accessories[kind]
		decoration.offset = Vector2(0, -32)
		decoration.add_to_group("home_accessories")
		decoration.set_meta("accessory", kind)
		add_child(decoration)
	var bed := HouseBed.new()
	bed.name = "MainHouseBed"
	bed.position = Vector2(-3.4, -1.0)
	bed.add_to_group("home_beds")
	add_child(bed)
	var table := Sprite2D.new()
	table.texture = RealisticArt.get_texture("realistic/home_table")
	if table.texture==null: table.texture=PixelArt.icon("food")
	table.scale = Vector2.ONE * PixelArt.PX
	table.position = Vector2(3, 0)
	add_child(table)

func _process(delta: float) -> void:
	if not is_instance_valid(game) or game.home_interior != self or GameState.game_over_active:
		return
	_exit.available = not GameState.recovery_active()
	var player := game.player()
	if not _leaving and not game._transitioning and not game._input_locked and _exit.available and is_instance_valid(player) and not player.dead and EXIT_FOOTPRINT.has_point(to_local(player.global_position)):
		_leaving = true
		game.leave_home()
		return
	if GameState.health() < GameState.health_max():
		_heal += float(GameState.health_max()) / GameState.sleep_recovery_seconds() * delta
		var amount := floori(_heal)
		if amount > 0:
			_heal -= amount
			GameState.heal(amount)
		_status.text = "HOME\nRecovering %d/%d HP" % [GameState.health(), GameState.health_max()]
	else:
		if GameState.recovery_active():
			GameState.finish_recovery()
		_status.text = "HOME\nFully healed. Walk through the doorway."

func _draw() -> void:
	draw_rect(Rect2(-7, -5, 14, 10), Color("#302c31"))
	draw_rect(Rect2(-6.5, -4.5, 13, 9), Color("#8a6546"))
	if _floor_texture:
		draw_texture_rect(_floor_texture,Rect2(-6.5,-4.5,13,9),false)
	else:
		for y in range(-4, 5):
			draw_line(Vector2(-6.5, y), Vector2(6.5, y), Color("#624831"), 0.055)
	draw_rect(Rect2(-7, -5, 14, 1.2), Color("#48505b"))
	if _floor_texture:
		draw_texture_rect(_floor_texture,Rect2(-6.5,-5,13,1.2),false,Color("#8b7963"))
	for x in [-4, 4]:
		draw_rect(Rect2(x - 0.7, -4.8, 1.4, 0.8), Color("#b6d5d3"))
		draw_line(Vector2(x, -4.8), Vector2(x, -4), Color("#4c504f"), 0.09)
	draw_rect(Rect2(-2.5, -1.8, 5, 4), Color("#754852"))
	draw_rect(Rect2(-2.3, -1.6, 4.6, 3.6), Color("#ad7666"), false, 0.12)

	draw_rect(Rect2(-1.6, 4.4, 3.2, 0.6), Color("#d6b87b"))

class HomeExit extends Interactable:
	func _ready() -> void:
		super._ready()
		prompt = "Leave Home"
		interact_radius = 2.0

	func interact(_player: Node) -> void:
		var game := get_tree().get_first_node_in_group("game") as Game
		if is_instance_valid(game) and available:
			game.leave_home()

	func _unhandled_input(event: InputEvent) -> void:
		var point := Vector2.ZERO
		var pressed := false
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			point = event.position
			pressed = true
		elif event is InputEventScreenTouch and event.pressed:
			point = event.position
			pressed = true
		if pressed and available and get_global_transform_with_canvas().origin.distance_to(point) < 65:
			interact(null)
			get_viewport().set_input_as_handled()
