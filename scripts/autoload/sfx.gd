extends Node
## Tiny procedural sound-effect bus. No external audio assets are required:
## short PCM tones are synthesized once, cached and played through a small pool
## of AudioStreamPlayers. Used for forest impacts, aggro/charge cues and pet
## battle skill feedback.

const MIX_RATE := 22050
const PLAYER_POOL := 8

var _cache: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _combat_variants: Dictionary = {}
var _next_player := 0
var _music: AudioStreamPlayer
var _music_cache: Dictionary = {}
var battle_track := ""


func _ready() -> void:
	_music = AudioStreamPlayer.new()
	_music.name = "BattleMusic"
	_music.volume_db = -18.0
	add_child(_music)
	for i in PLAYER_POOL:
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		player.volume_db = -7.0
		add_child(player)
		_players.append(player)
	# Finite cached one-shots: synthesize before the first combat contact.
	for kind in ["blade_swing","blade_hit","blade_finish","blade_armor","blade_defeat","blade_stone"]:
		_get_stream(kind)
		_get_stream(kind+"_v1")
	call_deferred("_bind_combat_settings")


func _exit_tree() -> void:
	for player in _players:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	_players.clear()
	stop_battle_music()
	_music_cache.clear()
	_cache.clear()


func _bind_combat_settings() -> void:
	if not GameSettings.changed.is_connected(_combat_setting_changed):
		GameSettings.changed.connect(_combat_setting_changed)

func _combat_setting_changed(key: String) -> void:
	if key not in ["effects_volume","mute_all"]: return
	for voice in _players:
		if not bool(voice.get_meta("combat_voice",false)): continue
		if GameSettings.effects_volume() <= 0 or GameSettings.mute_all():
			voice.stop()
		else:
			voice.volume_db = float(voice.get_meta("combat_volume",-9.0)) + GameSettings.volume_percent_to_db(GameSettings.effects_volume())

func play_combat(kind: String, volume_db := -9.0) -> void:
	var variant := int(_combat_variants.get(kind,0))
	_combat_variants[kind] = 1-variant
	play(kind if variant == 0 else kind+"_v1",volume_db)

func play(kind: String, volume_db: float = -7.0) -> void:
	var combat_voice := kind.begins_with("blade_") or kind in ["hit","aggro","charge"]
	if combat_voice and (GameSettings.mute_all() or GameSettings.effects_volume() <= 0 or GameSettings.master_volume() <= 0): return
	if _players.is_empty():
		return
	var stream := _get_stream(kind)
	if stream == null:
		return
	var player := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	player.stream = stream
	player.set_meta("combat_voice",combat_voice)
	player.set_meta("combat_volume",volume_db)
	player.volume_db = volume_db + (GameSettings.volume_percent_to_db(GameSettings.effects_volume()) if combat_voice else 0.0)
	player.play()


func has_sound(kind: String) -> bool:
	return _get_stream(kind) != null


func dialogue_voice(speaker: String, syllable: int = 0) -> AudioStreamWAV:
	# Finite, reusable vowel sounds. The dialogue owns its player so interrupting
	# a line stops its voice without touching combat sounds in the global pool.
	var low := speaker == "Pak Rahim"
	var vowel := posmod(syllable, 3)
	var key := "dialogue/%s/%d" % ["rahim" if low else "adam", vowel]
	if _cache.has(key): return _cache[key] as AudioStreamWAV
	var duration := 0.095 + float(vowel) * 0.009
	var count := int(MIX_RATE * duration)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var phase := 0.0
	var pitch := 172.0 if low else 218.0
	var formants: Vector2 = [Vector2(440, 1050), Vector2(620, 1350), Vector2(380, 900)][vowel]
	for i in count:
		var t := float(i) / MIX_RATE
		var progress := t / duration
		var frequency := pitch + 12.0 * sin(progress * PI) - progress * 15.0
		phase += TAU * frequency / MIX_RATE
		var sample := 0.0
		for harmonic in range(1, 15):
			var hz := frequency * harmonic
			var weight := 0.26 / pow(float(harmonic), 1.5)
			weight += 0.30 * exp(-pow((hz - formants.x) / 160.0, 2))
			weight += 0.12 * exp(-pow((hz - formants.y) / 220.0, 2))
			sample += sin(phase * harmonic) * weight
		# Soft attacks and releases avoid a click on each tiny syllable.
		var envelope := smoothstep(0.0, 0.012, t) * (1.0 - smoothstep(duration - 0.035, duration, t))
		var value := int(clampf(sample * envelope * 0.55, -0.95, 0.95) * 32767.0)
		bytes.encode_s16(i * 2, value)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = bytes
	_cache[key] = stream
	return stream

func urchin_arrival_sound(beat: String) -> AudioStreamWAV:
	return _get_stream("urchin_" + (beat if beat in ["surf", "sand", "rattle"] else "sand"))

func ending_sound(kind: String) -> AudioStreamWAV:
	if kind != "bed": return _get_stream("step" if kind == "board" else "ending_creak")
	if _cache.has("ending_bed"): return _cache.ending_bed
	# A quiet original major chord bed and soft surf; the story owns playback.
	var count := MIX_RATE*8
	var bytes := PackedByteArray()
	bytes.resize(count*2)
	for i in count:
		var t := float(i)/MIX_RATE
		var chord := sin(TAU*130.8125*t)*0.18+sin(TAU*164.8125*t)*0.10+sin(TAU*196*t)*0.08
		var swell := 0.5-0.5*cos(TAU*t/8)
		var surf := sin(TAU*1731*t)*sin(TAU*2387*t)*(0.025+0.02*cos(TAU*t/4))
		bytes.encode_s16(i*2,int((chord*swell+surf)*10000))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.data = bytes
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = count
	_cache.ending_bed = stream
	return stream


func _get_stream(kind: String) -> AudioStreamWAV:
	if _cache.has(kind):
		return _cache[kind] as AudioStreamWAV
	var stream := _build_stream(kind)
	if stream == null:
		return null
	_cache[kind] = stream
	return stream


func _build_combat_stream(kind: String) -> AudioStreamWAV:
	# One composite PCM voice (air/crack/body/metal), not several overlapping
	# players. Independent deterministic noise never consumes gameplay RNG.
	var alternate := kind.ends_with("_v1")
	kind = kind.trim_suffix("_v1")
	var duration := 0.16
	var bass := 112.0
	var body := 0.40
	var air := 0.36
	if kind == "blade_swing":
		duration = 0.11
		body = 0.06
		air = 0.34
	elif kind == "blade_finish":
		duration = 0.22
		bass = 82.0
		body = 0.55
	elif kind == "blade_armor":
		duration = 0.18
		bass = 165.0
		body = 0.14
		air = 0.18
	elif kind == "blade_defeat":
		duration = 0.24
		bass = 68.0
		body = 0.50
	if kind == "blade_stone":
		bass = 94.0
		air = 0.48
		body = 0.34
	if alternate: bass *= 1.045
	var count := int(MIX_RATE*duration)
	var bytes := PackedByteArray()
	bytes.resize(count*2)
	var seed_value := 44231
	var phase := 0.0
	var noise_low := 0.0
	for i in count:
		var t := float(i)/MIX_RATE
		var u := t/duration
		seed_value = (seed_value*1103515245+12345)&0x7fffffff
		var noise := float(seed_value)/1073741823.5-1.0
		noise_low = lerpf(noise_low,noise,0.3)
		phase += TAU*lerpf(bass,bass*0.36,u)/MIX_RATE
		var envelope := minf(1.0,t/0.003)*pow(1.0-u,2.2)
		var crack := (noise-noise_low)*exp(-t*70.0)*air
		var pressure := sin(phase)*body*exp(-t*9.0)
		var metal := (sin(TAU*840.0*t)+sin(TAU*1321.0*t)*0.45)*exp(-t*24.0)*0.07
		if kind == "blade_armor": metal *= 3.2
		if kind == "blade_swing":
			pressure = 0.0
			crack = noise_low*air*sin(u*PI)
			metal = 0.0
		var sample := clampf((pressure+crack+metal)*envelope,-0.92,0.92)
		bytes.encode_s16(i*2,int(sample*32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = bytes
	return stream


func _build_stream(kind: String) -> AudioStreamWAV:
	if kind.begins_with("blade_"): return _build_combat_stream(kind)
	var duration := 0.12
	var start_freq := 180.0
	var end_freq := 140.0
	var noise_amount := 0.35
	match kind:
		"kraken_ink":
			duration = 0.32
			start_freq = 250.0
			end_freq = 70.0
			noise_amount = 0.5
		"kraken_spin":
			duration = 0.7
			start_freq = 110.0
			end_freq = 170.0
			noise_amount = 0.65
		"turtle_eat":
			duration = 0.24
			start_freq = 190.0
			end_freq = 95.0
			noise_amount = 0.65
		"shark_bite":
			duration = 0.38
			start_freq = 160.0
			end_freq = 45.0
			noise_amount = 0.8
		"ending_creak":
			duration = 0.55
			start_freq = 105.0
			end_freq = 65.0
			noise_amount = 0.22
		"urchin_surf":
			duration = 0.42
			start_freq = 210.0
			end_freq = 90.0
			noise_amount = 0.8
		"urchin_sand":
			duration = 0.09
			start_freq = 145.0
			end_freq = 100.0
			noise_amount = 0.7
		"urchin_rattle":
			duration = 0.13
			start_freq = 710.0
			end_freq = 395.0
			noise_amount = 0.35
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
		"coin":
			duration = 0.09
			start_freq = 880.0
			end_freq = 1320.0
			noise_amount = 0.02
		"equip":
			duration = 0.16
			start_freq = 240.0
			end_freq = 520.0
			noise_amount = 0.18
		"deny":
			duration = 0.18
			start_freq = 190.0
			end_freq = 120.0
			noise_amount = 0.3
		"hit":
			duration = 0.1
			start_freq = 300.0
			end_freq = 150.0
			noise_amount = 0.5
		"step":
			duration = 0.05
			start_freq = 130.0
			end_freq = 95.0
			noise_amount = 0.4
		"portal_in":
			duration = 0.4
			start_freq = 300.0
			end_freq = 720.0
			noise_amount = 0.08
		"portal_out":
			duration = 0.35
			start_freq = 700.0
			end_freq = 260.0
			noise_amount = 0.08
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
		if kind == "turtle_eat":
			# Three soft crunches, rather than the pickup/coin or healing chime.
			sample *= pow(maxf(0.0, sin(ratio * PI * 3.0)), 2.0)
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


func start_battle_music(track: String) -> void:
	if battle_track == track and _music.playing:
		return
	battle_track = track
	var variant := posmod(track.hash(), 4)
	if not _music_cache.has(variant):
		_music_cache[variant] = _build_battle_track(variant)
	_music.stream = _music_cache[variant]
	_music.play()


func stop_battle_music() -> void:
	battle_track = ""
	if is_instance_valid(_music):
		_music.stop()


func _build_battle_track(variant: int) -> AudioStreamWAV:
	# Original eight-second chiptune: minor arpeggio, bass and percussion.
	const DURATION := 8.0
	var count := int(MIX_RATE * DURATION)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var notes := [0, 3, 7, 10, 7, 3, 5, 2, 0, 7, 12, 10, 7, 5, 3, 2]
	var root := 110.0 * pow(2.0, variant / 12.0)
	for index in count:
		var time := float(index) / MIX_RATE
		var step := int(time * 4) % notes.size()
		var beat := fmod(time, 0.25)
		var frequency := root * pow(2.0, float(notes[step]) / 12.0)
		var lead := sin(TAU * frequency * 2 * time) * exp(-beat * 13) * 0.22
		var bass := sin(TAU * root * 0.5 * time) * (0.7 + 0.3 * cos(TAU * time * 2)) * 0.19
		var kick_time := fmod(time, 0.5)
		var kick := sin(TAU * (58 * kick_time + 5 * (1 - exp(-kick_time * 28)))) * exp(-kick_time * 23) * 0.28
		var hat := sin(TAU * 5300 * time) * sin(TAU * 7210 * time) * exp(-beat * 65) * 0.07
		var value := int(clampf(lead + bass + kick + hat, -1, 1) * 32767)
		bytes.encode_s16(index * 2, value)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.data = bytes
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	# Godot's PCM mixer can decode the loop endpoint. Keep it inside the buffer;
	# count itself is one sample past the allocation (crashes Android AudioTrack).
	stream.loop_end = count - 1
	return stream
