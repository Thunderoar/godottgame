# Village districts — 2026-10-30

The default main map places **shops on the left (west)** and **occupied homes on
the right (east)**, following the corrected brief. This changes the authored
village, not a second scene, a decorative mock-up, or the player's saved layout.

```text
NORTH   West workshop + construction / equipment     Dimension Portal
                     merchant lanes      green      upper cottages
WEST    Pet / potion shops            wide padang    main cottage       EAST
        market court + BESUT sign      promenade     residential lanes  forest
SOUTH   Water/services → fishing jetty    kebun       lower cottages
                       coastline       pasture      farm homestead
```

## Geography and environment

- All five shop centres occupy x=10–18; construction uses x=10.25. Construction
  and equipment form the upper craft row, pet and potion the lower shopping row,
  and Water/services sits farther south toward the fishing landing.
- All eight occupied homes, including Adam's cottage, the farm homestead and
  forest watch lodge, stand east of every shop. Five ordinary households now share
  the eastern residential district. Historical `ResidentHouseWest` etc. IDs remain
  stable: those identifiers are persistence keys, not instructions to keep houses west.
- There is **10.1 world units (323.2 source pixels)** of horizontal separation
  between the rightmost shop footprint and the leftmost occupied-home footprint.
  This is a full-plot measurement, not a centre-to-centre estimate.
- `village_green` is a broad, softly feathered light-grass district between the
  quarters. A wakaf, bench, planters and flowers furnish its edges without filling
  the gap with buildings, water barriers, dense scenery, or a continuous wall.
- Community vegetable plots and livestock move into the southern green's
  extension, freeing residential plots while retaining garden, keeper and stable
  routines. Clotheslines, verandas, household planting, workshop materials and
  landing equipment follow their owners and avoid public circulation.
- The primary east–west route connects the cottage forecourt to the market.
  Secondary paths connect each house and shop; northern access reaches the
  sanctuary, and the coast route still reaches the landing, turtle and ship.
  Wider streets remain walkable rather than teleporting or snapping actors.

## Ownership and compatibility

The implementation lives in `data/maps/village_layout.tres`: `anchors.position`,
relative prop `offset`, `routes.from/to/via/width`, district polygons and scenery.
The main cottage, arrival, recovery, shoreline, jetty, portal, original forest
positions/IDs/HP associations, map dimensions and gameplay RNG remain unchanged.
Player-saved movable-building/decor positions still take precedence over new
source defaults; no save is cleared or migrated to force the arrangement.

The settlement editing area expands to encompass the western shops. A drag is
rejected when the centre or either side of its selection base enters the sea;
existing workshop reservation checks still apply. Existing customised layouts
remain authoritative, so a player's earlier arrangement need not match the new
canonical overview.

The terrain PNG and geometry hash were generated in a disposable source copy,
then copied into the checkout and imported with isolated user data. Runtime and
Map Studio continue to share the same geometry and imported bake. No editor
drafts or live game saves were cleared, and no running player/editor was stopped.

## Regression coverage

`KampungChecks` checks every home/shop's side, the >=10-unit full-plot separation,
central green identity, district membership, accessory clearance, worker travel,
editor selection bounds, sea rejection and saved-placement precedence.
`WorldChecks` checks actual destination and swept lane collision, reachability,
forest associations, imported-bake pixel parity and source-copy independence.
The workbench district-drag fixture now grabs inside the relocated residential
polygon rather than the former western district.

`world_review.gd` starts an isolated fixture directly instead of indefinitely
awaiting the player-paced introduction. It captures both quarters, green and
farm/coastal routes, day/night, settings changes and compact 832×480 framing as
well as the 1280×720 overview. It also records intermediate actual movement.

Verification exposed a pre-existing exact-duration Reduce Motion fade boundary:
rescaling elapsed time could round just below the completion threshold. The
one-line comparison now uses unscaled elapsed time and the selected duration;
normal dialogue timing and fade interpolation are unchanged. A separate boundary
probe records the before/after outputs in the external evidence bundle.

The broader new routes exposed an initial navigation-cache issue: a cached grid
could report no ship-return path while a fresh planner found a connected route.
Lobby now invalidates that initial grid after two physics frames, guarded by
current-world and journey ownership. No actors are teleported and no pathfinding
clearance is weakened; the exact ship-return destination is checked in WorldChecks.

These are Linux headless and Xvfb/llvmpipe checks, not physical Android touch,
native Windows, or comparative hardware-performance certification.

## Observed validation — 2026-10-30

- Canonical isolated gameplay: `--- tide test: 5906 checks, PASS ---`, exit 0.
- Disposable Creative Studio: `--- creative tools: 84 checks, 0 failures ---`,
  exit 0; both `creative restart: PASS` and `workbench restart: PASS`.
  Both restart scenes also passed against the final navigation-cache change.
- Actual-renderer review: `WORLD_REVIEW PASS`, exit 0; inspected 1280×720 overview
  and 832×480 quarter views. Actual input traversal and combat checks passed.
- Baseline measurement: homes and shops interleaved horizontally, clear band -25.8.
  Modified measurement: every occupied home right of every shop, clear band 10.1.
  Rollback measurement: original output and pristine map hash restored exactly.
- Reconstructed source patch and separate-copy rollback were checked byte-for-byte.
  Old introduction-waiting review/restart fixtures, three editor-fixture failures,
  layout-clearance failures, the fade-boundary failure and stale-grid return failure
  were recorded and corrected; they are not presented as successful runs.
- Linux Xvfb emitted input-method and unsupported V-Sync warnings. No native phone
  or Windows validation, release export, or hardware-performance claim is made.
