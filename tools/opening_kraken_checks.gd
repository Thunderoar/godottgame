class_name OpeningKrakenChecks
extends RefCounted
## Integrated deterministic checks for the caught arm and waking sea king.
static func run(game: Game, check: Callable) -> void:
	var start := OpeningKrakenRenderer.sample(0, false, "high")
	var snag := OpeningKrakenRenderer.sample(1.5, false, "high")
	var rising := OpeningKrakenRenderer.sample(2.5, false, "high")
	var fury := OpeningKrakenRenderer.sample(5.5, false, "high")
	check.call(start.rise == 0 and not start.awake and start.catch == 0, "second beat starts before the hidden Kraken has risen or woken")
	check.call(snag.catch == 1 and snag.rise == 0 and not snag.awake, "hook tension precedes the enormous body reveal")
	check.call(rising.rise > 0 and rising.rise < 1 and not rising.awake, "the Kraken emerges before its eyes open")
	check.call(fury.rise == 1 and fury.awake and fury.pose == 2, "the final beat holds the awakened sea king in fury")
	for t in [0.0, 0.6, 1.4, 2.5, 3.5, 4.5, 5.9]:
		var state := OpeningKrakenRenderer.sample(t, false, "high")
		check.call(state.line[0] == state.rod_tip and state.line[-1] == state.hook, "Kraken t=%.1f line connects the real rod tip and hooked arm" % t)
		check.call(Rect2(Vector2.ZERO, OpeningKrakenRenderer.FRAME).has_point(state.hook), "Kraken t=%.1f hook remains in the artwork" % t)
		for i in 3:
			check.call(state.feet[i] == state.boat + (OpeningFishingRenderer.FEET[i] * OpeningKrakenRenderer.BOAT_SCALE).round(), "Kraken t=%.1f friend %d stays grounded on the intact ship" % [t, i])
		var low := OpeningKrakenRenderer.sample(t, false, "low")
		check.call(low.line == state.line and low.hook == state.hook and low.feet == state.feet and low.pose == state.pose and low.rise == state.rise, "Kraken t=%.1f low quality retains every essential narrative anchor" % t)
	check.call(not OpeningKrakenRenderer.sample(5, false, "low").drops, "low quality removes optional droplets, not the hooked arm")
	check.call(OpeningKrakenRenderer.sample(0, true, "high") == OpeningKrakenRenderer.sample(5.9, true, "high"), "Reduce Motion holds a complete stable caught-arm/awake-Kraken tableau")
	for extent in [Vector2(1280, 526), Vector2(832, 286), Vector2(1600, 526), Vector2(600, 700)]:
		var area := Rect2(Vector2.ZERO, extent)
		var fit := OpeningKrakenRenderer.fit_rect(area)
		check.call(area.encloses(fit) and is_equal_approx(fit.size.x / fit.size.y, 480.0 / 224.0), "Kraken fits %s above the caption without stretching actors" % extent)
	var story := StorySequence.new()
	game.add_child(story)
	story.set_process(false)
	check.call(not story._canvas.uses_kraken_shot(), "peaceful beat does not expose the Kraken")
	story.advance()
	check.call(story._canvas.uses_kraken_shot() and story.page == 1 and story._page_time == 0, "Next enters the caught-hook beat with a fresh six-second clock")
	check.call(story._caption.text == StorySequence.INTRO[1], "second-beat story caption remains unchanged")
	var reduced := GameSettings.reduce_motion()
	var quality := GameSettings.effects_quality()
	story._page_time = 2.5
	GameSettings.set_reduce_motion(true, false)
	check.call(story._canvas.kraken_state().awake and not story._canvas.kraken_state().drops and story._page_time == 2.5, "live Reduce Motion stops motion immediately without resetting narrative time")
	GameSettings.set_effects_quality("low", false)
	check.call(story._canvas.kraken_state().ripples == 2, "live low quality updates the second beat")
	GameSettings.set_reduce_motion(reduced, false)
	GameSettings.set_effects_quality(quality, false)
	var count := PixelArt.CACHE.size()
	for i in 100: OpeningKrakenRenderer.sample(float(i) * 0.06, false, "high")
	check.call(count == PixelArt.CACHE.size(), "Kraken sampling never allocates textures or gameplay nodes")
	check.call(not OpeningKrakenArt.body(2).has_meta("realistic_art"), "opening Kraken is an original classic-pixel sprite, not a modern illustration")
	story._page_time = 5.99
	story._process(0.02)
	check.call(story.page == 2 and story._page_time == 0 and story._canvas.uses_wreck_shot(), "automatic six-second handoff enters the ship-breaking shot with a fresh clock")
	for kind in ["arjun", "mei", "ending"]:
		story.kind = kind
		story.page = 1
		check.call(not story._canvas.uses_kraken_shot(), "%s story never inherits the opening Kraken shot" % kind)
	story.finish()
	await game.get_tree().process_frame
	for t in [0.0, 0.5, 2.5, 5.9]:
		var early := StorySequence.new()
		game.add_child(early)
		early.set_process(false)
		early.advance()
		early._page_time = t
		early.advance()
		check.call(early.page == 2 and early._page_time == 0 and not early._canvas.uses_kraken_shot(), "Next at %.1fs safely exits the Kraken beat" % t)
		var ref: WeakRef = weakref(early._canvas._kraken)
		var completions := [0]
		early.completed.connect(func() -> void: completions[0] += 1)
		early.finish()
		early.finish()
		check.call(completions[0] == 1, "Skip after Kraken t=%.1f completes once" % t)
		await game.get_tree().process_frame
		check.call(ref.get_ref() == null, "Skip after Kraken t=%.1f releases the renderer" % t)
