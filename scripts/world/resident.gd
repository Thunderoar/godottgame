class_name Resident
extends Node2D
## Ambient settlement resident with a daily route. During an emergency the
## resident drops their routine and runs for shelter.

@export var resident_name := "Resident"
@export var role := "resident"
@export var activity := "Tending the settlement"
@export var speed := 0.9
@export var waypoints: Array[Vector2] = []
@export var shelter := Vector2(34, 23)
@export var combat_enabled := false
@export var combat_damage := 8
@export var combat_range := 4.2
@export var combat_interval := 1.15

var _sprite: Sprite2D
var _tool: Sprite2D
var _index := 0
var _wait := 0.0
var _bob := 0.0
var _frightened := false
var _threat_notified := false
var _attack_timer := 0.0


func _ready() -> void:
	add_to_group("settlement_target")
	_build()
	GameState.emergency_changed.connect(_on_emergency_changed)
	if GameState.emergency_active():
		_frightened = true


func _build() -> void:
	var tex := PixelArt.npc_texture(role)
	_sprite = Sprite2D.new()
	_sprite.name = "Sprite"
	_sprite.texture = tex
	_sprite.centered = false
	_sprite.offset = Vector2(-tex.get_width() * 0.5, -tex.get_height())
	_sprite.scale = Vector2(PixelArt.PX, PixelArt.PX)
	_sprite.z_index = 7
	add_child(_sprite)
	_tool = Sprite2D.new()
	_tool.texture = PixelArt.icon(_tool_icon())
	_tool.scale = Vector2(0.028, 0.028)
	_tool.position = Vector2(0.28, -0.62)
	_tool.z_index = 8
	add_child(_tool)


func _process(delta: float) -> void:
	_bob += delta
	if _attack_timer > 0.0:
		_attack_timer = maxf(0.0, _attack_timer - delta)
	if GameState.emergency_active() and combat_enabled:
		_fight(delta)
	else:
		_move_route(delta)
	if _sprite:
		_sprite.position.y = sin(_bob * 5.0) * 0.02
	if _tool:
		_tool.position.y = -0.62 + sin(_bob * 4.0) * 0.02
		_tool.visible = not _frightened


func _fight(delta: float) -> void:
	var enemy := _nearest_raider(10.0)
	if enemy == null:
		_move_route(delta)
		return
	var to_enemy: Vector2 = enemy.global_position - global_position
	if to_enemy.length() > combat_range:
		global_position += to_enemy.normalized() * minf(delta * 2.4, to_enemy.length())
		if _sprite:
			_sprite.flip_h = to_enemy.x < 0.0
	elif _attack_timer <= 0.0 and enemy.has_method("take_damage"):
		_attack_timer = combat_interval
		enemy.call("take_damage", combat_damage, to_enemy.normalized(), self)
		var spark := Sprite2D.new()
		spark.texture = PixelArt.icon("spark")
		spark.scale = Vector2(0.045, 0.045)
		spark.modulate = Color("#9fe3ff")
		spark.z_as_relative = false
		spark.z_index = 710
		spark.global_position = enemy.global_position + Vector2(0, -0.6)
		get_parent().add_child(spark)
		var tween := spark.create_tween().set_parallel(true)
		tween.tween_property(spark, "modulate:a", 0.0, 0.25)
		tween.tween_property(spark, "position:y", spark.position.y - 0.4, 0.25)
		tween.chain().tween_callback(spark.queue_free)


func _move_route(delta: float) -> void:
	var target: Variant = shelter if _frightened else _current_waypoint()
	if target == null:
		return
	var delta_pos: Vector2 = target - global_position
	if delta_pos.length() > 0.12:
		var step := minf(delta * (3.2 if _frightened else speed), delta_pos.length())
		global_position += delta_pos.normalized() * step
		if _sprite:
			_sprite.flip_h = delta_pos.x < 0.0
		if _frightened and delta_pos.length() < 2.5 and not _threat_notified:
			_threat_notified = true
			GameState.toast_requested.emit("%s is running for shelter!" % resident_name, "bad")
	elif not _frightened:
		_wait += delta
		if _wait >= 3.0:
			_wait = 0.0
			_index = (_index + 1) % maxi(1, waypoints.size())


func _nearest_raider(max_distance: float) -> Enemy:
	var best: Enemy = null
	var best_distance := max_distance
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not bool(enemy.get("settlement_mode")):
			continue
		var distance := global_position.distance_to(enemy.global_position)
		if distance < best_distance:
			best = enemy
			best_distance = distance
	return best


func _current_waypoint() -> Variant:
	if waypoints.is_empty():
		return null
	return waypoints[_index]


func _tool_icon() -> String:
	match role:
		"fisher":
			return "food"
		"gardener":
			return "food"
		"carpenter":
			return "hammer"
		"woodcutter":
			return "wood"
		"keeper":
			return "heart"
		"guard", "defender":
			return "shield"
		"farmer":
			return "food"
		"trader":
			return "gold"
		_:
			return "spark"


func _on_emergency_changed(active: bool, _remaining: int, _damage: int) -> void:
	_frightened = active
	if active:
		Vfx.pop(global_position + Vector2(0, -1.4), "close", Color("#ff9c6b"))
	if not active:
		_threat_notified = false


func take_attack_damage(_amount: int) -> void:
	if not _frightened:
		_frightened = true
		if combat_enabled:
			GameState.toast_requested.emit("%s joins the village defence!" % resident_name, "bad")
		else:
			GameState.toast_requested.emit("%s is in danger! Monsters are attacking the residents!" % resident_name, "bad")
