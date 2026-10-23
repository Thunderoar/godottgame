class_name GameHUD
extends CanvasLayer
## Persistent mobile HUD and the owner of every modal panel.

signal inventory_requested
signal build_mode_requested
signal menu_requested

const DEFAULT_CONTROL_LAYOUT := {
	"joystick": {"x": 20.0, "y": 514.0, "size": 190.0},
	"attack": {"x": 1148.0, "y": 586.0, "size": 102.0},
	"interact": {"x": 1156.0, "y": 486.0, "size": 82.0},
	"inventory": {"x": 24.0, "y": 160.0, "size": 64.0},
	"build": {"x": 96.0, "y": 160.0, "size": 64.0},
	"health_potion": {"x": 1122.0, "y": 540.0, "size": 58.0},
	"mana_potion": {"x": 1054.0, "y": 608.0, "size": 58.0},
}

var world: Node = null
var shop_panel: ShopPanel
var inventory_panel: InventoryPanel
var portal_panel: PortalPanel
var pet_battle_panel: PetBattlePanel
var sea_cleaning_panel: SeaCleaningPanel
var house_panel: HousePanel
var victory_panel: VictoryPanel
var defeat_panel: DefeatPanel
var tutorial_guide: TutorialGuide
var menu_panel: MenuPanel
var settings_panel: SettingsPanel
var dialogue_panel: DialoguePanel
var game_over_panel: GameOverPanel

var _root: Control
var _gold_label: Label
var _diamond_label: Label
var _identity_label: Label
var _clock_label: Label
var _health_bar: SegmentedBar
var _mana_bar: SegmentedBar
var _xp_bar: SegmentedBar
var _pet_bar: SegmentedBar
var _pet_xp_bar: SegmentedBar
var _pet_name: Label
var _pet_icon: TextureRect
var _objectives_box: VBoxContainer
var _emergency_panel: PanelContainer
var _emergency_label: Label
var _recovery_panel: PanelContainer
var _recovery_label: Label
var _recovery_bar: SegmentedBar
var _objective_panel: PanelContainer
var _mission_panel: PanelContainer
var _mission_arrows: Array[MissionArrow] = []
var _mission_timer := 0.0
var _boss_panel: PanelContainer
var _boss_label: Label
var _boss_bar: SegmentedBar
var _prompt_panel: PanelContainer
var _prompt_label: Label
var _loot_label: Label
var _sleep_panel: PanelContainer
var _sleep_bar: SegmentedBar
var _sleep_label: Label
var _joystick: TouchJoystick
var _attack_button: TouchActionButton
var _interact_button: TouchActionButton
var _inventory_button: TouchActionButton
var _build_button: TouchActionButton
var _health_potion_button: TouchActionButton
var _mana_potion_button: TouchActionButton
var _hp_count: Label
var _mp_count: Label
var _build_mode_panel: PanelContainer
var _menu_button: Button
var _zoom_out_button: Button
var _zoom_in_button: Button
var _control_nodes: Dictionary = {}
var _default_transforms: Dictionary = {}
var _fade: ColorRect
var _vignette: TextureRect
var _last_prompt := ""
var _last_objectives := ""
var _loot_timer := 0.0


func _ready() -> void:
	layer = 10
	add_to_group("hud")
	_build_root()
	_build_menu_button()
	_build_zoom_controls()
	_build_currency_panel()
	_build_vitals_panel()
	_build_objectives()
	_build_mission_guide()
	_build_emergency_panel()
	_build_build_mode_panel()
	_build_boss_bar()
	_build_controls()
	_apply_saved_settings()
	_build_prompt()
	_build_sleep_panel()
	_build_recovery_panel()
	_build_tutorial()
	_build_modals()
	_build_fade()
	_root.resized.connect(func() -> void:
		_root.pivot_offset = _root.size * 0.5)
	GameState.data_changed.connect(refresh_all)
	GameState.pet_changed.connect(_refresh_pet)
	GameSettings.changed.connect(_on_setting_changed)
	_apply_touch_mode()
	GameState.boss_health_changed.connect(_on_boss_health)
	GameState.expedition_changed.connect(_refresh_loot)
	GameState.emergency_changed.connect(_on_emergency_changed)
	set_process(true)
	refresh_all()


func _build_root() -> void:
	_root = Control.new()
	_root.name = "HUDRoot"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = GameUI.theme()
	add_child(_root)


func _build_menu_button() -> void:
	_menu_button = GameUI.button("Menu", Vector2(92, 38))
	_menu_button.name = "MenuButton"
	_menu_button.anchor_left = 1.0
	_menu_button.anchor_right = 1.0
	_menu_button.offset_left = -114
	_menu_button.offset_right = -22
	_menu_button.offset_top = 18
	_menu_button.offset_bottom = 56
	_menu_button.add_theme_font_size_override("font_size", 15)
	_menu_button.pressed.connect(func() -> void: menu_requested.emit())
	_root.add_child(_menu_button)


func _build_zoom_controls() -> void:
	_zoom_out_button = GameUI.button("−", Vector2(42, 38))
	_zoom_out_button.name = "ZoomOutButton"
	_zoom_out_button.tooltip_text = "Zoom out (− / mouse wheel down)"
	_zoom_out_button.anchor_left = 1.0
	_zoom_out_button.anchor_right = 1.0
	_zoom_out_button.offset_left = -104
	_zoom_out_button.offset_right = -62
	_zoom_out_button.offset_top = 66
	_zoom_out_button.offset_bottom = 104
	_zoom_out_button.add_theme_font_size_override("font_size", 20)
	_zoom_out_button.pressed.connect(func() -> void: _step_camera_zoom(-1.0))
	_root.add_child(_zoom_out_button)

	_zoom_in_button = GameUI.button("+", Vector2(42, 38))
	_zoom_in_button.name = "ZoomInButton"
	_zoom_in_button.tooltip_text = "Zoom in (+ / mouse wheel up)"
	_zoom_in_button.anchor_left = 1.0
	_zoom_in_button.anchor_right = 1.0
	_zoom_in_button.offset_left = -58
	_zoom_in_button.offset_right = -16
	_zoom_in_button.offset_top = 66
	_zoom_in_button.offset_bottom = 104
	_zoom_in_button.add_theme_font_size_override("font_size", 20)
	_zoom_in_button.pressed.connect(func() -> void: _step_camera_zoom(1.0))
	_root.add_child(_zoom_in_button)


func _step_camera_zoom(direction: float) -> void:
	var active_camera := get_viewport().get_camera_2d()
	if active_camera != null and active_camera.has_method("step_zoom"):
		active_camera.call("step_zoom", direction)


func _build_currency_panel() -> void:
	var panel := GameUI.panel(Color(0.035, 0.08, 0.09, 0.88), Color("#3a565a"))
	panel.position = Vector2(22, 18)
	panel.custom_minimum_size = Vector2(292, 134)
	_root.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	box.add_child(top)
	_identity_label = GameUI.label("Mira  •  Lv 1", 16, GameUI.TEXT)
	_identity_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_identity_label)
	_clock_label = GameUI.label("DAYTIME", 12, GameUI.GOLD)
	top.add_child(_clock_label)
	var currencies := HBoxContainer.new()
	currencies.add_theme_constant_override("separation", 14)
	box.add_child(currencies)
	currencies.add_child(GameUI.icon_rect("gold", 20))
	_gold_label = GameUI.label("120", 17, GameUI.GOLD)
	currencies.add_child(_gold_label)
	currencies.add_child(GameUI.icon_rect("diamond", 19))
	_diamond_label = GameUI.label("12", 17, GameUI.DIAMOND)
	currencies.add_child(_diamond_label)
	_xp_bar = SegmentedBar.new()
	_xp_bar.setup("XP", GameUI.TEAL, 10, true)
	_xp_bar.custom_minimum_size = Vector2(268, 22)
	box.add_child(_xp_bar)
	_pet_xp_bar = SegmentedBar.new()
	_pet_xp_bar.setup("PET XP", GameUI.PURPLE, 10, true)
	_pet_xp_bar.custom_minimum_size = Vector2(268, 22)
	box.add_child(_pet_xp_bar)



func _build_vitals_panel() -> void:
	# Keep bar objects alive for shared HUD state, but hide the crowded dashboard.
	# The compact PlayerVitalHud above the character remains available.
	var panel := GameUI.panel(Color(0.035, 0.08, 0.09, 0.9), Color("#3a565a"))
	panel.name = "VitalsPanel"
	panel.visible = false
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.offset_left = -330
	panel.offset_right = -22
	panel.offset_top = 64
	panel.offset_bottom = 218
	_root.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)
	var header := HBoxContainer.new()
	header.add_child(GameUI.label("VITALS", 11, GameUI.MUTED))
	var atk := GameUI.label("ATK %d  •  DEF %d" % [GameState.attack_power(), GameState.defense()], 11, GameUI.TEAL)
	atk.name = "VitalsStats"
	atk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	atk.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(atk)
	box.add_child(header)
	_health_bar = SegmentedBar.new()
	_health_bar.setup("HEALTH", GameUI.RED, 10, false)
	box.add_child(_health_bar)
	_mana_bar = SegmentedBar.new()
	_mana_bar.setup("MANA", GameUI.MANA, 10, false)
	box.add_child(_mana_bar)
	var pet_row := HBoxContainer.new()
	pet_row.add_theme_constant_override("separation", 8)
	box.add_child(pet_row)
	_pet_icon = TextureRect.new()
	_pet_icon.custom_minimum_size = Vector2(30, 30)
	_pet_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pet_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_pet_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pet_row.add_child(_pet_icon)
	var pet_info := VBoxContainer.new()
	pet_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pet_info.add_theme_constant_override("separation", 0)
	pet_row.add_child(pet_info)
	_pet_name = GameUI.label("Ember  Lv 1", 11, GameUI.MUTED)
	pet_info.add_child(_pet_name)
	_pet_bar = SegmentedBar.new()
	_pet_bar.setup("PET", GameUI.GOLD, 5, true)
	_pet_bar.custom_minimum_size = Vector2(250, 22)
	pet_info.add_child(_pet_bar)


func _build_objectives() -> void:
	_objective_panel = GameUI.panel(Color(0.035, 0.08, 0.09, 0.84), Color("#3a565a"))
	_objective_panel.anchor_left = 0.5
	_objective_panel.anchor_right = 0.5
	_objective_panel.offset_left = -202
	_objective_panel.offset_right = 202
	_objective_panel.offset_top = 18
	_objective_panel.offset_bottom = 88
	_root.add_child(_objective_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	_objective_panel.add_child(box)
	var head := HBoxContainer.new()
	head.add_child(GameUI.label("JOURNAL", 10, GameUI.GOLD))
	var zone := GameUI.label("Seaside Home", 10, GameUI.MUTED)
	zone.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zone.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	zone.name = "ZoneLabel"
	head.add_child(zone)
	box.add_child(head)
	_objectives_box = VBoxContainer.new()
	_objectives_box.add_theme_constant_override("separation", 1)
	box.add_child(_objectives_box)


func _build_mission_guide() -> void:
	_mission_panel = GameUI.panel(Color(0.025, 0.065, 0.075, 0.88), Color("#45666b"))
	_mission_panel.anchor_left = 0.5
	_mission_panel.anchor_right = 0.5
	_mission_panel.anchor_top = 1.0
	_mission_panel.anchor_bottom = 1.0
	_mission_panel.offset_left = -252
	_mission_panel.offset_right = 252
	_mission_panel.offset_top = -136
	_mission_panel.offset_bottom = -92
	_mission_panel.visible = false
	_root.add_child(_mission_panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	_mission_panel.add_child(row)
	for i in 3:
		var arrow := MissionArrow.new()
		arrow.custom_minimum_size = Vector2(160, 30)
		arrow.visible = false
		row.add_child(arrow)
		_mission_arrows.append(arrow)


func _update_mission_guide() -> void:
	if _mission_panel == null:
		return
	if world == null or not is_instance_valid(world):
		_mission_panel.visible = false
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		_mission_panel.visible = false
		return
	var targets: Array = []
	if world.has_method("get_guidance_targets"):
		targets = world.call("get_guidance_targets") as Array
	if targets.is_empty():
		_mission_panel.visible = false
		return
	_mission_panel.visible = true
	for i in _mission_arrows.size():
		var arrow := _mission_arrows[i]
		if i >= targets.size():
			arrow.visible = false
			continue
		var target: Dictionary = targets[i]
		var target_color: Color = target.get("color", GameUI.TEAL)
		var target_position: Vector2 = target.get("position", player.global_position)
		arrow.visible = true
		arrow.setup(str(target.get("label", "OBJECTIVE")), target_color)
		arrow.aim(player.global_position, target_position)


func _build_emergency_panel() -> void:
	_emergency_panel = GameUI.panel(Color(0.16, 0.035, 0.045, 0.94), Color("#c44f55"))
	_emergency_panel.anchor_left = 0.5
	_emergency_panel.anchor_right = 0.5
	_emergency_panel.offset_left = -290
	_emergency_panel.offset_right = 290
	_emergency_panel.offset_top = 96
	_emergency_panel.offset_bottom = 140
	_emergency_panel.visible = false
	_root.add_child(_emergency_panel)
	_emergency_label = GameUI.label("SETTLEMENT UNDER ATTACK", 14, Color("#ffc0b2"))
	_emergency_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_emergency_panel.add_child(_emergency_label)


func _build_build_mode_panel() -> void:
	_build_mode_panel = GameUI.panel(Color(0.035, 0.09, 0.07, 0.94), Color("#5f9b79"))
	_build_mode_panel.anchor_left = 0.5
	_build_mode_panel.anchor_right = 0.5
	_build_mode_panel.offset_left = -290
	_build_mode_panel.offset_right = 290
	_build_mode_panel.offset_top = 96
	_build_mode_panel.offset_bottom = 138
	_build_mode_panel.visible = false
	_root.add_child(_build_mode_panel)
	var label := GameUI.label("SETTLEMENT EDITOR  •  drag buildings inside the marked area", 13, Color("#b8f0c8"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_build_mode_panel.add_child(label)


func _build_boss_bar() -> void:
	_boss_panel = GameUI.panel(Color(0.06, 0.04, 0.055, 0.92), Color("#7a3d46"))
	_boss_panel.anchor_left = 0.5
	_boss_panel.anchor_right = 0.5
	_boss_panel.offset_left = -280
	_boss_panel.offset_right = 280
	_boss_panel.offset_top = 100
	_boss_panel.offset_bottom = 168
	_boss_panel.visible = false
	_root.add_child(_boss_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	_boss_panel.add_child(box)
	_boss_label = GameUI.label("THE GROTTO WARDEN", 13, Color("#ffb0a8"))
	_boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_boss_label)
	_boss_bar = SegmentedBar.new()
	_boss_bar.setup("BOSS", Color("#c94750"), 20, true)
	box.add_child(_boss_bar)


func _build_controls() -> void:
	_joystick = TouchJoystick.new()
	_joystick.anchor_top = 1.0
	_joystick.anchor_bottom = 1.0
	_joystick.offset_left = 20
	_joystick.offset_right = 210
	_joystick.offset_top = -206
	_joystick.offset_bottom = -16
	_root.add_child(_joystick)

	_attack_button = TouchActionButton.new()
	_attack_button.action = "attack"
	_attack_button.caption = "Strike"
	_attack_button.icon_kind = "sword"
	_attack_button.accent = Color("#e1a34f")
	_attack_button.diameter = 102
	_anchor_bottom_right(_attack_button, Vector2(-132, -134), Vector2(-30, -32))
	_root.add_child(_attack_button)

	_interact_button = TouchActionButton.new()
	_interact_button.action = "interact"
	_interact_button.caption = "Use"
	_interact_button.icon_kind = "spark"
	_interact_button.accent = Color("#61c9ba")
	_interact_button.diameter = 82
	_anchor_bottom_right(_interact_button, Vector2(-124, -234), Vector2(-42, -152))
	_root.add_child(_interact_button)

	_inventory_button = TouchActionButton.new()
	_inventory_button.action = "open_inventory"
	_inventory_button.caption = "Pack"
	_inventory_button.icon_kind = "backpack"
	_inventory_button.accent = Color("#c59b64")
	_inventory_button.diameter = 64
	_inventory_button.position = Vector2(24, 160)
	_root.add_child(_inventory_button)

	_build_button = TouchActionButton.new()
	_build_button.action = "toggle_build"
	_build_button.caption = "Build"
	_build_button.icon_kind = "hammer"
	_build_button.accent = Color("#79b98d")
	_build_button.diameter = 64
	_build_button.position = Vector2(96, 160)
	_root.add_child(_build_button)

	_health_potion_button = TouchActionButton.new()
	_health_potion_button.action = "use_health_potion"
	_health_potion_button.caption = "HP"
	_health_potion_button.icon_kind = "health_potion"
	_health_potion_button.accent = Color("#d45a61")
	_health_potion_button.diameter = 58
	_anchor_bottom_right(_health_potion_button, Vector2(-158, -180), Vector2(-100, -122))
	_root.add_child(_health_potion_button)
	_hp_count = GameUI.label("x2", 11, GameUI.TEXT)
	_hp_count.anchor_left = 1.0
	_hp_count.anchor_top = 1.0
	_hp_count.anchor_right = 1.0
	_hp_count.anchor_bottom = 1.0
	_hp_count.offset_left = -140
	_hp_count.offset_right = -110
	_hp_count.offset_top = -184
	_hp_count.offset_bottom = -166
	_hp_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(_hp_count)

	_mana_potion_button = TouchActionButton.new()
	_mana_potion_button.action = "use_mana_potion"
	_mana_potion_button.caption = "MP"
	_mana_potion_button.icon_kind = "mana_potion"
	_mana_potion_button.accent = Color("#608fd9")
	_mana_potion_button.diameter = 58
	_anchor_bottom_right(_mana_potion_button, Vector2(-226, -112), Vector2(-168, -54))
	_root.add_child(_mana_potion_button)
	_mp_count = GameUI.label("x1", 11, GameUI.TEXT)
	_mp_count.anchor_left = 1.0
	_mp_count.anchor_top = 1.0
	_mp_count.anchor_right = 1.0
	_mp_count.anchor_bottom = 1.0
	_mp_count.offset_left = -208
	_mp_count.offset_right = -178
	_mp_count.offset_top = -116
	_mp_count.offset_bottom = -98
	_mp_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(_mp_count)
	# Badges are drawn on the potion buttons themselves now.
	_hp_count.visible = false
	_mp_count.visible = false
	_control_nodes = {
		"joystick": _joystick,
		"attack": _attack_button,
		"interact": _interact_button,
		"inventory": _inventory_button,
		"build": _build_button,
		"health_potion": _health_potion_button,
		"mana_potion": _mana_potion_button,
	}
	_default_transforms.clear()
	for control_id in _control_nodes:
		var node := _control_nodes[control_id] as Control
		var entry := {
			"anchor_left": node.anchor_left,
			"anchor_top": node.anchor_top,
			"anchor_right": node.anchor_right,
			"anchor_bottom": node.anchor_bottom,
			"offset_left": node.offset_left,
			"offset_top": node.offset_top,
			"offset_right": node.offset_right,
			"offset_bottom": node.offset_bottom,
		}
		if node is TouchActionButton:
			entry["diameter"] = (node as TouchActionButton).diameter
		_default_transforms[control_id] = entry


func _apply_saved_settings() -> void:
	var saved := GameState.control_layout()
	if not saved.is_empty():
		_apply_control_layout(saved)
	_apply_gui_scale(GameState.gui_scale())


func get_gui_scale() -> float:
	return _root.scale.x if _root != null else 1.0


func set_gui_scale(value: float) -> void:
	var clamped := clampf(value, 0.75, 1.3)
	_apply_gui_scale(clamped)
	GameState.set_gui_scale(clamped)


func _apply_gui_scale(value: float) -> void:
	if _root == null:
		return
	_root.pivot_offset = _root.size * 0.5
	_root.scale = Vector2(value, value)


func get_control_layout_current() -> Dictionary:
	var result: Dictionary = {}
	for control_id in _control_nodes:
		var node := _control_nodes[control_id] as Control
		if node == null:
			continue
		var node_size := node.size.x
		if node is TouchActionButton:
			node_size = (node as TouchActionButton).diameter
		result[control_id] = {"x": node.position.x, "y": node.position.y, "size": node_size}
	return result


func set_control_layout(control_id: String, x: float, y: float, control_size: float) -> void:
	GameState.set_control_layout(control_id, x, y, control_size)
	_apply_control(control_id, x, y, control_size)


func reset_control_layout() -> void:
	GameState.reset_control_layout()
	_restore_default_control_layout()


func _restore_default_control_layout() -> void:
	for control_id in _default_transforms:
		var node := _control_nodes.get(control_id) as Control
		if node == null:
			continue
		var entry: Dictionary = _default_transforms[control_id]
		node.anchor_left = float(entry.get("anchor_left", 0.0))
		node.anchor_top = float(entry.get("anchor_top", 0.0))
		node.anchor_right = float(entry.get("anchor_right", 0.0))
		node.anchor_bottom = float(entry.get("anchor_bottom", 0.0))
		node.offset_left = float(entry.get("offset_left", 0.0))
		node.offset_top = float(entry.get("offset_top", 0.0))
		node.offset_right = float(entry.get("offset_right", 0.0))
		node.offset_bottom = float(entry.get("offset_bottom", 0.0))
		if node is TouchActionButton and entry.has("diameter"):
			var button := node as TouchActionButton
			button.diameter = float(entry["diameter"])
			button.custom_minimum_size = Vector2(button.diameter, button.diameter)
		elif node is TouchJoystick:
			var joystick := node as TouchJoystick
			joystick.radius = 72.0
			joystick.knob_radius = 30.0
			joystick.custom_minimum_size = Vector2(190, 190)
			joystick.queue_redraw()
		node.queue_redraw()


func _apply_control_layout(saved: Dictionary) -> void:
	for control_id in saved:
		if not DEFAULT_CONTROL_LAYOUT.has(control_id) or not _control_nodes.has(control_id):
			continue
		var values: Dictionary = (DEFAULT_CONTROL_LAYOUT[control_id] as Dictionary).duplicate()
		var override: Dictionary = saved[control_id]
		for key in override:
			values[key] = override[key]
		_apply_control(control_id, float(values.get("x", 0.0)), float(values.get("y", 0.0)), float(values.get("size", 80.0)))


func _apply_control(control_id: String, x: float, y: float, control_size: float) -> void:
	var node: Control = _control_nodes.get(control_id) as Control
	if node == null:
		return
	node.anchor_left = 0.0
	node.anchor_top = 0.0
	node.anchor_right = 0.0
	node.anchor_bottom = 0.0
	node.position = Vector2(x, y)
	node.size = Vector2(control_size, control_size)
	node.custom_minimum_size = Vector2(control_size, control_size)
	if node is TouchActionButton:
		(node as TouchActionButton).diameter = control_size
	elif node is TouchJoystick:
		var joystick := node as TouchJoystick
		joystick.radius = control_size * 0.38
		joystick.knob_radius = control_size * 0.16
		joystick.queue_redraw()


func _build_prompt() -> void:
	_prompt_panel = GameUI.panel(Color(0.035, 0.08, 0.09, 0.9), Color("#628487"))
	_prompt_panel.anchor_left = 0.5
	_prompt_panel.anchor_right = 0.5
	_prompt_panel.anchor_top = 1.0
	_prompt_panel.anchor_bottom = 1.0
	_prompt_panel.offset_left = -230
	_prompt_panel.offset_right = 230
	_prompt_panel.offset_top = -72
	_prompt_panel.offset_bottom = -24
	_prompt_panel.visible = false
	_root.add_child(_prompt_panel)
	_prompt_label = GameUI.label("", 15, GameUI.TEXT)
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_panel.add_child(_prompt_label)

	_loot_label = GameUI.label("", 12, GameUI.GOLD)
	_loot_label.anchor_left = 1.0
	_loot_label.anchor_right = 1.0
	_loot_label.anchor_top = 1.0
	_loot_label.anchor_bottom = 1.0
	_loot_label.offset_left = -360
	_loot_label.offset_right = -22
	_loot_label.offset_top = -286
	_loot_label.offset_bottom = -260
	_loot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_root.add_child(_loot_label)


func _build_sleep_panel() -> void:
	_sleep_panel = GameUI.panel(Color(0.035, 0.08, 0.09, 0.94), Color("#6d8d72"))
	_sleep_panel.anchor_left = 0.5
	_sleep_panel.anchor_right = 0.5
	_sleep_panel.offset_left = -220
	_sleep_panel.offset_right = 220
	_sleep_panel.offset_top = 190
	_sleep_panel.offset_bottom = 274
	_sleep_panel.visible = false
	_root.add_child(_sleep_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	_sleep_panel.add_child(box)
	_sleep_label = GameUI.label("Sleeping... 0%", 16, GameUI.TEXT)
	_sleep_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_sleep_label)
	_sleep_bar = SegmentedBar.new()
	_sleep_bar.setup("REST", GameUI.GREEN, 10, true)
	box.add_child(_sleep_bar)


func _build_recovery_panel() -> void:
	_recovery_panel = GameUI.panel(Color(0.035, 0.09, 0.07, 0.94), Color("#5f9b79"))
	_recovery_panel.anchor_left = 0.5
	_recovery_panel.anchor_right = 0.5
	_recovery_panel.offset_left = -220
	_recovery_panel.offset_right = 220
	_recovery_panel.offset_top = 190
	_recovery_panel.offset_bottom = 266
	_recovery_panel.visible = false
	_root.add_child(_recovery_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	_recovery_panel.add_child(box)
	_recovery_label = GameUI.label("RECOVERY WARD", 15, Color("#a8f2cf"))
	_recovery_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_recovery_label)
	_recovery_bar = SegmentedBar.new()
	_recovery_bar.setup("RECOVERY", Color("#70d69a"), 10, true)
	box.add_child(_recovery_bar)


func _build_tutorial() -> void:
	tutorial_guide = TutorialGuide.new()
	tutorial_guide.name = "TutorialGuide"
	_root.add_child(tutorial_guide)


func _build_modals() -> void:
	shop_panel = ShopPanel.new()
	_root.add_child(shop_panel)
	inventory_panel = InventoryPanel.new()
	_root.add_child(inventory_panel)
	portal_panel = PortalPanel.new()
	_root.add_child(portal_panel)
	pet_battle_panel = PetBattlePanel.new()
	_root.add_child(pet_battle_panel)
	sea_cleaning_panel = SeaCleaningPanel.new()
	_root.add_child(sea_cleaning_panel)
	house_panel = HousePanel.new()
	_root.add_child(house_panel)
	victory_panel = VictoryPanel.new()
	_root.add_child(victory_panel)
	defeat_panel = DefeatPanel.new()
	_root.add_child(defeat_panel)
	menu_panel = MenuPanel.new()
	_root.add_child(menu_panel)
	settings_panel = SettingsPanel.new()
	_root.add_child(settings_panel)
	dialogue_panel = DialoguePanel.new()
	_root.add_child(dialogue_panel)
	game_over_panel = GameOverPanel.new()
	_root.add_child(game_over_panel)


func _build_fade() -> void:
	_vignette = TextureRect.new()
	_vignette.texture = PixelArt.vignette_texture()
	_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vignette.stretch_mode = TextureRect.STRETCH_SCALE
	_vignette.modulate.a = 0.0
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_vignette)
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.modulate.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_fade)


func _anchor_bottom_right(ctrl: Control, top_left_from_corner: Vector2, bottom_right_from_corner: Vector2) -> void:
	ctrl.anchor_left = 1.0
	ctrl.anchor_right = 1.0
	ctrl.anchor_top = 1.0
	ctrl.anchor_bottom = 1.0
	ctrl.offset_left = top_left_from_corner.x
	ctrl.offset_top = top_left_from_corner.y
	ctrl.offset_right = bottom_right_from_corner.x
	ctrl.offset_bottom = bottom_right_from_corner.y


# ------------------------------------------------------------------ frame updates

func _process(delta: float) -> void:
	if not visible:
		return
	_clock_label.text = GameState.time_string()
	_clock_label.add_theme_color_override("font_color", GameUI.GOLD)
	_loot_timer += delta
	if _loot_timer > 0.25:
		_loot_timer = 0.0
		_refresh_loot()
	if _attack_button:
		var combatant := get_tree().get_first_node_in_group("player")
		if combatant != null and is_instance_valid(combatant) and combatant.has_method("cooldown_fraction"):
			_attack_button.set_cooldown(float(combatant.call("cooldown_fraction")))
		else:
			_attack_button.set_cooldown(0.0)
	_mission_timer += delta
	if _mission_timer > 0.2:
		_mission_timer = 0.0
		_update_mission_guide()
	_refresh_recovery()
	_update_prompt()
	if any_modal_open() or _sleep_panel.visible:
		return
	if Input.is_action_just_pressed("open_inventory"):
		inventory_requested.emit()
	elif Input.is_action_just_pressed("toggle_build"):
		build_mode_requested.emit()
	elif Input.is_action_just_pressed("use_health_potion"):
		_use_quick_potion("health_potion")
	elif Input.is_action_just_pressed("use_mana_potion"):
		_use_quick_potion("mana_potion")


func _update_prompt() -> void:
	var prompt := ""
	var player := get_tree().get_first_node_in_group("player")
	if player != null and player.get("nearby") != null and is_instance_valid(player.get("nearby")):
		var near: Node = player.get("nearby")
		if near.has_method("get_prompt"):
			prompt = str(near.call("get_prompt"))
	if prompt != _last_prompt:
		_last_prompt = prompt
		_prompt_panel.visible = prompt != ""
		_prompt_label.text = "✦  " + prompt
		if _interact_button:
			if prompt.length() > 0:
				var short := prompt.split(" ")[0]
				_interact_button.set_contextual(short.trim_suffix("."), _prompt_icon_kind(prompt))
			else:
				_interact_button.set_contextual("Use", "spark")


func _use_quick_potion(item_id: String) -> void:
	GameState.consume_item(item_id)


func set_world(w: Node) -> void:
	world = w
	_last_prompt = ""
	if _interact_button:
		_interact_button.set_contextual("Use", "spark")
	_prompt_panel.visible = false
	_boss_panel.visible = false
	_sleep_panel.visible = false
	var zone_label := _objective_panel.find_child("ZoneLabel", true, false) as Label
	if zone_label and w != null:
		zone_label.text = str(w.get("zone_name"))
	_on_emergency_changed(GameState.emergency_active(), GameState.emergency_monsters(), GameState.emergency_damage())
	refresh_all()


func refresh_all() -> void:
	if _root == null:
		return
	_identity_label.text = "%s  •  Lv %d" % [str(GameState.data.character_name), int(GameState.data.level)]
	_gold_label.text = str(GameState.gold())
	_diamond_label.text = str(GameState.diamonds())
	_health_bar.set_values(GameState.health(), GameState.health_max())
	_mana_bar.set_values(GameState.mana(), GameState.mana_max())
	_xp_bar.set_values(int(GameState.data.get("xp", 0)), int(GameState.data.get("xp_next", 60)))
	_refresh_pet()
	_refresh_objectives()
	_refresh_loot()
	_hp_count.text = "x%d" % GameState.item_count("health_potion")
	_mp_count.text = "x%d" % GameState.item_count("mana_potion")
	# Count badges live on the buttons now; the old floating labels stay hidden.
	if _health_potion_button:
		_health_potion_button.set_badge("x%d" % GameState.item_count("health_potion") if GameState.item_count("health_potion") > 0 else "")
	if _mana_potion_button:
		_mana_potion_button.set_badge("x%d" % GameState.item_count("mana_potion") if GameState.item_count("mana_potion") > 0 else "")
	# The Strike icon follows the active hero's weapon discipline.
	if _attack_button:
		_attack_button.set_icon(GameState.character_weapon_style())
	var vitals := _root.find_child("VitalsStats", true, false)
	if vitals is Label:
		vitals.text = "ATK %d  •  DEF %d  •  SH %d" % [GameState.attack_power(), GameState.defense(), GameState.shield()]


func _refresh_pet() -> void:
	var pet := GameState.get_active_pet()
	if pet.is_empty():
		_pet_name.text = "No companion"
		_pet_bar.set_values(0, 1)
		_pet_xp_bar.set_caption("PET XP")
		_pet_xp_bar.set_values(0, 1)
		_pet_icon.texture = null
		return
	_pet_icon.texture = PixelArt.pet_texture(str(pet.id))
	_pet_name.text = "%s  Lv %d  •  %s" % [PetDB.name_of(str(pet.id)), int(pet.level), "Support" if bool(pet.alive) else "RECOVERING"]
	_pet_name.add_theme_color_override("font_color", GameUI.MUTED if bool(pet.alive) else GameUI.RED)
	_pet_bar.set_values(int(pet.hp), int(pet.hp_max))
	_pet_bar.fill_color = GameUI.GOLD if bool(pet.alive) else Color("#5d4a45")
	var pet_xp := GameState.pet_xp_progress()
	if bool(pet_xp.get("max", false)):
		_pet_xp_bar.set_caption("PET XP MAX")
		_pet_xp_bar.set_values(1, 1)
	else:
		_pet_xp_bar.set_caption("PET XP")
		_pet_xp_bar.set_values(int(pet_xp.get("xp", 0)), int(pet_xp.get("next", 1)))


func _refresh_objectives() -> void:
	var lines := GameState.objective_lines()
	var joined := "\n".join(lines)
	if joined == _last_objectives:
		return
	_last_objectives = joined
	for child in _objectives_box.get_children():
		child.queue_free()
	for line in lines:
		var label := GameUI.label("◆  " + line, 12, GameUI.TEXT)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_objectives_box.add_child(label)


func _refresh_loot() -> void:
	if _loot_label == null:
		return
	if GameState.expedition_active():
		_loot_label.text = GameState.expedition_loot_summary()
		_loot_label.visible = true
	else:
		_loot_label.visible = false


func _on_boss_health(active: bool, boss_name: String, value: int, maximum: int) -> void:
	_boss_panel.visible = active
	if active:
		_boss_label.text = boss_name.to_upper()
		_boss_bar.set_values(value, maximum)
	_update_toast_layout()


func _update_toast_layout() -> void:
	# Notifications were removed. Panels such as the boss bar manage their own layout.
	pass


func _on_emergency_changed(active: bool, remaining: int, damage: int) -> void:
	if _emergency_panel == null:
		return
	_emergency_panel.visible = active
	if active:
		_emergency_label.text = "SETTLEMENT UNDER ATTACK  •  %d monsters  •  damage %d%%" % [remaining, damage]
	_boss_panel.offset_top = 148 if active else 100
	_boss_panel.offset_bottom = 216 if active else 168
	_update_toast_layout()


func _refresh_recovery() -> void:
	if _recovery_panel == null:
		return
	var active := GameState.recovery_active()
	_recovery_panel.visible = active
	if not active:
		return
	var pct := int(round(GameState.recovery_progress() * 100.0))
	_recovery_label.text = "RECOVERY WARD  •  %d%%" % pct
	_recovery_bar.set_values(pct, 100)


func set_sleep_state(active: bool, progress: float, label: String) -> void:
	_sleep_panel.visible = active
	if active:
		_sleep_label.text = label
		_sleep_bar.set_values(int(progress * 10.0), 10)


func _prompt_icon_kind(prompt: String) -> String:
	# Context-sensitive Use icon: talk / door / bed / gather / spark.
	var verb := prompt.split(" ")[0]
	match verb:
		"Talk":
			return "talk"
		"Enter", "Open", "Return":
			return "door"
		"Sleep":
			return "bed"
		"Gather":
			return "gather"
	return "spark"


func _show_key_hints() -> bool:
	# Keycaps only when the player is not on a touch layout.
	var mode := GameSettings.touch_controls()
	if mode == "always":
		return false
	if mode == "hidden":
		return true
	return not DisplayServer.is_touchscreen_available()


func _key_for_action(action_name: String) -> String:
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey:
			var code := (event as InputEventKey).physical_keycode
			if code != 0:
				return OS.get_keycode_string(code)
	return ""


func _apply_touch_mode() -> void:
	# Joystick hides on pure-keyboard layouts; buttons stay (they double as
	# clickable targets) and gain keycap hints sourced from the InputMap.
	var mode := GameSettings.touch_controls()
	var show_touch := mode == "always" or (mode == "auto" and DisplayServer.is_touchscreen_available())
	if _joystick:
		_joystick.visible = show_touch
	var hints := _show_key_hints()
	for pair in [["attack", _attack_button], ["interact", _interact_button], ["open_inventory", _inventory_button], ["toggle_build", _build_button], ["use_health_potion", _health_potion_button], ["use_mana_potion", _mana_potion_button]]:
		var button := pair[1] as TouchActionButton
		if button == null:
			continue
		button.set_key_hint(_key_for_action(pair[0]) if hints else "")


func _on_setting_changed(key: String) -> void:
	if key == "touch_controls":
		_apply_touch_mode()


func flash_hurt() -> void:
	# Player-damage vignette: an additional listener next to the camera shake.
	if _vignette == null:
		return
	if GameSettings.reduce_motion():
		_vignette.modulate.a = 0.25
		var quick := create_tween()
		quick.tween_property(_vignette, "modulate:a", 0.0, 0.3)
		return
	_vignette.modulate.a = 0.55
	var tween := create_tween()
	tween.tween_property(_vignette, "modulate:a", 0.12, 0.12)
	tween.tween_property(_vignette, "modulate:a", 0.0, 0.4)


func show_toast(_text: String, _tone: String = "info") -> void:
	# In-world notifications are intentionally disabled. Important state lives
	# in persistent HUD panels and the journal instead of timed pop-ups.
	pass


func start_tutorial() -> void:
	if tutorial_guide != null:
		tutorial_guide.start()


func set_build_mode(active: bool) -> void:
	_build_mode_panel.visible = active
	if _build_button:
		_build_button.caption = "Done" if active else "Build"


func any_modal_open() -> bool:
	for panel in [shop_panel, inventory_panel, portal_panel, pet_battle_panel, sea_cleaning_panel, house_panel, victory_panel, defeat_panel, menu_panel, settings_panel, dialogue_panel, game_over_panel]:
		if panel != null and panel.visible:
			return true
	return false


func hide_modals() -> void:
	for panel in [shop_panel, inventory_panel, portal_panel, pet_battle_panel, sea_cleaning_panel, house_panel, victory_panel, defeat_panel, menu_panel, settings_panel, dialogue_panel, game_over_panel]:
		if panel != null and panel.visible:
			panel.close_panel()


func fade_to_black(duration: float = 0.25) -> void:
	_fade.visible = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	_fade.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", 1.0, duration)
	await tween.finished


func fade_from_black(duration: float = 0.3) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", 0.0, duration)
	await tween.finished
	_fade.visible = false
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
