extends RefCounted
## New performed shots, spatial continuity, reversible presentation and safe controls.
static func run(game: Game, check: Callable) -> void:
	var campaign := GameState.campaign().duplicate(true)
	for index in 3:
		var opening := OpeningCastRenderer.sample(index, 0, false, "high")
		var acted := OpeningCastRenderer.sample(index, 1.2, false, "high")
		check.call(opening.subject == OpeningFishingRenderer.HEROES[index] and opening.camera_zoom > 3, "cast close-up identifies " + opening.subject)
		check.call(acted.poses[index] == 1 and opening.feet == acted.feet, "cast acting keeps " + opening.subject + " physically on the same boat")
		check.call(OpeningCastRenderer.sample(index, 0, true, "high") == OpeningCastRenderer.sample(index, 6, true, "high"), "reduced-motion cast tableau is time invariant: " + opening.subject)
		var low := OpeningCastRenderer.sample(index, 1.2, false, "low")
		check.call(low.camera_centre == acted.camera_centre and low.camera_zoom == acted.camera_zoom and low.poses == acted.poses, "low quality preserves close-up and performance: " + opening.subject)
		var story := StorySequence.new()
		game.add_child(story)
		story.set_process(false)
		story.page = index
		story._render()
		check.call(story._canvas.uses_cast_shot() and story._beat_label.text == OpeningCastRenderer.NAMES[index], "live cast route and name label agree for " + opening.subject)
		story._process(1.0)
		story._toggle_intro_pause()
		var time := story._page_time
		story._process(10.0)
		story._on_next_pressed()
		check.call(story._page_time == time and story.page == index, "manual pause freezes time and Next: " + opening.subject)
		story._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
		story._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_IN)
		check.call(story._intro_paused, "focus return preserves manual pause: " + opening.subject)
		story._toggle_intro_pause()
		story._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
		story._process(10)
		check.call(story._page_time == time, "unfocused opening consumes no cinematic time: " + opening.subject)
		story._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_IN)
		story._process(0.5)
		check.call(story._page_time > time, "focus return resumes a non-manually-paused opening")
		var completed := [0]
		story.completed.connect(func() -> void: completed[0] += 1)
		story._on_skip_pressed()
		story._on_skip_pressed()
		check.call(completed[0] == 1, "Skip completes once from cast shot: " + opening.subject)
		await game.get_tree().process_frame
	check.call(OpeningCastRenderer.sample(2, 1.5, false, "high").mei_look_left and not OpeningCastRenderer.sample(2, 6, false, "high").mei_look_left, "Mei Ling answers back along Arjun’s eyeline, then turns toward the shared horizon")
	var wide := OpeningCastRenderer.sample(2, 6, false, "high")
	var fishing := OpeningFishingRenderer.sample(0, false, "high")
	check.call(wide.camera_zoom == 1 and wide.camera_centre == OpeningFishingRenderer.FRAME * 0.5, "Mei Ling's pullback ends at the exact full-boat framing")
	for key in fishing:
		check.call(wide[key] == fishing[key], "pullback-to-fishing cut preserves shared set field: " + str(key))
	for extent in [Vector2(1280,536),Vector2(832,296),Vector2(600,716)]:
		var fitted := OpeningFishingRenderer.fit_rect(Rect2(Vector2.ZERO,extent))
		for index in 3:
			var state := OpeningCastRenderer.sample(index,1.2,false,"high")
			var face: Vector2 = state.feet[index]-Vector2(0,40.5 if index == 2 else 48)
			var scale := fitted.size.x / 640.0 * float(state.camera_zoom)
			var screen: Vector2 = fitted.get_center() + (face-state.camera_centre)*scale
			check.call(fitted.grow(-10).has_point(screen), "cast face fits above captions at %s / %d" % [extent,index])
	check.call(GameState.campaign() == campaign, "cast viewing never changes rescue, rewards or story progression")
