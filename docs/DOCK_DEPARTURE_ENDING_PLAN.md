# Dock departure ending plan

Planning date: 2026-10-30. Status: implemented; see the newest dock-departure section in `ACCEPTANCE_TESTS.md` for current validation. The following records the approved design.

## Confirmed experience

The user confirmed these decisions:

- After both rescues, Arjun and Mei Ling wait at the BESUT dock for Adam.
- Approaching them reveals a nearby Embark hint. Adam must deliberately interact.
- The three-friend reunion conversation happens at the dock after choosing Embark.
- The final animatics show all three sailing away together. Their destination stays open.
- An ending card leads to the title screen. Continue offers BESUT exploration explicitly set before departure.

This revises the automatically triggered cottage conversation and the old dock image that only hinted at future travel. Preserve the existing rescue stories, emotional dialogue, and saved progression.

## Player journey

1. Rescue either friend first; the other rescue remains available. No ending prompt yet.
2. Complete both rescues and return safely to BESUT. Finish the real incoming ship/disembarkation if Arjun was rescued last.
3. The friends gather at two clear dock posts. Already present friends walk there; loading an eligible save reconstructs them there without replaying an arrival.
4. Persistent objective text says: "Arjun and Mei Ling are waiting at the dock. Join them when you're ready." The world map marks the dock as the next story destination.
5. Adam remains free to explore, shop, defend BESUT, or leave and return. Waiting alone never starts an ending.
6. Within boarding reach, show "E - Embark together" for keyboard, or "Tap to embark together" for touch. A small in-world label belongs to the boarding point. Use the existing contextual HUD hint too; do not add a permanent touch action button.
7. An explicit activation starts the dock conversation. A brief dissolve connects the current live composition to the illustrated composition.
8. The conversation leads into preparation, boarding, farewell, and visible sailing. The final card closes the chapter without naming a destination.
9. Completing the ending saves its completion and returns to title. The completed save offers "Explore BESUT" with "Before departure" clearly visible.

## Live dock staging

Use the existing yellow UNISZA ship, jetty, and canonical rescued-friend IDs. Stage one Arjun and one Mei Ling; do not add decorative duplicates beside existing defenders.

- Derive posts and the boarding point from the resolved `jetty_deck` approach and harbour layout. Respect player layout, developer overrides, coast collision, crates, lamps, and Pak Rahim's existing position.
- Choose two validated standing posts off the central approach. Keep a clear Adam-sized path from land to interaction range. Validate routes and the actual timber footprint; a generic sea-rejecting spawn helper alone is insufficient for a dock.
- Give the friends distinct waiting poses: Arjun checks the mooring/looks toward the approach; Mei Ling stands beside a supply bag and watches for Adam. Both can turn toward him nearby without following him around.
- Add a temporary dock-wait duty to the existing `VillageHero` actors. Preserve their ability to respond to close threats, with a short leash around the dock and a return to their posts afterward. They must not chase an enemy across BESUT while the ending claims they are waiting.
- The interaction requires both friends to have arrived and settled. An interrupted walk resumes through normal actor routing. Unreachable posts keep the interaction unavailable and trigger a layout fallback to another clear position on the connected dock approach.
- Do not suspend village time, spawns, or attacks while Adam walks over. A nearby fight postpones embarking; it does not consume the ending or require clearing the whole map.
- Preserve Arjun's passenger handoff. While `_arjun_returning` owns him, create no village duplicate. If both friends are rescued, his incoming walk ends at his dock post; otherwise preserve his ordinary village return. Release the passenger representation before handing its final position to the canonical village actor.
- A friend already defending BESUT walks to the dock when the second rescue makes departure eligible. Repeated `data_changed` signals update duty without restarting the route or spawning another body.
- On a completed save's predeparture free play, both friends return to their usual defender behavior. The ending interaction is absent. A dedicated replay feature is outside this first implementation.

## Interaction and ownership

Create a dedicated `FinalDeparture` interactable at the dock. It references the existing ship presentation but calls a new Game-owned ending entry point, such as `begin_final_departure()`.

The turtle rescue route remains owned by `ShipDeparture`, `board_ship()`, and `enter_ocean()`. `sea_journey_available()` stays false after Arjun's rescue. The new ending route never changes ocean checkpoints or uses an exception to reopen that route.

Use one shared readiness predicate for hint visibility and actual activation. Revalidate it on activation, even if the hint was visible in the previous frame:

- Current world is the owning Lobby with the current journey serial.
- Both rescue flags are saved, final departure has not been completed, and both live friends occupy valid waiting posts.
- No transition, sailing, story, dock conversation, portal/arrival reveal, modal, settlement editor, home interior, game over, pending defeat, recovery, or emergency owns play.
- Adam is alive, awake, not attacking, and in actual boarding reach. Begin with the existing 2.2-world-unit ship radius, then tune from native captures.
- Nearby threats and burning trees around Adam, the friends, and the boarding approach are clear. Distant village enemies do not block forever.
- The referenced ship is moored and the incoming rescue return has finished.

The 0.75-second ending check becomes a readiness/staging refresh. It must stop calling `play_story("ending")` automatically. Auditing all existing `_check_campaign_ending()` callers is essential: lobby load and ship return must only prepare the invitation.

`FinalDeparture` uses the established distance/group API, not physics `body_entered`. Keyboard E and a direct mouse/touch target share the same entry point and proximity requirement. Unlike the older rescue ship's direct tap, clicking this ship from across the village must not start the ending. The embark target must be easy to select without Pak Rahim winning the same interaction zone.

If the player walks away, the hint disappears. If danger appears, hide the Embark action and show a concise local reason such as "Clear the nearby danger first." Do not use the no-op toast channel. Clearing danger restores the invitation; it never starts the story automatically.

Accepting Embark acquires the story lock immediately, releases held actions, hides ordinary HUD, and suspends the world and shared clock. One owned operation prevents duplicate starts from E repeats or touch/mouse emulation. Preserve world/journey/actor validity checks after every await.

## Conversation at the dock

Keep the thirty spoken turns and seven emotional movements: relief, the fishing-trip apology, fear while separated, a safer plan, gratitude to BESUT, practical preparation, and familiar companionship.

Restage the conversation against dock rails/crates, with all three at human scale in a loose triangle. Replace cottage/table-specific actions with dock actions. Mei Ling can hold a water flask; the admission about her cell still has a quiet listening shot. The three cups and courtyard should not appear after Adam has explicitly joined friends at the jetty.

Preserve reactions between speakers, rather than showing a single speaking portrait for every line. Distinct hands, posture, eye direction, and movement carry the scene.

Review the final preparation exchange for its new context. "Water. Food. A route. Then the boat." can remain if they are still on the dock preparing to board; supplies in the background must agree with it. Avoid dialogue implying they already reached their original world.

Dialogue stays player-paced. First Next reveals the current line; the next fresh press advances. Skip conversation jumps to the departure beats, not straight to title or a completed save.

## Departure storyboard

The following records the planned staging. The implemented seven departure beats and final copy live in ReunionDialogueDB and ReunionRenderer; the optional final spoken exchange was omitted. Dialogue reading time is unrestricted; the wordless departure targets roughly 25-40 seconds in the normal-motion presentation.

| Beat | Image and action | Purpose |
| --- | --- | --- |
| 1. All three | Match the live dock into an illustrated wide shot. Adam joins the space between his waiting friends. Start the reunion conversation here. | The player's approach becomes a visible act of joining them. |
| 2. Ready together | After the final exchange, Mei Ling secures the supply bag. Adam checks a rope; Arjun helps instead of rushing ahead. Show the group confirming readiness with a shared look. | Their new plan becomes action. |
| 3. Thank you, BESUT | Rahim and a small group of villagers stand on the shore. Adam offers a clear nod/wave, answered by the others. Keep it brief; gratitude was already spoken in the conversation. | Recognize the community that kept the search possible. |
| 4. Board | Show each friend physically crossing to the deck in an ordered sequence. Track all three through the cut; use distinct human-scale deck positions and correct hull layering. | Make boarding readable and prevent an apparent teleport. |
| 5. Cast off | Only after everyone is aboard, release the mooring line and stow it. The ship begins moving relative to the jetty; water and a wooden creak support the motion. | Establish that this departure actually happens. |
| 6. BESUT recedes | Wide shore view: the ship leaves the dock while villagers remain ashore. Follow with an onboard three-shot; the friends look outward together. | Give the farewell room and echo the opening separation with present togetherness. |
| 7. Open water | All three remain visibly aboard against the open horizon. Optional quiet final exchange: Adam, "Ready?"; Mei Ling, "Together."; Arjun, "Together." Dialogue is optional and must earn its place. | Close the rescue story and leave the destination open. |
| 8. Ending card | Fade to "Together, wherever the tide leads." with PB (Protect BESUT) branding and an intentional "Return to title" control. Final wording remains editorially adjustable. | Provide a clear ending and a deliberate exit. |

Avoid a second wreck, another encounter, a new portal, or naming a destination. The arrival at any future destination is a separate chapter.

Use the existing pixel-art presentation family and yellow ship silhouette. Capture day/night palette from the real world at entry. Night uses readable deck lighting; do not reset the clock to force sunset. Include an active companion in a quiet deck position if one is present, without changing its saved ownership or health; verify that it does not obscure the three friends.

Wordless beats can finish their authored motion then hold for Continue. This makes room for the farewell and keeps every animation inspectable. A separate Skip ending control can reach the final card once the player has chosen departure. Require input release before the final title action; a held E or fast double tap cannot fall through several stages.

Reduce Motion uses stable key poses, short dissolves, and discrete ship positions that still clearly communicate boarding and sailing. Low effects removes optional spray/ambient detail while retaining actors, ropes, supplies, shore separation, and subtitles. Muted playback communicates every important event visually.

## Saves, interruption, and free play

Keep `ending_seen` as the existing reunion completion record. Add one production-owned boolean, `campaign.departure_seen`, to distinguish the newly playable departure from older completed cottage reunions. Waiting/readiness is derived; do not add saved actor nodes, transient animation pages, or another redundant readiness flag.

- New journeys: both completion flags false.
- Both friends rescued and `departure_seen == false`: the dock ending is available, including on an old save with `ending_seen == true`. This gives old players an optional new ending without forcing a replay or removing their recorded reunion.
- Missing/invalid departure field sanitizes to false. A departure record requires both rescues. A valid true departure record also implies `ending_seen == true`.
- Starting or cancelling the sequence never marks final departure complete. Natural progression through the final card, or deliberately skipping to that card, can complete it once.
- Add a GameState transaction such as `complete_final_departure()` to validate rescues, set both flags together, emit the owning signal, and save at one boundary. UI and renderers do not write progression or grant rewards.
- Preserve inventory, currency, rescued friends, village condition, pet state, portal progress, and ocean checkpoints. Capture/save the real village at departure entry; the suspended cinematic does not age it.
- The final card's title action keeps story/input ownership until the title transition covers the world. Do not briefly restore live combat or advance the clock between the ending and title.
- If the app closes, a world is replaced, or a journey changes before the completion transaction, the next load returns to the dock-ready state. Full scene restart is sufficient; mid-line resume is outside scope.
- The completion transaction occurs on an explicit final-card action before returning to title. If closing occurs after the successful save but before the title transition finishes, Continue still recognizes completion.
- Existing save methods return void; `_save_now()` currently warns and returns when opening the file fails. Expose a success result for the ending completion path, with other callers free to ignore it. Check writing/closing as well as opening. If completion cannot be saved, keep the final card with a concise retry message instead of claiming a saved ending and leaving for title; restore the previous completion flags until retry succeeds.
- After final departure, Continue is labelled "Explore BESUT" with the subtitle "Before departure". It restores the preserved village state using the normal safe spawn. This is explicit earlier-time free play, so the friends can remain village defenders without contradicting their on-screen voyage.
- Older saves with only `ending_seen == true` still say Continue Journey until the new departure is completed. They can visit the dock voluntarily. No save resets or re-earned rescues.

## Implementation map

| Owner | Intended responsibility |
| --- | --- |
| `scripts/autoload/game_state.gd` | Departure default/sanitization, eligibility, final completion transaction, ready/completed campaign objective copy. |
| `scripts/game/game.gd` | Replace automatic story entry with staging refresh; own begin/cancel/complete/title flow, safe context, and Arjun passenger handoff. |
| `scripts/world/lobby.gd` | Resolve and validate dock posts, sync existing friends into/out of dock duty, construct the ending interactable, refresh with layout changes. |
| `scripts/world/village_hero.gd` | Dock waiting/movement, bounded local defense, same-world guards, return to regular defense during predeparture free play. |
| New `scripts/world/final_departure.gd` | Nearby keyboard/direct-tap Embark target and local hint; no save writes or ocean transition. |
| `scripts/world/ship_departure.gd` | Preserve rescue-route closure and incoming return. Share a visual reference if needed; do not add a bypass into ocean travel. |
| `scripts/data/reunion_dialogue_db.gd` | Preserve shared dialogue for both rescue orders and revise dock-specific wording only as necessary. |
| `scripts/core/reunion_art.gd`, `scripts/ui/reunion_renderer.gd` | Dock conversation poses and listening shots; preparation/boarding/sailing art and sampled motion. A small separate departure renderer is appropriate if this keeps responsibilities clearer. |
| `scripts/ui/story_sequence.gd` | Explicit conversation/departure/card phases, input release/debounce, owned sound, cancellation, and one completion signal. |
| `scripts/ui/game_hud.gd`, `scripts/ui/village_minimap.gd`, `scripts/ui/world_map_panel.gd` | Context hint and dock story destination using existing UI ownership; the expanded map reuses VillageMinimap. |
| `scripts/ui/title_screen.gd` | Completed-save Explore BESUT wording and before-departure explanation without changing New Journey behavior. |
| `scripts/data/field_guide_db.gd`, story docs | Explain dock invitation, deliberate embark, actual sailing, and earlier-time free play. |
| `tools/reunion_checks.gd`, related campaign/ocean fixtures | Replace automatic-entry assumptions with proximity and explicit interaction coverage. Retain the isolated `-Reunion` review route. |

## Work order

1. Implement and verify GameState eligibility/migration and remove automatic ending playback. Keep the ending callable through an explicit guarded entry.
2. Implement live friend staging and the actual Embark target. Review their walk, arrangement, input, and return-from-rescue handoff before building more cinematic content.
3. Restage the reunion dialogue at the dock and connect its completion to explicit departure phases.
4. Author boarding, cast-off, sailing, ending card, and the continuous handoff to title. Verify every actor through consecutive frames.
5. Add completed-save free-play wording and align objective, map, guide, and documentation copy.
6. Update affected fixtures, run the focused and full isolated gates, inspect native captures, and record only new evidence in acceptance documentation.

## Implemented details

`FinalDeparture` supplies a nearby E/ship/direct-tap route plus a tappable contextual banner. Both actors retain stable VillageHero identities, names, local defense and validated dock posts. Cached routes are revalidated after the complete village physics registration and layout changes; a blocked post gets a reachable alternative instead of an unsafe teleport.

The shared dialogue now uses the dock renderer. Seven explicit departure pages follow: preparation, gratitude, a visible gangplank crossing, cast-off, a receding ship, open water, and the final card. The active living companion is carried through the boarding shot. Each wordless page waits for its authored motion and then for Continue; the seven minimum holds total 28 seconds. The optional extra spoken exchange was omitted. Warm procedural music/surf, creaks and dialogue voices are owned by the sequence and stop on focus loss, mute, skip/cancel and exit.

The final-card action commits both completion flags through GameState, with rollback and retry if the file cannot be saved. Game holds the suspended world through the covered title transition. Completed saves offer Explore BESUT / Before departure; old reunion-completed saves can choose the new voyage at the dock.

## Acceptance criteria

Progression and staging:

- Neither rescue alone enables departure. Defeating the Kraken without opening Arjun's cage is insufficient.
- Both rescue orders reach the same invitation and conversation; Arjun's real incoming docking finishes first.
- Distant waiting, loading, periodic safety checks, and clearing a threat never auto-start the ending.
- Exactly one live Arjun and one Mei Ling exist; repeated signals, world swaps, and reloads do not duplicate them.
- Observe consecutive positions for their walk to the dock, local threat response, return to posts, and final passenger handoff. Validate altered layouts and blocked-post fallback.

Interaction and presentation:

- Far-away E/click/touch cannot embark. Nearby E, direct mouse click, and touch each start once. Crossing the radius alone does nothing.
- Pak Rahim remains accessible without stealing the Embark target. Sprint stays Sprint and no permanent Use/Board touch button appears.
- Every readiness guard blocks activation and resumes only the invitation afterward. Test threats at both friends and the dock, not just beside Adam.
- Long reading pauses do not advance dialogue or world time. All three speakers remain readable at 832x480 and 1280x720.
- Skip at each conversation turn reaches the departure; Skip ending reaches the final card; repeated gestures do not bypass release guards or complete twice.
- Boarding visibly places all three aboard before ropes release. The ship visibly separates from the jetty and BESUT recedes. Inspect frame sequences, not just start/end images.
- Day/night, mute, low effects, live Reduce Motion, and an active companion remain coherent. Sound stops on skip, focus loss, cancellation, and exit.

Saves and transitions:

- Real JSON reload preserves completed departure, rescues, possessions, village state, and the unchanged ocean checkpoint.
- Old reunion-completed saves gain optional dock departure while keeping their completion record. Malformed/missing new fields sanitize safely.
- Cancellation/world replacement at every phase leaves departure unconsumed, releases owned controls/audio, and never writes into a new journey.
- Final completion pays no loot, removes no friends or items, and never creates OceanJourney or KrakenIsland. The completed sea-rescue route remains closed through direct and low-level entry points.
- The final card leads to title without a live-world flash. Explore BESUT clearly says Before departure, loads safe free play, preserves defenders, and never automatically repeats the ending.

Validation routes after implementation:

- Isolated Windows import using `tools/test_isolated.ps1 -Godot <console-executable> -ImportOnly`.
- Focused `-Reunion`, plus native `-Reunion -Capture -Resolution 832x480` and `1280x720`; inspect input and consecutive animation frames.
- Focused `-OceanLevels` to protect completed sea closure, incoming return, and rescue flow; affected story/map/title checks in the canonical suite.
- Full isolated gameplay gate, requiring its final PASS summary, exit 0, and no failure/error markers. Inspect and report warnings.
- Update `tools/tide_test.gd` and `docs/ACCEPTANCE_TESTS.md` together for the new ending rule; run `git diff --check` and review the scoped diff.

The plan began as a source-inspection document. Implementation and fresh validation are recorded separately in `ACCEPTANCE_TESTS.md`; earlier results do not certify this change.
