# Combat, guardians and rooftop defenses

Current rules were updated by the BESUT rescue campaign on 2026-10-25; see [BESUT_STORY_CAMPAIGN.md](BESUT_STORY_CAMPAIGN.md). The implementation and evidence below describe the earlier milestone.

Date: 2026-10-24. Engine: Godot 4.7.2 stable official, ed1daf0bf, Windows.

## Delivered behavior

- Adam is a Malay male swordsman, Mei Ling a Chinese female archer, and Arjun an Indian male scythe wielder. Portraits, world silhouettes, shop discipline, starter weapon labels and selection cards agree. Creator credits remain Qayyim, Farhan and Ayiz.
- Updated 2026-10-25: all three heroes use basic attacks only. Skill 1/2/3 buttons, casting, cooldowns, keyboard actions and Settings rows are removed. Projectiles still stop at world obstacles.
- Mana is removed from player state, character stats, selection cards, overhead vitals, the potion shop and Pack. Legacy saves discard retired mana fields, potions and skill layouts while retaining other progress and active control customization.
- Every pet-duel rival has a distinct persistent pet ID. Winning recruits it to the owned roster and village guard. Five invincible guardians use the existing village route planner and attack fire monsters and sea urchins. Replays do not duplicate them; previous cleared duels recruit their rivals on load. Recruited pets can also be selected from the Pet Shop roster.
- Archer huts are replaced by dormant rooftop machine-gun mounts. The Construction Shop has a house selector and paid installation action. Each intact house costs 180 + 60 per level above Level 1 Gold. Guns fire every 0.6/0.5/0.4/0.3/0.2 seconds according to the central house tier and stop while their own house is ruined.
- Main-house interiors contain an interactable bed using the existing HouseDB recovery duration.
- Ten bosses have intimidating names and retain their distinct special powers. They start pursuit after a 2.2-second arrival warning without requiring a close approach. Each portal has colliding pillars and six rune traps, with one-second warnings and 0.65-second damage windows. Later levels increase damage and shorten trap cycles.
- Original eight-second procedural chiptune loops play during monster portal battles and pet duels, with four musical variants. Master volume/mute applies; leaving worlds, closing pet duels and resolving duels stop music.
- Remaining Malay gameplay labels, book pages, mission status, pet duel powers/status and loading destinations are English. Asset filenames and internal compatibility IDs are unchanged.

## Persistence and compatibility

GameState alone owns new persistent village_pets and roof_guns fields, including defaults and sanitization. Old qayyim/farhan/ayiz IDs migrate to adam/arjun/mei_ling. Existing hammer inventory IDs remain valid but their records describe scythes. Progress, inventory, house tiers and village unlocks are retained. Recruited guardians use stable pet IDs. No forest placement RNG, tree IDs, tree damage rules or scenery source data changed.

## Verification

Updated 2026-10-25: the isolated gameplay gate passes 991 checks, exit 0, after removing player skills and mana. The final native review passes with twelve 1280x720 fixtures, exit 0, and no FAIL, SCRIPT ERROR, ERROR or WARNING entries. Inspected hero cards, basic-attack HUD, Settings, the health-potion shop and Pack; the old mana bar, MP values and player skill buttons are absent.

- Incoming isolated baseline: 920 checks, PASS, exit 0.
- Previous expanded isolated gate (before skill/mana removal): 1006 checks, PASS, exit 0. Full stdout/stderr checked for [FAIL], SCRIPT ERROR and ERROR:; clean.
- New tools/combat_revamp_checks.gd now covers real basic-attack damage for all heroes, removed skill inputs, absence of mana, legacy save cleanup and touch action release; rival ownership and deduplication; both guardian enemy targets; paid/duplicate/invalid gun transactions; save/load and legacy migration; indoor sleeping; boss activation at range; trap warning/damage; and music lifecycle.
- Native OpenGL compatibility renderer: nine 1280x720 fixtures, combat revamp review: PASS, exit 0, no errors or warnings in the final capture run. Inspected hero cards, village rooftop gun/guardians, Construction Shop, indoor bed, both new weapon HUDs, centered boss warning/traps, English pet arena and rival reward.
- Renderer: AMD Radeon Vega 3 Graphics, OpenGL 3.3.13596. Captures and logs are temporary test artifacts; no shots or build outputs were written into the project.
- Tests use tools/test_isolated.ps1 on this Windows host. It backs up the real save as evidence and verifies isolated APPDATA/LOCALAPPDATA before destructive test operations. The actual real save is never restored or overwritten.

## Reproduction

Run the existing isolated Windows gate with the absolute 4.7.2 console executable. For renderer fixtures, use res://tools/combat_revamp_review.tscn with a fresh APPDATA/LOCALAPPDATA directory and TIDESWORN_TEST_ROOT covering it. The review refuses non-isolated data and writes its shots beneath that root.

## Limits

This is source-level delivery. APK/EXE exports and an on-device Android playtest were not performed. Battle music lifecycle and generated PCM/loop state were verified; subjective listening on the target device remains a playtest item. Player combat now has one basic-attack button for every hero.
