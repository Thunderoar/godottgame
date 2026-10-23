@tool
class_name MonsoonLighting
extends RefCounted
## Presentation derives only from GameState's existing 180s day / 180s night.
## Pure functions are shared by fixtures and runtime; no new clock or save fields.
const DAY := Color(1.0, 1.025, 1.015)
const DAWN := Color(0.96, 1.0, 0.98)
const GOLDEN := Color(1.025, 0.90, 0.82)
const NIGHT := Color(0.48, 0.62, 0.78)
const PHASE_SECONDS := 180.0

static func grade(world_time: float) -> Color:
	var cycle := fposmod(world_time, PHASE_SECONDS * 2.0)
	if cycle < PHASE_SECONDS:
		var morning := DAWN.lerp(DAY, smoothstep(0.0, 22.0, cycle))
		return morning.lerp(GOLDEN, smoothstep(133.0, 180.0, cycle))
	var evening := GOLDEN.lerp(NIGHT, smoothstep(180.0, 193.0, cycle))
	return evening.lerp(DAWN, smoothstep(340.0, 360.0, cycle))

static func lantern_strength(world_time: float) -> float:
	var cycle := fposmod(world_time, PHASE_SECONDS * 2.0)
	return smoothstep(140.0, 188.0, cycle) * (1.0 - smoothstep(336.0, 360.0, cycle))
