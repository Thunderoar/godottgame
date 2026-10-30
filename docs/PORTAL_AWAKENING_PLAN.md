# The Road Remembers — the Dimension Portal's origin

2026-10-30. Planning baseline: current source at `aaec9ab` on `main`.
Status: implemented 2026-10-30. The original design below is retained as planning
context; see `docs/PORTAL_AWAKENING.md` for the shipped flow and ownership, and
`docs/ACCEPTANCE_TESTS.md` for current verification evidence.

## 1. The central decision

The village begins without an active portal, complete arch, portal prompt or map
icon. Its existing portal clearing contains an overlooked, broken waystone: a
short fallen marker, shallow road carvings and the remains of a lantern socket.

Adam and Pak Rahim discover that it belonged to the same travellers' road whose
light was stolen by Chaos Citadel. Adam repairs its orientation and supplies an
ordinary village lantern. The old route reconnects, and the Dimension Portal
forms for the first time in the player's journey.

The cause is concrete: an incomplete route regains its local anchor and light.
The player's investigation and repair cause the appearance. A timer, level,
purchase or monster kill does not conjure it into the village.

The emotional movement is: BESUT shelters Adam; Adam notices a possible lead;
Rahim freely helps him investigate; their small act of care opens a way forward.
Adam can search for his friends while remaining part of the village.

## 2. What is established, and what this adds

Current source already establishes:

- Rahim welcomes Adam without debt, admits he has not seen the other friends,
  and asks him to meet his neighbours. He does not know their captors.
- Twilight's road once welcomed travellers. Its citadel answered its lights.
  Later, the citadel drew that light inward and the forest grew cold.
- Twilight's arrival, habitats and lantern are protected from regular guards.
- One village gate currently exists immediately; the first campaign stage is
  already logically unlocked. There is no discovery or opening transaction.
- The minimap draws its portal from the layout anchor independently of the actor.
  Hiding the actor alone would still disclose the gate.
- The current three active stages and both friend rescues already work.

Proposed connecting history:

- BESUT once held a small endpoint of that travellers' road.
- A fallen waystone and extinguished road lantern broke the local connection
  when the citadel took the road's light. The remnants later became overgrown.
- The road can accept a modest new local light. Reopening the entrance does not
  restore the distant forest; defeating its ruler remains necessary for that.
- The stable road opens into Arrival Glade's existing protected endpoint.

This adds a local explanation, rather than claiming the Kraken caused the
citadel's corruption or that Adam has a unique magical bloodline. Neither claim
is supported or needed. Rahim knows an old village story; Wisp later understands
the wider history. Nobody in BESUT suddenly knows where Mei Ling is imprisoned.

## 3. The intended playable sequence

### A. Arrive somewhere ordinary

Keep the illustrated opening, dock welcome and peaceful first day. At the old
portal location, show only low broken stone and a weathered lantern socket.
Use the authored `monster_portal` anchor so saved placements and forest identity
remain valid. There is no upright gate silhouette, swirl, portal sound, glow pool,
entry hotspot or destination label.

The clearing is reachable, with a continuous walkable approach. It should look
like a neglected piece of village history, not an obviously ready magical machine.

### B. Give the player something worth noticing

On approach, the shallow carvings catch the light and an unobtrusive interaction
reads "Examine the old stones." At dusk, a brief line of pale light follows one
carving and stops at the fallen section. This can recur quietly until examined.
Neither effect creates enemies or modifies the night schedule.

If the proposed fire-arrival portals are implemented, their torn edges can share
one restrained rune shape with the carving. Adam may comment on the resemblance
only after actually witnessing a relevant arrival. This is an optional clue, not
proof that the first boss commands every village invader.

Target first discovery around the player's first settled village exploration or
first defense. This is a pacing intention to test, not a required night number.
Players who investigate during daylight can progress immediately. Quiet nights,
tutorial Skip, defender kills and missed cinematics cannot block the route.

### C. Examine the incomplete road

A nearby tap/E gives a short, non-pausing observation:

> A line runs through the stones, then breaks where the marker has fallen.
> There is an empty lantern socket beside it.

Adam recognizes a physical problem, not a destination or rescue solution. Record
the discovery once. The map can now show a modest "Old Waystone" landmark rather
than a portal icon. Guidance becomes "Ask Rahim about the old stones."

### D. Let Rahim help without becoming an oracle

Add a contextual conversation to the actual dock host. Preserve the existing
welcome; this is a later conversation and follows ordinary non-pausing rules.
Keep it brief, player-paced and clearly separate from the welcome's final line.

Suggested exchange:

> Adam: "There are road marks by the fallen stone. They stop at a lantern socket."
>
> Rahim: "My father called it a waystone. Said there was a road into the woods,
> once. I thought it was only a story."
>
> Adam: "If the road is still there, someone beyond it might have seen my friends."
>
> Rahim: "Perhaps. I can't promise what you'll find. But we can set the marker
> straight. Take a lantern from the village rack. You can bring it back when
> you're ready."

The loan is recorded as story progress, not a consumable inventory item. It costs
no Gold, diamonds, pet purchase, house upgrade or workshop completion. No new
resource, crafting menu or fetch hunt is needed. The workshop remains a reward
after the first boss, avoiding a circular prerequisite.

Use conditional reminders if Adam speaks to Rahim before examining the site.
They must not mark the discovery complete or give him knowledge he has not gained.

### E. Make opening a deliberate action

Returning to the site offers "Set the marker and light the road."
The player sees a concise explanation: "An old path may still answer. You can
return through the light." The action opens the road; it never auto-enters it.

For the first version, use one short contextual action rather than a rotation
minigame, three beacons or a resource checklist. Adam braces the fallen marker,
turns its carved line into alignment, and places the borrowed lantern. Each
visible action has a readable result. Do not play a generic portal explosion.

The action can be attempted in daylight or darkness after the discovery and chat.
If nearby enemies or an active danger warning make a brief presentation unsafe,
show a persistent local "Clear the area before tending the waystone" explanation.
Never use a toast for this requirement and never demand that the whole forest
be empty. Assess enemies able to reach the interaction area, with a provisional
eight-world-unit radius, and nearby pending arrivals; tune it in actual play.

### F. Let the player watch the connection form

Suggested first reveal: approximately 8 seconds, subject to animatic review.

| Time | Picture | What it communicates |
| --- | --- | --- |
| 0.0–1.5 | Marker settles upright; the lantern is placed. | Adam performed the necessary repair. |
| 1.5–3.0 | A small warm line follows the now-continuous carving. | The circuit works because its gap was repaired. |
| 3.0–4.5 | A pale answering light appears within the old stone outline. | Something on the far side has responded. |
| 4.5–6.5 | Broken stone shapes resolve into the familiar arch; the surface reveals leaves and an old road, then settles into its swirl. | This is a passage to a place, rather than an enemy spawn or explosion. |
| 6.5–8.0 | Hold the stable doorway, lantern and Adam in the real clearing; restore the normal camera. | The player decides when to enter. |

Use the game's pixel-art scale and existing final portal silhouette. Site dressing
can be exchanged for the finished arch through controlled animation; no simulated
rubble, terrain deformation, player teleport or crushing collision is necessary.
Frame the actual authored site, including relocated player layouts, rather than
an unrelated full-screen illustration. Avoid a white flash or mandatory new music.

Game temporarily suspends the current world and shared clock for this deliberate
story event, releases held actions and owns camera/HUD restoration. No tree burns
or hidden raid advances while the player watches. Do not reuse normal modal locks
as a substitute for world suspension. Ordinary later conversations remain unpaused.

Skip is available immediately and reaches the same stable open gate. Reduce Motion
shows readable aligned-stone, answering-light and open-gate tableaux without camera
travel, spinning stones or flashing. Low effects and mute retain the causal steps.

### G. Give the opening its first payoff

After the reveal, the prompt becomes "Enter Twilight Wilds" and the existing
portal map icon becomes available. No loot or XP is awarded for opening it.
Adam remains beside the gate with control restored.

On the first visit, Wisp can say:

> "A village lantern. I haven't seen that light on this road for a long time."

That confirms the connection without replacing the optional memories. Their
existing stolen-light story then explains the ruined realm gradually. After boss
victory, both endpoints can take on warmer light. The village doorway stays open;
its continued existence is the visible result of the player's action.

## 4. Keep the two kinds of portal readable

| Feature | Fire-monster arrival tear, if implemented | Restored travellers' road |
| --- | --- | --- |
| Cause | A temporary hostile breach; wider origin remains unknown | A repaired waystone and a supplied local lantern |
| Appearance | Small, ragged, ember-coloured, unframed | Full stone arch, steady rune outline and anchored lantern |
| Lifetime | Admits its allocated monster and closes | Persists for the journey |
| Player action | Defend against the arriving creature | Deliberately open, enter, explore and return |
| Map | No lasting icon | Icon appears after opening |
| Relation to BESUT attacks | Presentation of actual existing arrivals | Does not become a village monster spawner |

Do not imply that closing the first realm stops all future village attacks.
The protected road and hostile tears use different routes. The first boss's
defeat restores Twilight Wilds; ordinary village defenses remain meaningful.

## 5. State, save and migration design

Keep gate appearance separate from campaign-stage eligibility. Portal 1 may
remain the first unlocked campaign definition, while traversal additionally
requires a restored entrance. Both the actor and GameState validate that rule.

Proposed GameState-owned `portal_origin` record:

- `schema`: 1.
- `site_examined`: false for a new journey.
- `rahim_consulted`: false until the contextual chat completes or is explicitly skipped.
- `opened`: false until the valid opening action commits.
- `reveal_seen`: false until the reveal completes or is explicitly skipped.

Derive the presentation stage instead of saving a second stage string:
unexamined remnant -> discovered site -> prepared site -> open gate. Restored-world
appearance derives from the existing first-portal cleared flag.

Use transactional APIs for discovery, chat completion and opening. Validate the
current world, journey, player, distance, context and prerequisites. No inventory
relic, kill counter, night number or per-frame progression writes are required.
Mark `opened` and save before the cinematic starts. A crash cannot undo the
achievement. On Continue, an open gate with an unfinished reveal is already usable;
offer an optional replay at the site, never force a repeated camera takeover.
Completion records `reveal_seen` only if the owning world/journey still match.

Inspect the raw save before recursive defaults merge. A save that lacks the new
record predates the discovery feature: grandfather it to an open gate, with the
prerequisites and reveal treated as complete. Existing players already had access,
even if they never entered. They should retain it. New saves carry explicit false
fields, including when the introduction was skipped.

Existing active expeditions, realm presence, first-portal clears, successor clears
or Mei Ling rescue must also imply an open entrance if an explicitly present but
inconsistent record says otherwise. Sanitize malformed fields and unknown schemas
deliberately; do not reinterpret a future schema as a new locked journey.

Opening does not start an expedition. Entry uses the existing expedition flow;
defeat does not reverse discovery or close the gate. New Journey resets origin
progress along with the rest of the journey. Device preferences stay separate.

## 6. Tutorial, guidance and presentation integration

- Preserve the ten tutorial event IDs. The existing portal-entry lesson changes
  its text/target according to discovery stage: examine stones, speak with Rahim,
  tend the waystone, then enter. Opening alone does not send the `portal` event.
- Permit investigation independently of the current tutorial lesson. The current
  phase-filtered mission event mechanism must not be the only progression store.
- Portal discovery and first entry must be legible during day as well as night.
  Remove the portal-entry lesson's night-only presentation restriction while
  preserving truthful fire-defense guidance. Check the phase transition behavior.
- Tutorial Skip hides guidance, not the interactables or the means to open the road.
  Support can be rediscovered through the site, Rahim and the normal Missions panel.
- Before opening, village rescue/pet guidance must not point at a nonexistent
  usable gate. Prefer actual current defense, the discovered site or Rahim.
- Update both picture-map sizes and any title/backdrop art that depicts this gate.
  Do not change the authored anchor just to hide its icon.
- Reword the intro's early promise to search for the friends, removing its current
  reference to "the final portal" before Adam has discovered one. Keep the dock
  welcome's uncertainty and unconditional hospitality.
- The Field Guide distinguishes discovered facts from later tactical guidance.
  Early text can describe an old waystone; destination/entry instructions become
  available after opening. Avoid revealing the full new origin before discovery.
- Once open, retain levels 1/3/5, both later arenas, rewards, pet battles, saves,
  boss thresholds, peaceful revisits and separate Arjun/Mei Ling rescue paths.

## 7. Expected implementation ownership

| Owner | Planned work |
| --- | --- |
| `scripts/autoload/game_state.gd` | Defaults, raw-save migration, sanitization, transactions and traversal checks |
| `scripts/world/lobby.gd` | Stage-dependent site construction at the existing anchor; guidance and refresh |
| Proposed `scripts/world/portal_origin_site.gd` | Nearby examination/opening interaction and presentation state |
| `scripts/world/portal_entrance.gd` | Existing usable entrance only after opening |
| `scripts/game/game.gd` | Opening presentation ownership, suspension, cancellation and input restoration |
| Proposed `scripts/ui/portal_awakening.gd` | A single deterministic reveal timeline using the actual site |
| `scripts/world/dock_host.gd`, `scripts/ui/dock_conversation.gd` | Contextual Rahim conversation and honest reminders |
| `scripts/data/mission_db.gd`, HUD/tutorial guidance | Stage-aware portal lesson and day/night behavior |
| `scripts/ui/village_minimap.gd`, map/title presentation | Hide undiscovered gate, show discovered site, then show usable gate |
| `scripts/data/realm_content_db.gd`, story/guide data | Brief Wisp recognition and consistent knowledge progression |
| `tools/`, `docs/ACCEPTANCE_TESTS.md` | Updated rules and isolated gameplay/render evidence |

Inspect existing portal-related fixtures before changing them: several currently
assume an immediately present gate. Tests concerned with later combat should use
an explicit already-open fixture; the new-journey integration test must actually
perform discovery, conversation, repair and entry.

## 8. Implementation order and acceptance

1. First build a rough reveal in the actual clearing using existing art and text.
   Review whether the repaired line, answering endpoint and stable arch explain
   themselves. Validate layout clearance before commissioning final art.
2. Add the progression/migration transactions and conditional site. Prove a new
   journey lacks traversal while existing saves retain access.
3. Connect the brief Rahim exchange, stage-aware guidance and manual opening.
4. Connect the deterministic reveal with Game's suspension and cleanup rules.
5. Update story/guide/map/title inconsistencies and the affected acceptance rules.
6. Run isolated import, the canonical gameplay gate and focused new-origin checks.
   Render the full journey at 1280x720 and 832x480; inspect consecutive reveal frames.

Required cases:

- New Journey, intro Skip and tutorial Skip all begin without a usable portal.
- Approaching/examining a site cannot enter Twilight or start an expedition.
- Early daytime exploration, quiet nights and no fire kills can all open the road.
- Rahim does not know the destination/captors or complete an unexamined discovery.
- Opening costs nothing and is possible without the post-boss workshop or upgrades.
- Actual nearby danger blocks the short action with visible local feedback; an
  unrelated distant enemy does not permanently lock the opening.
- Night arrival, shore/fire cinematics, story, sailing, recovery, a modal and
  settlement editing cannot acquire competing camera/input ownership.
- Skip, low effects, mute, Reduce Motion and live settings retain a readable reveal.
- Reload before discovery, after the chat, after opening commit, during the reveal
  and after entry preserves the correct state with no rewards or duplicate gate.
- Legacy saves with no new record retain entry, including active Twilight visits
  after loot banking and ongoing later-stage expeditions.
- World replacement, death, New Journey and invalid async callbacks cancel only
  their owned presentation and never restore an obsolete world or player.
- Player-relocated portal anchors, original forest fixtures, nearby routes and
  direct tap/E interaction remain correct; no new remote opening hotspot appears.
- Both map sizes hide the gate before opening; guidance never targets invisible
  traversal; the normal gate appears only after successful opening.
- First entry, manual pet battles, boss retreat/victory, safe return, defeat,
  peaceful revisits, later arena access and both friend rescues still work.

All test/save/capture work uses the existing Windows isolation wrapper and external
evidence directories. Record actual results when implemented; this plan provides
no new test PASS, measured visit length or physical-device claim.

## 9. Deliberate scope boundaries

The first version is one site, one short discovery exchange, one opening action
and one reveal. It introduces no additional boss, summonable wave, compulsory
kill quota, paid key, rare drop, house-tier requirement or global invasion origin.
The variable-night and fire-arrival documents remain independent proposals. This
origin works with today's actual spawns and with future quiet nights.

The player should be able to explain the result in one sentence: "We found the
broken road, gave it a light, and something on the other side answered."
