extends Area2D
## Port of Cainos' PropsAltar.cs
##
## Unity ran this as a MonoBehaviour with OnTriggerEnter2D on the altar itself.
## Here the GameObject becomes an Area2D so the same trigger drives it.

@export var rune_paths: Array[NodePath] = []
@export var lerp_speed := 1.0

var _runes: Array[Sprite2D] = []
var _cur_a := 0.0
var _target_a := 0.0
var _base_rgb := Color(1, 1, 1)


func _ready() -> void:
	for p in rune_paths:
		var n := get_node_or_null(p) as Sprite2D
		if n:
			_runes.append(n)
	if not _runes.is_empty():
		_base_rgb = _runes[0].modulate
	body_entered.connect(func(_b: Node2D) -> void: _target_a = 1.0)
	body_exited.connect(func(_b: Node2D) -> void: _target_a = 0.0)


func _process(delta: float) -> void:
	if _runes.is_empty():
		return
	# Unity started from an unset (zero-alpha) colour and lerped towards the
	# trigger state, so a rune that is already lit fades the same way.
	_cur_a = lerpf(_runes[0].modulate.a, _target_a, lerp_speed * delta)
	var c := Color(_base_rgb.r, _base_rgb.g, _base_rgb.b, _cur_a)
	for r in _runes:
		r.modulate = c