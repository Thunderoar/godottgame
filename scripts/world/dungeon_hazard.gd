class_name DungeonHazard
extends Node2D
## A repeating rune trap: warning, damaging pulse, then a safe interval.
const RADIUS := 1.35
const WARNING_SECONDS := 1.0
const ACTIVE_SECONDS := 0.65
var damage := 6
var cycle := 4.5
var clock := 0.0
var player: Player
var tint := Color("#de745a")
var element := ""
var _hit := false
var _material: ShaderMaterial

func _ready() -> void:
	add_to_group("dungeon_hazards")
	z_index = -1
	_material = RealmPresentation.spell_material(element if element != "" else "dark")
	var surface := Sprite2D.new()
	surface.texture = RealmPresentation.quad()
	surface.scale = Vector2.ONE*RADIUS
	surface.material = _material
	add_child(surface)
	_update_visual()

func _update_visual() -> void:
	_material.set_shader_parameter("clock",clock)
	_material.set_shader_parameter("activation",1.0 if clock >= WARNING_SECONDS else 0.0)
	_material.set_shader_parameter("fade",1.0 if clock < WARNING_SECONDS+ACTIVE_SECONDS else 0.12)
	_material.set_shader_parameter("motion",not GameSettings.reduce_motion() and GameSettings.effects_at_least("med"))

func _physics_process(delta: float) -> void:
	clock = fmod(clock + delta, cycle)
	if clock >= WARNING_SECONDS + ACTIVE_SECONDS:
		_hit = false
	if is_active() and not _hit and is_instance_valid(player) and not player.dead and not player.controls_locked and global_position.distance_to(player.global_position) < RADIUS:
		_hit = true
		player.take_damage(damage, global_position)
		if element in ["ice","forest","lightning"]: player.apply_elemental_slow(1.2,0.5)
	_update_visual()

func is_active() -> bool:
	return clock >= WARNING_SECONDS and clock < WARNING_SECONDS + ACTIVE_SECONDS

func _draw() -> void:
	pass
