class_name WorldMapPanel
extends ModalBase
var map: VillageMinimap

func _ready() -> void:
	_panel_size = Vector2(1000, 650)
	super._ready()

func open_map() -> void:
	open_panel("BESUT")

func _rebuild() -> void:
	_clear_content()
	map = VillageMinimap.new()
	map.expanded = true
	map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map.custom_minimum_size = Vector2(280, minf(510, maxf(240, panel.size.y - 112)))
	content.add_child(map)
