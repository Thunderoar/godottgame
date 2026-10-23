# Pixel & Animation

Open **Tidesworn → Pixel & Animation**. New creates a transparent 16, 32, 64 or
128-pixel square. Open PNG loads existing artwork; imported frames may be as large
as 512×512. The document supports at most 64 frames and 4,194,304 total pixels.
Undo snapshots are bounded to approximately 32 MiB (plus the redo stack).

Choose Pencil, Eraser, Picker, Fill, Line or Rectangle. Drawing uses integer
coordinates and un-antialiased lines. Select a rectangle, choose Move, then drag
it. Wheel zooms at the cursor; middle drag pans; Pixel grid can be toggled.
Transparency remains transparent in PNG export. Palette swatches are named in
tooltips and recent colours remain available below them.

Pick a source colour, choose a replacement and press Replace picked colour.
Preview palette shows nearest semantic-palette substitutions without changing the
art. Apply commits the preview; Cancel discards it. Named swatches and palette
resource loading/saving live in the World Palette tab, including separate world
and UI roles and an original/revised comparison.

The timeline supports blank frames, duplication, removal, reordering and editable
per-frame durations. Play / pause previews the clip. Import sprite sheet uses the
configured frame width/height; Import PNG sequence sorts same-size frames by
filename. Save As / Export sheet writes a horizontal PNG strip plus
`.png.frames.json` containing version, dimensions and durations. Open a saved sheet
with its frame dimensions to restore the animation. Save retains its existing
path. Unsaved edits require an explicit discard choice when replacing a document.
Disabling/reloading the plugin retains recovery drafts under the dedicated
`user://tidesworn_studio_recovery/` directory; reopening the studio restores them
as unsaved work without overwriting source art.

Register saved artwork adds the actual saved image to the persistent catalog,
with frame dimensions/count/durations. To use it, enter the returned asset ID on
a map object, or rename/configure its explicit runtime override in Asset Library.
Saving an already imported PNG triggers Godot resource refresh and cache
invalidation. Relaunch Play to inspect it in the actual game. Independently
painted images are not automatically recoloured when a WorldPalette changes.

No advanced layers, onion skin, frame tags or Aseprite parser are claimed. The
core tools, PNG round trip, animation timeline and runtime asset connection are
implemented and tested. This is an editor-time tool; exported games do not write
art into their resource pack.

Evidence: `evidence/creative/studio/pixel-editor.png`. Reproduce the automated
workflow with `./tools/test_creative_editor.sh`; it uses both a disposable source
copy and isolated userdata because this workflow intentionally writes assets.

Monsoon source PNGs are available under `assets/authored/monsoon/`. Open an
individual tree, undergrowth, cottage, stall or prop to edit its exact pixels.
The adjacent manifest records dimensions and attachment pivots. Register the
result under an explicit procedural key to use it as a runtime override;
generators remain the master for palette-aware fallback art.
