@tool
extends VBoxContainer
const W := preload("res://addons/tidesworn_creative_tools/widgets.gd")
const Canvas := preload("res://addons/tidesworn_creative_tools/creative_canvas.gd")
var studio: Control
var document := TidePixelDocument.new()
var canvas: Control
var tool: OptionButton
var picker: ColorPickerButton
var swatches: HFlowContainer
var recents: HFlowContainer
var frame_list: ItemList
var duration: SpinBox
var status: Label
var dimensions: OptionButton
var sheet_w: SpinBox
var sheet_h: SpinBox
var _start := Vector2i.ZERO
var _last := Vector2i.ZERO
var _stroke := false
var _playing := false
var _clock := 0.0
var _preview: Image
var _old_color := Color.TRANSPARENT

func _ready() -> void:
	var top := W.row(self)
	dimensions = W.option(top, ["16×16", "32×32", "64×64", "128×128"])
	dimensions.select(1)
	W.button(top, "New", _new)
	W.button(top, "Open PNG…", func() -> void: W.dialog(self, ["*.png ; PNG"], false, func(path: String) -> void: open_image(path)).popup_centered())
	W.button(top, "Save", _save)
	W.button(top, "Save As / Export sheet…", _save_as)
	W.button(top, "Undo", document.undo)
	W.button(top, "Redo", document.redo)
	var bar := W.row(self)
	tool = W.option(bar, ["Pencil", "Eraser", "Picker", "Fill", "Line", "Rectangle", "Select", "Move"])
	picker = ColorPickerButton.new()
	picker.custom_minimum_size = Vector2(60, 28)
	picker.color = document.color
	bar.add_child(picker)
	picker.color_changed.connect(func(color: Color) -> void: _old_color = document.color; document.color = color)
	var grid := W.check(bar, "Pixel grid", true)
	grid.toggled.connect(func(on: bool) -> void: canvas.grid = on; canvas.queue_redraw())
	W.button(bar, "Replace picked colour", func() -> void: document.replace_color(_old_color, picker.color))
	W.button(bar, "Preview palette", _preview_palette)
	W.button(bar, "Apply preview", _apply_preview)
	W.button(bar, "Cancel preview", func() -> void: _preview = null; refresh())
	swatches = HFlowContainer.new()
	add_child(swatches)
	recents = HFlowContainer.new()
	add_child(recents)
	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(split)
	canvas = Canvas.new()
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(canvas)
	canvas.pressed.connect(_press)
	canvas.dragged.connect(_drag)
	canvas.released.connect(_release)
	var side := VBoxContainer.new()
	side.custom_minimum_size.x = 220
	split.add_child(side)
	W.label(side, "ANIMATION FRAMES")
	frame_list = ItemList.new()
	frame_list.custom_minimum_size.y = 160
	frame_list.fixed_icon_size = Vector2i(48, 48)
	frame_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame_list.item_selected.connect(func(index: int) -> void:
		document.index = index
		_clock = 0.0
		refresh())
	side.add_child(frame_list)
	bar = W.row(side)
	W.button(bar, "+", func() -> void: document.add_frame())
	W.button(bar, "Duplicate", func() -> void: document.add_frame(true))
	W.button(bar, "Remove", document.remove_frame)
	bar = W.row(side)
	W.button(bar, "← Frame", func() -> void: document.reorder(-1))
	W.button(bar, "Frame →", func() -> void: document.reorder(1))
	W.button(side, "Play / pause", func() -> void: _playing = not _playing)
	duration = W.number(side, "Frame duration (seconds)", 0.13, 0.02, 10.0)
	duration.step = 0.01
	duration.value_changed.connect(func(value: float) -> void:
		if not is_equal_approx(document.durations[document.index], value):
			document.checkpoint()
			document.durations[document.index] = value
			document.changed.emit())
	bar = W.row(side)
	sheet_w = W.number(bar, "Sheet W", 32, 1, 512)
	sheet_h = W.number(bar, "H", 32, 1, 512)
	W.button(side, "Import sprite sheet…", func() -> void:
		W.dialog(self, ["*.png ; PNG sprite sheet"], false, func(path: String) -> void: open_image(path, Vector2i(sheet_w.value, sheet_h.value))).popup_centered())
	W.button(side, "Import PNG sequence…", _sequence_dialog)
	W.button(side, "Register saved artwork", _register)
	W.label(side, "Wheel: zoom • middle drag: pan
Select a rectangle, then Move it.
Picker also selects replacement source.
PNG export includes frame durations.
Save before switching to another asset.")
	status = W.label(self, "")
	document.changed.connect(refresh)
	set_process(true)
	rebuild_swatches()
	refresh()

func _process(delta: float) -> void:
	if not visible or not _playing: return
	_clock += delta
	if _clock >= document.durations[document.index]:
		_clock = 0.0
		document.index = (document.index + 1) % document.frames.size()
		refresh(false)

func rebuild_swatches() -> void:
	if swatches == null: return
	for child in swatches.get_children(): child.queue_free()
	for role in WorldPalette.current().world:
		var color: Color = WorldPalette.current().world[role]
		var button := W.button(swatches, " ", func() -> void: picker.color = color; document.color = color)
		button.tooltip_text = role + " #" + color.to_html(false)
		W.swatch(button, color)
		button.custom_minimum_size = Vector2(30, 26)

func refresh(rebuild_frames: bool = true) -> void:
	if canvas == null: return
	canvas.show_image(_preview if _preview != null else document.image())
	canvas.selection = document.selection
	canvas.queue_redraw()
	duration.set_value_no_signal(document.durations[document.index])
	if rebuild_frames:
		frame_list.clear()
		for i in document.frames.size():
			frame_list.add_item("%02d • %.2fs" % [i + 1, document.durations[i]], ImageTexture.create_from_image(document.frames[i]))
	frame_list.select(document.index)
	status.text = ("● UNSAVED  " if document.dirty else "Saved  ") + (document.source_path if not document.source_path.is_empty() else "Untitled") + " • %s • Frame %d/%d" % [document.image().get_size(), document.index + 1, document.frames.size()]

func _press(at: Vector2i) -> void:
	if not document.inside(at) or _playing: return
	if _preview != null: studio.report("Apply or cancel the palette preview before drawing."); return
	_start = at
	_last = at
	_stroke = true
	var name := tool.get_item_text(tool.selected)
	if name == "Picker":
		_old_color = document.image().get_pixelv(at)
		document.color = _old_color
		picker.color = _old_color
		return
	if name == "Select": return
	document.checkpoint()
	if name in ["Pencil", "Eraser"]: document.line(at, at, Color.TRANSPARENT if name == "Eraser" else picker.color)
	elif name == "Fill": document.fill(at, picker.color)
	_remember(picker.color)

func _drag(at: Vector2i) -> void:
	if not _stroke: return
	var name := tool.get_item_text(tool.selected)
	if name in ["Pencil", "Eraser"]:
		# Clamp before Bresenham so a far off-canvas cursor cannot allocate unbounded work.
		at = at.clamp(Vector2i.ZERO, document.image().get_size() - Vector2i.ONE)
		document.line(_last, at, Color.TRANSPARENT if name == "Eraser" else picker.color)
		_last = at
	elif name in ["Select", "Line", "Rectangle"]:
		canvas.selection = Rect2i(_start.min(at), (at - _start).abs() + Vector2i.ONE)
		canvas.queue_redraw()

func _release(at: Vector2i) -> void:
	if not _stroke: return
	_stroke = false
	at = at.clamp(Vector2i.ZERO, document.image().get_size() - Vector2i.ONE)
	match tool.get_item_text(tool.selected):
		"Line": document.line(_start, at, picker.color)
		"Rectangle": document.rectangle(_start, at, picker.color)
		"Select": document.selection = Rect2i(_start.min(at), (at - _start).abs() + Vector2i.ONE)
		"Move": document.move_selection(at - _start)
	refresh()

func _remember(color: Color) -> void:
	document.recent.erase(color)
	document.recent.push_front(color)
	if document.recent.size() > 12: document.recent.pop_back()
	for child in recents.get_children(): child.queue_free()
	W.label(recents, "Recent")
	for ink in document.recent:
		var button := W.button(recents, " ", func() -> void: picker.color = ink; document.color = ink)
		W.swatch(button, ink)

func _new() -> void:
	studio.confirm_discard(document.dirty, func() -> void:
		var size_value := [16, 32, 64, 128][dimensions.selected] as int
		document.new_image(Vector2i(size_value, size_value))
		canvas.zoom = minf(12, 384.0 / size_value)
		_preview = null
		refresh())

func open_image(path: String, frame_size := Vector2i.ZERO) -> void:
	studio.confirm_discard(document.dirty, func() -> void:
		var result := document.load_png(path, frame_size)
		if result != OK: studio.report("Open failed: " + error_string(result) + ". Frame dimensions must divide the image; max 512px/frame, 64 frames."); return
		canvas.zoom = minf(12, 384.0 / document.image().get_width())
		_preview = null
		refresh())

func _save() -> void:
	if document.source_path.is_empty(): _save_as(); return
	_save_to(document.source_path)

func _save_as() -> void:
	W.dialog(self, ["*.png ; PNG sprite sheet"], true, _save_to).popup_centered()

func _save_to(path: String) -> void:
	var result := document.save_png(path)
	if result == OK:
		AssetRegistry.invalidate()
		if Engine.is_editor_hint():
			EditorInterface.get_resource_filesystem().update_file(path)
			EditorInterface.get_resource_filesystem().scan()
	studio.report("PNG + frame durations saved: " + path if result == OK else "Save failed: " + error_string(result))
	refresh()

func _preview_palette() -> void:
	var colors: Array[Color] = []
	for ink in WorldPalette.current().world.values(): colors.append(ink)
	_preview = document.quantized(colors)
	refresh()

func _apply_preview() -> void:
	if _preview == null: return
	document.checkpoint()
	document.frames[document.index] = _preview
	_preview = null
	document.changed.emit()

func _sequence_dialog() -> void:
	var dialog := W.dialog(self, ["*.png ; PNG sequence"], false, func(_path: String) -> void: pass)
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILES
	dialog.files_selected.connect(func(paths: PackedStringArray) -> void:
		studio.confirm_discard(document.dirty, func() -> void:
			if paths.is_empty() or paths.size() > 64: studio.report("Select 1–64 frames."); return
			paths.sort()
			var images: Array[Image] = []
			var size_value := Vector2i.ZERO
			for path in paths:
				var image := Image.load_from_file(path)
				if image == null or image.get_width() > 512 or image.get_height() > 512: studio.report("Invalid PNG frame: " + path); return
				if size_value == Vector2i.ZERO: size_value = image.get_size()
				if image.get_size() != size_value: studio.report("Sequence dimensions must match."); return
				images.append(image)
			document.checkpoint()
			document.frames = images
			document.durations.clear()
			for image in images: document.durations.append(0.13)
			document.index = 0
			document.source_path = ""
			document.changed.emit()))
	dialog.popup_centered()

func _register() -> void:
	if document.dirty or document.source_path.is_empty(): studio.report("Save the PNG before registering it."); return
	# Register the actual saved file, without creating an extra copy.
	var id := "authored/" + document.source_path.get_file().get_basename()
	AssetRegistry.library().entries[id] = {"path": document.source_path, "category": "Animations" if document.frames.size() > 1 else "Props", "frame_size": document.image().get_size(), "columns": document.frames.size(), "frames": document.frames.size(), "durations": document.durations.duplicate(), "fps": 1.0 / document.durations[0], "license": "Original project artwork"}
	ResourceSaver.save(AssetRegistry.library(), AssetRegistry.PATH)
	AssetRegistry.invalidate()
	studio.asset_panel.refresh()
	studio.report("Registered " + id + ". Use this asset ID when placing a map object.")
