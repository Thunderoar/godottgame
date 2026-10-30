class_name FireArt
extends RefCounted
## Cached pixel poses for a creature crossing a small, temporary ember tear.

static func body(pose: String = "rest", frame: int = 0) -> Texture2D:
	if pose == "rest": return PixelArt.enemy_texture("fire", false, 0)
	return PixelArt.cached_texture("fire/arrival_v1/%s/%d" % [pose, posmod(frame, 2)], func() -> Image:
		var source := PixelArt.enemy_texture("fire", false, frame % 2).get_image()
		var img := PixelArt.image(32, 32)
		if pose == "core":
			PixelArt.ellipse(img, 16, 21, 3, 6, Color("#ffac35"))
			PixelArt.ellipse(img, 16, 22, 1, 3, Color("#ffe57b"))
			return img
		# Narrow silhouettes pass through the seam before the body gathers low.
		var width := 12 if pose == "cross" else (28 if pose == "settle" else 30)
		var height := 24 if pose == "settle" else 30
		var copy := source.duplicate() as Image
		copy.resize(width, height, Image.INTERPOLATE_NEAREST)
		img.blit_rect(copy, Rect2i(0, 0, width, height), Vector2i((32 - width) / 2, 32 - height))
		if pose == "notice":
			PixelArt.rect(img, 10, 20, 4, 3, PixelArt.OUTLINE)
			PixelArt.rect(img, 19, 20, 4, 3, PixelArt.OUTLINE)
		return img)

static func portal(frame: int) -> Texture2D:
	var phase := clampi(frame, 0, 7)
	return PixelArt.cached_texture("fire/portal_v1/%d" % phase, func() -> Image:
		var img := PixelArt.image(48, 52)
		if phase == 0:
			PixelArt.rect(img, 23, 24, 2, 3, Color("#ffe57b"))
			return img
		var width: int = [0, 2, 6, 12, 16, 14, 7, 2][phase]
		var height: int = [0, 13, 19, 22, 23, 22, 19, 9][phase]
		var outer: Array = []
		var inner: Array = []
		for i in 16:
			var a := float(i) * TAU / 16
			var rough := 1.0 + (0.08 if i % 3 == 0 else -0.03)
			outer.append(Vector2i(roundi(24 + cos(a) * width * rough), roundi(26 + sin(a) * height)))
			inner.append(Vector2i(roundi(24 + cos(a) * maxf(1, width - 3)), roundi(26 + sin(a) * maxf(2, height - 3))))
		PixelArt._fill_polygon(img, outer, Color("#913923"))
		PixelArt._fill_polygon(img, inner, Color("#211e2d"))
		for i in 16:
			var a := float(i) * TAU / 16
			var at := Vector2(24 + cos(a) * maxf(1, width - 1), 26 + sin(a) * (height - 1))
			PixelArt.rect(img, roundi(at.x), roundi(at.y), 2, 2, Color("#ffac35") if i % 3 else Color("#f8db83"))
		return img)
