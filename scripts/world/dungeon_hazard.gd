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
var _hit := false

func _ready() -> void:
	add_to_group("dungeon_hazards")
	z_index = -1

func _physics_process(delta: float) -> void:
	clock = fmod(clock + delta, cycle)
	if clock >= WARNING_SECONDS + ACTIVE_SECONDS:
		_hit = false
	if is_active() and not _hit and is_instance_valid(player) and not player.dead and not player.controls_locked and global_position.distance_to(player.global_position) < RADIUS:
		_hit = true
		player.take_damage(damage, global_position)
	queue_redraw()

func is_active() -> bool:
	return clock >= WARNING_SECONDS and clock < WARNING_SECONDS + ACTIVE_SECONDS

func _draw() -> void:
	var warning := clock < WARNING_SECONDS
	var color := tint if is_active() else (Color("#ffd383") if warning else tint.darkened(0.45))
	draw_circle(Vector2.ZERO, RADIUS, Color(color, 0.32 if is_active() else 0.09))
	draw_arc(Vector2.ZERO, RADIUS, 0, TAU, 40, color, 0.07, true)
	for i in 6:
		var direction := Vector2.from_angle(i * TAU / 6)
		draw_line(direction * 0.55, direction * (1.1 if is_active() else 0.85), color, 0.08)
