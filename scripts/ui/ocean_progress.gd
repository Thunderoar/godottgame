class_name OceanProgress
extends Control
var progress := 0.0
func _ready() -> void:
	custom_minimum_size = Vector2(220,54)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	var a := Vector2(22,25)
	var b := Vector2(size.x-22,25)
	var at := a.lerp(b,clampf(progress,0,1))
	draw_line(a,b,Color("#284c60"),9)
	draw_line(a,at,Color("#76d8c7"),5)
	for i in range(1,GameState.OCEAN_STAGES): draw_circle(a.lerp(b,float(i)/GameState.OCEAN_STAGES),4,Color("#e7c77c"))
	var arjun := PixelArt.portrait("arjun")
	var adam := PixelArt.portrait(str(GameState.data.get("character_id","adam")))
	draw_texture_rect_region(arjun,Rect2(b-Vector2(16,18),Vector2(32,32)),Rect2(24,24,48,48))
	draw_circle(at,19,Color("#112c3d"))
	draw_arc(at,19,0,TAU,32,Color("#e8ca80"),2)
	draw_texture_rect_region(adam,Rect2(at-Vector2(15,16),Vector2(30,30)),Rect2(24,24,48,48))
	draw_string(ThemeDB.fallback_font,Vector2(3,52),"BESUT",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("#c9e6e0"))
	draw_string(ThemeDB.fallback_font,Vector2(size.x-125,52),"ARJUN · KRAKEN ISLAND",HORIZONTAL_ALIGNMENT_RIGHT,120,10,Color("#e8ca80"))
