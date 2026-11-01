extends RefCounted
## Exercise real swept projectiles, cover, ability rotation and retiring owners.
static func run(game: Game, check: Callable, capture: Callable) -> void:
	var island := game.world as KrakenIsland
	var boss := island.boss
	var player := island.player
	var hp := GameState.health()
	var start := player.position
	var boss_start := boss.position
	var blink := player.invulnerable
	var timer := boss._special_timer
	var index := boss._power_index
	var state := boss._state
	var reduced := GameSettings.reduce_motion()
	var quality := GameSettings.effects_quality()
	var actors: Array[Node] = [boss,player]
	actors.append_array(island.crabs)
	var ticking: Array[bool] = []
	for actor in actors:
		ticking.append(actor.is_physics_processing())
		actor.set_physics_process(false)
	boss._cancel_powers()
	boss.position = Vector2(20,10)
	player.position = Vector2(20,18)
	boss._power_index = 0
	boss._special_timer = 0
	boss._state = Enemy.State.CHASE
	boss._chase(0)
	check.call(boss.tentacle_time >= 0 and boss.power == "", "the new Kraken rotation preserves its opening tentacle attack")
	boss._cancel_powers()
	boss._special_timer = 0
	boss._chase(0)
	check.call(boss.power == "ink" and boss.ink_shots.is_empty(), "the next automatic special raises a tentacle to aim black ink before firing")
	boss._update_power(KrakenKing.INK_WARNING-0.01)
	check.call(GameState.health() == hp and boss.ink_shots.is_empty() and boss._ink_lanes.size() == 3, "ink gives three visible warning lanes without early damage")
	if capture.is_valid(): await capture.call("ocean_07_ink_warning")
	player.invulnerable = 0
	_step(boss,0.02)
	check.call(boss.ink_shots.size() == 3, "the tentacle fires a real three-shot black ink fan")
	_step(boss,0.24)
	if capture.is_valid(): await capture.call("ocean_08_ink_shots")
	_step(boss,0.5)
	var ink_hp := GameState.health()
	check.call(ink_hp < hp, "fast black ink uses swept contact to hit Adam between frames")
	player.invulnerable = 0
	_step(boss,0.1)
	check.call(GameState.health() == ink_hp, "overlapping ink droplets cannot pay damage twice in one fan")
	boss._cancel_powers()
	GameState.set_health(hp)
	player.position = Vector2(20,18)
	boss._begin_power("ink")
	player.position = Vector2(27,18)
	_step(boss,KrakenKing.INK_WARNING)
	_step(boss,1.2)
	check.call(GameState.health() == hp, "moving away from the locked ink warning actually dodges the fan")
	boss._cancel_powers()
	boss.position = Vector2(8,17.7)
	player.position = Vector2(13,17.7)
	player.invulnerable = 0
	boss._begin_power("ink")
	check.call(boss._ink_origin.x < 9.45, "the aiming tentacle cannot place its ink muzzle through solid cover")
	_step(boss,KrakenKing.INK_WARNING)
	_step(boss,1)
	check.call(GameState.health() == hp and boss.ink_shots.is_empty(), "the fortress pillar blocks the ink fan before it can reach Adam")
	boss._cancel_powers()
	boss.position = Vector2(20,10)
	player.position = Vector2(23,10)
	boss._special_timer = 0
	boss._chase(0)
	check.call(boss.power == "spin" and boss._spin_tips.size() == 8, "the next automatic special winds up eight fan-like tentacles")
	boss._update_power(KrakenKing.SPIN_WARNING-0.01)
	check.call(GameState.health() == hp, "the full spinning-tentacle warning stays harmless")
	if capture.is_valid(): await capture.call("ocean_09_spin_warning")
	boss._update_power(0.2)
	var spin_hp := GameState.health()
	check.call(spin_hp < hp and boss._spin_hit, "the active fan spin damages Adam inside its marked radius")
	player.invulnerable = 0
	boss._update_power(0.3)
	check.call(GameState.health() == spin_hp, "one fan spin cannot repeatedly damage Adam while he overlaps its arms")
	if capture.is_valid(): await capture.call("ocean_10_spin_active")
	boss._cancel_powers()
	GameState.set_health(hp)
	boss._begin_power("spin")
	player.position = boss.position + Vector2(0,KrakenKing.SPIN_RADIUS+1)
	_step(boss,KrakenKing.SPIN_WARNING+0.1)
	check.call(GameState.health() == hp, "leaving the spin warning radius avoids all spinning tentacles")
	boss._cancel_powers()
	boss.position = Vector2(8,17.7)
	player.position = Vector2(12,17.7)
	boss._begin_power("spin")
	_step(boss,KrakenKing.SPIN_WARNING+0.1)
	var clipped := false
	for tip in boss._spin_tips:
		clipped = clipped or tip.distance_to(boss.position) < KrakenKing.SPIN_RADIUS-0.1
	check.call(GameState.health() == hp and clipped, "solid arena cover clips spinning arms and protects Adam")
	boss._cancel_powers()
	GameSettings.set_value("reduce_motion",true)
	GameSettings.set_value("effects_quality","low")
	boss._begin_power("spin")
	check.call(boss.power == "spin" and boss._spin_tips.size() == 8, "low effects and reduced motion retain all essential attack warnings")
	boss._cancel_powers()
	boss._begin_power("ink")
	_step(boss,KrakenKing.INK_WARNING)
	game.world = null
	boss._physics_process(1)
	game.world = island
	check.call(boss.ink_shots.is_empty() and boss.power_time < 0 and GameState.health() == hp, "retiring Kraken ink and fan powers cancel safely after a world handoff")
	GameSettings.set_value("reduce_motion",reduced)
	GameSettings.set_value("effects_quality",quality)
	GameState.set_health(hp)
	player.position = start
	player.invulnerable = blink
	boss.position = boss_start
	boss._power_index = index
	boss._special_timer = timer
	boss._state = state
	for i in actors.size(): actors[i].set_physics_process(ticking[i])

static func _step(boss: KrakenKing, delta: float) -> void:
	boss._update_power(delta)
	boss._update_ink(delta)
