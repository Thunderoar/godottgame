class_name TitleChecks
extends RefCounted
## Save-safe title state-machine regressions, included in the gameplay gate.

static func run(game: Game, check: Callable) -> void:
	var title := game.title_screen
	var original := GameState.data.duplicate(true)
	original.erase("play_time") # The existing autoload counts menu time too.
	check.call(title.current_page == TitleScreen.Page.HOME and not title._heroes.is_visible_in_tree(), "boot shows the main menu without hero selection")
	check.call(title._continue_button.disabled, "Continue is disabled without a save")
	check.call(title._start_button.focus_mode == Control.FOCUS_ALL, "Start Game supports keyboard focus")
	title._start_button.pressed.emit()
	await game.get_tree().process_frame
	check.call(title.current_page == TitleScreen.Page.HEROES and title._heroes.is_visible_in_tree(), "Start Game opens a dedicated hero selection page")
	for i in CharacterDB.CHARACTERS.size():
		title._card_buttons[i].pressed.emit()
		check.call(title.selected_character_id == CharacterDB.ids()[i] and title._card_buttons[i].button_pressed, "hero card previews %s without starting the game" % CharacterDB.ids()[i])
	var browsed := GameState.data.duplicate(true)
	browsed.erase("play_time")
	check.call(game.world == null and browsed == original and not FileAccess.file_exists(GameState.SAVE_PATH), "browsing heroes does not create a world or write a save")
	title._back_button.pressed.emit()
	check.call(title.current_page == TitleScreen.Page.HOME, "Back returns from selection to the main menu")
	title._start_button.pressed.emit()
	check.call(title.selected_character_id == "ayiz", "Back preserves the pending hero choice")
	title._open_credits()
	check.call(title._overlay.visible and title._start_button.focus_mode == Control.FOCUS_NONE, "title overlays isolate keyboard focus from the page")
	title._close_overlay()
	check.call(not title._overlay.visible and title._start_button.focus_mode == Control.FOCUS_ALL, "closing an overlay restores page keyboard focus")
	# Use a second title instance to exercise saved-journey confirmation and
	# signal guards without starting another world in the acceptance game.
	GameState.new_game("farhan")
	var saved_text := FileAccess.get_file_as_string(GameState.SAVE_PATH)
	var saved_serial := GameState.journey_serial
	var saved := TitleScreen.new()
	saved.save_available = true
	game._title_layer.add_child(saved)
	title.hide()
	await game.get_tree().process_frame
	var continued: Array[bool] = []
	var selected: Array[String] = []
	saved.continue_requested.connect(func() -> void: continued.append(true))
	saved.character_selected.connect(func(id: String) -> void: selected.append(id))
	check.call(not saved._continue_button.disabled and saved._save_summary.text.contains("Farhan"), "saved journey summary identifies the existing hero")
	saved._start_button.pressed.emit()
	saved._card_buttons[2].pressed.emit()
	saved._begin_button.pressed.emit()
	check.call(saved._overlay.visible and selected.is_empty(), "Begin requires explicit replacement confirmation when a save exists")
	check.call(FileAccess.get_file_as_string(GameState.SAVE_PATH) == saved_text and GameState.journey_serial == saved_serial, "opening replacement confirmation leaves saved progress unchanged")
	check.call(saved._overlay_close.has_focus(), "replacement confirmation defaults focus to Keep Saved Journey")
	saved._overlay_close.pressed.emit()
	check.call(not saved._overlay.visible and selected.is_empty(), "Keep Saved Journey cancels replacement")
	saved._back_button.pressed.emit()
	saved._continue_button.pressed.emit()
	saved._continue_button.pressed.emit()
	check.call(continued.size() == 1 and selected.is_empty(), "repeated Continue presses emit one handoff and skip hero selection")
	saved.show_continue_error()
	check.call(saved._error.visible and not saved._departing, "a failed Continue shows inline feedback and unlocks the title")
	var invalid_file := FileAccess.open(GameState.SAVE_PATH, FileAccess.WRITE)
	invalid_file.store_string("invalid save")
	invalid_file.close()
	check.call(not GameState.continue_game() and FileAccess.get_file_as_string(GameState.SAVE_PATH) == "invalid save", "Continue rejects unreadable save data without overwriting it")
	var restored := FileAccess.open(GameState.SAVE_PATH, FileAccess.WRITE)
	restored.store_string(saved_text)
	restored.close()
	check.call(GameState.load_game(), "saved title fixture restores successfully inside isolated user data")
	saved._start_button.pressed.emit()
	saved._begin_button.pressed.emit()
	# Confirm through the actual button signal; duplicate activation is guarded.
	var replace := saved._overlay_actions.get_child(1) as Button
	replace.pressed.emit()
	replace.pressed.emit()
	check.call(selected == ["ayiz"], "replacement confirms exactly one selected-hero handoff")
	saved.queue_free()
	await game.get_tree().process_frame
	GameState.delete_save()
	title.show()
	title._select_character("qayyim")
	title._show_page(TitleScreen.Page.HEROES, false)
