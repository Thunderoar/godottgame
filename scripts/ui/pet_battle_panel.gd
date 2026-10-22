class_name PetBattlePanel
extends ModalBase
## Five-level 1v1 companion tournament with simultaneous turns.
## Both pets choose Attack or Defend during a two-second window; when it
## expires, both actions resolve together. A victory always grants a pet level.

const SKILLS := {
	"attack": {"name": "Attack", "description": "Deal full attack damage this turn."},
	"defend": {"name": "Defend", "description": "Raise a shield and reduce incoming damage by 65% this turn."},
}

var selected := ""

var _battle_level := ""
var _battle_active := false
var _battle_resolved := false
var _result_visible := false

var _player_pet_id := ""
var _player_level := 1
var _player_hp := 1
var _player_max := 1
var _opponent_hp := 1
var _opponent_max := 1
var _player_damage := 5
var _enemy_damage := 3
var _turn_timer := 0.0
var _turn_number := 1
var _turn_active := false
var _awaiting_next := false
var _next_turn_timer := 0.0
var _player_choice := ""
var _enemy_choice := ""
var _rng := RandomNumberGenerator.new()

var _player_bar: SegmentedBar
var _enemy_bar: SegmentedBar
var _player_sprite: TextureRect
var _enemy_sprite: TextureRect
var _player_hp_label: Label
var _enemy_hp_label: Label
var _status: Label
var _timer_bar: ProgressBar
var _timer_label: Label
var _skill_buttons: Array[Button] = []
var _last_result: Dictionary = {}


func _ready() -> void:
	_panel_size = Vector2(920, 640)
	super._ready()
	GameState.data_changed.connect(func() -> void:
		if visible and not _battle_active and not _result_visible:
			_rebuild())


func open_pet_battles() -> void:
	_battle_active = false
	_battle_resolved = false
	_result_visible = false
	_last_result = {}
	selected = ""
	open_panel("Pet Battle Portal")


func _rebuild() -> void:
	_clear_content()
	var pet := GameState.get_active_pet()
	if pet.is_empty():
		add_body_text("No companion is ready. Visit Nia's Pet Shop first.", GameUI.RED, 17)
		return
	var pet_id := str(pet.get("id", "ember"))
	var pet_level := int(pet.get("level", 1))
	var xp := GameState.pet_xp_progress()
	add_body_text("Active companion: %s  •  Lv %d  •  HP %d/%d" % [PetDB.name_of(pet_id), pet_level, int(pet.get("hp", 0)), int(pet.get("hp_max", 0))], GameUI.TEXT, 17)
	var xp_text := "PET XP MAX" if bool(xp.get("max", false)) else "Pet XP %d/%d" % [int(xp.get("xp", 0)), int(xp.get("next", 1))]
	add_body_text("%s  •  Gold %d" % [xp_text, GameState.gold()], GameUI.PURPLE, 14)
	add_body_text("Choose a duel. Both pets pick Attack or Defend during a two-second window; actions then resolve at the same time.", GameUI.MUTED, 13)
	content.add_child(GameUI.spacer(2))
	for level_id in PetBattleDB.ordered_ids():
		_add_level_card(level_id)


func _add_level_card(level_id: String) -> void:
	var def := PetBattleDB.get_level(level_id)
	var state := GameState.pet_battle_state(level_id)
	var reason := GameState.pet_battle_clear_reason(level_id)
	var cleared := bool(state.get("cleared", false))
	var unlocked := bool(state.get("unlocked", false))
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", GameUI.style(Color("#152a31") if unlocked else Color("#141d20"), Color("#3e5c62") if unlocked else Color("#2a353a"), 2, 0))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	card.add_child(hbox)
	var preview := TextureRect.new()
	preview.texture = PixelArt.pet_texture(str(def.get("opponent_pet", "ember")))
	var tint: Color = def.get("opponent_tint", Color.WHITE)
	preview.modulate = tint
	preview.custom_minimum_size = Vector2(74, 74)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hbox.add_child(preview)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	hbox.add_child(info)
	var title_line := "%s  •  %s%s" % [str(def.get("name", level_id)), str(def.get("subtitle", "")), "  •  CLEARED" if cleared else ""]
	info.add_child(GameUI.label(title_line, 19, GameUI.GOLD if cleared else GameUI.TEXT))
	info.add_child(GameUI.label("Opponent: %s   •   Companion Lv %d+" % [str(def.get("opponent_name", "Rival")), int(def.get("pet_level", 1))], 13, GameUI.MUTED))
	var lore := GameUI.label(str(def.get("lore", "")), 13, GameUI.MUTED)
	lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore.custom_minimum_size = Vector2(500, 0)
	info.add_child(lore)
	info.add_child(GameUI.label("Reward: %d gold  •  %d pet XP  •  +1 level on victory" % [int(def.get("gold", 0)), int(def.get("xp", 0))], 13, GameUI.TEAL))
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(150, 0)
	right.add_theme_constant_override("separation", 5)
	hbox.add_child(right)
	if bool(reason.ok):
		var fight := GameUI.button("Fight", Vector2(132, 42))
		fight.pressed.connect(func() -> void: start_battle(level_id))
		right.add_child(fight)
	else:
		right.add_child(GameUI.chip("LOCKED", GameUI.RED))
		var why := GameUI.label(str(reason.reason), 12, GameUI.MUTED)
		why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		why.custom_minimum_size = Vector2(150, 0)
		right.add_child(why)
	content.add_child(card)


func start_battle(level_id: String) -> bool:
	var reason := GameState.pet_battle_clear_reason(level_id)
	if not bool(reason.ok):
		return false
	var pet := GameState.get_active_pet()
	var def := PetBattleDB.get_level(level_id)
	if pet.is_empty() or def.is_empty():
		return false
	selected = level_id
	_battle_level = level_id
	_battle_active = true
	_battle_resolved = false
	_result_visible = false
	_last_result = {}
	_player_pet_id = str(pet.get("id", "ember"))
	_player_level = int(pet.get("level", 1))
	_player_max = PetDB.max_health(_player_pet_id, _player_level)
	_player_hp = _player_max
	_opponent_max = int(def.get("hp", 45))
	_opponent_hp = _opponent_max
	_player_damage = PetDB.attack_damage(_player_pet_id, _player_level) + 3
	_enemy_damage = int(def.get("damage", 5))
	_turn_number = 1
	_rng.seed = 4471 + level_id.hash()
	_render_battle()
	_begin_turn()
	return true


func _process(delta: float) -> void:
	if not visible or not _battle_active or _battle_resolved:
		return
	_arena_idle(delta)
	if _awaiting_next:
		_next_turn_timer -= delta
		if _next_turn_timer <= 0.0:
			_awaiting_next = false
			_begin_turn()
		return
	if not _turn_active:
		return
	_turn_timer = maxf(0.0, _turn_timer - delta)
	_update_timer_ui()
	if _turn_timer <= 0.0:
		_resolve_turn()


var _arena_frame_timer := 0.0
var _arena_frame := 0


func _arena_idle(delta: float) -> void:
	# Both duelists idle-bob on their cushions while waiting.
	_arena_frame_timer += delta
	if _arena_frame_timer >= 0.32:
		_arena_frame_timer = 0.0
		_arena_frame = 1 - _arena_frame
		if _player_sprite != null and is_instance_valid(_player_sprite):
			_player_sprite.texture = PixelArt.pet_texture(_player_pet_id, _arena_frame)
		if _enemy_sprite != null and is_instance_valid(_enemy_sprite):
			var def := PetBattleDB.get_level(_battle_level)
			_enemy_sprite.texture = PixelArt.pet_texture(str(def.get("opponent_pet", "ember")), _arena_frame)


func _begin_turn() -> void:
	if not _battle_active or _battle_resolved:
		return
	_player_choice = ""
	_enemy_choice = _choose_enemy_skill()
	_turn_timer = 2.0
	_turn_active = true
	for button in _skill_buttons:
		if is_instance_valid(button):
			button.disabled = false
	if _timer_bar != null:
		_timer_bar.value = 2.0
	if _timer_label != null:
		_timer_label.text = "Choose a skill — both pets act when the timer reaches zero."
	if _status != null:
		_status.text = "Round %d. Rival is choosing." % _turn_number
	_update_timer_ui()


func choose_skill(skill_id: String) -> void:
	if not _battle_active or _battle_resolved or not _turn_active:
		return
	if _player_choice != "" or not SKILLS.has(skill_id):
		return
	_player_choice = skill_id
	for button in _skill_buttons:
		if is_instance_valid(button):
			button.disabled = true
	Sfx.play("select", -9.0)
	if _timer_label != null:
		_timer_label.text = "Locked in: %s. Waiting for the 2-second window." % str(SKILLS[skill_id].name)
	if _status != null:
		_status.text = "Your companion prepares %s while the rival chooses." % str(SKILLS[skill_id].name)


func _resolve_turn() -> void:
	if not _turn_active:
		return
	_turn_active = false
	var player_action := _player_choice if _player_choice != "" else "attack"
	var enemy_action := _enemy_choice if _enemy_choice != "" else _choose_enemy_skill()
	var player_damage := _player_damage if player_action == "attack" else 0
	var enemy_damage := _enemy_damage if enemy_action == "attack" else 0
	if player_action == "defend":
		enemy_damage = int(ceil(float(enemy_damage) * 0.35))
	if enemy_action == "defend":
		player_damage = int(ceil(float(player_damage) * 0.35))
	_opponent_hp = clampi(_opponent_hp - player_damage, 0, _opponent_max)
	_player_hp = clampi(_player_hp - enemy_damage, 0, _player_max)
	_play_skill_sound(player_action)
	_play_skill_sound(enemy_action)
	if player_action == "defend":
		_spawn_hit_fx("shield", true)
	if enemy_action == "defend":
		_spawn_hit_fx("shield", false)
	if player_damage > 0:
		_spawn_hit_fx("scratch" if _turn_number % 2 == 1 else "punch", false)
	if enemy_damage > 0:
		_spawn_hit_fx("punch" if _turn_number % 2 == 1 else "scratch", true)
	_update_bars()
	_play_resolve_animation(player_action, enemy_action, player_damage > 0, enemy_damage > 0)
	var bits: Array[String] = []
	bits.append("You: %s   •   Rival: %s" % [str(SKILLS[player_action].name), str(SKILLS[enemy_action].name)])
	if player_damage > 0:
		bits.append("You dealt %d." % player_damage)
	if enemy_damage > 0:
		bits.append("Rival dealt %d." % enemy_damage)
	if player_action == "defend" and enemy_damage > 0:
		bits.append("Your shield absorbed the worst of it.")
	if enemy_action == "defend" and player_damage > 0:
		bits.append("The rival's shield held.")
	if _status != null:
		_status.text = "  ".join(bits)
	if _opponent_hp <= 0 or _player_hp <= 0:
		var won := _opponent_hp <= 0 and _player_hp > 0
		_finish_battle(won)
		return
	_turn_number += 1
	for button in _skill_buttons:
		if is_instance_valid(button):
			button.disabled = true
	_awaiting_next = true
	_next_turn_timer = 0.9
	if _timer_label != null:
		_timer_label.text = "Next round in 0.9s."


func _play_resolve_animation(player_action: String, enemy_action: String, player_hit: bool, enemy_hit: bool) -> void:
	# Attacker lunges toward the centre; a defender flashes behind a shield.
	if GameSettings.reduce_motion():
		return
	if player_hit and _player_sprite != null and is_instance_valid(_player_sprite):
		var lunge := _player_sprite.create_tween()
		lunge.tween_property(_player_sprite, "position:x", 46.0, 0.1).set_trans(Tween.TRANS_SINE)
		lunge.tween_property(_player_sprite, "position:x", 0.0, 0.2).set_trans(Tween.TRANS_BACK)
	if enemy_hit and _enemy_sprite != null and is_instance_valid(_enemy_sprite):
		var lunge2 := _enemy_sprite.create_tween()
		lunge2.tween_property(_enemy_sprite, "position:x", -46.0, 0.1).set_trans(Tween.TRANS_SINE)
		lunge2.tween_property(_enemy_sprite, "position:x", 0.0, 0.2).set_trans(Tween.TRANS_BACK)
	if player_action == "defend" and _player_sprite != null and is_instance_valid(_player_sprite):
		var guard := _player_sprite.create_tween()
		_player_sprite.modulate = Color(0.62, 0.92, 1.05)
		guard.tween_property(_player_sprite, "modulate", Color.WHITE, 0.4)
	if enemy_action == "defend" and _enemy_sprite != null and is_instance_valid(_enemy_sprite):
		var guard2 := _enemy_sprite.create_tween()
		_enemy_sprite.modulate = Color(0.62, 0.92, 1.05)
		guard2.tween_property(_enemy_sprite, "modulate", Color.WHITE, 0.4)


func _choose_enemy_skill() -> String:
	var hp_ratio := float(_opponent_hp) / float(maxi(1, _opponent_max))
	if hp_ratio <= 0.35 and _rng.randf() < 0.58:
		return "defend"
	return "attack" if _rng.randf() < 0.64 else "defend"


func _play_skill_sound(skill_id: String) -> void:
	if skill_id == "defend":
		Sfx.play("skill_guard", -8.0)
	else:
		Sfx.play("skill_attack", -7.0)


func _spawn_hit_fx(kind: String, on_player: bool) -> void:
	var target := _player_sprite if on_player else _enemy_sprite
	if target == null or not is_instance_valid(target):
		return
	var centre := target.get_global_rect().get_center()
	var effect := PetHitEffect.new()
	add_child(effect)
	effect.setup(kind, centre, 96.0)
	effect.global_position = centre - effect.size * 0.5


func _update_timer_ui() -> void:
	if _timer_bar != null:
		_timer_bar.value = _turn_timer
	if _timer_label != null and _turn_active and _player_choice == "":
		_timer_label.text = "Choose a skill — action window %.1fs" % _turn_timer


func _render_battle() -> void:
	_clear_content()
	_result_visible = false
	_skill_buttons.clear()
	var def := PetBattleDB.get_level(_battle_level)
	add_section("%s  •  %s" % [str(def.get("name", "Pet Duel")), str(def.get("subtitle", "Duel"))], GameUI.GOLD)
	add_body_text("Both pets choose Attack or Defend. When the 2-second timer ends, both actions execute simultaneously.", GameUI.MUTED, 13)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 26)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(row)
	var left := _battle_card(_player_pet_id, PetDB.name_of(_player_pet_id), "Your companion  •  Lv %d" % _player_level, Color.WHITE)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	_player_bar = left.get_meta("hp_bar") as SegmentedBar
	_player_hp_label = left.get_meta("hp_label") as Label
	_player_sprite = left.get_meta("preview") as TextureRect
	var middle := VBoxContainer.new()
	middle.custom_minimum_size = Vector2(80, 0)
	middle.add_child(GameUI.spacer(74))
	var vs := GameUI.title("VS", 30, GameUI.GOLD)
	vs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	middle.add_child(vs)
	row.add_child(middle)
	var tint: Color = def.get("opponent_tint", Color.WHITE)
	var right := _battle_card(str(def.get("opponent_pet", "ember")), str(def.get("opponent_name", "Rival")), "Arena rival  •  Attack / Defend", tint)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)
	_enemy_bar = right.get_meta("hp_bar") as SegmentedBar
	_enemy_hp_label = right.get_meta("hp_label") as Label
	_enemy_sprite = right.get_meta("preview") as TextureRect
	var skills_line := GameUI.label("Rival skills: Attack  •  Defend", 12, GameUI.MUTED)
	skills_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(skills_line)
	_status = GameUI.label("", 14, GameUI.TEXT)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.custom_minimum_size = Vector2(780, 38)
	content.add_child(_status)
	_timer_bar = ProgressBar.new()
	_timer_bar.max_value = 2.0
	_timer_bar.value = 2.0
	_timer_bar.show_percentage = false
	_timer_bar.custom_minimum_size = Vector2(780, 14)
	_timer_bar.add_theme_stylebox_override("background", GameUI.style(Color("#102126"), Color("#3e5c62"), 1, 0))
	_timer_bar.add_theme_stylebox_override("fill", GameUI.style(GameUI.PURPLE, GameUI.PURPLE.lightened(0.25), 1, 0))
	content.add_child(_timer_bar)
	_timer_label = GameUI.label("", 12, GameUI.PURPLE)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(_timer_label)
	var skill_row := HBoxContainer.new()
	skill_row.add_theme_constant_override("separation", 10)
	content.add_child(skill_row)
	for skill_id in SKILLS:
		var skill: Dictionary = SKILLS[skill_id]
		var button := GameUI.button(str(skill.name), Vector2(0, 54))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.tooltip_text = str(skill.description)
		button.pressed.connect(func() -> void: choose_skill(str(skill_id)))
		skill_row.add_child(button)
		_skill_buttons.append(button)
	var forfeit := GameUI.button("Forfeit", Vector2(120, 46))
	forfeit.pressed.connect(_forfeit)
	content.add_child(forfeit)
	_update_bars()
	_update_timer_ui()


func _battle_card(pet_id: String, display_name: String, subtitle: String, tint: Color) -> PanelContainer:
	var card := GameUI.panel(Color("#14262c"), Color("#4a6a70"))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)
	var preview := TextureRect.new()
	preview.texture = PixelArt.pet_texture(pet_id)
	preview.modulate = tint
	preview.custom_minimum_size = Vector2(260, 132)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	box.add_child(preview)
	card.set_meta("preview", preview)
	var title := GameUI.label(display_name, 19, GameUI.TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var sub := GameUI.label(subtitle, 12, GameUI.MUTED)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)
	var hp := SegmentedBar.new()
	hp.setup("HP", GameUI.RED, 10, true)
	hp.custom_minimum_size = Vector2(250, 24)
	box.add_child(hp)
	var hp_label := GameUI.label("", 12, GameUI.MUTED)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hp_label)
	card.set_meta("hp_bar", hp)
	card.set_meta("hp_label", hp_label)
	return card


func _update_bars() -> void:
	if _player_bar != null:
		_player_bar.set_values(_player_hp, _player_max)
	if _enemy_bar != null:
		_enemy_bar.set_values(_opponent_hp, _opponent_max)
	if _player_hp_label != null:
		_player_hp_label.text = "%d / %d HP" % [_player_hp, _player_max]
	if _enemy_hp_label != null:
		_enemy_hp_label.text = "%d / %d HP" % [_opponent_hp, _opponent_max]


func _forfeit() -> void:
	if not _battle_active:
		return
	_battle_active = false
	_battle_resolved = true
	_turn_active = false
	_result_visible = true
	_last_result = {"ok": false, "message": "You forfeit the duel."}
	_render_result()


func _finish_battle(won: bool) -> void:
	if _battle_resolved:
		return
	_battle_resolved = true
	_battle_active = false
	_turn_active = false
	_awaiting_next = false
	_result_visible = true
	if won:
		Sfx.play("victory", -4.0)
		_last_result = GameState.complete_pet_battle(_battle_level)
	else:
		_last_result = {"ok": false, "message": "Your companion yields. Rest and try again."}
	_render_result()


func _render_result() -> void:
	_clear_content()
	_result_visible = true
	var def := PetBattleDB.get_level(_battle_level)
	var won := bool(_last_result.get("ok", false))
	add_section("DUEL COMPLETE", GameUI.GOLD if won else GameUI.RED)
	# Fresh pose preview (the battle widgets were just cleared).
	var pose := TextureRect.new()
	pose.texture = PixelArt.pet_texture(_player_pet_id, 6 if won else 5)
	pose.custom_minimum_size = Vector2(120, 110)
	pose.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pose.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pose.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pose.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(pose)
	if not GameSettings.reduce_motion():
		var bounce := pose.create_tween().set_loops(3)
		bounce.tween_property(pose, "position:y", -8.0 if won else 2.0, 0.2).set_trans(Tween.TRANS_SINE)
		bounce.tween_property(pose, "position:y", 0.0, 0.2).set_trans(Tween.TRANS_SINE)
	add_body_text("%s  •  %s" % [str(def.get("name", "Pet Duel")), str(def.get("opponent_name", "Rival"))], GameUI.TEXT, 20)
	if won:
		var leveled := int(_last_result.get("pet_levels", 0)) > 0
		add_body_text("Your companion wins the duel and gains a level." if leveled else "Your companion wins the duel at maximum level.", GameUI.GREEN, 18)
		var rewards := HBoxContainer.new()
		rewards.add_theme_constant_override("separation", 22)
		rewards.add_child(_reward_chip("gold", "%d gold" % int(_last_result.get("gold", 0)), GameUI.GOLD))
		rewards.add_child(_reward_chip("spark", "%d pet XP" % int(_last_result.get("xp", 0)), GameUI.PURPLE))
		rewards.add_child(_reward_chip("heart", "Level %d" % int(_last_result.get("pet_level", GameState.get_active_pet().get("level", 1))), GameUI.GREEN))
		content.add_child(rewards)
	else:
		add_body_text(str(_last_result.get("message", "The duel is lost.")), GameUI.RED, 18)
		add_body_text("Your companion is unharmed. Feed it, raise its level and challenge the arena again.", GameUI.MUTED, 13)
	content.add_child(GameUI.spacer(8))
	var back := GameUI.button("Back to the Tournament", Vector2(330, 48))
	back.pressed.connect(func() -> void:
		_result_visible = false
		_last_result = {}
		_rebuild())
	content.add_child(back)


func _reward_chip(kind: String, text: String, color: Color) -> Control:
	var panel := GameUI.panel(Color("#14262c"), color.darkened(0.3))
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	hbox.add_child(GameUI.icon_rect(kind, 24))
	hbox.add_child(GameUI.label(text, 18, color))
	panel.add_child(hbox)
	return panel


func close_panel() -> void:
	_battle_active = false
	_battle_resolved = false
	_turn_active = false
	_awaiting_next = false
	_result_visible = false
	super.close_panel()
