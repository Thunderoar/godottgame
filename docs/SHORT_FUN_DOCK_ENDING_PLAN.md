# Short, playful dock ending - proposed revamp

Planning date: 2026-10-30. Status: implemented. This is the approved creative direction; see the implementation notes below and the newest acceptance entry for fresh validation.

## Direction

The user says the ending dialogue is too long and wants a more fun version. Keep the live dock waiting, deliberate Embark choice, actual voyage, open destination and before-departure free play. Rework the delivered ending around a brief reunion, affectionate banter and visible action.

The live source contains 30 spoken turns (204 spoken words), followed by seven departure pages with required holds totaling 28 seconds. Reading requires at least 37 forward activations, including the final title action, and can reach 67 when each dialogue turn is manually revealed first. The revision should address word count, repeated explanations and input friction together.

Recommended target: nine short spoken lines / approximately 40 words, arranged as three exchanges on three readable conversation cards. That is roughly 80% less spoken text. Follow them with one continuous 17-second departure film and an intentional final-card title action. Aim for about 30-40 seconds with comfortable reading; actual reader-controlled time is unlimited and must be measured in implementation rather than promised as a fixed runtime.

## Emotional and comic spine

- Adam gets a quiet moment of relief, joins the banter, then gives BESUT a sincere thank-you.
- Arjun volunteers the no-fishing rule himself. His humor shows self-awareness and useful preparation; he is not made reckless or helpless again.
- Mei Ling enjoys the joke and invents the affectionate Captain Snacks nickname. Her participation should look playful rather than stern or parental.
- A small prop action pays off the dialogue: Arjun has packed food for the three friends. The others help him aboard with it.
- Preserve one unhurried shared smile after Adam says he missed this. Avoid another trauma recap, apology sequence, checklist or discussion about where to go next.
- The teasing concerns the old fishing disaster and the new snacks. Avoid jokes about imprisonment, abandonment, death, or a friend being unwelcome aboard.

## Proposed finished dialogue

### Exchange 1 - Three again

Adam approaches and the friends close the gap between them. Brief eye contact carries the relief before the joke.

Adam: "All three. Finally."
Arjun: "New rule: no fishing."
Mei Ling: "A plan with fewer tentacles. I like it."

Arjun shows his empty hands with a small, self-aware smile. Mei Ling shares the joke with him; neither scolds him. No new fishing-rod item or acquisition needs explanation.

### Exchange 2 - Captain Snacks

Arjun lifts a small parcel bag with unnecessary ceremony. Reveal three wrapped portions as a visual sign that he has thought about the whole group.

Arjun: "I brought snacks instead."
Mei Ling: "Captain Snacks. A much safer career."
Adam: "You two... I missed this."

Mei Ling gives an exaggerated little salute. Arjun straightens proudly, then Adam's warm smile settles the scene for a moment. The nickname is dialogue only: do not add a character title, rank or gameplay statistic.

### Exchange 3 - Time to go

Include the villagers in the composition. Adam turns toward Rahim and BESUT for his line; the friends answer the villagers' wave together.

Adam: "Thanks for everything, BESUT."
Mei Ling: "All aboard, Captain."
Arjun: "Best promotion ever."

Mei Ling's line calls back to her own nickname joke. Arjun gestures toward the gangplank with his supplies. The group begins moving as the player chooses Set sail.

All three characters have three lines. The final wording is an editorial proposal for review, not a change to character biographies.

## Reading and input

Use three conversation cards, each with three clearly named, compact dialogue rows. This keeps the exchange together and gives the player three deliberate reading stops rather than nine small interruptions.

- All text on a card appears immediately. Remove the ending's mandatory Show line / Next double action. Named rows preserve readability without requiring color recognition.
- Next advances cards 1 and 2. Set sail on card 3 begins the departure film. The latter is a clear action label at the handoff into motion.
- The player can hold any card indefinitely. Expressions and small gestures play once, then settle; the same gag must not loop while someone reads slowly.
- Keep the initial held-input release guard and touch/mouse debounce. One fresh action advances one card; the Embark gesture must not advance the first card too.
- Optional speaker murmurs remain brief, owned and skippable with the card. They never gate a button or delay a fast reader.
- Skip conversation goes directly to boarding. During the film, Skip ending goes to the final card. Neither consumes saved completion before the final card's explicit title action.
- Keep a small Pause/Resume control during the film and pause film time on focus loss. Manual pause and focus pause are separate, so regaining focus cannot undo a deliberate pause.
- Remove numbered seven-part departure labels and narration that repeats visible actions. Dialogue retains named speakers; the sailing film has no reading-dependent captions.

## Continuous departure storyboard

The following timings are targets. Refine them against actual captures while keeping the gangplank crossing readable.

| Film time | Picture and action | Purpose |
| --- | --- | --- |
| 0-6 seconds | Mei Ling, Arjun and Adam cross the gangplank in order. Near the top, Arjun's snack bag wobbles during a proud little salute; Mei Ling steadies it. Nobody falls, drops supplies into the water or leaves a friend behind. | Continue the joke through cooperative action; preserve visible boarding. |
| 6-9 seconds | Secure the parcels, release the final mooring and begin moving. All three and an active companion must already be aboard. | Make the departure physically clear. |
| 9-13 seconds | Rahim and the villagers wave as the ship separates from the jetty. Adam waves back. If framing permits, the familiar rescue turtle briefly surfaces and returns the wave. | Pay off BESUT's help and echo the turtle's opening rescue without another speech. |
| 13-17 seconds | Close on the three friends together aboard the yellow ship, then widen toward the open horizon and dissolve into the ending card. Let the final few seconds breathe. | Give the short ending warmth and a sense of a shared future. |

The turtle cameo is a presentation-only farewell, folded into the existing shot rather than another scene or stop. If it crowds the villagers/crew, omit it. The snack gag works without an equipped companion; a living pet can add a quiet reaction but is not required to understand the scene.

Keep the final line "Together, wherever the tide leads." The final card waits for Return to title, retaining a short input/readability guard. Do not duplicate the same final line in both the artwork and a second narrative paragraph below it.

## Visual and sound treatment

Keep the existing pixel-art family, dock, yellow UNISZA ship and human-scale actors. Add only the expressive poses and small food props needed to sell the new exchange: empty-handed self-awareness, parcel presentation, amused salute, shared smile and cooperative boarding.

Use a three-shot for most of the chat. A brief closer framing for the parcel reveal is enough; do not cut mechanically to a face for every short line. Reuse the existing boarding path and hull layering, then drive cast-off and sailing from a continuous cumulative clock so a shot transition never sends the ship backward.

A light warm musical bed, a small wooden creak and water give the departure energy. Leave space for the relief line and the final horizon. Use no laugh track, threatening Kraken sting or exaggerated disaster tease.

Capture the current day/night palette at entry. Low effects keeps every essential gesture/prop. Reduce Motion retains essential continuous boarding and ship separation, with stable helping/saluting poses and no bag wobble or ambient water drift. Muted playback must carry the complete joke and emotional close.

## Implementation plan

1. Put the three proposed exchanges into a compact data model with stable exchange/line IDs, speakers and moods. Represent the four departure shots with stable IDs and durations. Keep accessors returning copies.
2. Refactor only the ending branch of StorySequence into dialogue cards, continuous departure and final card. Intro and Mei Ling rescue timing/input remain independent. Keep the existing test-accessed members or explicit compatibility helpers where needed.
3. Update ReunionRenderer to sample exchange reactions and the cumulative departure timeline. Cache the small new poses and props on entry; rendering never builds art or writes progression.
4. Preserve Game's current Embark readiness, world/clock suspension, cancellation and covered title handoff. Preserve GameState's ending_seen/departure_seen completion transaction and failed-save retry. Automatic film progress must not auto-commit completion.
5. Update developer Full dock ending and manual dock setup to exercise the revised flow. Existing completed saves stay completed; do not reset flags or force the revamped film onto them.
6. Replace tests coupled to dialogue page numbers 30-36 or individual line text with named exchange/shot IDs and meaningful behavior checks. Update docs and acceptance evidence for the final implemented scope.

No new quest, destination, reward, travel checkpoint, captain rank, consumable item transaction or rescue prerequisite belongs to this revision.

## Acceptance and review

Creative review:

- Read the complete script aloud: each exchange must sound like friends responding, with no explanatory monologue.
- Keep no more than nine spoken turns and approximately 40-60 words unless a concrete improvement earns extra text.
- The no-fishing setup and Captain Snacks payoff should be understandable while muted and without a companion.
- Adam's relief and thanks remain sincere; Mei Ling smiles and participates; Arjun contributes rather than becoming the sole target of jokes.
- Measure ordinary reading from Embark to final card against the 30-40-second target. Record actual observed timing separately from the target.

Behavior and technical review:

- Exactly three normal dialogue advances reach the film when cards are shown in full. No Show line double tap, automatic dialogue timeout or seven intermediate Continue stops.
- Reading may pause indefinitely. Film pause/focus loss does not advance the ship or consume completion, and focus return respects manual pause.
- Capture consecutive gangplank positions, the bag gag, all-three-aboard before release, cast-off/separation and the final horizon. Verify continuity and framing at 832x480 and 1280x720 in day/night and Reduce Motion.
- Exercise keyboard, mouse and touch, held Embark input, fast repeated presses, Skip on every card and each film shot, cancellation and world/journey replacement in every phase.
- Keep both rescue orders, actual incoming Arjun docking, nearby danger deferral, old-save eligibility/completion, failed save/retry and before-departure free play passing.
- Verify live mute/quality changes and owned sound cleanup. Props cannot spend food, pay Gold, create drops or affect pet health.
- Use isolated -Reunion and -Developer reviews, then the canonical gameplay gate. Record fresh results in ACCEPTANCE_TESTS.md after implementation; prior passing counts do not validate this proposed rewrite.

## Implemented behavior

- Nine spoken lines / 40 words, three fully visible cards, one advance per exchange. Third button: Set sail.
- One cumulative 17-second film: boarding 0-6s, cast-off 6-9s, farewell 9-13s, horizon 13-17s. No intermediate Continue stops or narrated departure captions.
- Finite original salute/proud/wave/steady poses; three leaf-wrapped lunches; Arjun's brief bag wobble and Mei's helping hand. Adam waves to Rahim and the villagers. The optional companion follows aboard continuously; the joke also works without one.
- The receding hull remains on the waterline, and the dock dissolves into open sea. Final inscription is drawn once.
- Pause/Resume and focus-loss suspension freeze the sampled scene and owned audio. Returning focus preserves manual pause. Final card requires fresh released input plus a 0.6-second guard.
- Existing Game/GameState completion, failed-save retry, title handoff, earlier-time free play, old saves and developer test-save ownership remain in place.
- The automated natural-reading fixture allocates 4.5 seconds per card plus 17 seconds of film (30.5 simulated seconds). This validates timing and lack of intermediate inputs; it is not a measured human reading time. Reader-controlled cards still wait indefinitely.

See `ACCEPTANCE_TESTS.md` for current isolated/native results, warning explanations and evidence paths. No export or physical phone test is implied.
