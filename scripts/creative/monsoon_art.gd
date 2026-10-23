@tool
class_name MonsoonArt
extends RefCounted
## Original reproducible pixel assets. All dimensions are art pixels, feet at bottom.
## No world RNG, node allocation, source-image loads or frame-time generation.
const TREE_SIZES := [Vector2i(104, 128), Vector2i(116, 120), Vector2i(84, 144), Vector2i(96, 116), Vector2i(112, 144)]
const LOWER_HEIGHT := 46

static func family(id: String, at: Vector2) -> int:
	var serial := int(id.trim_prefix("forest_")) if id.begins_with("forest_") else absi(id.hash())
	if at.x < 18.0 and at.y > 10.0:
		return 4
	return posmod(serial, 4)

static func tree_texture(species: int, part: String = "whole") -> Texture2D:
	return PixelArt.cached_texture("monsoon/tree/%d/%s" % [species, part], func() -> Image:
		var whole := _tree(species)
		if part == "whole": return whole
		var split := whole.get_height() - LOWER_HEIGHT
		return whole.get_region(Rect2i(0, 0 if part == "upper" else split, whole.get_width(), split if part == "upper" else LOWER_HEIGHT)))

static func _tree(species: int) -> Image:
	var size: Vector2i = TREE_SIZES[posmod(species, TREE_SIZES.size())]
	var img := PixelArt.image(size.x, size.y)
	var cx := size.x / 2
	var foot := size.y - 3
	var dark := WorldPalette.color("wood_shadow")
	var wood := WorldPalette.color("wood")
	var rim := WorldPalette.color("sunlight")
	# Buttress roots and forked, tapering trunk: common material, distinct structure.
	PixelArt._fill_polygon(img, [Vector2i(cx - 12, foot), Vector2i(cx - 4, foot - 9), Vector2i(cx - 5, 38), Vector2i(cx + 3, 33), Vector2i(cx + 5, foot - 8), Vector2i(cx + 13, foot)], dark)
	PixelArt._fill_polygon(img, [Vector2i(cx - 3, foot - 3), Vector2i(cx - 2, 42), Vector2i(cx + 1, 39), Vector2i(cx + 2, foot - 5), Vector2i(cx + 7, foot - 1)], wood)
	PixelArt.line(img, cx - 2, foot - 13, cx - 2, 65, rim.darkened(0.22))
	for y in range(66, foot - 8, 11):
		PixelArt.hline(img, cx, y, 3, dark)
	if species == 4:
		# Coconut: curved trunk, separated arching feather fronds, visible sky gaps.
		img.fill(Color.TRANSPARENT)
		for y in range(35, foot):
			var bend := int(8.0 * sin((y - 35) * 0.018))
			PixelArt.hline(img, cx + bend - 4, y, 8, dark)
			PixelArt.hline(img, cx + bend - 3, y, 4, wood)
			if y % 8 < 2: PixelArt.hline(img, cx + bend - 3, y, 6, rim.darkened(0.2))
		for end in [Vector2i(5, 47), Vector2i(12, 22), Vector2i(32, 7), Vector2i(74, 9), Vector2i(103, 29), Vector2i(106, 54), Vector2i(75, 64)]:
			_frond(img, Vector2i(cx, 32), end)
		for at in [Vector2i(cx - 5, 36), Vector2i(cx + 2, 38), Vector2i(cx + 6, 33)]:
			PixelArt.ellipse(img, at.x, at.y, 4, 5, dark)
			PixelArt.ellipse(img, at.x - 1, at.y - 1, 2, 3, wood)
		return img
	# Branching silhouettes are visible through deliberate gaps in the crown.
	for side in [-1, 1]:
		PixelArt._fill_polygon(img, [Vector2i(cx - 3, 94), Vector2i(cx + side * 26, 47), Vector2i(cx + side * 30, 40), Vector2i(cx + side * 18, 69), Vector2i(cx + 3, 99)], dark)
	var lobes: Array = []
	match species:
		0: lobes = [[29, 51, 22, 23], [73, 51, 23, 25], [50, 27, 25, 24], [48, 62, 27, 22], [22, 73, 16, 16], [79, 75, 17, 17]]
		1: lobes = [[22, 49, 18, 17], [46, 33, 25, 19], [81, 34, 25, 20], [98, 55, 16, 17], [61, 60, 30, 21], [30, 66, 20, 15], [88, 69, 20, 16]]
		2: lobes = [[40, 23, 18, 21], [24, 48, 20, 23], [58, 46, 19, 24], [38, 64, 25, 24], [19, 80, 14, 18], [63, 83, 15, 17]]
		3: lobes = [[25, 42, 19, 21], [63, 39, 21, 23], [46, 21, 20, 18], [46, 61, 26, 21], [74, 65, 17, 17], [20, 65, 14, 16]]
	var deep := WorldPalette.color("leaf_deep")
	var leaf := WorldPalette.color("leaf")
	var mint := WorldPalette.color("leaf_mint")
	var sun := WorldPalette.color("leaf_sun")
	# Overlapping asymmetrical leaf masses, then directional clusters; no white noise.
	for i in lobes.size():
		var l: Array = lobes[i]
		var x := int(l[0])
		var y := int(l[1])
		var rx := int(l[2])
		var ry := int(l[3])
		_crown_mass(img, x, y + 3, rx, ry, deep.darkened(0.1))
		_crown_mass(img, x - 1, y, rx - 1, ry - 3, deep)
		_crown_mass(img, x - 3, y - 5, rx - 3, ry - 6, leaf)
		var rng := RandomNumberGenerator.new()
		rng.seed = 381 + species * 719 + i * 97
		for cluster in 7:
			var dx := rng.randi_range(-rx + 9, rx - 10)
			var dy := rng.randi_range(-ry + 10, ry - 7)
			if pow(float(dx) / rx, 2) + pow(float(dy) / ry, 2) > 0.72: continue
			var ink := leaf.lerp(mint, 0.72 if cluster % 3 == 0 else 0.36) if dy < 2 else leaf.lightened(0.035)
			_leaf_cluster(img, x + dx, y + dy - 4, ink, deep)
			if cluster % 5 == 0 and dy < 0:
				PixelArt.hline(img, x + dx - 2, y + dy - 6, 4, sun)
		if species == 3:
			for blossom in [Vector2i(x - 8, y - 7), Vector2i(x + 6, y + 3)]:
				PixelArt.rect(img, blossom.x - 2, blossom.y, 5, 3, WorldPalette.color("flower"))
				PixelArt.rect(img, blossom.x, blossom.y - 2, 2, 6, WorldPalette.color("coral"))
				PixelArt.rect(img, blossom.x, blossom.y, 2, 2, WorldPalette.color("cream"))
	return img

static func _crown_mass(img: Image, x: int, y: int, rx: int, ry: int, ink: Color) -> void:
	# Broken, overlapping leaf edges rather than repeated circles.
	var points: Array = []
	for p in [Vector2(-1, 0.2), Vector2(-0.91, -0.25), Vector2(-0.7, -0.33), Vector2(-0.8, -0.5), Vector2(-0.4, -0.84), Vector2(-0.08, -0.8), Vector2(0.04, -1), Vector2(0.5, -0.75), Vector2(0.6, -0.45), Vector2(0.86, -0.41), Vector2(1, -0.02), Vector2(0.86, 0.23), Vector2(0.95, 0.41), Vector2(0.6, 0.68), Vector2(0.24, 0.58), Vector2(0.0, 0.87), Vector2(-0.4, 0.72), Vector2(-0.55, 0.47), Vector2(-0.85, 0.5)]:
		points.append(Vector2i(x + roundi(p.x * rx), y + roundi(p.y * ry)))
	PixelArt._fill_polygon(img, points, ink)

static func _leaf_cluster(img: Image, x: int, y: int, ink: Color, shadow: Color) -> void:
	# Three pointed leaves form a coherent spray, with a selective underside.
	PixelArt._fill_polygon(img, [Vector2i(x - 8, y + 1), Vector2i(x - 6, y - 4), Vector2i(x - 1, y - 2), Vector2i(x + 1, y - 5), Vector2i(x + 5, y - 3), Vector2i(x + 9, y + 1), Vector2i(x + 4, y), Vector2i(x + 6, y + 4), Vector2i(x, y + 1), Vector2i(x - 3, y + 4), Vector2i(x - 3, y)], ink)
	PixelArt.hline(img, x - 1, y + 3, 4, shadow)

static func _frond(img: Image, origin: Vector2i, end: Vector2i) -> void:
	var leaf := WorldPalette.color("leaf")
	var mint := WorldPalette.color("leaf_mint")
	var dark := WorldPalette.color("leaf_deep")
	var delta := Vector2(end - origin)
	for step in 22:
		var t := step / 21.0
		var at := Vector2(origin) + delta * t + Vector2(0, -sin(t * PI) * 12)
		var length := int(sin(t * PI) * 12) + 2
		var tilt := -1 if delta.x < 0 else 1
		PixelArt.line(img, int(at.x), int(at.y), int(at.x) + tilt * 3, int(at.y) + length, dark)
		PixelArt.line(img, int(at.x), int(at.y) - 1, int(at.x) + tilt * 2, int(at.y) + length - 3, leaf)
		if step % 2 == 0: PixelArt.line(img, int(at.x), int(at.y) - 2, int(at.x) + tilt * 2, int(at.y) + length / 2, mint)

static func tree_shadow(species: int) -> Texture2D:
	return PixelArt.cached_texture("monsoon/shadow/%d" % species, func() -> Image:
		var img := PixelArt.image(112, 56)
		var shadow := WorldPalette.color("shadow")
		shadow.a = 0.13
		PixelArt.ellipse(img, 58, 26, 48, 20, shadow)
		shadow.a = 0.17
		PixelArt.ellipse(img, 53, 25, 35, 14, shadow)
		shadow.a = 0.24
		PixelArt.ellipse(img, 45, 24, 14, 6, shadow)
		# Clear canopy-shaped gaps produce linked dappled sunlight on the ground.
		for i in 9:
			var x := 22 + posmod(i * 23 + species * 11, 70)
			var y := 13 + posmod(i * 11, 26)
			PixelArt.rect(img, x, y, 6 + i % 3, 3, Color.TRANSPARENT)
		return img)

static func undergrowth(variant: int) -> Image:
	var img := PixelArt.image(40, 32)
	var deep := WorldPalette.color("leaf_deep")
	var leaf := WorldPalette.color("fern")
	var mint := WorldPalette.color("leaf_mint")
	match posmod(variant, 6):
		0, 1: # Fern / pandan fan: long stalks with paired pinnae.
			for end in [Vector2i(3, 16), Vector2i(8, 7), Vector2i(17, 2), Vector2i(28, 5), Vector2i(36, 15)]:
				PixelArt.line(img, 20, 30, end.x, end.y, deep)
				for j in range(2, 8):
					var at := Vector2(20, 30).lerp(Vector2(end), j / 8.0)
					var span := 5 - j / 2
					PixelArt._fill_polygon(img, [Vector2i(int(at.x) - span - 1, int(at.y) - 3), Vector2i(int(at.x) - span, int(at.y)), Vector2i(int(at.x) + 1, int(at.y) + 2)], leaf)
					PixelArt.line(img, int(at.x), int(at.y), int(at.x) + span, int(at.y) - 3, mint if variant == 0 else leaf)
		2: # Broad banana-leaf understory, split tips.
			for end in [Vector2i(5, 8), Vector2i(20, 2), Vector2i(35, 10)]:
				PixelArt.line(img, 20, 30, end.x, end.y, deep)
				PixelArt._fill_polygon(img, [Vector2i(20, 23), Vector2i(end.x - 5, end.y + 5), end, Vector2i(end.x + 5, end.y + 8)], leaf)
				PixelArt.line(img, 20, 23, end.x, end.y, mint)
		3: # A single hibiscus on an asymmetrical leafy stem.
			PixelArt.line(img, 20, 31, 21, 16, deep)
			_leaf_cluster(img, 16, 27, leaf, deep)
			PixelArt._fill_polygon(img, [Vector2i(21, 23), Vector2i(30, 17), Vector2i(30, 23)], mint)
			PixelArt.ellipse(img, 21, 15, 4, 2, WorldPalette.color("coral"))
			PixelArt.ellipse(img, 21, 15, 2, 4, WorldPalette.color("flower"))
			PixelArt.rect(img, 21, 14, 2, 2, WorldPalette.color("cream"))
		_: # Quiet low clover and wind-bent salty grass.
			for x in [7, 15, 21, 30]:
				var y := 17 + int(x) % 7
				PixelArt.line(img, x, 31, x - 3, y, deep)
				if variant == 4:
					PixelArt.ellipse(img, x - 3, y, 3, 2, leaf)
					PixelArt.ellipse(img, x + 1, y - 2, 2, 3, mint)
				else:
					PixelArt.line(img, x + 1, 30, x + 5, y - 3, WorldPalette.color("grass_warm"))
	return img

static func house(level: int, lights_only: bool = false) -> Image:
	var img := PixelArt.image(224, 176)
	var lvl := clampi(level, 1, 5)
	var width := 102 + (lvl - 1) * 15
	var wall_h := 55 + (lvl - 1) * 6
	var left := 112 - width / 2
	var right := left + width
	var base := 151
	var top := base - wall_h
	var roof_h := 38 + (lvl - 1) * 4
	var ridge := top - roof_h
	var wood := WorldPalette.color("wood").darkened(0.12 if lvl == 1 else 0.0)
	var dark := WorldPalette.color("wood_shadow")
	var outline := WorldPalette.color("outline")
	var cream := WorldPalette.color("cream")
	var roof := WorldPalette.color("roof").darkened(0.14 if lvl == 1 else 0.0)
	var shutter := WorldPalette.color("sea_deep").lerp(WorldPalette.color("leaf_mint"), 0.28)
	var window_y := top + 20
	if lights_only:
		for wx: int in [left + 17, right - 30]:
			PixelArt.rect(img, wx + 2, window_y + 2, 9, 12, WorldPalette.color("lantern"))
			PixelArt.vline(img, wx + 6, window_y + 2, 12, dark)
			PixelArt.hline(img, wx + 2, window_y + 8, 9, dark)
		return img
	var contact := WorldPalette.color("shadow")
	contact.a = 0.24
	PixelArt.ellipse(img, 113, base + 6, width / 2 + 12, 9, contact)
	# Short structural stilts, raised deck, weathered siding and upright beams.
	for x: int in [left + 4, left + 21, right - 25, right - 8]:
		PixelArt.rect(img, x, base - 1, 6, 9, dark)
		PixelArt.rect(img, x, base - 1, 2, 8, wood)
	PixelArt.rect(img, left, top, width, wall_h - 2, outline)
	PixelArt.rect(img, left + 2, top + 2, width - 4, wall_h - 6, wood)
	for row in range(top + 5, base - 12, 7):
		PixelArt.hline(img, left + 4, row + 5, width - 8, dark)
		PixelArt.hline(img, left + 4, row, width - 8, wood.lightened(0.12))
		for x in range(left + 12, right - 8, 26):
			PixelArt.hline(img, x + posmod(row, 8), row + 3, 9, wood.darkened(0.09))
	for x: int in [left + 2, right - 7]:
		PixelArt.rect(img, x, top + 4, 5, wall_h - 8, dark)
		PixelArt.vline(img, x, top + 5, wall_h - 10, wood.lightened(0.16))
	# Long ridge with flared end slopes and lapped clay tiles. Never white stripes.
	for row in roof_h:
		var t := row / float(roof_h)
		var span := int(lerpf(width * 0.57, width + 24.0, t))
		var start := 112 - span / 2
		PixelArt.hline(img, start, ridge + row, span, outline)
		if row > 1:
			PixelArt.hline(img, start + 2, ridge + row, span - 4, roof)
			for x in range(start + 4, start + span - 4):
				var tile := posmod(x + (row / 6 % 2) * 5, 11)
				if row % 6 == 5:
					PixelArt.px(img, x, ridge + row, roof.darkened(0.17))
				elif tile < 2:
					PixelArt.px(img, x, ridge + row, roof.lightened(0.12))
	PixelArt.rect(img, 112 - int(width * 0.3), ridge, int(width * 0.6), 3, dark)
	PixelArt.hline(img, 112 - int(width * 0.3) + 2, ridge, int(width * 0.6) - 4, WorldPalette.color("sunlight"))
	PixelArt.rect(img, left - 12, top - 3, width + 24, 5, dark)
	PixelArt.hline(img, left - 10, top - 3, width + 20, wood.lightened(0.2))
	# Deep eave shadow and understated carved ventilation openings.
	PixelArt.rect(img, left + 6, top + 2, width - 12, 6, dark)
	for x in range(left + 10, right - 8, 7):
		PixelArt.rect(img, x, top + 3, 3, 3, outline)
	# Door stays centred on its original interaction and recovery footprint.
	PixelArt.rect(img, 101, base - 41, 22, 34, dark)
	PixelArt.rect(img, 104, base - 38, 16, 29, wood.darkened(0.28))
	PixelArt.vline(img, 112, base - 36, 25, dark)
	PixelArt.rect(img, 116, base - 25, 2, 2, cream)
	for wx: int in [left + 17, right - 30]:
		PixelArt.rect(img, wx, window_y, 13, 17, outline)
		PixelArt.rect(img, wx + 2, window_y + 2, 9, 12, WorldPalette.color("sea_deep"))
		PixelArt.rect(img, wx + 3, window_y + 2, 3, 4, WorldPalette.color("sea_shallow").darkened(0.12))
		PixelArt.vline(img, wx + 6, window_y + 2, 12, dark)
		PixelArt.hline(img, wx + 2, window_y + 8, 9, dark)
		for sx: int in [wx - 6, wx + 14]:
			PixelArt.rect(img, sx, window_y, 5, 15, shutter)
			for yy in range(window_y + 3, window_y + 14, 4): PixelArt.hline(img, sx + 1, yy, 3, WorldPalette.color("leaf_mint"))
		PixelArt.rect(img, wx - 2, window_y + 17, 17, 3, dark)
		if lvl >= 3:
			for fx in [wx + 1, wx + 7, wx + 12]:
				PixelArt.rect(img, fx, window_y + 14, 3, 4, WorldPalette.color("leaf_deep"))
				PixelArt.rect(img, fx - 1, window_y + 12, 4, 3, WorldPalette.color("flower"))
	# Sheltered veranda, paired posts, deck and central steps.
	PixelArt.rect(img, left - 3, base - 9, width + 6, 6, dark)
	PixelArt.hline(img, left - 3, base - 9, width + 6, wood.lightened(0.28))
	for x in range(left + 2, right, 9): PixelArt.vline(img, x, base - 8, 4, wood)
	PixelArt.rect(img, 99, base - 2, 26, 4, wood)
	PixelArt.rect(img, 96, base + 2, 32, 4, dark)
	PixelArt.hline(img, 97, base + 2, 30, wood.lightened(0.3))
	if lvl >= 2:
		for x: int in [left + 9, right - 14]:
			PixelArt.rect(img, x, top + 11, 4, wall_h - 17, dark)
			PixelArt.vline(img, x, top + 12, wall_h - 18, wood.lightened(0.26))
		PixelArt.rect(img, left + 5, top + 10, width - 10, 3, roof.darkened(0.24))
		for x: int in [left + 7, right - 33]:
			PixelArt.rect(img, x, base - 18, 25, 3, wood.lightened(0.16))
			for rail in range(x, x + 25, 6): PixelArt.rect(img, rail, base - 15, 2, 7, dark)
	if lvl == 1:
		PixelArt.rect(img, left + 23, top - 15, 13, 6, roof.darkened(0.27))
		PixelArt.line(img, left + 8, base - 29, left + 21, base - 20, dark)
	if lvl >= 3:
		# Small cooking flue, aligned with the existing high-quality smoke emitter.
		PixelArt.rect(img, right - 19, ridge - 2, 8, 18, dark)
		PixelArt.rect(img, right - 18, ridge - 2, 3, 16, WorldPalette.color("stone"))
		PixelArt.rect(img, right - 21, ridge - 4, 12, 3, outline)
	if lvl >= 4:
		for x: int in [left - 7, right + 2]:
			PixelArt.rect(img, x, base - 8, 7, 9, roof.darkened(0.2))
			PixelArt.ellipse(img, x + 3, base - 11, 8, 5, WorldPalette.color("leaf_deep"))
			PixelArt.ellipse(img, x + 1, base - 13, 6, 3, WorldPalette.color("leaf_mint"))
	if lvl == 5:
		for x: int in [left + 13, right - 17]:
			PixelArt.vline(img, x, top + 5, 8, dark)
			PixelArt.rect(img, x - 3, top + 11, 7, 10, outline)
			PixelArt.rect(img, x - 2, top + 12, 5, 7, WorldPalette.color("lantern"))
	return img

static func prop(kind: String) -> Texture2D:
	return PixelArt.cached_texture("monsoon/props/" + kind, func() -> Image:
		var img := PixelArt.image(64, 64)
		var wood := WorldPalette.color("wood")
		var dark := WorldPalette.color("wood_shadow")
		var cream := WorldPalette.color("cream")
		var contact := WorldPalette.color("shadow")
		contact.a = 0.20
		PixelArt.ellipse(img, 33, 59, 24, 4, contact)
		match kind:
			"fishing_net":
				for x in [9, 52]:
					PixelArt.rect(img, x, 8, 3, 51, dark)
					PixelArt.vline(img, x, 9, 49, wood)
				PixelArt.rect(img, 8, 8, 48, 3, wood)
				for x in range(12, 52, 6):
					PixelArt.line(img, x, 14, mini(53, x + 12), 49, cream.darkened(0.2))
					PixelArt.line(img, x, 14, maxi(11, x - 12), 49, dark)
				PixelArt.hline(img, 12, 49, 40, cream.darkened(0.18))
				PixelArt.ellipse(img, 31, 36, 6, 3, WorldPalette.color("sea_mid"))
				PixelArt._fill_polygon(img, [Vector2i(35, 36), Vector2i(41, 32), Vector2i(41, 40)], WorldPalette.color("sea_deep"))
			"timber":
				for at in [Vector2i(13, 53), Vector2i(27, 54), Vector2i(42, 52), Vector2i(20, 42), Vector2i(36, 41)]:
					PixelArt.rect(img, at.x - 5, at.y - 15, 12, 16, dark)
					PixelArt.vline(img, at.x - 3, at.y - 13, 11, wood)
					PixelArt.ellipse(img, at.x, at.y, 7, 5, wood)
					PixelArt.ellipse_outline(img, at.x, at.y, 4, 3, dark)
					PixelArt.hline(img, at.x - 1, at.y - 1, 3, cream.darkened(0.18))
			"bucket":
				PixelArt.ellipse_outline(img, 31, 35, 11, 17, dark)
				PixelArt._fill_polygon(img, [Vector2i(18, 36), Vector2i(23, 59), Vector2i(42, 59), Vector2i(46, 36)], WorldPalette.color("sea_deep"))
				PixelArt.rect(img, 23, 40, 3, 16, WorldPalette.color("sea_mid"))
				PixelArt.ellipse(img, 32, 36, 14, 4, cream)
				PixelArt.ellipse(img, 32, 36, 11, 3, WorldPalette.color("sea_shallow"))
			"lantern":
				PixelArt.rect(img, 29, 12, 5, 47, dark)
				PixelArt.vline(img, 29, 14, 43, wood)
				PixelArt.rect(img, 29, 9, 20, 4, wood)
				PixelArt.vline(img, 46, 11, 8, dark)
				PixelArt.rect(img, 40, 18, 13, 17, WorldPalette.color("outline"))
				PixelArt.rect(img, 42, 20, 9, 12, WorldPalette.color("lantern"))
				PixelArt.vline(img, 46, 20, 12, dark)
				PixelArt.hline(img, 40, 33, 13, dark)
			_: # Woven baskets and occupied porch planters.
				PixelArt._fill_polygon(img, [Vector2i(13, 40), Vector2i(18, 59), Vector2i(46, 59), Vector2i(51, 40)], dark)
				PixelArt.rect(img, 18, 43, 28, 13, wood)
				for y in range(44, 57, 4):
					PixelArt.hline(img, 19, y, 26, cream.darkened(0.23))
				for x in range(20, 46, 6): PixelArt.vline(img, x, 42, 16, dark)
				PixelArt.ellipse(img, 32, 40, 19, 4, cream.darkened(0.32))
				if kind == "planter":
					for at in [Vector2i(19, 31), Vector2i(32, 25), Vector2i(43, 32)]:
						PixelArt.line(img, 32, 40, at.x, at.y, WorldPalette.color("leaf_deep"))
						_leaf_cluster(img, at.x, at.y + 3, WorldPalette.color("leaf"), WorldPalette.color("leaf_deep"))
						PixelArt.ellipse(img, at.x, at.y - 2, 4, 3, WorldPalette.color("coral"))
						PixelArt.rect(img, at.x, at.y - 3, 2, 2, cream)
				else:
					for at in [Vector2i(22, 35), Vector2i(31, 33), Vector2i(41, 35)]:
						PixelArt.ellipse(img, at.x, at.y, 5, 4, WorldPalette.color("grass_warm"))
		return img)
