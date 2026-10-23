@tool
class_name WorldTerrain
extends RefCounted
const MAP_RECT := Rect2(0, 0, 64, 40)
const OCEAN_WIDTH_PIXELS := 806

static func _make_terrain_texture() -> Texture2D:
	var key := "terrain_lobby_revamp_%d" % WorldPalette.generation
	if PixelArt.CACHE.has(key):
		return PixelArt.CACHE[key]
	var w := int(MAP_RECT.size.x * 32.0)
	var h := int(MAP_RECT.size.y * 32.0)
	var img := PixelArt.image(w, h)
	# Broad authored-looking meadow bands replace the repeating olive atlas.
	var rng := RandomNumberGenerator.new()
	rng.seed = 4771
	var grass := WorldPalette.color("grass")
	var sun := WorldPalette.color("grass_light")
	var shade := WorldPalette.color("grass_shadow")
	for y in h:
		for x in w:
			var field := sin(float(x) * 0.009 + sin(float(y) * 0.013)) * 0.5 + sin(float(y) * 0.017 + float(x) * 0.004) * 0.3
			var col := grass.lerp(sun, maxf(0.0, field) * 0.20)
			if x > 46 * 32:
				col = col.lerp(shade, smoothstep(46.0 * 32, 62.0 * 32, float(x)) * 0.24)
			img.set_pixel(x, y, col)
	# Sparse clumps with contact shadows and individual blades, not white noise.
	for i in 1800:
		var x := rng.randi_range(3, w - 4)
		var y := rng.randi_range(3, h - 4)
		if sin(float(x) * 0.013) + cos(float(y) * 0.019) < -0.7:
			continue
		PixelArt.hline(img, x - 2, y + 1, 5, grass.darkened(0.06))
		PixelArt.line(img, x, y, x - 1, y - 2, sun.darkened(0.08))
		PixelArt.line(img, x + 1, y, x + 2, y - 1, grass.lightened(0.09))
	# Path network.
	_paint_path(img, [Vector2(34, 24), Vector2(30, 23.2), Vector2(27, 22.6), Vector2(23.8, 22.2)], 0.72)
	_paint_path(img, [Vector2(33.2, 23.5), Vector2(31.5, 20.5), Vector2(29.5, 16.5), Vector2(27, 12.2), Vector2(24, 10.2)], 0.62)
	_paint_path(img, [Vector2(34, 24), Vector2(29, 25.8), Vector2(23, 28), Vector2(17, 30.2), Vector2(11, 31.8)], 0.62)
	_paint_path(img, [Vector2(23.8, 22.2), Vector2(21.5, 20.8), Vector2(21.3, 20.5)], 0.52)
	_paint_path(img, [Vector2(23.8, 22.2), Vector2(25.5, 19.7), Vector2(26.8, 18.8)], 0.52)
	# House clearing.
	_blend_ellipse(img, 34 * 32, 23 * 32, 150, 105, WorldPalette.color("sand"), 0.11)
	_paint_path(img, [Vector2(39.4, 22.0), Vector2(42.8, 15.8), Vector2(43.4, 10.7)], 0.4)
	# Coast and sea.
	_paint_coast(img, rng)
	# A few stone patches around the house.
	for p in [Vector2(31.5, 22.5), Vector2(37, 23.4), Vector2(33.2, 25.4)]:
		_blend_ellipse(img, int(p.x * 32), int(p.y * 32), 26, 15, WorldPalette.color("stone"), 0.25)
	# Grass fringe and tiny flowers.
	for i in 460:
		var x := rng.randi_range(2, w - 3)
		var y := rng.randi_range(2, h - 3)
		var shore := _coast_pixel_y(x)
		if y > shore - 7:
			continue
		var color := WorldPalette.color("grass_shadow") if i % 5 != 0 else WorldPalette.color("gold")
		img.set_pixel(x, y, color)
		if i % 7 == 0:
			img.set_pixel(x + 1, y, color.lightened(0.1))
	var tex := ImageTexture.create_from_image(img)
	PixelArt.CACHE[key] = tex
	return tex


static func _coast_pixel_y(x: int) -> int:
	var u := clampf(float(x) / (25.0 * 32.0), 0.0, 1.0)
	var world_y := lerpf(21.0, 37.0, smoothstep(0.0, 1.0, u)) + sin(float(x) / 31.0) * 0.55
	# Turn the final coast down beyond the map edge instead of cutting the sea
	# and sand off in a vertical rectangle. The rest of the beach is unchanged.
	world_y += smoothstep(22.0 * 32.0, float(OCEAN_WIDTH_PIXELS - 2), float(x)) * 7.0
	return int(world_y * 32.0)


static func _paint_coast(img: Image, rng: RandomNumberGenerator) -> void:
	var water_near := WorldPalette.color("sea_shallow")
	var water_far := WorldPalette.color("sea_deep")
	var sand := WorldPalette.color("sand")
	var sand_dark := WorldPalette.color("wet_sand")
	var foam := WorldPalette.color("foam")
	var max_x := OCEAN_WIDTH_PIXELS
	for x in range(0, max_x, 2):
		var shore := _coast_pixel_y(x)
		var sand_top := clampi(shore - 94, 0, img.get_height())
		if sand_top >= img.get_height():
			continue
		img.fill_rect(Rect2i(x, sand_top, 2, mini(shore, img.get_height()) - sand_top), sand)
		if shore >= img.get_height():
			continue
		img.fill_rect(Rect2i(x, shore, 2, img.get_height() - shore), water_near)
		# A second darker water band further out.
		var deep_start := mini(img.get_height() - 1, shore + 96)
		img.fill_rect(Rect2i(x, deep_start, 2, img.get_height() - deep_start), water_far)
		# Wet sand line.
		img.fill_rect(Rect2i(x, shore - 4, 2, 4), sand_dark)
		# Dithered grass-to-sand transition at the inland edge of the beach.
		for band in 7:
			var by := sand_top + band
			if by < 0:
				continue
			if (x + band * 3) % (band + 2) != 0:
				img.set_pixel(x, by, WorldPalette.color("grass_warm").darkened(0.05 * float(band)))
		# Ragged foam.
		if (x / 2) % 7 != 0:
			img.set_pixel(x, shore, foam)
			if x % 6 == 0:
				img.set_pixel(x, shore + 1, foam)
	# Pebbles on the sand.
	for i in 180:
		var x := rng.randi_range(1, max_x - 1)
		var shore := _coast_pixel_y(x)
		var top := maxi(0, shore - 90)
		if top >= img.get_height():
			continue
		var y := rng.randi_range(top, mini(img.get_height() - 1, maxi(top, shore - 5)))
		img.set_pixel(x, y, sand_dark if i % 2 == 0 else WorldPalette.color("sand"))
	# Wave highlights.
	for i in 260:
		var x := rng.randi_range(1, max_x - 1)
		var shore := _coast_pixel_y(x)
		if shore >= img.get_height() - 8:
			continue
		var y := rng.randi_range(shore + 12, img.get_height() - 2)
		var length := rng.randi_range(2, 9)
		var col := WorldPalette.color("foam") if i % 3 else WorldPalette.color("sea_shallow")
		for xx in length:
			if x + xx < max_x and y >= _coast_pixel_y(x + xx):
				img.set_pixel(x + xx, y, col)
	# Reeds at the water edge.
	for i in 38:
		var x := rng.randi_range(1, max_x - 1)
		var shore := _coast_pixel_y(x)
		if shore <= 30 or shore >= img.get_height() - 5:
			continue
		var height := rng.randi_range(6, 17)
		var col := WorldPalette.color("grass_shadow") if i % 2 == 0 else WorldPalette.color("grass")
		for yy in height:
			img.set_pixel(x, shore - 4 - yy, col)
		img.set_pixel(x - 1, shore - 10, col.darkened(0.15))


static func _paint_path(img: Image, points: Array, width_units: float) -> void:
	var px_points: Array[Vector2] = []
	for p in points:
		px_points.append(Vector2(p.x * 32.0, p.y * 32.0))
	var width_px := width_units * 32.0
	var base := WorldPalette.color("path")
	var edge := WorldPalette.color("path_edge")
	var light := WorldPalette.color("sand")
	for i in px_points.size() - 1:
		var a := px_points[i]
		var b := px_points[i + 1]
		var bounds := Rect2(a, Vector2.ZERO).expand(b).grow(int(width_px) + 4)
		for y in range(int(bounds.position.y), int(bounds.position.y + bounds.size.y)):
			if y < 0 or y >= img.get_height():
				continue
			for x in range(int(bounds.position.x), int(bounds.position.x + bounds.size.x)):
				if x < 0 or x >= img.get_width():
					continue
				var p := Vector2(x, y)
				var d := _distance_to_segment(p, a, b)
				var edge_noise := sin(float(x) * 0.31 + float(y) * 0.12) * 2.5
				if d <= width_px * 0.5 + edge_noise:
					img.set_pixel(x, y, base)
					if d > width_px * 0.5 - 4:
						img.set_pixel(x, y, edge)
					elif (x * 7 + y * 13) % 29 == 0:
						img.set_pixel(x, y, light)


static func _distance_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(0.001, ab.length_squared()), 0.0, 1.0)
	return p.distance_to(a + ab * t)


static func _blend_ellipse(img: Image, cx: int, cy: int, rx: int, ry: int, color: Color, alpha: float) -> void:
	for y in range(-ry, ry + 1):
		var span := int(round(float(rx) * sqrt(maxf(0.0, 1.0 - pow(float(y) / float(maxi(1, ry)), 2.0)))))
		for x in range(-span, span + 1):
			var px := cx + x
			var py := cy + y
			if px < 0 or py < 0 or px >= img.get_width() or py >= img.get_height():
				continue
			var existing := img.get_pixel(px, py)
			img.set_pixel(px, py, existing.lerp(color, alpha))


