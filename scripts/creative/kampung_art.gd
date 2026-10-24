@tool
class_name KampungArt
extends RefCounted
## Original small-scale timber, garden and sanctuary art. No reference pixels.
const KINDS := ["banana", "veranda", "clothesline", "wakaf", "drying_rack", "herbs", "parit", "trough", "garden_shed", "sanctuary_arch", "sentinel", "companion_stone", "moon_flower"]

static func texture(kind: String) -> Texture2D:
	var override := AssetRegistry.get_texture("village/" + kind)
	if override: return override
	return PixelArt.cached_texture("kampung/" + kind, func() -> Image: return draw(kind))

static func draw(kind: String) -> Image:
	var img := PixelArt.image(128, 112)
	var wood := WorldPalette.color("wood")
	var dark := WorldPalette.color("wood_shadow")
	var light := WorldPalette.color("cream")
	var roof := WorldPalette.color("roof")
	var mint := WorldPalette.color("leaf_mint")
	var jade := WorldPalette.color("grass_shadow")
	var stone := WorldPalette.color("stone")
	var ink := WorldPalette.color("outline")
	PixelArt.ellipse(img, 64, 105, 42, 5, Color(0.16, 0.25, 0.27, 0.15))
	match kind:
		"banana":
			for stem in [57, 66, 73]:
				PixelArt.line(img, stem, 103, 63, 47, dark)
				PixelArt.line(img, stem + 2, 103, 65, 47, wood)
			for i in 7:
				var end := Vector2(13 + i * 17, 51 + (i % 3) * 12)
				var origin := Vector2(64, 42 + i % 2 * 7)
				for t in range(1, 81):
					var f := t / 80.0
					var at := origin.lerp(end, f) + Vector2(0, -sin(f * PI) * 17)
					var span := int(sin(f * PI) * 10)
					PixelArt.rect(img, int(at.x), int(at.y) - span, 2, span * 2 + 1, jade if i % 2 else mint.darkened(0.18))
				PixelArt.line(img, int(origin.x), int(origin.y), int(end.x), int(end.y), mint)
			for i in 5: PixelArt.rect(img, 67 + i % 2 * 3, 62 + i * 3, 5, 4, WorldPalette.color("sunlight"))
		"veranda":
			# Open sided selasar: floor and rail behind the clear central steps.
			PixelArt.rect(img, 12, 76, 104, 19, dark)
			for y in range(78, 96, 4): PixelArt.hline(img, 14, y, 100, wood.lightened(0.12))
			for x in [17, 36, 89, 108]: PixelArt.rect(img, x, 65, 3, 30, dark)
			for x in [15, 87]: PixelArt.rect(img, x, 66, 26, 3, wood)
			for y in range(96, 106, 3): PixelArt.rect(img, 49 - (y - 96) / 3, y, 30 + (y - 96) / 3 * 2, 2, wood)
		"clothesline":
			for x in [17, 109]: PixelArt.rect(img, x, 47, 3, 56, dark)
			PixelArt.line(img, 18, 53, 65, 58, light.darkened(0.2))
			PixelArt.line(img, 65, 58, 110, 53, light.darkened(0.2))
			for i in 4:
				var x := 27 + i * 20
				var color := [mint, roof.lightened(0.25), light, WorldPalette.color("sea_deep")][i] as Color
				PixelArt.rect(img, x, 57, 14, 23 + i % 2 * 5, color)
				PixelArt.vline(img, x + 3, 59, 19, color.darkened(0.15))
		"wakaf", "garden_shed":
			var shed := kind == "garden_shed"
			for x in [27, 96]: PixelArt.rect(img, x, 53, 5, 50, dark)
			PixelArt.rect(img, 22, 91, 85, 8, wood)
			if shed:
				PixelArt.rect(img, 31, 58, 65, 34, dark)
				for x in range(33, 96, 7): PixelArt.rect(img, x, 61, 4, 29, wood)
			else:
				PixelArt.rect(img, 31, 83, 64, 6, wood)
				for x in [38, 87]: PixelArt.rect(img, x, 87, 4, 8, dark)
			for y in 35:
				var span := 34 + y * 2
				PixelArt.hline(img, 64 - span / 2, 24 + y, span, dark if y % 6 == 0 else roof)
			PixelArt.hline(img, 10, 60, 109, wood)
		"drying_rack":
			for x in [24, 98]: PixelArt.rect(img, x, 61, 4, 43, dark)
			PixelArt.rect(img, 19, 65, 88, 25, wood)
			for x in range(23, 103, 6): PixelArt.vline(img, x, 67, 20, dark)
			for i in 6:
				PixelArt.ellipse(img, 31 + i * 12, 76 + i % 2 * 5, 5, 2, WorldPalette.color("sea_deep"))
		"herbs":
			PixelArt.rect(img, 22, 91, 84, 11, dark)
			for i in 4:
				var x := 29 + i * 22
				PixelArt.rect(img, x, 77, 12, 15, roof.darkened(0.15))
				PixelArt.line(img, x + 6, 78, x + 6, 57, jade)
				for y in range(60, 77, 6): PixelArt.ellipse(img, x + (3 if y % 4 else 9), y, 5, 2, mint)
		"parit":
			PixelArt.rect(img, 11, 94, 106, 10, stone.darkened(0.3))
			PixelArt.rect(img, 13, 96, 102, 5, WorldPalette.color("sea_deep"))
			for x in range(12, 114, 13): PixelArt.rect(img, x, 92, 9, 12, stone)
		"trough":
			PixelArt.rect(img, 23, 84, 82, 18, dark)
			PixelArt.rect(img, 27, 86, 74, 7, WorldPalette.color("sea_shallow"))
			PixelArt.hline(img, 25, 84, 78, wood)
		"sanctuary_arch":
			# Framing at the sides leaves the entire central approach open.
			for x in [8, 109]:
				PixelArt.rect(img, x, 57, 11, 48, ink)
				PixelArt.rect(img, x + 2, 59, 7, 43, stone)
				PixelArt.rect(img, x - 3, 54, 17, 5, dark)
				PixelArt.rect(img, x + 4, 64, 2, 12, mint)
			PixelArt.rect(img, 7, 48, 114, 6, dark)
			PixelArt.rect(img, 12, 46, 104, 3, wood)
			for x in range(19, 113, 12): PixelArt.rect(img, x, 51, 5, 5, mint.darkened(0.3))
		"sentinel", "companion_stone":
			var pet := kind == "companion_stone"
			PixelArt.rect(img, 41, 97, 46, 8, ink)
			PixelArt.rect(img, 46, 66, 36, 31, stone.darkened(0.15))
			PixelArt.rect(img, 49, 68, 30, 25, stone)
			if pet:
				PixelArt.ellipse(img, 64, 65, 16, 14, stone)
				PixelArt.line(img, 49, 58, 48, 41, stone)
				PixelArt.line(img, 78, 58, 80, 41, stone)
				for x in [57, 70]: PixelArt.rect(img, x, 62, 3, 3, mint)
				PixelArt.ellipse(img, 64, 85, 8, 5, mint)
			else:
				PixelArt.rect(img, 52, 37, 24, 32, stone.darkened(0.1))
				PixelArt.rect(img, 56, 42, 16, 22, dark)
				PixelArt.line(img, 59, 86, 68, 72, mint)
				PixelArt.line(img, 59, 72, 68, 86, mint)
		"moon_flower":
			for i in 5:
				var x := 39 + i * 12
				PixelArt.line(img, 64, 103, x, 81 + i % 3 * 5, jade)
				PixelArt.ellipse(img, x, 80 + i % 3 * 5, 5, 3, WorldPalette.color("sea_shallow"))
				PixelArt.rect(img, x - 1, 77 + i % 3 * 5, 2, 3, light)
	return img
