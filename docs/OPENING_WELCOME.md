# Eighth opening beat: a place in BESUT

The intro now has eight pages. The first seven captions and their visual sequence
remain in order: fishing, awakening, wreck, landfall, captivity, turtle rescue,
Adam's promise. The new final page makes the village's welcome tangible before
Game loads the Lobby and starts its existing tutorial.

Caption: **"Welcome to BESUT, Adam. Come, rest and make yourself at home."
The villagers lead him in from the shore.**

The sixth page brought him to safety; the seventh established his promise.
This eighth page gives the player a moment of belonging before responsibility.
The welcome offers care freely, without requesting service in return or granting
an inventory item, house upgrade, currency or rescue progress.

## Six-second performance

| Time | Performance |
| --- | --- |
| 0.00–0.35 | Hold the exact completed shore tableau from the preceding promise. |
| 0.35–1.50 | The water keeper clears a path; the planter approaches with the folded cloth. |
| 1.50–2.20 | Hands reach toward the same cloth as it passes to Adam. |
| 2.20–2.90 | The planter steps aside; the water keeper invites Adam toward the homes. |
| 2.90–4.95 | Adam follows along the sandy path, carrying the cloth; the camera gently pans inland. |
| 4.95–6.00 | Hold Adam among the villagers, an open cottage, garden and a raised greeting. The turtle remains at the shore. |

The expanded 720×224 panorama contains the exact original 480×224 rescue
background at its left. Camera travel reveals the additional land and a villager
already standing near the cottage. It does not teleport Adam, generate gameplay
terrain or introduce a new realm. All displayed art remains uniformly fitted
above the actual caption panel at desktop, compact and wide window sizes.

`OpeningWelcomeArt` creates finite cutscene textures under
`opening/welcome/.../v1`; derived images copy their sources. Shared rescue art,
world art, RNG, saves and authored maps are untouched. `OpeningWelcomeRenderer`
uses the one story page clock and no delayed actions, independent timers or
tweens. It warms on entry to `INTRO_WELCOME_PAGE == 7`.

Reduce Motion holds the completed village tableau with no camera travel.
Low quality retains the cloth, people, path and welcome, removing optional sea
glints and reducing water marks. Both settings respond live without resetting
reading time. The seventh page now has Next; the eighth owns Continue. Next,
Skip and automatic advance use the existing one-shot completion path.

## Verification

`OpeningWelcomeChecks` is part of `StoryChecks` in the canonical isolated gate.
It covers consecutive actor/cloth positions, handoff-before-walk, spacing, camera
bounds, shore continuity, shared-image integrity, lazy ownership, accessibility,
caption-safe fitting, full reading time and early cleanup. `tools/tide_test.gd`
also checks the eighth caption at the actual new-journey entry point.

The isolated `res://tools/opening_welcome_test.tscn` adds phase captures, an
optional 73-frame `-- --sequence` review, mouse/touch Next/Continue/Skip and the
real Game intro → Lobby → tutorial handoff. Use the Windows isolation wrapper
and external evidence directories; never launch destructive tests with normal
player data. Current measured results are recorded in `ACCEPTANCE_TESTS.md`.

## First playable arrival: village dock

After the introduction, Game loads the village with `arrive_at_dock` enabled.
Adam starts at the resolved `jetty_deck` approach with his companion on the
planks and the camera already following him. The transition destination reads
"Besut Village · Dock". Completing the eighth page, automatic advance and Skip
all use this same first-arrival path. Continue with an unfinished introduction
also takes this path after replaying the introduction.

This is a one-time world setup option, not saved progression or a change to the
developer layout. The normal cottage/authored spawn remains the home anchor for
later village returns and completed-intro Continue. Recovery takes precedence
over a requested dock arrival. Defender home positions stay cottage-relative.
The movement lesson begins measuring from Adam's actual dock position, so placing
him there does not count as player movement; its existing arrows lead ashore.

The canonical gate checks new-journey Skip, deck clearance for both actors,
the route ashore, ordinary returns and recovery. The focused native fixture
additionally walks off the dock using held input and captures successive frames,
then exercises Continue for both unfinished and completed introductions.
