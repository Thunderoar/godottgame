class_name OceanScenery
extends Node2D
## Non-colliding background life. Threatening sharks belong to OceanJourney.
var clock := 0.0
var life: Array[Dictionary] = []
func _ready() -> void:
	z_index = 1
	var specs := [
		["whale",Vector2(30,8),0.12,0.42],["megalodon",Vector2(9,9),0.1,0.35],
		["mermaid",Vector2(28,15.7),0.08,0.5],["diver",Vector2(18,8),0.06,0.45],
		["fish",Vector2(4,7),0.55,0.42],["fish",Vector2(7,7.8),0.55,0.34],
		["fish",Vector2(32,13),0.7,0.37],["fish",Vector2(34,13.5),0.7,0.28],
		["fish",Vector2(24,18),0.45,0.33],["fish",Vector2(26,18.5),0.45,0.27]]
	for spec in specs:
		var s := Sprite2D.new()
		s.texture = OceanArt.creature(spec[0])
		s.scale = Vector2.ONE * PixelArt.PX * float(spec[3]) * (3.5 if spec[0] in ["whale","megalodon"] else 1.8)
		s.position = spec[1]
		s.modulate = Color("#608c9c") if spec[0] in ["whale","megalodon"] else Color("#b2d1ce")
		add_child(s)
		life.append({"kind":spec[0],"sprite":s,"base":spec[1],"speed":spec[2]})
	for i in 18:
		var kind: String = ["coral","starfish","crab","chest","pearl","coral"][i%6]
		var s := Sprite2D.new()
		s.texture = OceanArt.seabed(kind)
		s.position = Vector2(-2+i*2.7,20.8+(i%3)*0.3)
		s.scale = Vector2.ONE * PixelArt.PX * (1.0 if kind == "coral" else 0.5)
		add_child(s)
	var wreck := Sprite2D.new()
	wreck.texture = OceanArt.seabed("wreck")
	wreck.position = Vector2(32,19.5)
	wreck.scale = Vector2.ONE * PixelArt.PX * 2.3
	wreck.modulate = Color("#92b4b4")
	add_child(wreck)
func _process(delta: float) -> void:
	if GameSettings.reduce_motion(): return
	var ocean := get_parent() as OceanJourney
	if is_instance_valid(ocean._ocean_settings) and ocean._ocean_settings.visible: return
	clock += delta
	for actor in life:
		var s := actor.sprite as Sprite2D
		var base: Vector2 = actor.base
		s.position = Vector2(fposmod(base.x-clock*float(actor.speed)+6,52)-6,base.y+sin(clock*0.65+base.x)*0.22)
		s.texture = OceanArt.creature(str(actor.kind),int(clock*2)%2)
	queue_redraw()
func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(-20,21),Vector2(5,20.6),Vector2(20,21.1),Vector2(32,20.6),Vector2(65,21),Vector2(65,30),Vector2(-20,30)]),Color("#758e8b"))
	for i in 75:
		var x := fposmod(i*4.179,65)-10
		var y := 21.2+fposmod(i*1.197,2.8)
		draw_line(Vector2(x,y),Vector2(x+0.12,y),Color("#b3bfa3"),PixelArt.PX)
	for i in 35:
		var x := i*1.7-10
		var points := PackedVector2Array()
		for j in 7: points.append(Vector2(x+sin(clock*1.4+i+j*0.4)*0.16*j/6,22-j*(0.15+(i%4)*0.035)))
		draw_polyline(points,Color("#3e9d94") if i%2 else Color("#30747f"),0.12)
	for i in 4:
		var actor: Dictionary = life[3]
		var at: Vector2 = actor.sprite.position
		var rise := fposmod(clock*0.7+i*0.6,3.0)
		draw_arc(at+Vector2(-0.7,-0.5-rise),0.05+rise*0.012,0,TAU,10,Color(0.6,0.9,0.95,0.45),PixelArt.PX)
