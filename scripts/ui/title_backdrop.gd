class_name TitleBackdrop
extends Control
## Presentation-only coastal diorama. Never creates gameplay actors or consumes RNG.
## Cached village art stays consistent with the selected, restart-bound art family.

const DESIGN_SIZE := Vector2(1280, 720)
const WAVE_SPEED := 0.32
const REDRAW_INTERVAL := 1.0 / 30.0
var _time := 0.0
var _redraw_accum := 0.0
var _houses: Array[Texture2D] = []
var _trees: Array[Texture2D] = []
var _ship: Texture2D
var _hero: Texture2D
var _companion: Texture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for level in [1, 2, 3]:
		_houses.append(PixelArt.house_texture(level))
	for species in [0, 2, 4]:
		_trees.append(MonsoonArt.tree_texture(species))
	_ship = PixelArt.ship_texture()
	_hero = PixelArt.character_texture("adam", 3, 4)
	_companion = PixelArt.pet_texture("ember")
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
	_redraw_accum += delta
	if _redraw_accum >= REDRAW_INTERVAL:
		_redraw_accum = fmod(_redraw_accum, REDRAW_INTERVAL)
		queue_redraw()


func _draw() -> void:
	var fit := maxf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	var placement := (size - DESIGN_SIZE * fit) * 0.5
	if size.x < 800:
		placement.x = (size.x - DESIGN_SIZE.x * fit) * 0.68
	draw_set_transform(placement, 0, Vector2.ONE * fit)
	_draw_sky()
	_draw_water()
	_draw_village()
	_draw_boardwalk()
	# Fine, reproducible flecks break up broad flat colour without a random stream.
	for i in 100:
		var p := Vector2(posmod(i * 193, 1280), posmod(i * 97, 720))
		draw_rect(Rect2(p, Vector2(1, 1)), Color(0.95, 0.87, 0.66, 0.055))
	draw_set_transform(Vector2.ZERO)
	_draw_readability()


func _draw_sky() -> void:
	for i in 60:
		var t := float(i) / 59.0
		var colour := Color("#142e40").lerp(Color("#b57c64"), t)
		draw_rect(Rect2(0, i * 7, 1280, 8), colour)
	var sun_y := 118.0 if size.x < 800 else 215.0
	# The halo is atmosphere; the stepped disk remains deliberately pixel-like.
	for i in range(5, 0, -1):
		draw_circle(Vector2(886, sun_y), 54 + i * 24, Color(1, 0.77, 0.46, 0.017))
	for i in 12:
		var y := sun_y - 52.0 + i * 9
		var half_width := sqrt(maxf(0, 54 * 54 - pow(y + 4.5 - sun_y, 2)))
		draw_rect(Rect2(886 - half_width, y, half_width * 2, 9), Color("#f5d39a").lerp(Color("#e7aa75"), float(i) / 12.0))
	for cloud in [Vector3(720, 111, 0.9), Vector3(1094, 157, 0.7), Vector3(1050, 77, 0.5)]:
		var x: float = float(cloud.x) + roundf(sin(_time * 0.13 + cloud.y) * 4)
		draw_rect(Rect2(x, cloud.y, 162 * cloud.z, 4), Color(0.87, 0.76, 0.65, 0.26))
		draw_rect(Rect2(x + 24, cloud.y - 5, 94 * cloud.z, 5), Color(0.87, 0.76, 0.65, 0.22))
	_poly([Vector2(0, 343), Vector2(170, 299), Vector2(284, 317), Vector2(458, 261), Vector2(610, 310), Vector2(747, 284), Vector2(878, 319), Vector2(1050, 265), Vector2(1280, 310), Vector2(1280, 409), Vector2(0, 409)], Color("#53666a"))
	_poly([Vector2(0, 375), Vector2(190, 350), Vector2(365, 374), Vector2(568, 321), Vector2(722, 359), Vector2(898, 339), Vector2(1030, 363), Vector2(1180, 310), Vector2(1280, 337), Vector2(1280, 416), Vector2(0, 416)], Color("#304e58"))
	for i in 5:
		draw_rect(Rect2(0, 386 + i * 4, 1280, 5), Color(0.62, 0.71, 0.67, 0.045))
	if GameSettings.effects_at_least("med"):
		for i in 4:
			var bird := Vector2(948 + i * 29, 211 + sin(i * 2.1) * 24)
			bird.x += sin(_time * 0.45 + i) * 11
			var wing := sin(_time * 4 + i) * 2
			draw_line(bird - Vector2(5, 1 + wing), bird, Color("#324954"), 1)
			draw_line(bird, bird + Vector2(5, -1 - wing), Color("#324954"), 1)


func _draw_water() -> void:
	for row in 34:
		var y := 400.0 + row * 10
		var depth := float(row) / 33.0
		draw_rect(Rect2(0, y, 1280, 11), Color("#396669").lerp(Color("#102f40"), depth))
		var drift := roundf(sin(_time + row * 1.37) * (3 + depth * 7))
		for j in 9:
			var x := float(posmod(j * 157 + row * 43, 1280)) + drift
			draw_rect(Rect2(x, y + 2, 12 + posmod(j * 17 + row * 23, 55), 1 + floorf(depth)), Color(0.55, 0.78, 0.73, 0.13))
		if row < 25:
			var half_width := 15.0 + row * 4.5
			var warmth := 0.36 - row * 0.011
			draw_rect(Rect2(886 - half_width + drift, y, half_width * 2, 2), Color(0.96, 0.76, 0.45, warmth))
			if row % 3 == 0:
				draw_rect(Rect2(870 - half_width * 0.4 - drift, y + 5, half_width * 1.4, 2), Color(0.96, 0.76, 0.45, warmth * 0.5))


func _draw_village() -> void:
	_poly([Vector2(1015, 449), Vector2(1106, 405), Vector2(1190, 412), Vector2(1280, 437), Vector2(1280, 720), Vector2(1090, 720), Vector2(1060, 552), Vector2(987, 510)], Color("#b39870"))
	_poly([Vector2(1032, 451), Vector2(1110, 419), Vector2(1190, 424), Vector2(1280, 451), Vector2(1280, 720), Vector2(1115, 720), Vector2(1080, 542), Vector2(1006, 505)], Color("#38584d"))
	_poly([Vector2(1094, 720), Vector2(1114, 583), Vector2(1074, 514), Vector2(1126, 458), Vector2(1138, 464), Vector2(1094, 518), Vector2(1137, 582), Vector2(1121, 720)], Color("#9a8c68"))
	if _trees.size() == 3:
		_stamp(_trees[0], Vector2(1190, 440), 0.85, Color("#8da595"))
		_stamp(_trees[2], Vector2(1280, 461), 1.0, Color("#8da595"))
	if _houses.size() == 3:
		# Light on the ground, never a replacement window mask over imported art.
		draw_circle(Vector2(1116, 489), 46, Color(1, 0.73, 0.35, 0.055))
		_stamp(_houses[1], Vector2(1110, 493), 0.95)
		_stamp(_houses[0], Vector2(1240, 513), 0.74, Color("#c5c7b0"))
		_stamp(_houses[0], Vector2(1216, 588), 0.92)
	# Working harbour: mooring pier, piles and a quietly bobbing student ship.
	draw_rect(Rect2(892, 528, 235, 12), Color("#493f37"))
	draw_rect(Rect2(892, 528, 235, 6), Color("#aa8861"))
	for x in range(898, 1128, 13):
		draw_rect(Rect2(x, 528, 1, 7), Color("#6b5946"))
	for x in [907, 985, 1068, 1122]:
		draw_rect(Rect2(x, 520, 4, 35), Color("#493f37"))
		draw_rect(Rect2(x - 1, 519, 6, 3), Color("#c5a571"))
	if _ship != null:
		_stamp(_ship, Vector2(967, 576 + roundf(sin(_time) * 2)), 1.05)
	for i in 28:
		var p := Vector2(1100 + posmod(i * 47, 180), 555 + posmod(i * 61, 160))
		draw_rect(Rect2(p, Vector2(3, 2)), Color("#6d8564"))


func _draw_boardwalk() -> void:
	# A foreground jetty places Adam and Ember inside the landscape, not in a card.
	_poly([Vector2(652, 720), Vector2(775, 561), Vector2(864, 561), Vector2(846, 720)], Color("#3a3330"))
	for row in 20:
		var y := 564.0 + row * 8.5
		var p := float(row) / 19.0
		var left := lerpf(777, 652, p)
		var right := lerpf(863, 846, p)
		draw_rect(Rect2(left, y, right - left, 7), Color("#8f7659").lerp(Color("#4d4b42"), p))
		draw_rect(Rect2(left + 4, y + 2, right - left - 8, 1), Color(0.90, 0.75, 0.50, 0.17))
		if row % 3 == 0:
			draw_circle(Vector2(left + 7, y + 3), 1.2, Color("#343a36"))
			draw_circle(Vector2(right - 7, y + 3), 1.2, Color("#343a36"))
	_lantern(Vector2(781, 569), 0.7)
	_lantern(Vector2(844, 684), 1.1)
	if _hero != null:
		draw_ellipse_shadow(Vector2(796, 612), Vector2(21, 5))
		_stamp(_hero, Vector2(795, 614), 2.15, Color("#c1c1a4"))
	if _companion != null:
		draw_ellipse_shadow(Vector2(837, 633), Vector2(15, 4))
		_stamp(_companion, Vector2(837, 634), 1.45, Color("#d8b991"))
	if _trees.size() == 3:
		_stamp(_trees[1], Vector2(1301, 710), 1.7, Color("#577b6e"))
		_stamp(_trees[2], Vector2(1178, 857), 2.0, Color("#476d62"))
	if GameSettings.effects_at_least("high"):
		for i in 9:
			var p := Vector2(1070 + posmod(i * 53, 210), 524 + posmod(i * 43, 175))
			p += Vector2(sin(_time + i) * 4, cos(_time * 0.8 + i) * 3)
			draw_rect(Rect2(p, Vector2(2, 2)), Color(0.95, 0.83, 0.45, 0.25 + 0.2 * sin(_time * 2 + i)))


func _lantern(foot: Vector2, factor: float) -> void:
	var top := foot - Vector2(0, 49) * factor
	for i in range(3, 0, -1):
		draw_circle(top, i * 10 * factor, Color(1, 0.68, 0.30, 0.025))
	draw_rect(Rect2(foot - Vector2(2, 49) * factor, Vector2(4, 49) * factor), Color("#343e38"))
	draw_rect(Rect2(top - Vector2(5, 6) * factor, Vector2(10, 13) * factor), Color("#493e2f"))
	draw_rect(Rect2(top - Vector2(3, 4) * factor, Vector2(6, 9) * factor), Color("#edc383"))


func _draw_readability() -> void:
	var portrait := size.x < 800
	for i in 64:
		var p := float(i) / 63.0
		var alpha := lerpf(0.92, 0.0, pow(p, 1.25))
		if portrait:
			alpha *= 0.65
		var left := floorf(i * size.x / 80)
		var right := floorf((i + 1) * size.x / 80)
		draw_rect(Rect2(left, 0, right - left, size.y), Color(0.02, 0.06, 0.075, alpha))
	if portrait:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.055, 0.07, 0.22))
	for i in 20:
		var p := float(i) / 19.0
		draw_rect(Rect2(0, size.y - 160 + i * 8, size.x, 8), Color(0.015, 0.04, 0.05, p * 0.6))
	# Fine corner registration marks make the scene feel framed, not boxed in.
	var ink := Color(0.81, 0.72, 0.51, 0.25)
	for corner in [Vector2(20, 20), Vector2(size.x - 20, 20), Vector2(20, size.y - 20), Vector2(size.x - 20, size.y - 20)]:
		var inward := Vector2(1 if corner.x < size.x * 0.5 else -1, 1 if corner.y < size.y * 0.5 else -1)
		draw_line(corner, corner + Vector2(16 * inward.x, 0), ink, 1)
		draw_line(corner, corner + Vector2(0, 16 * inward.y), ink, 1)


func draw_ellipse_shadow(at: Vector2, extent: Vector2) -> void:
	var points := PackedVector2Array()
	for i in 16:
		var angle := TAU * float(i) / 16.0
		points.append(at + Vector2(cos(angle) * extent.x, sin(angle) * extent.y))
	draw_colored_polygon(points, Color(0.01, 0.04, 0.05, 0.45))


func _poly(points: Array, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array(points), color)


func _stamp(tex: Texture2D, foot: Vector2, factor: float, tint: Color = Color.WHITE) -> void:
	var dimensions := tex.get_size() * factor
	draw_texture_rect(tex, Rect2((foot - Vector2(dimensions.x * 0.5, dimensions.y)).round(), dimensions), false, tint)
