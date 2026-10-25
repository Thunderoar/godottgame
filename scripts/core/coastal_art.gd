class_name CoastalArt
extends RefCounted
## Reproducible original pixels for the northern cliff and turtle journey.
static func cliff_texture() -> Texture2D:
	return PixelArt.cached_texture("coast/northern_cliff/v1", func() -> Image:
		var img := PixelArt.image(64, 64)
		img.fill(Color("#46535a"))
		for row in 4:
			var y := row * 16
			PixelArt.hline(img, 0, y + 14, 64, Color("#293941"))
			for col in 3:
				var x := posmod(col * 24 + (row % 2) * 12, 64)
				PixelArt.rect(img, x, y + 2, 20, 3, Color("#738582"))
				PixelArt.line(img, x, y, x, y + 14, Color("#304048"))
		PixelArt.rect(img, 0, 0, 64, 6, Color("#6d8d52"))
		return img)

static func turtle_texture(open_mouth: bool = false, stroke: int = 0) -> Texture2D:
	return PixelArt.cached_texture("coast/turtle/%s/%d/v1" % [str(open_mouth), stroke % 2], func() -> Image:
		var img := PixelArt.image(96, 48)
		var flipper_y := 34 if stroke % 2 == 0 else 29
		PixelArt.ellipse(img, 24, flipper_y, 13, 7, Color("#5da58b"))
		PixelArt.ellipse(img, 56, flipper_y, 13, 7, Color("#5da58b"))
		PixelArt.ellipse(img, 41, 24, 30, 17, Color("#243f44"))
		PixelArt.ellipse(img, 41, 21, 28, 16, Color("#3c7c68"))
		PixelArt.ellipse(img, 41, 18, 22, 11, Color("#6eab76"))
		for x in [25, 40, 55]:
			PixelArt.line(img, x, 9, x + 6, 30, Color("#356951"))
		PixelArt.hline(img, 19, 21, 45, Color("#356951"))
		PixelArt.ellipse(img, 77, 24, 14, 10, Color("#86c69b"))
		PixelArt.ellipse(img, 80, 20, 2, 3, Color("#102f3c"))
		PixelArt.px(img, 81, 19, Color.WHITE)
		if open_mouth:
			PixelArt.rect(img, 82, 26, 13, 8, Color("#172a38"))
			PixelArt.rect(img, 83, 32, 10, 2, Color("#df9382"))
		else:
			PixelArt.hline(img, 84, 28, 9, Color("#245452"))
		return img)

static func food_texture() -> Texture2D:
	return PixelArt.cached_texture("coast/turtle_food/v1", func() -> Image:
		var img := PixelArt.image(32, 24)
		PixelArt.ellipse(img, 17, 12, 11, 7, Color("#f4c96c"))
		PixelArt._fill_polygon(img, [Vector2i(7, 12), Vector2i(1, 5), Vector2i(1, 19)], Color("#de8859"))
		PixelArt.hline(img, 11, 8, 11, Color("#fff0b5"))
		PixelArt.ellipse(img, 24, 10, 1, 2, Color("#213c4a"))
		return img)
