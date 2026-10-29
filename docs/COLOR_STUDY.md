# Fresh coastal colour study — 30 October 2026

## Scope and method

Revisit all nine files supplied under `/home/roku/Documents/games/tournamentgame/drive-download-20261023T215528Z-1-001/inspo`. Character art remains excluded. Samples are manually selected environmental rectangles; large promo panels, black letterboxing, obvious actors and fighting effects are omitted. All eight frames of `elventales-gif.gif` are included. R03 and R05 repeat a rural-art family and are not counted as two independent style votes. R09 has very little unobstructed environment, so only small background/rock patches are sampled.

Decode screenshot sRGB channels to linear light before conversion to D65 OKLab, then polar OKLCH. Report median lightness L and chroma C per reference, not an average hue of nine unrelated scenes. These are **displayed screenshot samples**, including JPEG/WebP compression and scaling—not the games' original authored palettes, a calibrated display measurement, or a claim about their artists' intent. Hue-shift and hierarchy interpretations below are artistic inferences from the images.

Primary technical basis: [W3C CSS Color 4: OKLab/OKLCH](https://www.w3.org/TR/css-color-4/#ok-lab). UI contrast is checked with linear relative luminance against [WCAG 2.2 contrast minimum](https://www.w3.org/TR/WCAG22/#contrast-minimum); this is a text-pair check, not certification of an entire game interface.

## Observed environmental samples

| Reference | Median L | Median C | Application / inference |
|---|---:|---:|---|
| R01 `eastward-1024x576.webp` | 0.457 | 0.031 | Cool low-chroma structure and shadows support warm surfaces; use depth, not overall dullness. |
| R02 `elventales-gif.gif` | 0.862 | 0.057 | Very light cyan distance; atmospheric air, not a near-white foreground wash. |
| R03 `hqdefault.jpg` | 0.596 | 0.062 | Honey earth and darker warm timber; readable structural value steps. |
| R04 `images.jpg` | 0.540 | 0.032 | Restrained architectural midtones; accents stay local. |
| R05 `maxresdefault.jpg` | 0.621 | 0.076 | Warm yard/building grouping; same rural family as R03, not an independent vote. |
| R06 `maxresdefault1.jpg` | 0.541 | 0.115 | Highest sustained crop chroma; primary guide for fresh green foliage and colourful canopies. |
| R07 `sddefault.jpg` | 0.716 | 0.093 | Sunny yellow-green meadow against honey paths; protect open bright space. |
| R08 `unnamed.webp` | 0.645 | 0.056 | Warm workshop stone/wood against cooler industrial shadows; keep material identity. |
| R09 `unnamed1.webp` | 0.383 | 0.041 | Dark rock/background samples only; retain low-value support for action, not a daytime colour target. |

The important finding is **not** “all references are saturated”: R01/R04/R08 are restrained and R09 is deliberately dark. Our blend takes the fresh meadow/canopy energy of R06/R07, R02's cyan air and cooler distance, R03/R05's warm material grouping, and the quieter structural shadow hierarchy of the remaining references.

## Original palette chosen for this game

- Meadow `#83b993` → `#8fbd55`: OKLCH L about **0.737 → 0.743**, C **0.079 → 0.143**, hue **153.5° → 129.2°**. More yellow-green chroma without bleaching its underlying value.
- Leaves: deep `#285747` → body `#459653` → lit clusters `#a7d960` → sun tips `#d6e97f`. Shadows shift cooler; highlights shift towards yellow. Generated ramps retain ordered linear-light luminance.
- Warm ground: path `#e4bc76`, sand `#f5d795`, edge `#b3935d`; dry surfaces stay warmer than greenery, not the same cyan-green wash.
- Roof `#e78158`, timber `#b77d4b`, cool-plum timber shadow `#654853`. Existing material texture and the approved two roof planes remain intact.
- Water: shallow `#54cfc0` → middle `#279faf` → deep `#235d83`, preserving distinct lightness shelves and warm shore contrast.
- Canopies: teal `#329dab`, coral `#dd7656`, orchid `#9b74b7`, ochre `#c69a4b`, green `#589852`. Cream is shared; each occupation keeps its goods and silhouette.
- UI semantic palette, hero/pet/enemy artwork, actor title tints, day/night grades, and all simulation data are unchanged. Title sky/water/island colours lift the scenic side while the original readability scrim and navigation stay intact.

There is no global HSV filter, shader saturation multiplier, actor recolour, new gameplay RNG draw, new world clock or save field. The existing resource title remains Monsoon Afterglow; this is its fresh-colour revision rather than a new player-facing mode.

## Reproduction and acceptance

The external delivery includes the ROI coordinates, reference SHA256s, complete per-reference metrics, source snapshots, generated swatches, native source patch and a separate-copy rollback. Compare baseline and changed world captures with identical camera, time, zoom, player position and viewport. Inspect 1280×720, 832×480, dusk/night and Low/Reduce Motion. Check silhouette alpha/geometry separately from the newly intended RGB changes. Palette/cache invalidation and terrain-bake signature guards must remain functional. Source bake writes run only in a disposable project with isolated user data.
