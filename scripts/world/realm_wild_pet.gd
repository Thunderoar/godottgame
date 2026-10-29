class_name RealmWildPet
extends RealmInteractable
## Small authored home routines. Nearby visitors are noticed, never chased away.

var _routine_time := 0.0
var _step := 0
var _rest := 4.0
var _companion_here := false
var _offsets: Array = []
var pose := "rest"

func _ready() -> void:
	super._ready()
	_offsets = [Vector2(-1.0,0.3), Vector2(0.7,-0.5), Vector2.ZERO] if stable_id == "bramble_cat" else [Vector2(-0.8,-0.6),Vector2(0.9,-0.4),Vector2.ZERO]
	refresh()

func refresh() -> void:
	super.refresh()
	if not is_instance_valid(art): return
	_companion_here = GameState.active_pet_id() == stable_id
	art.texture = RealmContentArt.texture("bond") if _companion_here else PixelArt.pet_texture(stable_id)
	art.scale = Vector2.ONE * PixelArt.PX * (1.0 if _companion_here else 1.5)
	if _companion_here:
		label.text = caption + "'s clearing\nRest together"
		prompt = "Rest in your companion's clearing"

func _process(delta: float) -> void:
	super._process(delta)
	var game := get_tree().get_first_node_in_group("game") as Game
	if not is_instance_valid(game) or game.world != get_parent() or game._transitioning: return
	if _companion_here != (GameState.active_pet_id() == stable_id): refresh()
	_routine_time += delta
	var nearby := is_instance_valid(game.player()) and game.player().position.distance_to(position) < 4.2
	if _companion_here or GameSettings.reduce_motion():
		position = _home
		pose = "rest"
	elif nearby:
		pose = "notice"
		art.flip_h = game.player().position.x < position.x
	else:
		_rest -= delta
		if _rest > 0:
			pose = "sniff" if _rest < 1.0 else "rest"
		else:
			pose = "walk" if stable_id == "bramble_cat" else "flutter"
			var target: Vector2 = _home + _offsets[_step]
			art.flip_h = target.x < position.x
			position = position.move_toward(target, delta * (0.48 if stable_id == "bramble_cat" else 0.55))
			if position.distance_to(target) < 0.01:
				_step = (_step + 1) % _offsets.size()
				_rest = 4.0 + float(_step)
	art.position.y = -0.65
	art.scale = Vector2.ONE * PixelArt.PX * (1.0 if _companion_here else 1.5)
	if not _companion_here:
		var frame := 0
		if not GameSettings.reduce_motion():
			if pose == "walk": frame = 3 if int(_routine_time * 7) % 2 == 0 else 0
			elif pose == "sniff" or fmod(_routine_time, 6.0) > 5.6: frame = 2
		art.texture = PixelArt.pet_texture(stable_id, frame)
	if not GameSettings.reduce_motion() and not _companion_here:
		art.position.y += sin(_routine_time * (7.0 if pose == "walk" else 2.2)) * (0.025 if stable_id == "bramble_cat" else 0.10)
		if pose == "sniff" and stable_id == "bramble_cat": art.position.y += 0.06
		if stable_id == "dusk_moth": art.scale.x *= 0.90 + sin(_routine_time * 4.0) * 0.10

func interact(actor: Node) -> void:
	refresh()
	if _companion_here:
		var realm := get_parent() as TwilightRealm
		if is_instance_valid(realm) and realm.can_read_interest(self, actor):
			realm.show_reading(caption + "'s clearing", "Your companion settles beside you. This clearing already belongs to a friend.", _home)
		return
	super.interact(actor)
