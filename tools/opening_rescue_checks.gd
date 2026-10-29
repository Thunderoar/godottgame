class_name OpeningRescueChecks
extends RefCounted
## Rescue causality, support contact, sheltering shore and isolated story lifetime.
static func run(game: Game, check: Callable) -> void:
	var start := OpeningRescueRenderer.sample(0, false, "high")
	var meet := OpeningRescueRenderer.sample(OpeningRescueRenderer.MEET, false, "high")
	var boarded := OpeningRescueRenderer.sample(OpeningRescueRenderer.BOARDED, false, "high")
	var end := OpeningRescueRenderer.sample(6, false, "high")
	check.call(start.piece_id == 0 and start.adam == OpeningRescueRenderer.WRECK_FEET and not start.boarded, "rescue opens with Adam stranded on his own stern fragment, not already riding")
	check.call(meet.turtle == Vector2(108, 175) and meet.adam == start.adam and not meet.departed, "turtle comes alongside and offers its shell before Adam moves")
	check.call(boarded.adam == boarded.seat and not boarded.departed, "Adam is safely aboard before the turtle departs")
	check.call(end.ashore and end.welcoming and OpeningRescueArt.on_sand(end.adam) and end.phase == "welcome", "sixth beat ends with Adam safe on BESUT sand and a reaching welcome")
	check.call(end.adam.x - 6 > end.turtle.x + 91, "safe-arrival boots clear the turtle's head instead of standing on its face")
	check.call(OpeningRescueArt.on_sand(end.helper) and OpeningRescueArt.on_sand(end.neighbour), "both villagers stand on actual beach geometry, never open water")
	check.call(OpeningRescueRenderer.sample(0, true, "high") == OpeningRescueRenderer.sample(6, true, "high"), "Reduce Motion holds a complete rescue-and-welcome tableau without hiding the turtle")
	var previous := start
	for i in 241:
		var t := float(i) / 40
		var state := OpeningRescueRenderer.sample(t, false, "high")
		var low := OpeningRescueRenderer.sample(t, false, "low")
		var equal := true
		for key in ["adam", "turtle", "seat", "wreck", "phase", "helper", "neighbour", "pose", "boarded", "departed", "ashore"]: equal = equal and state[key] == low[key]
		check.call(equal, "rescue %.3fs low quality preserves action, faces, support and chronology" % t)
		check.call(OpeningRescueRenderer.supported(state), "rescue %.3fs Adam has continuous wreck, shell or beach support" % t)
		check.call(not state.departed or state.boarded, "rescue %.3fs transport never begins before boarding" % t)
		check.call(not state.ashore or state.arrived, "rescue %.3fs Adam never steps onto shore before the turtle arrives" % t)
		if t >= OpeningRescueRenderer.ARRIVE:
			check.call(state.turtle == end.turtle, "rescue %.3fs turtle waits in the shallows while Adam disembarks" % t)
		check.call(state.adam.distance_to(previous.adam) <= 7 and state.turtle.distance_to(previous.turtle) <= 5, "rescue %.3fs consecutive positions remain continuous" % t)
		var actors_fit := Rect2(16, 48, 448, 171).has_point(state.adam) and Rect2(Vector2.ZERO, OpeningRescueRenderer.FRAME).encloses(Rect2(state.turtle, Vector2(96, 48)))
		check.call(actors_fit and state.adam.distance_to(state.helper) >= 35 and state.adam.distance_to(state.neighbour) >= 60, "rescue %.3fs all actors fit above captions and faces stay separate" % t)
		if t >= OpeningRescueRenderer.MEET and t <= OpeningRescueRenderer.DEPART:
			check.call(state.turtle == meet.turtle, "rescue %.3fs turtle waits still while its passenger boards" % t)
		previous = state
	var source := [OpeningFishingArt.hero("adam", 0).get_image().get_data(), CoastalArt.turtle_texture().get_image().get_data(), OpeningWreckArt.piece("hull", 0).get_image().get_data(), PixelArt.npc_texture("water_keeper").get_image().get_data()]
	var campaign := GameState.campaign()
	var world_time := float(GameState.data.get("world_time", 0))
	var story := StorySequence.new()
	game.add_child(story)
	story.set_process(false)
	for i in StorySequence.INTRO_RESCUE_PAGE:
		check.call(story._canvas._rescue == null and not story._canvas.uses_rescue_shot(), "intro page %d never warms or draws the sixth-beat rescue early" % i)
		story.advance()
	check.call(story._canvas._rescue != null and story._canvas.uses_rescue_shot() and story._page_time == 0, "entering only intro page five warms rescue art before drawing")
	check.call(story.lines().size() == 7 and story._caption.text == StorySequence.INTRO[StorySequence.INTRO_RESCUE_PAGE], "rescue preserves the seven-beat order and original sixth caption")
	check.call(source[0] == OpeningFishingArt.hero("adam", 0).get_image().get_data() and source[1] == CoastalArt.turtle_texture().get_image().get_data() and source[2] == OpeningWreckArt.piece("hull", 0).get_image().get_data() and source[3] == PixelArt.npc_texture("water_keeper").get_image().get_data(), "new rescue poses and art leave shared hero, turtle, wreck and villager pixels untouched")
	var settings := [GameSettings.reduce_motion(), GameSettings.effects_quality()]
	story._page_time = 2.0
	GameSettings.set_reduce_motion(true, false)
	check.call(story._canvas.rescue_state().ashore and story._page_time == 2.0, "live Reduce Motion reveals the welcoming tableau without restarting page time")
	GameSettings.set_effects_quality("low", false)
	check.call(not story._canvas.rescue_state().glints and story._canvas.rescue_state().ripples == 2 and story._canvas.rescue_state().welcoming, "live low quality removes only optional glints and wake marks")
	GameSettings.set_reduce_motion(bool(settings[0]), false)
	GameSettings.set_effects_quality(str(settings[1]), false)
	for size in [Vector2(1280, 720), Vector2(832, 480), Vector2(1600, 720)]:
		var available := Rect2(Vector2.ZERO, Vector2(size.x, size.y - 184))
		var fitted := OpeningRescueRenderer.fit_rect(available)
		check.call(available.encloses(fitted) and absf(fitted.size.x / fitted.size.y - 480.0 / 224.0) < 0.001, "rescue %s keeps people and turtle uniformly fitted above captions" % size)
	var cached := PixelArt.CACHE.size()
	for i in 100: OpeningRescueRenderer.sample(float(i) * 0.06, false, "high")
	check.call(PixelArt.CACHE.size() == cached, "rescue sampling allocates no textures, gameplay actors or asynchronous callbacks")
	story._page_time = 5.99
	story._process(0.02)
	check.call(story.page == 6 and story._page_time == 0 and not story._canvas.uses_rescue_shot(), "six seconds hands rescue to the original final promise caption with fresh reading time")
	check.call(story._canvas.uses_rescue_epilogue() and story._canvas.rescue_state().ashore and story._canvas.rescue_state().adam == end.adam, "the final promise keeps Adam safely ashore instead of putting him back on the turtle")
	var promise_start := story._canvas.rescue_state()
	story._page_time = 5.8
	var promise_end := story._canvas.rescue_state()
	check.call(promise_start == promise_end, "the final promise holds the exact completed rescue tableau for its whole reading time")
	check.call(story._caption.text == StorySequence.INTRO[6] and story._next.text == "Continue", "epilogue reuse preserves the final promise's words and Continue behavior")
	story.finish()
	await game.get_tree().process_frame
	check.call(GameState.campaign() == campaign and float(GameState.data.get("world_time", 0)) == world_time, "standalone rescue viewing never writes campaign or advances village time")
	for kind in ["arjun", "mei", "ending"]:
		var other := StorySequence.new()
		other.kind = kind
		game.add_child(other)
		other.set_process(false)
		other.page = StorySequence.INTRO_RESCUE_PAGE
		check.call(not other._canvas.uses_rescue_shot() and not other._canvas.uses_rescue_epilogue(), "%s story never inherits the intro rescue renderer" % kind)
		other.finish()
	for t in [0.0, 0.7, 1.7, 2.2, 2.6, 3.7, 5.1, 5.8]:
		var early := StorySequence.new()
		game.add_child(early)
		early.set_process(false)
		for i in StorySequence.INTRO_RESCUE_PAGE: early.advance()
		early._page_time = t
		var reference: WeakRef = weakref(early._canvas._rescue)
		early.advance()
		check.call(early.page == 6 and early._page_time == 0, "Next at rescue %.2fs exits immediately without a delayed boarding callback" % t)
		var completed := [0]
		early.completed.connect(func() -> void: completed[0] += 1)
		early.finish()
		early.finish()
		await game.get_tree().process_frame
		check.call(completed[0] == 1 and reference.get_ref() == null, "Skip after rescue %.2fs completes once and releases its renderer" % t)
