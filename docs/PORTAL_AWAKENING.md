# The road remembers — portal discovery and awakening

Implemented 2026-10-30. New journeys begin with a fallen waystone at the existing
`monster_portal` anchor, without a usable Dimension Portal or its map icon.
The old travellers' road reconnects when Adam aligns its marker and supplies the
village lantern Rahim lends him. This connects the village opening to Twilight's
existing memories of the citadel taking the road's light.

## Playable flow

1. Approach the broken stones and tap them, or use nearby E. A short world caption
   describes the broken carved line and empty lantern socket. Reading does not
   pause simulation or lock movement. Walking away clears the caption.
2. Speak with Pak Rahim at the dock. After discovery, his five-line contextual
   conversation replaces the ordinary reminder. He recalls his father's story,
   admits uncertainty about the destination, and lends a lantern freely.
   Completing the conversation or explicitly skipping it prepares the repair;
   cancellation/world replacement does not. Later chats remind the player what
   to do, and recognize an already open road.
3. Return to the stones and choose the nearby interaction, "Set the marker and
   light the road." Local enemies, recovery, emergencies and arrival ownership
   prevent unsafe overlap. There is no kill quota, night requirement, paid key,
   house upgrade, workshop dependency or inventory relic.
4. The eight-second reveal aligns the marker, lights the carving progressively,
   shows the answering road, forms the arch, and settles into the normal portal.
   The player remains in the real clearing and chooses when to enter afterward.
5. The existing portal transition enters Twilight Wilds. Wisp's first greeting
   recognizes a village lantern. His later discovery/memory/restoration responses
   remain intact. Normal expedition rewards, bonds and rescue progression continue.

The village clock and world suspend during the deliberate reveal; ordinary
discovery captions and later Rahim chats retain the normal non-pausing rules.
Game owns held-input release, suspension, camera/HUD restoration and cancellation.
The reveal has an immediately available Skip button. Reduce Motion uses stable
tableaux; low effects and mute preserve the explanatory visuals and captions.
No player/pet repositioning, terrain editing, new monster spawning or rewards
are part of opening the road.

## Guidance and persistence

`GameState.portal_origin` stores schema 1 plus `site_examined`, `rahim_consulted`,
`opened` and `reveal_seen`. All production writes use GameState transactions.
Opening saves before presentation and does not start an expedition. Continue
after an interrupted reveal retains the usable portal, with an optional nearby
Watch awakening button. E/main gate interaction still enters the open road.

Raw saves lacking this record predate the feature and retain their previous
portal access without a forced reveal. Active expeditions, saved realm presence,
attempts, clears or Mei Ling's rescue reconcile contradictory closed flags.
Unknown future numeric schemas fail load without overwriting the file.
New Journey explicitly resets origin progress; defeat does not close an opened
road or erase its discovery.

The map hides both the gate and waystone until discovery. After examination it
shows a stone marker, switching to the normal portal picture after opening.
The portal tutorial lesson, Missions panel and objective guidance describe the
current discovery stage. Portal/boss teaching is available in daylight too.
Tutorial Hide tips does not remove interactions. The opening promise no longer
names a final portal before Adam discovers a road; the early guide preserves
his uncertainty about Mei Ling's location.

## Ownership and verification

- `PortalOriginSite` and `WaystoneArt`: nearby interactions, captions, broken stone,
  borrowed lantern and progressive carved light.
- `PortalAwakening`: deterministic reveal timeline and temporary camera, captions,
  Skip and restoration of hidden overhead vitals.
- `Game`: world/journey ownership, local danger checks, suspension and cleanup.
- `GameState`: origin defaults, transactions, eligibility and actual save migration.
- `DockConversation`: contextual discovery exchange and ready/open reminders.
- `Lobby`, `VillageMinimap`, `MissionDB` and existing guidance/guide owners:
  stage-dependent world construction and player directions.

`tools/portal_origin_checks.gd` is included in the canonical gameplay gate. The
focused route is `tools/test_isolated.ps1 -Godot <console-executable> -PortalOrigin`.
Add `-Capture -Resolution 1280x720` or `832x480` for native rendered evidence.
Native runs exercise actual screen taps and Skip; headless runs use the same
world touch handler without relying on a nonexistent physical window transform.
Both routes exercise nearby E, actual save files and the real Twilight transition.
Record verification results in `docs/ACCEPTANCE_TESTS.md`.
