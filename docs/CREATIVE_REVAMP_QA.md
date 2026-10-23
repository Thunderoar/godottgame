# Creative revamp QA

Validated with Godot `4.7.2.stable.arch_linux.ed1daf0bf`, GL Compatibility.
All journey/settings mutations used verified isolated XDG data. Editor import/save
tests additionally used a disposable copy of the source project. Real player
saves were never deleted, restored or overwritten.

## Results

| Check | Actual result | Evidence |
|---|---|---|
| Incoming baseline | 408 checks, PASS | Baseline audit and before images |
| Final isolated gameplay gate | **438 checks, PASS**, no script errors/failures | `evidence/creative/logs/acceptance.log` |
| Native graphical regressions | **63 checks, 0 failures** | `logs/native-ui.log` |
| Fresh source import | PASS; plugin loaded without parse/missing-resource errors | `logs/clean-import.log` |
| Native authoring workspace | **27 checks, 0 failures** | `logs/editor.log` |
| Editor output in a new runtime process | **PASS**: saved registry, edited PNG, authored map and live water collision | `logs/restart.log`, `studio/authored-runtime.png` |
| Exported resource pack | **EXPORTED_RUNTIME PASS**: actual game/player and imported planter load with editor code excluded | `logs/export-runtime.log` |
| Before/after tour | 53 fresh final captures; selected comparable views retained | `before/`, `after/` |
| Motion | 1,170 rendered frames at 60 FPS, 1,166 physics samples | `motion/movement.mp4`, `samples.json`, `analysis.json` |
| Diff whitespace | `git diff --check`: clean | Delivery check |

Paths above are relative to `docs/evidence/creative/` unless otherwise shown.
The fresh-import runner copies source while excluding `.godot` and generated
builds, so cached imports cannot conceal absent source assets. The export smoke
used a temporary Windows-compatible resource-pack preset, then ran the PCK with
the installed Linux engine. It verifies packed resources/runtime separation;
it is not a Windows executable or Android device test.

## Coverage and visual inspection

The existing gameplay suite covers hero selection, inventory/equipment, atomic
purchases, potion use, house and pet progression, duels, portals/bosses, forest HP,
forest-loss game over, emergencies, sea cleaning, recovery, settlement placement,
save/load, touch controls, GUI scaling, camera zoom and accessibility. New checks
cover semantic palettes/cache invalidation; pixel tools/transparency/history;
frame/duration PNG round trips; sprite atlas cropping and missing-asset
diagnostics; map persistence/IDs; real authored collision/navigation; native
TileMapLayer batching; imported world art; an existing forest-tree override without
renumbering; micro-action priorities/cleanup/Reduce Motion; and motion-driven
player animation.

Native editor tests exercise brush handlers, PNG import/save/reimport, animation
frame operations, palette preview/application, native map undo/redo, saved map
reload, unsaved-discard protection and plugin disable/re-enable and recovery of unsaved pixel work across reload. A separate game
process proves those files survive editor shutdown. These are focused automated
workflows, not exhaustive human testing of every possible document/input.

Inspected actual images at 1280×720 and 832×480, including village/forest/beach,
coast east and turtle, BESUT, market/shop, inventory/HUD, dungeon, portals, combat,
shopping, motion, GUI extremes and zoom extremes. The native UI checks also resize
to 832×468 and test physical touch sizes and input dispatch. The beach retains its
mask; new foliage has cooler shadows, brighter roofs and distinct materials.
The final dungeon comparison also replaced inherited oversized grey floor bands
with small theme-tinted flagstones while preserving geometry. The final art review reduced pale canopy mapping and replaced brown twig-like
atlas grass with palette-aware clustered tufts. Art remains readable with optional
effects reduced. The full quality/Reduce Motion matrix was captured by the tour.

Reviewed consecutive rendered movement frames at native crop size, as well as
whole-scene context. Motion scenarios include normalized diagonals, rapid turns,
start/stop, camera follow, zoom changes while moving, a pet and resident travelling
around an explicit obstacle, enemy pursuit and an NPC shop approach. Explicit
scenario initializations reset interpolation; displacement analysis excludes those
boundaries. Largest within-scenario per-tick displacements were player 0.073334,
pet 0.150001, camera 0.172677, enemy 0.108572 and resident 0.085370 world units.
Most moving samples retain fractional art-pixel coordinates. These measurements
support the rendered review; they do not replace it.

The movie is a fixed-60-FPS simulation/render recording. Capturing 19.5 seconds took
54 wall-clock seconds on the software renderer; this is not a real-time 60 FPS
hardware claim. MP4 compression is for convenient review; original AVI remains at
`/tmp/tidesworn-creative-motion/motion.avi` while temporary artifacts are retained.

## Measured performance

Identical 1280×720 village framing, original seed, High effects, GL Compatibility,
Mesa llvmpipe under Xvfb. Sixty warm-up frames followed by 180 measured frames.
Runs were sequential. Values are one local comparison, not a statistical benchmark
or a prediction for Android.

| Metric | Source branch | Revised |
|---|---:|---:|
| First village construction | 350.89 ms | 1,133.41 ms |
| Mean rendered frame interval | 25.79 ms | 26.54 ms |
| 95th percentile interval | 29.64 ms | 30.50 ms |
| Mean physics process | 1.73 ms | 2.18 ms |
| Mean draw calls | 283.24 | 285.62 |
| Scene nodes | 1,307 | 1,331 |
| Texture memory | 45,514,771 bytes | 45,757,143 bytes |
| Procedural cache entries | 86 | 105 |

The extra initial work is material-aware terrain/foliage generation. Textures are
cached across world reconstruction when the palette is unchanged. Average frame
interval increased about 2.9%; no real-device 60 FPS promise is made. New terrain
layers are batched, collision runs merge, and imported clips preload frames.
A delivery repeat on the final source measured baseline/revised means of
33.86/32.74 ms, 95th percentiles of 57.05/42.45 ms, construction of
616.11/1,128.58 ms and draw calls of 285.73/286.83. The first pair above precedes
the final shared-image ownership repair; the repeat uses the final source. This
variation is larger than the small frame-time difference, so neither pair
establishes a hardware speedup or a sustained frame-rate guarantee. The extra
cold-construction cost is consistent. Raw values: `performance.json`; reproducible
harness: `tools/creative_benchmark.tscn`.

## Findings repaired during QA

A native editor session exposed the pre-existing orphan ConfirmDialog's missing
`_fit_panel()` method; a small fitting implementation fixes its parse error.
The first authored-sprite runtime test exposed process callbacks before clip
configuration; `_ready` and bounds guards now disable static-clip processing.
Tool screenshot capture now explicitly draws instead of waiting indefinitely for
an editor redraw signal. Floating-point SpinBox defaults are configured before
setting values so footprints and scale are not silently rounded.

The final pixel-level map review caught shared image data being resized while
building object previews. Preview and foliage transforms now duplicate image data
before editing it, and a rendered-canvas regression verifies the cottage remains
visible after repeated painting. The map grid also uses world-cell spacing at the
default zoom.

## Limits

Windows/Android executable installation, physical touch hardware, mobile GPU
performance and long-duration soak tests were not performed. Linux is currently
the integrated isolated-Play launcher host. The core map envelope remains the
existing village, with additive terrain and stable base-object overrides; existing
cottage/shop movement stays in settlement Build mode. Validation of authored
geometry is conservative and still requires an actual Play check against all
original collision. Pixel editing intentionally omits advanced layers/tags and
Aseprite JSON. Source-map version 1 adds no player-save migration.

Xvfb reports unsupported V-Sync and an unavailable X input method. A repeat full
verbose tour and the final dungeon review completed without ObjectDB warnings. Some full
screenshot-tour runs also report two ObjectDB instances retained at shutdown;
the gameplay gate, native regression run, editor/restart workflow and export smoke
are free of script/runtime errors. This shutdown warning is tracked rather than
reported as a completely warning-free graphical tour.

## Reproduce

```sh
./tools/test_isolated.sh
./tools/test_creative_editor.sh
```

For graphical tours/movies use the isolated commands in `docs/ACCEPTANCE_TESTS.md`.
Do not run destructive raw acceptance scenes against normal user data.
