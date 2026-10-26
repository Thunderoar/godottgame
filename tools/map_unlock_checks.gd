class_name MapUnlockChecks
extends RefCounted

static func run(game: Game, check: Callable, capture: Callable = Callable()) -> void:
	var snapshot := GameState.data.duplicate(true)
	var autosave := GameState.autosave_enabled
	var ticking := game.is_processing()
	GameState.autosave_enabled = false
	game.set_process(false)
	game.hud.hide_modals()
	var minimap := game.hud._minimap
	var icons := minimap.map_icons(game.world)
	var ids: Array = icons.map(func(icon: Dictionary) -> String: return str(icon.id))
	check.call(["shop_potion", "shop_equipment", "shop_pet", "shop_house", "shop_services", "monster_portal", "pet_portal", "jetty_deck", "house", "ship"].all(func(id: String) -> bool: return id in ids), "map contains pictures for every shop, both portals, home, jetty and ship")
	check.call(icons.all(func(icon: Dictionary) -> bool: return icon.texture is Texture2D and not icon.has("letter") and not icon.has("label")), "map markers use textures without letter labels or explanations")
	check.call(minimap.mouse_filter == Control.MOUSE_FILTER_STOP and not minimap.expanded, "minimap accepts interaction instead of passing touches into the world")
	if capture.is_valid(): await capture.call("01_picture_minimap")
	var press := InputEventScreenTouch.new()
	press.index = 24
	press.position = game.get_viewport().get_final_transform() * minimap.get_global_rect().get_center()
	press.pressed = true
	Input.parse_input_event(press)
	await game.get_tree().process_frame
	var release := InputEventScreenTouch.new()
	release.index = 24
	release.position = press.position
	Input.parse_input_event(release)
	await game.get_tree().process_frame
	await game.get_tree().process_frame
	check.call(game.hud.map_panel.visible and game.hud.any_modal_open(), "a real minimap screen tap opens the expanded map")
	check.call(game.player().controls_locked and not game.player().try_attack(), "expanded map locks movement and combat input")
	var expanded := game.hud.map_panel.map
	check.call(expanded.expanded and expanded.mouse_filter == Control.MOUSE_FILTER_IGNORE and expanded.size.y > 200, "expanded map presents a larger non-recursive picture surface")
	check.call(expanded.map_icons(game.world).size() == icons.size(), "expanded and compact maps share live location records")
	if capture.is_valid(): await capture.call("02_expanded_picture_map")
	game.hud.map_panel.close_panel()
	check.call(not game.hud.any_modal_open() and not game.player().controls_locked, "closing the map restores world controls")
	var layer := CanvasLayer.new()
	layer.layer = 210
	game.add_child(layer)
	GameState.data.campaign.arjun_rescued = false
	GameState.data.campaign.mei_ling_rescued = false
	var title := TitleScreen.new()
	layer.add_child(title)
	title._show_page(TitleScreen.Page.HEROES, false)
	await game.get_tree().process_frame
	check.call(title._hero_available("adam") and not title._hero_available("arjun") and not title._hero_available("mei_ling"), "Choose Your Road begins with only Adam available")
	check.call(title._card_locks[1].visible and title._card_locks[2].visible and title._card_status[1].text == "LOCKED", "missing friends have visible lock art and locked status")
	check.call(title._card_unlock_text[1].text.contains("Kraken") and title._card_unlock_text[2].text.contains("Drowned Throne"), "each locked card explains its own rescue condition")
	if capture.is_valid(): await capture.call("03_locked_friends")
	title._card_buttons[1].pressed.emit()
	await game.get_tree().process_frame
	check.call(title.selected_character_id == "adam" and title._overlay.visible and not title._card_buttons[1].button_pressed, "tapping locked Arjun explains his rescue without selecting him")
	if capture.is_valid(): await capture.call("04_arjun_unlock_requirement")
	title._overlay_close.pressed.emit()
	title._card_buttons[2].pressed.emit()
	check.call(title.selected_character_id == "adam" and title._overlay_title.text.contains("Mei Ling"), "tapping locked Mei Ling shows her separate unlock explanation")
	title._overlay_close.pressed.emit()
	check.call(GameState.rescue_friend("arjun"), "Arjun rescue transaction records the map/title fixture unlock")
	check.call(title._hero_available("arjun") and not title._card_locks[1].visible and not title._hero_available("mei_ling"), "rescuing Arjun unlocks only his own card")
	title._select_character("arjun")
	check.call(title.selected_character_id == "arjun" and title._card_buttons[1].button_pressed, "rescued Arjun can be viewed as an unlocked village defender")
	GameState.rescue_friend("mei_ling")
	check.call(title._hero_available("mei_ling") and not title._card_locks[2].visible, "the final-portal rescue unlocks Mei Ling's card")
	GameState.save_game()
	check.call(GameState.load_game() and title._hero_available("arjun") and title._hero_available("mei_ling"), "both card unlocks survive save reload")
	if capture.is_valid(): await capture.call("05_rescued_friend_cards")
	layer.queue_free()
	await game.get_tree().process_frame
	GameState.data = snapshot
	GameState._emit_all()
	await game._load_lobby(false)
	for frame in 3: await game.get_tree().physics_frame
	game.hud.visible = true
	GameState.autosave_enabled = autosave
	game.set_process(ticking)
