# Fire monsters: individual ember portals and first arrival

2026-10-30. Source inspected at `aaec9ab` on `main`.
Status: design proposal only. No gameplay, art, audio, settings or player saves
changed. Timings and dimensions below are starting values for an animatic review,
not measured pacing or implemented behavior.

Implementation update, 2026-10-30: individual ember portals and the coordinated
shore/forest presenter are now implemented. See `FIRE_MONSTER_ARRIVAL.md` and the
latest acceptance entry for current behavior and verification. The original
proposal below records the design, including the still-separate night scheduler.

## The idea

One small, temporary portal admits one fire monster, then seals. Give the first
arrival enough attention to teach that visual language. Let the surrounding
forest repeat it to reveal the scale of the intrusion. The emotional progression
is curiosity, intrusion, recognition, multiplication, responsibility.

The central image: a single ember hangs motionless between two trees. It stretches
into a thin wound in the air. Something on the other side presses against it.
A small flame body squeezes through, gathers itself, and notices a living tree.
Then several other wounds open between the trunks.

Keep this in the actual village, using its pixel-art language and actual arrival
positions. The monster is small; the implication of many independent entrances
provides the menace. This establishes a method of arrival without inventing a
summoner, a link to the Kraken, or an explanation for the existing Dimension Portal.

## What the current monsters actually do

- `Lobby.FIRE_MONSTER_COUNT` is 24. Dusk replenishes toward that living count once
  per night, subtracting survivors. Twelve forest anchors are reused with random
  offsets and `safe_spawn()`. Later-dungeon emergencies can add up to six, toward
  a fire population of 30. TwilightRealm does not trigger that emergency.
- Village fires are `Enemy` instances with kind `fire`, `forest_mode`, 40 HP,
  damage 3, speed 1.62, body radius 0.4 and attack interval 1.6 seconds. They
  currently appear through the generic 0.35-second fade and SPAWN state.
- Their current sprite is a procedural 32-by-32 flame silhouette: red-orange
  outer tongues, an amber body, a pale yellow core and dark rectangular eyes.
  `kind == "fire"` is distinct from elemental `minion_fire` / `demon_fire`.
- They choose a nearest attackable mature tree, with a closer living player or
  exposed resident able to take priority within the six-unit village actor range.
  They are not ranged fireball attackers, passive contact burners, or dedicated
  building attackers. Sheltered/dead residents and protected saplings are excluded.
- A real tree strike ignites the tree and deals damage. Burning then removes
  two HP per second until extinguished or the tree falls. Defeating the attacker
  does not itself extinguish the tree. Water Keepers heal/extinguish burning trees
  and can attack fire monsters with water bolts.
- Their ordinary melee phases are WINDUP 0.42 s, ATTACK 0.14 s, RECOVER 0.50 s.
  Damage is claimed once on the first active frame, subject to the real range
  check. Animation must continue to describe those timings.
- Living monsters retain their HP and remain dangerous after dawn. Saved survivors
  restore as existing creatures, rather than entering the village a second time.
- Fire-monster combat, impacts against them, and burning-tree effects deliberately
  follow a silent audio policy. The introduction should work entirely visually.

Relevant owners: `scripts/world/lobby.gd`, `scripts/combat/enemy.gd`,
`scripts/world/forest_tree.gd`, `scripts/world/resident.gd`,
`scripts/core/pixel_art.gd`, `scripts/data/element_db.gd`, and
`scripts/data/field_guide_db.gd`.

## What the reveal should teach

1. The warm shape is an intruder entering BESUT, rather than an existing torch.
2. Each temporary opening admits exactly one creature.
3. The creature is interested in the living forest; nearby people are also at risk.
4. The entrance closes by itself. The immediate actionable target is the monster.
5. Adam has time to respond when control returns; the scene has not secretly
   burned trees elsewhere while the camera was occupied.

Do not demonstrate a fake tree ignition. Show the creature's attention, its
orientation toward a real tree, and its first intent to approach. Actual ignition
belongs to ordinary combat after the handoff. The existing defense lesson and
actual tree feedback can then teach the consequence honestly.

## First standalone fire introduction: 10.5 seconds

| Time | Picture and motion | Dramatic function |
| --- | --- | --- |
| 0.0–0.8 | Settle on a real forest opening with one mature trunk and a visible patch of ground. Retain enough surrounding scenery to recognize BESUT. | Establish what is at stake before showing the intruder. |
| 0.8–1.8 | A single ember appears above the ground. It drifts slightly, then becomes unnaturally still for about a quarter second. A faint warm reflection marks the trunk. | Catch the eye; invite curiosity. The stillness is the first wrong detail. |
| 1.8–3.0 | The ember pulls into a narrow vertical seam, widening into an irregular oval. A dark centre remains visible inside a restrained ember rim. Two or three small motes are drawn inward. | Make a hole readable, rather than an explosion or a normal flame. |
| 3.0–4.2 | A pale inner core presses into view, followed by a narrow leading flame tongue. The body pinches through the opening in two distinct poses. It appears to pull itself forward, with a brief resistant hold. | Give the entrance effort and the monster intention. Avoid a simple opacity fade. |
| 4.2–5.4 | The body clears the rim, compresses low, then reforms into its familiar flame silhouette. The contact shadow anchors it. The opening pinches shut behind it, leaving a momentary point of light. | Reveal the species cleanly and establish one opening, one monster. |
| 5.4–6.6 | Dark eyes settle toward the nearby mature tree. The forward flame leans subtly toward the trunk while the rear tongue trails. Hold that readable silhouette for roughly 0.3 s. | Turn a curious arrival into a threat through target attention. |
| 6.6–8.4 | Widen within the same forest opening. Two or three other actual allocated portals open at slightly different phases; a further visible opening may suggest depth only if an allocated monster belongs there. | Reveal multiplication without displaying 24 synchronized flashes. |
| 8.4–9.2 | Hold a readable composition: closed lead portal, grounded lead monster, living tree, and other distinct arrivals. Optional caption: “Fire Monsters · Protect the forest.” | Let the player understand the picture before taking it away. |
| 9.2–10.5 | Restore the saved player camera and zoom. Match preview feet, orientation and rest pose to the real spawn records. Restore HUD and controls through the owning Game flow. | Convert anticipation into a clear opportunity to act. |

Use one deliberate widening and the return to Adam. Avoid touring all forest
anchors. Never move Adam or the companion to make a reaction shot possible.
If Adam is already in the selected framing, a brief visual turn may be considered
later; it is not necessary for the first version.

During the full introduction, the real Lobby and authoritative world clock are
suspended by Game. All visible creatures are cosmetic previews, outside enemy,
target and reward groups. There is no scripted tree hit, hidden burn damage,
passive damage zone or forced kill. After handoff the normal SPAWN settle and
visible windup precede real attacks. Do not add an invisible grace timer.

The first real target remains chosen by normal AI. The storyboard can point a
preview toward a tree, but cannot promise that the tree remains its target if a
closer exposed resident or Adam becomes eligible when simulation resumes.

## Portal and body visual language

Use a small vertical tear whose lower tip meets the ground plane. Begin with an
outer height around 40–48 source pixels and width around 28–36, tuned against
the actual 32-pixel body. Keep the opening large enough for the silhouette to
read without scaling the monster into a boss. `PixelArt.PX` is 1/32 world unit.

Palette: subdued burnt-red exterior, a narrow orange/amber lip, restrained pale
yellow at stressed points, dark interior. Keep the monster's pale core the focal
point once it clears the opening. Reserve the strongest contrast for the brief
emergence silhouette. Avoid a white screen flash or sustained bright bloom.

The entrance has no stone frame, navigation label, interaction prompt or permanent
map icon. Its irregular perimeter and quick closure distinguish it from the large
usable Dimension Portal. It is not targetable, destructible or a recurring spawner.
Embers and a faint ground mark are presentation only and disappear shortly after
closure; neither causes damage nor becomes saved terrain.

Use depth ordering or a small clip/mask so the rear body can remain behind the
rim while the front is visible. Retain a clear ground-contact shadow. Simply
scaling a fully visible creature from zero would suggest growth or conjuration,
weakening the idea that it crossed a threshold.

Suggested arrival key poses: core behind seam, leading tongue, narrow body halfway,
body clearing rim, low compression, reformed body, eyes toward tree, forward lean.
Reuse the reformed silhouette for the exact gameplay handoff. Build cached original
pixel poses and a small shared portal frame set, rather than unrelated portrait art.

The intended character is watchful and hungry. Its flame stretches into movement;
it gathers low before striking and relaxes during recovery. Keep the arrival's
pinch-through effort separate from attack windup, so ordinary idle motion does not
look like an imminent hit. Later combat polish should read the existing FSM and
actual velocity; it must not add a second attack clock or change damage/reach.

## One portal per monster, with a readable group

Every genuinely new fire monster gets its own entrance, including offscreen
members and emergency additions. A three-monster batch produces three portals;
a 24-monster initial wave produces 24. The camera concentrates on the lead and
nearby followers instead of requiring all entrances to fit in one frame.

Use short phase offsets within the allocated group, initially around 0.15–0.25 s
for nearby followers. During a full suspended introduction this is preview motion;
all delivered real enemies still commit together at the final handoff. During
ordinary play, use a shared delivery deadline and vary the cosmetic lead-in phases;
do not quietly change individual AI activation times or spawn extra enemies.

The existing 24-monster allocation remains a separate balance issue. Presentation
cannot turn it into eight monsters or silently implement variable night profiles.
Conversely, the proposed night scheduler can later supply groups of up to eight
without changing the visual rule. Never pad a one-monster batch with fake followers.

At close range portals must not overlap into one orange mass. Reserve distinct
valid footprints when allocating points, preserving one opening per body. The
existing twelve reused forest anchors make this a real implementation requirement.
If a point fails final collision/clearance validation, reject that allocation using
an explicit batch policy; never draw a convincing entrance at one place and silently
deliver its enemy somewhere else.

Avoid one PointLight2D, material or particle emitter per portal. Reuse cached frames
and shared resources; use simple readable rim/ground sprites for low effects.
Any additional decorative variation uses a separate deterministic stream, never
Lobby's seeded forest construction RNG or global random state.

## The existing sea-urchin reveal needs one coordinator

Current flow matters: `Lobby._on_day_phase_changed()` can ask
`Game.try_urchin_introduction()` to stage both populations. `UrchinArrival` runs
for eight seconds; `Lobby.finish_urchin_arrival()` then creates fires and urchins
and commits `complete_home_arrival()`. An independent fire cinematic attached to
`_spawn_forest_monsters()` would therefore fire inside another arrival's completion.

Plan one Game-owned arrival coordinator, while retaining separate shore and fire
presenters. Select the chapters before taking camera/input ownership:

- Only fires need a first reveal: the 10.5-second sequence above.
- Only urchins need one: keep their current eight-second sequence.
- Both need one and both populations are allocated: one combined sequence around
  14.5 seconds. Retain the shore's first seven seconds, transition directly into a
  condensed 6.5-second forest chapter, then use one final one-second return to Adam.
  The condensed chapter preserves ember, seam, crossing, tree attention and nearby
  follower entrances; remove separate establishing and repeated reaction holds.
- Neither needs a full reveal, or story interruption is unsafe: ordinary world
  cues and portals, with no camera takeover.

During the combined version both species remain previews until one final delivery.
Do not let real urchins attack while the camera subsequently watches the forest.
The combined timing is proposed new behavior and needs its own review; it is not
how the existing eight-second presenter currently works.

Show one Skip control immediately. Skip finishes the entire combined introduction
and delivers the same authorized valid allocation; it does not queue a second
camera takeover. Record seen flags only for chapters actually completed or
explicitly skipped into a successful handoff for that species.

The separate `NIGHT_ENCOUNTER_PLAN.md` is still a proposal. Its quiet/forest/shore/
mixed profiles must not be treated as shipped behavior. This plan attaches to the
first actual eligible fire allocation, not hardcoded night one, and never creates
an encounter merely to show the animatic. If that scheduler ships later, its
selected batches, expiry rules and species remain authoritative.

## Repeated appearances and unsafe first arrivals

Use an ordinary eight-second visual warning when the full story is unavailable
or has already been seen. Under today's dusk system that adds a warning before
fire delivery; this timing change needs integration with the shore warning.
Under a future scheduler it occupies the eight seconds before its committed due
time. Do not apply both delays consecutively.

For most of the warning show only sparse embers at the actual reserved points.
During the final roughly 1.2 seconds, use compact seam, emergence and closure
poses. Deliver real bodies at the shared deadline and let cosmetic residue finish
afterward. A very short closure may overlap the normal SPAWN settle. Match the
last preview to the real sprite; suppress only a redundant generic fade, not the
real settle or attack windup. Any overlap must remain readable and non-damaging.

Ordinary cues leave movement and combat available. If the arrival is offscreen,
show an owned direction cue such as “Embers in the eastern forest,” with the
bearing computed from the real points. Do not use `GameHUD.show_toast()`.
The warning must survive muted sound and low effects.

Safety eligibility follows the existing story guards: current Lobby and journey,
living awake player, completed welcome, no story, modal, interior, building editor,
sailing, transition, defeat, recovery, urgent burning or live village threat.
If unsafe, use ordinary delivery and leave the full introduction unseen. A later
new safe fire allocation can introduce the species. Existing survivors never
replay their entrance merely because the flag remains unseen.

## Persistence, placement and ownership

Propose a defaulted and strictly sanitized `campaign.fire_intro_seen`. Track fire
and shore introduction state independently. Old saves containing fire survivors
should migrate as already introduced; do not replay their arrival. An old save
with no survivors provides no proof of prior exposure: a future genuinely new,
safe fire allocation may receive the introduction.

Extend the current saved arrival transaction to retain actual fire points and
stable per-member IDs, not just the current `home_arrival.fires` count. Include
the warning start/deadline and a bounded disposition. Do not save previews or
per-frame animation time. A future scheduler should own the batch identity instead
of creating a parallel schedule here.

Reserve and validate land, authored collision/water, body clearance, separation
and traversable forest access. Exclude recovery wards, occupants, doorways and
critical service routes. Revalidate at delivery, especially during running-world
warnings when placement or actors can change. `safe_spawn()` returns its input
on failure; calling it is not proof that the resulting point is safe.

Deliver real bodies and capture survivors plus batch disposition in one GameState
save transaction, with no await between creation and commit. Saving during a
warning retains the same member IDs/points/deadline. Reload restores pending work
or delivered survivors, never rerolls positions or replays a committed portal.
Duplicate phase/completion callbacks must be harmless.

At dawn pending ordinary entries expire without daytime spawning; survivors and
burning remain. Full stories suspend the clock, so they cannot naturally cross
dawn. World/journey replacement cancels previews and rejects stale delivery. Do
not restore a retired camera or unlock controls owned by a new story or world.
Stop temporary audio, tweens and nodes on cancellation. Restoring saved monsters
uses a separate path that bypasses portals and introduction eligibility entirely.

Suggested boundaries:

- Game: one arrival owner, chapter choice, interruption guards, world/clock/input
  suspension and restoration.
- Lobby: validated allocations, real spawning, restoration and survivor capture.
- Proposed FireArrival: sampleable timeline, cosmetic bodies, portals and framing.
- PixelArt / proposed FireArt: shared deterministic textures and species poses.
- Enemy: real FSM, collision, targeting, damage and rewards. A narrow reveal option
  avoids a duplicate fade without bypassing SPAWN.
- GameState: defaults, migration, saved pending data, seen flags and atomic commit.

## Accessibility and audio

Keep the first version silent for fire/portal effects, preserving the established
fire-monster/burning policy. Existing ordinary ambient sound may continue. A new
portal sound would be a separate deliberate audio decision, not an automatic roar,
crackle loop or 24 overlapping bursts.

Reduce Motion replaces camera travel with cuts or brief gentle fades; remove
distortion, wobble and ember orbiting. Keep distinct ember/seam/body/closed states
and identical delivery timing. Low effects retains rim, dark interior, body, eyes,
contact shadow and attack cues; extra motes and light pools are optional. Changing
either setting live must not restart a batch, skip delivery or change combat.

## Build and review order

1. Review a rough timed forest sequence with placeholder portals and current
   monster bodies: solo, three members, full current wave, and combined shore/fire.
2. Implement allocation/transaction and interruption ownership before final art.
3. Make the matched handoff, Skip, restoration and repeat warning reliable.
4. Add the cached arrival poses and portal depth treatment. Combat-specific pose
   polish can follow without becoming a dependency of the entrance.
5. Run isolated checks and inspect native consecutive rendered frames at 1280x720
   and 832x480, including low effects and live Reduce Motion.

Acceptance must establish one portal per delivered new fire, no portals for saved
survivors, exact authorized counts, valid nonoverlapping locations, no damage or
rewards from previews, no duplicate species delivery, and no hidden simulation
during a camera takeover. Test one/three/eight/24 fires and emergency additions;
Skip at every beat; mixed chapter order/completion; pause owners and held actions;
blocked/edited forest; resident/player interception; save/load around the commit;
dawn, world replacement and new journey; one real tree ignition, continued burning
after its attacker dies, watering and one real reward. Preserve the 64-tree fixture
and existing combat timings. Do not assert proposed quiet-night tests pass until
the separate scheduler is implemented.

This document is based on source inspection and existing design/acceptance records.
No engine test or new visual/audio validation was run for this planning task.
