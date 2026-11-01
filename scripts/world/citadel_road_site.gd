class_name CitadelRoadSite
extends RealmInteractable
## Mechanisms are NOT optional reading interests and create no combat refuge.
func _ready() -> void:
	super._ready()
	art.hide()
	GameState.data_changed.connect(refresh)

func refresh() -> void:
	if not is_instance_valid(label): return
	var path := GameState.citadel_path()
	var realm := get_parent() as TwilightRealm
	if is_instance_valid(realm) and realm._boss_defeated:
		if kind == "ward": label.text = "Citadel restored\nThe road is open"
		elif kind == "camp": label.text = "Citadel lantern\nRest & set checkpoint"
		elif stable_id == "watchpost": label.text = "Rootway winch\n"+("Shortcut open" if GameState.realm_progress().shortcut else "Open the shortcut")
		else: label.text = "Crossing light\nRoad restored"
		prompt = label.text.replace("\n"," · ")
		queue_redraw()
		return
	var field := "crossing_lit" if stable_id == "crossing" else "watchpost_lit"
	if kind == "ward":
		label.text = "Citadel outer ward\n"+("Enter when ready" if GameState.citadel_road_ready() else str(CitadelApproachDB.next_step(path).title))
	elif kind == "camp":
		label.text = "Citadel lantern\n"+("Prepare & rest" if not path.lantern_prepared and CitadelApproachDB.can_prepare(path,bool(GameState.realm_progress().shortcut)) else "Rest & set checkpoint")
	else:
		label.text = ("Crossing light" if stable_id == "crossing" else "Rootway winch")+"\n"+("Light restored" if path[field] else ("Relight the marker" if stable_id == "crossing" else "Restore watchpost light"))
	prompt = label.text.replace("\n"," · ")
	queue_redraw()

func _draw() -> void:
	if kind == "ward": return
	var path := GameState.citadel_path()
	var field := "lantern_prepared" if kind == "camp" else ("crossing_lit" if stable_id == "crossing" else "watchpost_lit")
	var color := Color("#f5d58e") if path[field] or (get_parent() as TwilightRealm)._boss_defeated else Color("#9d8ba8")
	draw_rect(Rect2(-0.5,-0.3,1,0.35),Color("#555469"))
	draw_rect(Rect2(-0.22,-1.3,0.44,1.0),Color("#6a6376"))
	draw_circle(Vector2(0,-1.35),0.25,color)
	draw_arc(Vector2(0,-1.35),0.40,0,TAU,16,color,0.06)
	if stable_id == "watchpost":
		draw_line(Vector2(-0.65,-0.9),Vector2(0.65,-0.9),Color("#d4c0a2"),0.12)
		draw_circle(Vector2(0,-0.9),0.2,Color("#393346"))

func get_touch_verb() -> String:
	return "Enter" if kind == "ward" else "Use"

func interact(actor: Node) -> void:
	var realm := get_parent() as TwilightRealm
	var game := get_tree().get_first_node_in_group("game") as Game
	if not is_instance_valid(game) or game.world != realm or game._input_locked or game._transitioning or game._defeat_pending or realm._leaving or realm._boss_arrived: return
	if actor != realm.player or actor.dead or actor.sleeping or actor.global_position.distance_to(global_position)>interact_radius: return
	if realm._boss_defeated and kind in ["ward","road_light"]:
		realm.show_reading("Citadel restored","Mei Ling is safe. The road is open; explore or return to BESUT whenever you are ready.",position)
		return
	if kind == "ward": realm.request_citadel_entry()
	elif kind == "camp": realm.rest_at_camp()
	elif stable_id == "watchpost": realm.open_shortcut()
	else:
		var result := GameState.light_citadel_site("crossing")
		realm.set_message(str(result.message))
		if bool(result.ok): realm.show_reading("The crossing light",str(result.message),position)
	refresh()
