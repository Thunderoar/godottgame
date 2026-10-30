# Twilight Wilds — first explorable dimension

**2026-10-30 portal awakening:** new journeys first discover the fallen village
waystone, ask Pak Rahim about it, and restore its carved road with his borrowed
lantern. The Dimension Portal appears through an owned reveal, then enters this
realm normally. Existing saves retain their entrance. See `PORTAL_AWAKENING.md`.

Implemented 2026-10-29. The first dimension replaces the two village battle entrances with one **Dimension Portal**, entering the world directly. The old `monster_portal` anchor remains authoritative for placement; the retired `pet_portal` anchor stays in layout data to preserve old layouts and original forest identity, but produces no entrance or map icon.

## The journey

The compact layout is **56×52 world units**, reduced from the original 72×72
(about 44% less area). Landmarks and optional loops sit closer together; character
scale, path widths, combat speeds and the 20×20 boss arena remain unchanged. The
main authored road is about 25% shorter. Terrain, boundaries, shortcut, habitats,
onward passages and discovery mapping all use the compact footprint. Existing
six-by-six discovery IDs and stable checkpoint/bond IDs remain compatible.

Follow the stone road from Arrival Glade across Rootbound Crossing toward Broken Watchpost and the Ashen Approach. Bramble Grove branches west; Moonpool Hollow loops east. At the watchpost, the rootway winch opens a permanent shortcut through the escarpment. The citadel lantern provides a two-second rest and a saved return checkpoint.

Six guards form three authored pairs: two Darkfire Imps north of the crossing, an Imp and Ember Watcher at the watchpost, and an Imp and Rune Keeper south of the lantern. Only one pair attacks at a time. Arrival, full pet stages, reading sites and the lantern are protected from guards and their attacks. Shadow & Chaos Fiend waits beyond the citadel's inner threshold. Dormant enemies cannot be damaged by weapons or companion attacks. Retreating to the lantern resets the unfinished boss, its spells and attack sequence.

## Read the Wilds: three combat encounters

The Imp holds still for a 0.65-second directional warning, commits to a 0.38-second
rush, then recovers. The Watcher locks its aim for 0.90 seconds before firing three
non-homing shots with gaps. Use a gap, side approach or the real stone cover on the
watchpost's outer flank. The Keeper gives a 1.05-second warning for a small fixed
cross; ordinary diagonal movement escapes into a clear quadrant. The Field Guide's
Monsters section illustrates all three profiles.

One shared attack slot covers a pair's windup and all live damaging effects,
including travelling shots. A whole charge, fan or cross can contact Adam once;
cross intersections and multiple overlapping shots cannot cause duplicate hits.
Warnings and damage share clipped geometry. Swept tests stop shots and charges at
real walls, pursuit limits and protected spaces, including the complete 8x7 animal
stages plus clearance. Low effects, Reduce Motion and mute retain essential cues.

Only six regular guards spawn: four Imps, one Watcher and one Keeper. Total HP is
282, with the existing base movement, 7 damage, 14 XP per guard and ordinary loot
rules. No additional saved encounter fields, currency, stat upgrades or boss keys
are introduced. The shared HUD still counts every living guard and the ruler,
including dormant actors; it is not an aggro counter.

Entering a different encounter or a refuge immediately invalidates old casts.
Living guards walk home through refuge-aware routes, retain their current HP and
settle without teleporting or healing. Killed guards stay dead for that visit;
Continue retains the existing fresh-combat reconstruction policy. Returning actors
do not draw the companion away from the player's active fight. Normal menus keep
their existing simulation behavior. A protected animal challenge ends pursuing
regular casts before suspending the world.

Runtime ownership is held by `RealmEncounterDirector`, `RealmGuard` and its owned
`RealmGuardAttack`. `RealmCombatDB` supplies the profiles/zones; `RealmGuardRoutes`
filters only guard routes. Ordinary village/player routing and legacy ElementDB
powers remain unchanged. The crossing homes were placed north of the bridge and
the Watcher shifted away from the winch's silhouette during rendered review.

The realm uses its own twilight grade while the shared day/night clock continues. Twilight exploration does not start the legacy dungeon emergency. Saved village attackers remain saved; returning at night still follows the village's ordinary wave and defense rules.

## Wild companions

Bramble Cat rests, sniffs and walks a small three-stop circuit beside scratched timber. Dusk Moth flutters between nearby perches and moonblooms. Pawprints and pale flowers mark their approaches. Both notice Adam and stop when he comes close, so neither requires chasing or waiting. Reduce Motion holds a stable home pose. Their patrol clocks and positions are temporary; map icons remain at the habitat anchors.

Each habitat reserves an 8x7 protected clearing before decorative trees are placed. Bringing the same species as the active companion replaces the wild double with a resting bond wreath; interacting there gives a peaceful caption rather than a self-duel. Other companions can still take a reward-free friendly spar.

Approach and tap a wild pet, or use E, to open the **existing PetBattlePanel**. The cat uses Bramble Court's arena background and the moth uses Moonlit Ring's; both reuse the original sprites, segmented HP bars, animations, hit effects, music and Attack/Shield/Special turn engine. Starter Ember can challenge either animal without clearing tournament duels or buying levels. The rival uses the existing ready-skill selection and replies after the player's action. There is no forced player timeout. No separate in-world battle overlay or duplicate duel engine remains.

- **Bramble Cat:** 30 arena HP, 4 base damage. As a companion it attacks more strongly and more often than the moth.
- **Dusk Moth:** 42 arena HP, 5 base damage. As a companion it provides stronger, more frequent shielding than the cat.

The world and its combat timers suspend during an accepted challenge, including existing projectiles, hazards and automatic companion support. The battle's Settings button suspends replies, cooldowns and battle input. The map actors and camera stay in place throughout. Close or Return to the Wilds restores the world and controls; replacement cancels the owned session and music. Screen buttons and number keys 1/2/3 choose powers. The result screen remains protected until closed.

A first win immediately commits the bond and companion/village-guardian ownership. The cat pays 25 Gold and 50 participant XP; the moth pays 35 Gold and 65 participant XP. Already-owned pets and friendly repeat spars pay no rewards or guaranteed levels. Rewards belong to the companion that entered the challenge. Losing or leaving changes no saved arena HP and grants no rewards. Normal first-win XP can still heal a companion through level-up. Later expedition defeat cannot erase a bonded pet.

## Saves and outcomes

The optional Waykeeper, Wisp, waits beside Arrival Glade. E or a nearby direct tap opens a short, non-pausing caption. His words recognize memories, bonds and the restored citadel. Meeting him gives no currency, recruitment or campaign objective.

Three weathered stones preserve **The Road That Shone**, **When the Bells Fell Silent**, and **A Light Below the Throne**. They can be read in any order, before or after victory. Reading commits immediately and adds the complete text to **Menu → Field Guide → Story & Sea → Memories of Twilight**. Unknown slots conceal titles and text. Re-reading pays no XP or Gold. Captions own their text independently of landmark hints, have a touch Close button, and dismiss on walking away; they never lock movement or pause the world.

The Rootway Hollow is a small northern pocket at (8,24), reached by the short optional spur from the existing rootway. The world remains **56x52** and the original main road remains **49.55 units**. A bent road marker and moonblooms mark the spur. The pocket can also be reached from the northern approach before opening the winch; the winch still shortens the grove route. No invisible shortcut prerequisite gates the cache. Nearby interactions require a clear physics line to the hollow, preventing E/touch through a wall.

Its single gift is **25 Gold per journey**. In an uncleared realm, opening commits Gold to expedition loot and records a pending cache ID together. Reload keeps it opened without paying again. Banking transfers the claim into the permanent journey ledger alongside the Gold; defeat discards the pending claim with the lost loot and permits a retry. In a restored realm the gift banks immediately, whether the visit has an active expedition or is already post-victory. Opened art loses its glint. Discovery markers appear only after the actual interest is approached with a clear view, rather than merely revealing its map cell.

New saved fields are `realm_progress.waykeeper_met`, `discovered_content`, `read_fragments`, `banked_caches`, and `expedition.pending_caches`. Defaults and sanitization accept old saves, reject unknown/duplicate IDs and reconcile pending claims already banked. All production writes stay in GameState; ambient motion never writes saves.

`GameState.realm_progress` owns discovered cells on a normalized 6x6 map grid, landmarks, shortcut status, a stable checkpoint ID, bonded encounter IDs and saved realm presence. Unknown destinations sanitize to Arrival Glade. Old saves with an active first-portal expedition migrate to the new realm safely. Existing owned pets and cleared duel recruits remain owned.

Continue resumes an active realm visit at its last safe checkpoint; unfinished enemies and bosses reset. Defeat retains the existing home recovery flow, discards ordinary unbanked expedition loot, and preserves the realm checkpoint/discoveries/bonds. Returning through a rift banks expedition loot and ends the visit.

Boss victory commits the existing first-portal rewards, banks expedition loot and opens its existing successor. It restores the terrain/light, removes hostile packs/spells, and leaves the player free to explore. Saved realm presence remains valid after expedition banking; Continue reconstructs the peaceful cleared world. A return rift appears in the chamber. Cleared first realms remain peaceful on revisits rather than automatically repeating the boss.

A dismissible **New for BESUT** reminder names Luma and Bram's free West Workshop
restoration. It survives landmark changes, returning home and save/reload until
Got it is selected. In the village, Village plans opens the existing Missions
panel, which retains the reward explanation. Unread workshop guidance yields to
emergency defense. The reminder hides during modals, travel, stories, home
interiors and settlement editing without pausing simulation.

Wild-companion guidance checks the two actual habitat bonds/owned pets, including
legacy ownership, rather than requiring a retired tournament victory. Both bonds
complete habitat guidance without inventing old duel clears.

Onward passages retain their combat-level gates. Labels show required level and
remaining player XP; an attempted locked entry explains village defense and
cleared later-stage replays as preparation. The peaceful first realm cannot be
farmed after clearing it. Six first-realm encounters plus its first boss provide
342 player XP; a boss-only zero-XP fixture still needs 70 XP for level 3. Companion
challenge XP does not level Adam. No XP, price, enemy or house-tier rebalance is
part of this guidance update.

The expanded map reveals terrain and pet locations as cells are explored. The boss marker appears only after discovering the citadel. No ground route points directly to an undiscovered boss.

## Campaign compatibility and scope

The stable first-stage ID is still `tidebound_grotto`; its ruler remains Shadow & Chaos Fiend and its first-clear Luma reward remains distinct from Dusk Moth. The two later stages are optional physical onward passages east of the citadel, with their actual unlock/level requirements. They retain their existing arena combat, but no longer gate Mei Ling's rescue. They have not been rebuilt as exploration dimensions.

This is the complete first exploration slice. The proposed three-dimension campaign compression remains a future migration: no seven legacy stages, earned rewards, pets or rescue flags were deleted. Arjun's ocean/Kraken rescue remains separate. Shadow & Chaos Fiend holds Mei Ling in Chaos Citadel: his defeat immediately saves her rescue flag and shows her rescue story. She returns to BESUT as a bow defender, while Adam can keep exploring the peaceful realm or choose the return rift. Both rescue orders lead to the same one-time village reunion. Earlier first-clear saves credit her rescue on load without repeating rewards or respawning the boss. A 10–15-minute visit is not claimed without player pacing measurements.

## Ownership and verification

- `RealmDB`: authored paths, landmarks, habitat definitions and checkpoint positions.
- `RealmContentDB`: stable optional-content IDs, words, locations, reservations and journal slots.
- `RealmContentArt`: reproducible pixel art for Wisp, stones, hollow and habitat clues.
- `RealmWildPet` / `RealmInterest`: temporary pet routines and guarded optional interactions.
- `TwilightLandscape`: deterministic terrain/decor; independent from village RNG.
- `TwilightRealm`: world construction, local encounters, threshold/reset, shortcut and victory.
- `RealmCombatDB` / `RealmEncounterDirector`: authored pairs, refuges, shared attack ownership and cancellation.
- `RealmGuard` / `RealmGuardAttack`: physical guard behavior, fixed warnings, swept collision and one-hit casts.
- `RealmGuardRoutes` / `RealmCombatArt`: refuge-aware monster paths and reproducible profile/cover art.
- `RealmInteractable`: nearby direct tap/E routes with current-world guards.
- `PetBattlePanel`: shared arena presentation and manual turns for tournament and habitat battles, with guarded habitat suspension/rewards/cleanup.
- `GameState`: all durable progression and one-time token-guarded reward transactions.

`tools/twilight_checks.gd` runs both inside the canonical isolated gameplay suite and via `tools/twilight_test.tscn`, including `tools/realm_life_checks.gd` for the first expansion and `tools/realm_combat_checks.gd` for the second. The focused scene accepts `-- --capture` under an isolated actual renderer and writes screenshots to `TIDESWORN_TEST_ROOT`. Tests must use the same environment isolation as the canonical wrapper. See the newest Twilight section in `ACCEPTANCE_TESTS.md` for recorded evidence; older reports are historical.

Windows review: use the canonical isolated wrapper with -Twilight, optionally -Capture -Resolution 832x480 or 1280x720. It prints the external evidence directory and rejects incomplete/error-bearing runs.
