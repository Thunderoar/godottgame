class_name BesutSign
extends Node2D
## Village-entry road sign reading BESUT — the seaside settlement's name,
## painted cream on weathered wood so it stays readable at normal gameplay
## distance and when zoomed out. Grounded with a shadow and a slim collider
## placed clear of doors, paths, portals and shop fronts.


func _ready() -> void:
	z_index = 5
	light_mask = 0
	_build()


func _build() -> void:
	var shadow := Sprite2D.new()
	shadow.name = "Shadow"
	shadow.texture = PixelArt.light_texture()
	shadow.modulate = Color(0.02, 0.03, 0.03, 0.3)
	shadow.scale = Vector2(0.016, 0.007)
	shadow.position = Vector2(0, -0.02)
	shadow.z_index = -1
	add_child(shadow)
	var sprite := Sprite2D.new()
	sprite.name = "Board"
	sprite.texture = PixelArt.besut_sign_texture()
	sprite.centered = false
	var size := PixelArt.besut_sign_texture().get_size()
	sprite.offset = Vector2(-size.x * 0.5, -size.y + 2.0)
	sprite.scale = Vector2(PixelArt.PX, PixelArt.PX) * 1.4
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	# Slim post collider; the board is high enough to walk "behind".
	var body := StaticBody2D.new()
	body.name = "Body"
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(0.5, 0.5)
	shape.shape = rect
	shape.position = Vector2(0, -0.25)
	body.add_child(shape)
	add_child(body)
