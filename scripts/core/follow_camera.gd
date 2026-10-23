class_name FollowCamera
extends Camera2D
## Smooth camera with look-ahead, a decaying hit shake and a user-configurable
## zoom. Each world owns one so its map bounds can differ between the lobby and
## a portal dungeon.
##
## The zoom setting (GameSettings.camera_zoom, percent of DEFAULT_ZOOM) is read
## every frame and eased toward, so changing it in Settings transitions smoothly
## and applies identically in the lobby and in dungeons. Equal x/y zoom keeps
## pixels square. The camera rounds its position to the art grid ONLY when the
## effective zoom renders one art pixel at a whole number of screen pixels
## (e.g. the crisp 2:1 look); at fractional scales the engine's own
## snap_2d_transforms_to_pixel keeps rendering crisp while motion stays smooth
## instead of stepping a whole art pixel at a time.

const DEFAULT_ZOOM := 40.0
const LOOKAHEAD_UNITS := 1.15
const ART_GRID := 32.0
const ZOOM_EASE := 3.5

var target: Node2D
var bounds := Rect2(0, 0, 64, 40)
var follow_speed := 6.0
var shake_amount := 0.0
var shake_time := 0.0
var _rng := RandomNumberGenerator.new()
var _look := Vector2.ZERO
var _zoom_target := DEFAULT_ZOOM


func _ready() -> void:
	add_to_group("camera")
	_rng.randomize()
	_zoom_target = zoom_from_settings()
	zoom = Vector2(_zoom_target, _zoom_target)
	position_smoothing_enabled = false
	limit_left = int(bounds.position.x)
	limit_top = int(bounds.position.y)
	limit_right = int(bounds.position.x + bounds.size.x)
	limit_bottom = int(bounds.position.y + bounds.size.y)
	make_current()


func zoom_from_settings() -> float:
	# The setting is a percentage of DEFAULT_ZOOM, clamped to a sane range:
	# 70% (about 28 — wide, near the old main-branch framing) up to 160%
	# (64 — the chunky 2:1 close view).
	var pct := float(GameSettings.camera_zoom()) if GameSettings != null else 100.0
	return clampf(DEFAULT_ZOOM * pct / 100.0, 28.0, 64.0)


func _process(delta: float) -> void:
	# Ease toward the configured zoom so Settings changes glide, never snap.
	var wanted := zoom_from_settings()
	if absf(wanted - _zoom_target) > 0.001:
		_zoom_target = wanted
	if absf(zoom.x - _zoom_target) > 0.01:
		var eased := lerpf(zoom.x, _zoom_target, clampf(delta * ZOOM_EASE, 0.0, 1.0))
		zoom = Vector2(eased, eased)
	if is_instance_valid(target):
		var aim := target.global_position + Vector2(0, -1.0)
		# Look a little ahead of the player's facing so the view leads movement.
		var facing_variant: Variant = target.get("facing")
		if facing_variant != null and not GameSettings.reduce_motion():
			var facing: Vector2 = facing_variant
			if facing.length_squared() > 0.2:
				_look = _look.lerp(facing.normalized() * LOOKAHEAD_UNITS, clampf(delta * 3.0, 0.0, 1.0))
			else:
				_look = _look.lerp(Vector2.ZERO, clampf(delta * 3.0, 0.0, 1.0))
		aim += _look
		global_position = global_position.lerp(aim, clampf(delta * follow_speed, 0.0, 1.0))
		# Snap to the art grid only when one art pixel maps to a whole
		# number of screen pixels; otherwise the 1/32 rounding would step
		# the view a whole art pixel at a time and read as jitter.
		var art_scale := zoom.x / ART_GRID
		if absf(art_scale - roundf(art_scale)) < 0.02:
			global_position = (global_position * ART_GRID).round() / ART_GRID
	if shake_time > 0.0:
		shake_time = maxf(0.0, shake_time - delta)
		offset = Vector2(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1)) * shake_amount * (shake_time / maxf(0.01, shake_time + delta))
	else:
		offset = offset.lerp(Vector2.ZERO, clampf(delta * 12.0, 0.0, 1.0))


func shake(amount: float = 0.16, duration: float = 0.2) -> void:
	# The screen_shake GameSetting existed but nothing read it; this camera now
	# honours it, and reduce-motion disables shake entirely.
	if GameSettings.reduce_motion() or not GameSettings.screen_shake():
		return
	shake_amount = amount
	shake_time = duration
