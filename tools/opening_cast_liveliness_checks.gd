extends RefCounted
## Concrete task, facial, listener, prop, cut-continuity and finite-cache regressions.
static func run(game: Game, check: Callable) -> void:
	var saved := GameState.data.duplicate(true)
	var original := OpeningFishingArt.hero("adam",0).get_image().get_data()
	var warmer := OpeningFishingRenderer.new()
	var cache_size := OpeningCastArt.FRAMES.size()
	check.call(cache_size == 432, "acting uses exactly 432 bounded prewarmed sprite variants, independent of elapsed time")
	for index in 3:
		var actions: Array[int] = []
		var mouths: Array[int] = []
		var blinks := 0
		for tick in 120:
			var time := float(tick)*0.05
			var state := OpeningCastRenderer.sample(index,time,false,"high")
			var actor: Dictionary = state.crew[index]
			if not int(actor.action) in actions: actions.append(int(actor.action))
			if not int(actor.mouth) in mouths: mouths.append(int(actor.mouth))
			if actor.blink: blinks += 1
			var speakers := 0
			for member in state.crew:
				if member.speaking: speakers += 1
			check.call(speakers <= 1, "only the current speaker has talking mouth shapes: shot %d / %.2f" % [index,time])
			check.call(state.hand == OpeningCastPerformance.rod_hand(state.feet[1],state.crew[1]), "reel wrist and rod share one anchor: shot %d / %.2f" % [index,time])
		check.call(actions.size() >= 3 and 0 in mouths and 1 in mouths and 2 in mouths and blinks > 0, "speaker %d performs a task, closes between speech bursts and blinks" % index)
		var low := OpeningCastRenderer.sample(index,1.3,false,"low")
		check.call(low.crew == OpeningCastRenderer.sample(index,1.3,false,"high").crew, "low effects retains task, expression and listener score: " + str(index))
		check.call(OpeningCastRenderer.sample(index,0,true,"high").crew == OpeningCastRenderer.sample(index,5.99,true,"high").crew, "reduced-motion acting is a static readable prop tableau: " + str(index))
	for cut in 2:
		var before := OpeningCastRenderer.sample(cut,6,false,"high")
		var after := OpeningCastRenderer.sample(cut+1,0,false,"high")
		for field in ["crew","feet","boat","hand","rod_tip","mei_look_left"]:
			check.call(before[field] == after[field], "motivated cut preserves ensemble field %s at cut %d" % [field,cut])
	var wide := OpeningCastRenderer.sample(2,6,false,"high")
	check.call(wide.crew == OpeningFishingRenderer.sample(0,false,"high").crew, "pullback-to-wide preserves held rope, chart and every actor state")
	check.call(OpeningCastPerformance.sample(4.5,false)[0].attention == "Arjun", "Adam anticipates Arjun's reply before the camera cut")
	check.call(OpeningCastPerformance.sample(11.5,false)[2].attention == "Arjun" and OpeningCastPerformance.sample(11.5,false)[2].mouth == 3, "Mei Ling stops reading and smiles before answering")
	check.call(OpeningCastPerformance.sample(14.3,false)[1].business == "take the joke" and not OpeningCastPerformance.sample(14.3,false)[1].speaking, "Arjun reacts to Mei Ling without stealing her line")
	check.call(OpeningCastPerformance.sample(23.5,false)[0].action == 5 and OpeningCastPerformance.sample(23.5,false)[2].action == 5, "rope and chart are stowed before the existing hooked-Kraken shot")
	for id in ["adam","arjun","mei_ling"]:
		var rest := OpeningCastArt.frame(id,0,0,false,0).get_image().get_data()
		check.call(rest != OpeningCastArt.frame(id,2,0,false,0).get_image().get_data(), id+" task changes actual sprite pixels, not only descriptive metadata")
		check.call(rest != OpeningCastArt.frame(id,0,2,false,0).get_image().get_data(), id+" speaking changes actual mouth pixels")
		check.call(rest != OpeningCastArt.frame(id,0,0,true,0).get_image().get_data(), id+" blink changes actual eye pixels")
	for tick in 240: OpeningCastRenderer.sample(tick/80, float(tick%80)*0.075,false,"high")
	check.call(OpeningCastArt.FRAMES.size() == cache_size and warmer != null, "sampling a long replay allocates no sprite frames or caches")
	check.call(OpeningFishingArt.hero("adam",0).get_image().get_data() == original, "new acting never repaints shared hero source textures")
	check.call(GameState.data == saved, "pure ensemble performance never mutates saves, rescue flags or possessions")
