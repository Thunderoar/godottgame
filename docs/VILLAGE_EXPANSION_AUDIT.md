# Village expansion: audit after the Twilight merge

29 October 2026. Source baseline: `577e2af1692e18fcf1cccb925d81d020db5cfb64`
on `main`, clean at inspection. This audits the implemented workshop, its new
Twilight Wilds integration, and the proposed residential/harbour follow-up.
No gameplay, authored map, player save or balance values were changed.

Follow-up: the subsequent implementation addresses F1-F3 and F4's preparation
messaging. See the progression-repair section in `ACCEPTANCE_TESTS.md` for current
verification. Findings below record the inspected baseline; D1-D5 remain explicit
requirements for a future residential feature, not shipped population mechanics.

## Verdict

The workshop has a real saved prerequisite, physical work, permanent shop
licensing, a restored shelter and a changed resident routine. The merged game
passes its canonical gate. However, the next step should first repair the
story-to-village handoff and ordinary builder job recovery. Adding another
ruin or NPC does not yet constitute a population or repair-coverage system.

Priorities below distinguish current defects from requirements for future work.
P1 means fix before relying on the affected automation or implementing the
dependent expansion. P2 means a progression, guidance or measurement gap.

## Current defects and integration gaps

### F1 — P1: an unreachable ordinary repair monopolizes a builder

`Resident._repair_buildings()` claims the nearest damaged structure before
checking route feasibility. While distant, it repeatedly calls `_walk_to()`
and returns. An empty route, a permanently obstructed approach, or a reachable
path endpoint outside actual working range never releases this claim. Replanning
in `_walk_to()` does not abandon or deprioritize the job.

The isolated probe enclosed a ruined house's workpoint with fixture collision.
The exact route was empty. After 480 real physics frames, the builder still
owned the same target, remained 3 units from its workpoint, and had supplied no
work: house HP 0, timer 10 seconds. This is a synthetic obstruction reproduction,
not evidence that the default layout blocks that particular house.

This also affects commissioned projects: `VillageProjectSite.work_builder()`
deliberately does not interrupt an existing ordinary repair claim. A stranded
builder can therefore keep ignoring the workshop. Player project labour remains
available, so this is not a complete campaign softlock. Night/death/retirement
can release ordinary claims; they are not a daytime failure-recovery policy.

Required fix: validate the actual workpoint, abandon empty/stalled/unreachable
jobs, release `target.builder`, back off that target, and try another eligible
job. Retain continuous movement and arrival-before-work. Test both a blocked
target with another reachable repair and a commissioned project waiting behind
it; test release on death, shelter, geometry change and world retirement.

Evidence: `scripts/world/resident.gd:639`, `:385`;
`scripts/world/village_project_site.gd:104`; `AUDIT_BLOCKED_ROUTE` and
`AUDIT_STUCK_CLAIM` in the external probe log.

### F2 — P2: first victory silently grants the village's next opportunity

The old `VictoryPanel` contains the free-workshop invitation and Luma's companion
explanation. `TwilightRealm._on_boss_finished()` now restores the realm in place
without opening that panel. Its replacement message reports Gold and diamonds,
then offers peaceful exploration/return. It does not mention the workshop, Luma,
or where to select the new companion. Subsequent landmark surveys replace it
with a generic peaceful-world hint.

The probe killed the actual active realm boss through its normal damage path.
The clear flag made the workshop eligible, Luma was owned, and the victory panel
stayed closed. The message was exactly the current Gold/diamonds/explore/return
message. This proves the transaction succeeds; the missing part is discovery.

The opportunity remains discoverable at Bram, Missions, Garrick's locked stock,
Rami and the site. It is not deleted. But returning to the village does not
automatically track the newly available project; ordinary rescue guidance can
lead the player back toward the portal. The workshop guide's statement that the
first victory panel explains this is now historical.

Required fix: keep free post-boss exploration and surface both rewards through
owned persistent UI, with a durable return-to-village invitation until acted on
or dismissed. Do not depend on the no-op toast channel or reintroduce a mandatory
results modal. Add an integrated real-boss-clear -> village -> discover/commission
test rather than only invoking `GameState.complete_portal()` in a village fixture.

Evidence: `scripts/world/twilight_realm.gd:276`, `:166`;
`scripts/ui/victory_panel.gd::_rebuild`;
`scripts/world/lobby.gd::get_guidance_targets`; `AUDIT_ACTUAL_VICTORY`.

### F3 — P2: wild-companion guidance still checks an obsolete tournament flag

`Lobby.get_guidance_targets()` and `GameState.objective_lines()` test
`pet_duel_1.cleared` to decide whether wild companions remain to discover.
Twilight's two habitats bond through `realm_progress.bonded` and pet ownership.
Neither completes that tournament flag. The removed village Pet Battle Portal
was the normal UI caller for the old tournament panel.

The probe bonded both `bramble_cat` and `dusk_moth`; `pet_duel_1.cleared` remained
false. Accordingly, the companion-guidance condition remains pending even when
the new habitat content is complete. It may be masked by higher-priority rescue
guidance, but becomes misleading when those priorities are exhausted.

Required fix: derive habitat guidance from the actual encounter IDs/ownership,
with a separate explicit policy for retained legacy tournament content. Do not
fabricate tournament victories to silence the objective. Update NpcInfo's old
tournament wording when this route is resolved.

Evidence: `scripts/world/lobby.gd:1720`;
`scripts/autoload/game_state.gd:1507`, `::complete_wild_encounter`;
`scripts/ui/npc_info.gd::description`; `AUDIT_WILD_OBJECTIVE`.

### F4 — P2: the old XP forecast no longer describes the first realm

Twilight supplies six optional regular enemies, each worth `14 * 3` player XP,
plus 90 first-clear boss XP: **342 XP**, reaching level 4 with 32 residual XP
from a zero-XP fixture. The previous audit modeled 774 XP for the former first
arena. Wild challenge XP belongs to the participating companion, not Adam.

Using current catalogs and actual GameState XP methods, the same arithmetic
model (all ordinary enemies and each boss cleared once, no village kills,
replays or supplemental XP) produces:

| After stage | XP earned in that stage | Level / residual XP | Next requires | Cumulative supplemental XP needed |
| --- | ---: | --- | ---: | ---: |
| 1 | 342 | 4 / 32 | 3 | 0 |
| 3 | 1,547 | 10 / 467 | 7 | 0 |
| 5 | 2,681 | 14 / 1,292 | 12 | 0 |
| 7 | 3,744 | 18 / 1,438 | 18 | 0 |
| 8 | 4,706 | 20 / 1,734 | 21 | 796 |
| 9 | 5,758 | 22 / 2,202 | 25 | 7,558 |

The last figure already includes earlier shortfalls; do not add 796 again.
The arithmetic deliberately continues beyond level-locked entries to measure
the cumulative gap. It is not a demonstrated playable route or a duration estimate.

Boss-only completion from zero XP yields level 2 / 30 XP, while the second stage
requires level 3: a 70-XP gap. Two regular Twilight kills would cover it before
victory. After victory the first realm is peaceful, so skipping its optional
encounters permanently changes that visit's available XP. Village combat and
later arena replays remain alternative sources. This is a preparation/guidance
issue, not proof of an unavoidable softlock. Normal tutorial defense also
contributes variable XP, excluded from this fixture.

Required decision: explain level preparation and replay opportunities before
stacking a residential story gate onto the route. Measure natural time, deaths,
spending and return-to-village behavior. Do not silently rebalance XP or require
all optional habitat/enemy content based on this arithmetic alone.

Evidence: `scripts/world/twilight_realm.gd::_build_encounters`;
`scripts/world/dungeon.gd::_build_monsters`;
`scripts/autoload/game_state.gd::register_kill`, `::xp_for_level`;
external `arithmetic.log` and boss-only runtime probe.

## Requirements before the next expansion

### D1 — P1: a second project is not a catalog-only addition

The current feature intentionally implements one workshop. `Lobby.workshop`,
site creation, worker dispatch/release, placement reservations, activity
reconciliation, project cards and guidance all name that one project.
The sanitizer iterates IDs but applies the first-portal prerequisite and global
ten-second duration to every record. Cards and messages also assume workshop
stock licensing. `activation_clear()` uses the workshop structure for its legacy
fit-out exception.

Before adding a residential entry, make prerequisite, duration, structure,
workpoint/footprint, benefit text, project-card identity and runtime dispatch
project-specific. Keep a small runtime site registry and one worker lease per
project; define how one builder chooses among repair and civic jobs. Avoid
introducing a second independent clock, direct UI state writes, or an abstract
economy framework larger than the two real projects require.

### D2 — P1: preserve already repaired residential ruins, including schema-1 saves

The probe confirmed that `home_damaged_house`, `home_destroyed_house` and
`home_ruined_house` all accept ordinary repair at journey start. Only the West
Workshop is story-locked. Those buildings can already be shelters and have
purchased guns before a proposed Portal-3 residential unlock.

Raw saves without `village_progression` gain the existing legacy entitlement.
Saves created after the workshop implementation already have schema 1 and
`legacy_access=false`; they can nevertheless have repaired the other ruins.
They need protection too. A new default record is not proof that a residential
building was never earned.

Separate restoration/fit-out entitlement from current damage HP. Preserve HP,
gun ownership, placement and shelter use; offer an earned building an optional
fit-out or arrival event. Test pre-workshop saves, current schema-1 repaired and
damaged sites, partial new projects, future schemas and repeated loads. Do not
reuse a broad legacy flag to grant every future civic reward automatically.

### D3 — P2: houses currently provide shelter, not population or hiring capacity

The observed fresh village contains 24 NPCs, four specialists, 12 houses of
which eight are intact, and 64 living trees. Repairing an existing ruin changes
intact-house counts, not total buildings or population. `WorldTally` counts real
nodes; it is not a saved occupancy simulation.

Residents choose the nearest intact shelter without household assignment or
capacity. Hiring is controlled by house tier, nominal worker counts, dead-slot
replacement and existing caps. A newly restored house does not itself add slots.
Changing those rules would affect survival balance and is separate scope.

For an actual new household, specify stable arrival IDs, persistent eligibility,
one-time spawning, household/home references, routes, health/death handling and
save migration. Today resident health and personality seeding use `resident_name`;
renaming someone changes identity. Separate display names from stable IDs before
making configurable households, or explicitly keep immutable identity names.
Existing named residents must not be hidden and re-awarded as newcomers.

### D4 — P2: an idle workpoint is not demonstrated repair coverage

Builders choose global nearest damaged targets, with no district assignment,
territory, job priority radius or player deployment control. Moving their idle
waypoints can alter travel distances, but cannot establish a promised coverage
benefit. Rami's completed-workshop routine is visible world change; it is not a
new productive worker or a repair-rate bonus.

Before promising a residential repair post, define its actual capability and
compare identical crew/tier, damage, day length and geometry with/without it.
Measure reachable job completion and travel time, including two simultaneous
repairs, blocked routes, night interruption, damaged shelter and edited layouts.
Retain the ten seconds of actual labour after arrival. Do not count a free new
builder plus tier baseline as if it were only a waypoint change.

### D5 — P2: choose the residential reward and gate after measuring the new route

Portal 3 / Glacial Necropolis remains a candidate milestone, not a validated
pacing result. Twilight now offers two permanent village guardians before its
boss; Luma, diamond upgrades and Arjun's independent rescue already provide
other growth. A household needs a distinct authored purpose and a safe, coherent
arrival, rather than another opaque requirement to collect.

Keep recruitment entitlement separate from resident vitality; re-entering the
village must not duplicate a household or resurrect dead people. If arrival is
staged, wait for an appropriate active-village context without resetting the
clock, deleting attackers or making essential management depend on a mortal
speaker. Preserve the separate Arjun/Mei Ling rescues and existing shared house
tier rules. A harbour response should not depend on inland restoration.

## Recommended implementation order

1. Recover blocked ordinary builder jobs and cover the queued-workshop case.
2. Repair the actual Twilight victory -> workshop/Luma handoff and habitat guidance.
3. Play a fresh journey with ordinary funds, optional encounters and real defense;
   record first clear, village return, commission discovery and next-stage entry.
4. Generalize only the project-specific assumptions needed for one second site,
   with preservation of existing schema-1 repairs.
5. Implement one residential place with one explicit useful effect and an authored
   resident routine. Add a new household only with its complete identity/lifecycle
   contract; keep population capacity and production out of this first follow-up.

## Verification and limits

Executed on native Windows, Godot `4.7.2.stable.official.ed1daf0bf`:

- Isolated import: exit 0; existing Android build-tools-directory diagnostic.
- Canonical isolated gameplay: **5,729 checks, PASS**, exit 0; empty stderr and
  no `[FAIL]`, `SCRIPT ERROR` or `ERROR:` markers.
- Native Compatibility/OpenGL Twilight review at **832x480**: **68 checks, PASS**,
  exit 0; empty stderr. Inspected all five captures: arrival, manual challenge,
  complete boss chamber, restored realm and discovered map. Challenge controls
  and map Close remain visible. This does not measure natural pacing.
- Two external audit scenes used verified isolated user-data roots. The first
  reproduced the repair claim and actual boss reward handoff. The second used
  real catalog/XP APIs for arithmetic and verified the stale tournament flag.
  Both exited 0 with empty stderr and their explicit completion markers.
- `git diff --check` passed after the documentation changes.

The full suite passing does not invalidate the reproduced gaps: its workshop
checks arrange clear approaches and directly complete the portal; its Twilight
checks verify ownership/rewards without asserting workshop invitation text,
ordinary builder abandonment or habitat-guidance completion.

External evidence directories (outside the repository):

- Import: `C:/Users/LUQMAN/AppData/Local/Temp/tidesworn-tests-6acff383bdc24b40941210e1caaa5eb5/`.
- Gameplay: `C:/Users/LUQMAN/AppData/Local/Temp/tidesworn-tests-e2cf201b5e304af3b007019a4b2a6cf4/`.
- Native captures: `C:/Users/LUQMAN/AppData/Local/Temp/tidesworn-tests-6c1db492dac84d67a7adba5c9d4e3953/`.
- Audit scenes, source and logs: `C:/Users/LUQMAN/AppData/Local/Temp/besut-progression-audit-df59340cbc6043fe96552a86e890fbdf/`.

No source editor/bake changes were made, so editor save/bake/restart tests were
not rerun. No 1280x720 review, Android validation, natural first-boss combat
difficulty test or new performance measurement is claimed for this audit.
