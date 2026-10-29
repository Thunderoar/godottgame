# Unified portal and first dimension: source audit

Date: 2026-10-29. Checkout inspected: Windows `godottgame`, branch `main`, HEAD `ea8cffd`, including its current working-tree configuration. This report audits the shared-chat proposal against current source. It does not implement or approve the proposal's individual design choices.

## Scope and evidence

User direction: one village portal; physical exploration instead of destination/duel selection boxes; wildlife that can be challenged and tamed; three intended boss dimensions; concentrate on the first dimension.

Twilight Wilds, its named areas, two suggested pets, a 10–15-minute visit, in-world manual duels, checkpoints, and village-pressure changes are recommendations from the earlier chat. They remain design proposals. Current source contains ten portal bosses plus the separate ocean Kraken route. The other two proposed dimension bosses have not been selected.

Inspected Game/GameState, dungeon construction and outcomes, elemental enemies/effects/projectiles, pet catalogs and battle UI, follower routing, portal interactions, maps/guidance, village placement, and relevant test code. No Godot sessions, import, acceptance tests, screenshots, exports, or live-save operations were run for this audit. A Godot executable was not found on PATH; this does not establish whether one is installed elsewhere. Existing import-sidecar and `project.godot` modifications were present before the audit and left untouched. Current `project.godot` names the application `Protect Besut`; the older AGENTS.md application-name observation is stale for this working tree.

## Conclusion

The direction is feasible using the existing movement, combat, companion ownership, art, interaction, and world-lifecycle systems. It needs a new exploration lifecycle and progression model. Removing a portal and enlarging Dungeon would retain behavior that actively defeats exploration: global pursuit, timed boss activation, visible boss guidance, tournament gating, and modal victory handling.

## Findings, ordered by implementation risk

### 1. High: three dimensions conflict with ten saved campaign stages

Evidence: `scripts/data/portal_db.gd::PORTALS/ordered_ids()` defines ten stable IDs. `scripts/autoload/game_state.gd::_make_default()`, `portal_clear_reason()` and `complete_portal()` own unlocks, level gates, first/repeat rewards and attempts. `scripts/game/game.gd::show_victory()` rescues Mei Ling for the last ordered portal; `_rescue_mei_ling()` assumes a Dungeon and fixed exit coordinates.

Consequence: shortening `ordered_ids()` to three can move the rescue trigger, strand old progress, or make rewards inaccessible. The first stage's ID remains `tidebound_grotto` although its displayed name is Chaos Citadel. The current final ruler is Abyss Monarch, not the older Malakar name. Arjun's ocean/Kraken rescue is separate.

Recommendation: build the first realm behind an explicit mapping from its stable realm ID to the existing first boss/progression ID. Preserve the legacy catalog until the full three-realm migration is specified. Define the two other rulers, final-rescue owner, and treatment of all ten legacy stages before shipping campaign compression. Never infer rescue from an array position in the new system.

### 2. High: current combat cannot provide a safe arrival or discovery phase

Evidence: `scripts/world/dungeon.gd::_ready()` alerts regular enemies immediately. `_physics_process()` alerts all enemies including the boss after 2.2 seconds. `Enemy.take_damage()` can also activate the Dungeon boss, and `ElementalBoss._physics_process()` has a Dungeon-specific dormant guard.

Consequence: adding a final chamber or delaying one timer is insufficient. Existing enemies can pursue across the realm and the boss can activate before the intended threshold.

Recommendation: give encounters local activation areas, pursuit limits and reset behavior. Gate boss activation and damage eligibility together behind the chamber trigger. Prevent companion targeting through the boundary from starting it early. Distinguish dormant, active, defeated and reset encounter states; release held player controls at transitions.

### 3. High: the suggested pets are inaccessible to an untouched starter companion

Evidence: `GameState.pet_battle_state()` requires the preceding duel clear. `pet_battle_clear_reason()` also requires companion level 2 for Bramble Cat and level 3 for Dusk Moth. `PetBattleDB` puts Sparring Ember first. The new-game companion starts at level 1.

Consequence: transplanting the two suggested encounters leaves their tournament prerequisites in place. Discovery alone cannot unlock either animal.

Recommendation: realm encounters need independent eligibility based on encounter discovery, companion readiness and deliberate challenge acceptance. Remove tournament-order dependencies from these encounters. Balance the first encounter for starter Ember; make later difficulty readable without requiring a hidden tutorial duel or paid upgrade.

### 4. High: controls_locked does not isolate an in-world duel

Evidence: `Game._apply_input_lock()` locks Player controls. Normal modals do not suspend the world. `Pet._physics_process()` continues its automatic support. Elemental projectiles/effects damage the current same-world player independently of input locking. `Game.open_pet_battles()` explicitly refuses a Dungeon context.

Consequence: reusing the panel in a clearing can leave Adam taking damage while unable to act, with his companion also healing/attacking outside the duel. A camera change provides no combat isolation.

Recommendation: separate the duel rules from their modal presentation. Game should own a challenge session, pinned to the current world, encounter and participating pet. Suspend outside combat, companion support, existing projectiles, hazards and their timers for the protected challenge, then restore the exact prior state on every exit. Keep Settings/quit usable. World replacement must invalidate delayed replies and animations. A peaceful loss changes arena HP only; a win can still legitimately heal the saved pet through level-up rewards, so do not promise that *all* saved HP stays unchanged.

### 5. High: victory currently ends the expedition before continued exploration

Evidence: `Dungeon._on_boss_finished()` locks movement, calls `GameState.complete_portal()` and shows the victory flow. That transaction calls `bank_expedition_loot()`, which clears expedition state. VictoryPanel's main action returns home. Dungeon's defeat handler checks for an active expedition.

Consequence: allowing movement after victory without changing this model leaves the player in a realm whose expedition is already inactive. Later loot, damage/defeat, saving and Continue need defined behavior. Replacing the victory panel alone is insufficient.

Recommendation: separate boss clear, one-time rewards, expedition completion and departure. Specify whether post-boss enemies remain hostile and when loot banks. Maintain an explicit realm-presence state even after the expedition is settled, or finish the visit through a controlled return. A restored-world epilogue requires this policy first.

### 6. High: checkpoint and resume behavior do not exist yet

Evidence: default saved expedition data contains active status, portal ID and loot, with no realm checkpoint, discovered regions, opened shortcuts, encounter completion or player position. `Game._on_continue_requested()` rebuilds the dungeon, and Dungeon always spawns at `SPAWN`. Unfinished enemies/bosses are reconstructed.

Recommendation: persist stable checkpoint/landmark/encounter IDs through GameState defaults, sanitization and transaction methods. Reset unfinished fights on resume. Validate checkpoint reachability, suppress hostile activation until arrival finishes, and fall back safely for invalid IDs. Define death retry separately from save-and-Continue; the existing defeat rule returns home with 10% HP and recovery. Merely adding a saved position does not implement either policy.

### 7. High: village safety needs a complete rule, not a removed banner

Evidence: `Game._process()` advances the shared clock and starts a nighttime emergency after 14 seconds in an active Dungeon expedition. It accumulates settlement-damage tint. The previous Lobby is freed during world replacement; `Lobby` owns physical home-enemy simulation and emergency attackers upon return.

Consequence: the village does not keep physically simulating in the background during a dungeon trip. Conversely, during today's village pet modal it does. These two situations must not be conflated. Clock progress, existing saved attackers and return-wave behavior remain relevant even if the dungeon emergency trigger is disabled.

Recommendation: define whether realm visits advance the shared clock, whether pending raids persist, and what happens when returning at night. For relaxed exploration, suppress the expedition-triggered emergency without silently healing the village or deleting its saved enemies. Keep ordinary village danger when the player is home. Test entry near dusk and return across multiple phases. Permanent twilight should be local lighting, not a second authoritative game clock.

### 8. Medium: both proposed wild pets currently have identical support statistics

Evidence: `scripts/data/pet_db.gd` gives Bramble Cat and Dusk Moth the same base HP, heal, attack, shield and intervals. Their `base_pet` values distinguish visual ancestry; the stat accessors read each pet record directly. Moss and Luma are distinct IDs with different roles. The first portal also separately awards Luma.

Consequence: the earlier description of an attacking cat versus shielding moth is an intended redesign, not existing behavior. Keeping the boss's Luma reward while adding Dusk Moth also needs a deliberate roster decision.

Recommendation: retain ownership IDs, but give the wild recruits intentional support roles and matching descriptions. Define whether Luma remains a separate reward/species. Preserve all previously owned pets; do not collapse similar art into one ID implicitly. Test both companion and village-defense behavior.

### 9. Medium: duel incentives undermine exploration and tactics

Evidence: `complete_pet_battle()` guarantees at least one companion level even on repeat wins; repeats pay 25% XP and no Gold. It recruits immediately, before any bonding interaction. Cooldowns tick while both fighters wait for the player's next choice.

Consequence: the easiest encounter can raise a companion to level 5; waiting for Special becomes a reliable strategy. A later bonding animation would be cosmetic if recruitment remained automatic on duel victory.

Recommendation: reserve substantial rewards for first completion, remove repeat guaranteed levels for the new encounter path, and specify bounded repeat rewards. Keep manual selection and no forced player timeout. Consider action-based cooldowns only as a separate balancing decision. Make the chosen taming boundary explicit: either win commits ownership and the approach animation confirms it, or victory saves a pending bond and interaction commits once. Test quitting at that boundary and duplicate callbacks. Pin rewards to the participating pet, rather than looking up whichever pet is active when completion runs.

### 10. Medium: exploration is exposed by map and guidance code

Evidence: `VillageMinimap.map_icons()` shows the live Dungeon boss immediately; `_draw()` displays the full background. `Dungeon.get_guidance_targets()` returns the boss position and `MissionPath` draws a route to it. The expanded map reuses VillageMinimap.

Recommendation: gate terrain, icons and guidance on the same persistent discovery state in both map sizes. Before discovery, use local landmarks/tracks; after finding the stronghold, offer guidance to it. Do not mask the background while leaving a boss icon or arrow visible through it.

### 11. Medium: a new world class needs shared APIs, not missing type branches

Evidence: Enemy routing recognizes Lobby, Dungeon and KrakenIsland explicitly. Pet fallback route bounds recognize Dungeon, otherwise using 64×40 outdoors. Game defeat/service routing, map rendering and PortalExit also depend on concrete world types/groups. `_nearest_gate_center()` averages the two village portal anchors.

Recommendation: keep Game as world-transition owner; introduce explicit shared world APIs for bounds, player, routing, encounter availability and return destination. Audit concrete type branches before selecting a new class or subclassing Dungeon. Inherited Dungeon setup must not recreate timers/global alerts. Source shortcut changes must invalidate route caches; ensure followers and large bosses fit routes. Reuse local encounter routes rather than assuming an enormous full-world AStar grid is cheap: ResidentRoutes builds one physics-tested cell every 0.5 units.

### 12. Medium: existing duel music cleanup is incomplete

Evidence: `PetBattlePanel._finish_battle()` clears `_battle_active` without stopping music; `close_panel()` stops it only when that flag is true. Existing `tools/combat_revamp_checks.gd` covers closing an active duel, not a completed result.

Recommendation: give the session explicit music ownership and cleanup on win, loss, cancel, results close and world replacement. In a realm, restore the appropriate exploration/boss track after a duel. Add a completed-duel-close regression, not just the existing active-close test.

### 13. Medium: the combat lesson described in the proposal does not match all current powers

Evidence: `ElementDB` maps Dark Blaze to a projectile fan, Mirage Assault to a dash, and Chaos Crossfire to crossing ground lines. The chaos minion is a dashing Darkfire Imp; it is not an existing mirage-teaching enemy. Boss skills rotate predictably through ElementalBoss.

Recommendation: foreshadow the actual mechanics: fan avoidance, a warned dash with trailing danger, and leaving a cross-shaped danger zone. A deceptive mirage minion would be additional implementation. Use spaces that allow the starter sword and companion to function, and keep warnings readable with low effects/reduced motion.

## Recommended first playable scope

Use one connected authored first realm with a readable main route, two optional habitats, one looping shortcut, a preparation landmark, and a deliberately triggered boss chamber. Arrival and preparation must be safe. Establish collision and complete player/companion routes before decoration. A 10–15-minute first visit is a playtest hypothesis, not a map-size requirement.

A useful route is arrival → crossing → watchpost → approach → citadel, with Bramble Grove and Moonpool Hollow branching off and rejoining. Every branch should pay off. Taming must not be required to open the chamber. The return portal must remain reachable before the boss so players can bank loot or leave to recover. The first version should prove a satisfying discovery/challenge/recruitment loop before adding three realms, procedural maps or elaborate post-clear transformation.

Implementation order:

1. Specify stable progression mapping, death/retry/resume, village time, taming commit and post-boss rules.
2. Introduce realm state/defaults/sanitization and shared world/encounter APIs.
3. Build and verify the empty walkable loop, one village entrance and reliable return.
4. Add local enemy encounters and boss threshold; retain existing attacks and damage pacing.
5. Move duel logic behind a protected session; add one discoverable habitat and durable recruitment, then the second.
6. Add discovery maps, shortcut persistence, guidance, reward tuning and environmental feedback.
7. Update tutorial/field-guide/portal text, old-save migration and acceptance coverage together.

## Required verification before calling implementation complete

- One village battle entrance; entry arrives in-world without a destination list. Mouse, E and real touch enter/return once; reentry during a transition is rejected. Update map anchors, labels, guidance and portal-effect center consistently without disturbing the original forest fixture or player layout.
- Starter Ember can discover and challenge the first wild pet without a hidden tournament prerequisite. Optional taming never blocks the boss route. Routes remain clear for player and follower; opening a shortcut refreshes navigation.
- Boss remains dormant and undamageable until the threshold; companion attacks cannot bypass this. Nearby combat does not alert every distant encounter. Chamber warnings and retreat/reset rules remain reliable.
- During a duel, outside enemies, pending casts, projectiles, hazards and companion support cannot affect the protected session. Win/loss/cancel/settings/focus loss/world replacement restore control, camera, AI and music; no held action leaks into exploration.
- Recruitment and first rewards commit exactly once across replay, reload and duplicate completion. A later expedition defeat preserves bonded pets and discoveries while following the chosen loot-loss policy. Test already-owned and legacy-duel recruits, active-pet changes and interrupted bonding.
- Checkpoints survive Continue; invalid/blocked IDs recover safely. An unfinished boss resets. Test quitting before/after boss reward, during a duel, after a bond and during return. Old active expeditions and old ten-stage saves retain earned progression and both rescue flags.
- Village clock/raid rules match the chosen policy at dusk, dawn and on repeated returns. Pending home attackers are not silently erased. Ordinary home defeat and ocean/Kraken rescue still work.
- Undiscovered paths/bosses remain hidden in both maps and guidance. The player can navigate using landmarks without forced arrows to undiscovered goals. Already discovered places survive a restart.
- Post-boss presence, loot, damage, defeat and Continue remain valid even if expedition banking has finished. Final rescue and reunion happen once for the intended boss only.
- Inspect actual 1280×720 and 832×480 renders, consecutive movement frames, touch controls, reduced-motion/low-effects warnings and camera framing. Profile representative paths/encounters; do not infer performance from headless tests or old reports.
- Update `tools/tide_test.gd` and `docs/ACCEPTANCE_TESTS.md` together for changed game rules. Existing assertions deliberately require two portals, ten levels, sequential duels, timed boss pursuit and dungeon emergencies; replace the obsolete expectations with behavior coverage rather than simply removing failures. Run the isolated import/gameplay gate and applicable focused/render/editor checks, then verify the scoped diff.

## Audit limits

All behavior findings above are source-backed; their runtime reproduction and visual quality were not tested in this audit. No current gameplay PASS count or performance claim is made. The proposed map, balance, three-realm migration and encounter architecture require implementation and testing. This report is the only file added for the audit; no gameplay fixes were made.
