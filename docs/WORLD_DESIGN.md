# Besut village spatial blueprint

Source baseline: remote `main` verified at f37c843ef7388fc7ba0f89df9cc1aaf23a68beaf,
24 October 2026. This document records the design before implementation.

## Ownership audit

| Responsibility | Before | Intended owner |
|---|---|---|
| Land, shore, sea mask, sea collision | WorldTerrain + Lobby wrappers | Shared WorldTerrain shore sampler; same geometry contract |
| Service/building coordinates | Lobby builders, base proxy map, protected-point list | WorldLayout resource referenced by AuthoredMap |
| Painted roads | Six independent WorldTerrain polylines | WorldLayout route graph, endpoints at actual approaches |
| Building physics, interactions, recovery | Lobby children, GameState transactions | Existing builders; move complete owner nodes |
| Persistent forest | Lobby's seeded construction sequence | Unchanged sequence, IDs, positions, health, art overrides |
| Player customization | GameState settlement_layout | Highest priority, runtime-resolved layout copy |
| Authored paint/props | AuthoredMapRenderer | Existing renderer, shared layout clearance validation |
| NPC planning | ResidentRoutes, actual World2D collision | Existing continuous movement and shape queries |
| Editor | Hybrid Map Studio and base proxies | Same studio, shared terrain, spatial overlays and undoable layout edits |

The baseline's northern path misses both portals and meets the north fence at a
closed section. Construction has a narrow isolated road. Water service and several
homes have no road. A diagonal beach path ends beyond the jetty. Grass and flower
scatter competes with entrances; critical coordinates are repeated in validation.
The cottage, garden beds, shops, BESUT sign and residence lanes lack shared ground.

## Composition and connectivity

Home arrival is the emotional centre. A broad, quiet forecourt opens west into a
market crescent, east to the kitchen gardens, and south into a village promenade.
A northern lane goes around the west side of the cottage, through a real fence
gap into a paired portal court. The construction workshop connects through an
eastern lane and forest defence gate. This makes a legible northern loop.

The southern loop connects the market to the west gate, fisher court and jetty
landing, then along the beach to cleaning/driftwood destinations, through the
south gate to BESUT and the water service. Southern cottages and the horse yard
join the garden promenade. West cottages have their own lane into the market;
north and eastern cottages join the portal and woodland routes respectively.

Forest paths use existing clearings and avoid existing trunks. Meadow, woodland
edge and interior have irregular authored polygons; ground masses and understory
change across them. The protected trees remain the same gameplay objects.
The shore retains its shared sampler, sea shelves and turtle grounding. Jetty
access is explicitly the landward landing; deck planks never imply permission
to walk into sea collision. Nets, stores and fishing activity frame that landing.

Primary lanes target 2–2.4 units, secondary 1.5–1.8, woodland tracks 1.1–1.4.
Final centreline and approach checks use actual physics with player-sized
clearance. Wide gathering courts occur at home, market and the portals. Scenery
is rejected from entrances, routes, building plots and authored water/collision.
No cosmetic object adds a hidden collision.

## Compatibility and implementation boundaries

AuthoredMap keeps old layers/objects and gains an optional versioned WorldLayout.
Maps without it inherit the shipped village layout. No save schema is changed.
Player position overrides win over developer base overrides and layout anchors.
House/stall art, colliders, targets, merchants and local props share a movable
parent. Runtime layout resolution and route rebuilding follow those parents.

Forest generation retains its historical exclusion positions and RNG ordering,
even when developer or player structures move. Those legacy coordinates are a
compatibility constraint, not the new placement authority. Optional decoration
uses independent RNG and reservations. Combat, progression, clock and input
remain owned by their existing systems.

Implementation and measured results will be documented in WORLD_LAYOUT.md and
WORLD_OVERHAUL_REPORT.md, with actual before/after renderer evidence.
