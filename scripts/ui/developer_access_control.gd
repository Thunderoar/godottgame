class_name DeveloperAccessControl
extends VBoxContainer
## Shared by title, village and ocean settings. Unlock lasts for this app session.
var code_input: LineEdit
var message: Label
var _locked: VBoxContainer
var _unlocked: HBoxContainer

func _ready() -> void:
	add_theme_constant_override("separation",8)
	add_child(GameUI.divider(Color("#38545a")))
	add_child(GameUI.label("DEVELOPER ACCESS",14,GameUI.GOLD))
	_locked = VBoxContainer.new()
	add_child(_locked)
	var row := HBoxContainer.new()
	_locked.add_child(row)
	code_input = LineEdit.new()
	code_input.name = "DeveloperCode"
	code_input.secret = true
	code_input.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_PASSWORD
	code_input.max_length = 128
	code_input.placeholder_text = "Developer unlock code"
	code_input.custom_minimum_size = Vector2(180,42)
	code_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	code_input.text_submitted.connect(func(_text: String) -> void: _unlock())
	row.add_child(code_input)
	var unlock := GameUI.button("Unlock",Vector2(108,42))
	unlock.name = "UnlockDeveloper"
	unlock.pressed.connect(_unlock)
	row.add_child(unlock)
	_unlocked = HBoxContainer.new()
	add_child(_unlocked)
	var tools := GameUI.button("Open developer tools",Vector2(220,44))
	tools.pressed.connect(func() -> void:
		var game := get_tree().get_first_node_in_group("game") as Game
		if is_instance_valid(game): game.open_developer_tools())
	_unlocked.add_child(tools)
	var lock := GameUI.button("Lock",Vector2(90,44))
	lock.pressed.connect(func() -> void:
		var game := get_tree().get_first_node_in_group("game") as Game
		if GameState.developer_session_active() and is_instance_valid(game): game.end_developer_test(true)
		else: GameSettings.lock_developer())
	_unlocked.add_child(lock)
	message = GameUI.label("Developer tools require an unlock code.",13,GameUI.MUTED)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(message)
	GameSettings.changed.connect(_on_setting_changed)
	_refresh()

func _unlock() -> void:
	var entered := code_input.text
	code_input.clear()
	if GameSettings.unlock_developer(entered):
		message.text = "Developer access unlocked for this app session."
	else:
		message.text = "Code not accepted. Wait a moment and try again."
	_refresh()

func _on_setting_changed(key: String) -> void:
	if key == "developer_access":
		code_input.clear()
		_refresh()

func _refresh() -> void:
	var unlocked := GameSettings.is_developer_unlocked()
	_locked.visible = not unlocked
	_unlocked.visible = unlocked
	if unlocked: message.text = "Unlocked for this app session. Test tools use a separate journey."
