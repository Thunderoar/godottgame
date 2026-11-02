class_name PlayerSprite
extends Sprite2D
## Directional character animation: a proper 4-frame walk cycle
## (contact/pass/contact/pass), an idle stand with occasional blinks, plus hurt
## and sleeping poses. Facing: 0 south, 1 north, 2 east, 3 west.
##
## Frames in PixelArt.character_texture: 0-3 walk, 4 idle, 5 idle blink,
## 6 hurt recoil. The sine squash from the old sprite survives only as a
## secondary motion while walking.

enum Pose { IDLE, WALK, HURT, SLEEP, ATTACK }

@export var character_id := "adam"
@export var frame_duration := 0.13
@export var base_scale := Vector2(PixelArt.PX, PixelArt.PX)

var facing := 0
var moving := false
var pose := Pose.IDLE

var attack_stage := ""
var attack_step := 0
var attack_facing := 2
var attack_key := 0
var attack_age := 0.0
var attack_hold := 0.0
var attack_duration := 0.2
var attack_return_pending := false
var motion_ratio := 0.0
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


func set_motion(actual: Vector2, nominal_speed: float) -> void:
	motion_ratio = clampf(actual.length() / maxf(0.1, nominal_speed), 0.0, 1.8)
	moving = actual.length() > 0.08
	if not moving:
		_timer = 0.0
	_apply()


func begin_attack(direction: Vector2, step: int, _style: String, seconds: float) -> void:
	attack_facing = (2 if direction.x > 0 else 3) if absf(direction.x) > absf(direction.y) else (0 if direction.y > 0 else 1)
	attack_step = step
	attack_stage = "load"
	attack_age = 0
	attack_key = 0
	attack_hold = 0
	attack_return_pending = false
	attack_duration = maxf(0.01,seconds)
	pose = Pose.ATTACK
	_apply()

func strike_attack(direction: Vector2, step: int, style: String) -> void:
	begin_attack(direction,step,style,0.12)
	attack_stage = "strike"
	attack_key = 1
	_apply()

func confirm_attack(seconds: float) -> void:
	if attack_stage == "strike" and not GameSettings.reduce_motion():
		attack_hold = maxf(attack_hold,seconds)

func recover_attack(seconds: float) -> void:
	if attack_stage.is_empty(): return
	if attack_stage == "strike" and attack_age < 0.08:
		attack_return_pending = true
		return
	attack_stage = "return"
	attack_duration = maxf(0.01,seconds)
	attack_age = 0
	attack_key = 3
	_apply()

func end_attack() -> void:
	attack_stage = ""
	attack_return_pending = false
	attack_hold = 0
	if pose == Pose.ATTACK: pose = Pose.IDLE
	_apply()

func advance_attack(delta: float) -> void:
	if attack_stage.is_empty(): return
	if GameSettings.reduce_motion(): attack_hold = 0
	var held := minf(maxf(0,delta),attack_hold)
	attack_hold -= held
	attack_age += maxf(0,delta-held)
	if attack_stage == "strike":
		attack_key = 1 if attack_age < 0.045 else 2
		if attack_return_pending and attack_age >= 0.08:
			attack_stage = "return"
			attack_key = 3
			attack_return_pending = false
	_apply()

func play_pose(new_pose: Pose, duration := 0.0) -> void:
	# Hurt / sleep poses override the cycle for a moment.
	if new_pose != Pose.ATTACK: attack_stage = ""
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
	if not attack_stage.is_empty():
		pose = Pose.ATTACK
		advance_attack(delta)
		return
	if moving:
		pose = Pose.WALK
		_timer += delta * motion_ratio
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
		var profile: Dictionary = PersonalityProfile.current().heroes.get(character_id, {})
		var temperament := float(profile.get("stride", 1.0))
		var breathe := 1.0 + sin(_bob * 11.0 * temperament) * 0.008
		scale = Vector2(base_scale.x, base_scale.y * breathe)
	else:
		scale = base_scale
	var profile: Dictionary = PersonalityProfile.current().heroes.get(character_id, {})
	rotation = sin(_bob * 1.6) * float(profile.get("rest", 0.0)) if not moving and not GameSettings.reduce_motion() else 0.0


func _apply() -> void:
	var dir := attack_facing if not attack_stage.is_empty() and pose not in [Pose.HURT,Pose.SLEEP] else facing
	if dir == 3:
		dir = 2
		flip_h = true
	else:
		flip_h = false
	if pose == Pose.HURT:
		texture = PixelArt.character_texture(character_id, dir, 6)
	elif pose == Pose.SLEEP:
		texture = PixelArt.character_texture(character_id, dir, 5)
	elif not attack_stage.is_empty():
		pose = Pose.ATTACK
		texture = CombatPoseArt.texture(character_id,dir,attack_step,attack_key)
	elif moving:
		texture = PixelArt.character_texture(character_id, dir, _frame)
	else:
		texture = PixelArt.character_texture(character_id, dir, 5 if _blinking else 4)
