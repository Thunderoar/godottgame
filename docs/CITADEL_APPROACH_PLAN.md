# Earn the road to Chaos Citadel — incorporated implementation specification

2026-11-01. Incorporates all nine findings in the external Citadel deep audit.
This supersedes the earlier position-only first-boss threshold and optional-winch
behavior. The original proposal and audit remain preserved outside the repository.
Acceptance evidence is recorded separately; this specification is not a test result.

## Playable progression

1. Arrival Glade retains its return rift and optional Wisp conversation. Wisp
   recognizes the village light, confirms an archer was taken alive, and explains
   that three guarded road lights feed the outer ward. Adam supplies Mei Ling's
   name. Wisp stays in his home; neither speaking to him nor reading lore is a gate.
2. Defeat the Rootbound patrol waves (2, 4, then 6 Imps), then relight the crossing marker at (33,40.8).
   It is a mechanism, NOT a protected optional-reading interest. Its silhouette,
   steady light and message change; there is no new XP or currency payout.
3. Defeat the watchpost waves (2, 4, then 6 alternating Imps/Watchers), then turn the existing winch at (37,32).
   This restores the second light and opens the physical Rootway shortcut in one
   accepted action. Already-open legacy shortcuts can still restore the new light.
4. Defeat the ashen waves (2, 4, then 6 alternating Imps/Keepers). Rest at the lantern to heal Adam and revive/
   heal the companion, save the camp checkpoint, and prepare the third light.
   Ordinary early rest remains available even before any road task is completed.
5. At the outer ward choose Enter the citadel or Not yet. Three labeled road
   emblems communicate progress. The physical wall covers the whole chamber,
   including the east and north seams; the exterior onward-road network remains
   usable. Consenting opens ordinary traversal, not automatic movement/combat.
6. Cross the inner threshold for the Game-owned, player-paced first confrontation.
   Adam recognizes Mei Ling; she warns about the floor; the fiend refuses to free
   her. Three readable cards contain seven lines. Face the fiend or Skip commits
   presentation history and hands control to the actual boss. Retry uses one card.
7. Boss victory still saves Mei Ling rescue, rewards and clear before the existing
   seven-shot rescue. The relief line is now “You did it” rather than repeating a
   first recognition. The Arjun-aware exchange, BESUT defender, peaceful realm,
   Luma, workshop guidance, optional onward stages and dock ending stay intact.

Nothing requires pet wins, memories/cache, purchases, another level, house upgrades,
nighttime or rescuing Arjun first. No new inventory key, price or damage buff is added. Reinforcements expand the
existing profiles; their short arrival warnings are safety cues, not an idle quest timer. Tasks may be done out of order; mechanism messages,
ward reasons, tracker and selected navigation derive from one next-action graph.
The selected `citadel_road` objective ID remains stable as its next task changes.

## Audit F1: single kill/road transaction

Enemy._die delegates its existing reward work through an overridable narrow hook.
RealmGuard accepts an actual lethal death through GameState before presentation.
Current-world ownership, the actual pack member, stable sector/wave/member ID, lethal HP,
combat damage eligibility and a visit-local duplicate claim are checked. The
GameState transaction mutates the kill count, XP and (on the final actual death of a wave)
completed-wave checkpoint; the third wave also completes its sector before saving or emitting data_changed. Save failure rolls back the
state and claim without presenting a recorded victory. Ordinary physical drops
are spawned once by the inherited death hook after acceptance, not paid by another
listener. Normal Enemy, boss and village reward branches retain their behavior.

Completed waves persist for the journey and do not respawn. An unfinished
wave reconstructs on Continue under the existing policy; strict per-guard lifetime
anti-farming is intentionally not introduced. Unbanked loot still follows ordinary
banking/defeat loss; road persistence does not silently insure dropped/carried loot.

## Audit F2: readiness and runtime permissions

`CitadelApproachDB.ready` requires all three pair IDs, both earlier light flags,
the open shortcut and lantern_prepared. This is NOT sufficient damage permission.

| Phase | Meaning | Boss damage |
|---|---|---|
| SEALED | Missing-task explanation; rest and return remain usable | No |
| READY | Road earned; offer Enter / Not yet | No |
| ENTRY_GRANTED | Fresh consent; physical front opens | No |
| INTRO | Threshold conversation owns suspension | No |
| COMBAT | Valid introduction handoff, current live world/attempt | Yes |
| RETREATING | Reset actor/spells before restoring entrance ownership | No |
| RESTORED | Peaceful saved clear; no hostile ruler | No |

Only the combat handoff sets _boss_arrived, enables the ruler, frames the chamber
and starts its music. Leaving the arena resets boss HP/effects and revokes entry
consent without losing road progress. A fresh choice is needed for another attempt.
Ranged/companion attacks use the same composed current-world combat permission.
Abnormal external placement inside the locked trigger safely recovers to camp;
ordinary movement stays continuous. The ward never seals the main exit during an
active fight; retreat uses the south opening. Outside passages are not chamber
back doors and remain reachable from the approach.

## Audit F3: timing, input and cancellation

The normal two-second rest runs in the active world. At completion one transaction
heals, saves camp and (if eligible) records lantern preparation. Only AFTER that
completion does the Game-owned preparation dialogue hold gameplay callbacks. The ambient
world, HUD, music and shared clock continue. A modal can defer its reveal without losing earned preparation. Modal-close
routing does not unlock an unfinished rest. There is no global SceneTree pause.

Game owns the conversation, callback hold/HUD/lock state and cancellation.
It releases held world controls, holds the owned realm
actors while the reading cards are open. The world process mode and visible HUD
are preserved; environment/idle animation and the shared clock keep running. Normal Wisp/optional reading and ordinary menus retain
non-pausing rules. Every conversation completion checks world and journey identity.
Clear-world cancels owned entry/introduction before retiring actors. Focus loss
cannot advance or arm dialogue; focus return requires a fresh release/press. All
buttons have explicit keyboard focus and release guards; text is readable without
a typewriter. Skip advances the introduction to combat, never rescue or rewards.

## Audit F4: additive save compatibility

`realm_progress.citadel_path` contains cleared_pairs, waves_cleared, crossing_lit, watchpost_lit,
lantern_prepared and intro_seen. Defaults and load sanitization both own it. Pair
IDs are allowlisted/deduplicated and flags require actual boolean types.
Wave counts accept only finite integral numbers from 0 through 3. Legacy completed
IDs migrate to three completed waves; three waves reconcile the completed ID. Light
flags require their pair; prepared requires the complete prerequisite graph;
intro_seen requires prepared. Earned watchpost light reconciles shortcut openness.
The global save version remains 6. No actors, timers or consent are serialized.

Old uncleared saves keep camp/shortcut, discoveries, pets and possessions but do
not fabricate road victories from attempts or checkpoint presence. Their open
winch offers restoration of its new light. Cleared first-stage saves retain
peaceful access and the existing Mei Ling rescue migration without repeating
rewards. New Journey resets the new fields. Test developer travel uses its existing
separate save and explicitly prepares a direct-Citadel fixture without paying XP.
There is no new production skip flag or arbitrary console command.

## Audits F5–F9: geometry, dialogue, tuning and reveal

- F5: the crossing site is outside RealmContentDB.INTERESTS; it reserves no combat
  refuge. Existing protected habitats, reading sites and camp keep their rules.
- F6: `next_step` drives progress-sensitive text and directions. Completing the
  watchpost before crossing never sends Adam back to a finished winch. Named
  dialogue pages avoid fragile turn offsets. Wisp ambient responses remain.
- F7: authored sector/member ordinal remains stable when completed waves are skipped;
  remaining enemies retain the original tuning and existing CombatBalance scaling.
- F8: unrevealed ruler/prison are hidden behind the ward composition; merely
  discovering the citadel shows a sealed entrance on both map sizes, not its boss
  portrait. Legitimate intro reveals actors; persisted intro_seen permits later
  recognition. Dead bosses stay hidden across data_changed and the rescue tween.
  Interior fighting lanes/arena bounds and normal camera behavior are preserved.
- F9: existing prison opening/helping-hand/arrival shots remain. Only redundant
  recognition wording is adjusted; the Arjun branch and rescue transaction remain.

## Review and acceptance

The canonical Twilight scene includes Citadel checks, also available alone through
`res://tools/citadel_test.tscn`. Always set XDG_DATA_HOME and TIDESWORN_TEST_ROOT
before starting Godot; use the Windows isolated wrapper's Twilight route on Windows.
The dedicated route covers fresh rush rejection, real front/east collision,
exterior passage reachability, map concealment, the prerequisite truth table,
actual guard deaths, save/reload, stable stats, coherent final-death notifications,
early rest, preparation suspension, optional-content independence, entry consent,
keyboard/touch input, focus loss, short retries and replacement cancellation.

Keep independent focused Mei rescue and Developer checks and the full tide gate.
Rendered review is required at 1280x720 and 832x480, including low effects, Reduce
Motion, actor visibility, reading fit, actual buttons and safe traversal. Native
Windows/Android and player pacing are not certified by Linux/headless/llvmpipe.
The former 6–10-minute target remains an unmeasured playtest hypothesis, not a claim.

## Reinforcement expansion — 2026-11-01

The same road graph now requires nine waves / 36 guards before boss entry.
`REALM_REINFORCEMENT_WAVES.md` owns warning/cancellation, checkpoints and rewards.
Existing Enter/Not yet, introduction, retreat and rescue contracts remain unchanged.
