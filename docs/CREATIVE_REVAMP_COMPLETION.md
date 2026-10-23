# Tidesworn creative revamp delivery

Implementation branch: `feat/tidesworn-creative-revamp`, based on source commit
`0652c65c5b521cbe5c7059b9be3e97d6284a7592` from `visual-overhaul-merge-2`.
Target pull-request branch: `visual-overhaul-merge-2`. Main is preserved.

## Delivered systems

The village now uses fresh semantic grass, warm sand, turquoise/deep-blue water,
terracotta/painted roofs, shutters, flower boxes and original authored planters.
Terrain has coherent meadow variation and material transitions. Foliage is
recoloured from the existing pack without changing original files or forest IDs;
batched grass uses new palette-aware silhouettes. Dungeon floors now use small staggered, theme-tinted flagstones in place of the
inherited oversized grey bands. The beach fringe follows the
inland boundary; the existing full-map water mask, turtle and BESUT remain.

Player walk timing follows actual velocity, including stopping at collision.
Movement tuning is inspectable. Heroes use a shared personality resource with
individual motion details. Residents have occupation tools/poses, dialogue,
proximity greetings and interruptible priorities. Merchants greet nearby players
and react to sales. Pets alternate their walking poses correctly and gain quiet
idle gestures. Enemy visual cadence follows travel speed. Combat damage frames,
cooldowns, targeting, economy, continuous actor coordinates and camera design are
preserved.

The native **Tidesworn** editor workspace contains:

- Asset Library: import/copy, thumbnails, search/categories, provenance and grid/
  animation metadata, preview, semantic overrides, source reimport and diagnostics.
- Map Studio: visual base terrain/object proxies, layered painting, region move,
  object placement/properties, stable base overrides, native undo/redo, save/load,
  duplicate, dirty/locking/visibility state, seeded decoration, validation and
  isolated actual-game preview. Runtime uses TileMapLayer, merged collisions,
  authored object/merchant/route/spawn integration and stable tree HP identities.
- Pixel & Animation: transparent canvases, integer drawing tools, selection/move,
  undo/redo, named/recent colours, palette replacement preview, PNG save/import,
  frame timeline/durations/reordering, sheets/sequences and catalog registration.
- World Palette: editable world/UI semantic roles, palette files and an
  original/revised comparison. Palette changes invalidate generated texture caches;
  independent raster art stays independent.

## Main source files

| Purpose | Files |
|---|---|
| Editor workspace | `addons/tidesworn_creative_tools/plugin.gd`, `studio.gd`, `widgets.gd` |
| Asset authoring | `asset_panel.gd`, `scripts/creative/asset_catalog.gd`, `asset_registry.gd`, `data/asset_registry/library.tres` |
| Map authoring/runtime | `map_panel.gd`, `scripts/creative/authored_map.gd`, `map_renderer.gd`, `authored_sprite.gd`, `data/maps/*.tres` |
| Pixel authoring | `pixel_document.gd`, `pixel_panel.gd`, `creative_canvas.gd` |
| Palette/terrain/art | `palette_panel.gd`, `scripts/creative/world_palette.gd`, `world_terrain.gd`, `data/palettes/*.tres`, `scripts/core/pixel_art.gd`, `shaders.gd`, `ui_theme.gd` |
| Personality/movement | `scripts/creative/micro_action.gd`, `personality_profile.gd`, `data/personality.tres`, `scripts/player/player.gd`, `player_sprite.gd`, `scripts/pets/pet.gd`, `scripts/combat/enemy.gd`, `scripts/world/resident.gd`, `shop_npc.gd` |
| Integration/cleanup | `scripts/world/lobby.gd`, `dungeon.gd`, `forest_tree.gd`, `scripts/game/game.gd`, `scripts/ui/confirm_dialog.gd`, `project.godot` |
| Verification | `tools/creative_checks.gd`, `creative_restart.gd/.tscn`, `test_creative_editor.sh`, `creative_benchmark.gd/.tscn`, `authored_preview.gd/.tscn`, `motion_review.gd`, `tide_test.gd`, `addons/tidesworn_creative_tools/studio_test.gd` |

## Use it

Open `project.godot` in Godot 4.7.2 and choose **Tidesworn** on the editor's main
workspace bar. Enable Tidesworn Creative Studio under Project Settings → Plugins
if it has been disabled.

Import an image in Asset Library, configure its grid and ID, then select Edit
pixels. Save the PNG and refresh/reimport. Place that ID with Map Studio's Place
object tool; paint terrain on the relevant layers, save and use Play this map.
For new artwork, start in Pixel & Animation, save and Register saved artwork.
The shipped `coastal/planter` example is visible in the real village.

Full workflows: [assets](ASSET_WORKFLOW.md), [maps](MAP_EDITOR_GUIDE.md),
[pixels](PIXEL_EDITOR_GUIDE.md), [art direction](ART_DIRECTION.md).

## Verification and evidence

**438 gameplay checks PASS; 63 native UI checks pass; 24 editor checks pass;
separate editor-output restart PASS; exported resource-pack runtime PASS.**
The suite adds 30 checks to the verified 408-check source baseline. A fresh
source-copy import verifies the plugin without relying on the local `.godot`
cache. All mutating tests use isolated user data; editor authoring tests also
use a disposable source copy.

Before/after images: `docs/evidence/creative/before/` and `after/`.
Tool screenshots and authored runtime: `studio/`. Motion MP4, consecutive-frame
crops and numeric analysis: `motion/`. Logs and measured performance are alongside
them. Detailed results, repaired failures and limitations:
[CREATIVE_REVAMP_QA.md](CREATIVE_REVAMP_QA.md).

The software-renderer comparison measured 25.79 → 26.54 ms mean frame interval
and 350.89 → 1,133.41 ms first village construction. The latter is a cold-generation
cost; cached terrain is reused while the palette is unchanged. Real Windows and
Android devices, mobile performance and soak testing remain unverified. Advanced
pixel layers/tags/Aseprite parsing are outside the focused editor. Existing service
placement and the fixed village envelope remain protected architecture boundaries.
The QA report records an intermittent screenshot-tour shutdown ObjectDB warning;
this delivery does not claim every graphical run is warning-free.
