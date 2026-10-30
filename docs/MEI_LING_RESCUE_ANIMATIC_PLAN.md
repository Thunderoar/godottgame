# Mei Ling rescue at Chaos Citadel - proposed animatic

Planning date: 2026-10-30. This document records the approved storyboard and implementation plan. The seven-beat rescue is now implemented; see the latest section of `ACCEPTANCE_TESTS.md` for current verification rather than treating planned checks below as test results. Render review placed the runtime prison at (31,7), clear of the HUD; the original candidate below remains planning history.

## Accepted direction

Shadow & Chaos Fiend's defeat starts an animated rescue at his own citadel. The sequence shows Mei Ling's prison opening, Adam reaching her, and her safe passage to BESUT. Adam then resumes exploration in the restored Twilight Wilds.

The latest request replaces the earlier approach-and-interact option: opening the prison happens inside the animatic. There is no additional rescue interaction after victory. The fiend remains the first-realm boss, under the stable ID `tidebound_grotto`.

## Why the presentation needs work

The current progression already belongs to this boss. `GameState.complete_portal()` records Mei Ling's rescue before presenting it. `TwilightRealm._on_boss_finished()` restores the realm and routes the first rescue into `Game._rescue_mei_ling()`.

The missing piece is visual causality. The current scene supplies two captions and slides Adam and Mei Ling toward a generic portal. A temporary sprite is placed beside Adam just before the story hides the world. The player does not see a captive in the arena, a prison releasing her, an actual meeting, or a visible arrival in BESUT.

The new sequence should make those actions readable with captions hidden. Captions provide emotion and context rather than explaining actions the artwork never performs.

## Encounter setup

- Add a visible stone prison alcove and magical seal behind and slightly to the right of the fiend. A starting layout candidate is around world position (29, 5); finalize it through camera and movement review rather than treating that coordinate as approved geometry.
- Show recognizable Mei Ling inside: existing face, tied hair, clothing palette and human scale. A hand at the seal or a small turn toward Adam communicates that she is alive.
- Repeat a modest architectural detail from the opening's guarded ruin so the prison feels like the destination of her capture.
- The seal shares the fiend's chaos color and emblem. Its animation responds to his defeat during the rescue.
- The alcove is scenery, not an enemy, destructible target or navigation obstacle. Keep existing attack lanes and threshold activation intact.
- Keep the prisoner and upper prison silhouette inside the boss framing at both supported review sizes. If composition fails, move the alcove before widening the arena or shrinking characters.
- Before rescue the alcove shows its captive; afterward it is open and empty. Derive that state from the existing campaign flag, including peaceful revisits and legacy saves.

## Proposed storyboard

Target approximately 24 seconds of animation before any optional reading holds. Timings are an editorial starting point, not a measured player-session duration.

| Beat | Time | Shot and action | Sound and words | Purpose |
| --- | --- | --- | --- | --- |
| 1. The last strike | 0-2 s | Match the citadel's geography. The fiend buckles and breaks into dark ash. Adam stays braced until the danger passes. The prison remains visible in the background. | Battle music resolves into a low fading note; one final impact, then quiet. | Connect the rescue directly to the enemy just defeated. |
| 2. The prison answers | 2-5 s | Cut closer to Mei Ling. The same chaos emblem dims, fractures and sheds its light. She looks up and takes her hand away from the seal. | A restrained stone crack and fading magical hum. No explanatory caption needed. | Show that the fiend powered her captivity. |
| 3. Freedom | 5-8 s | The seal dissolves and the prison gate retracts. Mei Ling steps across the threshold onto solid ground, steadies herself, then faces Adam. | Gate movement and a clear footstep. Adam: "Mei Ling!" | Make release a visible action, with continuous physical contact and movement. |
| 4. They meet | 8-13 s | Adam lowers or sheathes his sword and crosses the short distance. He offers a hand; she takes it, then stands independently. They exchange a relieved look. | Mei Ling: "Adam... you found me." Adam: "You're safe now." | Give the rescue a human payoff and give Mei Ling her own response. |
| 5. A road home | 13-18 s | Warm light returns through the chamber's stone channels. Adam indicates the restored return rift; Mei Ling turns toward it. A brief wide shot keeps the opened prison, both friends and the route readable. | Mei Ling: "And Arjun?" If he is rescued: "He's safe in BESUT." Otherwise: "I'm still looking. I'll find him." Then: "Go through. The villagers will help you." | Connect this rescue to the other friend without inventing his rescue or location. |
| 6. She arrives | 18-22 s | Mei Ling walks into the rift. Match-cut to her emerging in BESUT, where familiar villagers welcome her. Include Arjun only when his saved rescue flag is true. | Gentle portal sound, village ambience and a short musical resolution. | Demonstrate safe arrival while explaining why Adam does not accompany her. |
| 7. Back to Adam | 22-24 s | Return to Adam in the cleared citadel. The prison is empty and the return rift remains. Dissolve back to the actual gameplay view and restore controls. | Persistent guidance: "Mei Ling is safe in BESUT. Explore the restored Wilds or return through the rift." | End with an understandable location and next action. |

The BESUT insert is an authored shot. It must not construct a live Lobby or advance village simulation during the suspended story. After the sequence, the normal Lobby rebuild creates the actual saved defender when Adam returns.

If both friends are now rescued, keep the existing village reunion ending for Adam's real return to BESUT. The arrival insert must not mark `ending_seen` or consume that reunion.

## Animation and presentation rules

- Use distinct poses for bracing, looking up, stepping free, offering/taking a hand and standing. Do not represent the whole rescue as two idle sprites sliding across a background.
- Keep feet planted during holds. Gate travel must reveal a real opening; Mei Ling crosses it only after clearance. Her hand and Adam's hand must meet in the contact pose.
- Maintain recognizable citadel colors and architecture across cuts. The shift from chaos purple to warmer restored light supplies the scene's visual arc.
- Keep characters and the gate readable at 832x480 as well as 1280x720. Reserve caption space outside the action and preserve nearest-neighbor pixel rendering.
- Use sound sparingly: impact, seal, gate, footsteps, portal and musical resolution. All essential actions remain understandable muted.
- Reduce Motion uses composed key poses and short dissolves through every narrative beat. It removes shake, strong flashes and sweeping camera movement without jumping directly from captivity to a village portrait.
- Low effects may reduce ash and particles, but must retain the seal change, opening, release and arrival.
- Next advances to a coherent beat boundary; Skip completes the whole scene safely. Input release and a fresh-press guard prevent the attack/tap that killed the fiend from immediately skipping the rescue.
- Give dialogue a readable hold where needed. Use durations specific to this rescue; do not change the six-second timing of unrelated intro, Arjun or ending scenes.

## State and lifecycle design

Keep the existing immediate-rescue contract. The boss-clear transaction remains responsible for the clear, rescue flag, banked loot, rewards, successor unlock and mission progress. Commit the outcome before starting the animatic.

No new prison-pending state or rescue save schema is needed for this direction. Old first-clear saves continue receiving Mei Ling's rescue through the existing sanitizer. Already-rescued saves retain her freedom and show an empty prison without replaying the sequence or issuing rewards.

Game owns the sequence and the temporary suspension of its current world. The renderer owns only temporary visual state. The presentation must never write campaign flags or pay rewards at an animation timestamp.

Capture the owning world and journey serial at entry. Guard repeated starts and re-check ownership after awaits. A single completion path handles natural completion, Next, Skip and cancellation. Restore HUD/process/input state only for the world and journey that still own the operation. Avoid replaying frame-triggered audio when drawing or changing settings.

If the application closes during the animatic, Continue restores the peaceful cleared realm and the already-saved rescue. It need not replay the rescue to make progression valid. Returning home creates one Mei Ling defender through the existing stable-ID synchronization.

Resolve battle audio once at the story handoff. Do not rely on the ordinary enemy fade tween to finish while its world is suspended: the authored first beat supplies the fiend's visible defeat. Remove the current temporary duplicate Mei Ling sprite when the new renderer provides her complete presentation.

## Implementation order and owners

1. Lock the storyboard and rough compositions. Check arena alcove placement, prison silhouette, hand contact and the rift-to-village match cut at both target sizes before polishing particles.
2. Add shared prison/character pose art using the existing procedural pixel-art and cached-texture patterns. Proposed owners: `scripts/core/mei_ling_rescue_art.gd` and `scripts/ui/mei_ling_rescue_renderer.gd`. Keep a deterministic `sample(elapsed, reduced, quality, arjun_rescued)` interface, following the opening renderers. Share prison identity between world and story instead of building unrelated designs.
3. Integrate captive/open-empty presentation in `scripts/world/twilight_realm.gd`, with its stable anchor in `scripts/data/realm_db.gd`. Confirm that scenery does not change combat collision or targeting.
4. Replace the generic `kind == "mei"` drawing in `scripts/ui/story_sequence.gd` with the authored rescue renderer and scene-specific beat timing. Keep its existing completed signal and Game ownership. Update `scripts/game/game.gd` to remove duplicate sprite presentation and guard the handoff.
5. Update all player-facing rescue wording together: `scripts/ui/npc_info.gd`, `scripts/ui/mission_panel.gd`, `scripts/ui/title_screen.gd`, `scripts/ui/objective_tracker_data.gd`, `scripts/data/field_guide_db.gd` and applicable portal/mission descriptions. Remove the stale "final portal boss" description and any wording that still asks for Mei Ling after she is already safe.
6. Extend the dedicated rescue checks and relevant story/Twilight integration checks. Add the new acceptance contract to `docs/ACCEPTANCE_TESTS.md`, update `docs/TWILIGHT_WILDS.md`, and record the presentation update in `AGENTS.md` without erasing historical evidence.

## Acceptance and evidence

Behavior checks:

- Threshold activation remains required; victory starts one rescue sequence at the correct boss.
- Rescue is saved before the first animated frame. Duplicate boss signals, repeated completion, Skip and repeated input cannot pay twice or start another sequence.
- Pending combat effects cannot hurt Adam during the story. The world, clock, HUD and controls recover correctly afterward.
- Skipping from each beat yields the same saved rescue and peaceful realm as natural completion.
- Actual JSON reload during the post-victory state preserves rescue, currency, pets and clear history. Old first-clear saves and already-rescued saves remain compatible.
- Both Arjun states produce truthful dialogue and village inserts. No premature reunion occurs; both rescue orders still lead to one ending on actual village return.
- BESUT creates one bow defender, and her existing ranged attacks still damage the intended village threats.

Presentation checks:

- Sample consecutive frames through the gate opening, first step, hand contact and portal entry. Check clearance, grounded feet, pose order and movement continuity, not only final positions.
- Inspect real rendered shots of captive, defeated fiend, open prison, meeting, village arrival and restored gameplay at 832x480 and 1280x720.
- Review normal and Reduce Motion, low effects, mute, long captions and mid-scene live-setting changes. Essential story actions remain legible.
- Test Next, Skip and touch/mouse/keyboard input without held attacks carrying into the returned world.

Run an isolated import before gameplay checks if global classes change. Extend `tools/test_isolated.ps1` with a mutually exclusive rescue-focused switch that selects the existing `tools/mei_ling_rescue_test.tscn`, supports captures at both resolutions, rejects failure/error markers and requires its exact PASS summary plus exit 0. Then run the focused rescue route, Twilight route and canonical full gameplay gate with isolated APPDATA, LOCALAPPDATA and TIDESWORN_TEST_ROOT. Never run the destructive fixtures against normal player data.

Finish with `git diff --check`, scoped source inspection and current acceptance evidence. Preserve unrelated user files, including the existing untracked Android rendering plan. This planning document itself makes no runtime or device-validation claim.
