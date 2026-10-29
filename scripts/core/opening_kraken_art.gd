class_name OpeningKrakenArt
extends RefCounted
## Cutscene-only, finite-palette sprites. No imported illustration or shared edits.
const ARM_FRAMES := 24

static func hook_at(frame: int) -> Vector2:
	var rise := float(clampi(frame, 0, ARM_FRAMES)) / float(ARM_FRAMES)
	return Vector2(288 - roundf(rise * 8), 196 - roundf(rise * 71))

static func arm(frame: int, caught: bool) -> Texture2D:
	return PixelArt.cached_texture("opening/kraken/arm/%s/%d/v1" % [caught, frame], func() -> Image:
		var img := PixelArt.image(480, 224)
		var tip := hook_at(frame)
		var rise := float(frame) / float(ARM_FRAMES)
		var points := PackedVector2Array([Vector2(365, 183), Vector2(351, 198), Vector2(332, 207), Vector2(312, 207), Vector2(296, 196), Vector2(tip.x + 2, tip.y + 40), Vector2(tip.x - 3, tip.y + 19), tip])
		if not caught:
			points = PackedVector2Array([Vector2(414, 163), Vector2(430, 169), Vector2(448, 162), Vector2(457, 149 - rise * 14), Vector2(456, 132 - rise * 20), Vector2(447, 119 - rise * 22)])
		# Stamp pixel discs along the spine: tapered living flesh, no vector elbows.
		for layer in 2:
			for i in points.size() - 1:
				var radius := lerpf(11, 3, float(i) / float(points.size() - 2))
				var steps := maxi(1, int(points[i].distance_to(points[i + 1])))
				for step in steps + 1:
					var at := points[i].lerp(points[i + 1], float(step) / float(steps)).round()
					var r := maxi(2, roundi(radius) + (2 if layer == 0 else 0))
					PixelArt.ellipse(img, int(at.x), int(at.y), r, r, Color("#192e47") if layer == 0 else Color("#74618b"))
		for i in points.size() - 1:
			var a := (points[i] + Vector2(-2, -3)).round()
			var b := (points[i + 1] + Vector2(-2, -3)).round()
			PixelArt.line(img, int(a.x), int(a.y), int(b.x), int(b.y), Color("#b09aa9"))
			if caught:
				for u in [0.25, 0.75]:
					var at := points[i].lerp(points[i + 1], u).round() + Vector2(2, 2)
					PixelArt.ellipse(img, int(at.x), int(at.y), 3, 2, Color("#d2b6a5"))
					PixelArt.px(img, int(at.x), int(at.y), Color("#765976"))
		return img)

static func backdrop(stage: int) -> Texture2D:
	return PixelArt.cached_texture("opening/kraken/sky/%d/v1" % stage, func() -> Image:
		var img := PixelArt.image(480, 224)
		var skies := [["#8bbcca", "#add0d1", "#d4dfcf", "#f1dfbf"], ["#648ba2", "#7ca4af", "#a0b8b6", "#bbc8b9"], ["#354c69", "#456880", "#648b99", "#89a5a4"]]
		var seas := [["#82c0b7", "#59a5a7", "#378993", "#286e80"], ["#559aa0", "#397f8c", "#296674", "#214f65"], ["#3b7b89", "#2c6476", "#224e65", "#1a3d55"]]
		for i in 4:
			PixelArt.rect(img, 0, i * 22, 480, 22, Color(skies[stage][i]))
			PixelArt.rect(img, 0, 88 + i * 34, 480, 34, Color(seas[stage][i]))
		PixelArt.ellipse(img, 369, 35, 21, 21, Color("#d2ceaf") if stage < 2 else Color("#819da0"))
		PixelArt.ellipse(img, 369, 35, 15, 15, Color("#f4e0b0") if stage < 2 else Color("#a3b7ac"))
		PixelArt.hline(img, 0, 88, 480, Color("#bdcdb9") if stage < 2 else Color("#89a6a7"))
		for i in 93:
			var y := 94 + posmod(i * 31, 126)
			PixelArt.hline(img, posmod(i * 89, 480), y, 4 + i % 14, Color(seas[stage][maxi(0, mini(3, (y - 88) / 34) - 1)]))
		return img)

static func body(pose: int) -> Texture2D:
	return PixelArt.cached_texture("opening/kraken/body/%d/v1" % pose, func() -> Image:
		var img := PixelArt.image(156, 170)
		var ink := Color("#172d46")
		# Crown and mantle make a sea king, not a borrowed combat walk sprite.
		PixelArt._fill_polygon(img, [Vector2i(22, 90), Vector2i(24, 43), Vector2i(38, 16), Vector2i(50, 25), Vector2i(61, 5), Vector2i(79, 20), Vector2i(96, 4), Vector2i(107, 24), Vector2i(121, 14), Vector2i(136, 46), Vector2i(139, 105), Vector2i(120, 144), Vector2i(48, 147)], ink)
		PixelArt.ellipse(img, 81, 78, 53, 62, Color("#574b77"))
		PixelArt.ellipse(img, 76, 70, 44, 53, Color("#77638f"))
		PixelArt.ellipse(img, 68, 61, 30, 37, Color("#93809f"))
		PixelArt._fill_polygon(img, [Vector2i(29, 78), Vector2i(37, 43), Vector2i(44, 32), Vector2i(40, 79), Vector2i(53, 116), Vector2i(47, 127)], Color("#456a7b"))
		PixelArt._fill_polygon(img, [Vector2i(105, 34), Vector2i(124, 46), Vector2i(130, 86), Vector2i(118, 119), Vector2i(110, 120), Vector2i(121, 80)], Color("#39465f"))
		for i in 4:
			PixelArt.line(img, 41 + i * 3, 47 + i * 2, 46 + i * 3, 61 + i * 2, Color("#66547d"))
			PixelArt.line(img, 113 - i * 3, 46 + i * 2, 108 - i * 3, 60 + i * 2, Color("#aa929f"))
		for point in [Vector2i(40, 20), Vector2i(62, 11), Vector2i(96, 10), Vector2i(121, 20)]:
			PixelArt._fill_polygon(img, [point, point + Vector2i(-3, 17), point + Vector2i(10, 13)], Color("#b5a27c"))
		for i in 21:
			var x := 48 + posmod(i * 17, 65)
			var y := 28 + posmod(i * 11, 29)
			PixelArt.rect(img, x, y, 2, 2, Color("#b19ba7") if i % 3 else Color("#65537d"))
		# Heavy brow silhouettes remain readable on a phone; eyes never strobe.
		for x in [48, 94]:
			PixelArt.rect(img, x - 3, 69, 24, 11, ink)
			if pose == 0:
				PixelArt.hline(img, x, 75, 18, Color("#ba9b83"))
			else:
				PixelArt.rect(img, x, 72, 18, 6, Color("#d88443"))
				PixelArt.rect(img, x + 2, 73, 14, 3, Color("#f6d77f"))
				PixelArt.rect(img, x + 8, 72, 3, 7, ink)
		PixelArt.line(img, 45, 67, 69, 73, ink)
		PixelArt.line(img, 94, 73, 116, 66, ink)
		PixelArt._fill_polygon(img, [Vector2i(74, 83), Vector2i(87, 83), Vector2i(84, 96), Vector2i(78, 97)], Color("#c5aa8b"))
		PixelArt._fill_polygon(img, [Vector2i(60, 108), Vector2i(79, 101), Vector2i(102, 106), Vector2i(93, 123 if pose < 2 else 135), Vector2i(72, 125 if pose < 2 else 138)], ink)
		if pose == 2:
			PixelArt._fill_polygon(img, [Vector2i(70, 111), Vector2i(93, 110), Vector2i(87, 130), Vector2i(78, 129)], Color("#965b68"))
			for x in [69, 82, 94]:
				PixelArt._fill_polygon(img, [Vector2i(x, 108), Vector2i(x + 6, 108), Vector2i(x + 3, 117)], Color("#e1c89c"))
		else:
			PixelArt.line(img, 68, 111, 93, 110, Color("#b89586"))
		for i in 5:
			var x := 25 + i * 23
			PixelArt._fill_polygon(img, [Vector2i(63, 128), Vector2i(x, 148), Vector2i(x - 9, 165), Vector2i(x + 7, 168), Vector2i(91, 133)], ink)
			PixelArt.line(img, x, 149, x - 3, 162, Color("#79648c"))
		return img)

static func hero(id: String, pose: int) -> Texture2D:
	return PixelArt.cached_texture("opening/kraken/%s/%d/v1" % [id, pose], func() -> Image:
		# Copy the cutscene-only unarmed sprite; never repaint a cached source.
		var img := OpeningFishingArt.hero(id, 0).get_image().duplicate() as Image
		if pose == 0: return img
		var c := CharacterDB.get_character(id)
		var head_y := 21 if id == "mei_ling" else 16
		PixelArt.rect(img, 19, head_y - 1, 3, 3, Color("#f6e4bc"))
		PixelArt.rect(img, 21, head_y, 1, 2, Color("#293e4b"))
		PixelArt.hline(img, 18, head_y - 3, 5, Color("#34474a"))
		PixelArt.rect(img, 20, head_y + 4, 2, 3, Color("#69485a"))
		if id == "arjun":
			# Both hands stay on the rod; wider boots read as bracing, not running.
			PixelArt.rect(img, 9, 46, 7, 2, Color("#514439"))
			PixelArt.rect(img, 21, 46, 7, 2, Color("#514439"))
		elif id == "adam":
			PixelArt.line(img, 12, 28, 8, 35, c.accent.lightened(0.15))
			PixelArt.line(img, 8, 35, 17, 37, c.tint)
			PixelArt.rect(img, 17, 36, 4, 3, c.tint)
		else:
			PixelArt.line(img, 23, 31, 25, 26, Color("#618875"))
			PixelArt.line(img, 25, 26, 22, 25, c.tint)
		return img)
