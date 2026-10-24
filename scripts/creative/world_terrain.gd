@tool
class_name WorldTerrain
extends RefCounted
const MAP_RECT := Rect2(0, 0, 64, 40)
const OCEAN_WIDTH_PIXELS := 806

static func _make_terrain_texture(layout: WorldLayout = null) -> Texture2D:
	if layout == null: layout = WorldLayout.village()
	var key := "terrain_village_layout_%d_%d" % [WorldPalette.generation, layout.signature()]
	# Imported source bake avoids regenerating the curated default on every launch.
	# Geometry/palette edits invalidate it; custom maps still render from data.
	if layout.terrain_bake_hash == layout.signature() and layout.terrain_palette_hash == palette_signature() and layout.baked_texture() != null:
		var override := AssetRegistry.get_texture(key)
		return override if override else layout.terrain_bake
	if not _terrain_keys.has(key):
		_terrain_keys.append(key)
		while _terrain_keys.size() > 4: PixelArt.CACHE.erase(_terrain_keys.pop_front())
	return PixelArt.cached_texture(key, func() -> Image: return _make_terrain_image(layout))

static var _terrain_keys: Array[String] = []

static func _make_terrain_image(layout: WorldLayout) -> Image:
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
			if x > (45.0 + sin(y * 0.005) * 1.4) * 32:
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
	# Broad polygonal soil/grass masses with feathered boundaries.
	_paint_zones(img, layout)
	_paint_coast(img, rng)
	# Union each route material before compositing: junctions have no dark seams.
	var materials := {}
	for route in layout.routes:
		var material := str(route.get("material", "path"))
		if material == "deck": continue
		if not materials.has(material): materials[material] = PixelArt.image(w, h)
		_paint_path(materials[material], Array(layout.route_points(route)), float(route.get("width", 1.6)), material, str(route.get("role", "secondary")))
	for surface in materials.values(): img.blend_rect(surface, Rect2i(0, 0, w, h), Vector2i.ZERO)
	_paint_sanctuary(img, layout)
	for entry in layout.anchors:
		var kind := str(entry.get("kind", ""))
		var id := str(entry.get("id", ""))
		if kind in ["house", "shop", "residence"] or id in ["market", "north_gate"]:
			var at := layout.approach(id) / PixelArt.PX
			_blend_ellipse(img, int(at.x), int(at.y), 57 if kind != "house" else 95, 27 if kind != "house" else 50, WorldPalette.color("sand"), 0.14)
	return img


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


static func _paint_path(img: Image, points: Array, width_units: float, material: String = "path", role: String = "secondary") -> void:
	var px_points: Array[Vector2] = []
	for p in points:
		px_points.append(Vector2(p.x * 32.0, p.y * 32.0))
	var width_px := width_units * 32.0
	var base := WorldPalette.color(material).lerp(WorldPalette.color("grass"), 0.38)
	if role == "informal": base = WorldPalette.color("grass_shadow").lerp(WorldPalette.color("path"), 0.30)
	if material == "stone": base = WorldPalette.color("stone").lerp(WorldPalette.color("grass_shadow"), 0.18)
	var light := WorldPalette.color("sand")
	for i in px_points.size() - 1:
		var a := px_points[i]
		var b := px_points[i + 1]
		var bounds := Rect2(a, Vector2.ZERO).expand(b).grow(int(width_px * 0.5) + 3)
		for y in range(int(bounds.position.y), int(bounds.position.y + bounds.size.y), 2):
			if y < 0 or y >= img.get_height():
				continue
			for x in range(int(bounds.position.x), int(bounds.position.x + bounds.size.x), 2):
				if x < 0 or x >= img.get_width():
					continue
				var p := Vector2(x, y)
				var d := p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b))
				var edge_noise := sin(float(x) * 0.07 + float(y) * 0.045) * 1.1
				var coverage := clampf((width_px * 0.5 + edge_noise - d) / 4.5, 0.0, 1.0)
				if coverage <= 0.0: continue
				if coverage <= img.get_pixel(x, y).a or is_sea(Vector2(x, y) * PixelArt.PX): continue
				var ink := base
				if (int(x / 6) * 7 + int(y / 3) * 13) % 43 == 0: ink = base.lerp(light, 0.12)
				ink.a = coverage
				img.fill_rect(Rect2i(x, y, mini(2, img.get_width() - x), mini(2, img.get_height() - y)), ink)


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


static func _paint_zones(img: Image, layout: WorldLayout) -> void:
	for zone in layout.zones:
		var id := str(zone.get("id", ""))
		if id in ["beach", "waterfront", "reserved_gameplay"]: continue
		var polygon: PackedVector2Array = zone.get("polygon", PackedVector2Array())
		if polygon.size() < 3: continue
		var bounds := Rect2(polygon[0], Vector2.ZERO)
		for point in polygon: bounds = bounds.expand(point)
		var inner := Geometry2D.offset_polygon(polygon, -1.0)
		var color := WorldPalette.color(str(zone.get("material", "grass")))
		var strength := 0.22 if id not in ["forest_interior", "market", "portal_grounds"] else 0.38
		for y in range(maxi(0, int(bounds.position.y / PixelArt.PX)), mini(img.get_height(), int(bounds.end.y / PixelArt.PX)), 8):
			for x in range(maxi(0, int(bounds.position.x / PixelArt.PX)), mini(img.get_width(), int(bounds.end.x / PixelArt.PX)), 8):
				var at := Vector2(x, y) * PixelArt.PX
				if not Geometry2D.is_point_in_polygon(at, polygon): continue
				var interior := false
				for inset in inner:
					if Geometry2D.is_point_in_polygon(at, inset): interior = true; break
				var alpha := strength
				if not interior:
					var boundary := INF
					for i in polygon.size():
						boundary = minf(boundary, at.distance_to(Geometry2D.get_closest_point_to_segment(at, polygon[i], polygon[(i + 1) % polygon.size()])))
					alpha *= smoothstep(0.0, 1.0, boundary)
				var ink := img.get_pixel(x, y).lerp(color, alpha)
				img.fill_rect(Rect2i(x, y, mini(8, img.get_width() - x), mini(8, img.get_height() - y)), ink)


static func shore_y(world_x: float) -> float:
	var x := int(world_x / PixelArt.PX)
	return float(_coast_pixel_y(x - posmod(x, 2))) * PixelArt.PX


static func is_sea(at: Vector2) -> bool:
	return at.x >= 0.0 and at.x < OCEAN_WIDTH_PIXELS * PixelArt.PX and at.y >= shore_y(at.x)


static func palette_signature() -> int:
	var palette := WorldPalette.current().world
	var keys := palette.keys()
	keys.sort()
	var swatches: Array = []
	for key in keys: swatches.append([key, (palette[key] as Color).to_rgba32()])
	return hash(swatches)


static func _paint_sanctuary(img: Image, layout: WorldLayout) -> void:
	# Rings of inset stones distinguish companion court from ancient combat court.
	# Both share the same cool material and keep their fronts clear.
	var stone := WorldPalette.color("stone").lerp(WorldPalette.color("grass_shadow"), 0.25)
	for id in ["monster_portal", "pet_portal"]:
		var center := layout.approach(id) / PixelArt.PX
		var radius := Vector2(73, 30)
		_blend_ellipse(img, int(center.x), int(center.y), 77, 33, stone, 0.35)
		for i in 16:
			var angle := float(i) * TAU / 16.0
			var point := center + Vector2(cos(angle), sin(angle)) * radius
			PixelArt.rect(img, int(point.x) - 3, int(point.y) - 2, 7, 4, stone.darkened(0.12))
			PixelArt.hline(img, int(point.x) - 2, int(point.y) - 2, 5, stone.lightened(0.15))
