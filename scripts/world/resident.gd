class_name Resident
extends CharacterBody2D
## Ambient settlement resident with a daily route. During an emergency the
## resident drops their routine and runs for shelter.

@export var resident_name := "Resident"
@export var role := "resident"
@export var activity := "Tending the settlement"
const WALK_SPEED := 0.9
@export var speed := WALK_SPEED
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
const WATER_RANGE := 2.6
const WATER_INTERVAL := 1.25
const WATER_HEAL := 5
const PLANT_SECONDS := 2.0
@export var water_power := false
@export var worker_role := ""
var _build_target: SettlementTarget
var _tree_task: ForestTree
var _care_clock := 0.0
var _care_search := 0.0
var _watering := false
var dead := false
var sheltered := false
var _shelter_house: SettlementTarget


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
	GameState.data_changed.connect(_refresh_life)
	_refresh_life()
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
	if dead:
		return
	if GameState.game_over_active:
		velocity = Vector2.ZERO
		_watering = false
		queue_redraw()
		return
	_bob += delta
	if _attack_timer > 0.0:
		_attack_timer = maxf(0.0, _attack_timer - delta)
	if not worker_role.is_empty():
		_run_worker(delta)
	elif _seek_shelter(delta):
		pass
	elif water_power and _care_for_forest(delta):
		pass
	elif GameState.emergency_active() and combat_enabled:
		_fight(delta)
	elif not _frightened and _update_shopping(delta):
		pass
	else:
		_move_route(delta)
	_update_personality(delta)
	queue_redraw()


func _care_for_forest(delta: float) -> bool:
	_watering = false
	_care_search -= delta
	if is_instance_valid(_tree_task) and not _accept_tree(_tree_task):
		_release_tree_task()
	if not is_instance_valid(_tree_task) and _care_search <= 0.0:
		_care_search = 0.5
		var lobby := get_parent() as Lobby
		if lobby:
			var best := INF
			for tree in lobby._forest_trees:
				if not is_instance_valid(tree) or not _accept_tree(tree):
					continue
				if is_instance_valid(tree.caretaker) and tree.caretaker != self:
					continue
				var distance := global_position.distance_to(tree.global_position)
				# Fires have priority; distribute jobs through per-tree claims.
				var score := distance + (0.0 if tree.burning else 80.0)
				if score < best:
					_tree_task = tree
					best = score
			if is_instance_valid(_tree_task):
				_tree_task.caretaker = self
				_end_visit()
				_care_clock = 0.0
	if not is_instance_valid(_tree_task):
		return false
	var offset := _tree_task.global_position - global_position
	if offset.length() > WATER_RANGE:
		_walk_to(_tree_task.global_position + Vector2(0, 1.2), 3.2, delta)
		_care_clock = 0.0
		# Do not let an unreachable claim block the other caretakers forever.
		if _path.is_empty():
			_release_tree_task()
		return true
	velocity = Vector2.ZERO
	move_and_slide()
	_care_clock += delta
	if _sprite:
		_sprite.flip_h = offset.x < 0.0
	if _tree_task.fallen:
		if _care_clock >= PLANT_SECONDS:
			if _tree_task.replant():
				GameState.save_game()
			_release_tree_task()
	else:
		_watering = true
		if _care_clock >= WATER_INTERVAL:
			_care_clock -= WATER_INTERVAL
			_tree_task.water(WATER_HEAL)
	return true


func _release_tree_task() -> void:
	if is_instance_valid(_tree_task) and _tree_task.caretaker == self:
		_tree_task.caretaker = null
	_tree_task = null
	_care_clock = 0.0
	_watering = false


func _draw() -> void:
	var hp := GameState.resident_health(resident_name)
	if hp < 100 and not dead and not sheltered:
		draw_rect(Rect2(-0.4, -1.45, 0.8, 0.1), Color("#27353b"))
		draw_rect(Rect2(-0.4, -1.45, 0.8 * hp / 100.0, 0.1), Color("#ef7676"))
	if not _watering or not is_instance_valid(_tree_task):
		return
	var origin := Vector2(0.2, -0.65)
	var end := to_local(_tree_task.global_position) + Vector2(0, -1.1)
	for i in 12:
		var t := float(i) / 12.0 if GameSettings.reduce_motion() else fmod(float(i) / 12.0 + _bob * 1.4, 1.0)
		var point := origin.lerp(end, t) + Vector2(0, -sin(t * PI) * 0.65)
		draw_rect(Rect2(point, Vector2(0.09, 0.13)), Color("#8ce9ff"))


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
	if worker_role == "fighter":
		return "sword"
	if worker_role == "builder":
		return "hammer"
	if water_power:
		return "mana"
	match role:
		"fisher":
			return "food"
		"gardener":
			return "food"
		"carpenter", "builder":
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


func take_attack_damage(amount: int) -> void:
	if dead or sheltered:
		return
	GameState.damage_resident(resident_name, amount)
	if shopping_state != Shopping.ROUTINE:
		_end_visit()
	if not _frightened:
		_frightened = true
		if combat_enabled:
			GameState.toast_requested.emit("%s joins the village defence!" % resident_name, "bad")
		else:
			GameState.toast_requested.emit("%s is in danger! Monsters are attacking the residents!" % resident_name, "bad")


func take_damage(amount: int, _from_dir: Vector2 = Vector2.ZERO, _source: Node = null) -> void:
	take_attack_damage(amount)


func _refresh_life() -> void:
	dead = GameState.resident_health(resident_name) <= 0
	visible = not dead and not sheltered
	if dead:
		remove_from_group("settlement_target")
		_release_tree_task()
		_release_build_task()
		_end_visit()
	elif not is_in_group("repair_workers"):
		add_to_group("settlement_target")


func _seek_shelter(delta: float) -> bool:
	var danger := GameState.emergency_active()
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and enemy.get_parent() == get_parent() and enemy.kind == "urchin" and not enemy.dead and global_position.distance_to(enemy.global_position) < 10.0:
			danger = true
			break
	if sheltered and (not is_instance_valid(_shelter_house) or not _shelter_house.is_intact()):
		sheltered = false
		visible = true
	if not danger:
		_frightened = false
		sheltered = false
		visible = true
		return false
	_release_tree_task()
	if shopping_state != Shopping.ROUTINE:
		_end_visit()
	if sheltered:
		return true
	if not is_instance_valid(_shelter_house) or not _shelter_house.is_intact():
		_shelter_house = null
		var best := INF
		for node in get_tree().get_nodes_in_group("structures"):
			var house := node as SettlementTarget
			if not is_instance_valid(house) or house.structure_kind != "house" or not house.is_intact() or house.get_parent().get_parent() != get_parent():
				continue
			var distance := global_position.distance_to(house.shelter_position())
			if distance < best:
				best = distance
				_shelter_house = house
	if not is_instance_valid(_shelter_house):
		_move_route(delta)
		return true
	if _walk_to(_shelter_house.shelter_position(), 3.2, delta):
		sheltered = true
		visible = false
		velocity = Vector2.ZERO
	return true


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
			# A crowd is dynamic; retry this actor without rebuilding every static
			# navigation cell for every resident. Actual edits invalidate in Lobby.
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
	_release_tree_task()
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


func _accept_tree(tree: ForestTree) -> bool:
	if worker_role == "water":
		return tree.burning and not tree.fallen
	if worker_role == "planter":
		return tree.fallen
	return tree.fallen or tree.burning

func _run_worker(delta: float) -> void:
	_watering = false
	if worker_role == "fighter" and _fight_kind("urchin", delta, false):
		return
	if worker_role == "water":
		if _care_for_forest(delta):
			return
		if _fight_kind("fire", delta, true):
			return
	if _seek_shelter(delta):
		_release_build_task()
		return
	if worker_role == "builder" and _repair_buildings(delta):
		return
	if worker_role == "planter" and _care_for_forest(delta):
		return
	_move_route(delta)

func _fight_kind(kind: String, delta: float, ranged: bool) -> bool:
	var enemy: Enemy
	var best := 12.0
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(candidate) or candidate.dead or candidate.is_queued_for_deletion() or candidate.get_parent() != get_parent() or candidate.kind != kind:
			continue
		var distance := global_position.distance_to(candidate.global_position)
		if distance < best:
			best = distance
			enemy = candidate
	if not is_instance_valid(enemy):
		return false
	sheltered = false
	visible = true
	_frightened = false
	_end_visit()
	var direction := enemy.global_position - global_position
	if _sprite:
		_sprite.flip_h = direction.x < 0
	var reach := 5.0 if ranged else 1.35
	if direction.length() > reach:
		_walk_to(enemy.global_position, 2.8, delta)
		return true
	velocity = Vector2.ZERO
	if _attack_timer <= 0:
		_attack_timer = WATER_INTERVAL if ranged else combat_interval
		if ranged:
			var bolt := VillageBolt.new()
			bolt.target = enemy
			bolt.source = self
			bolt.water = true
			bolt.damage = 6
			get_parent().add_child(bolt)
			bolt.global_position = global_position + Vector2(0.2, -0.7)
		else:
			enemy.take_damage(10, direction.normalized(), self)
			Vfx.ring(global_position + direction.normalized() * 0.6 + Vector2(0, -0.4), 0.5, Color("#e5f2ff"), 0.2)
			if _tool and not GameSettings.reduce_motion():
				_tool.rotation = -0.8
				_tool.create_tween().tween_property(_tool, "rotation", 0.0, 0.25)
	return true

func _release_build_task() -> void:
	if is_instance_valid(_build_target) and _build_target.builder == self:
		_build_target.builder = null
	_build_target = null

func _repair_buildings(delta: float) -> bool:
	if GameState.is_night():
		_release_build_task()
		return false
	if is_instance_valid(_build_target):
		var state := GameState.structure_state(_build_target.structure_id)
		if int(state.get("health", 0)) >= int(state.get("maximum", 1)):
			_release_build_task()
	if not is_instance_valid(_build_target):
		var best := INF
		for node in get_tree().get_nodes_in_group("structures"):
			if not is_instance_valid(node) or node.get_parent().get_parent() != get_parent() or node.is_queued_for_deletion():
				continue
			var state := GameState.structure_state(node.structure_id)
			if int(state.get("health", 0)) >= int(state.get("maximum", 1)) or (is_instance_valid(node.builder) and node.builder != self):
				continue
			var distance := global_position.distance_to(node.attack_position(global_position))
			if distance < best:
				best = distance
				_build_target = node
		if is_instance_valid(_build_target):
			_build_target.builder = self
	if not is_instance_valid(_build_target):
		return false
	var point := _build_target.attack_position(global_position)
	if _build_target.structure_kind == "house":
		point = _build_target.shelter_position() + Vector2(0, 0.5)
	else:
		point += (global_position - point).normalized() * 0.8
	if global_position.distance_to(point) > 0.4:
		_walk_to(point, 2.8, delta)
		return true
	velocity = Vector2.ZERO
	if GameState.start_structure_work(_build_target.structure_id):
		if _tool:
			_tool.rotation = 0.0 if GameSettings.reduce_motion() else sin(_bob * 12) * 0.5
		if GameState.work_structure(_build_target.structure_id, delta):
			_release_build_task()
	return true
