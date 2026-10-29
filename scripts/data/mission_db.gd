class_name MissionDB
extends RefCounted
## One action at a time. Events are accepted only for the current lesson.

const DAY_STEPS := [0, 1, 2, 3, 5, 6, 7]
const NIGHT_STEPS := [4, 8, 9]

const STEPS := [
	{"event": "move", "title": "1. Learn to move", "text": "Use WASD or the left joystick. Hold Shift or the Sprint button to run; the blue bar below health is stamina. Tap NPCs and nearby objects directly. Walk along the dotted arrows to the yard marker.", "target": "yard"},
	{"event": "gather", "title": "2. Gather wood", "text": "Follow the arrows to driftwood. Stand beside it and tap the driftwood, or press E. Wood can be sold at the equipment shop.", "target": "wood"},
	{"event": "buy", "title": "3. Buy a potion", "text": "Visit Mara's Potion Shop. Tap the shop, then Buy a Health Potion. After a hit leaves HP at 25% or below, a potion is used automatically while stock lasts.", "target": "potion"},
	{"event": "inventory", "title": "4. Open your backpack", "text": "Tap Pack or press I to inspect your items, equip weapons and use supplies.", "target": ""},
	{"event": "fire_kill", "title": "5. Protect a tree", "text": "Day and night each last 3 minutes. New monsters arrive only at night; survivors remain dangerous by day. Follow the arrows to a fire monster and press F or Attack. Fire monsters can attack you, exposed residents and mature trees. Drops are collected automatically.", "target": "fire"},
	{"event": "services", "title": "6. Meet the water keepers", "text": "Visit the Worker Shop. Blue workers fight fire monsters and extinguish trees; green workers plant protected 30-second saplings. Hire extra specialists with Gold.", "target": "services"},
	{"event": "house", "title": "7. Learn village repairs", "text": "Visit Bram's Construction Shop. Houses shelter residents from sea urchins. Orange builders repair damaged houses and fences by day, working for 10 seconds after arrival. Preview Levels 1-5 and upgrade the main house with diamonds. Its level raises workers, fences and purchased rooftop guns. Buy tower defenses at the Equipment Shop.", "target": "house"},
	{"event": "feed", "title": "8. Feed your companion", "text": "Buy Pet Food at Nia's Pet Shop, then feed it from the pet shop or Pack. Your pet helps you fight and heal.", "target": "pet"},
	{"event": "portal", "title": "9. Enter your first dungeon", "text": "Follow the arrows to the Monster Battle Portal. Tap the left portal and enter Chaos Citadel. The Shore Gate brings you home during a village raid.", "target": "portal"},
	{"event": "boss", "title": "10. Defeat the first boss", "text": "Defeat Shadow & Chaos Fiend in the Level 1 Chaos Citadel. Defeating him completes the tutorial; Portals 2-10 belong to the rescue story. Keep moving, use potions and follow the path to your current target.", "target": "boss"},
]


static func step(index: int) -> Dictionary:
	return STEPS[index].duplicate(true) if index >= 0 and index < STEPS.size() else {}


static func phase_steps(night: bool) -> Array:
	return NIGHT_STEPS.duplicate() if night else DAY_STEPS.duplicate()
