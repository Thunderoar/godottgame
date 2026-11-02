# Combat impact pass — weight, contact, response

## Goal and diagnosis

The first visual pass made the existing sword attacks more readable. This pass
makes contact feel physical rather than merely decorative: the attacker, blade,
victim, sound and camera should agree on the moment of resistance.

Observed starting points:

- Blade ribbons faded continuously through a hit, identical in timing to misses.
- The player had no coordinated body follow-through/contact pose.
- Enemy hit-stop affected its animation bob, not gameplay; keep that separation.
- Each enemy could request camera shake and Player requested it again per swing.
- The camera's legacy shake had no original-duration envelope or directional kick.
- Ordinary impacts reused the same short electronic/noisy tone.
- Existing fire-monster silence, dialogue holds, world transitions, and low-motion
  presentation are contracts, not optional polish to discard for spectacle.

## Ordered implementation

### M0 — Preserve the current game

Keep the same checkout and the merged visual pass. Snapshot the actual source,
including the unrelated startup-splash work. Work in the existing external
MODIFIED_FILE role. Archive the previous role contents rather than losing the
first pass's patch, rollback or verification. Change only combat-owned sites.

### M1 — Load the body, then commit

`CombatBodyMotion` is an actor-owned presentation component, added beside the
existing Sprite node on Player and Enemy. It changes only Sprite2D.offset and
skew, preserving their captured rest values. It does not reparent the Sprite,
move a CharacterBody2D, modify collision, or fight existing sprite position/scale
animation and wind-up tweens.

- Wind-up draws back by at most 0.085 world units.
- Ordinary follow-through starts at 0.18 world units and settles over 0.18 s.
- The existing thrust/slam uses visual weight 1.45, settling over 0.24 s.
- Texture-pixel offsets are converted through current sprite scale/rotation so
  procedural and imported actor art receive comparable world-space displacement.
- Lean/skew is small and directional; no new attack frames/art replacement or
  weapon reach is implied. The planted shadow remains at the collision body.

### M2 — Let a successful strike meet resistance

Player resolves its existing damage calls at the same ACTIVE frame. The batch
checks whether an HP-bearing target actually lost HP before declaring contact.
A rejected/protected/stale target cannot trigger a false contact pause.

The weapon snaps to a readable contact sample and holds its art clock for 45 ms
(65 ms for the existing thrust/slam). The attacker holds its follow-through for
the same duration. Misses retain a continuous swing. There is no global time scale,
SceneTree pause, input delay, delayed damage, or frozen attack cooldown. Large
visual deltas consume the hold and advance the remainder, rather than losing time.

### M3 — Make the victim react without changing its AI

A separate sprite recoil travels along the hit direction, then restores exactly.
Bosses use 45% of the ordinary visual recoil; their stagger immunity remains.
Enemy's existing physical knockback, AI state transitions, attack/special timers,
wind-up interrupt rule, collision and rewards are unchanged. Existing animation-
only hit-stop remains; a heavy ordinary hit can hold that visual pose for 50 ms.

Repeated reactions replace the old offset instead of accumulating drift. Death
cancels body recoil before the existing corpse fade/knock-slide. Player death,
revival and sleep clear pending body presentation; dialogue ownership also clears
combat motion while leaving ambient/idle presentation alive.

### M4 — Differentiate impact identities

The existing 24 contact slots are reused, not expanded:

| Contact | Presentation |
|---|---|
| Ordinary | Directional ivory fracture with a dark contrast edge |
| Finisher | Larger warm-gold fracture, pressure-front arc, longer visual hold |
| Armor | Steel-blue brackets and restrained victim recoil |
| Lethal | Distinct gold defeat accent alongside existing death presentation |
| Critical | Existing explicit critical styling; no new roll/multiplier |
| Incoming hurt | Local coral strike mark; existing damage guards still own it |

The finisher pressure front is art, NOT an area-damage shockwave. The sword's
third step is more emphatic, not more damaging. Only confirmed strikes show the
additional solid blade edge/contact color. Ordinary number labels briefly punch
up by 22%, then settle in 0.1 s; the existing 0.6 s lifetime is retained, with a
short opaque beat before fading. Reduce Motion/low quality skip the number pop.

### M5 — One camera accent, not a pile of shakes

Player owns one presentation batch per melee swing. Enemy feedback suppresses
its individual camera/death-hit voice only while that explicit batch owns it.
Direct damage, allied hits, and arrows outside that batch retain legacy ownership.

`Vfx.camera_punch` routes only into the source's current world. One accepted
swing produces one directional damped kick, regardless of target count. Strength
is capped rather than accumulated. Legacy noise now decays against its original
duration; combined offset is limited to 0.08 world units. Expiration returns to
exact zero, including a delta larger than the entire effect.

No zoom pulse, camera movement amplification or full-screen flash is introduced.
Screen Shake off / Reduce Motion clear active feedback immediately. A lightweight
presentation callback clears a kick if dialogue suspends camera physics, avoiding
a stranded offset throughout a conversation. Retiring worlds cannot punch the
new world's camera.

### M6 — Give the hit a body and a material

Five original mono 16-bit/22.05 kHz PCM sounds are cached before combat:

- `blade_swing`: quiet filtered-air pass for a miss.
- `blade_hit`: short crack, low body and a restrained metal edge.
- `blade_finish`: lower, longer body for the authored thrust/slam.
- `blade_armor`: brighter inharmonic metal response.
- `blade_defeat`: weightier low transient for a lethal swing.

Each is one composite voice, not stacked players per target. Actual melee kills
suppress the old per-corpse hit voice so multi-kills still produce one accent.
Fire-only hits stay silent. Mute/Master behavior is preserved; the new voices also
honor effects volume and stop when it is set to zero live. Synthesis uses a local
deterministic noise generator, never gameplay RNG. Sample endpoints are softened
and amplitude is bounded; no claim of subjective listening or device-latency QA
is made from numerical waveform checks alone.

## Accessibility, lifecycle and cost

- Low effects / Reduce Motion: no body displacement, lean, or contact holds;
  essential directional contact, amounts and existing hit timing remain readable.
- Live setting changes release holds/offsets; old motion does not resurrect.
- Nodes inherit normal world processing. Deliberate cinematic suspension retains
  its existing ownership. Dialogue clears transient combat presentation only.
- One reusable body component per actor; no per-hit body node/timer/tween allocation.
  Contacts remain bounded at 24. Existing pooled sparks/numbers still use tweens.
- Camera strength is bounded, audio has a finite cache/pool, and there is no global
  slow motion. These are design limits, not a measured phone/FPS benchmark.

## Verification and acceptance

1. Run the same isolated rendered input against baseline, modified and rollback.
   Confirm exact damage/cooldown/phases and report the observed feedback pipeline.
2. Capture consecutive impact samples at 1280x720 and 832x480 with identical camera
   framing. Sample camera displacement separately so static comparisons are fair.
3. Exercise 480 weapon/style/direction/quality draw combinations.
4. Run combat_impact_checks through combat_visual_checks in the canonical gate:
   recoil restoration, holds/whiffs, exact-rest camera envelopes, low/reduced mode,
   live toggles, multi-target/multi-kill aggregation, fire silence, dialogue and
   stale-world ownership, unchanged damage/timers and safe cached PCM samples.
5. Build a native reconstruction patch and a self-contained rollback. Execute the
   rollback on a separate modified copy, verify pristine source hashes, run the
   same input, then reapply the candidate bytes.
6. Apply only scoped verified changes to the working checkout. Recheck unrelated
   startup work and run isolated runtime validation before claiming completion.

The existing four absolute role paths remain canonical. Prior role contents are
preserved under this pass's PREVIOUS_ROLES directory. The latest patch and default
rollback target this impact pass's starting source (the first visual pass remains
intact); the original visual-pass rollback is retained in that history.

Linux Xvfb/Mesa llvmpipe rendering is not native Windows, physical Android/touch,
export, soak, listening, or performance certification. Final literal commands,
stdout/stderr, statuses, source hashes and corrections belong in VERIFICATION.txt.
