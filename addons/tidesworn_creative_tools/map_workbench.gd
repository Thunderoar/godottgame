@tool
extends VBoxContainer
## Editor-only scene browser, spatial inspector and non-destructive canvas gestures.
const W := preload("res://addons/tidesworn_creative_tools/widgets.gd")
const KINDS := ["anchors", "routes", "zones", "scenery", "activities"]
const LABELS := ["Buildings & anchors", "Roads", "Districts", "Scenery", "Workpoints"]
const CELL := 8.0
var panel: Control
var scene: Tree
var search: LineEdit
var category: OptionButton
var assets: ItemList
var asset_search: LineEdit
var inspector: VBoxContainer
var fields: Dictionary = {}
var heading: Label
var help: Label
var coordinates: Label
var problems: ItemList
var layer_list: Tree
var inspector_tabs: TabContainer
var kind := ""
var identity := ""
var point := -1
var pending := ""
var _scene_key := ""
var _inspector_key := ""
var _building := false
var _before: Dictionary = {}
var _origin := Vector2.ZERO
var _delta := Vector2.ZERO
var _drag_point := -1
var _thumbnails: Dictionary = {}
var _new_type: OptionButton
var _last_map := 0
var carry_district := false

func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(tabs)
	var browse := VBoxContainer.new()
	browse.name = "Scene"
	tabs.add_child(browse)
	search = W.entry(browse, "Find a building, road, district…")
	search.text_changed.connect(func(_text: String) -> void: _rebuild_scene())
	category = W.option(browse, ["Everything"] + LABELS + ["Objects", "Base trees & props"])
	category.item_selected.connect(func(index: int) -> void:
		if index >= 1 and index <= KINDS.size():
			panel.spatial_kind.select(index - 1)
			panel._spatial_entries()
		panel.tool.select(11)
		_rebuild_scene()
		panel.refresh())
	scene = Tree.new()
	scene.hide_root = true
	scene.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scene.custom_minimum_size.y = 180
	scene.item_selected.connect(_scene_selected)
	scene.item_activated.connect(frame_selection)
	browse.add_child(scene)
	_new_type = W.option(browse, ["Landmark / commons", "Road", "District", "Scenery"])
	W.button(browse, "Create on canvas…", func() -> void:
		pending = "create"
		panel.tool.select(11)
		panel.studio.report("Click the map to create " + _new_type.get_item_text(_new_type.selected) + ". Esc cancels."))
	var palette := VBoxContainer.new()
	palette.name = "Assets"
	tabs.add_child(palette)
	asset_search = W.entry(palette, "Search props or imported art…")
	asset_search.text_changed.connect(func(_text: String) -> void: _rebuild_assets())
	assets = ItemList.new()
	assets.size_flags_vertical = Control.SIZE_EXPAND_FILL
	assets.fixed_icon_size = Vector2i(36, 36)
	assets.item_selected.connect(func(index: int) -> void:
		clear_selection()
		panel.asset.text = str(assets.get_item_metadata(index))
		panel.object_label.text = panel.asset.text.get_file().capitalize()
		panel.metadata.text = "{}"
		panel.scale_value.value = 1
		panel.blocking.button_pressed = false
		panel.interactive.button_pressed = false
		panel.tool.select(7)
		panel._lock_base_properties(false)
		panel.object_controls.show()
		panel.studio.report("Place " + panel.asset.text + " by clicking the map. V returns to selection."))
	palette.add_child(assets)
	W.button(palette, "Refresh imported art", func() -> void: _thumbnails.clear(); _rebuild_assets())
	W.label(palette, "Select an asset, then click to place.\nOriginal props and registered art.")
	var layers := VBoxContainer.new()
	layers.name = "Layers"
	tabs.add_child(layers)
	layer_list = Tree.new()
	layer_list.columns = 3
	layer_list.column_titles_visible = true
	layer_list.set_column_title(0, "Layer")
	layer_list.set_column_title(1, "Show")
	layer_list.set_column_title(2, "Lock")
	layer_list.set_column_expand(1, false)
	layer_list.set_column_expand(2, false)
	layer_list.set_column_custom_minimum_width(1, 38)
	layer_list.set_column_custom_minimum_width(2, 38)
	layer_list.hide_root = true
	layer_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layer_list.item_edited.connect(_layer_edited)
	layer_list.item_selected.connect(func() -> void:
		if _building: return
		var item := layer_list.get_selected()
		if item:
			panel.layer.select(AuthoredMap.LAYERS.find(item.get_metadata(0)))
			panel.refresh())
	layers.add_child(layer_list)
	W.label(layers, "Show affects this canvas only.
Locks protect paint strokes.
Both are undoable editor settings.")
	coordinates = W.label(self, "V Select  •  F Frame  •  Home Fit")
	coordinates.add_theme_font_size_override("font_size", 11)
	_rebuild_assets()

func document() -> AuthoredMap:
	return panel.map as AuthoredMap

func layout() -> WorldLayout:
	return document().resolved_layout()

func build_inspector(parent: Control) -> void:
	inspector_tabs = TabContainer.new()
	parent.add_child(inspector_tabs)
	var edit := VBoxContainer.new()
	edit.name = "Inspector"
	inspector_tabs.add_child(edit)
	heading = W.label(edit, "Select a village feature")
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help = W.label(edit, "Click buildings directly. Choose Roads or Districts to edit their shapes.")
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.custom_minimum_size.x = 235
	help.add_theme_font_size_override("font_size", 12)
	inspector = VBoxContainer.new()
	edit.add_child(inspector)
	var validation := VBoxContainer.new()
	validation.name = "Issues"
	inspector_tabs.add_child(validation)
	W.button(validation, "Check map", panel._validate)
	problems = ItemList.new()
	problems.custom_minimum_size = Vector2(230, 180)
	problems.item_selected.connect(_problem_selected)
	validation.add_child(problems)
	W.label(validation, "Select an issue to locate its feature.\nPreview always uses isolated progress.")

func refresh() -> void:
	if scene == null or inspector == null: return
	if _last_map != document().get_instance_id():
		_last_map = document().get_instance_id()
		_scene_key = ""
		_inspector_key = ""
	var key := str(hash(document().snapshot())) + search.text + str(category.selected) + kind + identity
	if key != _scene_key:
		_rebuild_scene()
		_rebuild_layers()
		_scene_key = key
	var inspector_key := str(_last_map) + kind + identity + str(point)
	if inspector_key != _inspector_key:
		_rebuild_inspector()
		_inspector_key = inspector_key
	panel.object_controls.visible = kind in ["objects", "base"] or panel.tool.selected == 7
	_draw_selection()

func clear_selection() -> void:
	cancel_drag()
	kind = ""
	identity = ""
	point = -1
	_inspector_key = ""

func _rebuild_scene() -> void:
	if scene == null: return
	_building = true
	var collapsed := {}
	var old := scene.get_root()
	if old:
		for child in old.get_children(): collapsed[child.get_text(0)] = child.collapsed
	scene.clear()
	var root := scene.create_item()
	var selected_item: TreeItem
	var spatial := layout()
	var collections := KINDS + ["objects", "base"]
	for c in collections.size():
		if category.selected > 0 and category.selected != c + 1: continue
		var label: String = (LABELS + ["Authored objects", "Base trees & props"])[c]
		var branch := scene.create_item(root)
		branch.set_text(0, label)
		branch.set_selectable(0, false)
		branch.collapsed = bool(collapsed.get(label, c >= 3)) if search.text.is_empty() else false
		var entries: Array = spatial.get(collections[c]) if c < KINDS.size() else (document().objects if c == KINDS.size() else panel.base.objects)
		for entry: Dictionary in entries:
			if collections[c] == "base" and not spatial.anchor(str(entry.get("base_id", ""))).is_empty(): continue
			var id := str(entry.get("id", ""))
			if not search.text.is_empty() and not (id + " " + str(entry.get("label", ""))).to_lower().contains(search.text.to_lower()): continue
			var item := scene.create_item(branch)
			item.set_text(0, str(entry.get("label", "")) + " · " + id if not str(entry.get("label", "")).is_empty() else id)
			item.set_tooltip_text(0, str(entry.get("label", id)))
			item.set_metadata(0, {"kind": collections[c], "id": id})
			if kind == collections[c] and identity == id:
				branch.collapsed = false
				item.select(0)
				selected_item = item
	_building = false
	if selected_item: scene.scroll_to_item(selected_item)

func _scene_selected() -> void:
	if _building: return
	var item := scene.get_selected()
	if item == null: return
	var data: Variant = item.get_metadata(0)
	if data is Dictionary: select_feature(str(data.kind), str(data.id))

func select_spatial() -> void:
	if panel.spatial_entry.selected < 0: return
	select_feature(panel.spatial_kind.get_item_text(panel.spatial_kind.selected), panel.spatial_entry.get_item_text(panel.spatial_entry.selected))

func select_feature(collection: String, id: String) -> void:
	kind = collection
	identity = id
	if category and category.selected > 0:
		category.select(KINDS.find(kind) + 1 if kind in KINDS else (6 if kind == "objects" else 7))
	point = -1
	panel.selected_object = -1
	if kind in KINDS:
		panel.spatial_kind.select(KINDS.find(kind))
		panel._spatial_entries()
		for i in panel.spatial_entry.item_count:
			if panel.spatial_entry.get_item_text(i) == identity: panel.spatial_entry.select(i)
	elif kind == "objects":
		for i in document().objects.size():
			if document().objects[i].id == identity: panel.selected_object = i
	panel.tool.select(11)
	_inspector_key = ""
	panel.refresh()

func selected(source: WorldLayout = null) -> Dictionary:
	if kind.is_empty(): return {}
	var entries: Array
	if kind == "objects": entries = document().objects
	elif kind == "base":
		for override in document().objects:
			if override.get("id", "") == identity: return override
		entries = panel.base.objects
	else: entries = (source if source else layout()).get(kind)
	for entry: Dictionary in entries:
		if str(entry.get("id", "")) == identity: return entry
	return {}

func _editable() -> Dictionary:
	if kind == "objects": return selected()
	if kind == "base":
		for entry in document().objects:
			if entry.get("id", "") == identity: return entry
		var copy := selected().duplicate(true)
		document().objects.append(copy)
		return copy
	for entry in panel._editable_layout().get(kind):
		if entry.get("id", "") == identity: return entry
	return {}

func _points(entry: Dictionary, spatial: WorldLayout) -> PackedVector2Array:
	if entry.is_empty(): return PackedVector2Array()
	match kind:
		"routes": return spatial.route_points(entry)
		"zones": return entry.get("polygon", PackedVector2Array())
		"activities": return PackedVector2Array(spatial.activity_points(entry))
		"scenery": return PackedVector2Array([spatial.scenery_position(entry)])
		_: return PackedVector2Array([entry.get("position", Vector2.ZERO)])

func _rebuild_inspector() -> void:
	for child in inspector.get_children():
		inspector.remove_child(child)
		child.queue_free()
	fields.clear()
	var entry := selected()
	heading.text = str(entry.get("label", identity)) if not str(entry.get("label", "")).is_empty() else (identity if not entry.is_empty() else "Select a village feature")
	heading.tooltip_text = identity
	help.text = "Click to select • drag to move • arrows nudge\nShift + arrows: 1 unit • Esc: cancel • Ctrl+D: duplicate"
	if entry.is_empty(): return
	_text("label", "Display name", str(entry.get("label", "")))
	var points := _points(entry, layout())
	if point >= points.size(): point = points.size() - 1
	var at := points[clampi(point, 0, points.size() - 1)] if not points.is_empty() else Vector2.ZERO
	if kind not in ["routes", "zones", "activities"]: _vector_fields("position", "World position", at)
	if kind == "routes":
		_choice("from", "From", _anchor_ids(), str(entry.get("from", "arrival")))
		_choice("to", "To", _anchor_ids(), str(entry.get("to", "market")))
		_number("width", "Road width", float(entry.get("width", 1.8)), 0.8, 8)
		_number("feather", "Soft edge", float(entry.get("feather", 0.140625)), 0.03, 1.5)
		_choice("material", "Surface", ["path", "stone", "sand", "grass"], str(entry.get("material", "path")))
		_choice("role", "Hierarchy", ["primary", "secondary", "informal"], str(entry.get("role", "secondary")))
		help.text = "Drag road bends; endpoints follow anchors. Use + Point to insert a bend."
	elif kind == "zones":
		_choice("material", "Ground", ["grass", "grass_light", "grass_shadow", "grass_warm", "path", "sand", "stone", "leaf_deep"], str(entry.get("material", "grass")))
		_number("density", "Plant density", float(entry.get("density", 0.1)), 0, 1)
		_number("feather", "Edge blend width", float(entry.get("feather", 1.0)), 0.1, 8)
		var default_strength := 0.22 if identity not in ["forest_interior", "market", "portal_grounds"] else 0.38
		_number("strength", "Ground tint", float(entry.get("strength", default_strength)), 0, 1)
		var carry := W.check(inspector, "Move district contents", carry_district)
		carry.toggled.connect(func(on: bool) -> void: carry_district = on)
		help.text = "Drag vertices to reshape, or drag inside to move. Carry contents to move the district together."
	elif kind == "activities":
		_choice("owner", "Workspace", _anchor_ids(), str(entry.get("owner", "arrival")))
		if point < 0: point = 0
		var record: Dictionary = entry.get("points", [])[clampi(point, 0, entry.get("points", []).size() - 1)] if not entry.get("points", []).is_empty() else {}
		_choice("point_anchor", "Point anchor", _anchor_ids(), str(record.get("anchor", "arrival")))
		help.text = "Drag purple workpoints. Local offsets follow their assigned anchors."
	elif kind in ["anchors", "scenery"]:
		_choice("zone", "District", _zone_ids(), str(entry.get("zone", "transition")))
		if kind == "anchors":
			_rect_fields("footprint", "Building footprint", entry.get("footprint", Rect2(-0.5, -0.5, 1, 1)))
			_vector_fields("approach", "Door / approach offset", entry.get("approach", Vector2.ZERO))
			_vector_fields("clearance", "Entrance clear space", entry.get("clearance", Vector2.ONE), true)
			_rect_fields("yard", "Maintained yard", entry.get("yard", Rect2()))
			help.text = "Drag a building or type coordinates. Doors and attached props follow."
		else:
			_text("asset", "Asset", str(entry.get("asset", "baskets")))
			_choice("parent", "Attached to", [""] + _anchor_ids(), str(entry.get("parent", "")))
			_number("scale", "Scale", float(entry.get("scale", 1)), 0.1, 4)
			_rect_fields("footprint", "Ground footprint", entry.get("footprint", Rect2(-0.45, -0.35, 0.9, 0.35)))
	if kind in ["zones", "activities"] or (kind == "routes" and point > 0 and point < points.size() - 1):
		_vector_fields("position", "World position" + (" • point %d" % (point + 1) if kind in ["zones", "activities", "routes"] else ""), at)
	W.button(inspector, "Apply changes", apply_properties)
	if kind in ["routes", "zones", "activities"]:
		var bar := W.row(inspector)
		W.button(bar, "+ Point…", func() -> void: pending = "point"; panel.tool.select(11); panel.studio.report("Click to insert a point. Esc cancels."))
		W.button(bar, "− Point", remove_point)
	var bar := W.row(inspector)
	var duplicate := W.button(bar, "Duplicate", duplicate_selection)
	duplicate.disabled = kind in ["anchors", "activities", "base"]
	var remove := W.button(bar, "Delete", delete_selection)
	remove.disabled = kind in ["base", "activities"] or (kind == "anchors" and not entry.get("editor_created", false))
	W.button(inspector, "Frame selection  [F]", frame_selection)
	if kind in ["objects", "base"]:
		panel._lock_base_properties(kind == "base" or entry.has("base_id"))
		panel.asset.text = str(entry.get("asset", "flowers"))
		panel.object_label.text = str(entry.get("label", ""))
		panel.depth.value = float(entry.get("depth", 5))
		panel.scale_value.value = float(entry.get("scale", 1))
		var footprint: Vector2 = entry.get("footprint", Vector2(0.7, 0.5))
		panel.footprint_x.value = footprint.x
		panel.footprint_y.value = footprint.y
		panel.blocking.button_pressed = bool(entry.get("blocking", false))
		panel.interactive.button_pressed = bool(entry.get("interactive", false))
		panel.metadata.text = JSON.stringify(entry.get("metadata", {}), "\t")

func _number(key: String, label: String, value: float, minimum := -128.0, maximum := 128.0) -> void:
	var row := W.row(inspector)
	var box := W.number(row, label, value, minimum, maximum)
	box.step = 0.01 if key == "feather" and minimum < 0.1 else 0.05
	fields[key] = box

func _text(key: String, label: String, value: String) -> void:
	W.label(inspector, label)
	fields[key] = W.entry(inspector, label, value)

func _choice(key: String, label: String, values: Array, value: String) -> void:
	W.label(inspector, label)
	var choices := values.duplicate()
	if not choices.has(value): choices.append(value)
	var box := W.option(inspector, choices)
	box.select(choices.find(value))
	fields[key] = box

func _vector_fields(key: String, label: String, value: Vector2, positive := false) -> void:
	W.label(inspector, label)
	var row := W.row(inspector)
	for axis in ["x", "y"]:
		var box := W.number(row, axis.to_upper(), value[axis], 0.1 if positive else -128, 128)
		box.step = 0.25
		fields[key + "_" + axis] = box

func _rect_fields(key: String, label: String, value: Rect2) -> void:
	_vector_fields(key + "_origin", label + " • offset", value.position)
	_vector_fields(key + "_size", "Size" + (" (0 disables yard)" if key == "yard" else ""), value.size)

func _vector(key: String) -> Vector2:
	return Vector2(fields[key + "_x"].value, fields[key + "_y"].value)

func _choice_value(key: String) -> String:
	var box: OptionButton = fields[key]
	return box.get_item_text(box.selected)

func _anchor_ids() -> Array:
	var ids: Array = []
	for entry in layout().anchors: ids.append(str(entry.id))
	return ids

func _zone_ids() -> Array:
	var ids: Array = []
	for entry in layout().zones: ids.append(str(entry.id))
	return ids

func apply_properties() -> void:
	if selected().is_empty(): return
	var before := document().snapshot()
	var entry := _editable()
	for key in ["zone", "from", "to", "material", "role", "owner", "parent"]:
		if fields.has(key): entry[key] = _choice_value(key)
	for key in ["width", "density", "scale", "feather", "strength"]:
		if fields.has(key): entry[key] = fields[key].value
	for key in ["label", "asset"]:
		if fields.has(key): entry[key] = fields[key].text
	for key in ["approach", "clearance"]:
		if fields.has(key + "_x"): entry[key] = _vector(key)
	for key in ["footprint", "yard"]:
		if fields.has(key + "_origin_x"):
			var size := _vector(key + "_size").max(Vector2.ZERO)
			entry[key] = Rect2(_vector(key + "_origin"), size)
	if kind == "activities" and point >= 0 and point < entry.get("points", []).size():
		entry.points[point].anchor = _choice_value("point_anchor")
	if fields.has("position_x"): _set_point(entry, _vector("position"), point)
	panel._commit(before, document().snapshot(), "Edit " + identity)
	_inspector_key = ""
	panel.refresh()

func _set_point(entry: Dictionary, at: Vector2, index: int) -> void:
	at = at.clamp(Vector2.ZERO, Vector2(document().size) - Vector2.ONE * 0.01)
	if kind == "routes":
		var points: PackedVector2Array = entry.get("via", PackedVector2Array())
		if index > 0 and index <= points.size(): points[index - 1] = at
		entry.via = points
	elif kind == "zones":
		var polygon: PackedVector2Array = entry.polygon
		if index >= 0 and index < polygon.size(): polygon[index] = at
		entry.polygon = polygon
	elif kind == "activities":
		if index >= 0 and index < entry.points.size(): entry.points[index].offset = at - layout().position_of(str(entry.points[index].anchor))
	elif kind == "scenery":
		entry.position = at - layout().position_of(str(entry.get("parent", "")))
	else:
		entry.position = at
		if kind == "anchors":
			var owner := str(entry.get("relative_to", ""))
			if not owner.is_empty(): entry.offset = at - layout().position_of(owner)
			# A previous developer override must not silently shadow this direct edit.
			for object in document().objects:
				if object.get("base_id", "") == identity: object.position = at

func _draw_selection() -> void:
	panel.canvas.edit_overlay.clear()
	var spatial := layout()
	var entry := selected(spatial)
	if entry.is_empty(): panel.canvas.queue_redraw(); return
	var points := _points(entry, spatial)
	var moved := points.duplicate()
	if not _before.is_empty():
		if _drag_point >= 0 and _drag_point < moved.size(): moved[_drag_point] += _delta
		else:
			for i in moved.size(): moved[i] += _delta
	var color := Color("ffce77") if kind != "zones" else Color("8fd3ff")
	if kind == "activities": color = Color("e1a2ff")
	var shape := moved.duplicate()
	if kind == "zones" and shape.size() > 2: shape.append(shape[0])
	for i in shape.size(): shape[i] *= CELL
	var overlay := {"points": shape, "color": color, "screen_width": 2.0, "radius": 5.0}
	if kind == "zones": overlay.fill = Color(color, 0.1)
	if not shape.is_empty(): overlay.label = identity
	panel.canvas.edit_overlay.append(overlay)
	if kind == "anchors":
		var rect := spatial.world_footprint(identity)
		if not _before.is_empty(): rect.position += _delta
		var corners := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y), rect.position])
		for i in corners.size(): corners[i] *= CELL
		panel.canvas.edit_overlay.append({"points": corners, "color": color, "screen_width": 2.0, "handles": false, "fill": Color(color, 0.1)})
	panel.canvas.queue_redraw()

func _handle_at(at: Vector2) -> int:
	var entry := selected()
	if entry.is_empty(): return -1
	var points := _points(entry, layout())
	var radius: float = 9.0 / (CELL * panel.canvas.zoom)
	var nearest := -1
	for i in points.size():
		if kind == "routes" and i in [0, points.size() - 1]: continue
		if points[i].distance_to(at) <= radius: radius = points[i].distance_to(at); nearest = i
	return nearest

func _pick(at: Vector2) -> Dictionary:
	var spatial := layout()
	var filter := category.selected
	# Buildings use their complete visible plot, not just the bottom pivot.
	if filter in [0, 1]:
		var closest := INF
		var chosen := ""
		for entry in spatial.anchors:
			var id := str(entry.id)
			var rect := spatial.world_footprint(id)
			if rect.grow(0.2).has_point(at) and rect.get_area() < closest:
				closest = rect.get_area(); chosen = id
		if not chosen.is_empty(): return {"kind": "anchors", "id": chosen}
	if filter in [0, 6, 7]:
		for collection in ["objects", "base"]:
			var entries: Array = document().objects if collection == "objects" else panel.base.objects
			for i in range(entries.size() - 1, -1, -1):
				var entry: Dictionary = entries[i]
				if collection == "base" and not spatial.anchor(str(entry.get("base_id", ""))).is_empty(): continue
				var texture: Texture2D = panel._preview_texture(entry)
				if texture == null: continue
				var size := texture.get_size() / 32.0 * float(entry.get("scale", 1))
				var pos: Vector2 = entry.get("position", Vector2.ZERO)
				if Rect2(pos - Vector2(size.x * 0.5, size.y), size).has_point(at): return {"kind": collection, "id": str(entry.id)}
	if filter in [0, 4, 5]:
		for collection in ["scenery", "activities"]:
			if filter > 0 and filter != KINDS.find(collection) + 1: continue
			for entry in spatial.get(collection):
				var points: PackedVector2Array = PackedVector2Array(spatial.activity_points(entry)) if collection == "activities" else PackedVector2Array([spatial.scenery_position(entry)])
				for pos in points:
					if pos.distance_to(at) < 0.75: return {"kind": collection, "id": str(entry.id)}
	if filter in [0, 2]:
		var distance: float = maxf(0.45, 8.0 / (CELL * panel.canvas.zoom))
		var chosen := ""
		for entry in spatial.routes:
			var points := spatial.route_points(entry)
			for i in points.size() - 1:
				var d := at.distance_to(Geometry2D.get_closest_point_to_segment(at, points[i], points[i + 1]))
				if d < distance: distance = d; chosen = str(entry.id)
		if not chosen.is_empty(): return {"kind": "routes", "id": chosen}
	if filter in [0, 3]:
		for entry in spatial.zones:
			if Geometry2D.is_point_in_polygon(at, entry.get("polygon", PackedVector2Array())): return {"kind": "zones", "id": str(entry.id)}
	return {}

func press(pixel: Vector2i) -> void:
	var at := Vector2(pixel) / CELL
	if not Rect2(Vector2.ZERO, Vector2(document().size)).has_point(at): return
	if not pending.is_empty():
		if pending == "create": create_feature(at)
		else: insert_point(at)
		pending = ""
		return
	_drag_point = _handle_at(at)
	if _drag_point < 0:
		var hit := _pick(at)
		if hit.is_empty(): clear_selection(); panel.refresh(); return
		select_feature(str(hit.kind), str(hit.id))
		_drag_point = _handle_at(at)
	point = _drag_point
	if kind == "activities" and point < 0: point = 0
	_origin = at
	_delta = Vector2.ZERO
	_before = document().snapshot()
	_inspector_key = ""
	refresh()

func drag(pixel: Vector2i) -> void:
	if _before.is_empty(): return
	_delta = Vector2(pixel) / CELL - _origin
	if panel.snap.button_pressed: _delta = _delta.snapped(Vector2.ONE * 0.25)
	_draw_selection()
	coordinates.text = "Move  Δx %.2f  Δy %.2f  • Esc cancels" % [_delta.x, _delta.y]

func release(pixel: Vector2i) -> void:
	if _before.is_empty(): return
	drag(pixel)
	var before := _before
	_before = {}
	if not _delta.is_zero_approx():
		_apply_delta(_delta, _drag_point)
		panel._commit(before, document().snapshot(), "Move " + identity)
	_inspector_key = ""
	_delta = Vector2.ZERO
	panel.refresh()

func _apply_delta(delta: Vector2, index: int) -> void:
	var points := _points(selected(), layout())
	if points.is_empty(): return
	var entry := _editable()
	if kind == "zones" and index < 0 and carry_district: _move_district_contents(entry, delta)
	if kind in ["routes", "zones", "activities"]:
		if index >= 0: _set_point(entry, points[index] + delta, index)
		else:
			for i in points.size(): _set_point(entry, points[i] + delta, i)
	else: _set_point(entry, points[0] + delta, 0)

func cancel_drag() -> void:
	_before = {}
	_delta = Vector2.ZERO
	pending = ""
	if panel.canvas: _draw_selection()

func cursor(at: Vector2i) -> void:
	if _before.is_empty(): coordinates.text = "x %.2f   y %.2f  •  zoom %.0f%%" % [at.x / CELL, at.y / CELL, panel.canvas.zoom * 100]

func tool_changed() -> void:
	cancel_drag()
	if panel.object_controls: panel.object_controls.visible = panel.tool.selected == 7 or kind in ["objects", "base"]

func frame_selection() -> void:
	var entry := selected()
	if entry.is_empty(): panel._fit_map(); return
	var points := _points(entry, layout())
	if points.is_empty(): return
	var rect := Rect2(points[0] * CELL, Vector2.ZERO)
	for p in points: rect = rect.expand(p * CELL)
	if kind == "anchors":
		var footprint := layout().world_footprint(identity)
		rect = Rect2(footprint.position * CELL, footprint.size * CELL)
	panel.canvas.frame_area(rect.grow(28))

func key_input(event: InputEventKey) -> void:
	if event.ctrl_pressed or event.meta_pressed:
		match event.keycode:
			KEY_S: panel._save(panel.path)
			KEY_Z: panel._history_step(event.shift_pressed)
			KEY_Y: panel._history_step(true)
			KEY_D: duplicate_selection()
		return
	match event.keycode:
		KEY_TAB: panel.canvas_only.button_pressed = not panel.canvas_only.button_pressed
		KEY_HOME: panel._fit_map()
		KEY_F: frame_selection()
		KEY_V: panel.tool.select(11); tool_changed()
		KEY_DELETE, KEY_BACKSPACE: delete_selection()
		KEY_ESCAPE: cancel_drag()
		KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN:
			if selected().is_empty(): return
			var delta := Vector2.ZERO
			match event.keycode:
				KEY_LEFT: delta.x = -1
				KEY_RIGHT: delta.x = 1
				KEY_UP: delta.y = -1
				KEY_DOWN: delta.y = 1
			var before := document().snapshot()
			_apply_delta(delta * (1 if event.shift_pressed else 0.25), point)
			panel._commit(before, document().snapshot(), "Nudge " + identity)
			_inspector_key = ""
			panel.refresh()

func _new_id(prefix: String) -> String:
	return prefix + "_%x" % Time.get_ticks_usec()

func create_feature(at: Vector2) -> void:
	var before := document().snapshot()
	var spatial: WorldLayout = panel._editable_layout()
	var entry := {"id": _new_id(["commons", "road", "district", "detail"][_new_type.selected]), "label": ["New commons", "New road", "New district", "New detail"][_new_type.selected]}
	match _new_type.selected:
		0:
			kind = "anchors"
			entry.merge({"kind": "landmark", "position": at, "approach": Vector2.ZERO, "clearance": Vector2(2, 2), "footprint": Rect2(-0.5, -0.5, 1, 1), "zone": spatial.zone_at(at), "editor_created": true, "destination": false})
		1:
			kind = "routes"
			entry.merge({"from": "arrival", "to": "market", "via": PackedVector2Array([at]), "width": 1.8, "material": "path", "role": "secondary"})
		2:
			kind = "zones"
			var rect := Rect2(at - Vector2(4, 3), Vector2(8, 6)).intersection(Rect2(Vector2.ZERO, Vector2(document().size)))
			entry.merge({"polygon": PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]), "material": "grass_light", "density": 0.05, "allowed": ["flowers", "bush", "bench"]})
		3:
			kind = "scenery"
			entry.merge({"asset": "bench", "parent": "", "position": at, "scale": 1.0, "zone": spatial.zone_at(at)})
	spatial.get(kind).append(entry)
	identity = str(entry.id)
	point = -1
	panel._commit(before, document().snapshot(), "Create " + kind.trim_suffix("s"))
	select_feature(kind, identity)

func insert_point(at: Vector2) -> void:
	if kind not in ["routes", "zones", "activities"] or selected().is_empty(): return
	var before := document().snapshot()
	var points := _points(selected(), layout())
	var entry := _editable()
	if kind == "activities":
		var owner := str(entry.get("owner", "arrival"))
		entry.points.append({"anchor": owner, "offset": at - layout().position_of(owner)})
		point = entry.points.size() - 1
	else:
		var closest := INF
		var insert := 0
		var count := points.size() - 1 if kind == "routes" else points.size()
		for i in count:
			var distance := at.distance_to(Geometry2D.get_closest_point_to_segment(at, points[i], points[(i + 1) % points.size()]))
			if distance < closest: closest = distance; insert = i
		var vertices: PackedVector2Array = entry.get("via", PackedVector2Array()) if kind == "routes" else entry.polygon
		vertices.insert(clampi(insert if kind == "routes" else insert + 1, 0, vertices.size()), at)
		entry["via" if kind == "routes" else "polygon"] = vertices
		point = insert + 1
	panel._commit(before, document().snapshot(), "Insert point")
	_inspector_key = ""
	panel.refresh()

func remove_point() -> void:
	if kind not in ["routes", "zones", "activities"] or point < 0: return
	var before := document().snapshot()
	var entry := _editable()
	if kind == "activities":
		if point >= entry.points.size(): return
		if entry.points.size() <= 1: panel.studio.report("A routine needs at least one workpoint."); return
		entry.points.remove_at(point)
	else:
		var vertices: PackedVector2Array = entry.get("via", PackedVector2Array()) if kind == "routes" else entry.polygon
		var index := point - 1 if kind == "routes" else point
		if index < 0 or index >= vertices.size(): return
		if kind == "zones" and vertices.size() <= 3: panel.studio.report("A district needs at least three vertices."); return
		vertices.remove_at(index)
		entry["via" if kind == "routes" else "polygon"] = vertices
	point = -1
	panel._commit(before, document().snapshot(), "Remove point")
	_inspector_key = ""
	panel.refresh()

func duplicate_selection() -> void:
	if kind not in ["objects", "scenery", "routes", "zones"] or selected().is_empty(): return
	if kind == "objects" and selected().has("base_id"): panel.studio.report("Base services keep one identity; place a new asset instead."); return
	var before := document().snapshot()
	var copy := selected().duplicate(true)
	copy.id = _new_id(identity + "_copy")
	if kind == "objects": document().objects.append(copy)
	else: panel._editable_layout().get(kind).append(copy)
	identity = str(copy.id)
	point = -1
	_apply_delta(Vector2(1, 1), -1)
	panel._commit(before, document().snapshot(), "Duplicate feature")
	select_feature(kind, identity)

func delete_selection() -> void:
	var entry := selected()
	if entry.is_empty() or kind == "base": return
	if kind == "activities": panel.studio.report("Existing actor routines retain their identity. Move or edit their workpoints instead."); return
	if kind == "anchors":
		if not entry.get("editor_created", false): panel.studio.report("Existing building identities are retained. Move or edit their footprint instead."); return
		for route in layout().routes:
			if route.get("from", "") == identity or route.get("to", "") == identity: panel.studio.report("Reconnect roads before removing this landmark."); return
	var before := document().snapshot()
	var entries: Array = document().objects if kind == "objects" else panel._editable_layout().get(kind)
	for i in entries.size():
		if entries[i].get("id", "") == identity: entries.remove_at(i); break
	clear_selection()
	panel._commit(before, document().snapshot(), "Delete feature")
	panel.refresh()

func show_validation(warnings: PackedStringArray) -> void:
	problems.clear()
	for warning in warnings:
		problems.add_item(warning)
		problems.set_item_tooltip(problems.item_count - 1, warning)
	if warnings.is_empty(): problems.add_item("No authoring conflicts found.")
	inspector_tabs.current_tab = 1

func _problem_selected(index: int) -> void:
	var message := problems.get_item_text(index)
	var spatial := layout()
	var best := {"kind": "", "id": ""}
	for collection in KINDS:
		for entry in spatial.get(collection):
			var id := str(entry.id)
			if message.contains(id) and id.length() > str(best.id).length(): best = {"kind": collection, "id": id}
	if not str(best.id).is_empty():
		select_feature(str(best.kind), str(best.id))
		frame_selection()

func _rebuild_assets() -> void:
	if assets == null: return
	assets.clear()
	var ids: Array = ["tree", "house", "garden", "flowers", "bush", "bench", "rock", "fence", "sign", "monsoon/planter"]
	ids.append_array(AssetRegistry.library().entries.keys())
	for id: String in ids:
		if not asset_search.text.is_empty() and not id.to_lower().contains(asset_search.text.to_lower()): continue
		if not _thumbnails.has(id):
			var texture := AuthoredMapRenderer.object_texture(id)
			if texture:
				var img := texture.get_image().duplicate() as Image
				var size := Vector2(img.get_size())
				size *= 36.0 / maxf(size.x, size.y)
				img.resize(maxi(1, int(size.x)), maxi(1, int(size.y)), Image.INTERPOLATE_NEAREST)
				_thumbnails[id] = ImageTexture.create_from_image(img)
		assets.add_item(id, _thumbnails.get(id))
		assets.set_item_metadata(assets.item_count - 1, id)


func _rebuild_layers() -> void:
	if layer_list == null: return
	_building = true
	layer_list.clear()
	var root := layer_list.create_item()
	for name in AuthoredMap.LAYERS:
		var item := layer_list.create_item(root)
		item.set_text(0, name)
		item.set_metadata(0, name)
		for column in [1, 2]:
			item.set_cell_mode(column, TreeItem.CELL_MODE_CHECK)
			item.set_editable(column, true)
		item.set_checked(1, not bool(panel._hidden.get(name, false)))
		item.set_checked(2, bool(panel._locked.get(name, false)))
	_building = false

func _layer_edited() -> void:
	if _building: return
	var item := layer_list.get_edited()
	var column := layer_list.get_edited_column()
	if item and column in [1, 2]: panel._set_layer_flag(str(item.get_metadata(0)), "hidden" if column == 1 else "locked", not item.is_checked(column) if column == 1 else item.is_checked(column))


func _move_district_contents(zone: Dictionary, delta: Vector2) -> void:
	var spatial: WorldLayout = panel._editable_layout()
	var polygon: PackedVector2Array = zone.get("polygon", PackedVector2Array())
	var moved := {}
	for anchor in spatial.anchors:
		if anchor.get("zone", "") != identity: continue
		anchor.position += delta
		moved[str(anchor.id)] = true
	for anchor in spatial.anchors:
		var parent := str(anchor.get("relative_to", ""))
		if moved.has(str(anchor.id)) and not parent.is_empty(): anchor.offset = anchor.position - spatial.position_of(parent)
	for detail in spatial.scenery:
		if detail.get("zone", "") == identity and not moved.has(str(detail.get("parent", ""))): detail.position += delta
	for object in document().objects:
		var id := str(object.get("base_id", ""))
		if moved.has(id): object.position = spatial.position_of(id)
		elif id.is_empty() and Geometry2D.is_point_in_polygon(object.get("position", Vector2.ZERO), polygon): object.position += delta
	for road in spatial.routes:
		var points: PackedVector2Array = road.get("via", PackedVector2Array())
		for i in points.size():
			if Geometry2D.is_point_in_polygon(points[i], polygon): points[i] += delta
		road.via = points
