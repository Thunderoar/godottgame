class_name DialoguePanel
extends ModalBase
## Persistent dialogue box used by special NPCs. Replaces transient dialogue
## notifications with a readable modal and an explicit close action.

var _speaker := "NPC"
var _lines: Array[String] = []


func _ready() -> void:
	_panel_size = Vector2(620, 380)
	super._ready()


func open_dialogue(speaker: String, lines: Array) -> void:
	_speaker = speaker
	_lines.clear()
	for line in lines:
		_lines.append(str(line))
	open_panel(speaker)


func _rebuild() -> void:
	_clear_content()
	add_body_text(_speaker, GameUI.GOLD, 20)
	for line in _lines:
		var label := GameUI.label(line, 18, GameUI.TEXT)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.add_child(label)
	content.add_child(GameUI.spacer(8))
	var close := GameUI.button("Close", Vector2(180, 44))
	close.pressed.connect(close_panel)
	content.add_child(close)
