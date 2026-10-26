class_name KrakenIsland
extends Node2D
## Final sea destination. Boss victory unlocks a real, interactable prison.
var zone_name := "Kraken King's Island"
var player: Player
var camera: Camera2D
var boss: KrakenKing
var cage: RescueCage
var defeated := false
var _rescuing := false
var _hint: Label

func _ready() -> void:
	Vfx.ensure_pool(self)
	for edge in [Rect2(0, 2, 40, 1), Rect2(0, 2, 1, 23), Rect2(39, 2, 1, 23), Rect2(0, 24, 40, 1)]:
		var body := StaticBody2D.new()
		body.collision_layer = 1
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = edge.size
		shape.shape = rect
		body.position = edge.get_center()
		body.add_child(shape)
		add_child(body)
	player = Player.new()
	player.position = Vector2(12, 21)
	add_child(player)
	camera = Camera2D.new()
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	camera.position = Vector2(20, 13)
	add_child(camera)
	camera.make_current()
	get_viewport().size_changed.connect(_fit_camera)
	_fit_camera()
	boss = KrakenKing.new()
	boss.position = Vector2(21, 9)
	boss.boss_finished.connect(_on_kraken_defeated)
	add_child(boss)
	cage = RescueCage.new()
	cage.island = self
	cage.position = Vector2(33, 8)
	cage.prompt = "Free Arjun"
	cage.available = false
	cage.interact_radius = 2.6
	add_child(cage)
	var exit := IslandExit.new()
	exit.position = Vector2(7, 21)
	exit.prompt = "Return to BESUT"
	add_child(exit)
	var layer := CanvasLayer.new()
	add_child(layer)
	_hint = GameUI.label("Defeat Vorath, the Kraken King. Then approach Arjun's prison and press Use.", 18, GameUI.GOLD)
	_hint.position = Vector2(28, 80)
	_hint.size = Vector2(700, 65)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layer.add_child(_hint)
	if bool(GameState.campaign().get("arjun_rescued", false)):
		cage.opened = true
		cage.get_child(cage.get_child_count() - 1).visible = false
		_hint.text = "Arjun is safe in BESUT. Challenge the Kraken again or return to shore."
	Sfx.start_battle_music("kraken_island")

func get_player() -> Player:
	return player

func get_map_rect() -> Rect2:
	return Rect2(0, 0, 40, 25)

func get_guidance_targets() -> Array:
	return [{"label": "FREE ARJUN" if defeated else "KRAKEN KING", "position": cage.position if defeated else Vector2(21, 9), "color": GameUI.GOLD}]

func _on_kraken_defeated(_enemy: Enemy) -> void:
	if defeated: return
	defeated = true
	cage.available = not bool(GameState.campaign().get("arjun_rescued", false))
	_hint.text = "The Kraken King is defeated! Open Arjun's prison with Use." if cage.available else "The Kraken King is defeated. Arjun is safe in BESUT; return to shore."
	Sfx.stop_battle_music()

func free_arjun() -> void:
	if not defeated or _rescuing or not is_instance_valid(player) or bool(GameState.campaign().get("arjun_rescued", false)): return
	_rescuing = true
	player.controls_locked = true
	cage.opened = true
	cage.available = false
	GameState.rescue_friend("arjun")
	var game := get_tree().get_first_node_in_group("game") as Game
	if is_instance_valid(game):
		game._arjun_returning = true
		await game.play_story("arjun")
		if is_instance_valid(game) and game.world == self: game.return_from_ocean()

func _draw() -> void:
	draw_rect(Rect2(-30, -30, 100, 90), Color("#163f57"))
	draw_rect(Rect2(1, 3, 38, 21), Color("#958968"))
	for i in 17:
		var x := 2.0 + fposmod(i * 7.2, 36)
		var y := 4.0 + fposmod(i * 3.1, 18)
		draw_circle(Vector2(x, y), 0.13, Color("#b1a181"))
	draw_rect(Rect2(4, 20, 5, 4), Color("#886b4e"))
	draw_texture_rect(CoastalArt.turtle_texture(), Rect2(2, 24, 5, 2.5), false)

class RescueCage extends Interactable:
	var island: KrakenIsland
	var opened := false
	func _ready() -> void:
		super._ready()
		var friend := Sprite2D.new()
		friend.texture = PixelArt.character_texture("arjun", 0)
		friend.scale = Vector2.ONE * PixelArt.PX * 1.5
		friend.position.y = -1
		add_child(friend)
	func _process(delta: float) -> void:
		super._process(delta)
		queue_redraw()
	func _draw() -> void:
		draw_rect(Rect2(-1.6, -3, 3.2, 3.3), Color("#293d4c"), false, 0.14)
		if not opened:
			for i in 7: draw_line(Vector2(-1.5 + i * 0.5, -3), Vector2(-1.5 + i * 0.5, 0.3), Color("#c1cbd0"), 0.08)
	func interact(actor: Node) -> void:
		if available and is_instance_valid(actor) and actor.global_position.distance_to(global_position) <= interact_radius: island.free_arjun()

class IslandExit extends Interactable:
	func interact(_actor: Node) -> void:
		var game := get_tree().get_first_node_in_group("game") as Game
		if is_instance_valid(game): game.return_from_ocean()

func _fit_camera() -> void:
	var view := get_viewport_rect().size
	camera.zoom = Vector2.ONE * minf(view.x / 43.0, view.y / 28.0)
