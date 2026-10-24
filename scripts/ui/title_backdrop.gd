class_name TitleBackdrop
extends Control
## A presentation-only harbour. No gameplay nodes, clocks or placement RNG.

const DESIGN_SIZE := Vector2(1280, 720)
const WAVE_SPEED := 0.45
var _time := 0.0
var _houses: Array[Texture2D] = []
var _trees: Array[Texture2D] = []
var _ship: Texture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for level in [1, 2, 3]:
		_houses.append(PixelArt.house_texture(level))
	for species in [0, 2, 4]:
		_trees.append(MonsoonArt.tree_texture(species))
	_ship = PixelArt.ship_texture()
	GameSettings.changed.connect(_on_settings_changed)
	resized.connect(queue_redraw)
	_update_motion()


func _on_settings_changed(_key: String) -> void:
	_update_motion()


func _update_motion() -> void:
	set_process(not GameSettings.reduce_motion() and GameSettings.effects_at_least("med"))
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta * WAVE_SPEED
	queue_redraw()


func _draw() -> void:
	var fit := maxf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	draw_set_transform((size - DESIGN_SIZE * fit) * 0.5, 0, Vector2.ONE * fit)
	# Broad, stepped colour bands keep the sky in the game's pixel-art language.
	for i in 36:
		var t := float(i) / 35.0
		var sky := Color("#233a50").lerp(Color("#c38c78"), t)
		draw_rect(Rect2(0, i * 12, 1280, 13), sky)
	draw_circle(Vector2(974, 192), 90, Color(1, 0.74, 0.48, 0.055))
	draw_circle(Vector2(974, 192), 66, Color(1, 0.74, 0.48, 0.08))
	draw_rect(Rect2(940, 157, 68, 70), Color("#f5ce97"))
	draw_rect(Rect2(930, 171, 88, 42), Color("#f5ce97"))
	for cloud in [Vector3(630, 120, 1), Vector3(1080, 92, 0.8), Vector3(780, 242, 0.65)]:
		var p := Vector2(cloud.x, cloud.y)
		draw_rect(Rect2(p, Vector2(138, 8) * cloud.z), Color("#b6a0a0"))
		draw_rect(Rect2(p + Vector2(24, -7) * cloud.z, Vector2(78, 9) * cloud.z), Color("#b6a0a0"))
	_poly([Vector2(0, 330), Vector2(190, 298), Vector2(310, 322), Vector2(475, 260), Vector2(610, 310), Vector2(735, 278), Vector2(880, 326), Vector2(1080, 275), Vector2(1280, 310), Vector2(1280, 440), Vector2(0, 440)], Color("#4e6268"))
	_poly([Vector2(0, 366), Vector2(240, 344), Vector2(410, 374), Vector2(660, 320), Vector2(790, 362), Vector2(970, 344), Vector2(1160, 306), Vector2(1280, 328), Vector2(1280, 450), Vector2(0, 450)], Color("#344e53"))
	draw_rect(Rect2(0, 390, 1280, 330), Color("#284f5c"))
	for row in 22:
		var y := 397.0 + row * 15
		var drift := roundf(sin(_time + row * 1.7) * 9)
		for j in 7:
			var x := float(posmod(j * 203 + row * 67, 1280)) + drift
			draw_rect(Rect2(x, y, 32 + posmod(row * 13 + j * 31, 65), 2), Color(0.48, 0.70, 0.70, 0.12))
		if row < 12:
			var spread := 15 + row * 6
			draw_rect(Rect2(972 - spread + drift, y, spread * 2, 3), Color(0.96, 0.77, 0.54, 0.22 - row * 0.012))
	# The shore and lane lead the eye from the sea to the lit cottage.
	_poly([Vector2(680, 720), Vector2(656, 616), Vector2(718, 569), Vector2(800, 544), Vector2(856, 482), Vector2(1032, 440), Vector2(1280, 475), Vector2(1280, 720)], Color("#b59c73"))
	_poly([Vector2(706, 720), Vector2(686, 622), Vector2(744, 578), Vector2(826, 560), Vector2(884, 498), Vector2(1040, 456), Vector2(1280, 490), Vector2(1280, 720)], Color("#405b48"))
	_poly([Vector2(860, 720), Vector2(822, 612), Vector2(924, 539), Vector2(998, 501), Vector2(1015, 505), Vector2(950, 550), Vector2(858, 620), Vector2(900, 720)], Color("#9b8b67"))
	# Distant palms and homes use the same cached authored art as the village.
	if _trees.size() == 3:
		_stamp(_trees[2], Vector2(1160, 475), 0.9, Color("#879983"))
		_stamp(_trees[0], Vector2(1250, 490), 1.2)
	if _houses.size() == 3:
		_stamp(_houses[0], Vector2(1130, 497), 0.65, Color("#c4b5a2"))
		_stamp(_houses[1], Vector2(1000, 532), 1.05)
		_stamp(_houses[0], Vector2(1200, 562), 0.85)
	# Jetty boards, piles and rope. The hero's harbour is the focal point.
	draw_rect(Rect2(620, 568, 272, 19), Color("#443e37"))
	draw_rect(Rect2(620, 568, 272, 11), Color("#9c7c57"))
	for x in range(628, 891, 14):
		draw_rect(Rect2(x, 569, 2, 9), Color("#69543e"))
	for x in [634, 716, 804, 882]:
		draw_rect(Rect2(x, 559, 5, 42), Color("#4a4038"))
		draw_rect(Rect2(x - 1, 558, 7, 4), Color("#b89562"))
	if _ship != null:
		_stamp(_ship, Vector2(706, 650 + roundf(sin(_time) * 2)), 0.9)
	if _trees.size() == 3:
		_stamp(_trees[1], Vector2(1265, 697), 1.65, Color("#b1bca0"))
		_stamp(_trees[2], Vector2(1093, 746), 1.8)
	# Ground details are deterministic and never touch the forest RNG.
	for i in 24:
		var p := Vector2(920 + posmod(i * 57, 330), 590 + posmod(i * 37, 124))
		draw_rect(Rect2(p, Vector2(4, 2)), Color("#6e8059"))
	# Quiet left edge for typography; retain a clear scenic right half.
	for i in 48:
		var alpha := lerpf(0.97, 0.0, pow(float(i) / 47.0, 1.7))
		draw_rect(Rect2(i * 19, 0, 19, 720), Color(0.035, 0.075, 0.095, alpha))
	draw_rect(Rect2(0, 0, 1280, 60), Color(0.025, 0.06, 0.075, 0.28))
	draw_rect(Rect2(0, 672, 1280, 48), Color(0.025, 0.06, 0.075, 0.72))
	draw_set_transform(Vector2.ZERO)


func _poly(points: Array, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array(points), color)


func _stamp(tex: Texture2D, foot: Vector2, factor: float, tint: Color = Color.WHITE) -> void:
	var dimensions := tex.get_size() * factor
	draw_texture_rect(tex, Rect2((foot - Vector2(dimensions.x * 0.5, dimensions.y)).round(), dimensions), false, tint)
