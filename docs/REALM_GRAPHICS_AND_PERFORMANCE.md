# Realm graphics, sea lessons and crowded-night performance

## Presentation

Ten bosses, ten small demons and ten matching arena props now use imported transparent game sprites with rendered material detail. Floor art uses neutral basalt slabs, biome colour, restrained elemental seams and edge depth. Existing portal order, collisions, elemental mechanics and save IDs are preserved. Authored per-sprite rectangles prevent neighbouring sprite fragments, and the final atlases have larger transparent gaps. The new high-resolution atlas regions are scaled to the original world footprints, with linear sampling for these assets only. Explicit AssetRegistry overrides remain authoritative; procedural art stays available if optional imported actor/prop art is missing.

`RealmPresentation` shares imported atlas textures rather than creating a texture per monster/frame. Each ground spell and projectile uses one small shader quad: flames, ice facets, branching voltage, wind/water/soul spirals, earth/root cracks or toxic pools. Amber warnings precede damage; spell ownership, swept projectile collision and damage timers remain gameplay logic. Reduce Motion/Low retains readable static spells and removes optional shader animation. Repeating rune traps also use the shared shader surface. Thin soft impact rings and luminous weapon arcs replace the old filled glow stamps.

Art and the production prompt set: [assets/authored/realms/PROMPTS.md](../assets/authored/realms/PROMPTS.md). Generated with the built-in image tool, copied locally and imported through Godot. No player-facing implementation details were added to the game.

## Sea and village lessons

The sea has no text floating over fish, rubbish, hearts, bombs or sharks. The separate Sea Guide appears after the turtle boards and before the route starts. It explains Pickup/E for every piece of rubbish, automatic fish feeding, dodging bombs and sharks, hearts and fullness. Route time, fullness and hazards wait until Ready. The Sea Guide button reopens the same lesson safely without resetting route progress. Retries keep the acknowledged lesson for that visit; a new sea visit presents it again.

Village potion instructions now explain automatic use at 25% HP. When all lessons in the current phase are complete, the tutorial correctly says to wait for dawn/night; it no longer incorrectly sends an unfinished tutorial into the rescue story or points at a movement control while waiting.

## Night workload

- Fire/urchin target searches run on a staggered 0.22-second clock. Invalid, dead, fallen or sheltered targets are rejected immediately. Movement, collision, damage, attack timers and active boss combat still run every physics step.
- Pack separation samples neighbours every 0.12 seconds and reuses the steering force between samples, with cheap squared-distance rejection and world ownership guards.
- Path searches are staggered; moving destinations must move sufficiently to require another route. Path smoothing tests far visible corners first, reuses its query shape, and still validates collision clearance.
- A blocked villager retries its own route without rebuilding the entire static navigation grid. Real structure/tree/layout edits continue to invalidate the shared planner.
- Daylight/lamp presentation updates at 0.12 seconds. Only the closest four dynamic village lights (two on Medium, zero on Low) render; warm window sprites and ambient night grading remain. Tiny fire/urchin sprites use ambient grading without repeated lantern passes; black shadows and warning decals skip dynamic lighting. The HUD clock updates its label/theme only when the displayed time changes.

## Verification workflow

`tools/presentation_checks.gd` is integrated into the isolated gameplay gate. It covers distinct imported alpha sprites, light budgets, static-grid ownership, sea briefing safety, label-free objects and reopening/resuming the same route. Coastal and movement tests explicitly acknowledge the new sea tutorial.

`tools/review_presentation.ps1` launches a bounded native renderer run with temporary user data and a live-save backup. The scene runs the same 48-monster night workload for 150 rendered frames (30 warm-up, 120 samples), writes median/p95 process and physics times and draw calls, then captures ten active realms/warnings and sea screens at 1280x720 and 832x480. Timings are hardware/load-specific; they are not a promise of a fixed FPS on every device. APK/EXE exports are not rebuilt by this source change.

## Measured evidence

Same AMD Radeon Vega 3 Compatibility renderer, 48 monsters, 120 samples after 30 warm-up frames:

| Metric | Before (ms) | After (ms) |
|---|---:|---:|
| Physics median | 69.188 | 23.610 |
| Physics p95 | 87.579 | 61.830 |
| Process median | 49.737 | 47.048 |
| Process p95 | 74.300 | 96.033 |

Physics median fell by about 66%. Process p95 was higher in this short run, so the evidence establishes reduced simulation cost rather than universally stable frame pacing or a guaranteed FPS. Draw calls in the sampled last frame were 622 before and 612 after. Raw metrics and matching crowded-night captures live in `docs/evidence/realm-graphics-2026-10-28/before` and `after`.

The final sprite pass replaced crowded atlases with spaced v3 sheets and authored per-sprite regions, including separate prop rectangles. Imported atlas boundaries are validated by the acceptance checks. Import-only tests use Godot recovery mode to avoid editor-plugin initialization hanging alongside the live editor; runtime gameplay tests use the normal engine mode. No live editor or player process was stopped.


Final verification: **1,500 isolated gameplay checks PASS, exit 0**, followed by **34 native final-atlas checks PASS, exit 0**. Both final logs contain no FAIL, SCRIPT ERROR or ERROR entries. All ten final realms, clear sprite regions, warning/active spells and the sea tutorial were inspected. Native captures include 1280x720 and 832x480 sea screens. Evidence is preserved in docs/evidence/realm-graphics-2026-10-28/. The final combat fixture waits for transition input unlock instead of racing a fixed loading timer. All saves/captures used verified temporary user data; live save backups were never restored over ongoing play.

## Boss enlargement fix

The legacy Enemy wind-up tween targeted PixelArt.PX regardless of the new atlas sprite's dimensions. Rendering between physics ticks exposed that oversized transform even though the elemental subclass reset its scale on the next physics update. Enemy now owns one cancellable pose tween and resolves rest scale/origin through the actual actor. Elemental art refresh changes the texture without fighting animation transforms. Recovery, stagger and death cancel old poses; lunges restore the authored origin. The regression samples all ten bosses and ten minions during wind-up and interruption.

Boss-size fix verified with 1,520 isolated gameplay checks and 54 native checks, both PASS/exit 0 with clean error scans. Evidence: docs/evidence/boss-size-fix-2026-10-28/.
