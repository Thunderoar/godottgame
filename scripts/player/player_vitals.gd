class_name PlayerVitalHud
extends Node2D
## Minimal floating health/mana dashboard above the player's head. Pet and XP
## information stays in the main HUD; this world-space bar shows only HP and MP.

var _pulse := 0.0


func _ready() -> void:
	z_as_relative = false
	z_index = 880
	light_mask = 0
	position = Vector2(0, -1.62)
	set_process(true)


func _process(delta: float) -> void:
	_pulse += delta
	queue_redraw()


func _draw() -> void:
	var hp_max := maxi(1, GameState.health_max())
	var mp_max := maxi(1, GameState.mana_max())
	var hp_ratio := clampf(float(GameState.health()) / float(hp_max), 0.0, 1.0)
	var mp_ratio := clampf(float(GameState.mana()) / float(mp_max), 0.0, 1.0)
	var width := 1.75
	var height := 0.11
	var gap := 0.045
	var top := -height - gap
	draw_rect(Rect2(-width * 0.5 - 0.04, top - 0.04, width + 0.08, height * 2.0 + gap + 0.08), Color(0.015, 0.035, 0.04, 0.9))
	draw_rect(Rect2(-width * 0.5, top, width, height), Color("#321a20"))
	draw_rect(Rect2(-width * 0.5, top, width * hp_ratio, height), Color("#df525d"))
	draw_rect(Rect2(-width * 0.5, top, width, height), Color(0.86, 0.74, 0.62, 0.65), false, 0.018)
	draw_rect(Rect2(-width * 0.5, 0.0, width, height), Color("#172339"))
	draw_rect(Rect2(-width * 0.5, 0.0, width * mp_ratio, height), Color("#6a9fe8"))
	draw_rect(Rect2(-width * 0.5, 0.0, width, height), Color(0.75, 0.84, 0.94, 0.65), false, 0.018)
