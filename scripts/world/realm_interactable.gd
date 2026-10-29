class_name RealmInteractable
extends Interactable
## Direct touch/E interaction in the current realm, with no destination menu.

var kind := "pet"
var stable_id := ""
var caption := ""
var art: Sprite2D
var label: Label
var _home := Vector2.ZERO

func _ready() -> void:
	super._ready()
	_home = position
	interact_radius = 2.5
	art = Sprite2D.new()
	art.texture = PixelArt.pet_texture(stable_id) if kind == "pet" else PixelArt.icon("portal" if kind in ["exit", "passage"] else "spark")
	art.scale = Vector2.ONE * PixelArt.PX * (1.5 if kind == "pet" else 1.0)
	art.position.y = -0.65
	art.texture_filter = VisualStyle.texture_filter()
	add_child(art)
	if kind in ["exit", "passage"]:
		art.texture = PixelArt.portal_frame_texture("pet" if kind == "exit" else "chaos")
		art.centered = false
		art.offset = Vector2(-40,-112)
		art.position.y = 0
		var swirl := Sprite2D.new()
		swirl.texture = PixelArt.portal_swirl_texture("pet" if kind == "exit" else "chaos",0)
		swirl.centered = false
		swirl.offset = Vector2(-24,-92)
		swirl.scale = Vector2.ONE * PixelArt.PX
		add_child(swirl)
		move_child(swirl,0)
	label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = caption
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color("#e8dbb9"))
	label.add_theme_color_override("font_outline_color", Color("#151a2b"))
	label.add_theme_constant_override("outline_size", 4)
	label.scale = Vector2.ONE * PixelArt.PX
	label.position = Vector2(-3, -2.1)
	label.size = Vector2(192, 48)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)
	refresh()

func refresh() -> void:
	if not is_instance_valid(label): return
	if kind == "pet":
		var bonded := GameState.realm_pet_bonded(stable_id)
		label.text = "%s\n%s" % [caption, "Bonded · friendly spar" if bonded else "Wild · approach to challenge"]
	elif kind == "passage":
		var reason := GameState.portal_clear_reason(stable_id)
		label.text = "%s\n%s" % [caption, "Enter" if bool(reason.ok) else str(reason.reason)]
	elif kind == "shortcut":
		label.text = "Rootway winch\n" + ("Shortcut open" if GameState.realm_progress().shortcut else "Open the shortcut")
	else:
		label.text = caption
	prompt = label.text.replace("\n", " · ")

func _process(delta: float) -> void:
	super._process(delta)
	var game := get_tree().get_first_node_in_group("game") as Game
	if is_instance_valid(game) and is_instance_valid(game.player()):
		label.visible = game.player().global_position.distance_to(global_position) < (4.0 if kind == "passage" else 6.0)
		var realm := get_parent() as TwilightRealm
		if kind == "shortcut" and is_instance_valid(realm) and realm.combat != null and realm.combat.active_id == "watchpost_guard":
			label.visible = false # The HUD hint owns this fight; keep its lanes readable.
	if kind == "pet" and is_instance_valid(art):
		art.position.y = -0.65 + (0.0 if GameSettings.reduce_motion() else sin(_bob * 1.8) * 0.045)
		art.flip_h = sin(_bob * 0.3) > 0.8

func interact(actor: Node) -> void:
	var game := get_tree().get_first_node_in_group("game") as Game
	var realm := get_parent() as TwilightRealm
	if not is_instance_valid(game) or not is_instance_valid(realm) or game.world != realm or game._input_locked or game._transitioning or game._defeat_pending or not is_instance_valid(actor): return
	if actor != game.player() or actor.dead or actor.sleeping or actor.global_position.distance_to(global_position) > interact_radius: return
	match kind:
		"pet": realm.challenge_pet(self)
		"exit": realm.exit_to_lobby(true)
		"shortcut": realm.open_shortcut()
		"camp": realm.rest_at_camp()
		"passage":
			var reason := GameState.portal_clear_reason(stable_id)
			if bool(reason.ok): game.enter_portal(stable_id)
			else: realm.set_message(str(reason.reason))
	refresh()
