class_name OpeningCaptureArt
extends RefCounted
## Finite cutscene pixels; source ship/hero/monster images remain untouched.
const ARM_FRAMES := 36
const CAGE := Vector2(132, 87)
const HERO_SIZE := Vector2(32, 48)

static func arjun_feet(t: float) -> Vector2:
	var u := clampf((t - 0.45) / 1.10, 0, 1)
	u = u * u * (3 - 2 * u)
	return Vector2(86, 193).lerp(Vector2(175, 181), u).round()

static func arm_tip(frame: int) -> Vector2:
	var t := float(clampi(frame, 0, ARM_FRAMES)) * 2.25 / ARM_FRAMES
	var contact := arjun_feet(t) + Vector2(10, -20)
	var release := clampf((t - 2.05) / 0.20, 0, 1)
	return contact.lerp(Vector2(64, 174), release * release).round()

static func backdrop(right: bool) -> Texture2D:
	return PixelArt.cached_texture("opening/capture/backdrop/%s/v1" % right, func() -> Image:
		var img := PixelArt.image(232, 224)
		var sky := ["#263d56", "#354f67", "#4c6a7b", "#6e8a92"] if not right else ["#302f4b", "#45405e", "#5d5572", "#7b7287"]
		for i in 4: PixelArt.rect(img, 0, i * 23, 232, 23, Color(sky[i]))
		# Distant island silhouettes establish separate shores and horizons.
		for i in 6:
			var x := i * 45 - 8
			PixelArt._fill_polygon(img, [Vector2i(x, 95), Vector2i(x + 12, 63 + posmod(i * 13, 19)), Vector2i(x + 25, 69), Vector2i(x + 46, 95)], Color("#344e61") if not right else Color("#49425e"))
		for i in 4: PixelArt.rect(img, 0, 93 + i * 25, 232, 25, Color(["#467886", "#356575", "#295365", "#213f53"][i]))
		for i in 40:
			PixelArt.hline(img, posmod(i * 61, 223), 99 + posmod(i * 17, 115), 4 + i % 12, Color("#5b8d94") if i % 3 == 0 else Color("#3e6a79"))
		var rock := Color("#35434f") if not right else Color("#454250")
		PixelArt._fill_polygon(img, [Vector2i(42, 188), Vector2i(65, 164), Vector2i(127, 148), Vector2i(231, 146), Vector2i(231, 223), Vector2i(7, 223)], Color("#1c303e"))
		PixelArt._fill_polygon(img, [Vector2i(54, 184), Vector2i(78, 161), Vector2i(133, 145), Vector2i(231, 144), Vector2i(231, 213), Vector2i(25, 217)], rock)
		for row in 5:
			var y := 163 + row * 11
			PixelArt.hline(img, 72 - row * 9, y, 160 + row * 9, Color("#58606a") if not right else Color("#676170"))
			for col in 6:
				var x := 78 + col * 31 - (row % 2) * 14
				PixelArt.vline(img, x, y + 1, 9, Color("#283843") if not right else Color("#33333f"))
		# Broken seawall and barnacled edges; arithmetic never touches world RNG.
		for i in 8:
			PixelArt.rect(img, 76 + i * 20, 133 + i % 3 * 3, 17, 13, Color("#58616a") if not right else Color("#6c6571"))
			PixelArt.hline(img, 77 + i * 20, 133 + i % 3 * 3, 15, Color("#7f8587"))
		for i in 16:
			PixelArt.rect(img, 43 + posmod(i * 31, 186), 205 + i % 6 * 2, 3, 2, Color("#6c8b85"))
		if right:
			# A recessed ruin, rather than an unestablished magical crossing.
			PixelArt.rect(img, 154, 50, 68, 135, Color("#252638"))
			PixelArt._fill_polygon(img, [Vector2i(152, 76), Vector2i(165, 46), Vector2i(208, 46), Vector2i(225, 76)], Color("#686174"))
			PixelArt.rect(img, 164, 75, 49, 107, Color("#171f30"))
			PixelArt._fill_polygon(img, [Vector2i(164, 75), Vector2i(178, 59), Vector2i(198, 59), Vector2i(213, 75)], Color("#171f30"))
			for side in [151, 214]:
				for row in 8:
					PixelArt.rect(img, side, 75 + row * 13, 11, 11, Color("#767080") if row % 3 else Color("#575366"))
					PixelArt.vline(img, side, 75 + row * 13, 11, Color("#8c8190"))
			for i in 5: PixelArt.rect(img, 162 + i * 10, 56 - (3 if i in [1, 2, 3] else 0), 8, 12, Color("#8b7c90"))
			for x in [156, 218]:
				PixelArt.rect(img, x, 105, 3, 8, Color("#a18cae"))
				PixelArt.px(img, x + 1, 107, Color("#d4c3d3"))
			PixelArt.line(img, 221, 59, 225, 85, Color("#384b4c"))
			PixelArt.line(img, 225, 85, 218, 117, Color("#485f56"))
		else:
			# A far fortress wall relates the prison to the later island arena.
			for i in 5:
				PixelArt.rect(img, 138 + i * 21, 52 + i % 2 * 5, 19, 63, Color("#3a5062"))
				PixelArt.rect(img, 138 + i * 21, 46 + i % 2 * 5, 7, 9, Color("#4c6473"))
				PixelArt.vline(img, 143 + i * 21, 69, 12, Color("#203646"))
		return img)

static func cage(front: bool) -> Texture2D:
	return PixelArt.cached_texture("opening/capture/cage/%s/v1" % front, func() -> Image:
		var img := PixelArt.image(94, 103)
		if front:
			# Offset uprights leave the occupant's face in a generous clear interval.
			for x in [10, 30, 58, 78]:
				PixelArt.rect(img, x, 25, 3, 71, Color("#496273"))
				PixelArt.vline(img, x, 25, 71, Color("#b2c3c1"))
			PixelArt.rect(img, 7, 74, 77, 4, Color("#617f8a"))
			PixelArt.hline(img, 8, 74, 75, Color("#a1b7b8"))
			PixelArt.rect(img, 7, 93, 78, 5, Color("#708b94"))
		else:
			PixelArt.rect(img, 5, 24, 83, 72, Color("#263748"))
			for y in range(31, 91, 12):
				PixelArt.hline(img, 8, y, 76, Color("#344959"))
				for x in range(12 + y % 3 * 9, 86, 24): PixelArt.vline(img, x, y - 10, 9, Color("#1e2f40"))
			PixelArt.rect(img, 3, 94, 88, 8, Color("#7c8c8d"))
			PixelArt.hline(img, 5, 94, 84, Color("#b9bcb0"))
		return img)

static func cage_frame() -> Texture2D:
	return PixelArt.cached_texture("opening/capture/cage_frame/v1", func() -> Image:
		var img := PixelArt.image(94, 103)
		for x in [3, 85]:
			PixelArt.rect(img, x, 23, 6, 74, Color("#4c6374"))
			PixelArt.vline(img, x, 23, 74, Color("#92a8b0"))
			for y in [30, 88]: PixelArt.rect(img, x + 2, y, 2, 3, Color("#d2cdb6"))
		PixelArt._fill_polygon(img, [Vector2i(0, 25), Vector2i(20, 7), Vector2i(70, 7), Vector2i(93, 25)], Color("#243948"))
		PixelArt._fill_polygon(img, [Vector2i(6, 22), Vector2i(22, 10), Vector2i(68, 10), Vector2i(85, 22)], Color("#6a7d88"))
		PixelArt.line(img, 22, 10, 68, 10, Color("#b5c3bf"))
		PixelArt.rect(img, 1, 22, 92, 5, Color("#8fa3a8"))
		PixelArt.ellipse(img, 46, 11, 6, 7, Color("#b59b6c"))
		PixelArt.ellipse(img, 46, 11, 2, 3, Color("#e3ce9c"))
		return img)

static func lock_texture() -> Texture2D:
	return PixelArt.cached_texture("opening/capture/lock/v1", func() -> Image:
		var img := PixelArt.image(13, 17)
		PixelArt.ellipse_outline(img, 6, 5, 4, 4, Color("#ccd1bd"))
		PixelArt.rect(img, 1, 6, 11, 10, Color("#66543c"))
		PixelArt.rect(img, 2, 6, 9, 9, Color("#c2a372"))
		PixelArt.hline(img, 3, 7, 7, Color("#e4c590"))
		PixelArt.ellipse(img, 6, 10, 2, 2, Color("#2b3c46"))
		PixelArt.vline(img, 6, 11, 3, Color("#2b3c46"))
		return img)

static func hero(id: String, pose: int) -> Texture2D:
	return PixelArt.cached_texture("opening/capture/%s/%d/v1" % [id, pose], func() -> Image:
		# Rebuild the lower body for a standing Mei Ling; retain canonical face/palette.
		var img := OpeningFishingArt.hero(id, 0).get_image().duplicate() as Image
		var c := CharacterDB.get_character(id)
		var head := img.get_region(Rect2i(5, 5 if id == "arjun" else 10, 24, 20)).duplicate()
		img.fill(Color.TRANSPARENT)
		img.blit_rect(head, Rect2i(0, 0, 24, 20), Vector2i(5, 5))
		var tunic: Color = Color("#4e7667") if id == "mei_ling" else c.accent
		PixelArt.rect(img, 9, 25, 17, 13, Color("#283c47"))
		PixelArt.rect(img, 10, 25, 15, 12, tunic)
		PixelArt.rect(img, 11, 26, 5, 9, tunic.lightened(0.18))
		PixelArt.rect(img, 10, 35, 15, 3, Color("#654c3b"))
		PixelArt.rect(img, 17, 35, 3, 2, Color("#d6b77a"))
		for x in [11, 20]:
			PixelArt.rect(img, x, 38, 5, 9, Color("#2b3d47"))
			PixelArt.rect(img, x, 46, 7, 2, Color("#5e4b3b"))
		# A visible leftward glance/reach connects both friends to the lost ship.
		if pose > 0:
			PixelArt.rect(img, 18, 15, 4, 3, c.tint)
			PixelArt.rect(img, 12, 15, 3, 2, Color("#f4dfbd"))
			PixelArt.px(img, 12, 15, Color("#263849"))
			PixelArt.hline(img, 11, 13, 5, Color("#38414b"))
			PixelArt.line(img, 11, 28, 5, 29, tunic.lightened(0.18))
			PixelArt.line(img, 5, 29, 2, 25, c.tint)
			PixelArt.rect(img, 0, 23, 4, 3, c.tint)
		else:
			PixelArt.rect(img, 7, 28, 4, 10, tunic.lightened(0.12))
			PixelArt.rect(img, 7, 37, 4, 3, c.tint)
		PixelArt.rect(img, 24, 28, 4, 8, tunic.darkened(0.12))
		PixelArt.rect(img, 24, 35, 4, 4, c.tint)
		if pose == 2:
			PixelArt.rect(img, 11, 44, 6, 4, Color.TRANSPARENT)
			PixelArt.rect(img, 7, 44, 8, 4, Color("#5e4b3b"))
		return img)

static func guard(frame: int) -> Texture2D:
	return PixelArt.cached_texture("opening/capture/guard/%d/v1" % frame, func() -> Image:
		var img := PixelArt.image(38, 58)
		var ink := Color("#1d2d3e")
		var bone := Color("#b9b6a1")
		PixelArt._fill_polygon(img, [Vector2i(5, 29), Vector2i(10, 19), Vector2i(29, 19), Vector2i(35, 32), Vector2i(30, 48), Vector2i(8, 48)], ink)
		PixelArt.rect(img, 10, 24, 20, 23, Color("#596c70"))
		PixelArt.rect(img, 13, 24, 5, 21, Color("#7f8a81"))
		PixelArt.ellipse(img, 19, 13, 10, 10, ink)
		PixelArt.ellipse(img, 19, 12, 8, 8, bone)
		PixelArt.rect(img, 11, 5, 15, 3, Color("#7f8b83"))
		PixelArt.rect(img, 13, 12, 5, 4, ink)
		PixelArt.rect(img, 22, 12, 4, 4, ink)
		PixelArt.hline(img, 14, 13, 3, Color("#88d8c3"))
		PixelArt.hline(img, 23, 13, 2, Color("#88d8c3"))
		PixelArt.hline(img, 16, 19, 7, Color("#49565d"))
		PixelArt.line(img, 19, 3, 22, 0, Color("#78918a"))
		for x in [6, 29]:
			PixelArt.rect(img, x, 29, 5, 13, ink)
			PixelArt.rect(img, x + 1, 30, 3, 11, bone.darkened(0.15))
			PixelArt.rect(img, x, 40, 5, 4, bone)
		for x in [10, 24]:
			var step := 2 if frame == 1 and x == 10 else 0
			PixelArt.rect(img, x, 46, 6, 10 - step, ink)
			PixelArt.rect(img, x - 2, 54 - step, 9, 4, Color("#869087"))
		for y in [29, 34, 39]: PixelArt.hline(img, 17, y, 8, Color("#b2b3a0"))
		return img)

static func arm(frame: int) -> Texture2D:
	return PixelArt.cached_texture("opening/capture/arm/%d/v1" % frame, func() -> Image:
		var img := PixelArt.image(232, 224)
		var tip := arm_tip(frame)
		var spine := PackedVector2Array()
		for i in 25:
			spine.append(Vector2(47, 121).bezier_interpolate(Vector2(9, 168), Vector2(tip.x - 30, 196), tip, float(i) / 24).round())
		for layer in 2:
			for i in 24:
				var steps := maxi(1, roundi(spine[i].distance_to(spine[i + 1])))
				for step in steps + 1:
					var at := spine[i].lerp(spine[i + 1], float(step) / steps).round()
					var r := maxi(2, roundi(lerpf(9, 3, float(i) / 24))) + (2 if layer == 0 else 0)
					PixelArt.ellipse(img, int(at.x), int(at.y), r, r, Color("#1c3047") if layer == 0 else Color("#79668b"))
		for i in range(2, 24, 3):
			PixelArt.ellipse(img, int(spine[i].x), int(spine[i].y - 2), 3, 2, Color("#d0b3a6"))
			PixelArt.px(img, int(spine[i].x), int(spine[i].y - 2), Color("#896479"))
		return img)
