class_name Pet
extends Node2D
## Companion follower with three support abilities: gradual healing, automatic
## attacks and periodic shields. Pets are never permanently lost.

var player: Node2D
var body_radius := 0.3

var _sprite: Sprite2D
var _shadow: Sprite2D
var _level_label: Label
var _frame_timer := 0.0
var _frame := 0
var _bob := 0.0
var _heal_timer := 0.0
var _attack_timer := 0.0
var _shield_timer := 0.0
var _down_timer := 0.0


func _ready() -> void:
	add_to_group("pet")
	z_index = 5
	_build()
	GameState.pet_changed.connect(_refresh)
	_refresh()
	if is_instance_valid(player):
		position = player.position + Vector2(-0.95, 0.5)


func _build() -> void:
	_shadow = Sprite2D.new()
	_shadow.name = "Shadow"
	_shadow.texture = PixelArt.light_texture()
	_shadow.modulate = Color(0.02, 0.03, 0.03, 0.35)
	_shadow.scale = Vector2(0.015, 0.008)
	_shadow.position = Vector2(0, -0.05)
	_shadow.z_index = -1
	add_child(_shadow)

	_sprite = Sprite2D.new()
	_sprite.name = "Sprite"
	_sprite.texture = PixelArt.pet_texture(GameState.active_pet_id())
	_sprite.scale = Vector2(PixelArt.PX, PixelArt.PX) * 1.12
	_sprite.position = Vector2(0, -0.5)
	_sprite.z_index = 6
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)

	_level_label = Label.new()
	_level_label.name = "Level"
	_level_label.add_theme_font_size_override("font_size", 11)
	_level_label.add_theme_color_override("font_color", Color("#f1d27a"))
	_level_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_level_label.add_theme_constant_override("shadow_offset_x", 1)
	_level_label.add_theme_constant_override("shadow_offset_y", 1)
	_level_label.scale = Vector2(0.026, 0.026)
	_level_label.position = Vector2(-0.26, 0.08)
	_level_label.z_index = 7
	add_child(_level_label)


func _process(delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		if not is_instance_valid(player):
			return
	var pet := GameState.get_active_pet()
	var alive := not pet.is_empty() and bool(pet.get("alive", false))
	if not alive:
		visible = false
		_down_timer += delta
		if _down_timer >= 5.0:
			_down_timer = 0.0
			GameState.revive_active_pet()
			GameState.toast_requested.emit("%s recovers and returns to your side." % PetDB.name_of(GameState.active_pet_id()), "good")
		return
	visible = true
	_down_timer = 0.0
	_bob += delta
	_frame_timer += delta
	if _frame_timer >= 0.34:
		_frame_timer -= 0.34
		_frame = 1 - _frame
		if _sprite:
			_sprite.texture = PixelArt.pet_texture(GameState.active_pet_id(), _frame)
	var side := -1.0 if player.facing.x >= 0.0 else 1.0
	var desired := player.global_position + Vector2(0.95 * side, 0.5)
	if global_position.distance_to(player.global_position) > 4.0:
		global_position = desired
	else:
		global_position = global_position.lerp(desired, clampf(delta * 5.2, 0.0, 1.0))
	if _sprite:
		_sprite.position.y = -0.5 + sin(_bob * 5.5) * 0.035
		_sprite.flip_h = player.facing.x < -0.1
	if _level_label:
		_level_label.text = "Lv %d" % int(pet.get("level", 1))
		_level_label.position.y = 0.08 + sin(_bob * 5.5) * 0.02
	_process_abilities(delta, pet)


func _process_abilities(delta: float, pet: Dictionary) -> void:
	var enemy := _nearest_enemy(7.0)
	var in_combat := enemy != null
	if not in_combat:
		return
	var id := str(pet.id)
	var level := int(pet.get("level", 1))
	_heal_timer += delta
	_attack_timer += delta
	_shield_timer += delta
	if _heal_timer >= PetDB.heal_interval(id, level):
		_heal_timer = 0.0
		if GameState.health() < GameState.health_max():
			GameState.heal(PetDB.heal_amount(id, level))
			_ability_icon("heart", Color("#ff8c8c"), player.global_position + Vector2(0, -1.5))
	if enemy != null and _attack_timer >= PetDB.attack_interval(id, level):
		_attack_timer = 0.0
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			var direction: Vector2 = (enemy.global_position - global_position).normalized()
			enemy.call("take_damage", PetDB.attack_damage(id, level), direction, self)
			_ability_icon("spark", Color("#f3d37a"), enemy.global_position + Vector2(0, -0.6))
	if _shield_timer >= PetDB.shield_interval(id, level):
		_shield_timer = 0.0
		GameState.add_shield(PetDB.shield_amount(id, level))
		_ability_icon("shield", Color("#8fe8f7"), player.global_position + Vector2(0, -1.7))


func _nearest_enemy(max_distance: float) -> Node2D:
	var best: Node2D = null
	var best_distance := max_distance
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		if not enemy.has_method("take_damage"):
			continue
		var distance := global_position.distance_to(enemy.global_position)
		if distance < best_distance:
			best = enemy
			best_distance = distance
	return best


func _ability_icon(kind: String, color: Color, at: Vector2) -> void:
	if not is_inside_tree():
		return
	var icon := Sprite2D.new()
	icon.texture = PixelArt.icon(kind)
	icon.scale = Vector2(0.045, 0.045)
	icon.modulate = color
	icon.z_as_relative = false
	icon.z_index = 720
	icon.global_position = at
	get_parent().add_child(icon)
	icon.global_position = at
	var tween := icon.create_tween().set_parallel(true)
	tween.tween_property(icon, "position:y", at.y - 0.65, 0.55)
	tween.tween_property(icon, "modulate:a", 0.0, 0.55)
	tween.chain().tween_callback(icon.queue_free)


func _refresh() -> void:
	var id := GameState.active_pet_id()
	if _sprite:
		_sprite.texture = PixelArt.pet_texture(id, _frame)
	var pet := GameState.get_active_pet()
	visible = not pet.is_empty() and bool(pet.get("alive", false))
