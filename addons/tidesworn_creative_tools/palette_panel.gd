@tool
extends VBoxContainer
const W := preload("res://addons/tidesworn_creative_tools/widgets.gd")
var studio: Control
var palette: WorldPalette
var swatches: GridContainer
var name_entry: LineEdit
var role_entry: LineEdit
var domain: OptionButton
var picker: ColorPickerButton
var comparison: Label
var path := "res://data/palettes/coast.tres"
var dirty := false

func _ready() -> void:
	palette = (load(path) as WorldPalette).duplicate(true)
	var top := W.row(self)
	name_entry = W.entry(top, "Palette title", palette.title)
	name_entry.text_changed.connect(func(_text: String) -> void: dirty = true)
	W.button(top, "Load palette…", func() -> void: W.dialog(self, ["*.tres ; WorldPalette"], false, _load).popup_centered())
	W.button(top, "Save palette…", func() -> void: W.dialog(self, ["*.tres ; WorldPalette"], true, _save).popup_centered())
	var controls := W.row(self)
	domain = W.option(controls, ["World", "UI"])
	role_entry = W.entry(controls, "Role name", "grass")
	picker = ColorPickerButton.new()
	picker.color = palette.world.grass
	controls.add_child(picker)
	W.button(controls, "Set named swatch", _set_role)
	W.button(controls, "Preview in studio", func() -> void:
		WorldPalette.use_palette(palette, true)
		AssetRegistry.invalidate()
		studio.map_panel.refresh()
		studio.pixel_panel.rebuild_swatches()
		studio.report("Palette preview applied. Save it to persist changes for the game."))
	W.label(self, "ORIGINAL → REVISED • Click a revised swatch to edit. Independent PNGs retain their colours.")
	swatches = GridContainer.new()
	swatches.columns = 5
	add_child(swatches)
	_rebuild()

func _rebuild() -> void:
	for child in swatches.get_children(): child.queue_free()
	var original := load("res://data/palettes/original.tres") as WorldPalette
	for role in palette.world:
		W.label(swatches, role)
		var old := ColorRect.new()
		old.custom_minimum_size = Vector2(80, 30)
		old.color = original.world.get(role, Color.WHITE)
		swatches.add_child(old)
		W.label(swatches, "→")
		var button := ColorPickerButton.new()
		button.custom_minimum_size = Vector2(100, 30)
		button.color = palette.world[role]
		button.color_changed.connect(func(color: Color) -> void:
			palette.world[role] = color
			dirty = true)
		swatches.add_child(button)
		W.label(swatches, (palette.world[role] as Color).to_html(false))

func _set_role() -> void:
	var role := role_entry.text.strip_edges()
	if role.is_empty(): return
	var colors: Dictionary = palette.world if domain.selected == 0 else palette.ui
	colors[role] = picker.color
	dirty = true
	_rebuild()

func _load(source: String) -> void:
	var loaded := load(source) as WorldPalette
	if loaded == null: studio.report("Select a WorldPalette resource."); return
	studio.confirm_discard(dirty, func() -> void:
		palette = loaded.duplicate(true)
		path = source
		name_entry.text = palette.title
		dirty = false
		_rebuild())

func _save(destination: String) -> void:
	palette.title = name_entry.text
	var result := ResourceSaver.save(palette, destination)
	if result == OK:
		path = destination
		dirty = false
		WorldPalette.use_palette(palette, true)
		AssetRegistry.invalidate()
	studio.report("Palette saved: " + destination if result == OK else error_string(result))
