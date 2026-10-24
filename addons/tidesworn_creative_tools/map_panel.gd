@tool
extends VBoxContainer
const W := preload("res://addons/tidesworn_creative_tools/widgets.gd")
const Canvas := preload("res://addons/tidesworn_creative_tools/creative_canvas.gd")
const Workbench := preload("res://addons/tidesworn_creative_tools/map_workbench.gd")
const CELL := 8
var workbench: Control
var properties: VBoxContainer
var inspector_scroll: ScrollContainer
var guides: CheckBox
var canvas_only: CheckBox
var object_controls: VBoxContainer
var _saved_snapshot: Dictionary = {}
var studio: Control
var map: AuthoredMap
var base: AuthoredMap
var path := "res://data/maps/village.tres"
var dirty := false
var canvas: Control
var layer: OptionButton
var terrain_choice: OptionButton
var tool: OptionButton
var brush: SpinBox
var locked: CheckBox
var shown: CheckBox
var snap: CheckBox
var status: Label
var asset: LineEdit
var object_label: LineEdit
var depth: SpinBox
var scale_value: SpinBox
var footprint_x: SpinBox
var footprint_y: SpinBox
var blocking: CheckBox
var interactive: CheckBox
var metadata: TextEdit
var selected_object := -1
var _hidden: Dictionary = {}
var _locked: Dictionary = {}
var _before: Dictionary = {}
var _preview_spatial: WorldLayout
var _start := Vector2i.ZERO
var _last := Vector2i.ZERO
var _selection := Rect2i()
var _base: Image
var _base_generation := -1
var _local_history := UndoRedo.new()
var spatial_kind: OptionButton
var spatial_entry: OptionButton
var spatial_vertex: SpinBox
var route_width: SpinBox
var spatial_shown: CheckBox
var _base_signature := 0

func _ready() -> void:
	base = load("res://data/maps/village_objects.tres") as AuthoredMap
	map = (load(path) as AuthoredMap).copy_map()
	_hidden = map.editor_hidden
	_locked = map.editor_locked
	var bar := W.row(self)
	W.button(bar, "New…", _new)
	W.button(bar, "Open…", func() -> void: W.dialog(self, ["*.tres ; AuthoredMap"], false, _load).popup_centered())
	W.button(bar, "Save", func() -> void: _save(path))
	W.button(bar, "Duplicate / Save As…", func() -> void: W.dialog(self, ["*.tres ; AuthoredMap"], true, _save).popup_centered())
	W.button(bar, "Undo", func() -> void: _history_step(false))
	W.button(bar, "Redo", func() -> void: _history_step(true))
	W.button(bar, "Validate", _validate)
	W.button(bar, "Save & Play", _play)
	W.button(bar, "Fit map", _fit_map)
	W.button(bar, "Frame selection", func() -> void: workbench.frame_selection())
	bar = W.row(self)
	layer = W.option(bar, AuthoredMap.LAYERS)
	terrain_choice = W.option(bar, AuthoredMap.MATERIALS)
	tool = W.option(bar, ["Pencil", "Eraser", "Rectangle", "Fill", "Eyedropper", "Select", "Move", "Place object", "Select object", "Move object", "Move layout point", "Select / move layout"])
	brush = W.number(bar, "Brush", 1, 1, 8)
	tool.item_selected.connect(func(index: int) -> void:
		if index == 7: _lock_base_properties(false)
		if workbench:
			_cancel_gesture()
			workbench.tool_changed())
	bar = W.row(self)
	locked = W.check(bar, "Lock layer")
	shown = W.check(bar, "Visible", true)
	snap = W.check(bar, "Snap", true)
	snap.tooltip_text = "Layout points snap to 0.25 units; placed objects snap to cell centres."
	guides = W.check(bar, "Guides", false)
	guides.toggled.connect(func(on: bool) -> void: spatial_shown.button_pressed = on)
	canvas_only = W.check(bar, "Canvas only", false)
	canvas_only.toggled.connect(func(on: bool) -> void:
		workbench.visible = not on
		inspector_scroll.visible = not on
		call_deferred("_fit_map"))
	var grid := W.check(bar, "Grid", false)
	grid.toggled.connect(func(on: bool) -> void: canvas.grid = on; canvas.queue_redraw())
	layer.item_selected.connect(func(_i: int) -> void:
		locked.set_pressed_no_signal(_locked.get(_layer(), false))
		shown.set_pressed_no_signal(not _hidden.get(_layer(), false)))
	locked.toggled.connect(func(on: bool) -> void: _set_layer_flag(_layer(), "locked", on))
	shown.toggled.connect(func(on: bool) -> void: _set_layer_flag(_layer(), "hidden", not on))
	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(split)
	canvas = Canvas.new()
	canvas.zoom = 1.0
	canvas.grid_step = CELL
	canvas.grid = false
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	workbench = Workbench.new()
	workbench.panel = self
	split.add_child(workbench)
	workbench.custom_minimum_size.x = 185
	var viewport_split := HSplitContainer.new()
	viewport_split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(viewport_split)
	viewport_split.add_child(canvas)
	canvas.focus_mode = Control.FOCUS_ALL
	canvas.key_pressed.connect(func(event: InputEventKey) -> void: workbench.key_input(event))
	canvas.cancelled.connect(_cancel_gesture)
	canvas.hovered.connect(func(at: Vector2i) -> void: workbench.cursor(at))
	canvas.pressed.connect(_press)
	canvas.dragged.connect(_drag)
	canvas.released.connect(_release)
	var scroll := ScrollContainer.new()
	inspector_scroll = scroll
	scroll.custom_minimum_size.x = 260
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	viewport_split.add_child(scroll)
	properties = VBoxContainer.new()
	properties.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(properties)
	workbench.build_inspector(properties)
	object_controls = VBoxContainer.new()
	properties.add_child(object_controls)
	var object_parent := properties
	properties = object_controls
	W.label(properties, "Object appearance & behavior")
	asset = W.entry(properties, "Asset ID", "flowers")
	object_label = W.entry(properties, "Label", "Coastal planter")
	bar = W.row(properties)
	depth = W.number(bar, "Depth", 5, -1000, 1000)
	bar = W.row(properties)
	scale_value = W.number(bar, "Scale", 1, 0.1, 4)
	scale_value.step = 0.1
	bar = W.row(properties)
	footprint_x = W.number(bar, "Footprint X", 0.7, 0.1, 8)
	footprint_x.step = 0.1
	bar = W.row(properties)
	footprint_y = W.number(bar, "Y", 0.5, 0.1, 8)
	footprint_y.step = 0.1
	blocking = W.check(properties, "Blocks navigation / collision")
	interactive = W.check(properties, "Interactive (inspect label)")
	W.label(properties, "Metadata JSON • kind: route/spawn/prop
route: resident name in metadata.resident")
	metadata = TextEdit.new()
	metadata.custom_minimum_size = Vector2(240, 90)
	metadata.text = "{}"
	properties.add_child(metadata)
	W.button(properties, "Apply properties", _apply_object)
	W.button(properties, "Delete selected object", _delete_object)
	properties = object_parent
	var seed_box := W.number(object_controls, "Decoration seed", map.seed_value, 0, 999999)
	W.button(object_controls, "Seed flower clusters", func() -> void: _decorate(int(seed_box.value)))
	var tip := W.label(properties, "Wheel zoom • middle/Space drag pan
Ctrl+S Save • Ctrl+Z / Shift+Z Undo/Redo
V Select • F Frame • Home Fit
Esc cancels a drag without changing the map.")
	tip.add_theme_font_size_override("font_size", 11)
	for child in properties.get_children():
		if child is Label and child.text.length() > 60:
			child.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			child.custom_minimum_size.x = 230
	properties = object_parent
	var advanced := VBoxContainer.new()
	var advanced_button := W.button(properties, "Advanced point tools ▸", func() -> void: advanced.visible = not advanced.visible)
	advanced_button.tooltip_text = "Legacy point selector and road width controls"
	properties.add_child(advanced)
	advanced.hide()
	properties = advanced
	bar = W.row(properties)
	spatial_shown = W.check(bar, "Overlays", false)
	spatial_kind = W.option(bar, ["anchors", "routes", "zones", "scenery", "activities"])
	bar = W.row(properties)
	spatial_entry = W.option(bar, [])
	spatial_entry.custom_minimum_size.x = 230
	bar = W.row(properties)
	spatial_vertex = W.number(bar, "Point", 0, 0, 128)
	bar = W.row(properties)
	route_width = W.number(bar, "Width", 1.8, 0.8, 8)
	route_width.step = 0.05
	W.button(bar, "Apply road width", _apply_route_width)
	spatial_kind.item_selected.connect(func(_i: int) -> void: _spatial_entries(); workbench.select_spatial(); refresh())
	spatial_entry.item_selected.connect(func(_i: int) -> void: workbench.select_spatial(); refresh())
	spatial_shown.toggled.connect(func(on: bool) -> void: guides.set_pressed_no_signal(on); refresh())
	_spatial_entries()
	status = W.label(self, "")
	status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_saved_snapshot = map.snapshot()
	tool.select(11)
	refresh()
	call_deferred("_fit_map")

func _layer() -> String:
	return layer.get_item_text(layer.selected)

func refresh() -> void:
	if canvas == null or map == null: return
	locked.set_pressed_no_signal(_locked.get(_layer(), false))
	shown.set_pressed_no_signal(not _hidden.get(_layer(), false))
	var spatial := map.resolved_layout()
	_preview_spatial = spatial
	if _base == null or _base_generation != WorldPalette.generation or _base_signature != spatial.signature():
		_base = WorldTerrain._make_terrain_texture(spatial).get_image().duplicate() as Image
		_base.resize(map.size.x * CELL, map.size.y * CELL, Image.INTERPOLATE_NEAREST)
		_base_generation = WorldPalette.generation
		_base_signature = spatial.signature()
	var image := _base.duplicate() as Image
	for name in AuthoredMap.LAYERS:
		if _hidden.get(name, false): continue
		for at in map.layers.get(name, {}):
			var tile := AuthoredMapRenderer.tile_image(map.cell(name, at), at, map, name)
			tile.resize(CELL, CELL, Image.INTERPOLATE_NEAREST)
			image.blend_rect(tile, Rect2i(Vector2i.ZERO, Vector2i(CELL, CELL)), at * CELL)
	for data in _preview_objects():
		var texture := _preview_texture(data)
		if texture == null: continue
		var img := texture.get_image().duplicate() as Image
		for turn in int(data.get("turns", 0)): img.rotate_90(CLOCKWISE)
		var target_size := Vector2i(Vector2(img.get_size()) * (float(CELL) / 32.0) * float(data.get("scale", 1.0))).max(Vector2i.ONE)
		img.resize(target_size.x, target_size.y, Image.INTERPOLATE_NEAREST)
		var p: Vector2 = data.get("position", Vector2.ZERO)
		var pivot: Vector2 = data.get("pivot", Vector2(0.5, 1))
		image.blend_rect(img, Rect2i(Vector2i.ZERO, target_size), Vector2i(p * CELL) - Vector2i(Vector2(target_size) * pivot))
	_update_spatial_overlay(spatial)
	canvas.show_image(image)
	canvas.selection = Rect2i(_selection.position * CELL, _selection.size * CELL)
	canvas.queue_redraw()
	if workbench: workbench.refresh()
	status.text = ("● UNSAVED  " if dirty else "Saved  ") + path + " • %d authored objects • %d validation warnings" % [map.objects.size(), map.warnings().size()]

func _press(at: Vector2i) -> void:
	if tool.selected == 11:
		workbench.press(at)
		return
	if _locked.get(_layer(), false): studio.report("Layer is locked."); return
	_start = at / CELL
	_last = _start
	_before = map.snapshot()
	var name := tool.get_item_text(tool.selected)
	match name:
		"Pencil", "Eraser": _brush(_start, "" if name == "Eraser" else _material())
		"Fill": _fill(_start)
		"Eyedropper":
			var value := map.cell(_layer(), _start)
			var i := AuthoredMap.MATERIALS.find(value)
			if i >= 0: terrain_choice.select(i)
		"Place object": _place(at)
		"Select object", "Move object": _select_object(at)
	refresh()

func _drag(at: Vector2i) -> void:
	if tool.selected == 11:
		workbench.drag(at)
		return
	if _before.is_empty(): return
	var cell := at / CELL
	var name := tool.get_item_text(tool.selected)
	if name in ["Pencil", "Eraser"]:
		var distance := maxi(absi(cell.x - _last.x), absi(cell.y - _last.y))
		for step in distance + 1:
			_brush(Vector2i(Vector2(_last).lerp(Vector2(cell), float(step) / maxi(1, distance)).round()), "" if name == "Eraser" else _material())
		_last = cell
	elif name in ["Select", "Rectangle"]:
		_selection = Rect2i(_start.min(cell), (cell - _start).abs() + Vector2i.ONE)
	refresh()

func _release(at: Vector2i) -> void:
	if tool.selected == 11:
		workbench.release(at)
		return
	if _before.is_empty(): return
	var cell := at / CELL
	var name := tool.get_item_text(tool.selected)
	if name == "Rectangle":
		var rect := Rect2i(_start.min(cell), (cell - _start).abs() + Vector2i.ONE).intersection(Rect2i(Vector2i.ZERO, map.size))
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x): map.paint(_layer(), Vector2i(x, y), _material())
	elif name == "Move":
		var region := _selection.intersection(Rect2i(Vector2i.ZERO, map.size))
		var cells := {}
		for y in range(region.position.y, region.end.y):
			for x in range(region.position.x, region.end.x):
				var p := Vector2i(x, y)
				cells[p] = map.cell(_layer(), p)
				map.paint(_layer(), p, "")
		for p in cells: map.paint(_layer(), p + cell - _start, cells[p])
		_selection.position += cell - _start
	elif name == "Move layout point":
		_move_layout_point(Vector2(at) / CELL)
	elif name == "Move object" and selected_object >= 0:
		map.objects[selected_object].position = Vector2(cell) + Vector2.ONE * 0.5 if snap.button_pressed else Vector2(at) / CELL
	if name not in ["Select", "Select object", "Eyedropper"]: _commit(_before, map.snapshot(), name)
	_before = {}
	refresh()

func _material() -> String:
	return "blocked" if _layer() == "Collision" else terrain_choice.get_item_text(terrain_choice.selected)

func _brush(at: Vector2i, ink: String) -> void:
	for y in int(brush.value):
		for x in int(brush.value): map.paint(_layer(), at + Vector2i(x, y), ink)

func _fill(at: Vector2i) -> void:
	if not Rect2i(Vector2i.ZERO, map.size).has_point(at): return
	var target := map.cell(_layer(), at)
	if target == _material(): return
	var todo: Array[Vector2i] = [at]
	map.paint(_layer(), at, _material())
	while not todo.is_empty():
		var point: Vector2i = todo.pop_back()
		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = point + d
			if Rect2i(Vector2i.ZERO, map.size).has_point(next) and map.cell(_layer(), next) == target:
				map.paint(_layer(), next, _material())
				todo.append(next)

func _place(at: Vector2i) -> void:
	var data := _object_properties()
	if data.is_empty(): return
	data.id = "authored_%x_%x" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
	data.position = Vector2(at / CELL) + Vector2.ONE * 0.5 if snap.button_pressed else Vector2(at) / CELL
	map.objects.append(data)
	selected_object = map.objects.size() - 1
	workbench.kind = "objects"
	workbench.identity = str(data.id)
	workbench._inspector_key = ""

func _select_object(at: Vector2i) -> void:
	selected_object = -1
	var distance := 2.0
	var chosen := {}
	for data in _preview_objects():
		if data.get("preview_only", false): continue
		var p: Vector2 = data.position
		var d := p.distance_to(Vector2(at) / CELL)
		if d < distance:
			distance = d
			chosen = data
	if chosen.is_empty(): return
	if chosen.get("protected", false):
		workbench.select_feature("anchors", str(chosen.get("base_id", "")))
		tool.select(11)
		return
	for i in map.objects.size():
		if map.objects[i].id == chosen.id: selected_object = i
	if selected_object < 0 and chosen.has("base_id"):
		var before := map.snapshot()
		map.objects.append(chosen.duplicate(true))
		selected_object = map.objects.size() - 1
		_commit(before, map.snapshot(), "Edit base object override")
	if selected_object < 0: return
	var data: Dictionary = map.objects[selected_object]
	var is_base := data.has("base_id")
	_lock_base_properties(is_base)
	asset.text = data.get("asset", "flowers")
	object_label.text = data.get("label", "")
	depth.value = data.get("depth", 5)
	scale_value.value = data.get("scale", 1)
	blocking.button_pressed = data.get("blocking", false)
	interactive.button_pressed = data.get("interactive", false)
	var footprint: Vector2 = data.get("footprint", Vector2(0.7, 0.5))
	footprint_x.value = footprint.x
	footprint_y.value = footprint.y
	metadata.text = JSON.stringify(data.get("metadata", {}), "	")
	workbench.kind = "objects"
	workbench.identity = str(data.id)
	workbench._inspector_key = ""
	studio.report("Selected " + str(data.id))

func _object_properties() -> Dictionary:
	var meta: Variant = JSON.parse_string(metadata.text)
	if not meta is Dictionary: studio.report("Object metadata must be a JSON object."); return {}
	return {"asset": asset.text, "label": object_label.text, "depth": int(depth.value), "scale": scale_value.value, "blocking": blocking.button_pressed, "interactive": interactive.button_pressed, "footprint": Vector2(footprint_x.value, footprint_y.value), "metadata": meta, "kind": meta.get("kind", "prop")}

func _apply_object() -> void:
	var before := map.snapshot()
	if selected_object < 0 and workbench.kind == "base":
		workbench._editable()
		for i in map.objects.size():
			if map.objects[i].id == workbench.identity: selected_object = i
	if selected_object < 0: return
	var data := _object_properties()
	if data.is_empty(): return
	if map.objects[selected_object].has("base_id"):
		map.objects[selected_object].depth = int(depth.value)
	else:
		map.objects[selected_object].merge(data, true)
	_commit(before, map.snapshot(), "Object properties")

func _delete_object() -> void:
	if selected_object < 0: return
	var before := map.snapshot()
	map.objects.remove_at(selected_object)
	selected_object = -1
	_commit(before, map.snapshot(), "Delete object")

func _commit(before: Dictionary, after: Dictionary, title: String) -> void:
	if before == after: return
	if studio.plugin != null:
		var history: EditorUndoRedoManager = studio.plugin.get_undo_redo()
		history.create_action("Tidesworn: " + title, UndoRedo.MERGE_DISABLE, map)
		history.add_do_method(self, "_restore_document", after, map.get_instance_id())
		history.add_undo_method(self, "_restore_document", before, map.get_instance_id())
		history.commit_action()
	else:
		_local_history.create_action(title)
		_local_history.add_do_method(_restore.bind(after))
		_local_history.add_undo_method(_restore.bind(before))
		_local_history.commit_action()

func _restore_document(state: Dictionary, identity: int) -> void:
	if map.get_instance_id() == identity: _restore(state)

func _restore(state: Dictionary) -> void:
	map.restore(state)
	_hidden = map.editor_hidden
	_locked = map.editor_locked
	dirty = map.snapshot() != _saved_snapshot
	_spatial_entries()
	refresh()

func _history_step(redo: bool) -> void:
	var history := _local_history
	if studio.plugin != null:
		var manager: EditorUndoRedoManager = studio.plugin.get_undo_redo()
		history = manager.get_history_undo_redo(manager.get_object_history_id(map))
	if history:
		if redo: history.redo()
		else: history.undo()

func _new() -> void:
	studio.confirm_discard(dirty, func() -> void:
		map = AuthoredMap.new()
		_hidden = {}
		_locked = {}
		map.palette = WorldPalette.current()
		path = "res://data/maps/untitled.tres"
		dirty = true
		_saved_snapshot = {}
		workbench.clear_selection()
		selected_object = -1
		_local_history.clear_history()
		_spatial_entries()
		refresh())

func _load(source: String) -> void:
	var loaded := load(source) as AuthoredMap
	if loaded == null: studio.report("Select an AuthoredMap resource."); return
	studio.confirm_discard(dirty, func() -> void:
		map = loaded.copy_map()
		_hidden = map.editor_hidden
		_locked = map.editor_locked
		path = source
		dirty = false
		_saved_snapshot = map.snapshot()
		workbench.clear_selection()
		selected_object = -1
		_local_history.clear_history()
		if map.palette: WorldPalette.use_palette(map.palette)
		_spatial_entries()
		refresh()
		_fit_map())

func _save(destination: String) -> void:
	map.editor_hidden = _hidden
	map.editor_locked = _locked
	var result := ResourceSaver.save(map, destination)
	if result == OK:
		path = destination
		dirty = false
		_saved_snapshot = map.snapshot()
		if Engine.is_editor_hint(): EditorInterface.get_resource_filesystem().scan()
	refresh()
	studio.report("Saved map: " + destination if result == OK else error_string(result))

func _validate() -> void:
	var warnings := map.warnings()
	workbench.show_validation(warnings)
	studio.report("Map validation: " + ("no protected-area conflicts. Check routes in Play." if warnings.is_empty() else "
".join(warnings)))

func _play() -> void:
	if dirty: _save(path)
	if dirty: return
	workbench.show_validation(map.warnings())
	if studio.plugin != null:
		# Launch with independent userdata; never reuse the player's save in authoring preview.
		var root := OS.get_cache_dir().path_join("tidesworn-map-preview")
		DirAccess.make_dir_recursive_absolute(root.path_join("userdata"))
		var args := PackedStringArray(["XDG_DATA_HOME=" + root.path_join("userdata"), "TIDESWORN_TEST_ROOT=" + root, OS.get_executable_path(), "--path", ProjectSettings.globalize_path("res://"), "res://tools/authored_preview.tscn", "--", "--map=" + path])
		var pid := OS.create_process("/usr/bin/env", args)
		studio.report("Map preview started in isolated data: " + root if pid > 0 else "Unable to launch preview.")

func _decorate(seed_value: int) -> void:
	var before := map.snapshot()
	map.seed_value = seed_value
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var spatial := map.resolved_layout()
	for i in 32:
		var at := Vector2i(rng.randi_range(3, map.size.x - 4), rng.randi_range(3, map.size.y - 4))
		if not spatial.reserved(Vector2(at) + Vector2.ONE * 0.5, 0.6) and map.cell("Decoration", at).is_empty(): map.paint("Decoration", at, "flower")
	_commit(before, map.snapshot(), "Seed decoration")


func _exit_tree() -> void:
	_local_history.free()


func _preview_objects() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if base:
		for object in base.objects:
			var overridden := false
			for override in map.objects:
				if override.get("base_id", "") == object.get("base_id", ""):
					overridden = true
					break
			if not overridden:
				var proxy := object.duplicate(true)
				var spatial := _preview_spatial if _preview_spatial else map.resolved_layout()
				var id := str(proxy.get("base_id", ""))
				if spatial.anchor(id).get("kind", "") == "fence": continue
				if not spatial.anchor(id).is_empty(): proxy.position = spatial.position_of(id)
				result.append(proxy)
	result.append_array(map.objects)
	var spatial := _preview_spatial if _preview_spatial else map.resolved_layout()
	for entry in spatial.anchors:
		var kind := str(entry.get("kind", ""))
		if kind == "portal": result.append({"id": entry.id, "asset": "preview/portal/" + ("pet" if entry.id == "pet_portal" else "grotto"), "position": entry.position, "preview_only": true})
		if kind == "fence":
			var horizontal: bool = entry.get("axis", "horizontal") == "horizontal"
			var span: Vector2 = entry.get("span", Vector2.ZERO)
			var coordinate := span.x
			while coordinate < span.y:
				var gap := false
				for opening in entry.get("gaps", PackedVector2Array()):
					if coordinate >= opening.x and coordinate <= opening.y: gap = true
				if not gap: result.append({"id": str(entry.id) + str(coordinate), "asset": "fence", "position": entry.position + (Vector2(coordinate, 0) if horizontal else Vector2(0, coordinate)), "turns": 0 if horizontal else 1, "pivot": Vector2(0.5, 1) if horizontal else Vector2(0.5, 0.5), "preview_only": true})
				coordinate += 1.55
		if kind not in ["residence", "ruin"]: continue
		result.append({"id": entry.id, "asset": "house", "position": entry.position, "scale": 0.78, "level": entry.get("level", 1), "preview_only": true})
	for detail in spatial.scenery:
		if not spatial.scenery_fits(detail): continue
		var at: Vector2 = detail.get("position", Vector2.ZERO)
		if not str(detail.get("parent", "")).is_empty(): at += spatial.position_of(str(detail.parent))
		result.append({"id": detail.id, "asset": "workspace/" + str(detail.get("asset", "baskets")), "position": at, "scale": detail.get("scale", 1), "preview_only": true})
	for entry in spatial.activity_records():
		var points := spatial.activity_points(entry)
		if points.is_empty(): continue
		if entry.get("kind", "") == "animal": result.append({"id": entry.id, "asset": "preview/animal/" + str(entry.get("species", "chicken")), "position": points[0], "scale": entry.get("scale", 1), "preview_only": true})
	result.append({"id": "jetty_preview", "asset": "jetty", "position": spatial.position_of("harbour", Vector2(9, 28.5)), "preview_only": true})
	result.append({"id": "boat_preview", "asset": "ship", "position": spatial.activity_points(spatial.activity("boat"))[0], "preview_only": true})
	return result


func _lock_base_properties(is_base: bool) -> void:
	asset.editable = not is_base
	object_label.editable = not is_base
	scale_value.editable = not is_base
	footprint_x.editable = not is_base
	footprint_y.editable = not is_base
	blocking.disabled = is_base
	interactive.disabled = is_base
	metadata.editable = not is_base


func _spatial_entries() -> void:
	var previous := spatial_entry.get_item_text(spatial_entry.selected) if spatial_entry.selected >= 0 else ""
	spatial_entry.clear()
	var spatial := map.resolved_layout()
	for entry in spatial.get(spatial_kind.get_item_text(spatial_kind.selected)):
		spatial_entry.add_item(str(entry.get("id", "")))
		if entry.get("id", "") == previous: spatial_entry.select(spatial_entry.item_count - 1)

func _editable_layout() -> WorldLayout:
	if map.layout == null: map.layout = WorldLayout.village().copy_layout()
	return map.layout

func _move_layout_point(at: Vector2) -> void:
	if not Rect2(Vector2.ZERO, Vector2(map.size)).has_point(at): return
	var kind := spatial_kind.get_item_text(spatial_kind.selected)
	var entries: Array = _editable_layout().get(kind)
	if spatial_entry.selected < 0 or spatial_entry.selected >= entries.size(): return
	var entry: Dictionary = entries[spatial_entry.selected]
	if kind == "anchors":
		entry.position = at.snapped(Vector2.ONE * 0.25) if snap.button_pressed else at
		var parent := str(entry.get("relative_to", ""))
		if not parent.is_empty(): entry.offset = entry.position - _editable_layout().position_of(parent)
	elif kind == "scenery":
		var parent := str(entry.get("parent", ""))
		entry.position = at - (_editable_layout().position_of(parent) if not parent.is_empty() else Vector2.ZERO)
	elif kind == "activities":
		var points: Array = entry.get("points", [])
		var index := int(spatial_vertex.value)
		if index >= points.size():
			studio.report("Choose an existing activity point.")
			return
		points[index].offset = at - _editable_layout().position_of(str(points[index].get("anchor", "")))
	else:
		var key := "via" if kind == "routes" else "polygon"
		var points: PackedVector2Array = entry.get(key, PackedVector2Array())
		var index := int(spatial_vertex.value)
		if index >= points.size():
			studio.report("This route/zone has %d editable points; choose an existing vertex." % points.size())
			return
		points[index] = at
		entry[key] = points

func _apply_route_width() -> void:
	if spatial_kind.get_item_text(spatial_kind.selected) != "routes": return
	var before := map.snapshot()
	if spatial_entry.selected >= 0:
		_editable_layout().routes[spatial_entry.selected].width = route_width.value
	_commit(before, map.snapshot(), "Change road width")

func _update_spatial_overlay(spatial: WorldLayout) -> void:
	canvas.spatial_overlay.clear()
	if spatial_shown == null or not spatial_shown.button_pressed: return
	var kind := spatial_kind.get_item_text(spatial_kind.selected)
	var selected_id := spatial_entry.get_item_text(spatial_entry.selected) if spatial_entry.selected >= 0 else ""
	# Show one spatial category at a time; label only the selected feature.
	# This keeps overlapping district/road/footprint geometry legible at map scale.
	if kind == "zones":
		for zone in spatial.zones:
			var points: PackedVector2Array = zone.get("polygon", PackedVector2Array()).duplicate()
			if points.is_empty(): continue
			points.append(points[0])
			for i in points.size(): points[i] *= CELL
			var overlay := {"points": points, "color": Color(0.5, 0.8, 0.95, 0.65)}
			if zone.get("id", "") == selected_id: overlay.label = selected_id; overlay.width = 2.0
			canvas.spatial_overlay.append(overlay)
	elif kind == "activities":
		for entry in spatial.activities:
			var points := PackedVector2Array(spatial.activity_points(entry))
			if points.is_empty(): continue
			if points.size() == 1: points.append(points[0] + Vector2(0.3, 0))
			for i in points.size(): points[i] *= CELL
			var overlay := {"points": points, "color": Color(0.9, 0.55, 0.95, 0.8), "width": 2.0}
			if entry.get("id", "") == selected_id: overlay.label = selected_id
			canvas.spatial_overlay.append(overlay)
	elif kind == "scenery":
		for entry in spatial.scenery:
			var at: Vector2 = entry.get("position", Vector2.ZERO)
			var parent := str(entry.get("parent", ""))
			if not parent.is_empty(): at += spatial.position_of(parent)
			var overlay := {"points": PackedVector2Array([at * CELL, (at + Vector2(0.4, 0)) * CELL]), "color": Color(0.9, 0.8, 0.5), "width": 3.0}
			if entry.get("id", "") == selected_id: overlay.label = selected_id
			canvas.spatial_overlay.append(overlay)
	elif kind == "routes":
		for route in spatial.routes:
			var points := spatial.route_points(route)
			for i in points.size(): points[i] *= CELL
			var overlay := {"points": points, "color": Color(1, 0.7, 0.3, 0.7), "width": 1.0}
			if route.get("id", "") == selected_id: overlay.label = selected_id; overlay.width = 2.0
			canvas.spatial_overlay.append(overlay)
	else:
		for entry in spatial.anchors:
			var plot := spatial.world_footprint(str(entry.id))
			if plot.has_area():
				var corners := PackedVector2Array([plot.position, Vector2(plot.end.x, plot.position.y), plot.end, Vector2(plot.position.x, plot.end.y), plot.position])
				for i in corners.size(): corners[i] *= CELL
				canvas.spatial_overlay.append({"points": corners, "color": Color(0.4, 0.85, 0.6, 0.3), "handles": false})
			if entry.get("id", "") == selected_id and entry.has("yard"):
				var yard: Rect2 = entry.yard
				yard.position += spatial.position_of(selected_id)
				var outline := PackedVector2Array([yard.position, Vector2(yard.end.x, yard.position.y), yard.end, Vector2(yard.position.x, yard.end.y), yard.position])
				for i in outline.size(): outline[i] *= CELL
				canvas.spatial_overlay.append({"points": outline, "color": Color(0.9, 0.85, 0.5, 0.8), "width": 2.0})
			var at := spatial.approach(str(entry.id))
			var clearance: Vector2 = entry.get("clearance", Vector2.ONE)
			var rect := Rect2(at - clearance * 0.5, clearance)
			var points := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y), rect.position])
			for i in points.size(): points[i] *= CELL
			var overlay := {"points": points, "color": Color(0.9, 0.3, 0.4, 0.35), "handles": false}
			if entry.get("id", "") == selected_id: overlay.label = selected_id; overlay.width = 2.0
			canvas.spatial_overlay.append(overlay)


func _preview_texture(data: Dictionary) -> Texture2D:
	var id := str(data.get("base_id", ""))
	var asset_id := str(data.get("asset", ""))
	if id.begins_with("forest_"):
		return MonsoonArt.tree_texture(MonsoonArt.family(id, data.get("position", Vector2.ZERO)))
	if id == "house": return PixelArt.house_texture(1)
	if id.begins_with("shop_"): return PixelArt.stall_texture(id.trim_prefix("shop_"))
	if asset_id.begins_with("preview/animal/"): return PixelArt.animal_texture(asset_id.trim_prefix("preview/animal/"))
	if asset_id.begins_with("preview/portal/"):
		var theme_id := asset_id.trim_prefix("preview/portal/")
		return PixelArt.cached_texture("studio/portal/" + theme_id, func() -> Image:
			var frame := PixelArt.portal_frame_texture(theme_id, false).get_image().duplicate() as Image
			var swirl := PixelArt.portal_swirl_texture(theme_id, 0).get_image()
			var combined := PixelArt.image(80, 112)
			combined.blend_rect(swirl, Rect2i(Vector2i.ZERO, swirl.get_size()), Vector2i(16, 20))
			combined.blend_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), Vector2i.ZERO)
			return combined)
	if asset_id == "house": return PixelArt.house_texture(int(data.get("level", 1)))
	if asset_id.begins_with("workspace/"): return WorldComposition.texture(asset_id.trim_prefix("workspace/"))
	if asset_id == "jetty": return PixelArt.dock_texture()
	if asset_id == "ship": return PixelArt.ship_texture()
	return AuthoredMapRenderer.object_texture(asset_id)


func _fit_map() -> void:
	if canvas.image_texture == null: return
	canvas.fit_image()

func _set_layer_flag(name: String, flag: String, value: bool) -> void:
	var before := map.snapshot()
	if flag == "locked": _locked[name] = value
	else: _hidden[name] = value
	map.editor_hidden = _hidden
	map.editor_locked = _locked
	_commit(before, map.snapshot(), "Change layer " + flag)


func _cancel_gesture() -> void:
	if not _before.is_empty():
		var state := _before
		_before = {}
		_restore(state)
	if workbench: workbench.cancel_drag()
