# BESUT village progression: source audit and proposed design

Status: audited design, 29 October 2026. The complete first workshop slice is now
implemented; see [VILLAGE_WORKSHOP.md](VILLAGE_WORKSHOP.md) for shipped behavior
and validation. Later district proposals below remain design work.
The [deep audit](VILLAGE_PROGRESSION_AUDIT.md) records findings and evidence.

Inspected the working tree at commit `263edaf` on `main` in
`C:/Users/LUQMAN/Documents/tournamentgame/godottgame`, including the local opening
and dock-arrival changes. Existing edits were preserved. Source and resource
inspection was the initial evidence. A subsequent isolated headless audit at
`32f92c1` passed 14 targeted checks and exercised the actual XP/catalog APIs,
ruin repairs, physics routes and resident refresh behavior. It did not run the
full gameplay gate or produce new visual captures.
The existing `docs/evidence/illustrated-coast-2026-10-29/village.png` was inspected
for spatial context and is historical evidence, not a new capture.

## 1. Design conclusion

BESUT already has the parts of a growing village, but its current progression
mostly strengthens an already populated village. Shops, occupations, houses,
specialists, gates and harbour are built when the Lobby loads. Plot progression
unlocks the next dungeon and returns friends; it does not yet coordinate civic
projects, service expansion, household arrivals or changing neighbourhoods.

The proposed loop is:

**Meet someone → understand a local need → achieve a story milestone → choose a
restoration project → see people use the restored place → gain a useful option
for the next adventure.**

Keep the welcome generous. The villagers gave Adam shelter before he earned it.
Basic care, a working cottage, basic equipment, companion care and an initial
forest-defense crew should be available from arrival. Expansion should express
belonging and collective recovery. Do not turn the opening into a debt contract.

Use three distinct forms of progression:

- **Story milestones:** permanent achievements that reveal opportunities.
- **Village projects:** specific places and services the player chooses to restore.
- **House tier:** the existing shared quality tier for homes, fences, purchased
  rooftop guns, recovery and worker baseline.

Do not make a second universal village-level number that duplicates house tier.
Do not make every boss victory demand another house purchase to continue.

## 2. What actually exists

### Merchants and services

| Entity | Current function and gate | Useful progression role, proposed |
| --- | --- | --- |
| Mara, Potion Shop | Health potions, 25 Gold each; stock selected by shop category. Available from the start. | Reliable early care; later herbal-workplace restoration can improve the service or introduce a deliberately designed new supply. Additional potion products do not exist yet. |
| Garrick, Equipment Shop | Gear filtered by the player's discipline, shared armour/shields, Gold weapon upgrades through +5, wood sales and rooftop gun purchases. Purchases mainly depend on funds/ownership. | Basic smith at arrival; later forge commissions reveal higher equipment bands. Keep a useful pre-boss weapon available. |
| Nia, Pet Shop | Pet food, 15 Gold; Moss adoption, 140 Gold; owned companion selection, feeding and paid upgrades. Ember starts owned; Luma is a first-portal reward. | Introduce companion care early; attach guardian-related village improvement to the existing duel system. Buying a pet alone does not recruit a village guardian. |
| Bram, Construction Shop | Five-tier main-house preview and diamond upgrades. No story gate currently. | Explain projects, show future opportunities, start paid work, and report benefits and blockers. Preserve the shared house tier. |
| Amina, Worker Shop | Hire water keepers, builders, planters and swordsmen; replace dead slots. One of each starts present. | Describe actual jobs and later unlocked work assignments. Preserve starter specialists and existing hire access in the first implementation. |
| Mission Guide | Tutorial status, arrows and campaign objectives. | Persistent project journal and clear next objective; no separate competing quest tracker. |
| Coastal Guard | Sea-cleaning report; nets rubbish for real Gold through the coastal system. | Shore recovery and harbour project contact. Keep basic rubbish collection available. |
| Unisza Student | Welcome dialogue; no current progression transaction. | Optional local context and project explanation, without inventing an existing research system. |

Sources: `scripts/world/lobby.gd::_build_shops`, `scripts/world/shop_npc.gd`,
`scripts/ui/shop_panel.gd`, `scripts/ui/house_panel.gd`,
`scripts/ui/village_services_panel.gd`, `scripts/ui/mission_panel.gd`,
`scripts/world/special_npc.gd`, `scripts/data/item_db.gd`,
`scripts/data/pet_db.gd`, `scripts/autoload/game_state.gd`.

### Residents: occupations are not all production systems

The authored layout contains these twelve named ambient residents. They have
routes, work presentation, dialogue, shopping and danger/shelter behaviour. These
occupational labels do not imply output inventories, daily wages, food production,
housing assignments or recruitment quests.

| Resident | Current occupation | Proposed local connection |
| --- | --- | --- |
| Sami | Fisher | Shore/harbour restoration, explanation of the sea route |
| Hana | Gardener | Household gardens and Mara's herbal workplace |
| Rami | Carpenter | Bram's project introduction and completion scenes |
| Daud | Woodcutter | Salvaged driftwood and workshop supplies; no live-tree felling requirement |
| Noor | Animal keeper | Nia's companion grounds and animal yard |
| Bilal | Farmer | Kebun/farm district restoration |
| Yusuf | Trader | Market stock and returning trade |
| Tomas | Sea-gate watcher | Harbour defense dialogue |
| Sora | Forest-gate watcher | Forest watch-lodge restoration |
| Amir | Stablehand | Stable/animal-yard life; no current riding system |
| Laila | Household gardener | Restored residential courts |
| Zara | Resident visiting cottages | Household arrival/welcome scenes |

These people already live here. Do not describe them as newly rescued or remove
them merely to reintroduce them as rewards. A later new household needs new stable
IDs, explicit residency state and authored activities.

`Lobby._add_resident()` currently sets ambient residents' `combat_enabled` to
false, including the authored watcher roles. Specialist swordsmen are separate
actors with real combat. A watcher sprite or `NpcInfo` description is not proof
of fighting capability. Any watch-post combat reward must create or assign an
actual defender through supported behaviour.

Ambient resident shopping is presentation: `ShopNPC.ambient_purchase()` increments
an in-memory count and animation. It does not generate player revenue or spend
the player's inventory. Farms, gardens, livestock and horses likewise do not
currently establish a player-facing production economy.

Sources: `data/maps/village_layout.tres::activities`,
`scripts/world/resident.gd::_physics_process`, `::_update_shopping`, `::_run_worker`,
`scripts/world/lobby.gd::_add_resident`, `scripts/creative/personality_profile.gd`.

### Buildings, land and defenses

| Entity | Current behaviour | Implication for expansion |
| --- | --- | --- |
| Main cottage | Enterable; recovery home; persistent damage state `cottage`. Visual/layout ID is `house`. | Preserve recovery and arrival routes; explicitly map layout IDs to structure IDs. |
| Seven residence anchors | East, West, South, North, WestNorth, EastSouth and SouthWest. Persistent structure HP, shelter and rooftop mounting; no individual interiors. | Existing shelter is useful, but there is no household capacity or occupancy system. |
| Four ruin anchors | `AbandonedHouse`, `DamagedHouse`, `DestroyedHouse`, `RuinedHouse`. Spawn as zero-health houses, retaining their stable structure records. | Strong restoration candidates, but they are currently ordinary repair targets. Their authored state descriptions do not create separate quest states. |
| Four fence anchors | Damageable, repairable, shared tier. | Upgrade quality can remain linked to house tier. New coverage needs explicit geometry and path checks. |
| Five market stalls | Existing interactions and collisions; targets created without persistent structure IDs. | Shop availability is not currently modeled by persistent building damage. A shop unlock needs explicit service state. |
| Six garden anchors, animal yard, stable, props | Authored layout, activities and presentation. | Suitable places for future projects; productive output would be new gameplay. |
| Forest | 64 original trees with persistent health/growth and strict stable identity. | Growth must protect the forest; do not clear trees or reorder generation to make room for rewards. |
| Harbour, jetty, ship and turtle | Working campaign route; ocean checkpoints and separate controls. | Harbour expansion should improve an existing lifeline, not silently remove the only sea-rescue entrance. |
| Monster and Pet Battle Portals | Both present immediately. Monster chain has prerequisite/level gates; duels have their own sequence/pet-level gates. | Add narrative consequences without replacing working progression. |

Residence structure IDs are generated as `home_` plus the anchor's snake-case ID,
for example `ResidentHouseWest` → `home_resident_house_west`.

The B/menu settlement editor moves registered existing placeables and saves
positions. It does not buy, instantiate or expand a catalogue of buildings.
Residences are currently ordinary Node2D holders, not registered movable
SettlementPlaceables. Authored developer layouts and saved player layouts are
separate systems.

Sources: `scripts/world/lobby.gd::_build_house`, `::_build_residential_life`,
`::_add_resident_house`, `::_add_ruin_house`, `::_build_fences`,
`scripts/world/settlement_target.gd`, `scripts/world/settlement_editor.gd`,
`data/maps/village.tres`, `data/maps/village_layout.tres`.

### Specialists, companions and returning friends

- Water keepers extinguish/heal trees and attack fire monsters. Planters restore
  fallen trees with protected 30-second saplings. Builders physically travel to
  structures and spend 10 seconds working by day. Swordsmen fight sea urchins.
- Water keeper count is at least house tier, capped at five; other specialist
  counts are at least house tier, capped at eight. Raising house tier supplies
  higher baseline counts, rather than simply increasing hiring capacity. Dead
  worker slots can be replaced. Do not add population caps in an initial patch
  without explicitly reconciling this existing contract.
- House tier controls each structure's reported tier and house/fence appearance,
  purchased gun stats and friend damage formulas. Do not assume every structure's
  maximum HP increases: registration uses its configured maximum HP.
- Rooftop guns are optional purchases for individual intact houses, at
  `180 + 60 × (house tier - 1)` Gold each. A house upgrade does not buy guns.
- The active pet provides support. Winning the five manual pet duels recruits
  distinct rivals into ownership and `village_pets`; those guardians visibly
  defend the Lobby. This is already a good example of adventure changing home.
- Arjun and Mei Ling independently return as real village defenders. They do not
  switch the player's Adam discipline or unlock new playable story starts.

Sources: `scripts/autoload/game_state.gd::worker_count`, `::hire_worker`,
`::upgrade_house`, `::structure_level`, `::buy_roof_gun`, `::_recruit_duel_pet`,
`scripts/world/house_defense.gd`, `scripts/world/village_hero.gd`,
`scripts/pets/village_pet.gd`, `tools/village_upgrade_test.gd`.

## 3. Existing progression and why it feels disconnected

The first-playable opening currently arrives at the dock. The tutorial covers
movement, gathering, buying, inventory, defense, workers, housing, pets and the
first dungeon, with phase-aware day/night selection. Portal 1 ends training even
if some lessons were missed. A lesson event is normally only accepted for the
current lesson, so it is not a general-purpose achievement log.

The ten monster portals require levels 1, 3, 5, 7, 9, 12, 15, 18, 21 and 25 and
unlock in order. The first is displayed as **Chaos Citadel** despite retaining the
stable ID `tidebound_grotto`; the final is **Abyssal Throne**, `drowned_throne`,
whose current boss display name is **Abyss Monarch**. Use catalog names in UI.

Arjun's branch is ship → three ocean routes → Kraken victory → explicitly free
the cage → ship return. Mei Ling's branch is the final monster portal. Both can
currently be pursued independently; both rescues trigger the one-time reunion.
`board_ship()` currently checks world/activity/recovery/emergency conditions,
not a portal-clear prerequisite.

House upgrades currently require an intact cottage and diamonds, with prices
8, 18, 32 and 54: 112 diamonds to complete. A new journey starts with 12 diamonds
and 120 Gold, so tier 2 can be bought immediately. The first six portal first-clear
rewards total 112 diamonds; including starting gems gives 124, before other loot
or replay rewards. Funds alone therefore allow house completion well before the
story ends. This is arithmetic, not a measured time-to-completion claim.

Gold already has renewable sources: driftwood gathers two wood per pile with a
14-second cooldown, wood sells for four Gold each, rubbish pays one Gold, and
combat pays rewards. Gold also funds gear, upgrades, potions, pet care, workers
and guns. A 90-Gold Iron Sword and 25-Gold potion leave only five of the starting
120 Gold, so a mandatory paid project before combat needs another viable funding
route or a free introductory commission.

The missing connection is a persistent answer to: **"What changed in BESUT because
I did that, and what new thing can I do here now?"**

Sources: `scripts/data/mission_db.gd`, `scripts/data/portal_db.gd`,
`scripts/data/house_db.gd`, `scripts/world/resource_pile.gd`,
`scripts/game/game.gd::board_ship`, `scripts/autoload/game_state.gd::complete_portal`,
`::campaign_objective`, `docs/OPENING_WELCOME.md`.

## 4. Proposed story and expansion milestones

These are proposed gates, not current behaviour. Start with district recovery
inside the existing 64 × 40 map. A larger map, new sea geometry and settlement
simulation are separate scope. Restoring one building does not unlock an entire
district's benefits unless those benefits are explicitly authored.

| Milestone | People and place | Proposed result |
| --- | --- | --- |
| Arrival / welcome | Dock, cottage, core merchants, starter specialists | Care, survival and both adventure routes remain accessible. Introduce a local need through a person and show its location. |
| House visit during training | Rami + Bram, existing cottage yard | Introduce the future west-workshop commission and its location. No extra paid chore or separate prerequisite project is needed. |
| Clear Chaos Citadel | Bram + Rami, `AbandonedHouse` in the west | First substantial restoration becomes available. Complete it to open a working annex and license advanced sword stock at Garrick's. Luma retains its existing first-clear reward. |
| Clear portal 3, Glacial Necropolis | Laila + Zara, west residential court | A residential project prepares an additional household/place of work. Existing residents gain destination changes; any actual newcomers need new IDs and designed actors. No automatic tax revenue. |
| Clear portal 5, Infernal Forge | Yusuf + Garrick, market/workshop | Candidate improved forge commissions and a later stock-band design. A distinct benefit still needs specification; do not implement a redundant unlock. |
| Rescue Arjun, present the opportunity on a stable Lobby return | Arjun + Sami + Tomas, waterfront | Existing Arjun defender joins; harbour/watch project becomes available with a useful patrol deployment option. It must work even if inland projects are unfinished. Patrol assignment UI is new scope. |
| Clear portal 7, Thornwood Court | Sora + Amina, forest watch lodge | Forest-response project, better assignment coverage and readable defensive routes. Maintain every original tree identity and starter fire/tree care. Assignment mechanics are new scope. |
| Rescue Mei Ling / reunion | Mei Ling, friends and the village | Existing ranged defender joins; celebration and final restoration choices support continued village life. Ending should not require completing every civic project. |

Keep all existing house-upgrade eligibility and worker rules in the first slice.
The initial proposal's tier 3/4/5 gates at Portal 1 / Portal 5 / both rescues are
withdrawn as implementation defaults. They would also delay specialist supply,
defender damage, gun strength and recovery, and would make tier 5 a post-rescue
reward. Reconsider them only after measuring those coupled balance effects.

The milestone table is a content direction, not a release-ready specification
for later districts. Each later project needs a defined mechanical benefit,
stable footprint, affected actors and cost before implementation.

Portals 2, 4, 6, 8 and 9 can advance dialogue, visually show work/returning trade,
or unlock a small commission. They do not all need a new building or menu. A
later content pass should give each return a specific acknowledgment without
making ten mandatory chores.

## 5. A concrete first project

Working name: **A Roof for the Workshop**. Narrative text is provisional.

1. During the training house visit, Bram explains that the west abandoned house
   could shelter a shared workbench. Rami is already present in the village.
2. The site can be inspected before the first boss. It explains: "Restore after
   Chaos Citadel. Bram needs a safe place for the workbench."
3. First clear of Chaos Citadel permanently marks the opportunity eligible. A
   return notice names the place, person and benefit; no currency is charged.
4. Bram offers the commission, with a preview of the restored exterior and the
   exact equipment it makes available. The first vertical slice should use a
   free commission to validate the loop; later project prices remain unbalanced.
5. The player accepts. A builder reaches the site and works by day using the
   existing 10-second pacing. This is a dedicated project job, separate from
   damage repair. Night, danger and leaving the active Lobby suspend work. A
   player can instead tap the site to begin free on-site work under the same
   conditions. Moving, attacking, damage, opening a modal, sailing, losing focus
   or changing worlds cancels player work and releases held controls. This is
   new behavior; the existing repair interaction only starts a builder timer.
6. Completion restores the building, enables the service, changes Rami's work
   destination and local dialogue if he is alive, and exposes the new stock
   family. Otherwise a living builder uses the workpoint; no named resident is
   resurrected. Derive these effects from one committed project record, then
   reconcile nodes. Wait for the future ground collision area to be clear before
   activating it; zero work remaining may wait for clearance without restarting.
7. Reloading, returning from a portal and replaying Chaos Citadel retain the
   annex and stock. They never charge, recruit or celebrate a second time.

For the first slice, explicitly cover the entire sword catalog. Rusty Sword,
Iron Sword, all current armour/shields, potions, pet care, worker hiring and gun
purchases retain basic access. The workshop licenses Tideblade, Emberfang,
Glacial Edge, Tempest Saber, Thorncrown Blade, Stormbreaker, Soulrender and
Monarch Slayer together. Gold still controls affordability after that initial
license. Restricting Tideblade alone would let players buy a later weapon instead.
Finer chapter-specific bands are deferred; do not accidentally implement them
through arbitrary array order or price comparisons. Legacy non-sword access is
preserved, and rescued friends remain defenders rather than playable disciplines.

Leave the existing +5 upgrades for owned basic swords available in this slice.
Iron Sword +5 has 28 weapon ATK versus Tideblade's 26, but costs 1,065 Gold
including purchase versus Tideblade's 240. This is an expensive alternative,
not a broken prerequisite. First-boss viability still needs actual playtesting.

The stock license is permanent. Later damage to the annex does not revoke the
license or take purchased gear away. Local work/use may pause until ordinary
repair restores the site. The completed annex intentionally retains house
shelter and optional purchased rooftop-gun support; the workshop is an additional
facility role with a distinct sign/workpoint, not a silent change to house kind.

The first project reuses one existing anchor. All four current ruin workpoints
had exact physics-backed routes in the isolated baseline fixture, including
`AbandonedHouse` at (4.4, 10.8). This does not validate a completed project layout
or a player's edited layout. Its authored ruin footprint is 5.2 × 2.1, smaller
than the ordinary residence footprint of 5.6 × 3.8; reserve and verify the actual
future visual/ground extents explicitly. Do not move forest trees to fit it.

## 6. Progression rules that keep this playable

- Reveal future opportunities at their locations and shops. A locked action
  should name one concrete missing milestone/project and its reward.
- Story eligibility is permanent. Damage can disable a completed facility
  locally; ordinary repair restores it without paying the project cost again.
  The first workshop's permanent stock license remains usable at Garrick's.
- Keep progression-critical resources renewable and accessible before their
  gates. Do not require destroying living forest trees for building materials.
- Gold serves repeatable purchases and project spending; diamonds retain their
  established house-upgrade role. Delay new timber economies, food chains,
  research points, taxes and currencies until the first loop works.
- Preserve the existing worker baseline/hire rules in the initial slice. House
  tier can remain shared quality while projects add places, services and route
  options. Population capacity is a later explicit rule change.
- A named resident may die. Essential project management must remain available
  through Bram/the journal/site, with replacement work capability. Do not tie
  completion exclusively to one vulnerable actor or silently revive them.
- Keep ocean-first and portal-first play valid. Once-only unlock processing must
  handle achievements earned before the relevant conversation or site visit.
- Distinguish a commissioned project from an ordinary damaged building. Existing
  builders and repair points must not bypass plot gates, and an upgrade must not
  convert a locked site into a free operational house.
- Existing tutorials teach visits as well as purchases; avoid adding long project
  tasks that prevent reaching the essential fire/portal lessons in their phase.
- Menus do not pause raids. Show concise requirements and nearby destination
  guidance; use existing story ownership only for deliberate short celebrations.
- Project labor advances only in the active Lobby, never through elapsed
  world-clock time, ocean travel, a closed game or loading-screen time. It can
  continue while browsing a menu only when a valid builder is doing the work.
- Do not require a perfect village or every optional duel to rescue friends.
  Existing all-forest-lost game over remains; communicate danger through actual
  persistent UI and world state, since toasts are deliberately disabled.

## 7. Implementation design

Suggested new catalog: `scripts/data/village_project_db.gd` with stable project
IDs, milestone requirements, anchor/structure mappings, costs, work duration,
completion effects, prerequisite projects and explanatory text. This file does
not exist yet. Keep it declarative and return copies like the other DBs.

Persist in GameState, with defaults and sanitisation:

```text
village_progression.schema = 1
village_progression.milestones = { stable milestone ID: true }
village_progression.projects = {
  west_workshop: { state: "working", work_remaining: 6.5 }
}
```

For projects, persist `not_started`, `working`, `complete`; derive hidden/visible/
eligible/funded/damaged status from story facts, catalog and structure state.
Keep structure HP in `structures`. Avoid persisting a second copy of shop tiers
or population counts that can contradict completed projects. Milestones cover
new durable achievements; derive existing portal/rescue facts from their current
authoritative records rather than copying them into another save field.

Suggested GameState API:

- `project_status(id)` returns eligibility, missing requirements, work state,
  price and benefit for all interfaces.
- `start_village_project(id)` rechecks eligibility and funds, deducts once and
  starts saved work in one transaction. No mutation on failure.
- `work_village_project(id, delta)` accepts validated work, prevents multiple
  workers double-counting the same time and completes once.
- `item_purchase_status(id)`, `house_upgrade_status()` and
  `service_status(id)` expose the same reasons used by the actual transactions.

Those names are proposals. Work submission needs worker identity plus current
world/journey ownership, a runtime lease, on-site proximity and one permitted
contributor per physics tick. A bare delta is not sufficient authority. Recheck
the lease, daytime, danger and site at the moment of work. Release claims on
death, shelter, interruption, exit and unreachable-route timeout. Save remaining
work at start, interruption, completion and normal save boundaries, not per frame.
An interrupted hard exit may lose work since the last save; do not claim stronger
durability than the underlying save API provides.

The actual purchase/upgrade methods must enforce
gates; disabling a button alone is insufficient. Price scaling and stock bands
should have a single data source. Weapon upgrade permissions need an explicit
decision too, otherwise unlimited access to +5 may undermine intended gear bands.

Only GameState writes progression. Game owns story/transition sequencing. Lobby
reconciles buildings, interaction availability, residents, worker tasks, markers
and routes from saved state with current-world and journey-serial guards. Never
reload the whole Lobby just to show a completed project: that risks interrupting
combat, actor state and world ownership.

For a new journey's gated site, adapt `SettlementTarget`, repair interactions,
repair APIs and builder task selection together. A pending site should not offer
shelter, gun purchases or ordinary repairs. Project work must not also decrement
`structures[id].repair_remaining`. On completion set full structural HP and
clear the repair timer once. Afterwards damage repair changes HP without changing
project completion or replaying rewards. Ensure live reconciliation updates
collision, nav invalidation, lights, facility art, ambient-shop reservations,
workpoints and map markers coherently. Ordinary house texture refresh must not
erase the annex's facility identity.

Reserve the full future footprint in the runtime layout while rendering ruins.
This alone does not constrain player dragging: SettlementEditor's current drag
logic clamps/snaps but does not check project reservations. Validate placements
against reserved sites and work approaches, and revalidate an old/custom layout
at commission and activation. Do not reset user placements to solve conflicts.
Also check live actor occupancy immediately before collision activation.
Keep player placement overrides and developer resources separate. If the initially
non-destination ruin becomes a work destination, explicitly validate a reachable
approach; changing art or its label alone does not make it navigable.

Reapply project activity destinations after every resolved-layout refresh;
`refresh_spatial_layout()` currently restores Rami's authored waypoints and would
erase a one-off runtime assignment. Apply the same rule when loading or changing
developer layouts. Resolve NPC project dialogue through both interaction paths:
direct mouse/touch NpcInfo currently opens its own role description, while normal
interaction can use AuthoredInteraction lines. Updating only one path misses
players using the other. VillageMinimap currently draws generic house icons for
ruins/residences regardless of repair state, so project markers need explicit
state-aware rendering. MissionPanel also needs a visible-state refresh path.

Extend Bram's existing panel and the mission journal first. Show commission,
work progress and completion there and at the site. Update ShopPanel's signature
to include stock eligibility, so a milestone changes visible cards and stock
without breaking its in-place price refresh or scrolling. A new modal would
need full creation/close/hide/input-lock integration; it is unnecessary initially.

### Existing saves

Adding defaults alone would relock facilities for established players. Introduce
an explicit progression schema marker and detect its absence on the raw loaded
save before recursive defaults merge hides that absence. Grant legacy saves the
baseline services and access they already had; preserve owned gear, tiers,
workers, completed repairs, pets, defenders, layouts and currencies. Use a legacy
entitlement where needed rather than falsely claiming a story event happened.
Offer new optional projects without retroactive charges or duplicate rewards.
An already repaired ruin stays repaired with its shelter and any purchased gun;
offer an optional fit-out instead of destroying it to replay construction. Legacy
advanced-stock access stays available independently of that fit-out.

New journeys use the new project rules. Detect pre-existing saves, not merely
`SAVE_VERSION == 6`, because existing load behaviour merges defaults rather than
performing a version-switch migration. Project schema and migration tests are
part of the first implementation, not cleanup for later.

Arjun eligibility derives from the existing saved rescue flag. Present it only
when a current Lobby is ready and no transition/story/sailing owns the scene.
Do not require the transient `_arjun_returning` flag to have completed: reloading
after the island rescue skips that runtime choreography. Likewise, record or
derive portal eligibility in GameState, but queue civic presentation until Lobby
return; the final portal hands directly into Mei Ling's rescue and reunion.
The journal must retain opportunities even if a celebration/notice was skipped.

## 8. Delivery order and verification

1. **Model and migration:** one project catalog entry, GameState transactions,
   shared requirement queries and legacy access policy. No world changes yet.
2. **One complete playable loop:** first portal → west workshop commission →
   physical work → restored site → Tideblade stock → persistent journal/map
   acknowledgment. Include affordable preparation and worker-loss recovery.
3. **Observe pacing:** time to first meaningful improvement, mandatory spending,
   first-boss viability, forest health during work, route reachability and whether
   players understand what changed. Record observations rather than inventing
   precise completion-time targets from source inspection.
4. **Add the parallel harbour response:** Arjun return consequences without an
   inland prerequisite; then residential/forest projects and later stock bands.
5. **Only then consider wider scope:** population capacity, productive farms,
   new households, larger map regions or deeper resource chains.

Required acceptance coverage for implementation:

- New journey retains basic shops, recovery, all starter specialists and both
  adventure entrances; dock arrival remains intact.
- Tutorial skip and phase changes do not lose durable project opportunities.
- Locked direct API calls cannot purchase/upgrade/repair around project gates.
- Failed starts deduct nothing; repeated clicks and repeated boss events cannot
  double-charge, duplicate buildings, reset work or grant rewards twice.
- Work requires valid on-site ownership, pauses at night/danger, survives reload,
  releases claims on death/unreachable routes, and has a free recovery route.
- A pending site cannot shelter residents or host purchased guns. Completed
  damaged facilities recover through ordinary repairs without losing ownership.
- Portal-first, ocean-first, Arjun-before-portal and final-portal-before-Arjun
  orders all remain completable; reunion stays one-shot.
- Legacy saves retain prior access and assets; malformed/unknown project fields
  sanitise without creating rewards or overwriting unreadable saves.
- Completion updates stock while its shop is already open, plus map markers,
  workpoints, residents, collision and pathfinding without scene reloads.
- Original forest fixture order, positions, HP associations and RNG stay intact.
- Actual renders at 1280×720 and 832×480 show understandable ruins, work and
  completion states; touch interaction and successive movement frames work.

When rules change, update `tools/tide_test.gd` and `docs/ACCEPTANCE_TESTS.md`
together, extend the relevant village/story/map checks and run the canonical
Windows isolated gate after import. Authoring/bake changes additionally require
disposable-source creative checks. Finish with scoped diff review and
`git diff --check`. None of those runtime checks is claimed by this design audit.

## 9. Decisions to settle during implementation

Recommended defaults are the free first annex commission, Tideblade as its first
entry purchase in a consistently gated advanced-stock family, no new currency,
existing house-upgrade access and specialist baseline preserved, and the two
independent rescue branches retained. Later paid project costs and finer stock
bands require economy/combat measurements. The existing late-campaign XP gap
also needs an explicit preparation/replay plan before expanding chapter gates;
see the audit's calculation. Capacity-based population, new consumables,
production output and a larger map need separate designs.

The first success criterion is concrete: **after returning from the first boss,
the player can help restore a recognisable place, see a living villager use
it, and gain a clearly explained useful purchase that remains after reloading.**
