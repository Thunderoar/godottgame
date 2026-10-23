class_name AuthoredMapRenderer
extends Node2D
## Additive authored overrides on the existing village; existing forest IDs untouched.
var definition: AuthoredMap
static var override_path := ""

static func selected_map() -> AuthoredMap:
	var path := override_path
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--map="):
			path = arg.trim_prefix("--map=")
	if path.is_empty():
		path = "res://data/maps/village.tres"
	return load(path) as AuthoredMap

static func tile_image(material: String, at: Vector2i, map: AuthoredMap, layer: String) -> Image:
	var img := Image.create_empty(32, 32, false, Image.FORMAT_RGBA8)
	var color := WorldPalette.color(material) if material != "blocked" else Color(0.8, 0.2, 0.2, 0.3)
	img.fill(color)
	if layer in ["Decoration", "Vegetation", "Foreground"]:
		img.fill(Color.TRANSPARENT)
		var prop := PixelArt.coastal_prop("flowers" if material == "flower" else "bush").get_image().duplicate() as Image
		prop.resize(32, 32, Image.INTERPOLATE_NEAREST)
		return prop
	# Deterministic material grain, then feathered edges toward existing neighbours.
	var rng := RandomNumberGenerator.new()
	rng.seed = map.seed_value + at.x * 7919 + at.y * 104729
	for i in 5:
		var p := Vector2i(rng.randi_range(2, 29), rng.randi_range(2, 29))
		img.fill_rect(Rect2i(p, Vector2i(3, 2)), color.lightened(0.055) if i % 2 else color.darkened(0.035))
	for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var other := map.cell(layer, at + direction)
		if other == material:
			continue
		var neighbour := WorldPalette.color(other) if not other.is_empty() else WorldPalette.color("grass")
		if material.begins_with("sea") and other.is_empty():
			neighbour = WorldPalette.color("sand")
		for length in 32:
			var band := 2 + int(sin(float(length + at.x * 32 + at.y * 13) * 0.55) * 1.5)
			for depth in band:
				var p := Vector2i(depth if direction.x < 0 else 31 - depth, length) if direction.x != 0 else Vector2i(length, depth if direction.y < 0 else 31 - depth)
				img.set_pixelv(p, neighbour.lerp(color, float(depth + 1) / float(band + 1)))
	return img

func _ready() -> void:
	if definition == null:
		return
	# One TileMapLayer per populated authoring layer. Build only used tile variants.
	for layer in AuthoredMap.LAYERS:
		var cells: Dictionary = definition.layers.get(layer, {})
		if cells.is_empty(): continue
		if layer == "Collision":
			_add_cell_collisions(cells)
			continue
		var tile_layer := TileMapLayer.new()
		tile_layer.name = layer
		tile_layer.scale = Vector2.ONE * PixelArt.PX
		tile_layer.z_as_relative = false
		tile_layer.z_index = -998 + AuthoredMap.LAYERS.find(layer) if layer in ["Terrain", "Paths", "Water", "Shore"] else (8 if layer == "Foreground" else 2)
		var tiles := TileSet.new()
		tiles.tile_size = Vector2i(32, 32)
		var atlas := TileSetAtlasSource.new()
		atlas.texture_region_size = Vector2i(32, 32)
		var variants := {}
		var cell_variants := {}
		var images: Array[Image] = []
		for at in cells:
			var material := definition.cell(layer, at)
			var key := material
			for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				key += ":" + definition.cell(layer, at + direction)
			if not variants.has(key):
				variants[key] = images.size()
				images.append(tile_image(material, at, definition, layer))
			cell_variants[at] = variants[key]
		var sheet := Image.create_empty(32 * mini(16, images.size()), 32 * int(ceil(images.size() / 16.0)), false, Image.FORMAT_RGBA8)
		for i in images.size():
			var coordinate := Vector2i(i % 16, int(i / 16))
			sheet.blit_rect(images[i], Rect2i(0, 0, 32, 32), coordinate * 32)
		atlas.texture = ImageTexture.create_from_image(sheet)
		for i in images.size(): atlas.create_tile(Vector2i(i % 16, int(i / 16)))
		tiles.add_source(atlas, 0)
		tile_layer.tile_set = tiles
		for at in cells:
			var i := int(cell_variants[at])
			tile_layer.set_cell(at, 0, Vector2i(i % 16, int(i / 16)))
		add_child(tile_layer)
		if layer == "Water": _add_cell_collisions(cells)
	for data in definition.objects:
		if data.has("base_id"):
			_apply_base_override(data)
			continue
		var is_tree: bool = str(data.get("asset", "")) == "tree" and data.get("kind", "prop") != "decoration"
		var holder: Node2D = ForestTree.new() if is_tree else Node2D.new()
		if holder is ForestTree:
			holder.tree_id = str(data.get("id", ""))
			holder.max_health = int(data.get("metadata", {}).get("health", 100))
		holder.name = str(data.get("id", "AuthoredObject"))
		holder.position = data.get("position", Vector2.ZERO)
		holder.set_meta("authored_id", data.get("id", ""))
		holder.set_meta("metadata", data.get("metadata", {}))
		holder.z_index = int(data.get("depth", 5))
		holder.rotation = float(data.get("rotation", 0.0))
		var sprite := AuthoredSprite.new()
		sprite.configure(str(data.get("asset", "")))
		sprite.scale = Vector2.ONE * PixelArt.PX * float(data.get("scale", 1.0))
		holder.add_child(sprite)
		if holder is ForestTree:
			holder.register_visual(sprite)
			var lobby := get_parent() as Lobby
			if lobby:
				lobby._forest_trees.append(holder)
				holder.felled.connect(lobby._on_forest_tree_felled)
		if data.get("blocking", false):
			_add_collision(Vector2.ZERO, data.get("footprint", Vector2(0.7, 0.5)), holder)
		add_child(holder)
		holder.z_index = int(data.get("depth", 5))
		if data.get("interactive", false):
			var interaction := AuthoredInteraction.new()
			interaction.speaker = str(data.get("label", "Village detail"))
			interaction.prompt = "Inspect " + interaction.speaker
			interaction.lines = [str(data.get("metadata", {}).get("description", "A handcrafted detail of the seaside village."))]
			interaction.show_marker = false
			holder.add_child(interaction)
		if str(data.get("kind", "")) == "shop":
			var merchant := ShopNPC.new()
			merchant.shop_type = str(data.get("metadata", {}).get("shop_type", "potion"))
			merchant.npc_kind = "builder" if merchant.shop_type == "house" else merchant.shop_type
			merchant.npc_name = str(data.get("label", "Market neighbour"))
			merchant.position = Vector2(0, 0.7)
			holder.add_child(merchant)
		if str(data.get("kind", "")) in ["route", "spawn"]:
			holder.add_to_group("authored_" + str(data.kind))
			if data.kind == "route":
				for resident in get_tree().get_nodes_in_group("residents"):
					if resident.resident_name == str(data.get("metadata", {}).get("resident", "")):
						resident.waypoints.append(holder.global_position)

static func object_texture(id: String) -> Texture2D:
	var imported := AssetRegistry.get_texture(id)
	if imported:
		return imported
	match id:
		"tree": return PixelArt.authored_tree_texture()
		"monsoon/planter": return MonsoonArt.prop("planter")
		"house": return PixelArt.house_texture(1)
		"shop": return PixelArt.stall_texture("potion")
		"flowers", "bush", "bench", "rock": return PixelArt.coastal_prop(id)
		"fence": return PixelArt.fence_texture()
		"garden": return PixelArt.garden_texture()
		"sign": return PixelArt.besut_sign_texture()
		_: return PixelArt.icon(id)

func _add_collision(at: Vector2, size: Vector2, owner_node: Node = null) -> void:
	var body := StaticBody2D.new()
	body.name = "Body"
	body.collision_layer = 1
	body.position = at
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	shape.shape = rectangle
	body.add_child(shape)
	(owner_node if owner_node != null else self).add_child(body)


func _add_cell_collisions(cells: Dictionary) -> void:
	# Merge horizontal runs instead of adding one collision node per painted cell.
	for y in definition.size.y:
		var x := 0
		while x < definition.size.x:
			if not cells.has(Vector2i(x, y)):
				x += 1
				continue
			var start := x
			while x < definition.size.x and cells.has(Vector2i(x, y)): x += 1
			_add_collision(Vector2(start + (x - start) * 0.5, y + 0.5), Vector2(x - start, 1))


func _apply_base_override(data: Dictionary) -> void:
	var id := str(data.base_id)
	# Player layout has precedence over developer base placement.
	if GameState.data.get("settlement_layout", {}).has(id): return
	if id == "house" or id.begins_with("shop_"): return
	for group in ["placeable", "forest_tree"]:
		for node in get_tree().get_nodes_in_group(group):
			var source_id := str(node.placeable_id) if node is SettlementPlaceable else str(node.tree_id)
			if source_id != id: continue
			node.position = data.get("position", node.position)
			node.z_index = int(data.get("depth", node.z_index))
			node.rotation = float(data.get("rotation", 0.0))
			return
