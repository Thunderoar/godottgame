class_name PetHitEffect
extends Control
## Short-lived arena impact effect: claw scratches, punch bursts or a shield
## shell. Drawn procedurally so the pet duel needs no external art assets.

var kind := "scratch"
var tint := Color("#f7d06b")
var _age := 0.0
var _lifetime := 1.05


func setup(effect_kind: String, at: Vector2, diameter: float = 96.0) -> void:
	kind = effect_kind
	size = Vector2(diameter, diameter)
	global_position = at - size * 0.5
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_as_relative = false
	z_index = 900
	queue_redraw()


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	_age += delta
	var t := clampf(_age / _lifetime, 0.0, 1.0)
	modulate.a = 1.0 - t
	scale = Vector2.ONE * (1.0 + t * 0.18)
	queue_redraw()
	if _age >= _lifetime:
		queue_free()


func _draw() -> void:
	var c := size * 0.5
	match kind:
		"shield":
			draw_circle(c, size.x * 0.36, Color(0.45, 0.86, 1.0, 0.14))
			draw_arc(c, size.x * 0.38, -2.6, 2.6, 32, Color("#8fe8ff"), 4.0, true)
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(0, -26), c + Vector2(22, -14), c + Vector2(16, 18),
				c + Vector2(0, 28), c + Vector2(-16, 18), c + Vector2(-22, -14),
			]), Color(0.48, 0.8, 0.95, 0.25))
			draw_line(c + Vector2(0, -20), c + Vector2(0, 20), Color("#d8fbff"), 3.0)
		"punch":
			draw_circle(c, 14.0, Color(1.0, 0.74, 0.38, 0.45))
			draw_circle(c, 7.0, Color("#ffe7a6"))
			for i in 8:
				var angle := TAU * float(i) / 8.0
				var inner := c + Vector2.from_angle(angle) * 12.0
				var outer := c + Vector2.from_angle(angle) * (28.0 + float(i % 2) * 8.0)
				draw_line(inner, outer, Color("#ffbe63"), 3.0)
		"impact":
			for i in 4:
				var angle := TAU * float(i) / 4.0 + 0.4
				draw_line(c + Vector2.from_angle(angle) * 4.0, c + Vector2.from_angle(angle) * 32.0, tint, 3.0)
			draw_circle(c, 12.0, Color(tint.r, tint.g, tint.b, 0.55))
		_:
			# Claw scratches.
			for i in 3:
				var offset := float(i - 1) * 12.0
				draw_line(c + Vector2(-24 + offset, -26), c + Vector2(8 + offset, 26), Color("#ff5966"), 4.0)
				draw_line(c + Vector2(-22 + offset, -26), c + Vector2(10 + offset, 26), Color("#ffb3b3"), 1.5)
			draw_circle(c, 8.0, Color(1.0, 0.3, 0.35, 0.35))
