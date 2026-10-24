class_name PetBattlePanel
extends ModalBase
## Three-skill 1v1 duels: player acts first, then the rival replies.
## Both pets wait for an explicit player choice, then resolve together.
## A victory always grants a pet level.

const SKILLS := {
	"attack": {"name": "1. Serang", "description": "Serangan biasa. Cooldown 2 saat.", "cooldown": 2.0, "power": 1.0},
	"defend": {"name": "2. Perisai", "description": "Kurangkan serangan seterusnya sebanyak 65%. Cooldown 5 saat.", "cooldown": 5.0, "power": 0.0},
	"burst": {"name": "3. Kuasa Khas", "description": "Serangan berganda. Cooldown 8 saat.", "cooldown": 8.0, "power": 2.0},
}

var selected := ""
var _arena_frame_timer := 0.0
var _arena_frame := 0
var _player_cooldowns: Dictionary = {}
var _enemy_cooldowns: Dictionary = {}
var _player_guard := false
var _enemy_guard := false
var _enemy_pending := false
var _enemy_wait := 0.0
var _arena_backdrop: TextureRect
var _arena_veil: ColorRect
var _enemy_cd_label: Label

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
	_panel_size = Vector2(920, 640)
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
	add_body_text(xp_text, GameUI.PURPLE, 14)
	add_body_text("Pilih duel 1 lawan 1. Anda mempunyai tiga kuasa dengan cooldown masing-masing. Pemain bergerak dahulu, kemudian musuh membalas.", GameUI.MUTED, 13)
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
	_player_cooldowns = {"attack": 0.0, "defend": 0.0, "burst": 0.0}
	_enemy_cooldowns = {"attack": 0.0, "defend": 0.0, "burst": 0.0}
	_player_guard = false
	_enemy_guard = false
	_enemy_pending = false
	_awaiting_next = false
	_rng.seed = 4471 + level_id.hash()
	_render_battle()
	_begin_turn()
	return true


func _process(delta: float) -> void:
	if not visible or not _battle_active or _battle_resolved:
		return
	_arena_idle(delta)
	for skill_id in SKILLS:
		_player_cooldowns[skill_id] = maxf(0, float(_player_cooldowns.get(skill_id, 0)) - delta)
		_enemy_cooldowns[skill_id] = maxf(0, float(_enemy_cooldowns.get(skill_id, 0)) - delta)
	_refresh_skill_buttons()
	if _enemy_pending:
		_enemy_wait -= delta
		if _enemy_wait <= 0:
			_resolve_enemy_turn()
	elif _awaiting_next:
		_next_turn_timer -= delta
		if _next_turn_timer <= 0:
			_awaiting_next = false
			_begin_turn()

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
	_enemy_choice = ""
	_turn_active = true
	if is_instance_valid(_status):
		_status.text = "Giliran anda - pilih satu kuasa."
	_update_timer_ui()
	_refresh_skill_buttons()

func choose_skill(skill_id: String) -> void:
	if not _battle_active or _battle_resolved or not _turn_active or not _player_choice.is_empty() or not SKILLS.has(skill_id):
		return
	if float(_player_cooldowns.get(skill_id, 0)) > 0:
		return
	_player_choice = skill_id
	Sfx.play("select", -9.0)
	_resolve_turn()

func _resolve_turn() -> void:
	if not _turn_active or _player_choice.is_empty():
		return
	_turn_active = false
	var skill: Dictionary = SKILLS[_player_choice]
	_player_cooldowns[_player_choice] = float(skill.get("cooldown", 2))
	var damage := roundi(_player_damage * float(skill.get("power", 1)))
	if _player_choice == "defend":
		_player_guard = true
		_spawn_hit_fx("shield", true)
	elif damage > 0:
		if _enemy_guard:
			damage = ceili(damage * 0.35)
			_enemy_guard = false
		_opponent_hp = maxi(0, _opponent_hp - damage)
		_spawn_hit_fx("punch" if _player_choice == "burst" else "scratch", false)
	_play_skill_sound(_player_choice)
	_play_resolve_animation(_player_choice, "", damage > 0, false)
	_update_bars()
	_status.text = "%s%s. Musuh membalas selepas ini." % [skill.get("name", "Kuasa"), " - %d damage" % damage if damage > 0 else " diaktifkan"]
	if _opponent_hp <= 0:
		_finish_battle(true)
		return
	_enemy_pending = true
	_enemy_wait = 0.7
	_refresh_skill_buttons()

func _resolve_enemy_turn() -> void:
	if not _battle_active or _battle_resolved or not _enemy_pending:
		return
	if not SKILLS.has(_enemy_choice) or float(_enemy_cooldowns.get(_enemy_choice, 0)) > 0:
		_enemy_choice = _choose_enemy_skill()
	if _enemy_choice.is_empty():
		_enemy_wait = 0.1
		_status.text = "Kuasa musuh sedang cooldown..."
		return
	_enemy_pending = false
	var skill: Dictionary = SKILLS[_enemy_choice]
	_enemy_cooldowns[_enemy_choice] = float(skill.get("cooldown", 2))
	var damage := roundi(_enemy_damage * float(skill.get("power", 1)))
	if _enemy_choice == "defend":
		_enemy_guard = true
		_spawn_hit_fx("shield", false)
	elif damage > 0:
		if _player_guard:
			damage = ceili(damage * 0.35)
			_player_guard = false
		_player_hp = maxi(0, _player_hp - damage)
		_spawn_hit_fx("punch" if _enemy_choice == "burst" else "scratch", true)
	_play_skill_sound(_enemy_choice)
	_play_resolve_animation("", _enemy_choice, false, damage > 0)
	_update_bars()
	_status.text = "Musuh: %s%s." % [skill.get("name", "Kuasa"), " - %d damage" % damage if damage > 0 else " diaktifkan"]
	if _player_hp <= 0:
		_finish_battle(false)
		return
	_turn_number += 1
	_awaiting_next = true
	_next_turn_timer = 0.6
	_refresh_skill_buttons()

func _play_resolve_animation(player_action: String, enemy_action: String, player_hit: bool, enemy_hit: bool) -> void:
	if GameSettings.reduce_motion():
		return
	for entry in [[_player_sprite, player_action, player_hit, 1.0], [_enemy_sprite, enemy_action, enemy_hit, -1.0]]:
		var sprite := entry[0] as TextureRect
		if not is_instance_valid(sprite):
			continue
		if bool(entry[2]):
			var origin := sprite.position
			var lunge := sprite.create_tween()
			lunge.tween_property(sprite, "position", origin + Vector2(float(entry[3]) * 28, 0), 0.12)
			lunge.tween_property(sprite, "position", origin, 0.22)
		elif str(entry[1]) == "defend":
			var normal := sprite.modulate
			sprite.modulate = Color("#9bdbff")
			sprite.create_tween().tween_property(sprite, "modulate", normal, 0.4)

func _choose_enemy_skill() -> String:
	var ready: Array[String] = []
	for skill_id in SKILLS:
		if float(_enemy_cooldowns.get(skill_id, 0)) <= 0:
			ready.append(str(skill_id))
	if ready.is_empty():
		return ""
	return ready[_rng.randi_range(0, ready.size() - 1)]

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
	if is_instance_valid(_timer_label):
		_timer_label.text = "Tiga kuasa berasingan. Musuh hanya membalas selepas anda bertindak."

func _refresh_skill_buttons() -> void:
	for button in _skill_buttons:
		if not is_instance_valid(button):
			continue
		var id := str(button.get_meta("skill_id", "attack"))
		var remaining := float(_player_cooldowns.get(id, 0))
		button.disabled = not _turn_active or remaining > 0 or not _battle_active
		button.text = "%s\n%s" % [SKILLS[id].get("name", id), "%.1fs" % remaining if remaining > 0 else "Sedia"]
	if is_instance_valid(_enemy_cd_label):
		var parts: Array[String] = []
		for id in SKILLS:
			var remaining := float(_enemy_cooldowns.get(id, 0))
			parts.append("%s: %s" % [str(SKILLS[id].get("name", id)), "%.1fs" % remaining if remaining > 0 else "Sedia"])
		_enemy_cd_label.text = " | ".join(parts)

func _render_battle() -> void:
	_clear_content()
	play_entry_fade()
	_result_visible = false
	_panel_size = get_viewport_rect().size
	_fit_panel()
	var definition := PetBattleDB.get_level(_battle_level)
	_arena_backdrop = TextureRect.new()
	_arena_backdrop.name = "FullArenaBackground"
	_arena_backdrop.texture = load(str(definition.get("background", ""))) as Texture2D
	_arena_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_arena_backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_arena_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(_arena_backdrop)
	panel.move_child(_arena_backdrop, 0)
	_arena_veil = ColorRect.new()
	_arena_veil.color = Color(0, 0, 0, 0.25)
	_arena_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(_arena_veil)
	panel.move_child(_arena_veil, 1)
	var stage := Control.new()
	stage.name = "OpenBattleStage"
	stage.custom_minimum_size = Vector2(0, maxf(155, get_viewport_rect().size.y - 330))
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(stage)
	_player_sprite = _arena_pet(stage, _player_pet_id, Vector2(0.23, 0.70), Color.WHITE)
	_enemy_sprite = _arena_pet(stage, str(definition.get("opponent_pet", "ember")), Vector2(0.77, 0.70), definition.get("opponent_tint", Color.WHITE))
	_player_sprite.name = "PlayerPet"
	_enemy_sprite.name = "RivalPet"
	var left := VBoxContainer.new()
	left.position = Vector2(18, 8)
	left.custom_minimum_size = Vector2(260, 0)
	stage.add_child(left)
	left.add_child(_arena_label("%s - Lv %d" % [PetDB.name_of(_player_pet_id), _player_level], 22))
	_player_bar = SegmentedBar.new()
	_player_bar.setup("HP", GameUI.RED, 10, true)
	_player_bar.custom_minimum_size = Vector2(260, 25)
	left.add_child(_player_bar)
	_player_hp_label = _arena_label("", 14)
	left.add_child(_player_hp_label)
	var right := VBoxContainer.new()
	right.anchor_left = 1
	right.anchor_right = 1
	right.offset_left = -278
	right.offset_right = -18
	right.offset_top = 8
	right.custom_minimum_size = Vector2(260, 0)
	stage.add_child(right)
	right.add_child(_arena_label(str(definition.get("opponent_name", "Rival")), 22))
	_enemy_bar = SegmentedBar.new()
	_enemy_bar.setup("HP", GameUI.RED, 10, true)
	_enemy_bar.custom_minimum_size = Vector2(260, 25)
	right.add_child(_enemy_bar)
	_enemy_hp_label = _arena_label("", 14)
	right.add_child(_enemy_hp_label)
	_enemy_cd_label = _arena_label("", 12)
	_enemy_cd_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_enemy_cd_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(_enemy_cd_label)
	_status = _arena_label("Giliran anda.", 18)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.custom_minimum_size = Vector2(0, 28)
	content.add_child(_status)
	_timer_label = _arena_label("", 13)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(_timer_label)
	var skills := HBoxContainer.new()
	skills.add_theme_constant_override("separation", 12)
	content.add_child(skills)
	for id in SKILLS:
		var button := GameUI.button(str(SKILLS[id].get("name", id)), Vector2(0, 64))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.set_meta("skill_id", id)
		button.tooltip_text = str(SKILLS[id].get("description", ""))
		button.pressed.connect(choose_skill.bind(str(id)))
		skills.add_child(button)
		_skill_buttons.append(button)
	_update_bars()
	_update_timer_ui()

func _arena_pet(stage: Control, id: String, at: Vector2, tint: Color) -> TextureRect:
	var sprite := TextureRect.new()
	sprite.texture = PixelArt.pet_texture(id)
	sprite.modulate = tint
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.anchor_left = at.x
	sprite.anchor_right = at.x
	sprite.anchor_top = at.y
	sprite.anchor_bottom = at.y
	var extent := minf(170, maxf(80, stage.custom_minimum_size.y * 0.44))
	sprite.offset_left = -extent / 2
	sprite.offset_right = extent / 2
	sprite.offset_top = -extent / 2
	sprite.offset_bottom = extent / 2
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(sprite)
	return sprite

func _arena_label(text: String, size: int) -> Label:
	var label := GameUI.label(text, size, GameUI.TEXT)
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	return label

func _clear_content() -> void:
	for backdrop in [_arena_backdrop, _arena_veil]:
		if is_instance_valid(backdrop):
			backdrop.queue_free()
	_arena_backdrop = null
	_arena_veil = null
	_player_sprite = null
	_enemy_sprite = null
	_player_bar = null
	_enemy_bar = null
	_player_hp_label = null
	_enemy_hp_label = null
	_status = null
	_timer_label = null
	_timer_bar = null
	_enemy_cd_label = null
	_skill_buttons.clear()
	super._clear_content()

func _battle_card(pet_id: String, display_name: String, subtitle: String, tint: Color) -> PanelContainer:
	var card := GameUI.panel(Color(0.04, 0.08, 0.10, 0.24), Color("#4a6a70"))
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
