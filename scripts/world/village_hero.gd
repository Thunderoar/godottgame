class_name VillageHero
extends CharacterBody2D
## Rescued friends are persistent allies. Their bodies are rebuilt from campaign IDs.
var hero_id := "arjun"
var home := Vector2.ZERO
var dock_waiting := false
var _nameplate: Label
var _sprite: Sprite2D
var _attack_timer := 0.0
var _route_timer := 0.0
var _path := PackedVector2Array()
var _target: Enemy
var _clock := 0.0

func _ready() -> void:
	add_to_group("village_heroes")
	collision_layer = 0
	collision_mask = 1
	z_index = 6
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 0.25
	shape.shape = circle
	add_child(shape)
	_sprite = Sprite2D.new()
	_sprite.scale = Vector2.ONE * PixelArt.PX
	_sprite.position.y = -0.6
	add_child(_sprite)
	_sprite.texture = PixelArt.character_texture(hero_id, 0)
	_nameplate = Label.new()
	_nameplate.text = "Arjun" if hero_id == "arjun" else "Mei Ling"
	_nameplate.position = Vector2(-0.75,-1.75)
	_nameplate.size = Vector2(84,20)
	_nameplate.scale = Vector2.ONE*0.018
	_nameplate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_nameplate.add_theme_font_size_override("font_size",17)
	_nameplate.add_theme_color_override("font_color",Color("#ffe3a2") if hero_id == "arjun" else Color("#c4f0d7"))
	_nameplate.add_theme_color_override("font_outline_color",Color("#183c43"))
	_nameplate.add_theme_constant_override("outline_size",5)
	_nameplate.visible = dock_waiting
	add_child(_nameplate)

func _physics_process(delta: float) -> void:
	var game := get_tree().get_first_node_in_group("game") as Game
	if GameState.game_over_active or not is_instance_valid(game) or game.world != get_parent(): return
	_nameplate.visible = dock_waiting
	_clock += delta
	_attack_timer = maxf(0, _attack_timer - delta)
	_route_timer -= delta
	if _route_timer <= 0:
		_route_timer = 0.5
		_target = nearest_threat()
		var destination := _target.global_position if is_instance_valid(_target) else home
		_path = get_parent().resident_path(global_position, destination)
	var destination := _target.global_position if is_instance_valid(_target) and not _target.dead else home
	while not _path.is_empty() and position.distance_to(_path[0]) < 0.3: _path.remove_at(0)
	var next := _path[0] if not _path.is_empty() else destination
	var reach := 6.0 if hero_id == "mei_ling" else 2.2
	var distance := global_position.distance_to(destination)
	velocity = (next - global_position).normalized() * 3.5 if distance > (reach if is_instance_valid(_target) else 0.35) else Vector2.ZERO
	move_and_slide()
	var facing := 2 if velocity.x >= 0 else 1
	if dock_waiting and velocity.length() < 0.1 and not is_instance_valid(_target):
		var actor := game.player()
		facing = (2 if actor.position.x > position.x else 1) if is_instance_valid(actor) and actor.position.distance_to(position) < 5 else (2 if hero_id == "arjun" else 0)
	_sprite.texture = PixelArt.character_texture(hero_id, facing, int(_clock * 5) % 2 if velocity.length() > 0.1 else 0)
	if is_instance_valid(_target) and not _target.dead and distance <= reach and _attack_timer <= 0:
		_attack_timer = 0.8 if hero_id == "mei_ling" else 1.1
		var direction := (_target.global_position - global_position).normalized()
		if hero_id == "mei_ling":
			var arrow := Arrow.new()
			arrow.source = self
			arrow.damage = 14 + GameState.house_level() * 3
			arrow.direction = direction
			arrow.position = position + Vector2(0, -0.6)
			get_parent().add_child(arrow)
		else:
			_target.take_damage(20 + GameState.house_level() * 4, direction, self)
			Vfx.ring(_target.global_position, 0.8, GameUI.GOLD, 0.25)

func nearest_threat() -> Enemy:
	var found: Enemy
	var nearest := 20.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion() or not enemy is Enemy or enemy.dead or enemy.get_parent() != get_parent() or enemy.kind not in ["fire", "urchin"]: continue
		if dock_waiting and enemy.position.distance_to(home) > 4.5: continue
		var distance := position.distance_to(enemy.position)
		if distance < nearest:
			nearest = distance
			found = enemy
	return found
