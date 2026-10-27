class_name IconArt
extends RefCounted
## Native 32x32 icon set for touch controls, shop cards and HUD chrome.
##
## Style rules (see docs/VISUAL_OVERHAUL.md): 1px dark outline applied by an
## automatic alpha pass, three-tone shading (dark / mid / light) and light from
## the top-left. `PixelArt.icon(kind, size)` routes size >= 24 here; size 16
## keeps the original compact art so existing callers never change.


const OUTLINE := Color("#241a1c")
const SHADOW := Color(0, 0, 0, 0.22)


static func icon(kind: String, size: int = 32) -> Texture2D:
	var key := "icon32_%s_%d" % [kind, size]
	if PixelArt.CACHE.has(key):
		return PixelArt.CACHE[key]
	var img := PixelArt.image(size, size)
	draw_icon(img, kind, size)
	var tex := ImageTexture.create_from_image(img)
	PixelArt.CACHE[key] = tex
	return tex


static func draw_icon(img: Image, kind: String, size: int) -> void:
	var s := size / 32.0
	match kind:
		"sword":
			_sword(img, s)
		"scythe":
			_line(img, 10 * s, 28 * s, 22 * s, 6 * s, Color("#a87c4d"), 3 * s)
			_line(img, 22 * s, 6 * s, 10 * s, 3 * s, Color("#d9e3dc"), 3 * s)
			_line(img, 10 * s, 3 * s, 4 * s, 13 * s, Color("#d9e3dc"), 3 * s)
		"hammer":
			_hammer(img, s)
		"bow":
			_bow(img, s)
		"armor":
			_armor(img, s)
		"shield":
			_shield(img, s)
		"potion_red", "health_potion":
			_potion(img, s, Color("#8f2835"), Color("#ef5763"), Color("#ffb0a8"))
		"potion_blue", "mana_potion":
			_potion(img, s, Color("#243f79"), Color("#5889d7"), Color("#b5d0ff"))
		"food":
			_food(img, s)
		"wood":
			_wood(img, s)
		"gold":
			_gold(img, s)
		"diamond":
			_diamond(img, s)
		"heart":
			_heart(img, s)
		"mana":
			_mana(img, s)
		"backpack":
			_backpack(img, s)
		"build":
			_build(img, s)
		"sprint":
			PixelArt.ellipse(img, int(21*s), int(6*s), int(3*s), int(3*s), Color("#8fe8f7"))
			for seg in [[19,11,14,19],[16,14,9,12],[16,15,23,18],[14,19,21,24],[14,19,9,27]]:
				_line(img, seg[0]*s, seg[1]*s, seg[2]*s, seg[3]*s, Color("#8fe8f7"), 3*s)
			_line(img, 3*s, 18*s, 9*s, 18*s, Color("#f2c45a"), 2*s)
		"talk":
			_talk(img, s)
		"door":
			_door(img, s)
		"bed":
			_bed(img, s)
		"gather":
			_gather(img, s)
		"chest":
			_chest(img, s)
		"menu":
			_menu(img, s)
		"close":
			_close(img, s)
		"plus":
			_plus(img, s)
		"arrow":
			_arrow(img, s)
		"lock":
			_lock(img, s)
		"check":
			_check(img, s)
		"spark":
			_spark(img, s)
		"portal":
			_portal(img, s)
		"pet":
			_pet_paw(img, s)
		_:
			_generic(img, s)
	_outline(img)
	_drop_shadow(img, size)


# ------------------------------------------------------------------ helpers

static func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)


static func _rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy in range(maxi(0, y), mini(img.get_height(), y + h)):
		for xx in range(maxi(0, x), mini(img.get_width(), x + w)):
			img.set_pixel(xx, yy, c)


static func _ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for yy in range(img.get_height()):
		for xx in range(img.get_width()):
			var dx := (float(xx) + 0.5 - cx) / maxf(0.001, rx)
			var dy := (float(yy) + 0.5 - cy) / maxf(0.001, ry)
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(xx, yy, c)


static func _line(img: Image, x0: float, y0: float, x1: float, y1: float, c: Color, w: float = 1.0) -> void:
	var steps := maxi(1, int(maxf(absf(x1 - x0), absf(y1 - y0)) * 2.0))
	for i in steps + 1:
		var t := float(i) / float(steps)
		var px := roundf(lerpf(x0, x1, t))
		var py := roundf(lerpf(y0, y1, t))
		if w <= 1.0:
			_px(img, int(px), int(py), c)
		else:
			var r := (w - 1.0) * 0.5
			_rect(img, int(px - r), int(py - r), int(w), int(w), c)


static func _poly(img: Image, points: Array, c: Color) -> void:
	if points.is_empty():
		return
	var min_y := 99999
	var max_y := -1
	for p in points:
		min_y = mini(min_y, int(p.y))
		max_y = maxi(max_y, int(p.y))
	for y in range(min_y, max_y + 1):
		var nodes: Array[float] = []
		for i in points.size():
			var a: Vector2 = points[i]
			var b: Vector2 = points[(i + 1) % points.size()]
			if (a.y < y and b.y >= y) or (b.y < y and a.y >= y):
				var t := float(y - a.y) / float(b.y - a.y)
				nodes.append(a.x + t * (b.x - a.x))
		nodes.sort()
		for n in range(0, nodes.size() - 1, 2):
			for x in range(int(nodes[n]), int(nodes[n + 1]) + 1):
				_px(img, x, y, c)


static func _outline(img: Image) -> void:
	# Automatic 1px outline: any transparent pixel 4-adjacent to an opaque one
	# becomes the outline colour. Gives every icon the same crisp border.
	var w := img.get_width()
	var h := img.get_height()
	var marks: Array[Vector2i] = []
	for y in h:
		for x in w:
			if img.get_pixel(x, y).a > 0.05:
				continue
			var touch := false
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx: int = x + d.x
				var ny: int = y + d.y
				if nx < 0 or ny < 0 or nx >= w or ny >= h:
					continue
				if img.get_pixel(nx, ny).a > 0.05:
					touch = true
					break
			if touch:
				marks.append(Vector2i(x, y))
	for m in marks:
		img.set_pixel(m.x, m.y, OUTLINE)


static func _drop_shadow(img: Image, size: int) -> void:
	# A faint hard shadow two pixels below the silhouette. Kept subtle so icons
	# stay crisp on light panels.
	if size < 24:
		return
	var marks: Array[Vector2i] = []
	for y in size - 2:
		for x in size:
			if img.get_pixel(x, y).a > 0.05 and img.get_pixel(x, y + 2).a <= 0.05:
				marks.append(Vector2i(x, y + 2))
	for m in marks:
		img.set_pixel(m.x, m.y, Color(0, 0, 0, 0.28))


# ------------------------------------------------------------------ icons

static func _sword(img: Image, s: float) -> void:
	var steel := Color("#cfd4cc")
	var steel_dark := Color("#79838b")
	var gold := Color("#c9964c")
	var grip := Color("#5d3f27")
	# Blade from bottom-left guard to top-right tip.
	_line(img, 11 * s, 21 * s, 25 * s, 7 * s, steel, 3.0 * s)
	_line(img, 12 * s, 22 * s, 26 * s, 8 * s, steel_dark, 1.0 * s)
	_line(img, 10 * s, 20 * s, 24 * s, 6 * s, Color("#eef2e9"), 1.0 * s)
	_px(img, int(27 * s), int(6 * s), steel)
	# Crossguard.
	_line(img, 7 * s, 24 * s, 13 * s, 18 * s, gold, 3.0 * s)
	_line(img, 8 * s, 26 * s, 14 * s, 20 * s, Color("#8a6430"), 1.0 * s)
	# Grip and pommel.
	_line(img, 9 * s, 25 * s, 5 * s, 29 * s, grip, 2.4 * s)
	_ellipse(img, 5 * s, 29 * s, 2.0 * s, 2.0 * s, gold)
	_px(img, int(4 * s), int(28 * s), Color("#ffe0a0"))


static func _hammer(img: Image, s: float) -> void:
	var grip := Color("#8a6239")
	var grip_dark := Color("#5c3f26")
	var head := Color("#9ea8a3")
	var head_light := Color("#ccd3cc")
	var head_dark := Color("#4d5656")
	# Diagonal shaft.
	_line(img, 8 * s, 27 * s, 19 * s, 16 * s, grip, 3.0 * s)
	_line(img, 9 * s, 28 * s, 20 * s, 17 * s, grip_dark, 1.0 * s)
	# Chunky head, slightly rotated feel via stacked rects.
	_rect(img, int(16 * s), int(6 * s), int(11 * s), int(10 * s), head_dark)
	_rect(img, int(17 * s), int(7 * s), int(9 * s), int(8 * s), head)
	_rect(img, int(18 * s), int(7 * s), int(7 * s), int(2 * s), head_light)
	_rect(img, int(17 * s), int(12 * s), int(9 * s), int(2 * s), Color("#6f7a76"))
	_rect(img, int(24 * s), int(8 * s), int(2 * s), int(6 * s), head_light)


static func _bow(img: Image, s: float) -> void:
	var wood := Color("#9a6d3d")
	var wood_light := Color("#c49357")
	var wood_dark := Color("#5f4226")
	var string := Color("#ded2ad")
	var arrow_wood := Color("#c9ad74")
	var tip := Color("#cfd8d4")
	# Bow limb (an arc of thick pixels).
	for i in 15:
		var t := float(i) / 14.0
		var a := -1.25 + t * 2.5
		var cx := 20.0 + cos(a) * 8.5
		var cy := 15.5 - sin(a) * 11.5
		_px(img, int(cx * s), int(cy * s), wood)
		_px(img, int((cx - 1.0) * s), int(cy * s), wood_dark)
		if i % 3 == 1:
			_px(img, int((cx + 1.0) * s), int(cy * s), wood_light)
	# String.
	_line(img, 17 * s, 4 * s, 17 * s, 27 * s, string, 1.0 * s)
	# Nocked arrow pointing left.
	_line(img, 22 * s, 16 * s, 6 * s, 16 * s, arrow_wood, 1.6 * s)
	_poly(img, [Vector2(6 * s, 16 * s), Vector2(11 * s, 14 * s), Vector2(11 * s, 18 * s)], tip)
	_line(img, 8 * s, 14 * s, 6 * s, 12 * s, Color("#e7dcc4"), 1.0 * s)
	_line(img, 8 * s, 18 * s, 6 * s, 20 * s, Color("#e7dcc4"), 1.0 * s)


static func _armor(img: Image, s: float) -> void:
	var plate := Color("#a5b3b0")
	var plate_dark := Color("#38484c")
	var plate_mid := Color("#6c7b7e")
	var trim := Color("#e8d18a")
	_poly(img, [Vector2(8 * s, 5 * s), Vector2(24 * s, 5 * s), Vector2(27 * s, 10 * s), Vector2(23 * s, 27 * s), Vector2(9 * s, 27 * s), Vector2(5 * s, 10 * s)], plate_mid)
	_poly(img, [Vector2(10 * s, 7 * s), Vector2(22 * s, 7 * s), Vector2(24 * s, 11 * s), Vector2(21 * s, 24 * s), Vector2(11 * s, 24 * s), Vector2(8 * s, 11 * s)], plate)
	_line(img, 10 * s, 7 * s, 8 * s, 11 * s, Color("#d3dcd6"), 1.4 * s)
	_rect(img, int(14 * s), int(9 * s), int(4 * s), int(14 * s), plate_dark)
	_rect(img, int(8 * s), int(13 * s), int(16 * s), int(2 * s), plate_dark)
	_px(img, int(16 * s), int(12 * s), trim)
	_px(img, int(15 * s), int(15 * s), trim)
	_px(img, int(17 * s), int(18 * s), trim)


static func _shield(img: Image, s: float) -> void:
	var wood := Color("#5f4933")
	var face := Color("#a88a5c")
	var face_light := Color("#c7a877")
	var boss := Color("#e4c979")
	_poly(img, [Vector2(6 * s, 4 * s), Vector2(26 * s, 4 * s), Vector2(29 * s, 10 * s), Vector2(16 * s, 29 * s), Vector2(3 * s, 10 * s)], wood)
	_poly(img, [Vector2(8 * s, 6 * s), Vector2(24 * s, 6 * s), Vector2(26 * s, 10 * s), Vector2(16 * s, 26 * s), Vector2(6 * s, 10 * s)], face)
	_line(img, 8 * s, 6 * s, 6 * s, 10 * s, face_light, 1.4 * s)
	_line(img, int(16 * s), 6 * s, 16 * s, 26 * s, boss, 1.0 * s)
	_line(img, int(6 * s), 13 * s, 26 * s, 13 * s, boss, 1.0 * s)
	_ellipse(img, 16 * s, 13 * s, 3.0 * s, 3.0 * s, Color("#8a6430"))
	_ellipse(img, 16 * s, 13 * s, 2.0 * s, 2.0 * s, boss)
	_px(img, int(15 * s), int(12 * s), Color("#fff2bb"))


static func _potion(img: Image, s: float, dark: Color, mid: Color, light: Color) -> void:
	var glass := Color("#cfd6cf")
	var glass_dark := Color("#8f9a93")
	var cork := Color("#6d5a4e")
	var shine := Color(1, 1, 1, 0.5)
	# Neck and cork.
	_rect(img, int(12 * s), int(3 * s), int(8 * s), int(4 * s), cork)
	_rect(img, int(13 * s), int(6 * s), int(6 * s), int(2 * s), Color("#4b3d33"))
	# Flask body.
	_ellipse(img, 16 * s, 19 * s, 8.5 * s, 9.5 * s, glass_dark)
	_ellipse(img, 16 * s, 19 * s, 7.5 * s, 8.5 * s, Color(0.85, 0.92, 0.9, 0.55))
	# Liquid fills the bottom two thirds.
	for y in range(int(13 * s), int(28 * s)):
		for x in range(int(8 * s), int(25 * s)):
			var dx := (float(x) + 0.5 - 16.0 * s) / (8.0 * s)
			var dy := (float(y) + 0.5 - 19.0 * s) / (9.0 * s)
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(x, y, mid)
	for y in range(int(13 * s), int(28 * s)):
		for x in range(int(8 * s), int(25 * s)):
			var dx := (float(x) + 0.5 - 16.0 * s) / (8.0 * s)
			var dy := (float(y) + 0.5 - 19.0 * s) / (9.0 * s)
			if dx * dx + dy * dy <= 1.0 and float(y) > 23.0 * s:
				img.set_pixel(x, y, dark)
	# Surface line and shine.
	_line(img, 10 * s, 15 * s, 22 * s, 15 * s, light, 1.0 * s)
	_line(img, 11 * s, 18 * s, 11 * s, 23 * s, shine, 1.0 * s)
	_px(img, int(12 * s), int(17 * s), shine)


static func _food(img: Image, s: float) -> void:
	var bowl := Color("#c58b45")
	var bowl_dark := Color("#8d5b30")
	var bowl_light := Color("#efc36e")
	var kibble := [Color("#b0623a"), Color("#d3854d"), Color("#8d4f30")]
	# Bowl.
	_ellipse(img, 16 * s, 20 * s, 11.0 * s, 6.0 * s, bowl_dark)
	_ellipse(img, 16 * s, 19 * s, 10.0 * s, 5.0 * s, bowl)
	_rect(img, int(6 * s), int(18 * s), int(20 * s), int(2 * s), bowl_light)
	# Kibble heap.
	for i in 9:
		var ang := TAU * float(i) / 9.0
		var cx := 16.0 * s + cos(ang) * 5.0 * s
		var cy := 16.0 * s - absf(sin(ang)) * 2.5 * s
		_ellipse(img, cx, cy, 2.2 * s, 2.2 * s, kibble[i % kibble.size()])
	_ellipse(img, 16 * s, 15 * s, 3.0 * s, 2.0 * s, Color("#e8a56b"))
	# Little fish bone garnish.
	_line(img, 13 * s, 14 * s, 19 * s, 14 * s, Color("#e7dcc4"), 1.0 * s)


static func _wood(img: Image, s: float) -> void:
	var bark := Color("#6e4a2c")
	var bark_dark := Color("#4a3020")
	var bark_light := Color("#b07a45")
	var ring := Color("#d3aa72")
	# Two stacked logs.
	_ellipse(img, 12 * s, 21 * s, 7.0 * s, 5.5 * s, bark_dark)
	_ellipse(img, 12 * s, 21 * s, 5.8 * s, 4.4 * s, bark)
	_ellipse(img, 12 * s, 21 * s, 3.0 * s, 2.4 * s, ring)
	_ellipse(img, 20 * s, 20 * s, 8.0 * s, 6.0 * s, bark_dark)
	_ellipse(img, 20 * s, 20 * s, 6.8 * s, 5.0 * s, bark)
	_ellipse(img, 20 * s, 20 * s, 3.6 * s, 2.8 * s, ring)
	_ellipse(img, 20 * s, 12 * s, 7.0 * s, 5.5 * s, bark_dark)
	_ellipse(img, 20 * s, 12 * s, 5.8 * s, 4.4 * s, bark_light)
	_ellipse(img, 20 * s, 12 * s, 3.0 * s, 2.4 * s, ring)
	_px(img, int(19 * s), int(11 * s), bark_dark)
	# Grain ticks.
	_line(img, 5 * s, 17 * s, 9 * s, 16 * s, bark_dark, 1.0 * s)
	_line(img, 24 * s, 16 * s, 27 * s, 15 * s, bark_dark, 1.0 * s)


static func _gold(img: Image, s: float) -> void:
	var rim := Color("#8b5a1f")
	var face := Color("#f4c755")
	var light := Color("#ffe28a")
	var glint := Color("#fff3c2")
	_ellipse(img, 16 * s, 16 * s, 11.0 * s, 11.0 * s, rim)
	_ellipse(img, 16 * s, 16 * s, 9.5 * s, 9.5 * s, face)
	_ellipse(img, 13.5 * s, 13.5 * s, 5.0 * s, 5.0 * s, light)
	# Stamped wave mark.
	_line(img, 12 * s, 17 * s, 16 * s, 14 * s, rim, 1.4 * s)
	_line(img, 16 * s, 14 * s, 20 * s, 17 * s, rim, 1.4 * s)
	_px(img, int(10 * s), int(10 * s), glint)
	_px(img, int(11 * s), int(9 * s), glint)


static func _diamond(img: Image, s: float) -> void:
	var face := Color("#87ecff")
	var face_dark := Color("#42a7c7")
	var face_light := Color("#d9fbff")
	var cut := Color("#bdf2ff")
	_poly(img, [Vector2(11 * s, 5 * s), Vector2(21 * s, 5 * s), Vector2(28 * s, 13 * s), Vector2(16 * s, 29 * s), Vector2(4 * s, 13 * s)], face_dark)
	_poly(img, [Vector2(12 * s, 6 * s), Vector2(20 * s, 6 * s), Vector2(26 * s, 13 * s), Vector2(16 * s, 27 * s), Vector2(6 * s, 13 * s)], face)
	# Table facet.
	_poly(img, [Vector2(12 * s, 6 * s), Vector2(20 * s, 6 * s), Vector2(22 * s, 9 * s), Vector2(16 * s, 11 * s), Vector2(10 * s, 9 * s)], face_light)
	# Facet lines.
	_line(img, int(6 * s), 13 * s, 26 * s, 13 * s, cut, 1.0 * s)
	_line(img, 10 * s, 9 * s, 16 * s, 27 * s, cut, 1.0 * s)
	_line(img, 22 * s, 9 * s, 16 * s, 27 * s, cut, 1.0 * s)
	_px(img, int(14 * s), int(14 * s), Color.WHITE)


static func _heart(img: Image, s: float) -> void:
	var base := Color("#e65555")
	var dark := Color("#a83a44")
	var light := Color("#ffb0a8")
	_poly(img, [Vector2(16 * s, 28 * s), Vector2(4 * s, 16 * s), Vector2(4 * s, 9 * s), Vector2(9 * s, 5 * s), Vector2(16 * s, 9 * s), Vector2(23 * s, 5 * s), Vector2(28 * s, 9 * s), Vector2(28 * s, 16 * s)], base)
	_ellipse(img, 10 * s, 10 * s, 5.0 * s, 4.6 * s, base)
	_ellipse(img, 22 * s, 10 * s, 5.0 * s, 4.6 * s, base)
	_line(img, 16 * s, 28 * s, 16 * s, 20 * s, dark, 1.0 * s)
	_ellipse(img, 10 * s, 10 * s, 2.2 * s, 2.0 * s, light)
	_px(img, int(8 * s), int(8 * s), light)


static func _mana(img: Image, s: float) -> void:
	var base := Color("#6ea7ee")
	var dark := Color("#3d6bb0")
	var light := Color("#bfe2ff")
	_poly(img, [Vector2(16 * s, 3 * s), Vector2(24 * s, 15 * s), Vector2(21 * s, 25 * s), Vector2(11 * s, 25 * s), Vector2(8 * s, 15 * s)], base)
	_poly(img, [Vector2(16 * s, 6 * s), Vector2(22 * s, 15 * s), Vector2(19.5 * s, 23 * s), Vector2(12.5 * s, 23 * s), Vector2(10 * s, 15 * s)], base)
	_line(img, 16 * s, 6 * s, 16 * s, 24 * s, dark, 1.0 * s)
	_line(img, 12 * s, 12 * s, 13 * s, 20 * s, light, 1.2 * s)
	_px(img, int(15 * s), int(9 * s), light)
	# Tiny surface sheen.
	_line(img, 13 * s, 18 * s, 19 * s, 18 * s, Color(1, 1, 1, 0.35), 1.0 * s)


static func _backpack(img: Image, s: float) -> void:
	var pack := Color("#a5683d")
	var pack_dark := Color("#7b4b2c")
	var pack_light := Color("#c28e58")
	var strap := Color("#3c281d")
	var buckle := Color("#e4bb62")
	_rect(img, int(6 * s), int(9 * s), int(20 * s), int(19 * s), pack_dark)
	_rect(img, int(7 * s), int(10 * s), int(18 * s), int(17 * s), pack)
	_rect(img, int(9 * s), int(12 * s), int(14 * s), int(3 * s), pack_light)
	# Lid.
	_rect(img, int(8 * s), int(6 * s), int(16 * s), int(6 * s), pack_dark)
	_rect(img, int(9 * s), int(7 * s), int(14 * s), int(4 * s), pack)
	# Straps and buckles.
	_rect(img, int(11 * s), int(13 * s), int(3 * s), int(14 * s), strap)
	_rect(img, int(18 * s), int(13 * s), int(3 * s), int(14 * s), strap)
	_rect(img, int(10 * s), int(17 * s), int(5 * s), int(4 * s), buckle)
	_rect(img, int(17 * s), int(17 * s), int(5 * s), int(4 * s), buckle)
	# Side pocket.
	_rect(img, int(24 * s), int(14 * s), int(3 * s), int(8 * s), pack_light)
	_px(img, int(12 * s), int(8 * s), Color("#f1e2c2"))


static func _build(img: Image, s: float) -> void:
	# Hammer over a small plank: the settlement-editor mark.
	_hammer(img, s)
	var plank := Color("#8a6138")
	var plank_light := Color("#b08452")
	_rect(img, int(3 * s), int(23 * s), int(12 * s), int(5 * s), Color("#5c3f26"))
	_rect(img, int(4 * s), int(24 * s), int(10 * s), int(3 * s), plank)
	_line(img, 5 * s, 25 * s, 13 * s, 25 * s, plank_light, 1.0 * s)


static func _talk(img: Image, s: float) -> void:
	var bubble := Color("#dfe9e2")
	var bubble_dark := Color("#9fb3a8")
	var dots := Color("#3a4a44")
	_ellipse(img, 16 * s, 13 * s, 12.0 * s, 9.0 * s, bubble_dark)
	_ellipse(img, 16 * s, 13 * s, 11.0 * s, 8.0 * s, bubble)
	_poly(img, [Vector2(11 * s, 20 * s), Vector2(15 * s, 20 * s), Vector2(9 * s, 27 * s)], bubble)
	_poly(img, [Vector2(11 * s, 20.5 * s), Vector2(14.5 * s, 20.5 * s), Vector2(10.5 * s, 25 * s)], bubble_dark)
	for i in 3:
		_ellipse(img, (11.0 + float(i) * 5.0) * s, 13 * s, 1.6 * s, 1.6 * s, dots)
	_ellipse(img, 9 * s, 9 * s, 2.4 * s, 1.8 * s, Color.WHITE)


static func _door(img: Image, s: float) -> void:
	var frame := Color("#5c4126")
	var door := Color("#7d5631")
	var door_light := Color("#a8794a")
	var knob := Color("#e4bb62")
	# Frame.
	_rect(img, int(7 * s), int(5 * s), int(18 * s), int(24 * s), frame)
	# Door with arch top.
	_ellipse(img, 16 * s, 9 * s, 8.0 * s, 4.0 * s, door)
	_rect(img, int(8 * s), int(9 * s), int(16 * s), int(19 * s), door)
	_rect(img, int(10 * s), int(9 * s), int(12 * s), int(18 * s), door_light)
	# Panels.
	_rect(img, int(12 * s), int(12 * s), int(8 * s), int(6 * s), door)
	_rect(img, int(12 * s), int(20 * s), int(8 * s), int(6 * s), door)
	_px(img, int(19 * s), int(19 * s), knob)
	_px(img, int(19 * s), int(18 * s), Color("#fff2bb"))
	# Threshold.
	_rect(img, int(6 * s), int(28 * s), int(20 * s), int(2 * s), Color("#4a3420"))


static func _bed(img: Image, s: float) -> void:
	var frame := Color("#4a3021")
	var mattress := Color("#dad0bb")
	var blanket := Color("#7c4d57")
	var blanket_light := Color("#9e6670")
	var pillow := Color("#f1e7d1")
	# Frame posts.
	_rect(img, int(4 * s), int(10 * s), int(4 * s), int(17 * s), frame)
	_rect(img, int(24 * s), int(13 * s), int(4 * s), int(14 * s), frame)
	# Base and mattress.
	_rect(img, int(4 * s), int(17 * s), int(24 * s), int(9 * s), frame)
	_rect(img, int(6 * s), int(14 * s), int(20 * s), int(5 * s), mattress)
	# Pillow.
	_ellipse(img, 10 * s, 15 * s, 4.4 * s, 2.6 * s, pillow)
	# Blanket over the lower part.
	_rect(img, int(15 * s), int(17 * s), int(11 * s), int(6 * s), blanket)
	_line(img, 15 * s, 17 * s, 26 * s, 17 * s, blanket_light, 1.0 * s)
	_line(img, 15 * s, 20 * s, 26 * s, 20 * s, blanket_light, 1.0 * s)
	# Zzz hint.
	_px(img, int(24 * s), int(10 * s), Color("#bfe2ff"))
	_px(img, int(26 * s), int(8 * s), Color("#bfe2ff"))
	_px(img, int(28 * s), int(6 * s), Color("#bfe2ff"))


static func _gather(img: Image, s: float) -> void:
	# An open hand reaching down: the gather / pick-up mark.
	var skin := Color("#d9ad83")
	var skin_dark := Color("#a87c56")
	var skin_light := Color("#f0cba3")
	# Palm.
	_ellipse(img, 16 * s, 21 * s, 8.0 * s, 7.0 * s, skin)
	_ellipse(img, 15 * s, 20 * s, 6.0 * s, 5.0 * s, skin_light)
	# Fingers.
	for i in 4:
		var fx := (9.0 + float(i) * 4.2) * s
		_rect(img, int(fx), int(8 * s), int(3 * s), int(9 * s), skin)
		_rect(img, int(fx), int(8 * s), int(3 * s), int(2 * s), skin_light)
		_rect(img, int(fx), int(16 * s), int(3 * s), int(1 * s), skin_dark)
	# Thumb.
	_ellipse(img, 24 * s, 20 * s, 2.6 * s, 4.0 * s, skin)
	_px(img, int(24 * s), int(17 * s), skin_light)
	# Cuff.
	_rect(img, int(9 * s), int(26 * s), int(15 * s), int(3 * s), Color("#3f7f72"))
	_rect(img, int(9 * s), int(26 * s), int(15 * s), int(1 * s), Color("#5ba795"))


static func _chest(img: Image, s: float) -> void:
	var wood := Color("#8a5f36")
	var wood_dark := Color("#5c3f26")
	var wood_light := Color("#b08452")
	var band := Color("#c9a45c")
	var lock := Color("#f2d377")
	# Body.
	_rect(img, int(5 * s), int(13 * s), int(22 * s), int(13 * s), wood_dark)
	_rect(img, int(6 * s), int(14 * s), int(20 * s), int(11 * s), wood)
	# Rounded lid.
	_ellipse(img, 16 * s, 13 * s, 11.0 * s, 6.0 * s, wood_dark)
	_ellipse(img, 16 * s, 13 * s, 10.0 * s, 5.0 * s, wood_light)
	_line(img, 6 * s, 13 * s, 26 * s, 13 * s, wood, 2.0 * s)
	# Iron bands.
	_rect(img, int(8 * s), int(8 * s), int(3 * s), int(18 * s), band)
	_rect(img, int(21 * s), int(8 * s), int(3 * s), int(18 * s), band)
	# Lock plate.
	_rect(img, int(14 * s), int(13 * s), int(4 * s), int(5 * s), lock)
	_px(img, int(15 * s), int(15 * s), Color("#7a5a1f"))


static func _menu(img: Image, s: float) -> void:
	var bar := Color("#e8e2cd")
	for i in 3:
		_rect(img, int(7 * s), int((9 + i * 6) * s), int(18 * s), int(3 * s), bar)
		_rect(img, int(7 * s), int((9 + i * 6) * s), int(4 * s), int(3 * s), Color("#f7f2dd"))
	_px(img, int(8 * s), int(10 * s), Color("#7fd8c8"))


static func _close(img: Image, s: float) -> void:
	var cross := Color("#e66a6a")
	var cross_light := Color("#ffb9b0")
	_line(img, 9 * s, 9 * s, 23 * s, 23 * s, cross, 4.0 * s)
	_line(img, 23 * s, 9 * s, 9 * s, 23 * s, cross, 4.0 * s)
	_line(img, 9 * s, 9 * s, 23 * s, 23 * s, cross_light, 1.4 * s)
	_line(img, 23 * s, 9 * s, 9 * s, 23 * s, cross_light, 1.4 * s)


static func _plus(img: Image, s: float) -> void:
	var bar := Color("#8fd8a8")
	var bar_light := Color("#c8f2d6")
	_rect(img, int(14 * s), int(7 * s), int(4 * s), int(18 * s), bar)
	_rect(img, int(7 * s), int(14 * s), int(18 * s), int(4 * s), bar)
	_rect(img, int(14 * s), int(7 * s), int(2 * s), int(18 * s), bar_light)
	_rect(img, int(7 * s), int(14 * s), int(18 * s), int(2 * s), bar_light)


static func _arrow(img: Image, s: float) -> void:
	var head := Color("#f2c45a")
	var head_light := Color("#ffe28a")
	_poly(img, [Vector2(9 * s, 6 * s), Vector2(24 * s, 16 * s), Vector2(9 * s, 26 * s)], head)
	_poly(img, [Vector2(11 * s, 10 * s), Vector2(20 * s, 16 * s), Vector2(11 * s, 22 * s)], head_light)


static func _lock(img: Image, s: float) -> void:
	var body := Color("#9aa3a1")
	var body_dark := Color("#5c6462")
	var body_light := Color("#c3ccc7")
	var shackle := Color("#79817f")
	# Shackle.
	for i in 16:
		var a := PI + PI * float(i) / 15.0
		var cx := 16.0 * s + cos(a) * 6.5 * s
		var cy := 12.0 * s + sin(a) * 6.0 * s
		_rect(img, int(cx - 1.5 * s), int(cy - 1.5 * s), int(3 * s), int(3 * s), shackle)
	# Body.
	_rect(img, int(8 * s), int(12 * s), int(16 * s), int(13 * s), body_dark)
	_rect(img, int(9 * s), int(13 * s), int(14 * s), int(11 * s), body)
	_rect(img, int(9 * s), int(13 * s), int(14 * s), int(2 * s), body_light)
	# Keyhole.
	_ellipse(img, 16 * s, 18 * s, 2.0 * s, 2.0 * s, Color("#2b3234"))
	_rect(img, int(15 * s), int(19 * s), int(2 * s), int(4 * s), Color("#2b3234"))


static func _check(img: Image, s: float) -> void:
	var tick := Color("#8fd8a8")
	var tick_light := Color("#d6f5df")
	_line(img, 6 * s, 17 * s, 12 * s, 24 * s, tick, 4.0 * s)
	_line(img, 12 * s, 24 * s, 26 * s, 8 * s, tick, 4.0 * s)
	_line(img, 6 * s, 17 * s, 12 * s, 24 * s, tick_light, 1.4 * s)
	_line(img, 12 * s, 24 * s, 22 * s, 12 * s, tick_light, 1.4 * s)


static func _spark(img: Image, s: float) -> void:
	var core := Color("#fff2b0")
	var mid := Color("#e6c85d")
	_line(img, 16 * s, 2 * s, 16 * s, 30 * s, mid, 2.6 * s)
	_line(img, 2 * s, 16 * s, 30 * s, 16 * s, mid, 2.6 * s)
	_line(img, 6 * s, 6 * s, 26 * s, 26 * s, core, 1.6 * s)
	_line(img, 26 * s, 6 * s, 6 * s, 26 * s, core, 1.6 * s)
	_ellipse(img, 16 * s, 16 * s, 3.0 * s, 3.0 * s, Color.WHITE)


static func _portal(img: Image, s: float) -> void:
	var glow := Color("#9d78d8")
	var glow_light := Color("#d6b9ff")
	var stone := Color("#596563")
	# Ring.
	_ellipse(img, 16 * s, 16 * s, 12.0 * s, 13.0 * s, stone)
	_ellipse(img, 16 * s, 16 * s, 10.0 * s, 11.0 * s, glow.darkened(0.45))
	# Swirl.
	for i in 22:
		var a := TAU * float(i) / 22.0 + 0.6
		var r := 2.0 + float(i) / 22.0 * 8.0
		var cx := 16.0 * s + cos(a * 2.4) * r * s
		var cy := 16.0 * s + sin(a * 2.4) * r * s
		_px(img, int(cx), int(cy), glow_light if i % 3 == 0 else glow)
	_ellipse(img, 16 * s, 16 * s, 3.0 * s, 3.0 * s, glow_light)
	_px(img, int(16 * s), int(15 * s), Color.WHITE)


static func _pet_paw(img: Image, s: float) -> void:
	var pad := Color("#e88f6b")
	var pad_light := Color("#ffc3a8")
	_ellipse(img, 16 * s, 21 * s, 6.5 * s, 5.0 * s, pad)
	_ellipse(img, 15 * s, 20 * s, 4.0 * s, 3.0 * s, pad_light)
	for i in 3:
		var ang := -2.1 + float(i) * 0.65
		var cx := 16.0 * s + cos(ang) * 7.2 * s
		var cy := 12.0 * s + sin(ang) * 4.6 * s
		_ellipse(img, cx, cy, 2.6 * s, 3.2 * s, pad)
		_px(img, int(cx), int(cy - 1.5 * s), pad_light)


static func _generic(img: Image, s: float) -> void:
	var base := Color("#9aa3a1")
	_ellipse(img, 16 * s, 16 * s, 10.0 * s, 10.0 * s, Color("#5c6462"))
	_ellipse(img, 16 * s, 16 * s, 8.5 * s, 8.5 * s, base)
	_ellipse(img, 13 * s, 13 * s, 3.5 * s, 3.5 * s, Color("#c3ccc7"))
