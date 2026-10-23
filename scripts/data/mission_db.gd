class_name MissionDB
extends RefCounted
## One action at a time. Events are accepted only for the current lesson.

const STEPS := [
	{"event": "move", "title": "1. Learn to move", "text": "Use WASD or the left joystick. Walk along the dotted arrows to the yard marker.", "target": "yard"},
	{"event": "gather", "title": "2. Gather wood", "text": "Follow the arrows to driftwood. Stand beside it and press E or Use. Wood can be sold at the equipment shop.", "target": "wood"},
	{"event": "buy", "title": "3. Buy a potion", "text": "Visit Mara's Potion Shop. Click or touch the shop to open it, then press Buy on a health potion.", "target": "potion"},
	{"event": "inventory", "title": "4. Open your backpack", "text": "Tap Pack or press I to inspect your items, equip weapons and use supplies.", "target": ""},
	{"event": "fire_kill", "title": "5. Protect a tree", "text": "Day and night each last 3 minutes. New monsters arrive only at night; survivors remain dangerous by day. Follow the arrows to a fire monster and press F or Strike. Fire monsters attack mature trees, never people. Drops are collected automatically.", "target": "fire"},
	{"event": "services", "title": "6. Meet the water keepers", "text": "Visit the Water Keeper Shop. Two keepers help from the start. Hire more with Gold; they heal burning trees and plant protected 30-second saplings.", "target": "services"},
	{"event": "house", "title": "7. Learn village repairs", "text": "Visit Bram's Construction Shop. Houses shelter residents from sea urchins. To repair, approach a damaged house or fence and press E / Use (Betulkan). Repairs are free and immediate. Tap any house level to preview its design. Cottage upgrades use diamonds.", "target": "house"},
	{"event": "feed", "title": "8. Feed your companion", "text": "Buy Pet Food at Nia's Pet Shop, then feed it from the pet shop or Pack. Your pet helps you fight and heal.", "target": "pet"},
	{"event": "portal", "title": "9. Enter your first dungeon", "text": "Follow the arrows to the Monster Battle Portal. Use it and enter Tidebound Grotto. The Shore Gate brings you home during a village raid.", "target": "portal"},
	{"event": "boss", "title": "10. Defeat the first boss", "text": "Defeat the dungeon monsters and boss. Keep moving, use potions and follow the path to your current target.", "target": "boss"},
]


static func step(index: int) -> Dictionary:
	return STEPS[index].duplicate(true) if index >= 0 and index < STEPS.size() else {}
