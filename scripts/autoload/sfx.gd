extends Node
## Tiny procedural sound-effect bus. No external audio assets are required:
## short PCM tones are synthesized once, cached and played through a small pool
## of AudioStreamPlayers. Used for forest impacts, aggro/charge cues and pet
## battle skill feedback.

const MIX_RATE := 22050
const PLAYER_POOL := 8

var _cache: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0


func _ready() -> void:
	for i in PLAYER_POOL:
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		player.volume_db = -7.0
		add_child(player)
		_players.append(player)


func _exit_tree() -> void:
	for player in _players:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	_players.clear()
	_cache.clear()


func play(kind: String, volume_db: float = -7.0) -> void:
	if _players.is_empty():
		return
	var stream := _get_stream(kind)
	if stream == null:
		return
	var player := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	player.stream = stream
	player.volume_db = volume_db
	player.play()


func has_sound(kind: String) -> bool:
	return _get_stream(kind) != null


func _get_stream(kind: String) -> AudioStreamWAV:
	if _cache.has(kind):
		return _cache[kind] as AudioStreamWAV
	var stream := _build_stream(kind)
	if stream == null:
		return null
	_cache[kind] = stream
	return stream


func _build_stream(kind: String) -> AudioStreamWAV:
	var duration := 0.12
	var start_freq := 180.0
	var end_freq := 140.0
	var noise_amount := 0.35
	match kind:
		"tree_hit":
			duration = 0.13
			start_freq = 150.0
			end_freq = 95.0
			noise_amount = 0.65
		"aggro":
			duration = 0.24
			start_freq = 210.0
			end_freq = 330.0
			noise_amount = 0.22
		"charge":
			duration = 0.3
			start_freq = 110.0
			end_freq = 55.0
			noise_amount = 0.45
		"skill_attack":
			duration = 0.14
			start_freq = 320.0
			end_freq = 180.0
			noise_amount = 0.3
		"skill_guard":
			duration = 0.2
			start_freq = 170.0
			end_freq = 225.0
			noise_amount = 0.12
		"skill_recover":
			duration = 0.28
			start_freq = 320.0
			end_freq = 620.0
			noise_amount = 0.05
		"victory":
			duration = 0.5
			start_freq = 420.0
			end_freq = 840.0
			noise_amount = 0.04
		"select":
			duration = 0.05
			start_freq = 650.0
			end_freq = 700.0
			noise_amount = 0.0
		_:
			duration = 0.08
			start_freq = 260.0
			end_freq = 220.0
			noise_amount = 0.2
	var count := maxi(1, int(MIX_RATE * duration))
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var phase := 0.0
	var lcg := 987654321
	for i in count:
		var t := float(i) / float(MIX_RATE)
		var ratio := t / duration
		var envelope := pow(maxf(0.0, 1.0 - ratio), 2.0)
		var attack := minf(1.0, ratio * 24.0)
		var freq := lerpf(start_freq, end_freq, ratio)
		phase = fmod(phase + TAU * freq / float(MIX_RATE), TAU)
		lcg = (lcg * 1103515245 + 12345) & 0x7fffffff
		var noise := (float(lcg) / 2147483647.0) * 2.0 - 1.0
		var sample := (sin(phase) * 0.72 + noise * noise_amount) * envelope * attack
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		if value < 0:
			value += 65536
		bytes[i * 2] = value & 0xFF
		bytes[i * 2 + 1] = (value >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = bytes
	return stream
