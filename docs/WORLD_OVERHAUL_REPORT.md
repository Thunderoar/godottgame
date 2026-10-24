# Coherent village world — implementation and evidence

24 October 2026. Source: remote main verified at
`f37c843ef7388fc7ba0f89df9cc1aaf23a68beaf` before any implementation.
Feature branch: `codex/coherent-village-world`. The original checkout was clean;
the repair branch was not replaced. This report accompanies committed source,
authored geography, real screenshots and reproducible test/benchmark tools.

## Result and design reasoning

The village now has one coordinated spatial model with **47 anchors, 36 route
edges, 10 polygonal districts and 21 contextual workspace records**. The macro
composition retains familiar functional anchors while changing their relationship
to the ground, access network and neighbouring districts. The home forecourt,
market crescent, northern portal court, eastern workshop/woodland approach,
garden promenade and coastal loop read as connected destinations.

The baseline drew six unrelated terrain paths. Its northern route missed the
portals and met a closed fence section; several homes/shops lacked a path and
the beach route missed the jetty landing. Building positions, protected points
and editor proxies were separate coordinate lists. The implementation replaces
that fragmentation with a shared route graph and building approach metadata.
The detailed pre-implementation ownership audit and blueprint are
[WORLD_DESIGN.md](WORLD_DESIGN.md); the schema/workflow is
[WORLD_LAYOUT.md](WORLD_LAYOUT.md).

The northern fence has an actual gate on the portal approach. Shop roads terminate
at customer points below their counters. Cottage lanes reach their fronts;
the gardens and water service join a southern loop. Woodland tracks weave around
the unchanged trunks. The timber jetty is walkable on its visible planks, with
sea collision immediately beyond its deck. Nets, baskets and mooring details
frame the fishing landing; the turtle remains on the shared sand shelf.

Ground regions blend across irregular district polygons. Broad meadow, warmer
village/garden ground, shaded forest floor, maintained earth lanes and cooler
portal paving provide hierarchy without changing the Monsoon palette. Road
materials are unioned before compositing, so junctions have no overlapping dark
edges. A rendered first pass was too paved and busy: roads were narrowed/softened,
flower borders became selective, and entrances/clearings gained negative space.
Tree-centred understory and contextual workspaces replace arbitrary decoration.
The original tree silhouettes, house tiers and warm night windows remain intact.

## Implementation and compatibility

- AuthoredMap v2 carries or references WorldLayout; old maps inherit defaults.
  Map Studio and gameplay resolve the same geometry, rather than owning
  separate path/landmark lists. Semantic districts constrain detail categories,
  vegetation density and ground materials.
- Reservations protect complete declared entrance rectangles, owner footprints
  and route ribbons. Physics tests verify exact approaches and continuous
  centreline clearance using real overlap/cast queries. New spawn clearance
  searches avoid trees, buildings, authored water and collision without RNG.
- House/stall art, collision, merchants, targets and local workspaces move with
  their owner. Player positions win over developer overrides and defaults.
  Moving home updates recovery/shelter references. Customized roads can repair
  their resolved centreline once against synchronized physics.
- The **64 original forest trees** retain every fixture ID, position, creation
  order and maximum HP. Historical exclusion positions and the 160-draw prefix
  are frozen only for forest compatibility. Flowers, grass and understory use
  independent RNG, so decoration cannot renumber persistent trees.
- The shore sampler drives terrain, water mask, turtle grounding and spawn
  checks; sea collision follows it and subtracts only the visible deck. Land
  paint cannot disguise existing water collision. Authored sea materials also
  create collision when painted outside the Water layer.
- No autoload, save field, scene-switching mechanism, combat rewrite or player
  movement model was introduced. Existing progression, forest destruction/
  replanting, day/night clock, resident roles, missions, defensive NPCs and
  settlement editing remain covered by the combined gate. The legacy converted
  Unity scene is untouched. Existing AssetRegistry overrides retain precedence.

The implementation uses Godot's native
[polygon operations](https://docs.godotengine.org/en/stable/classes/class_geometry2d.html)
and [physics shape queries](https://docs.godotengine.org/en/stable/classes/class_physicsdirectspacestate2d.html)
for authored regions and actual clearance, rather than inferring walkability
from decorative textures.

## Authoring and startup

Map Studio adds category-specific district, road and plot/approach overlays,
canonical anchor dragging, route-bend/zone-vertex editing, road width controls,
native undo/redo and saved spatial resources. Only the selected feature is
labeled to avoid overlay clutter. Its existing import, pixel/animation, palette,
source recovery and isolated Play workflows remain available.

The 2D authoring canvas shares terrain geometry and shows service-specific art,
residences, tree families, workspaces, jetty and boat. Some base-object scale,
fence segment art, live characters and lighting remain representative there;
**Play this map** is the exact runtime preview. Graph insertion/removal and
footprint/kind changes use the focused Resource inspector/source resource.

Profiling found road rasterization dominated first construction. Tight raster
bounds, native segment queries and prepared reservation buckets reduce that cost.
The unchanged village also loads a reproducible, imported 119 KiB terrain bake.
Stable geometry/palette hashes reject stale art; palette/layout edits render
live, and the test gate compares complete RGBA pixels with the generator.
At most four generated terrain variants remain cached. Optional bake loading
also guards first-import timing, so a fresh editor checkout does not report a
missing imported source texture. Explicit baking is tested only in a disposable
source copy; it never runs during gameplay.

## Actual before/after evidence

The same `world_review.gd` and shell wrapper run against a clean archive of the
verified main commit and the final source. Every PNG is an actual GL Compatibility
viewport capture. Manifests record time, player position, zoom, resolution,
effects and Reduce Motion. Day fixtures hold the clock at 45 seconds, night at
205; environment actors are held for paired framing. Intentional new spawn
clearance can change enemy placement. Movement uses real InputMap input and
combat asserts actual enemy damage.

| Location/state | Main before | Implemented after |
|---|---|---|
| Cottage/spawn | [before](evidence/world/before/spawn.png) | [after](evidence/world/after/spawn.png) |
| Market | [before](evidence/world/before/market.png) | [after](evidence/world/after/market.png) |
| Market/home transition | [before](evidence/world/before/market-home.png) | [after](evidence/world/after/market-home.png) |
| Portals/approach | [before](evidence/world/before/portals.png) | [after](evidence/world/after/portals.png) |
| Forest boundary | [before](evidence/world/before/forest-edge.png) | [after](evidence/world/after/forest-edge.png) |
| Forest interior | [before](evidence/world/before/forest-interior.png) | [after](evidence/world/after/forest-interior.png) |
| Beach/turtle | [before](evidence/world/before/beach-turtle.png) | [after](evidence/world/after/beach-turtle.png) |
| Jetty/ship | [before](evidence/world/before/jetty-ship.png) | [after](evidence/world/after/jetty-ship.png) |
| Gardens/residences | [before](evidence/world/before/farms-residential.png) | [after](evidence/world/after/farms-residential.png) |
| BESUT | [before](evidence/world/before/besut.png) | [after](evidence/world/after/besut.png) |
| Western cottages | [before](evidence/world/before/west-cottages.png) | [after](evidence/world/after/west-cottages.png) |
| Wide topology | [before](evidence/world/before/overview.png) | [after](evidence/world/after/overview.png) |
| Night village | [before](evidence/world/before/night-village.png) | [after](evidence/world/after/night-village.png) |
| Night forest | [before](evidence/world/before/night-forest.png) | [after](evidence/world/after/night-forest.png) |
| Night coast | [before](evidence/world/before/night-coast.png) | [after](evidence/world/after/night-coast.png) |
| Active traversal | [before](evidence/world/before/traversal-14.png) | [after](evidence/world/after/traversal-14.png) |
| Actual combat | [before](evidence/world/before/combat.png) | [after](evidence/world/after/combat.png) |
| Small screen | [before](evidence/world/before/small-screen.png) | [after](evidence/world/after/small-screen.png) |

There are 27 captures per ref, including all effects tiers, Reduce Motion,
28/64 zoom and Low night rendering. Native gameplay fixtures are 1280×720;
small-screen fixtures are 832×480. The wide overview deliberately uses zoom 17
for inspection, outside the player's normal 28–64 range. Editor/restart evidence
is in `evidence/world/editor/`; its water/blocked-road paint is a deliberate
validation fixture, not the shipped village. Native-size images and overview,
night, coast, woodland, small-screen and combat compositions were inspected.

## Verification

- Incoming main: 562 isolated gameplay checks, PASS.
- Final combined gameplay gate: **720 checks, PASS**, exit 0.
- Spatial checks: **158 checks, 0 failures**, also integrated into that gate.
- Native graphical deep audit: **63 checks, 0 failures**, exit 0.
- Disposable native editor workflow: **34 checks, 0 failures**, followed by a
  separate runtime restart PASS. This includes explicit source bake, reimport,
  stable bake selection, spatial editing and native undo/redo.
- Final paired renderer runs: 27 PNGs each, actual traversal and combat damage
  verified, `WORLD_REVIEW PASS`, exit 0.
- `git diff --check` clean; final logs have no `[FAIL]`, `SCRIPT ERROR` or `ERROR:`.
  Xvfb reports its expected unsupported-VSync/input-method warnings.

All mutating tests/captures verified temporary XDG user data. Editor-writing and
bake tests used disposable source copies. A read-only live-save backup was made;
no player save was deleted/restored or overwritten by these tests. Raw acceptance
and destructive legacy capture/conversion tools were not used. Scene-based runners enforced isolation throughout.

## Performance

| Metric | Verified main | Implemented world |
|---|---:|---:|
| First village build in process (ms) | 707.532 | 214.710 |
| Cached reconstruction (ms) | 17.524 | 26.260 |
| High median / p95 (ms) | 28.106 / 41.674 | 26.596 / 30.961 |
| Medium median / p95 (ms) | 30.537 / 36.594 | 26.982 / 34.929 |
| Low median / p95 (ms) | 21.803 / 26.377 | 19.186 / 22.591 |
| High draw calls | 298.66 | 291.56 |
| Scene nodes | 1529 | 1524 |
| Texture memory (bytes) | 45929645 | 46000613 |
| High physics monitor (ms) | 1.122 | 1.220 |
| Eight destination planning queries (ms) | 16.189 | 14.659 |
| Active residents median / p95 (ms) | 30.491 / 39.271 | 27.322 / 31.468 |
| Active resident physics monitor (ms) | 1.629 | 1.700 |

The measurements use the same host/llvmpipe software renderer, GL Compatibility,
1280×720, fixed day clock at 45 seconds and matching camera/settings. Static
quality workloads use 40 warm-up plus 180 measured frame intervals. A separate
High workload restores all 14 residents, warms for 60 frames and measures 240.
Runs are sequential without concurrent imports/tests. Physics values are Godot
monitor averages; path planning measures eight actual destination queries.
These are fixture frame intervals, not native Android FPS or a combat stress test.
Raw measurements and manifests are retained beside the screenshots.

The final paired static medians and p95 intervals meet the approximate 10–15%
steady-frame regression target; the observed medians improve by about 5%, 12%
and 12% across High/Medium/Low. Draw calls and node count fall slightly; texture
memory changes by about 0.15%. The imported bake avoids default road generation
at launch. First village construction measures 707.5 → 214.7 ms in this pair;
an earlier matched run measured 430.1 → 354.9 ms. These are first constructions
inside a process, not controlled cold operating-system file-cache measurements.

Cached reconstruction adds about 8.7 ms (17.5 → 26.3 ms), a real remaining cost
of spatial/reservation and contextual composition work, although it occurs only
on world construction rather than each frame. Earlier matched runs before the
bake, using a live follow-camera fixture, measured High medians 29.024 → 27.279 ms,
Low 20.882 → 21.042 ms, and active residents 26.919 → 27.750 ms. Both host timing
and fixture details affect the apparent improvement. These observations support
comparable steady rendering with small resource changes, not a reproducible
hardware speedup claim. Phone performance and sustained combat remain unmeasured.

## Limits and preserved trade-offs

The village is deliberately curated, not a general world generator. Major
building anchors remain familiar; coherency comes from connected access, shared
plots/regions and contextual composition rather than moving everything. The
persistent forest positions remain fixed, so some inherited canopy clusters
and ruin relationships remain recognizable. Physics-centreline and complete
entrance tests do not guarantee every point along a decorative road edge is
free for every possible actor or player-created arrangement.

Legitimate saved layouts remain authoritative. A player can still deliberately
seal an entrance or overlap structures in the existing Build workflow; no
migration deletes/repositions their possessions. Custom routes repair only
where a real path exists. Live custom terrain has a first-generation cost and
must be baked explicitly to gain the unchanged-default startup path.

The render harness holds enemies for comparison and measures normal day residents
separately; it is not a long unattended raid or Android thermal/performance audit.
No physical Android device was connected. The previously delivered APK was the
verified main snapshot, not this later overhaul. The studio canvas remains a
representative authoring preview where noted above; isolated Play is exact.
