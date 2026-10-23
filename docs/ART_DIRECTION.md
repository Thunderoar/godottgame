# Pantai: sun-kissed Malaysian coastal fantasy

Warm sand and timber meet cool turquoise water, terracotta roofs, painted shutters,
flowering sill boxes and fresh grass. Dark cool foliage shadows frame readable
heroes and enemies. Paths keep the original access network and gain warm material
contrast. BESUT and the turtle retain their established positions and identity.

`data/palettes/coast.tres` is the default semantic WorldPalette;
`forest.tres` is an area variant, `original.tres` is the baseline comparison.
World and UI dictionaries are separate. Terrain, water, selected foliage,
procedural gardens, houses and new props consume semantic roles. Independent
imported raster assets preserve their authored colours. New art is original code
or user-provided imported imagery; the original TX pack is not overwritten.

The base terrain is shared by runtime and map preview through WorldTerrain.
Composition uses broad coherent meadow fields, sparse clustered blades, connected
paths, pale beach and depth-separated water. Buildings retain their collision
and silhouette footprints, adding painted shutters, warm eaves and planter boxes.

Priority: player/threat silhouettes, then destinations and landmarks, then ambient
detail. No bloom or extra full-screen lights. Permanent daytime remains. Reduce
Motion removes optional pose motion; quality settings retain batched vegetation.

The studio World Palette tab compares original/revised swatches. Save resources
to persist edits; Preview updates the studio and invalidates generated caches.
