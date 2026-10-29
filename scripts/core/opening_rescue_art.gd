class_name OpeningRescueArt
extends RefCounted
## Original finite classic pixels: a living rescuer and a shore that offers care.
## Shared combat, turtle, friend and wreck images are copied, never repainted.
const FRAME := Vector2i(480, 224)
const SHORE := [Vector2i(350, 130), Vector2i(480, 117), Vector2i(480, 224), Vector2i(307, 224), Vector2i(318, 199), Vector2i(331, 174), Vector2i(339, 150)]

static func on_sand(at: Vector2) -> bool:
	var polygon := PackedVector2Array()
	for point in SHORE: polygon.append(Vector2(point))
	return Geometry2D.is_point_in_polygon(at, polygon)

static func backdrop() -> Texture2D:
	return PixelArt.cached_texture("opening/rescue/backdrop/v1", func() -> Image:
		var img := PixelArt.image(FRAME.x, FRAME.y)
		# Cool exposed sea gives way to peach light over the inhabited shore.
		for row in 6:
			var cool := Color(["#496982", "#5b7b90", "#7896a0", "#9ab1b0", "#bcc5b8", "#d7cfb9"][row])
			var warm := Color(["#bdaca9", "#d2b8aa", "#e1c5a7", "#edd1ae", "#f4debc", "#f4e3c5"][row])
			for col in 12: PixelArt.rect(img, col * 40, row * 16, 40, 16, cool.lerp(warm, float(col) / 11))
		PixelArt.ellipse(img, 336, 41, 27, 24, Color("#e8d3af"))
		PixelArt.ellipse(img, 336, 41, 20, 19, Color("#f6e7bc"))
		PixelArt.ellipse(img, 336, 41, 14, 14, Color("#fff0ce"))
		# Broad cloud shelves and a distant green headland, not a new realm reveal.
		for cloud in [Vector2i(46, 40), Vector2i(191, 27)]:
			PixelArt.rect(img, cloud.x, cloud.y, 61, 5, Color("#b5c1bc"))
			PixelArt.rect(img, cloud.x + 9, cloud.y - 4, 34, 4, Color("#c7cec1"))
		PixelArt._fill_polygon(img, [Vector2i(257, 106), Vector2i(292, 83), Vector2i(316, 88), Vector2i(350, 64), Vector2i(384, 81), Vector2i(432, 71), Vector2i(480, 93), Vector2i(480, 138)], Color("#788d7a"))
		PixelArt._fill_polygon(img, [Vector2i(290, 118), Vector2i(332, 94), Vector2i(369, 101), Vector2i(405, 86), Vector2i(480, 109), Vector2i(480, 145)], Color("#597967"))
		for row in 8: PixelArt.rect(img, 0, 96 + row * 16, 480, 16, Color(["#699f9d", "#578f96", "#437f8a", "#357180", "#2c6576", "#265a6e", "#225265", "#214b5d"][row]))
		for i in 58:
			PixelArt.hline(img, posmod(i * 71, 473), 101 + posmod(i * 19, 120), 4 + i % 12, Color("#83b5ac") if i % 3 == 0 else Color("#437f86"))
		# Shallow water hugs the actual sand outline instead of a flat green wedge.
		PixelArt._fill_polygon(img, [Vector2i(341, 132), Vector2i(480, 119), Vector2i(480, 224), Vector2i(292, 224), Vector2i(307, 195), Vector2i(320, 169), Vector2i(329, 147)], Color("#70a99b"))
		PixelArt._fill_polygon(img, SHORE, Color("#d7bb85"))
		PixelArt._fill_polygon(img, [Vector2i(354, 139), Vector2i(480, 127), Vector2i(480, 224), Vector2i(319, 224), Vector2i(332, 192), Vector2i(342, 165)], Color("#efd39a"))
		for i in 24:
			var x := 345 + posmod(i * 37, 131)
			var y := 151 + posmod(i * 13, 66)
			PixelArt.rect(img, x, y, 2 + i % 3, 1, Color("#c4a878"))
		# A worn path connects the people on the beach to a real village home.
		PixelArt._fill_polygon(img, [Vector2i(389, 136), Vector2i(410, 136), Vector2i(390, 192), Vector2i(365, 198)], Color("#d7bd86"))
		PixelArt._fill_polygon(img, [Vector2i(352, 129), Vector2i(366, 104), Vector2i(480, 99), Vector2i(480, 137), Vector2i(409, 143)], Color("#637f55"))
		# A small timber cottage with warm windows; part of this shot, not runtime art.
		for x in [398, 445]: PixelArt.rect(img, x, 107, 4, 34, Color("#584c3e"))
		PixelArt.rect(img, 387, 78, 69, 47, Color("#70563e"))
		for y in range(82, 123, 6): PixelArt.hline(img, 389, y, 65, Color("#a48354"))
		PixelArt._fill_polygon(img, [Vector2i(377, 80), Vector2i(397, 54), Vector2i(444, 54), Vector2i(465, 80)], Color("#3b4944"))
		PixelArt._fill_polygon(img, [Vector2i(382, 76), Vector2i(400, 56), Vector2i(442, 56), Vector2i(459, 76)], Color("#927b51"))
		for y in [63, 68, 73]: PixelArt.hline(img, 395 - (y - 63), y, 49 + (y - 63) * 2, Color("#b99c68"))
		PixelArt.rect(img, 413, 96, 15, 29, Color("#354849"))
		for x in [393, 434]:
			PixelArt.rect(img, x, 91, 14, 16, Color("#403f36"))
			PixelArt.rect(img, x + 2, 93, 10, 12, Color("#e9bf75"))
			PixelArt.hline(img, x + 2, 98, 10, Color("#856d48"))
			PixelArt.vline(img, x + 6, 93, 12, Color("#856d48"))
		PixelArt.rect(img, 383, 123, 78, 5, Color("#ae9163"))
		# Curved palm and leafy crown frame the beach without crossing actors' faces.
		for i in 47:
			var x := 366 - roundi(sin(float(i) / 46 * PI * 0.5) * 12)
			PixelArt.rect(img, x, 91 + i, 5, 2, Color("#7a6847"))
			if i % 6 == 0: PixelArt.hline(img, x, 91 + i, 5, Color("#b2965f"))
		for tip in [Vector2i(319, 85), Vector2i(329, 69), Vector2i(362, 60), Vector2i(388, 76), Vector2i(394, 99)]:
			PixelArt._fill_polygon(img, [Vector2i(366, 91), Vector2i(tip.x, tip.y), Vector2i(tip.x + 5, tip.y + 7), Vector2i(366, 95)], Color("#3c6e54"))
			PixelArt.line(img, 366, 92, tip.x + 2, tip.y + 3, Color("#7a9d65"))
		for x in [460, 469, 477]:
			PixelArt.rect(img, x, 144, 4, 17, Color("#8a774f"))
			PixelArt.rect(img, x - 1, 142, 6, 3, Color("#c0a26c"))
		PixelArt.hline(img, 458, 149, 22, Color("#a58d5d"))
		return img)

static func stern() -> Texture2D:
	return PixelArt.cached_texture("opening/rescue/stern/v1", func() -> Image:
		var source := OpeningWreckArt.piece("hull", 0).get_image().duplicate() as Image
		return source.get_region(Rect2i(0, 103, 150, 61)))

static func turtle(stroke: int) -> Texture2D:
	return PixelArt.cached_texture("opening/rescue/turtle/%d/v1" % stroke, func() -> Image:
		var img := PixelArt.image(96, 48)
		var ink := Color("#243e46")
		var flip := [0, -3, -1, 2][posmod(stroke, 4)] as int
		PixelArt._fill_polygon(img, [Vector2i(14, 31), Vector2i(4, 36 + flip), Vector2i(16, 43 + flip), Vector2i(31, 34)], ink)
		PixelArt._fill_polygon(img, [Vector2i(17, 31), Vector2i(7, 36 + flip), Vector2i(17, 39 + flip), Vector2i(29, 33)], Color("#579d82"))
		PixelArt.ellipse(img, 42, 27, 31, 16, ink)
		PixelArt.ellipse(img, 43, 28, 28, 11, Color("#90b88a"))
		PixelArt.ellipse(img, 40, 20, 30, 17, Color("#315f52"))
		PixelArt.ellipse(img, 40, 18, 26, 14, Color("#6b9c69"))
		PixelArt.ellipse(img, 37, 14, 20, 8, Color("#9fbd79"))
		for points in [[Vector2i(27, 8), Vector2i(42, 5), Vector2i(49, 14), Vector2i(40, 23), Vector2i(27, 20), Vector2i(23, 13)], [Vector2i(49, 14), Vector2i(60, 12), Vector2i(65, 21), Vector2i(56, 28), Vector2i(40, 23)]]:
			for i in points.size():
				var a: Vector2i = points[i]
				var b: Vector2i = points[(i + 1) % points.size()]
				PixelArt.line(img, a.x, a.y, b.x, b.y, Color("#47754f"))
		PixelArt.line(img, 15, 22, 27, 20, Color("#47754f"))
		PixelArt.line(img, 25, 31, 27, 20, Color("#47754f"))
		PixelArt.ellipse(img, 74, 25, 10, 8, ink)
		PixelArt.ellipse(img, 78, 24, 13, 9, Color("#8cbd8c"))
		PixelArt.ellipse(img, 81, 21, 8, 5, Color("#b5d6a1"))
		PixelArt.rect(img, 82, 20, 2, 3, ink)
		PixelArt.px(img, 82, 20, Color("#f7ebc4"))
		PixelArt.hline(img, 84, 28, 7, Color("#436d59"))
		PixelArt._fill_polygon(img, [Vector2i(52, 29), Vector2i(44, 36 - flip), Vector2i(57, 45 - flip), Vector2i(70, 35)], ink)
		PixelArt._fill_polygon(img, [Vector2i(54, 30), Vector2i(48, 36 - flip), Vector2i(57, 41 - flip), Vector2i(66, 35)], Color("#70ad87"))
		PixelArt.line(img, 53, 35 - flip, 59, 40 - flip, Color("#a6cb95"))
		return img)

static func adam(pose: int) -> Texture2D:
	return PixelArt.cached_texture("opening/rescue/adam/%d/v1" % pose, func() -> Image:
		var source := OpeningFishingArt.hero("adam", 0).get_image().duplicate() as Image
		var head := source.get_region(Rect2i(5, 5, 24, 20)).duplicate()
		var img := PixelArt.image(32, 48)
		var c := CharacterDB.get_character("adam")
		var skin: Color = c.tint
		var cloth: Color = c.accent
		var seated := pose == 2
		img.blit_rect(head, Rect2i(0, 0, 24, 20), Vector2i(5, 10 if seated else 5))
		var y := 30 if seated else 25
		PixelArt.rect(img, 9, y, 17, 13, Color("#2e4549"))
		PixelArt.rect(img, 10, y, 15, 11, cloth.darkened(0.12))
		PixelArt.rect(img, 11, y + 1, 5, 9, cloth.lightened(0.12))
		PixelArt.hline(img, 10, y + 10, 15, Color("#6b5640"))
		if seated:
			PixelArt.rect(img, 10, 41, 16, 5, Color("#33434a"))
			PixelArt.rect(img, 21, 43, 5, 5, Color("#33434a"))
			PixelArt.hline(img, 20, 47, 9, Color("#66513d"))
		else:
			for x in [11, 20]:
				PixelArt.rect(img, x, 37, 5, 10, Color("#33434a"))
				PixelArt.rect(img, x - 1, 45, 7, 3, Color("#66513d"))
		# Reaching is physical help/boarding, never a weapon or combat stance.
		if pose == 1 or pose == 3:
			PixelArt.line(img, 23, y + 2, 28, y + 3 if pose == 1 else y + 1, cloth.lightened(0.14))
			PixelArt.rect(img, 28, y + 2 if pose == 1 else y, 4, 3, skin)
		else:
			PixelArt.rect(img, 23, y + 2, 3, 8, cloth.lightened(0.14))
			PixelArt.rect(img, 23, y + 9, 4, 3, skin)
		PixelArt.line(img, 11, y + 3, 7, y + 8, cloth.lightened(0.1))
		PixelArt.rect(img, 5, y + 7, 4, 3, skin)
		if pose == 0:
			# Wet sleeve and a small held-in arm communicate exhaustion, not injury.
			PixelArt.line(img, 9, y + 8, 17, y + 7, skin)
			PixelArt.px(img, 12, 35, Color("#9bbfb0"))
		return img)

static func villager(kind: String, welcome: bool) -> Texture2D:
	return PixelArt.cached_texture("opening/rescue/villager/%s/%s/v1" % [kind, welcome], func() -> Image:
		var source := PixelArt.npc_texture(kind).get_image().duplicate() as Image
		source.resize(32, 48, Image.INTERPOLATE_NEAREST)
		var img := PixelArt.image(40, 52)
		img.blit_rect(source, Rect2i(0, 0, 32, 48), Vector2i(4, 4))
		if kind == "water_keeper" and welcome:
			PixelArt.line(img, 13, 29, 5, 32, Color("#78bdce"))
			PixelArt.line(img, 5, 32, 1, 31, Color("#d9b18b"))
			PixelArt.rect(img, 0, 30, 4, 3, Color("#d9b18b"))
		elif kind == "tree_planter":
			# A folded cloth offered by a second villager makes the welcome concrete.
			PixelArt.rect(img, 6, 32, 18, 12, Color("#86a28a"))
			PixelArt.rect(img, 7, 32, 16, 9, Color("#e9dab5"))
			PixelArt.hline(img, 8, 34, 13, Color("#c4b58e"))
			PixelArt.rect(img, 5, 33, 4, 3, Color("#d9b18b"))
		return img)
