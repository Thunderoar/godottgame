# Ten Demon Realms

The supplied demon roster uses imported, rendered game sprites through `RealmPresentation` and `ElementalArt`, with the original procedural pixels retained as a fallback. Existing portal IDs, unlock order and the final Mei Ling rescue remain stable. The Abyss Monarch occupies the final throne. The subsequent graphics/performance pass is documented in [REALM_GRAPHICS_AND_PERFORMANCE.md](REALM_GRAPHICS_AND_PERFORMANCE.md); the evidence below records the earlier pixel-art implementation.

| Portal ID | Ruler | Three powers | Small monsters |
|---|---|---|---|
| tidebound_grotto | Shadow & Chaos Fiend / Demon Pembunuh Bayangan | Dark Blaze, Mirage Assault, Chaos Crossfire | Darkfire Imp (dash) |
| sunken_crypt | Gale Tempest Demon / Tuan Angin Pusaran | Razor Tornado, Gale Blades, Cyclone Uplift | Gale Harpy (ranged) |
| reef_hollow | Glacial Frost Demon / Jeneral Ais Beku | Crystal Barrage, Eternal Frost, Glacial Prison | Frost Revenant (ranged) |
| brine_cavern | Tectonic Earth Titan / Raksasa Tanah Bebatuan | Rupture Fault, Magma Bombardment, Titan Earthquake | Magma Golem (slam) |
| kelp_maze | Infernal Blaze Lord / Pahlawan Api Neraka | Magma Sword Cleave, Infernal Rush, Hellfire Crown | Cinder Swordsman (dash) |
| bone_gallery | Voltage Lightning Demon / Pangeran Kilat Petir | Lightning Step, Thunder Judgment, Voltaic Arcs | Volt Wraith (dash) |
| storm_shrine | Thorn Forest Queen / Ratu Hutan Berduri | Root Prison, Venom Blossom, Thorn Lash | Thorn Stalker (snare) |
| coral_throne | Abyssal Tsunami Demon / Panglima Lautan Bergelora | Tsunami Wall, Hydro Trident, Pressure Whirlpool | Trident Marauder (wave) |
| abyss_gate | Necromancer of Decay / Penyihir Puaka Hijau | Corrosive Plague, Soul Corruption, Raise the Fallen | Plague Acolyte (pool) |
| drowned_throne | Abyss Monarch / Raja Iblis Utama | Black-Hole Dominion, Sovereign Souls, Pure-Darkness Apocalypse | Soulbound Knight (homing) |

Each power warns for 0.85 seconds, then performs actual ground damage, swept projectiles, a charge or a capped group of three summoned attackers. Ice, roots and lightning can slow; tornadoes, gravity and whirlpools pull through collision-aware movement; quakes and waves push. Poison/acid/fire zones persist and can be avoided. The caster owns its effects; death/world replacement cancels them. Reduce Motion preserves warnings and gameplay while removing optional pose motion.

Realm floors, crystals/roots/obelisk props, ambient colour, rune shapes, boss silhouettes and small demon art match the element. PixelArt/AssetRegistry keys remain authoritative. Boss names and cast names appear above the boss. The Field Guide and portal counter list all three powers.

## Player rewards and weapons

- Every regular kill gives three times its previous combat XP. Fire/urchin deaths, including kills by Arjun, Mei Ling, residents, pets and raid defenders, pay Gold directly to the player without walking to a drop. Each death pays once. Dungeon loot banking and portal completion rewards retain their normal rules.
- The next-level requirement is `60 + 35*(level-1) + 5*(level-1)^2`. Existing levels and accumulated XP migrate to this curve on load without losing XP.
- Each of sword/scythe/bow now has nine purchasable choices plus its starter: seven new weapons per discipline, twenty-one additions total.
- Owned weapons have five permanent Gold upgrades. Each rank adds 20% of base weapon attack. Cost is `max(25, round(price*0.25) + base_attack*3) * (rank+1)`. The shop displays the same transaction cost and upgraded attack used by combat. Armour/shield stats are unchanged.
- Upgrade records live in GameState `weapon_upgrades`, merge into old saves and sanitize to owned valid weapons/ranks 0..5. Failed/unaffordable/cross-discipline upgrades do not spend money.

## Verification

`ElementalChecks` is integrated into `tools/tide_test.gd`; `tools/elemental_test.tscn` also supports a focused isolated/native run. It covers shared rewards, duplicate-death protection, all three weapon disciplines, five upgrade ranks, save migration, thirty power execution paths and ten original boss art variants. Native capture writes room and close boss fixtures under the temporary test root. Use the standard isolated wrappers; never run against a live player save.


Final Windows / Godot 4.7.2 evidence: **1,456 full isolated gameplay checks PASS, exit 0**; **208 native 832x480 checks PASS, exit 0**. Both logs are clean of FAIL, SCRIPT ERROR and ERROR entries. The native tests exercise all thirty power execution paths and successful dodges, all ten small-monster attack patterns, shared allied rewards, persistent upgrades and save compatibility. No APK or standalone executable was rebuilt.

Native boss previews: [Chaos](evidence/demon-realms-2026-10-28/boss_chaos.png), [Wind](evidence/demon-realms-2026-10-28/boss_wind.png), [Ice](evidence/demon-realms-2026-10-28/boss_ice.png), [Earth](evidence/demon-realms-2026-10-28/boss_earth.png), [Fire](evidence/demon-realms-2026-10-28/boss_fire.png), [Lightning](evidence/demon-realms-2026-10-28/boss_lightning.png), [Forest](evidence/demon-realms-2026-10-28/boss_forest.png), [Water](evidence/demon-realms-2026-10-28/boss_water.png), [Decay](evidence/demon-realms-2026-10-28/boss_decay.png), [Abyss Monarch](evidence/demon-realms-2026-10-28/boss_dark.png). Forge previews: [swords](evidence/demon-realms-2026-10-28/forge_choices_adam.png), [scythes](evidence/demon-realms-2026-10-28/forge_choices_arjun.png), [bows](evidence/demon-realms-2026-10-28/forge_choices_mei_ling.png). [Full gameplay log](evidence/demon-realms-2026-10-28/gameplay.log) / [native log](evidence/demon-realms-2026-10-28/native.log).
