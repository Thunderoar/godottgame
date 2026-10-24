class_name LoadingScreen
extends CanvasLayer
## Render the loading cover before rebuilding a destination, then fade it away.
var cover: ColorRect
var destination: Label
var dots: Label
var _clock := 0.0
var active := false
var _tween: Tween

func _ready() -> void:
	layer = 400
	cover = ColorRect.new()
	cover.color = Color("#101e25")
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(cover)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cover.add_child(centre)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 12)
	centre.add_child(stack)
	var logo := GameUI.label("PB", 76, GameUI.GOLD)
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(logo)
	var subtitle := GameUI.label("PROTECT BESUT", 20, GameUI.TEXT)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(subtitle)
	var icons := HBoxContainer.new()
	icons.alignment = BoxContainer.ALIGNMENT_CENTER
	for texture in [PixelArt.npc_texture("tree_planter"), PixelArt.house_texture(3), PixelArt.pet_texture("ember")]:
		var picture := TextureRect.new()
		picture.texture = texture
		picture.custom_minimum_size = Vector2(86, 76)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icons.add_child(picture)
	stack.add_child(icons)
	destination = GameUI.label("", 21, GameUI.TEAL)
	destination.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(destination)
	dots = GameUI.label("•  •  •", 24, GameUI.GOLD)
	dots.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(dots)
	cover.hide()

func _process(delta: float) -> void:
	if not active:
		return
	_clock += delta
	dots.text = ["●  ·  ·", "·  ●  ·", "·  ·  ●"][int(_clock * 4) % 3]

func begin(place: String) -> void:
	active = true
	destination.text = place
	cover.show()
	cover.modulate.a = 0
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(cover, "modulate:a", 1.0, 0.12)
	await _tween.finished
	await get_tree().process_frame

func finish() -> void:
	await get_tree().process_frame
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(cover, "modulate:a", 0.0, 0.18)
	await _tween.finished
	cover.hide()
	active = false
