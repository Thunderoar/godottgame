@tool
extends VBoxContainer
const W := preload("res://addons/tidesworn_creative_tools/widgets.gd")
const CATEGORIES := ["All", "Terrain", "Characters", "NPCs", "Enemies", "Pets", "Buildings", "Props", "Effects", "UI icons", "Animations", "Miscellaneous"]
var studio: Control
var search: LineEdit
var category: OptionButton
var assets: ItemList
var preview: TextureRect
var details: Label
var semantic: LineEdit
var provenance: LineEdit
var width: SpinBox
var height: SpinBox
var columns: SpinBox
var count: SpinBox
var fps: SpinBox
var margin: SpinBox
var spacing: SpinBox
var pivot_x: SpinBox
var pivot_y: SpinBox
var required: CheckBox
var selected_id := ""
var ids: Array[String] = []
var pending_imports := PackedStringArray()
var _clock := 0.0
var _frame := 0
var animation := false
var import_dialog: FileDialog

func _ready() -> void:
	var top := W.row(self)
	W.button(top, "Import image / sequence…", _choose_import)
	W.button(top, "Refresh / reimport", refresh_sources)
	search = W.entry(top, "Search semantic ID or path")
	search.text_changed.connect(func(_text: String) -> void: refresh())
	category = W.option(top, CATEGORIES)
	category.item_selected.connect(func(_index: int) -> void: refresh())
	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(split)
	assets = ItemList.new()
	assets.custom_minimum_size.x = 300
	assets.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	assets.icon_mode = ItemList.ICON_MODE_TOP
	assets.fixed_icon_size = Vector2i(64, 64)
	assets.item_selected.connect(_select)
	split.add_child(assets)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.x = 440
	split.add_child(scroll)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(info)
	preview = TextureRect.new()
	preview.custom_minimum_size = Vector2(250, 170)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	info.add_child(preview)
	details = W.label(info, "Import an original image, or drop project files here.
Select an asset to preview and edit its runtime override.")
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	semantic = W.entry(info, "Runtime ID (e.g. house_1 or character/qayyim)")
	provenance = W.entry(info, "Source / author / license (record before sharing)")
	var fields := W.row(info)
	width = W.number(fields, "Frame W", 32, 1)
	height = W.number(fields, "H", 32, 1)
	fields = W.row(info)
	columns = W.number(fields, "Columns", 1, 1, 128)
	count = W.number(fields, "Frames", 1, 1, 256)
	fps = W.number(fields, "FPS", 8, 1, 60)
	fields = W.row(info)
	margin = W.number(fields, "Margin", 0)
	spacing = W.number(fields, "Spacing", 0)
	fields = W.row(info)
	pivot_x = W.number(fields, "Pivot X", 16, -512, 512)
	pivot_y = W.number(fields, "Y", 32, -512, 512)
	required = W.check(info, "Required asset (missing path is an error)")
	fields = W.row(info)
	W.button(fields, "Save ID / override", save_entry)
	W.button(fields, "Edit pixels", _edit_pixels)
	W.button(fields, "Play / pause", func() -> void: animation = not animation)
	W.button(info, "Remove override (keeps source file)", _remove)
	W.label(info, "32 pixels = 1 world unit • nearest filtering
Use frame dimensions that match the original artwork.
Overrides: house_1, npc_fisher, icon_flower, character/qayyim.
Map objects can use any registered ID.")
	refresh()
	set_process(true)

func _process(delta: float) -> void:
	if not visible or not animation or selected_id.is_empty(): return
	_clock += delta
	if _clock >= 1.0 / maxf(1, fps.value):
		_clock = 0.0
		_frame = (_frame + 1) % maxi(1, int(count.value))
		preview.texture = AssetRegistry.get_texture(selected_id, _frame)

func _choose_import() -> void:
	import_dialog = W.dialog(self, ["*.png, *.webp, *.jpg, *.jpeg, *.svg ; Images", "*.tres, *.res ; Godot texture resources"], false, _import_file, true)
	import_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILES
	import_dialog.files_selected.connect(_import_files)
	import_dialog.popup_centered()

func _import_files(paths: PackedStringArray) -> void:
	for path in paths: _import_file(path)

func _import_file(path: String) -> void:
	var image: Image
	if path.get_extension().to_lower() in ["tres", "res"]:
		var resource := load(path) as Texture2D
		if resource: image = resource.get_image()
	else:
		image = Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.is_empty():
		studio.report("Cannot import: supported images or Texture2D resources only: " + path)
		return
	if image.get_width() > 4096 or image.get_height() > 4096:
		studio.report("Image exceeds the 4096×4096 import limit.")
		return
	var group := category.get_item_text(category.selected)
	if group == "All": group = "Miscellaneous"
	var directory := "res://assets/authored/" + group.to_snake_case()
	DirAccess.make_dir_recursive_absolute(directory)
	var base := path.get_file().get_basename().validate_filename().to_snake_case()
	var dest := directory.path_join(base + ".png")
	var suffix := 1
	while FileAccess.file_exists(dest):
		dest = directory.path_join(base + "_%d.png" % suffix)
		suffix += 1
	image.convert(Image.FORMAT_RGBA8)
	var result := image.save_png(dest)
	if result != OK:
		studio.report("Import failed: " + error_string(result))
		return
	var id := group.to_snake_case() + "/" + dest.get_file().get_basename()
	AssetRegistry.library().entries[id] = {"path": dest, "category": group, "source": path, "license": "Unspecified — add provenance", "frame_size": Vector2i.ZERO, "columns": 1, "frames": 1, "fps": 8.0, "pivot": Vector2(image.get_width() * 0.5, image.get_height()), "required": false}
	selected_id = id
	ResourceSaver.save(AssetRegistry.library(), AssetRegistry.PATH)
	AssetRegistry.invalidate()
	if Engine.is_editor_hint(): EditorInterface.get_resource_filesystem().scan()
	refresh()
	for i in ids.size():
		if ids[i] == id:
			assets.select(i)
			_select(i)
	studio.report("Imported " + id + ". Set provenance and a semantic override, or place it in a map.")

func refresh_sources() -> void:
	AssetRegistry.invalidate()
	if Engine.is_editor_hint():
		var files := PackedStringArray()
		for entry in AssetRegistry.library().entries.values(): files.append(str(entry.path))
		if not files.is_empty(): EditorInterface.get_resource_filesystem().reimport_files(files)
	refresh()
	studio.report("Asset cache cleared; imported source resources refreshed.")

func refresh() -> void:
	if assets == null: return
	assets.clear()
	ids.clear()
	var keys := AssetRegistry.library().entries.keys()
	keys.sort()
	for id in keys:
		var entry: Dictionary = AssetRegistry.library().entries[id]
		if category.selected > 0 and entry.get("category", "") != category.get_item_text(category.selected): continue
		if not search.text.is_empty() and not (str(id) + str(entry.get("path", ""))).to_lower().contains(search.text.to_lower()): continue
		ids.append(id)
		var icon: Texture2D
		if ResourceLoader.exists(str(entry.path)):
			icon = AssetRegistry.get_texture(id)
		elif FileAccess.file_exists(str(entry.path)):
			var image := Image.load_from_file(ProjectSettings.globalize_path(str(entry.path)))
			if image: icon = ImageTexture.create_from_image(image)
		assets.add_item(str(id), icon)

func _select(index: int) -> void:
	if index < 0 or index >= ids.size(): return
	selected_id = ids[index]
	var entry: Dictionary = AssetRegistry.library().entries[selected_id]
	semantic.text = selected_id
	provenance.text = str(entry.get("license", ""))
	var texture := AssetRegistry.get_texture(selected_id) if ResourceLoader.exists(str(entry.path)) else null
	var image := Image.load_from_file(ProjectSettings.globalize_path(str(entry.path)))
	if image: preview.texture = ImageTexture.create_from_image(image)
	elif texture: preview.texture = texture
	var size: Vector2i = entry.get("frame_size", Vector2i.ZERO)
	if size == Vector2i.ZERO and image: size = image.get_size()
	width.value = size.x
	height.value = size.y
	columns.value = entry.get("columns", 1)
	count.value = entry.get("frames", 1)
	fps.value = entry.get("fps", 8)
	margin.value = entry.get("margin", 0)
	spacing.value = entry.get("spacing", 0)
	var pivot: Vector2 = entry.get("pivot", Vector2(size.x * 0.5, size.y))
	pivot_x.value = pivot.x
	pivot_y.value = pivot.y
	required.button_pressed = entry.get("required", false)
	details.text = "%s
%s
Source: %s
Size: %s • Category: %s
Runtime usage: procedural key override or authored map asset ID" % [selected_id, entry.path, entry.get("source", "local"), image.get_size() if image else Vector2i.ZERO, entry.get("category", "Miscellaneous")]

func save_entry() -> void:
	if selected_id.is_empty() or semantic.text.strip_edges().is_empty():
		studio.report("Select an imported asset and enter a semantic ID.")
		return
	var entry: Dictionary = AssetRegistry.library().entries[selected_id].duplicate(true)
	var size := Vector2i(width.value, height.value)
	var image := Image.load_from_file(ProjectSettings.globalize_path(str(entry.path)))
	if image == null: studio.report("Missing source image."); return
	var end := Vector2i(int(margin.value) + (int(columns.value) - 1) * (size.x + int(spacing.value)) + size.x, int(margin.value) + (int(ceil(count.value / columns.value)) - 1) * (size.y + int(spacing.value)) + size.y)
	if end.x > image.get_width() or end.y > image.get_height():
		studio.report("Frame grid extends outside the source image.")
		return
	entry.merge({"frame_size": size, "columns": int(columns.value), "frames": int(count.value), "fps": fps.value, "margin": int(margin.value), "spacing": int(spacing.value), "pivot": Vector2(pivot_x.value, pivot_y.value), "license": provenance.text, "required": required.button_pressed}, true)
	var id := semantic.text.strip_edges()
	if id != selected_id and AssetRegistry.library().entries.has(id):
		studio.report("ID already exists. Remove its override explicitly before replacing it.")
		return
	AssetRegistry.library().entries[id] = entry
	if id != selected_id: AssetRegistry.library().entries.erase(selected_id)
	selected_id = id
	var result := ResourceSaver.save(AssetRegistry.library(), AssetRegistry.PATH)
	AssetRegistry.invalidate()
	refresh()
	studio.report("Saved runtime override: " + id if result == OK else error_string(result))

func _edit_pixels() -> void:
	if selected_id.is_empty(): return
	var entry: Dictionary = AssetRegistry.library().entries[selected_id]
	studio.open_pixels(str(entry.path), entry.get("frame_size", Vector2i.ZERO))

func _remove() -> void:
	if selected_id.is_empty(): return
	AssetRegistry.library().entries.erase(selected_id)
	ResourceSaver.save(AssetRegistry.library(), AssetRegistry.PATH)
	AssetRegistry.invalidate()
	selected_id = ""
	refresh()

func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("type", "") == "files"

func _drop_data(_at: Vector2, data: Variant) -> void:
	_import_files(PackedStringArray(data.get("files", [])))
