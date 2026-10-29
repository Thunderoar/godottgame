class_name StorySequence
extends CanvasLayer
## Illustrated, skippable story beats; one signal owns completion and cleanup.
signal completed
signal departure_covered
## Only the title handoff uses this prelude. Reading time starts after the reveal.
const ARRIVAL_OUT := 0.28
const ARRIVAL_HOLD := 0.06
const ARRIVAL_REVEAL := 0.64
const ARRIVAL_CAPTION := 0.22
const LOADING_IN := 0.12
const LOADING_READ := 0.55
const LOADING_OUT := 0.18
const INTRO_LANDFALL_PAGE := 3
const INTRO_CAPTURE_PAGE := 4
const INTRO_RESCUE_PAGE := 5
const INTRO_WELCOME_PAGE := 7
const INTRO := [
	"Adam, Arjun and Mei Ling went fishing together in a peaceful sea.",
	"Arjun's hook caught the arm of an enormous Kraken. The sea king awoke in fury!",
	"The Kraken smashed their ship into three pieces. The three friends were separated.",
	"Clinging to the broken bow, Mei Ling washed ashore at a guarded ruin.",
	"The Kraken imprisoned Arjun. The ruin's guards captured Mei Ling alive: \"Our ruler will want answers.\"",
	"A brave turtle rescued Adam and brought him to the villagers of BESUT.",
	"To repay their kindness, Adam protects BESUT and searches the sea for Arjun and the final portal for Mei Ling.",
	"\"Welcome to BESUT, Adam. Come, rest and make yourself at home.\" The villagers lead him in from the shore."
]
var kind := "intro"
var page := 0
var clock := 0.0
var _page_time := 0.0
var _caption: Label
var _canvas: StoryCanvas
var _next: Button
var _done := false
var _caption_panel: PanelContainer
var arrive_from_title := false
var include_loading_screen := false
var _opening_loading: LoadingScreen
var _arrival_active := false
var _arrival_time := 0.0
var _arrival_reduced := false
var _departure_emitted := false
var _curtain: ColorRect
var _skip: Button

func _ready() -> void:
	layer = 350
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	_canvas = StoryCanvas.new()
	_canvas.sequence = self
	_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(_canvas)
	var panel := GameUI.panel(Color("#102733"), Color("#bc9c61"))
	_caption_panel = panel
	panel.anchor_top = 1
	panel.anchor_bottom = 1
	panel.anchor_right = 1
	panel.offset_top = -174
	panel.offset_bottom = -18
	panel.offset_left = 24
	panel.offset_right = -24
	root.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	_caption = GameUI.label("", 22, GameUI.TEXT)
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_caption)
	var row := HBoxContainer.new()
	box.add_child(row)
	var skip := GameUI.button("Skip scene", Vector2(150, 42))
	_skip = skip
	skip.pressed.connect(finish)
	row.add_child(skip)
	var space := Control.new()
	space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(space)
	_next = GameUI.button("Next", Vector2(150, 42))
	_next.pressed.connect(advance)
	row.add_child(_next)
	_render()
	if arrive_from_title and kind == "intro":
		_arrival_active = true
		_arrival_reduced = GameSettings.reduce_motion()
		_curtain = ColorRect.new()
		_curtain.color = Color("#102733")
		_curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_curtain.mouse_filter = Control.MOUSE_FILTER_STOP
		root.add_child(_curtain)
		if include_loading_screen:
			_opening_loading = LoadingScreen.new()
			add_child(_opening_loading)
			_opening_loading.present("Adam's Journey", 0.0)
		GameSettings.changed.connect(_on_arrival_setting_changed)
		_apply_arrival()

static func sample_arrival(elapsed: float, reduced: bool, with_loading: bool = false) -> Dictionary:
	var fade_out := 0.12 if reduced else ARRIVAL_OUT
	var hold := 0.0 if reduced else ARRIVAL_HOLD
	var reveal := 0.16 if reduced else ARRIVAL_REVEAL
	var caption := 0.08 if reduced else ARRIVAL_CAPTION
	if with_loading:
		hold = LOADING_IN + LOADING_READ
		reveal = maxf(reveal, LOADING_OUT)
	var total := fade_out + hold + reveal
	var t := maxf(0.0, elapsed)
	var covered := t >= fade_out
	var reveal_progress := clampf((t - fade_out - hold) / reveal, 0.0, 1.0)
	var out_progress := clampf(t / fade_out, 0.0, 1.0)
	var veil := out_progress * out_progress * (3.0 - 2.0 * out_progress)
	if covered: veil = 1.0 - reveal_progress * reveal_progress * (3.0 - 2.0 * reveal_progress)
	var words := clampf((t - total + caption) / caption, 0.0, 1.0)
	var loading_alpha := 0.0
	if with_loading and covered:
		var loading_in := clampf((t - fade_out) / LOADING_IN, 0.0, 1.0)
		var loading_out := clampf((t - fade_out - hold) / LOADING_OUT, 0.0, 1.0)
		loading_alpha = loading_in * loading_in * (3.0 - 2.0 * loading_in)
		if loading_out > 0: loading_alpha = 1.0 - loading_out * loading_out * (3.0 - 2.0 * loading_out)
	return {"cover_alpha": veil, "art_alpha": 1.0 if covered else 0.0,
		"caption_alpha": words * words * (3.0 - 2.0 * words),
		"covered": covered, "ready": t + 0.000001 >= total, "duration": total,
		"loading_alpha": loading_alpha}

func arrival_state() -> Dictionary:
	return sample_arrival(_arrival_time, _arrival_reduced, include_loading_screen)

func opening_loader() -> LoadingScreen:
	return _opening_loading

func _apply_arrival() -> void:
	var state := arrival_state()
	_canvas.modulate.a = state.art_alpha
	_caption_panel.modulate.a = state.caption_alpha
	_curtain.modulate.a = state.cover_alpha
	if is_instance_valid(_opening_loading):
		_opening_loading.cover.modulate.a = state.loading_alpha
	_next.disabled = true
	_skip.disabled = true
	if state.covered and not _departure_emitted:
		_departure_emitted = true
		departure_covered.emit()
	if not _done and state.ready: _finish_arrival()

func _finish_arrival() -> void:
	if not _arrival_active: return
	_arrival_active = false
	if not _departure_emitted:
		_departure_emitted = true
		departure_covered.emit()
	_canvas.modulate.a = 1.0
	_caption_panel.modulate.a = 1.0
	_next.disabled = false
	_skip.disabled = false
	_curtain.hide()
	if is_instance_valid(_opening_loading):
		_opening_loading.dismiss()
		_opening_loading.queue_free()
		_opening_loading = null

func _on_arrival_setting_changed(key: String) -> void:
	if _arrival_active and key == "reduce_motion" and GameSettings.reduce_motion():
		# Shorten an in-flight dissolve, but never rewind it if the setting flips back.
		_arrival_reduced = true
		if not _departure_emitted and _arrival_time >= 0.12:
			# Still retire the title under a fully opaque frame when shortening mid-fade.
			_arrival_time = 0.12
		_apply_arrival()

func lines() -> Array:
	match kind:
		"arjun": return ["The sea king is defeated. Adam unlocks Arjun's prison!", "Arjun runs aboard the UNISZA ship. Together they sail back to BESUT."]
		"mei": return ["The final portal guardian falls. Mei Ling is free!", "Mei Ling follows Adam through the portal, back to BESUT Village."]
		"ending": return ["Adam, Arjun and Mei Ling are reunited in BESUT Village.", "Their fishing voyage crossed into another dimension. This island is now their home.", "With their friends and the villagers, they choose a peaceful new life in BESUT. THE END · Village life continues."]
	return INTRO

func _process(delta: float) -> void:
	if _done: return
	if _arrival_active:
		_arrival_time += maxf(0.0, delta)
		_apply_arrival()
		_canvas.queue_redraw()
		return
	clock += delta
	_page_time += delta
	_canvas.queue_redraw()
	if _page_time >= 6.0:
		advance()

func _render() -> void:
	_canvas.prepare_page()
	_caption.text = str(lines()[page])
	_next.text = "Continue" if page == lines().size() - 1 else "Next"

func advance() -> void:
	if _done: return
	_finish_arrival()
	page += 1
	_page_time = 0
	if page >= lines().size(): finish()
	else: _render()

func finish() -> void:
	if _done: return
	_finish_arrival()
	_done = true
	completed.emit()
	queue_free()

class StoryCanvas extends Control:
	var sequence: StorySequence
	var _fishing: OpeningFishingRenderer
	var _kraken: OpeningKrakenRenderer
	var _wreck: OpeningWreckRenderer
	var _capture: OpeningCaptureRenderer
	var _landfall: OpeningLandfallRenderer
	var _rescue: OpeningRescueRenderer
	var _welcome: OpeningWelcomeRenderer
	func _ready() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if is_instance_valid(sequence) and sequence.kind == "intro":
			_fishing = OpeningFishingRenderer.new()
			_kraken = OpeningKrakenRenderer.new()
		GameSettings.changed.connect(_on_presentation_changed)
	func _on_presentation_changed(key: String) -> void:
		if key in ["reduce_motion", "effects_quality"]: queue_redraw()
	func uses_fishing_shot() -> bool:
		return is_instance_valid(sequence) and sequence.kind == "intro" and sequence.page == 0
	func fishing_state() -> Dictionary:
		return OpeningFishingRenderer.sample(sequence._page_time, GameSettings.reduce_motion(), GameSettings.effects_quality())
	func uses_kraken_shot() -> bool:
		return is_instance_valid(sequence) and sequence.kind == "intro" and sequence.page == 1
	func kraken_state() -> Dictionary:
		return OpeningKrakenRenderer.sample(sequence._page_time, GameSettings.reduce_motion(), GameSettings.effects_quality())
	func uses_wreck_shot() -> bool:
		return is_instance_valid(sequence) and sequence.kind == "intro" and sequence.page == 2
	func uses_landfall_shot() -> bool:
		return is_instance_valid(sequence) and sequence.kind == "intro" and sequence.page == INTRO_LANDFALL_PAGE
	func landfall_state() -> Dictionary:
		return OpeningLandfallRenderer.sample(sequence._page_time, GameSettings.reduce_motion(), GameSettings.effects_quality())
	func uses_capture_shot() -> bool:
		return is_instance_valid(sequence) and sequence.kind == "intro" and sequence.page == INTRO_CAPTURE_PAGE
	func capture_state() -> Dictionary:
		return OpeningCaptureRenderer.sample(sequence._page_time, GameSettings.reduce_motion(), GameSettings.effects_quality())
	func uses_rescue_shot() -> bool:
		return is_instance_valid(sequence) and sequence.kind == "intro" and sequence.page == INTRO_RESCUE_PAGE
	func uses_rescue_epilogue() -> bool:
		return is_instance_valid(sequence) and sequence.kind == "intro" and sequence.page == INTRO_RESCUE_PAGE + 1
	func rescue_state() -> Dictionary:
		var elapsed := 6.0 if uses_rescue_epilogue() else sequence._page_time
		return OpeningRescueRenderer.sample(elapsed, GameSettings.reduce_motion(), GameSettings.effects_quality())
	func uses_welcome_shot() -> bool:
		return is_instance_valid(sequence) and sequence.kind == "intro" and sequence.page == INTRO_WELCOME_PAGE
	func welcome_state() -> Dictionary:
		return OpeningWelcomeRenderer.sample(sequence._page_time, GameSettings.reduce_motion(), GameSettings.effects_quality())
	func prepare_page() -> void:
		# Warm on entering this page, not in _draw or before the title curtain exists.
		if uses_wreck_shot() and _wreck == null:
			if _kraken == null: _kraken = OpeningKrakenRenderer.new()
			_wreck = OpeningWreckRenderer.new(_kraken)
		if uses_landfall_shot() and _landfall == null:
			_landfall = OpeningLandfallRenderer.new()
		if uses_capture_shot() and _capture == null:
			_capture = OpeningCaptureRenderer.new()
		if (uses_rescue_shot() or uses_rescue_epilogue()) and _rescue == null:
			_rescue = OpeningRescueRenderer.new()
		if uses_welcome_shot() and _welcome == null:
			if _rescue == null: _rescue = OpeningRescueRenderer.new()
			_welcome = OpeningWelcomeRenderer.new(_rescue)
	func wreck_state() -> Dictionary:
		return OpeningWreckRenderer.sample(sequence._page_time, GameSettings.reduce_motion(), GameSettings.effects_quality())
	func _draw() -> void:
		if not is_instance_valid(sequence): return
		if uses_welcome_shot():
			draw_rect(Rect2(Vector2.ZERO, size), Color("#102733"))
			var bottom := size.y - 184.0
			if is_instance_valid(sequence._caption_panel): bottom = sequence._caption_panel.position.y - 10.0
			if _welcome != null:
				_welcome.draw(self, Rect2(Vector2.ZERO, Vector2(size.x, maxf(1, bottom))), welcome_state())
			return
		if uses_fishing_shot():
			draw_rect(Rect2(Vector2.ZERO, size), Color("#102733"))
			var bottom := size.y - 184.0
			if is_instance_valid(sequence._caption_panel): bottom = sequence._caption_panel.position.y - 10.0
			if _fishing != null:
				_fishing.draw(self, Rect2(Vector2.ZERO, Vector2(size.x, maxf(1, bottom))), fishing_state())
			return
		if uses_kraken_shot():
			draw_rect(Rect2(Vector2.ZERO, size), Color("#102733"))
			var bottom := size.y - 184.0
			if is_instance_valid(sequence._caption_panel): bottom = sequence._caption_panel.position.y - 10.0
			if _kraken != null:
				_kraken.draw(self, Rect2(Vector2.ZERO, Vector2(size.x, maxf(1, bottom))), kraken_state())
			return
		if uses_wreck_shot():
			draw_rect(Rect2(Vector2.ZERO, size), Color("#102733"))
			var bottom := size.y - 184.0
			if is_instance_valid(sequence._caption_panel): bottom = sequence._caption_panel.position.y - 10.0
			if _wreck != null:
				_wreck.draw(self, Rect2(Vector2.ZERO, Vector2(size.x, maxf(1, bottom))), wreck_state())
			return
		if uses_landfall_shot():
			draw_rect(Rect2(Vector2.ZERO, size), Color("#102733"))
			var bottom := size.y - 184.0
			if is_instance_valid(sequence._caption_panel): bottom = sequence._caption_panel.position.y - 10.0
			if _landfall != null:
				_landfall.draw(self, Rect2(Vector2.ZERO, Vector2(size.x, maxf(1, bottom))), landfall_state())
			return
		if uses_capture_shot():
			draw_rect(Rect2(Vector2.ZERO, size), Color("#102733"))
			var bottom := size.y - 184.0
			if is_instance_valid(sequence._caption_panel): bottom = sequence._caption_panel.position.y - 10.0
			if _capture != null:
				_capture.draw(self, Rect2(Vector2.ZERO, Vector2(size.x, maxf(1, bottom))), capture_state())
			return
		if uses_rescue_shot() or uses_rescue_epilogue():
			draw_rect(Rect2(Vector2.ZERO, size), Color("#102733"))
			var bottom := size.y - 184.0
			if is_instance_valid(sequence._caption_panel): bottom = sequence._caption_panel.position.y - 10.0
			if _rescue != null:
				_rescue.draw(self, Rect2(Vector2.ZERO, Vector2(size.x, maxf(1, bottom))), rescue_state())
			return
		draw_set_transform(Vector2.ZERO, 0, size / Vector2(1280, 720))
		draw_rect(Rect2(0, 0, 1280, 720), Color("#102b40"))
		var t := sequence._page_time
		var p := sequence.page
		for i in 10:
			var y := 220.0 + i * 34
			draw_line(Vector2(0, y), Vector2(1280, y), Color("#245a71"), 2)
		if sequence.kind == "ending":
			draw_rect(Rect2(0, 280, 1280, 310), Color("#416e4b"))
			_tex(PixelArt.house_texture(3), Vector2(640, 250), Vector2(260, 270))
			for i in 3: _hero(["adam", "arjun", "mei_ling"][i], Vector2(510 + i * 130, 430), t)
			return
		if sequence.kind == "mei":
			draw_circle(Vector2(900, 250), 105, Color("#8056b4"))
			draw_circle(Vector2(900, 250), 75, Color("#16394c"))
			_hero("adam", Vector2(lerpf(550, 940, clampf(t / 5, 0, 1)), 370), t)
			_hero("mei_ling", Vector2(lerpf(410, 850, clampf(t / 5, 0, 1)), 370), t)
			return
		if sequence.kind == "arjun":
			draw_rect(Rect2(0, 310, 1280, 230), Color("#897d55"))
			var door := clampf(t / 2, 0, 1)
			for i in 6: draw_line(Vector2(340 + i * 25 + door * 170, 180), Vector2(340 + i * 25 + door * 170, 340), Color("#c1ccd2"), 6)
			_tex(PixelArt.ship_texture(), Vector2(900 - (t * 55 if p > 0 else 0), 365), Vector2(390, 210))
			_hero("arjun", Vector2(lerpf(400, 900, clampf(t / 4, 0, 1)), 320), t)
			_hero("adam", Vector2(790, 320), t)
			return
		if p < 3:
			var broken := p == 2
			if not broken: _tex(PixelArt.ship_texture(), Vector2(620, 330), Vector2(650, 300))
			else:
				for i in 3:
					draw_set_transform(Vector2(390 + i * 230, 340 + t * (8 + i * 3)), (i - 1) * t * 0.07, size / Vector2(1280, 720))
					draw_rect(Rect2(-80, -20, 160, 45), Color("#e1b644"))
				draw_set_transform(Vector2.ZERO, 0, size / Vector2(1280, 720))
			for i in 3: _hero(["adam", "arjun", "mei_ling"][i], Vector2(440 + i * 160, 290 + (t * 30 if broken else 0)), t)
			if p > 0:
				_tex(CampaignArt.kraken_texture(), Vector2(990 - sin(t * 2) * 25, 270), Vector2(400, 300))
				draw_line(Vector2(600, 240), Vector2(900, 220), Color("#e9e0b5"), 3)
		elif p == 3:
			_tex(CampaignArt.kraken_texture(), Vector2(350, 260), Vector2(350, 270))
			_hero("arjun", Vector2(570, 260), t)
			for i in 6: draw_line(Vector2(510 + i * 24, 150), Vector2(510 + i * 24, 310), Color("#a5b6c1"), 6)
			_hero("mei_ling", Vector2(980, 280), t)
			_tex(PixelArt.enemy_texture("drowned"), Vector2(1090, 300), Vector2(100, 120))
		else:
			draw_colored_polygon(PackedVector2Array([Vector2(760, 540), Vector2(800, 260), Vector2(1280, 180), Vector2(1280, 540)]), Color("#6b9c65"))
			_tex(CoastalArt.turtle_texture(false, int(t * 4) % 2), Vector2(500 + minf(t * 45, 300), 350), Vector2(290, 145))
			_hero("adam", Vector2(480 + minf(t * 45, 300), 270), t)
			_tex(PixelArt.npc_texture("water_keeper"), Vector2(1050, 280), Vector2(95, 135))
	func _tex(texture: Texture2D, centre: Vector2, extent: Vector2) -> void:
		draw_texture_rect(texture, Rect2(centre - extent / 2, extent), false)
	func _hero(id: String, at: Vector2, t: float) -> void:
		_tex(PixelArt.character_texture(id, 2, int(t * 4) % 2), at, Vector2(80, 95))
