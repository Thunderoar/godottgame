class_name SettlementTarget
extends Node2D
## Marks a building as an emergency attack target. Damage is kept in GameState
## so it survives scene changes and saves.

@export var target_name := "Building"
@export var damage_scale := 0.35

var _flash_timer := 0.0


func _ready() -> void:
	add_to_group("settlement_target")
	z_index = 1


func take_attack_damage(amount: int) -> void:
	if not GameState.emergency_active():
		return
	var damage := maxi(1, int(round(float(amount) * damage_scale)))
	GameState.damage_settlement(damage)
	_flash_timer = 0.35
	var spark := Sprite2D.new()
	spark.texture = PixelArt.icon("spark")
	spark.scale = Vector2(0.05, 0.05)
	spark.modulate = Color("#ff9b58")
	spark.z_as_relative = false
	spark.z_index = 720
	spark.global_position = global_position + Vector2(0, -0.5)
	get_parent().add_child(spark)
	var tween := spark.create_tween().set_parallel(true)
	tween.tween_property(spark, "modulate:a", 0.0, 0.3)
	tween.tween_property(spark, "position:y", spark.position.y - 0.6, 0.3)
	tween.chain().tween_callback(spark.queue_free)
