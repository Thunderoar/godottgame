class_name VisualStyleSettings
extends VBoxContainer
## Shared by title, village and ocean settings; does not touch journey data.
var _choice: OptionButton
var _note: Label

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
	GameSettings.changed.connect(_on_setting_changed)
	_on_setting_changed("visual_style")

func _on_setting_changed(key: String) -> void:
	if key != "visual_style":
		return
	_choice.selected = GameSettings.VISUAL_STYLES.find(GameSettings.visual_style())
	_note.text = "Restart the game to apply this style. Your journey is unchanged." if GameSettings.visual_style() != GameSettings.active_visual_style() else "Village, characters, portals and ocean art. Style changes apply after restarting the game."
