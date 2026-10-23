@tool
class_name WorldPalette
extends Resource
## Semantic world/UI materials. Independent raster artwork is never recoloured.
@export var title := "Pantai • sunlit coast"
@export var world: Dictionary = {
	"grass": Color("78b75b"), "grass_light": Color("a7ce66"),
	"grass_shadow": Color("446f56"), "grass_warm": Color("c6b86f"),
	"sea_shallow": Color("59b8c2"), "sea_deep": Color("256780"),
	"sand": Color("f3d69a"), "wet_sand": Color("cfae76"),
	"path": Color("d9b77e"), "path_edge": Color("b79868"),
	"wood": Color("a86f4a"), "stone": Color("b5a78f"),
	"coral": Color("f37b65"), "gold": Color("f5c66e"),
	"flower": Color("f1a2bf"), "shadow": Color("283749"),
	"foam": Color("e7f5e7"), "roof": Color("c56d52")
}
@export var ui: Dictionary = {
	"panel": Color("203c43"), "raised": Color("2e4d51"),
	"border": Color("a88858"), "text": Color("fff1d8"),
	"muted": Color("b3c7ba"), "accent": Color("76c6bc")
}
static var active: WorldPalette
static var generation := 0

static func current() -> WorldPalette:
	if active == null:
		active = load("res://data/palettes/monsoon_afterglow.tres") as WorldPalette
	return active

static func color(role: String) -> Color:
	var materials := current().world
	if materials.has(role): return materials[role]
	# Older palettes remain valid: new roles derive from established materials.
	var fallback := {"leaf": "grass_shadow", "leaf_mint": "grass_light", "leaf_sun": "grass_warm", "leaf_deep": "grass_shadow", "fern": "grass", "sea_mid": "sea_shallow", "wood_shadow": "shadow", "sunlight": "gold", "cream": "sand", "lantern": "gold", "outline": "shadow"}
	return materials.get(fallback.get(role, role), Color.MAGENTA)

static func select_for_map(palette: WorldPalette) -> void:
	# Developer A/B preview only; no player preference or shared-resource mutation.
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--palette="):
			var path := argument.trim_prefix("--palette=")
			var preview := load(path) as WorldPalette if ResourceLoader.exists(path) else null
			if preview != null:
				use_palette(preview)
				return
	use_palette(palette if palette != null else current())


static func use_palette(palette: WorldPalette, force := false) -> void:
	if active == palette and not force: return
	active = palette
	generation += 1
	PixelArt.CACHE.clear()
	GameUI.invalidate()
