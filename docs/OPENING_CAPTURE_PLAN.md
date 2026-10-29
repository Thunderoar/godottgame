# Opening beat four: two friends taken captive

Design record, 2026-10-29. Implemented in `OPENING_CAPTURE_REDESIGN.md`; current
verification results are recorded in `ACCEPTANCE_TESTS.md`. The original plan below
records the intended staging and review process.

## Narrative job

Beat three makes the separation hurt. Beat four turns that separation into two
specific rescue goals. The viewer should leave knowing that Arjun and Mei Ling
are alive, that neither can leave freely, and that they have been taken to
different places. Their expressions should retain fear, resolve and recognition.

The existing caption remains:

> Arjun was dragged to the Kraken's island and locked in a prison. Monsters captured Mei Ling.

Target only `StorySequence`, `kind == "intro" and page == 3`. Retain the six-page
introduction, six-second page duration, existing caption and Next/Skip behavior.
Adam's turtle rescue belongs to page four, the fifth beat.

## Recommended composition

Use a fixed, two-panel montage on the same 480 x 224 logical stage as the Kraken
and wreck shots. Initial layout budget: two 232-pixel panels with a 16-pixel navy
gutter. Each panel has its own horizon and ground plane. The division establishes
an editorial jump in place and time; it does not depict two adjacent locations.

The complete composition fits uniformly above the actual caption bounds. Reuse
the caption-aware sizing pattern and nearest filtering of the previous shots.
Target approximately 29 x 43 logical pixels per friend, adjusting staging before
reducing their size. Empty background may extend beyond the fitted stage.

- Left: Kraken-island landing, wet stone, a cage with a readable lock, and a
  partial crowned Kraken silhouette with one clearly connected working arm.
  Keep the mast fragment near the landing as a visual link to Arjun's wreck.
- Right: a separate ruined landing with Mei Ling's recognizable bow fragment,
  two monster silhouettes, and a recessed stone passage. A restrained violet
  accent can hint at her eventual portal rescue. The passage is architectural;
  its depiction does not establish a new magical transport event.
- Maintain the visual identities and unarmed clothing of beats one to three.
  Arjun's rust/orange accent and Mei Ling's green clothing remain easy to follow.
- Direct attention through action, facing direction and restrained local contrast.
  Keep the inactive panel readable and still. Avoid darkening a friend until their
  identity is lost, and avoid simultaneous major actions.

This montage deliberately compresses the journey after the wreck. It does not
attempt to show a sea crossing, two captures and two new destinations in real time.

## Six-second performance

| Page time | Primary action | What the viewer understands |
| --- | --- | --- |
| 0.00-0.45 | Establish both landings; Arjun and the Kraken's arm are the active group. Mei Ling holds beside her grounded fragment in the right panel. | The friends have reached different dangerous places. |
| 0.45-1.55 | The connected arm draws Arjun the short distance from the landing across the open cage threshold. His braced body, reaching hand and forced step share the same motion anchors. | The Kraken is taking Arjun prisoner. |
| 1.55-2.25 | Once Arjun is fully inside, the door closes and the lock settles. The arm releases and retreats. Arjun turns toward the sea. | His escape is physically blocked; he is visibly alive. |
| 2.25-2.65 | Left settles into its final hold. A guard enters Mei Ling's escape route on the right; she turns toward it. | Attention transfers to the second friend. |
| 2.65-3.70 | A second monster closes the other side. Mei Ling takes a small retreating step, then braces as both exits are blocked. | She has been surrounded and captured. |
| 3.70-4.65 | The guards escort her a short distance toward the ruined passage. She looks back toward the sea with one hand reaching outward. | Her loss of freedom is clear, and her destination differs from Arjun's. |
| 4.65-6.00 | Hold the locked cage and the guarded Mei Ling together. Keep her visible at the passage entrance, with a guard blocking the return path. | Two living friends need rescuing. |

The exact motion distances are layout tuning, not additional story events. The
important boundaries are: Arjun crosses the threshold before closure; enclosure
precedes the focus transfer; Mei Ling is surrounded before she is escorted; the
last 1.35 seconds permit recognition and caption reading.

## Physical and emotional readability

Arjun must enter through the open door. The arm's contact follows his body during
the pull, releases after his arrival, and retracts clear of his face. Feet retain
a credible relation to the landing and cage floor. Separate cage back, occupant,
door and lock layers allow correct occlusion. Place bars around the face opening
and choose spacing that keeps his face and reaching hand legible at 832 x 480.

Mei Ling's guards should be threatening through their size, approach and blocked
routes. Start with the current drowned-monster visual vocabulary, adapted into
finite cutscene approach/guard poses. Keep the number at two and the scale around
1.2-1.4 times her height, subject to compact-screen review. Her head, hand and
silhouette remain distinct from both guards and the passage throughout capture.

Use a short backward look for each friend as the emotional link to the wreck.
Their final positions communicate captivity while preserving personality and
hope. Reserve Adam, the turtle, BESUT and the coming warmth for the next beat.

Use the established crown, purple/teal Kraken palette and prison roof/metal/lock
motifs. A small dedicated cutscene cage can follow `KrakenArt.prison_texture()`
without changing that shared gameplay texture. The final portal boss and later
rescue outcomes remain unrevealed.

## Art and runtime ownership

Proposed files:

- `scripts/core/opening_capture_art.gd`: `OpeningCaptureArt`; original finite pixel
  backdrops, layered cage, lock, short arm-frame set, hero poses and guard poses.
  Cache keys under `opening/capture/.../v1`; copy source images before deriving art.
- `scripts/ui/opening_capture_renderer.gd`: `OpeningCaptureRenderer`; pure
  `sample(elapsed, reduced, quality)`, `fit_rect()` and layered `draw()` methods.
  Return explicit phase, actor/contact anchors, door progress, lock state, guard
  positions and focus state so tests can check the visible causal relationships.
- `scripts/ui/story_sequence.gd`: add one renderer member, `uses_capture_shot()`
  and `capture_state()`; warm it in `prepare_page()` on entering intro page three,
  then delegate drawing before the generic branches. Keep the target predicate
  specific to intro so rescue and ending stories never inherit it.
- `tools/opening_capture_checks.gd`: meaningful narrative, geometry, lifecycle
  and presentation checks, integrated through `StoryChecks.run()`.
- `tools/opening_capture_test.gd` and `.tscn`: isolated focused native review,
  deterministic captures and actual Next/Skip pointer events.
- Update the previous wreck handoff assertion to identify the new capture shot;
  append the current behavior and actual results to `docs/ACCEPTANCE_TESTS.md`.

Sample the existing page clock rather than creating timers, tweens or delayed
callbacks. Warm finite textures on page entry, outside drawing. Use fixed
arithmetic for optional water details and keep gameplay RNG untouched. The renderer
owns presentation data; campaign progress remains with the existing completion
path in Game and GameState.

Keep the authored pixel sequence consistent in both selectable visual styles,
following the existing first-three-beat treatment. Do not modify global art-style
defaults or shared character, enemy, cage or ship resources for this shot.

## Accessibility and controls

- Reduce Motion shows a stable final tableau: Arjun behind the locked cage and
  Mei Ling visibly guarded at the passage. Both remain identifiable from frame one.
- Low quality keeps the full capture chronology, connected arm, cage/lock, both
  guards, visible faces and essential ground silhouettes. Reduce only decorative
  spray, ripples and background accents.
- Live settings changes update presentation without resetting page time. Switching
  Reduce Motion off follows the existing samplers' current-time behavior.
- Next can leave during any phase. Skip completes once. Held-action cleanup and
  world/input ownership continue through existing StorySequence/Game behavior.
- Keep dialogue, labels, camera shake, zoom and flashes out of this implementation;
  the existing caption and the two actions carry the scene.

## Implementation order and review gates

1. Capture the current target panel, preceding wreck ending and following rescue
   opening with fixed page/time/viewport/settings. Preserve a source diff baseline.
   Record the other 12 settled story panels for regression comparison.
2. Build static final staging first. Review faces, cage enclosure, guard blocking,
   fragment recognition and caption clearance at 1280 x 720 and 832 x 480.
3. Implement Arjun's pull, threshold crossing, door closure and arm release; check
   consecutive positions and occlusion, including immediately around phase changes.
4. Implement Mei Ling's reaction, encirclement, short escort and final hold. Review
   the transfer of attention and whether both fates read with the caption hidden
   in review captures. Hidden-caption review is a fixture option, not product UI.
5. Add settings behavior, early exits and focused checks. Integrate the single
   target page and inspect transitions from beat three and into beat five.
6. Refresh imports safely, run the isolated canonical gate, then native focused
   reviews at 1280 x 720, 832 x 480 and wide 1600 x 720. Inspect a deterministic
   frame sequence in addition to static captures. Compare the 12 non-target panels.
7. Record current evidence and limitations; run `git diff --check` and inspect the
   scoped source diff. Keep captures and generated artifacts outside the checkout.

For Windows, use the actual Godot console executable and follow the existing
PowerShell isolation wrapper. Focused runs need equivalent process-local APPDATA,
LOCALAPPDATA and TIDESWORN_TEST_ROOT isolation before launch. The current application
name in `project.godot` is `Protect Besut`; the historical AGENTS description of
`Save The World` must not be used to guess a live-save path. Preserve existing
device settings and player progress throughout review.

## Acceptance criteria

- Visual cause and consequence read in order for both friends, without captions.
- Each friend is visibly alive and captive in the final hold; face and silhouette
  remain distinguishable at compact resolution.
- Arjun never passes through closed bars; door closure follows threshold clearance.
  Cage/guard foreground elements preserve the intended readable occlusion.
- Mei Ling's return path is visibly blocked before escort begins; her body stays
  clear of guard overlap and the scene edge throughout the sampled path.
- Essential anchors and narrative milestones agree across quality levels. Reduce
  Motion is temporally stable; setting changes preserve the six-second clock.
- Entry, automatic advance, early Next and repeated Skip clean up once and leave
  no captured pointer or held combat action. Intro completion retains its existing
  save semantics; entering this page does not rescue either friend or change routes.
- Only intro page three selects this renderer. The loader, first three shots,
  fifth/sixth beats and rescue/reunion panels retain their current behavior.
- Current canonical gate exits zero with its exact PASS summary and no failure or
  error markers; native captures and input are reviewed and warnings are reported.

The original draft was based on source inspection. Its proposed 29 x 43 actor
budget became 32 x 48 dedicated sprites in the implementation to retain readable
faces and hands. The implemented portcullis closes from 1.55 to 2.05 seconds, then
the arm retracts until 2.25; the overall six-second staging is preserved.
