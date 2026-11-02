class_name OpeningCastRenderer
extends RefCounted
## Same deck, same foot anchors, same unarmed actors. Only the camera and acting change.
## The final pullback lands exactly on the first fishing frame; no gameplay state.
const NAMES := ["ADAM", "ARJUN", "MEI LING"]
const CLOSE_ZOOM := 4.2
const PULL_START := 2.2
const PULL_END := 5.6

static func sample(shot: int, elapsed: float, reduced: bool, quality: String) -> Dictionary:
	var index := clampi(shot, 0, 2)
	var t := clampf(elapsed, 0.0, 6.0)
	var state := OpeningFishingRenderer.sample(0, reduced, quality)
	var pose := 1 if (reduced or (t >= 0.8 and t < 4.6)) else 0
	state.poses[index] = pose
	# A static camera for accessibility; the third tableau is the complete group.
	var pull := 1.0 if reduced and index == 2 else (smoothstep(PULL_START, PULL_END, t) if index == 2 else 0.0)
	var face: Vector2 = state.feet[index] - Vector2(0, 40.5 if index == 2 else 48)
	var close := face + Vector2(-25 if index == 2 else 27, 10)
	var push := 0.0 if reduced else smoothstep(0, 2.0, t) * 0.12
	state["camera_zoom"] = lerpf(CLOSE_ZOOM + push, 1.0, pull)
	state["camera_centre"] = close.lerp(OpeningFishingRenderer.FRAME * 0.5, pull)
	# Arjun's hands and his actual rod rise together, not as independent props.
	if index == 1 and pose == 1:
		state.hand.y -= 1.5
		state.rod_tip.y -= 3.0
	state["mei_look_left"] = index == 2 and not reduced and t < 4.6
	state["subject"] = OpeningFishingRenderer.HEROES[index]
	state["pullback"] = pull
	return state
