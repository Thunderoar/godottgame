class_name ReunionDialogueDB
extends RefCounted
## One shared conversation for either rescue order. Completion remains campaign.ending_seen.
const TITLES := ["COUNTING THREE", "THE FISHING TRIP", "WHAT THEY COULDN'T SAY", "A PLAN TOGETHER", "WHO HELPED THEM", "THE NEXT STEP", "FAMILIAR COMPANY", "WHEN THEY'RE READY"]
const TURNS := [
	{"beat":0,"speaker":"adam","mood":"soft","text":"You're both here."},
	{"beat":0,"speaker":"arjun","mood":"smile","text":"Still counting?"},
	{"beat":0,"speaker":"adam","mood":"soft","text":"Just making sure."},
	{"beat":0,"speaker":"mei_ling","mood":"soft","text":"Take your time. We're not going anywhere yet."},
	{"beat":1,"speaker":"arjun","mood":"neck","text":"About that fishing trip..."},
	{"beat":1,"speaker":"mei_ling","mood":"smile","text":"Please don't tell me you nearly caught it."},
	{"beat":1,"speaker":"arjun","mood":"down","text":"I was going to say I'm sorry."},
	{"beat":1,"speaker":"adam","mood":"soft","text":"You couldn't have known what was down there."},
	{"beat":1,"speaker":"mei_ling","mood":"soft","text":"None of us could."},
	{"beat":2,"speaker":"mei_ling","mood":"cup","text":"When the fighting stopped outside my cell, I thought the fiend had won."},
	{"beat":2,"speaker":"adam","mood":"soft","text":"I was still there."},
	{"beat":2,"speaker":"mei_ling","mood":"soft","text":"I know that now."},
	{"beat":2,"speaker":"arjun","mood":"down","text":"I thought I was the only one left."},
	{"beat":2,"speaker":"adam","mood":"down","text":"I didn't know where to look. I just couldn't stop."},
	{"beat":3,"speaker":"mei_ling","mood":"resolved","text":"Next time, we keep each other in sight."},
	{"beat":3,"speaker":"arjun","mood":"soft","text":"And if we get separated?"},
	{"beat":3,"speaker":"mei_ling","mood":"resolved","text":"We find a place to meet. We leave a sign. Something."},
	{"beat":3,"speaker":"adam","mood":"resolved","text":"Then we make a plan before we go."},
	{"beat":4,"speaker":"adam","mood":"soft","text":"Rahim gave me a place to rest. Everyone here helped me keep looking."},
	{"beat":4,"speaker":"mei_ling","mood":"soft","text":"They were waiting when I came through the rift."},
	{"beat":4,"speaker":"arjun","mood":"resolved","text":"Then we thank them properly. All three of us."},
	{"beat":5,"speaker":"mei_ling","mood":"soft","text":"What do we do now?"},
	{"beat":5,"speaker":"adam","mood":"resolved","text":"We work out where to go. Together."},
	{"beat":5,"speaker":"arjun","mood":"smile","text":"First, I want a proper look at that boat."},
	{"beat":5,"speaker":"mei_ling","mood":"resolved","text":"Water. Food. A route. Then the boat."},
	{"beat":5,"speaker":"arjun","mood":"smile","text":"You've already made a list?"},
	{"beat":5,"speaker":"mei_ling","mood":"smile","text":"Someone has to."},
	{"beat":6,"speaker":"adam","mood":"smile","text":"I'm glad it's you two."},
	{"beat":6,"speaker":"arjun","mood":"smile","text":"Who else would put up with us?"},
	{"beat":6,"speaker":"mei_ling","mood":"resolved","text":"Come on. Let's see what needs doing."},
]
const DOCK_TEXT := "Together, when they're ready."

static func turn(index: int) -> Dictionary:
	if index >= TURNS.size(): return {"beat":7,"speaker":"","mood":"resolved","text":DOCK_TEXT}
	return TURNS[clampi(index,0,TURNS.size()-1)].duplicate(true)

static func lines() -> Array:
	var result: Array = []
	for row in TURNS: result.append(str(row.text))
	result.append(DOCK_TEXT)
	return result
