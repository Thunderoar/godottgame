@tool
extends VBoxContainer
const W := preload("res://addons/tidesworn_creative_tools/widgets.gd")
const Canvas := preload("res://addons/tidesworn_creative_tools/creative_canvas.gd")
const CELL := 8
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
var _start := Vector2i.ZERO
var _last := Vector2i.ZERO
var _selection := Rect2i()
var _base: Image
var _base_generation := -1
var _local_history := UndoRedo.new()

func _ready() -> void:
	base = load("res://data/maps/village_objects.tres") as AuthoredMap
	map = (load(path) as AuthoredMap).duplicate(true)
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
	W.button(bar, "Play this map", _play)
	bar = W.row(self)
	layer = W.option(bar, AuthoredMap.LAYERS)
	terrain_choice = W.option(bar, AuthoredMap.MATERIALS)
	tool = W.option(bar, ["Pencil", "Eraser", "Rectangle", "Fill", "Eyedropper", "Select", "Move", "Place object", "Select object", "Move object"])
	brush = W.number(bar, "Brush", 1, 1, 8)
	tool.item_selected.connect(func(index: int) -> void:
		if index == 7: _lock_base_properties(false))
	bar = W.row(self)
	locked = W.check(bar, "Lock layer")
	shown = W.check(bar, "Visible", true)
	snap = W.check(bar, "Snap objects", true)
	var grid := W.check(bar, "Grid", true)
	grid.toggled.connect(func(on: bool) -> void: canvas.grid = on; canvas.queue_redraw())
	layer.item_selected.connect(func(_i: int) -> void:
		locked.set_pressed_no_signal(_locked.get(_layer(), false))
		shown.set_pressed_no_signal(not _hidden.get(_layer(), false)))
	locked.toggled.connect(func(on: bool) -> void: _locked[_layer()] = on; dirty = true; refresh())
	shown.toggled.connect(func(on: bool) -> void: _hidden[_layer()] = not on; dirty = true; refresh())
	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(split)
	canvas = Canvas.new()
	canvas.zoom = 1.0
	canvas.grid_step = CELL
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(canvas)
	canvas.pressed.connect(_press)
	canvas.dragged.connect(_drag)
	canvas.released.connect(_release)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.x = 265
	split.add_child(scroll)
	var properties := VBoxContainer.new()
	scroll.add_child(properties)
	W.label(properties, "OBJECT • stable identity")
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
	var seed_box := W.number(properties, "Decoration seed", map.seed_value, 0, 999999)
	W.button(properties, "Seed flower clusters", func() -> void: _decorate(int(seed_box.value)))
	W.label(properties, "Wheel: zoom • middle drag: pan
Paint layers override procedural terrain.
Water and Collision layers block actors.
Select then Move shifts a tile region.
Place props with an imported ID or:
tree, house, garden, flowers, fence, sign.")
	for child in properties.get_children():
		if child is Label and child.text.length() > 60:
			child.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			child.custom_minimum_size.x = 230
	status = W.label(self, "")
	refresh()

func _layer() -> String:
	return layer.get_item_text(layer.selected)

func refresh() -> void:
	if canvas == null or map == null: return
	if _base == null or _base_generation != WorldPalette.generation:
		_base = WorldTerrain._make_terrain_texture().get_image().duplicate() as Image
		_base.resize(map.size.x * CELL, map.size.y * CELL, Image.INTERPOLATE_NEAREST)
		_base_generation = WorldPalette.generation
	var image := _base.duplicate() as Image
	for name in AuthoredMap.LAYERS:
		if _hidden.get(name, false): continue
		for at in map.layers.get(name, {}):
			var tile := AuthoredMapRenderer.tile_image(map.cell(name, at), at, map, name)
			tile.resize(CELL, CELL, Image.INTERPOLATE_NEAREST)
			image.blend_rect(tile, Rect2i(Vector2i.ZERO, Vector2i(CELL, CELL)), at * CELL)
	for data in _preview_objects():
		var texture := AuthoredMapRenderer.object_texture(str(data.get("asset", "")))
		if texture == null: continue
		var img := texture.get_image().duplicate() as Image
		var target_size := Vector2i(Vector2(img.get_size()) * (float(CELL) / 32.0) * float(data.get("scale", 1.0))).max(Vector2i.ONE)
		img.resize(target_size.x, target_size.y, Image.INTERPOLATE_NEAREST)
		var p: Vector2 = data.get("position", Vector2.ZERO)
		image.blend_rect(img, Rect2i(Vector2i.ZERO, target_size), Vector2i(p * CELL) - Vector2i(int(target_size.x / 2), target_size.y))
	canvas.show_image(image)
	canvas.selection = Rect2i(_selection.position * CELL, _selection.size * CELL)
	canvas.queue_redraw()
	status.text = ("● UNSAVED  " if dirty else "Saved  ") + path + " • %d authored objects • %d validation warnings" % [map.objects.size(), map.warnings().size()]

func _press(at: Vector2i) -> void:
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

func _select_object(at: Vector2i) -> void:
	selected_object = -1
	var distance := 2.0
	var chosen := {}
	for data in _preview_objects():
		var p: Vector2 = data.position
		var d := p.distance_to(Vector2(at) / CELL)
		if d < distance:
			distance = d
			chosen = data
	if chosen.is_empty(): return
	if chosen.get("protected", false):
		studio.report("Protected village service: use settlement Build mode to move the cottage or existing shops safely.")
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
	studio.report("Selected " + str(data.id))

func _object_properties() -> Dictionary:
	var meta: Variant = JSON.parse_string(metadata.text)
	if not meta is Dictionary: studio.report("Object metadata must be a JSON object."); return {}
	return {"asset": asset.text, "label": object_label.text, "depth": int(depth.value), "scale": scale_value.value, "blocking": blocking.button_pressed, "interactive": interactive.button_pressed, "footprint": Vector2(footprint_x.value, footprint_y.value), "metadata": meta, "kind": meta.get("kind", "prop")}

func _apply_object() -> void:
	if selected_object < 0: return
	var data := _object_properties()
	if data.is_empty(): return
	var before := map.snapshot()
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
		history.add_do_method(self, "_restore", after)
		history.add_undo_method(self, "_restore", before)
		history.commit_action()
	else:
		_local_history.create_action(title)
		_local_history.add_do_method(_restore.bind(after))
		_local_history.add_undo_method(_restore.bind(before))
		_local_history.commit_action()

func _restore(state: Dictionary) -> void:
	map.restore(state)
	dirty = true
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
		selected_object = -1
		_local_history.clear_history()
		refresh())

func _load(source: String) -> void:
	var loaded := load(source) as AuthoredMap
	if loaded == null: studio.report("Select an AuthoredMap resource."); return
	studio.confirm_discard(dirty, func() -> void:
		map = loaded.duplicate(true)
		_hidden = map.editor_hidden
		_locked = map.editor_locked
		path = source
		dirty = false
		selected_object = -1
		_local_history.clear_history()
		if map.palette: WorldPalette.use_palette(map.palette)
		refresh())

func _save(destination: String) -> void:
	map.editor_hidden = _hidden
	map.editor_locked = _locked
	var result := ResourceSaver.save(map, destination)
	if result == OK:
		path = destination
		dirty = false
		if Engine.is_editor_hint(): EditorInterface.get_resource_filesystem().scan()
	refresh()
	studio.report("Saved map: " + destination if result == OK else error_string(result))

func _validate() -> void:
	var warnings := map.warnings()
	studio.report("Map validation: " + ("no protected-area conflicts. Check routes in Play." if warnings.is_empty() else "
".join(warnings)))

func _play() -> void:
	if dirty: studio.report("Save the map before launching it."); return
	if not map.warnings().is_empty(): studio.report("Resolve protected-area conflicts before Play: " + "
".join(map.warnings())); return
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
	for i in 32:
		var at := Vector2i(rng.randi_range(3, map.size.x - 4), rng.randi_range(3, map.size.y - 4))
		if map.cell("Decoration", at).is_empty(): map.paint("Decoration", at, "flower")
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
			if not overridden: result.append(object)
	result.append_array(map.objects)
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
