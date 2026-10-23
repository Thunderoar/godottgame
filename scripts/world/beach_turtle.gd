class_name BeachTurtle
extends Node2D
## Grounded scenery: only the sprite breathes, its world position stays on sand.
var _art: Sprite2D
var _time := 0.0

func _ready() -> void:
	add_to_group("beach_turtle")
	z_index = 6
	var shadow := Sprite2D.new()
	shadow.texture = PixelArt.light_texture()
	shadow.scale = Vector2(0.010, 0.004)
	shadow.modulate = Color(0.12, 0.09, 0.04, 0.25)
	shadow.position.y = 0.08
	add_child(shadow)
	_art = Sprite2D.new()
	_art.texture = PixelArt.turtle_texture()
	_art.scale = Vector2.ONE * PixelArt.PX
	_art.position.y = -0.18
	add_child(_art)


func _process(delta: float) -> void:
	_time += delta
	_art.scale.y = PixelArt.PX * (1.0 + (sin(_time * 1.6) * 0.018 if not GameSettings.reduce_motion() else 0.0))
