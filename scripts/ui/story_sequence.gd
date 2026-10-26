class_name StorySequence
extends CanvasLayer
## Illustrated, skippable story beats; one signal owns completion and cleanup.
signal completed
const INTRO := [
	"Adam, Arjun and Mei Ling went fishing together in a peaceful sea.",
	"Arjun's hook caught the arm of an enormous Kraken. The sea king awoke in fury!",
	"The Kraken smashed their ship into three pieces. The three friends were separated.",
	"Arjun was dragged to the Kraken's island and locked in a prison. Monsters captured Mei Ling.",
	"A brave turtle rescued Adam and brought him to the villagers of BESUT.",
	"To repay their kindness, Adam protects BESUT and searches the sea for Arjun and the final portal for Mei Ling."
]
var kind := "intro"
var page := 0
var clock := 0.0
var _page_time := 0.0
var _caption: Label
var _canvas: StoryCanvas
var _next: Button
var _done := false

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
	skip.pressed.connect(finish)
	row.add_child(skip)
	var space := Control.new()
	space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(space)
	_next = GameUI.button("Next", Vector2(150, 42))
	_next.pressed.connect(advance)
	row.add_child(_next)
	_render()

func lines() -> Array:
	match kind:
		"arjun": return ["The sea king is defeated. Adam unlocks Arjun's prison!", "Arjun runs aboard the UNISZA ship. Together they sail back to BESUT."]
		"mei": return ["The final portal guardian falls. Mei Ling is free!", "Mei Ling follows Adam through the portal, back to BESUT Village."]
		"ending": return ["Adam, Arjun and Mei Ling are reunited in BESUT Village.", "Their fishing voyage crossed into another dimension. This island is now their home.", "With their friends and the villagers, they choose a peaceful new life in BESUT. THE END · Village life continues."]
	return INTRO

func _process(delta: float) -> void:
	clock += delta
	_page_time += delta
	_canvas.queue_redraw()
	if _page_time >= 6.0:
		advance()

func _render() -> void:
	_caption.text = str(lines()[page])
	_next.text = "Continue" if page == lines().size() - 1 else "Next"

func advance() -> void:
	if _done: return
	page += 1
	_page_time = 0
	if page >= lines().size(): finish()
	else: _render()

func finish() -> void:
	if _done: return
	_done = true
	completed.emit()
	queue_free()

class StoryCanvas extends Control:
	var sequence: StorySequence
	func _draw() -> void:
		if not is_instance_valid(sequence): return
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
