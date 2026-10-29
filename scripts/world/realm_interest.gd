class_name RealmInterest
extends RealmInteractable
## Optional reading and treasure, guarded identically for E and direct touch.

func _ready() -> void:
	super._ready()
	art.texture = RealmContentArt.texture(kind)
	art.scale = Vector2.ONE * PixelArt.PX * 1.5
	art.position.y = -0.65
	refresh()

func refresh() -> void:
	if not is_instance_valid(label): return
	var progress := GameState.realm_progress()
	var suffix := "Speak" if kind == "waykeeper" else "Read memory"
	if kind == "memory" and stable_id in progress.get("read_fragments", []): suffix = "Read again"
	if kind == "cache":
		var opened := GameState.realm_cache_opened(stable_id)
		suffix = "Empty hollow" if opened else "Search the hollow"
		if is_instance_valid(art): art.texture = RealmContentArt.texture("cache_open" if opened else "cache")
	label.text = caption + "\n" + suffix
	prompt = caption + " · " + suffix

func _process(delta: float) -> void:
	super._process(delta)
	if kind != "waykeeper" or not is_instance_valid(art): return
	var realm := get_parent() as TwilightRealm
	if not is_instance_valid(realm) or not is_instance_valid(realm.player): return
	var near := realm.player.position.distance_to(position) < 4.0
	art.flip_h = realm.player.position.x < position.x
	art.modulate = Color("#fff3d4") if near else Color.WHITE

func interact(actor: Node) -> void:
	var realm := get_parent() as TwilightRealm
	if not is_instance_valid(realm) or not realm.can_read_interest(self, actor): return
	GameState.discover_realm_content(stable_id)
	match kind:
		"waykeeper":
			var words := RealmContentDB.waykeeper_words(GameState.realm_progress(), realm._boss_defeated)
			GameState.meet_realm_waykeeper()
			realm.show_reading(caption, words, position)
		"memory":
			GameState.read_realm_fragment(stable_id)
			var count: int = GameState.realm_progress().read_fragments.size()
			realm.show_reading(caption, str(RealmContentDB.INTERESTS[stable_id].text) + "\n\nMemory %d / 3 · Saved in Field Guide → Story & Sea" % count, position)
		"cache":
			var result := GameState.claim_realm_cache(stable_id)
			realm.show_reading(caption, str(result.message), position)
	refresh()
