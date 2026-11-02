class_name CombatBodyMotion
extends Node
## Additive presentation on the sprite ONLY. Offset/skew have one owner here;
## existing animation, wind-up tweens, world position and collision stay intact.
var actor: Node2D
var sprite: Sprite2D
var stage := "idle"
var aim := Vector2.RIGHT
var age := 0.0
var duration := 0.18
var hold := 0.0
var weight := 1.0
var displacement := Vector2.ZERO
var _rest_offset := Vector2.ZERO
var _rest_skew := 0.0

func _ready() -> void:
	add_to_group("combat_visual_effects")
	process_priority = 50
	set_process(false)

func configure(subject: Node2D, image: Sprite2D) -> void:
	actor = subject
	sprite = image
	_rest_offset = image.offset
	_rest_skew = image.skew

func windup(direction: Vector2, seconds: float) -> void:
	_start("windup",direction,seconds,1.0)

func swing(direction: Vector2, strength: float = 1.0) -> void:
	_start("strike",direction,0.24 if strength > 1.0 else 0.18,strength)

func recoil(direction: Vector2, strength: float = 1.0, armored := false) -> void:
	_start("recoil",direction,0.22 if strength > 1.0 else 0.18,strength*(0.45 if armored else 1.0))
	hold = 0.025 if _enabled() else 0.0

func _start(next: String, direction: Vector2, seconds: float, strength: float) -> void:
	if not is_instance_valid(sprite): return
	stage = next
	aim = direction.normalized() if direction.length_squared() > 0.001 else Vector2.RIGHT
	age = 0.0
	duration = maxf(0.01,seconds)
	hold = 0.0
	weight = clampf(strength,0.0,1.6)
	set_process(true)
	advance(0.0)

func confirm_hit(seconds: float) -> void:
	if stage == "strike" and _enabled():
		hold = maxf(hold,clampf(seconds,0.0,0.075))

func _process(delta: float) -> void:
	advance(delta)

func advance(delta: float) -> void:
	if stage == "idle": return
	if not is_instance_valid(actor) or actor.is_queued_for_deletion() or not is_instance_valid(sprite):
		cancel()
		return
	if not _enabled() or DialogueWorldHold.protects(actor):
		cancel()
		return
	var held := minf(maxf(0.0,delta),hold)
	hold -= held
	age += maxf(0.0,delta-held)
	var t := clampf(age/duration,0.0,1.0)
	var distance := 0.0
	var lean := 0.0
	match stage:
		"windup":
			distance = -0.085*smoothstep(0.0,1.0,t)
			lean = -0.065*t
		"strike":
			distance = 0.18*weight*pow(1.0-t,2.0)
			lean = 0.105*weight*pow(1.0-t,2.0)
		"recoil":
			distance = 0.18*weight*pow(1.0-t,2.0)
			lean = 0.14*weight*sin((1.0-t)*PI*0.5)
	if t >= 1.0 and stage != "windup":
		cancel()
		return
	displacement = aim*distance
	# Sprite.offset is in texture pixels; convert through its current animation
	# transform so both authored 32px and illustrated sprites move in world units.
	var local := displacement.rotated(-sprite.rotation)
	var safe_scale := Vector2(maxf(absf(sprite.scale.x),0.0001),maxf(absf(sprite.scale.y),0.0001))
	sprite.offset = _rest_offset + local/safe_scale
	sprite.skew = _rest_skew + lean*aim.x

func _enabled() -> bool:
	return not GameSettings.reduce_motion() and GameSettings.effects_at_least("med")

func cancel() -> void:
	stage = "idle"
	hold = 0.0
	displacement = Vector2.ZERO
	if is_instance_valid(sprite):
		sprite.offset = _rest_offset
		sprite.skew = _rest_skew
	set_process(false)

func _exit_tree() -> void:
	cancel()
