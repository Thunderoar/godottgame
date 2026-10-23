# Monsoon Afterglow delivery and visual QA

2026-10-24 · Godot 4.7.2.stable.arch_linux.ed1daf0bf · GL Compatibility.
Branch: `feat/monsoon-afterglow-art-overhaul`, based on remote `main`
`a858b4c55c7f702def02035cc89aca88d37f1cf8`, verified with `git ls-remote`
and fetched before implementation. No historical repair branch was used as the
baseline. Main and unrelated work are preserved.

## Implemented result

The playable village now uses a fresh clustered meadow, five original tropical
tree families, six undergrowth silhouettes, seaglass water shelves, shell/tide
detail, raised timber homes across all five tiers, woven market stalls and
occupation-specific dressing. Nets, baskets, stacked timber, buckets and porch
planters support existing residents' routines. Doors, shops, gardens, turtle,
BESUT, paths and forest persistence retain their gameplay relationships.

Late-day warmth and jade/indigo night derive from the existing GameState clock.
Warm window pixels persist on Low; existing bounded local lights operate at
dusk/night on Medium/High. Tree-owned contact/dappled shadows are baked and follow
the tree lifecycle. Water animation changes colour inside the original mask;
Low/Reduce Motion retain complete painted water. Boat motion responds to live
settings changes. Heroes retain animation/timing contracts, with small outline
and costume refinements; outdoor hats, work aprons and pollution fragments add
readable identity. Portal runes, damp minerals and teal/apricot UI frames connect
the secondary environments.

36 original transparent production PNGs and a dimension/pivot manifest are in
`assets/authored/monsoon/`. Code is the reproducible master; explicit imported
overrides retain priority. No source atlas was overwritten, illustration used as
a static playable character, save schema changed or combat tuning altered.

## Source ownership

| Owner | Changes |
|---|---|
| `scripts/creative/monsoon_art.gd` | Original trees, split crowns/trunks, shadows, plants, cottage tiers and props |
| `world_palette.gd`, `data/palettes/monsoon_afterglow.tres` | Semantic world/UI materials, old-role fallback, preview and cache invalidation |
| `world_terrain.gd`, `map_renderer.gd` | Broad meadow regions, connected path grain, depth shelves, shells, authored material stamps |
| `scripts/core/pixel_art.gd` | Override-aware integration, stalls, NPC details, actor outlines, portal runes and urchin fragments |
| `scripts/core/shaders.gd` | Pixel-stepped masked crests receiving night ambience |
| `monsoon_lighting.gd`, `scripts/world/lobby.gd` | Existing-clock light, windows, family selection, workspaces and responsive boat tween |
| `dungeon.gd`, `ui_theme.gd` | Grouped minerals and teal/apricot frames |
| `data/maps/village.tres`, `palette_panel.gd` | Shipped palette/planters and comparison presets |
| `assets/authored/monsoon/` | 36 editable PNGs and metadata |
| `tools/monsoon_checks.gd`, `monsoon_test.*`, `fixtures/monsoon_forest.json`, `tide_test.gd` | Persistence, silhouette, palette, cache, import, clock and comfort regressions |
| `monsoon_review.*`, `review_monsoon.sh`, `export_monsoon_assets.*` | Protected real-renderer evidence, metrics and explicit source export |
| `docs/.gdignore` | Keep documentation screenshots out of Godot imports |

## Observations and iteration

Fresh captures preceded artwork changes; the final matching harness was also
run against a clean archive of the exact reference main. Historical Creative
Studio captures were inspected for context only. Baseline weaknesses observed:
strong yellow-green grass, similar narrow crowns, pin-like grass scatter, bright
roof stripes, flat counters and an abrupt static shallow/deep water boundary.

The first new canopy pass looked bead-like. Rendered inspection led to broken
crown edges and connected pointed sprays. Enlarged flower replacements crowded
the village, so they became single-stem hibiscus. Final walking space is quieter;
broad, spreading, upright, flowering and coconut silhouettes separate the forest.
Timber homes have readable decks, supports, eaves, shutters and stairs. The dungeon
combat fixture was moved off the return gate so the strike and hero are visible.

Regression probes caught clipped leaf tips in two families; cluster margins were
bounded. Editor testing exposed six-decimal resource-colour truncation during
RGBA8 painting; full-precision swatches fixed the round trip. Imported house art
now owns its entire window treatment. Profiling found discarded legacy-atlas
loads in the plant replacement branch; loading only the chosen art removed a
temporary cached-reconstruction regression.

## Actual screenshot evidence

`evidence/monsoon/before/` and `after/` contain matching 1280×720 PNGs and JSON
manifests recording world time, camera, zoom, quality and Reduce Motion. Narrow UI
captures are 832×480. Environmental actors are held for comparable framing; the
caretaker performs real watering and both combat fixtures assert actual damage.

| Scene | Before | After |
|---|---|---|
| Village/cottage | [before](evidence/monsoon/before/village.png) | [after](evidence/monsoon/after/village.png) |
| Market | [before](evidence/monsoon/before/market.png) | [after](evidence/monsoon/after/market.png) |
| Forest | [before](evidence/monsoon/before/forest.png) | [after](evidence/monsoon/after/forest.png) |
| Beach | [before](evidence/monsoon/before/beach.png) | [after](evidence/monsoon/after/beach.png) |
| Turtle | [before](evidence/monsoon/before/turtle.png) | [after](evidence/monsoon/after/turtle.png) |
| East coast | [before](evidence/monsoon/before/east-coast.png) | [after](evidence/monsoon/after/east-coast.png) |
| BESUT | [before](evidence/monsoon/before/besut.png) | [after](evidence/monsoon/after/besut.png) |
| Both portals | [before](evidence/monsoon/before/portals.png) | [after](evidence/monsoon/after/portals.png) |
| Golden hour | [before](evidence/monsoon/before/golden-hour.png) | [after](evidence/monsoon/after/golden-hour.png) |
| Night village | [before](evidence/monsoon/before/night-village.png) | [after](evidence/monsoon/after/night-village.png) |
| Night forest | [before](evidence/monsoon/before/night-forest.png) | [after](evidence/monsoon/after/night-forest.png) |
| Water keeper | [before](evidence/monsoon/before/water-keeper.png) | [after](evidence/monsoon/after/water-keeper.png) |
| Coastal combat | [before](evidence/monsoon/before/coastal-combat.png) | [after](evidence/monsoon/after/coastal-combat.png) |
| Dungeon combat | [before](evidence/monsoon/before/dungeon-combat.png) | [after](evidence/monsoon/after/dungeon-combat.png) |
| Narrow shop | [before](evidence/monsoon/before/small-shop.png) | [after](evidence/monsoon/after/small-shop.png) |

Both directories also include `water-low`, `water-med`, `water-high`,
`reduce-motion`, `zoom-28`, `zoom-64`, `small-screen`, `inventory`, `shop`,
`new-journey` and `dungeon`. Native editor palette/map captures and clickable
cottage tier previews are alongside them. PNGs are actual gameplay/editor renders.

## Verification and performance

The protected incoming gate passed 524 checks. The final gameplay gate passes **562 checks, PASS**, exit 0, including
38 additional Monsoon regressions; logs contain no failure/script/error markers. Native rendering passed the 63-check deep
audit, the actual mouse/touch interaction review, and the 27-check editor workflow
plus a separate runtime restart. Full logs are in `evidence/monsoon/logs/`.
The real-renderer tour produced 26 before and 26 after captures; both combat
fixtures verified damage and the caretaker reported `watering=true`.

Matching benchmark: same host, Mesa llvmpipe / GL Compatibility, 1280×720,
Qayyim at the cottage, existing world clock held at 360 seconds, existing night
survivors/residents held for equivalent framing. Each quality tier has 40 warm-up
frames and 180 measured intervals. Runs were sequential. These are fixture frame
intervals, not Android FPS or a combat-stress result.

| Metric | Main baseline | Monsoon |
|---|---:|---:|
| First village construction in process | 977.62 ms | 476.64 ms |
| Cached reconstruction | 19.64 ms | 20.49 ms |
| High median / mean | 32.45 / 34.91 ms | 29.08 / 30.16 ms |
| High p95 / worst interval | 56.88 / 90.69 ms | 36.27 / 72.10 ms |
| Medium median / mean | 32.52 / 37.93 ms | 28.18 / 28.59 ms |
| Medium p95 / worst interval | 64.79 / 122.83 ms | 32.32 / 37.42 ms |
| Low median / mean | 19.91 / 20.44 ms | 21.93 / 22.41 ms |
| Low p95 / worst interval | 24.18 / 33.26 ms | 27.71 / 28.98 ms |
| High mean draw calls | 323.79 | 336.70 |
| Texture memory | 55,387,795 B | 55,113,375 B |
| Generated cache entries | 128 | 150 |

High median improved about 10%; Medium about 13%. Low median increased about
10%, within the brief's approximate 10–15% target; its p95 increased about 15%
while the worst interval improved. Cached construction adds less than 1 ms in
this pair. Discrete terrain blocks reduce cold CPU generation. Extra props/windows
add draw overhead; daylight local-light suppression keeps effects restrained.
Quality totals include water/wind/light changes together; individual water-versus-
light GPU cost was not isolated.

A preceding post-optimization pair measured High medians 36.19 → 31.96 ms and
cached reconstruction 26.25 → 23.10 ms. This variability prevents a reliable
hardware speedup claim. Raw final metrics are `before/performance.json` and
`after/performance.json`; repeat with `tools/review_monsoon.sh` on the relevant
source. Rendering has no per-frame image generation. Existing unchanged-palette
terrain reuse is asserted; switching palettes invalidates generated textures.
All mutating tests used verified isolated XDG data. Editor import/save tests also
used a disposable source copy. No live save was deleted or restored; a read-only
backup was retained under `/tmp` and never copied back over player progress.

### Movement evidence

The existing motion harness recorded **1,166 physics samples** and a **1,170-frame,
19.5-second movie** across eight directions, moving zoom, obstacle routing and
shopping. Video is `evidence/monsoon/motion/movement.mp4`; original AVI stays in
`/tmp/tidesworn-monsoon-motion/`. Recording took about 51 seconds on llvmpipe;
fixed 60 FPS output is not a real-time 60 FPS hardware claim. Consecutive native
frames and `analysis.json` accompany it. Moving samples retain fractional art-pixel
coordinates for player, pet, camera, enemy and resident.

The audit does not hide existing physics corrections. The largest player step
(0.42145 units) occurs at initial overlap recovery; the resident probe has a
0.69888-unit correction at sample 817 and the camera a 0.34569-unit catch-up at
566. A separate protected fixed-FPS run on the exact main baseline reproduces
these same three values and indices. They are inherited probe/physics behaviour,
not jumps introduced by the artwork. Pet and enemy maxima remain about 0.15 and
0.10833 units. Baseline numeric samples are retained; its headless probe reports
an inherited two-instance ObjectDB shutdown warning. The delivered native movie,
acceptance, editor/restart and graphical tours have no script/error markers.

## Critical visual review and limits

Monsoon Cinema is expressed through distinct layered crowns, tree-owned shadows,
structural timber and occupied workspaces. Seaglass Reverie is strongest in the
jade/mint foliage, turquoise water shelves, quiet meadow and coral/cream flowers.
Lanterns of the Tide appears in warm night windows against cool scenery and
clock-linked evening warmth.

This is a substantial playable transformation, with visible limits: repeated
family crowns, a fixed path network, related front-facing houses and a regular
dungeon flagstone layout remain. It does not claim unique hand painting for every
tree or reconstruction of a historic building. Broad quiet walking regions are
intentional for navigation and combat readability.

No Android hardware, native Windows GPU/input, extended soak or hardware-GPU
performance claim is made. Local measurements use Linux software rendering.
Editor base-tree proxies are representative; Play is authoritative for families,
lighting and collision. Palette comparison shows old colours on new geometry;
the reference commit and paired captures preserve exact historical appearance.
