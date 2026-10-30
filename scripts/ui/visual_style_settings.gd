class_name VisualStyleSettings
extends VBoxContainer
## Shared by title, village and ocean settings; does not touch journey data.
var _choice: OptionButton
var _note: Label
var _frame_rate: OptionButton
var _resolution: OptionButton

func _ready() -> void:
	add_theme_constant_override("separation", 6)
	add_child(GameUI.label("Art style", 14, GameUI.TEXT))
	_choice = OptionButton.new()
	_choice.name = "VisualStyleOption"
	_choice.custom_minimum_size = Vector2(0, 44)
	_choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for label in GameSettings.VISUAL_STYLE_LABELS:
		_choice.add_item(label)
	_choice.item_selected.connect(func(index: int) -> void:
		GameSettings.set_visual_style(str(GameSettings.VISUAL_STYLES[index])))
	add_child(_choice)
	_note = GameUI.label("", 13, GameUI.MUTED)
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_note)
	if OS.has_feature("android"):
		add_child(GameUI.label("Frame rate", 14, GameUI.TEXT))
		_frame_rate = OptionButton.new()
		_frame_rate.name = "FrameRateOption"
		_frame_rate.custom_minimum_size.y = 44
		_frame_rate.add_item("60 FPS")
		_frame_rate.add_item("30 FPS · Battery saver")
		_frame_rate.item_selected.connect(func(index: int) -> void: GameSettings.set_value("target_fps", GameSettings.FRAME_RATES[index]))
		add_child(_frame_rate)
		add_child(GameUI.label("Rendering resolution", 14, GameUI.TEXT))
		_resolution = OptionButton.new()
		_resolution.name = "RenderResolutionOption"
		_resolution.custom_minimum_size.y = 44
		_resolution.add_item("Balanced · Lower GPU load")
		_resolution.add_item("Native · Sharper image")
		_resolution.item_selected.connect(func(index: int) -> void: GameSettings.set_value("render_resolution", GameSettings.RENDER_RESOLUTIONS[index]))
		add_child(_resolution)
	GameSettings.changed.connect(_on_setting_changed)
	_on_setting_changed("visual_style")

func _on_setting_changed(key: String) -> void:
	if is_instance_valid(_frame_rate):
		_frame_rate.selected = GameSettings.FRAME_RATES.find(GameSettings.target_fps())
		_resolution.selected = GameSettings.RENDER_RESOLUTIONS.find(GameSettings.render_resolution())
	if key != "visual_style":
		return
	_choice.selected = GameSettings.VISUAL_STYLES.find(GameSettings.visual_style())
	_note.text = "Restart the game to apply this style. Your journey is unchanged." if GameSettings.visual_style() != GameSettings.active_visual_style() else "Village, characters, portals and ocean art. Style changes apply after restarting the game."
