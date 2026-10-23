# Visual & Feel Overhaul — Design Doc

Status: in progress on branch `visual-overhaul`. Engine: Godot 4.7.2 (GL Compatibility,
1280×720 landscape, `canvas_items` stretch, nearest filtering, 2D pixel snapping ON).

## 1. Art direction

- **One pixel language.** All new art is procedural, generated through `PixelArt` /
  new `IconArt` / `Shaders` static factories with stable cache keys. Nothing is imported
  from outside the existing TX asset pack.
- **Outline rule.** World-space creatures keep the existing soft `PixelArt.OUTLINE`
  silhouettes. UI icons at 32×32 get a 1px dark outline, 3-tone shading and
  top-left lighting (see `scripts/core/icon_art.gd`).
- **Light.** Permanent daytime stays. The lobby grade moves from the current
  neon lime cast to a natural, slightly desaturated green with warm highlights and
  cool shadow tints (terrain `modulate` + overlay re-grade). No day/night cycle.
- **Animation frame counts.** Player walk = 4 frames per facing (contact/pass ×2),
  idle = 2 frames + breathe. Enemies = 4 walk frames + windup/hit poses. Pets =
  idle/walk (4) + attack/hurt/happy/sleep poses. Shopkeepers = idle bust with
  blink + tool motion. Portal interiors = 8 baked swirl frames cycled at 10 fps.
- **Icon sizes.** 16×16 (unchanged, existing callers) and a new native 32×32 set.
  Touch buttons draw the 32px icon at an integer scale; inventory/shop cards use 32.

## 2. Pixel-scale decision (superseded: user-adjustable zoom)

The overhaul shipped a fixed integer 2:1 scale (`zoom = 64`). The repair pass
replaced the fixed constant with a **user setting**:

- `FollowCamera.DEFAULT_ZOOM = 40` — the classic village framing (view ≈ 32×18
  world units), chosen as the default after comparing with the pre-overhaul
  branch; 64 proved too close for ordinary play.
- `GameSettings.camera_zoom` (int, 70..160 % of the default, persisted in
  `user://settings.cfg`) drives every world's camera; each `FollowCamera` eases
  toward the target zoom so Settings changes glide.
- The camera rounds its position to the 1/32 art grid **only** when the
  effective zoom renders one art pixel at a whole number of screen pixels
  (e.g. the crisp 2:1 look at 64); at fractional scales the engine's
  `snap_2d_transforms_to_pixel` keeps rendering crisp without whole-art-pixel
  stepping. `snap_2d_vertices_to_pixel` is OFF (double snapping caused jitter).
- Equal x/y zoom always — no distortion. Camera zoom never resizes the HUD.

## 3. Performance budget (Android, GL Compatibility)

- Cap `PointLight2D` per screen (~3 for portals/torches; existing dungeon lights are
  already sparse and are being kept).
- `CPUParticles2D` only (no GPU particles).
- VFX (sparks, rings, dust, damage numbers) come from a small pre-allocated pool
  (`scripts/core/vfx.gd`) — no per-hit node churn.
- Grass/foliage renders through a shared `MultiMeshInstance2D` per texture variant
  with a shared wind `ShaderMaterial` — one draw call per variant, per-instance
  colour jitter, sway computed on the GPU from `MODEL_MATRIX` phase (no per-instance
  uniforms, which are unverified on the Compatibility renderer).
- No per-frame `Image`/`Texture` creation; no `get_nodes_in_group` in hot paths
  (cached with a refresh timer).

## 4. Quality & accessibility switches

New `GameSettings` keys (sanitised, persisted in `user://settings.cfg`, exposed in the
Settings panel):

- `reduce_motion` (bool, default false) — disables hit-stop, screen shake, camera
  look-ahead, wind interaction bending and ambient drift.
- `effects_quality` ("low" | "med" | "high", default "high") — low drops ambient
  life, wind interaction, extra lights and hit-stop; med keeps wind but drops
  ambient particles; high keeps everything.
- `camera_zoom` (int, 70..160, default 100) — percent of `FollowCamera.DEFAULT_ZOOM`
  (40); eased live, persisted across restarts and world switches.
- `ui_scale` (int, 75..130, default 100) — the single GUI-scale authority. The HUD
  scales its root from the top-left and divides its layout rect by the factor so
  edge-anchored controls stay glued to the screen; a legacy save-file scale value
  is migrated once.

Telegraphs never rely on colour alone (shape + motion: ground decal + wind-up pose +
flash). Touch targets stay ≥ 44px. Text contrast stays on the `GameUI` palette.

## 5. Feedback rules (local, not toast)

`toast_requested` has 45 emit sites and zero listeners, and `GameHUD.show_toast()` is
deliberately a no-op (tests assert `_toast_box == null` forever). Every new feedback
surface is therefore **local to the panel or world object that produced it**:
shop buy/sell feedback animates inside `ShopPanel` (coin arc, number tick, card pop,
keeper reaction line + emote, shake on failure); combat feedback goes through the
shared `HitFeedback`/`Vfx` helpers (flash, sparks, damage numbers, micro-shake).

## 6. Decisions needed from the owner

1. **Pixel scale** — shipped at 2:1 (`zoom = 64`, hero 64×96). Alternative 1:1 is a
   one-constant change. See §2.
2. **Sword combo chain** — implemented as a 3-step animation chain (swing L→R,
   R→L, thrust) where every hit frame is still gated by `attack_cooldown`, so DPS is
   unchanged; treat as presentation. Flag: `AttackDB.ENABLE_SWORD_COMBO`.
3. **Forest trees** — already resolved by the owner in the current repo state:
   trees have HP, fall at 0, and all-dead triggers Game Over (suite is green on
   this). README still claims invulnerability and is corrected in this branch.
   No tree damage logic was touched.
4. **Orphaned `PauseMenu` / `ConfirmDialog`** — 615 + ~200 lines, referenced by
   nothing (no `pause_menu` action, no wiring in `game.gd`). Per the task rules this
   branch does NOT wire it in. Recommendation: either wire it (needs an owner call
   on pausing during emergencies) or delete it.
5. **`RECOVERY_SECONDS` gameplay bug — fixed in the follow-up commit.** The
   recovery ward now heals at `GameState.sleep_recovery_seconds()` (the
   HouseDB `recovery_time` per cottage level, 10→2 s), matching the bed and
   the `HousePanel` progression; the hardcoded 8.0 s const was removed and the
   suite asserts the HouseDB rate.
6. **`upgrade_pet` cost duplication** — consolidated behind
   `GameState.pet_upgrade_cost(level)` (formula unchanged: `45 + level * 35`). Safe
   consolidation, explicitly allowed by the task.
7. **Open question kept open** — `export_presets.cfg` is gitignored and absent from
   the repo (AGENTS.md gotcha 14); both export presets are effectively lost for
   fresh clones. Recommend un-ignoring and committing a preset.

## 7. Verification

- `tools/tide_test.tscn` remains the only gate: **361 checks, PASS, exit 0**
  after the repair pass (46 dedicated visual-repair regression checks were
  added). The bar for this branch: no new failures, no `SCRIPT ERROR` /
  `ERROR:` lines.
- `tools/visual_review.tscn` (new, non-destructive) renders fixed scenarios
  (title, lobby, dungeon, each shop, portals, HUD at 1280×720 and 832×480) to PNGs
  under `/home/z/my-project/shots/` without ever calling `delete_save()`.
- Attack-timing rule change (damage lands on the active frame, not on button
  press) is reflected in updated waits inside `tide_test.gd` and documented in
  `docs/ACCEPTANCE_TESTS.md` in the same change.
