class_name PlayerSprite
extends Sprite2D
## Directional character animation: a proper 4-frame walk cycle
## (contact/pass/contact/pass), an idle stand with occasional blinks, plus hurt
## and sleeping poses. Facing: 0 south, 1 north, 2 east, 3 west.
##
## Frames in PixelArt.character_texture: 0-3 walk, 4 idle, 5 idle blink,
## 6 hurt recoil. The sine squash from the old sprite survives only as a
## secondary motion while walking.

enum Pose { IDLE, WALK, HURT, SLEEP }

@export var character_id := "mira"
@export var frame_duration := 0.13
@export var base_scale := Vector2(PixelArt.PX, PixelArt.PX)

var facing := 0
var moving := false
var pose := Pose.IDLE

var _frame := 0
var _timer := 0.0
var _bob := 0.0
var _blink_timer := 2.8
var _blinking := false
var _pose_timer := 0.0


func _ready() -> void:
	_apply()


func set_facing(new_facing: int, is_moving: bool) -> void:
	if new_facing >= 0:
		facing = new_facing
	moving = is_moving
	_apply()


func play_pose(new_pose: Pose, duration := 0.0) -> void:
	# Hurt / sleep poses override the cycle for a moment.
	pose = new_pose
	_pose_timer = duration
	_apply()


func _process(delta: float) -> void:
	_bob += delta
	if _pose_timer > 0.0:
		_pose_timer = maxf(0.0, _pose_timer - delta)
		if _pose_timer <= 0.0 and (pose == Pose.HURT):
			pose = Pose.IDLE
			_apply()
	if pose == Pose.HURT:
		return
	if pose == Pose.SLEEP:
		if _frame != 5:
			_frame = 5
			_apply()
		return
	if moving:
		pose = Pose.WALK
		_timer += delta
		if _timer >= frame_duration:
			_timer -= frame_duration
			_frame = (_frame + 1) % 4
			_apply()
	else:
		pose = Pose.IDLE
		# Idle: stand (4) with a periodic blink (5).
		_blink_timer -= delta
		if _blinking:
			if _blink_timer <= 0.0:
				_blinking = false
				_blink_timer = randf_range(2.2, 4.4)
				_apply()
		elif _blink_timer <= 0.0:
			_blinking = true
			_blink_timer = 0.13
			_apply()
		elif _frame != 4 and _frame != 5:
			_frame = 4
			_apply()
	# Secondary squash on the walk, preserving the pixel baseline.
	if moving and not GameSettings.reduce_motion():
		var breathe := 1.0 + sin(_bob * 11.0) * 0.02
		scale = Vector2(base_scale.x, base_scale.y * breathe)
	else:
		scale = base_scale


func _apply() -> void:
	var dir := facing
	if dir == 3:
		dir = 2
		flip_h = true
	else:
		flip_h = false
	if pose == Pose.HURT:
		texture = PixelArt.character_texture(character_id, dir, 6)
	elif pose == Pose.SLEEP:
		texture = PixelArt.character_texture(character_id, dir, 5)
	elif moving:
		texture = PixelArt.character_texture(character_id, dir, _frame)
	else:
		texture = PixelArt.character_texture(character_id, dir, 5 if _blinking else 4)
