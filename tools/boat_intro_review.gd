extends Node
var checks := 0
var failures := 0
func _ready() -> void:
	if not TestEnvironment.require_isolation(): get_tree().quit(1); return
	GameState.autosave_enabled = false
	GameState.new_game("adam")
	var game := load("res://scenes/game.tscn").instantiate() as Game
	add_child(game)
	await get_tree().process_frame
	await preload("res://tools/opening_cast_checks.gd").run(game, _check)
	await OpeningFishingChecks.run(game, _check)
	await OpeningKrakenChecks.run(game, _check)
	await OpeningWreckChecks.run(game, _check)
	await OpeningLandfallChecks.run(game, _check)
	await OpeningCaptureChecks.run(game, _check)
	await OpeningRescueChecks.run(game, _check)
	await OpeningWelcomeChecks.run(game, _check)
	var title := game.title_screen
	var story := StorySequence.new()
	add_child(story)
	story.set_process(false)
	for extent in [Vector2i(1280,720),Vector2i(832,480),Vector2i(360,780)]:
		get_window().content_scale_size = extent
		get_window().size = extent
		await get_tree().process_frame
		story.hide()
		title._show_page(TitleScreen.Page.HEROES,false)
		await get_tree().create_timer(0.4).timeout
		await _capture("%dx%d-selection" % [extent.x,extent.y])
		if extent.x >= 832:
			_check(title._card_buttons.size() == 1 and _inside(title._card_buttons[0]) and _inside(title._begin_button),"single Adam card and Begin fit %s" % extent)
		story.show()
		for index in 3:
			story.page = index
			story._page_time = 1.5
			story._render()
			await _capture("%dx%d-%s" % [extent.x,extent.y,OpeningCastRenderer.NAMES[index].to_lower().replace(" ","-")])
			_check(_inside(story._caption_panel) and _inside(story._next) and _inside(story._skip) and _inside(story._intro_pause),"cast captions/navigation fit %s / %d" % [extent,index])
		if extent.x == 1280:
			for index in 3:
				for moment in [0.25,1.0,2.0,3.25,4.75]:
					story.page = index
					story._page_time = moment
					story._render()
					await _capture("acting-%s-%.2f" % [OpeningCastRenderer.NAMES[index].to_lower().replace(" ","-"),moment])
		story.page = 2
		story._page_time = 4.0
		await _capture("%dx%d-pullback" % [extent.x,extent.y])
		story.page = StorySequence.INTRO_FISHING_PAGE
		story._page_time = 0
		story._render()
		await _capture("%dx%d-all-three" % [extent.x,extent.y])
		GameSettings.set_reduce_motion(true,false)
		story.page = 2
		story._render()
		await _capture("%dx%d-reduced" % [extent.x,extent.y])
		GameSettings.set_reduce_motion(false,false)
	story.finish()
	print("--- boat intro review: %d checks, %s ---" % [checks,"PASS" if failures == 0 else "FAIL"])
	get_tree().quit(0 if failures == 0 else 1)
func _inside(control: Control) -> bool:
	return get_viewport().get_visible_rect().encloses(control.get_global_rect())
func _capture(label: String) -> void:
	var directory := OS.get_environment("TIDESWORN_TEST_ROOT").path_join("shots")
	DirAccess.make_dir_recursive_absolute(directory)
	await get_tree().create_timer(0.05).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(directory.path_join(label+".png"))
func _check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("[OK] " if ok else "[FAIL] ", message)
