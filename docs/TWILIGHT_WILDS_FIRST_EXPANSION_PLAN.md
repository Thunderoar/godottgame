# First Signs of Life: first playable expansion specification

Date: 2026-10-29. Source baseline: `928b913`. Status: implemented and verified.
Parent design: [compact content expansion](TWILIGHT_WILDS_EXPANSION_PLAN.md).
Implementation and final evidence: [Twilight Wilds](TWILIGHT_WILDS.md) and
[acceptance tests](ACCEPTANCE_TESTS.md#living-twilight-wilds--first-expansion-2026-10-29).

Presentation update, 2026-10-30: habitat challenges now reuse the pre-existing
PetBattlePanel arena and turn engine. The staging/overlay implementation described
below is historical; current ownership and behavior are in TWILIGHT_WILDS.md.

## 1. The exact milestone

This specifies build-order item 1 from the expansion proposal: living cat/moth
habitats, the arrival Waykeeper, three readable memories, and one rootway hollow
cache. Its purpose is to make exploring the current map rewarding before adding
new enemy types, restoration objectives or puzzles.

Keep the 56x52 bounds, current main road, six regular enemies, boss, combat tuning,
checkpoint, winch, two pet recruitment rewards and nine onward passages. Existing
save flags remain authoritative. This milestone adds one small optional pocket and
improves the places already visited; it does not expand the map boundary.

The desired loop is: notice a clue -> investigate a living place -> choose whether
to challenge/read -> discover how the place connects to the realm -> use a familiar
route or shortcut -> find a tangible reward -> continue toward the citadel or home.

## 2. Concrete deliverables

| Addition | Amount | What changes for the player |
|---|---:|---|
| Waykeeper wisp | 1 | An optional local character reacts to discoveries |
| Habitat routines | 2 | Cat patrol/rest/notice; moth flight/perch/notice |
| Environmental clue trails | 2 short trails | Tracks lead west; glowing plants lead east |
| Memory fragments | 3 | A small local story, preserved in the existing Field Guide |
| Hollow cache | 1 | A visible, one-time 25-Gold exploration reward |
| Hollow approach | About 10 optional road units | A fair secret within the existing boundary |
| Journal page | 1 appended page | Three discovered-memory slots, no new menu/tab |

The bridge repair, grove restoration, mirror puzzle, two additional caches and new
enemy profiles belong to later milestones. Their future reward IDs can be reserved
without spawning inaccessible placeholders or new task markers now.

## 3. First-visit flow

1. Adam arrives beside the rift. The Waykeeper turns toward him, but no dialogue
   starts automatically and movement is never held for a greeting.
2. The road remains obvious. A worn marker near the first bend is readable if the
   player approaches it. The player may ignore both guide and marker entirely.
3. At the western junction, a few pawprints lead to Bramble Grove. The cat is visibly
   doing something before the player reaches its interaction radius.
4. Approaching the cat interrupts its ambient routine. A deliberate challenge pose
   and nearby prompt make the optional duel clear. Taming still starts immediately
   from an accepted E/tap; no waiting for an animation or extra prerequisite.
5. Exploring around the grove reveals a second memory. Returning toward the watchpost
   exposes the familiar winch and a subtle clue along the rootway.
6. Following that clue reaches the western hollow and its cache. Opening it gives
   explicit carried/banked feedback and permanently records its location.
7. The eastern route introduces Dusk Moth through glowing plants and a different
   habitat routine. The final memory is nearby and can be read independently.
8. The player can visit the checkpoint, face the boss, or leave. All three memories,
   the wisp and the cache remain optional and can be found in another order.

No route, pet, cache or fragment is available only during this particular sequence.
A Continue that starts at the citadel checkpoint must still support the full update.

## 4. Spatial reservations

These are proposed centers; actual placements require collision and rendered review.
World coordinates are current compact-map coordinates, not texture pixels.

| Object | Proposed center | Placement intention |
|---|---|---|
| Waykeeper | (22,45) | Off the arrival walking line, separated from the return rift |
| Road memory | (29,43) | A quiet roadside bend before the main guard area |
| Grove memory | (10,31) | A nonblocking marked trunk outside the cat's duel staging |
| Moonpool memory | (49,30) | A small clear patch beside the eastern branch |
| Hollow/cache | (8,24) | A roughly 5x4 pocket west of the rootway |
| Cat challenge anchor | Existing (12,35) | Stable, clear staging independent of its patrol |
| Moth challenge anchor | Existing (44,27) | Stable, clear staging independent of its flight |

Keep approximately an 8x7 staging reservation around each habitat anchor, with
Adam's watching position and both duelists' ground positions inside clear space.
Place tall scenery behind it and avoid adding new collision inside the reservation.
Separate interest-point touch targets from the pets and existing winch/camp/rift.

The hollow can use a short spur from around (17,28) through (13,26) to (8,24).
Reserve the walking corridor and pocket before generating trees. The main road
must not become longer, and the pocket must not encroach on the boss arena.

The current geography also permits northern approaches around the root barrier.
Treat an early discovery from that side as valid exploration. The winch offers a
shorter route rather than an unexplained lock on a visible cache. If a future design
requires exclusive access through the winch, it needs actual enclosing geometry,
not just a flag check on the box.

## 5. Waykeeper: a character with a narrow purpose

### Role and appearance

A small lantern-like woodland wisp remembers the old road. It is a local inhabitant,
not a missing friend, quest vendor or recruit. Its silhouette should be distinct from
Dusk Moth and from tiny ambient insects. It floats just off the ground and turns
toward Adam; Reduce Motion uses a stable pose and steady light.

Its ground anchor stays beside the path. It never escorts the player, blocks the
rift, pursues Adam through the map or gives currency for repeated conversation.

### Interaction

Use the existing E/direct-tap convention. A visual acknowledgement may happen when
Adam first approaches, but text appears only after deliberate interaction. Offer one
short response at a time, with no dialogue-choice menu or mandatory camera movement.

Suggested response priority and draft copy:

| Condition | Response |
|---|---|
| Boss defeated | "The road is breathing again. Some quiet places are still waiting to be found." |
| All three memories found | "Those lights belonged to the road. The citadel gathered what the forest lost." |
| At least one realm pet bonded | "A little trust can travel farther than a bright lantern." |
| At least one memory found | "The stones remember. You need only stop long enough to read them." |
| First meeting / no discoveries | "Old stones lead to the citadel. Small lives still shelter beside the road." |

Responses describe the world, not a checklist. Repeated interaction has no material
reward. A saved `waykeeper_met` flag controls its discovered map presence; greeting
poses are transient. No campaign rescue or ending flags change.

Game.open_dialogue() currently excludes Dungeon worlds, including TwilightRealm.
Use a narrow realm-safe caption route instead of removing that global context guard.

## 6. Bramble Cat: territorial and approachable

### Habitat and routine

Give the clearing a low resting trunk or perch behind the usable floor, a scratched
post and sparse brambles around its edge. None of these should pinch the approach.

Use a short, predictable routine: rest for roughly 4-7 seconds, walk a short ground
arc, inspect/sniff the post, then return. Start with two or three authored waypoints
within about 1.3 units of the home anchor. A slow grounded movement around 0.4-0.6
units/second is a starting tuning range, not a final measured requirement.

When Adam approaches within roughly four units, the cat stops at its current safe
position and turns toward him or his companion. It should not run away, despawn,
attack Adam or make the player chase it to accept a challenge. Leaving the area
allows the routine to resume after a short delay.

### Clues and challenge

Use three small clusters of pawprints along the western branch, not a continuous
screen-filling trail. Scratched wood near the clearing provides the final clue.
Keep the marks visually quieter than combat telegraphs.

Inside interaction range, show a concise Challenge/Friendly spar prompt. Accepted
duels keep the existing manual powers, stats, reward transaction and world suspension.
Do not tie challenge availability to the new memory or cache.

## 7. Dusk Moth: a different kind of creature

### Habitat and routine

Add two or three recognizable moon-bloom plants near the pool. The moth travels a
small, slow arc between nearby perches, settles, then opens its wings. Use authored
waypoints within about 1.3 units of its existing home anchor; it stays reachable.

It never flies onto an inaccessible water point or over blocking scenery. When Adam
approaches, it settles or hovers in a visible ready pose. Interaction must work
immediately at the visible actor position rather than waiting for a landing cycle.

### Clues and accessibility

Use a few pale flowers/light buds along the eastern route. Optional particles and
wing glows can enrich them, but static plant shapes still guide players at low effects
or with motion reduced. Tiny ambient insects must not look like more tameable pets.

The later mirror puzzle is not introduced in this milestone. Keep the moth clearing
available and avoid planting puzzle-looking switches that cannot do anything yet.

## 8. Moving-pet integration and identity

The current challenge stages Adam and both duelists relative to the wild actor's
current position. A moving actor could therefore stage a duel inside a tree or pool.
Change staging to use the canonical habitat challenge anchor, while preserving the
real pre-challenge positions for cleanup.

On accepted challenge: release held actions, create the existing validated session,
suspend the world, save relevant transforms/presentation state, and stage at that
fixed cleared anchor. On close: restore transforms, camera, actor state and controls.
Return the pet to its notice pose while Adam is still nearby. Never restore a patrol
by snapping it to a random new point or executing an old tween after the duel.

Ambient routines and timer/tween state are runtime-only. They do not need per-frame
saves or saved actor positions. Reduce Motion can stop at a valid idle pose; it must
not make the actor harder to find or challenge. Companion behavior/rewards stay intact.

Handle a same-pet visit deliberately: if Adam's active owned companion is the named
habitat pet, avoid rendering and dueling a duplicate of that animal. Use the habitat
as a friendly rest/bond interaction while that companion visits. With another active
companion, an already-bonded habitat can retain the existing non-rewarding friendly
spar against a clearly labeled local resident. Do not create another owned pet ID,
change saved recruitment, or pay another first-win reward to solve a visual issue.

## 9. Three memories: short text with a coherent discovery

Memories are environmental props: a road marker, an engraved trunk and a weathered
moonpool tablet. Each is deliberately read with E/tap. They are not floating currency
pickups, forced cutscenes or mandatory quest steps. Display a clear read/unread state.

Draft copy:

### The Road That Shone (`memory_road_lights`)

"We lit the road for every traveller. Fox, moth and stranger alike could follow its
warmth home. The citadel's light once answered ours."

### When the Bells Fell Silent (`memory_silent_bells`)

"The bells fell quiet before the trees darkened. Small creatures gathered where the
last lanterns burned. We left those clearings undisturbed."

### A Light Below the Throne (`memory_stolen_light`)

"The road did not lose its light. Something drew it inward, beneath the citadel.
When its windows brightened, the forest grew cold."

Each passage can stand alone, and none is numbered in the world. Together they
reframe the boss as the source of the forest's loss, while adding no new claim about
Arjun, Mei Ling or the cause of their established shipwreck/rescue story.

First deliberate read saves that fragment ID immediately. Reading again is free
and pays no Gold/XP. No single-use prop disappears before its save is accepted.
The player can find the third passage first, skip all of them, or read them after
boss victory. Copy can be refined during rendered review before shipping.

## 10. Reading and journal presentation

Use an owned, dismissible realm caption for short interactions, without locking
movement or pausing simulation. The current survey updates area hints every 0.4
seconds, so it must not overwrite a passage the player just chose to read.

Caption priority: defeat/critical boss warning -> challenge's own UI -> deliberate
memory/Waykeeper interaction -> ordinary landmark guidance. Clear interaction text
on dismissal, world replacement or leaving its vicinity; all read text remains in
the journal. A boss activation may replace the caption immediately.

Append one "Memories of Twilight" page to the existing Story & Sea section of the
Field Guide. Preserve existing page order. Show three fixed slots; unknown slots
say "Not yet discovered" without revealing their locations or text. Found slots
contain the full passage. A simple illustration fills in as memories are found;
its completion is derived from the three IDs, not a separate currency or reward flag.

No permanent counter is added to the combat HUD. New interest icons appear on the
expanded map only after their actual discovery, not merely because a terrain cell
was revealed. Pet map markers remain attached to stable habitat anchors.

## 11. The rootway hollow and its cache

### Discovery and contents

Keep the pocket small: a bent old road marker, a displaced root and one restrained
glint should make a nearby player curious. The entrance must be visible without
requiring a rare animation, audio cue, pixel-perfect tap or deliberate wall clipping.
Use a fallen trunk or root hollow to frame a single small coffer.

Cache ID: `cache_rootway_hollow`. Contents: exactly 25 Gold, paid at most once per
journey after successful banking. This is currently one Health Potion's shop price,
so it is useful without creating a weapon, currency or upgrade system. No additional
supplies are introduced by this milestone.

The cache does not require all memories, meeting the wisp, taming a pet or clearing
the boss. Opening it is a normal nearby interaction. The game validates the current
world, living actor, range and unobstructed access; a wall must not permit remote
collection simply because the point is within the interaction radius.

### Reward states

| State | World presentation | Accepted transition |
|---|---|---|
| Unknown | Subtle environmental clue | Approach/discover -> known |
| Known, not collected | Closed cache | Accept claim -> pending or banked |
| Pending during an uncleared active expedition | Open, carried feedback | Bank -> permanent claim; defeat -> known again |
| Banked | Open/empty cache | No further payout |

When the realm is uncleared and an expedition is active, atomically add 25 unbanked
Gold and the pending cache ID, then save once. Reload reconstructs the open pending
cache and existing loot rather than awarding again. Banking commits both wallet
Gold and its permanent claim before saving; losing the expedition clears the pending
claim with the loot so the reward can be tried again.

When the realm is already restored, bank the 25 Gold and permanent cache claim
together immediately. Apply this to the current post-boss visit and later peaceful
revisits, even if start_expedition() created an otherwise empty active expedition.
The current code ends the expedition on boss victory but preserves realm presence;
that must not make a missed cache silently grant nothing.

The accepted claim is recorded before any animation or emitted callback. Two taps,
simultaneous touch/mouse events or a duplicate completion cannot award twice.
First opening feedback says either "25 Gold carried — return to bank it" or "25 Gold
banked." Reopening an empty box makes its state clear. Do not use the no-op toast API.

## 12. Save data and code boundaries

Proposed durable state:

- `realm_progress.waykeeper_met`: bool.
- `realm_progress.discovered_content`: known interest IDs for map presence.
- `realm_progress.read_fragments`: the three known memory IDs.
- `realm_progress.banked_caches`: known cache IDs, one exposed in this milestone.
- `expedition.pending_caches`: known IDs whose Gold is present in that expedition.

Defaults and sanitization allow old saves to load without losing checkpoints,
discoveries, companions or rescue flags. Accept only known IDs, remove duplicates,
and reconcile pending/banked state so an already banked cache cannot remain payable.
Do not infer cache ownership from how much Gold happens to be in an old save.
The configured reward comes from the content definition, never an amount supplied
by a UI callback. Existing ordinary enemy loot and XP rules remain unchanged.

Suggested ownership:

- A small `RealmContentDB` holds the new IDs, provisional placements, copy, reward
  and habitat waypoint/pose definitions. Existing RealmDB anchors stay authoritative.
- A `RealmWildPet` subclass of RealmInteractable owns bounded ambient routines,
  notice poses and local-resident presentation. Keep `wildlife[id]` and the existing
  challenge API compatible.
- Narrow Waykeeper/interest components own presentation and accepted E/tap routes.
  Game/world code validates live actor/world/proximity; GameState validates and owns
  all durable mutations, banking and duplicate-claim protection.
- TwilightRealm builds these components and owns caption priority, clear staging
  reservations and hollow topology. Do not put an entire dialogue or quest engine
  into it or change village NPC routing for this update.
- WildPetChallenge uses fixed habitat staging, preserving its existing cleanup and
  world suspension. Content callbacks after awaits verify world/actor ownership.

Keep decorative trees separate from village ForestTrees and preserve the village's
original RNG/ID associations. New scene art uses stable AssetRegistry/PixelArt keys
and independent scenery randomness. No runtime writes to authored source resources.

## 13. Build and review order

1. Reserve habitat staging, fragment approaches and the hollow's actual walkable
   corridor. Verify routes, main-road length and all nine onward passages.
2. Add content definitions, defaults/sanitization and cache bank/loss transactions.
   Prove reward behavior before coupling it to visible opening animations.
3. Implement cat/moth routines and fixed-anchor challenge integration. Review both
   creatures with motion on/off, before/after bonding and with the same pet active.
4. Add the Waykeeper and owned caption presentation; verify no forced greeting or
   control lock and no landmark-hint overwrite during deliberate reading.
5. Add the three fragments, journal page and discovery-gated map icons.
6. Place the hollow cache, environmental clues and final habitat props; then review
   the entire sequence from a fresh journey, an old checkpoint and a cleared realm.

This is one complete milestone. First review should establish that creatures feel
alive, a curious detour pays off, and the fragments make the citadel more interesting.
Do not add the next milestone's puzzle switches or restoration objectives midway.

## 14. Completion checklist

- Both pets remain guaranteed, visible, reachable and immediately challengeable.
  Patrols stay inside clear bounds and return reliably; reduced motion preserves access.
- Duels stage at cleared fixed anchors from every ambient pose. Win, loss, cancel,
  Settings, active-pet changes, defeat and world replacement restore all ownership.
- Same-pet visits do not present a self-duel or duplicate owned/recruit rewards.
- Wisp interactions never gate travel, award currency or overwrite rescue progression.
- Memories work in every discovery order, reread cleanly and persist through Continue.
  Journal unknown slots do not reveal hidden sites. Caption ownership survives a
  landmark boundary, and critical combat information still takes priority.
- Cache tests cover unopened/pending/banked, immediate duplicate attempts, defeat,
  banking, reload, boss completion, peaceful revisit and malformed/old save data.
- New objects cannot be collected remotely through walls. All new paths and staging
  positions are collision-clear for Adam and his companion; shortcuts update routes.
- Actual renders and real injected taps at 1280x720 and 832x480 show distinct targets,
  readable captions, correct perch/ground support and unchanged full boss framing.
- Full isolated gameplay and focused save/render/restart checks pass. Update
  tide_test and ACCEPTANCE_TESTS with implemented changes. No phone/export/performance
  claims come from this plan, and no permanent check tally is assumed.

## Evidence limits

This specification comes from source inspection of the compact layout, current
RealmInteractable behavior, WildPetChallenge staging/cleanup, terrain/decor generation,
realm captions/survey, expedition banking and the existing Field Guide UI. Proposed
positions, waypoint speeds and draft copy have not been rendered or playtested.
Only planning documents are changed; no gameplay or tests were modified or rerun.
