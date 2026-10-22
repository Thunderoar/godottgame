extends Node
## Authoritative runtime state for the whole game.
##
## GameState owns player stats, currencies, inventory, pets, the house and
## permanent portal progress. Scenes read from it and call its transactional
## methods; they never keep their own copy of health, gold or progression.

signal data_changed
signal toast_requested(text: String, tone: String)
signal pet_changed
signal house_changed(level: int)
signal portal_completed(portal_id: String)
signal player_defeated
signal expedition_changed
signal boss_health_changed(active: bool, name: String, value: int, maximum: int)
signal recovery_changed(active: bool, progress: float)
signal emergency_changed(active: bool, remaining: int, damage: int)
signal game_over_triggered(reason: String)

const SAVE_PATH := "user://tidesworn_save.json"
const SAVE_VERSION := 6
const INVENTORY_STACK_DEFAULT := 9
const DEFAULT_CHARACTER := "qayyim"
const AUTO_HEAL_RATIO := 0.10
const AUTO_HEAL_REARM_RATIO := 0.35

var data: Dictionary = {}
var has_existing_save := false
var autosave_enabled := true
var game_over_active := false

var _clock_accum := 0.0
var _last_purchase: Dictionary = {}
var _purchase_serial := 0
var _auto_heal_armed := true


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
	# The settlement is deliberately locked in permanent daytime.
	data.play_time = float(data.get("play_time", 0.0)) + delta


# --------------------------------------------------------------- creation

func _make_default(character_id: String) -> Dictionary:
	var character := CharacterDB.get_character(character_id)
	var hp_max := int(character.hp)
	var mana_max := int(character.mana)
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
		"mana_potion": 1,
		"pet_food": 1,
		"wood": 0,
	}
	return {
		"version": SAVE_VERSION,
		"character_id": str(character.id),
		"character_name": str(character.name),
		"character_title": str(character.title),
		"level": 1,
		"xp": 0,
		"xp_next": 60,
		"hp": hp_max,
		"hp_max": hp_max,
		"mana": mana_max,
		"mana_max": mana_max,
		"shield": 0,
		"gold": 120,
		"diamonds": 12,
		"inventory": inventory,
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
		"sea_cleaned": 0,
		"forest_health": {},
		"settings": {
			"gui_scale": 1.0,
			"control_layout": {},
		},
		"play_time": 0.0,
		"tutorial_seen": false,
	}


func new_game(character_id: String = DEFAULT_CHARACTER) -> void:
	data = _make_default(character_id)
	_auto_heal_armed = true
	game_over_active = false
	has_existing_save = true
	_save_now()
	_emit_all()


func continue_game() -> bool:
	if not has_existing_save:
		return false
	load_game()
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
		inventory.erase(item_id)
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
	elif effect.has("mana"):
		if mana() >= mana_max():
			return {"ok": false, "message": "Your mana is already full."}
		data.mana = mini(mana_max(), mana() + int(effect.mana))
		message = "Mana restored."
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
			total += int(ItemDB.get_item(id).get("attack", 0))
	return total


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


func mana() -> int:
	return int(data.get("mana", 0))


func mana_max() -> int:
	return int(data.get("mana_max", 50))


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
	_try_auto_heal()
	data_changed.emit()
	if health() <= 0:
		player_defeated.emit()


func _try_auto_heal() -> void:
	if not _auto_heal_armed or health() <= 0:
		return
	if float(health()) / float(maxi(1, health_max())) > AUTO_HEAL_RATIO:
		return
	if item_count("health_potion") <= 0:
		return
	var potion := ItemDB.get_item("health_potion")
	remove_item("health_potion", 1)
	data.hp = mini(health_max(), health() + int(potion.get("effect", {}).get("heal", 45)))
	_auto_heal_armed = false
	toast_requested.emit("Health critical! A potion was used automatically.", "bad")


func heal(amount: int) -> void:
	if amount <= 0:
		return
	data.hp = clampi(health() + amount, 0, health_max())
	if float(health()) / float(maxi(1, health_max())) >= AUTO_HEAL_REARM_RATIO:
		_auto_heal_armed = true
	data_changed.emit()


func set_health(value: int) -> void:
	data.hp = clampi(value, 0, health_max())
	if float(health()) / float(maxi(1, health_max())) >= AUTO_HEAL_REARM_RATIO:
		_auto_heal_armed = true
	data_changed.emit()


func spend_mana(amount: int) -> bool:
	if mana() < amount:
		return false
	data.mana = mana() - amount
	data_changed.emit()
	return true


# --------------------------------------------------------------- experience

func grant_xp(amount: int) -> void:
	if amount <= 0:
		return
	data.xp = int(data.get("xp", 0)) + amount
	var leveled := false
	while int(data.xp) >= int(data.get("xp_next", 60)):
		data.xp = int(data.xp) - int(data.get("xp_next", 60))
		data.level = int(data.get("level", 1)) + 1
		data.xp_next = int(round(float(data.get("xp_next", 60)) * 1.45))
		data.hp_max = int(data.get("hp_max", 100)) + 10
		data.mana_max = int(data.get("mana_max", 50)) + 4
		data.hp = health_max()
		data.mana = mana_max()
		leveled = true
	if leveled:
		_auto_heal_armed = true
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
	var cost := 45 + level * 35
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
	data_changed.emit()
	_save_if_needed()
	return {
		"ok": true,
		"xp": amount,
		"levels": gained,
		"level": int(pet.get("level", before)),
		"message": "%s gains %d pet XP." % [PetDB.name_of(str(pet.id)), amount],
	}


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


func set_forest_tree_health(tree_id: String, health: int, max_health: int) -> void:
	var healths: Dictionary = data.get("forest_health", {})
	healths[tree_id] = clampi(health, 0, max_health)
	data.forest_health = healths


func trigger_game_over(reason: String) -> void:
	if game_over_active:
		return
	game_over_active = true
	game_over_triggered.emit(reason)


func gui_scale() -> float:
	var settings: Dictionary = data.get("settings", {})
	return clampf(float(settings.get("gui_scale", 1.0)), 0.75, 1.3)


func set_gui_scale(value: float) -> void:
	var settings: Dictionary = data.get("settings", {})
	settings.gui_scale = clampf(value, 0.75, 1.3)
	data.settings = settings
	data_changed.emit()
	save_game()


func control_layout() -> Dictionary:
	var settings: Dictionary = data.get("settings", {})
	var layout: Dictionary = settings.get("control_layout", {})
	return layout.duplicate(true)


func set_control_layout(control_id: String, x: float, y: float, control_size: float) -> void:
	var settings: Dictionary = data.get("settings", {})
	var layout: Dictionary = settings.get("control_layout", {})
	layout[control_id] = {"x": snappedf(x, 1.0), "y": snappedf(y, 1.0), "size": snappedf(control_size, 1.0)}
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
	if level >= HouseDB.max_level():
		return {"ok": false, "message": "The cottage is already complete."}
	var cost := HouseDB.upgrade_cost(level)
	if diamonds() < cost:
		return {"ok": false, "message": "You need %d diamonds." % cost}
	data.diamonds = diamonds() - cost
	data.house_level = level + 1
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
	data.deaths = int(data.get("deaths", 0)) + 1
	lose_expedition_loot()
	data.shield = 0
	data.hp = maxi(1, int(round(float(health_max()) * 0.10)))
	data.mana = int(round(float(mana_max()) * 0.5))
	data.recovery_active = true
	revive_active_pet()
	_save_if_needed()
	player_defeated.emit()
	data_changed.emit()
	pet_changed.emit()
	recovery_changed.emit(true, recovery_progress())


func leave_portal_safely() -> Dictionary:
	var banked := bank_expedition_loot()
	_save_if_needed()
	return banked


func kills() -> int:
	return int(data.get("kills", 0))


func register_kill(xp: int) -> void:
	data.kills = int(data.get("kills", 0)) + 1
	grant_xp(xp)


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
	_auto_heal_armed = true
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

func time_string() -> String:
	return "DAYTIME"


func objective_lines() -> Array[String]:
	var out: Array[String] = []
	if emergency_active():
		out.append("Settlement under attack! Defend the residents and forest trees")
	if recovery_active():
		out.append("Recover inside the cottage ward")
	if expedition_active():
		var portal_id := expedition_portal()
		out.append("Defeat %s" % str(PortalDB.get_portal(portal_id).get("boss_name", "the boss")))
	elif not bool(portal_state("tidebound_grotto").get("cleared", false)):
		out.append("Enter the Tidebound Grotto")
	else:
		out.append("Explore the Sunken Crypt")
	if house_level() < HouseDB.max_level():
		out.append("Upgrade the cottage")
	if not bool(pet_battle_state("pet_duel_1").get("cleared", false)):
		out.append("Challenge the Pet Battle Portal")
	return out


func save_game() -> void:
	_save_now()


func _save_if_needed() -> void:
	if autosave_enabled:
		_save_now()


func _save_now() -> void:
	if data.is_empty():
		return
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
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		return false
	var loaded: Dictionary = parsed
	# Merge into a fresh default so old saves gain new fields safely.
	var loaded_id := str(loaded.get("character_id", DEFAULT_CHARACTER))
	if not CharacterDB.ids().has(loaded_id):
		loaded_id = DEFAULT_CHARACTER
	var fallback := _make_default(loaded_id)
	data = _merge(fallback, loaded)
	_sanitize()
	_auto_heal_armed = true
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
	data.gold = maxi(0, int(data.get("gold", 0)))
	data.diamonds = maxi(0, int(data.get("diamonds", 0)))
	data.hp_max = maxi(1, int(data.get("hp_max", 100)))
	data.hp = clampi(int(data.get("hp", data.hp_max)), 0, int(data.hp_max))
	data.mana_max = maxi(0, int(data.get("mana_max", 50)))
	data.mana = clampi(int(data.get("mana", data.mana_max)), 0, int(data.mana_max))
	data.shield = clampi(int(data.get("shield", 0)), 0, 60)
	data.house_level = clampi(int(data.get("house_level", 1)), 1, HouseDB.max_level())
	data.level = maxi(1, int(data.get("level", 1)))
	if not (data.get("inventory", {}) is Dictionary):
		data.inventory = {}
	if not (data.get("pets", {}) is Dictionary):
		data.pets = {}
	if not (data.get("portals", {}) is Dictionary):
		data.portals = {}
	if not (data.get("settlement_layout", {}) is Dictionary):
		data.settlement_layout = {}
	if not (data.get("pet_battles", {}) is Dictionary):
		data.pet_battles = {}
	data.sea_cleaned = maxi(0, int(data.get("sea_cleaned", 0)))
	if not (data.get("forest_health", {}) is Dictionary):
		data.forest_health = {}
	var settings: Dictionary = data.get("settings", {})
	if not (settings.get("control_layout", {}) is Dictionary):
		settings.control_layout = {}
	settings.gui_scale = clampf(float(settings.get("gui_scale", 1.0)), 0.75, 1.3)
	data.settings = settings
	if not bool((data.get("expedition", {}) as Dictionary).get("active", false)):
		_clear_expedition()
	data.emergency_active = bool(data.get("emergency_active", false))
	data.emergency_monsters = maxi(0, int(data.get("emergency_monsters", 0)))
	data.emergency_damage = clampi(int(data.get("emergency_damage", 0)), 0, 100)
	data.recovery_active = bool(data.get("recovery_active", false))
	var character_id := str(data.get("character_id", DEFAULT_CHARACTER))
	if not CharacterDB.ids().has(character_id):
		character_id = DEFAULT_CHARACTER
		data.character_id = character_id
	var character := CharacterDB.get_character(character_id)
	data.character_name = str(character.name)
	data.character_title = str(character.title)
	# Remove retired consumables from old saves.
	if data.inventory is Dictionary:
		data.inventory.erase("pet_revival")
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
	# A weapon from another discipline would break combat presentation.
	var equipped: Dictionary = data.get("equipped", {})
	var weapon_id := str(equipped.get("weapon", ""))
	var weapon_style := str(ItemDB.get_item(weapon_id).get("style", ""))
	if weapon_id == "" or (weapon_style != "" and weapon_style != CharacterDB.weapon_style(character_id)):
		var starter := str(character.get("starter_weapon", "rusty_sword"))
		data.inventory[starter] = 1
		equipped.weapon = starter
	data.equipped = equipped
