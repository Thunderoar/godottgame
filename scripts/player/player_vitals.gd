class_name PlayerVitalHud
extends Node2D
## Floating health, XP and level above the player's head.

var _pulse := 0.0
var _level: Label
var _xp: Label


func _ready() -> void:
	z_as_relative = false
	z_index = 880
	light_mask = 0
	position = Vector2(0, -1.62)
	_level = Label.new()
	_level.scale = Vector2.ONE * PixelArt.PX
	_level.position = Vector2(1.0, -0.25)
	_level.add_theme_font_size_override("font_size", 13)
	_level.add_theme_color_override("font_color", Color("#ffe2a0"))
	_level.add_theme_color_override("font_shadow_color", Color.BLACK)
	add_child(_level)
	_xp = Label.new()
	_xp.scale = Vector2.ONE * PixelArt.PX
	_xp.position = Vector2(-0.85, -0.65)
	_xp.add_theme_font_size_override("font_size", 10)
	_xp.add_theme_color_override("font_shadow_color", Color.BLACK)
	add_child(_xp)
	set_process(true)


func _process(delta: float) -> void:
	_pulse += delta
	_level.text = "Lv %d" % int(GameState.data.get("level", 1))
	_xp.text = "XP %d/%d" % [int(GameState.data.get("xp", 0)), int(GameState.data.get("xp_next", 60))]
	queue_redraw()


func _draw() -> void:
	var hp_max := maxi(1, GameState.health_max())
	var hp_ratio := clampf(float(GameState.health()) / float(hp_max), 0.0, 1.0)
	var width := 1.75
	var height := 0.11
	var gap := 0.045
	var top := -height - gap
	draw_rect(Rect2(-width * 0.5 - 0.04, top - 0.04, width + 0.08, height * 2.0 + gap + 0.08), Color(0.015, 0.035, 0.04, 0.9))
	draw_rect(Rect2(-width * 0.5, top, width, height), Color("#321a20"))
	draw_rect(Rect2(-width * 0.5, top, width * hp_ratio, height), Color("#df525d"))
	draw_rect(Rect2(-width * 0.5, top, width, height), Color(0.86, 0.74, 0.62, 0.65), false, 0.018)
	var xp_ratio := clampf(float(GameState.data.get("xp", 0)) / maxi(1, int(GameState.data.get("xp_next", 60))), 0, 1)
	var xp_y := 0.0
	draw_rect(Rect2(-width * 0.5, xp_y, width, height), Color("#263730"))
	draw_rect(Rect2(-width * 0.5, xp_y, width * xp_ratio, height), Color("#8ae1b5"))
