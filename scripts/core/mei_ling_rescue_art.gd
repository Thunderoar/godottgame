class_name MeiLingRescueArt
extends RefCounted
## Shared citadel prison and finite unarmed poses. Never repaint cached source art.
const FRAME := Vector2i(480, 224)
enum Pose { IDLE, ALERT, WALK_A, WALK_B, REACH, POINT }

static func hall(restored: bool) -> Texture2D:
	return PixelArt.cached_texture("mei_rescue/hall/%s/v1" % restored, func() -> Image:
		var img := PixelArt.image(FRAME.x, FRAME.y)
		img.fill(Color("#29343c") if restored else Color("#242434"))
		for row in 7:
			for col in 15:
				var x := col * 36 - (18 if row % 2 else 0)
				var y := row * 19
				PixelArt.rect(img, x + 1, y + 1, 34, 17, Color("#50565a") if restored else Color("#42404f"))
		for x in [20, 192, 444]:
			PixelArt.rect(img, x, 7, 15, 139, Color("#252b35"))
			PixelArt.rect(img, x + 3, 10, 9, 128, Color("#6a6969") if restored else Color("#5c5264"))
			PixelArt.rect(img, x - 4, 8, 23, 7, Color("#8d8380"))
			PixelArt.rect(img, x - 5, 137, 25, 8, Color("#887a7d"))
		for x in [76, 242]:
			PixelArt.ellipse(img, x + 22, 38, 23, 23, Color("#1b2531"))
			PixelArt.rect(img, x - 1, 38, 47, 63, Color("#1b2531"))
			PixelArt.ellipse(img, x + 22, 38, 18, 18, Color("#849b8a") if restored else Color("#63456e"))
			PixelArt.rect(img, x + 4, 38, 37, 58, Color("#849b8a") if restored else Color("#63456e"))
			PixelArt.vline(img, x + 21, 20, 77, Color("#c4b997") if restored else Color("#a382a3"))
			for y in [47, 70]: PixelArt.hline(img, x + 4, y, 37, Color("#b4ac91") if restored else Color("#957592"))
		PixelArt.rect(img, 0, 146, 480, 78, Color("#57554f") if restored else Color("#514555"))
		for y in range(150, 224, 15):
			for x in range(-20, 480, 40):
				PixelArt.rect(img, x + (20 if y % 2 else 0), y, 37, 12, Color("#777465") if restored else Color("#6b596c"))
		PixelArt.rect(img, 0, 141, 480, 5, Color("#b5a789") if restored else Color("#847080"))
		# Inlaid road channels lead to the same return-rift plinth in both shots.
		for x in range(24, 457, 16):
			PixelArt.rect(img, x, 203, 12, 2, Color("#d6bd82") if restored else Color("#8c5a83"))
		for x in [57, 286]:
			PixelArt.rect(img, x, 114, 8, 23, Color("#322e36"))
			PixelArt.ellipse(img, x + 4, 111, 5, 7, Color("#f4d493") if restored else Color("#b573b4"))
			PixelArt.ellipse(img, x + 4, 110, 2, 4, Color("#fff0c4") if restored else Color("#e4b7d8"))
		return img)

static func prison_back() -> Texture2D:
	return PixelArt.cached_texture("mei_rescue/prison/back/v1", func() -> Image:
		var img := PixelArt.image(96, 128)
		PixelArt.ellipse(img, 48, 33, 46, 32, Color("#292b37"))
		PixelArt.rect(img, 2, 33, 92, 91, Color("#292b37"))
		PixelArt.ellipse(img, 48, 34, 39, 26, Color("#77717c"))
		PixelArt.rect(img, 9, 34, 78, 87, Color("#77717c"))
		PixelArt.ellipse(img, 48, 37, 32, 22, Color("#242937"))
		PixelArt.rect(img, 16, 37, 64, 78, Color("#242937"))
		for x in [6, 82]:
			for y in range(45, 118, 14): PixelArt.rect(img, x, y, 9, 11, Color("#a09599"))
		for x in [23, 42, 61]: PixelArt.line(img, x, 13, x + 3, 23, Color("#b8a7ac"))
		PixelArt.rect(img, 0, 119, 96, 7, Color("#b4a292"))
		PixelArt.hline(img, 4, 120, 88, Color("#e0c6a5"))
		return img)

static func gate() -> Texture2D:
	return PixelArt.cached_texture("mei_rescue/prison/gate/v1", func() -> Image:
		var img := PixelArt.image(64, 84)
		for x in range(3, 64, 10):
			PixelArt.rect(img, x, 0, 4, 84, Color("#333445"))
			PixelArt.vline(img, x + 1, 0, 83, Color("#a69cae"))
		for y in [5, 64]:
			PixelArt.rect(img, 0, y, 64, 5, Color("#5d536b"))
			PixelArt.hline(img, 0, y, 64, Color("#b7a0b7"))
		return img)

static func hero(id: String, pose: int, left: bool = false) -> Texture2D:
	return PixelArt.cached_texture("mei_rescue/hero/%s/%d/%s/v1" % [id, pose, left], func() -> Image:
		var img := PixelArt.image(48, 52)
		var source := OpeningCaptureArt.hero(id, 0) if id == "mei_ling" else OpeningFishingArt.hero(id, 0)
		img.blit_rect(source.get_image(), Rect2i(0, 0, 32, 48), Vector2i(8, 4))
		var c := CharacterDB.get_character(id)
		var tunic: Color = Color("#4e7667") if id == "mei_ling" else c.accent
		if pose == Pose.ALERT:
			var head := img.get_region(Rect2i(12,8,25,20))
			PixelArt.rect(img,12,8,25,20,Color.TRANSPARENT)
			img.blit_rect(head,Rect2i(0,0,25,20),Vector2i(12,6))
		if pose in [Pose.REACH, Pose.POINT, Pose.ALERT]:
			PixelArt.rect(img, 31, 31, 9, 15, Color.TRANSPARENT)
			var hand_y := 31 if pose == Pose.REACH else (25 if pose == Pose.POINT else 28)
			PixelArt.line(img, 32, 32, 38, hand_y + 1, tunic.lightened(0.18))
			PixelArt.line(img, 33, 33, 39, hand_y + 2, tunic)
			PixelArt.rect(img, 38, hand_y, 5, 3, c.tint)
		if pose in [Pose.WALK_A, Pose.WALK_B]:
			PixelArt.rect(img, 17, 42, 21, 10, Color.TRANSPARENT)
			var stride := 3 if pose == Pose.WALK_A else -3
			for pair in [[20, stride], [29, -stride]]:
				PixelArt.rect(img, int(pair[0]), 41, 5, 10, Color("#2b3d47"))
				PixelArt.rect(img, int(pair[0]) + int(pair[1]), 49, 7, 3, Color("#5e4b3b"))
		if left: img.flip_x()
		return img)

static func village() -> Texture2D:
	return PixelArt.cached_texture("mei_rescue/village/v1", func() -> Image:
		var img := PixelArt.image(FRAME.x, FRAME.y)
		img.fill(Color("#d5d6b8"))
		for i in 4:
			PixelArt.ellipse(img, 35 + i * 145, 111, 105, 64, Color("#607e63"))
			PixelArt.ellipse(img, 68 + i * 125, 126, 80, 46, Color("#819268"))
		PixelArt.rect(img, 0, 146, 480, 78, Color("#759065"))
		PixelArt.rect(img, 0, 178, 480, 32, Color("#c3af7f"))
		# A BESUT timber home, warm windows and an open door behind the welcoming party.
		PixelArt.rect(img, 273, 67, 142, 102, Color("#725a42"))
		for y in range(72, 166, 8): PixelArt.hline(img, 278, y, 132, Color("#aa8a59"))
		PixelArt._fill_polygon(img, [Vector2i(257, 74), Vector2i(293, 30), Vector2i(392, 30), Vector2i(431, 74)], Color("#3e5148"))
		for y in range(39, 72, 7): PixelArt.hline(img, 293 - (y - 39), y, 100 + (y - 39) * 2, Color("#87906a"))
		PixelArt.rect(img, 333, 115, 27, 54, Color("#304344"))
		for x in [287, 376]:
			PixelArt.rect(img, x, 97, 23, 28, Color("#403e35"))
			PixelArt.rect(img, x + 2, 99, 19, 24, Color("#f0cb89"))
			PixelArt.vline(img, x + 11, 99, 24, Color("#8b744d"))
			PixelArt.hline(img, x + 2, 110, 19, Color("#8b744d"))
		PixelArt.rect(img, 267, 167, 156, 6, Color("#d3b583"))
		for x in [440, 459, 478]:
			PixelArt.rect(img, x, 139, 5, 34, Color("#b49c69"))
		for y in [148, 160]: PixelArt.hline(img, 437, y, 43, Color("#b49c69"))
		for i in 32: PixelArt.rect(img, posmod(i * 53, 474), 212 + i % 9, 3, 1, Color("#a7b77b"))
		return img)

static func draw_prison(canvas: CanvasItem, feet: Vector2, opening: float, captive: bool, seal_alpha: float, cracks: float = 0.0, captive_pose: int = Pose.IDLE) -> void:
	canvas.draw_texture(prison_back(), feet - Vector2(48, 126))
	if captive:
		canvas.draw_texture(hero("mei_ling", captive_pose, true), feet - Vector2(24, 62))
	var remaining := roundf(84 * (1.0 - clampf(opening, 0, 1)))
	if remaining > 0:
		canvas.draw_texture_rect_region(gate(), Rect2(feet + Vector2(-32, -94), Vector2(64, remaining)), Rect2(0, 84 - remaining, 64, remaining))
	if seal_alpha > 0:
		var centre := feet + Vector2(0, -55)
		var color := Color("#dd94ce")
		color.a = seal_alpha
		canvas.draw_arc(centre, 19, 0, TAU, 24, color, 2, false)
		canvas.draw_polyline(PackedVector2Array([centre + Vector2(0,-14), centre + Vector2(11,0), centre + Vector2(0,14), centre + Vector2(-11,0), centre + Vector2(0,-14)]), color, 2, false)
		if cracks > 0:
			canvas.draw_polyline(PackedVector2Array([centre + Vector2(-7,-19),centre + Vector2(2,-8),centre + Vector2(-4,0),centre + Vector2(8,9),centre + Vector2(5,19)]), Color(0.98,0.87,0.72,cracks), 2, false)
