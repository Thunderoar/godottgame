class_name OpeningWreckChecks
extends RefCounted
## Cause, strike, exactly three physical art fragments and a readable separation.
static func run(game: Game, check: Callable) -> void:
	var start := OpeningWreckRenderer.sample(0, false, "high")
	var windup := OpeningWreckRenderer.sample(0.9, false, "high")
	var contact := OpeningWreckRenderer.sample(OpeningWreckRenderer.IMPACT, false, "high")
	var end := OpeningWreckRenderer.sample(5.8, false, "high")
	check.call(not start.broken and start.strike_frame == 0, "wreck opens with the same intact boat before the strike")
	check.call(windup.windup and not windup.broken and windup.strike_tip.y < 97, "Kraken raises its striking arm before any timber separates")
	check.call(contact.broken and contact.foam and contact.strike_tip == Vector2(147, 173), "the strike contacts the wooden hull before the three fragments diverge")
	check.call(end.broken and end.piece_ids == PackedInt32Array([0, 1, 2]) and end.pivots.size() == 3, "aftermath retains exactly three identified ship fragments")
	check.call(end.feet[0].x + 90 < end.feet[1].x and end.feet[1].x + 60 < end.feet[2].x, "three friends finish visibly separated in different currents")
	check.call(OpeningWreckRenderer.sample(3.8, false, "high").hero_pose == 1, "the friends reach back toward each other after the impact")
	check.call(OpeningWreckRenderer.sample(0, true, "high") == OpeningWreckRenderer.sample(5.9, true, "high"), "Reduce Motion holds the complete three-friend aftermath without a strike loop")
	for t in [0.0, 0.8, 1.44, 1.45, 2.2, 3.5, 5.8]:
		var state := OpeningWreckRenderer.sample(t, false, "high")
		var low := OpeningWreckRenderer.sample(t, false, "low")
		check.call(state.pivots == low.pivots and state.feet == low.feet and state.angles == low.angles and state.strike_tip == low.strike_tip and state.broken == low.broken, "wreck t=%.2f low quality preserves every essential fragment/actor/strike anchor" % t)
		for i in 3:
			var local: Vector2 = (OpeningFishingRenderer.FEET[i] * OpeningWreckRenderer.SCALE).round() - OpeningWreckRenderer.PIVOTS[i] * OpeningWreckRenderer.SCALE
			var expected: Vector2 = state.pivots[i] + local.rotated(state.angles[i])
			check.call(state.feet[i].distance_to(expected) < 0.001, "wreck t=%.2f friend %d moves with its own rotating ship fragment" % [t, i])
			check.call(Rect2(16, 45, 448, 175).has_point(state.feet[i]) and state.feet[i].y - 43 > 0, "wreck t=%.2f friend %d remains in frame above the caption" % [t, i])
	check.call(OpeningWreckRenderer.sample(1.8, false, "low").debris.size() < OpeningWreckRenderer.sample(1.8, false, "high").debris.size(), "low quality reduces optional wood chips, not the three real ship pieces")
	for y in [0, 32, 70, 112, 130, 150, 179]:
		var counts := PackedInt32Array([0, 0, 0])
		for x in 440: counts[OpeningWreckArt.piece_owner(x, y)] += 1
		check.call(counts[0] > 130 and counts[1] > 130 and counts[2] > 130 and counts[0] + counts[1] + counts[2] == 440, "ship art row %d partitions into three contiguous owned pieces without missing pixels" % y)
	var hull_before := OpeningFishingArt.hull().get_image().get_data()
	var hero_before := OpeningKrakenArt.hero("adam", 2).get_image().get_data()
	for i in 3:
		check.call(OpeningWreckArt.piece("hull", i).get_size() == OpeningFishingArt.BOAT_SIZE, "fragment %d retains the original yellow ship's pixel coordinates" % i)
	check.call(hull_before == OpeningFishingArt.hull().get_image().get_data() and hero_before == OpeningKrakenArt.hero("adam", 2).get_image().get_data(), "fragment/reaching-pose builders never repaint the shared ship or hero source")
	var story := StorySequence.new()
	game.add_child(story)
	story.set_process(false)
	check.call(story._canvas._wreck == null and not story._canvas.uses_wreck_shot(), "wreck art is not warmed during the title/first-beat handoff")
	story.advance()
	check.call(story._canvas._wreck == null and story._canvas.uses_kraken_shot(), "beat two retains its original awakening performance")
	story.advance()
	check.call(story._canvas._wreck != null and story._canvas.uses_wreck_shot() and story._page_time == 0, "Next prepares beat three before its first draw and resets the reading clock")
	check.call(story._caption.text == StorySequence.INTRO[2] and story.lines().size() == 6, "the six-beat story and third caption remain unchanged")
	var reduced := GameSettings.reduce_motion()
	var quality := GameSettings.effects_quality()
	story._page_time = 1.7
	GameSettings.set_reduce_motion(true, false)
	check.call(story._canvas.wreck_state().broken and story._canvas.wreck_state().debris.is_empty() and story._page_time == 1.7, "live Reduce Motion switches to the stable aftermath without restarting time")
	GameSettings.set_effects_quality("low", false)
	check.call(story._canvas.wreck_state().ripples == 2, "live low quality updates the wreck without hiding friends or fragments")
	GameSettings.set_reduce_motion(reduced, false)
	GameSettings.set_effects_quality(quality, false)
	var cached := PixelArt.CACHE.size()
	for i in 100: OpeningWreckRenderer.sample(float(i) * 0.06, false, "high")
	check.call(PixelArt.CACHE.size() == cached, "wreck sampling allocates no textures, gameplay nodes or asynchronous animation chains")
	story._page_time = 5.99
	story._process(0.02)
	check.call(story.page == 3 and story._page_time == 0 and not story._canvas.uses_wreck_shot() and story._canvas.uses_capture_shot(), "six seconds hands off safely to the two-friend capture beat")
	for kind in ["arjun", "mei", "ending"]:
		story.kind = kind
		story.page = 2
		check.call(not story._canvas.uses_wreck_shot(), "%s story never inherits the shipwreck performance" % kind)
	story.finish()
	await game.get_tree().process_frame
	for t in [0.0, 0.8, 1.45, 2.2, 5.9]:
		var early := StorySequence.new()
		game.add_child(early)
		early.set_process(false)
		early.advance()
		early.advance()
		early._page_time = t
		early.advance()
		check.call(early.page == 3 and early._page_time == 0, "Next at wreck %.2fs exits without a delayed strike callback" % t)
		var reference: WeakRef = weakref(early._canvas._wreck)
		var completions := [0]
		early.completed.connect(func() -> void: completions[0] += 1)
		early.finish()
		early.finish()
		check.call(completions[0] == 1, "Skip after wreck %.2fs completes exactly once" % t)
		await game.get_tree().process_frame
		check.call(reference.get_ref() == null, "Skip after wreck %.2fs releases its whole renderer" % t)
