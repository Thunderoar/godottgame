class_name TutorialSpotlight
extends Control
## A non-blocking dimmer with one bright target and an animated pointer.

var hud: GameHUD
var target_rect := Rect2()
var _clock := 0.0
var _scroll_target: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100


func _process(delta: float) -> void:
	_clock += delta
	visible = is_instance_valid(hud) and hud.visible and hud.tutorial_guide.visible
	if not visible:
		return
	target_rect = _resolve_target()
	_layout_guide()
	queue_redraw()


func _layout_guide() -> void:
	var guide := hud.tutorial_guide
	var extent := Vector2(minf(316, size.x - 32), minf(242, size.y - 32))
	var candidates := [Vector2(size.x - extent.x - 20, 150), Vector2(20, 150), Vector2(20, 20), Vector2(size.x - extent.x - 20, 20)]
	guide.set_anchors_preset(Control.PRESET_TOP_LEFT)
	guide.size = extent
	for candidate in candidates:
		var point: Vector2 = candidate
		point.y = minf(point.y, size.y - extent.y - 16)
		if not Rect2(point, extent).intersects(target_rect.grow(35)) and (not is_instance_valid(hud._map_button) or not Rect2(point, extent).intersects(hud._map_button.get_global_rect())):
			guide.position = point
			return


func _control_rect(control: Control) -> Rect2:
	if not is_instance_valid(control) or not control.is_visible_in_tree():
		return Rect2()
	return Rect2(control.get_global_rect().position - global_position, control.get_global_rect().size).grow(8)


func _find_action(node: Node, item: String, caption: String = "") -> Control:
	if node is ItemCard and node.item_id == item:
		return node._action_button
	if node is Button and not caption.is_empty() and node.text == caption:
		return node
	for child in node.get_children():
		var found := _find_action(child, item, caption)
		if found:
			return found
	return null


func _resolve_target() -> Rect2:
	var step := GameState.mission_step()
	if step >= MissionDB.STEPS.size(): return Rect2()
	var modal: ModalBase
	for child in get_parent().get_children():
		if child is ModalBase and child.visible:
			modal = child
	var action: Control
	if modal:
		if modal == hud.shop_panel and step == 2:
			action = _find_action(modal.content, "health_potion")
		elif modal == hud.shop_panel and step == 7:
			action = _find_action(modal.content, "pet_food") if GameState.item_count("pet_food") <= 0 else _find_action(modal.content, "", "Feed")
		elif modal == hud.portal_panel and step == 8:
			action = _find_action(modal.content, "", "Enter")
		if not is_instance_valid(action):
			action = modal._close_button
		if action != _scroll_target:
			_scroll_target = action
			if modal.content.is_ancestor_of(action):
				modal.body.ensure_control_visible(action)
		return _control_rect(action)
	if step == 3:
		return _control_rect(hud._inventory_button)
	var game := get_tree().get_first_node_in_group("game") as Game
	if not is_instance_valid(game) or not is_instance_valid(game.world) or not is_instance_valid(game.player()):
		return Rect2()
	var player := game.player()
	if step in [2, 5, 6, 7] and game.world is Lobby:
		var kind := str({2: "potion", 5: "services", 6: "house", 7: "pet"}.get(step, "potion"))
		for shop in get_tree().get_nodes_in_group("ambient_shop"):
			if is_instance_valid(shop) and shop.shop_type == kind and shop.get_parent().get_parent() == game.world:
				var centre: Vector2 = shop.global_position + Vector2(0, -0.6)
				var transform := game.world.get_global_transform_with_canvas()
				var world_rect := Rect2(transform * (centre - Vector2(1.8, 1.7)), Vector2(3.6, 3.6) * transform.get_scale())
				if get_viewport_rect().encloses(world_rect):
					return world_rect
	if step == 4:
		var found := false
		for enemy in get_tree().get_nodes_in_group("forest_monsters"):
			if is_instance_valid(enemy) and not enemy.dead:
				found = true
				if enemy.global_position.distance_to(player.global_position) < 3.0:
					return _control_rect(hud._attack_button)
		if not found:
			return _control_rect(hud._clock_label)
	if step == 9 and game.world is Dungeon:
		return _control_rect(hud._attack_button)
	if step == 1 and is_instance_valid(player.nearby) and player.nearby is ResourcePile:
		return _control_rect(hud._interact_button)
	if step == 8 and is_instance_valid(player.nearby) and player.nearby is PortalEntrance and player.nearby.gate_kind == "monster":
		return _control_rect(hud._interact_button)
	return _control_rect(hud._joystick)


func _draw() -> void:
	if target_rect.size == Vector2.ZERO:
		return
	var hole := target_rect.intersection(Rect2(Vector2.ZERO, size))
	var dim := Color(0.015, 0.025, 0.045, dim_strength())
	draw_rect(Rect2(0, 0, size.x, maxf(0, hole.position.y)), dim)
	draw_rect(Rect2(0, hole.end.y, size.x, maxf(0, size.y - hole.end.y)), dim)
	draw_rect(Rect2(0, hole.position.y, maxf(0, hole.position.x), hole.size.y), dim)
	draw_rect(Rect2(hole.end.x, hole.position.y, maxf(0, size.x - hole.end.x), hole.size.y), dim)
	var gold := Color("#ffe18b")
	draw_rect(hole, gold, false, 3.0)
	var below := hole.position.y < 90.0
	var direction := Vector2.UP if below else Vector2.DOWN
	var tip := Vector2(hole.get_center().x, hole.end.y + 8 if below else hole.position.y - 8)
	var bob := 0.0 if GameSettings.reduce_motion() else sin(_clock * 4) * 5.0
	tip -= direction * bob
	var tail := tip - direction * 40.0
	draw_line(tail, tip - direction * 5, gold, 6, true)
	draw_colored_polygon(PackedVector2Array([tip, tip - direction * 18 + Vector2(13, 0), tip - direction * 18 - Vector2(13, 0)]), gold)


func dim_strength() -> float:
	return 0.0
