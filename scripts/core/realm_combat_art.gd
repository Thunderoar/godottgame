class_name RealmCombatArt
extends RefCounted
## Staff/lantern and stone mantle silhouettes share the realm's pixel palette.

static func guard_texture(profile: String, frame: int) -> Texture2D:
	if profile == "imp": return PixelArt.enemy_texture("minion_chaos",false,frame%2)
	return PixelArt.cached_texture("realm_guard_v1_%s_%d" % [profile,frame],func() -> Image:
		var img := PixelArt.image(48,64)
		var ink := Color("#252235")
		var cloth := Color("#74617f")
		var pale := Color("#ae91af")
		var light := Color("#f6da9b") if frame != 3 else Color("#9f8295")
		var bob := frame%2
		PixelArt.ellipse(img,24,57,16,4,Color("#29273b"))
		if profile == "watcher":
			img.fill_rect(Rect2i(13,30+bob,20,23),ink)
			img.fill_rect(Rect2i(16,30+bob,14,22),cloth)
			img.fill_rect(Rect2i(19,34+bob,3,17),pale)
			PixelArt.ellipse(img,23,25+bob,11,14,ink)
			PixelArt.ellipse(img,23,23+bob,8,11,cloth)
			img.fill_rect(Rect2i(17,22+bob,13,7),ink)
			img.fill_rect(Rect2i(19,24+bob,3,2),light)
			img.fill_rect(Rect2i(26,24+bob,3,2),light)
			img.fill_rect(Rect2i(37,13,3,42),pale)
			img.fill_rect(Rect2i(30,11,10,3),pale)
			img.fill_rect(Rect2i(28,17,12,17),ink)
			img.fill_rect(Rect2i(31,20,6,10),light)
			if frame == 2:
				PixelArt.ellipse_outline(img,34,25,10,12,Color("#ffe8ad"))
		else:
			# A broad, low stone mantle, with one readable cross rune.
			img.fill_rect(Rect2i(8,31+bob,32,23),ink)
			img.fill_rect(Rect2i(11,29+bob,26,22),cloth)
			img.fill_rect(Rect2i(6,35+bob,7,12),pale)
			img.fill_rect(Rect2i(35,35+bob,7,12),pale)
			PixelArt.ellipse(img,24,26+bob,12,10,ink)
			img.fill_rect(Rect2i(14,21+bob,20,7),pale)
			img.fill_rect(Rect2i(18,28+bob,3,2),light)
			img.fill_rect(Rect2i(28,28+bob,3,2),light)
			img.fill_rect(Rect2i(22,34+bob,4,14),light)
			img.fill_rect(Rect2i(17,39+bob,14,4),light)
			if frame == 2: PixelArt.ellipse_outline(img,24,40+bob,13,13,Color("#e0b7ed"))
		return img)

static func cover_texture() -> Texture2D:
	return PixelArt.cached_texture("realm_watchpost_cover_v1",func() -> Image:
		var img := PixelArt.image(48,48)
		PixelArt.ellipse(img,24,42,20,5,Color("#25283a"))
		img.fill_rect(Rect2i(8,13,31,28),Color("#302f44"))
		img.fill_rect(Rect2i(11,14,25,25),Color("#74687d"))
		img.fill_rect(Rect2i(9,10,29,7),Color("#a18e9c"))
		img.fill_rect(Rect2i(12,21,23,2),Color("#484151"))
		img.fill_rect(Rect2i(12,30,23,2),Color("#484151"))
		img.fill_rect(Rect2i(22,17,2,5),Color("#484151"))
		img.fill_rect(Rect2i(29,23,2,7),Color("#484151"))
		img.fill_rect(Rect2i(16,32,2,6),Color("#484151"))
		return img)
