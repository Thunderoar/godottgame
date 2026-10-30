class_name PortalOriginSite
extends Interactable
## Discoverable broken road. The nearby action never starts an expedition.

var stone: Sprite2D
var lantern: Sprite2D
var ground: Sprite2D
var line: Line2D
var caption: Label
var replay_button: Button
var flowers: Sprite2D
var ribbons: Array[Sprite2D] = []
var glimmers: Array[Sprite2D] = []
var _words := ""
var _time := 0.0
var revealing := false
const ROAD_POINTS := [Vector2(-1.2,0.1),Vector2(-0.55,0.1),Vector2(-0.55,-0.12),Vector2(0.38,-0.12),Vector2(0.85,0.08)]

func _ready() -> void:
	show_marker = false
	interact_radius = 2.6
	super._ready()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ground = _piece(WaystoneArt.ground(), Vector2(-88,-58), Vector2.ZERO)
	ground.z_index = -1
	flowers = _piece(WaystoneArt.flowers(),Vector2(-88,-45),Vector2.ZERO)
	for at in [Vector2(-2.25,0.9),Vector2(2.25,0.9)]:
		ribbons.append(_piece(WaystoneArt.ribbon(),Vector2(-12,-42),at))
	stone = _piece(WaystoneArt.marker(),Vector2(-15,-48),Vector2(-0.7,-0.05))
	lantern = _piece(WaystoneArt.lantern(),Vector2(-10,-30),Vector2(0.94,0.08))
	line = Line2D.new()
	line.points = PackedVector2Array(ROAD_POINTS)
	line.width = PixelArt.PX*2
	line.default_color = Color("#eddf9d")
	add_child(line)
	for at in [Vector2(0.94,-0.66),Vector2(-0.45,-0.7),Vector2(0.25,0.16)]:
		var glimmer := _piece(WaystoneArt.glimmer(),Vector2(-6,-6),at)
		glimmer.light_mask = 0
		glimmers.append(glimmer)
	caption = Label.new()
	caption.add_theme_font_size_override("font_size",14)
	caption.add_theme_color_override("font_color",Color("#f8efd0"))
	caption.add_theme_color_override("font_outline_color",Color("#243c46"))
	caption.add_theme_constant_override("outline_size",5)
	caption.scale = Vector2.ONE*PixelArt.PX
	caption.position = Vector2(-4.5,-3.3)
	caption.size = Vector2(288,110)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(caption)
	replay_button = GameUI.button("Watch awakening",Vector2(160,48))
	replay_button.scale = Vector2.ONE*PixelArt.PX
	replay_button.position = Vector2(1.8,0.5)
	replay_button.pressed.connect(func() -> void: interact(get_tree().get_first_node_in_group("game").player()))
	add_child(replay_button)
	GameState.data_changed.connect(refresh)
	GameSettings.changed.connect(_on_cue_setting_changed)
	refresh()

func _piece(texture: Texture2D, offset: Vector2, at: Vector2) -> Sprite2D:
	var part := Sprite2D.new()
	part.texture = texture
	part.centered = false
	part.offset = offset
	part.scale = Vector2.ONE*PixelArt.PX
	part.position = at
	add_child(part)
	return part

func refresh() -> void:
	if not is_instance_valid(stone) or revealing: return
	var progress := GameState.portal_origin()
	available = not bool(progress.opened)
	stone.visible = not bool(progress.opened)
	stone.rotation = -1.1
	lantern.visible = bool(progress.opened)
	line.modulate.a = 0.55 if bool(progress.opened) else 0.12
	line.points = PackedVector2Array(ROAD_POINTS)
	if bool(progress.opened):
		prompt = "The village lantern keeps the road open"
		_words = "" # E and the gate's main hotspot always enter the already open road.
	elif bool(progress.rahim_consulted): prompt = "Set the marker and light the road"
	elif bool(progress.site_examined): prompt = "Old waystone · Ask Pak Rahim at the dock"
	else: prompt = "Examine the old stones"
	caption.text = _words if not _words.is_empty() else prompt
	replay_button.visible = bool(progress.opened) and not bool(progress.reveal_seen)
	_update_cues()

func _on_cue_setting_changed(key: String) -> void:
	if key in ["reduce_motion","effects_quality"]: _update_cues()

func _update_cues() -> void:
	var opened := GameState.portal_opened()
	var prepared := bool(GameState.portal_origin().get("rahim_consulted",false))
	var animated := not GameSettings.reduce_motion() and GameSettings.effects_at_least("med")
	for i in glimmers.size():
		var glimmer := glimmers[i]
		glimmer.visible = not opened and not revealing and (i == 0 or GameSettings.effects_at_least("med"))
		glimmer.modulate = Color("#ffe6a0") if prepared else Color("#d0eadf")
		glimmer.modulate.a = 0.75 if not animated else 0.38+0.38*maxf(0,sin(_time*1.6+float(i)*1.8))
		var home: Vector2 = [Vector2(0.94,-0.66),Vector2(-0.45,-0.7),Vector2(0.25,0.16)][i]
		glimmer.position = home+Vector2(0,sin(_time*1.1+float(i))*0.055 if animated else 0.0)
	for i in ribbons.size():
		ribbons[i].rotation = sin(_time*0.9+float(i)*0.7)*0.025 if animated and not opened else 0.0

func _process(delta: float) -> void:
	super._process(delta)
	_time += delta
	_update_cues()
	if revealing: return
	var game := get_tree().get_first_node_in_group("game") as Game
	if not is_instance_valid(game) or game.world != get_parent() or not is_instance_valid(game.player()): return
	var near := game.player().global_position.distance_to(global_position) < 5.3
	caption.visible = near and not game._input_locked and not GameState.portal_opened()
	replay_button.visible = near and not game._input_locked and GameState.portal_opened() and not bool(GameState.portal_origin().reveal_seen)
	if not near and not _words.is_empty():
		_words = ""
		refresh()
	if not GameState.portal_opened():
		line.modulate.a = 0.16 if GameSettings.reduce_motion() else 0.12+(maxf(0,sin(_time*1.2))*0.28 if GameState.is_night() else 0.02)

func set_message(words: String) -> void:
	_words = words
	caption.text = words
	caption.show()

func light_road(fraction: float) -> void:
	var points := PackedVector2Array()
	var progress := clampf(fraction,0,1)*float(ROAD_POINTS.size()-1)
	points.append(ROAD_POINTS[0])
	for index in range(1,ROAD_POINTS.size()):
		if float(index) <= progress: points.append(ROAD_POINTS[index])
		else:
			points.append((ROAD_POINTS[index-1] as Vector2).lerp(ROAD_POINTS[index],clampf(progress-float(index-1),0,1)))
			break
	line.points = points

func valid_actor(actor: Node) -> bool:
	var game := get_tree().get_first_node_in_group("game") as Game
	if not is_instance_valid(game) or not get_parent() is Lobby or game.world != get_parent() or game._input_locked or game._transitioning or game._story_active or game._defeat_pending or game._sailing or game._game_over or game.hud.any_modal_open() or is_instance_valid(game.home_interior): return false
	if get_parent().journey_serial != GameState.journey_serial or get_parent()._settlement_editor.active: return false
	if not is_instance_valid(actor) or actor != game.player() or actor.dead or actor.sleeping or actor.global_position.distance_to(global_position) > interact_radius: return false
	var ray := PhysicsRayQueryParameters2D.create(actor.global_position,global_position,1)
	return get_world_2d().direct_space_state.intersect_ray(ray).is_empty()

func interact(actor: Node) -> void:
	if not valid_actor(actor): return
	var game := get_tree().get_first_node_in_group("game") as Game
	var progress := GameState.portal_origin()
	if bool(progress.opened):
		if not bool(progress.reveal_seen): game.awaken_portal(self,true)
	elif bool(progress.rahim_consulted): game.awaken_portal(self)
	else:
		GameState.examine_waystone()
		set_message("A line breaks beneath the fallen marker.\nThe lantern socket is empty.\nAsk Pak Rahim at the dock.")
