# Opening beat two: the hook and the sea king

Implemented 2026-10-29. The literal target is `StorySequence`: `kind == "intro"`
and `page == 1`. The original caption, six-second page duration, Next, Skip,
campaign completion and loading-screen handoff are preserved.

## Direction and ordered performance

The first beat establishes a friendship; the second must show **cause before
consequence**. A giant monster beside a floating fishing line did not explain
what Arjun caught. The new shot stages that relationship without an extra caption.

| Time | Action | Readable consequence |
| --- | --- | --- |
| 0.0–0.5 s | Yellow UNISZA ship and the same three unarmed friends; hook at the surface | Continues the fishing trip, not a combat encounter |
| 0.5–1.4 s | Rod bends, line loses slack, Arjun braces, friends react | Something much heavier than a fish is caught |
| 1.4–1.6 s | Hold the taut connection; a submerged shape darkens the water | A moment to read the cause before the reveal |
| 1.6–3.4 s | Hooked arm rises with its attached line; crowned mantle breaks the surface | The catch belongs to an enormous sea king |
| 3.4–4.2 s | Amber eyes open beneath a heavy brow | The Kraken wakes, rather than appearing angry from frame one |
| 4.2–6.0 s | Beak/mouth opens; hold the looming king and taut line | Fury is readable before the next beat destroys the ship |

The ship stays whole for this entire beat. Its mast, sails, rail and nameplate are
reused from beat one. Friends retain their identities, boat-relative feet and
dedicated unarmed poses. The rod tip, fishing line, hook and arm endpoint share
one sampled anchor: there is no unrelated diagonal line floating over the scene.

## Classic pixel language

- Original low-resolution sprites, limited colour clusters, stepped sky/sea bands,
  dark silhouettes and nearest filtering; no generated illustration, soft bloom,
  image-generation dependency or fullscreen flashes.
- A purpose-built crowned Kraken with three finite facial poses and purple/teal
  mantle shading, amber eyes, pixel teeth and tapered sucker-lined arms.
- Arms are rasterised once into finite cached pixel frames. Their silhouettes
  use the same pixel grid as the body, not smooth vector elbows over pixel sprites.
- A uniform 480×224 stage fits above the actual caption bounds. Only empty sky
  and water extend at other aspect ratios; people and the monster never stretch.
- No camera shake or zoom. Subtle boat recoil, finite pose changes and fixed-
  arithmetic droplets carry the motion without gameplay RNG or particle nodes.

The existing `GameSettings.DEFAULTS.visual_style` now defaults to `"pixel"`,
including missing/invalid saved preferences. Explicit `"modern"` preferences still
load normally and the existing Settings selector retains both options. Selection
remains restart-bound, so no running world mixes art families. The local device
already had `visual_style="pixel"`; its settings and live journey files were not
rewritten. This default change also makes untouched later story branches request
their classic procedural sprite family on a fresh/default launch.

## Ownership and accessibility

`OpeningKrakenArt` owns finite textures under `opening/kraken/.../v1` and duplicates
source image data before deriving reaction poses. Shared boat/hero art is not
modified. `OpeningKrakenRenderer.sample()` is pure, with clamped elapsed time,
snapped anchors and no timers, nodes, async chains, save writes or random calls.
Textures are warmed outside drawing; every drawing call reuses existing resources.

Reduce Motion presents a stable complete key pose: caught arm, taut line, awakened
king, grounded friends. It removes bob/recoil/looping drops without stopping the
six-second reading clock. Low quality removes optional droplets and some foam,
not the hook, arm, facial pose or narrative sequence. Both settings update live.
Next can exit at any phase; Skip completes once and releases the renderer. Only
intro page one delegates here; rescue/reunion stories and the later intro drawing
branches retain their code paths. Beat one and its PB loader remain unchanged.

## Reproduce safely

Refresh global classes with an isolated `godot --headless --path . --import`, then
run `./tools/test_isolated.sh`. `OpeningKrakenChecks` is called by `StoryChecks`
inside that canonical gate. Never run its destructive acceptance scene against
ordinary user data.

Focused native review, replacing `1280x720` with `832x480` or `1600x720` as needed:

```sh
review=$(mktemp -d /tmp/tidesworn-kraken-opening-XXXXXXXX)
XDG_DATA_HOME="$review/userdata" TIDESWORN_TEST_ROOT="$review" \
  timeout 120 xvfb-run -a -s '-screen 0 1920x1080x24' \
  env LIBGL_ALWAYS_SOFTWARE=1 godot --audio-driver Dummy --path . \
  --resolution 1280x720 res://tools/opening_kraken_test.tscn \
  >"$review/stdout.txt" 2>"$review/stderr.txt"
cat "$review/stdout.txt" "$review/stderr.txt"
if rg -n '\[FAIL\]|SCRIPT ERROR|ERROR:' "$review/stdout.txt" "$review/stderr.txt"; then exit 1; fi
rg '^--- opening kraken: [0-9]+ checks, PASS ---$' "$review/stdout.txt"
```

Inspect captures, not just exit status. The native fixture captures seven timed
phases plus accessibility/low-quality variants and drives real Next/Skip touches.
The style checks cover the pixel default, invalid/missing preference fallback and
explicit modern opt-in. Dated final results and limitations are recorded in
`docs/ACCEPTANCE_TESTS.md` after execution.

## Transaction continuity

The original four external transaction role paths are reused. Their previous
versions are retained under `history/pre-second-beat/`. The second-beat patch
reconstructs this change from commit `668b481`; the self-contained rollback accepts
a disposable project directory (all changed files) or a story-source copy (that
file only). It does not reset a Git branch or touch normal user data. Matched
baseline/modified/rollback runs use intro page one at identical times/resolution.
The implementation is reapplied after verifying restored bytes and pixels.

## Observed result — 2026-10-29

- Full isolated gameplay: **1,743 PASS**, exit 0, no failure/error/warning markers.
- Native second-beat review: **87 PASS** at each of 1280x720, 832x480 and 1600x720;
  actual touch Next/Skip and the caption-safe composition were inspected.
- Both styles' isolated restart routes: **25 PASS each**, retaining two existing
  ObjectDB cleanup warnings. Native Xvfb input-method/V-Sync warnings also remain.
- Baseline/modified/rollback default-style probes: modern legacy / classic-pixel
  awakening / modern legacy; all exit 0, complete once and preserve page timing.
- All baseline source states and four sampled baseline PNGs restore exactly.
  Under a fixed Classic Pixel style, all **12 non-target panels are identical**.
- Preview: 72 native frames, 1280x720, six seconds, encoded at 12 sampled fps;
  encode/decode verified. This is Linux software rendering, not phone/Windows
  certification or a hardware frame-rate claim.

The first Skip-input fixture needed a layout frame; a supplemental reapplication
needed global-class reimport. Their failed logs are retained separately from final
passing runs. The implementation remains applied; no commit/push was requested.

## Follow-up: the strike and shipwreck

Beat three is now implemented in `OPENING_WRECK_REDESIGN.md`. Its opening holds this
beat's final keyframe before the arm winds up. Optional drawing switches default
to the original awakening layers; the new wreck shot alone hides/replaces those
layers during the strike. The six-second beat-two handoff and its pixel art remain
owned here; actual ship fracture and friend separation belong to the next shot.
