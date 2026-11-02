# Adam-only selection and boat cast introduction

## Intent and boundaries

Remove Arjun and Mei Ling **entirely from new-journey character selection**, not from the game. No locked cards, silhouettes, rescued cards or rescue-requirement overlays remain there. Adam is the sole story hero. Keep the existing Start → Adam’s Journey → Begin flow, replacement confirmation, Continue and legacy saved heroes. CharacterDB, rescue flags, weapons, defenders and ending remain intact.

Introduce **Adam, Arjun and Mei Ling on their actual boat** before showing the whole group. Meet people before explaining the disaster: calm → confidence → affectionate teasing → togetherness → interruption. Do not use floating portraits, combat poses, weapon demonstrations or character-select stat cards for the introductions.

## Authored animatic / normal motion

All times below begin after the existing title/loading reveal. These are six-second shots; Next can advance early. No recorded voice-over or new music is claimed: the dialogue is readable text, and acting/editing carries the exchange.

| Time | Framing and performance | Dialogue / edit motivation |
| --- | --- | --- |
| 0–6 s: Adam | Warm medium close-up at the stern rail, camera at face/chest height. Keep timber, rope and sail visible so he is already aboard, not against an abstract portrait background. A restrained 4.2×→4.32× push emphasizes stillness. At 0.8 s he looks right; hold that look instead of looping gestures. Settle at 4.6 s. | **Adam:** “Quiet out here. I could get used to this.” His rightward eyeline motivates the next cut. Calm is his introduction, not exposition about his future combat role. |
| 6–12 s: Arjun | Cut rightward along the deck to the fisherman. Retain the same sail, horizon and rail. He lifts his hands and attached rod together at 0.8 s, lets his confidence land, then relaxes at 4.6 s. The line remains connected to the rod/float. | **Arjun:** “Wait till you see what I catch.” A harmless boast now; a setup for the hooked Kraken later. Do not reveal the Kraken early or turn the shot into an ominous warning. |
| 12–14.2 s: Mei Ling | Reaction close-up on the bench; mirror her cutscene actor **about its foot anchor**, facing back toward Arjun. Keep part of him and the rod in the frame, giving her reply a visible recipient. Her restrained hand/face pose punctuates the joke. | **Mei Ling:** “Catch dinner first. Then we’ll be impressed.” Affectionate, not hostile. Hold the reaction before moving the camera; the viewer should read the punchline, not chase a zoom. |
| 14.2–17.6 s: pullback | In Mei Ling’s same shot, ease smoothly from her framing to the complete boat. At local 4.6 s she settles toward the shared horizon. Reveal the triangle: Adam stern, Arjun fishing amidships, Mei Ling seated forward. Preserve every deck/foot/prop anchor. | The joke becomes a group moment. This is one continuous reframing, not a dissolve to a different illustration. |
| 17.6–18 s: landing | Hold exact full-boat camera, base actor poses and fishing-prop geometry. | A short settling beat avoids a camera pop at the next page boundary. |
| 18–24 s: together | Existing layered wide fishing shot: all three friends visible, yellow UNISZA hull, sail, bucket, sea and float. Label: **THREE FRIENDS · ONE BOAT**. Existing small fishing/friendship gestures resume. | Establish what “together” looks like before separation. This group geography is the reference for the wreck’s three fragments. |
| 24–30 s: hook / awakening | Existing tension-before-reveal performance: connected line catches an arm, body emerges, eyes awaken, fury holds. | The boast pays off as a reversal, not a separate unrelated incident. |
| 30–66 s: consequence / home | Existing ship strike and three-way separation → Mei Ling’s landfall → both captures → Adam’s turtle rescue → village promise → BESUT welcome. | Preserve cause-and-effect and all rescue/campaign ownership. The dock welcome and gameplay still follow. |

## Edit, composition and accessibility rules

- Direct motivated cuts Adam → Arjun → Mei Ling, then a motivated pullback → wide. Same boat space, light, horizon and actor positions; no flipped boat or mirrored text/rod. Only Mei Ling’s actor changes facing, then returns to the original group pose.
- Name labels identify people, not RPG classes. Short dialogue remains fully visible immediately; no typewriter presses or invented VO.
- The automatic introduction now has **11 pages / 66 seconds**, plus the unchanged loading/title reveal (normal 1.59 s with loading). The three new pages add 18 seconds. Next and Skip remain available.
- Opening Pause freezes arrival/shot time and Next. Window focus loss freezes time; focus return resumes only if the user did not manually pause. Skip remains an escape during manual pause. Completion is still emitted once and progression remains owned by Game.
- Reduce Motion uses stable readable character tableaux and a static complete group for Mei Ling’s final reveal: no push, pullback, bob or gesture loop. Low effects removes optional water detail, not cast/action/camera information. Setting changes never restart narrative time.
- Clip enlarged boat art above the caption panel. Preserve uniform pixel scale; fit faces and controls at 1280×720 and 832×480. Compact opening controls also fit a 360×780 portrait viewport.

## Implementation ownership

- `TitleScreen.HERO_IDS` is the UI-only allowlist, independent of CharacterDB; stale friend selection calls are rejected even after rescue/load.
- `OpeningCastRenderer.sample()` is deterministic presentation data: named subject, fixed feet, finite acting poses, matched camera and reaction eyeline. No saves, world RNG, gameplay actors or asynchronous callbacks.
- `OpeningFishingRenderer.draw()` reuses original layered boat art and restores its drawing transform after the reaction flip. The cast renderer’s final geometry equals the existing fishing renderer’s initial geometry.
- `StorySequence.INTRO_*_PAGE` constants bind story routing; old numerical test offsets are replaced where affected. Opening pause/focus ownership does not change rescue or ending controls.

## Verification and delivery

See the sibling `VERIFICATION.txt` for actual commands, stdout, stderr, exit codes, hashes, corrections and final results; historical check counts are not current proof. Rendered review captures cover the individual shots, partial pullback, final group, reduced motion and Adam-only selection. The title review uses real mouse, touch and keyboard events, including replacement/Continue paths.

This deliverable is a runnable modified project copy. The original checkout is retained byte-for-byte; the accompanying patch reconstructs the candidate from the pristine source, and the executable rollback is tested on a separate candidate copy. No commit, push, export, Windows-native run, audio listening test or physical-device touch test is implied.
