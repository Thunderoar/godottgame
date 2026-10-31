class_name ShopNPC
extends Interactable
## A merchant or service NPC. The world places a stall behind it; this node is
## just the person and interaction point. Names are intentionally not floating
## over NPCs; their identity appears only when the interaction panel opens.

@export var shop_type := "potion"
@export var npc_kind := "potion"
@export var npc_name := "Mara"

var sprite: Sprite2D
var _customer: WeakRef
var ambient_sales := 0
var expression := MicroAction.new()
var _greet_clock := 0.0
var _was_near := false


func _ready() -> void:
	super._ready()
	add_to_group("ambient_shop")
	prompt = "Open %s shop" % npc_name
	touch_verb = "Enter"
	_build()


func _unhandled_input(event: InputEvent) -> void:
	var pressed := false
	var screen_position := Vector2.ZERO
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		pressed = true
		screen_position = event.position
	elif event is InputEventScreenTouch and event.pressed:
		pressed = true
		screen_position = event.position
	if not pressed or not available:
		return
	var game := get_tree().get_first_node_in_group("game") as Game
	if not is_instance_valid(game) or not game.world is Lobby or game._input_locked or game._game_over:
		return
	if get_parent().get_parent() != game.world or game.world._settlement_editor.active:
		return
	var world_position := get_canvas_transform().affine_inverse() * screen_position
	# Entire stall footprint, rather than a tiny merchant or Talk button.
	var local: Vector2 = get_parent().to_local(world_position)
	if Rect2(-1.8, -3.1, 3.6, 3.9).has_point(local):
		interact(game.player())
		get_viewport().set_input_as_handled()


func _build() -> void:
	var tex := PixelArt.npc_texture(npc_kind)
	sprite = Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = tex
	sprite.centered = false
	sprite.offset = Vector2(-tex.get_width() * 0.5, -tex.get_height())
	sprite.scale = Vector2(PixelArt.PX, PixelArt.PX)
	sprite.z_index = 0
	add_child(sprite)


func interact(_player: Node) -> void:
	var game := get_tree().get_first_node_in_group("game")
	if game == null:
		return
	if shop_type == "services":
		game.call("open_village_services", false)
		return
	if shop_type == "house":
		if game.has_method("open_house"):
			game.call("open_house")
		return
	if game.has_method("open_shop"):
		game.call("open_shop", shop_type, npc_name)


func customer_position() -> Vector2:
	return global_position + Vector2(0.75, 1.55)


func reserve_customer(resident: Resident) -> bool:
	if _customer != null and is_instance_valid(_customer.get_ref()) and _customer.get_ref() != resident:
		return false
	_customer = weakref(resident)
	return true


func release_customer(resident: Resident) -> void:
	if _customer != null and _customer.get_ref() == resident:
		_customer = null


func ambient_purchase() -> void:
	# Ambient exchange only. Never call GameState buy_item or open the player UI.
	ambient_sales += 1
	expression.request("shop")


func _physics_process(delta: float) -> void:
	_greet_clock -= delta
	if _greet_clock <= 0.0:
		_greet_clock = 0.5
		var game := get_tree().get_first_node_in_group("game")
		var player: Node2D = game.call("player") if game and game.has_method("player") else null
		var nearby := is_instance_valid(player) and player.global_position.distance_to(global_position) < 2.8
		if nearby and not _was_near: expression.request("greet")
		_was_near = nearby
	expression.tick(delta, GameSettings.reduce_motion())
	if sprite:
		sprite.rotation = expression.tilt
		sprite.position.y = -expression.lift
