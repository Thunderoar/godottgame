# Asset workflow

Open the Godot 4.7.2 editor and select **Tidesworn → Asset Library**. The plugin
is enabled in project.godot; it can also be toggled in Project Settings → Plugins.

1. Choose a category, then **Import image / sequence…**, or drag project files
   onto the library. PNG, WebP, JPEG, SVG and Godot Texture2D resources are accepted.
   External art is converted/copied into `assets/authored/<category>/` with a
   unique filename. Original files and the TX pack are preserved.
2. Select the thumbnail. Set a semantic ID, source/license description, frame
   width/height, columns, frame count, FPS, margin, spacing and pivot. Save ID /
   override validates the grid against the actual image. Search and category
   filters narrow the browser; Play previews frames. Nearest sampling is used.
3. Place that ID on a map object, or explicitly replace a procedural key:
   `house_1`, `stall_potion`, `npc_fisher`, `icon_flower`, etc. Procedural keys are
   visible in PixelArt.cached_texture call sites. Required missing entries produce
   an error and magenta diagnostic art; optional entries report a fallback once.
4. **Edit pixels** opens a saved image directly in Pixel & Animation. Save,
   then Refresh / reimport. Changes affect the next game launch. The editor
   invalidates both registry and generated texture caches after reimport.

The library is `data/asset_registry/library.tres` (AssetCatalog version 1).
Entries contain a source path and metadata; IDs do not depend on file order.
Runtime uses imported Texture2D resources, including AtlasTexture frames. It does
not read PNG source files or look up files every frame. Authored map sprites
preload clips and respect frame durations. Registry cache: 384 entries; generated
art cache: at most approximately 1,024 entries before reset.

A hero sheet may use `character/qayyim`, `character/farhan` or `character/ayiz`.
The compatible layout is three facing rows (south, north, east), seven frames per
row: four walk poses, stand, blink and hurt. West mirrors east. Configure the full
21-frame sheet, seven columns. This preserves combat frame timing and hero roles.

For a sequence of independent PNG frames, use **Pixel & Animation → Import PNG
sequence**, then export/register the combined sheet. Tile atlases use the same
frame grid, margin and spacing controls. The focused workflow does not parse
Aseprite JSON or animation tags. Standard Godot import settings remain available
in the normal Import dock.

The original `coastal/planter` example was painted with TidePixelDocument and is
used by four actual village objects. PNG sources are independent artwork:
changing a semantic palette never silently recolours them. Source filenames and
provenance remain visible in the library. Check third-party licensing before
sharing imported art; the plugin cannot determine a license automatically.

Evidence: `evidence/creative/studio/asset-library.png`, `pixel-editor.png` and
`authored-runtime.png`. The automated editor runner performs import, grid setup,
editing, reimport and runtime reload in a disposable copy of the source project.
