# Map Studio

Open **Tidesworn → Map Studio**. The default document is
`data/maps/village.tres`; `creative_test.tres` is a practice garden. New maps use
the existing 64×40 village envelope. This is a hybrid authoring system: the
procedural base, existing gameplay objects, and authored overrides coexist.

## Paint and arrange

Choose a layer and material, then Pencil, Eraser, Rectangle, Fill or Eyedropper.
Brush size is 1–8 cells. A cell is 32 art pixels / one world unit. Mouse wheel
zooms at the cursor; middle drag pans. Grid and object snap are independent.
Layer visibility and locking are persisted editor preferences. Select a region,
then use Move and drag to shift its cells on the current layer.

Terrain, Paths, Water and Shore create material layers with neighbour-aware
feathered transitions. Grass, paths, sand, shallow/deep water and stone are
available. Decoration/Vegetation paint sparse flowers or plants rather than
opaque terrain. Water cells also block actors; Collision paints invisible
runtime collision. Adjacent collision cells merge into horizontal runs.
TileMapLayer batches each populated visual layer, rather than creating one node
per cell. Procedural grass is suppressed beneath authored terrain paint.

Choose Place object and an asset ID (`coastal/planter`, `tree`, `bush`, `house`,
`shop`, `fence`, `flowers`, `rock`, `bench`, `sign`, `garden`, or an imported ID).
Set label, scale, depth, footprint, blocking, interactivity and metadata. Select
object loads its properties; Move object changes its position. Apply properties
commits edits. Delete removes the selected authored object. IDs remain stable.

The viewport also shows fixed-seed base object proxies from
`data/maps/village_objects.tres`. Selecting an existing non-protected object
creates an explicit base override; moving it moves the existing runtime node,
including its collision, without recreating or renumbering it. Deleting that
override restores the procedural base placement. Base-object asset/scale/collision
controls are read-only. The cottage and original shops use the existing player
Build mode, which maintains their service/recovery contracts. Base proxies are
representative art; **Play this map** is the exact gameplay preview.

New authored trees use ForestTree and their stable authored ID for HP. Existing
forest IDs and seeded creation order remain unchanged. Player settlement layout
has precedence over developer base-object placement. Do not reuse an ID for a
different persistent object.

Metadata JSON can add context:

```json
{"kind":"prop", "description":"A cool seat overlooking the sea."}
```

Interactive props show the label/description in the game's existing dialogue UI.
`kind: "shop"` plus `shop_type: "potion"`, `"equipment"`, `"pet"` or `"house"`
creates a working merchant. `kind: "route"` plus `resident: "<existing name>"`
adds a route waypoint to that resident. `kind: "spawn"` plus `primary: true`
explicitly sets the initial player spawn; recovery still takes priority.

## Save and verify

Undo/Redo uses Godot's EditorUndoRedoManager. Save writes a versioned AuthoredMap
resource; Duplicate / Save As writes another document. A dirty indicator and
confirmation protect unsaved edits. Seed flower clusters fills empty decoration
cells with deterministic variation and preserves manually painted cells.

Validate checks IDs, bounds, protected destinations and reachability through
authored water/collision/footprints. It is conservative authoring validation;
**Play this map** verifies the full original physics geometry. Resolve warnings
before launching. Play saves no source or player progress: the preview runs the
actual game in a separate isolated userdata directory under the OS cache.

Command-line equivalent (use isolated data when previewing):

```sh
godot --path . res://tools/authored_preview.tscn -- --map=res://data/maps/creative_test.tres
```

Developer resources stay in `res://data/maps`; player furniture layout stays in
GameState's existing save. A game session never writes developer maps. Saving a
test map does not select it as the shipped village: save the intended final map
as `village.tres`, or supply `--map=...` for a preview. The editor's Play launcher
currently uses Linux `/usr/bin/env`; on Windows use the isolated command-line
preview or run the chosen map after setting the override in a development launch.

Evidence: `evidence/creative/studio/map-editor.png` and `authored-runtime.png`.
The editor test paints grass, a curved path and water, places a tree and imported
prop, uses native undo/redo, saves/reloads and starts a second process to verify
imported graphics and actual water collision.

Monsoon Afterglow is now the default village palette and shares the runtime's
clustered meadow and material stamps. New tree proxies use the original
Monsoon broadleaf asset; fixed procedural-tree proxies remain representative,
while Play shows each stable ID's actual family. The World Palette quick buttons
compare Monsoon, Previous coast and Original. Select a palette for a map and
explicitly Save to persist it. Painted tiles retain the existing layer and
collision contracts.
