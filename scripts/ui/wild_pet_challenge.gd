class_name WildPetChallenge
extends Control
## The clearing remains visible. Only the manual duel UI continues to process.
signal closed

var duel: PetDuel
var realm: TwilightRealm
var encounter: RealmInteractable
var _token := 0
var _saved: Dictionary = {}
var _controls: Array[Dictionary] = []
var _buttons: Dictionary = {}
var _status: Label
var _health: Label
var _resolved := false
var _participant := ""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var top := PanelContainer.new()
	add_child(top)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 120
	top.offset_right = -120
	top.offset_top = 86
	top.add_theme_stylebox_override("panel", GameUI.style(Color(0.06,0.08,0.16,0.9), Color("#8d8eae"), 1, 10))
	_health = GameUI.label("", 18, GameUI.TEXT)
	_health.clip_text = true
	_health.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(_health)
	var bottom := PanelContainer.new()
	add_child(bottom)
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 24
	bottom.offset_right = -24
	bottom.offset_top = -218
	bottom.offset_bottom = -24
	bottom.add_theme_stylebox_override("panel", GameUI.style(Color(0.06,0.08,0.16,0.94), Color("#8d8eae"), 1, 12))
	var box := VBoxContainer.new()
	bottom.add_child(box)
	_status = GameUI.label("", 16, GameUI.TEXT)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_status)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	for id in PetBattlePanel.SKILLS:
		var button := GameUI.button(str(PetBattlePanel.SKILLS[id].name), Vector2(0,70))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.tooltip_text = str(PetBattlePanel.SKILLS[id].description)
		button.pressed.connect(choose_skill.bind(str(id)))
		row.add_child(button)
		_buttons[id] = button
	var actions := HBoxContainer.new()
	box.add_child(actions)
	var leave := GameUI.button("Leave the challenge", Vector2(240,70))
	leave.pressed.connect(close_panel)
	actions.add_child(leave)
	var settings := GameUI.button("Settings", Vector2(140,70))
	settings.pressed.connect(func() -> void:
		var game := get_tree().get_first_node_in_group("game") as Game
		if is_instance_valid(game): game.open_settings())
	actions.add_child(settings)

func open_challenge(owner_world: TwilightRealm, wild: RealmInteractable) -> void:
	_token = GameState.begin_wild_encounter(wild.stable_id)
	if _token == 0:
		closed.emit()
		return
	realm = owner_world
	encounter = wild
	_participant = GameState.active_pet_id()
	duel = PetDuel.new()
	duel.setup(GameState.get_pet(_participant), wild.stable_id)
	_resolved = false
	_saved = {"mode": realm.process_mode, "player": realm.player.position, "pet": realm.pet.position, "wild": wild.position, "camera": realm.camera.position, "zoom": realm.camera.zoom, "camera_mode": realm.camera.process_mode}
	realm.process_mode = Node.PROCESS_MODE_DISABLED
	realm.player.position = wild.position + Vector2(0, 3.0)
	realm.pet.position = wild.position + Vector2(-2.2, 0.7)
	wild.position += Vector2(2.2, 0.7)
	wild.label.visible = false
	if is_instance_valid(wild.marker): wild.marker.visible = false
	realm.camera.position = _saved.wild + Vector2(0, 1.1)
	realm.camera.zoom = Vector2.ONE * minf(70, get_viewport_rect().size.x / 12.5)
	realm.camera.reset_physics_interpolation()
	var hud := get_tree().get_first_node_in_group("hud") as GameHUD
	_controls.clear()
	var obscured: Array = hud._control_nodes.values()
	obscured.append_array([hud._map_button,hud._clock_label.get_parent(),realm.player.get_node("VitalHud"),realm.pet.get_node("PetHealth")])
	for control in obscured:
		_controls.append({"node": control, "visible": control.visible})
		control.visible = false
	visible = true
	move_to_front()
	Sfx.start_battle_music(str(RealmDB.ENCOUNTERS[wild.stable_id].duel))
	_refresh()

func _process(delta: float) -> void:
	if not visible: return
	var game := get_tree().get_first_node_in_group("game") as Game
	if not is_instance_valid(game) or not is_instance_valid(realm) or game.world != realm or not is_instance_valid(encounter):
		close_panel()
		return
	for item in _controls:
		if is_instance_valid(item.node): item.node.visible = false
	if game.hud.settings_panel.visible: return
	game.hud._prompt_panel.visible = false
	var before_hp := duel.player_hp
	var before_guard := duel.rival_guard
	duel.tick(delta)
	if duel.player_hp < before_hp: _hit_fx("scratch", realm.pet)
	if not before_guard and duel.rival_guard: _hit_fx("shield", encounter)
	if not duel.result.is_empty() and not _resolved:
		_resolved = true
		if duel.result == "win":
			var reward := GameState.complete_wild_encounter(_token)
			duel.status = str(reward.get("message", "Challenge complete."))
			Sfx.play("victory", -7)
		else:
			GameState.cancel_wild_encounter(_token)
			duel.status = "Your companion yields peacefully. Both pets are unharmed. You can try again."
		Sfx.stop_battle_music()
	_refresh()

func choose_skill(id: String) -> void:
	if not visible or not is_instance_valid(realm) or _resolved: return
	if duel.choose(id):
		Sfx.play("skill_guard" if id == "defend" else "skill_attack", -10)
		_hit_fx("shield" if id == "defend" else ("punch" if id == "burst" else "scratch"), realm.pet if id == "defend" else encounter)
	_refresh()

func _hit_fx(kind: String, subject: Node2D) -> void:
	var center := subject.get_global_transform_with_canvas() * Vector2(0,-0.6)
	var effect := PetHitEffect.new()
	add_child(effect)
	effect.setup(kind,center,70)
	effect.global_position = center - effect.size * 0.5

func _refresh() -> void:
	_health.text = "%s  %d/%d HP     ·     %s  %d/%d HP" % [PetDB.name_of(_participant),duel.player_hp,duel.player_max,PetDB.name_of(duel.rival_id),duel.rival_hp,duel.rival_max]
	_status.text = duel.status
	for id in _buttons:
		var button := _buttons[id] as Button
		var cooldown := float(duel.player_cooldowns[id])
		button.disabled = _resolved or duel.turn != "player" or cooldown > 0
		button.text = "%s%s" % [str(PetBattlePanel.SKILLS[id].name), " · %.1fs" % cooldown if cooldown > 0 else ""]

func _unhandled_input(event: InputEvent) -> void:
	if not visible: return
	var game := get_tree().get_first_node_in_group("game") as Game
	if is_instance_valid(game) and game.hud.settings_panel.visible: return
	if event.is_action_pressed("ui_cancel"):
		close_panel()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		var ids := {KEY_1: "attack", KEY_2: "defend", KEY_3: "burst"}
		if ids.has(event.physical_keycode):
			choose_skill(ids[event.physical_keycode])
			get_viewport().set_input_as_handled()

func close_panel() -> void:
	if not visible and _token == 0: return
	GameState.cancel_wild_encounter(_token)
	_token = 0
	visible = false
	Sfx.stop_battle_music()
	var game := get_tree().get_first_node_in_group("game") as Game
	if is_instance_valid(realm) and not realm.is_queued_for_deletion():
		realm.process_mode = int(_saved.mode)
		if is_instance_valid(game) and game.world == realm:
			realm.player.position = _saved.player
			realm.pet.position = _saved.pet
			realm.camera.position = _saved.camera
			realm.camera.zoom = _saved.zoom
			realm.camera.process_mode = int(_saved.camera_mode)
			if is_instance_valid(encounter):
				encounter.position = _saved.wild
				encounter.label.visible = true
				encounter.refresh()
			if _resolved: realm.set_message(duel.status)
	for item in _controls:
		if is_instance_valid(item.node): item.node.visible = bool(item.visible)
	_controls.clear()
	if is_instance_valid(game):
		game.hud.release_world_controls()
		game.hud._apply_touch_mode()
		game.hud._update_prompt()
	realm = null
	encounter = null
	closed.emit()

func _exit_tree() -> void:
	if _token != 0: close_panel()
