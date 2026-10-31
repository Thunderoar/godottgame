# Equipment-driven combat difficulty — 2026-10-31

Enemy strength now uses one fixed tuning policy in `CombatBalance`. It does not
read the player's weapon, upgrades, armour, house tier or pet level. Buying and
upgrading equipment therefore retains its full advantage rather than causing
enemies to grow alongside it.

- Regular enemy maximum HP: authored value × 1.45, rounded to nearest integer.
- Boss maximum HP: authored value × 1.35, rounded to nearest integer.
- Melee, special and projectile damage: authored value × 1.25, rounded up.
- Repeated melee/special attack intervals: authored interval × 0.90.
- Movement speed, attack warnings, recovery windows, reach, collision, wave
  quotas, loot, XP and shop/upgrade prices retain their authored contracts.

`Enemy._ready()` applies this exactly once after each world's or subclass's
authored stats are configured. This covers fire monsters, ordinary/emergency
urchins, legacy regular monsters, elemental minions, all three Twilight guard
profiles, elemental rulers, the Kraken and all ten fortress crabs. Guard casts
and elemental-minion powers use the same shorter repeated cooldown; their first
attack and warning times remain authored. Boss summons derive their base damage
from their ruler's original base damage, avoiding two difficulty multipliers.

Manual pet rivals and habitat challenges use the boss HP multiplier and damage
multiplier at battle setup. The player still acts first, chooses each turn, and
can use Shield/Special. There is no automatic player turn or shorter input timer.
Ocean bombs, rubbish, sharks, fullness and lives are route hazards rather than
equipment combat; they retain the two-level turtle journey rules.

Examples of live stats:

| Enemy | HP | Melee damage |
| --- | ---: | ---: |
| Village fire | 58 | 4 |
| Ordinary urchin | 44 | 8 |
| Emergency urchin | 87 | 12 |
| Kraken fortress crab | 70 | 9 |
| Shadow & Chaos Fiend | 567 | 23 |
| Gale Tempest Demon | 1,026 | 33 |
| Abyss Monarch | 1,512 | 38 |
| Kraken King | 972 | 20 |

Saved living village attackers keep their saved current HP, clamped to the new
maximum. Reloading neither heals their wounds nor reapplies a multiplier to their
saved HP. New arrivals spawn with the new maximum. No save fields/version change.

The canonical gate includes `tools/combat_balance_checks.gd`: live regular and
specialised constructors, boss damage channels, actual equipment and permanent
Gold-upgrade transactions, mitigation and all five manual rival battle setups.
At Adam level 1, a 58-HP target takes five starter-sword hits, three Iron Sword
hits, or two Iron Sword +5 hits before combo multipliers and companion support.
Leather Vest reduces a 12-damage emergency hit to six. Existing battle/arrival,
reward, rescue and real save/reload suites continue to exercise the integrated
combat. See the newest acceptance section for actual run results and limits.
