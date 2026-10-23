# Original Monsoon Afterglow artwork

These 36 transparent PNGs are production-sized editable exports of original
project code in `scripts/creative/monsoon_art.gd` and `scripts/core/pixel_art.gd`.
No reference-image pixels or downloaded illustrations are included.

Runtime uses palette-aware, cached generators; importing an explicit semantic
override in the Asset Library makes edited raster art authoritative. The adjacent
manifest records attachment pivots, frame dimensions and nearest sampling. Upper
tree parts retain the whole tree's pivot even though their image is cropped;
assemble upper and lower parts at that shared bottom-centre world anchor.
Cottages retain their existing (112,176) attachment anchor.

See `docs/ART_DIRECTION.md` and `docs/ASSET_WORKFLOW.md` for generation, palette,
PNG import, editing and reimport instructions. Re-export only with an explicit
output destination. Master code remains the source for palette-aware variants.
