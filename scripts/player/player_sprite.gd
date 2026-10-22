class_name PlayerSprite
extends Sprite2D
## Swaps generated directional character textures and adds a small walk bob.
## Facing: 0 south, 1 north, 2 east, 3 west.

@export var character_id := "mira"
@export var frame_duration := 0.24
@export var base_scale := Vector2(PixelArt.PX, PixelArt.PX)

var facing := 0
var moving := false

var _frame := 0
var _timer := 0.0
var _bob := 0.0


func _ready() -> void:
	_apply()


func set_facing(new_facing: int, is_moving: bool) -> void:
	if new_facing >= 0:
		facing = new_facing
	moving = is_moving
	_apply()


func _process(delta: float) -> void:
	_bob += delta
	if moving:
		_timer += delta
		if _timer >= frame_duration:
			_timer -= frame_duration
			_frame = 1 - _frame
			_apply()
	elif _frame != 0:
		_frame = 0
		_timer = 0.0
		_apply()
	# Tiny squash-stretch rather than an offset, preserving the pixel baseline.
	var breathe := 1.0 + sin(_bob * (7.0 if moving else 2.0)) * (0.014 if moving else 0.006)
	scale = Vector2(base_scale.x, base_scale.y * breathe)


func _apply() -> void:
	var dir := facing
	if dir == 3:
		dir = 2
		flip_h = true
	else:
		flip_h = false
	texture = PixelArt.character_texture(character_id, dir, _frame)
