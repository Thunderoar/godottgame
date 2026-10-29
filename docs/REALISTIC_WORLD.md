# Realistic coastal world presentation — 2026-10-28

The village reference directs a realistic coastal kampung presentation: timber houses with tile roofs, detailed market stalls, tropical plants, natural water and warm lamps. Imported prerendered 3D artwork runs in the existing 2D game. Camera rotation, polygonal 3D environments and a new physics engine are outside this presentation change.

## Coverage

- Five distinct home tiers, village houses and all five shop exteriors/interiors/keepers.
- Three heroes with four authored views; residents, workers and eight companion/opponent appearances.
- Five tree families, palms, shrubs, flowers, garden plants, lamps, fences, benches, barrels, netting, boats, jetty and home furniture.
- Underwater landscape, turtle, fish, sharks, whale, diver, mermaid, coral, treasure, wreck and mine.
- Full animal duel arena with realistic companions and a background that fills its panel.
- Kraken body, closed/open prison and fortress floor/pillars. Elemental bosses retain the previous authored realm presentation.

## Source and integration

`assets/authored/realistic/` contains the local image_gen source PNGs, `regions.json`, `PROMPTS.md` and `SUPPLEMENTAL_PROMPTS.md`. The initial text-to-image sheets and later transparency/spacing edits are documented there. Alpha sheets stay transparent; ground materials, interiors and scene backdrops are opaque. `tools/realistic_atlas_regions.py --write` inspects alpha and writes region metadata without changing source pixels.

`RealisticArt` sits behind explicit AssetRegistry overrides in `PixelArt.cached_texture`. Runtime loads imported Texture2D resources, retains their physical pixels and gives normalized ImageTextures their previous logical sizes with `set_size_override`. Actors keep their existing feet, animation scales, collisions and interaction ranges. Direction/frame cache keys share canonical physical views; walking/attack motion uses the existing animation transforms. This is not a newly authored skeletal animation set.

Trees split the same padded physical canvas into exact upper/lower pieces. Tree family selection, persistent IDs, forest fixture order and placement RNG are unchanged. Developer/player settlement positions still resolve through WorldLayout. Terrain materials shade the original map rather than painting a new shoreline or changing collision. Explicit terrain overrides bypass that material. Mirrored material sampling avoids tile seams; the ground atlas uses mipmaps for distant detail.

Lamps use imported silhouettes while retaining bounded existing PointLight2D ownership. Low/Reduce Motion keep static art and terrain. WarmWindows samples the house's own amber windows rather than placing a procedural window mask over imported art. No additional autoload or player save field is introduced.

The home floor keeps a strong Texture2D reference so it remains visible to the renderer. The pet arena background and veil explicitly fill their parent after layout. Kraken art refresh now respects the shared rest-transform pose contract, preventing frame refresh from resetting wind-up scale.

## Reproduction

Use verified isolated user data. The Windows wrappers back up the current Protect Besut save as evidence and never restore over a live game.

```powershell
.\tools\test_isolated.ps1 -Godot <Godot-console.exe> -ImportOnly
.\tools\test_isolated.ps1 -Godot <Godot-console.exe>
.\tools\review_presentation.ps1 -Godot <Godot-console.exe> -Label realistic-final -Scene res://tools/realistic_review.tscn
.\tools\review_presentation.ps1 -Godot <Godot-console.exe> -Label realistic-performance
```

The gameplay gate includes `realistic_checks.gd`: logical/physical texture sizes, distinct house and companion appearances, canonical frame reuse, five exterior/interior pairings and bounded Kraken poses. Native review covers day/night village, market, coast, forest, five shops, home, live animal duel, sea guide/swimming at two sizes and the Kraken island. Construction and worker captures use their actual HousePanel/VillageServicesPanel interaction routes, including upgrade/hire content; the worker panel now includes its matching ShopScene band. Existing Monsoon/World checks continue to enforce tree, override, palette and layout contracts.

## Final evidence

Godot 4.7.2, Windows Compatibility renderer on AMD Radeon Vega 3:

- Reimport completed with clean error scans.
- Isolated gameplay gate: **1,542 checks, PASS, exit 0**.
- Final native realistic review: **26 checks, PASS, exit 0**.
- Native realm/pose/performance review: **54 checks, PASS, exit 0**.
- All stdout/stderr scans are clean of `[FAIL]`, `SCRIPT ERROR` and `ERROR:`.

The crowded-night workload uses 48 monsters, 30 warm-up frames and 120 measured frames:

| Metric | Current run |
|---|---:|
| Process median | 47.015 ms |
| Process p95 | 54.872 ms |
| Physics median | 44.511 ms |
| Physics p95 | 50.669 ms |
| Last sampled draw calls | 494 |

This remains a demanding scene on the Vega 3; these timings do not establish smooth 60 FPS. The earlier presentation run had a lower physics median and higher process p95, so the runs do not support a blanket claim that every frame is faster. Existing light/perception/navigation budgets remain in place; Low and Reduce Motion still disable optional effects. Native captures verify visual presentation on this renderer rather than performance on every target phone.

Evidence lives in [evidence/realistic-world-2026-10-28/](evidence/realistic-world-2026-10-28/): clean logs, raw metrics and actual-renderer PNGs. No player saves or backup files are copied into the repository. No APK/EXE export is produced by this change.
