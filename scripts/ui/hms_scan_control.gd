class_name HmsScanControl
extends VBoxContainer
## Embedded in existing settings, so the current modal retains input ownership.

var _status: Label
var _code: TextureRect
var _generate: Button


func _ready() -> void:
	add_theme_constant_override("separation", 8)
	add_child(GameUI.label("SHARE BESUT", 14, GameUI.GOLD))
	var description := GameUI.label("Share the BESUT field guide: game screenshots, the story of three friends, places to explore and ways to protect nature.", 13, GameUI.TEXT)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(description)
	_generate = GameUI.button("Create website QR", Vector2(0, 44))
	_generate.name = "CreateBesutQR"
	_generate.disabled = not HmsScanService.available()
	_generate.pressed.connect(_create_qr)
	add_child(_generate)
	var open_guide := GameUI.button("Open BESUT guide ↗", Vector2(0, 44))
	open_guide.name = "OpenBesutGuide"
	open_guide.pressed.connect(func() -> void: OS.shell_open(HmsScanService.PAGE_URL))
	add_child(open_guide)
	_status = GameUI.label("", 13, GameUI.MUTED)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_status)
	_status.text = "Made on your device with HUAWEI Scan Kit. No sign-in needed." if HmsScanService.available() else "QR sharing is available in the Android HMS build."
	_code = TextureRect.new()
	_code.name = "BesutMessageQR"
	_code.custom_minimum_size = Vector2(224, 224)
	_code.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_code.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_code.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_code.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_code.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_code.hide()
	add_child(_code)
	visibility_changed.connect(_clear_qr)


func _create_qr() -> void:
	var result := HmsScanService.generate_message_qr()
	_code.texture = result.get("texture") as Texture2D
	_code.visible = bool(result.get("ok", false))
	_status.text = "Scan with another phone to open the visual BESUT guide, or share a screenshot. The public page needs an internet connection; no sign-in is required." if _code.visible else str(result.get("message", "Could not create the QR code."))


func _clear_qr() -> void:
	if not is_visible_in_tree():
		_code.texture = null
		_code.hide()
		_status.text = "Made on your device with HUAWEI Scan Kit. No sign-in needed." if HmsScanService.available() else "QR sharing is available in the Android HMS build."
