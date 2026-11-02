# Combat evolution — intent, posing and contact ownership

Implemented against clean `main` source `367e019`, following the researched plan
stored with the external transaction. No new playable hero, dodge/parry, skill,
mana, enemy warning-time reduction, damage buff or global time-scale change.

## 1. Responsive intent

- `Player.request_attack` accepts one expiring **100 ms** request if an attack
  cannot start immediately. A newer distinct press replaces that single slot.
- `try_attack` remains the strict immediate execution API for existing callers.
  The request owner never bypasses phase/cooldown rules or adds hold-to-repeat.
- Keyboard `_unhandled_input`, touch `pressed`, and the existing synthetic
  InputMap polling fallback use `submit_attack_input` to deduplicate the edge.
  Normal release preserves an acknowledged tap; cancellation revokes it.
- A small static diamond on Attack indicates queued intent, not confirmed damage.
- Controls lock, world/dialogue ownership, focus loss, death, revival, sleep,
  journey mismatch, pointer cancellation and world-control release clear/reject
  pending intent. World identity is checked again before execution.
- Bounded opt-in `combat_trace` stores up to 64 request/start/ACTIVE records with
  timestamps, physics frame and attack serial. It is off in ordinary play.

## 2. Remainder-safe timing (intentional behavioral correction)

`_update_attack_phase` consumes elapsed time across at most three phase boundaries
for ONE attack. ACTIVE damage/projectile creation happens once. A large stall
cannot create a chain of buffered catch-up attacks. New cooldown time is reduced
by elapsed time after the actual ACTIVE boundary, rather than starting a full
cooldown at the end of the slow update.

The authored sword wind-ups remain **60/50/90 ms**, active times **80/80/100 ms**,
recoveries **140/140/240 ms**, nominal Adam hit-frame cooldown **380 ms** and combo
window **340 ms**. Damage/range/knockback values are unchanged. Haste still scales
the same gameplay clocks. The next wind-up still takes time after eligibility.

**Do not claim identical realized DPS:** retained early inputs and removal of
lost phase remainders improve practical cadence. Analytical phase-duration tests
allow only one tick of quantization, not an extra tick at every boundary.

## 3. Actual committed attack silhouettes

`PlayerSprite` now owns ATTACK poses. Movement can animate the lower-level actor
without overwriting the committed weapon-facing/pose. Four authored code-native
keys per combo step (load/contact/overshoot/return) support all four logical
facings; left mirrors right where appropriate. Contact holds freeze the full pose
clock, not only its offset. Recovery permits the brief contact/overshoot to finish;
hurt, sleep, death and cancellation take ownership safely.

`CombatPoseArt` supplies stable frame-aware pose keys. Pixel mode extends the
existing procedural character body with stance, arms and blade keys. Illustrated
mode uses a copied, locally deformed version of its existing character image plus
its committed weapon/arm presentation; it is not a newly hand-painted animation
sheet. Both preserve 32×48 logical dimensions, palette/identity and feet. Original
imported source images are never mutated. AssetRegistry can override pose keys.
Current-character poses warm during world construction, not first contact.

## 4. Accepted contact result and explicit world ownership

`CombatHit` adapts the existing duck-typed `take_damage` API, returning accepted
state, actual HP delta, lethal/armor/heavy identity, material, attack ID, victim,
world, normal and contact position. Enemy stores its accepted result once; melee
and arrows reuse it. Rejected/protected/retired-world calls cannot emit success FX.

Contact position is a clamped visible-surface approximation from the actor sprite
and source direction/height. This changes presentation, NOT the existing hitbox or
melee collision geometry. Large actor art uses its visible bounds instead of a
universal `(0,-0.6)` center. It is not claimed to be an exact blade intersection.

HitFeedback routes contacts, sparks, numbers and legacy camera responses into the
resolved world. The existing player melee aggregation still owns exactly one
camera/audio accent per swing. Arrows keep swept collision, pierce accounting,
speed and damage, but use accepted pooled contacts and no longer allocate the
extra impact Sprite2D/tween. Old-world projectiles retire without applying hits.

## 5. Material richness without runaway noise

Flesh/steel/stone/ash contact identities select compact local fragments. They
reuse the existing **24-slot** contact pool; decorative fragments may borrow only
idle slots and are dropped first under saturation, never steal essential contact
cores. Low/Reduce Motion keep essential hit information and skip debris motion.

Stone hits now have a distinct composite response. The existing finite blade
sound set has two prewarmed variants per identity, selected through a cosmetic
counter rather than gameplay RNG. It remains one voice per melee swing. Legacy
hit/aggro/charge voices now also honor effects volume/live mute. Fire-only combat
remains silent, and music/dialogue ownership is not changed.

Camera displacement/hold caps remain from the previous pass; this update does
not inflate camera shake or add fullscreen flashes, zoom pulses or new shaders.
Ground scuffs, haptics, sidechain mixing and subjective user-study thresholds
remain optional future experiments, not claims of implemented features.

## 6. Verification routes and limits

- `tools/combat_evolution_checks.gd`, integrated into `tools/tide_test.gd`, covers
  timing traces at 30/60/120 simulated Hz, oversized deltas, buffer expiry/replacement,
  cancellation, actual touch ownership, both pose providers, pose hold/priority,
  contact data/anchor/world, arrows, priority under pool saturation and sound variants.
- `tools/combat_evolution_review.tscn` supplies paired before/after/rollback inputs
  at 1280×720 and 832×480; `COMBAT_REVIEW_STYLE=illustrated` permits a separate
  illustrated-process review. The older review fixtures account for the corrected
  1 ms elapsed remainder after their 61 ms anticipation sample.
- The external `motion_probe.tscn` records a controlled 90-frame/60 Hz replay with
  three explicit/early requests, actual phased strikes and moving contact poses.
  This is a deterministic renderer replay, not a physical human-input test.
- Always isolate both XDG_DATA_HOME and TIDESWORN_TEST_ROOT before import/test.
  Final commands, outputs, statuses, corrected errors, hashes, reconstruction and
  rollback are in the same four external role artifacts; prior roles are archived.
- Linux headless/Xvfb/llvmpipe validation is not native Windows, real Android/touch,
  audio-listening, physical input-to-display latency or a performance/thermal study.
  No target-device FPS claim is made. No commit/push unless explicitly requested.
