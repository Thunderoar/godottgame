class_name FollowCamera
extends Camera2D
## Smooth camera with look-ahead and a decaying hit shake. Each world owns one
## so its map bounds can differ between the lobby and a portal dungeon.
##
## Nearest-filtered art, interpolated actors and an unsnapped camera preserve
## continuous motion. Zoom is a device preference independent of the HUD.

const ZOOM_SCALE := 38.0
const LOOKAHEAD_UNITS := 1.15

var target: Node2D
var bounds := Rect2(0, 0, 64, 40)
var framing_bounds := Rect2() # Optional encounter framing, released on retreat/exit.
var follow_speed := 6.0
var shake_amount := 0.0
var shake_time := 0.0
var _shake_duration := 0.1
var impact_time := 0.0
var impact_duration := 0.16
var impact_strength := 0.0
var impact_direction := Vector2.RIGHT
var impact_count := 0
var _rng := RandomNumberGenerator.new()
var _look := Vector2.ZERO
var manual_pan := false
var pan_center := Vector2.ZERO


func _init() -> void:
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS


func _ready() -> void:
	add_to_group("camera")
	set_process(false)
	GameSettings.changed.connect(_feedback_setting_changed)
	_rng.randomize()
	zoom = Vector2.ONE * GameSettings.camera_zoom()
	position_smoothing_enabled = false
	limit_left = int(bounds.position.x)
	limit_top = int(bounds.position.y)
	limit_right = int(bounds.position.x + bounds.size.x)
	limit_bottom = int(bounds.position.y + bounds.size.y)
	make_current()


func _physics_process(delta: float) -> void:
	var desired_zoom := GameSettings.camera_zoom()
	if framing_bounds.has_area():
		var available := get_viewport_rect().size / (framing_bounds.size + Vector2(2,2))
		desired_zoom = minf(desired_zoom,minf(available.x,available.y))
	zoom = zoom.lerp(Vector2.ONE * desired_zoom, 1.0 - exp(-10.0 * delta))
	if is_instance_valid(target):
		var aim: Vector2 = target.global_position + Vector2(0, -1.0)
		# Look a little ahead of the player's facing so the view leads movement.
		var facing_variant: Variant = target.get("facing")
		if facing_variant != null and not GameSettings.reduce_motion():
			var facing: Vector2 = facing_variant
			if facing.length_squared() > 0.2:
				_look = _look.lerp(facing.normalized() * LOOKAHEAD_UNITS, clampf(delta * 3.0, 0.0, 1.0))
			else:
				_look = _look.lerp(Vector2.ZERO, clampf(delta * 3.0, 0.0, 1.0))
		if GameSettings.reduce_motion():
			_look = _look.move_toward(Vector2.ZERO, delta * 6.0)
		aim += _look
		if framing_bounds.has_area(): aim = framing_bounds.get_center()
		if manual_pan: aim = pan_center
		global_position = global_position.lerp(aim, 1.0 - exp(-delta * follow_speed))
	advance_feedback(delta)


func _feedback_setting_changed(key: String) -> void:
	if key in ["reduce_motion","screen_shake"] and (GameSettings.reduce_motion() or not GameSettings.screen_shake()):
		clear_feedback()

func _process(_delta: float) -> void:
	# Dialogue holds physics callbacks, but leaves presentation running. Do not
	# strand an impact offset while a conversation owns the world.
	if DialogueWorldHold.protects(self): clear_feedback()

func advance_feedback(delta: float) -> void:
	# A finite directional impulse carries the contact. Legacy noise is secondary
	# and the combined displacement is capped in world units, never accumulated.
	if GameSettings.reduce_motion() or not GameSettings.screen_shake():
		clear_feedback()
		return
	var feedback := Vector2.ZERO
	if shake_time > 0.0:
		shake_time = maxf(0.0,shake_time-delta)
		var decay := shake_time/maxf(0.01,_shake_duration)
		feedback = Vector2(_rng.randf_range(-1,1),_rng.randf_range(-1,1))*shake_amount*decay*decay
	if impact_time > 0.0:
		impact_time = maxf(0.0,impact_time-delta)
		var t := 1.0-impact_time/impact_duration
		var pulse := sin(t*TAU*1.35)*exp(-t*4.5)
		if impact_time > 0.0: feedback += impact_direction*pulse*0.07*impact_strength
	offset = feedback.limit_length(0.08)
	if impact_time <= 0.0 and shake_time <= 0.0: set_process(false)

func punch(direction: Vector2, strength := 1.0) -> void:
	if GameSettings.reduce_motion() or not GameSettings.screen_shake(): return
	if direction.length_squared() < 0.001 or strength <= 0.0: return
	impact_direction = direction.normalized()
	impact_strength = maxf(impact_strength*impact_time/impact_duration,clampf(strength,0.0,1.6))
	impact_time = impact_duration
	impact_count += 1
	set_process(true)

func clear_feedback() -> void:
	shake_time = 0.0
	impact_time = 0.0
	impact_strength = 0.0
	offset = Vector2.ZERO
	set_process(false)

func shake(amount: float = 0.16, duration: float = 0.2) -> void:
	if GameSettings.reduce_motion() or not GameSettings.screen_shake(): return
	shake_amount = clampf(amount,0.0,0.08)
	shake_time = maxf(0.0,duration)
	_shake_duration = maxf(0.01,duration)
	set_process(true)
