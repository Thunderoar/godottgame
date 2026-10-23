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
	z_index = 3
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
	var shake := create_tween()
	shake.tween_property(self, "position:x", position.x + 0.07, 0.04)
	shake.tween_property(self, "position:x", position.x - 0.05, 0.04)
	shake.tween_property(self, "position:x", position.x, 0.05)
	for i in 3:
		var leaf := Sprite2D.new()
		leaf.texture = PixelArt.leaf_texture()
		leaf.scale = Vector2(0.030, 0.030)
		leaf.modulate = Color("#c7e07a") if i % 2 == 0 else Color("#ffb45f")
		leaf.z_as_relative = false
		leaf.z_index = 720
		leaf.global_position = global_position + Vector2(randf_range(-0.5, 0.5), -1.7 - float(i) * 0.25)
		get_parent().add_child(leaf)
		leaf.global_position = leaf.global_position
		var tween := leaf.create_tween().set_parallel(true)
		tween.tween_property(leaf, "modulate:a", 0.0, 0.36 + float(i) * 0.06)
		tween.tween_property(leaf, "position:y", leaf.position.y - 0.75 - float(i) * 0.2, 0.36 + float(i) * 0.06)
		tween.tween_property(leaf, "position:x", leaf.position.x + randf_range(-0.35, 0.35), 0.36 + float(i) * 0.06)
		tween.chain().tween_callback(leaf.queue_free)


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
		body.collision_layer = 0
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
		body.collision_layer = 0
	queue_redraw()


func _draw() -> void:
	if fallen or health >= max_health:
		return
	var ratio := clampf(float(health) / float(maxi(1, max_health)), 0.0, 1.0)
	var bar := Rect2(-0.75, -3.1, 1.5, 0.12)
	draw_rect(bar.grow(0.04), Color(0.02, 0.04, 0.04, 0.88))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)), Color("#7fcf67").lerp(Color("#df525d"), 1.0 - ratio))
	draw_rect(bar, Color(0.75, 0.8, 0.72, 0.55), false, 0.02)
