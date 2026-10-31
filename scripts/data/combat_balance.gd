class_name CombatBalance
extends RefCounted
## Fixed encounter tuning: equipment upgrades retain their full advantage.
## Warning durations, movement and rewards deliberately keep their authored values.
const REGULAR_HEALTH := 1.45
const BOSS_HEALTH := 1.35
const DAMAGE := 1.25
const ATTACK_INTERVAL := 0.90

static func health(base: int, boss: bool = false) -> int:
	return maxi(1, roundi(base * (BOSS_HEALTH if boss else REGULAR_HEALTH)))

static func damage(base: int) -> int:
	return maxi(1, ceili(base * DAMAGE))

