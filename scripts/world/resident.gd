class_name Resident
extends CharacterBody2D
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

enum Shopping { ROUTINE, WALK_TO_SHOP, BROWSE, PURCHASE, LEAVE }
var shopping_state := Shopping.ROUTINE
var shopping_visits := 0
var _shop: ShopNPC
var _shopping_timer := 0.0
var _visit_clock := 0.0
var _shopping_rng := RandomNumberGenerator.new()
var _purchase_icon: Sprite2D
var _path := PackedVector2Array()
var _path_goal := Vector2(INF, INF)
var _path_index := 0
var _path_revision := -1
var _stuck_time := 0.0
var _sprite: Sprite2D
var _tool: Sprite2D
var _index := 0
var _wait := 0.0
var _bob := 0.0
var _frightened := false
var _threat_notified := false
var _attack_timer := 0.0
var expression := MicroAction.new()
var _social_clock := 0.0
var _greeting_cooldown := 0.0
var _stride := 0.0
var _occupation: Dictionary = {}


func _ready() -> void:
	add_to_group("settlement_target")
	add_to_group("residents")
	z_index = 6
	collision_layer = 0
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 0.22
	shape.shape = circle
	add_child(shape)
	_shopping_rng.seed = absi(resident_name.hash())
	_visit_clock = _shopping_rng.randf_range(7.0, 22.0)
	_occupation = PersonalityProfile.current().occupations.get(role, {"action": "rest", "line": activity})
	speed *= 0.94 + float(absi(resident_name.hash()) % 13) * 0.01
	_build()
	var conversation := AuthoredInteraction.new()
	conversation.speaker = resident_name
	conversation.lines = [_occupation.get("line", activity)]
	conversation.prompt = "Talk to " + resident_name
	conversation.show_marker = false
	conversation.interact_radius = 1.1
	add_child(conversation)
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
	_sprite.z_index = 0
	add_child(_sprite)
	_tool = Sprite2D.new()
	_tool.texture = PixelArt.occupation_tool(str(_occupation.get("tool", _tool_icon())))
	_tool.scale = Vector2(0.028, 0.028)
	_tool.position = Vector2(0.28, -0.62)
	_tool.z_index = 0
	add_child(_tool)


func _physics_process(delta: float) -> void:
	_bob += delta
	if _attack_timer > 0.0:
		_attack_timer = maxf(0.0, _attack_timer - delta)
	if GameState.emergency_active() and combat_enabled:
		_fight(delta)
	elif not _frightened and _update_shopping(delta):
		pass
	else:
		_move_route(delta)
	_update_personality(delta)



func _fight(delta: float) -> void:
	var enemy := _nearest_raider(10.0)
	if enemy == null:
		_move_route(delta)
		return
	var to_enemy: Vector2 = enemy.global_position - global_position
	if to_enemy.length() > combat_range:
		_walk_to(enemy.global_position, 2.4, delta)
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
	var arrived := _walk_to(target, 3.2 if _frightened else speed, delta)
	if arrived and not _frightened:
		_wait += delta
		if _wait >= 3.0:
			_wait = 0.0
			_index = (_index + 1) % maxi(1, waypoints.size())
	elif _path.is_empty() and not _frightened:
		# Unreachable edited routes are skipped after a short wait, without resets.
		_wait += delta
		if _wait >= 5.0:
			_wait = 0.0
			_index = (_index + 1) % maxi(1, waypoints.size())
	else:
		_wait = 0.0


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
			return "wood"


func _on_emergency_changed(active: bool, _remaining: int, _damage: int) -> void:
	_frightened = active
	if active:
		_end_visit()
	if active:
		Vfx.pop(global_position + Vector2(0, -1.4), "close", Color("#ff9c6b"))
	if not active:
		_threat_notified = false


func take_attack_damage(_amount: int) -> void:
	if shopping_state != Shopping.ROUTINE:
		_end_visit()
	if not _frightened:
		_frightened = true
		if combat_enabled:
			GameState.toast_requested.emit("%s joins the village defence!" % resident_name, "bad")
		else:
			GameState.toast_requested.emit("%s is in danger! Monsters are attacking the residents!" % resident_name, "bad")


func _walk_to(destination: Vector2, pace: float, delta: float) -> bool:
	var lobby := get_parent() as Lobby
	var revision := lobby.resident_routes_revision() if lobby else 0
	if destination.distance_to(_path_goal) > 0.3 or revision != _path_revision:
		_path_goal = destination
		_path_index = 0
		_path = lobby.resident_path(global_position, destination, shopping_state != Shopping.WALK_TO_SHOP) if lobby else PackedVector2Array([destination])
		_path_revision = lobby.resident_routes_revision() if lobby else 0
	if _path.is_empty():
		velocity = velocity.move_toward(Vector2.ZERO, delta * 8.0)
		move_and_slide()
		return false
	while _path_index < _path.size() - 1 and global_position.distance_to(_path[_path_index]) < 0.16:
		_path_index += 1
	var offset := _path[_path_index] - global_position
	var final := _path_index == _path.size() - 1
	var wanted := offset.normalized() * minf(pace, offset.length() * (4.0 if final else 8.0))
	velocity = velocity.move_toward(wanted, delta * 8.0)
	var before := global_position
	move_and_slide()
	if wanted.length() > 0.1 and global_position.distance_to(before) < wanted.length() * delta * 0.1:
		_stuck_time += delta
		if _stuck_time > 0.75:
			if lobby:
				lobby.invalidate_resident_routes()
			_path_goal = Vector2(INF, INF)
			_stuck_time = 0.0
	else:
		_stuck_time = 0.0
	if _sprite and absf(velocity.x) > 0.05:
		_sprite.flip_h = velocity.x < 0.0
	return final and offset.length() < 0.16


func _update_shopping(delta: float) -> bool:
	if shopping_state == Shopping.ROUTINE:
		_visit_clock -= delta
		if _visit_clock <= 0.0:
			begin_shop_visit()
		return shopping_state != Shopping.ROUTINE
	if not is_instance_valid(_shop) or _shop.is_queued_for_deletion():
		_end_visit()
		return false
	_shopping_timer += delta
	if _shopping_timer > 60.0:
		_end_visit()
		return false
	match shopping_state:
		Shopping.WALK_TO_SHOP:
			if _walk_to(_shop.customer_position(), maxf(speed, 1.35), delta):
				shopping_state = Shopping.BROWSE
				_shopping_timer = 0.0
		Shopping.BROWSE:
			velocity = velocity.move_toward(Vector2.ZERO, delta * 8.0)
			move_and_slide()
			if _tool:
				_tool.rotation = sin(_shopping_timer * 3.0) * 0.12
			if _shopping_timer >= 1.8:
				shopping_state = Shopping.PURCHASE
				_shopping_timer = 0.0
				_shop.ambient_purchase()
				_show_exchange()
		Shopping.PURCHASE:
			if _shopping_timer >= 1.0:
				shopping_visits += 1
				shopping_state = Shopping.LEAVE
				_shopping_timer = 0.0
				# Resume the nearest routine point by walking there, never reset position.
				var nearest := INF
				for i in waypoints.size():
					var distance := global_position.distance_squared_to(waypoints[i])
					if distance < nearest:
						nearest = distance
						_index = i
		Shopping.LEAVE:
			var point: Variant = _current_waypoint()
			if point == null or _walk_to(point, maxf(speed, 1.35), delta):
				_end_visit()
	return true


func begin_shop_visit() -> bool:
	if shopping_state != Shopping.ROUTINE or GameState.emergency_active():
		return false
	_visit_clock = _shopping_rng.randf_range(24.0, 50.0)
	var shops := get_tree().get_nodes_in_group("ambient_shop")
	if shops.is_empty():
		return false
	var start := _shopping_rng.randi_range(0, shops.size() - 1)
	for i in shops.size():
		var shop := shops[(start + i) % shops.size()] as ShopNPC
		if not is_instance_valid(shop) or shop.is_queued_for_deletion():
			continue
		var lobby := get_parent() as Lobby
		if lobby == null or lobby.resident_path(global_position, shop.customer_position(), false).is_empty():
			continue
		if shop.reserve_customer(self):
			_shop = shop
			shopping_state = Shopping.WALK_TO_SHOP
			_shopping_timer = 0.0
			_path_goal = Vector2(INF, INF)
			return true
	return false


func _show_exchange() -> void:
	if _purchase_icon == null:
		_purchase_icon = Sprite2D.new()
		_purchase_icon.texture = PixelArt.icon("gold")
		_purchase_icon.scale = Vector2.ONE * PixelArt.PX
		_purchase_icon.z_index = 2
		add_child(_purchase_icon)
	_purchase_icon.texture = PixelArt.icon("gold")
	_purchase_icon.position = Vector2(0.2, -0.6)
	_purchase_icon.modulate.a = 1.0
	_purchase_icon.visible = true
	var tween := _purchase_icon.create_tween()
	tween.tween_property(_purchase_icon, "position", Vector2(0.1, -0.95), 0.35)
	tween.tween_callback(func() -> void: _purchase_icon.texture = PixelArt.icon("food"))
	tween.tween_interval(0.35)
	tween.tween_property(_purchase_icon, "modulate:a", 0.0, 0.25)


func _end_visit() -> void:
	if is_instance_valid(_shop):
		_shop.release_customer(self)
	_shop = null
	shopping_state = Shopping.ROUTINE
	_visit_clock = _shopping_rng.randf_range(24.0, 50.0)
	_path_goal = Vector2(INF, INF)
	if _tool:
		_tool.rotation = 0.0


func _exit_tree() -> void:
	if is_instance_valid(_shop):
		_shop.release_customer(self)


func _update_personality(delta: float) -> void:
	var actual := get_real_velocity()
	_stride += actual.length() * delta * 8.0
	_greeting_cooldown = maxf(0.0, _greeting_cooldown - delta)
	_social_clock -= delta
	if _frightened:
		expression.request("alert")
	elif shopping_state in [Shopping.BROWSE, Shopping.PURCHASE]:
		expression.request("shop")
	elif actual.length() < 0.08 and _wait > 0.4:
		expression.request(str(_occupation.get("action", "rest")))
	if _social_clock <= 0.0 and not _frightened:
		_social_clock = 0.7
		if _greeting_cooldown <= 0.0 and shopping_state == Shopping.ROUTINE:
			for other in get_tree().get_nodes_in_group("residents"):
				if other == self or not is_instance_valid(other) or other._frightened: continue
				if global_position.distance_to(other.global_position) < 1.35:
					expression.request("greet")
					other.expression.request("greet")
					_greeting_cooldown = 12.0
					other._greeting_cooldown = 12.0
					break
	expression.tick(delta, GameSettings.reduce_motion())
	if _sprite:
		_sprite.rotation = expression.tilt * 0.35
		_sprite.position.y = -expression.lift
		if actual.length() > 0.08 and not GameSettings.reduce_motion():
			_sprite.position.y -= absf(sin(_stride)) * PixelArt.PX
	if _tool:
		_tool.visible = not _frightened
		_tool.rotation = expression.tilt * (5.0 if role == "carpenter" else 2.0)
		_tool.position.y = -0.62 - expression.lift
		if role == "gardener" and expression.state == "work":
			_tool.rotation += 0.35 if not GameSettings.reduce_motion() else 0.0
