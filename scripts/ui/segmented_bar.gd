class_name SegmentedBar
extends Control
## Segmented stat bar. The number of segments is data-driven so the player's
## health always draws ten chunks and the pet's always draws five.

@export var caption := "HEALTH"
@export var segments := 10
@export var fill_color := Color("#df525d")
@export var empty_color := Color("#281d22")
@export var border_color := Color("#5b7c80")

var value := 100
var maximum := 100
var compact := false

var _displayed := -1.0
var _flash := 0.0
var _gain := 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(210, 30 if compact else 36)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	queue_redraw()


func setup(title: String, color: Color, segment_count: int = 10, is_compact: bool = false) -> void:
	caption = title
	fill_color = color
	segments = segment_count
	compact = is_compact
	custom_minimum_size = Vector2(210, 24 if compact else 34)
	queue_redraw()


func set_values(current: int, total: int) -> void:
	var previous := value
	value = clampi(current, 0, maxi(1, total))
	maximum = maxi(1, total)
	if _displayed < 0.0:
		_displayed = float(value)
	elif value < previous:
		_flash = 0.32
	elif value > previous:
		_gain = 0.4
	queue_redraw()


func _process(delta: float) -> void:
	if _displayed < 0.0:
		_displayed = float(value)
	var drifting := absf(_displayed - float(value)) > 0.01
	if drifting:
		# Smooth drain/fill toward the real value; instant for the first paint.
		_displayed = lerpf(_displayed, float(value), clampf(delta * 9.0, 0.0, 1.0))
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta)
	if _gain > 0.0:
		_gain = maxf(0.0, _gain - delta)
	if drifting or _flash > 0.0 or _gain > 0.0:
		queue_redraw()


func set_caption(text: String) -> void:
	caption = text
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var font_size := 11 if compact else 13
	var bar_h := 12.0 if compact else 16.0
	var bar_y := size.y - bar_h
	draw_rect(Rect2(0, bar_y, size.x, bar_h), Color(0.02, 0.055, 0.065, 0.92))
	var inner := Rect2(2, bar_y + 2, size.x - 4, bar_h - 4)
	var gap := 2.0
	var segment_w := (inner.size.x - gap * float(segments - 1)) / float(segments)
	var ratio := clampf(float(value) / float(maximum), 0.0, 1.0)
	var shown := clampf(_displayed / float(maximum), 0.0, 1.0)
	var filled := shown * float(segments)
	for i in segments:
		var x := inner.position.x + float(i) * (segment_w + gap)
		draw_rect(Rect2(x, inner.position.y, segment_w, inner.size.y), empty_color)
		var amount := clampf(filled - float(i), 0.0, 1.0)
		if amount > 0.0:
			var color := fill_color
			if ratio <= 0.3:
				color = fill_color.lerp(Color("#ff9e54"), 0.45)
			if _flash > 0.0:
				color = color.lerp(Color.WHITE, _flash * 1.6)
			elif _gain > 0.0:
				color = color.lerp(Color("#d6ffd0"), _gain * 1.2)
			draw_rect(Rect2(x, inner.position.y, segment_w * amount, inner.size.y), color)
			draw_rect(Rect2(x, inner.position.y, segment_w * amount, 2), color.lightened(0.28))
	draw_rect(Rect2(0, bar_y, size.x, bar_h), border_color, false, 1.0)
	var text := "%s  %d/%d" % [caption, value, maximum]
	draw_string(font, Vector2(1, bar_y - 5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.87, 0.86, 0.78, 0.9))
