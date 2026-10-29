extends Node
## Authoritative runtime state for the whole game.
##
## GameState owns player stats, currencies, inventory, pets, the house and
## permanent portal progress. Scenes read from it and call its transactional
## methods; they never keep their own copy of health, gold or progression.

signal data_changed
signal village_project_changed
signal day_phase_changed(night: bool)

var journey_serial := 0
signal toast_requested(text: String, tone: String)
signal pet_changed
signal house_changed(level: int)
signal portal_completed(portal_id: String)
signal player_defeated
signal auto_potion_used(healed: int)
signal expedition_changed
signal boss_health_changed(active: bool, name: String, value: int, maximum: int)
signal recovery_changed(active: bool, progress: float)
signal emergency_changed(active: bool, remaining: int, damage: int)
signal game_over_triggered(reason: String)

const SAVE_PATH := "user://tidesworn_save.json"
const SAVE_VERSION := 6
const INVENTORY_STACK_DEFAULT := 9
const DEFAULT_CHARACTER := "adam"
const AUTO_HEAL_RATIO := 0.25
const COMBAT_XP_MULTIPLIER := 3
const MAX_WEAPON_UPGRADE := 5

var data: Dictionary = {}
var has_existing_save := false
var autosave_enabled := true
var game_over_active := false

var _clock_accum := 0.0
var _last_purchase: Dictionary = {}
var _purchase_serial := 0
var _project_work_frames: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	has_existing_save = FileAccess.file_exists(SAVE_PATH)
	if has_existing_save:
		load_game()
	else:
		data = _make_default(DEFAULT_CHARACTER)


func _process(delta: float) -> void:
	if data.is_empty():
		return
	data.play_time = float(data.get("play_time", 0.0)) + delta


# --------------------------------------------------------------- creation

func _make_default(character_id: String) -> Dictionary:
	var character := CharacterDB.get_character(character_id)
	var hp_max := int(character.hp)
	var pet_max := PetDB.max_health("ember", 1)
	var portal_state := {}
	for portal_id in PortalDB.ordered_ids():
		portal_state[portal_id] = {
			"unlocked": portal_id == "tidebound_grotto",
			"cleared": false,
			"attempts": 0,
		}
	var starter_weapon := str(character.get("starter_weapon", "rusty_sword"))
	var inventory := {
		starter_weapon: 1,
		"cloth_tunic": 1,
		"health_potion": 2,
		"pet_food": 1,
		"wood": 0,
	}
	return {
		"version": SAVE_VERSION,
		"village_progression": VillageProjectDB.default_progression(),
		"campaign": {"intro_seen": false, "ocean_stage": 1, "arjun_rescued": false, "mei_ling_rescued": false, "ending_seen": false},
		"character_id": str(character.id),
		"character_name": str(character.name),
		"character_title": str(character.title),
		"level": 1,
		"xp": 0,
		"xp_next": 60,
		"hp": hp_max,
		"hp_max": hp_max,
		"shield": 0,
		"gold": 120,
		"diamonds": 12,
		"inventory": inventory,
		"weapon_upgrades": {},
		"equipped": {
			"weapon": starter_weapon,
			"armor": "cloth_tunic",
			"shield": "",
		},
		"pets": {
			"ember": {
				"id": "ember",
				"level": 1,
				"xp": 0,
				"hp": pet_max,
				"hp_max": pet_max,
				"alive": true,
				"owned": true,
			},
		},
		"active_pet": "ember",
		"house_level": 1,
		"portals": portal_state,
		"expedition": {
			"active": false,
			"portal_id": "",
			"gold": 0,
			"diamonds": 0,
			"items": {},
		},
		"kills": 0,
		"bosses": 0,
		"deaths": 0,
		"recovery_active": false,
		"emergency_active": false,
		"emergency_monsters": 0,
		"emergency_damage": 0,
		"settlement_layout": {},
		"pet_battles": {},
		"village_pets": [],
		"realm_progress": {"cells": [], "landmarks": ["arrival"], "shortcut": false, "checkpoint": "arrival", "visit_active": false, "bonded": []},
		"roof_guns": {},
		"sea_cleaned": 0,
		"forest_health": {},
		"forest_growth": {},
		"water_keeper_count": 1,
		"worker_counts": {"builder": 1, "planter": 1, "fighter": 1},
		"resident_health": {},
		"structures": {},
		"mission_step": 0,
		"completed_missions": [],
		"settings": {
			"gui_scale": 1.0,
			"control_layout": {},
		},
		"play_time": 0.0,
		"world_time": 0.0,
		"home_wave": -1,
		"home_monsters": [],
		"tutorial_seen": false,
	}


func new_game(character_id: String = DEFAULT_CHARACTER) -> void:
	_wild_session.clear()
	journey_serial += 1
	_project_work_frames.clear()
	var carried_settings: Dictionary = (data.get("settings", {}) as Dictionary).duplicate(true)
	data = _make_default(character_id)
	if not carried_settings.is_empty():
		data.settings = carried_settings
	game_over_active = false
	has_existing_save = true
	_save_now()
	_emit_all()


func continue_game() -> bool:
	if not has_existing_save or not load_game():
		return false
	game_over_active = false
	return not data.is_empty()


func _emit_all() -> void:
	data_changed.emit()
	pet_changed.emit()
	house_changed.emit(int(data.get("house_level", 1)))
	expedition_changed.emit()
	recovery_changed.emit(bool(data.get("recovery_active", false)), recovery_progress())
	emergency_changed.emit(emergency_active(), int(data.get("emergency_monsters", 0)), int(data.get("emergency_damage", 0)))


# --------------------------------------------------------------- economy

func gold() -> int:
	return int(data.get("gold", 0))


func diamonds() -> int:
	return int(data.get("diamonds", 0))


func add_gold(amount: int) -> void:
	if amount == 0:
		return
	data.gold = maxi(0, gold() + amount)
	data_changed.emit()


func add_diamonds(amount: int) -> void:
	if amount == 0:
		return
	data.diamonds = maxi(0, diamonds() + amount)
	data_changed.emit()


## Atomically buys one shop item. Returns {"ok": bool, "message": String}.
func buy_item(item_id: String, quantity: int = 1) -> Dictionary:
	var item := ItemDB.get_item(item_id)
	if item.is_empty():
		return {"ok": false, "message": "Unknown item."}
	var access := item_purchase_status(item_id)
	if not bool(access.ok): return access
	quantity = maxi(1, quantity)
	var now := Time.get_ticks_msec()
	var previous: int = int(_last_purchase.get(item_id, -9999))
	if now - previous < 280:
		return {"ok": false, "message": "Just a moment..."}
	_last_purchase[item_id] = now

	if ItemDB.is_equipment(item_id) and item_count(item_id) > 0:
		return {"ok": false, "message": "You already own that."}
	if quantity > 1 and not ItemDB.is_equipment(item_id):
		# The UI buys one at a time; this guard keeps accidental bulk calls sane.
		quantity = 1

	var price := int(item.get("price", 0))
	var currency := str(item.get("currency", "gold"))
	var balance := gold() if currency == "gold" else diamonds()
	if price > 0 and balance < price:
		return {"ok": false, "message": "Not enough %s." % currency}
	if not can_add_item(item_id, quantity):
		return {"ok": false, "message": "Your pack is full of that."}

	if price > 0:
		if currency == "gold":
			data.gold = gold() - price
		else:
			data.diamonds = diamonds() - price
	# Only after the deduction is confirmed do we mutate inventory.
	add_item(item_id, quantity, false)
	if item_id == "health_potion":
		record_mission_event("buy")
	_purchase_serial += 1
	_save_if_needed()
	data_changed.emit()
	var label := str(item.get("name", item_id))
	toast_requested.emit("Purchased %s." % label, "good")
	return {"ok": true, "message": "Purchased %s." % label}


func can_add_item(item_id: String, quantity: int = 1) -> bool:
	var item := ItemDB.get_item(item_id)
	if item.is_empty():
		return false
	var stack := int(item.get("stack", INVENTORY_STACK_DEFAULT))
	var current := item_count(item_id)
	return current + quantity <= stack


func sell_item(item_id: String, quantity: int = 1) -> Dictionary:
	var item := ItemDB.get_item(item_id)
	if item.is_empty() or not bool(item.get("sellable", false)):
		return {"ok": false, "message": "That is not something a shop will buy."}
	if quantity <= 0 or item_count(item_id) < quantity:
		return {"ok": false, "message": "You do not have that many."}
	var value := int(item.get("price", 0)) * quantity
	if value <= 0:
		return {"ok": false, "message": "That has no value."}
	if not remove_item(item_id, quantity):
		return {"ok": false, "message": "Could not complete the sale."}
	data.gold = gold() + value
	_save_if_needed()
	data_changed.emit()
	toast_requested.emit("Sold %dx %s for %d gold." % [quantity, str(item.name), value], "gold")
	return {"ok": true, "message": "Sold for %d gold." % value}


func add_item(item_id: String, quantity: int = 1, notify: bool = true) -> bool:
	if quantity <= 0 or not ItemDB.exists(item_id):
		return false
	var inventory: Dictionary = data.get("inventory", {})
	if not can_add_item(item_id, quantity):
		return false
	inventory[item_id] = item_count(item_id) + quantity
	data.inventory = inventory
	if notify:
		data_changed.emit()
	return true


func remove_item(item_id: String, quantity: int = 1) -> bool:
	if quantity <= 0:
		return false
	var inventory: Dictionary = data.get("inventory", {})
	var count := int(inventory.get(item_id, 0))
	if count < quantity:
		return false
	if count == quantity:
		# A zero marker prevents default starter potions reappearing on save merge.
		if item_id == "health_potion": inventory[item_id] = 0
		else: inventory.erase(item_id)
	else:
		inventory[item_id] = count - quantity
	data.inventory = inventory
	if ItemDB.is_equipment(item_id):
		var equipped: Dictionary = data.get("equipped", {})
		for slot in equipped:
			if str(equipped[slot]) == item_id:
				equipped[slot] = ""
		data.equipped = equipped
	data_changed.emit()
	return true


func item_count(item_id: String) -> int:
	return int((data.get("inventory", {}) as Dictionary).get(item_id, 0))


func consume_item(item_id: String) -> Dictionary:
	var item := ItemDB.get_item(item_id)
	if item.is_empty():
		return {"ok": false, "message": "Unknown item."}
	if item_count(item_id) <= 0:
		return {"ok": false, "message": "You do not have one."}
	var effect: Dictionary = item.get("effect", {})
	if effect.is_empty():
		return {"ok": false, "message": "That cannot be used here."}

	var used := false
	var message := ""
	if effect.has("heal"):
		if health() >= health_max():
			return {"ok": false, "message": "You are already at full health."}
		data.hp = mini(health_max(), health() + int(effect.heal))
		message = "Health restored."
		used = true
	elif effect.has("pet_xp"):
		var pet := get_active_pet()
		if pet.is_empty():
			return {"ok": false, "message": "You have no companion."}
		_give_pet_xp(pet, int(effect.pet_xp))
		message = "%s enjoys the treat." % PetDB.name_of(str(pet.id))
		used = true

	if not used:
		return {"ok": false, "message": "That cannot be used here."}
	remove_item(item_id, 1)
	_save_if_needed()
	data_changed.emit()
	toast_requested.emit(message, "good")
	return {"ok": true, "message": message}


func equip_item(item_id: String) -> Dictionary:
	if not ItemDB.is_equipment(item_id):
		return {"ok": false, "message": "That is not equipment."}
	if item_count(item_id) <= 0:
		return {"ok": false, "message": "You do not own that."}
	var item := ItemDB.get_item(item_id)
	var slot := str(item.get("slot", ""))
	if slot == "":
		return {"ok": false, "message": "That cannot be equipped."}
	var item_style := str(item.get("style", ""))
	if item_style != "" and item_style != character_weapon_style():
		return {"ok": false, "message": "%s cannot use that weapon discipline." % str(data.get("character_name", "This hero"))}
	var equipped: Dictionary = data.get("equipped", {})
	equipped[slot] = item_id
	data.equipped = equipped
	_save_if_needed()
	data_changed.emit()
	toast_requested.emit("Equipped %s." % str(item.name), "good")
	return {"ok": true, "message": "Equipped %s." % str(item.name)}


func equipped_item(slot: String) -> String:
	return str((data.get("equipped", {}) as Dictionary).get(slot, ""))


func character_weapon_style() -> String:
	return CharacterDB.weapon_style(str(data.get("character_id", DEFAULT_CHARACTER)))


func character_data() -> Dictionary:
	return CharacterDB.get_character(str(data.get("character_id", DEFAULT_CHARACTER)))


func attack_power() -> int:
	var character := CharacterDB.get_character(str(data.get("character_id", DEFAULT_CHARACTER)))
	var total := 4 + int(data.get("level", 1)) * 2 + int(character.get("attack", 0))
	for slot in ["weapon", "armor", "shield"]:
		var id := equipped_item(slot)
		if id != "":
			total += weapon_attack(id)
	return total

func weapon_rank(item_id: String) -> int:
	return clampi(int((data.get("weapon_upgrades", {}) as Dictionary).get(item_id, 0)),0,MAX_WEAPON_UPGRADE)

func weapon_attack(item_id: String) -> int:
	var base := int(ItemDB.get_item(item_id).get("attack", 0))
	return base + roundi(base * 0.2 * weapon_rank(item_id))

func weapon_upgrade_cost(item_id: String) -> int:
	var item := ItemDB.get_item(item_id)
	return maxi(25, roundi(int(item.get("price", 0))*0.25) + int(item.get("attack",0))*3) * (weapon_rank(item_id)+1)

func upgrade_weapon(item_id: String) -> Dictionary:
	var item := ItemDB.get_item(item_id)
	if item.get("kind", "") != "weapon" or item_count(item_id) <= 0:
		return {"ok":false,"message":"Buy this weapon before upgrading it."}
	if str(item.get("style","")) != character_weapon_style():
		return {"ok":false,"message":"This weapon belongs to another discipline."}
	if weapon_rank(item_id) >= MAX_WEAPON_UPGRADE:
		return {"ok":false,"message":"Weapon is already +5."}
	var cost := weapon_upgrade_cost(item_id)
	if gold() < cost: return {"ok":false,"message":"Not enough Gold for this upgrade."}
	data.gold = gold()-cost
	var ranks: Dictionary = data.get("weapon_upgrades", {})
	ranks[item_id] = weapon_rank(item_id)+1
	data.weapon_upgrades = ranks
	_save_if_needed()
	data_changed.emit()
	return {"ok":true,"message":"%s upgraded to +%d." % [ItemDB.name_of(item_id),weapon_rank(item_id)]}

func item_stat_line(item_id: String) -> String:
	var item := ItemDB.get_item(item_id)
	if item.get("kind","") == "weapon":
		return "ATK +%d  ·  Upgrade +%d/%d" % [weapon_attack(item_id),weapon_rank(item_id),MAX_WEAPON_UPGRADE]
	return ItemDB.stat_line(item_id)


func defense() -> int:
	var character := CharacterDB.get_character(str(data.get("character_id", DEFAULT_CHARACTER)))
	var total := int(character.get("defense", 0))
	for slot in ["weapon", "armor", "shield"]:
		var id := equipped_item(slot)
		if id != "":
			total += int(ItemDB.get_item(id).get("defense", 0))
	return total


func move_speed() -> float:
	var character := CharacterDB.get_character(str(data.get("character_id", DEFAULT_CHARACTER)))
	return float(character.get("speed", 4.2))


func health() -> int:
	return int(data.get("hp", 1))


func health_max() -> int:
	return int(data.get("hp_max", 100))


func shield() -> int:
	return int(data.get("shield", 0))


func add_shield(amount: int) -> void:
	if amount <= 0:
		return
	data.shield = mini(60, shield() + amount)
	data_changed.emit()


func damage_player(amount: int) -> void:
	if amount <= 0:
		return
	var reduced := maxi(1, amount - defense())
	var absorbed := mini(shield(), reduced)
	if absorbed > 0:
		data.shield = shield() - absorbed
		reduced -= absorbed
	if reduced > 0:
		data.hp = maxi(0, health() - reduced)
	var potion_used := _try_auto_heal()
	_interrupt_village_work()
	data_changed.emit()
	if potion_used: _save_if_needed()
	if health() <= 0:
		player_defeated.emit()


func _try_auto_heal() -> bool:
	if health() <= 0:
		return false
	if float(health()) / float(maxi(1, health_max())) > AUTO_HEAL_RATIO:
		return false
	if item_count("health_potion") <= 0:
		return false
	var potion := ItemDB.get_item("health_potion")
	if not remove_item("health_potion", 1): return false
	var previous_hp := health()
	data.hp = mini(health_max(), health() + int(potion.get("effect", {}).get("heal", 45)))
	# One bottle per damage event; the next hit can trigger another if still low.
	auto_potion_used.emit(health()-previous_hp)
	return true


func heal(amount: int) -> void:
	if amount <= 0:
		return
	data.hp = clampi(health() + amount, 0, health_max())
	data_changed.emit()


func set_health(value: int) -> void:
	data.hp = clampi(value, 0, health_max())
	data_changed.emit()


# --------------------------------------------------------------- experience

func xp_for_level(level: int) -> int:
	var step := maxi(0,level-1)
	return 60+35*step+5*step*step

func grant_xp(amount: int) -> void:
	if amount <= 0:
		return
	data.xp = int(data.get("xp", 0)) + amount
	var leveled := false
	while int(data.xp) >= int(data.get("xp_next", 60)):
		data.xp = int(data.xp) - int(data.get("xp_next", 60))
		data.level = int(data.get("level", 1)) + 1
		data.xp_next = xp_for_level(int(data.level))
		data.hp_max = int(data.get("hp_max", 100)) + 10
		data.hp = health_max()
		leveled = true
	if leveled:
		toast_requested.emit("Level %d reached. Your path grows clearer." % int(data.level), "gold")
	data_changed.emit()
	_save_if_needed()


# --------------------------------------------------------------- pets

func get_active_pet() -> Dictionary:
	var pets: Dictionary = data.get("pets", {})
	var id := str(data.get("active_pet", ""))
	if id == "" or not pets.has(id):
		return {}
	return pets[id]


func get_pet(pet_id: String) -> Dictionary:
	return (data.get("pets", {}) as Dictionary).get(pet_id, {})


func active_pet_id() -> String:
	return str(data.get("active_pet", ""))


func has_living_pet() -> bool:
	var pet := get_active_pet()
	return not pet.is_empty() and bool(pet.get("alive", false))


func set_active_pet(pet_id: String) -> bool:
	var pet := get_pet(pet_id)
	if pet.is_empty() or not bool(pet.get("owned", false)):
		return false
	data.active_pet = pet_id
	pet_changed.emit()
	_save_if_needed()
	return true


func purchase_pet(pet_id: String) -> Dictionary:
	var definition := PetDB.get_pet(pet_id)
	if definition.is_empty():
		return {"ok": false, "message": "Unknown companion."}
	if definition.has("base_pet"):
		return {"ok": false, "message": "Meet this companion in the Twilight Wilds." if RealmDB.ENCOUNTERS.has(pet_id) else "This companion cannot be purchased."}
	if not get_pet(pet_id).is_empty():
		return {"ok": false, "message": "That companion already lives with you."}
	var cost := int(definition.get("cost", 0))
	if gold() < cost:
		return {"ok": false, "message": "Not enough gold."}
	var max_hp := PetDB.max_health(pet_id, 1)
	data.gold = gold() - cost
	var pets: Dictionary = data.get("pets", {})
	pets[pet_id] = {
		"id": pet_id,
		"level": 1,
		"xp": 0,
		"hp": max_hp,
		"hp_max": max_hp,
		"alive": true,
		"owned": true,
	}
	data.pets = pets
	data.active_pet = pet_id
	_save_if_needed()
	_emit_all()
	toast_requested.emit("%s joins your journey." % str(definition.name), "good")
	return {"ok": true, "message": "%s joins your journey." % str(definition.name)}


func upgrade_pet(pet_id: String) -> Dictionary:
	var pet := get_pet(pet_id)
	if pet.is_empty():
		return {"ok": false, "message": "You do not own that companion."}
	var level := int(pet.get("level", 1))
	if level >= PetDB.MAX_LEVEL:
		return {"ok": false, "message": "That companion is already at max level."}
	var cost := pet_upgrade_cost(level)
	if gold() < cost:
		return {"ok": false, "message": "Not enough gold."}
	data.gold = gold() - cost
	pet.level = level + 1
	pet.hp_max = PetDB.max_health(pet_id, int(pet.level))
	pet.hp = int(pet.hp_max)
	pet.xp = 0
	pet_changed.emit()
	_save_if_needed()
	data_changed.emit()
	toast_requested.emit("%s reached level %d. Its support grows stronger." % [PetDB.name_of(pet_id), int(pet.level)], "gold")
	return {"ok": true, "message": "Companion upgraded."}


func _give_pet_xp(pet: Dictionary, amount: int) -> int:
	var levels_gained := 0
	pet.xp = int(pet.get("xp", 0)) + amount
	var level := int(pet.get("level", 1))
	while level < PetDB.MAX_LEVEL and int(pet.xp) >= PetDB.xp_for_level(level + 1):
		pet.xp = int(pet.xp) - PetDB.xp_for_level(level + 1)
		level += 1
		levels_gained += 1
		pet.level = level
		pet.hp_max = PetDB.max_health(str(pet.id), level)
		pet.hp = int(pet.hp_max)
	pet_changed.emit()
	return levels_gained


func pet_upgrade_cost(level: int) -> int:
	# Single source of truth for the companion upgrade price (was duplicated in
	# ShopPanel; formula unchanged: 45 + level * 35 gold).
	return 45 + clampi(level, 1, PetDB.MAX_LEVEL) * 35


func pet_xp_progress_for(pet_id: String) -> Dictionary:
	# Same shape as pet_xp_progress() but for any owned companion, not just the
	# active one (the shop shows XP bars for every owned pen).
	var pet := get_pet(pet_id)
	if pet.is_empty():
		return {"xp": 0, "next": 1, "level": 1, "max": false}
	var level := int(pet.get("level", 1))
	var maxed := level >= PetDB.MAX_LEVEL
	return {
		"xp": int(pet.get("xp", 0)),
		"next": PetDB.xp_for_level(level + 1) if not maxed else 1,
		"level": level,
		"max": maxed,
	}


func pet_xp_progress() -> Dictionary:
	var pet := get_active_pet()
	if pet.is_empty():
		return {"xp": 0, "next": 1, "level": 1, "max": false}
	var level := int(pet.get("level", 1))
	var maxed := level >= PetDB.MAX_LEVEL
	return {
		"xp": int(pet.get("xp", 0)),
		"next": 0 if maxed else PetDB.xp_for_level(level + 1),
		"level": level,
		"max": maxed,
	}


func feed_active_pet() -> Dictionary:
	return feed_pet(active_pet_id())


func feed_pet(pet_id: String) -> Dictionary:
	var pet := get_pet(pet_id)
	if pet.is_empty():
		return {"ok": false, "message": "You do not own that companion."}
	if int(pet.get("level", 1)) >= PetDB.MAX_LEVEL:
		return {"ok": false, "message": "That companion is already at max level."}
	if item_count("pet_food") <= 0:
		return {"ok": false, "message": "Buy pet food at Nia's Pet Shop first."}
	var effect: Dictionary = ItemDB.get_item("pet_food").get("effect", {})
	var amount := int(effect.get("pet_xp", 25))
	if not remove_item("pet_food", 1):
		return {"ok": false, "message": "Pet food could not be used."}
	var before := int(pet.get("level", 1))
	var gained := _give_pet_xp(pet, amount)
	record_mission_event("feed")
	data_changed.emit()
	_save_if_needed()
	return {
		"ok": true,
		"xp": amount,
		"levels": gained,
		"level": int(pet.get("level", before)),
		"message": "%s gains %d pet XP." % [PetDB.name_of(str(pet.id)), amount],
	}


var _wild_session: Dictionary = {}
var _wild_serial := 0

func realm_progress() -> Dictionary:
	return (data.get("realm_progress", {}) as Dictionary).duplicate(true)

func _sanitize_realm_progress() -> void:
	_wild_session.clear()
	var raw: Variant = data.get("realm_progress", {})
	var progress: Dictionary = raw if raw is Dictionary else {}
	var clean := {"cells": [], "landmarks": ["arrival"], "shortcut": bool(progress.get("shortcut", false)), "checkpoint": "camp" if str(progress.get("checkpoint", "arrival")) == "camp" else "arrival", "visit_active": bool(progress.get("visit_active", false)), "bonded": []}
	for key in ["cells", "landmarks", "bonded"]:
		var values: Variant = progress.get(key, [])
		if not values is Array: continue
		for value in values:
			var id := str(value)
			var valid := false
			if key == "cells":
				for x in 6:
					for y in 6:
						if id == "%d:%d" % [x,y]: valid = true
			elif key == "landmarks": valid = RealmDB.LANDMARKS.has(id)
			else: valid = RealmDB.ENCOUNTERS.has(id)
			if valid and id not in clean[key]: clean[key].append(id)
	data.realm_progress = clean
	var expedition: Variant = data.get("expedition", {})
	if expedition is Dictionary and bool(expedition.get("active", false)) and str(expedition.get("portal_id", "")) == RealmDB.PORTAL:
		data.realm_progress.visit_active = true # Old in-flight Portal 1 saves migrate into exploration.

func discover_realm_at(at: Vector2) -> void:
	var changed := false
	var center := Vector2i(floori(at.x / RealmDB.CELL_SIZE.x), floori(at.y / RealmDB.CELL_SIZE.y))
	for x in range(maxi(0,center.x-1), mini(6,center.x+2)):
		for y in range(maxi(0,center.y-1), mini(6,center.y+2)):
			var id := "%d:%d" % [x,y]
			if id not in data.realm_progress.cells:
				data.realm_progress.cells.append(id)
				changed = true
	if changed: _save_if_needed()

func discover_realm_landmark(id: String) -> void:
	if not RealmDB.LANDMARKS.has(id) or id in data.realm_progress.landmarks: return
	data.realm_progress.landmarks.append(id)
	_save_if_needed()

func open_realm_shortcut() -> void:
	if bool(data.realm_progress.shortcut): return
	data.realm_progress.shortcut = true
	_save_if_needed()
	data_changed.emit()

func set_realm_checkpoint(id: String) -> void:
	if id not in ["arrival", "camp"]: return
	data.realm_progress.checkpoint = id
	_save_if_needed()

func finish_realm_rest() -> void:
	data.hp = health_max()
	revive_active_pet()
	_save_if_needed()
	data_changed.emit()
	pet_changed.emit()

func end_realm_visit() -> void:
	_wild_session.clear()
	data.realm_progress.visit_active = false
	_save_if_needed()

func realm_pet_bonded(id: String) -> bool:
	return id in (data.get("realm_progress", {}) as Dictionary).get("bonded", []) or not get_pet(id).is_empty()

func wild_encounter_reason(id: String) -> Dictionary:
	if not RealmDB.ENCOUNTERS.has(id): return {"ok": false, "reason": "Unknown habitat."}
	if not bool(data.realm_progress.visit_active) or health() <= 0: return {"ok": false, "reason": "Visit the Twilight Wilds first."}
	if not has_living_pet(): return {"ok": false, "reason": "Your companion needs rest. Return home or visit the citadel lantern."}
	return {"ok": true, "reason": ""}

func begin_wild_encounter(id: String) -> int:
	if not bool(wild_encounter_reason(id).ok) or not _wild_session.is_empty(): return 0
	_wild_serial += 1
	_wild_session = {"token": _wild_serial, "id": id, "pet": active_pet_id(), "journey": journey_serial}
	return _wild_serial

func cancel_wild_encounter(token: int) -> void:
	if int(_wild_session.get("token", 0)) == token: _wild_session.clear()

func complete_wild_encounter(token: int) -> Dictionary:
	if _wild_session.is_empty() or int(_wild_session.token) != token or int(_wild_session.journey) != journey_serial or not bool(data.realm_progress.visit_active):
		return {"ok": false, "message": "This challenge has ended."}
	var id := str(_wild_session.id)
	var participant := get_pet(str(_wild_session.pet))
	_wild_session.clear() # Consume before signals/rebuilds can call back.
	if participant.is_empty(): return {"ok": false, "message": "Your companion is unavailable."}
	var first := not realm_pet_bonded(id)
	var def: Dictionary = RealmDB.ENCOUNTERS[id]
	var gold_reward := int(def.gold) if first else 0
	var xp_reward := int(def.xp) if first else 0
	if first:
		data.gold = gold() + gold_reward
		_give_pet_xp(participant, xp_reward)
		_recruit_duel_pet(str(def.duel), false)
	if id not in data.realm_progress.bonded: data.realm_progress.bonded.append(id)
	_save_if_needed()
	data_changed.emit()
	pet_changed.emit()
	return {"ok": true, "first": first, "gold": gold_reward, "xp": xp_reward, "message": "%s bonds with you. +%d Gold · +%d companion XP" % [str(def.name),gold_reward,xp_reward] if first else "A friendly spar. Your bond is already safe; no repeat rewards."}

func pet_battle_state(level_id: String) -> Dictionary:
	var cleared_map: Dictionary = data.get("pet_battles", {})
	var ids := PetBattleDB.ordered_ids()
	var index := ids.find(level_id)
	var cleared := bool(cleared_map.get(level_id, false))
	var unlocked := index == 0
	if index > 0:
		unlocked = bool(cleared_map.get(ids[index - 1], false))
	return {"unlocked": unlocked, "cleared": cleared, "index": index}


func pet_battle_clear_reason(level_id: String) -> Dictionary:
	var state := pet_battle_state(level_id)
	if not bool(state.get("unlocked", false)):
		return {"ok": false, "reason": "Clear the previous pet duel first."}
	var def := PetBattleDB.get_level(level_id)
	if def.is_empty():
		return {"ok": false, "reason": "Unknown pet duel."}
	var pet := get_active_pet()
	if pet.is_empty() or not bool(pet.get("alive", false)):
		return {"ok": false, "reason": "Your companion is resting."}
	var required := int(def.get("pet_level", 1))
	if int(pet.get("level", 1)) < required:
		return {"ok": false, "reason": "Requires companion level %d." % required}
	return {"ok": true, "reason": ""}


func complete_pet_battle(level_id: String) -> Dictionary:
	var def := PetBattleDB.get_level(level_id)
	if def.is_empty():
		return {"ok": false, "message": "Unknown pet duel."}
	var cleared_map: Dictionary = data.get("pet_battles", {})
	var first := not bool(cleared_map.get(level_id, false))
	var gold_reward := int(def.get("gold", 0)) if first else 0
	var xp_reward := int(def.get("xp", 0)) if first else maxi(1, int(float(def.get("xp", 0)) * 0.25))
	if gold_reward > 0:
		add_gold(gold_reward)
	var pet := get_active_pet()
	var levels := 0
	if not pet.is_empty():
		levels = _give_pet_xp(pet, xp_reward)
		# A duel victory always gives at least one companion level.
		if levels == 0 and int(pet.get("level", 1)) < PetDB.MAX_LEVEL:
			var next_level := int(pet.get("level", 1)) + 1
			pet.level = next_level
			pet.hp_max = PetDB.max_health(str(pet.id), next_level)
			pet.hp = int(pet.hp_max)
			pet.xp = 0
			levels = 1
			pet_changed.emit()
	var recruited := _recruit_duel_pet(level_id)
	cleared_map[level_id] = true
	data.pet_battles = cleared_map
	data_changed.emit()
	_save_if_needed()
	return {
		"ok": true,
		"first": first,
		"gold": gold_reward,
		"xp": xp_reward,
		"pet_levels": levels,
		"recruited_pet": recruited,
		"pet_level": int(pet.get("level", 1)),
		"message": "Pet duel won.",
	}


func register_rubbish_cleaned(amount: int = 1) -> void:
	if amount <= 0:
		return
	data.sea_cleaned = int(data.get("sea_cleaned", 0)) + amount
	add_gold(amount)
	data_changed.emit()
	_save_if_needed()


# --------------------------------------------------------------- forest / settings

func forest_tree_health(tree_id: String, max_health: int) -> int:
	var healths: Dictionary = data.get("forest_health", {})
	return clampi(int(healths.get(tree_id, max_health)), 0, max_health)


const MAX_WATER_KEEPERS := 5


func tutorial_complete() -> bool:
	# Clearing Portal 1 ends training, even if its fight crosses a day/night boundary.
	return bool(portal_state("tidebound_grotto").get("cleared", false)) or completed_mission_count() >= MissionDB.STEPS.size()


func mission_step() -> int:
	if tutorial_complete():
		return MissionDB.STEPS.size()
	var completed: Array = data.get("completed_missions", [])
	for index in MissionDB.phase_steps(is_night()):
		if str(MissionDB.step(int(index)).get("event", "")) not in completed:
			return int(index)
	return MissionDB.STEPS.size()

func completed_mission_count() -> int:
	return (data.get("completed_missions", []) as Array).size()

func record_mission_event(event: String) -> void:
	var lesson := MissionDB.step(mission_step())
	# Only real first-portal entry/clear callers send these events. Their result
	# must survive a clock phase change during the battle.
	var portal_event := event == "portal" or (event == "boss" and bool(portal_state("tidebound_grotto").get("cleared", false)))
	if not portal_event and (lesson.is_empty() or str(lesson.get("event", "")) != event):
		return
	var completed: Array = data.get("completed_missions", [])
	if event not in completed:
		completed.append(event)
	data.completed_missions = completed
	data.mission_step = mission_step()
	data_changed.emit()
	_save_if_needed()

func resident_health(id: String) -> int:
	return clampi(int((data.get("resident_health", {}) as Dictionary).get(id, 100)), 0, 100)


func damage_resident(id: String, amount: int) -> void:
	var healths: Dictionary = data.get("resident_health", {})
	healths[id] = maxi(0, resident_health(id) - maxi(0, amount))
	data.resident_health = healths
	_interrupt_village_work(id)
	data_changed.emit()
	if int(healths[id]) == 0:
		_save_if_needed()


func water_keeper_count() -> int:
	return clampi(maxi(house_level(), int(data.get("water_keeper_count", 1))), 1, MAX_WATER_KEEPERS)


func water_hire_slot() -> int:
	for i in water_keeper_count():
		if resident_health("Water Keeper %d" % (i + 1)) <= 0:
			return i
	return water_keeper_count() if water_keeper_count() < MAX_WATER_KEEPERS else -1


func water_hire_cost() -> int:
	return 80 + maxi(0, water_hire_slot() - 1) * 60


func hire_water_keeper() -> Dictionary:
	return hire_worker("water")

func register_structure(id: String, label: String, kind: String, maximum: int, initial_health: int = -1) -> void:
	if id.is_empty():
		return
	var structures: Dictionary = data.get("structures", {})
	var entry: Dictionary = structures.get(id, {})
	entry["health"] = clampi(int(entry.get("health", maximum if initial_health < 0 else initial_health)), 0, maximum)
	entry["maximum"] = maximum
	entry["name"] = label
	entry["kind"] = kind
	entry["repair_remaining"] = clampf(float(entry.get("repair_remaining", 0.0)), 0.0, 10.0)
	entry["level"] = house_level()
	structures[id] = entry
	data.structures = structures


func structure_state(id: String) -> Dictionary:
	return (data.get("structures", {}) as Dictionary).get(id, {}).duplicate(true)


func damage_structure(id: String, amount: int) -> void:
	var entry := structure_state(id)
	if entry.is_empty() or game_over_active:
		return
	entry["health"] = maxi(0, int(entry.get("health", 0)) - maxi(1, amount))
	data.structures[id] = entry
	data_changed.emit()
	if int(entry.health) == 0:
		_save_if_needed()


func repair_structure(id: String) -> Dictionary:
	if structure_project_locked(id):
		return {"ok": false, "message": "Commission the West Workshop with Bram first."}
	var entry := structure_state(id)
	if entry.is_empty() or game_over_active:
		return {"ok": false, "message": "This structure cannot be repaired."}
	if int(entry.get("health", 0)) >= int(entry.get("maximum", 1)):
		return {"ok": false, "message": "This structure is already intact."}
	entry["health"] = int(entry.get("maximum", 100))
	entry["repair_remaining"] = 0.0
	entry["level"] = clampi(int(entry.get("level", 1)), 1, 5)
	data.structures[id] = entry
	data_changed.emit()
	_save_if_needed()
	return {"ok": true, "message": "Structure repaired."}

func set_forest_tree_health(tree_id: String, health: int, max_health: int) -> void:
	var healths: Dictionary = data.get("forest_health", {})
	healths[tree_id] = clampi(health, 0, max_health)
	data.forest_health = healths


func forest_tree_growth(tree_id: String) -> float:
	return clampf(float((data.get("forest_growth", {}) as Dictionary).get(tree_id, 0.0)), 0.0, 30.0)


func set_forest_tree_growth(tree_id: String, remaining: float) -> void:
	if tree_id.is_empty():
		return
	var growth: Dictionary = data.get("forest_growth", {})
	if remaining <= 0.0:
		growth.erase(tree_id)
	else:
		growth[tree_id] = clampf(remaining, 0.0, 30.0)
	data.forest_growth = growth


func trigger_game_over(reason: String) -> void:
	if game_over_active:
		return
	game_over_active = true
	game_over_triggered.emit(reason)


func gui_scale() -> float:
	# Compatibility API: device settings survive new journeys and save deletion.
	return float(GameSettings.ui_scale()) / 100.0


func set_gui_scale(value: float, persist: bool = true) -> void:
	GameSettings.set_ui_scale(roundi(value * 100.0), persist)


func control_layout() -> Dictionary:
	var settings: Dictionary = data.get("settings", {})
	var layout: Dictionary = settings.get("control_layout", {})
	return layout.duplicate(true)


func set_control_layout(control_id: String, x: float, y: float, control_size: float) -> void:
	var settings: Dictionary = data.get("settings", {})
	var layout: Dictionary = settings.get("control_layout", {})
	layout[control_id] = {"x": clampf(snappedf(x, 1.0), 0, 8192), "y": clampf(snappedf(y, 1.0), 0, 8192), "size": clampf(snappedf(control_size, 1.0), 42, 260)}
	settings.control_layout = layout
	data.settings = settings
	data_changed.emit()
	save_game()


func reset_control_layout() -> void:
	var settings: Dictionary = data.get("settings", {})
	settings.control_layout = {}
	data.settings = settings
	data_changed.emit()
	save_game()


func pet_ability_summary() -> String:
	var pet := get_active_pet()
	if pet.is_empty():
		return "No companion"
	var id := str(pet.id)
	var level := int(pet.get("level", 1))
	return "Heal %d / Atk %d / Shield %d" % [
		PetDB.heal_amount(id, level),
		PetDB.attack_damage(id, level),
		PetDB.shield_amount(id, level),
	]


func revive_active_pet() -> void:
	var pet := get_active_pet()
	if pet.is_empty():
		return
	pet.alive = true
	pet.hp = int(pet.get("hp_max", 50))
	pet_changed.emit()
	_save_if_needed()


func damage_pet(amount: int) -> void:
	var pet := get_active_pet()
	if pet.is_empty() or not bool(pet.get("alive", false)):
		return
	pet.hp = maxi(0, int(pet.get("hp", 1)) - amount)
	if int(pet.hp) <= 0:
		pet.alive = false
		pet.hp = 0
		toast_requested.emit("%s is down, but will recover." % PetDB.name_of(str(pet.id)), "bad")
	pet_changed.emit()
	data_changed.emit()


# --------------------------------------------------------------- house

func house_level() -> int:
	return int(data.get("house_level", 1))


func upgrade_house() -> Dictionary:
	var level := house_level()
	if game_over_active or int(structure_state("cottage").get("health", 1)) <= 0:
		return {"ok": false, "message": "Repair the main house first."}
	if level >= HouseDB.max_level():
		return {"ok": false, "message": "The cottage is already complete."}
	var cost := HouseDB.upgrade_cost(level)
	if diamonds() < cost:
		return {"ok": false, "message": "You need %d diamonds." % cost}
	data.diamonds = diamonds() - cost
	data.house_level = level + 1
	for id in data.get("structures", {}):
		data.structures[id]["level"] = level + 1
	data.water_keeper_count = water_keeper_count()
	for worker_role in ["builder", "planter", "fighter"]:
		data.worker_counts[worker_role] = worker_count(worker_role)
	_save_if_needed()
	data_changed.emit()
	house_changed.emit(house_level())
	toast_requested.emit("The cottage is now %s." % str(HouseDB.get_level(house_level()).name), "gold")
	return {"ok": true, "message": "Cottage upgraded."}


func sleep_recovery_seconds() -> float:
	return HouseDB.recovery_time(house_level())


# --------------------------------------------------------------- portals

func portal_state(portal_id: String) -> Dictionary:
	return (data.get("portals", {}) as Dictionary).get(portal_id, {})


func portal_clear_reason(portal_id: String) -> Dictionary:
	var def := PortalDB.get_portal(portal_id)
	if def.is_empty():
		return {"ok": false, "reason": "Unknown portal."}
	var state := portal_state(portal_id)
	if state.is_empty() or not bool(state.get("unlocked", false)):
		return {"ok": false, "reason": "Sealed until the previous guardian falls."}
	var level_req := int(def.get("level_required", 1))
	if int(data.get("level", 1)) < level_req:
		return {"ok": false, "reason": "Requires level %d." % level_req}
	if emergency_active():
		return {"ok": false, "reason": "Defend the settlement before entering another portal."}
	if recovery_active():
		return {"ok": false, "reason": "Recover fully inside the cottage ward first."}
	return {"ok": true, "reason": ""}


func can_enter_portal(portal_id: String) -> bool:
	return bool(portal_clear_reason(portal_id).ok)


func start_expedition(portal_id: String) -> bool:
	if not can_enter_portal(portal_id):
		return false
	data.realm_progress.visit_active = portal_id == RealmDB.PORTAL
	var state := portal_state(portal_id)
	state.attempts = int(state.get("attempts", 0)) + 1
	data.portals[portal_id] = state
	data.expedition = {
		"active": true,
		"portal_id": portal_id,
		"gold": 0,
		"diamonds": 0,
		"items": {},
	}
	_save_if_needed()
	expedition_changed.emit()
	data_changed.emit()
	return true


func expedition_active() -> bool:
	return bool((data.get("expedition", {}) as Dictionary).get("active", false))


func expedition_portal() -> String:
	return str((data.get("expedition", {}) as Dictionary).get("portal_id", ""))


func expedition_loot() -> Dictionary:
	return (data.get("expedition", {}) as Dictionary).duplicate(true)


func add_expedition_loot(kind: String, amount: int, item_id: String = "") -> void:
	if not expedition_active() or amount <= 0:
		return
	var exp: Dictionary = data.get("expedition", {})
	if kind == "gold":
		exp.gold = int(exp.get("gold", 0)) + amount
	elif kind == "diamonds":
		exp.diamonds = int(exp.get("diamonds", 0)) + amount
	elif kind == "item" and item_id != "":
		var items: Dictionary = exp.get("items", {})
		items[item_id] = int(items.get(item_id, 0)) + amount
		exp.items = items
	data.expedition = exp
	expedition_changed.emit()
	data_changed.emit()


func expedition_loot_summary() -> String:
	var exp := expedition_loot()
	var bits: Array[String] = []
	if int(exp.get("gold", 0)) > 0:
		bits.append("%d gold" % int(exp.gold))
	if int(exp.get("diamonds", 0)) > 0:
		bits.append("%d diamonds" % int(exp.diamonds))
	for id in exp.get("items", {}):
		bits.append("%dx %s" % [int(exp.items[id]), ItemDB.name_of(str(id))])
	if bits.is_empty():
		return "No unbanked loot"
	return "Unbanked: " + ", ".join(bits)


func bank_expedition_loot() -> Dictionary:
	if not expedition_active():
		return {"gold": 0, "diamonds": 0, "items": {}}
	var exp := expedition_loot()
	var gained_gold := int(exp.get("gold", 0))
	var gained_diamonds := int(exp.get("diamonds", 0))
	var items: Dictionary = exp.get("items", {})
	data.gold = gold() + gained_gold
	data.diamonds = diamonds() + gained_diamonds
	for id in items:
		add_item(str(id), int(items[id]), false)
	_clear_expedition()
	_save_if_needed()
	data_changed.emit()
	expedition_changed.emit()
	if gained_gold + gained_diamonds > 0:
		toast_requested.emit("Loot banked: %d gold, %d diamonds." % [gained_gold, gained_diamonds], "good")
	return {"gold": gained_gold, "diamonds": gained_diamonds, "items": items}


func lose_expedition_loot() -> void:
	_clear_expedition()
	_save_if_needed()
	data_changed.emit()
	expedition_changed.emit()


func _clear_expedition() -> void:
	data.expedition = {
		"active": false,
		"portal_id": "",
		"gold": 0,
		"diamonds": 0,
		"items": {},
	}


func complete_portal(portal_id: String) -> Dictionary:
	var def := PortalDB.get_portal(portal_id)
	if def.is_empty():
		return {}
	var state := portal_state(portal_id)
	var first := not bool(state.get("cleared", false))
	var rewards: Dictionary = def.get("rewards_first", {}) if first else def.get("rewards_repeat", {})
	var summary := {
		"first": first,
		"gold": int(rewards.get("gold", 0)),
		"diamonds": int(rewards.get("diamonds", 0)),
		"xp": int(rewards.get("xp", 0)),
		"pet": "",
	}
	bank_expedition_loot()
	data.gold = gold() + summary.gold
	data.diamonds = diamonds() + summary.diamonds
	state.cleared = true
	data.portals[portal_id] = state
	data.bosses = int(data.get("bosses", 0)) + 1
	if portal_id == PortalDB.ordered_ids()[0]:
		record_mission_event("boss")
	if first:
		var unlock_id := str(def.get("unlocks", ""))
		if unlock_id != "":
			var unlock_state := portal_state(unlock_id)
			unlock_state.unlocked = true
			data.portals[unlock_id] = unlock_state
		var pet_reward := str(rewards.get("pet", ""))
		if pet_reward != "" and get_pet(pet_reward).is_empty():
			var definition := PetDB.get_pet(pet_reward)
			if not definition.is_empty():
				var pet_max := PetDB.max_health(pet_reward, 1)
				var pets: Dictionary = data.get("pets", {})
				pets[pet_reward] = {
					"id": pet_reward,
					"level": 1,
					"xp": 0,
					"hp": pet_max,
					"hp_max": pet_max,
					"alive": true,
					"owned": true,
				}
				data.pets = pets
				summary.pet = pet_reward
	grant_xp(int(summary.xp))
	_save_if_needed()
	data_changed.emit()
	portal_completed.emit(portal_id)
	expedition_changed.emit()
	return summary


func defeat_in_portal() -> void:
	data.realm_progress.visit_active = false
	data.deaths = int(data.get("deaths", 0)) + 1
	lose_expedition_loot()
	data.shield = 0
	data.hp = maxi(1, int(round(float(health_max()) * 0.10)))
	data.recovery_active = true
	revive_active_pet()
	_save_if_needed()
	player_defeated.emit()
	data_changed.emit()
	pet_changed.emit()
	recovery_changed.emit(true, recovery_progress())


func leave_portal_safely() -> Dictionary:
	data.realm_progress.visit_active = false
	var banked := bank_expedition_loot()
	_save_if_needed()
	return banked


func defeat_at_home() -> void:
	# Home has no expedition loot to lose. Reuse the existing recovery rules
	# without the portal's second player_defeated notification.
	data.deaths = int(data.get("deaths", 0)) + 1
	data.shield = 0
	data.hp = maxi(1, int(round(float(health_max()) * 0.10)))
	data.recovery_active = true
	revive_active_pet()
	_save_if_needed()
	data_changed.emit()
	pet_changed.emit()
	recovery_changed.emit(true, recovery_progress())


func kills() -> int:
	return int(data.get("kills", 0))


func register_kill(xp: int) -> void:
	data.kills = int(data.get("kills", 0)) + 1
	grant_xp(xp * COMBAT_XP_MULTIPLIER)


# --------------------------------------------------------------- recovery / emergency

func recovery_active() -> bool:
	return bool(data.get("recovery_active", false))


func recovery_progress() -> float:
	return clampf(float(health()) / float(maxi(1, health_max())), 0.0, 1.0)


func finish_recovery() -> void:
	if not recovery_active():
		return
	data.recovery_active = false
	data.hp = health_max()
	_save_if_needed()
	data_changed.emit()
	recovery_changed.emit(false, 1.0)
	toast_requested.emit("Recovery complete. The ward releases you.", "good")


func placeable_position(placeable_id: String, fallback: Vector2) -> Vector2:
	var layout: Dictionary = data.get("settlement_layout", {})
	if not layout.has(placeable_id):
		return fallback
	var stored: Variant = layout[placeable_id]
	if stored is Array and (stored as Array).size() >= 2:
		return Vector2(float(stored[0]), float(stored[1]))
	return fallback


func set_placeable_position(placeable_id: String, pos: Vector2) -> void:
	var layout: Dictionary = data.get("settlement_layout", {})
	layout[placeable_id] = [pos.x, pos.y]
	data.settlement_layout = layout
	_save_if_needed()
	data_changed.emit()


func emergency_active() -> bool:
	return bool(data.get("emergency_active", false))


func emergency_monsters() -> int:
	return int(data.get("emergency_monsters", 0))


func emergency_damage() -> int:
	return int(data.get("emergency_damage", 0))


func start_emergency(monster_count: int = 3) -> void:
	if emergency_active():
		return
	data.emergency_active = true
	data.emergency_monsters = maxi(1, monster_count)
	data.emergency_damage = 0
	_save_if_needed()
	data_changed.emit()
	emergency_changed.emit(true, emergency_monsters(), emergency_damage())
	toast_requested.emit("EMERGENCY! Monsters are attacking the settlement! The coastal guard needs your help! Return home and protect the residents!", "bad")


func damage_settlement(amount: int) -> void:
	if not emergency_active() or amount <= 0:
		return
	data.emergency_damage = clampi(emergency_damage() + amount, 0, 100)
	data_changed.emit()
	emergency_changed.emit(true, emergency_monsters(), emergency_damage())


func register_emergency_kill() -> void:
	if not emergency_active():
		return
	data.emergency_monsters = maxi(0, emergency_monsters() - 1)
	if emergency_monsters() <= 0:
		data.emergency_active = false
		data.emergency_monsters = 0
		_save_if_needed()
		data_changed.emit()
		emergency_changed.emit(false, 0, emergency_damage())
		toast_requested.emit("The settlement is safe. Emergency complete!", "good")
	else:
		_save_if_needed()
		data_changed.emit()
		emergency_changed.emit(true, emergency_monsters(), emergency_damage())


# --------------------------------------------------------------- time / save

const DAY_PHASE_SECONDS := 180.0


func is_night() -> bool:
	return fmod(float(data.get("world_time", 0.0)), DAY_PHASE_SECONDS * 2.0) >= DAY_PHASE_SECONDS


func night_number() -> int:
	return int(float(data.get("world_time", 0.0)) / (DAY_PHASE_SECONDS * 2.0))


func advance_world_clock(delta: float) -> void:
	if data.is_empty() or game_over_active or delta <= 0.0:
		return
	var before := float(data.get("world_time", 0.0))
	var after := before + delta
	data.world_time = after
	if int(before / DAY_PHASE_SECONDS) != int(after / DAY_PHASE_SECONDS):
		day_phase_changed.emit(is_night())


func mark_home_wave() -> void:
	data.home_wave = night_number()


func store_home_monsters(monsters: Array) -> void:
	data.home_monsters = monsters.duplicate(true)


func time_string() -> String:
	var remaining := ceili(DAY_PHASE_SECONDS - fmod(float(data.get("world_time", 0.0)), DAY_PHASE_SECONDS))
	return "%s %d:%02d" % ["NIGHT" if is_night() else "DAY", remaining / 60, remaining % 60]


func objective_lines() -> Array[String]:
	var lesson := MissionDB.step(mission_step())
	if not lesson.is_empty():
		return [str(lesson.get("title", "Learn to play"))]
	var out: Array[String] = []
	if emergency_active():
		out.append("Settlement under attack! Defend the residents and forest trees")
	if recovery_active():
		out.append("Recover inside the cottage ward")
	if expedition_active():
		var portal_id := expedition_portal()
		out.append("Defeat %s" % str(PortalDB.get_portal(portal_id).get("boss_name", "the boss")))
	elif not bool(portal_state("tidebound_grotto").get("cleared", false)):
		out.append("Explore Twilight Wilds through the Dimension Portal")
	else:
		out.append("Explore the onward passages beyond Chaos Citadel")
	if house_level() < HouseDB.max_level():
		out.append("Upgrade the cottage")
	if not bool(pet_battle_state("pet_duel_1").get("cleared", false)):
		out.append("Discover the wild companions of Twilight Wilds")
	return out.slice(0, 1)


func save_game() -> void:
	if game_over_active:
		return
	_save_now()


func _save_if_needed() -> void:
	if autosave_enabled:
		_save_now()


func _save_now() -> void:
	if data.is_empty():
		return
	# Capture living home enemies before any transaction saves, including kills.
	for game in get_tree().get_nodes_in_group("game"):
		if is_instance_valid(game) and is_instance_valid(game.world) and game.world is Lobby and game.world.is_node_ready() and game.world.journey_serial == journey_serial:
			store_home_monsters(game.world.capture_monsters())
			break
	data.version = SAVE_VERSION
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not save game: %s" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	has_existing_save = true


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		return false
	var parsed: Variant = json.data
	if not parsed is Dictionary:
		return false
	var loaded: Dictionary = parsed
	# Inspect raw schema before defaults merge, preserving future saves unchanged.
	var raw_progression: Variant = loaded.get("village_progression", {})
	if raw_progression is Dictionary and (raw_progression.get("schema", 1) is int or raw_progression.get("schema", 1) is float) and int(raw_progression.get("schema", 1)) > 1:
		return false
	for site in get_tree().get_nodes_in_group("village_project_sites"):
		if is_instance_valid(site): site.release_worker(false)
	# Merge into a fresh default so old saves gain new fields safely.
	var loaded_id := str(loaded.get("character_id", DEFAULT_CHARACTER))
	if not CharacterDB.ids().has(loaded_id):
		loaded_id = DEFAULT_CHARACTER
	var fallback := _make_default(loaded_id)
	data = _merge(fallback, loaded)
	if not loaded.has("village_progression"):
		data.village_progression = VillageProjectDB.default_progression(true)
	_project_work_frames.clear()
	if not loaded.has("completed_missions"):
		var completed: Array = []
		for index in mini(int(loaded.get("mission_step", 0)), MissionDB.STEPS.size()):
			completed.append(str(MissionDB.step(index).get("event", "")))
		data.completed_missions = completed
	_sanitize()
	game_over_active = false
	has_existing_save = true
	_emit_all()
	return true


func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	has_existing_save = false


func _merge(base: Dictionary, incoming: Dictionary) -> Dictionary:
	var out := base.duplicate(true)
	for key in incoming:
		var value: Variant = incoming[key]
		if value is Dictionary and out.get(key) is Dictionary:
			out[key] = _merge(out[key], value)
		else:
			out[key] = value
	return out


func _sanitize() -> void:
	_sanitize_realm_progress()
	_sanitize_campaign()
	_sanitize_village_progression()
	# Mana was retired; legacy saves keep all remaining progression.
	data.erase("mana")
	data.erase("mana_max")
	var completed: Array = []
	var raw: Variant = data.get("completed_missions", [])
	if raw is Array:
		for event in raw:
			if str(event) in MissionDB.STEPS.map(func(step: Dictionary) -> String: return str(step.get("event", ""))) and str(event) not in completed:
				completed.append(str(event))
	data.completed_missions = completed
	data.world_time = maxf(0.0, float(data.get("world_time", 0.0)))
	data.home_wave = clampi(int(data.get("home_wave", -1)), -1, night_number())
	var monsters: Array = []
	if data.get("home_monsters", []) is Array:
		for record in data.get("home_monsters", []):
			if not record is Dictionary or str(record.get("kind", "")) not in ["fire", "urchin"]:
				continue
			monsters.append({"kind": str(record.kind), "x": clampf(float(record.get("x", 32)), 0, 64), "y": clampf(float(record.get("y", 24)), 0, 40), "hp": clampi(int(record.get("hp", 30)), 1, 60), "raid": bool(record.get("raid", false))})
	data.home_monsters = monsters.slice(0, 64)
	data.gold = maxi(0, int(data.get("gold", 0)))
	data.diamonds = maxi(0, int(data.get("diamonds", 0)))
	data.hp_max = maxi(1, int(data.get("hp_max", 100)))
	data.hp = clampi(int(data.get("hp", data.hp_max)), 0, int(data.hp_max))
	data.shield = clampi(int(data.get("shield", 0)), 0, 60)
	data.house_level = clampi(int(data.get("house_level", 1)), 1, HouseDB.max_level())
	data.level = maxi(1, int(data.get("level", 1)))
	data.xp_next = xp_for_level(int(data.level))
	data.xp = maxi(0,int(data.get("xp",0)))
	# Preserve earned XP while migrating older exponential thresholds.
	while int(data.xp) >= int(data.xp_next):
		data.xp = int(data.xp)-int(data.xp_next)
		data.level = int(data.level)+1
		data.xp_next = xp_for_level(int(data.level))
		data.hp_max = int(data.hp_max)+10
		data.hp = int(data.hp_max)
	if not (data.get("inventory", {}) is Dictionary):
		data.inventory = {}
	var upgrades: Dictionary = {}
	if data.get("weapon_upgrades", {}) is Dictionary:
		for id in data.get("weapon_upgrades", {}):
			if ItemDB.get_item(str(id)).get("kind","") == "weapon" and item_count(str(id)) > 0:
				upgrades[str(id)] = clampi(int(data.weapon_upgrades[id]),0,MAX_WEAPON_UPGRADE)
	data.weapon_upgrades = upgrades
	if not (data.get("pets", {}) is Dictionary):
		data.pets = {}
	if not (data.get("portals", {}) is Dictionary):
		data.portals = {}
	if not (data.get("settlement_layout", {}) is Dictionary):
		data.settlement_layout = {}
	if not (data.get("pet_battles", {}) is Dictionary):
		data.pet_battles = {}
	var guardians: Array[String] = []
	if data.get("village_pets", []) is Array:
		for id in data.get("village_pets", []):
			if PetDB.PETS.has(str(id)) and str(id) not in guardians:
				guardians.append(str(id))
	data.village_pets = guardians
	if not data.get("roof_guns", {}) is Dictionary:
		data.roof_guns = {}
	for id in data.roof_guns.keys():
		data.roof_guns[id] = bool(data.roof_guns[id])
	data.sea_cleaned = maxi(0, int(data.get("sea_cleaned", 0)))
	if not (data.get("forest_health", {}) is Dictionary):
		data.forest_health = {}
	if not (data.get("forest_growth", {}) is Dictionary):
		data.forest_growth = {}
	if not data.get("worker_counts", {}) is Dictionary:
		data.worker_counts = {}
	for worker_role in ["builder", "planter", "fighter"]:
		data.worker_counts[worker_role] = clampi(int(data.worker_counts.get(worker_role, 1)), 1, 8)
	data.water_keeper_count = clampi(int(data.get("water_keeper_count", 1)), 1, MAX_WATER_KEEPERS)
	data.mission_step = clampi(int(data.get("mission_step", 0)), 0, MissionDB.STEPS.size())
	if not (data.get("resident_health", {}) is Dictionary):
		data.resident_health = {}
	for id in data.resident_health.keys():
		data.resident_health[id] = clampi(int(data.resident_health[id]), 0, 100)
	if not (data.get("structures", {}) is Dictionary):
		data.structures = {}
	for id in data.structures.keys():
		if not (data.structures[id] is Dictionary):
			data.structures.erase(id)
			continue
		var entry: Dictionary = data.structures[id]
		entry["maximum"] = clampi(int(entry.get("maximum", 200)), 1, 1000)
		entry["health"] = clampi(int(entry.get("health", 200)), 0, int(entry.maximum))
		entry["repair_remaining"] = clampf(float(entry.get("repair_remaining", 0.0)), 0.0, 10.0)
		entry["level"] = clampi(int(entry.get("level", 1)), 1, 5)
	for id in data.forest_growth.keys():
		data.forest_growth[id] = clampf(float(data.forest_growth[id]), 0.0, 30.0)
	var settings: Dictionary = data.get("settings", {})
	if not (settings.get("control_layout", {}) is Dictionary):
		settings.control_layout = {}
	for retired_control in ["skill_1", "skill_2", "skill_3", "mana_potion"]:
		settings.control_layout.erase(retired_control)
	settings.gui_scale = clampf(float(settings.get("gui_scale", 1.0)), 0.75, 1.3)
	data.settings = settings
	if not bool((data.get("expedition", {}) as Dictionary).get("active", false)):
		_clear_expedition()
	data.emergency_active = bool(data.get("emergency_active", false))
	data.emergency_monsters = maxi(0, int(data.get("emergency_monsters", 0)))
	data.emergency_damage = clampi(int(data.get("emergency_damage", 0)), 0, 100)
	data.recovery_active = bool(data.get("recovery_active", false))
	var character_id := CharacterDB.canonical_id(str(data.get("character_id", DEFAULT_CHARACTER)))
	data.character_id = character_id
	if not CharacterDB.ids().has(character_id):
		character_id = DEFAULT_CHARACTER
		data.character_id = character_id
	var character := CharacterDB.get_character(character_id)
	data.character_name = str(character.name)
	data.character_title = str(character.title)
	# Remove retired consumables from old saves.
	if data.inventory is Dictionary:
		data.inventory.erase("pet_revival")
		data.inventory.erase("mana_potion")
	# Keep starter ownership intact if a malformed save omitted it.
	if not data.pets.has("ember"):
		var pet_max := PetDB.max_health("ember", 1)
		data.pets["ember"] = {
			"id": "ember", "level": 1, "xp": 0, "hp": pet_max,
			"hp_max": pet_max, "alive": true, "owned": true,
		}
	if str(data.get("active_pet", "")) == "":
		data.active_pet = "ember"
	# Pets never remain permanently down after loading.
	for pet_id in data.pets:
		var pet: Dictionary = data.pets[pet_id]
		pet.alive = true
		pet.hp = int(pet.get("hp_max", PetDB.max_health(str(pet_id), int(pet.get("level", 1)))))
	# Existing cleared duels earn their rivals when an older save is loaded.
	for duel_id in PetBattleDB.ordered_ids():
		if bool(data.pet_battles.get(duel_id, false)):
			_recruit_duel_pet(duel_id, false)
	# A weapon from another discipline would break combat presentation.
	var equipped: Dictionary = data.get("equipped", {})
	var weapon_id := str(equipped.get("weapon", ""))
	var weapon_style := str(ItemDB.get_item(weapon_id).get("style", ""))
	if weapon_id == "" or (weapon_style != "" and weapon_style != CharacterDB.weapon_style(character_id)):
		var starter := str(character.get("starter_weapon", "rusty_sword"))
		data.inventory[starter] = 1
		equipped.weapon = starter
	data.equipped = equipped


const WORKER_LABELS := {"water": "Water Keeper", "builder": "Builder", "planter": "Planter", "fighter": "Swordsman"}
const BUILD_REPAIR_SECONDS := 10.0

func worker_count(worker_role: String) -> int:
	return water_keeper_count() if worker_role == "water" else clampi(maxi(house_level(), int(data.get("worker_counts", {}).get(worker_role, 1))), 1, 8)

func worker_name(worker_role: String, index: int) -> String:
	return "%s %d" % [str(WORKER_LABELS.get(worker_role, "Worker")), index + 1]

func worker_hire_slot(worker_role: String) -> int:
	if not WORKER_LABELS.has(worker_role):
		return -1
	for i in worker_count(worker_role):
		if resident_health(worker_name(worker_role, i)) <= 0:
			return i
	var limit := MAX_WATER_KEEPERS if worker_role == "water" else 8
	return worker_count(worker_role) if worker_count(worker_role) < limit else -1

func worker_hire_cost(worker_role: String) -> int:
	return 80 + maxi(0, worker_hire_slot(worker_role) - 1) * 60

func hire_worker(worker_role: String) -> Dictionary:
	var slot := worker_hire_slot(worker_role)
	if slot < 0 or game_over_active:
		return {"ok": false, "message": "No worker slots available."}
	var cost := worker_hire_cost(worker_role)
	if gold() < cost:
		return {"ok": false, "message": "Not enough Gold."}
	data.gold = gold() - cost
	if worker_role == "water":
		data.water_keeper_count = maxi(water_keeper_count(), slot + 1)
	else:
		var counts: Dictionary = data.get("worker_counts", {})
		counts[worker_role] = maxi(worker_count(worker_role), slot + 1)
		data.worker_counts = counts
	var healths: Dictionary = data.get("resident_health", {})
	healths[worker_name(worker_role, slot)] = 100
	data.resident_health = healths
	data_changed.emit()
	_save_if_needed()
	return {"ok": true, "message": "%s hired." % str(WORKER_LABELS.get(worker_role, "Worker"))}

func structure_level(_id: String) -> int:
	return house_level()

func upgrade_structure(id: String) -> Dictionary:
	var entry := structure_state(id)
	if entry.is_empty() or str(entry.get("kind", "")) != "house" or game_over_active:
		return {"ok": false, "message": "Choose the main house."}
	return upgrade_house()

func start_structure_work(id: String) -> bool:
	if structure_project_locked(id): return false
	var entry := structure_state(id)
	if entry.is_empty() or game_over_active or is_night() or int(entry.get("health", 0)) >= int(entry.get("maximum", 1)):
		return false
	if float(entry.get("repair_remaining", 0.0)) <= 0.0:
		entry["repair_remaining"] = BUILD_REPAIR_SECONDS
		data.structures[id] = entry
		data_changed.emit()
	return true

func work_structure(id: String, delta: float) -> bool:
	if structure_project_locked(id): return false
	if game_over_active or is_night():
		return false
	var entry := structure_state(id)
	var remaining := float(entry.get("repair_remaining", 0.0))
	if remaining <= 0.0:
		return false
	entry["repair_remaining"] = maxf(0, remaining - maxf(0, delta))
	data.structures[id] = entry
	if float(entry.repair_remaining) <= 0.0:
		return bool(repair_structure(id).get("ok", false))
	return false


func _recruit_duel_pet(level_id: String, notify: bool = true) -> String:
	var def := PetBattleDB.get_level(level_id)
	var id := str(def.get("opponent_pet", ""))
	if id.is_empty() or not PetDB.PETS.has(id):
		return ""
	if not data.pets.has(id):
		var level := clampi(int(def.get("pet_level", 1)), 1, PetDB.MAX_LEVEL)
		var maximum := PetDB.max_health(id, level)
		data.pets[id] = {"id": id, "level": level, "xp": 0, "hp": maximum, "hp_max": maximum, "alive": true, "owned": true}
	var guardians: Array = data.get("village_pets", [])
	if id not in guardians:
		guardians.append(id)
	data.village_pets = guardians
	if notify:
		pet_changed.emit()
	return id


const ROOF_GUN_BASE_COST := 180
const ROOF_GUN_LEVEL_COST := 60

func roof_gun_cost() -> int:
	return ROOF_GUN_BASE_COST + (house_level() - 1) * ROOF_GUN_LEVEL_COST


func has_roof_gun(structure_id: String) -> bool:
	return bool(data.get("roof_guns", {}).get(structure_id, false))


func buy_roof_gun(structure_id: String) -> Dictionary:
	if structure_project_locked(structure_id):
		return {"ok": false, "message": "Finish the West Workshop before installing a defense."}
	var structure := structure_state(structure_id)
	if str(structure.get("kind", "")) != "house" or int(structure.get("health", 0)) <= 0:
		return {"ok": false, "message": "Choose an intact house first."}
	if has_roof_gun(structure_id):
		return {"ok": false, "message": "This house already has a rooftop machine gun."}
	var cost := roof_gun_cost()
	if gold() < cost:
		return {"ok": false, "message": "Requires %d gold." % cost}
	data.gold = gold() - cost
	data.roof_guns[structure_id] = true
	data_changed.emit()
	_save_if_needed()
	return {"ok": true, "message": "Rooftop machine gun installed."}


# --------------------------------------------------------------- BESUT campaign
# --------------------------------------------------------------- village projects

func _sanitize_village_progression() -> void:
	var raw: Variant = data.get("village_progression", {})
	if not raw is Dictionary: raw = {}
	var clean := VillageProjectDB.default_progression()
	clean.legacy_access = raw.get("legacy_access", false) is bool and raw.get("legacy_access", false) == true
	var projects: Variant = raw.get("projects", {})
	if not projects is Dictionary: projects = {}
	for id in VillageProjectDB.ordered_ids():
		var entry: Variant = projects.get(id, {})
		if not entry is Dictionary: continue
		var state := str(entry.get("state", "not_started"))
		if state not in ["not_started", "working", "complete"]: state = "not_started"
		var remaining := float(entry.get("remaining", VillageProjectDB.WORK_SECONDS)) if entry.get("remaining", 0) is float or entry.get("remaining", 0) is int else VillageProjectDB.WORK_SECONDS
		if not is_finite(remaining) or remaining < 0: remaining = VillageProjectDB.WORK_SECONDS
		if state != "not_started" and not bool(portal_state("tidebound_grotto").get("cleared", false)): state = "not_started"
		clean.projects[id] = {"state": state, "remaining": 0.0 if state == "complete" else (VillageProjectDB.WORK_SECONDS if state == "not_started" else clampf(remaining, 0, VillageProjectDB.WORK_SECONDS))}
	var tracked := str(raw.get("tracked_project", ""))
	if tracked in VillageProjectDB.ordered_ids() and str(clean.projects[tracked].state) != "complete": clean.tracked_project = tracked
	data.village_progression = clean

func village_legacy_access() -> bool:
	var value: Variant = (data.get("village_progression", {}) as Dictionary).get("legacy_access", false)
	return value is bool and value == true

func project_status(id: String = VillageProjectDB.WORKSHOP) -> Dictionary:
	var definition := VillageProjectDB.get_project(id)
	if definition.is_empty(): return {"ok": false, "state": "unknown", "message": "Unknown village project."}
	var progress: Dictionary = (data.get("village_progression", {}) as Dictionary).get("projects", {})
	var entry: Dictionary = progress.get(id, {"state": "not_started", "remaining": VillageProjectDB.WORK_SECONDS})
	var state := str(entry.get("state", "not_started"))
	var eligible := bool(portal_state(str(definition.portal)).get("cleared", false))
	var reason := "Defeat %s in %s to make the workshop possible." % [PortalDB.get_portal(str(definition.portal)).boss_name, PortalDB.get_portal(str(definition.portal)).name]
	if eligible: reason = "Ready to commission with Bram. Free village restoration."
	if state == "working": reason = "Work pauses at night or near danger. Approach the workbench to help."
	if state == "complete": reason = "Workshop restored. Garrick's advanced sword stock is permanently licensed."
	definition.merge({"ok": eligible and state == "not_started" and not game_over_active, "eligible": eligible, "state": state, "remaining": float(entry.get("remaining", VillageProjectDB.WORK_SECONDS)), "message": reason, "legacy": village_legacy_access()}, true)
	return definition

func structure_project_locked(id: String) -> bool:
	return id == VillageProjectDB.WORKSHOP_STRUCTURE and not village_legacy_access() and str(project_status().state) != "complete"

func item_purchase_status(item_id: String) -> Dictionary:
	if not ItemDB.exists(item_id): return {"ok": false, "message": "Unknown item."}
	if item_id in VillageProjectDB.ADVANCED_SWORDS and item_count(item_id) <= 0 and not village_legacy_access() and str(project_status().state) != "complete":
		return {"ok": false, "message": "Restore the West Workshop with Bram to license this sword."}
	return {"ok": true, "message": ""}

func _village_project_site(id: String) -> Node:
	for site in get_tree().get_nodes_in_group("village_project_sites"):
		if is_instance_valid(site) and not site.is_queued_for_deletion() and str(site.project_id) == id and site.active_context(): return site
	return null

func start_village_project(id: String) -> Dictionary:
	var status := project_status(id)
	if not bool(status.get("ok", false)): return {"ok": false, "message": status.message}
	var site := _village_project_site(id)
	if site == null: return {"ok": false, "message": "Visit BESUT after your journey to commission this work."}
	var blocked: String = site.commission_blocker()
	if not blocked.is_empty(): return {"ok": false, "message": blocked}
	var cost := maxi(0, int(status.get("gold", 0)))
	if gold() < cost: return {"ok": false, "message": "Not enough Gold for this commission."}
	data.gold = gold() - cost
	data.village_progression.projects[id] = {"state": "working", "remaining": float(status.seconds)}
	data.village_progression.tracked_project = id
	_project_work_frames.erase(id)
	_save_if_needed()
	data_changed.emit()
	village_project_changed.emit()
	return {"ok": true, "message": "West Workshop commissioned. Builders work by day; you can help at the site."}

func work_village_project(id: String, delta: float, actor: Node) -> bool:
	if delta <= 0 or not is_finite(delta) or game_over_active: return false
	var site := _village_project_site(id)
	if site == null or not site.accepts_work(actor) or not bool(project_status(id).eligible) or str(project_status(id).state) != "working": return false
	var frame := Engine.get_physics_frames()
	if int(_project_work_frames.get(id, -1)) == frame: return false
	_project_work_frames[id] = frame
	var entry: Dictionary = data.village_progression.projects[id]
	entry.remaining = maxf(0, float(entry.remaining) - minf(delta, minf(0.1, site.get_physics_process_delta_time())))
	data.village_progression.projects[id] = entry
	return true

func complete_village_project(id: String) -> bool:
	var status := project_status(id)
	if not bool(status.get("eligible", false)) or str(status.get("state", "")) != "working" or float(status.get("remaining", 1)) > 0: return false
	var site := _village_project_site(id)
	if site == null or not site.activation_clear(): return false
	var structure := structure_state(str(status.structure))
	if structure.is_empty(): return false
	structure.health = int(structure.maximum)
	structure.repair_remaining = 0.0
	data.structures[str(status.structure)] = structure
	data.village_progression.projects[id] = {"state": "complete", "remaining": 0.0}
	data.village_progression.tracked_project = ""
	_save_if_needed()
	data_changed.emit()
	village_project_changed.emit()
	return true

func checkpoint_village_project() -> void:
	_save_if_needed()
	village_project_changed.emit()

func _interrupt_village_work(resident_id: String = "") -> void:
	for site in get_tree().get_nodes_in_group("village_project_sites"):
		if not is_instance_valid(site): continue
		var actor: Node = site.current_worker()
		if not is_instance_valid(actor): continue
		if (actor is Player and resident_id.is_empty()) or (actor is Resident and actor.resident_name == resident_id): site.release_worker()

func track_village_project(id: String) -> void:
	if id != "" and (not id in VillageProjectDB.ordered_ids() or str(project_status(id).state) == "complete"): return
	data.village_progression.tracked_project = id
	_save_if_needed()
	data_changed.emit()

func tracked_village_project() -> String:
	return str((data.get("village_progression", {}) as Dictionary).get("tracked_project", ""))

func village_npc_lines(speaker: String) -> Array:
	if speaker != "Rami": return []
	var status := project_status()
	if str(status.state) == "complete": return ["A sound roof and room to work. This workshop belongs to all of BESUT. Garrick can now offer you our advanced swords."]
	if str(status.state) == "working": return ["The western workshop is underway. Meet the builders there by day, or lend a hand yourself. We will keep the work safe until morning."]
	return VillageProjectDB.npc_lines(speaker) + [status.message]

const OCEAN_STAGES := 3

func campaign() -> Dictionary:
	return (data.get("campaign", {}) as Dictionary).duplicate(true)

func _sanitize_campaign() -> void:
	var raw: Variant = data.get("campaign", {})
	var clean: Dictionary = raw if raw is Dictionary else {}
	data.campaign = {"intro_seen": bool(clean.get("intro_seen", false)), "ocean_stage": clampi(int(clean.get("ocean_stage", 1)), 1, OCEAN_STAGES), "arjun_rescued": bool(clean.get("arjun_rescued", false)), "mei_ling_rescued": bool(clean.get("mei_ling_rescued", false)), "ending_seen": bool(clean.get("ending_seen", false))}
	if not bool(data.campaign.arjun_rescued) or not bool(data.campaign.mei_ling_rescued):
		data.campaign.ending_seen = false

func mark_story_seen(which: String) -> void:
	if which not in ["intro_seen", "ending_seen"]:
		return
	if which == "ending_seen" and not friends_reunited():
		return
	data.campaign[which] = true
	data_changed.emit()
	_save_if_needed()

func advance_ocean_stage(stage: int) -> bool:
	if stage != int(campaign().get("ocean_stage", 1)) or stage >= OCEAN_STAGES:
		return false
	data.campaign.ocean_stage = stage + 1
	data_changed.emit()
	_save_if_needed()
	return true

func rescue_friend(id: String) -> bool:
	if id not in ["arjun", "mei_ling"]:
		return false
	var key := id + "_rescued"
	if bool(campaign().get(key, false)):
		return false
	data.campaign[key] = true
	data_changed.emit()
	_save_if_needed()
	return true

func friends_reunited() -> bool:
	var story := campaign()
	return bool(story.get("arjun_rescued", false)) and bool(story.get("mei_ling_rescued", false))

func campaign_objective() -> String:
	var story := campaign()
	if friends_reunited():
		return "Three friends reunited. BESUT is your new home."
	var goals: Array[String] = []
	if not bool(story.get("arjun_rescued", false)):
		goals.append("Rescue Arjun: ship > sea route %d/3 > Kraken Island" % int(story.get("ocean_stage", 1)))
	if not bool(story.get("mei_ling_rescued", false)):
		goals.append("Rescue Mei Ling: defeat the final portal boss")
	return "\n".join(goals)
