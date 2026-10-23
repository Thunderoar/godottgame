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
	# Four-pixel clusters of discrete colours: broad quiet regions, no smooth
	# gradients or per-pixel noise. This is also the Map Studio base renderer.
	var rng := RandomNumberGenerator.new()
	rng.seed = 4771
	var grass := WorldPalette.color("grass")
	var sun := WorldPalette.color("grass_light")
	var shade := WorldPalette.color("grass_shadow")
	for y in range(0, h, 4):
		for x in range(0, w, 4):
			var field := sin(x * 0.009 + sin(y * 0.013)) * 0.5 + sin(y * 0.017 + x * 0.004) * 0.3
			var level := floorf(field * 3.0) / 3.0
			var col := grass.lerp(sun, maxf(0.0, level) * 0.24)
			if x > 45 * 32:
				col = col.lerp(shade, 0.12 + maxf(0.0, -level) * 0.3)
			img.fill_rect(Rect2i(x, y, 4, 4), col)
	# Low foliage grouped along coherent meadow regions; not confetti.
	for i in 850:
		var x := rng.randi_range(6, w - 8)
		var y := rng.randi_range(6, h - 8)
		if sin(x * 0.013) + cos(y * 0.019) < 0.15: continue
		var forest := x > 46 * 32
		var ink := grass.lerp(shade, 0.35) if forest else grass.lerp(sun, 0.28)
		PixelArt.rect(img, x - 3, y, 5, 2, ink)
		PixelArt.rect(img, x, y - 2, 3, 2, ink)
		if forest and i % 3 == 0:
			PixelArt.line(img, x, y, x + 5, y - 3, WorldPalette.color("wood").lerp(grass, 0.55))
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
		# Discrete sea-glass depth shelves; Low retains the full static design.
		for band in range(0, img.get_height() - shore, 8):
			var depth := clampf(float(band) / 144.0, 0.0, 1.0)
			var mid := WorldPalette.color("sea_mid")
			var col := water_near.lerp(mid, minf(1.0, depth * 2.0)) if depth < 0.5 else mid.lerp(water_far, (depth - 0.5) * 2.0)
			img.fill_rect(Rect2i(x, shore + band, 2, mini(8, img.get_height() - shore - band)), col)
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
	# Airy sand: shell pairs, drift marks and small grounded pebbles.
	for i in 65:
		var x := rng.randi_range(4, max_x - 8)
		var shore := _coast_pixel_y(x)
		var top := maxi(0, shore - 84)
		if top >= img.get_height() - 6: continue
		var y := rng.randi_range(top, mini(img.get_height() - 6, maxi(top, shore - 14)))
		if i % 4 == 0:
			PixelArt.hline(img, x - 2, y + 2, 7, sand_dark)
			PixelArt.rect(img, x - 1, y - 1, 4, 3, WorldPalette.color("cream"))
			PixelArt.rect(img, x + 3, y + 2, 2, 2, WorldPalette.color("coral").lerp(sand, 0.5))
		else:
			PixelArt.hline(img, x, y, 4 + i % 6, sand.lerp(sand_dark, 0.28))
	# Wave highlights.
	for i in 160:
		var x := rng.randi_range(1, max_x - 1)
		var shore := _coast_pixel_y(x)
		if shore >= img.get_height() - 8:
			continue
		var y := rng.randi_range(shore + 12, img.get_height() - 2)
		var length := rng.randi_range(2, 9)
		var col := WorldPalette.color("foam").lerp(water_near, 0.7) if i % 3 else WorldPalette.color("sea_mid").lightened(0.12)
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
					elif (int(x / 6) * 7 + int(y / 3) * 13) % 43 == 0:
						img.set_pixel(x, y, base.lerp(light, 0.32))
					elif d < 3.0 and int(y / 8) % 5 == 0:
						img.set_pixel(x, y, base.lerp(edge, 0.16))


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


