# Creative revamp audit

Source: `visual-overhaul-merge-2`, commit `0652c65c5b521cbe5c7059b9be3e97d6284a7592`.
Implementation branch: `feat/tidesworn-creative-revamp`. The source differs from
`main` in 89 files (8,735 additions / 1,987 deletions). No source-branch history
was replaced. Installed engine: `4.7.2.stable.arch_linux.ed1daf0bf`.

Read the repository instructions, README, architecture, overhaul, visual repair,
deep audit and acceptance reports. Inspected game/lobby/dungeon construction,
player/sprite/pet/enemy movement, resident shopping and AStar routes, settlement
placement, PixelArt/IconArt, shaders, camera, settings, theme and VFX pooling.

## Baseline evidence

Fresh isolated import completed. `./tools/test_isolated.sh`: **408 checks, PASS**,
no script errors or failures. Logs: `/tmp/tidesworn-creative-baseline/`.
The isolated graphical tour produced the baseline images in
`docs/evidence/creative/before/`; the larger source tour remains in that temporary
folder. Inspected the village and beach at native 1280×720.

The terrain repeats nine grass-atlas cells and overlays hardcoded olive moss,
sand, path and water colours. Tree sprites multiply RGB by `(0.76, 0.9, 0.74)`;
grass instances multiply already subdued art by roughly `0.62–0.86`. Most roofs
use dark brown/grey. These observed choices reduce separation between materials.
The inland beach fringe was painted near the wet shoreline, rather than at the
grass/sand boundary. Water already has a correct full-map alpha mask; preserve it.

## Movement findings

All actor types already use continuous CharacterBody2D motion. Player acceleration,
braking, normalized diagonals, collision-safe resident waypoint simplification,
pet catch-up and camera interpolation exist and pass baseline tests. No new grid
movement or camera snapping is warranted. PlayerSprite advances a fixed-time
walk cycle regardless of velocity; resident art bobs at a constant time rate.
Pet walk expression returns to frame 3 repeatedly instead of alternating contact
poses. Enemy anticipation, stagger, death and type-specific movement already
exist; retain their timing and combat semantics.

## Authoring gaps and design decisions

SettlementEditor moves registered existing objects and persists player layout.
It provides no terrain painting, asset library or image editor. PixelArt is a
useful fallback, but its unbounded process cache has no imported override contract.

Use named WorldPalette resources for terrain and material generators, a stable
semantic AssetCatalog, and sparse AuthoredMap resources alongside the existing
procedural base. TileMapLayer batches authored overrides; existing forest creation
order and IDs stay intact. Do not migrate player saves or write authoring data
through GameState. Native editor-only panels use standard PNG importing and
EditorUndoRedoManager for map actions. No new autoload is needed.

Godot documentation consulted: EditorPlugin, EditorImportPlugin,
EditorUndoRedoManager, TileMapLayer, ImageTexture, sprite animation and 2D lighting.
The actual installed 4.7.2 compiler and editor are the API compatibility gate.
