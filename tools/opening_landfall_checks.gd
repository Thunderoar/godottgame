class_name OpeningLandfallChecks
extends RefCounted
## Same bow, occupied shore, sentries before capture, continuous sampled motion.
static func run(game: Game, check: Callable) -> void:
	var start := OpeningLandfallRenderer.sample(0, false, "high")
	var arrival := OpeningLandfallRenderer.sample(OpeningLandfallRenderer.GROUNDED, false, "high")
	var end := OpeningLandfallRenderer.sample(6, false, "high")
	check.call(start.attached and start.piece_id == 2 and not start.grounded, "landfall begins with Mei Ling aboard her own bow fragment, not already a prisoner")
	check.call(start.rear == Vector2(340, 168) and start.lead == Vector2(435, 188) and not start.noticed, "the shore has two posted sentries before the survivor arrives")
	check.call(arrival.grounded and arrival.attached and not arrival.ashore and not arrival.noticed, "the bow grounds before Mei Ling climbs ashore or the sentries react")
	var capture := OpeningCaptureRenderer.sample(0, false, "high")
	check.call(end.mei == capture.mei and end.lead == capture.lead and end.rear == capture.rear and end.fragment == Vector2(264, 195), "landfall ends on the exact right-panel captive and guard anchors with the same grounded bow")
	check.call(OpeningLandfallRenderer.sample(0, true, "high") == OpeningLandfallRenderer.sample(6, true, "high"), "Reduce Motion holds one readable complete landfall tableau")
	var previous := start
	for i in 121:
		var t := float(i) / 20
		var state := OpeningLandfallRenderer.sample(t, false, "high")
		var low := OpeningLandfallRenderer.sample(t, false, "low")
		var equal := true
		for key in ["fragment", "mei", "rear", "lead", "attached", "grounded", "ashore", "noticed", "phase"]: equal = equal and state[key] == low[key]
		check.call(equal, "landfall %.2fs quality preserves every essential anchor and causal phase" % t)
		check.call(not state.attached or state.mei == state.fragment + Vector2(45, 6), "landfall %.2fs survivor stays attached to her drifting fragment" % t)
		var clear := true
		for key in ["mei", "rear", "lead"]:
			var at: Vector2 = state[key]
			clear = clear and Rect2(16, 60, 448, 153).has_point(at)
		check.call(clear and state.mei.distance_to(state.rear) >= 34 and state.mei.distance_to(state.lead) >= 34, "landfall %.2fs actors remain in frame and separated" % t)
		check.call(OpeningCaptureArt.on_right_landing(state.rear) and OpeningCaptureArt.on_right_landing(state.lead) and (not state.grounded or OpeningCaptureArt.on_right_landing(state.mei)), "landfall %.2fs posted guards and landed survivor have visible stone support" % t)
		var continuous := true
		for key in ["fragment", "mei", "rear", "lead"]: continuous = continuous and state[key].distance_to(previous[key]) <= 10
		check.call(continuous, "landfall %.2fs consecutive samples never teleport actors or wreckage" % t)
		previous = state
	var source := OpeningWreckArt.piece("hull", 2).get_image().get_data()
	var story := StorySequence.new()
	game.add_child(story)
	story.set_process(false)
	check.call(story._canvas._landfall == null, "landfall textures are not warmed on the title/fishing beat")
	for i in StorySequence.INTRO_LANDFALL_PAGE: story.advance()
	check.call(story._canvas.uses_landfall_shot() and story._canvas._landfall != null and story._canvas._capture == null, "only the inserted intro page warms the landfall renderer")
	check.call(story._caption.text.contains("washed ashore") and story.lines().size() == 8, "new caption explains how the separated friend reaches the occupied shore")
	check.call(source == OpeningWreckArt.piece("hull", 2).get_image().get_data(), "landfall cropping leaves shared bow-fragment pixels untouched")
	var settings := [GameSettings.reduce_motion(), GameSettings.effects_quality()]
	story._page_time = 2.0
	GameSettings.set_reduce_motion(true, false)
	check.call(story._canvas.landfall_state().phase == "hold" and story._page_time == 2.0, "live Reduce Motion reveals safe landfall without restarting the page")
	GameSettings.set_effects_quality("low", false)
	check.call(story._canvas.landfall_state().ripples == 2, "live low quality removes only optional water marks")
	GameSettings.set_reduce_motion(bool(settings[0]), false)
	GameSettings.set_effects_quality(str(settings[1]), false)
	var cached := PixelArt.CACHE.size()
	for i in 100: OpeningLandfallRenderer.sample(float(i) * 0.06, false, "high")
	check.call(PixelArt.CACHE.size() == cached, "sampling landfall creates no textures or gameplay state")
	for size in [Vector2(1280, 720), Vector2(832, 480), Vector2(1600, 720)]:
		var available := Rect2(Vector2.ZERO, Vector2(size.x, size.y - 184))
		check.call(available.encloses(OpeningCaptureRenderer.fit_rect(available)), "landfall fits above the caption at %s" % size)
	story._page_time = 5.99
	story._process(0.02)
	check.call(story.page == StorySequence.INTRO_CAPTURE_PAGE and story._page_time == 0 and story._canvas.uses_capture_shot(), "six-second landfall hands off to existing captivity with a fresh reading clock")
	check.call(story._caption.text.contains("ruler will want answers"), "capture explains taking the outsider alive without making the Kraken a servant")
	story.finish()
	await game.get_tree().process_frame
	for kind in ["arjun", "mei", "ending"]:
		var other := StorySequence.new()
		other.kind = kind
		game.add_child(other)
		other.set_process(false)
		other.page = StorySequence.INTRO_LANDFALL_PAGE
		check.call(not other._canvas.uses_landfall_shot(), "%s story never selects the intro landfall renderer" % kind)
		other.finish()
	for t in [0.0, 1.0, 3.3, 4.5, 5.8]:
		var early := StorySequence.new()
		game.add_child(early)
		early.set_process(false)
		for i in StorySequence.INTRO_LANDFALL_PAGE: early.advance()
		early._page_time = t
		var reference: WeakRef = weakref(early._canvas._landfall)
		early.advance()
		check.call(early.page == StorySequence.INTRO_CAPTURE_PAGE and early._page_time == 0, "Next at landfall %.2fs reaches capture immediately" % t)
		var completions := [0]
		early.completed.connect(func() -> void: completions[0] += 1)
		early.finish()
		early.finish()
		await game.get_tree().process_frame
		check.call(completions[0] == 1 and reference.get_ref() == null, "Skip after landfall %.2fs completes once and releases its renderer" % t)
