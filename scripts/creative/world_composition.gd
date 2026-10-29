class_name WorldComposition
extends RefCounted
## Low-cost static workspaces and ecological clusters; never consumes Lobby RNG.

static func build(lobby: Lobby, layout: WorldLayout) -> void:
	var holder := Node2D.new()
	holder.name = "VillageComposition"
	lobby.add_child(holder)
	for entry in layout.scenery:
		var asset := str(entry.get("asset", "baskets"))
		var zone := str(entry.get("zone", "transition"))
		var category := "domestic" if zone == "homestead" and asset in ["bench", "bucket"] else asset
		if not layout.allows(zone, category): continue
		var parent_id := str(entry.get("parent", ""))
		var owner_node: Node2D = holder
		if not parent_id.is_empty():
			for node in lobby.get_children():
				if (node is SettlementPlaceable and node.placeable_id == parent_id) or (node is Node2D and str(node.get_meta("layout_anchor", "")) == parent_id):
					owner_node = node
					break
		var at: Vector2 = entry.get("position", Vector2.ZERO)
		if not parent_id.is_empty() and owner_node == holder:
			at += layout.position_of(parent_id)
		# Customized layouts may hide an obstructing accessory without moving the save.
		# Keep the node so moving the owner clear can reveal it again.
		_add_prop(owner_node, entry, at)
		(owner_node.get_child(-1) as CanvasItem).visible = layout.scenery_fits(entry)
	# Existing tree silhouettes lead the composition. Understory is clustered at
	# the sides of trunks, never on a road, doorway, combat clearing or sea.
	var rng := RandomNumberGenerator.new()
	rng.seed = 90817
	for tree in lobby._forest_trees:
		var zone := layout.zone_at(tree.position)
		if zone not in ["forest_edge", "forest_interior"]: continue
		for i in 2:
			var at := tree.position + Vector2(rng.randf_range(-1.2, 1.2), rng.randf_range(-0.3, 0.65))
			if not allowed(lobby, layout, at, 0.45): continue
			var plant := Sprite2D.new()
			plant.texture = PixelArt.cached_texture("monsoon/undergrowth/%d" % (i * 2), func() -> Image: return MonsoonArt.undergrowth(i * 2))
			plant.centered = false
			plant.offset = Vector2(-20, -32)
			plant.scale = Vector2.ONE * PixelArt.PX * rng.randf_range(0.7, 1.05)
			plant.position = at
			plant.z_index = 3
			holder.add_child(plant)

static func allowed(lobby: Lobby, layout: WorldLayout, at: Vector2, radius: float) -> bool:
	if not Lobby.MAP_RECT.grow(-0.5).has_point(at) or layout.reserved(at, radius): return false
	if at.x < WorldTerrain.OCEAN_WIDTH_PIXELS * PixelArt.PX and at.y > WorldTerrain.shore_y(at.x) - 0.7: return false
	if lobby._authored_map:
		for layer in ["Terrain", "Paths", "Water", "Shore", "Collision"]:
			if not lobby._authored_map.cell(layer, Vector2i(at.floor())).is_empty(): return false
	return true

static func _add_prop(parent: Node2D, data: Dictionary, at: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.name = str(data.get("id", "Workspace"))
	sprite.texture = texture(str(data.get("asset", "baskets")))
	sprite.centered = false
	var size := sprite.texture.get_size()
	sprite.offset = Vector2(-size.x * 0.5, -size.y)
	sprite.scale = Vector2.ONE * PixelArt.PX * float(data.get("scale", 1.0))
	sprite.position = at
	sprite.z_index = 5 if not parent is SettlementPlaceable else 1
	sprite.add_to_group("village_workspace")
	sprite.set_meta("scenery_id", str(data.get("id", "")))
	if data.get("asset", "") == "flowers": sprite.add_to_group("flowers")
	parent.add_child(sprite)

static func texture(kind: String) -> Texture2D:
	if kind == "flowers": return PixelArt.coastal_prop("flowers")
	if kind in KampungArt.KINDS: return KampungArt.texture(kind)
	var imported := AssetRegistry.get_texture("village/" + kind)
	if imported: return imported
	if kind not in ["rope", "tools", "feed", "driftwood", "bench"]: return MonsoonArt.prop(kind)
	return PixelArt.cached_texture("village/" + kind, func() -> Image: return MonsoonArt.workspace(kind))


static func refresh(lobby: Lobby, layout: WorldLayout) -> void:
	var records := {}
	for entry in layout.scenery: records[str(entry.get("id", ""))] = entry
	for node in lobby.get_tree().get_nodes_in_group("village_workspace"):
		if not is_instance_valid(node) or not lobby.is_ancestor_of(node): continue
		var id := str(node.get_meta("scenery_id", ""))
		if records.has(id): node.visible = layout.scenery_fits(records[id])
