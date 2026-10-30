class_name ReunionDialogueDB
extends RefCounted
## Three reader-paced exchanges, one continuous film, one deliberate completion.
const EXCHANGES := ["three_again", "captain_snacks", "time_to_go"]
const TITLES := ["Three again", "Captain Snacks", "Time to go"]
const TURNS := [
	{"id":"finally","beat":0,"speaker":"adam","mood":"soft","text":"All three. Finally."},
	{"id":"no_fishing","beat":0,"speaker":"arjun","mood":"smile","text":"New rule: no fishing."},
	{"id":"tentacles","beat":0,"speaker":"mei_ling","mood":"smile","text":"A plan with fewer tentacles. I like it."},
	{"id":"snacks","beat":1,"speaker":"arjun","mood":"proud","text":"I brought snacks instead."},
	{"id":"captain","beat":1,"speaker":"mei_ling","mood":"salute","text":"Captain Snacks. A much safer career."},
	{"id":"missed_this","beat":1,"speaker":"adam","mood":"smile","text":"You two... I missed this."},
	{"id":"thanks","beat":2,"speaker":"adam","mood":"wave","text":"Thanks for everything, BESUT."},
	{"id":"aboard","beat":2,"speaker":"mei_ling","mood":"salute","text":"All aboard, Captain."},
	{"id":"promotion","beat":2,"speaker":"arjun","mood":"proud","text":"Best promotion ever."},
]
const DOCK_TEXT := "Together, wherever the tide leads."
const FILM_SECONDS := 17.0
const CARD_GUARD := 0.6
const SHOTS := ["boarding", "cast_off", "farewell", "horizon"]
const SHOT_STARTS := [0.0, 6.0, 9.0, 13.0]
const SHOT_ENDS := [6.0, 9.0, 13.0, FILM_SECONDS]

static func film_page() -> int:
	return EXCHANGES.size()

static func final_page() -> int:
	return film_page()+1

static func exchange_page(id: String) -> int:
	return EXCHANGES.find(id)

static func exchange(index: int) -> Array:
	var result: Array = []
	for row in TURNS:
		if int(row.beat) == index: result.append(row.duplicate(true))
	return result

static func turn(index: int) -> Dictionary:
	return TURNS[clampi(index,0,TURNS.size()-1)].duplicate(true)

static func shot_at(elapsed: float) -> int:
	for index in SHOT_ENDS.size():
		if elapsed < float(SHOT_ENDS[index]): return index
	return SHOTS.size()-1

static func lines() -> Array:
	var result: Array = []
	for index in EXCHANGES.size():
		var text := ""
		for row in exchange(index):
			text += "%s: %s\n" % [CharacterDB.get_character(str(row.speaker)).name,row.text]
		result.append(text.strip_edges())
	result.append("") # Film tells the story through action, without narration.
	result.append("") # Renderer owns the inscription; caption is for save errors.
	return result
