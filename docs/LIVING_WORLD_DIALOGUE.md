# Living-world dialogue — 2026-11-01

## Presentation and scope

Ordinary NPC dialogue, Rahim's welcome and voluntary chats, nearby side-quest
introductions and Citadel preparation/entry/introduction cards now leave the world
visible and processing. They do not set SceneTree.paused or disable the world root.
Characters stand still; the player's visual settles to idle. Ambient particles,
water/shaders, torch flicker, breathing/idle visuals, HUD, village music and the
shared clock continue. Generic NPC text uses a lightly washed bottom panel rather
than a dark central full-screen modal. Touch movement/attack/menu controls release
and hide until close; reading remains player-paced, never timed out.

This changes conversation ownership, not the existing animated story films,
portal/raid reveals, ending playback Pause/Resume, pet arenas or developer pause.
Nonmodal Wisp/lore captions remain ordinary live exploration captions.

## Safe hold, not a hidden global pause

Game owns one `DialogueWorldHold` for its current world. It records weak node
references and original physics callback flags, disabling gameplay physics without
changing process modes, collision layers or actor positions. Selected idle-callback
simulation (forest burn/growth, roof guns, floating rubbish, resource cooldowns,
wild-pet routines and arrival cues) also holds. Ambient world callbacks and visual
children continue. Newly ready world descendants join before their first physics
step. Existing disabled callbacks and dormant boss modes remain disabled afterward.
Damage APIs for player/enemy/resident/tree/structure reject late hits during a hold.
Realm attack/reinforcement ownership also rejects held worlds.

The clock and daylight can cross night while reading. Lobby defers hostile arrival
creation; release rechecks only the current night through the existing deduplicated
arrival owner, not an accumulated burst of missed waves. Existing cues and combat
callbacks resume without catch-up delta. Recovery healing also waits during a hold.
Ordinary shops/settings/inventory keep their prior live simulation behavior.

Close, skip and cancellation restore recorded callback flags exactly once, release
held inputs, and retain current modal/story/transition locks. World replacement
also closes ordinary dialogue and cannot freeze or unlock a replacement world.
No saved field, progression bypass, reward, stat or save-version change is added.

## Validation

`tools/dialogue_hold_checks.gd` is included in the canonical isolated tide gate;
standalone scene: `res://tools/dialogue_hold_test.tscn`, with `-- --capture` for an
actual renderer. Set BOTH XDG_DATA_HOME and TIDESWORN_TEST_ROOT to disposable
external paths before imports or tests. Tests exercise actual frames/ambient and
clock advancement, stationary actors, held/dynamically created callback ownership,
late damage, night crossing, restoration, menus, replacement and Citadel ambience.
Existing dock, side-quest, Twilight, portal, reunion, developer and full tide checks
remain authoritative for their other contracts. Results are in ACCEPTANCE_TESTS.md.
