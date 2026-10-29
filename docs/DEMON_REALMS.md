# Three Portal Bosses

The supplied demon roster uses imported, rendered game sprites through `RealmPresentation` and `ElementalArt`, with the original procedural pixels retained as a fallback. The active chain is now Chaos Citadel → Tempest Spire → Abyssal Throne (levels 1/3/5), with three bosses and nine campaign powers. The surviving portal IDs and final Mei Ling rescue remain stable. The Kraken route is separate and unchanged. The Abyss Monarch occupies the final throne. The subsequent graphics/performance pass is documented in [REALM_GRAPHICS_AND_PERFORMANCE.md](REALM_GRAPHICS_AND_PERFORMANCE.md); the evidence below records the earlier pixel-art implementation.

## Active campaign

| Portal ID | Ruler | Three powers | Small monsters |
|---|---|---|---|
| tidebound_grotto | Shadow & Chaos Fiend / Demon Pembunuh Bayangan | Dark Blaze, Mirage Assault, Chaos Crossfire | Darkfire Imp (dash) |
| sunken_crypt | Gale Tempest Demon / Tuan Angin Pusaran | Razor Tornado, Gale Blades, Cyclone Uplift | Gale Harpy (ranged) |
| drowned_throne | Abyss Monarch / Raja Iblis Utama | Black-Hole Dominion, Sovereign Souls, Pure-Darkness Apocalypse | Soulbound Knight (homing) |

Final encounter pacing: level 5, twelve level-five minions, 1,120 ruler HP, 30 ground/melee damage and 15 projectile damage; rune traps deal 9 damage on a 4.30-second cycle. First clear awards 650 Gold / 20 diamonds / 320 XP; repeat clear awards 360 / 9 / 120. The first stable stage now uses Twilight Wilds exploration: six authored encounters plus its local guard system, citadel boss and physical onward passages. Wind retains its existing arena stats and rewards. The three-stage chain and retired-save migration remain active.

### Legacy saves and retained artwork

The seven omitted realms cannot be entered or selected. Their historical save records and art remain available rather than deleting assets or earned history. Loading a save with the second ruler cleared, or progress in a retired realm, unlocks the new finale. An active retired expedition resumes in Abyssal Throne with its bag preserved. Existing final clears and rescue flags remain intact; migration does not grant rewards or rescue Mei Ling by itself.

Each power warns for 0.85 seconds, then performs actual ground damage, swept projectiles, a charge or a capped group of three summoned attackers. Ice, roots and lightning can slow; tornadoes, gravity and whirlpools pull through collision-aware movement; quakes and waves push. Poison/acid/fire zones persist and can be avoided. The caster owns its effects; death/world replacement cancels them. Reduce Motion preserves warnings and gameplay while removing optional pose motion.

Realm floors, crystals/roots/obelisk props, ambient colour, rune shapes, boss silhouettes and small demon art match the element. PixelArt/AssetRegistry keys remain authoritative. Boss names and cast names appear above the boss. The Field Guide and portal counter list all three powers.

## Player rewards and weapons

- Every regular kill gives three times its previous combat XP. Fire/urchin deaths, including kills by Arjun, Mei Ling, residents, pets and raid defenders, pay Gold directly to the player without walking to a drop. Each death pays once. Dungeon loot banking and portal completion rewards retain their normal rules.
- The next-level requirement is `60 + 35*(level-1) + 5*(level-1)^2`. Existing levels and accumulated XP migrate to this curve on load without losing XP.
- Each of sword/scythe/bow now has nine purchasable choices plus its starter: seven new weapons per discipline, twenty-one additions total.
- Owned weapons have five permanent Gold upgrades. Each rank adds 20% of base weapon attack. Cost is `max(25, round(price*0.25) + base_attack*3) * (rank+1)`. The shop displays the same transaction cost and upgraded attack used by combat. Armour/shield stats are unchanged.
- Upgrade records live in GameState `weapon_upgrades`, merge into old saves and sanitize to owned valid weapons/ranks 0..5. Failed/unaffordable/cross-discipline upgrades do not spend money.

## Verification

Current acceptance requires exactly three portal cards/guide boss pages, the direct second-to-final unlock, level-five final entry, all nine powers, and save migration coverage for every retired ID. The dated ten-realm logs below are historical evidence, not results for the shortened campaign.

### Historical ten-realm verification

`ElementalChecks` is integrated into `tools/tide_test.gd`; `tools/elemental_test.tscn` also supports a focused isolated/native run. It covers shared rewards, duplicate-death protection, all three weapon disciplines, five upgrade ranks, save migration, nine active campaign power execution paths and three boss art variants. Native capture writes room and close boss fixtures under the temporary test root. Use the standard isolated wrappers; never run against a live player save.


Final Windows / Godot 4.7.2 evidence: **1,456 full isolated gameplay checks PASS, exit 0**; **208 native 832x480 checks PASS, exit 0**. Both logs are clean of FAIL, SCRIPT ERROR and ERROR entries. The native tests exercise all thirty power execution paths and successful dodges, all ten small-monster attack patterns, shared allied rewards, persistent upgrades and save compatibility. No APK or standalone executable was rebuilt.

Native boss previews: [Chaos](evidence/demon-realms-2026-10-28/boss_chaos.png), [Wind](evidence/demon-realms-2026-10-28/boss_wind.png), [Ice](evidence/demon-realms-2026-10-28/boss_ice.png), [Earth](evidence/demon-realms-2026-10-28/boss_earth.png), [Fire](evidence/demon-realms-2026-10-28/boss_fire.png), [Lightning](evidence/demon-realms-2026-10-28/boss_lightning.png), [Forest](evidence/demon-realms-2026-10-28/boss_forest.png), [Water](evidence/demon-realms-2026-10-28/boss_water.png), [Decay](evidence/demon-realms-2026-10-28/boss_decay.png), [Abyss Monarch](evidence/demon-realms-2026-10-28/boss_dark.png). Forge previews: [swords](evidence/demon-realms-2026-10-28/forge_choices_adam.png), [scythes](evidence/demon-realms-2026-10-28/forge_choices_arjun.png), [bows](evidence/demon-realms-2026-10-28/forge_choices_mei_ling.png). [Full gameplay log](evidence/demon-realms-2026-10-28/gameplay.log) / [native log](evidence/demon-realms-2026-10-28/native.log).
