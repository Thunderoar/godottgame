class_name CampaignArt
extends RefCounted

static func heart_texture() -> Texture2D:
	return PixelArt.cached_texture("campaign/heart/v1", func() -> Image:
		var img := PixelArt.image(24, 24)
		PixelArt._fill_polygon(img, [Vector2i(2, 7), Vector2i(6, 2), Vector2i(11, 5), Vector2i(16, 2), Vector2i(22, 7), Vector2i(21, 13), Vector2i(12, 22), Vector2i(3, 13)], Color("#ff7298"))
		PixelArt.rect(img, 5, 5, 4, 3, Color("#ffe4ed"))
		return img)

static func bomb_texture() -> Texture2D:
	return PixelArt.cached_texture("campaign/sea_bomb/v1", func() -> Image:
		var img := PixelArt.image(32, 32)
		PixelArt.ellipse(img, 16, 19, 12, 11, Color("#182430"))
		PixelArt.ellipse(img, 13, 15, 7, 5, Color("#46566a"))
		PixelArt.rect(img, 13, 4, 6, 6, Color("#8d6950"))
		PixelArt.line(img, 17, 5, 22, 1, Color("#ffd066"))
		PixelArt.rect(img, 22, 0, 4, 4, Color("#ff723b"))
		return img)

static func kraken_texture() -> Texture2D:
	return PixelArt.cached_texture("campaign/kraken_king/v1", func() -> Image:
		var img := PixelArt.image(128, 112)
		for i in 8:
			var x := 12 + i * 15
			PixelArt.ellipse(img, x, 82 + i % 2 * 8, 11, 20, Color("#704b95"))
			PixelArt.ellipse(img, x, 87 + i % 2 * 8, 4, 12, Color("#b583ba"))
		PixelArt.ellipse(img, 64, 49, 40, 37, Color("#65408a"))
		PixelArt.ellipse(img, 61, 40, 31, 24, Color("#8e63ac"))
		for x in [44, 80]:
			PixelArt.ellipse(img, x, 51, 9, 8, Color("#ffe8a2"))
			PixelArt.ellipse(img, x + 2, 51, 3, 6, Color("#b43150"))
		PixelArt._fill_polygon(img, [Vector2i(38, 18), Vector2i(36, 2), Vector2i(53, 10), Vector2i(64, 0), Vector2i(76, 10), Vector2i(93, 2), Vector2i(90, 18)], Color("#eac779"))
		return img)
