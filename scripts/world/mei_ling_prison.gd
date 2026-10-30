class_name MeiLingPrison
extends Node2D
## Nonblocking scenery: the rescue transaction owns the captive/open state.
var opened := false

func _ready() -> void:
	name = "MeiLingPrison"
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scale = Vector2.ONE * PixelArt.PX
	GameState.data_changed.connect(refresh)
	refresh()

func refresh() -> void:
	opened = bool(GameState.campaign().get("mei_ling_rescued", false))
	queue_redraw()

func _draw() -> void:
	MeiLingRescueArt.draw_prison(self, Vector2.ZERO, 1.0 if opened else 0.0, not opened, 0.0 if opened else 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(-48,14), "Prison opened" if opened else "Mei Ling", HORIZONTAL_ALIGNMENT_CENTER, 96, 12, Color("#f3dfb7"))
