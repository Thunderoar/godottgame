class_name ItemDB
extends RefCounted
## Authoritative item catalogue.
##
## Every price, stack limit, effect and equipment value lives here. Shops,
## inventory, saving and combat read these records instead of duplicating
## numbers in scene scripts.

const ITEMS := {
	"rusty_sword": {
		"name": "Rusty Sword",
		"kind": "weapon",
		"slot": "weapon",
		"style": "sword",
		"price": 0,
		"currency": "gold",
		"stack": 1,
		"attack": 6,
		"description": "A chipped blade from the old house. Adam's first steel.",
		"shop": "equipment",
		"sellable": false,
	},
	"iron_sword": {
		"name": "Iron Sword",
		"kind": "weapon",
		"slot": "weapon",
		"style": "sword",
		"price": 90,
		"currency": "gold",
		"stack": 1,
		"attack": 14,
		"description": "Honest iron, balanced for a long expedition.",
		"shop": "equipment",
	},
	"tideblade": {
		"name": "Tideblade",
		"kind": "weapon",
		"slot": "weapon",
		"style": "sword",
		"price": 240,
		"currency": "gold",
		"stack": 1,
		"attack": 26,
		"description": "A blue-edged sword that hums near the sea.",
		"shop": "equipment",
	},
	"smith_hammer": {
		"name": "Harvest Scythe",
		"kind": "weapon",
		"slot": "weapon",
		"style": "scythe",
		"price": 0,
		"currency": "gold",
		"stack": 1,
		"attack": 9,
		"description": "Arjun's curved scythe. Sweeps through enemies in a wide arc.",
		"shop": "equipment",
		"sellable": false,
	},
	"iron_hammer": {
		"name": "Iron Scythe",
		"kind": "weapon",
		"slot": "weapon",
		"style": "scythe",
		"price": 100,
		"currency": "gold",
		"stack": 1,
		"attack": 18,
		"description": "A tempered crescent blade on a sturdy ash haft.",
		"shop": "equipment",
	},
	"tide_hammer": {
		"name": "Nightreaper",
		"kind": "weapon",
		"slot": "weapon",
		"style": "scythe",
		"price": 260,
		"currency": "gold",
		"stack": 1,
		"attack": 32,
		"description": "A dark reef-iron scythe that reaps through the drowned.",
		"shop": "equipment",
	},
	"reed_bow": {
		"name": "Reed Bow",
		"kind": "weapon",
		"slot": "weapon",
		"style": "bow",
		"price": 0,
		"currency": "gold",
		"stack": 1,
		"attack": 7,
		"description": "A light bow cut from coastal reed. Mei Ling's hunting companion.",
		"shop": "equipment",
		"sellable": false,
	},
	"yew_bow": {
		"name": "Yew Bow",
		"kind": "weapon",
		"slot": "weapon",
		"style": "bow",
		"price": 92,
		"currency": "gold",
		"stack": 1,
		"attack": 14,
		"description": "A strong yew stave with a waxed string.",
		"shop": "equipment",
	},
	"tide_bow": {
		"name": "Tidewind Bow",
		"kind": "weapon",
		"slot": "weapon",
		"style": "bow",
		"price": 245,
		"currency": "gold",
		"stack": 1,
		"attack": 25,
		"description": "Its arrows whistle like the wind over the shallows.",
		"shop": "equipment",
	},
	"cloth_tunic": {
		"name": "Worn Tunic",
		"kind": "armor",
		"slot": "armor",
		"price": 0,
		"currency": "gold",
		"stack": 1,
		"defense": 2,
		"description": "Patched cloth. Better than nothing.",
		"shop": "equipment",
		"sellable": false,
	},
	"leather_vest": {
		"name": "Leather Vest",
		"kind": "armor",
		"slot": "armor",
		"price": 75,
		"currency": "gold",
		"stack": 1,
		"defense": 6,
		"description": "Supple hide with bone buttons.",
		"shop": "equipment",
	},
	"shell_plate": {
		"name": "Shell Plate",
		"kind": "armor",
		"slot": "armor",
		"price": 210,
		"currency": "gold",
		"stack": 1,
		"defense": 12,
		"description": "Layered reef-shell, cool to the touch.",
		"shop": "equipment",
	},
	"drift_shield": {
		"name": "Driftwood Shield",
		"kind": "shield",
		"slot": "shield",
		"price": 60,
		"currency": "gold",
		"stack": 1,
		"defense": 4,
		"description": "Salt-cured planks bound with rope.",
		"shop": "equipment",
	},
	"tower_shield": {
		"name": "Warden's Shield",
		"kind": "shield",
		"slot": "shield",
		"price": 180,
		"currency": "gold",
		"stack": 1,
		"defense": 9,
		"description": "A heavy shield once carried by the grotto watch.",
		"shop": "equipment",
	},
	"health_potion": {
		"name": "Health Potion",
		"kind": "consumable",
		"price": 25,
		"currency": "gold",
		"stack": 9,
		"effect": {"heal": 45},
		"description": "Restores 45 health. Rose-glass bottle.",
		"shop": "potion",
		"lost_on_defeat": false,
	},

	"pet_food": {
		"name": "Pet Food",
		"kind": "consumable",
		"price": 15,
		"currency": "gold",
		"stack": 20,
		"effect": {"pet_xp": 25},
		"description": "Smoked fish and berries sold by Nia. Feed it to your active companion for 25 pet XP.",
		"shop": "pet",
		"lost_on_defeat": false,
	},
	"wood": {
		"name": "Driftwood",
		"kind": "material",
		"price": 4,
		"currency": "gold",
		"stack": 99,
		"description": "Sun-bleached wood gathered from the shore.",
		"shop": "",
		"sellable": true,
	},
}


static func get_item(item_id: String) -> Dictionary:
	return (ITEMS.get(item_id, {}) as Dictionary).duplicate(true)


static func exists(item_id: String) -> bool:
	return ITEMS.has(item_id)


static func name_of(item_id: String) -> String:
	return str(ITEMS.get(item_id, {}).get("name", item_id.capitalize()))


static func stock_for(shop_id: String) -> Array[String]:
	var out: Array[String] = []
	for id in ITEMS:
		if str(ITEMS[id].get("shop", "")) == shop_id:
			out.append(id)
	return out


static func equipment_stock() -> Array[String]:
	return stock_for("equipment")


static func equipment_for_style(style: String) -> Array[String]:
	var out: Array[String] = []
	for id in stock_for("equipment"):
		var item := get_item(id)
		var item_style := str(item.get("style", ""))
		if item_style != "" and item_style != style:
			continue
		out.append(id)
	return out


static func is_equipment(item_id: String) -> bool:
	var item := get_item(item_id)
	return str(item.get("kind", "")) in ["weapon", "armor", "shield"]


static func stat_line(item_id: String) -> String:
	var item := get_item(item_id)
	var bits: Array[String] = []
	if int(item.get("attack", 0)) > 0:
		bits.append("ATK +%d" % int(item["attack"]))
	if int(item.get("magic", 0)) > 0:
		bits.append("MAG +%d" % int(item["magic"]))
	if int(item.get("defense", 0)) > 0:
		bits.append("DEF +%d" % int(item["defense"]))
	for effect_key in item.get("effect", {}):
		match str(effect_key):
			"heal":
				bits.append("Heal %d" % int(item.effect[effect_key]))
			"pet_xp":
				bits.append("Pet XP +%d" % int(item.effect[effect_key]))
	return "  ".join(bits)
