# Twilight Wilds: earn the road to Chaos Citadel

**Status: design proposal only — not implemented or approved gameplay.**
**Date:** 2026-11-01, Asia/Kuala_Lumpur.
**Target:** /home/roku/Documents/ChatGPT/game — TwilightRealm, stable portal ID `tidebound_grotto`.
**Inspected source revision:** 906f5a13ebd3dc23086b92c887f1078814b0c18a, plus the current worktree.

## 1. The problem and the design decision

Today, TwilightRealm._physics_process() starts the ruler when Adam enters RealmDB.BOSS_TRIGGER. The existing six guards, Wisp, winch, lantern, habitats and memories are not prerequisites. The countryside is connected, so simply putting enemies along the stone road does not stop Adam walking around them.

**Recommendation: turn the approach into one short, cause-and-effect rescue quest: restore the road's three lights to break the citadel's OUTER ward.** The fiend still owns the separate PRISON seal. Opening the road must not free Mei Ling, weaken the boss numerically, pay his rewards or count as a portal clear.

Build this from the existing crossing, watchpost, winch, three guard pairs and lantern. Do not add another village errand chain, a new currency, a house upgrade, a level grind, a mandatory pet purchase, a timed wait, or three inventory keys. The progression should feel like recovering a stolen road, not completing an unrelated checklist.

The critical route is:

Arrival and Wisp's explanation -> crossing patrol -> relight crossing marker -> watchpost patrol -> turn the existing winch -> ashen sentries -> prepare the citadel lantern -> explicit decision at the ward -> first meeting with Mei Ling and the fiend -> boss fight -> existing saved rescue and peaceful realm.

Optional west/east loops remain available throughout. Players may explore or complete tasks out of order; the final eligibility rule, not forced corridor sequencing, enforces the required accomplishments.

## 2. Narrative logic and continuity

- Rahim has already given Adam the permanent village portal key. That key opens the way INTO this dimension, not every door within it. Never consume it or ask the player to earn it again.
- The existing memories say the road's light was drawn into the citadel. The new road lights make that story visible: the fiend has bound the outer ward to three guarded road sites.
- Wisp observed an archer being brought through. Adam supplies Mei Ling's name; Wisp need not inexplicably know the missing friends.
- The guards were ordered to hold her alive for the ruler's questions, consistent with the opening. Do not invent a sacrifice deadline or claim she powers the throne.
- Breaking the three road bindings opens only the outer ward. Defeating the fiend still breaks her prison seal through the existing complete_portal() transaction.
- No line assumes Arjun has been rescued. His state is read when a relevant exchange opens, not cached on first entering the Wilds.
- Wisp stays at his existing home. No unexplained teleporting guide, duplicate live Wisp, or new speaking pet is required.

## 3. Playable beats and authored dialogue

### Beat A — Arrival: a person to find, not a boss marker to chase

**Space:** Arrival Glade, return rift and Wisp. Keep the refuge safe. Stone tracks lead toward the crossing; one steady, broken-light motif links the roadside objects visually.

**Action:** a small persistent objective reads **Find a way into the citadel**. Nearby Wisp offers the explanation through the existing non-pausing reading panel. This conversation is strongly signposted but NOT a hidden mandatory dialogue flag. If Adam ignores him, the first road marker and the ward provide the same essential instructions.

**First conversation:**

- Adam: “I'm looking for my friend. An archer. Her name's Mei Ling.”
- Wisp: “The guards brought an archer to the citadel. Alive.”
- Adam: “Then that's where I'm going.”
- Wisp: “Its outer ward drinks from three lights along this road. The guards have bound them.”
- Adam: “Break the bindings. Open the road.”
- Wisp: “Yes. And keep your way home. That rift is still yours.”

**Presentation:** all text readable immediately, visible Close, replayable from Wisp. No forced camera sweep, auto-advancing exposition or dialogue during an attacking encounter. Keep his existing ambient memory/bond responses as optional follow-up rather than deleting them.

**If skipped:** the crossing marker reads “The road's light is bound to the nearby patrol. Free the marker, then relight it.” The ward later lists the actual missing task. Neither discovery nor walking near the boss grants completion.

### Beat B — Rootbound Crossing: learn, win, change something

**Action:** defeat the two existing crossing Imps using the already-authored warning/rush/recovery behavior. Then interact with the unlit crossing marker beside the main road. Its exact placement is a blockout task: reachable from the crossing without obstructing the bridge, guard homes or optional west branch.

**Teaching:** the paired rushes prepare the player to recognize and counter the fiend's later committed movement. This is instruction through action, not a compulsory perfect-dodge test.

**On approach:** Adam: “Those marks lead all the way north.”

**If activated too early:** “The patrol still binds this light.” Show a matching Imp sigil, not an unexplained red lock.

**After the pair falls and Adam relights it:**

- Adam: “One light back where it belongs.”
- Adam: “The old watchpost is next.”

The marker becomes visibly warm and the first ward emblem changes shape as well as color. Relighting awards no extra XP, Gold or item. It records a permanent journey accomplishment. A small local pulse, not a world-restoration effect, points along the road.

**Choice:** pawprints offer Bramble Grove here. The cat remains an optional friend, not a toll required to rescue a human.

### Beat C — Broken Watchpost: recover a route, not a second identical switch

**Action:** overcome the existing Imp/Watcher pair, then operate the existing Rootway winch. Extend that action to reconnect the watchpost's road light as well as open the real shortcut.

**Teaching:** read the fixed fan, approach from a safe side, or use the existing physical cover. No new guard or altered attack speed is required.

**Before combat, from a safe approach:** Adam: “A winch. If it still works, I won't have to take the long way back.”

**Winch while the pair lives:** “The watchpost binding holds the winch fast.” The restriction is specific to the new quest, not a false claim that a remote enemy is physically touching Adam.

**On success:**

- Adam: “There. A road back—and another light forward.”
- Adam: “One binding left.” (Only if the crossing light is already lit.)

If completed out of order, use “The watchpost light is free. The crossing still needs me.” Never announce a false ordinal.

**Visible result:** roots retract at the existing barrier, route planners invalidate, the second emblem changes, and the west loop reconnects. Do not add another return-to-Wisp task.

**Choice:** Moonpool Hollow and Dusk Moth lie along an inviting east loop. Show the protected habitat clearly; the challenge can be lost, left or ignored without blocking the quest.

### Beat D — Ashen Approach: make the last lesson and the rest matter

**Action:** defeat the existing Imp/Keeper pair. Their marked cross prepares Adam to read the fiend's floor attacks. The lantern remains a refuge; no enemy should hit through its safe space.

**First sight of the blocked road:** Adam: “The lantern's still here. The arch beyond it isn't letting anything through.”

**Lantern interaction has two distinct meanings:**

1. **Rest / set checkpoint** remains available early, even when road tasks are incomplete. Preserve the existing two-second healing/revival rest. Do not deny healing because Adam explored ahead, lost his pet challenge, or skipped a conversation.
2. **Prepare the road** becomes available after all three pairs are cleared and the crossing marker and watchpost light are restored. The first successful preparation includes the normal rest and checkpoint, lights the third lamp, and records readiness. Subsequent rests do not replay the preparation.

**If incomplete:** give the earliest remaining task and offer Rest anyway. Example: “The crossing light is still bound. You can rest here before returning.” Never just say “Not ready.”

**When preparation is possible:**

- Adam: “The road's light reaches this lantern now.”
- Adam: “Mei Ling. I'm coming.”

A short owned reveal shows the three emblems answer; essential static geometry still communicates this with Reduce Motion and muted audio. Do not start combat, apply restored-world lighting, or reveal a victory state. End with **The outer ward can now be opened.**

### Beat E — At the ward: choose the confrontation

The outer ward blocks every entrance to the actual chamber, including the existing eastern opening. It must not consist of a decorative strip that can be walked around. Keep the onward-passage routes outside the chamber traversable; their existing predecessor/level gates still apply.

**While locked:** inspect the ward to see three labeled emblems and the actual missing action. A discovered map icon says **Sealed citadel entrance**, not an undiscovered boss destination. No conversation spam on repeated collisions.

**When ready:** use a deliberate nearby interaction: **Enter the citadel** / **Not yet**. Eligibility does not automatically pull Adam inside. A fresh confirmation authorizes entry; held Attack, a winch tap, or closing the rest panel cannot accidentally accept it.

After confirmation, the opening becomes traversable and Adam crosses through normal continuous movement. Cancel/Not yet leaves him in safety. No auto-walk, position snap or locked-in fight is needed.

**Reveal discipline:** a readable stone/ward silhouette and bounded exterior camera prevent the full boss/captive tableau being revealed from the lantern or east route before entry. Verify sightlines at both review resolutions and camera zoom extremes. Preserve existing interior arena dimensions and fighting lanes.

### Beat F — First meeting: make the rescue personal, then release control

After authorized threshold entry, suspend the owned world and shared clock for one short, player-paced confrontation. Cancel regular casts, release held controls, and frame the fiend, Adam and sealed prison. The boss remains non-damaging until the conversation ends.

**First-entry script:**

- Adam: “Mei Ling!”
- Mei Ling: “Adam? Stay clear of the marked floor!”
- Fiend: “Another traveller following a stolen light.”
- Adam: “Open the prison.”
- Fiend: “The road may answer you. This citadel answers me.”
- Mei Ling: “Then show him the difference.”
- Adam: “Stay back from the bars. I've got this.”

Mei Ling is alert and helpful, not just a silent object waiting for rescue. Avoid explaining the whole boss pattern over dialogue: guards have already introduced rush, fan and cross.

Offer a clear final **Face the fiend** action and Skip. Skip advances presentation safely into the same fight, never directly to victory or rescue. Commit the one-time intro-seen flag at the valid combat handoff. Cancelling because the world changed must not start combat in the replacement world or falsely mark the introduction complete.

**Retry:** no repeated seven-line speech. A brief “Mei Ling: Watch the floor, Adam.” / “Adam: I see it.” can be dismissed or skipped. Full intro replay may be optional, never mandatory. Retreat still resets the unfinished boss and its effects; the three road accomplishments remain earned.

### Beat G — Existing rescue, now with a payoff

Keep the existing immediate-rescue transaction and seven-beat rescue animatic. Do not add a second cage-opening requirement to Mei Ling's path. The opened road and the opened prison are visually distinct events.

The existing exchange about Arjun remains truthful: “He's safe in BESUT” only when rescued; otherwise “I'm still looking. I'll find him.” If adding an earlier optional Wisp branch, use “My other friend made it home” / “I still have another friend to find,” never imply the sea rescue happened offscreen.

Afterward the realm is peaceful, prison empty, hostile actors/effects removed, and the chamber return rift available. No road task can relock a cleared realm. Luma, first-clear currency, workshop guidance, onward unlocks, and the eventual explicit dock ending retain their existing owners.

## 4. Hard gates, soft guidance and optional branches

| Content | Required for first boss access? | Reason |
|---|---|---|
| Existing portal awakening | Yes, unchanged | Access to the dimension |
| Hear Wisp's whole conversation | No | Context must not become a dialogue-flag trap |
| Defeat all three existing road pairs | Yes | The ward bindings have identifiable guardians |
| Relight crossing marker | Yes | First visible act of reclaiming the road |
| Operate watchpost winch | Yes | Restores second light and a useful return route |
| Prepare lantern after prerequisites | Yes | Third light, checkpoint, and readiness payoff |
| Confirm entrance and cross threshold | Yes | Deliberate meeting, not proximity ambush |
| Win either habitat challenge | No | Optional build/relationship choice, no self-duel/dead-pet lock |
| Collect all memories/cache | No | Exploration rewards retain their optional meaning |
| Buy gear, reach another level, spend currency | No | No grinding or shopping gate |
| Rescue Arjun first, wait for night, upgrade house | No | Rescue order and village systems stay independent |

Players can reach the approach early, inspect the problem, rest, and turn back. They cannot activate or damage the boss early. Doing legitimate tasks out of order records them immediately; no requirement to repeat combat because Wisp had not been spoken to.

## 5. Proposed durable state and transaction boundaries

Use additive defaults and sanitization under `realm_progress.citadel_path`, not a second quest/save manager. Keep global save version 6 unless implementation establishes a real reason to change it.

Proposed fields:

- `cleared_pairs`: allowlisted unique IDs `rootbound_patrol`, `watchpost_guard`, `ashen_sentries`.
- `crossing_lit`: bool; valid only with crossing pair complete.
- `watchpost_lit`: bool; valid only with watchpost pair complete; the same accepted transaction opens the existing `realm_progress.shortcut`.
- `lantern_prepared`: bool; accepted only with all pairs and both earlier lights complete.
- `intro_seen`: bool, presentation history only, never a substitute for eligibility.

Derive the number of lit emblems and the current objective; do not separately save a counter, stage number and arbitrary ready flag that can disagree.

**Boss admission predicate, proposed:**

`all_three_pairs_cleared AND crossing_lit AND watchpost_lit AND shortcut_open AND lantern_prepared`

A cleared portal bypasses unfinished-road requirements for peaceful exploration, but never respawns an attackable ruler. Wisp/memory/pet flags, player level, `intro_seen`, and mere checkpoint presence are not admission credentials.

**Pair-completion policy:** completed pairs remain cleared for this journey after reload, shore return or defeat. This is an explicit extension to the current fresh-combat reconstruction policy; implement and document it deliberately. An unfinished pair retains the existing reset-on-Continue policy, including resetting surviving HP. Its temporary live/death evidence must not be inferred from a missing or queued node. Only two actual accepted deaths from that authored pair finish it. Removing actors on world replacement or boss victory grants no road credit.

No new pair/anchor quest payout is introduced. Ordinary enemy XP/drop rules remain; duplicate death/completion signals in the same visit must not pay again, and a completed pair must not respawn on reconstruction. The existing policy can still allow a partially completed encounter to be fought again after reconstruction; this proposal does not claim a new global anti-farming system. If strict per-guard one-time reward persistence is wanted, design a separate six-stable-ID kill-and-loot claim transaction rather than quietly adding half a ledger here.

Record pair completion through GameState with current-world/journey ownership and actual encounter evidence. Save the completion before its celebratory pulse/dialogue. Reward handling must remain single-owner: RealmGuard inherits Enemy._die(), which already calls register_kill() and spawns ordinary drops. A new listener must NOT call those again. Review save/signal ordering at that exact site during implementation; test closure immediately after the second death.

Record each anchor action before presentation. Duplicate winch/lantern input is idempotent. Cancelled preparation before an accepted transaction grants no readiness; interruption after acceptance preserves readiness. Intro/camera timing never writes rescue/rewards.

**Loot policy:** keep expedition banking and defeat loss unchanged. Saving road progress does not silently bank carried Gold, preserve uncollected drops, or refund loot when a cleared pair no longer respawns. Checkpoint and readiness are journey progress, not an insurance policy for expedition loot.

## 6. Runtime enforcement — more than a visible door

1. World-collision ward spans all chamber approaches, with a deliberate, readable front entrance. Verify geometry, wall joins, capsule clearance and the eastern seam with physics routes.
2. The single authoritative eligibility query is used by the ward prompt, entry interaction, threshold start, boss targeting and boss damage acceptance. Do not use the UI as a security boundary.
3. A forged/teleported position inside BOSS_TRIGGER without valid readiness/entry authorization does not activate or expose an attackable boss. On reconstruction, select a safe valid spawn before enabling physics; live abnormal positions trigger a guarded safe recovery, not per-frame snapping.
4. Arrows, companions and knockback cannot hurt a dormant/ineligible boss or start a conversation through the ward. Boss effects cannot threaten the preparation refuge.
5. Entry has separate eligibility, fresh consent, owned introduction and combat-handoff states. Consent is transient per visit/attempt; it is not a permanent saved bypass.
6. Preserve one active guard pair/shared attack slot. Boss handoff cancels every remaining cast before combat or dialogue begins.
7. Game owns the deliberate introduction/preparation suspension; the existing normal reading and ordinary menus stay non-pausing. Do not globally pause SceneTree or alter normal menu behavior.
8. Every await rechecks world identity, journey serial and live actor. Defeat, return rift, replacement, New Journey, title, and developer session termination cancel owned work.
9. Exiting remains possible. Do not close the gate on Adam or his companion; reset an unfinished ruler after retreat, then restore a safe entry prompt. No soft lock behind the ward.
10. Cleared revisits construct no hostile ruler, preserve open routes, and skip road/introduction demands entirely.

## 7. Guidance, accessibility and pacing

Use one current main objective, not six simultaneous HUD tasks:

- “Restore the crossing light” -> “Free the watchpost winch” -> “Clear the ashen sentries” -> “Prepare the citadel lantern” -> “Enter the citadel when ready” -> “Defeat Shadow & Chaos Fiend.”

Each objective accounts for actual out-of-order completion; it does not send the player to an already-finished task. During a local fight its attack hint takes visual priority. Update the existing objective tracker, tutorial boss lesson, mission panel, map labels, Field Guide and Wisp/ward text together. No new toast-based system: show_toast() is intentionally ineffective.

The entrance emblems show shape + label + lit/broken state, not color alone. Essential light paths are steady and readable with low effects, Reduce Motion and mute. Dialogue fits 832x480 and 1280x720 with wrapping, scrolling and visible Close/Skip; no mandatory voice, timed reading or repeated tap-to-reveal words. Keyboard, primary touch and mouse share nearby guarded interactions.

Recommended dialogue budget: six Wisp lines, one/two short lines at each road accomplishment, two lantern lines, seven confrontation lines. Optional contextual responses remain replayable without forced interruptions. No monologue after every enemy.

Pacing is a design target, NOT a measured claim: aim for a first critical-path approach of roughly 6–10 minutes and an optional exploratory visit of roughly 10–15. Measure actual median/slow/fast-player times before accepting those numbers. Do not pad duration with timers, extra HP or mandatory detours. Experienced players may finish much faster once the route is understood; they must still fulfill its actual prerequisites on a fresh journey.

## 8. Save compatibility and retry matrix

| State | Intended result |
|---|---|
| Fresh journey | All road lights bound; Wisp offers orientation; boss inaccessible |
| Old uncleared save without new fields | New defaults; preserve checkpoint, discoveries, pets, loot, flags and possessions |
| Old camp checkpoint | Keep camp spawn/rest; clearly name missing tasks and maintain a walkable route back; do not fabricate cleared encounters from checkpoint/attempt count |
| Old cleared first portal / rescued Mei Ling | Preserve existing rescue migration and peaceful access; no new gate or repeated rewards |
| One completed pair then save/reload | Pair remains absent; accepted light state preserved; unfinished others reconstruct |
| One guard of a pair killed then reload | Existing unfinished-pair reconstruction policy; no false pair completion |
| Defeat after preparing lantern | Existing home recovery and unbanked-loot loss; retain completed road and checkpoint; retry need not redo quest |
| Quit during preparation pulse | Accepted readiness survives; presentation may be omitted safely |
| Quit/cancel before valid intro combat handoff | No rescue/clear; no replacement-world combat; intro may replay coherently |
| Retreat after intro | Reset boss HP/effects; retain road readiness; offer short retry exchange |
| New Journey | Reset all new road fields with the rest of progression |
| Developer travel to Twilight | Fresh test road, isolated test save only |
| Developer travel directly to Citadel | Explicitly prepare test-only prerequisites without paying quest/combat rewards, then exercise normal entrance/intro; no production skip flag |
| Malformed/future state | Allowlist IDs, strict boolean types, reconcile dependencies; reject unsupported future schema before overwrite if introducing one |

Do not infer unknown historical kill results or invent a successful migration from a catalog helper. Test actual JSON load paths. Existing normal save must never be replaced by developer progress or a stale snapshot.

## 9. Implementation map — future work, not edits made

All existing paths below are under `/home/roku/Documents/ChatGPT/game/`:

- `scripts/data/realm_db.gd`: road-site definitions, ward geometry and admission approach; retain 56x52 map and full arena.
- `scripts/data/realm_content_db.gd`: Wisp's state-aware optional exchanges; preserve memory text/journal behavior.
- Proposed `scripts/data/citadel_approach_db.gd`: named dialogue beats and authored objective descriptors, not a second state owner.
- `scripts/autoload/game_state.gd`: defaults, sanitization, pair/anchor transactions, derived access/objectives, migration and test-only destination preparation.
- `scripts/world/twilight_realm.gd`: reconstruct completed pairs/sites, world-owned evidence collection, physical ward and guarded boss handoff; retain reset/rescue/post-clear flow.
- `scripts/combat/realm_guard.gd` and `scripts/combat/realm_encounter_director.gd`: accepted-death evidence and completion notification, without duplicate Enemy rewards.
- `scripts/world/realm_interactable.gd`: nearby cross-marker/winch/lantern/entrance actions; preserve rest and exit access.
- `scripts/world/twilight_landscape.gd` and scoped art owners: dormant/lit marker identity, readable ward, no village RNG contamination.
- `scripts/game/game.gd`: owned preparation/introduction suspension, cancellation, safe consent/handoff, developer routing.
- `scripts/ui/objective_tracker_data.gd`, `scripts/ui/mission_panel.gd`, `scripts/data/mission_db.gd`, `scripts/data/field_guide_db.gd`: one consistent prerequisite-aware objective flow. Preserve ten tutorial events; road subtasks are not new global tutorial indices.
- `scripts/ui/story_sequence.gd` or a small Game-owned approach-dialogue presenter: reuse lifecycle/input patterns, but do not overload Mei Ling's post-victory story or silently pause Wisp's existing panel.
- `tools/twilight_checks.gd`, `tools/realm_life_checks.gd`, `tools/realm_combat_checks.gd`, `tools/mei_ling_rescue_checks.gd`, developer checks, `tools/tide_test.gd`, focused wrappers and `docs/ACCEPTANCE_TESTS.md`: update fixtures and real acceptance, not only textual expectations.
- `docs/TWILIGHT_WILDS.md`, relevant rescue/campaign descriptions and `AGENTS.md`: document intentional supersession of optional winch and reset-on-reload completed pairs, while retaining historical evidence.

The watched worktree already has modified `project.godot` and untracked `assets/ui/`. They are unrelated; preserve them. Do not push without a request.

## 10. Implementation sequence and acceptance

### Phase 1 — block out cause and effect

Place the crossing marker, dress the existing winch, stage the lantern, and prove an unbroken ward collision boundary. Walk the entire fresh route, west/east loops and every return path. Verify the boss/prison reveal cannot leak from ordinary exterior camera positions. Do this before polished cinematics.

### Phase 2 — implement authoritative progression

Add additive save fields and derived access. Hook actual pair completion exactly once; gate real activation/damage/targeting and every entrance. Reconstruct completed pairs and all visual states from saved data. Update developer fixtures explicitly. Then verify real save/reload and defeat—not just in-memory dictionaries.

### Phase 3 — add story and guidance

Ship the drafted Wisp/road/lantern/intro exchanges, fresh consent, short retries and consistent objectives. Preserve optional content and the existing post-victory rescue/Arjun branches. No localization-sensitive line offsets; use named beats.

### Phase 4 — review experience and regressions

Automated acceptance must include at least:

1. Fresh arrival -> sprint directly north: ward blocks; boss inactive/invulnerable.
2. West shortcut, eastern wall seam, onward-road approach and knockback cannot bypass it.
3. Forced in-bounds chamber position without readiness cannot activate/damage boss.
4. Five guard deaths, every missing pair combination, missing crossing light, missing winch and missing lantern preparation each refuse admission with the correct reason.
5. Missing Wisp/pet/memory/cache flags do NOT refuse otherwise legitimate admission.
6. Out-of-order clears/lights are credited without replay or false ordinal dialogue.
7. Winch simultaneously persists its light and shortcut; repeated taps cannot replay rewards.
8. Rest works before readiness with a dead companion; repeated rest does not fabricate preparedness.
9. Only actual deaths complete a pair; retirement, victory cleanup and stale handles do not.
10. Completed-pair persistence and unfinished-pair reconstruction match the declared policy.
11. Duplicate death/interaction callbacks give no extra ordinary or quest payout.
12. Save/reload before/after each road commit, preparation and intro handoff yields coherent state.
13. Every old-save row in the compatibility matrix uses actual disk fixtures.
14. Not yet, held Attack, pointer release and closing panels cannot start a fight accidentally.
15. Boss cannot damage during dialogue; Skip/finish each start exactly one fight.
16. World replacement/defeat/New Journey during each owned await cannot leak locks, camera, music or writes.
17. Retreat restores safe play and short retry; it never relocks earned road tasks.
18. Victory still commits Mei Ling rescue/rewards before presentation, once, in both Arjun states.
19. Cleared revisits stay peaceful and retain optional companions, lore and onward passages.
20. Normal menus keep ticking; owned story and habitat challenges suspend appropriately.
21. Direct developer Citadel travel exercises a deliberately prepared isolated fixture and cannot alter the normal save.
22. Existing village, ocean, rescue, reunion and normal-save restoration contracts still pass.

Rendered/input review: inspect the fresh approach, all three light changes, each refusal state, full ward boundary, entrance choice, boss reveal, intro/retry, and peaceful aftermath at 832x480 and 1280x720. Include real pointer/keyboard actions, continuous movement samples, low effects, Reduce Motion, mute and camera zoom extremes. Verify companion clearance and legible overlays, not just screenshots of endpoints.

Then perform isolated import, focused Twilight/Mei rescue/Developer checks and canonical gameplay gate; require their exact final PASS summaries, exit 0 and no failure/error markers. Keep warnings and platform limits explicit. Run git diff --check and inspect the scoped diff. Record measured playtest pacing and confusion before tuning difficulty.

**Success definition:** a new player can explain why the citadel is sealed, knows the next useful action, sees each accomplishment change the road, can rest/leave/retry without punishment loops, and cannot meet or beat the ruler before legitimately opening the approach. The rescue remains the payoff, not another gate after victory.

## 11. This planning delivery's verification limits

This document was derived from current source and the user's requested direction. It changes no production source, save, quest, dialogue, reward or collision. No new runtime validation is claimed for the proposed feature. The earlier focused run in this chat observed the pre-change world: 200 Twilight checks PASS under Linux/Xvfb/llvmpipe, with X11 input-method and V-Sync warnings. That evidence is not acceptance of this new design.
