class_name EquipmentArt
extends RefCounted
## Catalogue-specific sword silhouettes; colours describe appearance, not effects.

const SWORDS := ["rusty_sword", "iron_sword", "tideblade", "emberfang", "glacial_edge", "tempest_saber", "thorncrown_blade", "stormbreaker", "soulrender", "monarch_slayer"]
const COLOURS := ["#aa775c", "#b9cbd3", "#48cbdc", "#f39b4b", "#a5e5f7", "#75cbbb", "#85b964", "#d9b95e", "#b599dc", "#ffe2a0"]

static func icon(item_id: String, fallback: String = "sword") -> Texture2D:
	var index := SWORDS.find(item_id)
	if index < 0: return PixelArt.icon(fallback, 32)
	return PixelArt.cached_texture("catalogue_" + item_id, func() -> Image:
		var img := PixelArt.image(48, 48)
		var colour := Color(COLOURS[index])
		var outline := Color("#182b3b")
		var width := 2 + index / 3
		var top := 7 if index == 0 else 3
		# Broad late-game blades, a curved saber, a notched starter and thorn edges.
		for y in range(top, 33):
			var bend := maxi(0, (20 - y) / 5) if index == 5 else 0
			var half := mini(width, maxi(0, (y - top) / 2))
			if index == 4: half = mini(half, 2 + (y % 7) / 4)
			if index == 6 and y % 6 < 2: half += 2
			if index == 7 and y > 22: half += 1
			if index == 0 and y in [12, 13, 22]: half = 1
			PixelArt.hline(img, 24 + bend - half - 1, y, half * 2 + 3, outline)
			PixelArt.hline(img, 24 + bend - half, y, half * 2 + 1, colour)
			PixelArt.px(img, 24 + bend - half, y, colour.lightened(0.45))
			PixelArt.px(img, 25 + bend, y, colour.darkened(0.25))
		# Guards and grips have distinct proportions as well as colour.
		var guard := 6 + index % 4
		PixelArt.rect(img, 24 - guard, 32, guard * 2 + 1, 3, outline)
		PixelArt.hline(img, 25 - guard, 33, guard * 2 - 1, Color("#d9b66d"))
		PixelArt.rect(img, 22, 35, 5, 9, outline)
		PixelArt.rect(img, 23, 35, 3, 8, Color("#704838"))
		for y in [36, 39, 42]: PixelArt.hline(img, 23, y, 3, colour.darkened(0.25))
		PixelArt.rect(img, 22, 43, 5, 3, colour)
		if index >= 2:
			PixelArt.rect(img, 23, 30, 3, 4, colour.lightened(0.35))
		if index == 9:
			for x in [17, 24, 31]: PixelArt.line(img, x, 30, x, 33, Color("#ffe2a0"))
		return img)

static func upgrade_hint(item_id: String) -> String:
	var item := ItemDB.get_item(item_id)
	if item.get("kind", "") != "weapon": return ""
	var rank := GameState.weapon_rank(item_id)
	var power := GameState.weapon_attack(item_id)
	if rank >= GameState.MAX_WEAPON_UPGRADE: return "ATK %d · Fully upgraded" % power
	var base := int(item.get("attack", 0))
	var next := base + roundi(base * 0.2 * (rank + 1))
	return "Upgrade +%d: ATK %d → %d" % [rank + 1, power, next]


static func comparison(item_id: String) -> Dictionary:
	var item := ItemDB.get_item(item_id)
	if item.get("kind", "") != "weapon": return {}
	var equipped := GameState.equipped_item("weapon")
	var current := GameState.weapon_attack(equipped)
	var candidate := GameState.weapon_attack(item_id)
	var delta := candidate - current
	var compatible := str(item.get("style", "")) == GameState.character_weapon_style()
	var text := "Currently equipped" if equipped == item_id else "vs %s: ATK %d → %d (%+d)" % [ItemDB.name_of(equipped) if equipped != "" else "Unarmed", current, candidate, delta]
	if not compatible: text = "Different weapon discipline · Cannot equip"
	return {"text": text, "delta": delta, "current": current, "candidate": candidate, "compatible": compatible, "equipped": equipped == item_id}
