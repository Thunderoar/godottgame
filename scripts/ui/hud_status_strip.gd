class_name HudStatusStrip
extends Control
## Compact balances followed by live world tallies; rows wrap before edge controls.
signal height_changed
const FONT_SIZE := 18
const HEIGHT := 34.0
var gold_label: Label
var diamond_label: Label
var _flow: HFlowContainer
var _chips: Dictionary = {}
var _labels: Dictionary = {}
var counts: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flow = HFlowContainer.new()
	_flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flow.add_theme_constant_override("h_separation", 6)
	_flow.add_theme_constant_override("v_separation", 5)
	_flow.minimum_size_changed.connect(_sync_height)
	add_child(_flow)
	for kind in ["gold", "diamond"]:
		var chip := _chip(kind, 106 if kind == "gold" else 98)
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
	for entry in [["npc", 118], ["monsters", 115], ["trees", 124], ["fires", 76], ["homes", 128]]:
		var chip := _chip(str(entry[0]), int(entry[1]))
		var label := GameUI.label("", FONT_SIZE)
		label.mouse_filter = Control.MOUSE_FILTER_PASS
		chip.add_child(label)
		_labels[entry[0]] = label
	refresh_currency()
	refresh_world(null)

func _chip(id: String, width: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = id.capitalize() + "Count"
	panel.custom_minimum_size = Vector2(width, HEIGHT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := GameUI.style(Color(0.035, 0.08, 0.09, 0.9), Color("#3a565a"), 1)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", style)
	_flow.add_child(panel)
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
	_flow.size.x = size.x
	call_deferred("_sync_height")

func _sync_height() -> void:
	var height := maxf(HEIGHT, _flow.get_combined_minimum_size().y)
	if not is_equal_approx(size.y, height):
		size.y = height
		height_changed.emit()
