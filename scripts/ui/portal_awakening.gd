class_name PortalAwakening
extends Node2D
## One sampled timeline in the real clearing. Game owns suspension and cleanup.
signal completed

const DURATION := 8.0
var site: PortalOriginSite
var home: Lobby
var serial := -1
var cancelled := false
var elapsed := 0.0
var _done := false
var _gate: PortalEntrance
var _frame: Sprite2D
var _road: Sprite2D
var _swirl: Sprite2D
var _camera: Camera2D
var _previous_camera: Camera2D
var _start := Vector2.ZERO
var _start_zoom := Vector2.ONE
var _ui: CanvasLayer
var _root: Control
var _caption: Label
var _skip: Button
var _hidden_vitals: Array[Dictionary] = []

func _ready() -> void:
	serial = GameState.journey_serial
	z_index = 50
	_gate = home.get_node_or_null("MonsterBattlePortal") as PortalEntrance
	if is_instance_valid(_gate): _gate.hide()
	site.revealing = true
	site.caption.hide()
	site.replay_button.hide()
	for actor in [home.player, home.pet]:
		for child in actor.get_children():
			if child is CanvasItem and (child is WorldHealthBar or child is PlayerVitalHud or str(child.name) == "PetHealth"):
				_hidden_vitals.append({"node":child,"visible":child.visible})
				child.hide()
	_previous_camera = get_viewport().get_camera_2d()
	_start = _previous_camera.global_position if is_instance_valid(_previous_camera) else site.global_position
	_start_zoom = _previous_camera.zoom if is_instance_valid(_previous_camera) else Vector2.ONE*32
	_camera = Camera2D.new()
	_camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	_camera.position = _start
	_camera.zoom = _start_zoom
	add_child(_camera)
	_camera.make_current()
	_road = _part(WaystoneArt.road(),Vector2(-24,-92))
	_swirl = _part(PixelArt.portal_swirl_texture("chaos",0),Vector2(-24,-92))
	_frame = _part(PixelArt.portal_frame_texture("chaos",false),Vector2(-40,-112))
	_ui = CanvasLayer.new()
	_ui.layer = 270
	add_child(_ui)
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_root)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 24
	panel.offset_right = -24
	panel.offset_top = -116
	panel.offset_bottom = -24
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel",GameUI.style(Color("#172f3aef"),Color("#a5b493"),1,16))
	_root.add_child(panel)
	_caption = GameUI.label("",22,Color("#f5e9bd"))
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(_caption)
	_skip = GameUI.button("Skip reveal",Vector2(184,68))
	_skip.pressed.connect(finish)
	_root.add_child(_skip)
	_root.resized.connect(_fit)
	GameSettings.changed.connect(_on_setting_changed)
	_fit()
	sample(0)

func _part(texture: Texture2D, offset: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.offset = offset
	sprite.scale = Vector2.ONE*PixelArt.PX
	sprite.position = site.global_position
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	return sprite

func _fit() -> void:
	var scale_factor := float(get_window().size.y)/maxf(1,get_viewport_rect().size.y) if DisplayServer.get_name() != "headless" else 1.0
	_skip.size = Vector2(184,maxf(48,44/maxf(0.1,scale_factor)))
	_skip.position = Vector2(_root.size.x-_skip.size.x-24,24)

func _process(delta: float) -> void:
	if _done: return
	var game := get_tree().get_first_node_in_group("game") as Game
	if not is_instance_valid(home) or home.is_queued_for_deletion() or not is_instance_valid(site) or not is_instance_valid(game) or game.world != home or serial != GameState.journey_serial or game._game_over or game._defeat_pending:
		cancel()
		return
	sample(elapsed+maxf(0,delta))
	if elapsed >= DURATION: finish()

func sample(time: float) -> void:
	elapsed = clampf(time,0,DURATION)
	var reduced := GameSettings.reduce_motion()
	var align := smoothstep(0,1.5,elapsed)
	if reduced: align = 1.0 if elapsed >= 1.0 else 0.0
	site.stone.visible = elapsed < 5.8
	site.stone.rotation = lerpf(-1.1,0,align)
	site.stone.position = Vector2(-0.7,-0.05).lerp(Vector2(0,-0.2),align)
	site.lantern.visible = elapsed >= 1.2
	site.lantern.modulate.a = 1.0 if reduced else smoothstep(1.2,2.0,elapsed)
	site.line.modulate.a = lerpf(0.12,0.9,smoothstep(1.5,3,elapsed))
	site.light_road((1.0 if elapsed >= 2 else 0.0) if reduced else smoothstep(1.5,3,elapsed))
	var answer := smoothstep(3,4.5,elapsed)
	var arch := smoothstep(4.5,6.3,elapsed)
	if reduced:
		answer = 1.0 if elapsed >= 3 else 0.0
		arch = 1.0 if elapsed >= 5 else 0.0
	_frame.modulate.a = arch
	_road.modulate.a = answer*(1.0-smoothstep(6.1,7,elapsed))
	_swirl.modulate.a = smoothstep(6.1,7,elapsed)
	if not reduced: _swirl.texture = PixelArt.portal_swirl_texture("chaos",int(elapsed*9)%8)
	var focus := site.global_position+Vector2(0,-1.2)
	var zoom_target := Vector2.ONE*minf(52,get_viewport_rect().size.y/10.0)
	var half_view := get_viewport_rect().size/zoom_target/2.0
	focus = focus.clamp(half_view+Vector2.ONE*0.15,home.get_map_rect().end-half_view-Vector2.ONE*0.15)
	var approach := smoothstep(0,1.2,elapsed)*(1.0-smoothstep(7,8,elapsed))
	_camera.global_position = focus if reduced else _start.lerp(focus,approach)
	_camera.zoom = zoom_target if reduced else _start_zoom.lerp(zoom_target,approach)
	_camera.force_update_scroll()
	if elapsed < 1.5: _caption.text = "Adam sets the fallen marker upright. The carved road joins again."
	elif elapsed < 3: _caption.text = "Adam turns Pak Rahim's portal key. The unlocked lantern lights the old road."
	elif elapsed < 4.5: _caption.text = "Across the darkness, another light answers."
	elif elapsed < 6.5: _caption.text = "Leaves. Old stones. A road into the woods."
	else: _caption.text = "The road remembers. Enter when you are ready; its light leads home."

func _on_setting_changed(key: String) -> void:
	if key in ["reduce_motion","effects_quality"]: sample(elapsed)

func _input(event: InputEvent) -> void:
	if not _done and event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ESCAPE,KEY_SPACE,KEY_ENTER]:
		get_viewport().set_input_as_handled()
		finish()

func finish() -> void:
	if _done: return
	_done = true
	hide()
	_ui.hide()
	var game := get_tree().get_first_node_in_group("game") as Game
	var owned := is_instance_valid(game) and game.world == home and serial == GameState.journey_serial
	if owned:
		for item in _hidden_vitals:
			if is_instance_valid(item.node): item.node.visible = bool(item.visible)
		if is_instance_valid(_gate): _gate.show()
		if is_instance_valid(site):
			site.revealing = false
			site.refresh()
		if is_instance_valid(_previous_camera) and get_viewport().get_camera_2d() == _camera: _previous_camera.make_current()
	completed.emit()
	queue_free()

func cancel() -> void:
	cancelled = true
	finish()
