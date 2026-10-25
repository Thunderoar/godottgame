class_name BeachRubbish
extends Interactable
## A beached piece has exactly one paid, distance-checked manual collection.
var collected := false
const REWARD := 1

func _ready() -> void:
	show_marker = false
	prompt = "Pick Up Rubbish (+1 Gold)"
	interact_radius = 1.8
	super._ready()
	add_to_group("beach_rubbish")
	z_index = 5
	var sprite := Sprite2D.new()
	sprite.texture = PixelArt.rubbish_texture(0)
	sprite.scale = Vector2.ONE * PixelArt.PX * 1.8
	add_child(sprite)

func interact(player: Node) -> void:
	if collected or not available or not is_instance_valid(player) or GameState.game_over_active:
		return
	if player.global_position.distance_to(global_position) > interact_radius:
		return
	var game := get_tree().get_first_node_in_group("game") as Game
	if not is_instance_valid(game) or game.player() != player or game._input_locked:
		return
	collected = true
	available = false
	GameState.register_rubbish_cleaned(REWARD)
	player.play_pickup()
	Sfx.play("coin", -10.0)
	queue_free()
