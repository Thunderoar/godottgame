# Twilight Wilds: compact content expansion plan

Date: 2026-10-29. Source baseline: `928b913`, including the compact 56x52 realm.
Status: milestones 1 and 2 implemented and verified; milestones 3 and 4 remain proposals.

Detailed milestone 1 specification: [First Signs of Life](TWILIGHT_WILDS_FIRST_EXPANSION_PLAN.md).
Detailed milestone 2 specification: [Read the Wilds — combat expansion](TWILIGHT_WILDS_COMBAT_EXPANSION_PLAN.md).

## 1. Experience and scope

Keep the 56x52 footprint, approximately 49.55-unit main road, character scale and
20x20 boss arena. Add reasons to look, choose, interact and revisit within that
space. A first visit should alternate arrival, a discovery, a short fight, a quiet
habitat, a useful mechanism and the boss approach. Optional activities extend the
visit through play rather than longer corridors.

Every new feature should provide at least one of: a choice, useful information,
a tangible reward, distinctive wildlife behavior, or a visible environmental change.
Main-path readability, usable touch controls and short return trips remain primary.

Preserve these rules:

- Taming and restoration are optional for reaching the boss. Ember remains sufficient.
- The return rift is available from arrival. The main bridge is never gated by repairs.
- Pet habitats and the checkpoint remain protected; manual duels suspend the world.
- Normal menus retain their existing simulation behavior. Realm visits retain the
  current shared-clock policy and do not trigger offscreen village emergencies.
- No new currency, mandatory crafting grind, random pet spawn odds or night-only
  puzzle windows. Permanent twilight is presentation, independent of the village clock.
- Boss defeat still leaves a peaceful, explorable realm. Missed activities remain
  completable afterward. Existing companions, campaign stages and both rescues survive.

## 2. What exists and what is missing

RealmDB currently defines seven landmarks, two tameable pets, six regular enemies,
an arrival rift, checkpoint, shortcut and nine physical onward passages. Terrain and
collision use the compact bounds; saved discoveries use normalized six-by-six cells.

Milestone 1 now gives the pets home routines and fixed duel stages, adds Wisp the
Waykeeper, saves three memories in a journal, and exposes the one-time rootway
hollow cache. Realm interactions also cover return, winch, rest and onward travel.
Milestone 2 organizes six guards into three local pairs: four Darkfire Imps, one
Ember Watcher and one Rune Keeper. It adds stationary rush warnings, a fixed fan,
a short ground cross, physical cover and dependable retreat with one owned attack
at a time. Restoration activities and environmental puzzles remain proposed.
Post-clear changes restore terrain/light and remove hostiles.

Use the existing landscape and lifecycle as the foundation, and introduce content
definitions instead of adding another independent world or global quest system.

## 3. Content budget for the full expansion

| Content | Proposed total | Treatment |
|---|---:|---|
| Core landmarks | 7 | Existing destinations, stronger local identity |
| Tameable pets | 2 | Existing cat and moth, improved behavior and staging |
| Regular enemy types | 3 | Dash, projectile fan, crossing ground warning |
| Regular enemies | 6 initially | Redistribute into three authored encounters |
| Optional restoration activities | 3 | Small bridge, grove ward, moonpool mirrors |
| Treasure caches | 3 | Distinct clues and fixed one-time rewards |
| Story fragments | 3 | Short, readable in any order |
| Guide character | 1 | Quiet arrival-area Waykeeper wisp |
| Secret pocket | 1 | Small western hollow inside current bounds |
| Boss | 1 | Existing ruler/powers; improved foreshadowing |

This is an expansion ceiling, not an instruction to place every object immediately.
Avoid overlapping interaction targets. Introduce one new action at a time, with
quiet links between landmarks. Keep the nine existing passages reachable throughout;
their eventual three-dimension campaign migration remains separate work.

## 4. Area-by-area design

Coordinates below refer to existing landmarks or provisional content reservations.
New placements require actual collision, visibility and touch-target validation.

### Arrival Glade — orientation and reassurance

Existing arrival: (26,46); return rift: (26,48).

- Add a small Waykeeper wisp off the walking line, provisionally around (22,45).
  It turns toward Adam and gives a few optional lines about the fading road lights.
  It is a local inhabitant, not another missing friend or an escort objective.
- Give the rift a readable ground apron and an unmistakable silhouette. Reserve its
  approach so NPCs, foliage and interaction markers cannot crowd returning players.
- Introduce leaf movement, small harmless insects and distant citadel ambience.
  Essential routes remain readable without particles or audio.
- Establish one obvious road and the first visible clue toward the western branch.

Payoff: confidence to explore and an understandable reason to investigate the realm.
No mandatory dialogue or selection screen before movement.

### Rootbound Crossing — the first optional decision

Existing crossing: (33,40).

- Strengthen the existing bridge with banks, stone shoulders, water movement and
  clear foot support. The main crossing remains available from the beginning.
- Place cat tracks and scratched wood toward the western path, with moth lights
  encountered later toward the eastern loop. Clues should lead somewhere real.
- Add an optional damaged western footbridge or log crossing, roughly around
  (17,41), leading toward the first cache near (8,41).
- Its missing plank is found nearby as a world object, not bought or crafted. Recover
  the plank, return and place it. The restored crossing lights the first waylight.
- Place the first short road inscription on the route, independent of the repair.

The optional crossing needs a genuine local obstacle and traversable bridge opening;
painting a log over already walkable water would not create a useful activity.
Do not let this local geometry alter access to the main road or return rift.

### Bramble Grove — a creature's home

Existing habitat: (12,35).

- Give the cat a resting ledge, a scratching post or fallen trunk and a short patrol.
  It notices Adam, watches the active companion and takes a deliberate challenge pose.
- Keep its authored spawn reliable. Observing or approaching it is enough to challenge;
  no feeding item, random spawn roll or prior restoration is required.
- Add an optional corrupted grove ward outside the protected challenge clearing.
  Two existing guards occupy this encounter, rather than adding an unlimited spawner.
- After those guards are defeated, an interaction restores the ward and its waylight.
  Leaves brighten, harmless wildlife returns and one Pet Food becomes available.
- A damaged field note tells the second part of the local story.

The ward encounter must not spill into the cat's safe clearing. The challenge keeps
its existing world suspension even if a projectile was already in flight.

### Broken Watchpost — utility and a tactical fight

Existing landmark: (35,31); winch: (37,32).

- Make the structure readable as a broken observation post: low wall sections,
  a fallen banner, supply remnants and a clear winch mechanism.
- Stage the second encounter around cover with an Imp and an Ember Watcher.
  Position cover so the player can avoid the fan without pinning the companion.
- Animate the existing winch, root release and opened route; persist the final state.
  Keep the current shortcut useful without adding a fee or a mandatory boss key.
- Let the opened rootway reveal a clue toward a small western hollow, provisionally
  near (8,24), containing the largest of the three caches.

The hollow is a small optional pocket within the current bounds. Carve its actual
route through decorative collision before placing scenery or rewards there.

### Moonpool Hollow — calm observation and a small puzzle

Existing habitat: (44,27).

- Give Dusk Moth a loop around glowing plants, occasional perches and a soft response
  when Adam approaches. Motion stays inside the clearing and returns reliably to
  an accessible challenge position.
- Add two rotatable reflecting stones. The player redirects a beam toward a dark
  lantern; solving it restores the moonpool waylight and reveals the second cache.
- Use visible beam endpoints, one nearby example and a clear completion response.
  No timer, obscure symbol guessing, external item, clock-phase requirement or RNG.
- Place the third fragment here, explaining the connection between the old lights
  and the citadel. The moth can be challenged before solving the puzzle.

Save mirror orientations and solved state. Restore beams, reward eligibility and
collision from that state after Continue. A reset interaction must always work.

### Ashen Approach — preparation through familiar warnings

Existing approach: (26,25); checkpoint: (26,22).

- Transition to dry leaves, dim roots and scorched stone while keeping the walking
  surface quiet enough for attack warnings to stand out.
- Stage the final regular encounter with an Imp and a Rune Keeper, outside the safe
  checkpoint radius. This introduces the cross-shaped warning before the boss.
- Give the lantern a proper sheltered rest space, seating and a short inscription.
  Keep its approach and recovery area clear of hostile effects.
- Frame a visible glimpse of the citadel as the player approaches; reveal the boss
  map marker only when the stronghold is actually discovered.

Rest remains a short preparation step. No boss-access checklist is introduced.

### Chaos Citadel and the onward court — climax and aftermath

Existing ruler: (26,10); arena: (16,1), size 20x20.

- Add broken architectural edges, restrained banners and a recognizable throne or
  beacon behind the ruler, all outside the dodge lanes and overhead-warning area.
- Reuse the fan, dash and cross language learned from the regular encounters.
  Do not add simultaneous extra minion waves to the first version of this fight.
- Keep threshold-only activation, all-direction retreat/reset and full arena framing.
- After victory, release the oppressive ambience, soften corrupted props and let
  wildlife use nearby paths. The return rift remains prominent.
- Make onward passages look like a coherent echo court with readable paths and
  individual lock states, without moving, hiding or merging saved campaign stages.

Any unfinished ward, bridge, puzzle, cache or lore fragment must still work in the
peaceful world. A cleared boss cannot remove an item needed for an optional activity.

## 5. Regular combat: teach three useful responses

| Enemy | Role | Player learns | Initial constraints |
|---|---|---|---|
| Darkfire Imp | Existing warned dash | Step aside from a committed rush | Preserve current damage pacing |
| Ember Watcher | New small projectile fan | Find the gap or use cover | Few projectiles; generous first warning |
| Rune Keeper | New crossing ground lines | Move out of the marked intersection | One readable pattern; no new status ailment |

Use three authored two-enemy encounters. Keep approximately the current HP/damage
budget initially and cap simultaneously attacking regular actors at three. No
encounter should pull the entire map or invade a protected habitat. Boss activation
does not alert every remaining group.

All three use the chaos visual identity. Do not turn every existing Imp into the
new attack type by changing the global chaos catalog. Give variants explicit attack
profiles, or narrow subclasses, while retaining Enemy's damage/ownership contracts.

Ordinary fights retain the existing fresh-visit reset policy. A completed grove
restoration stays complete and its cleared ward may remain safe on later visits.
Do not add saved per-enemy HP for the whole realm merely to implement this activity.

## 6. Rewards and persistence

Initial added reward budget, to playtest: 50 Gold across three caches (10/15/25),
one Health Potion and one Pet Food across the entire expansion. No extra guaranteed
diamonds, permanent combat multipliers or repeated level rewards. Existing boss,
enemy and pet-bond rewards retain their own rules.

Cache supplies follow the same banking policy as their currency. An unbanked potion
is not a usable inventory potion under the existing system. Do not advertise it as
an immediate mid-fight heal or secretly add it to permanent inventory while also
counting it as losable loot. The already available camp remains the reliable free
pre-boss recovery point.

Different payoffs matter: the bridge opens access, the ward improves a habitat, the
mirrors change the pool, the winch shortens travel, fragments explain the realm and
pet encounters earn companions. Everything should not become an identical coin box.

| State | On defeat / reload | Reward policy |
|---|---|---|
| Memories, discoveries and bonds | Persist | No repeat payout |
| Bridge plank / repair, ward, mirror state | Persist | Stable activity IDs; no lost puzzle items |
| Ordinary enemy loot | Existing expedition rules | Unbanked loot may be lost |
| Cache opened in an active expedition | Preserve pending claim with its loot | Commit claim when banking; release on loot loss |
| Cache found in an already restored realm | Peaceful visit remains active | Atomically bank reward and permanent claim together, including later revisits |

The cache model must handle boss victory ending `expedition.active` while
`realm_progress.visit_active` remains true. Do not call `add_expedition_loot()`
unconditionally after victory: it currently rejects inactive expeditions.

Store pending and banked cache IDs beside their owning loot transaction. A reload
must not duplicate pending loot. A defeat must not permanently consume a cache whose
contents were discarded. First cache payment and its permanent claim must share one
accepted GameState mutation/save boundary, including duplicate-callback protection.

Proposed new fields under realm progress/visit state: bridge stage (0..2), ward
restored flag, two sanitized mirror orientations and solved flag, read-fragment IDs,
discovered-interest IDs, pending-cache IDs and banked-cache IDs. Prefer deriving
waylight visuals from activity completion instead of saving duplicate booleans.
All new fields need defaults, load sanitization and old-save tests.

## 7. Atmosphere, discovery and presentation

- Reserve strong silhouettes: arrival rift, crossing, cat trunk, broken watchpost,
  moonpool and citadel. Keep combat floors quieter than the surrounding decoration.
- Make clues precede rewards: tracks before the cat, drifting lights before the
  moth, a glint or disturbed leaves before the hollow. Avoid invisible pixel hunts.
- Reveal treasure icons only after discovering the actual interest point; revealed
  terrain cells alone should not expose every secret object behind scenery.
- Use bounded, nonblocking birds/insects and short habitat routines. No reward
  depends on waiting for a rare animation, weather event or ambient spawn.
- Use a few low-volume environmental sounds with distance falloff, respecting mute.
  Critical attack and puzzle feedback remains readable without audio or particles.
- Use the existing persistent realm caption and Field Guide for important information.
  `GameHUD.show_toast()` remains a no-op. Do not add mandatory popup chains.
- Keep E and direct touch as the interaction routes; retain Sprint's meaning. Nearby
  interaction targets must remain distinguishable on a compact landscape screen.

The three fragments tell one optional local story: the road lights once protected
the forest; corruption drove its animals into the remaining refuges; the citadel
became the source of the stolen light. This adds context without rewriting Adam,
Arjun or Mei Ling's established rescue story.

## 8. Implementation order

The player-facing delivery milestones are: **1. First Signs of Life** (implemented),
**2. Combat expansion** (implemented), **3. Environmental activities**,
and **4. World response and polish**. The six engineering steps below describe
dependencies across those deliveries, not a replacement numbering system.

1. **Foundations:** define stable content IDs and rewards; add/sanitize/save the new
   state and pending/banked claim transactions. Verify duplicate, death, reload and
   post-boss paths before placing rewards.
2. **Living places:** improve habitat art/routines, arrival guide, tracks and landmark
   silhouettes. Establish side-pocket topology and clearance before decoration.
3. **Discovery payoff:** ship the three caches and three short fragments, using owned
   persistent feedback and discovery-gated map icons. This makes exploration rewarding.
4. **Combat variety:** introduce the Watcher and Rune Keeper and organize the six
   actors into three local encounters with protected-area and active-count limits.
5. **Environmental activities:** add the optional plank crossing, grove restoration
   and moonpool mirrors, each with a distinct payoff and durable completion state.
6. **World response and polish:** connect local restoration visuals and global boss
   aftermath, sound, low-effects fallbacks, camera framing and save/restart reviews.

The first reviewable milestone should be the living habitats, three fragments and
the rootway hollow cache. Define the other two cache transactions early, but expose
those world objects with their bridge/puzzle activities in the later milestone.
Do not introduce a new prerequisite for a cache a player already earned. Build all
milestones on the same saved content IDs and test enjoyment before expanding scope.

## 9. Engineering boundaries

- Keep placement/definitions in RealmDB or a small RealmContentDB; avoid growing
  TwilightRealm with every cache, dialogue and puzzle rule inline.
- Reuse RealmInteractable's distance, direct-tap and current-world guards. Add narrow
  reusable interest/activity components rather than a second global interaction API.
- Keep durable writes in GameState. Do not edit data directly from props or UI.
- Collision changes invalidate both monster and companion routes. A visual bridge
  or cleared root must match the physics state on construction and after interaction.
- Do not register decorative realm trees as village ForestTrees or reuse their IDs.
  Keep scenery RNG independent of the original village forest stream.
- Preserve world/session validity after awaits; settings, story, defeat, cancel and
  world replacement must not leave actor, camera, audio or synthetic-input locks.
- Optional guide dialogue needs a realm-safe presentation; Game.open_dialogue()
  currently excludes Dungeon contexts, including TwilightRealm. Do not bypass that
  context guard globally to add one character.

## 10. Acceptance and playtest decisions

Automated checks should cover all existing routes plus new pocket/bridge access,
unambiguous interactions, three enemy profiles, encounter limits, discovery-gated
icons, migration and sanitization, interrupted activity progress, reward idempotence,
loot loss/banking, post-victory cache collection and completion of missed activities.
Preserve the current forest fixture, clock, pet-duel and campaign/rescue coverage.

Inspect actual 1280x720 and 832x480 renders and injected touch: no collision pinches,
overlapping targets, warnings hidden by decoration, chase into safe clearings, input
leaks or camera clipping. Test reduced motion/low effects and muted audio. Update
tide_test and ACCEPTANCE_TESTS together with any implemented rule changes.

Playtest questions: can a new player find the boss route without a tutorial arrow;
do both optional branches attract attention; is each reward worth its detour; can
the player explain the three enemy warnings before fighting the ruler; does the
restored world feel different; and is returning to the village still quick?

Measure route choices, backtracking and time spent walking versus interacting. No
specific first-visit duration or frame-rate improvement is claimed by this plan.

## Deferred scope

Additional tameable species, procedural events, fishing, a crafting tree, farming,
elite waves, repeatable daily quests, a second boss, new realm currencies and the
three-dimension campaign migration are outside the first content expansion. Each
would need its own space, progression purpose and save policy. Revisit a third pet
only after the existing cat and moth have distinct, enjoyable habitats and roles.

## Evidence limits

This proposal is grounded in inspection of RealmDB, TwilightRealm,
TwilightLandscape, RealmInteractable, ElementalMinion, GameState's realm/expedition
transactions, ItemDB and the current implementation guide. No gameplay source was
changed, no new art was generated, and no engine/tests were rerun for this planning
document. Coordinates and reward budgets are proposed, not validated placements.
