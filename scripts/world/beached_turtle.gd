class_name BeachedTurtle
extends Node2D
## A green sea turtle resting on the dry sand above the waterline. Pure scenery
## with a restrained breathing idle — no glow, no sparks, no interaction, and it
## never sits in the ocean or under the animated water overlay.


const BREATH_AMPLITUDE := 0.022
const BREATH_SPEED := 1.1


var _sprite: Sprite2D
var _shadow: Sprite2D
var _breath := 0.0


func _ready() -> void:
	z_index = 4
	light_mask = 0
	_build()


func _build() -> void:
	_shadow = Sprite2D.new()
	_shadow.name = "Shadow"
	_shadow.texture = PixelArt.light_texture()
	_shadow.modulate = Color(0.02, 0.03, 0.03, 0.32)
	_shadow.scale = Vector2(0.012, 0.006)
	_shadow.position = Vector2(0, -0.02)
	_shadow.z_index = -1
	add_child(_shadow)
	_sprite = Sprite2D.new()
	_sprite.name = "Sprite"
	_sprite.texture = PixelArt.turtle_texture()
	_sprite.centered = false
	var size := PixelArt.turtle_texture().get_size()
	_sprite.offset = Vector2(-size.x * 0.5, -size.y + 1.0)
	_sprite.scale = Vector2(PixelArt.PX, PixelArt.PX) * 1.35
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)
	# A small grounded collider so the player walks around it, never through it.
	var body := StaticBody2D.new()
	body.name = "Body"
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 0.38
	shape.shape = circle
	shape.position = Vector2(0, -0.18)
	body.add_child(shape)
	add_child(body)


func _process(delta: float) -> void:
	# Slow shell breathing and the occasional lazy head lift.
	_breath += delta
	var breathe := sin(_breath * BREATH_SPEED)
	if _sprite:
		_sprite.scale = Vector2(PixelArt.PX * 1.35, PixelArt.PX * 1.35 * (1.0 + breathe * BREATH_AMPLITUDE))
		_sprite.position = Vector2(0, breathe * 0.015)
