extends Node
## Real GL-rendered menu journey with actual mouse, touch and keyboard events.
var game: Game
var output := ""
var failures := 0
var checks := 0

func _ready() -> void:
	if not TestEnvironment.require_isolation():
		get_tree().quit(1)
		return
	output = OS.get_environment("TITLE_OUTPUT")
	if output.is_empty():
		get_tree().quit(1)
		return
	DirAccess.make_dir_recursive_absolute(output)
	GameState.delete_save()
	game = load("res://scenes/game.tscn").instantiate()
	add_child(game)
	await _settle()
	var title := game.title_screen
	_check(title.current_page == TitleScreen.Page.HOME and not title._heroes.is_visible_in_tree(), "fresh boot displays only the main menu")
	await _shot("01-main-menu")
	await _click(title._start_button)
	_check(title._heroes.is_visible_in_tree(), "actual Start Game click opens hero selection")
	await _shot("02-choose-your-road")
	_check(_cards_fit(title), "all three complete hero cards fit the landscape selection")
	await _click(title._card_buttons[1])
	_check(title.selected_character_id == "arjun", "clicking Arjun previews the scythe hero")
	await _shot("03-farhan-selected")
	await _key(KEY_ESCAPE)
	_check(title.current_page == TitleScreen.Page.HOME and not FileAccess.file_exists(GameState.SAVE_PATH), "Escape returns without creating a save")
	await _click(_find_button(title._home, "Settings"))
	_check(title._overlay.visible, "Settings opens from the boot menu")
	await _shot("04-settings")
	for i in 12:
		await _key(KEY_TAB)
		var focused := get_viewport().gui_get_focus_owner()
		_check(focused != null and title._overlay.is_ancestor_of(focused), "settings Tab focus remains in the overlay (%d)" % i)
	var reduce := _find_check(title._overlay, "Reduce motion")
	await _click(reduce)
	_check(GameSettings.reduce_motion() and not (title.get_child(0) as TitleBackdrop).is_processing(), "Reduce Motion immediately stops harbour animation")
	await _key(KEY_ESCAPE)
	_check(not title._overlay.visible, "Escape closes Settings")
	await _click(_find_button(title._home, "How to Play"))
	await _shot("05-how-to-play")
	await _key(KEY_ESCAPE)
	await _click(_find_button(title._home, "Credits"))
	await _shot("06-credits")
	await _key(KEY_ESCAPE)
	# Keyboard activation and touch hero selection use the same native controls.
	title._start_button.grab_focus()
	await _key(KEY_ENTER)
	_check(title.current_page == TitleScreen.Page.HEROES, "Enter activates the focused Start Game button")
	await _touch(title._card_buttons[2])
	_check(title.selected_character_id == "mei_ling", "touch selects Mei Ling")
	await _click(title._card_buttons[0])
	await _click(title._begin_button)
	await _wait_for_world()
	_check(game.world is Lobby and str(GameState.data.get("character_id")) == "adam", "Begin Journey loads the selected hero into the village")
	game.hud.tutorial_guide.call("_skip")
	await _shot("07-journey-started")
	await game.return_to_title()
	await _settle()
	title = game.title_screen
	_check(not title._continue_button.disabled and title._save_summary.text.contains("Adam"), "returning title displays the saved hero")
	await _shot("08-saved-journey")
	var saved_text := FileAccess.get_file_as_string(GameState.SAVE_PATH)
	await _click(title._start_button)
	await _click(title._card_buttons[1])
	await _click(title._begin_button)
	_check(title._overlay.visible, "existing progress has a visible replacement confirmation")
	await _shot("09-replace-confirmation")
	await _click(title._overlay_close)
	_check(FileAccess.get_file_as_string(GameState.SAVE_PATH) == saved_text, "cancelling replacement keeps the exact save bytes")
	# Compact actual-window fixtures with logical canvas reduced to match.
	var window := get_window()
	var original_scale := window.content_scale_size
	window.content_scale_size = Vector2i(832, 480)
	window.size = Vector2i(832, 480)
	await _settle()
	await _shot("10-compact-heroes")
	_check(_inside(title._begin_button) and _inside(title._back_button), "compact selection keeps Begin and Back on screen")
	_check(_cards_fit(title), "compact selection shows every full hero card without scrolling")
	await _click(title._back_button)
	await _shot("11-compact-menu")
	_check(_inside(title._start_button) and _inside(title._continue_button), "compact menu keeps both journey actions on screen")
	window.content_scale_size = Vector2i(600, 900)
	window.size = Vector2i(600, 900)
	await _settle()
	await _click(title._start_button)
	await _shot("12-narrow-heroes")
	_check(title._cards.vertical and _inside(title._begin_button), "narrow selection stacks cards and retains Begin")
	window.content_scale_size = original_scale
	window.size = Vector2i(1280, 720)
	await _settle()
	await _click(title._begin_button)
	var serial := GameState.journey_serial
	await _click(title._overlay_actions.get_child(1))
	await _wait_for_world()
	_check(str(GameState.data.get("character_id")) == "arjun" and GameState.journey_serial == serial + 1, "confirmed replacement starts exactly one Arjun journey")
	game.hud.tutorial_guide.call("_skip")
	await game.return_to_title()
	await _settle()
	title = game.title_screen
	serial = GameState.journey_serial
	await _click(title._continue_button)
	await _wait_for_world()
	_check(game.world is Lobby and str(GameState.data.get("character_id")) == "arjun" and GameState.journey_serial == serial, "Continue resumes Arjun directly without starting a new journey")
	game.hud.tutorial_guide.call("_skip")
	_check(GameState.start_expedition(PortalDB.ordered_ids()[0]), "expedition resume fixture starts")
	await game.return_to_title()
	await _settle()
	title = game.title_screen
	_check(title._save_summary.text.contains(str(PortalDB.get_portal(PortalDB.ordered_ids()[0]).get("name"))), "saved summary identifies an active expedition")
	await _click(title._continue_button)
	await _wait_for_world()
	_check(game.world is Dungeon, "Continue resumes a saved expedition in its dungeon")
	await game.return_to_title()
	await _settle()
	title = game.title_screen
	var invalid_file := FileAccess.open(GameState.SAVE_PATH, FileAccess.WRITE)
	invalid_file.store_string("unreadable saved journey")
	invalid_file.close()
	await _click(title._continue_button)
	_check(game.title_screen == title and game.world == null and title._error.visible and not title._departing, "failed Continue keeps the menu usable and shows inline feedback")
	_check(FileAccess.get_file_as_string(GameState.SAVE_PATH) == "unreadable saved journey", "failed Continue preserves unreadable save bytes")
	await _shot("13-continue-error")
	print("TITLE_REVIEW %s %d checks, %d failures" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	get_tree().quit(0 if failures == 0 else 1)

func _inside(control: Control) -> bool:
	return get_viewport().get_visible_rect().encloses(control.get_global_rect())

func _cards_fit(title: TitleScreen) -> bool:
	var scroll := title._cards.get_parent() as ScrollContainer
	for card in title._card_buttons:
		if not scroll.get_global_rect().encloses(card.get_global_rect()):
			return false
	return not scroll.get_v_scroll_bar().visible

func _settle() -> void:
	await get_tree().create_timer(0.3).timeout

func _click(control: Control) -> void:
	if control == null:
		_check(false, "requested click target exists")
		return
	var point := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	Input.parse_input_event(motion)
	await get_tree().process_frame
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		Input.parse_input_event(event)
		await get_tree().process_frame
	await _settle()

func _touch(control: Control) -> void:
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.position = control.get_global_rect().get_center()
		event.pressed = pressed
		Input.parse_input_event(event)
		await get_tree().process_frame
	await _settle()

func _key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await get_tree().process_frame
	await get_tree().process_frame

func _wait_for_world() -> void:
	for i in 100:
		if is_instance_valid(game.world) and not game._transitioning:
			await _settle()
			return
		await get_tree().create_timer(0.1).timeout
	_check(false, "journey transition completes within ten seconds")

func _shot(label: String) -> void:
	await _settle()
	await RenderingServer.frame_post_draw
	var error := get_viewport().get_texture().get_image().save_png(output.path_join(label + ".png"))
	_check(error == OK, "capture " + label)

func _find_button(root: Node, text: String) -> Button:
	if root is Button and root.text == text:
		return root
	for child in root.get_children():
		var found := _find_button(child, text)
		if found != null:
			return found
	return null

func _find_check(root: Node, text: String) -> CheckBox:
	return _find_button(root, text) as CheckBox

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("[%s] %s" % ["PASS" if ok else "FAIL", message])
