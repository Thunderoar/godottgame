class_name RealmContentArt
extends RefCounted
## Tiny, readable silhouettes with static clues at every quality setting.

static func texture(kind: String) -> Texture2D:
	return PixelArt.cached_texture("twilight_content_v1_" + kind, func() -> Image:
		var img := PixelArt.image(48, 56)
		var ink := Color("#222536")
		var gold := Color("#f3d99b")
		if kind == "waykeeper":
			# A hooded keeper, a warm face and a crooked lantern staff.
			PixelArt.ellipse(img,24,49,15,4,Color("#252c40"))
			PixelArt.ellipse(img,22,29,11,16,ink)
			img.fill_rect(Rect2i(12,29,21,18),Color("#676886"))
			img.fill_rect(Rect2i(15,34,4,12),Color("#9991ad"))
			PixelArt.ellipse(img,22,22,11,13,Color("#8f88a7"))
			PixelArt.ellipse(img,23,23,7,8,ink)
			img.fill_rect(Rect2i(19,22,3,2),gold)
			img.fill_rect(Rect2i(26,22,3,2),gold)
			img.fill_rect(Rect2i(23,32,3,13),Color("#d9bd83"))
			img.fill_rect(Rect2i(37,12,2,36),Color("#a48b72"))
			img.fill_rect(Rect2i(32,11,7,2),Color("#a48b72"))
			img.fill_rect(Rect2i(29,15,8,12),ink)
			img.fill_rect(Rect2i(31,17,4,7),gold)
			img.fill_rect(Rect2i(31,19,4,3),Color("#fff0ce"))
		elif kind == "memory":
			PixelArt.ellipse(img,24,47,18,5,Color("#262d3d"))
			img.fill_rect(Rect2i(11,20,26,27),ink)
			img.fill_rect(Rect2i(14,17,20,28),Color("#707288"))
			img.fill_rect(Rect2i(17,14,14,29),Color("#9293a3"))
			img.fill_rect(Rect2i(19,23,10,2),gold)
			img.fill_rect(Rect2i(23,20,2,17),gold)
			img.fill_rect(Rect2i(18,31,12,2),Color("#d0bb8e"))
			img.fill_rect(Rect2i(12,40,8,5),Color("#789187"))
		elif kind in ["cache", "cache_open"]:
			PixelArt.ellipse(img,24,40,22,12,ink)
			PixelArt.ellipse(img,24,35,21,12,Color("#766073"))
			PixelArt.ellipse(img,24,34,13,9,Color("#302c40"))
			img.fill_rect(Rect2i(4,39,8,8),Color("#8b7283"))
			img.fill_rect(Rect2i(36,38,8,9),Color("#8b7283"))
			img.fill_rect(Rect2i(13,43,24,4),Color("#574a61"))
			if kind == "cache":
				img.fill_rect(Rect2i(22,35,7,3),gold)
				img.fill_rect(Rect2i(25,32,2,9),Color("#fff1c9"))
			img.fill_rect(Rect2i(7,29,7,3),Color("#879884"))
		elif kind == "trunk":
			img.fill_rect(Rect2i(5,30,38,14),ink)
			img.fill_rect(Rect2i(5,28,37,12),Color("#756078"))
			for x in [11,17,24]: img.fill_rect(Rect2i(x,28,2,8),Color("#c5a5b5"))
			PixelArt.ellipse(img,38,34,5,6,Color("#aa8a99"))
		elif kind == "bloom":
			img.fill_rect(Rect2i(22,30,2,17),Color("#7c9b91"))
			for p in [Vector2i(19,27),Vector2i(26,30),Vector2i(22,23)]:
				PixelArt.ellipse(img,p.x,p.y,5,4,Color("#b9c4e2"))
				img.fill_rect(Rect2i(p.x-1,p.y-1,2,2),gold)
		elif kind == "tracks":
			for p in [Vector2i(15,34),Vector2i(32,22)]:
				PixelArt.ellipse(img,p.x,p.y,4,3,Color("#c8a9b5"))
				for x in [-3,0,3]: img.fill_rect(Rect2i(p.x+x-1,p.y-6,2,2),Color("#c8a9b5"))
		elif kind == "sign":
			img.fill_rect(Rect2i(22,20,3,29),Color("#776575"))
			img.fill_rect(Rect2i(8,20,26,8),Color("#b49a9d"))
			img.fill_rect(Rect2i(8,22,10,3),gold)
		else: # The companion's own clearing holds a resting wreath, not a second pet.
			PixelArt.ellipse_outline(img,24,38,17,8,Color("#b9c5a1"))
			for x in [13,24,35]: PixelArt.ellipse(img,x,35,3,3,gold)
		return img)
