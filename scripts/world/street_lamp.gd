class_name StreetLamp
extends Node2D
var light: PointLight2D
var bulb: Sprite2D
func _ready() -> void:
	z_index = 8
	light = PointLight2D.new()
	light.texture = PixelArt.light_texture()
	light.texture_scale = 0.065
	light.color = Color("#ffdca0")
	light.energy = 0.65
	light.position = Vector2(0,-2.65)
	add_child(light)
	bulb = Sprite2D.new()
	bulb.texture = PixelArt.light_texture()
	bulb.scale = Vector2(0.0035,0.0035)
	bulb.position = light.position
	bulb.modulate = Color("#ffe5ac")
	bulb.light_mask = 0
	add_child(bulb)
func _process(_delta: float) -> void:
	bulb.visible = GameState.is_night()
func _draw() -> void:
	draw_set_transform(Vector2(0,0.05),0,Vector2(1,0.3))
	draw_circle(Vector2.ZERO,0.4,Color(0.03,0.07,0.08,0.3))
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(-0.14,-2.5,0.28,2.5),Color("#283e47"))
	draw_rect(Rect2(-0.08,-2.5,0.06,2.5),Color("#6f8d8e"))
	draw_rect(Rect2(-0.28,-0.25,0.56,0.25),Color("#344f56"))
	draw_rect(Rect2(-0.32,-3.03,0.64,0.12),Color("#25353f"))
	draw_rect(Rect2(-0.25,-2.9,0.5,0.5),Color("#e8bf71"))
	draw_rect(Rect2(-0.15,-2.83,0.14,0.35),Color("#fff1b6"))
	draw_line(Vector2(0,-2.91),Vector2(0,-2.4),Color("#443d37"),0.05)
	draw_rect(Rect2(-0.32,-2.43,0.64,0.12),Color("#344a52"))
