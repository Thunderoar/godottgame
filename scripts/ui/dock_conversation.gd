class_name DockConversation
extends CanvasLayer
## A player-paced conversation over the actual dock. Game owns world suspension.
signal completed

const PORTRAIT_PATH := "res://assets/authored/characters/pak_rahim.png"
const ADAM_PORTRAIT_PATH := "res://assets/authored/characters/adam_concerned.png"
const ADAM_SURPRISED_PATH := "res://assets/authored/characters/adam_surprised.png"
const ADAM_RESOLVED_PATH := "res://assets/authored/characters/adam_resolved.png"
const WORD_FADE_SECONDS := 0.12
const SPEECH_SPEED := 1.25
const REDUCED_FADE_SECONDS := 0.18
const WELCOME := [
	{"speaker": "Pak Rahim", "line": "Easy now, Adam. The dock's steady, even if your legs aren't. Here. Small sips."},
	{"speaker": "Adam", "expression": "concerned", "line": "There were three of us. Arjun. Mei Ling. Have you seen them?"},
	{"speaker": "Pak Rahim", "line": "Only you, I'm afraid. The turtle wouldn't leave until we'd brought you ashore. Stubborn little thing. A good friend to have."},
	{"speaker": "Adam", "expression": "concerned", "line": "Then I need to go back out. They could still be out there."},
	{"speaker": "Pak Rahim", "line": "I know. I won't ask you to give up on them. But you can barely hold that cup. Let us help you get your strength back first."},
	{"speaker": "Pak Rahim", "line": "I'm Rahim. I look after the village's water. Most days that means thirsty seedlings. Today, it means you. Welcome to BESUT."},
	{"speaker": "Adam", "expression": "surprised", "line": "You don't even know me. Why help?"},
	{"speaker": "Pak Rahim", "line": "You washed up on our shore, lad. That was introduction enough. There's a cottage ready for you. No debt attached."},
	{"speaker": "Pak Rahim", "line": "We have our troubles, too. After dark, creatures come for the trees and homes. We keep one another safe. You won't have to face your troubles alone, either."},
	{"speaker": "Adam", "expression": "resolved", "line": "When I'm steady, I'll help. And I'll find my friends. I just... don't know where to start."},
	{"speaker": "Pak Rahim", "line": "Explore the northern clearing when you're ready, Adam. There used to be an old road there. See what remains; it may help your search."},
	{"speaker": "Pak Rahim", "line": "And Adam? You can look for a way home and still have a place here. Both can be true."},
]
const REMINDER := [
	{"speaker": "Pak Rahim", "line": "Good to see you on your feet, Adam. A little steadier than our first morning, eh?"},
	{"speaker": "Pak Rahim", "line": "Get to know the neighbours, keep a few Health Potions in your pack, and look after the trees when night comes. Small things matter here."},
	{"speaker": "Pak Rahim", "line": "Your friends haven't been forgotten. Rest when you need to. The search can take more than one pair of hands."},
]

var introduction := true
var waystone := false
var road_reminder := ""
const WAYSTONE_READY := [
	{"speaker": "Pak Rahim", "line": "You already have the portal key, Adam. Take it to the locked portal in the northern clearing. Unlock the lantern's socket and the old road will answer."},
	{"speaker": "Pak Rahim", "line": "Take your time. Clear any creatures nearby before you work. You can look after yourself and keep searching for your friends."},
]
const WAYSTONE_OPEN := [
	{"speaker": "Pak Rahim", "line": "So the old road answered. My father would have liked to see that lantern burning again."},
	{"speaker": "Pak Rahim", "line": "I don't know what waits beyond it. Follow its light home when you need a rest. BESUT will be here."},
]
const WAYSTONE := [
	{"speaker": "Adam", "expression": "concerned", "line": "I found a fallen waystone in the northern clearing, but there's no portal. Do you know what happened to the old road?"},
	{"speaker": "Pak Rahim", "line": "That road has slept for years. My father kept its lantern, and I still have the key. Its light can call the portal back. The key costs nothing."},
	{"speaker": "Adam", "expression": "resolved", "line": "If the road is still there, someone beyond it might have seen my friends."},
	{"speaker": "Pak Rahim", "line": "Take this portal key, Adam. It fits the locked lantern by the old waystone in the northern clearing."},
	{"speaker": "Pak Rahim", "line": "Follow the arrow to the portal. Use Enter or E there to turn the key and unlock the road. Once it opens, choose Enter again when you're ready to explore."},
]
var page := 0
var cancelled := false
var _done := false
var _root: Control
var _panel: Panel
var _portrait: TextureRect
var _rahim_portrait: Texture2D
var _adam_portrait: Texture2D
var _adam_expressions: Dictionary[String, Texture2D] = {}
var _speaker: Label
var _role: Label
var _line: HFlowContainer
var _counter: Label
var _back: Button
var _next: Button
var _skip: Button
var _voice: AudioStreamPlayer
var _reveal_elapsed := 0.0
var _revealing := false
var _syllable := 0
var _words: Array[Label] = []
var _word_starts: Array[float] = []
var _reveal_duration := 0.0
var _voice_word := -1
var _word_font_size := 23

func _ready() -> void:
	layer = 350
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.theme = GameUI.theme().duplicate() as Theme
	_root.theme.set_color("font_shadow_color", "Label", Color.TRANSPARENT)
	add_child(_root)
	# A faint wash keeps the living dock visible; no opaque full-screen backdrop.
	var wash := ColorRect.new()
	wash.color = Color(0.12, 0.24, 0.25, 0.12)
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(wash)
	_panel = Panel.new()
	_panel.add_theme_stylebox_override("panel", GameUI.style(Color("#fff8e9"), Color("#86b6ae"), 2, 18))
	_root.add_child(_panel)
	var chapter := GameUI.label("BESUT JETTY", 13, Color("#527c79"))
	chapter.position = Vector2(26, 18)
	_panel.add_child(chapter)
	_speaker = GameUI.title("", 30, Color("#345e61"))
	_speaker.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	_speaker.position = Vector2(26, 43)
	_panel.add_child(_speaker)
	_role = GameUI.label("", 14, Color("#678580"))
	_role.position = Vector2(27, 82)
	_panel.add_child(_role)
	_line = HFlowContainer.new()
	_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_line.add_theme_constant_override("v_separation", 2)
	_line.position = Vector2(26, 113)
	_panel.add_child(_line)
	_portrait = TextureRect.new()
	_portrait.name = "SpeakerPortrait"
	_rahim_portrait = load(PORTRAIT_PATH) as Texture2D
	_adam_portrait = load(ADAM_PORTRAIT_PATH) as Texture2D
	_adam_expressions = {
		"concerned": _adam_portrait,
		"surprised": load(ADAM_SURPRISED_PATH) as Texture2D,
		"resolved": load(ADAM_RESOLVED_PATH) as Texture2D,
	}
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_portrait)
	_back = _button("Back", _previous)
	_next = _button("Next", advance)
	_skip = _button("Skip conversation" if introduction or waystone else "Leave", finish)
	_skip.add_theme_font_size_override("font_size", 14)
	_counter = GameUI.label("", 14, Color("#678580"))
	_panel.add_child(_counter)
	_voice = AudioStreamPlayer.new()
	_voice.name = "DialogueVoice"
	_voice.bus = "Master"
	add_child(_voice)
	GameSettings.changed.connect(_on_presentation_changed)
	_apply_voice_volume()
	_root.resized.connect(_fit)
	_fit()
	_render()

func _button(text: String, action: Callable) -> Button:
	var button := GameUI.button(text, Vector2(112, 44))
	button.add_theme_stylebox_override("normal", GameUI.style(Color("#e4f1e8"), Color("#96bdb0"), 1, 9))
	button.add_theme_stylebox_override("hover", GameUI.style(Color("#cee9df"), Color("#5c9d94"), 2, 9))
	button.add_theme_stylebox_override("disabled", GameUI.style(Color("#f0f0e3"), Color("#c8d4c1"), 1, 9))
	button.add_theme_color_override("font_disabled_color", Color("#8f9d91"))
	button.add_theme_color_override("font_color", Color("#345e61"))
	button.pressed.connect(action)
	_panel.add_child(button)
	return button

func _fit() -> void:
	var viewport := _root.size
	var width := minf(1120, viewport.x - 40)
	var compact := width < 900
	var height := 304.0 if compact else 284.0
	_panel.position = Vector2((viewport.x - width) * 0.5, viewport.y - height - 24)
	_panel.size = Vector2(width, height)
	var art_width := 250.0 if compact else 326.0
	_portrait.size = Vector2(art_width, minf(430, viewport.y - 56))
	_portrait.position = Vector2(_panel.position.x + width - art_width - 12, _panel.position.y + height - _portrait.size.y - 2)
	_line.size = Vector2(width - art_width - 54, height - 174)
	_word_font_size = 20 if compact else 23
	_line.add_theme_constant_override("h_separation", 6 if compact else 7)
	for word in _words: word.add_theme_font_size_override("font_size", _word_font_size)
	_back.position = Vector2(26, height - 58)
	_next.position = Vector2(150, height - 58)
	_next.size = Vector2(146, 44)
	_counter.position = Vector2(314, height - 45)
	_skip.position = Vector2(width - art_width - 178, 28)
	_skip.size = Vector2(162, 36)

func entries() -> Array:
	if waystone: return WAYSTONE
	if not introduction and road_reminder == "ready": return WAYSTONE_READY
	if not introduction and road_reminder == "open": return WAYSTONE_OPEN
	return WELCOME if introduction else REMINDER

func _render() -> void:
	var entry: Dictionary = entries()[page]
	_speaker.text = str(entry.speaker)
	_role.text = "Village water keeper" if entry.speaker == "Pak Rahim" else "Still finding his feet"
	_prepare_words(str(entry.line))
	_portrait.texture = _adam_expressions.get(str(entry.get("expression", "concerned")), _adam_portrait) if entry.speaker == "Adam" else _rahim_portrait
	_back.disabled = page == 0
	_next.text = ("To the waystone" if waystone else "Let's begin") if page == entries().size() - 1 else "Next"
	_counter.text = "%02d / %02d" % [page + 1, entries().size()]
	_voice.stop()
	_reveal_elapsed = 0.0
	_syllable = 0
	_voice_word = 0
	_revealing = true
	_next.text = "Reveal"
	_play_syllable()

static func word_seconds(word: String) -> float:
	var spoken := word.trim_suffix(".").trim_suffix(",").trim_suffix("?").trim_suffix("!")
	var duration := clampf(0.16 + float(spoken.length()) * 0.022, 0.20, 0.38)
	if word.ends_with("..."): duration += 0.52
	elif word.ends_with(".") or word.ends_with("?") or word.ends_with("!"): duration += 0.36
	elif word.ends_with(",") or word.ends_with(":") or word.ends_with(";"): duration += 0.18
	return duration / SPEECH_SPEED

func _prepare_words(text: String) -> void:
	for word in _words:
		_line.remove_child(word)
		word.queue_free()
	_words.clear()
	_word_starts.clear()
	var start := 0.0
	# Every word occupies its final position from the start. Fading alpha rather
	# than inserting text keeps wrapping and the dialogue box perfectly still.
	for token in text.split(" ", false):
		var word := GameUI.label(token, _word_font_size, Color("#334c50"))
		word.mouse_filter = Control.MOUSE_FILTER_IGNORE
		word.modulate.a = 0.0
		_line.add_child(word)
		_words.append(word)
		_word_starts.append(start)
		start += word_seconds(token)
	_reveal_duration = _word_starts[-1] + WORD_FADE_SECONDS if not _word_starts.is_empty() else 0.0

func _process(delta: float) -> void:
	if _done or not _revealing: return
	_reveal_elapsed += maxf(0.0, delta)
	var reduced := GameSettings.reduce_motion()
	var elapsed := _reveal_elapsed * (_reveal_duration / REDUCED_FADE_SECONDS) if reduced else _reveal_elapsed
	if _reveal_elapsed >= (REDUCED_FADE_SECONDS if reduced else _reveal_duration):
		reveal_line()
		return
	var current := 0
	for i in _words.size():
		_words[i].modulate.a = smoothstep(0.0, WORD_FADE_SECONDS, elapsed - _word_starts[i])
		if elapsed >= _word_starts[i]: current = i
	if current != _voice_word:
		_voice_word = current
		_voice.stop()
		# A slow frame can cross several words. Speak only the current word,
		# never a backlog, and stay silent through the punctuation pauses.
		if not reduced and elapsed - _word_starts[current] < WORD_FADE_SECONDS: _play_syllable()

func reveal_line() -> void:
	_revealing = false
	for word in _words: word.modulate.a = 1.0
	_voice.stop()
	_next.text = ("To the waystone" if waystone else "Let's begin") if page == entries().size() - 1 else "Next"

func _play_syllable() -> void:
	if not _revealing or GameSettings.mute_all() or GameSettings.master_volume() <= 0 or GameSettings.effects_volume() <= 0: return
	_voice.stream = Sfx.dialogue_voice(str(entries()[page].speaker), _syllable)
	_voice.pitch_scale = [1.0, 1.035, 0.975, 1.015][_syllable % 4]
	_syllable += 1
	_voice.play()

func _apply_voice_volume() -> void:
	_voice.volume_db = -12.0 + GameSettings.volume_percent_to_db(GameSettings.effects_volume())
	if GameSettings.mute_all() or GameSettings.master_volume() <= 0 or GameSettings.effects_volume() <= 0: _voice.stop()

func _on_presentation_changed(key: String) -> void:
	if key in ["effects_volume", "master_volume", "mute_all"]: _apply_voice_volume()
	if key == "reduce_motion" and GameSettings.reduce_motion() and _revealing: reveal_line()

func _previous() -> void:
	if _done or page == 0: return
	page -= 1
	_render()

func advance() -> void:
	if _done: return
	if _revealing:
		reveal_line()
		return
	if page == entries().size() - 1:
		finish()
		return
	page += 1
	_render()

func _input(event: InputEvent) -> void:
	if _done: return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_E]:
			get_viewport().set_input_as_handled()
			# Player polls actions in physics: handled GUI input alone cannot
			# stop the final E from immediately talking to the dock host again.
			if event.keycode == KEY_E: Input.action_release("interact")
			advance()
		elif event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			finish()

func finish() -> void:
	if _done: return
	_done = true
	_revealing = false
	_voice.stop()
	set_process(false)
	completed.emit()
	queue_free()

func cancel() -> void:
	cancelled = true
	finish()
