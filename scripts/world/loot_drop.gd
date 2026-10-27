class_name LootDrop
extends Interactable
## Loot is collected automatically when the player touches it. There is no
## collect button and these do not join the interaction prompt group.

@export var kind := "gold"
@export var amount := 10
@export var item_id := ""

const MAGNET_RADIUS := 4.0
const MAGNET_SPEED := 10.0
var attracting := false
var pop_velocity := Vector2.ZERO

var _sprite: Sprite2D
var _label: Label
var _t := 0.0


func _ready() -> void:
	available = false
	interact_radius = 0.9
	show_marker = false
	collision_layer = 0
	collision_mask = 0
	monitoring = false
	monitorable = false
	_sprite = Sprite2D.new()
	_sprite.texture = PixelArt.loot_texture(kind if kind != "item" else item_id)
	_sprite.scale = Vector2(0.045, 0.045)
	_sprite.position = Vector2(0, -0.18)
	_sprite.z_index = 5
	add_child(_sprite)
	_label = Label.new()
	_label.text = str(amount) if kind != "item" else ""
	_label.add_theme_font_size_override("font_size", 11)
	_label.add_theme_color_override("font_color", Color("#ffe08a") if kind == "gold" else Color("#9ff3ff"))
	_label.scale = Vector2(0.028, 0.028)
	_label.position = Vector2(-0.15, -0.55)
	add_child(_label)


func _physics_process(delta: float) -> void:
	_t += delta
	if _t >= 0.4:
		pop_velocity = Vector2.ZERO
	if pop_velocity.length_squared() > 0.0005:
		# Short spit-arc out of a defeated body, decaying quickly.
		global_position += pop_velocity * delta
		pop_velocity = pop_velocity.move_toward(Vector2.ZERO, delta * 7.0)
		pop_velocity.y += delta * 3.0
	if _sprite:
		_sprite.position.y = -0.18 + sin(_t * 3.2) * 0.06
	var game := get_tree().get_first_node_in_group("game") as Game
	var player := game.player() if is_instance_valid(game) and game.world == get_parent() else null
	if player != null and is_instance_valid(player):
		if player.dead: return
		var distance := global_position.distance_to(player.global_position)
		if kind in ["gold","diamond"] and (attracting or distance <= MAGNET_RADIUS):
			attracting = true
			pop_velocity = Vector2.ZERO
			global_position = global_position.move_toward(player.global_position,MAGNET_SPEED * delta)
		if global_position.distance_to(player.global_position) <= (0.35 if attracting else 0.9):
			_collect()


func _collect() -> void:
	if is_queued_for_deletion():
		return
	if GameState.expedition_active():
		if kind == "item":
			GameState.add_expedition_loot("item", amount, item_id)
		elif kind == "diamond":
			GameState.add_expedition_loot("diamonds", amount)
		else:
			GameState.add_expedition_loot("gold", amount)
	else:
		if kind == "gold":
			GameState.add_gold(amount)
		elif kind == "diamond":
			GameState.add_diamonds(amount)
		elif kind == "item":
			GameState.add_item(item_id, amount)
	GameState.toast_requested.emit("Collected %s." % _loot_label(), "gold")
	queue_free()


func interact(_player: Node) -> void:
	_collect()


func _loot_label() -> String:
	if kind == "item":
		return "%dx %s" % [amount, ItemDB.name_of(item_id)]
	return "%d %s" % [amount, "diamonds" if kind == "diamond" else "gold"]
