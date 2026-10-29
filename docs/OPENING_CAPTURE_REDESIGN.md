# Opening beat four: two friends taken captive

Implemented 2026-10-29. Target: `StorySequence`, intro page three (the fourth beat).
The design record is `OPENING_CAPTURE_PLAN.md`.

## Staging

Two separate shores share a fixed 480 x 224 pixel stage with a navy gutter. The
left panel places Arjun at the Kraken's island prison. The right shows Mei Ling
at a ruined landing, with a recessed passage and two drowned-style guards.
Different skies, architecture and separate horizons establish a montage across
place and time. Each friend's yellow ship fragment connects the scene to the wreck.

The original caption remains: "Arjun was dragged to the Kraken's island and locked
in a prison. Monsters captured Mei Ling."

| Time | Performance |
| --- | --- |
| 0.00-0.45 | Establish both shores; attention begins with the Kraken and Arjun. |
| 0.45-1.55 | The Kraken's connected arm draws a bracing Arjun onto the cage floor. |
| 1.55-2.05 | The portcullis descends after Arjun has cleared the threshold. The lock appears when it is shut. |
| 2.05-2.25 | The arm releases and retracts; Arjun reaches back through the bars. |
| 2.25-2.65 | The leading guard closes Mei Ling's route toward the passage. |
| 2.65-3.70 | Mei Ling retreats; the second guard closes her return route. |
| 3.70-4.65 | The guards escort her toward the passage, maintaining visible gaps around her. |
| 4.65-6.00 | Hold both living captives. Mei Ling remains visible at the entrance. |

Friends use dedicated standing, bracing and reaching poses, canonical colors and
32 x 48 source sprites. The front cage bars leave Arjun's face clear; the crossbar
and lock sit below it. The leading guard faces inward and retains its correct
draw bounds. All characters remain human-scale relative to the architecture.
Adam and the turtle enter in the following original beat.

## Ownership

- `scripts/core/opening_capture_art.gd`: finite pixel scenery, hero/guard poses,
  cage back, portcullis, frame, lock and 37 raster arm poses. Keys use
  `opening/capture/.../v1`. Derived faces and hull fragments copy their source images.
- `scripts/ui/opening_capture_renderer.gd`: pure page-clock sampler, uniform
  caption-safe fitting and layered drawing. The arm and Arjun share one quantized
  contact anchor. The cage door is clipped to its opening as it descends.
- `scripts/ui/story_sequence.gd`: one target-specific renderer, warmed on page
  entry through `prepare_page()` and used only for `kind == "intro", page == 3`.
- `tools/opening_capture_checks.gd`: integrated by `StoryChecks` into the canonical
  gate. Checks causal ordering, threshold clearance, guard spacing, continuous
  positions, face clearance, quality invariants, settings and early exits.
- `tools/opening_capture_test.tscn`: focused headless/native entry point. Native
  review captures the phases and drives screen-touch Next and mouse Skip through
  the actual story controls. `-- --sequence` adds 73 exact page-time frames.

No independent timers, tweens, gameplay actors or RNG participate in the shot.
Textures are warmed outside drawing. The six-second clock, original words,
completion/save semantics, title loader and the other story panels keep their
existing ownership. The authored pixel sequence follows the first three opening
beats, including when the player has selected the modern world style.

Reduce Motion samples the complete final tableau at all times. Low quality
reduces optional water marks while preserving every actor, arm, door and guard
anchor. Live changes preserve the current page clock. Next and Skip have no
delayed capture callback that can outlive the page.

## Safe verification

On Windows, refresh imports and run the canonical gate with the actual console
executable through `tools/test_isolated.ps1`. For native focused reviews, launch
`res://tools/opening_capture_test.tscn` at 1280 x 720, 832 x 480 and 1600 x 720.
Set process-local APPDATA, LOCALAPPDATA and TIDESWORN_TEST_ROOT to a fresh external
directory before starting Godot; the fixture rejects unverified user-data paths.
Use `-- --wide-review` for the wide fixture on Windows: it switches only the review
window to borderless, requests 1600 x 720 and asserts the actual viewport size.
This avoids the monitor-work-area clamp on decorated windows. Captures go under
that root's `shots/` directory. Ordinary player data is never
used. Inspect the frames as well as the exit code and exact PASS summary.

Current observed results and limitations are recorded in the dated acceptance
entry. Captured motion is a deterministic 12-sample-per-second engine sequence,
not a hardware performance measurement or physical-phone test.

## Observed verification, 2026-10-29

- Windows Godot 4.7.2 official, AMD Radeon Vega 3 Compatibility renderer.
- Canonical isolated gameplay: **2,370 checks, PASS**, exit 0.
- Native focused review: **553 PASS** at 1280 x 720; **626 PASS** at 832 x 480
  including 73 timed captures; **554 PASS** at verified 1600 x 720. Each exits 0.
- Final gameplay/native logs have no failure/error/warning markers. Import exits
  0 without error markers and reports `Unable to open Android 'build-tools' directory.`
- All **12 non-target story panels match the original rendered pixels exactly**
  under the same page/time/settings/viewport. The target panel differs as intended.
- Consecutive capture phases, the final hold, Reduce Motion, low quality, wide
  framing and the following turtle-rescue frame were visually inspected. The
  six-second GIF preview was encoded and decoded with its duration verified.

External evidence root:
`C:/Users/LUQMAN/.codex/visualizations/2026/10/29/01a185fb-3395-7151-879e-52835b76eed3/opening-capture/`.
It contains baseline/final panels, focused logs/captures, the sampled motion
preview, contact sheet, reproduction helpers and `verification.json`. The canonical
log root is recorded in that JSON. Earlier failed helper runs remain preserved:
an external `--script` helper needed deferred loading after singleton setup, a
new weak-reference test needed an explicit type, and the mirrored leading guard
needed its drawing origin corrected. The first wide window was clamped to 1370
pixels; the final borderless run verifies actual 1600-pixel output.

No export or physical Android test was performed. Source screenshots, bakes and
build outputs were not added; normal player saves/settings were not used.
