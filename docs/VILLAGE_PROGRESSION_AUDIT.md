# Village progression plan: deep audit

29 October 2026. Scope: audit the proposed progression design against current
source and isolated runtime probes; revise the design, without implementing
gameplay. The [revised plan](VILLAGE_PROGRESSION_PLAN.md) incorporates these
decisions. The initial inspection began at `263edaf`; the existing dock-arrival
work was committed independently as `32f92c1` during the audit. No game source,
player save or authored map was edited by this audit.

## Verdict

The people → restoration → capability loop fits the existing game. The original
plan was not ready to implement unchanged: its first stock gate was incomplete,
its project work contract was underspecified, and later house gates would alter
several survival systems at once. The revised first slice is narrower and has
explicit ownership, migration and failure rules. Later district ideas remain
content proposals, not validated features.

P1 below means resolve before implementing the affected behavior. P2 means
resolve before claiming that part of progression works end to end. These are
design/integration findings; the proposed project system does not exist yet.

## Findings and decisions

### A1 — P1: a Tideblade-only gate has an immediate alternative purchase

Current `ShopPanel._equipment_stock()` includes the whole matching discipline.
`GameState.buy_item()` checks price, ownership and capacity, not story access.
The probe bought both Tideblade and Stormbreaker before any portal clear using
fixture funds. Restricting just Tideblade leaves every stronger sword available.

**Decision:** first slice explicitly gates the entire advanced sword family
behind the workshop, in both the transaction and the UI. Leave basic armour,
shields, care, hiring and guns available. Chapter-specific bands are a later
design; stock order and price must not implicitly define them. Preserve already
owned equipment and legacy access. Recheck eligibility when a card is clicked,
since displayed state can become stale.

Evidence: `scripts/ui/shop_panel.gd::_equipment_stock`, `::_current_signature`,
`scripts/autoload/game_state.gd::buy_item`; runtime checks 1–2.

### A2 — P1: existing ruin repairs bypass story projects

Every ruin registers as a damaged `house` in the `structures` group. The probe
started ordinary repair at the proposed workshop, then placed the actual builder
at its workpoint and called its existing work logic for two five-second fixture
steps. The site became intact with Portal 1 still uncleared. This verifies the
API bypass, not ten seconds of natural player observation.

**Decision:** pending projects must be excluded from ordinary repair selection,
repair interactions and the GameState repair APIs. Use a dedicated project job
and timer. Never let `repair_remaining` and project work count the same labor.
Completed facilities return to normal damage-repair behavior without replaying
project payment, stock licensing or celebrations.

Evidence: `scripts/world/resident.gd::_repair_buildings`,
`scripts/world/structure_repair_point.gd::interact`,
`scripts/autoload/game_state.gd::start_structure_work`, `::repair_structure`;
runtime checks 5–9.

### A3 — P1: the proposed free player fallback does not exist

The current player repair interaction starts a ten-second timer; it does not
supply work. With the world disabled, the probe confirmed that timer remained
ten seconds after an interval. Reusing that interaction alone would strand a
project when all builders are dead or unable to reach it.

**Decision:** implement actual free on-site player work with cancellation on
movement, combat, damage, modal opening, focus loss and world transitions. One
contributor owns each project at a time. Work requires the current active Lobby,
matching journey, valid actor, safe daytime context and on-site proximity.
Cancel work without discarding already accepted progress. No repeated taps or
synthetic held input may accelerate construction.

Evidence: same repair interaction; runtime checks 6–7. Current builder code has
no explicit unreachable-target abandonment in `_repair_buildings`; tree care
does release an empty-path claim. Do not assume that tree behavior protects
project jobs. `_exit_tree()` releases tree/shop ownership, not a builder claim.

### A4 — P1: delaying house tiers also delays survival support

The original suggested tier 3/4/5 gates at Portal 1 / Portal 5 / both rescues
were not cosmetic. The house tier raises baseline specialists, gun rates/range,
friend damage and recovery speed. Tier 5 after both rescues has no role in helping
those rescues, and delayed baseline workers shift pressure onto Gold hiring.

**Decision:** withdraw those gates from the first implementation. Preserve all
current house-upgrade eligibility and worker rules. Measure survival and spending
before considering any later gate. Keep civic expansion separate from the
existing shared quality tier.

Evidence: `scripts/autoload/game_state.gd::upgrade_house`, `::worker_count`,
`::water_keeper_count`, `scripts/world/house_defense.gd`,
`scripts/world/village_hero.gd`, `scripts/data/house_db.gd`.

### A5 — P1: repairing an old save's site must not remove earned facilities

A current repaired ruin persists on reload, can shelter people, and can accept
a bought gun. Replacing that state with a locked project would destroy earned
access. A missing new schema after defaults merge cannot distinguish legacy
state reliably, and an invalid schema must not be treated as a valid completion.

**Decision:** inspect raw data before merge; migrate once with explicit legacy
entitlements. Retain existing stock access, HP, shelter, gun ownership, placements,
workers and equipment. Offer already restored sites an optional workshop fit-out
without demolishing them. Missing, malformed and unsupported future schemas need
separate handling; do not overwrite a future schema or unreadable save to make
it look current. No retroactive charges or invented rescue/portal facts.

Evidence: `scripts/autoload/game_state.gd::load_game`, `::_merge`, `::_sanitize`,
`::register_structure`; runtime checks 11 and 14.

### A6 — P1: a clear footprint does not guarantee safe collision activation

`SettlementTarget._refresh()` disables ruined building collision and restores
it with a deferred change when repaired. Actors can walk through ruins. Reserving
a future area in layout metadata does not remove actors already standing there;
SettlementEditor dragging currently clamps/snaps positions without consulting
project reservations.

**Decision:** protect future extents and approaches in placement validation,
revalidate custom/legacy layouts, then check live occupancy before activation.
A project at zero work can wait for clearance. Do not spawn collision around
people or reset saved layouts. The lease must also prevent two builders or a
player and builder contributing twice in one tick.

Evidence: `scripts/world/settlement_target.gd::_refresh`,
`scripts/world/settlement_editor.gd::_drag`, `::_finish_drag`,
`scripts/creative/world_layout.gd::reserved`, `::world_footprint`.

### A7 — P2: first-clear XP does not by itself reach the final gates

The probe used the actual XP API and catalog values. It modeled all regular
enemies killed once plus each first-clear boss XP reward, with no village kills,
repeat runs or other supplemental XP. For arithmetic it accumulated portals
even when the next entry would be level-locked; this is not a playable route.

| After portal | XP earned in that portal | Resulting level / residual XP | Next portal requires | Supplemental XP shortfall at that point |
| --- | ---: | --- | ---: | ---: |
| 1 | 774 | 5 / 254 | 3 | 0 |
| 3 | 1,547 | 11 / 119 | 7 | 0 |
| 5 | 2,681 | 15 / 364 | 12 | 0 |
| 7 | 3,744 | 18 / 1,870 | 18 | 0 |
| 8 | 4,706 | 20 / 2,166 | 21 | 364 |
| 9 | 5,758 | 22 / 2,634 | 25 | 7,126 |

The final 7,126 is the cumulative supplemental need in this model; do not add
the earlier 364 to it. Earning the missing XP earlier changes later residuals.
Boss-only rushing yields less XP, while village defense/replays supply more.

**Decision:** explicitly plan late preparation/replays and measure the actual
play path. Additional project gates must not stack opaque chores onto an
already existing XP requirement. No XP rebalance is implemented or implied by
this audit, and house level is not player combat level.

Evidence: `scripts/world/dungeon.gd::_build_monsters`,
`scripts/autoload/game_state.gd::register_kill`, `::grant_xp`, `::xp_for_level`,
`scripts/data/portal_db.gd`; probe `all_minions_first_clear_xp` record.

### A8 — P2: costs and upgrades need a budget, not just a progression chart

An Iron Sword costs 90 Gold; its first upgrade is 65, and all five cost 975
in total. Including purchase, Iron Sword +5 costs 1,065 Gold for 28 weapon ATK,
versus Tideblade's 240 Gold for 26. This is a costly alternate preparation path;
it does not justify disabling existing +5 upgrades in the first slice.

A complete first dungeon with all twelve Gold drops collected yields 96–168
drop Gold plus the 160 first-clear reward: 256–328 before other spending. That
can fund Tideblade after a free commission. A boss rush guarantees neither those
drops nor enough funds for it. Starting inventory already includes two health
potions and one pet food; the tutorial's purchase lesson is additional spending.

**Decision:** keep the introductory commission free. Buying the newly licensed
weapon is optional; explain its price before the work. Do not advertise an
immediate gear grant. Preserve renewable income without requiring live-tree
destruction. Later paid projects need budgets including potions, replacement
workers, upgrades and repairs, not just boss reward totals.

Evidence: `scripts/data/item_db.gd`,
`scripts/autoload/game_state.gd::weapon_upgrade_cost`, `::_make_default`,
`scripts/combat/enemy.gd::_spawn_reward`, `scripts/world/loot_drop.gd`;
probe `sword_catalog` record. Gold ranges are source arithmetic, not measured
time or guaranteed spending power after a natural run.

### A9 — P2: a saved rescue flag is not the return-animation completion event

`free_arjun()` saves `arjun_rescued` on the island before the return sequence.
`_arjun_returning` is runtime-only; reload can rebuild the Lobby directly with
the friend already available. Requiring the landing callback would lose the
harbour opportunity. The final portal also hands into Mei Ling's rescue rather
than an ordinary victory panel, so civic UI there could interrupt the ending.

**Decision:** derive eligibility from authoritative saved portal/rescue facts.
Queue presentation until the current Lobby is ready and transition, sailing,
story and modal ownership permit it. Reconcile on load and return, not only in
one victory callback. Keep opportunities in the journal if a notice is missed;
do not use acknowledgement or a watched cutscene as an unlock prerequisite.

Evidence: `scripts/world/kraken_island.gd::free_arjun`,
`scripts/game/game.gd::show_victory`, `::finish_ship_return`,
`::_check_campaign_ending`, `scripts/autoload/game_state.gd::rescue_friend`.

### A10 — P2: a one-off NPC route/dialogue change will not survive all flows

The probe changed Rami's waypoints and called `refresh_spatial_layout()`. His
original three authored points returned. Separately, direct touch via NpcInfo
opens a role-description dialogue; normal AuthoredInteraction can use its own
lines. Changing only those lines does not consistently change what tapping
the resident says. Rami can also be dead, and has no generic named-resident
replacement/revival transaction.

**Decision:** derive activity overrides after each layout resolution, load and
project reconciliation. Use one project-aware dialogue resolver for all input
routes. If Rami is dead, a living builder can use the annex; completion never
requires resurrecting him or waiting for an unavailable actor.

Evidence: `scripts/world/lobby.gd::refresh_spatial_layout`,
`scripts/world/resident.gd::_ready`, `scripts/ui/npc_info.gd::_unhandled_input`,
`scripts/creative/authored_interaction.gd::interact`; runtime check 12.

### A11 — P2: facility identity and map state need explicit presentation

The site is currently a house. Once repaired it accepts an optional rooftop gun;
ordinary refresh sets house art from the shared house tier. VillageMinimap draws
all residence/ruin anchors as tier-one houses regardless of HP or project status.
MissionPanel has no data-changed refresh subscription like the shops do.

**Decision:** intentionally preserve the completed annex's shelter/gun support
and give it an additional facility role, persistent workshop identity and visible
workpoint. Never grant a gun automatically. Ensure ordinary refresh preserves
that identity, project/map states agree, and open journal/shop panels update.
Use existing panel/world feedback; do not depend on no-op toasts.

Evidence: `scripts/world/settlement_target.gd::_refresh`, `::_build_defense`,
`scripts/ui/village_minimap.gd::map_icons`, `scripts/ui/mission_panel.gd`;
runtime checks 11 and 13. The facility-specific art requirement is a design
inference from the refresh code, not an implemented-art test.

### A12 — P2: work needs an explicit simulation and save contract

Game advances its clock in multiple world types, but clears the old Lobby on
travel. That does not simulate its builders while absent. Current structure work
updates remaining time without per-tick disk writes. `_save_now()` writes the
save directly and warns/returns on an open error; it does not expose a durable
transaction result to callers.

**Decision:** project labor runs only in the active Lobby with a valid worker.
No offline or ocean-time completion, including through a return-time catch-up
calculation. Save at project start, interruption, completion and normal save
boundaries, without per-frame writes. Describe in-memory atomic mutation honestly;
do not claim crash-safe payments or successful persistence from a bool that does
not represent disk I/O. The free first commission avoids a new payment-loss risk.

Evidence: `scripts/game/game.gd::_process`, `::_clear_world`,
`scripts/autoload/game_state.gd::work_structure`, `::_save_now`.

### A13 — P2: the default ruin is reachable, but its future footprint is unverified

All four current ruin workpoints had nonempty exact-goal physics paths from
Bram's approach, without nearest-goal fallback. The west candidate is at
(4.4, 10.8), away from the main workshop and outside the default central market
cluster. Its resource footprint is 5.2 × 2.1; ordinary residence footprints are
5.6 × 3.8. No project facade, future reservation, activated collision or custom
placement was validated by that result.

**Decision:** keep the west site as a candidate, not a proven optimal location.
Before shipping, verify the full restored site, builder and civilian approach,
player walk/touch route, visibility and edited layouts. Make guidance lead to
the actual workpoint. An authored road link or topology change needs disposable
creative/bake checks; a path across grass alone is not visual wayfinding proof.

Evidence: `data/maps/village_layout.tres`,
`scripts/world/resident_routes.gd::path`,
`scripts/world/lobby.gd::_add_resident_house`; probe `ruin_sites` record.

## Evidence and limits

- Native Windows engine: `4.7.2.stable.official.ed1daf0bf`.
- Isolated import via `tools/test_isolated.ps1 -ImportOnly`: exit 0, no script
  error markers. It emitted `Unable to open Android 'build-tools' directory.`
  This is reported rather than described as a completely clean import.
- Final external scene probe: **14 checks, 0 failures**, exit 0; no `[AUDIT_FAIL]`,
  `SCRIPT ERROR` or `ERROR:` markers in the final probe logs. The scene used
  verified isolated APPDATA/LOCALAPPDATA, with the actual user-data path under
  its test root before any fixture save mutation.
- The first attempt used `--script`/SceneTree and hit autoload-identifier compile
  failures in the harness path. Only its own processes were stopped. The corrected
  external Node scene completed successfully; no gameplay fix masked the failure.
- The probe exercised actual existing APIs, not a mock future project system.
  Position changes, fixture funds and direct worker calls were deliberate test
  setup; they do not certify natural play, combat balance or touch UX.
- No full acceptance gate, new render, Android export, device test or sustained
  performance measurement was run. Documentation was checked with
  `git diff --check`; no gameplay changes required acceptance expectations to be
  rewritten.

Local evidence directory, containing the probe, scene, successful logs and the
separate failed-harness logs:
`C:/Users/LUQMAN/AppData/Local/Temp/besut-progression-audit-6fffedd909c64b15bb5141d42d862a33`.
Import evidence:
`C:/Users/LUQMAN/AppData/Local/Temp/tidesworn-tests-fdacb8953ee04664b8775783f15707e1`.

## Readiness after revision

Ready to implement as one slice: free workshop project; consistent advanced-stock
license; ordinary damage and project work kept separate; real player fallback;
current house rules retained; permanent saved eligibility; legacy entitlements;
project-aware site/NPC/journal/map reconciliation. The revised plan specifies
required acceptance coverage for those behaviors.

Still requiring measured design work: first-boss experience with basic gear,
natural return/commission timing during raids, final site appearance, later
district benefits and costs, finer gear bands and late-campaign XP preparation.
The design audit is complete; these future gameplay features are not certified
by the probe.
