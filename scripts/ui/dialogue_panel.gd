class_name DialoguePanel
extends ModalBase
## Persistent dialogue box used by special NPCs. Replaces transient dialogue
## notifications with a readable modal and an explicit close action.

var _speaker := "NPC"
var _lines: Array[String] = []


func _ready() -> void:
	z_index = 200 # Keep story clues above tutorial cards and the ordinary HUD.
	_panel_size = Vector2(620, 380)
	super._ready()
	body.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED


func open_dialogue(speaker: String, lines: Array) -> void:
	_speaker = speaker
	_lines.clear()
	for line in lines:
		_lines.append(str(line))
	open_panel(speaker)


func _rebuild() -> void:
	_clear_content()
	for line in _lines:
		var label := GameUI.label(line, 18, GameUI.TEXT)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.add_child(label)
	# The fixed header already owns the title and Close button. Keep the body
	# for text so the full clue fits without duplicate headings or hidden buttons.
