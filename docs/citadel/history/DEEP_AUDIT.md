# Deep audit: earn the road to Chaos Citadel

**Date:** 2026-11-01 (Asia/Kuala_Lumpur). **Route:** evaluation only.

## Verdict

**Keep the core design; do not implement the draft unchanged.** Three high-priority integration decisions need to be made explicit, five medium-priority cases need corrections or dedicated acceptance, and one dialogue-polish issue remains. These are findings about a proposal and its fit with current code, NOT nine newly reproduced production bugs.

The existing proposal remains byte-for-byte intact at [/home/roku/Documents/ChatGPT/citadel-preboss-plan-20261101-begoe056/CITADEL_PREBOSS_FLOW_PLAN.md](/home/roku/Documents/ChatGPT/citadel-preboss-plan-20261101-begoe056/CITADEL_PREBOSS_FLOW_PLAN.md). Its SHA-256 is `92214071726dca839879b3e0437fa3ca30910aadfa80452c2a80136446d6deb1`.

No gameplay, normal player save, existing plan, source test, collision or dialogue was edited. Source revision inspected: `906f5a13ebd3dc23086b92c887f1078814b0c18a`, plus current worktree. Existing modified `project.godot` and untracked `assets/ui/` were left alone.

## What was checked, and what the evidence actually proves

1. Re-read the full proposal against its current progression, combat, reward, save, camera, map, story, developer and objective owners.
2. Ran a real Godot 4.7.2 **headless source probe** under external isolated user data. It made five observations; exit 0; no `SCRIPT ERROR` or `ERROR:` markers. It did not instantiate/play the whole game or a future gate.
3. Exhaustively modeled all **128** combinations of seven proposed road prerequisite bits, **30** legal completion orders, and **112** phase/context permission combinations. These are design-model checks, not production feature tests.
4. The model found **15 of the 30** legal completion orders make the draft's fixed crossing follow-up send the player toward an already-finished watchpost. A shared proposed next-action resolver handled all 30 orders in that small model.
5. Evaluated deterministic counterexamples for spawn-index HP drift, refuge placement, and raw camera framing. These are conditional implementation hazards, not claims that future authored assets already fail.

The older 200-check Twilight PASS from earlier in this chat validates the pre-change game only. It is not reused as approval of this proposal. No new native Windows, Android, physical touch, rendered gate/camera, performance, pacing or full gameplay-suite validation was performed in this audit.

## Findings, highest priority first

### F1 — P1: persist the kill outcome and road completion together

**Evidence:** proposal lines 191–199; [/home/roku/Documents/ChatGPT/game/scripts/combat/enemy.gd:847–875](/home/roku/Documents/ChatGPT/game/scripts/combat/enemy.gd#L847); [/home/roku/Documents/ChatGPT/game/scripts/autoload/game_state.gd:677–692](/home/roku/Documents/ChatGPT/game/scripts/autoload/game_state.gd#L677) and 1671–1673.

Enemy._die() pays ordinary XP through register_kill(); grant_xp() emits data_changed and saves before a later RealmGuard/world callback could record the new pair completion. A callback that merely adds cleared_pairs after super._die() therefore creates an intermediate saved state with the kill/XP accepted and the road completion absent.

**Observed source probe:** calling the actual register_kill(14) produced a saved file with `kills=1`, `xp=42`, `cleared_pairs=[]`. A later separate follow-up produced `cleared_pairs=["rootbound_patrol"]`. The data_changed observer also saw the incomplete pair record. The probe simulates the proposed callback boundary; it does not pretend the new pair callback exists today.

The opposite ordering is also unsafe: saving pair completion before accepting the final kill/XP can remove the pair on reload without awarding its final kill. No speculative extra Gold payout is needed to trigger this issue.

**Required amendment:** identify one GameState acceptance transaction for the legitimate final death, pair credit, kill count and XP mutation. All state must be internally coherent before its signals/save. Refactor a narrow death-reward hook if necessary; do not award XP in a second listener or copy the whole Enemy death presentation into RealmGuard. Ordinary physical drops remain single-owner and retain existing collection/loss semantics. Do not promise persistence success when the save failed.

**Acceptance:** inspect actual JSON and signal snapshots at the reward boundary; duplicate death, second-death reentrancy and replacement must neither double pay nor lose pair credit. Test closure between the legacy call and a hypothetical follow-up to prove that unsafe arrangement is not shipped. This is logical transaction consistency, not a claim of filesystem power-loss durability.

### F2 — P1: specify the entry/intro/combat state machine, not just a readiness predicate

**Evidence:** proposal lines 185–211; [/home/roku/Documents/ChatGPT/game/scripts/world/twilight_realm.gd:282–318](/home/roku/Documents/ChatGPT/game/scripts/world/twilight_realm.gd#L282) and 331–338.

The draft correctly distinguishes consent and presentation in prose, but its named predicate contains only road accomplishments and is then described as shared by admission, targeting and damage. Those are not equivalent permissions. A ready road must not make a boss attackable during the entrance prompt or conversation. Conversely, cancellation must not leave an open gate with an active ruler or strand Adam on its far side.

**Required amendment:** keep a single read-only road-readiness predicate, composed with explicit Game-owned attempt/lifecycle conditions. Lock the transition table before coding:

| Phase | Ward/actor behavior | Combat permission |
|---|---|---|
| SEALED | Missing-task explanation; leave/rest available | None |
| READY | Offer Enter / Not yet; road requirements already satisfied | None |
| ENTRY_GRANTED | Fresh consent; allow ordinary crossing for this attempt | None |
| INTRO | Owned world/clock suspension; guard casts cancelled | None |
| COMBAT | Introduction finished/skipped through valid handoff | Boss targeting/damage allowed only for current live attempt |
| RETREATING | Disable/reset boss and effects first; let actors clear exit | None |
| RESTORED | Peaceful routes; no hostile ruler | None |

Only the COMBAT handoff sets the combat-active owner (`_boss_arrived` must not double as “standing in a conversation”). Admission consent is transient and invalidated on retreat, replacement, defeat and New Journey. Persist intro_seen only at the valid handoff, not as an admission credential.

**Geometry amendment:** explicitly join the chamber's whole boundary. The current east route passes `(35,15)`; the east wall at x=35 spans y=2.5..11.5, so a front-only barrier does not protect that opening. Review northern/outer seams too. A full ward boundary must still leave the separate onward-road network and the route back to the lantern usable. Avoid closing a door on a companion or having an enemy push Adam through it.

**Acceptance:** each phase × readiness × consent × current-world × alive condition gets an explicit test. The audit model exercises 112 such combinations for the recommended policy, but only engine tests can prove future physics and actual call sites enforce it.

### F3 — P1: separate the running rest timer from the suspended preparation reveal

**Evidence:** proposal lines 99–111 and 209; [/home/roku/Documents/ChatGPT/game/scripts/world/twilight_realm.gd:272–279](/home/roku/Documents/ChatGPT/game/scripts/world/twilight_realm.gd#L272), 384–396; [/home/roku/Documents/ChatGPT/game/scripts/game/game.gd:966–1001](/home/roku/Documents/ChatGPT/game/scripts/game/game.gd#L966), 446–456.

Today the two-second rest advances in TwilightRealm._physics_process(). Game-owned story suspension disables that world. Wrapping the existing rest in the new suspended preparation presentation would prevent its timer from finishing. This is a source-backed integration hazard, not an observed deadlock in an implemented new feature.

The current rest callback also clears `_input_locked` directly, while modal-close restoration does not account for a new approach operation. Reusing those callbacks without ownership changes risks premature unlock or competing restorations.

**Required amendment:** sequence normal running rest -> accepted combined heal/checkpoint/readiness completion -> Game-owned suspended reveal. Alternatively, deliberately move the preparation timer to an owner that continues while the world is disabled. Choose one, not a mixture. Keep ordinary early rest available. Store previous world/HUD/input state and release only the lock owned by the finishing operation. Modal close, focus changes, Skip and replacement must not override another owner's lock.

**Acceptance:** completion after the intended two seconds, save/quit during rest and reveal, settings interaction, duplicate input, cancellation on every await, and no stuck/early-released controls. No global SceneTree pause.

### F4 — P2: an already-open legacy winch still needs to restore its new light

**Evidence:** proposal lines 179 and 233–245; [/home/roku/Documents/ChatGPT/game/scripts/autoload/game_state.gd:868–921](/home/roku/Documents/ChatGPT/game/scripts/autoload/game_state.gd#L868); [/home/roku/Documents/ChatGPT/game/scripts/world/twilight_realm.gd:376–382](/home/roku/Documents/ChatGPT/game/scripts/world/twilight_realm.gd#L376).

Existing saves can legitimately have `shortcut=true` and no new road-light fields. The current open_realm_shortcut() returns immediately when the shortcut is already open. The source probe confirmed calling it with an open shortcut does not change a separately introduced `watchpost_lit=false`. The current sanitizer also drops the proposed nested object entirely; that is expected until its explicitly planned implementation is added, not a newly discovered standalone bug.

**Required amendment:** distinguish mechanical shortcut openness from watchpost-light completion. After the required pair is defeated, an already-open winch must offer **Restore the watchpost light**, not “Shortcut open” as though the quest were done. The new combined action must be able to accept light restoration without requiring the old shortcut method to mutate again. Sanitization preserves earned existing openness without fabricating new combat victories, while accepting coherent new fields.

**Acceptance:** real old JSON with shortcut open, camp checkpoint, no citadel_path, old bond records and active expedition. Confirm access cannot be fabricated, the new light remains obtainable, and the return route stays open. Do not reset the shortcut just to force the animation again.

### F5 — P2: don't turn the crossing quest marker into an invulnerability pocket

**Evidence:** proposal line 55 leaves placement for blockout; [/home/roku/Documents/ChatGPT/game/scripts/data/realm_combat_db.gd:31–46](/home/roku/Documents/ChatGPT/game/scripts/data/realm_combat_db.gd#L31); [/home/roku/Documents/ChatGPT/game/scripts/combat/realm_encounter_director.gd:22–23](/home/roku/Documents/ChatGPT/game/scripts/combat/realm_encounter_director.gd#L22) and 98–115.

Every RealmContentDB.INTEREST currently creates a 2.6-radius protected circle. If the new marker is inserted into that catalog beside the crossing fight, this has combat consequences: engagement, damage eligibility and cast travel all depend on refuge geometry. A plausible but NOT approved marker at `(33,37)` puts both existing crossing guard homes inside its refuge. This is a conditional placement hazard, not a proven final-layout failure.

**Required amendment:** road mechanisms must opt out of optional-reading refuge generation unless a refuge is intentionally authored. Put the marker on a reachable, nonblocking approach, reserve its interaction space without blanket combat immunity, and test it against the complete pursuit/cast geometry. Do not expand a refuge into the mandatory encounter or remove protections from existing memories/pet habitats.

**Acceptance:** both crossing guards can engage, be damaged and complete the encounter; marker interaction cannot be used to turn the whole fight off. Low-effects art changes cannot change collision or safe geometry.

### F6 — P2: the crossing follow-up is wrong for half the legal completion orders

**Evidence:** proposal line 66 says “The old watchpost is next”; lines 17 and 220 promise out-of-order credit and accurate guidance.

The exhaustive model enumerated 30 legal sequences of crossing-clear, crossing-light, watchpost-clear, winch, ashen-clear and preparation. In 15, the winch has already been restored when Adam relights the crossing. The fixed line points him back to a completed task. This is a confirmed contradiction in the draft, not speculation about code.

Example: crossing clear -> watchpost clear -> winch -> crossing light -> ashen clear -> prepare.

**Required amendment:** every progress-sensitive line, ward reason and objective uses the same derived next-action resolver. After relighting the crossing:

- Watchpost unfinished: “The old watchpost is next.”
- Watchpost finished, sentries remain: “The last guards are up by the lantern.”
- All guards and earlier lights complete: “The lantern can carry it the rest of the way.”
- Already prepared/revisit: a neutral acknowledgment, not another quest order.

Ordinal lines must count actual restored lights, not assume visit order. Gate reasons should name the earliest actionable missing step, distinguishing defeat the patrol from activate the now-unbound mechanism.

**Acceptance:** all 30 legal orders and coherent legacy mixtures; no already-completed task appears as the required next action. The audit's illustrative corrected resolver handled all 30, but production dialogue still needs implementation/testing.

### F7 — P2: preserving completed pairs must not reindex remaining enemies' stats

**Evidence:** proposal lines 191 and 257; [/home/roku/Documents/ChatGPT/game/scripts/world/twilight_realm.gd:131–148](/home/roku/Documents/ChatGPT/game/scripts/world/twilight_realm.gd#L131).

Guard base max_hp currently depends on a single spawn-loop index. A natural implementation that skips completed pairs before incrementing that index would accidentally lower the HP of later pairs. Original ashen base HP is 50/52. If the first two pairs are skipped and only spawned actors increment the index, it becomes 42/44. These are pre-Enemy-setup source values, not claims about every final scaled runtime HP.

**Required amendment:** derive tuning from stable authored pair/member ordinal, independent of how many nodes are instantiated. Keep stable IDs for death evidence as well. Preserve the boss's existing separate runtime scaling; do not treat its raw PortalDB value as final rendered HP.

**Acceptance:** for every subset of completed pairs, each surviving guard retains the same authored HP/damage/XP/loot configuration as in a fresh reconstruction. No unrelated difficulty rebalance hides inside persistence work.

### F8 — P2: a closed ward alone does not preserve the first boss reveal

**Evidence:** proposal lines 125–129 and implementation map 253–265; [/home/roku/Documents/ChatGPT/game/scripts/ui/village_minimap.gd:103–110](/home/roku/Documents/ChatGPT/game/scripts/ui/village_minimap.gd#L103); [/home/roku/Documents/ChatGPT/game/scripts/core/follow_camera.gd:38–57](/home/roku/Documents/ChatGPT/game/scripts/core/follow_camera.gd#L38); [/home/roku/Documents/ChatGPT/game/scripts/core/game_settings.gd:46–48](/home/roku/Documents/ChatGPT/game/scripts/core/game_settings.gd#L46).

The existing map shows the boss portrait once the citadel landmark is discovered, independently of entrance consent/introduction. Existing boss/prison actors are also constructed before entry. Physical collision does not occlude their sprites. At the minimum zoom of 28, a simple 720-pixel-high frame centered at camp_y-1 reaches y≈8.14, above the boss's y=10 anchor. This frame arithmetic is illustrative; camera limits, lookahead and authored occlusion need rendered testing.

**Required amendment:** specify a transient reveal policy for world actors and a persistent presentation-history policy for maps. Before the legitimate first reveal, show a sealed-entrance marker, not the boss portrait. Gate boss/prison visibility or use proven exterior occluding composition; a camera-bound change alone must not expose an empty/out-of-map view. Preserve normal peaceful post-rescue visibility. Add the actual minimap and camera owners to the implementation map.

**Acceptance:** fresh approach from south, west, east and map panel at both sizes, min/max zoom, lookahead, Reduce Motion and reload. Test landmark discovered but intro unseen separately. Do not call the geometry/camera audit passed on headless evidence.

### F9 — P3: revise the post-victory recognition lines to acknowledge the new introduction

**Evidence:** proposal lines 133–164; [/home/roku/Documents/ChatGPT/game/scripts/ui/story_sequence.gd:260–267](/home/roku/Documents/ChatGPT/game/scripts/ui/story_sequence.gd#L260).

The new intro has Adam and Mei Ling speak before the fight. The retained rescue already contains “Mei Ling!”, “Adam... you found me,” and an authored meeting beat. Nothing is logically impossible, but staging both as the first recognition weakens the new sequence and adds repetition.

**Suggested amendment:** keep the existing prison-opening, reaching/helping-hand and arrival shots, but make their dialogue acknowledge the confrontation: Mei Ling “You did it.” Adam “You're safe now.” Preserve the subsequent Arjun-aware branch and the existing rescue transaction. No new long conversation after victory.

**Acceptance:** read the complete arrival -> road -> intro -> rescue -> return dialogue in both rescue orders; assess emotional continuity and voice, not just isolated captions.

## What survives the audit unchanged

- One coherent rescue purpose, three road accomplishments, and an explicit final confrontation are a good structural fit for the existing compact world.
- The prerequisite graph has no cycle in the small model: all 30 legal precursor orders can reach readiness.
- Wisp can stay optional without allowing boss access to be optional; marker/ward explanations carry essential information if he is missed.
- Pet battles, memories and cache remain genuine optional choices. No companion-species, dead-pet, currency, house-tier, Arjun-order or time-of-day lock is needed.
- The outer ward and prison seal remain distinct. Boss victory still owns Mei Ling's immediate saved rescue; do not add a post-boss prison chore.
- Keeping earned road progress through defeat supports retries and reduces repetitive dialogue/combat. The deliberate loss of ordinary unbanked loot remains coherent.
- Cleared legacy saves should remain peaceful with no retrospective quest debt.

## Explicit tradeoffs, not falsely reported bugs

The draft already acknowledges that unfinished pairs reconstruct and can grant ordinary XP for newly repeated kills. Strict journey-wide per-guard anti-farming was not promised. This audit does not silently turn that into a new required six-guard loot-ledger project. If that economy policy changes, design death/reward/collection persistence together and re-audit it.

The 6–10-minute critical-path target is unmeasured. It stays a playtest hypothesis, not an acceptance figure. Do not pad the map, dialogue or enemy HP to manufacture it.

The proposed new marker coordinate, ward boundary and exterior presentation are not yet authored. Their engine/renderer acceptance remains future work rather than a failed result being disguised as a pass.

## Required revisions before implementation

1. Specify F1's single accepted death/road transaction and failure behavior.
2. Add F2's phase table and permission composition; choose exact ward boundary, safe entry/exit and recovery behavior during blockout.
3. Choose F3's timer/suspension sequence and lock ownership.
4. Add F4's explicit old-open-winch migration case.
5. Author the marker with F5's refuge constraint; preserve stable tuning under F7.
6. Replace fixed follow-up text with F6's shared next-action resolver.
7. Add F8's minimap/camera/actor reveal owners and rendered acceptance.
8. Adjust F9's rescue recognition lines during dialogue pass.

**Audit disposition:** core direction recommended; unchanged draft is not implementation-ready. No new gameplay is declared accepted. The existing proposal is preserved; these amendments are recommendations, not silently applied revisions.

## Reproducible evidence and artifacts

- [Godot source probe](/home/roku/Documents/ChatGPT/citadel-preboss-audit-20261101-ai1eTGox/source_probe.gd)
- [Literal combined Godot stdout/stderr](/home/roku/Documents/ChatGPT/citadel-preboss-audit-20261101-ai1eTGox/source_probe.log)
- [Recorded Godot exit status](/home/roku/Documents/ChatGPT/citadel-preboss-audit-20261101-ai1eTGox/source_probe.exit)
- [Executable Python design model](/home/roku/Documents/ChatGPT/citadel-preboss-audit-20261101-ai1eTGox/design_model_checks.py)
- [Literal model stdout](/home/roku/Documents/ChatGPT/citadel-preboss-audit-20261101-ai1eTGox/design_model.log)
- [Full model states/orders/results](/home/roku/Documents/ChatGPT/citadel-preboss-audit-20261101-ai1eTGox/design_model_results.json)
- [Audited input SHA-256 manifest](/home/roku/Documents/ChatGPT/citadel-preboss-audit-20261101-ai1eTGox/audited_input_hashes.json)
- [Machine-readable finding index](/home/roku/Documents/ChatGPT/citadel-preboss-audit-20261101-ai1eTGox/findings.json)

Source-probe command (user data was set before launching the engine):

```sh
XDG_DATA_HOME="/home/roku/Documents/ChatGPT/citadel-preboss-audit-20261101-ai1eTGox/userdata" \
TIDESWORN_TEST_ROOT="/home/roku/Documents/ChatGPT/citadel-preboss-audit-20261101-ai1eTGox" \
timeout 120 godot --headless --audio-driver Dummy \
  --path /home/roku/Documents/ChatGPT/game \
  --script "/home/roku/Documents/ChatGPT/citadel-preboss-audit-20261101-ai1eTGox/source_probe.gd"
```

Model command:

```sh
python3 "/home/roku/Documents/ChatGPT/citadel-preboss-audit-20261101-ai1eTGox/design_model_checks.py"
```

Both returned exit 0. Assertions in the model verify its stated invariants/counterexamples; they do not prove production gating, physics, rendering or future transaction correctness. The source probe intentionally records current integration behavior; unsupported future fields being discarded is expected before implementation. Original plan and all input files named in the SHA manifest were reopened and checked after the audit.
