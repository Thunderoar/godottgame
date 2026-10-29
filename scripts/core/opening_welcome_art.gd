class_name OpeningWelcomeArt
extends RefCounted
## A continuation of the rescue shore, extended into an inhabited village.
const SIZE := Vector2i(720, 224)

static func backdrop() -> Texture2D:
	return PixelArt.cached_texture("opening/welcome/backdrop/v1", func() -> Image:
		var img := PixelArt.image(SIZE.x, SIZE.y)
		# Preserve the entire established shore. The pan discovers land to its right.
		for row in 6:
			PixelArt.rect(img, 480, row * 16, 240, 16, Color(["#bdaca9", "#d2b8aa", "#e1c5a7", "#edd1ae", "#f4debc", "#f4e3c5"][row]))
		PixelArt._fill_polygon(img, [Vector2i(480, 93), Vector2i(515, 77), Vector2i(549, 87), Vector2i(594, 65), Vector2i(653, 81), Vector2i(720, 62), Vector2i(720, 146), Vector2i(480, 146)], Color("#788d7a"))
		PixelArt._fill_polygon(img, [Vector2i(480, 109), Vector2i(528, 93), Vector2i(571, 104), Vector2i(624, 83), Vector2i(720, 98), Vector2i(720, 158), Vector2i(480, 158)], Color("#597967"))
		PixelArt.rect(img, 480, 117, 240, 107, Color("#d7bb85"))
		PixelArt.rect(img, 480, 127, 240, 97, Color("#efd39a"))
		PixelArt._fill_polygon(img, [Vector2i(480, 99), Vector2i(720, 105), Vector2i(720, 161), Vector2i(656, 150), Vector2i(619, 144), Vector2i(480, 137)], Color("#637f55"))
		PixelArt._fill_polygon(img, [Vector2i(474, 224), Vector2i(510, 224), Vector2i(613, 144), Vector2i(590, 144)], Color("#d7bd86"))
		for i in 46:
			PixelArt.rect(img, 483 + posmod(i * 37, 231), 151 + posmod(i * 19, 71), 2 + i % 3, 1, Color("#c4a878"))
		# A timber home, open door and broad shaded porch: invitation, not a reward.
		for x in [555, 637]: PixelArt.rect(img, x, 112, 5, 35, Color("#584c3e"))
		PixelArt.rect(img, 546, 81, 108, 56, Color("#70563e"))
		for y in range(85, 136, 6): PixelArt.hline(img, 548, y, 104, Color("#a48354"))
		PixelArt._fill_polygon(img, [Vector2i(531, 84), Vector2i(559, 48), Vector2i(638, 48), Vector2i(668, 84)], Color("#3b4944"))
		PixelArt._fill_polygon(img, [Vector2i(537, 79), Vector2i(562, 51), Vector2i(635, 51), Vector2i(661, 79)], Color("#927b51"))
		for y in [58, 64, 70, 76]: PixelArt.hline(img, 562 - (y - 58), y, 73 + (y - 58) * 2, Color("#b99c68"))
		PixelArt.rect(img, 589, 101, 23, 36, Color("#354849"))
		PixelArt.rect(img, 591, 103, 19, 32, Color("#514d3b"))
		PixelArt.rect(img, 610, 100, 10, 37, Color("#b39561"))
		for x in [554, 625]:
			PixelArt.rect(img, x, 96, 20, 21, Color("#403f36"))
			PixelArt.rect(img, x + 2, 98, 16, 17, Color("#e9bf75"))
			PixelArt.hline(img, x + 2, 105, 16, Color("#856d48"))
			PixelArt.vline(img, x + 9, 98, 17, Color("#856d48"))
		PixelArt.rect(img, 539, 136, 122, 6, Color("#ae9163"))
		PixelArt.rect(img, 581, 142, 40, 4, Color("#bfa273"))
		PixelArt.rect(img, 576, 146, 50, 4, Color("#ccb583"))
		# Forest, garden and low fence make the settlement feel tended and lived in.
		for x in [675, 704]:
			PixelArt.rect(img, x, 81, 7, 69, Color("#705b43"))
			for offset in [Vector2i(-15, -6), Vector2i(7, -19), Vector2i(27, 1)]:
				PixelArt.ellipse(img, x + offset.x, 76 + offset.y, 25, 22, Color("#355e49"))
				PixelArt.ellipse(img, x + offset.x - 3, 70 + offset.y, 19, 14, Color("#62865b"))
		for x in range(654, 719, 13):
			PixelArt.rect(img, x, 151, 4, 22, Color("#8a774f"))
			PixelArt.rect(img, x - 1, 150, 6, 3, Color("#c0a26c"))
		PixelArt.hline(img, 654, 158, 66, Color("#a58d5d"))
		for x in [523, 640, 650, 687]:
			PixelArt.rect(img, x, 150, 2, 8, Color("#537c50"))
			PixelArt.rect(img, x - 2, 148, 6, 3, Color("#deb582"))
		# blit_rect reads only; the shared rescue image is never resized or painted.
		img.blit_rect(OpeningRescueArt.backdrop().get_image(), Rect2i(0, 0, 480, 224), Vector2i.ZERO)
		return img)

static func planter_empty() -> Texture2D:
	return PixelArt.cached_texture("opening/welcome/planter_empty/v1", func() -> Image:
		# Rebuild the uncluttered base pose; painting over the cloth leaves a tray shape.
		var source := PixelArt.npc_texture("tree_planter").get_image().duplicate() as Image
		source.resize(32, 48, Image.INTERPOLATE_NEAREST)
		var img := PixelArt.image(40, 52)
		img.blit_rect(source, Rect2i(0, 0, 32, 48), Vector2i(4, 4))
		return img)

static func cloth() -> Texture2D:
	return PixelArt.cached_texture("opening/welcome/cloth/v1", func() -> Image:
		return OpeningRescueArt.villager("tree_planter", true).get_image().get_region(Rect2i(6, 32, 18, 12)))

static func guide() -> Texture2D:
	return PixelArt.cached_texture("opening/welcome/guide/v1", func() -> Image:
		var img := OpeningRescueArt.villager("water_keeper", false).get_image().duplicate() as Image
		PixelArt.line(img, 27, 29, 34, 24, Color("#78bdce"))
		PixelArt.line(img, 34, 24, 39, 23, Color("#d9b18b"))
		return img)

static func adam_step(frame: int) -> Texture2D:
	return PixelArt.cached_texture("opening/welcome/adam_step/%d/v1" % frame, func() -> Image:
		var img := OpeningRescueArt.adam(0).get_image().duplicate() as Image
		PixelArt.rect(img, 9, 37, 20, 11, Color.TRANSPARENT)
		for i in 2:
			var x := 11 + i * 9 + (1 if i == frame else -1)
			var lift := 2 if i == frame else 0
			PixelArt.rect(img, x, 37, 5, 10 - lift, Color("#33434a"))
			PixelArt.rect(img, x - 1, 45 - lift, 7, 3, Color("#66513d"))
		return img)

static func host() -> Texture2D:
	return PixelArt.cached_texture("opening/welcome/host/v1", func() -> Image:
		var img := OpeningRescueArt.villager("builder", true).get_image().duplicate() as Image
		PixelArt.line(img, 11, 29, 5, 24, Color("#a8c4d6"))
		PixelArt.line(img, 5, 24, 3, 17, Color("#d9b18b"))
		PixelArt.rect(img, 1, 14, 4, 5, Color("#d9b18b"))
		return img)
