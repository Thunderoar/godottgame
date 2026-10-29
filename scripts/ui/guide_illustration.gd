class_name GuideIllustration
extends Control
## Two visual equations on a paper page, with game sprites and pictograms.
var entry: Dictionary
var _ink := Color("#65513b")

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if custom_minimum_size.y <= 0:
		custom_minimum_size = Vector2(0, 260)
	resized.connect(queue_redraw)

func _draw() -> void:
	var left_width := size.x * 0.30
	draw_style_box(GameUI.style(Color("#ecdfbc"), Color("#9c8055"), 2, 0), Rect2(Vector2.ZERO, size))
	if bool(entry.get("memory_journal", false)):
		var read: Array = GameState.realm_progress().get("read_fragments", [])
		for i in RealmContentDB.FRAGMENTS.size():
			var at := Vector2(size.x * (float(i) + 0.5) / 3.0, size.y * 0.5)
			var texture := RealmContentArt.texture("memory")
			var dimensions := texture.get_size() * minf(76, size.y - 16) / texture.get_height()
			var found: bool = RealmContentDB.FRAGMENTS[i] in read
			draw_texture_rect(texture, Rect2(at - dimensions / 2, dimensions), false, Color.WHITE if found else Color("#667180"))
			if found: draw_circle(at + Vector2(0, size.y * 0.36), 3, Color("#9e7846"))
		return
	draw_line(Vector2(left_width, 14), Vector2(left_width, size.y - 14), Color("#b69a70"), 3)
	_picture(str(entry.get("actor", "npc:resident")), Vector2(left_width * 0.5, size.y * 0.49), minf(124, left_width - 35))
	var rows: Array = entry.get("rows", [])
	for row in rows.size():
		var y := size.y * (0.27 if row == 0 else 0.75)
		var start := left_width + 24
		var span := size.x - left_width - 48
		var line: Array = rows[row]
		for i in line.size():
			var centre := Vector2(start + span * (0.13 + i * 0.37), y)
			_picture(str(line[i]), centre, minf(76, span * 0.24))
			if i < line.size() - 1:
				_arrow(centre + Vector2(span * 0.16, 0), centre + Vector2(span * 0.22, 0))

func _arrow(a: Vector2, b: Vector2) -> void:
	draw_line(a, b, _ink, 3, true)
	draw_colored_polygon(PackedVector2Array([b + Vector2(4, 0), b + Vector2(-5, -5), b + Vector2(-5, 5)]), _ink)

func _texture(texture: Texture2D, centre: Vector2, extent: float) -> void:
	var dimensions := texture.get_size()
	var fitted := dimensions * extent / maxf(dimensions.x, dimensions.y)
	draw_texture_rect(texture, Rect2(centre - fitted / 2, fitted), false)

func _picture(id: String, at: Vector2, extent: float) -> void:
	if id.begins_with("realm_guard:"):
		_texture(RealmCombatArt.guard_texture(id.get_slice(":",1),0),at,extent)
		return
	if id.begins_with("hero:"):
		_texture(PixelArt.character_texture(id.get_slice(":", 1), 0), at, extent)
		return
	if id in ["turtle", "heart", "bomb", "kraken", "ship"]:
		var texture: Texture2D = CoastalArt.turtle_texture()
		match id:
			"heart": texture = CampaignArt.heart_texture()
			"bomb": texture = CampaignArt.bomb_texture()
			"kraken": texture = CampaignArt.kraken_texture()
			"ship": texture = PixelArt.ship_texture()
		_texture(texture, at, extent)
		return
	if id == "prison":
		_texture(KrakenArt.prison_texture(),at,extent)
		return
	if id == "trash_missed":
		_texture(PixelArt.rubbish_texture(),at,extent*0.7)
		_cross(at+Vector2(extent*0.23,-extent*0.25),extent*0.14)
		return
	if id == "fullness":
		draw_rect(Rect2(at-Vector2(extent*0.42,9),Vector2(extent*0.84,18)),Color("#a99c7d"))
		draw_rect(Rect2(at-Vector2(extent*0.42,9),Vector2(extent*0.7,18)),Color("#55a287"))
		return
	if id.begins_with("npc:"):
		_texture(PixelArt.npc_texture(id.get_slice(":", 1)), at, extent)
		return
	if id.begins_with("enemy_day:"):
		_texture(PixelArt.enemy_texture(id.get_slice(":", 1)), at, extent * 0.8)
		_picture("sun", at + Vector2(extent * 0.3, -extent * 0.3), extent * 0.4)
		return
	if id.begins_with("enemy:") or id.begins_with("boss:"):
		_texture(PixelArt.enemy_texture(id.get_slice(":", 1), id.begins_with("boss:")), at, extent)
		return
	if id.begins_with("time:"):
		draw_arc(at - Vector2(0, 9), extent * 0.28, 0, TAU, 24, _ink, 3, true)
		draw_line(at - Vector2(0, 9), at + Vector2(0, -extent * 0.22), _ink, 3)
		draw_string(ThemeDB.fallback_font, at + Vector2(-20, extent * 0.42), id.get_slice(":", 1), HORIZONTAL_ALIGNMENT_CENTER, 40, 17, _ink)
		return
	if id.begins_with("ability:"):
		var ability := id.get_slice(":", 1)
		_picture("bow" if ability in ["projectile", "projectile_charge"] else ("sword" if ability == "charge" else "hammer"), at, extent * 0.8)
		if ability in ["area", "slam", "projectile_charge"]:
			for i in 3:
				draw_arc(at, extent * (0.28 + i * 0.1), 0.1, PI - 0.1, 18, Color("#b45548"), 2, true)
		return
	match id:
		"house", "house_broken", "home_safe":
			_texture(PixelArt.house_texture(1 if id == "house_broken" else 3), at, extent)
			if id == "house_broken":
				_cross(at, extent * 0.3)
		"hut":
			_texture(PixelArt.roof_gun_texture(3), at, extent)
		"fence":
			_texture(PixelArt.fence_texture(3), at, extent)
		"tree", "tree_fire", "tree_heal", "sapling", "stump":
			var h := extent * (0.35 if id == "sapling" else 0.75)
			draw_rect(Rect2(at + Vector2(-4, -h * 0.1), Vector2(8, h * 0.65)), Color("#88603c"))
			if id != "stump":
				for offset in [Vector2(-0.17, 0), Vector2(0.17, 0), Vector2(0, -0.22)]:
					draw_circle(at + offset * h - Vector2(0, h * 0.1), h * 0.34, Color("#53834b"))
			if id == "tree_fire":
				_picture("flame", at + Vector2(12, 8), extent * 0.55)
			if id == "tree_heal":
				_plus(at + Vector2(20, -20), 8, Color("#358f65"))
		"flame":
			draw_colored_polygon(PackedVector2Array([at + Vector2(-extent * 0.25, extent * 0.3), at + Vector2(-extent * 0.3, 0), at + Vector2(-extent * 0.07, -extent * 0.15), at + Vector2(0, -extent * 0.4), at + Vector2(extent * 0.3, 0), at + Vector2(extent * 0.23, extent * 0.3)]), Color("#db6d36"))
			draw_circle(at + Vector2(0, extent * 0.15), extent * 0.13, Color("#ffd27b"))
		"water":
			for i in 3:
				var centre := at + Vector2((i - 1) * extent * 0.2, sin(i * 2.0) * 8)
				draw_circle(centre, extent * 0.1, Color("#399fc5"))
				draw_colored_polygon(PackedVector2Array([centre + Vector2(-extent * 0.1, 0), centre + Vector2(0, -extent * 0.2), centre + Vector2(extent * 0.1, 0)]), Color("#399fc5"))
		"sun":
			draw_circle(at, extent * 0.2, Color("#db9e36"))
			for i in 8:
				var direction := Vector2.from_angle(i * TAU / 8)
				draw_line(at + direction * extent * 0.27, at + direction * extent * 0.39, Color("#db9e36"), 3, true)
		"moon":
			draw_circle(at, extent * 0.3, Color("#51698c"))
			draw_circle(at + Vector2(extent * 0.14, -extent * 0.12), extent * 0.27, Color("#ecdfbc"))
		"hp_down", "hp_up":
			draw_rect(Rect2(at - Vector2(extent * 0.4, 8), Vector2(extent * 0.8, 16)), Color("#b2a483"))
			draw_rect(Rect2(at - Vector2(extent * 0.4, 8), Vector2(extent * (0.23 if id == "hp_down" else 0.75), 16)), Color("#bc5c55") if id == "hp_down" else Color("#4f9a68"))
			if id == "hp_up":
				_plus(at + Vector2(0, -23), 8, Color("#358f65"))
			else:
				draw_line(at + Vector2(-8, -23), at + Vector2(8, -23), Color("#bc5c55"), 4)
		"bow":
			draw_arc(at - Vector2(extent * 0.1, 0), extent * 0.33, -PI * 0.45, PI * 0.45, 20, Color("#8e643b"), 4, true)
			draw_line(at + Vector2(-extent * 0.05, -extent * 0.33), at + Vector2(-extent * 0.05, extent * 0.33), _ink, 2)
			_texture(PixelArt.arrow_texture(), at, extent * 0.7)
		"path":
			for i in 4:
				_arrow(at + Vector2(-extent * 0.4 + i * extent * 0.22, 0), at + Vector2(-extent * 0.28 + i * extent * 0.22, 0))
		"dialogue":
			draw_rect(Rect2(at - Vector2(extent * 0.37, extent * 0.25), Vector2(extent * 0.74, extent * 0.45)), _ink, false, 3)
			for i in 3:
				draw_circle(at + Vector2((i - 1) * extent * 0.18, 0), 3, _ink)
			draw_line(at + Vector2(-extent * 0.2, extent * 0.2), at + Vector2(-extent * 0.3, extent * 0.4), _ink, 3)
		"university":
			_texture(PixelArt.house_texture(5), at, extent * 0.85)
			draw_string(ThemeDB.fallback_font, at + Vector2(-30, extent * 0.46), "UniSZA", HORIZONTAL_ALIGNMENT_CENTER, 60, 15, _ink)
		"grave":
			_texture(PixelArt.npc_texture("resident"), at, extent * 0.8)
			_cross(at, extent * 0.3)
		"touch":
			draw_arc(at, extent * 0.25, 0, TAU, 24, _ink, 3)
			draw_circle(at, extent * 0.1, Color("#c1976a"))
		"question", "call", "level_up":
			var mark := "?" if id == "question" else ("!" if id == "call" else "↑")
			draw_string(ThemeDB.fallback_font, at + Vector2(-22, 19), mark, HORIZONTAL_ALIGNMENT_CENTER, 44, 48, Color("#8f5c9d") if id == "question" else _ink)
		"workers":
			for i in 3:
				_texture(PixelArt.npc_texture(["water_keeper", "tree_planter", "construction_worker"][i]), at + Vector2((i - 1) * extent * 0.26, 0), extent * 0.67)
		"seed":
			draw_circle(at, extent * 0.12, Color("#815a37"))
			draw_arc(at + Vector2(8, -10), 10, 0, PI, 12, Color("#528b4b"), 4)
		"pet":
			_texture(PixelArt.pet_texture("ember"), at, extent)
		"player":
			_texture(PixelArt.character_texture("adam", 0), at, extent)
		"trash":
			_texture(PixelArt.rubbish_texture(), at, extent * 0.7)
		"net":
			_texture(PixelArt.net_texture(), at, extent)
		"horse", "goat":
			_texture(PixelArt.animal_texture(id), at, extent)
		"garden":
			_texture(PixelArt.garden_texture(), at, extent)
		"shop":
			_texture(PixelArt.stall_texture("equipment"), at, extent)
		"sea", "fish":
			for i in 3:
				draw_arc(at + Vector2((i - 1) * extent * 0.23, 5), extent * 0.16, 0.1, PI - 0.1, 12, Color("#43849c"), 3)
			if id == "fish":
				_draw_fish(at - Vector2(0, 14), extent)
		_:
			var icon: String = str({"potion": "health_potion", "food": "food", "pack": "backpack"}.get(id, id))
			_texture(PixelArt.icon(str(icon), 32), at, extent * 0.7)

func _plus(at: Vector2, extent: float, color: Color) -> void:
	draw_line(at - Vector2(extent, 0), at + Vector2(extent, 0), color, 4)
	draw_line(at - Vector2(0, extent), at + Vector2(0, extent), color, 4)

func _cross(at: Vector2, extent: float) -> void:
	draw_line(at - Vector2(extent, extent), at + Vector2(extent, extent), Color("#b34f47"), 4)
	draw_line(at + Vector2(-extent, extent), at + Vector2(extent, -extent), Color("#b34f47"), 4)

func _draw_fish(at: Vector2, extent: float) -> void:
	draw_circle(at, extent * 0.12, Color("#8b9b83"))
	draw_colored_polygon(PackedVector2Array([at + Vector2(extent * 0.1, 0), at + Vector2(extent * 0.25, -extent * 0.1), at + Vector2(extent * 0.25, extent * 0.1)]), Color("#8b9b83"))
