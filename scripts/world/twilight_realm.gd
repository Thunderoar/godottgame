class_name TwilightRealm
extends Dungeon
## One connected authored exploration world; Dungeon's actor/routing API stays valid.

var wildlife: Dictionary = {}
var _packs: Array[Dictionary] = []
var _shortcut_body: StaticBody2D
var _survey_timer := 0.0
var _last_cell := ""
var _leaving := false
var _area_label: Label
var _hint_label: Label
var _message := ""
var _landmark := "arrival"
var _camp: RealmInteractable
var _camp_resting := false
var _camp_timer := 0.0

func _ready() -> void:
	portal_id = RealmDB.PORTAL
	zone_name = "Twilight Wilds"
	map_rect = Rect2(Vector2.ZERO, RealmDB.SIZE)
	_definition = PortalDB.get_portal(portal_id)
	add_to_group("world")
	add_to_group("dungeon")
	y_sort_enabled = true
	_boss_defeated = bool(GameState.portal_state(portal_id).get("cleared", false))
	_build_lighting()
	canvas_modulate.color = Color("#d7d6ec") if not _boss_defeated else Color("#eef3dd")
	background = Sprite2D.new()
	background.texture = TwilightLandscape.terrain(_boss_defeated)
	background.centered = false
	background.scale = RealmDB.SIZE / background.texture.get_size()
	background.z_as_relative = false
	background.z_index = -1000
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(background)
	_build_realm_bounds()
	TwilightLandscape.decorate(self)
	_build_player_and_pet()
	player.position = get_spawn_position()
	pet.position = player.position + Vector2(-1, 0.5)
	_build_camera()
	camera.global_position = player.position
	_build_places()
	if not _boss_defeated: _build_encounters()
	_build_realm_labels()
	Vfx.ensure_pool(self)
	GameState.player_defeated.connect(_on_player_defeated)
	Sfx.stop_battle_music()
	call_deferred("survey")

func _build_realm_bounds() -> void:
	var walls := StaticBody2D.new()
	walls.collision_layer = 1
	add_child(walls)
	_add_box(walls, Vector2(36, 0), Vector2(72, 2))
	_add_box(walls, Vector2(36, 72), Vector2(72, 2))
	_add_box(walls, Vector2(0, 36), Vector2(2, 72))
	_add_box(walls, Vector2(72, 36), Vector2(2, 72))
	# Chamber walls create a deliberate south entrance and an eastern passage.
	_add_box(walls, Vector2(27, 9), Vector2(1.2, 15))
	_add_box(walls, Vector2(45, 7), Vector2(1.2, 9))
	_add_box(walls, Vector2(29.5, 18), Vector2(6, 1.0))
	_add_box(walls, Vector2(42.5, 18), Vector2(6, 1.0))
	# Root escarpment makes the locked grove route a real shortcut, not a small
	# obstacle the player can simply sidestep. The main eastern road stays open.
	_add_box(walls, Vector2(10,31), Vector2(20,1.6))
	_add_box(walls, Vector2(29,31), Vector2(6,1.6))
	for edge in [Rect2(1,30.2,19,1.6),Rect2(26,30.2,6,1.6)]:
		var ridge := Polygon2D.new()
		ridge.polygon = PackedVector2Array([edge.position,edge.position+Vector2(edge.size.x,0),edge.end,edge.position+Vector2(0,edge.size.y)])
		ridge.color = Color("#51404f")
		add_child(ridge)
	for p in [Vector2(28,18),Vector2(44,18),Vector2(29,5),Vector2(43,5)]: _add_pillar(p)
	_shortcut_body = StaticBody2D.new()
	_shortcut_body.name = "RootwayBarrier"
	_shortcut_body.position = Vector2(23, 31)
	_shortcut_body.collision_layer = 1
	add_child(_shortcut_body)
	_add_box(_shortcut_body, Vector2.ZERO, Vector2(6.5, 1.6))
	var roots := Polygon2D.new()
	roots.polygon = PackedVector2Array([Vector2(-3.3,-0.8),Vector2(3.3,-0.8),Vector2(3.0,0.8),Vector2(-3.0,0.8)])
	roots.color = Color("#51404f")
	_shortcut_body.add_child(roots)
	if GameState.realm_progress().shortcut: _shortcut_body.queue_free()

func _place(kind: String, id: String, at: Vector2, title: String) -> RealmInteractable:
	var item := RealmInteractable.new()
	item.kind = kind
	item.stable_id = id
	item.position = at
	item.caption = title
	add_child(item)
	return item

func _build_places() -> void:
	_place("exit", "arrival", Vector2(36, 66), "Return to BESUT\nBank carried loot")
	_place("shortcut", "rootway", Vector2(48, 36), "Rootway winch")
	_camp = _place("camp", "camp", RealmDB.CAMP, "Citadel lantern\nRest & set checkpoint")
	for id in RealmDB.ENCOUNTERS:
		var def: Dictionary = RealmDB.ENCOUNTERS[id]
		wildlife[id] = _place("pet", id, def.at, def.name)
	# Physical legacy echoes preserve existing progression until later realms are authored.
	var ids := PortalDB.ordered_ids()
	for i in range(1, ids.size()):
		var at := Vector2(51 + ((i - 1) % 3) * 6, 8 + ((i - 1) / 3) * 7)
		_place("passage", ids[i], at, str(PortalDB.get_portal(ids[i]).name))
	if _boss_defeated: _place("exit", "citadel", Vector2(36, 10), "The citadel is restored\nReturn to BESUT")

func _build_encounters() -> void:
	var spots := [Vector2(41,43),Vector2(47,40),Vector2(46,33),Vector2(42,30),Vector2(33,28),Vector2(38,28)]
	for i in spots.size():
		var enemy := ElementalMinion.new()
		enemy.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
		enemy.element = "chaos"
		enemy.position = spots[i]
		enemy.max_hp = 42 + i * 2
		enemy.damage = 7
		enemy.speed = 1.7
		enemy.xp_reward = 14
		enemy.gold_reward = 7
		add_child(enemy)
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
		_packs.append({"enemy": enemy, "home": spots[i], "active": false})
	var ruler := ElementalBoss.new()
	ruler.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
	ruler.element = "chaos"
	ruler.is_boss = true
	ruler.monster_level = 3
	ruler.max_hp = int(_definition.boss_hp)
	ruler.damage = int(_definition.boss_damage)
	ruler.speed = float(_definition.boss_speed)
	ruler.special_damage = int(_definition.boss_damage)
	ruler.special_cooldown = float(_definition.boss_special_cooldown)
	ruler.projectile_damage = int(_definition.boss_projectile_damage)
	ruler.body_radius = 1.0
	ruler.position = RealmDB.BOSS
	ruler.boss_finished.connect(_on_boss_finished)
	boss = ruler
	add_child(boss)
	boss.process_mode = Node.PROCESS_MODE_DISABLED

func _build_realm_labels() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 3
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	_area_label = GameUI.label("TWILIGHT WILDS · ARRIVAL GLADE", 19, Color("#f2dfb8"))
	root.add_child(_area_label)
	_area_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_area_label.position.y = 18
	_area_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label = GameUI.label("", 14, Color("#d7d8e3"))
	root.add_child(_hint_label)
	_hint_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_hint_label.position = Vector2(140, 45)
	_hint_label.offset_right = -140
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	set_message(_landmark_hint("arrival"))

func _landmark_hint(id: String) -> String:
	return "The wilds are peaceful. Find missed companions, visit onward passages, or return to BESUT." if _boss_defeated else str(RealmDB.LANDMARKS[id].hint)

func set_message(message: String) -> void:
	_message = message
	if is_instance_valid(_hint_label): _hint_label.text = message

func survey() -> void:
	if not is_instance_valid(player): return
	var cell := RealmDB.cell_id(player.position)
	if cell != _last_cell:
		_last_cell = cell
		GameState.discover_realm_at(player.position)
	var nearest := _landmark
	var distance := 8.0
	for id in RealmDB.LANDMARKS:
		var def: Dictionary = RealmDB.LANDMARKS[id]
		var d := player.position.distance_to(def.at)
		if d < distance:
			distance = d
			nearest = id
	if nearest != _landmark:
		_landmark = nearest
		GameState.discover_realm_landmark(nearest)
		_area_label.text = "TWILIGHT WILDS · " + str(RealmDB.LANDMARKS[nearest].name).to_upper()
		set_message(_landmark_hint(nearest))

func _physics_process(delta: float) -> void:
	var game := get_tree().get_first_node_in_group("game") as Game
	if not is_instance_valid(game) or game.world != self or game._transitioning or game._defeat_pending or _leaving: return
	_survey_timer -= delta
	if _survey_timer <= 0:
		_survey_timer = 0.4
		survey()
	if _camp_resting:
		_camp_timer += delta
		if _camp_timer >= 2.0:
			_camp_resting = false
			GameState.finish_realm_rest()
			game._input_locked = false
			game._apply_input_lock()
			set_message("Rested. Checkpoint saved at the lantern. Step through the arch when ready.")
	if _boss_defeated: return
	for pack in _packs:
		var enemy := pack.enemy as Enemy
		if not is_instance_valid(enemy) or enemy.dead: continue
		var home: Vector2 = pack.home
		var near := player.position.distance_to(home) < 6.5
		var safe := player.position.distance_to(RealmDB.CAMP) < 3.5 or player.position.distance_to(Vector2(17,43)) < 4 or player.position.distance_to(Vector2(57,29)) < 4
		if bool(pack.active) and (player.position.distance_to(home) > 11 or safe):
			pack.active = false
			enemy.process_mode = Node.PROCESS_MODE_DISABLED
			enemy.position = home
			enemy.velocity = Vector2.ZERO
			_clear_effects(enemy)
		elif not bool(pack.active) and near and not safe:
			pack.active = true
			enemy.process_mode = Node.PROCESS_MODE_INHERIT
			enemy._player = player
			enemy._target = player
			enemy._enter(Enemy.State.CHASE)
	if not _boss_arrived and player.position.y < 17 and player.position.x > 28 and player.position.x < 44:
		_boss_arrived = true
		camera.framing_bounds = Rect2(25,0,22,21)
		camera.position = camera.framing_bounds.get_center()
		camera.zoom = Vector2.ONE * minf(GameSettings.camera_zoom(),get_viewport_rect().size.y / 23.0)
		GameState.discover_realm_landmark("citadel")
		boss.process_mode = Node.PROCESS_MODE_INHERIT
		boss.active = true
		boss.dungeon_alerted = true
		boss._player = player
		boss._target = player
		boss._enter(Enemy.State.ALERT)
		Sfx.start_battle_music(portal_id)
		set_message("SHADOW & CHAOS FIEND · Watch the fan, dash and crossing flames.")
	if _boss_arrived and is_instance_valid(boss) and not boss.dead and not Rect2(26,1,20,20).has_point(player.position):
		reset_boss()

func reset_boss() -> void:
	_boss_arrived = false
	camera.framing_bounds = Rect2()
	boss.active = false
	boss.dungeon_alerted = false
	boss.process_mode = Node.PROCESS_MODE_DISABLED
	boss.position = RealmDB.BOSS
	boss.hp = boss.max_hp
	boss.velocity = Vector2.ZERO
	boss._cast_time = 0
	boss._pending = {}
	boss._charging = false
	boss._special_timer = 2.5
	boss._skill_index = 0
	boss._ability_label.visible = false
	_clear_effects(boss)
	Sfx.stop_battle_music()
	set_message("The fiend retreats to its throne. Rest at the lantern before trying again.")

func _clear_effects(caster: Enemy = null) -> void:
	for child in get_children():
		if child is ElementalEffect or child is ElementalProjectile:
			if caster == null or child.caster == caster: child.queue_free()

func alert_intruders(_include_boss: bool = false) -> void:
	# Damage must never wake distant encounters or bypass the chamber threshold.
	pass

func can_damage_actor(actor: Node) -> bool:
	if actor == boss: return _boss_arrived and not _boss_defeated
	return actor.process_mode != Node.PROCESS_MODE_DISABLED

func _on_boss_finished(_enemy: Enemy) -> void:
	if _boss_defeated: return
	_boss_defeated = true
	camera.framing_bounds = Rect2()
	var summary := GameState.complete_portal(portal_id)
	_clear_effects()
	for pack in _packs:
		if is_instance_valid(pack.enemy): pack.enemy.queue_free()
	background.texture = TwilightLandscape.terrain(true)
	canvas_modulate.color = Color("#eef3dd")
	Sfx.stop_battle_music()
	Sfx.play("victory", -5)
	player.controls_locked = false
	_place("exit", "citadel", RealmDB.BOSS, "Citadel restored\nReturn to BESUT")
	for child in get_children():
		if child is RealmInteractable: child.refresh()
	set_message("Citadel restored · +%d Gold · +%d diamonds. Explore peacefully, or return through the rift." % [int(summary.gold), int(summary.diamonds)])

func challenge_pet(encounter: RealmInteractable) -> void:
	var game := get_tree().get_first_node_in_group("game") as Game
	if _boss_arrived or _camp_resting or not is_instance_valid(game) or game.hud.any_modal_open(): return
	var reason := GameState.wild_encounter_reason(encounter.stable_id)
	if not bool(reason.ok):
		set_message(str(reason.reason))
		return
	game.hud.release_world_controls()
	game._input_locked = true
	game._apply_input_lock()
	game.hud.wild_challenge.open_challenge(self, encounter)

func open_shortcut() -> void:
	GameState.open_realm_shortcut()
	if is_instance_valid(_shortcut_body): _shortcut_body.queue_free()
	if _monster_routes != null: _monster_routes.invalidate()
	pet.invalidate_routes()
	set_message("Rootway opened. The grove now loops directly to the citadel approach.")

func rest_at_camp() -> void:
	if _boss_arrived: return
	var game := get_tree().get_first_node_in_group("game") as Game
	if not is_instance_valid(game): return
	GameState.set_realm_checkpoint("camp")
	game.hud.release_world_controls()
	game._input_locked = true
	game._apply_input_lock()
	_camp_resting = true
	_camp_timer = 0
	set_message("Resting at the lantern…")

func exit_to_lobby(bank_loot: bool) -> void:
	var game := get_tree().get_first_node_in_group("game") as Game
	if _leaving or not is_instance_valid(game) or game.world != self or game._transitioning: return
	_leaving = true
	game.hud.release_world_controls()
	game._input_locked = true
	game._apply_input_lock()
	if bank_loot: GameState.leave_portal_safely()
	GameState.end_realm_visit()
	game.return_to_lobby(false)

func get_spawn_position() -> Vector2:
	return RealmDB.checkpoint_position(str(GameState.realm_progress().checkpoint))

func get_guidance_targets() -> Array:
	return [] # Landmarks, tracks and discovered map cells lead exploration.

func minimap_markers() -> Array:
	return []
