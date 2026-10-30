class_name DeveloperPanel
extends ModalBase
## Explicit developer workbench. Only this panel suspends a world for testing.
var _tab := "Travel"
var _message := ""
var _busy := false

func _ready() -> void:
	_panel_size = Vector2(760,600)
	super._ready()

func _rebuild() -> void:
	_clear_content()
	if not GameSettings.is_developer_unlocked():
		add_body_text("Unlock developer access in Settings first.",GameUI.MUTED,16)
		return
	var game := get_tree().get_first_node_in_group("game") as Game
	var active := GameState.developer_session_active()
	add_section("TEST JOURNEY · NORMAL SAVE PROTECTED" if active else "START A PROTECTED TEST JOURNEY",GameUI.GOLD)
	add_body_text("Scene jumps, rescue shortcuts and test rewards use a separate save. End the session to restore your normal journey at its saved world checkpoint.",GameUI.MUTED,14)
	if not _message.is_empty(): add_body_text(_message,GameUI.TEAL,15)
	var session := HBoxContainer.new()
	content.add_child(session)
	var start := GameUI.button("End test session" if active else "Start test session",Vector2(205,44))
	start.name = "DeveloperSession"
	start.disabled = _busy
	start.pressed.connect(func() -> void:
		if _busy: return
		if active: game.end_developer_test()
		else: game.start_developer_test())
	session.add_child(start)
	var lock := GameUI.button("Lock developer mode",Vector2(200,44))
	lock.pressed.connect(func() -> void:
		if active: game.end_developer_test(true)
		else:
			close_panel()
			GameSettings.lock_developer())
	session.add_child(lock)
	if not active: return
	var options := HBoxContainer.new()
	content.add_child(options)
	for option in [["invulnerable","Protect Adam (land)"],["freeze_time","Freeze world clock"]]:
		var toggle := CheckBox.new()
		toggle.text = str(option[1])
		toggle.button_pressed = GameState.developer_option(str(option[0]))
		toggle.toggled.connect(func(on: bool) -> void: GameState.set_developer_option(str(option[0]),on))
		options.add_child(toggle)
	add_body_text("The world is paused while this workbench is open. Close it to play the test.",GameUI.MUTED,13)
	var tabs := HBoxContainer.new()
	content.add_child(tabs)
	for group in DeveloperDB.GROUPS:
		var tab := GameUI.button(group,Vector2(120,40))
		tab.toggle_mode = true
		tab.button_pressed = _tab == group
		tab.pressed.connect(func() -> void:
			_tab = group
			body.scroll_vertical = 0
			_rebuild())
		tabs.add_child(tab)
	for action in DeveloperDB.actions(_tab):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation",12)
		content.add_child(row)
		var text := VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text)
		text.add_child(GameUI.label(str(action[2]),16,GameUI.TEXT))
		var detail := GameUI.label(str(action[3]),13,GameUI.MUTED)
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.add_child(detail)
		var go := GameUI.button("Play" if _tab == "Scenes" else ("Go" if _tab == "Travel" else "Apply"),Vector2(88,46))
		go.name = str(action[0])
		go.disabled = _busy
		go.pressed.connect(_run.bind(str(action[0])))
		row.add_child(go)

func _run(id: String) -> void:
	if _busy: return
	_busy = true
	var game := get_tree().get_first_node_in_group("game") as Game
	var result := await game.run_developer_action(id)
	_busy = false
	_message = str(result.get("message",""))
	if visible: _rebuild()
