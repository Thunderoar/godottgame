class_name KrakenCrab
extends Enemy
## Fortress guards reuse the regular melee telegraph, damage and loot lifecycle.
var retreating := false

func _ready() -> void:
	kind = "crab"
	max_hp = 48
	damage = 7
	speed = 2.0
	body_radius = 0.55
	xp_reward = 8
	gold_reward = 6
	diamond_chance = 0.0
	attack_interval = 1.6
	dungeon_alerted = true
	super._ready()

func _physics_process(delta: float) -> void:
	var game := get_tree().get_first_node_in_group("game") as Game
	var island := get_parent() as KrakenIsland
	if retreating or not is_instance_valid(game) or game.world != island or not is_instance_valid(island) or island.defeated or island._rescuing:
		velocity = Vector2.ZERO
		return
	super._physics_process(delta)

func _personality_for(_kind_id: String) -> Dictionary:
	return {"skitter": 0.4, "skitter_rate": 0.5}

func _sprite_rest_scale() -> Vector2:
	return Vector2.ONE * PixelArt.PX * 1.75

func _sprite_rest_position() -> Vector2:
	return Vector2(0,-0.875)

func _draw() -> void:
	if dead or hp >= max_hp: return
	draw_rect(Rect2(-0.47,-1.8,0.94,0.14),Color("#17282e"))
	draw_rect(Rect2(-0.45,-1.78,0.9 * float(hp)/max_hp,0.1),Color("#d75a58"))

func retreat() -> void:
	if retreating or dead: return
	retreating = true
	set_physics_process(false)
	velocity = Vector2.ZERO
	collision_layer = 0
	remove_from_group("enemies")
	_clear_windup_pose()
	_telegraph.hide()
	var escape := create_tween().set_parallel(true)
	escape.tween_property(self,"modulate:a",0.0,0.45)
	if not GameSettings.reduce_motion():
		escape.tween_property(self,"position:x",position.x + (-1.8 if position.x < 20 else 1.8),0.45)
	escape.chain().tween_callback(queue_free)
