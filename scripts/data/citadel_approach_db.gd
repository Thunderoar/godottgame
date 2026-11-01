class_name CitadelApproachDB
extends RefCounted
## One prerequisite graph supplies dialogue, prompts and objective guidance.
const PAIRS := ["rootbound_patrol", "watchpost_guard", "ashen_sentries"]
const CROSSING := Vector2(33, 40.8)
const ENTRANCE := Vector2(26, 19.2)
const WISP := "Adam: I'm looking for my friend. An archer. Her name's Mei Ling.\nWisp: I know that village lantern's light. The guards brought an archer to the citadel. Alive.\nAdam: Then that's where I'm going.\nWisp: Its outer ward drinks from three lights along this road. The guards have bound them.\nAdam: Break the bindings. Open the road.\nWisp: Yes. Old stones lead north, but keep your way home. That rift is still yours."
const INTRO := [
	"Adam: Mei Ling!\nMei Ling: Adam? Stay clear of the marked floor!",
	"Fiend: Another traveller following a stolen light.\nAdam: Open the prison.",
	"Fiend: The road may answer you. This citadel answers me.\nMei Ling: Then show him the difference.\nAdam: Stay back from the bars. I've got this.",
]
static func defaults() -> Dictionary:
	return {"cleared_pairs": [], "crossing_lit": false, "watchpost_lit": false, "lantern_prepared": false, "intro_seen": false}
static func ready(path: Dictionary, shortcut: bool) -> bool:
	return PAIRS.all(func(id: String) -> bool: return id in path.get("cleared_pairs", [])) and path.get("crossing_lit", false) == true and path.get("watchpost_lit", false) == true and shortcut and path.get("lantern_prepared", false) == true
static func can_prepare(path: Dictionary, shortcut: bool) -> bool:
	var copy := path.duplicate(true)
	copy.lantern_prepared = true
	return ready(copy, shortcut)
static func next_step(path: Dictionary) -> Dictionary:
	var cleared: Array = path.get("cleared_pairs", [])
	if PAIRS[0] not in cleared: return {"id":"crossing_guards", "title":"Free the crossing light", "detail":"Defeat the two Imps north of Rootbound Crossing. Read their rush, step aside, then counter."}
	if not path.get("crossing_lit",false): return {"id":"crossing", "title":"Relight the crossing marker", "detail":"The patrol binding is broken. Return to the marker beside the bridge and relight it."}
	if PAIRS[1] not in cleared: return {"id":"watchpost_guards", "title":"Free the watchpost winch", "detail":"Defeat the watchpost pair. Use the fan gaps or the real stone cover."}
	if not path.get("watchpost_lit",false): return {"id":"watchpost", "title":"Restore the watchpost light", "detail":"Turn the Rootway winch to reconnect its light and open the shortcut."}
	if PAIRS[2] not in cleared: return {"id":"ashen_guards", "title":"Clear the ashen sentries", "detail":"Defeat the last pair south of the lantern. Move diagonally out of the marked cross."}
	if not path.get("lantern_prepared",false): return {"id":"lantern", "title":"Prepare the citadel lantern", "detail":"Rest at the lantern to restore your strength, save a checkpoint and carry the last light to the ward."}
	return {"id":"enter", "title":"Enter the citadel when ready", "detail":"The outer ward can be opened. Approach its entrance and choose Enter the citadel. The prison seal still belongs to the fiend."}
static func followup(path: Dictionary) -> String:
	return str(next_step(path).detail)
