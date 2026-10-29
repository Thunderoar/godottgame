# Illustrated coastal presentation — 2026-10-29

The current visual direction follows the user's latest village reference: quiet olive meadows, warm brown paths, pale sand, red tiled timber houses, clear silhouettes, gentle shaded volume and restrained outlines. The 2.5D illustration style replaces the previous photographic surface treatment.

After integration with the selectable-art update, this library belongs to **Modern Illustrated**. **Classic Pixel** remains the default and uses procedural art with nearest filtering. Choose Art style in Settings and restart to apply it; the active family stays fixed during a session. Village terrain, home/realm/island floors, ocean backgrounds, pet arena and map filtering follow that choice. The historical results below predate this integration.

## Coverage and ownership

`assets/authored/illustrated/` owns the new local source artwork: houses/stalls, village props, foliage, heroes/residents, furniture, pets, marine life, ocean scenery, interiors, portal arches, Kraken/prison, ten bosses, ten minions and themed realm props/floor. `PROMPTS.md` records the exact built-in image_gen edit prompts and original local sources. The previous realistic/realms folders remain source history. Alpha is preserved for sprites; rooms and backgrounds are opaque.

`RealisticArt` keeps its compatibility name and public API, but selects the illustrated library. It preserves original logical dimensions with size overrides, canonical frame sharing and exact tree upper/lower reconstruction. Dynamic atlas metadata replaces old photographic rectangle coordinates for elemental actors/props. New regions are authored with `tools/illustrated_atlas_regions.py --write`, which inspects alpha and writes JSON without editing pixels. Explicit AssetRegistry overrides remain authoritative.

Village ground uses `illustrated_terrain.gdshader` over the existing authoritative terrain texture. Broad grass/dirt/sand shapes keep the original path and shoreline geometry; photographed grass/noisy repeating ground is removed. The material samples only the authoritative map and uses static colors and sparse flecks. It does not consume placement RNG or alter sea collision. The expanded map's background uses the same village material; markers draw above it. Map still appears only after pressing Map.

The existing live clock, light budget and Low/Reduce Motion controls retain ownership of night lighting and optional animation. House windows sample their own artwork. Character feet, combat scales, saved progression, tree IDs/order, player layout, movement, rewards and attack timings retain their existing contracts. No new autoload, save field or physics world is introduced.

## Verification

Run the isolated import/gameplay wrappers and the existing native review scenes:

```powershell
.\tools\test_isolated.ps1 -Godot <Godot-console.exe> -ImportOnly
.\tools\test_isolated.ps1 -Godot <Godot-console.exe>
.\tools\review_presentation.ps1 -Godot <Godot-console.exe> -Label illustrated -Scene res://tools/realistic_review.tscn
.\tools\review_presentation.ps1 -Godot <Godot-console.exe> -Label illustrated-realms
```

The compatibility-named realistic checks validate illustrated style routing, logical sizes, frame sharing, house/pet diversity and bounded Kraken poses. Presentation checks verify all twenty elemental sprites and pose regressions. Existing Monsoon/World checks still enforce tree fixtures, exact split pixels, palette invalidation, overrides and static geometry. Native review covers day/night village, coast/forest, five real shop routes, home, expanded map, animal duel, sea guide at two sizes and Kraken. Realm review covers all ten bosses, warning/active spells and the crowded-night workload.

## Final results

- Reimport completed with clean error scans.
- Isolated gameplay gate: **1,544 checks PASS, exit 0**.
- Native village/shops/sea/map/duel review: **27 checks PASS, exit 0**.
- Native realm/pose/performance review: **54 checks PASS, exit 0**.
- All final stdout/stderr scans are clean of `[FAIL]`, `SCRIPT ERROR` and `ERROR:`.

Native inspection caught neighboring fin/tail fragments in the first marine sheets. Image_gen spacing edits separated their rectangular crop areas; the final captures show the complete whale, diver and mermaid without neighboring sprite fragments. Separate framing edits preserve full tree crowns and boss weapons. Atlas metadata was regenerated and the affected resources reimported before final validation.

The 48-monster crowded-night workload on AMD Radeon Vega 3 Compatibility renderer, after 30 warm-up frames and over 120 measured frames, recorded:

| Metric | Current run |
|---|---:|
| Process median | 40.419 ms |
| Process p95 | 58.435 ms |
| Physics median | 38.900 ms |
| Physics p95 | 51.869 ms |
| Last sampled draw calls | 467 |

These remain hardware/load-specific measurements, not a 60 FPS guarantee. Low/Reduce Motion and the existing bounded light/perception/navigation work remain available. Final logs, raw metrics, village/shop/sea/map/duel captures, all ten boss wind-ups and warning/active realm captures are preserved in [evidence/illustrated-coast-2026-10-29/](evidence/illustrated-coast-2026-10-29/). No player saves or backups are copied into the repository.

Twenty-one PNG sources and their prompts live in [assets/authored/illustrated/](../assets/authored/illustrated/). The generated sources use the built-in image_gen tool; `PROMPTS.md`, `SPACING_PROMPTS.md` and `MARINE_SPACING_PROMPTS.md` preserve the full prompt set. No APK/EXE is rebuilt and no Git commit/push is included in this visual edit.

## Selectable-style integration verification (2026-10-29)

With upstream 96c5fc3, fresh isolated Windows gameplay gates pass 1,837 checks in each art mode. Native style/startup reviews pass 32 checks per mode, and the native Modern Illustrated world review passes 27 checks. All exit 0 with clean failure/error scans; the import separately reports a missing Android build-tools directory. See the integration section in [ACCEPTANCE_TESTS.md](ACCEPTANCE_TESTS.md) for scope and limits.

The standalone review wrappers create fresh settings and therefore now start Classic Pixel. For illustrated captures, select/persist modern before launching the review scene in the same verified isolated user-data directory, following the selectable-style restart example in ACCEPTANCE_TESTS.md. Never seed or overwrite normal player settings to run a review.
