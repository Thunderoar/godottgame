class_name ElementalMinion
extends Enemy
## A realm's small demons have their own ranged, rush, trap or wave attacks.
var element := "chaos"
var _power_clock := 1.5
var _shot_clock := -1.0
var _shot_direction := Vector2.RIGHT

func _ready() -> void:
	kind = "minion_"+element
	special_damage = damage
	super._ready()
	_update_art()

func _physics_process(delta: float) -> void:
	if dead: return
	_power_clock = maxf(0,_power_clock-delta)
	if _shot_clock >= 0:
		_shot_clock -= delta
		if _shot_clock < 0: _shoot()
	super._physics_process(delta)
	_update_art()

func _update_art() -> void:
	sprite.texture = PixelArt.enemy_texture(kind,false,_frame)
	sprite.texture_filter = VisualStyle.texture_filter()

func _sprite_rest_scale() -> Vector2:
	return Vector2.ONE*PixelArt.PX*(64.0/sprite.texture.get_height())

func _sprite_rest_position() -> Vector2:
	return Vector2(0,-0.9)

func _chase(delta: float) -> void:
	if is_instance_valid(_target) and _power_clock <= 0 and global_position.distance_to(_target.global_position) < 8:
		_power_clock = 3.6
		var style := str(ElementDB.get_element(element).get("minion_attack","ranged"))
		match style:
			"ranged","homing":
				_shot_direction = global_position.direction_to(_target.global_position)
				_shot_clock = 0.55
				Vfx.ring(global_position,1.1,Color("#ffdb9e"),0.55)
			"dash": _begin_charge()
			_:
				var effect := ElementalEffect.new()
				effect.caster = self
				effect.element = element
				effect.position = _target.position
				effect.damage = damage
				effect.windup = 0.75
				effect.radius = 1.35
				effect.duration = 2.0 if style in ["pool","snare"] else 0.65
				effect.slow = 0.5 if style == "snare" else 1.0
				if style == "wave":
					effect.position = position
					effect.pattern = "wave"
					effect.direction = position.direction_to(_target.position)
					effect.length = 5.0
					effect.travel_speed = 2.5
				get_parent().add_child(effect)
	super._chase(delta)

func _shoot() -> void:
	if dead or not is_instance_valid(_player) or _player.get_parent() != get_parent(): return
	var count := 3 if element == "wind" else 1
	for i in count:
		var orb := ElementalProjectile.new()
		orb.caster = self
		orb.element = element
		orb.direction = _shot_direction.rotated((i-(count-1)*0.5)*0.2)
		orb.position = position
		orb.damage = damage
		orb.speed = 5.5
		orb.homing = element == "dark"
		get_parent().add_child(orb)

func name_text() -> String:
	return str(ElementDB.get_element(element).get("minion_name","Demon"))
