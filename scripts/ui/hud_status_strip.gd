class_name HudStatusStrip
extends Control
## Two framed sections: combined balances and combined live world tallies.
signal height_changed
const FONT_SIZE := 18
const HEIGHT := 34.0
var gold_label: Label
var diamond_label: Label
var _currency_panel: PanelContainer
var _stats_panel: PanelContainer
var _currency_row: HBoxContainer
var _stats_flow: HFlowContainer
var _available_width := 1000.0
var _chips: Dictionary = {}
var _labels: Dictionary = {}
var counts: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_currency_panel = _section("CurrencySection")
	_currency_row = HBoxContainer.new()
	_currency_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_currency_row.add_theme_constant_override("separation", 6)
	_currency_panel.add_child(_currency_row)
	_stats_panel = _section("StatsSection")
	_stats_flow = HFlowContainer.new()
	_stats_flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stats_flow.add_theme_constant_override("h_separation", 6)
	_stats_flow.add_theme_constant_override("v_separation", 4)
	_stats_flow.minimum_size_changed.connect(_sync_height)
	_stats_panel.add_child(_stats_flow)
	for kind in ["gold", "diamond"]:
		var chip := _chip(kind, 106 if kind == "gold" else 98, _currency_row)
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 5)
		chip.add_child(row)
		var icon := GameUI.icon_rect(kind, 18)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
		var label := GameUI.label("0", FONT_SIZE, GameUI.GOLD if kind == "gold" else GameUI.DIAMOND)
		label.mouse_filter = Control.MOUSE_FILTER_PASS
		row.add_child(label)
		if kind == "gold": gold_label = label
		else: diamond_label = label
	for entry in [["npc", 108], ["monsters", 105], ["trees", 114], ["fires", 66], ["homes", 118]]:
		var chip := _chip(str(entry[0]), int(entry[1]), _stats_flow)
		var label := GameUI.label("", FONT_SIZE)
		label.mouse_filter = Control.MOUSE_FILTER_PASS
		chip.add_child(label)
		_labels[entry[0]] = label
	refresh_currency()
	refresh_world(null)

func _section(section_name: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = section_name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := GameUI.style(Color(0.035, 0.08, 0.09, 0.9), Color("#3a565a"), 1)
	style.content_margin_left = 1
	style.content_margin_right = 1
	style.content_margin_top = 1
	style.content_margin_bottom = 1
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	return panel

func _chip(id: String, width: int, parent: Container) -> MarginContainer:
	# Cells have padding only; their shared section owns the single frame.
	var panel := MarginContainer.new()
	panel.name = id.capitalize() + "Count"
	panel.custom_minimum_size = Vector2(width, HEIGHT - 2)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for edge in ["left", "right"]: panel.add_theme_constant_override("margin_" + edge, 4 if parent == _stats_flow else 8)
	for edge in ["top", "bottom"]: panel.add_theme_constant_override("margin_" + edge, 4)
	parent.add_child(panel)
	_chips[id] = panel
	return panel

static func compact_amount(value: int) -> String:
	if value < 10000: return str(value)
	for unit in [[1000000000, "B"], [1000000, "M"], [1000, "K"]]:
		if value >= int(unit[0]):
			return ("%.1f" % (floorf(float(value) / float(unit[0]) * 10) / 10)).trim_suffix(".0") + str(unit[1])
	return str(value)

func refresh_currency() -> void:
	gold_label.text = compact_amount(GameState.gold())
	diamond_label.text = compact_amount(GameState.diamonds())
	gold_label.tooltip_text = "%d Gold" % GameState.gold()
	diamond_label.tooltip_text = "%d Diamonds" % GameState.diamonds()

func refresh_world(world: Node) -> void:
	counts = WorldTally.snapshot(world)
	var village := bool(counts.get("village", false))
	for id in _labels:
		_chips[id].visible = not counts.is_empty() and (village or id == "monsters")
	_stats_panel.visible = not counts.is_empty()
	call_deferred("_arrange_sections")
	if counts.is_empty(): return
	_set_count("npc", "NPC %d/%d" % [counts.npc_alive, counts.npc_total], GameUI.TEXT if counts.npc_alive == counts.npc_total else GameUI.RED)
	_set_count("monsters", "Monsters %d" % counts.monsters, GameUI.RED if counts.monsters > 0 else GameUI.TEXT)
	_set_count("trees", "Trees %d/%d" % [counts.trees_alive, counts.trees_total], GameUI.GREEN if counts.trees_alive == counts.trees_total else GameUI.GOLD)
	_set_count("fires", "Fire %d" % counts.fires, GameUI.GOLD if counts.fires > 0 else GameUI.TEXT)
	_set_count("homes", "Homes %d/%d" % [counts.homes_intact, counts.homes_total], GameUI.TEXT if counts.homes_intact > 0 else GameUI.RED)
	_labels.npc.tooltip_text = "Living people, including sheltered villagers and service NPCs. Workers: %d/%d." % [counts.workers_alive, counts.workers_total]
	_labels.trees.tooltip_text = "Living trees include %d protected saplings. Fallen trees remain in the total." % counts.saplings
	_labels.monsters.tooltip_text = "Living monsters in this world, including bosses. Fire monsters: %d; sea urchins: %d." % [counts.fire_monsters, counts.urchins]
	_labels.homes.tooltip_text = "Intact houses / all repairable house sites, including the cottage and ruins. Fences are excluded."
	_labels.fires.tooltip_text = "Mature trees currently burning."

func _set_count(id: String, text: String, color: Color) -> void:
	var label := _labels[id] as Label
	if label.text != text: label.text = text
	label.add_theme_color_override("font_color", color)

func fit(available_width: float, factor: float, display_scale: float) -> void:
	# Keep text at least 12 physical pixels when the logical canvas is stretched.
	var zoom := maxf(factor, 12.0 / (FONT_SIZE * maxf(0.1, display_scale)))
	scale = Vector2.ONE * zoom
	size.x = maxf(140, available_width / zoom)
	_available_width = size.x
	_arrange_sections()
	call_deferred("_sync_height")

func _arrange_sections() -> void:
	_currency_panel.position = Vector2.ZERO
	_currency_panel.size = _currency_panel.get_combined_minimum_size()
	var natural_width := 2.0
	var visible_cells := 0
	for id in _labels:
		if not _chips[id].visible: continue
		natural_width += _chips[id].get_combined_minimum_size().x
		visible_cells += 1
	natural_width += maxf(0, visible_cells - 1) * 6
	_stats_panel.size.x = minf(natural_width, _available_width)
	var beside := _currency_panel.size.x + 12 + _stats_panel.size.x <= _available_width
	_stats_panel.position = Vector2(_currency_panel.size.x + 12, 0) if beside else Vector2(0, _currency_panel.size.y + 5)
	_sync_height()

func _sync_height() -> void:
	_stats_panel.size.y = maxf(HEIGHT, _stats_panel.get_combined_minimum_size().y)
	var height := maxf(HEIGHT, _currency_panel.size.y)
	if _stats_panel.visible: height = maxf(height, _stats_panel.position.y + _stats_panel.size.y)
	if not is_equal_approx(size.y, height):
		size.y = height
		height_changed.emit()
