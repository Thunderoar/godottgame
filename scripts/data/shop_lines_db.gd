class_name ShopLinesDB
extends RefCounted
## Shopkeeper dialogue lines, one table per shop kind and mood. Keepers: Mara
## (potions), Garrick (equipment + wood), Nia (companions), Bram (construction).
## Same DB pattern as the other *_db.gd files: const table + static getters that
## return duplicates so callers can never mutate the source.


const LINES := {
	"potion": {
		"keeper": "Mara",
		"greeting": [
			"Fresh tonics, still warm from the still.",
			"Come in, come in — mind the fumes.",
			"You look like you met a bogling. I have just the thing.",
		],
		"buy": [
			"Good choice. Sip it, do not gulp it.",
			"That one has never failed anybody. Yet.",
			"Wrapped and sealed. Next!",
		],
		"deny": [
			"Coin first, tonic after. House rule.",
			"That purse is too light, dear.",
			"Come back when the gold jingles.",
		],
		"equip": [
			"Hold it steady — there you go.",
		],
		"sell": [
			"A fair price for honest work.",
		],
		"close": [
			"Mind the fog on your way home.",
			"Come back before the tide turns.",
		],
	},
	"equipment": {
		"keeper": "Garrick",
		"greeting": [
			"Steel today? Good. I hate slow mornings.",
			"Every blade on that rack outlived its last owner.",
			"Watch the sparks. Always watch the sparks.",
		],
		"buy": [
			"Good iron. Treat it well and it returns the favour.",
			"Sold! Try not to chip it on the first bogling.",
			"That one sings when it swings. Hear it?",
		],
		"deny": [
			"Not enough coin. The forge does not run on promises.",
			"Gold first. Then the good steel.",
		],
		"equip": [
			"Fits you. Mind the edge.",
		],
		"sell": [
			"Driftwood again? Fine, fine. Into the pile.",
			"Good stack. The forge eats well tonight.",
		],
		"close": [
			"Keep your edge and your wits.",
		],
	},
	"pet": {
		"keeper": "Nia",
		"greeting": [
			"Shh — the tide moth just settled.",
			"They pick their people, you know.",
			"Softly now. They are all listening.",
		],
		"buy": [
			"She likes you. Look at that!",
			"A fine match. Feed her well.",
			"Take good care of this one. They remember.",
		],
		"deny": [
			"They are not cheap to keep, and neither is gold.",
			"More gold first, friend.",
		],
		"equip": [
			"There — a companion at your heel again.",
		],
		"sell": [
			"Every coin helps the pens.",
		],
		"close": [
			"Come back and visit, both of you.",
		],
	},
	"house": {
		"keeper": "Bram",
		"greeting": [
			"Blueprints, diamonds, and a straight wall. That is all I need.",
			"Five levels, five lives for that cottage. Let us begin.",
			"Measure twice. Build once.",
		],
		"buy": [
			"The lanterns go in at level five. You will see.",
			"Good. The crew starts at dawn.",
			"Another level closer to the Lantern House.",
		],
		"deny": [
			"Diamonds only. The quarry will not take promises.",
			"Bring me the deep stones — diamonds, friend.",
		],
		"equip": [
			"The porch is level. Good.",
		],
		"sell": [
			"Every gem counts toward the next beam.",
		],
		"close": [
			"Mind the scaffolding on your way out.",
		],
	},
}


static func line(shop_type: String, mood: String) -> String:
	var table: Dictionary = LINES.get(shop_type, {}) as Dictionary
	if table.is_empty():
		return "Welcome."
	var options: Array = table.get(mood, []) as Array
	if options.is_empty():
		options = table.get("greeting", ["Welcome."]) as Array
	return str(options[randi() % options.size()])


static func keeper_of(shop_type: String) -> String:
	return str((LINES.get(shop_type, {}) as Dictionary).get("keeper", "Merchant"))
