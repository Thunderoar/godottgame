extends Node
## Headless probe for the attack pipeline: verifies phases, hit timing,
## slash visibility and damage application without a display.


func _ready() -> void:
	GameState.delete_save()
	var game: Game = load("res://scenes/game.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	await game.call("_on_character_selected", "qayyim")
	await get_tree().create_timer(0.4).timeout
	var hud: GameHUD = game.get("hud")
	hud.tutorial_guide.call("_skip")
	var p: Player = game.call("player")
	p.global_position = Vector2(34.0, 30.0)
	var dummy := Enemy.new()
	dummy.kind = "bogling"
	dummy.max_hp = 500
	dummy.damage = 0
	dummy.speed = 0.0
	dummy.position = p.global_position + Vector2(1.6, 0.0)
	game.world.add_child(dummy)
	p.facing = Vector2.RIGHT
	await get_tree().process_frame

	var ok := true
	var slash: Sprite2D = p.get_node_or_null("Slash")
	_check(slash != null, "slash sprite exists")
	var struck: bool = bool(p.call("try_attack"))
	_check(struck, "try_attack accepted")
	_check(p.attacking, "attacking flag set during anticipation")
	var saw_slash := false
	var hit_at := -1.0
	var elapsed := 0.0
	var hp0 := dummy.hp
	for i in 20:
		await get_tree().create_timer(0.05).timeout
		elapsed += 0.05
		if slash != null and slash.visible:
			saw_slash = true
		if hit_at < 0.0 and dummy.hp < hp0:
			hit_at = elapsed
	_check(saw_slash, "slash arc visible during the swing (elapsed %.2f)" % elapsed)
	_check(hit_at > 0.0, "damage landed on the active frame (%.2fs)" % hit_at if hit_at > 0.0 else "damage never landed")
	_check(hit_at >= 0.05 and hit_at <= 0.2, "hit frame within sword wind-up window (%.2fs)" % hit_at)
	await get_tree().create_timer(0.5).timeout
	_check(not p.attacking, "attacking cleared after recovery")
	_check(dummy.hp < hp0, "dummy kept its damage")
	dummy.queue_free()

	# Enemy telegraph: a fresh dummy should wind up visibly before damaging.
	var dummy2 := Enemy.new()
	dummy2.kind = "bogling"
	dummy2.max_hp = 300
	dummy2.damage = 0
	dummy2.speed = 0.0
	dummy2.position = p.global_position + Vector2(0.8, 0.0)
	game.world.add_child(dummy2)
	await get_tree().create_timer(0.1).timeout
	var state_name := ""
	var windup_seen := false
	for i in 30:
		await get_tree().create_timer(0.05).timeout
		var s: int = int(dummy2.get("_state"))
		if s == 4:  # State.WINDUP
			windup_seen = true
			state_name = "WINDUP"
	var telegraph: Sprite2D = dummy2.get_node_or_null("Telegraph") if dummy2.get_child_count() > 2 else null
	_check(windup_seen, "enemy enters WINDUP before attacking (state %s)" % state_name)
	dummy2.queue_free()

	print("--- attack probe: %s ---" % ("PASS" if ok else "FAIL"))
	get_tree().quit(0 if ok else 1)


func _check(condition: bool, label: String) -> void:
	print("[%s] %s" % ["OK" if condition else "FAIL", label])
	if not condition:
		ok = false


var ok := true
