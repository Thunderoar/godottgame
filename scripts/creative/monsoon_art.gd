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
	var dark := WorldPalette.color("wood_shadow").lerp(Color("2d5146"),0.22)
	var wood := WorldPalette.color("wood").lerp(WorldPalette.color("sunlight"),0.18)
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
	var deep := WorldPalette.color("leaf_deep").darkened(0.10).lerp(Color("253f39"),0.18)
	var leaf := WorldPalette.color("leaf").lerp(WorldPalette.color("fern"),0.24).darkened(0.03)
	var mint := WorldPalette.color("leaf_mint").lerp(WorldPalette.color("leaf_sun"),0.62).darkened(0.08)
	var sun := WorldPalette.color("leaf_sun").lerp(WorldPalette.color("sunlight"),0.12)
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
		_crown_mass(img,x-5,y-9,maxi(7,rx-7),maxi(5,ry-10),leaf.lerp(mint,0.28))
		var rng := RandomNumberGenerator.new()
		rng.seed = 381 + species * 719 + i * 97
		for cluster in 10:
			var dx := rng.randi_range(-rx + 9, rx - 10)
			var dy := rng.randi_range(-ry + 10, ry - 7)
			if pow(float(dx) / rx, 2) + pow(float(dy) / ry, 2) > 0.72: continue
			var ink := leaf.lerp(mint, 0.62 if cluster % 3 == 0 else 0.26) if dy < 2 else leaf.lerp(deep,0.14)
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
	var leaf := WorldPalette.color("leaf").lerp(WorldPalette.color("fern"),0.32)
	var mint := WorldPalette.color("leaf_mint").lerp(WorldPalette.color("leaf_sun"),0.65).darkened(0.08)
	var dark := WorldPalette.color("leaf_deep").darkened(0.12)
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
	var deep := WorldPalette.color("leaf_deep").darkened(0.10)
	var leaf := WorldPalette.color("fern").lerp(WorldPalette.color("leaf"),0.35).darkened(0.10)
	var mint := WorldPalette.color("leaf_mint").lerp(WorldPalette.color("leaf_sun"),0.70).darkened(0.10)
	PixelArt.ellipse(img,20,28,15,3,Color(WorldPalette.color("grass_shadow"),0.14))
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
	if not lights_only:
		# Gable-end front: the ridge runs into the scene, not across the facade.
		for x in [49, 76, 144, 171]:
			PixelArt.rect(img, x, 147, 5, 12, Color("34434a"))
			PixelArt.rect(img, x + 1, 147, 2, 11, Color("99714e"))
		_house_poly(img, [[44,120],[112,91],[180,120],[180,149],[44,149]], Color("34434a"))
		_house_poly(img, [[48,120],[112,95],[176,120],[176,145],[48,145]], Color("99714e"))
		for y in [123,132,141]:
			PixelArt.rect(img, 49, y, 126, 1, Color("725d48"))
		# A thick lintel and shaded gable give the doorway real recess.
		_house_poly(img, [[50,120],[112,95],[174,120],[170,124],[112,101],[54,124]], Color("b88b58"))
		PixelArt.rect(img, 99, 109, 27, 36, Color("35413c"))
		PixelArt.rect(img, 102, 113, 21, 31, Color("454a3e"))
		PixelArt.rect(img, 103, 114, 4, 29, Color("303b36"))
		PixelArt.rect(img, 123, 113, 3, 31, Color("c79a61"))
		PixelArt.rect(img, 99, 109, 27, 4, Color("cd9c62"))
		# Low front windows stay below the projected eaves, not on a side wall.
		for x in [63, 146]:
			PixelArt.rect(img, x-2, 124, 20, 18, Color("34434a"))
			PixelArt.rect(img, x, 126, 16, 13, Color("49736b"))
			PixelArt.rect(img, x+7, 126, 2, 13, Color("34434a"))
			PixelArt.rect(img, x, 132, 16, 2, Color("34434a"))
		# Roof planes reproduce the supplied projection, not the reference pixels.
		_house_poly(img, [[36,56],[112,21],[188,56],[188,126],[112,94],[36,126]], Color("34434a"))
		_house_poly(img, [[40,59],[108,27],[108,91],[40,122]], Color("bd7e52"))
		_house_poly(img, [[116,27],[184,59],[184,122],[116,91]], Color("98634e"))
		# Parallel courses travel along the same projected roof directions.
		for y in [42,55,68,81]:
			_house_poly(img, [[42,y+31],[106,y+1],[106,y+5],[42,y+35]], Color("d0925e"))
			_house_poly(img, [[118,y+1],[182,y+31],[182,y+35],[118,y+5]], Color("ad7654"))
		# Longitudinal seams read as a pitched volume even without fine texture.
		for x in [57,75,93]:
			var yy := 59 - int((x-40)*32.0/68.0)
			PixelArt.rect(img,x,yy,1,60,Color("9d654b"))
		for x in [132,150,168]:
			var yy := 27 + int((x-116)*32.0/68.0)
			PixelArt.rect(img,x,yy,1,60,Color("805344"))
		# Paired inset roof panels follow each roof plane, not a front rectangle.
		_house_poly(img, [[57,64],[84,51],[84,74],[57,87]], Color("8b614c"))
		_house_poly(img, [[60,65],[81,55],[81,72],[60,82]], Color("c99468"))
		_house_poly(img, [[140,51],[167,64],[167,87],[140,74]], Color("704f43"))
		_house_poly(img, [[143,55],[164,65],[164,82],[143,72]], Color("ab7959"))
		# Ridge spine recedes in screen Y. Front eaves reveal their thickness.
		PixelArt.rect(img, 108, 24, 8, 69, Color("80523f"))
		PixelArt.rect(img, 109, 25, 3, 66, Color("e4b47a"))
		PixelArt.rect(img, 113, 26, 2, 65, Color("b8774d"))
		_house_poly(img, [[37,122],[109,90],[112,95],[40,128]], Color("694d3e"))
		_house_poly(img, [[112,95],[115,90],[187,122],[184,128]], Color("5a4a3e"))
		_house_poly(img, [[40,122],[109,91],[110,94],[41,125]], Color("e1ad72"))
		_house_poly(img, [[114,94],[115,91],[184,122],[183,125]], Color("c98d5e"))
		# Shallow porch top / centered steps; no projecting side return.
		PixelArt.rect(img, 42, 147, 140, 6, Color("c09a68"))
		PixelArt.rect(img, 42, 153, 140, 5, Color("665943"))
		PixelArt.rect(img, 44, 152, 136, 2, Color("d0ad77"))
		PixelArt.rect(img, 100, 154, 26, 4, Color("99714e"))
		PixelArt.rect(img, 97, 158, 32, 4, Color("c09a68"))
		PixelArt.rect(img, 94, 162, 38, 3, Color("71674d"))
		_finish_house(img, level)
	else:
		for x in [63,146]:
			PixelArt.rect(img, x+1, 127, 6, 5, Color("f0c57d"))
			PixelArt.rect(img, x+9, 127, 6, 5, Color("f0c57d"))
			PixelArt.rect(img, x+1, 134, 6, 4, Color("d9aa68"))
			PixelArt.rect(img, x+9, 134, 6, 4, Color("d9aa68"))
		_house_poly(img, [[62,66],[79,58],[79,72],[62,80]], Color("d9b979"))
		_house_poly(img, [[145,58],[162,66],[162,80],[145,72]], Color("c8a268"))
		_house_poly(img, [[62,72],[79,64],[79,66],[62,74]], Color.TRANSPARENT)
		_house_poly(img, [[145,64],[162,72],[162,74],[145,66]], Color.TRANSPARENT)
		PixelArt.vline(img, 70, 62, 14, Color.TRANSPARENT)
		PixelArt.vline(img, 153, 64, 12, Color.TRANSPARENT)
	return img

# Geometry is locked to the user-approved reference-led cottage proof.
static func _house_poly(img: Image, points: Array, ink: Color) -> void:
	var vertices: Array = []
	for point in points:
		vertices.append(Vector2i(point[0], point[1]))
	PixelArt._fill_polygon(img, vertices, ink)

static func _finish_house(img: Image, level: int) -> void:
	var tier := clampi(level, 1, 5)
	var clay := WorldPalette.color("roof").lerp(Color("b87850"), 0.48)
	var timber := WorldPalette.color("wood").lerp(Color("ac8959"), 0.42)
	var timber_dark := WorldPalette.color("wood_shadow").lerp(Color("49584b"), 0.30)
	# Two roof planes, each textured in its own projected material coordinates.
	# This is discrete clustered colour, not image noise or a gradient overlay.
	for side in 2:
		for x in range(40, 185):
			var u := float(x - 40) / 68.0 if side == 0 else float(184 - x) / 68.0
			if u < 0.0 or u >= 1.0: continue
			var back := 59.0 - u * 32.0
			for y in range(27, 123):
				var v := float(y) - back
				if v < 0.0 or v >= 63.0: continue
				var row := int(v) / 8
				var seam := posmod(int((1.0 - u) * 68.0) + (row % 2) * 4, 9)
				var along := posmod(int(v), 8)
				var tile := int((1.0 - u) * 68.0 + (row % 2) * 4) / 9
				var variation := float(posmod(tile * 13 + row * 7 + tier, 5) - 2) * 0.024
				var ink := clay.lightened(variation + 0.03) if side == 0 else clay.darkened(0.19 - variation)
				if along == 7: ink = ink.darkened(0.20)
				elif along == 0 and seam > 1: ink = ink.lightened(0.12)
				elif seam == 0: ink = ink.darkened(0.12)
				elif seam == 1 and along < 6: ink = ink.lightened(0.05)
				# Occasional coherent edge wear, not all-over pixel confetti.
				if posmod(tile + row * 3, 13) == 0 and along == 1 and seam in [4, 5]: ink = ink.lightened(0.13)
				PixelArt.px(img, x, y, ink)
	# Warm varied timber stays under the roof. Existing openings remain dark.
	for y in range(96, 147):
		for x in range(48, 177):
			var original := img.get_pixel(x, y)
			if original != Color("99714e") and original != Color("725d48"): continue
			var row := posmod(y - 97, 7)
			var board := (y - 97) / 7
			var ink := timber.lightened(float(posmod(board, 3) - 1) * 0.035)
			if row == 6: ink = timber_dark
			elif row == 0: ink = ink.lightened(0.15)
			elif row == 3 and posmod(x + board * 11, 29) < 7: ink = ink.darkened(0.10)
			if posmod(x + (board % 2) * 14, 38) == 0: ink = ink.darkened(0.16)
			PixelArt.px(img, x, y, ink)
	# Real roof glazing: inset frames follow the SAME slopes as their tiles.
	_house_poly(img, [[56,63],[85,49],[85,76],[56,89]], timber_dark)
	_house_poly(img, [[59,64],[82,53],[82,74],[59,85]], timber.lightened(0.21))
	_house_poly(img, [[62,66],[79,58],[79,72],[62,80]], Color("3c6663"))
	_house_poly(img, [[64,66],[68,64],[68,77],[64,79]], Color("79a99a"))
	PixelArt.vline(img, 70, 62, 14, timber_dark)
	_house_poly(img, [[62,72],[79,64],[79,66],[62,74]], timber_dark)
	_house_poly(img, [[139,49],[168,63],[168,89],[139,76]], timber_dark)
	_house_poly(img, [[142,53],[165,64],[165,85],[142,74]], timber)
	_house_poly(img, [[145,58],[162,66],[162,80],[145,72]], Color("385d5c"))
	_house_poly(img, [[147,60],[151,62],[151,74],[147,72]], Color("6d9484"))
	PixelArt.vline(img, 153, 64, 12, timber_dark)
	_house_poly(img, [[145,64],[162,72],[162,74],[145,66]], timber_dark)
	# Ridge caps and thick front eaves; neither changes the approved contour.
	for y in range(27, 88, 8):
		PixelArt.rect(img, 109, y, 6, 1, clay.darkened(0.36))
		PixelArt.rect(img, 109, y + 1, 3, 2, clay.lerp(WorldPalette.color("sunlight"), 0.65))
	for x in [48, 173]:
		PixelArt.vline(img, x, 125, 21, timber_dark)
		PixelArt.vline(img, x + 1, 126, 19, timber.lightened(0.17))
	# Door jamb, inner recess, threshold and selective hardware highlights.
	PixelArt.rect(img, 100, 112, 2, 31, timber_dark)
	PixelArt.rect(img, 124, 114, 2, 29, timber.lightened(0.20))
	PixelArt.rect(img, 103, 141, 20, 3, timber_dark.darkened(0.25))
	PixelArt.hline(img, 102, 144, 23, timber.lightened(0.22))
	for wx in [63, 146]:
		PixelArt.rect(img, wx + 1, 127, 3, 3, Color("88b8a4"))
		PixelArt.hline(img, wx - 2, 141, 20, timber_dark)
		PixelArt.hline(img, wx - 1, 142, 18, timber.lightened(0.18))
	# Porch boards, risers and wear are aligned to the horizontal front.
	for x in range(46, 180, 8):
		PixelArt.vline(img, x, 148, 4, timber_dark.lightened(0.15))
		PixelArt.vline(img, x + 1, 148, 3, timber.lightened(0.20))
	for y in [154, 158, 162]:
		var width: int = 26 + ((y - 154) / 4) * 6
		PixelArt.hline(img, 113 - width / 2, y, width, timber.lightened(0.25))
	# Useful threshold props stay inside the existing building silhouette.
	PixelArt.rect(img, 84, 143, 10, 9, timber_dark)
	PixelArt.rect(img, 85, 144, 8, 7, Color("a28b58"))
	for y in [145, 148, 151]: PixelArt.hline(img, 85, y, 8, Color("786841"))
	for x in [87, 91]: PixelArt.vline(img, x, 144, 7, Color("c0a46b"))
	PixelArt.rect(img, 158, 144, 8, 8, clay.darkened(0.20))
	PixelArt.hline(img, 157, 143, 10, clay.lightened(0.13))
	PixelArt.ellipse(img, 161, 141, 5, 3, WorldPalette.color("leaf_deep"))
	PixelArt.ellipse(img, 160, 139, 3, 2, WorldPalette.color("leaf"))
	if tier >= 2:
		for x in [56, 167]:
			PixelArt.hline(img, x, 134, 6, timber.lightened(0.24))
	if tier >= 3:
		for x in [66, 151]:
			PixelArt.rect(img, x - 3, 143, 12, 3, timber_dark)
			PixelArt.hline(img, x - 2, 142, 10, WorldPalette.color("leaf_deep"))
			for fx in [x, x + 4]: PixelArt.rect(img, fx, 140, 2, 2, WorldPalette.color("flower"))
	if tier >= 4:
		PixelArt.hline(img, 102, 110, 23, WorldPalette.color("gold").darkened(0.12))
	if tier == 5:
		for x in [97, 126]:
			PixelArt.vline(img, x, 115, 8, timber_dark)
			PixelArt.rect(img, x - 1, 120, 4, 6, Color("b28b58"))

static func cottage_ground() -> Image:
	var img := PixelArt.image(384, 256)
	var soil := WorldPalette.color("path_edge").lerp(WorldPalette.color("wood_shadow"), 0.22)
	var rim := soil
	rim.a = 0.12
	# Interlocking soil masses: broken organic margins rather than a solid polygon.
	for patch in [[192,83,118,30],[148,102,63,30],[231,111,58,31],[192,136,39,53]]:
		PixelArt.ellipse(img, patch[0],patch[1],patch[2],patch[3],rim)
	var worn := soil.lightened(0.16)
	worn.a = 0.25
	for patch in [[192,84,105,22],[190,114,28,40],[183,163,27,28]]:
		PixelArt.ellipse(img,patch[0],patch[1],patch[2],patch[3],worn)
	var shadow := WorldPalette.color("shadow")
	shadow.a = 0.18
	PixelArt.ellipse(img,192,66,98,10,shadow)
	var stone := WorldPalette.color("stone").lerp(WorldPalette.color("path"), 0.43)
	stone.a = 0.72
	for p in [Vector2i(190,91),Vector2i(194,114),Vector2i(187,139),Vector2i(183,162)]:
		_house_poly(img, [[p.x-12,p.y],[p.x-8,p.y-4],[p.x+9,p.y-3],[p.x+13,p.y+2],[p.x+7,p.y+5],[p.x-11,p.y+4]], stone)
		PixelArt.hline(img,p.x-7,p.y-3,15,Color(stone,0.80).lightened(0.09))
		PixelArt.hline(img,p.x-8,p.y+4,15,Color(stone,0.50).darkened(0.15))
	# Independently seeded decorative clusters; zero gameplay RNG consumption.
	var rng := RandomNumberGenerator.new()
	rng.seed = 40173
	for bed in [Vector2i(89,103),Vector2i(280,97),Vector2i(123,132),Vector2i(253,137)]:
		for sprig in 6:
			var x: int = int(bed.x) + rng.randi_range(-13,13)
			var y: int = int(bed.y) + rng.randi_range(-7,7)
			var leaf := WorldPalette.color("leaf").lerp(WorldPalette.color("grass_shadow"),0.4)
			leaf.a = 0.68
			_house_poly(img,[[x-4,y],[x-3,y-5],[x,y-2],[x+2,y-7],[x+5,y],[x+1,y+2]],leaf)
			PixelArt.hline(img,x,y-2,3,Color(WorldPalette.color("leaf_sun"),0.65))
			if sprig == 2:
				PixelArt.rect(img,x,y-3,2,2,Color(WorldPalette.color("flower"),0.78))
	for p in [Vector2i(123,94),Vector2i(271,116),Vector2i(151,151)]:
		PixelArt.rect(img,p.x,p.y,7,2,Color(soil,0.45))
		PixelArt.rect(img,p.x+2,p.y-1,3,1,Color(soil,0.35))
	return img


static func prop(kind: String) -> Texture2D:
	return PixelArt.cached_texture("monsoon/props/" + kind, func() -> Image: return _work_prop(kind))


# Shared material treatment; dimensions/cache ownership stay with existing callers.
static func _work_prop(kind: String) -> Image:
	var img := PixelArt.image(64, 64)
	var wood := WorldPalette.color("wood").lerp(Color("b59666"), 0.42)
	var dark := WorldPalette.color("wood_shadow").lerp(Color("304b45"), 0.30)
	var light := wood.lerp(WorldPalette.color("cream"), 0.40)
	var fibre := WorldPalette.color("cream").lerp(wood, 0.48)
	var metal := WorldPalette.color("stone").lerp(Color("48746d"), 0.50).darkened(0.14)
	PixelArt.ellipse(img, 32, 60, 23, 2, Color(WorldPalette.color("shadow"), 0.18))
	match kind:
		"fishing_net":
			for x in [9, 51]:
				PixelArt.rect(img, x, 10, 4, 49, dark)
				PixelArt.vline(img, x + 1, 11, 46, wood)
				PixelArt.rect(img, x - 1, 56, 6, 3, dark)
			_prop_bin(img, 8, 10, 49, 4, 3, wood, dark, light)
			# Sagging linen mesh, not a flat grid or a newly drawn animal.
			for row in 7:
				var previous := Vector2i(13, 16 + row * 5)
				for step in range(1, 9):
					var t := step / 8.0
					var point := Vector2i(13 + step * 5, 16 + row * 5 + int(sin(t * PI) * 5.0))
					PixelArt.line(img, previous.x, previous.y, point.x, point.y, fibre.darkened(0.12 if row % 2 else 0.22))
					previous = point
			for column in 8:
				var x := 14 + column * 5
				PixelArt.line(img, x, 16, x - 2, 48 + int(sin(column / 7.0 * PI) * 5.0), Color(fibre, 0.75))
			for x in [15, 29, 43]:
				PixelArt.ellipse(img, x, 16, 2, 2, wood.lightened(0.12))
			for x in [14, 25, 37, 48]: PixelArt.rect(img, x, 51, 3, 3, metal)
		"timber":
			for at in [Vector2i(18, 53), Vector2i(31, 54), Vector2i(43, 52), Vector2i(25, 42), Vector2i(38, 41)]:
				_house_poly(img, [[at.x-6,at.y],[at.x+4,at.y-19],[at.x+13,at.y-18],[at.x+6,at.y+1]], dark)
				PixelArt.line(img, at.x-3, at.y-2, at.x+6, at.y-18, wood)
				PixelArt.line(img, at.x, at.y-3, at.x+9, at.y-18, light.darkened(0.17))
				PixelArt.ellipse(img, at.x, at.y, 6, 4, wood)
				_prop_ring(img, at.x, at.y, 4, 2, dark.lightened(0.10))
				PixelArt.hline(img, at.x-2, at.y-2, 4, light)
				PixelArt.px(img, at.x, at.y, dark)
		"bucket":
			_prop_ring(img, 32, 32, 11, 16, dark)
			PixelArt.line(img, 23, 23, 26, 19, metal.lightened(0.16))
			_house_poly(img, [[18,36],[22,57],[28,59],[39,59],[44,56],[47,36]], dark)
			_house_poly(img, [[20,37],[24,55],[29,57],[38,57],[42,55],[45,37]], wood)
			for x in [25, 31, 37, 42]: PixelArt.vline(img, x, 40, 15, dark.lightened(0.08))
			PixelArt.vline(img, 23, 41, 11, light.darkened(0.12))
			PixelArt.hline(img, 23, 49, 20, metal)
			PixelArt.hline(img, 24, 54, 18, metal.darkened(0.12))
			PixelArt.ellipse(img, 32, 36, 15, 5, fibre)
			PixelArt.ellipse(img, 32, 36, 12, 3, dark)
			PixelArt.ellipse(img, 32, 37, 10, 2, WorldPalette.color("sea_shallow").lerp(metal, 0.60))
			PixelArt.hline(img, 25, 36, 7, WorldPalette.color("cream").darkened(0.18))
		"lantern":
			PixelArt.rect(img, 26, 13, 5, 45, dark)
			PixelArt.vline(img, 27, 14, 43, wood)
			_prop_bin(img, 23, 57, 12, 3, 2, wood, dark, light)
			PixelArt.line(img, 30, 22, 43, 12, dark)
			_prop_bin(img, 27, 11, 24, 4, 3, wood, dark, light)
			PixelArt.vline(img, 47, 14, 6, dark)
			PixelArt.rect(img, 40, 23, 15, 19, dark)
			PixelArt.rect(img, 42, 25, 11, 14, WorldPalette.color("lantern").lerp(wood, 0.18))
			PixelArt.rect(img, 49, 25, 4, 14, WorldPalette.color("lantern").lerp(wood, 0.38))
			PixelArt.vline(img, 47, 25, 14, dark)
			PixelArt.vline(img, 43, 26, 9, WorldPalette.color("cream"))
			_prop_bin(img, 38, 23, 19, 3, 4, metal, dark, metal.lightened(0.24))
			_prop_bin(img, 39, 40, 17, 3, 2, metal, dark, metal.lightened(0.15))
		_:
			_woven_pot(img, 32, 40, 19, 19, wood, dark, fibre)
			if kind == "planter":
				PixelArt.ellipse(img, 32, 39, 15, 3, dark.darkened(0.20))
				for at in [Vector2i(20, 29), Vector2i(32, 22), Vector2i(44, 30)]:
					PixelArt.line(img, 32, 40, at.x, at.y, WorldPalette.color("leaf_deep"))
					_leaf_cluster(img, at.x, at.y + 3, WorldPalette.color("leaf").lerp(WorldPalette.color("fern"),0.30), WorldPalette.color("leaf_deep"))
					PixelArt.ellipse(img, at.x, at.y-1, 4, 3, WorldPalette.color("flower").darkened(0.10))
					PixelArt.rect(img, at.x-1, at.y-2, 2, 2, WorldPalette.color("cream"))
			else:
				PixelArt.ellipse(img, 32, 39, 15, 3, dark)
				for at in [Vector2i(23, 36), Vector2i(32, 33), Vector2i(40, 36)]:
					PixelArt.ellipse(img, at.x, at.y, 5, 4, WorldPalette.color("grass_warm").lerp(wood,0.36))
					PixelArt.hline(img, at.x-2, at.y-2, 3, fibre)
	return img


static func _prop_ring(img: Image, cx: int, cy: int, rx: int, ry: int, ink: Color) -> void:
	var previous := Vector2i(cx+rx, cy)
	for step in range(1,65):
		var angle := TAU*step/64.0
		var point := Vector2i(cx+roundi(cos(angle)*rx), cy+roundi(sin(angle)*ry))
		PixelArt.line(img, previous.x, previous.y, point.x, point.y, ink)
		previous=point


static func _prop_bin(img: Image, x: int, y: int, width: int, height: int, depth: int, wood: Color, dark: Color, top: Color) -> void:
	PixelArt.rect(img, x, y, width, height, dark)
	PixelArt.rect(img, x+1, y+1, width-2, maxi(1,height-2), wood)
	_house_poly(img, [[x,y],[x+4,y-depth],[x+width-4,y-depth],[x+width,y]], top)
	PixelArt.hline(img, x+1, y, width-2, wood.lightened(0.16))
	PixelArt.hline(img, x, y+height-1, width, dark)


static func _woven_pot(img: Image, cx: int, rim_y: int, radius: int, height: int, wood: Color, dark: Color, fibre: Color) -> void:
	_house_poly(img, [[cx-radius,rim_y],[cx-radius+5,rim_y+height-2],[cx-8,rim_y+height],[cx+8,rim_y+height],[cx+radius-5,rim_y+height-2],[cx+radius,rim_y]], dark)
	_house_poly(img, [[cx-radius+2,rim_y+1],[cx-radius+7,rim_y+height-3],[cx+radius-7,rim_y+height-3],[cx+radius-2,rim_y+1]], wood)
	for y in range(rim_y+3, rim_y+height-2, 3):
		var inset := 3 + (y-rim_y)/5
		PixelArt.hline(img, cx-radius+inset, y, (radius-inset)*2, fibre.darkened(0.13))
		for x in range(cx-radius+inset+2, cx+radius-inset, 7): PixelArt.rect(img, x+(y%2), y, 2, 2, dark.lightened(0.12))
	PixelArt.ellipse(img, cx, rim_y, radius, 4, dark)
	_prop_ring(img, cx, rim_y-1, radius-1, 3, fibre)


static func workspace(kind: String) -> Image:
	var img := PixelArt.image(64, 48)
	var wood := WorldPalette.color("wood").lerp(Color("b59666"), 0.42)
	var dark := WorldPalette.color("wood_shadow").lerp(Color("304b45"), 0.30)
	var light := wood.lerp(WorldPalette.color("cream"), 0.40)
	var fibre := WorldPalette.color("cream").lerp(wood, 0.48)
	var metal := WorldPalette.color("stone").lerp(Color("48746d"), 0.50)
	PixelArt.ellipse(img, 32, 44, 24, 2, Color(WorldPalette.color("shadow"),0.17))
	match kind:
		"rope":
			# A low oval coil on the ground, not a vertical stack of dotted rings.
			PixelArt.ellipse(img, 30, 35, 20, 8, dark)
			PixelArt.ellipse(img, 30, 32, 20, 8, fibre.darkened(0.16))
			for ring in 4:
				var radius := 18-ring*4
				var depth := 6-ring
				_prop_ring(img, 30, 31, radius, depth, dark.lightened(0.12))
				_prop_ring(img, 30, 30, radius, depth, fibre)
			PixelArt.ellipse(img, 30, 30, 3, 1, dark)
			for x in [15, 22, 29, 36, 43]: PixelArt.line(img, x, 36, x+1, 39, wood)
			for i in 3: PixelArt.line(img, 46, 35+i, 55, 40+i, wood)
			PixelArt.line(img, 47, 35, 55, 40, fibre)
		"tools":
			_prop_bin(img, 10, 30, 44, 12, 5, wood, dark, light)
			PixelArt.rect(img, 13, 28, 38, 3, dark)
			for x in [18, 35, 46]:
				PixelArt.line(img, x, 35, x-5, 12, dark)
				PixelArt.line(img, x+1, 35, x-4, 12, light)
			_prop_bin(img, 5, 11, 17, 5, 3, metal.darkened(0.12), dark, metal.lightened(0.20))
			_house_poly(img, [[27,8],[34,8],[36,19],[31,24],[27,18]], metal)
			PixelArt.hline(img, 28, 9, 5, WorldPalette.color("cream").darkened(0.20))
			PixelArt.line(img, 40, 10, 46, 17, metal)
			PixelArt.vline(img, 13, 33, 6, light)
			PixelArt.vline(img, 49, 33, 6, dark)
		"feed":
			_prop_bin(img, 11, 29, 42, 13, 6, wood, dark, light)
			_house_poly(img, [[15,28],[20,23],[44,23],[49,28],[46,32],[18,32]], WorldPalette.color("grass_warm").lerp(wood,0.32))
			for x in range(18,47,5):
				PixelArt.line(img, x, 29, x+2, 24, fibre)
				PixelArt.px(img, x+1, 31, dark.lightened(0.10))
			for x in [14, 24, 39, 49]: PixelArt.vline(img, x, 33, 7, dark)
			PixelArt.hline(img, 14, 39, 35, light.darkened(0.15))
		"driftwood":
			for i in 3:
				var y := 36+i*3
				var weathered := wood.lerp(WorldPalette.color("stone"),0.35)
				_house_poly(img, [[8,y],[47,y-9],[55,y-6],[14,y+3]], dark)
				PixelArt.line(img, 12, y, 51, y-7, weathered)
				PixelArt.line(img, 14, y-1, 49, y-8, light.lerp(weathered,0.4))
				PixelArt.line(img, 14, y+1, 50, y-6, weathered.darkened(0.15))
			PixelArt.line(img, 31, 30, 37, 17, dark)
			PixelArt.line(img, 32, 29, 38, 17, wood)
		"bench":
			for x in [13, 48]:
				PixelArt.rect(img, x, 21, 4, 22, dark)
				PixelArt.vline(img, x+1, 23, 19, wood)
			_prop_bin(img, 8, 18, 49, 7, 3, wood, dark, light)
			PixelArt.hline(img, 11, 21, 43, dark.lightened(0.13))
			_prop_bin(img, 8, 32, 49, 5, 7, wood, dark, light)
			PixelArt.hline(img, 14, 29, 37, wood.darkened(0.12))
			PixelArt.hline(img, 12, 31, 41, wood.darkened(0.10))
			for x in [13, 48]:
				PixelArt.px(img, x+1, 20, dark)
				PixelArt.px(img, x+1, 34, dark)
	return img


# Companion frontage family: same elevated view and warm timber as the cottage.
static func stall(kind: String) -> Image:
	var img := PixelArt.image(112, 96)
	var timber := WorldPalette.color("wood").lerp(Color("ac8959"), 0.42)
	var dark := WorldPalette.color("wood_shadow").lerp(Color("344a43"), 0.32)
	var cream := WorldPalette.color("cream").darkened(0.08)
	var dye: Color = {"potion":Color("5a9188"),"equipment":Color("b76b58"),"pet":Color("93799c"),"house":Color("aa9668"),"services":Color("718e77")}.get(kind,Color("718e77"))
	# Posts, shelves and a visible counter-top; interaction/collision stay external.
	for x in [13, 95]:
		PixelArt.rect(img,x,29,4,57,dark)
		PixelArt.vline(img,x+1,31,53,timber.lightened(0.16))
	PixelArt.rect(img,19,35,74,22,dark.darkened(0.20))
	for x in range(21,92,9): PixelArt.vline(img,x,36,20,timber.darkened(0.32))
	PixelArt.hline(img,20,47,72,timber)
	PixelArt.hline(img,20,48,72,dark)
	_house_poly(img,[[15,56],[97,56],[103,62],[9,62]],timber.lightened(0.17))
	PixelArt.rect(img,9,62,94,5,dark)
	PixelArt.hline(img,10,62,92,timber.lightened(0.32))
	PixelArt.rect(img,12,67,88,16,timber.darkened(0.11))
	for row in range(68,82,4):
		PixelArt.hline(img,14,row,84,dark.lightened(0.07))
		for x in range(15+(row%8),96,10):
			PixelArt.hline(img,x,row+1,6,timber.lightened(0.11))
	for x in [13,39,69,96]:
		PixelArt.vline(img,x,67,16,dark)
		PixelArt.vline(img,x+1,67,15,timber.lightened(0.15))
	PixelArt.hline(img,12,82,88,dark)
	# A shallow pitched cloth canopy: centre ridge recedes in screen Y.
	_house_poly(img,[[7,19],[56,4],[105,19],[105,44],[56,29],[7,44]],dark)
	for side in 2:
		for x in range(10,103):
			var u := float(x-10)/44.0 if side==0 else float(102-x)/44.0
			if u<0.0 or u>=1.0:continue
			var back := 20.0-u*13.0
			for y in range(7,43):
				var v := float(y)-back
				if v<0.0 or v>=20.0:continue
				var stripe := int((1.0-u)*44.0)/10
				var ink: Color=dye if stripe%2==0 else cream
				if side==1:ink=ink.darkened(0.16)
				if int(v)%5==4:ink=ink.darkened(0.06)
				elif int(v)%5==0:ink=ink.lightened(0.04)
				PixelArt.px(img,x,y,ink)
	_house_poly(img,[[8,42],[54,27],[56,30],[10,46]],dye.darkened(0.32))
	_house_poly(img,[[56,30],[58,27],[104,42],[102,46]],dye.darkened(0.42))
	_house_poly(img,[[10,42],[54,28],[54,30],[11,44]],cream.darkened(0.22))
	_house_poly(img,[[58,28],[102,42],[101,44],[58,30]],cream.darkened(0.35))
	PixelArt.rect(img,54,6,4,23,dark)
	PixelArt.vline(img,55,7,20,timber.lightened(0.38))
	# Goods have a purpose and share the cottage's restrained material ramps.
	match kind:
		"potion":
			for x in [22,88]:
				PixelArt.vline(img,x,41,8,dark)
				PixelArt.ellipse(img,x,48,4,3,WorldPalette.color("leaf_deep"))
				PixelArt.ellipse(img,x-1,46,3,2,WorldPalette.color("leaf_sun").darkened(0.13))
			for i in 4:
				var x := 28+i*16
				var y := 50+(i%2)*2
				var glass: Color=[Color("aa655d"),Color("619d91"),Color("c8a468"),Color("8e829d")][i]
				PixelArt.rect(img,x,y,3,3,cream.darkened(0.25))
				PixelArt.ellipse(img,x+1,y+6,4,4,glass.darkened(0.25))
				PixelArt.ellipse(img,x,y+5,3,3,glass)
				PixelArt.rect(img,x-1,y+4,1,2,glass.lightened(0.38))
		"equipment":
			PixelArt.line(img,23,57,36,43,Color("596c6d"))
			PixelArt.line(img,25,57,38,43,Color("c1ccba"))
			PixelArt.line(img,27,51,33,56,Color("c69b62"))
			PixelArt.ellipse(img,58,53,8,7,dark)
			PixelArt.ellipse(img,57,52,6,5,Color("8d9a8e"))
			PixelArt.ellipse(img,57,52,2,2,cream.darkened(0.20))
			PixelArt.rect(img,77,47,12,11,dark)
			PixelArt.rect(img,79,49,8,6,Color("a17550"))
			PixelArt.hline(img,79,49,8,WorldPalette.color("roof").darkened(0.13))
		"pet":
			PixelArt.rect(img,23,49,15,11,dark)
			PixelArt.rect(img,25,50,11,8,Color("ba9b68"))
			for y in [52,55,58]:PixelArt.hline(img,25,y,11,Color("887149"))
			PixelArt.ellipse(img,57,56,9,4,Color("546968"))
			PixelArt.ellipse(img,57,54,7,2,Color("c2ae77"))
			PixelArt.rect(img,77,47,8,12,dye.darkened(0.17))
			PixelArt.rect(img,79,45,4,3,cream.darkened(0.17))
			PixelArt.rect(img,79,52,4,3,cream.darkened(0.13))
		"house":
			PixelArt.rect(img,24,47,25,12,cream.darkened(0.12))
			PixelArt.hline(img,27,50,19,Color("5e8e92"))
			PixelArt.vline(img,31,51,6,Color("5e8e92"))
			PixelArt.hline(img,31,56,12,Color("5e8e92"))
			for y in [51,55]:
				PixelArt.rect(img,58,y,27,4,timber.lightened(0.13))
				PixelArt.hline(img,58,y+3,27,dark)
			PixelArt.rect(img,89,44,3,15,Color("b7a470"))
			for y in range(46,58,3):PixelArt.hline(img,89,y,2,dark)
		_:
			PixelArt.ellipse(img,29,55,7,5,Color("537d7a"))
			PixelArt.hline(img,23,51,12,Color("88aaa0"))
			for x in [51,64]:
				PixelArt.line(img,x,57,x-3,43,timber.lightened(0.21))
				PixelArt.rect(img,x-6,42,6,4,Color("7c9388"))
			PixelArt.rect(img,77,47,13,11,dark)
			PixelArt.rect(img,79,49,9,7,cream.darkened(0.21))
	return img

static func shop_ground(kind: String) -> Image:
	var img := PixelArt.image(192,160)
	var soil := WorldPalette.color("path_edge").lerp(WorldPalette.color("wood_shadow"),0.18)
	soil.a=0.16
	for p in [[96,53,58,14],[84,65,37,18],[107,74,32,20]]:
		PixelArt.ellipse(img,p[0],p[1],p[2],p[3],soil)
	var contact := WorldPalette.color("shadow")
	contact.a=0.16
	PixelArt.ellipse(img,96,39,45,6,contact)
	var stone := WorldPalette.color("stone").lerp(WorldPalette.color("path"),0.42)
	stone.a=0.54
	for at: Vector2i in [Vector2i(96,67),Vector2i(94,86)]:
		_house_poly(img,[[at.x-10,at.y],[at.x-6,at.y-3],[at.x+8,at.y-2],[at.x+11,at.y+2],[at.x+6,at.y+4],[at.x-8,at.y+3]],stone)
	# Margin details never add collision or block customer/service workpoints.
	if kind in ["potion","services"]:
		for at: Vector2i in [Vector2i(45,63),Vector2i(145,69)]:
			_house_poly(img,[[at.x-5,at.y],[at.x-2,at.y-6],[at.x,at.y-2],[at.x+3,at.y-8],[at.x+6,at.y]],Color(WorldPalette.color("leaf"),0.65))
	elif kind=="house":
		PixelArt.rect(img,140,66,12,3,Color(WorldPalette.color("wood"),0.40))
		PixelArt.hline(img,140,68,12,Color(WorldPalette.color("wood_shadow"),0.35))
	return img

static func stall_front(kind: String) -> Image:
	var img := stall(kind)
	# The original one-piece stall covered the merchant with its rear wall.
	# Keep canopy, posts and counter in front, but let the same unchanged NPC
	# sprite occupy the service opening. No actor art or physics changes.
	for y in range(62):
		for x in img.get_width():
			var post := (x>=13 and x<17) or (x>=95 and x<99)
			var canopy_front := 31.0+absf(float(x-56))*0.30
			if not post and float(y)>canopy_front:img.set_pixel(x,y,Color.TRANSPARENT)
	return img
