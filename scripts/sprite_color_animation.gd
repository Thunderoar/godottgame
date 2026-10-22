extends Sprite2D
## Port of Cainos' SpriteColorAnimation.cs
## Cycles the sprite tint through a Gradient. The phase offset is random per
## instance, exactly as Unity's `timer = time * Random.value` did.

@export var gradient: Gradient
@export var period := 1.0

var _timer := 0.0


func _ready() -> void:
	if period > 0.0:
		_timer = period * randf()


func _process(delta: float) -> void:
	if gradient == null or period <= 0.0:
		return
	_timer += delta
	if _timer > period:
		_timer = 0.0
	modulate = gradient.sample(_timer / period)