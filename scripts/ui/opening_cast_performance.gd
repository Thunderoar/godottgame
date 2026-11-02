class_name OpeningCastPerformance
extends RefCounted
## One 24-second ensemble score: three close-ups, then the wide shot.
## Acting survives cuts. No per-frame images, RNG, nodes, audio or progression writes.
const REEL_WRISTS := [Vector2(25,30), Vector2(25,29), Vector2(25,28), Vector2(25,29), Vector2(25,30)]

static func sample(elapsed: float, reduced: bool) -> Array[Dictionary]:
	var t := 18.0 if reduced else clampf(elapsed, 0.0, 24.0)
	var crew: Array[Dictionary] = []
	for index in 3:
		var action := 0
		var business := "hold coil" if index == 0 else ("watch float" if index == 1 else "chart on lap")
		if index == 0:
			if t < 3.2:
				action = 1 if t < 0.35 or (t >= 1.0 and t < 1.65) else (3 if t >= 2.4 else 2)
				business = ["hold coil","gather rope","form loop","lower coil","settle coil"][action]
			elif t < 4.0 or (t >= 9.0 and t < 10.0):
				action = 4
				business = "settle coil"
		elif index == 1:
			if (t >= 6.25 and t < 9.8) or (t >= 19.0 and t < 20.2):
				var start := 6.25 if t < 18 else 19.0
				action = [1,2,3,2][int((t-start)/0.28) % 4]
				business = "work reel"
			elif (t >= 9.8 and t < 10.4) or (t >= 14.1 and t < 14.7):
				action = 4
				business = "confident hold" if t < 12 else "take the joke"
		else:
			if t < 10.5:
				action = 2 if (t >= 1.0 and t < 2.8) or (t >= 7.0 and t < 8.8) else 1
				business = "trace chart" if action == 2 else "read chart"
			elif t < 14.5:
				action = 4 if t >= 12.7 and t < 13.6 else 3
				business = "one palm-up tease" if action == 4 else "lower chart and answer"
			elif t < 15.5:
				action = 2
				business = "return to chart"
		# Finish the little jobs during the wide, before the original Kraken shot.
		if index == 0 and t >= 21.5:
			action = 3 if t < 22.1 else (4 if t < 22.6 else 5)
			business = "stow coil" if action != 5 else "coil stowed"
		if index == 2 and t >= 21.0:
			action = 2 if t < 21.6 else (3 if t < 22.3 else 5)
			business = "fold and stow chart" if action != 5 else "chart stowed"
		var attention := "horizon"
		if t < 4.0: attention = "own task" if index == 0 or index == 2 else "Adam"
		elif t < 6.0: attention = "Arjun" if index == 0 else ("float" if index == 1 else "chart")
		elif t < 10.5: attention = "Arjun" if index == 0 else ("float" if index == 1 else "chart")
		elif t < 14.5: attention = "Mei Ling" if index != 2 else "Arjun"
		elif t < 16.6: attention = "Mei Ling" if index == 0 else ("float" if index == 1 else "chart")
		var mouth := 0
		var local := t - index * 6.0
		if not reduced and local >= 0.55 and local < 4.05:
			# Irregular phrase groups, with closed-mouth rests; stylised speech, not VO lip sync.
			for window in [Vector2(0.55,1.50),Vector2(1.85,2.70),Vector2(3.05,4.05)]:
				if local >= window.x and local < window.y:
					mouth = [1,2,1,0][int((local-window.x)*8.0) % 4]
		if (index == 0 and t >= 14.3 and t < 15.5) or (index == 1 and t >= 10.4 and t < 11.0) or (index == 2 and ((t >= 10.8 and t < 12) or (t >= 13.6 and t < 14.4))):
			if mouth == 0: mouth = 3
		var blink := false
		if not reduced:
			var times: Array = [[2.8,8.8,15.8,21.4],[4.8,10.8,16.4,22.2],[1.7,7.2,14.9,20.7]][index]
			for centre in times:
				if absf(t-float(centre)) < 0.075: blink = true
		var gaze := 1 if attention in ["Adam","Arjun","Mei Ling"] else (2 if attention in ["own task","chart"] else 0)
		crew.append({"action":action,"mouth":mouth,"blink":blink,"gaze":gaze,"attention":attention,"business":business,"speaking":mouth in [1,2]})
	return crew

static func right_wrist(action: int) -> Vector2:
	return REEL_WRISTS[clampi(action,0,4)]

static func rod_hand(foot: Vector2, actor: Dictionary) -> Vector2:
	return (foot + (right_wrist(int(actor.action))-Vector2(16,48))*1.5).round()
