extends Node

var checks := 0
var failures := 0

func _ready() -> void:
	if not TestEnvironment.require_isolation(): get_tree().quit(1); return
	GameState.autosave_enabled = false
	GameState.new_game("adam")
	GameSettings.set_value("tutorial_hidden", true)
	var game := load("res://scenes/game.tscn").instantiate() as Game
	add_child(game)
	game._remove_title()
	await game._load_lobby(false)
	var hud := game.hud
	hud.settings_panel.open_settings()
	await get_tree().process_frame
	await get_tree().process_frame
	var appearance: VisualStyleSettings
	for child in hud.settings_panel.content.get_children():
		if child is VisualStyleSettings: appearance = child
	_check(appearance != null, "shared interface settings available")
	appearance._size_slider.value = 75
	_check(GameSettings.ui_scale() == 75 and is_equal_approx(hud.get_gui_scale(), 0.75), "size slider immediately shrinks HUD")
	appearance._size_slider.value = 130
	appearance._size_slider.drag_ended.emit(true)
	GameSettings.load_settings()
	_check(GameSettings.ui_scale() == 130, "larger interface size persists")
	GameSettings.set_ui_scale(100)
	_check(appearance._size_slider.value == 100, "interface size slider synchronizes external changes")
	hud.settings_panel.close_panel()
	var saved := GameState.data.duplicate(true)
	_check(EquipmentArt.comparison("iron_sword").delta == 8, "comparison uses equipped starter and stronger sword")
	GameState.data.weapon_upgrades["rusty_sword"] = 5
	_check(EquipmentArt.comparison("iron_sword").delta == 2, "comparison includes equipped weapon upgrades")
	GameState.data.equipped.weapon = "iron_sword"
	_check(EquipmentArt.comparison("rusty_sword").delta == -2, "comparison identifies weaker weapon")
	_check(EquipmentArt.comparison("iron_sword").equipped, "comparison identifies currently equipped weapon")
	GameState.data = saved
	for role in WorkerPreview.NPCS:
		var preview := WorkerPreview.new()
		preview.setup(role)
		add_child(preview)
		GameSettings.set_reduce_motion(false)
		preview._process(0.2)
		_check(preview._clock > 0, "worker job preview animates: " + str(role))
		GameSettings.set_reduce_motion(true)
		var stopped := preview._clock
		preview._process(0.2)
		_check(preview._clock == stopped, "worker preview respects Reduce motion: " + str(role))
		preview.queue_free()
	GameSettings.set_reduce_motion(false)
	_check(GameState.data == saved, "cosmetic worker previews never mutate progression")
	for role in GameState.WORKER_LABELS:
		var before := GameState.worker_status(role)
		var id := GameState.worker_name(role, 0)
		GameState.damage_resident(id, 100)
		var dead := GameState.worker_status(role)
		_check(int(dead.alive) == int(before.alive) - 1 and int(dead.fallen) == 1, "worker death reduces living count: " + str(role))
		GameState.data.gold = 1000
		var hired := GameState.hire_worker(role)
		var replaced := GameState.worker_status(role)
		_check(bool(hired.ok) and int(replaced.fallen) == 0 and int(replaced.total) == int(before.total), "replacement restores living count without adding a slot: " + str(role))
	GameState.data = saved.duplicate(true)
	for id in ItemDB.stock_for("potion"):
		var preview := PotionPreview.new()
		preview.setup(id)
		add_child(preview)
		preview._process(0.2)
		_check(preview._clock > 0 and not PotionPreview.usage_hint(id).is_empty(), "potion effect preview animates with usage guidance: " + id)
		GameSettings.set_reduce_motion(true)
		var stopped := preview._clock
		preview._process(0.2)
		_check(preview._clock == stopped, "potion preview respects Reduce motion: " + id)
		GameSettings.set_reduce_motion(false)
		preview.queue_free()
	_check(GameState.data == saved, "potion previews do not consume items or mutate progression")
	GameState.damage_resident(GameState.worker_name("water", 0), 100)
	hud._status_strip.refresh_world(game.world)
	_check(hud._status_strip._labels.workers.text == "Workers 3/4", "HUD exposes living worker deficit")
	GameSettings.set_value("interface_opacity", -10)
	_check(GameSettings.get_value("interface_opacity") == 25, "opacity clamps to readable minimum")
	GameSettings.set_value("interface_opacity", 50)
	_check(is_equal_approx(hud._attack_button.modulate.a, 0.5), "land controls update immediately")
	_check(is_equal_approx(hud._status_strip.modulate.a, 0.5), "land status updates immediately")
	_check(is_equal_approx(hud.settings_panel.modulate.a, 1.0), "Settings stays readable")
	GameSettings.load_settings()
	_check(GameSettings.get_value("interface_opacity") == 50, "opacity survives settings reload")
	GameSettings.set_value("interface_opacity", 500)
	_check(GameSettings.get_value("interface_opacity") == 100, "opacity clamps to full visibility")
	var images := {}
	for id in EquipmentArt.SWORDS:
		var bytes := EquipmentArt.icon(id).get_image().get_data()
		var key := bytes.hex_encode()
		_check(not images.has(key), "distinct sword silhouette: " + id)
		images[key] = true
	_check(EquipmentArt.upgrade_hint("iron_sword").contains("14 → 17"), "upgrade preview uses actual attack formula")
	_check(HmsScanService.MESSAGE == "PB (Protect BESUT)\nNature needs a protector.", "English QR message")
	GameState.data.village_progression.legacy_access = true
	for view in [Vector2i(1280,720), Vector2i(832,480)]:
		get_window().size = view
		get_window().content_scale_size = view
		hud.village_services_panel.open_services()
		await _capture("workers-%d" % view.x)
		var status_label := hud.village_services_panel.find_child("WorkerStatus_water", true, false) as Label
		_check(status_label != null and status_label.text.contains("0/1 alive"), "Worker Shop displays current death count")
		hud.village_services_panel.body.ensure_control_visible(status_label.get_parent().get_parent().get_parent())
		await _capture("workers-loss-%d" % view.x)
		hud.village_services_panel.body.scroll_vertical = 1000
		await _capture("workers-bottom-%d" % view.x)
		hud.village_services_panel.close_panel()
		hud.shop_panel.open_shop("equipment", "Garrick")
		await get_tree().process_frame
		await get_tree().process_frame
		hud.shop_panel.body.ensure_control_visible(hud.shop_panel._cards[0])
		await _capture("swords-%d" % view.x)
		hud.shop_panel.body.ensure_control_visible(hud.shop_panel._cards[6])
		await _capture("swords-advanced-%d" % view.x)
		hud.shop_panel.close_panel()
		hud.shop_panel.open_shop("potion", "Mara")
		await get_tree().process_frame
		await get_tree().process_frame
		hud.shop_panel.body.ensure_control_visible(hud.shop_panel._cards[0])
		await _capture("potions-%d" % view.x)
		hud.shop_panel.body.ensure_control_visible(hud.shop_panel._cards[-1])
		await _capture("potions-bottom-%d" % view.x)
		hud.shop_panel.close_panel()
		GameSettings.set_value("interface_opacity", 50)
		await _capture("hud-%d" % view.x)
		hud.settings_panel.open_settings()
		await _capture("settings-%d" % view.x)
		hud.settings_panel.close_panel()
	game._clear_world()
	var ocean := OceanJourney.new()
	game.world = ocean
	game._world_holder.add_child(ocean)
	hud.set_world(ocean)
	hud.visible = false
	await get_tree().process_frame
	_check(ocean != null, "ocean scene available")
	if ocean != null:
		_check(is_equal_approx(ocean._ocean_joystick.modulate.a, 0.5), "ocean controls inherit saved opacity")
		GameSettings.set_value("interface_opacity", 75)
		_check(is_equal_approx(ocean._ocean_header.modulate.a, 0.75), "ocean header updates immediately")
		_check(is_equal_approx(ocean._ocean_settings.modulate.a, 1.0), "ocean Settings stays readable")
		var original_extent := ocean._ocean_joystick.size.x
		GameSettings.set_ui_scale(75)
		_check(ocean._ocean_joystick.size.x < original_extent, "interface size shrinks ocean controls immediately")
		GameSettings.set_ui_scale(130)
		_check(ocean._ocean_joystick.size.x > original_extent, "interface size enlarges ocean controls immediately")
	game.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	print("--- interface shop: %d checks, %s ---" % [checks, "PASS" if failures == 0 else "FAIL"])
	get_tree().quit(0 if failures == 0 else 1)

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("[%s] %s" % ["OK" if ok else "FAIL", message])

func _capture(label: String) -> void:
	# Opening modals rebuilds after a frame even without a renderer.
	if DisplayServer.get_name() == "headless":
		await get_tree().process_frame
		await get_tree().process_frame
		return
	await get_tree().create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	var path := OS.get_environment("TIDESWORN_TEST_ROOT").path_join(label + ".png")
	_check(get_viewport().get_texture().get_image().save_png(path) == OK, "capture " + label)
