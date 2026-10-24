# Map Studio upgrade — 24 October 2026

The user redirected the next village-layout pass into a substantial native editor
upgrade so they can shape the map themselves. No shipped village placement,
world bounds, forest fixture, player save field or gameplay rule was changed.
The working baseline was `ab3affc` on `codex/kampung-world-redesign`.

The practical workflow is in [MAP_STUDIO_GUIDE.md](MAP_STUDIO_GUIDE.md).

## Delivered workspace

- Three-part workspace: searchable Scene/Assets/Layers sidebar, pannable canvas,
  and contextual Inspector/Issues sidebar. Canvas-only mode expands the map view.
- Direct selection of complete building plots, authored objects and spatial
  geometry; constant-screen-size handles; offset-preserving dragging with an
  uncommitted outline preview. Terrain is regenerated on commit, not each drag.
- Exact world position controls and quarter-unit keyboard nudges. Existing shops
  and cottage can be moved through their canonical anchors in the editor.
- Road endpoints, width, hierarchy, material, soft edges, and bend insertion/removal.
  District creation, duplication, vertex editing/removal, ground/density controls,
  blend width and tint. New commons/routing landmarks connect custom road networks.
- Optional district-with-contents movement carries assigned anchors, accessories,
  local workspaces, authored props and in-polygon road bends as one undo action.
- Scenery owners, local offsets, footprints and scale; existing actor workpoint
  handles, anchor assignments, added destinations and guarded point removal.
- Searchable real asset thumbnails; placed-prop duplicate/delete with stable new
  IDs; manual imported-art refresh; original-tree edits as stable-ID overrides.
- Undoable tile-layer visibility and locks; native undo/redo with saved-state dirty
  tracking and document guards. Derived texture caches are excluded from snapshots.
- Issues that locate affected features; new polygon and road-endpoint diagnostics.
  Save & Play saves, then launches an isolated runtime even with authoring warnings.
- Clear Fit/Frame/Grid/Guides controls, keyboard shortcuts and gesture cancellation.
  Static preview now includes portal composites, fence runs/gaps and animal positions.

The old point selector is retained under Advanced point tools for compatibility.
Existing pixel editing, palette editing, importer, undo integration and plugin
recovery remain intact. No editor class is referenced from gameplay scripts.

## Actual native screenshots

The [previous editor](evidence/district-spacing/editor/map-editor.png) required
bottom dropdowns for layout selection. These screenshots are from the upgraded
Godot main workspace on the actual GL Compatibility renderer under Xvfb:

| View | Evidence |
|---|---|
| Building selection and numeric Inspector | [image](evidence/map-studio/after/workbench-building.png) |
| Road endpoint and bend editing | [image](evidence/map-studio/after/workbench-road.png) |
| District shape and blend settings | [image](evidence/map-studio/after/workbench-district.png) |
| Full workspace overview | [image](evidence/map-studio/after/workbench-overview.png) |
| Canvas-only overview | [image](evidence/map-studio/after/workbench-canvas-only.png) |
| Independently saved map in real gameplay | [image](evidence/map-studio/after/workbench-runtime.png) |

These are deliberate authoring test maps. The moved workshop intentionally
triggers a conservative spacing warning, demonstrating that unfinished maps
remain inspectable. They are not changes to the shipped village.

## Verification

- Isolated source import: clean.
- `./tools/test_isolated.sh`: **898 checks, PASS**, exit 0, no `[FAIL]`,
  `SCRIPT ERROR` or `ERROR:` markers. This includes unchanged forest associations,
  complete default terrain RGBA parity, navigation, combat, economy and saves.
- `./tools/test_creative_editor.sh`: **84 checks, 0 failures**, exit 0, in a
  disposable source checkout. Original pixel/import/palette/recovery checks and
  the new direct editing gestures run inside the real native editor.
- Separate **creative restart PASS** verifies the original authoring workflow.
- Separate **workbench restart PASS** verifies actual shop owner placement, new
  commons/road/district, saved blend settings, resident workpoint ownership and
  the placed bench in a fresh game process.
- Native screenshots inspected at building, road, district and overview scales;
  canvas-only mode gives the full map a larger view. `git diff --check`: clean.

The 47 added editor checks exercise mouse/key input handlers, an uncommitted
drag and Escape, native undo/redo, numeric positions, nudges, framing, scene/asset
search, placement/duplication/deletion, forest overrides, geometry point edits,
district contents, routines, layer controls, paint/pan cancellation, protected
identity deletion, validation selection, save/reload and stale undo isolation.
The five added gameplay checks inspect generated blend/road pixels and terrain
cache signatures. They verify presentation without changing navigation widths.

One intermediate native run crashed with signal 11 during the existing image
reimport workflow, before map tests. Its log is retained. Subsequent complete
editor runs and both runtime restarts pass; no engine fix is claimed. Xvfb's
input-method and unsupported V-Sync warnings remain environmental. Final delivery
logs are checked independently from the retained intermediate failure log.

## Ownership and limits

Map Studio edits a private source copy and embeds customized WorldLayout data in
the saved AuthoredMap. Original service/actor IDs are retained, and work routines
keep at least one point. Original forest IDs are never regenerated. Explicit
player placements still win in normal gameplay; previews use isolated progress.
No automatic terrain-bake write occurs. Optional blend keys are included in cache
signatures only when authored, preserving unchanged default bake hashes/pixels.

The envelope remains 64 × 40. New commons are routing landmarks; asset-palette
houses are visual authored objects. Creating new functional service types,
campaign portals, NPC roles or species remains content/code work. Building
footprints describe reservations, not automatic collider resizing. Static preview
approximates ruin damage and omits live lighting/NPC simulation; use Save & Play
for exact behavior. District moves retain the fixed forest rather than moving
its persistent trees implicitly. Input testing uses native handlers under Xvfb;
physical touch hardware, native Windows and long human authoring sessions remain
unverified.

Primary implementation: `map_workbench.gd`, `map_panel.gd`, `creative_canvas.gd`,
`AuthoredMap.snapshot/restore`, optional WorldLayout/WorldTerrain blend data,
`map_workbench_test.gd`, `creative_workbench_restart.*`, and the isolated runners.
