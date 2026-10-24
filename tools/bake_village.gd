extends Node
## Explicit source authoring operation. Never called by gameplay or test runners.
func _ready() -> void:
	if not TestEnvironment.require_isolation(): get_tree().quit(1); return
	if not "--write-village-bake" in OS.get_cmdline_user_args():
		print("Source write requires --write-village-bake; see docs/WORLD_LAYOUT.md")
		get_tree().quit(1)
		return
	var map := load("res://data/maps/village.tres") as AuthoredMap
	WorldPalette.select_for_map(map.palette)
	var layout := map.resolved_layout()
	DirAccess.make_dir_recursive_absolute("res://assets/authored/village")
	var result := WorldTerrain._make_terrain_image(layout).save_png("res://assets/authored/village/terrain.png")
	if result == OK:
		map.layout.terrain_bake_path = "res://assets/authored/village/terrain.png"
		map.layout.terrain_bake_hash = layout.signature()
		map.layout.terrain_palette_hash = WorldTerrain.palette_signature()
		var destination := map.layout.resource_path
		result = ResourceSaver.save(map.layout, destination) if not destination.is_empty() and not "::" in destination else ResourceSaver.save(map, "res://data/maps/village.tres")
	print("VILLAGE_BAKE ", "PASS" if result == OK else "FAIL", " geometry=", layout.signature(), " palette=", WorldTerrain.palette_signature())
	get_tree().quit(0 if result == OK else 1)
