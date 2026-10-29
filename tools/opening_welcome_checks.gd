class_name OpeningWelcomeChecks
extends RefCounted
## The new final page must earn its welcome without changing journey progression.
static func run(game: Game, check: Callable) -> void:
	var start := OpeningWelcomeRenderer.sample(0, false, "high")
	var end := OpeningWelcomeRenderer.sample(6, false, "high")
	var shore := OpeningRescueRenderer.sample(6, false, "high")
	check.call(start.adam == shore.adam and start.helper == shore.helper and start.planter == shore.neighbour and start.turtle == shore.turtle and start.camera == 0, "eighth beat matches the completed rescue/promise positions exactly")
	check.call(end.received and end.guided and end.settled and end.phase == "home", "welcome ends with cloth received, a guide and a place in the village")
	check.call(OpeningWelcomeRenderer.sample(0, true, "high") == OpeningWelcomeRenderer.sample(6, true, "high"), "Reduce Motion holds the complete village welcome without camera travel")
	var previous := start
	for i in 121:
		var t := float(i) / 20
		var state := OpeningWelcomeRenderer.sample(t, false, "high")
		var low := OpeningWelcomeRenderer.sample(t, false, "low")
		var equal := true
		for key in ["adam", "helper", "planter", "host", "turtle", "camera", "cloth", "received", "phase"]: equal = equal and state[key] == low[key]
		check.call(equal, "welcome %.2fs quality preserves every story action and anchor" % t)
		check.call(state.adam.distance_to(previous.adam) <= 7 and state.helper.distance_to(previous.helper) <= 7 and state.planter.distance_to(previous.planter) <= 7 and state.cloth.distance_to(previous.cloth) <= 7, "welcome %.2fs consecutive actor and cloth positions stay continuous" % t)
		check.call(t >= OpeningWelcomeRenderer.RECEIVED or state.adam == start.adam, "welcome %.2fs Adam receives care before walking into village life" % t)
		check.call(state.adam.distance_to(state.helper) >= 35 and state.adam.distance_to(state.planter) >= 32 and state.helper.distance_to(state.planter) >= 35, "welcome %.2fs the villagers leave Adam and each other readable space" % t)
		check.call(state.camera >= 0 and state.camera <= 200 and state.camera >= previous.camera and state.adam.x - state.camera >= 16 and state.adam.x - state.camera <= 464, "welcome %.2fs the pan stays within the panorama and keeps Adam framed" % t)
		check.call(state.adam.y >= 150 and state.helper.y >= 140 and state.planter.y >= 140 and OpeningRescueArt.on_sand(Vector2(minf(state.adam.x, 479), state.adam.y)), "welcome %.2fs every travelling actor stays on the established land" % t)
		if state.received:
			check.call(state.cloth == state.adam + Vector2(8, -14), "welcome %.2fs the received cloth stays with Adam" % t)
		previous = state
	var source := OpeningRescueArt.backdrop().get_image().get_data()
	var planter_source := OpeningRescueArt.villager("tree_planter", true).get_image().get_data()
	var campaign := GameState.campaign()
	var world_time := float(GameState.data.get("world_time", 0))
	var story := StorySequence.new()
	game.add_child(story)
	story.set_process(false)
	for i in StorySequence.INTRO_WELCOME_PAGE:
		check.call(story._canvas._welcome == null and not story._canvas.uses_welcome_shot(), "intro page %d does not allocate or draw the village welcome early" % i)
		story.advance()
	check.call(story.lines().size() == 8 and story._canvas.uses_welcome_shot() and story._canvas._welcome != null and story._page_time == 0, "page seven lazily enters the new eighth beat with full reading time")
	check.call(story._caption.text.contains("Welcome to BESUT, Adam") and story._next.text == "Continue", "the village speaks directly to Adam and Continue belongs to the eighth beat")
	check.call(source == OpeningRescueArt.backdrop().get_image().get_data() and planter_source == OpeningRescueArt.villager("tree_planter", true).get_image().get_data(), "welcome extensions and handoff poses never modify shared shore or villager pixels")
	var panorama := OpeningWelcomeArt.backdrop().get_image()
	check.call(panorama.get_region(Rect2i(0, 0, 480, 224)).get_data() == source, "the first 480 pixels of the village panorama preserve the exact rescue shore")
	var settings := [GameSettings.reduce_motion(), GameSettings.effects_quality()]
	story._page_time = 1.1
	GameSettings.set_reduce_motion(true, false)
	check.call(story._canvas.welcome_state().settled and story._page_time == 1.1, "live Reduce Motion shows the settled welcome without restarting the clock")
	GameSettings.set_effects_quality("low", false)
	check.call(not story._canvas.welcome_state().glints and story._canvas.welcome_state().received, "low quality keeps the welcome and cloth while removing optional sea details")
	GameSettings.set_reduce_motion(bool(settings[0]), false)
	GameSettings.set_effects_quality(str(settings[1]), false)
	for size in [Vector2(1280, 720), Vector2(832, 480), Vector2(1600, 720)]:
		var available := Rect2(Vector2.ZERO, Vector2(size.x, size.y - 184))
		var fit := OpeningWelcomeRenderer.fit_rect(available)
		check.call(available.encloses(fit) and is_equal_approx(fit.size.x / fit.size.y, 480.0 / 224.0), "welcome %s preserves proportions and caption clearance" % size)
	var cached := PixelArt.CACHE.size()
	for i in 100: OpeningWelcomeRenderer.sample(float(i) * 0.06, false, "high")
	check.call(PixelArt.CACHE.size() == cached, "welcome page-clock sampling creates no textures or world actors")
	var completed := [0]
	story.completed.connect(func() -> void: completed[0] += 1)
	story._page_time = 5.99
	story._process(0.02)
	check.call(story._done and completed[0] == 1, "only after the eighth beat's six seconds does the intro complete")
	story.finish()
	await game.get_tree().process_frame

	check.call(completed[0] == 1 and GameState.campaign() == campaign and float(GameState.data.get("world_time", 0)) == world_time, "standalone welcome completes once without changing campaign or village time")
	for t in [0.0, 1.6, 2.5, 3.7, 5.5]:
		var early := StorySequence.new()
		game.add_child(early)
		early.set_process(false)
		for i in StorySequence.INTRO_WELCOME_PAGE: early.advance()
		early._page_time = t
		var reference: WeakRef = weakref(early._canvas._welcome)
		early.advance()
		await game.get_tree().process_frame
		check.call(reference.get_ref() == null, "Next at welcome %.1fs releases the renderer with no delayed handoff or pan" % t)
	for kind in ["arjun", "mei", "ending"]:
		var other := StorySequence.new()
		other.kind = kind
		game.add_child(other)
		other.set_process(false)
		other.page = StorySequence.INTRO_WELCOME_PAGE
		check.call(not other._canvas.uses_welcome_shot(), "%s story does not inherit the intro's village welcome" % kind)
		other.finish()
	await game.get_tree().process_frame

static func run_dock_arrivals(game: Game, check: Callable) -> void:
	var snapshot := GameState.data.duplicate(true)
	var autosave := GameState.autosave_enabled
	GameState.autosave_enabled = false
	GameState.data = GameState._make_default("adam")
	GameState._emit_all()
	await game._load_lobby(false, true)
	await game.get_tree().physics_frame
	await game.get_tree().physics_frame
	var lobby := game.world as Lobby
	var deck := lobby._layout.world_footprint("jetty_deck")
	var planner := ResidentRoutes.new(lobby)
	check.call(lobby.player.position == lobby._layout.approach("jetty_deck") and lobby._mission_walk_origin == lobby.player.position, "first arrival places Adam and the movement-lesson origin at the resolved dock")
	check.call(deck.grow(-0.26).has_point(lobby.player.position) and deck.grow(-0.18).has_point(lobby.pet.position), "first-arrival player and companion bodies fit inside the physical deck")
	check.call(planner.point_clear(lobby.player.position) and planner.point_clear(lobby.pet.position) and planner.segment_clear(lobby.player.position, lobby._layout.approach("jetty_landing")), "dock arrival has clear actor-sized space and an unblocked route ashore")
	check.call(lobby.get_spawn_position() == lobby._house_position + Vector2(0, 2.9) and lobby._recovery_center == lobby._house_position + Vector2(0, 2.3), "dock first arrival leaves home, defender and recovery anchors owned by the cottage")
	check.call(lobby.camera.target == lobby.player and GameState.mission_step() == 0, "dock camera follows the correct player while the first lesson waits for input")
	await game._load_lobby(false)
	check.call(not game.world.arrive_at_dock and game.player().position == game.world.get_spawn_position(), "an ordinary village return restores the normal home arrival instead of repeating first landfall")
	GameState.data.recovery_active = true
	GameState.data.hp = 1
	await game._load_lobby(false, true)
	check.call(game.player().position == game.world.get_spawn_position() and game.player().position.distance_to(game.world._recovery_center) < Lobby.RECOVERY_RADIUS, "active recovery keeps Adam at the cottage even if a dock arrival was requested")
	GameState.data = snapshot
	GameState._emit_all()
	await game._load_lobby(false)
	GameState.autosave_enabled = autosave
