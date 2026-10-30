# BESUT rescue campaign

Implemented 2026-10-25 for Godot 4.7.2.

**2026-10-30 dock ending:** after both rescues, Arjun and Mei Ling gather at the live dock. Approach and choose Embark together to start the player-paced reunion, then watch preparation, farewell, boarding, cast-off and sailing. The destination remains open. An ending card returns to title; Explore BESUT explicitly restores Before departure free play. `departure_seen` saves final completion independently of old reunion records. See [DOCK_DEPARTURE_ENDING_PLAN.md](DOCK_DEPARTURE_ENDING_PLAN.md).

**2026-10-30 completed sea journey:** once Arjun is freed, the return ship still
brings Adam and Arjun home, but future boarding and sea/island entry are closed.
The ship remains moored as village scenery. Closure follows the saved
`arjun_rescued` flag, including older completed saves; it needs no extra save field.
A new journey reopens the route. Defeating the Kraken without freeing Arjun and
rescuing Mei Ling alone leave the unfinished sea rescue available. This supersedes
earlier replay descriptions. The final departure is a separate cinematic interaction; it does not reopen the completed sea game.

**2026-10-30 Kraken Island guards:** ten armoured crab monsters guard the fortress
approaches, away from Adam's arrival and the pillars. They skitter, telegraph a
pincer strike, take normal weapon damage and drop collectible Gold when defeated.
All ten crabs and the Kraken engage Adam immediately upon arena entry, including
guards outside the normal proximity radius. The Kraken begins his first tentacle
warning after 0.6 seconds; dodgeable warnings still precede damage.
Hitting a winding-up crab interrupts it. When the Kraken King falls, surviving
crabs retreat without kill rewards so Adam can approach Arjun's unlocked prison.
The prison still requires a separate tap/E interaction to rescue him. The Field
Guide includes the crab; `-OceanLevels` review covers the encounter too.

**2026-10-30 two sea levels:** the current turtle journey has exactly two levels.
Level 1 has bombs, rubbish, heart pickups and fish; level 2 adds sharks. Both last
45 seconds. The first completion saves level 2 before its automatic forward-swim
transition; the second carries Adam directly to Kraken Island. The Sea Guide,
portrait timeline, objectives and Arjun's title-card requirement reflect two levels.
Level 1 also hides the decorative megalodon so sharks are introduced in level 2.
The three-life cap, fish/fullness rules, rubbish penalties and separate Kraken
fight/prison interaction remain in force. Old stage-3 checkpoints load at level 2,
preserving possessions and rescue flags. This supersedes the historical three-route
notes below. Focused review: `tools/test_isolated.ps1 -Godot <console-executable>
-OceanLevels`, with optional `-Capture -Resolution 832x480` or `1280x720`.

**2026-10-30 dock welcome:** after the eight opening beats, Pak Rahim, the village
water keeper, talks to Adam on the actual dock before movement lessons begin.
He offers water and shelter without demanding repayment, listens to Adam's worry
for Arjun and Mei Ling, and suggests meeting the neighbours as a first step.
The player advances the dialogue; original cute, airy anime-inspired artwork sits
on the right. New Journey and interrupted Continue saves use this story handoff
once; later nearby talks are short reminders under normal menu simulation rules.
See `docs/DOCK_WELCOME.md` for the dialogue owner, art prompt and review route.

## Playable story

New journeys start as Adam. The title's other hero cards preview his missing friends. The skippable illustrated opening shows their fishing trip, Arjun hooking the Kraken, the ship breaking into three parts, Mei Ling drifting ashore on the broken bow at a guarded ruin, both friends being captured, and the turtle rescuing Adam. The ruin already has sentries; they take the unfamiliar survivor alive because their ruler wants answers. The Kraken remains an independent sea king, not their commander or servant. Adam repays BESUT's villagers by defending their island while searching for his friends.

The ship leads to two sea levels, each lasting 45 seconds. Level 1 has bombs, rubbish, heart pickups and fish; level 2 adds sharks. Completed levels persist as checkpoints. Level 2 leads to Kraken Island: defeat Vorath, who pursues Adam around the stone pillars, uses telegraphed melee attacks and alternates tentacle slams and dragging hooks; approach the prison and tap it or press E to open it. The rescue scene shows Arjun leaving the cage and boarding the ship. Arjun stands visibly on the rear deck, away from Adam and the mast, with the same foot alignment and human scale as the player. He disembarks and follows village walking routes at the normal resident pace (0.9 world units/second), instead of finishing the trip in a fixed few seconds.

Mei Ling is held by Abyss Monarch in Abyssal Throne, the third and last Monster Portal (level 5). The shortened chain is Chaos Citadel (level 1) → Tempest Spire (level 3) → Abyssal Throne (level 5). Defeating that boss frees her. She walks out through the portal alongside Adam. Both rescued friends become village defenders: Arjun uses his scythe and Mei Ling fires arrows at fire monsters and sea urchins.

When both friends have returned, they wait at the dock for Adam to choose Embark together. The reunion conversation leads into boarding and sailing. The final card returns to title; Explore BESUT offers earlier-time village play. Arjun's completed rescue keeps the playable sea journey closed, including after save/load.

## Turtle controls and rules

- Initial travel speed is 2.5 times the previous baseline; three starting lives. At 50% fullness or above, four-direction steering is equally fast (12 world units/second), including reverse. Below 50%, steering and scrolling use a shared 0.7 speed multiplier. At 0%, the turtle immediately dies, even with remaining lives or blinking protection.
- Steer in all four directions with the joystick, WASD or arrow keys. Reverse steering can catch drifting rubbish; diagonals remain normalized. The rider stays on the shell.
- Pick Up/E collects rubbish for one Gold; each item resolves once.
- Fish within mouth reach are eaten automatically to refill fullness without restoring health; no Eat button or F input is needed. Pink hearts are also collected automatically nearby to restore one life, capped at three, with a recovery effect. Pick Up is the only sea action button and targets rubbish only.
- Bombs drift horizontally and vertically. Contact explodes, costs a life and starts a 1.4-second blinking protection window. Swept collision prevents fast bombs skipping through the turtle.
- Pick Up ignores fish, hearts and hazards without consuming them or costing a life. Each missed rubbish item costs one life, including during blinking protection; missed fish and avoided hazards do not.
- At zero lives, the turtle flips, sinks and fades with its rider; retry becomes available after that animation. Retry preserves cleared-route checkpoints and earned cleanup Gold.
- Controls opens Settings locally during a sea run; the run waits while that settings panel is visible.

## Village interface

Loading screens animate the NPC and pet jumping; Reduce Motion keeps them still. The world clock is bottom-centre, above the screen edge, with interaction prompts separated above it. Press the top-right Map button to view the map with actual resolved shop, portal and jetty anchors, the player, attacked targets and burning trees. Close returns to gameplay; there is no always-visible minimap.

Tower-defense purchases are at the Equipment/Weapons Shop. The existing paid rooftop mounts, costs, targets and house-tier fire rates are unchanged. Construction handles house upgrades.

Settings offers a drag-and-resize control editor alongside numeric X/Y/size rows. World and sea layouts can be edited separately, including Menu. Changes commit through GameState; saved positions remain where selected when GUI scale changes, with viewport clamping for smaller screens.

Tap villagers, workers, rescued friends, guardians, the coastal guard and guide for their roles and abilities. Merchant panels explain their services. The illustrated field guide has People, Monsters, Bosses and Story & Sea categories, with current behavior explanations. Tutorial text now acknowledges attacks on people, explains weapon-shop towers, uses English day/night labels, keeps the world undimmed, and closes training after the first Monster Battle Portal is cleared. Portal 1 victory is recorded across day/night changes; older saves with Portal 1 already cleared also count as finished. Portals 2-3 remain part of the rescue story.

## Ownership and saves

GameState alone persists the campaign dictionary: intro_seen, ocean_stage, arjun_rescued, mei_ling_rescued, ending_seen and departure_seen. Defaults and load sanitization support older saves without discarding currency, equipment, pets, portal progress or settlement layout. New journeys start a new rescue story; existing saves retain their previous hero and progression. Temporary ocean health, items and mid-run position do not persist.

Game owns world transitions and story overlays. Story sequences temporarily suspend their current world and restore it afterward; normal menus retain existing village-time behavior. Friends are rebuilt from stable IDs, with arrival staging and duplicate guards. All tests use temporary user data. Forest IDs, placement RNG and the all-trees-lost rule are unchanged.

## Verification

The focused scene is tools/story_test.tscn; StoryChecks is also part of tools/tide_test.tscn. Coverage includes save migration and checkpoints, actual screen touches and drags, food/heart/bomb damage, blink immunity, death/retry, the real Kraken damage/unlock path, prison interaction, the incoming passenger, both rescue sequences, reunion persistence and ally deduplication. Native renderer captures cover village HUD, NPC information, the control editor, shipwreck, the turtle run, prison island and ending at 1280x720 and 832x480. Final measured tallies are recorded in docs/ACCEPTANCE_TESTS.md.

Physical-phone testing remains with the player. The APK is a release-mode export signed with the existing development certificate for direct installation, not a Play Store submission.

Final evidence: isolated gameplay **1,114 checks, PASS, exit 0**; final native 832×480 **41 checks, PASS, exit 0**. The earlier 1280×720 pass covered 39 checks and the same rescue transitions. The final native fixtures also cover the illustrated story book and weapon-shop tower purchase. Logs are clean.

Android APK exported successfully after reconnect: **ProtectBESUT 1.1.0**, versionCode **2**, **55,528,892 bytes**. Package com.tidesworn.protectbesut includes arm64-v8a and armeabi-v7a, minimum API 24 and target API 36. Release export exited 0 with clean logs; APK Signature Schemes v2/v3 and zipalign -c -P 16 4 verify successfully. SHA-256: 2107c5aaa37b3399301b57abcbfd858463c6ffc60e08ad64e9a2bfbed3e3002d. Output is build/android/ProtectBESUT-1.1.0.apk; build/android/ProtectBESUT.apk is the identical latest copy. The existing development certificate matches the previous APK for direct-install updates.

## Picture map and locked friend cards

The compact map is touch/click/keyboard accessible and opens WorldMapPanel. Both sizes draw the current world terrain and picture markers for shops, portals, home, houses, gardens, the jetty and ship. Letter markers and the explanatory legend are removed. Player location and flashing danger markers remain live. The expanded map uses the existing modal input lock and close path. Dungeon/sea-island maps use their own actual bounds and key landmarks.

Choose Your Road keeps Arjun and Mei Ling locked until their campaign rescue flags are set. Darkened portraits, lock artwork and LOCKED status are accompanied by visible instructions, including on compact layouts. Tapping a locked card opens a fuller explanation without selecting it or writing a save. Arjun requires all three sea routes, the Kraken King and his prison; Mei Ling requires Abyss Monarch in the final Abyssal Throne portal. Each rescue independently unlocks that friend’s card as a village defender, and save reload preserves both unlocks. New journeys still begin as Adam.

MapUnlockChecks is included in the isolated gameplay gate. tools/map_unlock_test.tscn is the focused renderer/touch test; the 832×480 native review passes 18 checks, exit 0, with clean logs and inspected map/card fixtures.

Picture-map/friend-lock verification: complete isolated gameplay **1,132 checks, PASS, exit 0**; native focused review **18 checks, PASS, exit 0**, with inspected 832×480 fixtures and clean stdout/stderr.

APK 1.1.1 (versionCode 3) exported successfully: 55537255 bytes, SHA-256 10ee159e9c6c162f2227be29dbb4b0f4b56955e579aad96742b350208f32677e. APK signatures v2/v3 and 16-KiB ZIP alignment verify. build/android/ProtectBESUT-1.1.1.apk and the stable ProtectBESUT.apk are identical.

## Portal 1 tutorial finish

Clearing Tidebound Grotto finishes and hides the tutorial immediately. Its boss event survives a night-to-day change during combat. Continued saves with Portal 1 already cleared require no repeat fight. Later portal guidance is labeled as the Mei Ling rescue objective. Portals 2-3 and both rescue flags retain their campaign progression.

Full isolated gate: 1,142 checks, PASS, exit 0; clean logs. APK 1.1.2 (versionCode 4): 55537255 bytes; SHA-256 78525b3a0b0f95c198073be8fc1aa88957f209273241d4fb80f347f1dde8bc9c. Signatures v2/v3, 16-KiB alignment, min API 24 and both ARM architectures verified. Output: build/android/ProtectBESUT-1.1.2.apk; stable ProtectBESUT.apk is identical.

## Top-left balances

Gold and diamonds now appear together with their pixel icons in the top-left HUD. GameState data changes refresh both readouts immediately. The panel scales with the existing GUI layout and passes pointer input through to the world. Native 832x480 layout inspected; existing map/card review passes 18 checks, exit 0. APK 1.1.3, versionCode 5, 55537255 bytes; SHA-256 a1ed273a274a9cd3ad7ac894f101dbbb1a3b6db498fa13cc69997b1b1ef571cd. Signature v2/v3 and 16-KiB ZIP alignment verified. Output: build/android/ProtectBESUT-1.1.3.apk; stable APK updated identically.

## Windows control and ocean update 1.2.1

Sprint is permanently visible next to Attack; talk/use/board touch buttons are removed. Tap NPCs and nearby objects directly, and tap the ship to board immediately. Stamina appears below HP. All portal-name CLEARED labels are hidden, including monster/pet selection titles, while progression remains saved. The turtle now swims horizontally and vertically using normalised joystick/WASD input. Animated open-jaw sharks, fish, mermaid, whale, megalodon and diver appear above a decorated seabed with coral, seaweed, sand, crabs, starfish, treasure chests, pearls and a wreck. A portrait timeline spans the three sea routes. Missed objects continue to the viewport edge; the old action-range ring is removed. Street lamps and nearby magnetic currency collection are present in the Windows project.

Verification: isolated full gameplay 1,168 PASS (exit 0); final native 832x480 review 28 PASS (exit 0), including real ship screen taps and inspected controls/ocean fixtures. APK 1.2.1, code 7, 55,554,313 bytes, SHA-256 d25e11e1dc7bf4bf353c27e27df05cbc724469490a192d253b8d4f8df845d01e. Package com.tidesworn.protectbesut and signing certificate match the original 1.1.3 APK; signature v2/v3 and 16-KiB ZIP alignment verify. build/android/ProtectBESUT-1.2.1.apk and stable ProtectBESUT.apk are identical.

## Automatic route travel (1.2.2)

Finishing routes 1 and 2 now visibly carries Adam forwards on the turtle, then automatically loads the next sea route and swims in from the left. The next checkpoint is saved before departure. Successful-route progression does not repeat the diving/rescue introduction or wait for a Next button. The third route uses the same forward swim before entering Kraken Island. Death still offers Ride Again. Each new route retains the previous three-life reset.

1.2.2 verification: full gameplay 1,191 PASS; native story/transition review 62 PASS at 832x480; both exit 0 with clean script/error logs. APK 55558409 bytes, SHA-256 0397042603ee47b9846540dbe03bcb4f3e07fb35499df98f26f3e028fd8b82ba; original package/signature retained, v2/v3 and 16-KiB alignment verified. Output: build/android/ProtectBESUT-1.2.2.apk; stable ProtectBESUT.apk updated identically.

## Kraken fortress and hunger update (1.3.0)

The Kraken arena uses the same blue-grey portal flagstone renderer as the supplied reference, with stone pillars, purple runic circles and dungeon lighting. The camera frames the entire boss, player and illustrated prison. A visible arm grips Arjun’s locked cage while the fighting tentacle alternates an orange telegraph, extending slam and hook/drag. Collision-aware pulling cannot pass through walls; defeating the real boss unlocks the cage for a separate tap-to-free action. Kraken and cage use new cached, original pixel art.

Fish restore 35 fullness (capped at 100), never lives. Swimming drains fullness at 3 per second. The current movement rule slows steering/travel below 50% and makes zero fullness immediately fatal (superseding the original five-second damage interval). Pink hearts still heal. Every rubbish item must be collected: an escaped or uncollected end-of-route item costs one life even during blink immunity, and automatic feeding never consumes rubbish or bypasses its collection penalty. Final route spawns allow enough travel time to collect rubbish before the timer ends. A fatal missed-rubbish penalty prevents advancing the checkpoint. Fullness, lives and missed counts reset on a new route or retry. The HUD and illustrated guide separate fullness from health.

1.3.0 verification: 1,217 full gameplay checks PASS and 25 native checks PASS at 832x480, exit 0. APK 55570862 bytes, SHA-256 7de1f1c21f8d578fc0ce624533f1f8f7cd0848f6c1f581f73451b89a6334094b. Original application ID and signing certificate retained; v2/v3 signatures and 16-KiB ZIP alignment verified. Output: build/android/ProtectBESUT-1.3.0.apk; stable ProtectBESUT.apk updated identically.


## Low-health potion protection

Carry Health Potions from Mara. After a hit leaves the living player at 25% HP or below, one potion is used automatically for up to 45 HP. It can trigger again on the next critical hit while stock lasts, including when maximum HP is high. Healing has green world feedback; depleted stock stays depleted across save/load. It does not revive an already defeated player or affect the turtle's separate sea-run lives/fullness.
