class_name RubbishSystem
extends Node2D
## Spawns flotsam in the shallows. The coastal guard nets some pieces for +1 Gold;
## pieces that slip past transform into rubbish monsters on the sand.

@export var spawn_interval := 8.5
@export var initial_delay := 3.0

var guard: CoastalGuard
var caught_count := 0
var beached_count := 0

var _timer := 0.0
var _lane_index := 0
var _rng := RandomNumberGenerator.new()

const LANES := [
	{
		"start": Vector2(4.0, 28.6),
		"target": Vector2(15.4, 26.1),
		"speed": 0.72,
	},
	{
		"start": Vector2(4.6, 30.8),
		"target": Vector2(22.0, 33.0),
		"speed": 0.62,
	},
	{
		"start": Vector2(4.2, 29.7),
		"target": Vector2(18.8, 29.0),
		"speed": 0.80,
	},
	{
		"start": Vector2(4.6, 30.2),
		"target": Vector2(20.4, 31.2),
		"speed": 0.68,
	},
]


func _ready() -> void:
	add_to_group("rubbish_system")
	_rng.seed = 55123
	_timer = spawn_interval - initial_delay


func _process(delta: float) -> void:
	if guard == null or not is_instance_valid(guard):
		return
	if GameState.emergency_active():
		return
	_timer += delta
	if _timer >= spawn_interval:
		_timer = 0.0
		spawn_piece(_lane_index % LANES.size())
		_lane_index += 1


func spawn_piece(lane: int = 0) -> RubbishPiece:
	var lane_data: Dictionary = LANES[lane % LANES.size()]
	var piece := RubbishPiece.new()
	piece.setup(self, guard, lane_data.start, lane_data.target, float(lane_data.speed))
	add_child(piece)
	return piece


func on_rubbish_caught(piece: RubbishPiece) -> void:
	caught_count += 1
	# A small ripple where the guard's net lifts the piece out.
	Vfx.ring(piece.global_position + Vector2(0, 0.1), 0.5, Color(0.85, 0.95, 0.95, 0.7), 0.35)
	GameState.register_rubbish_cleaned(1)
	if piece:
		piece.outcome = "caught"


func on_rubbish_beached(piece: RubbishPiece) -> void:
	beached_count += 1
	var spawn_at: Vector2 = piece.target if piece else Vector2(17, 29)
	var monster := Enemy.new()
	monster.kind = "rubbish"
	monster.max_hp = 30
	monster.damage = 6
	monster.speed = 1.35
	monster.xp_reward = 5
	monster.gold_reward = 7
	monster.diamond_chance = 0.0
	monster.body_radius = 0.4
	monster.position = spawn_at
	get_parent().add_child(monster)
