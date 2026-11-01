extends RefCounted

static func run(story: StorySequence, check: Callable, capture: Callable) -> void:
	story.set_process(false)
	check.call(story.kind == "arjun" and story._canvas._arjun != null and bool(GameState.campaign().arjun_rescued), "Arjun's real rescue warms its renderer only after the saved rescue transaction")
	story._mei_input_armed = false
	story._on_next_pressed()
	story._on_skip_pressed()
	check.call(not story._done and not story._arjun_paused and story.page == 0, "the prison interaction cannot also skip or pause Arjun's rescue film")
	story._mei_input_armed = true
	story._next.disabled = false
	story._skip.disabled = false
	story._mei_input_cooldown = 0
	story._on_next_pressed()
	var held := story._page_time
	story._process(1)
	check.call(story._arjun_paused and story._page_time == held and story._next.text == "Resume", "Pause freezes the entire continuous Arjun rescue timeline")
	story._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	story._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_IN)
	story._process(1)
	check.call(story._arjun_paused and story._page_time == held, "returning focus preserves a manually paused Arjun rescue")
	story._on_next_pressed()
	story._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	story._process(1)
	check.call(not story._arjun_paused and story._page_time == held, "focus loss freezes Arjun's film even when it was running")
	story._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_IN)
	var before := ArjunRescueRenderer.sample(0,6,false)
	var after := ArjunRescueRenderer.sample(1,0,false)
	check.call(before.adam == after.adam and before.arjun == after.arjun and before.ship == after.ship, "changing Arjun's rescue caption never jumps either friend or the ship")
	var worst := 0.0
	for i in 719:
		var a := ArjunRescueRenderer.sample(0,i/60.0,false)
		var b := ArjunRescueRenderer.sample(0,(i+1)/60.0,false)
		worst = maxf(worst,maxf(a.adam.distance_to(b.adam),maxf(a.arjun.distance_to(b.arjun),a.ship.distance_to(b.ship))))
	check.call(worst < 2.1, "rescue movement stays continuous across release, reunion, boarding and cast-off")
	var boarding := ArjunRescueRenderer.sample(1,2.6,false)
	var sailing := ArjunRescueRenderer.sample(1,4.8,false)
	check.call(float(boarding.aboard) == 1 and boarding.rope and float(boarding.sail) == 0 and not sailing.rope and float(sailing.sail) > 0, "both friends board before the rope releases and the ship sails")
	check.call(ArjunRescueRenderer.sample(0,0,true).arjun == ArjunRescueRenderer.sample(0,5.9,true).arjun and ArjunRescueRenderer.sample(1,0,true).ship == ArjunRescueRenderer.sample(1,5.9,true).ship, "reduced motion uses two calm readable rescue compositions")
	if capture.is_valid():
		for shot in [[0,1.8,"ocean_11_arjun_release"],[0,3.3,"ocean_12_arjun_reunion"],[1,0.5,"ocean_13_arjun_walk"],[1,2.5,"ocean_14_arjun_board"],[1,4.5,"ocean_15_arjun_sailing"]]:
			story.page = int(shot[0])
			story._page_time = float(shot[1])
			story._render()
			await capture.call(str(shot[2]))
		check.call(story._caption_panel.get_global_rect().end.y <= story.get_viewport().get_visible_rect().end.y and story._caption.get_line_count()*story._caption.get_line_height() <= story._caption.size.y, "Arjun rescue captions and buttons fit the current viewport")
	story.page = 0
	story._page_time = 5.99
	story._render()
	story._process(0.02)
	check.call(story.page == 1 and is_equal_approx(story._page_time,0.01), "automatic caption handoff carries frame overshoot without restarting the animation")
	story._process(6)
	check.call(story._done and bool(GameState.campaign().arjun_rescued), "the completed rescue film hands back to Game without repeating the rescue transaction")
