# BESUT rescue campaign

Implemented 2026-10-25 for Godot 4.7.2.

## Playable story

New journeys start as Adam. The title's other hero cards preview his missing friends. The skippable illustrated opening shows their fishing trip, Arjun hooking the Kraken, the ship breaking into three parts, both friends being captured, and the turtle rescuing Adam. Adam repays BESUT's villagers by defending their island while searching for his friends.

The ship leads to three sea routes, each lasting 45 seconds. Completed routes persist as checkpoints. Route three leads to Kraken Island: defeat Vorath, approach the prison and press Use to open it. The rescue scene shows Arjun leaving the cage and boarding the ship. His visible passenger returns to the jetty, disembarks and walks into the village.

Mei Ling is held by Malakar in Drowned Throne, the last Monster Portal. Defeating that boss frees her. She walks out through the portal alongside Adam. Both rescued friends become village defenders: Arjun uses his scythe and Mei Ling fires arrows at fire monsters and sea urchins.

When both friends have returned, an illustrated reunion reveals that their fishing voyage crossed into another dimension. They choose BESUT as their new home. The ending is saved once; village play continues afterward. The sea king can be challenged again without imprisoning or recruiting Arjun twice.

## Turtle controls and rules

- Initial speed is 2.5 times the previous baseline; three starting lives.
- Steer up/down with the joystick, W/S or arrow keys. The rider stays on the shell.
- Pick Up/E collects rubbish for one Gold; each item resolves once.
- Eat/F consumes food without restoring health. Pink hearts periodically appear: Eat one to restore one life, capped at three, with a recovery effect.
- Bombs drift horizontally and vertically. Contact explodes, costs a life and starts a 1.4-second blinking protection window. Swept collision prevents fast bombs skipping through the turtle.
- Wrong item actions cost a life. Missed items do not act as bomb collisions.
- At zero lives, the turtle flips, sinks and fades with its rider; retry becomes available after that animation. Retry preserves cleared-route checkpoints and earned cleanup Gold.
- Controls opens Settings locally during a sea run; the run waits while that settings panel is visible.

## Village interface

Loading screens animate the NPC and pet jumping; Reduce Motion keeps them still. The world clock is bottom-centre, above the screen edge, with interaction prompts separated above it. A top-right minimap uses actual resolved shop, portal and jetty anchors, marks the player, and flashes red at attacked targets and burning trees.

Tower-defense purchases are at the Equipment/Weapons Shop. The existing paid rooftop mounts, costs, targets and house-tier fire rates are unchanged. Construction handles house upgrades.

Settings offers a drag-and-resize control editor alongside numeric X/Y/size rows. World and sea layouts can be edited separately, including Menu. Changes commit through GameState; saved positions remain where selected when GUI scale changes, with viewport clamping for smaller screens.

Tap villagers, workers, rescued friends, guardians, the coastal guard and guide for their roles and abilities. Merchant panels explain their services. The illustrated field guide has People, Monsters, Bosses and Story & Sea categories, with current behavior explanations. Tutorial text now acknowledges attacks on people, explains weapon-shop towers, uses English day/night labels, keeps the world undimmed, and closes training after the first Monster Battle Portal is cleared. Portal 1 victory is recorded across day/night changes; older saves with Portal 1 already cleared also count as finished. Portals 2-10 remain part of the rescue story.

## Ownership and saves

GameState alone persists the campaign dictionary: intro_seen, ocean_stage, arjun_rescued, mei_ling_rescued and ending_seen. Defaults and load sanitization support older saves without discarding currency, equipment, pets, portal progress or settlement layout. New journeys start a new rescue story; existing saves retain their previous hero and progression. Temporary ocean health, items and mid-run position do not persist.

Game owns world transitions and story overlays. Story sequences temporarily suspend their current world and restore it afterward; normal menus retain existing village-time behavior. Friends are rebuilt from stable IDs, with arrival staging and duplicate guards. All tests use temporary user data. Forest IDs, placement RNG and the all-trees-lost rule are unchanged.

## Verification

The focused scene is tools/story_test.tscn; StoryChecks is also part of tools/tide_test.tscn. Coverage includes save migration and checkpoints, actual screen touches and drags, food/heart/bomb damage, blink immunity, death/retry, the real Kraken damage/unlock path, prison interaction, the incoming passenger, both rescue sequences, reunion persistence and ally deduplication. Native renderer captures cover village HUD, NPC information, the control editor, shipwreck, the turtle run, prison island and ending at 1280x720 and 832x480. Final measured tallies are recorded in docs/ACCEPTANCE_TESTS.md.

Physical-phone testing remains with the player. The APK is a release-mode export signed with the existing development certificate for direct installation, not a Play Store submission.

Final evidence: isolated gameplay **1,114 checks, PASS, exit 0**; final native 832×480 **41 checks, PASS, exit 0**. The earlier 1280×720 pass covered 39 checks and the same rescue transitions. The final native fixtures also cover the illustrated story book and weapon-shop tower purchase. Logs are clean.

Android APK exported successfully after reconnect: **ProtectBESUT 1.1.0**, versionCode **2**, **55,528,892 bytes**. Package com.tidesworn.protectbesut includes arm64-v8a and armeabi-v7a, minimum API 24 and target API 36. Release export exited 0 with clean logs; APK Signature Schemes v2/v3 and zipalign -c -P 16 4 verify successfully. SHA-256: 2107c5aaa37b3399301b57abcbfd858463c6ffc60e08ad64e9a2bfbed3e3002d. Output is build/android/ProtectBESUT-1.1.0.apk; build/android/ProtectBESUT.apk is the identical latest copy. The existing development certificate matches the previous APK for direct-install updates.

## Picture map and locked friend cards

The compact map is touch/click/keyboard accessible and opens WorldMapPanel. Both sizes draw the current world terrain and picture markers for shops, portals, home, houses, gardens, the jetty and ship. Letter markers and the explanatory legend are removed. Player location and flashing danger markers remain live. The expanded map uses the existing modal input lock and close path. Dungeon/sea-island maps use their own actual bounds and key landmarks.

Choose Your Road keeps Arjun and Mei Ling locked until their campaign rescue flags are set. Darkened portraits, lock artwork and LOCKED status are accompanied by visible instructions, including on compact layouts. Tapping a locked card opens a fuller explanation without selecting it or writing a save. Arjun requires all three sea routes, the Kraken King and his prison; Mei Ling requires Malakar in the final Drowned Throne portal. Each rescue independently unlocks that friend’s card as a village defender, and save reload preserves both unlocks. New journeys still begin as Adam.

MapUnlockChecks is included in the isolated gameplay gate. tools/map_unlock_test.tscn is the focused renderer/touch test; the 832×480 native review passes 18 checks, exit 0, with clean logs and inspected map/card fixtures.

Picture-map/friend-lock verification: complete isolated gameplay **1,132 checks, PASS, exit 0**; native focused review **18 checks, PASS, exit 0**, with inspected 832×480 fixtures and clean stdout/stderr.

APK 1.1.1 (versionCode 3) exported successfully: 55537255 bytes, SHA-256 10ee159e9c6c162f2227be29dbb4b0f4b56955e579aad96742b350208f32677e. APK signatures v2/v3 and 16-KiB ZIP alignment verify. build/android/ProtectBESUT-1.1.1.apk and the stable ProtectBESUT.apk are identical.

## Portal 1 tutorial finish

Clearing Tidebound Grotto finishes and hides the tutorial immediately. Its boss event survives a night-to-day change during combat. Continued saves with Portal 1 already cleared require no repeat fight. Later portal guidance is labeled as the Mei Ling rescue objective. Portals 2-10 and both rescue flags retain their campaign progression.

Full isolated gate: 1,142 checks, PASS, exit 0; clean logs. APK 1.1.2 (versionCode 4): 55537255 bytes; SHA-256 78525b3a0b0f95c198073be8fc1aa88957f209273241d4fb80f347f1dde8bc9c. Signatures v2/v3, 16-KiB alignment, min API 24 and both ARM architectures verified. Output: build/android/ProtectBESUT-1.1.2.apk; stable ProtectBESUT.apk is identical.

## Top-left balances

Gold and diamonds now appear together with their pixel icons in the top-left HUD. GameState data changes refresh both readouts immediately. The panel scales with the existing GUI layout and passes pointer input through to the world. Native 832x480 layout inspected; existing map/card review passes 18 checks, exit 0. APK 1.1.3, versionCode 5, 55537255 bytes; SHA-256 a1ed273a274a9cd3ad7ac894f101dbbb1a3b6db498fa13cc69997b1b1ef571cd. Signature v2/v3 and 16-KiB ZIP alignment verified. Output: build/android/ProtectBESUT-1.1.3.apk; stable APK updated identically.
