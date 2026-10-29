class_name OpeningCaptureChecks
extends RefCounted
## Capture causality, doorway clearance, actor paths and the real story lifecycle.
static func run(game: Game, check: Callable) -> void:
	var start := OpeningCaptureRenderer.sample(0, false, "high")
	var pulled := OpeningCaptureRenderer.sample(1.55, false, "high")
	var locked := OpeningCaptureRenderer.sample(2.20, false, "high")
	var surrounded := OpeningCaptureRenderer.sample(3.70, false, "high")
	var end := OpeningCaptureRenderer.sample(5.8, false, "high")
	check.call(start.door == 0 and not start.locked and start.arjun.x < 132, "capture begins with Arjun outside an open cage")
	check.call(pulled.arjun == Vector2(175, 181) and pulled.door == 0, "Arjun reaches the cage floor before the door starts closing")
	check.call(locked.locked and locked.door == 1 and not locked.gripping, "the prison locks before the Kraken releases Arjun")
	check.call(locked.mei == start.mei and locked.lead == start.lead and locked.rear == start.rear, "Mei Ling's scene waits until Arjun's capture has settled")
	check.call(surrounded.lead.x > surrounded.mei.x and surrounded.rear.x < surrounded.mei.x, "two guards close both of Mei Ling's escape routes before escort")
	check.call(end.mei.x > surrounded.mei.x + 40 and end.lead.x - end.mei.x == 36 and end.mei.x - end.rear.x == 36, "guards escort the visible Mei Ling into the ruined passage together")
	check.call(end.phase == "hold" and OpeningCaptureRenderer.sample(4.65, false, "high") == OpeningCaptureRenderer.sample(6, false, "high").merged({"time": 4.65}, true), "the final 1.35 seconds hold both living captives without secondary motion")
	check.call(OpeningCaptureRenderer.sample(0, true, "high") == OpeningCaptureRenderer.sample(6, true, "high"), "Reduce Motion presents one stable complete captivity tableau")
	var previous := start
	for i in 121:
		var t := float(i) / 20.0
		var state := OpeningCaptureRenderer.sample(t, false, "high")
		var low := OpeningCaptureRenderer.sample(t, false, "low")
		var essential := ["arjun", "arm_tip", "arm_frame", "door", "locked", "mei", "rear", "lead", "phase"]
		var equal := true
		for key in essential: equal = equal and state[key] == low[key]
		check.call(equal, "capture %.2fs quality preserves capture geometry and chronology" % t)
		var in_frame := true
		for key in ["arjun", "mei", "lead", "rear"]:
			var at: Vector2 = state[key]
			in_frame = in_frame and Rect2(19, 60, 442, 154).has_point(at)
		check.call(in_frame and state.lead.x - state.mei.x >= 35 and state.mei.x - state.rear.x >= 35, "capture %.2fs faces and silhouettes stay separated inside the stage" % t)
		check.call(OpeningCaptureArt.on_right_landing(state.mei) and OpeningCaptureArt.on_right_landing(state.rear) and OpeningCaptureArt.on_right_landing(state.lead), "capture %.2fs friends and guards stand on the visible landing, not water" % t)
		if state.gripping:
			check.call(state.arm_tip == state.arjun + Vector2(10, -20), "capture %.2fs raster arm stays attached to its captive" % t)
		if state.door > 0:
			check.call(state.arjun == Vector2(175, 181), "capture %.2fs door never closes through a moving prisoner" % t)
		check.call(state.arjun.distance_to(previous.arjun) <= 9 and state.mei.distance_to(previous.mei) <= 7 and state.lead.distance_to(previous.lead) <= 15 and state.rear.distance_to(previous.rear) <= 7, "capture %.2fs consecutive actor positions stay continuous" % t)
		previous = state
	var settings := [GameSettings.reduce_motion(), GameSettings.effects_quality()]
	var hull := OpeningFishingArt.hull().get_image().get_data()
	var friend := OpeningFishingArt.hero("mei_ling", 0).get_image().get_data()
	var story := StorySequence.new()
	game.add_child(story)
	story.set_process(false)
	check.call(story._canvas._capture == null, "capture art is not warmed during the title or first beat")
	story.advance()
	story.advance()
	check.call(story._canvas._capture == null, "capture art is not warmed during the wreck")
	story.advance()
	check.call(story._canvas._capture == null and story._canvas.uses_landfall_shot(), "landfall establishes the guarded shore before capture warms")
	story.advance()
	check.call(story._canvas.uses_capture_shot() and story._canvas._capture != null and story._page_time == 0, "entering only intro capture page warms the capture before drawing")
	check.call(story._caption.text == StorySequence.INTRO[StorySequence.INTRO_CAPTURE_PAGE] and story.lines().size() == 8, "capture follows landfall and identifies the guards taking an outsider alive")
	check.call(hull == OpeningFishingArt.hull().get_image().get_data() and friend == OpeningFishingArt.hero("mei_ling", 0).get_image().get_data(), "capture art leaves shared ship and character pixels unchanged")
	var face_clear := true
	var bars := OpeningCaptureArt.cage(true).get_image()
	for y in range(58, 68):
		for x in range(38, 51): face_clear = face_clear and bars.get_pixel(x, y).a == 0
	check.call(face_clear, "closed cage bars and crossbar leave Arjun's face opening clear")
	for size in [Vector2(1280, 720), Vector2(832, 480), Vector2(1600, 720)]:
		var available := Rect2(Vector2.ZERO, Vector2(size.x, size.y - 184))
		var fitted := OpeningCaptureRenderer.fit_rect(available)
		check.call(available.encloses(fitted) and absf(fitted.size.x / fitted.size.y - 480.0 / 224.0) < 0.001, "capture %s preserves proportions above the caption" % size)
	story._page_time = 3.2
	GameSettings.set_reduce_motion(true, false)
	check.call(story._canvas.capture_state().locked and story._canvas.capture_state().phase == "hold" and story._page_time == 3.2, "live Reduce Motion shows captivity without restarting page time")
	GameSettings.set_effects_quality("low", false)
	check.call(story._canvas.capture_state().details == 2 and story._canvas.capture_state().locked, "live low quality retains both captives and reduces only water detail")
	GameSettings.set_reduce_motion(bool(settings[0]), false)
	GameSettings.set_effects_quality(str(settings[1]), false)
	var cached := PixelArt.CACHE.size()
	for i in 100: OpeningCaptureRenderer.sample(float(i) * 0.06, false, "high")
	check.call(PixelArt.CACHE.size() == cached, "capture sampling creates no cached textures")
	story._page_time = 5.99
	story._process(0.02)
	check.call(story.page == StorySequence.INTRO_RESCUE_PAGE and story._page_time == 0 and not story._canvas.uses_capture_shot(), "six-second capture hands off to Adam's turtle rescue")
	for kind in ["arjun", "mei", "ending"]:
		story.kind = kind
		story.page = StorySequence.INTRO_CAPTURE_PAGE
		check.call(not story._canvas.uses_capture_shot(), "%s story cannot select the intro captivity renderer" % kind)
	story.finish()
	await game.get_tree().process_frame
	for t in [0.0, 0.9, 1.55, 1.8, 2.3, 3.3, 4.1, 5.8]:
		var early := StorySequence.new()
		game.add_child(early)
		early.set_process(false)
		for i in StorySequence.INTRO_CAPTURE_PAGE: early.advance()
		early._page_time = t
		early.advance()
		check.call(early.page == StorySequence.INTRO_RESCUE_PAGE and early._page_time == 0, "Next at capture %.2fs immediately reaches Adam's rescue" % t)
		var reference: WeakRef = weakref(early._canvas._capture)
		var completions := [0]
		early.completed.connect(func() -> void: completions[0] += 1)
		early.finish()
		early.finish()
		await game.get_tree().process_frame
		check.call(completions[0] == 1 and reference.get_ref() == null, "Skip after capture %.2fs completes once and releases the renderer" % t)
