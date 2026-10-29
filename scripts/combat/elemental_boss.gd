class_name ElementalBoss
extends Enemy
## Three authored powers per ruler, rotating predictably with visible warnings.
var element := "chaos"
var skills: Array = []
var last_skill_id := ""
var _skill_index := 0
var _cast_time := 0.0
var _pending: Dictionary = {}
var _aim := Vector2.ZERO
var _ability_label: Label
var _summons: Array[Enemy] = []

func _ready() -> void:
	is_boss = true
	kind = "demon_"+element
	skills = ElementDB.get_element(element).get("skills",[])
	super._ready()
	_ability_label = Label.new()
	_ability_label.scale = Vector2.ONE*PixelArt.PX
	_ability_label.position = Vector2(-4,-7.2)
	_ability_label.size = Vector2(256,40)
	_ability_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ability_label.add_theme_font_size_override("font_size",15)
	_ability_label.add_theme_color_override("font_color",Color("#ffdb9c"))
	_ability_label.add_theme_color_override("font_outline_color",Color("#181322"))
	_ability_label.add_theme_constant_override("outline_size",4)
	_ability_label.visible = false
	add_child(_ability_label)
	for child in get_children():
		if child is WorldHealthBar: child.position.y = -5.8
	_update_art()

func _update_art() -> void:
	sprite.texture = PixelArt.enemy_texture(kind,true,0 if GameSettings.reduce_motion() else int(_bob*2)%2)
	sprite.texture_filter = VisualStyle.texture_filter()

func _sprite_rest_scale() -> Vector2:
	return Vector2.ONE*PixelArt.PX*(205.0/sprite.texture.get_height())

func _sprite_rest_position() -> Vector2:
	return Vector2(0,-3.05)

func _physics_process(delta: float) -> void:
	if dead: return
	if get_parent() is Dungeon and not get_parent()._boss_arrived and not active: return
	if _cast_time > 0:
		_cast_time = maxf(0,_cast_time-delta)
		if _cast_time == 0 and not _pending.is_empty():
			_execute_skill(_pending)
			_pending = {}
			_ability_label.visible = false
	super._physics_process(delta)
	_update_art()

func _chase(delta: float) -> void:
	if _cast_time > 0:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	super._chase(delta)

func _cast_special() -> void:
	if dead or _cast_time > 0 or skills.is_empty() or not is_instance_valid(_player) or _player.get_parent() != get_parent() or bool(_player.get("dead")): return
	_pending = skills[_skill_index%skills.size()].duplicate(true)
	_skill_index += 1
	last_skill_id = str(_pending.get("id",""))
	_aim = _player.global_position
	_cast_time = 0.85
	velocity = Vector2.ZERO
	_ability_label.text = str(_pending.get("name",""))
	_ability_label.visible = true
	var pattern := str(_pending.get("pattern","nova"))
	var aim_dir := global_position.direction_to(_aim)
	match pattern:
		"whirl": _ground(_aim,"circle",3.6,4.0,4.0,0.75)
		"pool": _ground(_aim,"circle",3.2,4.2,0.0,0.7)
		"snare":
			for offset in [Vector2.ZERO,Vector2(-2.5,0),Vector2(2.5,0)]: _ground(_aim+offset,"circle",1.65,2.2,0.0,0.3)
		"nova": _ground(global_position,"circle",5.0,0.7,-5.0,0.6 if element == "ice" else 1.0)
		"ring":
			_ground(_aim,"ring",3.5,2.2)
			_ground(global_position,"ring",5.0,2.2)
		"cross":
			for axis in [Vector2.RIGHT,Vector2.DOWN]:
				var effect := _ground(_aim-axis*7,"line",0.85,0.8)
				effect.direction = axis
				effect.length = 14
		"line","wave","cleave":
			var effect := _ground(global_position,pattern,1.4 if pattern == "wave" else 1.0,2.0 if pattern == "wave" else 0.65,-3.0)
			effect.direction = aim_dir
			effect.length = 11 if pattern != "cleave" else 5
			if pattern == "wave": effect.travel_speed = 3.0
		"strikes":
			for offset in [Vector2.ZERO,Vector2(-4,0),Vector2(4,0),Vector2(0,-4),Vector2(0,4)]: _ground(_aim+offset,"circle",1.65,0.65,0.0,0.5 if element == "lightning" else 1.0)
		_:
			_ground(global_position,"ring",2.2,0.1).damage = 0
	Sfx.play("charge",-13)

func _ground(at: Vector2, shape: String, reach: float, seconds: float, force: float = 0.0, slow_factor: float = 1.0) -> ElementalEffect:
	var effect := ElementalEffect.new()
	effect.caster = self
	effect.element = element
	effect.pattern = shape
	effect.position = get_parent().to_local(at)
	effect.radius = reach
	effect.damage = special_damage
	effect.duration = seconds
	effect.pull = force
	effect.slow = slow_factor
	get_parent().add_child(effect)
	return effect

func _execute_skill(skill: Dictionary) -> void:
	if dead or not is_instance_valid(_player) or _player.get_parent() != get_parent() or bool(_player.get("dead")): return
	match str(skill.get("pattern","")):
		"fan","volley","homing":
			var pattern := str(skill.pattern)
			var count := 7 if pattern == "fan" else 3
			for i in count:
				var spread := (float(i)-(count-1)*0.5)*(0.19 if pattern == "fan" else 0.13)
				var orb := ElementalProjectile.new()
				orb.caster = self
				orb.element = element
				orb.position = position+Vector2(0,-0.6)
				orb.direction = orb.position.direction_to(_aim).rotated(spread)
				orb.damage = projectile_damage
				orb.speed = 6.5 if pattern == "homing" else 8.0
				orb.homing = pattern == "homing"
				get_parent().add_child(orb)
		"dash":
			_charging = true
			_charge_time = 0.45
			_charge_hit = false
			_charge_dir = global_position.direction_to(_aim)
			for i in 3:
				var trail := _ground(global_position+_charge_dir*(i*2.0),"circle",1.1,1.5)
				trail.windup = 0.2+i*0.15
				if element == "chaos":
					var illusion := Sprite2D.new()
					illusion.texture = sprite.texture
					illusion.scale = sprite.scale
					illusion.position = position+_charge_dir*(i*2.0)+sprite.position
					illusion.modulate = Color(0.9,0.3,0.6,0.4)
					illusion.z_index = 6
					get_parent().add_child(illusion)
					var fade := illusion.create_tween()
					fade.tween_property(illusion,"modulate:a",0.0,0.65)
					fade.tween_callback(illusion.queue_free)
		"summon":
			_summons = _summons.filter(func(enemy: Enemy) -> bool: return is_instance_valid(enemy) and not enemy.dead)
			for i in maxi(0,3-_summons.size()):
				var minion := ElementalMinion.new()
				minion.element = element
				minion.monster_level = monster_level
				minion.max_hp = 40+monster_level*7
				minion.damage = maxi(5,floori(damage/3.0))
				minion.position = position+Vector2.from_angle(TAU*i/3.0)*3
				minion.dungeon_alerted = true
				get_parent().add_child(minion)
				_summons.append(minion)

func _boss_name() -> String:
	return str(ElementDB.get_element(element).get("name","Demon"))

func _die() -> void:
	_pending = {}
	_cast_time = 0
	if is_instance_valid(_ability_label): _ability_label.visible = false
	for summon in _summons:
		if is_instance_valid(summon): summon.queue_free()
	super._die()
