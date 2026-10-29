class_name ElementalProjectile
extends Node2D
## Swept, world-owned elemental shots. Homing has a bounded turning rate.
var caster: Enemy
var element := "dark"
var direction := Vector2.RIGHT
var damage := 10
var speed := 7.0
var life := 4.5
var homing := false
var radius := 0.45
var _tint := Color.WHITE
var _dead := false
var _spell: Sprite2D
var _material: ShaderMaterial
var _clock := 0.0

func _ready() -> void:
	add_to_group("elemental_projectiles")
	z_index = 8
	_tint = Color(str(ElementDB.get_element(element).get("glow","#c9a9ff")))
	_material = RealmPresentation.spell_material(element,true)
	_spell = Sprite2D.new()
	_spell.texture = RealmPresentation.quad()
	_spell.material = _material
	_spell.scale = Vector2.ONE*radius*1.6
	add_child(_spell)

func _physics_process(delta: float) -> void:
	if _dead: return
	_clock += delta
	_material.set_shader_parameter("clock",_clock)
	_material.set_shader_parameter("motion",not GameSettings.reduce_motion())
	_spell.rotation = direction.angle()
	if not is_instance_valid(caster) or caster.dead or caster.get_parent() != get_parent():
		queue_free()
		return
	life -= delta
	if life <= 0:
		queue_free()
		return
	var game := get_tree().get_first_node_in_group("game") as Game
	var player := game.player() if is_instance_valid(game) else null
	if not is_instance_valid(player) or player.get_parent() != get_parent() or player.dead: return
	if homing:
		direction = direction.lerp(global_position.direction_to(player.global_position),minf(delta*0.9,0.12)).normalized()
	var previous := global_position
	var motion := direction*speed*delta
	var ray := PhysicsRayQueryParameters2D.create(previous,previous+motion,1)
	var wall := get_world_2d().direct_space_state.intersect_ray(ray)
	var next := Vector2(wall.get("position",previous+motion))
	var closest := Geometry2D.get_closest_point_to_segment(player.global_position,previous,next)
	global_position = next
	if closest.distance_to(player.global_position) <= radius+0.25:
		player.take_damage(damage,global_position)
		if element in ["ice","forest","lightning"]: player.apply_elemental_slow(1.2,0.55)
		_burst()
	elif not wall.is_empty(): _burst()

func _burst() -> void:
	_dead = true
	Vfx.burst(global_position,_tint,5)
	queue_free()

func _draw() -> void:
	pass
