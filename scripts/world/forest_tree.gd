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
const GROW_SECONDS := 30.0
const BURN_INTERVAL := 1.0
const BURN_DAMAGE := 2
var growth_remaining := 0.0
var burning := false
var caretaker: Node
var _burn_clock := 0.0
var _effect_clock := 0.0
var _fall_tween: Tween
var _feedback: Node2D


func _ready() -> void:
	_feedback = Node2D.new()
	_feedback.name = "TreeFeedback"
	_feedback.z_as_relative = false
	_feedback.z_index = 700
	_feedback.draw.connect(_draw_feedback)
	add_child(_feedback)
	add_to_group("settlement_target")
	add_to_group("forest_tree")
	health = GameState.forest_tree_health(tree_id, max_health) if tree_id != "" else max_health
	z_index = 6
	light_mask = 0
	growth_remaining = GameState.forest_tree_growth(tree_id)
	if growth_remaining > 0.0:
		health = max_health
		_set_growing_visual()
		return
	if health <= 0:
		_apply_initial_fall()
	else:
		queue_redraw()


func register_visual(node: CanvasItem) -> void:
	_visuals.append(node)


func take_attack_damage(amount: int) -> void:
	if not is_attackable() or GameState.game_over_active:
		return
	burning = true
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


func take_physical_damage(amount: int) -> void:
	var was_burning := burning
	take_attack_damage(amount)
	if not fallen:
		burning = was_burning
	queue_redraw()


func take_damage(amount: int, _from_dir: Vector2 = Vector2.ZERO, _source: Node = null) -> void:
	take_attack_damage(amount)


func _process(delta: float) -> void:
	if GameState.game_over_active:
		return
	_effect_clock += delta
	if growth_remaining > 0.0:
		growth_remaining = maxf(0.0, growth_remaining - delta)
		GameState.set_forest_tree_growth(tree_id, growth_remaining)
		_set_growing_visual()
		if growth_remaining <= 0.0:
			_set_body_active(true)
			add_to_group("settlement_target")
			var lobby := get_parent() as Lobby
			if lobby:
				lobby.call_deferred("invalidate_resident_routes")
		queue_redraw()
	if burning and is_attackable():
		_burn_clock += delta
		if _burn_clock >= BURN_INTERVAL:
			_burn_clock -= BURN_INTERVAL
			health = maxi(0, health - BURN_DAMAGE)
			GameState.set_forest_tree_health(tree_id, health, max_health)
			if health == 0:
				_fell()
		queue_redraw()
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


func is_attackable() -> bool:
	return is_alive() and growth_remaining <= 0.0


func replant() -> bool:
	if not fallen or GameState.game_over_active:
		return false
	if _fall_tween and _fall_tween.is_valid():
		_fall_tween.kill()
	fallen = false
	burning = false
	health = max_health
	growth_remaining = GROW_SECONDS
	rotation = 0.0
	modulate = Color.WHITE
	add_to_group("forest_tree")
	GameState.set_forest_tree_health(tree_id, health, max_health)
	GameState.set_forest_tree_growth(tree_id, growth_remaining)
	_set_growing_visual()
	queue_redraw()
	return true


func water(amount: int) -> bool:
	if not burning or not is_attackable() or GameState.game_over_active:
		return false
	health = mini(max_health, health + maxi(0, amount))
	if health == max_health:
		burning = false
		_burn_clock = 0.0
	GameState.set_forest_tree_health(tree_id, health, max_health)
	queue_redraw()
	return true


func _set_body_active(active: bool) -> void:
	var body := get_node_or_null("Body") as StaticBody2D
	if body:
		body.set_deferred("collision_layer", 1 if active else 0)


func _set_growing_visual() -> void:
	var progress := 1.0 - growth_remaining / GROW_SECONDS
	scale = Vector2.ONE * lerpf(0.15, 1.0, progress)
	_feedback.scale = Vector2.ONE / scale
	for visual in _visuals:
		if is_instance_valid(visual):
			visual.visible = true
			visual.modulate = Color(0.76, 0.9, 0.74)
	if growth_remaining > 0.0:
		remove_from_group("settlement_target")
		_set_body_active(false)


func _fell() -> void:
	if fallen:
		return
	fallen = true
	burning = false
	GameState.set_forest_tree_growth(tree_id, 0.0)
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
	_fall_tween = tween
	tween.tween_property(self, "scale", Vector2(1.08, 0.42), 0.8)
	tween.tween_property(self, "rotation", 0.22, 0.8)
	tween.tween_property(self, "modulate:a", 0.0, 0.8)
	queue_redraw()


func _apply_initial_fall() -> void:
	fallen = true
	remove_from_group("settlement_target")
	remove_from_group("forest_tree")
	scale = Vector2(1.08, 0.42)
	rotation = 0.22
	modulate = Color(0.7, 0.66, 0.6, 0.0)
	var body := get_node_or_null("Body") as StaticBody2D
	if body != null:
		body.set_deferred("collision_layer", 0)
	queue_redraw()


func _draw() -> void:
	if is_instance_valid(_feedback):
		_feedback.queue_redraw()


func _draw_feedback() -> void:
	if fallen:
		return
	if health >= max_health and not burning and growth_remaining <= 0.0:
		return
	if burning:
		# Pixel flames remain readable with reduced motion and low effects.
		for i in 5:
			var flicker := 0.0 if GameSettings.reduce_motion() else sin(_effect_clock * 9.0 + i * 2.0) * 0.18
			var at := Vector2(-0.65 + i * 0.3, -0.7 - absf(sin(float(i) * 2.0)) * 1.6)
			var height := 0.65 + flicker
			var flame := PackedVector2Array([at, at + Vector2(-0.06, -height * 0.4), at + Vector2(0.08, -height * 0.32), at + Vector2(0.16 + flicker * 0.2, -height), at + Vector2(0.23, -height * 0.45), at + Vector2(0.33, -height * 0.3), at + Vector2(0.28, 0)])
			_feedback.draw_colored_polygon(flame, Color("#f16a26"))
			_feedback.draw_colored_polygon(PackedVector2Array([at + Vector2(0.07, 0), at + Vector2(0.16, -height * 0.6), at + Vector2(0.24, 0)]), Color("#ffdf65"))
	if growth_remaining > 0.0:
		var progress := 1.0 - growth_remaining / GROW_SECONDS
		var y := -3.1 * scale.y - 0.2
		_feedback.draw_rect(Rect2(-0.75, y, 1.5, 0.14), Color("#233b43"))
		_feedback.draw_rect(Rect2(-0.75, y, 1.5 * progress, 0.14), Color("#69d7ec"))
		_feedback.draw_line(Vector2(-0.95, y + 0.14), Vector2(-0.95, y - 0.2), Color("#a8d968"), 0.04)
		_feedback.draw_circle(Vector2(-1.04, y - 0.17), 0.09, Color("#72be58"))
		_feedback.draw_circle(Vector2(-0.87, y - 0.27), 0.09, Color("#a8d968"))
		return
	var ratio := clampf(float(health) / float(maxi(1, max_health)), 0.0, 1.0)
	var bar := Rect2(-0.75, -3.1, 1.5, 0.12)
	_feedback.draw_rect(bar.grow(0.04), Color(0.02, 0.04, 0.04, 0.88))
	_feedback.draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)), Color("#7fcf67").lerp(Color("#df525d"), 1.0 - ratio))
	_feedback.draw_rect(bar, Color(0.75, 0.8, 0.72, 0.55), false, 0.02)
