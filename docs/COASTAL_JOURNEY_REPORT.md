# Coastal journey and village visibility

Implemented 2026-10-25 with Godot 4.7.2 stable official (ed1daf0bf), Windows.

## Delivered behavior

1. Fire-monster tree impacts and burning are silent. No local fire audio player is created. Physical impacts on unburned trees retain their separate tree-hit sound.
2. Fire monsters and sea urchins can attack nearby living players and exposed residents. Shelter and dead-target exclusions remain. Fire still ignites mature trees; urchin tree damage stays physical. Night spawning and surviving daytime monsters are unchanged. Actor resolution uses the active Game player rather than a retiring world's group member.
3. Tall scenery becomes 25% opaque while its opaque pixels cover the player, then restores. This uses self_modulate alpha so damage tints, warm windows, selection and physics retain their owners. Existing forest positions, RNG order, IDs and health data are preserved.
4. A northern stone wall spans the 64-unit map width. The cave art and its collider have been removed. Both portals stand independently at their existing northern anchors, with full-size frames and clear approaches.
5. The indoor doorway automatically returns the player outdoors on foot, respecting recovery, modal input locks and transition guards.
6. Sea rubbish that escapes the guard remains on sand. A nearby active player uses Pick Up to collect it for exactly one Gold and a net sweep. A resolved piece cannot pay twice; guard catches and manual pickups remain mutually exclusive. Floating and beached populations are bounded.
7. The yellow UNISZA ship sits immediately beside the walkable jetty, where Board Ship is reachable. Boarding releases held actions and locks walking, pauses the optional boat bob, puts the player on deck and sails automatically west. Contact between the ship's leading art edge and the map boundary starts the covered loading/fade transition.
8. OceanJourney automatically dives the player, swims the turtle into view and places the player on its shell. The turtle swims while food and rubbish drift toward an action ring. Pick Up/E collects rubbish for one Gold; Eat/F opens the mouth and consumes food, restoring one turtle health. A wrong action or missed rubbish costs one of five health; empty inputs do not. Speed increases with elapsed time up to a fixed cap. Zero health offers Ride Again and Return to Shore.

## Ownership and persistence

No autoload or scene switching was added. Game builds the ocean under WorldHolder and returns through the existing lobby builder, bringing the player back aboard an incoming ship. ShipDeparture carries the player until the mooring is reached, then walks the passenger onto the resolved jetty deck before restoring collision, controls and HUD. Ocean owns its camera, temporary turtle health/items/score and anchored two-action HUD. The main combat HUD stays hidden during sailing and the ocean journey. World timers reset on clearing; touch actions release during exits.

Cleanup transactions use the existing GameState register_rubbish_cleaned method, so Gold and sea_cleaned persist. No new saved fields are required. The temporary turtle run does not resume after restarting the application; Continue resumes the village and retains earned Gold. Existing player progression and settlement placement remain authoritative.

CoastalArt creates original reproducible cliff, turtle mouth/stroke and food pixels through stable PixelArt cache keys. Existing art and the terrain bake are retained. Field-guide equations and the Coastal Guard report now describe player attacks and manual beach pickup.

## Verification

The gate invokes tools/coastal_checks.gd; tools/coastal_test.tscn runs the feature path separately. It verifies real damage, shelter exclusions, silent fire impacts and retained physical audio, fading/restoration, northern boundary collision, absent cave collision, standalone portal frames, pickup distance/deduplication, automatic exit, ship guards/boundary/fade, camera takeover, dive/rescue/mounting, correct/wrong/missed actions, acceleration, retry, incoming ship/passenger ownership, dock-before-disembark ordering, harbour return, released input and saved earnings.

Native checks inject real screen-touch events on Pick Up and Eat, scaling injected coordinates through the viewport transform. Native captures cover transparency, standalone portal and wall placement, manual shore collection, sailing, diving, turtle riding, net/mouth animations and results. Both 1280x720 and 832x480 are exercised with temporary user data. Before cave removal, the isolated gate passed 1048 checks and native focused runs at 1280x720 and 832x480 each passed 59 checks. After cave removal, the isolated gate passes 1049 checks, PASS, exit 0; the native 1280x720 review passes 60 checks, exit 0. Final stdout/stderr have no FAIL, SCRIPT ERROR, ERROR or WARNING entries. Tallies are also recorded in docs/ACCEPTANCE_TESTS.md.

## Limits

No APK/EXE export or Android-device playtest was requested or performed. The native verification uses the Dummy audio driver; tests verify that fire-tree hits create neither impact playback nor a local fire audio player, while physical impacts on unburned trees still request their sound. Scenery fading currently indexes the constructed world's sprites; source/editor changes rebuild that world. Beach objects and the turtle run are temporary; cleanup earnings persist.

## Silent fire / UNISZA follow-up (2026-10-25)

Fire impacts and burning no longer create sound; ordinary physical tree-hit audio on unburned trees remains. The ship is yellow with navy UNISZA pixel lettering and sits beside the jetty using harbour-relative placement. Return to Shore now sails the player back aboard, docks, then disembarks onto jetty_deck before unlocking movement. The coastline, visible deck collision and terrain bake are unchanged.

The final serial isolated gameplay gate passes **1055 checks, PASS, exit 0**. Native 1280×720 and 832×480 each pass **66 checks, PASS, exit 0**, including occupied-ship visibility. The latest 1280×720 captures verify the deck-placement correction during departure and return. Both cover real screen touches and return/dock/disembark ordering. An initial concurrent gate exceeded the existing six-second home-recovery test wait; the serial rerun passed without changing that gameplay or assertion. The native gesture fixture now separates synthetic presses across frames on slow renderers. Final stdout/stderr are clean.

Passenger visibility: while aboard, ShipDeparture marks the ship as occupied so WorldOcclusion keeps its yellow hull and UNISZA lettering opaque. Ordinary scenery fading resumes when the passenger reaches the jetty.

Deck placement correction: the passenger now stands inside the deck beside the mast, with the near hull drawn over the legs during departure and return. The foreground hull is removed only after the player steps onto the jetty.

Deck-placement verification: native 1280×720 **66 checks, PASS**, reviewed departure/return/jetty screenshots; isolated gameplay gate **1055 checks, PASS, exit 0**, with clean stdout/stderr.

## Complete fire-combat silence (2026-10-25)

Enemy.combat_sounds_enabled rejects fire-monster SFX across alert, repeated windup, specials and defeat. Player melee and roof guns share that policy for impacts/shots against fire monsters. ForestTree also suppresses physical impact audio while burning. Damage, target selection, cooldowns, VFX and all unrelated UI/music remain under their existing owners.

Complete fire-silence verification: official isolated gameplay gate **1073 checks, PASS, exit 0** and focused coastal scene **76 checks, PASS, exit 0**. Tests check actual playback-request counts while damage still lands, including gun fire against fire monsters and sea urchins. Final logs contain no FAIL, SCRIPT ERROR, ERROR or WARNING entries.
