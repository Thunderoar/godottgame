# The road remembers — portal discovery and awakening

Implemented 2026-10-30; exploration-first flow revised 2026-10-31. New journeys
begin without a portal. Only the fallen waystone remains at the stable
`monster_portal` anchor. Explore it, read the clue, consult Pak Rahim at the dock,
then return with his key to awaken the road. This supersedes the earlier
key-first revision on the same date.

## Playable flow

1. After the opening welcome, the first objective is **Explore the northern
   clearing**. Selected mission navigation and the default trail lead to the
   waystone. There is no portal actor, usable gate or portal picture on the map.
   Talking to Pak Rahim early gives his ordinary reminder and cannot grant a key.
2. Arriving within the waystone's normal interaction range automatically discovers
   it through the current-world/proximity/line-of-sight guards. E or a nearby tap
   can also examine it. A persistent **The missing portal** dialogue explains the
   fallen road and explicitly directs the player to Pak Rahim at the dock.
   It uses the existing fitted, scrollable modal with a visible Close action;
   dialogue z-order is above tutorial cards, HUD and world art. It releases held
   controls and hides selected navigation while open. Reading locks input but
   follows ordinary menu rules: the village clock continues.
3. The objective becomes **Meet Pak Rahim** and the same live arrow switches to
   him. His five-line conversation explains the sleeping road and gives its free
   permanent portal key. Cancelling or retiring its world grants nothing; explicit
   Skip/completion grants the key. The opening welcome never grants it.
4. The objective becomes **Unlock the Dimension Portal** and points back to the
   clearing. Enter/E or a nearby tap with the key unlocks the lantern socket.
   Nearby danger, recovery, emergency and arrival guards remain enforced. There
   is no payment, kill quota, night rule or house/workshop prerequisite.
5. The existing eight-second reveal aligns the fallen marker, lights the carving,
   shows the answering road and forms the portal. Opening is saved before the
   presentation. Skip/interruption retain the original contracts. Actors are not
   repositioned. A separate Enter travels into Twilight Wilds through its normal
   transition; expedition loot and both rescue arcs keep their owners.

BESUT Field Guide, mission cards, dock welcome/conversation and world captions
follow clearing → clue → Pak Rahim → key → portal. Stage-dependent descriptions
update after discovery and receipt; repeated objective instructions are suppressed.
People includes Rahim's actual village sprite and a key pictogram. The guide also
explains selectable mission arrows and the Sprint/Talk/Enter/Exit control.
Equipment references match Garrick and the Equipment Shop.

The deliberate portal reveal suspends the village and shared clock; ordinary
conversations and early locked-site captions do not. Game owns held-input release,
suspension, camera/HUD restoration and cancellation. Reduce Motion, low effects,
mute, save-before-presentation and one-time completion remain supported.

## Decoration and discovery cues

The unopened site reads as an old roadside landmark: a chipped oval of pale
stone, moss and fragments surrounds the fallen marker. Engraved stepping stones
curve toward the gap between the nearby cottages. Pale moonblooms and two
weathered wayfarer ribbons frame the edges while leaving the central approach
and lantern socket readable. The dressing follows the resolved portal anchor;
it introduces no collision, terrain paint, tree changes or new interactables.

A small glimmer draws attention to the empty socket. Extra quiet glimmers and
slight ribbon movement are available at medium/high effects; low effects and
Reduce Motion retain a steady socket cue and all essential stone/flower/cloth
silhouettes. Rahim's key-ready stage warms the glimmer, and opening the portal
retires it so the completed landmark no longer looks like an unfinished task.
Ambient presentation never writes discovery or progression and uses no gameplay
RNG, particles or extra light sources.

The focused native review includes a wider approach, a low-effects/Reduce Motion
view and a quiet night-lighting fixture, as well as the discovery conversation
and full reveal. This keeps visual verification separate from attack scheduling.

## Guidance and persistence

`GameState.portal_origin` retains schema 1 and the stable fields `site_examined`,
`rahim_consulted`, `opened` and `reveal_seen`. The saved `rahim_consulted` flag now
owns the permanent quest key, exposed through `portal_key_received()`. It is not
shop inventory and cannot be duplicated, sold or consumed. All production writes
still use GameState transactions. `consult_waystone()` requires discovery before
granting it; `open_waystone()` requires the key and records the actual site visit
with the opening commit. No new save version or saved field is required.

Key-only saves preserve the earned key with `site_examined=false`. Older completed
lantern conversations retain their earned access as the key. Raw saves without
origin data, active expeditions, saved realm presence, attempts, clears and rescue
flags retain their existing portal-access migration. Unknown future numeric
schemas are still rejected without overwriting the save. Malformed records cannot
fabricate access. New Journey resets the key and portal; ordinary defeat preserves
journey progression.

The actor's display name is Pak Rahim. The internal `PakRahim` node name, portrait
path and saved `rahim_consulted` ID remain stable for compatibility. Before either
a key or an optional examination, the locked site's map icon stays undiscovered;
after discovery it becomes visible. Opening changes it to the normal
portal picture. Missions, objective cards, selected arrows, default paths and the
Field Guide all use the same stage-dependent instructions. Hide tips does not
remove the key quest or its interactions.

## Ownership and verification

- `PortalOriginSite` and `WaystoneArt`: nearby interactions, captions, broken stone,
  key-locked lantern and progressive carved light.
- `PortalAwakening`: deterministic reveal timeline and temporary camera, captions,
  Skip and restoration of hidden overhead vitals.
- `Game`: world/journey ownership, local danger checks, suspension and cleanup.
- `GameState`: origin defaults, transactions, eligibility and actual save migration.
- `DockConversation`: discovery-follow-up exchange and key-ready/open reminders.
- `Lobby`, `VillageMinimap`, `MissionDB` and existing guidance/guide owners:
  stage-dependent world construction and player directions.

`tools/portal_origin_checks.gd` is included in the canonical gameplay gate. The
focused route is `tools/test_isolated.ps1 -Godot <console-executable> -PortalOrigin`.
Add `-Capture -Resolution 1280x720` or `832x480` for native rendered evidence.
Native runs exercise actual screen taps and Skip; headless runs use the same
world touch handler without relying on a nonexistent physical window transform.
Both routes exercise nearby E, actual save files and the real Twilight transition.
Record verification results in `docs/ACCEPTANCE_TESTS.md`.
