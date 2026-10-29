# Sea urchin animatic and animation beats

2026-10-30. Source audit at `b2b3b10`, with unrelated objective-tracker work
present in the working tree. This document adds a design proposal only.
The night schedule in `NIGHT_ENCOUNTER_PLAN.md` is also still a proposal.

Implementation update: the arrival presenter, pixel poses, one-time story
ownership and repeat warnings are now implemented. See `SEA_URCHIN_ARRIVAL.md`
and the newest acceptance entry for shipped scope and actual verification.
The storyboard below records the design; randomized night profiles remain future
work and are not implied by the arrival implementation.

## Dramatic purpose

Introduce a small, stubborn physical threat arriving from the sea. Its arrival
should establish origin, personality and danger through action: the water stirs,
spines break the foam, an awkward little creature finds its footing, then turns
its attention inland. The comic beat is brief; the physical threat remains real.

Use the existing violet/indigo spiny silhouette, pale yellow eyes and tiny
pollution fragments. The can caught in its spines is a character detail already
present in the procedural sprite, not a reward item or an origin explanation.
Do not imply that uncollected rubbish creates monsters. No new villain dialogue,
captor connection or ecological backstory is established by this sequence.

Build this as original pixel animation within the actual village shoreline.
No imported character portraits or separate illustrated reference family are
needed. Keep the eyes legible and the overall silhouette readable on sand at
night. The urchin should feel small in the world, not framed as a giant boss.

## What exists today

- `PixelArt.enemy_texture("urchin")` draws a 32-by-32 spiny violet body, yellow
  eyes, a crushed can and a tiny bottle-like fragment, with two movement frames.
- `Enemy._ready()` uses a generic 0.35-second fade. Urchins have no dedicated
  movement personality in `_personality_for()` and share the generic attack pose.
- Ordinary urchins have 30 HP, 6 damage and speed 1.35; emergency urchins have
  60 HP, 9 damage and speed 1.75. Animation must preserve both sets of stats.
- Melee uses 0.42-second WINDUP, 0.14-second ATTACK and 0.5-second RECOVER.
  Damage resolves once on the first active frame. A hit during windup can stagger.
- Urchins physically target buildings, mature trees, exposed residents and Adam.
  Sheltered/dead residents are excluded. Trees take physical damage, without fire.
- Enemy bodies collide with world geometry, not with the player. Spines are not
  currently a passive contact-damage aura or a projectile attack.
- The painted sea is world collision. `safe_spawn()` searches land but can return
  its original fallback point on failure: a cinematic needs explicit final-point
  validation rather than assuming its return value is always valid.

## Two presentation lengths

The first eligible scheduled shore arrival gets a one-time, approximately
8-second in-engine introduction. Later batches use an 8-second environmental
warning with ordinary play continuing, followed by the short existing spawn
settle. Never play the full introduction per individual enemy or every night.

The night plan decides whether an arrival exists. Presentation cannot manufacture
an arrival on a quiet/forest-only night, reroll a skipped batch or add enemies to
improve the composition. The schedule and its saved batch count stay authoritative.

### First-arrival storyboard — proposed 8 seconds

| Time | Picture and action | Rhythm / sound | Information conveyed |
| --- | --- | --- | --- |
| 0.0–0.8 s | Ease to a modest close view of the real shore. A narrow foam line moves against the ordinary surf rhythm. | Low shore wash; no loud alarm or dramatic score sting. | Something is approaching from the sea. |
| 0.8–2.0 s | Two or three spines interrupt the foam. Pause just long enough to read the silhouette; a small can edge catches the light. | A tiny metallic tick, then a short still beat. | A physical, spiny creature is arriving. |
| 2.0–3.2 s | The lead urchin crests the shore, turning from a low spiny silhouette into its rounded body. Water slides off; its shadow becomes grounded on sand. | Soft splash and two small sand taps. | Its body has weight and the sea-to-land transition is clear. |
| 3.2–4.6 s | It almost overbalances, checks itself with a short sideways step, and settles. The lodged can rattles once. | One small comic pause; no prolonged gag. | Stubborn and slightly awkward, rather than majestic or terrifying. |
| 4.6–5.8 s | Its eyes shift inland. The body lowers a little and its forward spines present toward the village. | Brief quiet; an optional restrained dry tick. | Its attention changes from arriving to threatening. |
| 5.8–7.0 s | Only the other members actually allocated to this batch appear behind it, offset in time and space. A one-enemy batch remains one enemy. | Staggered little taps; avoid identical synchronized movement. | This is the arriving group, with a readable count. |
| 7.0–8.0 s | Restore the gameplay camera. Match the final preview poses to validated land positions, replace previews with real enemies, then release the world. | Shore ambience returns to its normal level. | The introduction flows into the actual encounter. |

No attack, tree damage or resident injury occurs inside the introduction. Do not
stage a fake hit to teach an attack. Combat begins under the normal AI after the
handoff, with the existing spawn settle and normal visible windup.

The full introduction is deliberately eligible only when the active village is
safe to interrupt: no current attack near Adam, active emergency, urgent burning
or resident danger, recovery, modal, interior, story, sailing or transition.
If ineligible, deliver the ordinary arrival instead. Leave the introduction
unseen so a later safe scheduled arrival can introduce it. Never delay a threat
indefinitely to obtain a cinematic opportunity.

### Repeat-batch rhythm — no camera takeover

- About 8 seconds before the committed arrival: show a small disturbance at its
  actual shore entry and an owned, brief direction cue if the shore is offscreen.
- About 4 seconds before: add a low spine-like silhouette in the foam. This is
  environmental preview art, not a targetable live monster held invulnerable.
- At the scheduled time: real enemies materialize at validated land positions,
  use the normal 0.35-second settle, then enter ordinary movement/AI. Cosmetic
  foam can finish fading afterward without delaying or authorizing damage.
- New actors in one batch can settle a fraction apart, but the scheduler must
  record their complete allocation once. Staggering must not become extra rolls.

The cue remains useful without sound. Do not block controls, open a modal or
repeat a title card for these ordinary arrivals. Do not replay entry effects on
survivors restored from a save or on enemies that already walked inland.

## Animation vocabulary after arrival

Give the species a recognizable rhythm throughout play, rather than reserving
all character for its introduction. Presentation should follow actual FSM state
and actual movement, with gameplay timing unchanged.

| State | Proposed animation | Gameplay boundary |
| --- | --- | --- |
| Idle | Tiny alternating underside steps, occasional eye glance, restrained spine sway. | No whole-body bob that looks like constant attack preparation. |
| Moving | Small sideways body tilts and alternating base poses; a loose fragment lags slightly. Eyes remain readable instead of rotating with a rolling wheel. | Drive cycle from real distance/velocity, preserving acceleration, speed and collision. No sliding cycle while blocked. |
| Notice / target acquired | Eyes snap toward the valid target; front silhouette firms for one short beat. | Visual reaction only; do not insert an extra combat delay or a new forced ALERT state. |
| Windup, 0.00–0.18 s | Body compresses and draws back; forward spines become more prominent. | Feet/body position hold; existing telegraph begins. |
| Windup, 0.18–0.42 s | Hold the charged silhouette with a restrained dry tremble. The ground cue communicates imminent contact. | No damage, projectile, new reach or faster attack. |
| Active, 0.00–0.14 s | Short visual shove of the spiny shell; a contact accent occurs on the first active frame only if the real hit succeeds. | Existing one-hit claim and range check own damage. No body teleport or collision bypass. |
| Recover, 0.00–0.50 s | Shell rocks back and settles; the lodged can gives a tiny secondary wobble. | Existing recovery/cooldown continues. No second hit from follow-through. |
| Hit / interrupted windup | Brief shell recoil and dimmed spine flare, then existing stagger behavior. | Preserve interrupt rules; animation hit-stop does not freeze AI timers or expand stunlock. |
| Death, existing ~0.9 s | Spines relax, shell tilts, a few cool violet/sand motes dissipate and the body fades. | Collision/targeting and rewards resolve once through the existing death owner. No dropped sharp hazards, collectible can or second payout. |

Avoid an attack-looking idle pulse, permanently glowing threat ring, spinning
eyes, large rubbery squash, rapid jitter or a long decorative recovery after the
actual AI has already resumed. The player must be able to distinguish moving,
winding up, hitting and recovering at compact resolution.

## Framing, geography and player agency

- Pick an authored shore entry from real topology, not the dock deck, turtle
  position, recovery area, a shop doorway or a place occupied by the player.
- Check the final world-collision shape, authored water/collision cells and a
  traversable route inland. If no valid entry exists, skip the batch under the
  schedule's policy; do not force it through collision or move player buildings.
- Preview motion may be drawn over the water. Real Enemy bodies start on valid
  land: the animatic never removes sea collision to let them walk through it.
- Keep the shot wide enough to include foam, contact shadow and first land steps.
  Avoid full-screen flashing, a full-map zoom or camera shake on every entrance.
- Show Skip immediately during the full introduction; Escape and touch must work.
  Skipping reaches the same final batch, positions and normal combat timing.
- Full introduction playback temporarily suspends the world and clock through
  Game's existing story ownership. The sequence does not pause SceneTree itself.
  The suspended world cannot keep attacking unseen while the camera looks away.
- Restore the previous camera behavior/zoom and release held controls before
  the handoff. Never teleport Adam or his companion to improve the composition.

## Persistence and interruption

Propose a defaulted, sanitized `campaign.urchin_intro_seen` journey flag. Mark it
only when the introduction completes or the player explicitly skips to a
successful handoff. A world replacement or cancelled operation must not mark it.

Temporary previews stay outside combat/settlement/enemy groups and saves. At the
final handoff, instantiate and commit exactly the scheduled batch through
GameState's encounter transaction, then dismiss previews. Reward logic never
runs for a preview. Avoid a frame in which preview and real sprites both render.

Save/load during the introduction retains the authoritative pending batch and
unseen flag; reconstruction uses the same schedule, not a new probability roll.
The eventual dispatcher follows its normal expiry/cancellation rules. An already
consumed batch or restored survivor cannot replay the introduction or duplicate
enemies. A stale completion callback must verify the world, journey and batch ID.

No await may later restore an old world, camera or input owner after Game has
transitioned. Track and cancel presentation tweens, temporary nodes and audio.
Returning to the title, new journey, defeat and replacement must all clean up.

## Accessibility, sound and implementation owners

Reduce Motion keeps the important foam/spine/body/eyes beats through short pose
changes and gentle fades. Use direct framed cuts instead of the camera pan;
remove wobble/shake. Do not shorten a combat windup, change arrival eligibility,
move the spawn time or add invulnerability when this setting changes.

Low effects keeps the spine silhouette, eyes, contact shadow and windup cue;
optional foam droplets, fragment secondary motion and extra motes may disappear.
Sound is supporting information only, respects current effects/master/mute
settings, and stops on cancellation. Use a soft splash, sand taps and one light
can rattle; ordinary combat keeps the existing urchin audio policy.

Suggested ownership:

- Game: safe introduction eligibility, story suspension, camera/input restoration.
- Lobby / proposed encounter dispatcher: entry validation and batch handoff.
- Dedicated UrchinArrival presenter: timeline, temporary silhouettes, foam/audio.
- PixelArt / CoastalArt: deterministic cached pixel poses and shore accents.
- Enemy: existing FSM and combat authority; a species-specific visual pose adapter
  reads state without independently advancing timers or applying damage.
- GameState: intro-seen flag and saved encounter transaction.

Keep common enemy behavior stable; do not run a second combat state machine in
the animatic, update textures every frame without caching, or use editor APIs at
runtime. A rough first implementation can use 8–12 arrival key poses and a small
reusable movement/windup/recovery set rather than a large spritesheet production.

## Review sequence and acceptance

1. Build a greybox timed shoreline storyboard first, showing first-time, Skip
   and repeat-arrival paths with the intended group sizes. Review the rhythm.
2. Validate land entry and matched preview-to-enemy handoff with the schedule.
3. Add the original pixel poses and restrained audio; review consecutive frames.
4. Add species-specific visual combat poses without retiming existing damage.
5. Validate saves, cancellation, settings and the isolated gameplay gate.

Required evidence includes 1280x720 and 832x480 rendered sequences with fixed
camera samples: spines in foam, first land contact, wobble, inland look, camera
return and first real windup/hit/recovery. Single endpoints cannot prove motion.

Check batch sizes one/two/three, valid spawn spacing and a blocked/rearranged
shoreline; quiet/forest-only nights; daylight and saved survivors; overlapping
UI/story/recovery ownership; offscreen arrivals; Skip at every beat; world
replacement and save/load before and after handoff; matching regular/emergency
stat variants; one actual hit and one reward only; gun/pet targeting of real
enemies only; low effects, live Reduce Motion and muted audio.

No visual/audio/runtime result is claimed here. Only source inspection and this
plan document were completed; no gameplay code, art or player save was changed.
