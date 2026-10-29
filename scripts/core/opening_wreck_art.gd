class_name OpeningWreckArt
extends RefCounted
## Original pixel fragments and strike frames. Source images are always copied.
const STRIKE_FRAMES := 24

static func piece_owner(x: int, y: int) -> int:
	var tooth := [0, 2, -2, 3, -1, 1][posmod(y / 3, 6)] as int
	return 0 if x < 145 + tooth else (1 if x < 290 - tooth else 2)

static func piece(layer: String, index: int) -> Texture2D:
	return PixelArt.cached_texture("opening/wreck/%s/%d/v1" % [layer, index], func() -> Image:
		var texture: Texture2D = OpeningFishingArt.hull()
		if layer == "deck": texture = OpeningFishingArt.deck()
		elif layer == "rigging": texture = OpeningFishingArt.rigging(0)
		var img := texture.get_image().duplicate() as Image
		for y in img.get_height():
			for x in img.get_width():
				if piece_owner(x, y) != index:
					img.set_pixel(x, y, Color.TRANSPARENT)
				elif layer == "hull" and y > 110 and img.get_pixel(x, y).a > 0:
					# Exposed pale timber follows the same jagged partition on both sides.
					if piece_owner(maxi(0, x - 1), y) != index or piece_owner(mini(439, x + 1), y) != index:
						img.set_pixel(x, y, Color("#f3d18a"))
		return img)

static func strike_tip(frame: int) -> Vector2:
	var f := clampi(frame, 0, STRIKE_FRAMES)
	if f <= 12: return Vector2(447, 97).lerp(Vector2(260, 18), float(f) / 12.0).round()
	if f <= 18: return Vector2(260, 18).lerp(Vector2(147, 173), float(f - 12) / 6.0).round()
	return Vector2(147, 173).lerp(Vector2(342, 181), float(f - 18) / 6.0).round()

static func strike(frame: int) -> Texture2D:
	return PixelArt.cached_texture("opening/wreck/strike/%d/v1" % frame, func() -> Image:
		var img := PixelArt.image(480, 224)
		var start := Vector2(416, 163)
		var tip := strike_tip(frame)
		var throw := clampf(float(frame - 12) / 6.0, 0, 1)
		var control := Vector2(450, 114).lerp(Vector2(443, 55), throw)
		var reach := tip + Vector2(24, -28).lerp(Vector2(75, -78), throw)
		if frame > 18:
			# Retract into the sea, not across the king's eyes or the friends' faces.
			var settle := float(frame - 18) / 6.0
			control = control.lerp(Vector2(455, 196), settle)
			reach = tip + Vector2(75, -78).lerp(Vector2(27, 23), settle)
		var spine := PackedVector2Array()
		for i in 17: spine.append(start.bezier_interpolate(control, reach, tip, float(i) / 16.0).round())
		for layer in 2:
			var left: Array[Vector2i] = []
			var right: Array[Vector2i] = []
			for i in spine.size():
				var direction := spine[mini(i + 1, 16)] - spine[maxi(0, i - 1)]
				var normal := direction.normalized().orthogonal()
				var radius := lerpf(13, 4, float(i) / 16.0) + (2 if layer == 0 else 0)
				left.append(Vector2i((spine[i] + normal * radius).round()))
				right.push_front(Vector2i((spine[i] - normal * radius).round()))
			left.append_array(right)
			PixelArt._fill_polygon(img, left, Color("#192e47") if layer == 0 else Color("#74618b"))
		for i in range(1, 16):
			var a := spine[i] + Vector2(-2, -3)
			var b := spine[i + 1] + Vector2(-2, -3)
			PixelArt.line(img, int(a.x), int(a.y), int(b.x), int(b.y), Color("#b09aa9"))
			if i % 2 == 0:
				PixelArt.ellipse(img, int(spine[i].x + 2), int(spine[i].y + 2), 3, 2, Color("#d2b6a5"))
				PixelArt.px(img, int(spine[i].x + 2), int(spine[i].y + 2), Color("#765976"))
		return img)

static func foam(frame: int) -> Texture2D:
	return PixelArt.cached_texture("opening/wreck/foam/%d/v1" % frame, func() -> Image:
		var img := PixelArt.image(112, 52)
		for i in 9:
			var x := 10 + i * 11
			var h := 7 + posmod(i * 7, 19) + frame * 2
			PixelArt._fill_polygon(img, [Vector2i(x - 6, 43), Vector2i(x - 3, 42 - h), Vector2i(x + 2, 45 - h), Vector2i(x + 7, 44)], Color("#8bbab9"))
			PixelArt.line(img, x - 3, 42 - h, x, 47 - h, Color("#d9e1c6"))
		for i in 6:
			PixelArt.hline(img, 7 + i * 15, 44 + i % 3 * 2, 21, Color("#b9d7c8"))
		return img)

static func hero(id: String, pose: int) -> Texture2D:
	return PixelArt.cached_texture("opening/wreck/%s/%d/v1" % [id, pose], func() -> Image:
		var img := OpeningKrakenArt.hero(id, 2).get_image().duplicate() as Image
		var c := CharacterDB.get_character(id)
		var y := 32 if id == "mei_ling" else 28
		var shirt: Color = Color("#618875") if id == "mei_ling" else c.accent.lightened(0.15)
		if pose == 1:
			var right := id == "adam"
			PixelArt.line(img, 23 if right else 11, y, 29 if right else 5, y - 3, shirt)
			PixelArt.line(img, 29 if right else 5, y - 3, 31 if right else 1, y - 6, c.tint)
			PixelArt.rect(img, 29 if right else 0, y - 8, 3, 3, c.tint)
			if not right:
				var eye_y := 21 if id == "mei_ling" else 16
				PixelArt.rect(img, 19, eye_y, 3, 2, Color("#f6e4bc"))
				PixelArt.px(img, 19, eye_y, Color("#293e4b"))
		else:
			PixelArt.line(img, 11, y, 9, y + 7, shirt)
			PixelArt.line(img, 23, y, 26, y + 7, shirt)
			PixelArt.rect(img, 8, y + 6, 4, 3, c.tint)
			PixelArt.rect(img, 25, y + 6, 4, 3, c.tint)
		return img)
