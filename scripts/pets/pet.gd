class_name Pet
extends CharacterBody2D
## Companion follower with three support abilities: gradual healing, automatic
## attacks and periodic shields. Pets are never permanently lost.
##
## Overhaul (3F): spring-damper follow with a leash and a catch-up sprint (never
## sliding under the player's feet), walk/idle/blink animation with idle
## behaviours (sit, sniff, glance), species-specific ability VFX, a visible
## shield bubble while shield points remain, cosmetic growth tiers from PetDB,
## and a restrained sleeping pose while downed.

const LEASH_DISTANCE := 6.0
const CATCHUP_DISTANCE := 2.6
const FEET_CLEARANCE := 0.62
const FOLLOW_STIFFNESS := 9.5
const FOLLOW_DAMPING := 5.2

var player: Node2D
var body_radius := 0.3

var _sprite: Sprite2D
var _shadow: Sprite2D
var _level_label: Label
var _shield_bubble: Sprite2D
var _frame_timer := 0.0
var _frame := 0
var _bob := 0.0
var _heal_timer := 0.0
var _attack_timer := 0.0
var _shield_timer := 0.0
var _down_timer := 0.0
var _follow_velocity := Vector2.ZERO
var _idle_time := 0.0
var _idle_behaviour := 0
var _idle_behaviour_timer := 0.0
var _sniff_offset := Vector2.ZERO
var _pose_lock := 0.0
var _pose_offset := Vector2.ZERO
var _pose_tween: Tween
var _follow_path := PackedVector2Array()
var _route_timer := 0.0
var _route_bounds := Rect2()
var _route_planner: ResidentRoutes
var _last_level := 1


func _ready() -> void:
	add_to_group("pet")
	z_index = 6
	collision_layer = 0
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 0.18
	shape.shape = circle
	add_child(shape)
	_build()
	if _level_label:
		_level_label.visible = false
	var vitality := WorldHealthBar.new()
	vitality.name = "PetHealth"
	vitality.subject = self
	vitality.pet_bar = true
	vitality.position = Vector2(0, -1.25)
	add_child(vitality)
	GameState.pet_changed.connect(_refresh)
	_refresh()
	_last_level = int(GameState.get_active_pet().get("level", 1)) if not GameState.get_active_pet().is_empty() else 1
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
	_sprite.z_index = 0
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

	# Shield bubble: shown while shield points remain, rotating slowly.
	_shield_bubble = Sprite2D.new()
	_shield_bubble.name = "ShieldBubble"
	_shield_bubble.texture = PixelArt.light_texture()
	_shield_bubble.modulate = Color(0.55, 0.9, 1.0, 0.0)
	_shield_bubble.scale = Vector2(0.018, 0.021)
	_shield_bubble.z_as_relative = false
	_shield_bubble.z_index = 690
	add_child(_shield_bubble)



func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		var game := get_tree().get_first_node_in_group("game")
		player = game.call("player") if game != null else null
		if not is_instance_valid(player):
			return
	var pet := GameState.get_active_pet()
	var alive := not pet.is_empty() and bool(pet.get("alive", false))
	if not alive:
		_process_downed(delta)
		return
	_down_timer = 0.0
	_bob += delta
	if _pose_lock > 0.0:
		_pose_lock = maxf(0.0, _pose_lock - delta)
	var level := int(pet.get("level", 1))
	if level > _last_level:
		_celebrate()
	_last_level = level
	_follow(delta)
	_animate(delta, player)
	_update_shield_bubble(delta, level)
	_update_growth_aura(delta, pet)
	if _level_label:
		_level_label.text = "Lv %d" % level
		_level_label.position.y = 0.08 + sin(_bob * 5.5) * 0.02
	_process_abilities(delta, pet)


# ------------------------------------------------------------------ follow

func _follow(delta: float) -> void:
	var side := -1.0 if player.facing.x >= 0.0 else 1.0
	var desired := player.global_position + Vector2(0.95 * side, 0.5) + _sniff_offset
	var offset := desired - global_position
	_route_timer -= delta
	if _route_timer <= 0.0:
		_route_timer = 0.5
		var ray := PhysicsRayQueryParameters2D.create(global_position, desired, 1)
		if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
			var lobby := get_parent() as Lobby
			var game := get_tree().get_first_node_in_group("game") as Game
			var inside_home := is_instance_valid(game) and is_instance_valid(game.home_interior)
			if lobby and not inside_home:
				_follow_path = lobby.resident_path(global_position, desired)
			else:
				var world_bounds: Rect2 = Rect2(89, 19, 14, 10) if inside_home else (get_parent().map_rect if get_parent() is Dungeon else Rect2(0, 0, 64, 40))
				if _route_planner == null or _route_bounds != world_bounds:
					_route_bounds = world_bounds
					_route_planner = ResidentRoutes.new(get_parent(), world_bounds)
				_follow_path = _route_planner.path(global_position, desired)
		else:
			_follow_path.clear()
	while not _follow_path.is_empty() and global_position.distance_to(_follow_path[0]) < 0.25:
		_follow_path.remove_at(0)
	if not _follow_path.is_empty():
		offset = _follow_path[0] - global_position
	var distance := global_position.distance_to(desired)
	var max_speed := 9.0 if distance > LEASH_DISTANCE else (6.5 if distance > CATCHUP_DISTANCE else 4.5)
	# Approach velocity with braking distance; a bounded acceleration handles turns.
	var wanted := offset.normalized() * minf(max_speed, offset.length() * (3.0 if _follow_path.is_empty() else 8.0))
	var away := global_position - player.global_position
	if away.length() < FEET_CLEARANCE + 0.3 and away.length() > 0.001:
		var normal := away.normalized()
		# Remove inward travel near the feet; steer tangentially toward the slot.
		var inward := wanted.dot(normal)
		if inward < 0.0:
			wanted -= normal * inward
		wanted += normal * maxf(0.0, FEET_CLEARANCE + 0.05 - away.length()) * 5.0
	_follow_velocity = _follow_velocity.move_toward(wanted, 22.0 * delta)
	velocity = _follow_velocity
	move_and_slide()
	_follow_velocity = velocity


func _animate(delta: float, owner_player: Node2D) -> void:
	var moving := _follow_velocity.length() > 0.55
	if owner_player.get("sleeping") == true:
		if _frame != 5:
			_frame = 5
			_apply_texture()
		if _sprite:
			_sprite.rotation = -0.35
		return
	if _sprite:
		_sprite.rotation = 0.0
	if moving:
		_idle_time = 0.0
		_sniff_offset = _sniff_offset.move_toward(Vector2.ZERO, delta * 1.5)
		_frame_timer += delta
		# Walk cycle speed follows how fast the pet is actually moving.
		var cycle := clampf(0.34 - _follow_velocity.length() * 0.03, 0.14, 0.34)
		if _frame_timer >= cycle:
			_frame_timer = 0.0
			_frame = 3 if _frame in [0, 2] else (0 if _frame != 0 else 1)
			_apply_texture()
		if _sprite:
			_sprite.flip_h = _follow_velocity.x < -0.1
	else:
		_idle_time += delta
		# Idle behaviours: sit and blink, then the occasional sniff-and-glance.
		_idle_behaviour_timer -= delta
		if _idle_behaviour_timer <= 0.0:
			_idle_behaviour_timer = randf_range(1.6, 3.2)
			_idle_behaviour = randi() % 3
			if _idle_behaviour == 1:
				_sniff_offset = Vector2(randf_range(-0.3, 0.3), randf_range(-0.15, 0.2))
		if _idle_behaviour == 1:
			_sniff_offset = _sniff_offset.move_toward(Vector2.ZERO, delta * 0.4)
		if _pose_lock <= 0.0:
			var want := 2 if fmod(_idle_time, 3.4) > 3.15 else 0
			if _frame != want:
				_frame = want
				_apply_texture()
		# Glance at the player when resting beside them.
		if _sprite and _pose_lock <= 0.0:
			_sprite.flip_h = (owner_player.global_position.x - global_position.x) < -0.1
	if _sprite:
		_sprite.position = Vector2(0, -0.5 + sin(_bob * (7.0 if moving else 3.2)) * (0.035 if moving else 0.018)) + _pose_offset


func _apply_texture() -> void:
	if _sprite:
		_sprite.texture = PixelArt.pet_texture(GameState.active_pet_id(), _frame)


func _process_downed(delta: float) -> void:
	# Dazed instead of invisible: curled resting pose, then a happy
	# recovery pop when the revive timer completes.
	visible = true
	_down_timer += delta
	_bob += delta
	if _sprite:
		if _sprite.texture != PixelArt.pet_texture(GameState.active_pet_id(), 5):
			_sprite.texture = PixelArt.pet_texture(GameState.active_pet_id(), 5)
		_sprite.position.y = -0.30 + sin(_bob * 2.0) * 0.02
	if _shadow:
		_shadow.scale = Vector2(0.012, 0.007)
	if _level_label:
		_level_label.text = "..."
	if _down_timer >= 5.0:
		_down_timer = 0.0
		GameState.revive_active_pet()
		GameState.toast_requested.emit("%s recovers and returns to your side." % PetDB.name_of(GameState.active_pet_id()), "good")
		_celebrate()


func _celebrate() -> void:
	# Happy bounce with hearts on level-up or recovery.
	_frame = 6
	_apply_texture()
	_pose_lock = 0.8
	Vfx.pop(global_position + Vector2(0, -0.9), "heart", Color("#ff8c8c"))
	if not GameSettings.reduce_motion() and _sprite:
		if _pose_tween and _pose_tween.is_valid():
			_pose_tween.kill()
		_pose_tween = create_tween().set_loops(2)
		_pose_tween.tween_property(self, "_pose_offset:y", -0.16, 0.14).set_trans(Tween.TRANS_SINE)
		_pose_tween.tween_property(self, "_pose_offset:y", 0.0, 0.14).set_trans(Tween.TRANS_SINE)


# ------------------------------------------------------------------ abilities

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
			_ability_heal_fx()
	if enemy != null and _attack_timer >= PetDB.attack_interval(id, level):
		_attack_timer = 0.0
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			var direction: Vector2 = (enemy.global_position - global_position).normalized()
			enemy.call("take_damage", PetDB.attack_damage(id, level), direction, self)
			_ability_attack_fx(id, enemy.global_position, direction)
	if _shield_timer >= PetDB.shield_interval(id, level):
		_shield_timer = 0.0
		GameState.add_shield(PetDB.shield_amount(id, level))
		_ability_shield_fx()


func _ability_heal_fx() -> void:
	# Soft pulse ring + rising sparkle on the player; the old floating icon
	# stays as a small secondary cue.
	Vfx.ring(player.global_position + Vector2(0, -0.5), 0.9, Color(0.7, 1.0, 0.8, 0.6), 0.5)
	Vfx.pop(player.global_position + Vector2(0.25, -1.4), "heart", Color("#ff8c8c"))


func _ability_attack_fx(id: String, at: Vector2, dir: Vector2) -> void:
	# Species identity: fire lick (Ember), claw arc (Moss), light bolt (Luma).
	match id:
		"ember":
			Vfx.sparks(at + Vector2(0, -0.5), -dir, Color("#ff9c4f"), 7)
			Vfx.ring(at, 0.55, Color(1.0, 0.6, 0.3, 0.8), 0.3)
		"moss":
			Vfx.sparks(at + Vector2(0, -0.5), dir.orthogonal(), Color("#e8f0d8"), 6)
			Vfx.sparks(at + Vector2(0, -0.3), -dir.orthogonal(), Color("#e8f0d8"), 5)
		"luma":
			Vfx.sparks(global_position + Vector2(0, -0.4), dir, Color("#9fdcff"), 4)
			Vfx.sparks(at + Vector2(0, -0.5), -dir, Color("#d6f2ff"), 6)
			Vfx.ring(at, 0.5, Color(0.7, 0.95, 1.0, 0.9), 0.28)
	# Small lunge toward the strike.
	if _sprite and not GameSettings.reduce_motion():
		if _pose_tween and _pose_tween.is_valid():
			_pose_tween.kill()
		_pose_tween = create_tween()
		_pose_tween.tween_property(self, "_pose_offset", dir * 0.18, 0.1)
		_pose_tween.tween_property(self, "_pose_offset", Vector2.ZERO, 0.16)
		_pose_lock = 0.25
		_frame = 4
		_apply_texture()


func _ability_shield_fx() -> void:
	Vfx.ring(player.global_position + Vector2(0, -0.5), 0.65, Color(0.6, 0.92, 1.0, 0.7), 0.55)
	_ability_icon("shield", Color("#8fe8f7"), player.global_position + Vector2(0, -1.7))


func _update_shield_bubble(delta: float, _level: int) -> void:
	if _shield_bubble == null or not is_instance_valid(player):
		return
	var shield := GameState.shield()
	if shield > 0:
		_shield_bubble.visible = true
		_shield_bubble.global_position = player.global_position + Vector2(0, -0.55)
		_shield_bubble.rotation += delta * (0.0 if GameSettings.reduce_motion() else 0.2)
		var strength := clampf(float(shield) / 20.0, 0.25, 1.0)
		_shield_bubble.modulate = Color(0.55, 0.9, 1.0, 0.08 + strength * 0.08)
	else:
		_shield_bubble.visible = false


func _update_growth_aura(_delta: float, pet: Dictionary) -> void:
	# Cosmetic growth tiers from PetDB (optional "tiers" key, safe defaults).
	var def := PetDB.get_pet(str(pet.get("id", "ember")))
	var tiers: Dictionary = def.get("tiers", {"aura": 3, "glow": 5})
	var level := int(pet.get("level", 1))
	if level >= int(tiers.get("glow", 5)) and _sprite:
		var accent: Color = def.get("accent", Color("#ffd27a"))
		_sprite.modulate = accent.lerp(Color.WHITE, 0.72)
	elif _sprite:
		_sprite.modulate = Color.WHITE


func _nearest_enemy(max_distance: float) -> Node2D:
	var best: Node2D = null
	var best_distance := max_distance
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion() or bool(enemy.get("dead")) or enemy.get_parent() != get_parent():
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
	if not pet.is_empty():
		_last_level = int(pet.get("level", 1))
