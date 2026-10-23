# Visual & Feel Overhaul — Design Doc

Status: repaired on `visual-overhaul-merge-2`. Engine: Godot 4.7.2, GL Compatibility,
1280×720 canvas_items with responsive 832×480 support. The repair report at
`docs/VISUAL_REPAIR_REPORT.md` records current verification. Original design
intent below is superseded by the following camera, effects and ownership fixes.

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

## 2. Camera, pixel art and continuous movement

Default world zoom is 38, matching the wider known-good framing. Settings exposes
28–64 zoom with percentage feedback relative to 38, live smooth transitions and
device persistence across restart and world changes. GUI scale is independent.

Player acceleration/friction and normalized directional input are preserved.
Residents and pets now use collision-aware physics movement, bounded acceleration
and fractional positions. Planning cells guide routes but never become position
assignments. The old pet leash teleport and hard feet-clearance projection are gone.
Player damage uses velocity knockback instead of a positional nudge.

FollowCamera updates in physics and Godot interpolates rendering. Manual camera
art-grid rounding and both canvas snapping options are disabled; nearest texture
filtering remains. Actual rendered baseline images and consecutive 60 FPS movie
frames were inspected. Non-integer zoom naturally changes raster pixel coverage;
logical movement remains continuous and unsnapped.

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
- `effects_quality` ("low" | "med" | "high", default "high") — low drops optional smoke, wind, extra lobby lights and hit-stop; med keeps
  subtle water/wind; high adds small portal motes and optional smoke. Random star
  pollen/butterfly placeholders and water sparkles are removed at every tier.

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

1. **Pixel scale** — resolved by the repair: user-adjustable 28–64, default 38. See §2.
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

Use `tools/test_isolated.sh`; the raw acceptance scene deletes its save. Never
share user data with the real game during automated tests. The suite count is
data-driven; see `DEEP_AUDIT_REPORT.md` for the latest result and additional fixes.
`tools/visual_review.tscn -- --shots DIR` renders fresh scenarios outside res://;
`tools/motion_review.tscn` records continuous movement with Godot Movie Maker.
Both instantiate the actual game and write normal game/settings data, so they
also require isolated XDG_DATA_HOME and verified TIDESWORN_TEST_ROOT. Existing screenshots are historical only.
