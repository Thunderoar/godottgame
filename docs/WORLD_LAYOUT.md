# Village layout and authoring

The shipped `data/maps/village.tres` references
`data/maps/village_layout.tres` (`WorldLayout`). This is the canonical developer
layout. Runtime code reads a deep copy; no game session writes this resource.
AuthoredMap version 2 adds an optional `layout`; older maps without it inherit
village defaults. Existing layers, objects, stable IDs and save data remain valid.

## Data and hierarchy

| Collection | Fields and purpose |
|---|---|
| `anchors` | Stable `id`, `kind`, `position`, `zone`, local `footprint`, local `approach`, `clearance`, `owner`, `priority`, `movable`, `destination`; shop merchant/lamp, residence tier, ruin state and fence span/gaps |
| `routes` | Stable `id`, `from`/`to` anchor IDs, optional `via` points, full `width`, primary/secondary/informal `role`, ground `material` |
| `zones` | Stable `id`, authored concave `polygon`, material, decoration `density` and allowed categories |
| `scenery` | Stable `id`, asset, district, position, scale and optional owning building ID; building-local positions travel with that parent |

Positions are world units (32 art pixels each). Building approach offsets are
measured at the actual customer/door frontage. Footprints include their visual
plot; runtime colliders remain the existing builder-owned shapes. Reserved
approaches and road ribbons reject foliage and warn about blocking authoring.
Fence span/gap coordinates are local to the fence anchor, so moving a fence moves
its gates too. All runtime actors continue moving in continuous world space.

The primary network connects the home forecourt, market crescent, portal court,
workshop/forest gate, garden lane and coastal loop. Secondary lanes reach each
cottage, stall, stable and jetty. Informal tracks use the existing forest clearings.
The graph is connected at explicit anchor endpoints, rather than relying on
unrelated polylines happening to overlap visually.

## Districts

- Homestead: open frontage, porch seating, planters and a short recovery/door link.
- Market: connected merchant crescent; herb planters, smith tools/timber, pet
  feed and baskets; a separate workshop joins the northern/eastern loop.
- Portal grounds: cooler stone approaches and a shared northern gateway, framed
  by the existing warning stones and lanterns.
- Farmland/residential: garden promenade, animal yard, cottages with front paths,
  and ruins retained as settlement history.
- Waterfront/beach: a fishing court, nets, stores, mooring details and reachable
  timber jetty. The turtle uses the shared sandy shoreline shelf.
- Forest edge/interior: irregular overlapping regions, a shaded ground ramp,
  tree-centred understory and restrained tracks around existing trunks.
- Reserved gameplay: clear arrival/recovery and interaction space.

## Precedence and persistence

1. Existing player `GameState.settlement_layout` positions.
2. Developer AuthoredMap `objects` with an existing `base_id`.
3. Canonical WorldLayout anchors (or inherited defaults on an older map).

No player save migration is needed. House and shop owners contain their art,
collision, targets, merchant and local workspaces. Drag completion saves through
GameState, updates the ward and shelter references, invalidates resident planning
and refreshes ground routes. If a customized building crosses an authored road,
a one-time physics planner repairs the route on the resolved copy after the
physics server synchronizes. It never rewrites developer geometry or the save.
A deliberately sealed entrance cannot be made accessible without changing that
placement; the editor reports such conflicts rather than deleting structures.

Forest placement is a special compatibility boundary: the existing 64-tree
fixture, RNG state, creation order, IDs, positions and maximum HP remain unchanged.
Historical exclusion coordinates and the 160 pre-forest random draws are frozen
solely for that compatibility. They do not position buildings. Optional flowers,
understory and grass use separate seeded random streams.

## Edit in Map Studio

1. Open Tidesworn → Map Studio and enable **Spatial overlays**. Choose the spatial category to see
   blue district polygons, amber roads, or green plots with red approaches. Only
   the selected feature is labeled, keeping the overlay readable.
2. Choose `anchors`, `routes` or `zones`, then its stable ID in the adjacent list.
3. Choose **Move layout point** in the tool list. Drag/release to place the anchor,
   route bend or polygon vertex. `Bend / vertex` is a zero-based index into the
   route's `via` array or zone polygon. Route endpoints follow their anchors.
4. For a road, set **Road width**, then **Apply road width**. Width is the full
   ground ribbon, not a radius. Each edit participates in native Undo/Redo.
5. Validate, Save, and **Play this map**. Play runs the actual village in isolated
   user data; editor Save writes only the selected source map.

Adding/removing graph edges, inserting vertices, changing kinds/footprints or
adding new semantic rules is done in the focused `village_layout.tres` resource
(or its ordinary Godot Resource inspector). The studio supports moving the
existing curated graph; it is not a second world-generation framework.

Terrain and spatial geometry share the runtime renderer in the editor. Preview
includes service-specific stalls, residences, tree families, workspaces, jetty
and boat. Base-object tree scale, fence segment art, live NPCs, lighting and
player customization remain representative in the 2D authoring canvas; **Play**
is the exact full gameplay preview. Existing asset importer, pixel editor,
palette editor and source recovery drafts keep their original workflows.

## Geography, cache and physics

`WorldTerrain.shore_y` is the shared two-art-pixel sampler for terrain, water mask,
turtle grounding, land-paint clipping and spawn checks. Sea collision follows the
same coast and subtracts only the actual visible jetty deck footprint. Sea remains
solid beyond the planks; no invisible walkable sea extension is introduced.
Authored water adds collision even when its material is painted in another
terrain layer. Shore/land paint cannot visually reclaim existing water.

Terrain is generated only at construction/layout or palette changes. Equal
layouts reuse textures. At most four generated terrain versions remain cached;
foliage uses bounded PixelArt caches and existing MultiMesh grass batches.
Spatial reservation lookups use prepared local buckets rather than rebuilding
route arrays for every plant. There are no per-frame terrain images or new
physics bodies on cosmetic props. Spawn clearance searches are bounded and
consume no placement RNG.

### Rebuild the default terrain bake

`assets/authored/village/terrain.png` is a reproducible source export. The layout
stores its path plus geometry and palette hashes. The runtime loads the imported
texture only when both hashes match; missing/stale bakes use the live generator.
The gate compares the complete RGBA pixels of the bake and generator.

After deliberately changing the shipped layout/palette, use isolated user data:

```sh
bake_root=$(mktemp -d /tmp/tidesworn-bake-XXXXXXXX)
mkdir -p "$bake_root/userdata"
XDG_DATA_HOME="$bake_root/userdata" TIDESWORN_TEST_ROOT="$bake_root" \
  timeout 60 godot --headless --path . res://tools/bake_village.tscn -- --write-village-bake
XDG_DATA_HOME="$bake_root/userdata" timeout 120 godot --headless --path . --import
```

The explicit `--write-village-bake` operation writes the source PNG and matching
layout metadata. It is never invoked by gameplay. Map Studio edits invalidate
the old hashes immediately; Save may embed a customized layout in that selected
map, while maps without one continue inheriting `village_layout.tres`. A new
source PNG must be imported before exporting. The native editor runner tests
baking, saving, reimporting and reopening in a disposable source copy.

## Kampung compounds and activities

The kampung redesign adds `activities` to WorldLayout. Each has a stable `id`,
`kind`, semantic `owner` and `points` containing an anchor ID plus local `offset`.
Resident records also carry role, activity and existing combat parameters. Animals,
gathering piles, the moored boat, guard, student and water keepers use the same
model. Runtime resolves against the saved/developer/canonical anchor hierarchy.
Old WorldLayouts without activities inherit the village recipes using their
existing anchors; new semantic points have canonical fallbacks.

Scenery parents may be residences or semantic anchors as well as movable shops.
Building children move with their owner; geography-only anchors resolve at world
construction. Selected independently movable prop anchors and the jetty deck have
`relative_to` and `offset`. A saved prop remains independent and wins over that
relative default. Harbour art, mooring, boat, work routes and deck geometry now
share harbour-relative placement. Coast shape itself remains unchanged.

Map Studio's spatial category list now includes **scenery** and **activities**.
Move layout point edits a scenery offset relative to its parent, or the selected
activity point relative to its referenced anchor. Bend / vertex selects that
activity's point index. The overlay shows work routes; native undo/redo and map
snapshots include the complete activity collection. Owners/species/roles and new
point insertion are edited in the resource, alongside the existing graph schema.
Settlement drag completion refreshes semantic waypoints and route caches without
repositioning residents. Cosmetic plot-edge bushes consume only decoration RNG.
Road `role` participates in the bake signature because informal tracks now use
a different ground treatment. Changing hierarchy alone therefore rejects stale
terrain art. Source edits still require the explicit bake/import workflow above.
