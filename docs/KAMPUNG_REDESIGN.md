# Kampung world redesign

## Baseline audit and master plan — 24 October 2026

Started from fetched origin/main `1c9e77bef88e0cfe16d169cc80c9aed6ed2c692b`,
on `codex/kampung-world-redesign`. Clean checkout. Baseline isolated gameplay:
720 checks PASS. Actual Compatibility captures and metrics were recorded before
editing, with the unchanged world_review harness. Bounds remain 64 × 40 units.

Already working: connected 36-edge route graph, physics-tested entrances,
shared shore/collision sampler, editor overlays, save precedence, terrain bake,
and the 64-tree fixture. These are foundations, not problems to replace.

The overview reveals isolated house frontages, the eastern construction counter
separated from commerce, overlapping southeast ruin/house plots, disconnected
activity coordinates, an unusually bare sanctuary, and domestic decorations in
public circulation. Roads are readable but equally pale and substantial even
in the woods. The western housing lane has no shared social focus.

Plan: retain cottage, portals, coastline, forest and world bounds. Form a western
residential lane with related north/west homes; separate southeast residence and
ruin. Bring the carpenter's customer frontage to the northern market, maintaining
a service yard. Give existing farms an animal yard and stable-related horses.
Make harbour infrastructure and all twelve daily routines layout-owned. Frame
the sanctuary with distinct combat/companion monuments and quiet stone courts.
Use small original banana, veranda, drying, seating and work assets along plot
edges. Preserve open fronts, the cottage arrival and all combat clearings.

Intended relocation ledger and measured results are completed below after
physics and renderer review; source geometry remains in village_layout.tres.

## Research translated into choices

The [Besut District Council's Desa Ukiran Kayu](https://mdb.terengganu.gov.my/index.php/ms/pelawat/destinasi-menarik/desa-ukiran-kayu?lang=ms-MY)
supports Besut's timber-craft identity. The carpenter's yard therefore belongs
near the market rather than as an isolated fantasy booth. The
[Terengganu museum's own architecture account](https://museum.terengganu.gov.my/index.php/muzium/sejarah-pembinaan-muzium)
describes raised access, carved timber and connected communal courts: shaded
verandas and household lanes inform the design without copying a heritage house.
[Terengganu's cultural village](https://pitas2030.terengganu.gov.my/kampung-budaya-terengganu/)
documents fishing houses, net making and woodwork; nets/drying racks belong at
the landing and timber/tools at the carpenter. These are local references.
Bananas, clotheslines and informal household gardens are broader Malaysian
inspiration, not claims about a particular Besut parcel.

The supplied [Kuala Besut resort guide](https://www.tunabay.com.my/exploring-kuala-besut-terengganu-gateway-to-perhentian-island/)
provides waterfront context. The supplied travel page labels its lead image AI
generated, so it is not architectural evidence. The Johor communal-space paper
is a broader regional analogy; its inaccessible full text is not evidence for
Terengganu-specific dimensions. Photo searches of museum houses informed eaves
and shaded decks; no reference pixels were copied or imported.

The existing Geometry2D polygon and PhysicsDirectSpaceState2D shape-query model
is retained, checked against Godot documentation and the installed 4.7.2 engine.
ResidentRoutes still produces visible corners for continuous movement.


## Implemented geography and ownership

The authored resource now contains 58 anchors, 39 connected routes, 10 zones,
65 scenery records and 30 activity records. The 64 × 40 world, cottage, paired
portal IDs, shared shoreline, six gardens and original 64 forest associations
retain their existing contracts. No autoload, campaign rule, movement model,
collision-layer change or player-save field was added.

| Place | Before | After | Reason |
|---|---|---|---|
| Carpenter shop | (41.2,16.2) | (23.6,14.2) | Northern market frontage and timber-working yard |
| Herbal shop | (23.8,22.2) | (23.8,22.7) | Remove conservative plot overlap with equipment shop |
| Western home | (14,18.1) | (12.5,18.7) | Open coastal compound and shared lane |
| Northwest home | (11,12) | (15,10.7) | Relate western households through a common lane |
| Northern home | (25,8) | (23,7.2) | Upper neighbourhood with distinct garden frontage |
| Abandoned cottage | (17.8,13.6) | (6.7,15) | Older coastal parcel; remove overlap with new lane |
| Southwest home | (29,33) | (29,34.8) | Separate domestic plot from coastal circulation |
| Damaged southeast home | (52,33.2) | (58,36.2) | Separate ruin from inhabited southeast residence |
| Stable activity hub | (35.8,31.3) | (34.9,32.3) | Both horses and handler clear the southern house |
| Animal yard | scattered coordinates | hub (42.5,27.3) | Keep animals and keeper clear of fixed trunks |

All independently movable barrels/crates/signposts retain their old save IDs.
Their new defaults are local anchors of the appropriate building or workspace.
Explicit player positions still win. The carpenter's tools, timber, workpoints
and associated barrel follow its owner. Homes gain a shaded veranda, a side
banana clump, a clothesline and selective potted planting. The shared western
court has a wakaf; domestic fronts stay open. The market has shaded seating and
an herbal preparation table. Farm props frame existing beds and the animal yard;
feed belongs to the stable. These static details add no physics bodies.

Sami's workpoints, net stores, drying rack, rope, lamps, boat and gathering
positions now resolve from harbour/beach geography. The visible jetty and sea
cutout use matching harbour-relative deck coordinates. The shoreline sampler,
water mask, turtle grounding, sea-cleaning counter and sea-monster rules remain
unchanged. No land paint reclaims water. Defenders, farm workers and keepers use
existing collision-aware movement; all twelve daily residents have owner-local
routines. Changing a workshop or garden updates destinations without assigning
new actor positions.

The market crescent remains convenient to the three everyday retailers. Its
northern branch now reaches carpentry; the former eastern workshop road becomes
an eastward village/forest connection. Western homes share a bent lane and court;
the southeastern loop reaches the stable and southern home. Main routes retain
roughly 1.9–2.3-unit widths, quieter lanes 1.5–1.8 and woodland tracks 1.2. Earth
is less luminous; informal woodland wear is darker and less built. Materials
still union before compositing, avoiding dark junction seams.

Portal IDs, unlocks, swirls, effects limits and transitions are untouched. Inset
stone rings, a shared threshold, an ancient sentinel at the monster gate, a
companion monument at the pet gate and restrained magical planting give them a
shared precinct with different identities. The front interaction rectangles
remain clear. Forest tracks and understory preserve existing clearings and tree
positions; no optional decoration draws from gameplay RNG.

The default terrain was explicitly rebaked and imported. The full RGBA parity
check against live generation passes. Map Studio edits invalidate geometry
hashes and use the live generator, as before. New activity/scenery overlays and
relative point editing participate in native undo/redo and source save/reload.
The settlement editing area extends north within the existing world so picking
up the market workshop does not clamp it southward.

## Actual renderer review

Paired images use the same current `tools/world_review.gd` against an archived
copy of fetched main and this feature. They instantiate the real game through
`scenes/game.tscn` on the GL Compatibility renderer under Xvfb/llvmpipe. Manifests
record player and actual camera centre, resolution, time, zoom and settings.
Ordinary fixtures use zoom 38 at 1280 × 720; the overview uses diagnostic zoom
17, deep woodland uses supported zoom 64 and small-screen capture is 832 × 480.
Day is held at 45 seconds, night at 205. Environment actors are held for paired
framing; live movement and resident performance have separate fixtures.

| Review | Before | After | Assessment |
|---|---|---|---|
| Village overview | [image](evidence/kampung/before/overview-clean.png) | [image](evidence/kampung/after/overview-clean.png) | Grouped western households, market workshop and open cottage heart |
| Cottage arrival | [image](evidence/kampung/before/spawn.png) | [image](evidence/kampung/after/spawn.png) | Main roof remains the landmark; seating and plants frame circulation |
| Market | [image](evidence/kampung/before/market.png) | [image](evidence/kampung/after/market.png) | Counter fronts read as a shared commercial place |
| Western residences | [image](evidence/kampung/before/west-cottages.png) | [image](evidence/kampung/after/west-cottages.png) | Domestic work and social court replace isolated house sprites |
| Farm/stable | [image](evidence/kampung/before/farms-residential.png) | [image](evidence/kampung/after/farms-residential.png) | Animal care and planting belong to separate, readable grounds |
| Sanctuary | [image](evidence/kampung/before/portals.png) | [image](evidence/kampung/after/portals.png) | Shared stone vocabulary, distinct monuments and open entry courts |
| Forest edge | [image](evidence/kampung/before/forest-edge.png) | [image](evidence/kampung/after/forest-edge.png) | Maintained village gives way to shaded tracks and dense fixed canopy |
| Deep woodland | [image](evidence/kampung/before/deep-forest.png) | [image](evidence/kampung/after/deep-forest.png) | Existing ecological masses preserved, tracks less paved |
| Fishing harbour | [image](evidence/kampung/before/jetty-ship.png) | [image](evidence/kampung/after/jetty-ship.png) | Net mending and fish drying belong to the landing |
| Turtle beach | [image](evidence/kampung/before/beach-turtle.png) | [image](evidence/kampung/after/beach-turtle.png) | Open sandy shelf, visible turtle and unobstructed jetty |
| Night sanctuary | [image](evidence/kampung/before/night-portals.png) | [image](evidence/kampung/after/night-portals.png) | Monuments remain static/readable; no new light wash |
| Night homes | [image](evidence/kampung/before/night-residential.png) | [image](evidence/kampung/after/night-residential.png) | Timber, veranda and warm windows retain domestic identity |
| Night farm | [image](evidence/kampung/before/night-farm.png) | [image](evidence/kampung/after/night-farm.png) | Quiet agricultural edge remains readable during raids |

The first render was revised: thin banana pixels became broader leaves; the
workshop entrance moved clear of the fence; the residential lane bent around
fence runs; farm and horse points moved away from fixed trunks/buildings. These
are actual renderer/physics findings. Deliberately open arrival, portal and
beach space remains; adding detail uniformly would undermine their role.

The visual density review uses recognizable landmark, unobstructed frontage,
contextual prop grouping and quiet circulation as its criteria, rather than
inventing a universal occupancy score. Declared building plots occupy about
307.74 square units; route centreline length is about 252.96 units. Neither is a
claim about traversable area: route widths overlap and shore/forest are excluded
from that simple plot tally. Full declared plots have zero unintended building
intersections. Every destination and route centreline is checked in actual
physics with player clearance, and full entrance rectangles are checked too.

## Compatibility and limits

The full gate covers new-game spawn, all shops and purchases, paths, gathering,
sea cleaning, both portals, pet duels, dungeon entry/return, progression, combat,
night waves, emergencies, shelters, tree damage/protection, house recovery,
settlement dragging, save/load, graphics settings and synthetic touch input.
Older player layouts retain precedence. Tests exercise developer/player override
resolution, independent saved decorations, default inherited maps and forest
fixture stability. Arbitrarily obstructed player-built layouts are still reported
rather than silently deleted; no world design can make a sealed doorway usable.

Physics-backed NPC tests require actual arrival and bound every movement step by
speed × delta. Player traversal records intermediate positions and three rendered
frames; combat captures require real damage. The sample array can span several
physics ticks around a blocking screenshot readback, so it is not a frame-time
measurement. The performance run holds residents for presentation measurements,
then measures them live separately.

Animals retain their original stationary ambient bob inside authored yard/stable
locations; no roaming AI was added. Existing house tiers are preserved and gain
compound variations rather than a new orientation/collision system. New art is
reproducible code-native pixel art with registry overrides, not copied photos.
The unchanged persistent forest is a compatibility boundary, not a regenerated
landscape. Physical Android hardware, native Windows behavior and long human
playtests were not verified. Software-renderer figures below are relative desktop
evidence, not a mobile frame-rate guarantee.


## Measured runtime cost and travel

Final paired 1280 × 720 llvmpipe samples, frame median / p95 in milliseconds:

| Effects | Main | Redesign | Draw calls |
|---|---|---|---|
| high | 24.42 / 30.59 | 26.95 / 30.96 | 292 → 302 |
| med | 25.03 / 28.94 | 25.82 / 31.52 | 290 → 300 |
| low | 18.39 / 21.92 | 19.69 / 22.44 | 289 → 299 |

With residents active, median / p95 was
26.22 / 29.33 ms before and
26.32 / 29.73 ms after.
Node count rose from 1524 to 1589;
texture memory rose by approximately 0.96 MiB.
Eight destination plans took 14.33 → 16.43 ms.
Cold construction was 229.73 → 367.02 ms,
warm construction 27.85 → 31.96 ms.
Cold timing varied substantially across runs (main roughly 196–361 ms;
feature roughly 221–426 ms), so the single cold sample is not a stable startup
regression estimate. Final High median increased about
10.4%;
live-resident median changed about
0.4%.
These are modest static-detail costs on this software-renderer fixture, with
no per-frame terrain generation or extra decorative physics. They do not
establish native mobile performance.

Actual collision-aware arrival-to-destination path lengths (world units):

| Destination | Main | Redesign |
|---|---|---|
| forest_defence | 14.60 | 14.60 |
| jetty_landing | 22.60 | 22.60 |
| monster_portal | 15.42 | 15.42 |
| pet_portal | 15.42 | 15.42 |
| shop_equipment | 12.77 | 12.76 |
| shop_house | 10.88 | 14.01 |
| shop_pet | 8.73 | 8.73 |
| shop_potion | 9.53 | 9.48 |

The workshop moves farther from the home arrival, but joins the northern market
instead of requiring an eastern detour from the other merchants. Everyday
potion/equipment/pet travel, both portal paths, forest approach and jetty access
remain essentially unchanged. This is a deliberate commerce relationship tradeoff,
not a claim that every journey becomes shorter. Complete samples and manifests
are committed beside the paired PNGs; each side contains 32 actual captures.


## Delivery verification

- `godot --headless --path . --import` with isolated XDG data: clean.
- `./tools/test_isolated.sh`: **812 checks, PASS**, exit 0; baseline **720, PASS**.
- Native `tools/deep_audit_test.tscn`: **63 checks, 0 failures**, exit 0.
- `./tools/test_creative_editor.sh`: **37 checks, 0 failures**, then a separate
  **creative restart PASS**; source import/bake/save happens in a disposable copy.
- `./tools/review_world.sh` on archived main and feature: both **WORLD_REVIEW PASS**,
  **32 PNG captures per side**, actual movement and combat checks passed.
- Complete gameplay, renderer, editor/import/bake and restart logs were checked
  for `[FAIL]`, `SCRIPT ERROR`, `ERROR:` and tool failure markers: clean.
- `git diff --check`: clean. No `build/` or `res://shots` output was created.
  Normal player data was never used or restored by these tests.

Evidence lives under `docs/evidence/kampung/`. The editor canvas/runtime files
there are deliberately painted authoring test maps, including validation warnings;
they are not the shipped village. Renderer manifests and performance files are
raw measured outputs. Native Android hardware remains untested.

Primary implementation files: `data/maps/village_layout.tres`,
`scripts/creative/world_layout.gd`, `world_composition.gd`, `world_terrain.gd`,
`kampung_art.gd`, `authored_map.gd`, `scripts/world/lobby.gd`,
`addons/tidesworn_creative_tools/map_panel.gd` and `studio_test.gd`,
`tools/kampung_checks.gd`, `tools/kampung_probe.*`, `tools/world_review.gd`,
and the rebuilt `assets/authored/village/terrain.png`.
