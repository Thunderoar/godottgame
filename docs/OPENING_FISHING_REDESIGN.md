# First opening beat: a peaceful fishing morning

Implemented 2026-10-28. This is a presentation-only overhaul of introduction
page zero. The six captions, six-second page timer, Next/Skip controls, save flags,
world transition and later story panels retain their existing contracts.

## What changed

- Stepped morning sky, sun, quiet clouds, seabirds and layered blue/green water.
- Original cutscene-only yellow UNISZA boat: deck, sail/rigging and foreground
  hull/rail are separate cached layers. The nameplate and blue pennant remain.
- Adam stands relaxed, Arjun holds/adjusts a fishing rod, and Mei Ling sits by the
  tackle equipment. Dedicated unarmed poses replace the old armed walk loop.
- Actor foot positions and the rod hand are boat-relative. One snapped boat offset
  moves them together; the front rail occludes boots rather than faces.
- A continuous rod/line/float/ripple relationship makes fishing visible without
  reading the caption. The float is water-relative rather than glued to the boat.
- Short, staggered pose changes, blinking, sail/flag cycles, clouds, glints, hull
  reflections and waterline foam provide restrained secondary motion. No Kraken
  appears during the peaceful first beat.
- Artwork fits uniformly above the actual caption bounds. Ship/actor aspect ratios
  are preserved at desktop, compact and wide resolutions; only empty sea/sky extend.
- Live Reduce Motion holds the shot steady without stopping the story timer. Low
  quality removes optional reflections/glints/birds, not essential storytelling.

## Ownership and integration

- `scripts/core/opening_fishing_art.gd`: deterministic original pixel textures,
  namespaced `opening/fishing/.../v1` cache/override keys, separate boat layers and
  three dedicated poses per friend. No shared ship/character image is edited.
- `scripts/ui/opening_fishing_renderer.gd`: finite texture warmup, pure `sample()`
  function, uniform `fit_rect()`, layered drawing and connected fishing geometry.
  No gameplay nodes, timers, asynchronous animation chains or world RNG.
- `scripts/ui/story_sequence.gd`: first-beat delegation only, caption bounds and
  live presentation redraw. `uses_fishing_shot()` is true only when
  `kind == "intro" and page == 0`. All other drawing branches remain intact.
- `tools/opening_fishing_checks.gd`: deterministic motion/anchor checks, pose
  timeline, quality/accessibility, layout, timer/path isolation and early cleanup.
  `StoryChecks.run()` invokes this suite in the canonical isolated gameplay gate.
- `tools/opening_fishing_test.tscn`: focused headless/native entry point. Native
  runs capture four timed frames, Reduce Motion, low quality and the next-beat cut;
  real screen touches exercise Next and Skip and verify no held combat input.

Assets are warmed before the timed first drawing. Draw calls only sample state and
reuse cached textures. Decorative patterns use fixed arithmetic, not global or
village RNG. All actors retain canonical character identities/palettes. This work
does not alter gameplay progression, terrain, saves, global ship art or input maps.

## Reproduce safely

From the confirmed repository root, refresh newly registered global classes with
isolated data, then run the canonical wrapper:

```sh
bootstrap=$(mktemp -d /tmp/tidesworn-fishing-import-XXXXXXXX)
XDG_DATA_HOME="$bootstrap/userdata" TIDESWORN_TEST_ROOT="$bootstrap" \
  timeout 120 godot --headless --path . --import >"$bootstrap/import.log" 2>&1
cat "$bootstrap/import.log"
if rg -n 'SCRIPT ERROR|ERROR:' "$bootstrap/import.log"; then exit 1; fi
./tools/test_isolated.sh
git diff --check
```

Focused native review (repeat with 1280x720, 832x480 and 1600x720):

```sh
review=$(mktemp -d /tmp/tidesworn-fishing-review-XXXXXXXX)
XDG_DATA_HOME="$review/userdata" TIDESWORN_TEST_ROOT="$review" \
  timeout 120 xvfb-run -a -s '-screen 0 1920x1080x24' \
  env LIBGL_ALWAYS_SOFTWARE=1 godot --audio-driver Dummy --path . \
  --resolution 832x480 res://tools/opening_fishing_test.tscn \
  >"$review/review.log" 2>&1
cat "$review/review.log"
if rg -n '\[FAIL\]|SCRIPT ERROR|ERROR:' "$review/review.log"; then exit 1; fi
rg -q '^--- opening fishing: [0-9]+ checks, PASS ---$' "$review/review.log"
```

Inspect the captures under the printed external test root; exit zero alone does not
prove visual quality. Timed captures use exact `_page_time` values, not variable
wall-clock screenshots. Beat two was subsequently rebuilt in the same classic
pixel direction; see [OPENING_KRAKEN_REDESIGN.md](OPENING_KRAKEN_REDESIGN.md).

## Evidence and limits

Final dated results are recorded in `docs/ACCEPTANCE_TESTS.md`. Native evidence is
Linux Godot 4.7.2 with Xvfb/llvmpipe, not physical Android or native Windows testing.
X11 input-method and unsupported V-Sync warnings are reported, not hidden.

External evidence root:
`/home/roku/.codex/visualizations/2026/10/27/01a17f58-ca50-7720-9546-6da08b52c32a/first-beat-redesign/transaction`.

The transaction preserves the original story source, changed-copy role,
reconstructing patch, literal command/output/status ledger and a self-contained
executable rollback accepting a copy of `story_sequence.gd`. Baseline, modified and
restored runs use identical page/time/window inputs. Restored source and rendered
pixels match baseline; the 12 non-first story panels match across all three runs.
The implementation remains applied after rollback verification. User changes to
AGENTS.md, project.godot and scenes/game.tscn are preserved byte-for-byte.

## Follow-up: eased title entrance

The confirmed Adam handoff now requests `play_story("intro", true)`. StorySequence
sets `arrive_from_title` only when that title layer still exists; its deterministic
arrival prelude overlays the original selection screen rather than deleting it on
the click. `departure_covered` retires only the matching layer through Game's
`_remove_title_if_owner()` guard. Duplicate start/continue calls during a story
are rejected before they can reset progression or create a second intro.

Normal pacing is a 0.28-second smooth fade to navy, 0.06-second hold and 0.64-second
scene reveal. Caption opacity rises during the last 0.22 seconds. The art holds its
first pose and `_page_time`/`clock` remain zero throughout; the usual six seconds
begin only once the words and controls are fully visible. Hidden buttons are
disabled and the curtain consumes pointer input during the sub-second entrance.
The HUD stays hidden and no village is constructed behind the opening.

Reduce Motion uses 0.12 seconds out and 0.16 seconds in, with no hold, camera move
or scale effect. Enabling it mid-entrance shortens the remaining transition while
still covering title removal; disabling it again never rewinds the current reveal.
The prelude has no tweens, timers or asynchronous callbacks to outlive Skip/exit.
Normal in-world story calls and Continue with `intro_seen` already true are not
delayed. Continue with an unfinished intro uses the same safe entrance.

Validation: isolated gameplay 1,300 PASS; focused headless 81 PASS; native 112 PASS
at each of 1280x720, 832x480 and 1600x720. Native captures show the title fade,
covered frame, art reveal and caption settle, plus the shorter accessibility path.
All 13 settled panel images are unchanged, and rollback matches all eight old
hard-cut handoff samples exactly. See the appended acceptance entry and literal
external verification ledger for commands, outputs, hashes and warnings.

The same four artifact paths remain authoritative. `ROLLBACK.sh PROJECT_COPY_DIR`
now restores the coherent pre-handoff Game/Story/test/doc set and keeps the fishing
redesign. `ROLLBACK.sh TARGET_COPY.gd` restores only the bound story source; use the
project-directory form for a runnable rollback. The original first-beat roles and
their older rollback are preserved under `history/first-beat/`. The cumulative
`DIFF_FILE.patch` reconstructs the whole current implementation; the supplemental
`transition/delta.patch` isolates just this follow-up from the confirmed first-beat
state. The native motion preview is a deterministic frame-sampled in-engine render,
not a hardware performance recording.

## Follow-up: existing PB loader in that entrance

The title-intro path now sets `include_loading_screen`. StorySequence owns a local
`LoadingScreen` at the same overlay layer as the existing global one, uses
`present("Adam's Journey", 0.0)`, and drives its opacity from `sample_arrival()`.
The unchanged PB logo, planter/house/Ember icons, destination label and loading
dots are therefore reused directly. No asynchronous loading tween or callback is
needed on this local instance; normal world transitions still use their separate
global `begin()`/`finish()` instance.

The title fade is followed by a 0.12-second loader fade-in, 0.55 seconds fully
readable, and a 0.18-second loader fade-out overlapping the fishing-art reveal.
Normal entrance completes at 1.59 seconds; Reduce Motion completes at 0.97 seconds
while preserving the readable hold. Caption and first-beat clocks remain held
until the loader clears and the caption settles. At that point `dismiss()` and
`queue_free()` remove the owned loader. Early completion follows the same cleanup,
so it cannot cover a later village loading screen or intercept later input.

Final evidence: 1,326 canonical gameplay PASS; 100 focused headless PASS; 138 native
PASS at each of three resolutions. Matched rollback removes only this loader
addition and restores the preceding eased handoff, keeping the fishing redesign.
The original four artifact paths are reused; current project rollback restores all
eight pre-loader source/test/doc files. The prior role versions remain under
`history/eased-handoff/`. The supplemental `loading/delta.patch` isolates this step.
The final 1,326-check rerun includes the newer title-page slide integration. Its
shared native-fixture wait and unrelated title documentation are preserved by
the rollback baseline rather than overwritten with an older whole-file snapshot.
