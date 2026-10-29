# Supplemental realistic source prompts

Mode: built-in image_gen, local source assets. Transparent sheets use RGBA; backgrounds/surfaces use opaque RGB/RGBA. Imported textures retain original physical pixels. Atlas regions are metadata, not edited source pixels.

## trees-pair.png

Mode: text-to-image; transparent_background=true.

Transparent RGBA engine sprite atlas of exactly TWO isolated full tropical trees side by side, NO backdrop or ground. Left: wide lush mature Malaysian rain tree with broad umbrella canopy and visible branching trunk, realistic leaves and roots. Right: lush pink flowering coastal tree with natural thin branches, blooming pink flowers, visible brown trunk and roots. Orthographic elevated three-quarter view, realistic prerendered 3D sunlight and fine leaf detail matching a coastal RPG, not painting or cartoon. HUGE transparent space between the two trees: at least one-third tree width of clear empty air. Complete roots and crown visible, never touching or overlapping and no clipping. Keep large outer margins.

## ocean-background.png

Mode: text-to-image; transparent_background=false.

Wide 16:9 production game background, photorealistic prerendered 3D underwater tropical sea landscape, side-view camera for a scrolling turtle adventure. Clear blue cyan water with long soft sun shafts from the upper left, distant rocky underwater cliffs and gently sloping pale sandy seabed along the very bottom, colorful coral and natural seaweed confined to bottom corners and distance. Large uncluttered blue mid-water area for swimming creatures and readable gameplay, softly graded depth, cinematic refracted sunlight and delicate caustics. No fish, animals, people, text, UI or boats. Not painted, no cartoon or flat vector outlines. Realistic 3D materials with a calm readable composition.

## details.png

Mode: text-to-image; transparent_background=true.

Production game sprite atlas FIVE columns THREE rows, FIFTEEN isolated realistic prerendered 3D props with very large transparent gutters and complete silhouettes. Orthographic elevated front three-quarter view, warm tropical daylight, no background, text, painting or cartoon. Row1 left to right: white village chicken, white duck, grey house cat, friendly tan village dog, small colorful butterfly. Row2: carved timber bed with woven cream blanket, wooden wardrobe with open door and hanging clothes, wooden table with ceramic bowls, carved wooden chair, blue water bucket. Row3: leafy broken tree stump, rolled fishing net, garden watering can, simple rooftop mounted crossbow turret on compact wooden base, pile of discarded plastic bottles and tin cans. Keep every object and animal fully isolated with at least 80px empty alpha between them; no props crossing cell borders.

## kraken-set.png

Mode: text-to-image; transparent_background=true.

Transparent RGBA game sprite atlas exactly THREE columns ONE row with very large empty transparent gaps, physically rendered realistic dark fantasy 3D, elevated front three-quarter camera matching an RPG. LEFT: full enormous indigo blue sea Kraken with fierce eyes, bulbous armored mantle, eight detailed curling tentacles with visible suckers, cyan bioluminescent seams, complete silhouette entirely in its own cell, no background. MIDDLE: an isolated locked dark iron prison cage on small weathered stone base, arched iron top and closed barred front door, no person inside. RIGHT: same cage same size same base but barred door swung open. No floor beyond the small cage bases, no lettering, no text, no painterly/cartoon outlines. Every object isolated with at least 100 transparent pixels between silhouettes and full outer padding. Both cages vertically aligned and identical scale, full tentacles visible.

## gates.png

Mode: text-to-image; transparent_background=true.

Transparent RGBA atlas THREE columns ONE row, three separate realistic pre-rendered 3D fantasy RPG portal stone frames, orthographic elevated front camera, no background or ground plane, no text, huge transparent margins between them. LEFT: tall carved obsidian stone arch with violet crystal details and EMPTY TRANSPARENT opening, monster portal. CENTER: lighter carved stone arch with turquoise crystal and small animal relief motifs, pet battle portal, EMPTY TRANSPARENT opening. RIGHT: weathered dark fortress gate frame with orange lanterns and EMPTY TRANSPARENT opening. Complete full arches and grounded feet inside their own cells. No magical image inside the arch; game engine adds the swirling center. Fine stone material detail, bevels, realistic lighting and no painted or cartoon strokes.

## wood-floor.png

Mode: text-to-image; transparent_background=false.

Seamless square production PBR-style texture of traditional warm weathered Malaysian timber floorboards, orthographic straight-down view, realistic brown wood grain with slightly beveled plank seams and small nail heads, soft neutral illumination and ambient occlusion. Fine physically rendered 3D surface, edge to edge uninterrupted horizontal wooden planks. No furniture, walls, objects, text, borders, vignette or perspective. No painted, cartoon or pixelated outlines.

## household.png

Mode: text-to-image; transparent_background=true.

Transparent RGBA game asset atlas THREE columns TWO rows, SIX isolated realistic prerendered 3D props, elevated orthographic three-quarter camera, warm neutral coastal sunlight, generous clear alpha gutters. Row 1: closed weathered wood treasure chest with brass bands; standing wood weapon rack with a steel sword, scythe and bow; soft round teal woven pet bed with small ceramic water bowl. Row 2: complete full-body healthy brown village horse in calm standing pose; folded fishing net with wood floats; metal watering can. Physically detailed wood, cloth, steel and animal fur, no painted or cartoon strokes. All six entirely separate and fully inside their own cells with large transparent empty outer borders. No text, no scenery or backdrop, no ground plane.

## Sheet cleanup edits

vegetation.png, village-props.png and residents.png received image-to-image background-removal cleanup with transparency preserved. pets.png received an image-to-image spacing pass to separate the ten full silhouettes. ocean-bed.png received the following image-to-image spacing edit:

Edit this existing transparent RGBA sprite sheet into a clean production game atlas. Keep the ten realistic prerendered 3D aquatic assets and their appearance. Re-layout into exactly FIVE columns TWO rows with very generous transparent gaps between every silhouette, preserving each whole object fully inside its own cell. No objects may touch, overlap or cross grid boundaries. Top row: pink coral, orange starfish, treasure chest, open pearl shell, shipwreck. Bottom row: kelp, ruined stone arch, pink anemone, swimming mermaid with full entire tail and hair, scuba diver with full flippers. Especially separate anemone from mermaid tail by plenty of empty transparent air; separate mermaid from diver fully. No opaque backdrop or floor, no text, no grid lines. Smaller objects within their cells are fine; whole silhouettes and clean transparency are essential.
