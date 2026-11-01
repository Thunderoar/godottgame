extends RefCounted
## Real live-world frames; no whole-world process-mode override is used by dialogue.
static func run(game: Game, check: Callable, capture: Callable = Callable()) -> void:
	var snapshot := GameState.data.duplicate(true)
	var ticking := game.is_processing()
	var automatic := game._side_quest_auto_enabled
	var autosave := GameState.autosave_enabled
	game.set_process(false)
	game._side_quest_auto_enabled = false
	game.hud.hide_modals()
	GameState.autosave_enabled = false
	GameState.data = GameState._make_default("adam")
	GameState.data.campaign.dock_welcome_seen = true
	GameState.data.campaign.urchin_intro_seen = true
	GameState.data.campaign.fire_intro_seen = true
	await game._load_lobby(false)
	var home := game.world as Lobby
	var player := game.player()
	game.hud.visible = true
	var turtle: BeachTurtle
	for node in game.get_tree().get_nodes_in_group("beach_turtle"):
		if home.is_ancestor_of(node): turtle = node; break
	var enemy := Enemy.new()
	enemy.position = player.position+Vector2(5,0)
	home.add_child(enemy)
	var disabled := Node.new()
	home.add_child(disabled)
	disabled.set_physics_process(false)
	var mode := home.process_mode
	var player_physics := player.is_physics_processing()
	var enemy_physics := enemy.is_physics_processing()
	Input.action_press("move_right")
	Input.action_press("attack")
	Input.action_press("sprint")
	game.open_dialogue("Pak Rahim",["The tide keeps moving. Take your time."])
	var hold := game._dialogue_hold
	check.call(game.dialogue_holding(home) and home.process_mode==mode and home.is_processing() and not game.get_tree().paused,"dialogue holds gameplay callbacks without disabling the world or pausing the tree")
	check.call(game.hud.visible and not game.hud._attack_button.visible and not game.hud._joystick.visible,"dialogue preserves the HUD and hides/releases only world controls")
	check.call(not Input.is_action_pressed("move_right") and not Input.is_action_pressed("attack") and not Input.is_action_pressed("sprint"),"starting dialogue releases held movement, attack and sprint")
	check.call(not player.is_physics_processing() and not enemy.is_physics_processing() and player.velocity==Vector2.ZERO,"player and enemy hold position without residual sliding")
	var at := player.position
	var enemy_at := enemy.position
	var pet_at := home.pet.position
	var time := float(GameState.data.world_time)
	var ambient := turtle._time
	game._process(1)
	await game.get_tree().create_timer(0.2).timeout
	check.call(float(GameState.data.world_time)>time and turtle._time>ambient and player.position==at and enemy.position==enemy_at and home.pet.position==pet_at,"real frames advance world time and ambient breathing while actors stay fixed")
	game._sync_village_music()
	check.call(not game._village_music.stream_paused,"ordinary dialogue retains continuous village music")
	var hp := GameState.health()
	var enemy_hp := enemy.hp
	player.invulnerable = 0
	player.take_damage(5,enemy.position)
	enemy.take_damage(5,Vector2.ZERO,player)
	check.call(GameState.health()==hp and enemy.hp==enemy_hp,"late player/enemy damage callbacks cannot hurt either side during dialogue")
	var tree := home._forest_trees[0] as ForestTree
	var tree_hp := tree.health
	var resident := home._residents[0] as Resident
	var resident_hp := GameState.resident_health(resident.resident_name)
	var structure: SettlementTarget
	for node in game.get_tree().get_nodes_in_group("settlement_target"):
		if node is SettlementTarget and home.is_ancestor_of(node) and not node.structure_id.is_empty(): structure = node; break
	var structure_before := GameState.structure_state(structure.structure_id)
	structure.take_attack_damage(50)
	check.call(GameState.structure_state(structure.structure_id)==structure_before,"late structure damage cannot undermine village safety while actors are held")
	tree.take_attack_damage(5)
	resident.take_attack_damage(5)
	check.call(tree.health==tree_hp and GameState.resident_health(resident.resident_name)==resident_hp and not tree.is_processing(),"trees and residents are protected and tree burn/growth callbacks are held")
	var late := Enemy.new()
	late.position = enemy.position+Vector2(1,0)
	home.add_child(late)
	check.call(not late.is_physics_processing(),"actors created while dialogue is open join the hold before their first physics tick")
	if capture.is_valid(): await capture.call("dialogue_live_village")
	game.hud.dialogue_panel.close_panel()
	check.call(not game.dialogue_holding() and player.is_physics_processing()==player_physics and enemy.is_physics_processing()==enemy_physics and late.is_physics_processing() and not disabled.is_physics_processing() and game.hud._attack_button.visible,"closing restores each original callback flag, including newly held and already-disabled nodes")
	game._end_dialogue_hold(hold)
	check.call(not player.controls_locked and home.process_mode==mode,"releasing a hold twice cannot leave controls locked or change world process mode")
	game.open_menu()
	check.call(not game.dialogue_holding() and enemy.is_physics_processing(),"ordinary menus retain their existing live simulation rather than becoming dialogue holds")
	game.hud.menu_panel.close_panel()
	# Cross night while reading: lighting/clock continue, hostile arrival waits for close.
	enemy.queue_free()
	late.queue_free()
	await game.get_tree().process_frame
	GameState.data.world_time = 179.5
	game.open_dialogue("Pak Rahim",["The evening light changes, but we can finish speaking first."])
	game._process(1)
	check.call(GameState.is_night() and not is_instance_valid(home._urchin_cue) and not is_instance_valid(game._urchin_arrival),"night crossing updates time without starting a hostile arrival or nested cinematic mid-dialogue")
	game.hud.dialogue_panel.close_panel()
	await game.get_tree().process_frame
	check.call(is_instance_valid(home._urchin_cue),"closing rechecks the current night once and resumes the ordinary warned arrival")
	# A replacement must inherit neither the hold nor the old dialogue modal.
	game.open_dialogue("Pak Rahim",["We will speak again."])
	await game._load_dungeon(RealmDB.PORTAL,false)
	check.call(not game.dialogue_holding() and not game.hud.dialogue_panel.visible and game.world is TwilightRealm and game.player().is_physics_processing() and not game.player().controls_locked,"world replacement dismisses ordinary dialogue and restores only the retiring world's callback ownership")
	# Citadel conversations use the same hold while its inherited torch ambience runs.
	var realm := game.world as TwilightRealm
	realm.player.position = RealmDB.CAMP
	realm.pet.position = RealmDB.CAMP+Vector2(-1,0.5)
	realm.camera.position = RealmDB.CAMP
	realm.camera.force_update_scroll()
	game.play_citadel_sequence(realm,"preparation")
	var flicker := realm._flicker_time
	var clock := float(GameState.data.world_time)
	game._process(1)
	await game.get_tree().create_timer(0.2).timeout
	check.call(game.dialogue_holding(realm) and realm.process_mode!=Node.PROCESS_MODE_DISABLED and realm._flicker_time>flicker and float(GameState.data.world_time)>clock,"Citadel reading keeps live torch ambience and time instead of stopping its world")
	check.call(not realm.combat.combat_allowed() and not realm.player.is_physics_processing() and not realm.pet.is_physics_processing(),"Citadel hold blocks stale reinforcement/attack ownership and both player/companion movement")
	if capture.is_valid(): await capture.call("dialogue_live_citadel")
	game._citadel_conversation.cancel()
	await game._load_lobby(false)
	GameState.data = snapshot
	GameState._emit_all()
	GameState.autosave_enabled = autosave
	game._side_quest_auto_enabled = automatic
	game.set_process(ticking)
