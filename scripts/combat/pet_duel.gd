class_name PetDuel
extends RefCounted
## Presentation-free manual duel. Waiting never causes a player action.

var player_hp := 1
var player_max := 1
var rival_hp := 1
var rival_max := 1
var player_damage := 1
var rival_damage := 1
var player_guard := false
var rival_guard := false
var player_cooldowns := {"attack": 0.0, "defend": 0.0, "burst": 0.0}
var rival_cooldowns := {"attack": 0.0, "defend": 0.0, "burst": 0.0}
var turn := "player"
var wait := 0.0
var result := ""
var status := "Choose a power. The wild pet replies after you act."
var rival_id := ""

func setup(pet: Dictionary, id: String) -> void:
	rival_id = id
	var def: Dictionary = RealmDB.ENCOUNTERS[id]
	player_max = PetDB.max_health(str(pet.id), int(pet.level))
	player_hp = player_max
	rival_max = int(def.hp)
	rival_hp = rival_max
	player_damage = PetDB.attack_damage(str(pet.id), int(pet.level)) + 3
	rival_damage = int(def.damage)

func choose(skill_id: String) -> bool:
	if turn != "player" or not result.is_empty() or not PetBattlePanel.SKILLS.has(skill_id) or float(player_cooldowns.get(skill_id, 0)) > 0: return false
	var skill: Dictionary = PetBattlePanel.SKILLS[skill_id]
	player_cooldowns[skill_id] = float(skill.cooldown)
	if skill_id == "defend": player_guard = true
	else:
		var damage := roundi(player_damage * float(skill.power))
		if rival_guard:
			damage = ceili(damage * 0.35)
			rival_guard = false
		rival_hp = maxi(0, rival_hp - damage)
	status = str(skill.name).trim_prefix("1. ").trim_prefix("2. ").trim_prefix("3. ") + ". The wild pet replies…"
	if rival_hp == 0:
		result = "win"
		turn = "finished"
	else:
		turn = "rival"
		wait = 0.7
	return true

func tick(delta: float) -> void:
	if not result.is_empty(): return
	for key in player_cooldowns:
		player_cooldowns[key] = maxf(0, float(player_cooldowns[key]) - delta)
		rival_cooldowns[key] = maxf(0, float(rival_cooldowns[key]) - delta)
	if turn == "player": return
	wait -= delta
	if wait > 0: return
	if turn == "next":
		turn = "player"
		status = "Your turn. Choose a power when ready."
		return
	var choices := ["burst", "attack", "defend"]
	if rival_id == "dusk_moth" and not rival_guard: choices = ["defend", "burst", "attack"]
	var chosen := ""
	for key in choices:
		if float(rival_cooldowns[key]) <= 0:
			chosen = key
			break
	if chosen.is_empty():
		wait = 0.1
		return
	var skill: Dictionary = PetBattlePanel.SKILLS[chosen]
	rival_cooldowns[chosen] = float(skill.cooldown)
	if chosen == "defend": rival_guard = true
	else:
		var damage := roundi(rival_damage * float(skill.power))
		if player_guard:
			damage = ceili(damage * 0.35)
			player_guard = false
		player_hp = maxi(0, player_hp - damage)
	status = "Wild pet: " + str(skill.name).substr(3)
	if player_hp == 0:
		result = "loss"
		turn = "finished"
	else:
		turn = "next"
		wait = 0.6
