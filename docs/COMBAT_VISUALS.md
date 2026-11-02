# Character combat: layered weapon and contact presentation

**Impact follow-up:** the subsequent tactile pass is specified in
[COMBAT_IMPACT_PLAN.md](COMBAT_IMPACT_PLAN.md). It adds visual-only body/blade
contact holds, recoil, directional camera accents and composite audio without
changing the original damage/timing contracts below.

## Intent and boundaries

Make Adam's existing sword sequence readable, tactile and cohesive with BESUT's
pixel/illustrated settings. Effects follow the existing combat transaction, never
create one. No new damage, critical chance, blocking, hitboxes, knockback, cooldowns,
combo windows, save fields or camera trauma are introduced. Arjun/scythe,
Mei Ling/bow and legacy hammer styles have visual profiles in the shared renderer;
this does not change the Adam-only campaign or village-defender ownership.

## Ordered visual plan (implemented)

1. **Anticipation** — a small held edge/glint at the weapon hand. It is deliberately
   not an area-of-effect or enemy-style warning. Direction is latched from the same
   `_attack_dir` used by the combat phase. Wind-up duration comes from AttackDB.
2. **Commitment** — a custom geometry renderer replaces the old expanding texture
   at `Player/Slash`, while preserving its Sprite2D identity for existing probes.
   Left/right cuts sweep in opposite directions with tapered ribbons, dark
   silhouettes, teal midtones, ivory cores and restrained amber trailing edges.
   The sword finisher has a narrow pointed thrust; scythes use lavender, bow
   releases mint, and legacy slams amber. Geometry is bounded by the existing
   attack reach and compressed across the blade plane to protect overhead vitals.
3. **Contact** — the shared HitFeedback pipeline borrows a short-lived contact
   shape: normal radial strike, larger eight-ray critical accent, steel-blue
   broken armor brackets, or coral player-hurt accent. Armor means a boss resisted
   staggering, NOT that damage was blocked. `opts.crit` is supported presentation,
   not a new critical-hit roll; the test fixture explicitly requests that variant.
4. **Follow-through** — the head traverses the authored arc as its tail tapers and
   fades in 0.22 seconds (0.26 for thrust/slam). These are visual durations only;
   AttackDB still owns ACTIVE/RECOVERY timing. Effects never delay the next attack.
5. **Numbers** — pooled numbers now have a dark outline and three small staggered
   lanes so nearby contacts are more legible over bright ground. Existing amounts,
   critical punctuation, rise/fade duration and reduce-motion behavior remain.
6. **Cleanup** — attack cancellation on death/revival clears the weapon visual.
   Actor/world deletion owns ribbon lifetime; world deletion owns contact lifetime.
   Flash tweens are replaced, not stacked, on repeated hits. Contact pool reuse
   resets age, variant, tint, direction, duration and processing without old tweens.

## Ownership and budget

| Owner | Responsibility |
|---|---|
| `Player.try_attack` | Starts the anticipation visual after accepting an attack |
| `Player._show_slash` | Sends the latched aim, weapon style, arc and existing reach |
| `CombatVisuals` | Reusable actor-owned drawing, no damage or movement |
| `Enemy.take_damage` | Passes existing boss armor identity to shared feedback |
| `HitFeedback.impact` | Contact appearance alongside existing sparks/numbers |
| `Player.take_damage` | Local coral cue after existing damage guards |
| `Vfx.contact` / `VfxPool.contact` | Routes to the world's 24 reusable contacts |
| `CombatImpact` | Local held core, streaks/brackets and optional broken halo |

One existing Slash node is replaced in place per character. Each world allocates
24 contact nodes once, then uses a round-robin cursor; saturation replaces the
oldest slot rather than allocating or growing a list. Contacts use no tweens or
scene-tree timers. Visual geometry uses deterministic local calculations, not
random draws that could perturb gameplay RNG. Existing sparks/numbers still use
their established pooled nodes and owned tweens; this is not a zero-allocation
claim about the entire draw/tween pipeline. No performance benchmark is claimed.

## Accessibility and rendering

- **Low:** 12 ribbon segments, no secondary ribbon/glints/halo, four contact rays.
- **Medium:** 20 segments and an amber trail, but no detached glints/contact halo.
- **High:** 28 segments, three edge accents and a short broken contact halo.
- **Reduce Motion:** held direction marks with fading opacity, no moving ribbon,
  contact travel or expanding halo. Essential contact/amount feedback remains.
  Shared flash strength is reduced; existing enemy tint/invulnerability behavior
  remains owned by those actors. Existing camera settings still suppress shake.
- Draw callbacks read live settings, so an active effect adapts without respawn.
- Pixel style keeps hard edges; illustrated style allows antialiased linework.
- No full-screen flash, added camera shake, extra time scale or balance-dependent
  animation delay is introduced by this upgrade.

## Verification routes

`tools/combat_visual_checks.gd` is integrated into `tools/tide_test.gd`. It covers
weapon/style/direction/quality combinations, expiration/cancellation, pool
saturation and reset, rapid-flash ownership, zero-direction fallback, and the
absence of health/damage/position side effects from the new visual classes.

`tools/combat_visual_review.tscn` is an isolated real-renderer fixture. It checks
attack acceptance, anticipation without damage, exact active-frame damage,
unchanged cooldown, Slash compatibility, recovery completion and unblocked armor
damage. It captures anticipation, consecutive cut frames, reverse cut, thrust,
armor, an explicitly requested critical accent, incoming damage, low/reduced
motion, scythe and bow. It also runs 480 actual weapon draw combinations.

Always set both XDG_DATA_HOME and TIDESWORN_TEST_ROOT under a fresh temporary run
root before starting Godot; the fixture rejects non-isolated user data. Run the
canonical `./tools/test_isolated.sh` for the full gate. Render at 1280x720 and
832x480 under Xvfb/llvmpipe on this host; this is not native Windows, physical
Android, touch hardware, exported-build, or performance certification.

The external transaction record contains the pristine project, modified copy,
reconstructable diff, self-contained rollback and literal execution evidence.
