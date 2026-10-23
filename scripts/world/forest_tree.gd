class_name ForestTree
extends Node2D
## A protected village tree. Raiders target these during settlement emergencies;
## the player can defend them by clearing the attackers.

signal felled(tree: ForestTree)

@export var tree_id := ""
@export var tree_name := "Forest tree"
@export var max_health := 100

var health := 100
var fallen := false
var hit_count := 0

var _visuals: Array[CanvasItem] = []
var _flash_timer := 0.0


func _ready() -> void:
	add_to_group("settlement_target")
	add_to_group("forest_tree")
	health = GameState.forest_tree_health(tree_id, max_health) if tree_id != "" else max_health
	z_index = 6
	light_mask = 0
	if health <= 0:
		_apply_initial_fall()
	else:
		queue_redraw()


func register_visual(node: CanvasItem) -> void:
	_visuals.append(node)


func take_attack_damage(amount: int) -> void:
	if fallen:
		return
	hit_count += 1
	health = maxi(0, health - maxi(1, amount))
	if tree_id != "":
		GameState.set_forest_tree_health(tree_id, health, max_health)
	_flash_timer = 0.3
	for visual in _visuals:
		if is_instance_valid(visual):
			visual.modulate = Color(1.45, 1.1, 0.8)
	_spawn_impact_feedback()
	queue_redraw()
	if health <= 0:
		_fell()


func _process(delta: float) -> void:
	if _flash_timer <= 0.0:
		return
	_flash_timer = maxf(0.0, _flash_timer - delta)
	if _flash_timer <= 0.0 and not fallen:
		for visual in _visuals:
			if is_instance_valid(visual):
				visual.modulate = Color(0.76, 0.9, 0.74)


func _spawn_impact_feedback() -> void:
	Sfx.play("tree_hit", -5.0)
	if _visuals.is_empty() or not is_inside_tree():
		return
	if not GameSettings.reduce_motion():
		for visual in _visuals:
			if is_instance_valid(visual):
				var shake := visual.create_tween()
				shake.tween_property(visual, "position:x", 0.04, 0.04)
				shake.tween_property(visual, "position:x", -0.03, 0.04)
				shake.tween_property(visual, "position:x", 0.0, 0.05)
	Vfx.leaves(global_position + Vector2(0, -1.8), 2)


func is_alive() -> bool:
	return not fallen and health > 0


func _fell() -> void:
	if fallen:
		return
	fallen = true
	remove_from_group("settlement_target")
	remove_from_group("forest_tree")
	felled.emit(self)
	for visual in _visuals:
		if is_instance_valid(visual):
			visual.modulate = Color("#7d6547")
	var body := get_node_or_null("Body") as StaticBody2D
	if body != null:
		body.set_deferred("collision_layer", 0)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.08, 0.42), 0.8)
	tween.tween_property(self, "rotation", 0.22, 0.8)
	tween.tween_property(self, "modulate:a", 0.72, 0.8)
	queue_redraw()


func _apply_initial_fall() -> void:
	fallen = true
	remove_from_group("settlement_target")
	remove_from_group("forest_tree")
	scale = Vector2(1.08, 0.42)
	rotation = 0.22
	modulate = Color(0.7, 0.66, 0.6, 0.72)
	var body := get_node_or_null("Body") as StaticBody2D
	if body != null:
		body.set_deferred("collision_layer", 0)
	queue_redraw()


func _draw() -> void:
	if fallen or health >= max_health:
		return
	var ratio := clampf(float(health) / float(maxi(1, max_health)), 0.0, 1.0)
	var bar := Rect2(-0.75, -3.1, 1.5, 0.12)
	draw_rect(bar.grow(0.04), Color(0.02, 0.04, 0.04, 0.88))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)), Color("#7fcf67").lerp(Color("#df525d"), 1.0 - ratio))
	draw_rect(bar, Color(0.75, 0.8, 0.72, 0.55), false, 0.02)
