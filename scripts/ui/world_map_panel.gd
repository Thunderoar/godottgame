class_name WorldMapPanel
extends ModalBase
var map: VillageMinimap

func _ready() -> void:
	_panel_size = Vector2(1000, 650)
	super._ready()

func open_map() -> void:
	var game := get_tree().get_first_node_in_group("game") as Game
	open_panel("TWILIGHT WILDS · DISCOVERED PATHS" if is_instance_valid(game) and game.world is TwilightRealm else "BESUT")

func _rebuild() -> void:
	_clear_content()
	map = VillageMinimap.new()
	map.expanded = true
	map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map.custom_minimum_size = Vector2(280, minf(510, maxf(240, panel.size.y - 112)))
	content.add_child(map)
