extends Sprite2D
## Replaces the Unity Animator on PF Player.
##
## The original controller was a two-layer state machine: a `Direction` int
## (0 = South, 1 = North, 2 = East, 3 = West) feeding a `Movement` layer that
## blended the AM Player Idle and AM Player Move clips.
##
## The directional clips just swap the artwork. The Idle/Move clips did not
## animate frames at all - both drove the SpriteRenderer's sliced `m_Size.y`,
## giving the character a squash-and-stretch bob:
##
##   Idle : 1.40 -> 1.45 (t=0.517) -> 1.40, looping every 1s
##   Move : 1.35 -> 1.45 (t=0.517) -> 1.35, looping every 1s
##
## Those keyframes are reproduced verbatim below.

@export var south_texture: Texture2D
@export var north_texture: Texture2D
@export var east_texture: Texture2D
@export var west_texture: Texture2D

## Rest height the Unity SpriteRenderer was sliced to (m_Size.y).
@export var rest_height := 1.4
## Scale from the sliced-draw conversion, applied on top of the bob.
@export var base_scale := Vector2.ONE

const FACING_SOUTH := 0
const FACING_NORTH := 1
const FACING_EAST := 2
const FACING_WEST := 3

const IDLE_LOW := 1.4
const IDLE_HIGH := 1.45
const MOVE_LOW := 1.35
const MOVE_HIGH := 1.45
const PEAK_T := 0.51666665

var _facing := FACING_SOUTH
var _moving := false
var _timer := 0.0
var _current_facing := -1


func _ready() -> void:
	_apply_facing(FACING_SOUTH)


## Called by PointAndClickController. facing < 0 means "stopped, keep the pose".
func set_facing(facing: int, moving: bool) -> void:
	_moving = moving
	if facing >= 0:
		_facing = facing
		_apply_facing(facing)


func _apply_facing(facing: int) -> void:
	if facing == _current_facing:
		return
	_current_facing = facing
	match facing:
		FACING_SOUTH:
			texture = south_texture
			flip_h = false
		FACING_NORTH:
			texture = north_texture
			flip_h = false
		FACING_EAST:
			texture = east_texture
			flip_h = true
		FACING_WEST:
			texture = west_texture
			flip_h = false


func _process(delta: float) -> void:
	_timer += delta
	if _timer >= 1.0:
		_timer -= 1.0

	var low := MOVE_LOW if _moving else IDLE_LOW
	var high := MOVE_HIGH if _moving else IDLE_HIGH

	# Piecewise-linear through the three baked keyframes.
	var height: float
	if _timer <= PEAK_T:
		height = lerpf(low, high, _timer / PEAK_T)
	else:
		height = lerpf(high, low, (_timer - PEAK_T) / (1.0 - PEAK_T))

	scale = Vector2(base_scale.x, base_scale.y * (height / rest_height))