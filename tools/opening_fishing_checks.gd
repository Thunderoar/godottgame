class_name OpeningFishingChecks
extends RefCounted
## First-beat presentation checks; run by StoryChecks in the canonical safe gate.

static func run(game: Game, check: Callable) -> void:
	var initial := OpeningFishingRenderer.sample(0.0, false, "high")
	check.call(initial.poses == PackedInt32Array([0, 0, 0]), "fishing opening begins in three distinct relaxed/fishing/seated poses")
	for t in [0.0, 0.7, 1.5, 3.2, 4.7, 5.9]:
		var state := OpeningFishingRenderer.sample(t, false, "high")
		for i in 3:
			check.call((state.feet[i] - state.boat).is_equal_approx(OpeningFishingRenderer.FEET[i]), "fishing t=%.1f actor %d stays attached to deck" % [t, i])
		check.call(Rect2(Vector2.ZERO, OpeningFishingRenderer.FRAME).has_point(state.float) and state.rod_tip.x > state.hand.x, "fishing t=%.1f has an on-screen float and outward connected rod" % t)
	check.call(OpeningFishingRenderer.sample(1.5, false, "high").poses[1] == 1, "Arjun adjusts the fishing rod before the friendship gesture")
	check.call(OpeningFishingRenderer.sample(3.5, false, "high").poses[0] == 1 and OpeningFishingRenderer.sample(3.5, false, "high").poses[2] == 1, "Adam and Mei Ling share the middle-beat gesture")
	check.call(OpeningFishingRenderer.sample(5.8, false, "high").poses == PackedInt32Array([0, 0, 0]), "first beat settles before the existing Kraken cut")
	check.call(OpeningFishingRenderer.sample(0, true, "high") == OpeningFishingRenderer.sample(5.9, true, "high"), "Reduce Motion freezes all decorative shot motion, not the story timer")
	var low := OpeningFishingRenderer.sample(3.2, false, "low")
	var high := OpeningFishingRenderer.sample(3.2, false, "high")
	check.call(low.feet == high.feet and low.hand == high.hand and low.rod_tip == high.rod_tip and low.float == high.float and low.poses == high.poses, "low quality preserves every essential fishing anchor and performance")
	check.call(low.glints < high.glints and not low.reflection, "low quality removes only optional glints and reflections")
	for extent in [Vector2(1280, 536), Vector2(832, 342), Vector2(1600, 536), Vector2(640, 540)]:
		var area := Rect2(Vector2.ZERO, extent)
		var fitted := OpeningFishingRenderer.fit_rect(area)
		check.call(area.encloses(fitted) and is_equal_approx(fitted.size.x / fitted.size.y, 640.0 / 270.0), "fishing artwork fits %s uniformly without stretching people" % extent)
	var reduced := GameSettings.reduce_motion()
	var quality := GameSettings.effects_quality()
	var story := StorySequence.new()
	game.add_child(story)
	story.set_process(false)
	check.call(story._canvas.uses_fishing_shot() and story.lines().size() == 6, "only intro page zero uses the new six-beat opening renderer")
	var cache_size := PixelArt.CACHE.size()
	for i in 100: OpeningFishingRenderer.sample(float(i) * 0.06, false, "high")
	check.call(PixelArt.CACHE.size() == cache_size, "sampling fishing motion does not allocate or rebuild pixel textures")
	story._page_time = 3.2
	GameSettings.set_reduce_motion(true, false)
	check.call(story._canvas.fishing_state() == OpeningFishingRenderer.sample(3.2, true, quality) and story._page_time == 3.2, "live Reduce Motion takes effect without restarting the beat")
	GameSettings.set_effects_quality("low", false)
	check.call(not story._canvas.fishing_state().reflection, "live low quality immediately removes optional reflection")
	GameSettings.set_reduce_motion(reduced, false)
	GameSettings.set_effects_quality(quality, false)
	story._page_time = 5.99
	story._process(0.02)
	check.call(story.page == 1 and story._page_time == 0.0 and story._canvas.uses_kraken_shot(), "six-second auto advance resets time and hands beat two to the pixel Kraken renderer")
	for page in range(1, 6):
		story.page = page
		story._render()
		check.call(not story._canvas.uses_fishing_shot(), "intro page %d does not inherit the peaceful first shot" % page)
	for kind in ["arjun", "mei", "ending"]:
		story.kind = kind
		story.page = 0
		story._render()
		check.call(not story._canvas.uses_fishing_shot(), "%s story does not inherit fishing artwork" % kind)
	story.finish()
	await game.get_tree().process_frame
	for t in [0.0, 0.5, 3.0, 5.9]:
		var early := StorySequence.new()
		game.add_child(early)
		early.set_process(false)
		early._page_time = t
		var completions := [0]
		early.completed.connect(func() -> void: completions[0] += 1)
		early.advance()
		check.call(early.page == 1 and early._page_time == 0 and not early._canvas.uses_fishing_shot(), "Next at %.1fs exits the first-beat rendering path" % t)
		early.finish()
		await game.get_tree().process_frame
		var skipped := StorySequence.new()
		game.add_child(skipped)
		skipped.set_process(false)
		skipped._page_time = t
		var renderer_ref: WeakRef = weakref(skipped._canvas._fishing)
		completions[0] = 0
		skipped.completed.connect(func() -> void: completions[0] += 1)
		skipped.finish()
		skipped.finish()
		check.call(completions[0] == 1 and skipped.is_queued_for_deletion(), "Skip on first beat at %.1fs completes exactly once" % t)
		await game.get_tree().process_frame
		check.call(renderer_ref.get_ref() == null, "Skip at %.1fs releases the whole fishing renderer" % t)
	await _check_arrival(game, check)
	await _check_loading_arrival(game, check)

static func _check_loading_arrival(game: Game, check: Callable) -> void:
	var readable := StorySequence.sample_arrival(0.7, false, true)
	check.call(readable.loading_alpha == 1.0 and not readable.ready and readable.caption_alpha == 0, "existing PB loader has a fully readable hold before the story caption")
	var settled := StorySequence.sample_arrival(1.59, false, true)
	check.call(settled.ready and is_zero_approx(settled.loading_alpha) and is_equal_approx(settled.caption_alpha, 1.0), "loading entrance settles at 1.59 seconds without covering the readable caption")
	var accessible := StorySequence.sample_arrival(0.97, true, true)
	check.call(accessible.ready and StorySequence.sample_arrival(0.5, true, true).loading_alpha == 1.0, "Reduce Motion keeps the loading label readable and clears within 0.97 seconds")
	var reduced := GameSettings.reduce_motion()
	GameSettings.set_reduce_motion(false, false)
	var world_loading := game.loading_screen.active
	var story := StorySequence.new()
	story.arrive_from_title = true
	story.include_loading_screen = true
	game.add_child(story)
	story.set_process(false)
	var loader := story.opening_loader()
	check.call(loader != null and loader != game.loading_screen and loader is LoadingScreen, "opening reuses LoadingScreen in a separately owned instance")
	check.call(loader.destination.text == "Adam's Journey" and loader.cover.modulate.a == 0 and loader._tween == null, "opening loader uses the existing destination UI without an orphaned tween")
	var owner: WeakRef = weakref(loader)
	story._process(0.7)
	check.call(loader.cover.modulate.a == 1 and story._page_time == 0 and story.clock == 0, "loading hold never consumes first-beat reading or animation time")
	story._process(0.89)
	check.call(story.opening_loader() == null and not story._arrival_active and not story._next.disabled, "completed entrance dismisses its loader before enabling story navigation")
	await game.get_tree().process_frame
	check.call(owner.get_ref() == null, "owned loading screen is freed after reveal")
	check.call(game.loading_screen.active == world_loading, "opening loader does not borrow or modify the world's loading screen")
	story._process(5.99)
	check.call(story.page == 0, "six full seconds remain after the PB loader clears")
	story._process(0.02)
	check.call(story.page == 1, "first beat advances normally after loading and full reading time")
	story.finish()
	await game.get_tree().process_frame
	for t in [0.0, 0.34, 0.7, 1.04]:
		var early := StorySequence.new()
		early.arrive_from_title = true
		early.include_loading_screen = true
		game.add_child(early)
		early.set_process(false)
		var pending: WeakRef = weakref(early.opening_loader())
		early._process(t)
		early.finish()
		early.finish()
		check.call(early.opening_loader() == null and not early._arrival_active, "cancelling at %.2fs dismisses the opening loader immediately" % t)
		await game.get_tree().process_frame
		check.call(pending.get_ref() == null and game.loading_screen.active == world_loading, "cancellation at %.2fs leaves no loading overlay or global-loading interference" % t)
	GameSettings.set_reduce_motion(reduced, false)

static func _check_arrival(game: Game, check: Callable) -> void:
	var start := StorySequence.sample_arrival(0.0, false)
	check.call(start.art_alpha == 0 and start.cover_alpha == 0 and start.caption_alpha == 0, "title handoff begins with the old title unobscured, not the fishing scene")
	var half := StorySequence.sample_arrival(0.14, false)
	check.call(is_equal_approx(half.cover_alpha, 0.5) and half.art_alpha == 0, "title fades gently before any fishing artwork becomes visible")
	var covered := StorySequence.sample_arrival(0.28, false)
	check.call(covered.covered and covered.cover_alpha == 1.0 and covered.caption_alpha == 0, "title retirement is covered by an opaque navy frame")
	var middle := StorySequence.sample_arrival(0.66, false)
	check.call(is_equal_approx(middle.cover_alpha, 0.5) and middle.art_alpha == 1 and middle.caption_alpha == 0, "fishing illustration reveals before the caption")
	var end := StorySequence.sample_arrival(0.98, false)
	check.call(end.ready and is_zero_approx(end.cover_alpha) and is_equal_approx(end.caption_alpha, 1), "normal handoff settles within one second")
	check.call(StorySequence.sample_arrival(0.28, true).ready and StorySequence.sample_arrival(0.0, true).duration < end.duration, "Reduce Motion uses a shorter dissolve without a camera move")
	var reduced := GameSettings.reduce_motion()
	GameSettings.set_reduce_motion(false, false)
	var story := StorySequence.new()
	story.arrive_from_title = true
	var retired := [0]
	story.departure_covered.connect(func() -> void: retired[0] += 1)
	game.add_child(story)
	story.set_process(false)
	check.call(story._arrival_active and story._next.disabled and story._skip.disabled, "hidden handoff controls cannot be activated before they appear")
	story._process(0.14)
	check.call(retired[0] == 0 and story._page_time == 0 and story.clock == 0, "title remains owned during fade and no reading time is consumed")
	story._process(0.14)
	check.call(retired[0] == 1 and story._curtain.modulate.a == 1, "departure ownership signal fires once at full cover")
	story._process(0.38)
	check.call(story._page_time == 0 and story._caption_panel.modulate.a == 0, "reveal holds the first frame while the words are still hidden")
	story._process(0.32)
	check.call(not story._arrival_active and not story._curtain.visible and not story._next.disabled and not story._skip.disabled, "settled handoff releases only the visible story controls")
	check.call(story._page_time == 0 and story._caption_panel.modulate.a == 1, "first beat receives a full six seconds after the caption becomes readable")
	story._process(5.99)
	check.call(story.page == 0, "first fishing beat is not shortened by the entrance")
	story._process(0.02)
	check.call(story.page == 1 and story._page_time == 0 and retired[0] == 1, "normal six-second advance follows the entrance without a second title retirement")
	story.finish()
	await game.get_tree().process_frame
	for t in [0.0, 0.14, 0.4, 0.85]:
		var early := StorySequence.new()
		early.arrive_from_title = true
		game.add_child(early)
		early.set_process(false)
		early._process(t)
		var completions := [0]
		early.completed.connect(func() -> void: completions[0] += 1)
		early.finish()
		early.finish()
		check.call(completions[0] == 1 and not early._arrival_active and early.is_queued_for_deletion(), "cancelling entrance at %.2fs finishes once without a dangling curtain" % t)
		await game.get_tree().process_frame
	var live := StorySequence.new()
	live.arrive_from_title = true
	game.add_child(live)
	live.set_process(false)
	live._process(0.15)
	GameSettings.set_reduce_motion(true, false)
	check.call(live._arrival_reduced and live._departure_emitted and live._curtain.modulate.a == 1.0, "enabling Reduce Motion mid-fade still removes the title under full cover")
	GameSettings.set_reduce_motion(false, false)
	check.call(live._arrival_reduced, "disabling Reduce Motion mid-handoff never rewinds the dissolve")
	live._process(0.17)
	check.call(not live._arrival_active and live._page_time == 0, "shortened live handoff keeps the full first-beat timer")
	live.finish()
	GameSettings.set_reduce_motion(reduced, false)
	await game.get_tree().process_frame
