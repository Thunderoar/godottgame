class_name OpeningFishingArt
extends RefCounted
## Cutscene-only original pixels. Never modifies the shared ship/character images.
## All layers use the same 440 x 180 boat space; actors have explicit foot anchors.

const BOAT_SIZE := Vector2(440, 180)
const HERO_SIZE := Vector2(48, 72)
const LETTERS := [
	["10001", "10001", "10001", "10001", "10001", "10001", "01110"],
	["10001", "11001", "10101", "10011", "10001", "10001", "10001"],
	["11111", "00100", "00100", "00100", "00100", "00100", "11111"],
	["01111", "10000", "10000", "01110", "00001", "00001", "11110"],
	["11111", "00001", "00010", "00100", "01000", "10000", "11111"],
	["01110", "10001", "10001", "11111", "10001", "10001", "10001"],
]

static func backdrop() -> Texture2D:
	return PixelArt.cached_texture("opening/fishing/backdrop/v1", func() -> Image:
		var img := PixelArt.image(640, 270)
		var sky := ["#81b7c8", "#96c5cf", "#afd3d5", "#c8dfdb", "#e1e5d7", "#f5e4cc"]
		for band in sky.size():
			PixelArt.rect(img, 0, band * 16, 640, 16, Color(sky[band]))
		# A stepped halo, not a blurred glow. Sun stays clear of the mast and faces.
		PixelArt.ellipse(img, 520, 44, 33, 27, Color("#dce1cd"))
		PixelArt.ellipse(img, 520, 44, 25, 23, Color("#f5e8c8"))
		PixelArt.ellipse(img, 520, 44, 18, 18, Color("#fff1ce"))
		var sea := ["#9dccbf", "#88c3bb", "#70b6b2", "#5ba7aa", "#499ba3", "#3d909b", "#328593", "#2d7b8b"]
		for band in sea.size():
			PixelArt.rect(img, 0, 96 + band * 23, 640, 23, Color(sea[band]))
		PixelArt.hline(img, 0, 96, 640, Color("#e8e9ce"))
		PixelArt.hline(img, 0, 98, 640, Color("#b5d7c9"))
		# Deterministic broken highlights: no world RNG, no repeated full-width grid.
		for i in 125:
			var y := 103 + posmod(i * 31, 166)
			var x := posmod(i * 113 + (i / 7) * 19, 640)
			var length := 3 + (y - 96) / 16 + posmod(i * 7, 11)
			var ink := Color("#87c8bc") if y < 175 else Color("#58a8aa")
			if i % 4 == 0: ink = Color("#a4d3c1") if y < 175 else Color("#65b3af")
			PixelArt.hline(img, x, y, length, ink)
		for i in 17:
			var y := 102 + i * 6
			var spread := 10 + i * 3
			PixelArt.hline(img, 520 - spread + posmod(i * 7, 19), y, spread, Color("#d3dfbe") if i < 7 else Color("#9ecab1"))
		return img)

static func cloud() -> Texture2D:
	return PixelArt.cached_texture("opening/fishing/cloud/v1", func() -> Image:
		var img := PixelArt.image(154, 34)
		for blob in [Vector3(24, 22, 18), Vector3(49, 18, 26), Vector3(80, 12, 23), Vector3(109, 21, 29), Vector3(133, 25, 17)]:
			PixelArt.ellipse(img, int(blob.x), int(blob.y), int(blob.z), 9, Color("#cee1db"))
			PixelArt.ellipse(img, int(blob.x), int(blob.y) - 3, int(blob.z) - 2, 8, Color("#f8edda"))
		PixelArt.hline(img, 15, 30, 121, Color("#b9d5d2"))
		return img)

static func deck() -> Texture2D:
	return PixelArt.cached_texture("opening/fishing/deck/v1", func() -> Image:
		var img := PixelArt.image(440, 180)
		PixelArt._fill_polygon(img, [Vector2i(22, 108), Vector2i(369, 100), Vector2i(419, 112), Vector2i(377, 134), Vector2i(45, 132)], Color("#463e37"))
		PixelArt._fill_polygon(img, [Vector2i(33, 108), Vector2i(367, 103), Vector2i(406, 113), Vector2i(376, 126), Vector2i(49, 124)], Color("#b3814d"))
		for y in range(108, 126, 4):
			PixelArt.hline(img, 43, y, 344, Color("#6e543b"))
			PixelArt.hline(img, 52, y + 1, 323, Color("#d5a569"))
		for i in 12:
			PixelArt.line(img, 46 + i * 28, 108, 55 + i * 28, 125, Color("#725138"))
		# Far-side gunwale and stanchions sit behind the actors.
		PixelArt.line(img, 28, 103, 374, 98, Color("#614b37"))
		PixelArt.line(img, 28, 101, 374, 96, Color("#e9bd70"))
		for x in [36, 89, 205, 274, 361]:
			PixelArt.rect(img, x, 97, 3, 15, Color("#715039"))
			PixelArt.rect(img, x, 97, 2, 3, Color("#f2cc82"))
		# A bench behind Mei Ling, a tackle box, and one coil of rope.
		PixelArt.rect(img, 291, 96, 52, 5, Color("#523e32"))
		PixelArt.rect(img, 293, 95, 48, 3, Color("#d2a069"))
		for x in [298, 335]: PixelArt.rect(img, x, 100, 3, 14, Color("#6a4933"))
		PixelArt.rect(img, 152, 99, 23, 16, Color("#424d4c"))
		PixelArt.rect(img, 154, 100, 19, 12, Color("#75877a"))
		PixelArt.hline(img, 153, 105, 21, Color("#bec8a2"))
		PixelArt.rect(img, 162, 103, 3, 5, Color("#dfbd6e"))
		for i in 3:
			PixelArt.ellipse(img, 66, 113 - i, 13 - i * 3, 4 - i, Color("#73563b"))
			PixelArt.ellipse(img, 66, 112 - i, 11 - i * 3, 3 - i, Color("#d8bd85"))
		PixelArt.line(img, 55, 113, 45, 121, Color("#d8bd85"))
		return img)

static func rigging(frame: int) -> Texture2D:
	return PixelArt.cached_texture("opening/fishing/rigging/%d/v1" % (frame % 3), func() -> Image:
		var img := PixelArt.image(440, 180)
		var sway := [0, 1, 0][frame % 3] as int
		# Ropes first, mast and sail second: clear, layered rigging.
		PixelArt.line(img, 168, 7, 32, 106, Color("#937d59"))
		PixelArt.line(img, 170, 9, 389, 106, Color("#7d7357"))
		PixelArt.line(img, 171, 16, 426, 91, Color("#8c7958"))
		PixelArt.rect(img, 165, 4, 6, 114, Color("#4d4034"))
		PixelArt.rect(img, 166, 5, 2, 110, Color("#ae885b"))
		PixelArt.rect(img, 160, 114, 17, 4, Color("#453a31"))
		PixelArt._fill_polygon(img, [Vector2i(174, 19), Vector2i(314 + sway, 65), Vector2i(174, 96)], Color("#a99773"))
		PixelArt._fill_polygon(img, [Vector2i(175, 20), Vector2i(303 + sway, 63), Vector2i(176, 87)], Color("#efdfb3"))
		PixelArt._fill_polygon(img, [Vector2i(177, 24), Vector2i(263 + sway, 60), Vector2i(177, 73)], Color("#f9ebc7"))
		PixelArt.line(img, 177, 23, 302 + sway, 63, Color("#fff2cf"))
		for i in 4:
			PixelArt.line(img, 181 + i * 21, 29 + i * 7, 178 + i * 21, 86 - i * 4, Color("#ccb88e"))
		PixelArt._fill_polygon(img, [Vector2i(160, 36), Vector2i(55 - sway, 83), Vector2i(160, 100)], Color("#b5a280"))
		PixelArt._fill_polygon(img, [Vector2i(158, 39), Vector2i(67 - sway, 81), Vector2i(158, 91)], Color("#e2d1a8"))
		PixelArt.line(img, 158, 40, 69 - sway, 80, Color("#fae9bf"))
		PixelArt.line(img, 164, 26, 319, 70, Color("#574a37"))
		# Blue pennant remains recognizable across the cut to the existing ship.
		PixelArt._fill_polygon(img, [Vector2i(170, 5), Vector2i(170, 18), Vector2i(202, 12 + sway), Vector2i(185, 8)], Color("#285c86"))
		PixelArt.line(img, 172, 7, 192, 11 + sway, Color("#67a8ba"))
		return img)

static func hull() -> Texture2D:
	return PixelArt.cached_texture("opening/fishing/hull/v1", func() -> Image:
		var img := PixelArt.image(440, 180)
		PixelArt._fill_polygon(img, [Vector2i(20, 115), Vector2i(422, 109), Vector2i(380, 149), Vector2i(103, 165), Vector2i(52, 149)], Color("#514635"))
		PixelArt._fill_polygon(img, [Vector2i(30, 118), Vector2i(411, 113), Vector2i(376, 146), Vector2i(103, 160), Vector2i(57, 145)], Color("#cc913c"))
		PixelArt._fill_polygon(img, [Vector2i(37, 120), Vector2i(404, 116), Vector2i(380, 137), Vector2i(101, 149), Vector2i(57, 138)], Color("#edba50"))
		PixelArt.line(img, 41, 124, 397, 120, Color("#ffdc7f"))
		PixelArt.line(img, 60, 139, 379, 133, Color("#a77538"))
		PixelArt.line(img, 94, 154, 371, 142, Color("#f0bb54"))
		PixelArt.line(img, 113, 159, 362, 146, Color("#715437"))
		# Front rail masks boots; it never masks faces or the fishing hands.
		PixelArt.line(img, 23, 112, 418, 107, Color("#503f32"))
		PixelArt.line(img, 24, 110, 416, 105, Color("#ffe099"))
		for x in [45, 143, 280, 371]:
			PixelArt.rect(img, x, 101, 3, 15, Color("#65482f"))
			PixelArt.rect(img, x, 100, 3, 2, Color("#ffe0a0"))
		PixelArt.line(img, 406, 111, 434, 92, Color("#60462e"))
		PixelArt.line(img, 407, 110, 433, 92, Color("#b8955f"))
		# Smaller, boat-proportioned nameplate; hand-painted five-by-seven lettering.
		PixelArt.rect(img, 179, 126, 81, 21, Color("#ad813d"))
		PixelArt.rect(img, 181, 127, 77, 18, Color("#f7d777"))
		for letter in LETTERS.size():
			for y in 7:
				for x in 5:
					if LETTERS[letter][y][x] == "1":
						PixelArt.rect(img, 184 + letter * 12 + x * 2, 129 + y * 2, 2, 2, Color("#285665"))
		for x in [78, 306, 356]:
			PixelArt.rect(img, x, 125, 6, 5, Color("#7d683c"))
			PixelArt.hline(img, x + 1, 125, 4, Color("#e9c16a"))
		return img)

static func bucket() -> Texture2D:
	return PixelArt.cached_texture("opening/fishing/bucket/v1", func() -> Image:
		var img := PixelArt.image(22, 24)
		PixelArt.line(img, 4, 12, 6, 3, Color("#c4c6a9"))
		PixelArt.line(img, 6, 3, 17, 4, Color("#c4c6a9"))
		PixelArt.line(img, 17, 4, 20, 12, Color("#c4c6a9"))
		PixelArt._fill_polygon(img, [Vector2i(2, 10), Vector2i(21, 10), Vector2i(18, 23), Vector2i(5, 23)], Color("#3b6264"))
		PixelArt.rect(img, 5, 12, 4, 8, Color("#71968b"))
		PixelArt.ellipse(img, 11, 10, 10, 3, Color("#b8c3a6"))
		PixelArt.ellipse(img, 11, 10, 7, 2, Color("#385d63"))
		return img)

static func hero(id: String, pose: int) -> Texture2D:
	return PixelArt.cached_texture("opening/fishing/%s/%d/v1" % [id, pose % 3], func() -> Image:
		var img := PixelArt.image(32, 48)
		var c := CharacterDB.get_character(id)
		var skin: Color = c.tint
		var hair: Color = c.hair
		var tunic: Color = c.accent
		if id == "mei_ling": tunic = Color("#4e7667")
		var outline := Color("#34474a")
		var seated := id == "mei_ling"
		var head_y := 16 if not seated else 21
		var torso_y := 25 if not seated else 30
		var blink := pose == 2
		# Purpose-built unarmed bodies; no edits to cached combat character pixels.
		if seated:
			PixelArt.rect(img, 9, 38, 16, 5, outline)
			PixelArt.rect(img, 10, 39, 13, 3, Color("#34424b"))
			PixelArt.rect(img, 21, 40, 4, 7, Color("#34424b"))
			PixelArt.rect(img, 19, 46, 7, 2, Color("#4d4038"))
			PixelArt.rect(img, 9, 41, 4, 6, Color("#34424b"))
			PixelArt.rect(img, 7, 46, 7, 2, Color("#4d4038"))
		else:
			for x in [11, 20]:
				PixelArt.rect(img, x, 36, 5, 11, outline)
				PixelArt.rect(img, x + 1, 37, 3, 9, Color("#354047"))
				PixelArt.rect(img, x - 1, 46, 7, 2, Color("#514439"))
		PixelArt.rect(img, 9, torso_y - 1, 17, 14 if not seated else 10, outline)
		PixelArt.rect(img, 10, torso_y, 15, 12 if not seated else 8, tunic.darkened(0.12))
		PixelArt.rect(img, 11, torso_y, 5, 10 if not seated else 7, tunic.lightened(0.14))
		PixelArt.hline(img, 10, torso_y + 10 if not seated else torso_y + 6, 15, Color("#63503b"))
		PixelArt.rect(img, 17, torso_y + 9 if not seated else torso_y + 5, 3, 2, Color("#deb96c"))
		PixelArt.rect(img, 14, head_y + 7, 6, 4, skin.darkened(0.12))
		PixelArt.ellipse(img, 17, head_y, 8, 9, outline)
		PixelArt.ellipse(img, 17, head_y, 7, 8, skin)
		PixelArt.ellipse(img, 15, head_y - 4, 7, 5, hair)
		PixelArt.rect(img, 9, head_y - 3, 4, 9, hair)
		PixelArt.hline(img, 12, head_y - 8, 7, hair.lightened(0.14))
		var look := 1 if pose == 1 and id != "arjun" else 0
		PixelArt.rect(img, 22 + look, head_y, 2, 2, skin.darkened(0.12))
		PixelArt.hline(img, 18, head_y - 1, 3, outline)
		if not blink: PixelArt.px(img, 20, head_y, Color("#f6e6be"))
		PixelArt.hline(img, 19, head_y + 4, 3, Color("#9b6554"))
		if id == "arjun":
			PixelArt.rect(img, 13, head_y + 4, 8, 4, hair)
			PixelArt.hline(img, 17, head_y + 7, 5, hair)
		if seated:
			PixelArt.rect(img, 8, head_y - 3, 3, 16, hair)
			PixelArt.rect(img, 7, head_y + 2, 4, 2, Color("#d47b8c"))
			PixelArt.line(img, 24, torso_y + 1, 22 if pose != 1 else 18, torso_y + 7, tunic.lightened(0.2))
			PixelArt.rect(img, 20 if pose != 1 else 17, torso_y + 6, 4, 3, skin)
		elif id == "arjun":
			var lift := 1 if pose == 1 else 0
			PixelArt.line(img, 22, 27, 26, 31 - lift, outline)
			PixelArt.line(img, 23, 27, 26, 30 - lift, tunic.lightened(0.15))
			PixelArt.rect(img, 25, 29 - lift, 4, 3, skin)
			PixelArt.line(img, 12, 28, 17, 34, tunic.lightened(0.1))
			PixelArt.line(img, 17, 34, 24, 31 - lift, skin)
		else:
			PixelArt.rect(img, 23, 27, 3, 8, tunic.lightened(0.12))
			PixelArt.rect(img, 23, 35, 3, 3, skin)
			PixelArt.line(img, 11, 28, 8, 35, tunic.lightened(0.12))
			PixelArt.rect(img, 7, 35, 3, 3, skin)
		PixelArt.hline(img, 12, torso_y, 10, tunic.lightened(0.35))
		return img)
