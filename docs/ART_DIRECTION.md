# Current direction: illustrated coastal village

This direction applies to **Modern Illustrated** in Settings. **Classic Pixel** is the default; changing the art style requires a game restart.

The 2026-10-29 reference selects clean shaded 2.5D illustration: flat olive grass, soft brown lanes, red tiled timber houses and readable outlined objects. The current library, prompts, integration and native evidence are documented in [ILLUSTRATED_COAST.md](ILLUSTRATED_COAST.md). Imported illustration uses linear sampling with stable logical sizes; the original pixel art and Monsoon palette remain compatible fallbacks. The earlier direction below is retained as historical authoring guidance.

## Earlier Monsoon Afterglow direction

A Malaysian seaside settlement after gentle rain: layered jade forest, mint
leaf tips, turquoise shallows, creamy sand, warm timber and clay roofs. Golden
windows become the evening focal points. The style combines the environmental
layering of Monsoon Cinema, Seaglass Reverie's cool/warm material separation and
Lanterns of the Tide's small inviting lights.

## Shape, pixels and hierarchy

One art pixel is `PixelArt.PX` (1/32 world unit). Use nearest sampling, lossless
PNG, no mipmaps and transparent sprite margins. Keep movement and the camera
continuous; rounding physics coordinates is never a pixel-art technique.

Design silhouette and broad masses first. Use connected pointed leaf sprays,
stepped edges and selective underside shadows; avoid scattered isolated dots.
Ground has quiet broad four-pixel colour regions. Dense detail belongs at tree
bases, gardens and workspaces. Paths, character feet, entrances and enemy attack
telegraphs take priority over decoration. Existing collision footprints remain.

The five forest families are broadleaf, spreading rain-tree inspired, upright
leafy, flowering and coconut. They are stylised original designs, not botanical
species diagrams. Their different frame proportions, branches and crown masses
are authored in `scripts/creative/monsoon_art.gd`. Separate seeded leaf clusters
never consume the world's placement RNG. Split crowns and trunks preserve a
single bottom-centre attachment pivot. Dappled ground shadows belong to each tree
and fall/disappear with it; they add no dynamic lights or per-leaf nodes.

## Semantic palette

`data/palettes/monsoon_afterglow.tres` is the shipped village palette. World and
UI dictionaries remain separate. Previous `coast`, `forest` and `original`
resources remain usable; new roles derive from old roles when absent. Shared
resources are read only during play. Switching a palette clears generated art
and the cached UI theme. Imported PNGs retain their original colours.

| Material | Dark → body → light |
|---|---|
| Forest | `#34695F` → `#4E9988` → `#8FD6B6`, selective `#B9DC88` |
| Meadow | `#5B9583` → `#83B993` → `#A1CFA0` |
| Sea | `#28627E` → `#42A9B7` → `#79DCD6`, foam `#ECF8E9` |
| Timber | `#725448` → `#AD7959`, apricot `#F1B477` |
| Sand/path | wet `#D8B983`, path `#DDC38E`, dry `#F2D9A2` |
| Roof/garden | clay `#CE766A`, coral `#EE8491`, cream `#FFF0C8` |
| Atmosphere | shadow `#34445F`, outline `#273B50`, lantern `#F6C778` |

Do not round resource colours to six decimal places: RGBA8 conversion can
truncate a channel by one. Retain sufficient precision for exact paint swatches.
No palette substitution is silently applied to independent registered art.

## Terrain and water

Terrain and Map Studio share WorldTerrain. Meadows use discrete broad material
regions with quiet short grass near homes, fern/banana-like silhouettes in the
east, clover near the cottage and salty blades near shore. Leaf litter is limited
to forest terrain. Existing path centre lines remain connected; irregular edges,
small compact-earth clusters and ruts replace white speckles.

The original coast function and two-pixel column sampling remain authoritative
for sand, water and collision. Depth shelves, shell groups and broken crests are
baked into the terrain, so Low and Reduce Motion retain complete water. The
optional shader changes colour inside the mask only; it never displaces the
coastline. Crests use two-pixel sampling, no sparkle particles or smooth screen
reflection. Water receives the same canvas ambience as the landscape at night.

## Architecture and workspaces

Homes share long lapped-clay roofs, deep overhanging eaves, ventilated timber
facades, painted shutters, short stilts and a central stair. Each of the five
levels refines the same structure: repaired veranda, flower boxes, porch planting
and finally lantern fittings. Dimensions and interaction/collision anchors retain
the existing contract. This is an original kampung-inspired interpretation,
not a replica of a heritage building.

Market stalls share woven timber counters and sloping cloth awnings. Herbs,
forge coals, pet supplies, timber samples and water-service tools communicate
occupation. Fishing nets, baskets, stacked wood and watering buckets sit beside
existing routines. Shop baskets follow the movable shop group. Decorative props
never introduce hidden collision. BESUT, turtle, jetty and coast remain in place.

## Characters, threats and interface

Preserve the 32×48 hero frame and the three-direction/seven-frame import contract.
Qayyim remains teal, Farhan rust and Ayiz green with an indigo cloak for separation.
The shared cool outline anchors actors against the fresh meadow. Outdoor workers
gain woven hats; work aprons and water-keeper accents identify other occupations.
Ember remains warm orange. None of these changes retime movement, strikes or AI.

Fire monsters retain an ember silhouette; urchins retain spines and gain small
pollution fragments. Existing telegraphs and pooled hit accents remain readable.
Portal themes retain their individual ramps with recessed runes and damp jade
seams. Dungeons continue the stone palette with grouped mineral accents. Teal UI
foundations, warm sand text and apricot borders retain existing controls/layouts.

## Light and comfort

`MonsoonLighting` is a pure mapping from the existing GameState world time.
Day stays fresh; the final 47 daytime seconds warm gradually. The first 13 night
seconds cool toward jade/indigo, and the last 20 seconds lift toward dawn. The
180-second gameplay phases, night waves and persistence are unchanged.

Lantern strength rises across dusk and fades at dawn. Existing small PointLight2D
sources are disabled during daylight and on Low. Separate unshaded window pixels
provide a warm static equivalent on every quality tier. An imported house override
receives no procedural window mask. Trees use baked contact/dappled shadows.
Reduce Motion stops optional wind, water animation and decorative gestures;
static silhouettes, colour, windows and gameplay telegraphs remain.

## Research translated into implementation

- [Godot 2D lighting](https://docs.godotengine.org/en/stable/tutorials/2d/2d_lights_and_shadows.html): retain CanvasModulate with bounded local lights; use baked artwork for persistent canopy shading.
- [Godot CanvasItem shaders](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/canvas_item_shader.html): sample in texture pixels and preserve mask alpha; compile on the installed Compatibility renderer.
- [Godot TileMaps](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilemaps.html): retain the existing TileMapLayer batching for authored terrain.
- [Saint11's original tutorials](https://saint11.art/blog/pixel-art-tutorials/): organise value and silhouette before texture; foliage is connected leaf masses rather than uniform noise. No source pixels were copied.
- [Muzium Negara: Istana Satu](https://www.muziumnegara.gov.my/ms/struktur-istana-satu): reference Terengganu timber architecture and structural supports respectfully. The small village homes borrow material/construction cues without copying a palace or ornamental programme.

See [asset workflow](ASSET_WORKFLOW.md), [QA and delivery](MONSOON_AFTERGLOW_REPORT.md)
and the actual paired captures in `evidence/monsoon/`.

## Kampung compounds

`KampungArt` adds original cached veranda, wakaf, clothesline, banana, drying-rack,
herb, drain-cover, animal-yard and paired sanctuary artwork. Every kind supports
an explicit `village/<kind>` AssetRegistry override. It uses the existing semantic
palette, carries no physics bodies or particles, and remains present on Low and
Reduce Motion. Context and source references: [KAMPUNG_REDESIGN.md](KAMPUNG_REDESIGN.md).


## Approved cottage perspective and material pass (2026-10-29)

Classic Pixel cottages now follow the user-approved front-gable reference: the ridge runs away in screen Y, both roof slopes are visible, and thick front eaves frame a recessed entrance. Do not replace this with a flat front-facing trapezoid roof or an extended right wall. The five visual material grades retain the 224×176 frame, existing scale, centered doorway/steps, collision and saved anchors. Character artwork is unchanged.

`MonsoonArt.house()` owns clustered clay tiles, weathered timber, projected roof glazing, front window details and matching night emission. `MonsoonArt.cottage_ground()` supplies a static soil/stone/planting layer through Lobby's `CottageGround`, clipped on a copied image to water/map bounds and rebuilt only at construction/layout changes. Explicit house overrides and Modern Illustrated do not receive this procedural yard. No terrain bake, map topology, ecology RNG, light budget or game rule is changed. The title backdrop reuses the same cached cottage art.


## Companion market and foliage family (2026-10-30)

The Classic Pixel market now shares the approved elevated view, warm timber and
restrained material ramps with the cottage. Five occupations have distinct pitched
cloth canopies, visible counter tops and useful goods. `PixelArt.stall_texture()`
retains its existing key/override/Modern fallback route; `MonsoonArt.stall()` and
`stall_front()` separate rear art from canopy/counter foreground so the unchanged
merchant remains in the service opening. No NPC sprite or collision is redesigned.

Monsoon tree families retain their native bounds,46-pixel lower split and stable
forest identity, with deeper canopy interiors, warmer/yellow-green upper clusters
and coordinated trunks/palms. Only private decorative image streams are used.
Shop frontage soil/stone/edge details are static child sprites, clipped on copied
images through the same water/bounds helper as the cottage, rebuilt at placement
changes. Imported stall overrides retain presentation ownership. The title reuses
these cached foliage assets and adds one small matching harbour market frontage.
Terrain topology, source bakes, light budgets, actor artwork and gameplay are unchanged.
