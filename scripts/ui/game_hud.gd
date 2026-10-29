class_name GameHUD
extends CanvasLayer
## Persistent mobile HUD and the owner of every modal panel.

signal inventory_requested
signal build_mode_requested
signal menu_requested

const DEFAULT_CONTROL_LAYOUT := {
	"joystick": {"x": 20.0, "y": 514.0, "size": 190.0},
	"attack": {"x": 1148.0, "y": 586.0, "size": 102.0},
	"interact": {"x": 1190.0, "y": 486.0, "size": 82.0},
	"inventory": {"x": 24.0, "y": 160.0, "size": 64.0},
	"build": {"x": 96.0, "y": 160.0, "size": 64.0},
	"menu": {"x": 1166.0, "y": 18.0, "size": 64.0},
	"ocean_joystick": {"x": 24.0, "y": 510.0, "size": 180.0},
	"ocean_pickup": {"x": 1144.0, "y": 588.0, "size": 104.0},
	"health_potion": {"x": 1055.0, "y": 510.0, "size": 58.0},
}

var world: Node = null
var shop_panel: ShopPanel
var inventory_panel: InventoryPanel
var portal_panel: PortalPanel
var pet_battle_panel: PetBattlePanel
var wild_challenge: WildPetChallenge
var sea_cleaning_panel: SeaCleaningPanel
var house_panel: HousePanel
var victory_panel: VictoryPanel
var defeat_panel: DefeatPanel
var field_guide_panel: FieldGuidePanel
var map_panel: WorldMapPanel
var mission_panel: MissionPanel
var tutorial_guide: TutorialGuide
var menu_panel: MenuPanel
var settings_panel: SettingsPanel
var dialogue_panel: DialoguePanel
var game_over_panel: GameOverPanel
var village_services_panel: VillageServicesPanel

var _gui_layout: Dictionary = {}
var _root: Control
var _gold_label: Label
var _diamond_label: Label
var _identity_label: Label
var _clock_label: Label
var _minimap: VillageMinimap
var _map_button: Button
var _xp_bar: SegmentedBar
var _pet_xp_bar: SegmentedBar
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
var _hp_count: Label
var _build_mode_panel: PanelContainer
var _menu_button: Button
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
	_build_currency_panel()
	_build_minimap()
	_build_objectives()
	_build_mission_guide()
	_build_emergency_panel()
	_build_build_mode_panel()
	_build_boss_bar()
	_build_controls()
	_build_prompt()
	_build_sleep_panel()
	_build_recovery_panel()
	_build_tutorial()
	_build_modals()
	_build_fade()
	_capture_gui_layout()
	_apply_saved_settings()
	_root.resized.connect(_layout_gui)
	get_window().size_changed.connect(_schedule_gui_layout)
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


func _build_currency_panel() -> void:
	var balances := GameUI.panel(Color(0.035, 0.08, 0.09, 0.9), Color("#3a565a"))
	balances.name = "CurrencyPanel"
	balances.offset_left = 22
	balances.offset_right = 366
	balances.offset_top = 18
	balances.offset_bottom = 66
	balances.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(balances)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	balances.add_child(row)
	for kind in ["gold", "diamond"]:
		var amount := HBoxContainer.new()
		amount.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		amount.add_theme_constant_override("separation", 7)
		amount.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(amount)
		var icon := GameUI.icon_rect(kind, 24)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		amount.add_child(icon)
		var label := GameUI.label("", 19, GameUI.GOLD if kind == "gold" else GameUI.DIAMOND)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.clip_text = true
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		amount.add_child(label)
		if kind == "gold":
			_gold_label = label
		else:
			_diamond_label = label
	var clock := GameUI.panel(Color(0.035, 0.08, 0.09, 0.85), Color("#3a565a"))
	clock.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	clock.offset_left = -110
	clock.offset_right = 110
	clock.offset_top = -45
	clock.offset_bottom = -5
	_root.add_child(clock)
	_clock_label = GameUI.label(GameState.time_string(), 18, GameUI.GOLD)
	_clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clock.add_child(_clock_label)

func _build_objectives() -> void:
	pass

func _build_mission_guide() -> void:
	# Navigation is drawn on world paths; no bottom notification strip.
	pass


func _update_mission_guide() -> void:
	pass

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
	var label := GameUI.label("BUILD  •  drag buildings  •  Menu > Finish building to exit", 13, Color("#b8f0c8"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_build_mode_panel.add_child(label)


func _build_boss_bar() -> void:
	pass

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
	_attack_button.caption = "Attack"
	_attack_button.icon_kind = "sword"
	_attack_button.accent = Color("#e1a34f")
	_attack_button.diameter = 102
	_anchor_bottom_right(_attack_button, Vector2(-132, -134), Vector2(-30, -32))
	_root.add_child(_attack_button)

	_interact_button = TouchActionButton.new()
	_interact_button.action = "sprint"
	_interact_button.caption = "Sprint"
	_interact_button.icon_kind = "sprint"
	_interact_button.accent = Color("#61c9ba")
	_interact_button.diameter = 82
	_anchor_bottom_right(_interact_button, Vector2(-88, -234), Vector2(-6, -152))
	_root.add_child(_interact_button)

	_inventory_button = TouchActionButton.new()
	_inventory_button.action = "open_inventory"
	_inventory_button.caption = "Pack"
	_inventory_button.icon_kind = "backpack"
	_inventory_button.accent = Color("#c59b64")
	_inventory_button.diameter = 64
	_inventory_button.anchor_top = 1.0
	_inventory_button.anchor_bottom = 1.0
	_inventory_button.position = Vector2(235, -94)
	_root.add_child(_inventory_button)

	_control_nodes = {"joystick": _joystick, "attack": _attack_button, "interact": _interact_button, "inventory": _inventory_button, "menu": _menu_button}
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
			"size": node.size.max(node.get_combined_minimum_size()),
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
	return GameState.gui_scale()


func set_gui_scale(value: float, persist: bool = true) -> void:
	GameState.set_gui_scale(value, persist)
	_layout_gui()


func _capture_gui_layout() -> void:
	for child in _root.get_children():
		if child is Control and not child is ModalBase and not child is WildPetChallenge and not child is TutorialSpotlight and child != tutorial_guide and child != _fade and child != _vignette:
			_gui_layout[child] = {"left": child.offset_left, "top": child.offset_top, "size": child.size.max(child.get_combined_minimum_size())}


func _apply_gui_scale(_value: float) -> void:
	_layout_gui()


func _layout_gui() -> void:
	if _root == null:
		return
	# Each element retains its own anchor. Root and full-screen overlays never scale.
	_root.scale = Vector2.ONE
	var fit := minf(1.0, minf(_root.size.x / 1280.0, _root.size.y / 720.0))
	var factor := get_gui_scale() * fit
	var display_scale := 1.0
	if DisplayServer.get_name() != "headless":
		display_scale = minf(float(get_window().size.x) / maxf(1.0, _root.size.x), float(get_window().size.y) / maxf(1.0, _root.size.y))
	for node: Control in _gui_layout:
		if not is_instance_valid(node):
			continue
		var base: Dictionary = _gui_layout[node]
		var base_size: Vector2 = base.size
		var element_factor := factor
		if node in _control_nodes.values():
			element_factor = maxf(factor, 44.0 / maxf(1.0, base_size.x * display_scale))
		elif node == _menu_button or node == _map_button:
			element_factor = maxf(factor, 44.0 / maxf(1.0, base_size.y * display_scale))
		var left := float(base.left) * factor
		var top := float(base.top) * factor
		var control_id: Variant = _control_nodes.find_key(node)
		if control_id != null and GameState.control_layout().has(control_id):
			left = float(base.left)
			top = float(base.top)
		# Fit center journal and mission guide between edge controls at large scales.
		if node == _objective_panel:
			var available_width := maxf(230.0, _root.size.x - 2.0 * 330.0 * factor)
			element_factor = minf(factor, available_width / base_size.x)
			left = -base_size.x * element_factor * 0.5
		if node == _mission_panel:
			element_factor = minf(factor, maxf(240.0, _root.size.x - 2.0 * 250.0 * factor) / base_size.x)
			left = -base_size.x * element_factor * 0.5
		# Custom layouts are screen-space positions, clamped when windows shrink.
		var origin := Vector2(node.anchor_left, node.anchor_top) * _root.size + Vector2(left, top)
		origin = origin.clamp(Vector2(6, 6), (_root.size - base_size * element_factor - Vector2(6, 6)).max(Vector2(6, 6)))
		node.offset_left = origin.x - node.anchor_left * _root.size.x
		node.offset_top = origin.y - node.anchor_top * _root.size.y
		node.offset_right = node.offset_left + base_size.x
		node.offset_bottom = node.offset_top + base_size.y
		node.pivot_offset = Vector2.ZERO
		node.scale = Vector2.ONE * element_factor
	if is_instance_valid(_map_button) and is_instance_valid(_menu_button):
		var extent := _map_button.size*_map_button.scale
		var below := _menu_button.position.y+_menu_button.size.y*_menu_button.scale.y+8.0/maxf(0.1,display_scale)
		_map_button.position=Vector2(_menu_button.position.x,below).clamp(Vector2(6,6),(_root.size-extent-Vector2(6,6)).max(Vector2(6,6)))

	if _inventory_button and _build_button and not GameState.control_layout().has("inventory") and not GameState.control_layout().has("build"):
		var pack_right := _inventory_button.position.x + _inventory_button.size.x * _inventory_button.scale.x
		var build_left := maxf(_build_button.position.x, pack_right + 8.0 / maxf(0.1, display_scale))
		_build_button.position.x = build_left


func get_control_layout_current() -> Dictionary:
	var result: Dictionary = {}
	for control_id in _control_nodes:
		var node := _control_nodes[control_id] as Control
		if node == null:
			continue
		var node_size := node.size.x
		if node is TouchActionButton:
			node_size = (node as TouchActionButton).diameter
		var base: Dictionary = _gui_layout.get(node, {})
		result[control_id] = {"x": node.anchor_left * _root.size.x + float(base.get("left", node.offset_left)), "y": node.anchor_top * _root.size.y + float(base.get("top", node.offset_top)), "size": node_size}
	for id in ["ocean_joystick", "ocean_pickup"]:
		result[id] = GameState.control_layout().get(id, DEFAULT_CONTROL_LAYOUT[id]).duplicate()
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
		var default_size: Vector2 = entry.get("size", Vector2(80, 80))
		# Lower minimum size before restoring offsets; otherwise old custom sizes clamp them.
		node.custom_minimum_size = default_size
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
		_gui_layout[node] = {"left": node.offset_left, "top": node.offset_top, "size": default_size}
		node.size = default_size
		node.queue_redraw()
	_layout_gui()


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

	_gui_layout[node] = {"left": x, "top": y, "size": Vector2(control_size, control_size)}
	_layout_gui()


func _build_prompt() -> void:
	_prompt_panel = GameUI.panel(Color(0.035, 0.08, 0.09, 0.9), Color("#628487"))
	_prompt_panel.anchor_left = 0.5
	_prompt_panel.anchor_right = 0.5
	_prompt_panel.anchor_top = 1.0
	_prompt_panel.anchor_bottom = 1.0
	_prompt_panel.offset_left = -230
	_prompt_panel.offset_right = 230
	_prompt_panel.offset_top = -106
	_prompt_panel.offset_bottom = -58
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
	var spotlight := TutorialSpotlight.new()
	spotlight.hud = self
	spotlight.name = "TutorialSpotlight"
	_root.add_child(spotlight)


func _build_modals() -> void:
	map_panel = WorldMapPanel.new()
	_root.add_child(map_panel)
	field_guide_panel = FieldGuidePanel.new()
	_root.add_child(field_guide_panel)
	mission_panel = MissionPanel.new()
	_root.add_child(mission_panel)
	village_services_panel = VillageServicesPanel.new()
	_root.add_child(village_services_panel)
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
	wild_challenge = WildPetChallenge.new()
	_root.add_child(wild_challenge)


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
	var time_text := GameState.time_string()
	if _clock_label.text != time_text:
		_clock_label.text = time_text
		_clock_label.add_theme_color_override("font_color", GameUI.GOLD)
	_loot_timer += delta
	if _loot_timer > 0.25:
		_loot_timer = 0.0
		_refresh_loot()
	if _attack_button:
		var game := get_tree().get_first_node_in_group("game") as Game
		var combatant: Player = game.player() if is_instance_valid(game) else null
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



func _update_prompt() -> void:
	var prompt := ""
	var game := get_tree().get_first_node_in_group("game") as Game
	var player := game.player() if is_instance_valid(game) else null
	if player != null and player.get("nearby") != null and is_instance_valid(player.get("nearby")):
		var near: Node = player.get("nearby")
		if near.has_method("get_prompt"):
			prompt = str(near.call("get_prompt"))
	if prompt != _last_prompt:
		_last_prompt = prompt
		_prompt_label.text = prompt
	_prompt_panel.visible = prompt != "" and not any_modal_open()


func _use_quick_potion(item_id: String) -> void:
	GameState.consume_item(item_id)


func set_world(w: Node) -> void:
	world = w
	_last_prompt = ""
	if _interact_button:
		_interact_button.set_contextual("Sprint", "sprint")
	_prompt_panel.visible = false
	if is_instance_valid(_boss_panel):
		_boss_panel.visible = false
	_sleep_panel.visible = false
	if is_instance_valid(_objective_panel):
		var zone_label := _objective_panel.find_child("ZoneLabel", true, false) as Label
		if zone_label and w != null:
			zone_label.text = str(w.get("zone_name"))
	_on_emergency_changed(GameState.emergency_active(), GameState.emergency_monsters(), GameState.emergency_damage())
	refresh_all()


func refresh_all() -> void:
	if _root == null:
		return
	_gold_label.text = str(GameState.gold())
	_diamond_label.text = str(GameState.diamonds())
	_refresh_objectives()
	_refresh_loot()
	if _attack_button:
		_attack_button.set_icon(GameState.character_weapon_style())

func _refresh_pet() -> void:
	pass

func _refresh_objectives() -> void:
	pass

func _refresh_loot() -> void:
	if is_instance_valid(_loot_label):
		_loot_label.visible = false

func _on_boss_health(_active: bool, _boss_name: String, _value: int, _maximum: int) -> void:
	pass

func _update_toast_layout() -> void:
	# Notifications were removed. Panels such as the boss bar manage their own layout.
	pass


func _on_emergency_changed(active: bool, remaining: int, damage: int) -> void:
	if _emergency_panel == null:
		return
	_emergency_panel.visible = active
	if active:
		_emergency_label.text = "SETTLEMENT UNDER ATTACK  •  %d monsters  •  damage %d%%" % [remaining, damage]
	if is_instance_valid(_boss_panel):
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
		"Pick":
			return "gather"
		"Board":
			return "ship"
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
	for pair in [["attack", _attack_button], ["sprint", _interact_button], ["open_inventory", _inventory_button], ["toggle_build", _build_button], ["use_health_potion", _health_potion_button]]:
		var button := pair[1] as TouchActionButton
		if button == null:
			continue
		button.set_key_hint(_key_for_action(pair[0]) if hints else "")


func _on_setting_changed(key: String) -> void:
	if key == "ui_scale":
		_layout_gui()
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
	if wild_challenge != null and wild_challenge.visible: return true
	if village_services_panel != null and village_services_panel.visible:
		return true
	for panel in [map_panel, field_guide_panel, mission_panel, shop_panel, inventory_panel, portal_panel, pet_battle_panel, sea_cleaning_panel, house_panel, victory_panel, defeat_panel, menu_panel, settings_panel, dialogue_panel, game_over_panel]:
		if panel != null and panel.visible:
			return true
	return false


func hide_modals() -> void:
	if wild_challenge != null and wild_challenge.visible: wild_challenge.close_panel()
	if village_services_panel != null and village_services_panel.visible:
		village_services_panel.close_panel()
	for panel in [map_panel, field_guide_panel, mission_panel, shop_panel, inventory_panel, portal_panel, pet_battle_panel, sea_cleaning_panel, house_panel, victory_panel, defeat_panel, menu_panel, settings_panel, dialogue_panel, game_over_panel]:
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


func _schedule_gui_layout() -> void:
	# Physical window size can change while the stretched logical viewport stays identical.
	call_deferred("_layout_gui")


func release_world_controls() -> void:
	for control in _control_nodes.values():
		if control is TouchActionButton:
			control.cancel()
		elif control is TouchJoystick:
			control.cancel()
	for action in ["attack", "interact", "sprint", "move_left", "move_right", "move_up", "move_down", "open_inventory"]:
		Input.action_release(action)

func _build_minimap() -> void:
	# Preserve the private map-model accessor for existing tools; the HUD shows
	# only a button and performs no continuous compact-map drawing or updates.
	_minimap = VillageMinimap.new()
	_minimap.name = "VillageMinimap"
	_minimap.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_root.add_child(_minimap)
	_minimap.hide()
	_minimap.set_process(false)
	_map_button=GameUI.button("Map",Vector2(92,44))
	_map_button.name="MapButton"
	_map_button.anchor_left=1
	_map_button.anchor_right=1
	_map_button.offset_left=-114
	_map_button.offset_right=-22
	_map_button.offset_top=70
	_map_button.offset_bottom=114
	_map_button.add_theme_font_size_override("font_size",15)
	_map_button.pressed.connect(func() -> void:
		var game := get_tree().get_first_node_in_group("game") as Game
		if is_instance_valid(game): game.open_map())
	_root.add_child(_map_button)
