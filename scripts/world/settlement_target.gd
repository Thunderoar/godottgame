class_name SettlementTarget
extends Node2D
## Persistent, individually damageable house/fence. Shops retain raid tinting.

@export var target_name := "Building"
@export var damage_scale := 0.35
@export var structure_id := ""
@export var structure_kind := "house"
@export var max_health := 200
var _flash_timer := 0.0
var _destroyed := false
var _originals: Dictionary = {}
var _status: Label
var _status_clock := 0.0


func _ready() -> void:
	add_to_group("settlement_target")
	if not structure_id.is_empty():
		add_to_group("structures")
		GameState.register_structure(structure_id, target_name, structure_kind, max_health)
		GameState.data_changed.connect(_refresh)
		call_deferred("_refresh")
		call_deferred("_build_repair_points")
		_status = Label.new()
		_status.scale = Vector2.ONE * PixelArt.PX
		_status.position = Vector2(-1.2, -2.0)
		_status.add_theme_font_size_override("font_size", 12)
		_status.add_theme_color_override("font_color", Color("#b9eeff"))
		_status.add_theme_color_override("font_shadow_color", Color("#18303a"))
		_status.z_as_relative = false
		_status.z_index = 700
		add_child(_status)
	z_index = 1


func _build_repair_points() -> void:
	var points: Array[Vector2] = []
	if structure_kind == "fence":
		for child in get_parent().get_children():
			if child is StaticBody2D:
				points.append(to_local(child.global_position) + Vector2(0, 0.7))
	else:
		points.append(to_local(shelter_position()) + Vector2(0, 0.6))
	for point in points:
		var interaction := StructureRepairPoint.new()
		interaction.target = self
		interaction.position = point
		add_child(interaction)


func is_intact() -> bool:
	return not structure_id.is_empty() and int(GameState.structure_state(structure_id).get("health", 0)) > 0


func shelter_position() -> Vector2:
	return get_parent().global_position + Vector2(0, 0.8)


func attack_position(from: Vector2) -> Vector2:
	if structure_kind != "fence":
		return shelter_position()
	var best := global_position
	var distance := INF
	for child in get_parent().get_children():
		if child is StaticBody2D:
			var d := from.distance_squared_to(child.global_position)
			if d < distance:
				distance = d
				best = child.global_position
	return best


func take_damage(amount: int, _from_dir: Vector2 = Vector2.ZERO, _source: Node = null) -> void:
	take_attack_damage(amount)


func take_attack_damage(amount: int) -> void:
	if GameState.game_over_active:
		return
	if not structure_id.is_empty():
		if not is_intact():
			return
		GameState.damage_structure(structure_id, amount)
	elif GameState.emergency_active():
		GameState.damage_settlement(maxi(1, roundi(amount * damage_scale)))
	_flash_timer = 0.3
	queue_redraw()


func _process(delta: float) -> void:
	_status_clock -= delta
	if _status and _status_clock <= 0.0:
		_status_clock = 0.5
		var entry := GameState.structure_state(structure_id)
		var sheltered_count := 0
		if structure_kind == "house" and is_intact():
			for npc in get_tree().get_nodes_in_group("residents"):
				if is_instance_valid(npc) and npc.sheltered and npc._shelter_house == self and not npc.dead:
					sheltered_count += 1
		var damaged := int(entry.get("health", 0)) < int(entry.get("maximum", 1))
		_status.text = "Rosak - dekat & tekan Betulkan (percuma)" if damaged else ("Shelter: %d" % sheltered_count if sheltered_count > 0 else "")
	if _flash_timer > 0.0:
		_flash_timer -= delta
		queue_redraw()


func _refresh() -> void:
	if structure_id.is_empty() or not is_inside_tree():
		return
	var ruined := not is_intact()
	for child in get_parent().get_children():
		if child is Sprite2D:
			if not _originals.has(child):
				_originals[child] = {"scale": child.scale, "tint": child.modulate}
			var original: Dictionary = _originals[child]
			child.scale = original.scale * (Vector2(1, 0.25) if ruined else Vector2.ONE)
			child.modulate = Color("#685044") if ruined else original.tint
		elif child is StaticBody2D:
			child.set_deferred("collision_layer", 0 if ruined else 1)
		elif child is PointLight2D:
			child.visible = not ruined
		elif child is HouseBed:
			child.available = not ruined
	if ruined:
		remove_from_group("settlement_target")
	else:
		add_to_group("settlement_target")
	if ruined != _destroyed:
		_destroyed = ruined
		var lobby := get_parent().get_parent() as Lobby
		if lobby:
			lobby.call_deferred("invalidate_resident_routes")
	queue_redraw()


func _draw() -> void:
	if structure_id.is_empty():
		return
	var entry := GameState.structure_state(structure_id)
	var hp := int(entry.get("health", max_health))
	if hp >= max_health and _flash_timer <= 0.0:
		return
	var ratio := float(hp) / max_health
	draw_rect(Rect2(-0.9, -1.5, 1.8, 0.12), Color("#28353a"))
	draw_rect(Rect2(-0.9, -1.5, 1.8 * ratio, 0.12), Color("#e9ae55"))
	if _flash_timer > 0.0:
		draw_circle(Vector2(0, -0.5), 0.25, Color(1, 0.5, 0.2, 0.7))
