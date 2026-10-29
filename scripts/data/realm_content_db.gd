class_name RealmContentDB
extends RefCounted
## Stable journey IDs; ambient poses and patrol clocks are deliberately unsaved.

const WAYKEEPER := "waykeeper"
const CACHE := "cache_rootway_hollow"
const CACHE_GOLD := 25
const HOLLOW := Vector2(8, 24)
const INTERESTS := {
	"waykeeper": {"kind": "waykeeper", "name": "Wisp, the Waykeeper", "at": Vector2(22,45)},
	"memory_road_lights": {"kind": "memory", "name": "The Road That Shone", "at": Vector2(29,43), "text": "We lit the road for every traveller. Fox, moth and stranger alike could follow its warmth home. The citadel's light once answered ours."},
	"memory_silent_bells": {"kind": "memory", "name": "When the Bells Fell Silent", "at": Vector2(10,31), "text": "The bells fell quiet before the trees darkened. Small creatures gathered where the last lanterns burned. We left those clearings undisturbed."},
	"memory_stolen_light": {"kind": "memory", "name": "A Light Below the Throne", "at": Vector2(49,30), "text": "The road did not lose its light. Something drew it inward, beneath the citadel. When its windows brightened, the forest grew cold."},
	"cache_rootway_hollow": {"kind": "cache", "name": "Rootway Hollow", "at": HOLLOW},
}
const FRAGMENTS := ["memory_road_lights", "memory_silent_bells", "memory_stolen_light"]
const HOLLOW_PATH := [Vector2(17,28), Vector2(13,26), HOLLOW]

static func reserved(at: Vector2) -> bool:
	for def in RealmDB.ENCOUNTERS.values():
		if Rect2(def.at + Vector2(-4,-3), Vector2(8,7)).has_point(at): return true
	for def in INTERESTS.values():
		if at.distance_to(def.at) < 3.0: return true
	for i in range(1, HOLLOW_PATH.size()):
		if Geometry2D.get_closest_point_to_segment(at, HOLLOW_PATH[i-1], HOLLOW_PATH[i]).distance_to(at) < 2.5: return true
	return false

static func waykeeper_words(progress: Dictionary, restored: bool) -> String:
	if restored: return "The road is breathing again. Some quiet places are still waiting to be found."
	if progress.get("read_fragments", []).size() == 3: return "Those lights belonged to the road. The citadel gathered what the forest lost."
	if not progress.get("bonded", []).is_empty(): return "A little trust can travel farther than a bright lantern."
	if not progress.get("read_fragments", []).is_empty(): return "The stones remember. You need only stop long enough to read them."
	return "Old stones lead to the citadel. Small lives still shelter beside the road."

static func journal(progress: Dictionary) -> String:
	var read: Array = progress.get("read_fragments", [])
	var pages: Array[String] = ["%d / 3 memories recovered. Read the weathered stones in Twilight Wilds; each memory stays here." % read.size()]
	for id in FRAGMENTS:
		var def: Dictionary = INTERESTS[id]
		pages.append((str(def.name) + "\n" + str(def.text)) if id in read else "Unrecovered memory\nA quiet stone still holds its light.")
	return "\n\n".join(pages)
