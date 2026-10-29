class_name ElementalEffect
extends Node2D
## Owned, warned ground magic. Forces use collision motion, never teleportation.
var caster: Enemy
var element := "dark"
var pattern := "circle"
var damage := 12
var radius := 2.4
var length := 10.0
var direction := Vector2.RIGHT
var windup := 0.85
var duration := 0.65
var pull := 0.0
var slow := 1.0
var travel_speed := 0.0
var clock := 0.0
var _hit_clock := 0.0
var _tint := Color.WHITE
var _spell: Sprite2D
var _material: ShaderMaterial

func _ready() -> void:
	add_to_group("elemental_effects")
	z_index = 3
	_tint = Color(str(ElementDB.get_element(element).get("glow","#e6bbff")))
	_material = RealmPresentation.spell_material(element)
	_spell = Sprite2D.new()
	_spell.name = "ElementalVolume"
	_spell.texture = RealmPresentation.quad()
	_spell.material = _material
	_spell.texture_filter = VisualStyle.texture_filter()
	add_child(_spell)
	_update_presentation()

func _update_presentation() -> void:
	var linear := pattern in ["line","wave","cleave"]
	_spell.position = direction*length*0.5 if linear else Vector2.ZERO
	_spell.rotation = direction.angle() if linear else 0.0
	_spell.scale = Vector2(length*0.5+radius,radius) if linear else Vector2.ONE*(radius+0.8 if pattern == "ring" else radius)
	_material.set_shader_parameter("beam",linear)
	_material.set_shader_parameter("ring",pattern == "ring")
	_material.set_shader_parameter("inner_radius",maxf(0.0,(radius-0.8)/(radius+0.8)))
	_material.set_shader_parameter("clock",clock)
	_material.set_shader_parameter("activation",1.0 if clock >= windup else 0.0)
	_material.set_shader_parameter("fade",clampf((windup+duration-clock)*5.0,0.0,1.0))
	_material.set_shader_parameter("motion",not GameSettings.reduce_motion() and GameSettings.effects_at_least("med"))

func contains_point(at: Vector2) -> bool:
	var local := to_local(at)
	if pattern in ["line","wave","cleave"]:
		return Geometry2D.get_closest_point_to_segment(local,Vector2.ZERO,direction*length).distance_to(local) <= radius
	if pattern == "ring": return absf(local.length()-radius) <= 0.8
	return local.length() <= radius

func _physics_process(delta: float) -> void:
	if not is_instance_valid(caster) or caster.dead or caster.get_parent() != get_parent():
		queue_free()
		return
	clock += delta
	_update_presentation()
	if clock < windup: return
	if travel_speed > 0: position += direction*travel_speed*delta
	var game := get_tree().get_first_node_in_group("game") as Game
	var player := game.player() if is_instance_valid(game) else null
	_hit_clock -= delta
	if is_instance_valid(player) and player.get_parent() == get_parent() and not player.dead and contains_point(player.global_position):
		if _hit_clock <= 0:
			_hit_clock = 0.8
			player.take_damage(damage,global_position)
		if slow < 1: player.apply_elemental_slow(0.65,slow)
		if pull != 0:
			var force := player.global_position.direction_to(global_position) * pull * minf(delta,0.05)
			player.move_and_collide(force)
	if clock >= windup+duration: queue_free()

func _draw() -> void:
	pass
