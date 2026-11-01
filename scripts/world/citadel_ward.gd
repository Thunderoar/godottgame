class_name CitadelWard
extends Node2D
## A complete collision boundary; the southern opening alone admits a live attempt.
var realm: TwilightRealm
var front: StaticBody2D
var _open := false

func _ready() -> void:
	z_index = 100
	for wall in [Rect2(16.4,0.5,1.2,18), Rect2(34.4,0.5,1.2,18), Rect2(16.4,0.5,19.2,1.2)]:
		_body(wall)
	front = _body(Rect2(22,17.4,8,1.2))
	refresh()

func _body(rect: Rect2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.add_child(shape)
	add_child(body)
	return body

func refresh() -> void:
	var was_open := _open
	_open = realm._boss_defeated or realm.approach_phase in [TwilightRealm.ApproachPhase.ENTRY_GRANTED, TwilightRealm.ApproachPhase.INTRO, TwilightRealm.ApproachPhase.COMBAT, TwilightRealm.ApproachPhase.RETREATING]
	# Keep the exit open until a following companion has physically cleared it.
	if not _open and is_instance_valid(realm.pet) and RealmDB.BOSS_TRIGGER.has_point(realm.pet.position): _open = true
	if was_open != _open:
		if realm._monster_routes != null: realm._monster_routes.invalidate()
		if is_instance_valid(realm.pet): realm.pet.invalidate_routes()
	if is_instance_valid(front): front.collision_layer = 0 if _open else 1
	queue_redraw()

func _physics_process(_delta: float) -> void:
	if _open and realm.approach_phase in [TwilightRealm.ApproachPhase.READY,TwilightRealm.ApproachPhase.SEALED] and not RealmDB.BOSS_TRIGGER.has_point(realm.pet.position): refresh()

func _draw() -> void:
	var path := GameState.citadel_path()
	if not realm.citadel_revealed():
		draw_rect(Rect2(17,1.4,18,16),Color("#242536"))
		for y in range(3,17,2):
			draw_line(Vector2(17,y),Vector2(35,y),Color("#373346"),0.12)
	for x in [17.0,35.0]:
		draw_rect(Rect2(x-0.45,1,0.9,17.6),Color("#65586e"))
	if not _open:
		draw_rect(Rect2(22,17.4,8,1.2), Color("#302b46"))
		for x in range(23,30): draw_line(Vector2(x,17.4),Vector2(x,18.6),Color("#8a6d9c"),0.10)
	for index in 3:
		var lit := bool(path.get(["crossing_lit","watchpost_lit","lantern_prepared"][index],false)) or realm._boss_defeated
		var at := Vector2(24+index*2,18)
		var color := Color("#f1d68e") if lit else Color("#997baf")
		draw_circle(at,0.38,Color("#242536"))
		draw_arc(at,0.38,0,TAU,16,color,0.07)
		if lit: draw_line(at+Vector2(-0.18,0),at+Vector2(-0.03,0.18),color,0.08)
		if lit: draw_line(at+Vector2(-0.03,0.18),at+Vector2(0.2,-0.18),color,0.08)
		else: draw_line(at+Vector2(-0.16,-0.16),at+Vector2(0.16,0.16),color,0.08)
