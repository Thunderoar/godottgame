class_name VisualStyleSettings
extends VBoxContainer
## Shared by title, village and ocean settings; does not touch journey data.
var _choice: OptionButton
var _note: Label
var _frame_rate: OptionButton
var _resolution: OptionButton
var _opacity: HSlider
var _opacity_label: Label
var _size_slider: HSlider
var _size_label: Label

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
	add_child(GameUI.label("INTERFACE", 14, GameUI.GOLD))
	add_child(GameUI.label("Interface size", 14, GameUI.TEXT))
	_size_slider = HSlider.new()
	_size_slider.name = "InterfaceSizeSlider"
	_size_slider.min_value = 75
	_size_slider.max_value = 130
	_size_slider.step = 5
	_size_slider.value = GameSettings.ui_scale()
	_size_slider.custom_minimum_size.y = 40
	add_child(_size_slider)
	_size_label = GameUI.label("", 13, GameUI.TEXT)
	_size_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_size_label)
	_size_slider.value_changed.connect(func(value: float) -> void:
		GameSettings.set_ui_scale(roundi(value), false))
	_size_slider.drag_ended.connect(func(_changed: bool) -> void: GameSettings.save_settings())
	_size_slider.focus_exited.connect(GameSettings.save_settings)
	add_child(GameUI.label("HUD opacity", 14, GameUI.TEXT))
	var opacity_label := GameUI.label("", 13, GameUI.TEXT)
	opacity_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var opacity := HSlider.new()
	_opacity = opacity
	_opacity_label = opacity_label
	opacity.name = "InterfaceOpacitySlider"
	opacity.min_value = 25
	opacity.max_value = 100
	opacity.step = 5
	opacity.value = int(GameSettings.get_value("interface_opacity"))
	opacity.custom_minimum_size = Vector2(0, 40)
	opacity_label.text = "%d%% · Lower for a clearer view of the world" % int(opacity.value)
	opacity.value_changed.connect(func(value: float) -> void:
		opacity_label.text = "%d%% · Lower for a clearer view of the world" % int(value)
		GameSettings.set_value("interface_opacity", int(value), false))
	opacity.drag_ended.connect(func(_changed: bool) -> void: GameSettings.save_settings())
	opacity.focus_exited.connect(GameSettings.save_settings)
	add_child(opacity)
	add_child(opacity_label)
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
	_on_setting_changed("ui_scale")

func _on_setting_changed(key: String) -> void:
	if key == "ui_scale" and is_instance_valid(_size_slider):
		_size_slider.set_value_no_signal(GameSettings.ui_scale())
		_size_label.text = "%d%% · Smaller or larger HUD and touch controls" % GameSettings.ui_scale()
	if key == "interface_opacity" and is_instance_valid(_opacity):
		_opacity.set_value_no_signal(int(GameSettings.get_value("interface_opacity")))
		_opacity_label.text = "%d%% · Lower for a clearer view of the world" % int(_opacity.value)
	if is_instance_valid(_frame_rate):
		_frame_rate.selected = GameSettings.FRAME_RATES.find(GameSettings.target_fps())
		_resolution.selected = GameSettings.RENDER_RESOLUTIONS.find(GameSettings.render_resolution())
	if key != "visual_style":
		return
	_choice.selected = GameSettings.VISUAL_STYLES.find(GameSettings.visual_style())
	_note.text = "Restart the game to apply this style. Your journey is unchanged." if GameSettings.visual_style() != GameSettings.active_visual_style() else "Village, characters, portals and ocean art. Style changes apply after restarting the game."
