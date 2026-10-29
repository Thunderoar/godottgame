# Twilight Wilds — first explorable dimension

Implemented 2026-10-29. The first dimension replaces the two village battle entrances with one **Dimension Portal**, entering the world directly. The old `monster_portal` anchor remains authoritative for placement; the retired `pet_portal` anchor stays in layout data to preserve old layouts and original forest identity, but produces no entrance or map icon.

## The journey

Follow the stone road from Arrival Glade across Rootbound Crossing toward Broken Watchpost and the Ashen Approach. Bramble Grove branches west; Moonpool Hollow loops east. At the watchpost, the rootway winch opens a permanent shortcut through the escarpment. The citadel lantern provides a two-second rest and a saved return checkpoint.

Six local Darkfire Imp encounters activate near their home areas and disengage when the player retreats. Arrival, pet habitats and the lantern are safe from those pursuing packs. Shadow & Chaos Fiend waits beyond the citadel's inner threshold. Dormant enemies cannot be damaged by weapons or companion attacks. Retreating to the lantern resets the unfinished boss, its spells and attack sequence.

The realm uses its own twilight grade while the shared day/night clock continues. Twilight exploration does not start the legacy dungeon emergency. Saved village attackers remain saved; returning at night still follows the village's ordinary wave and defense rules.

## Wild companions

Approach and tap a wild pet, or use E, to challenge it in its habitat. Starter Ember can challenge either animal without clearing old tournament duels or buying levels. Adam watches while his companion faces the rival in the clearing; Attack, Shield and Special are manual choices. The rival replies after the player's action. There is no forced player timeout.

- **Bramble Cat:** 30 arena HP, 4 base damage; favors aggressive powers. As a companion it attacks more strongly and more often than the moth.
- **Dusk Moth:** 42 arena HP, 5 base damage; favors maintaining its shield. As a companion it provides stronger, more frequent shielding than the cat.

The world and its combat timers suspend during an accepted challenge, including existing projectiles, hazards and automatic companion support. Settings suspends the duel timer as well. Closing, winning, losing and replacing the world restore camera, actors, controls and music ownership. Screen buttons and number keys 1/2/3 choose powers.

A first win immediately commits the bond and companion/village-guardian ownership. The cat pays 25 Gold and 50 participant XP; the moth pays 35 Gold and 65 participant XP. Already-owned pets and friendly repeat spars pay no rewards or guaranteed levels. Rewards belong to the companion that entered the challenge. Losing or leaving changes no saved arena HP and grants no rewards. Normal first-win XP can still heal a companion through level-up. Later expedition defeat cannot erase a bonded pet.

## Saves and outcomes

`GameState.realm_progress` owns discovered 12-unit map cells, landmarks, shortcut status, a stable checkpoint ID, bonded encounter IDs and saved realm presence. Unknown destinations sanitize to Arrival Glade. Old saves with an active first-portal expedition migrate to the new realm safely. Existing owned pets and cleared duel recruits remain owned.

Continue resumes an active realm visit at its last safe checkpoint; unfinished enemies and bosses reset. Defeat retains the existing home recovery flow, discards ordinary unbanked expedition loot, and preserves the realm checkpoint/discoveries/bonds. Returning through a rift banks expedition loot and ends the visit.

Boss victory commits the existing first-portal rewards, banks expedition loot and opens its existing successor. It restores the terrain/light, removes hostile packs/spells, and leaves the player free to explore. Saved realm presence remains valid after expedition banking; Continue reconstructs the peaceful cleared world. A return rift appears in the chamber. Cleared first realms remain peaceful on revisits rather than automatically repeating the boss.

The expanded map reveals terrain and pet locations as cells are explored. The boss marker appears only after discovering the citadel. No ground route points directly to an undiscovered boss.

## Campaign compatibility and scope

The stable first-stage ID is still `tidebound_grotto`; its ruler remains Shadow & Chaos Fiend and its first-clear Luma reward remains distinct from Dusk Moth. The later nine stages are physical onward passages east of the citadel, with their actual unlock/level requirements. They retain their existing arena combat and rescue progression. They have not been rebuilt as exploration dimensions.

This is the complete first exploration slice. The proposed three-dimension campaign compression remains a future migration: no seven legacy stages, earned rewards, pets or rescue flags were deleted. Arjun's ocean/Kraken rescue and the Abyss Monarch/Mei Ling rescue remain separate. A 10–15-minute visit is not claimed without player pacing measurements.

## Ownership and verification

- `RealmDB`: authored paths, landmarks, habitat definitions and checkpoint positions.
- `TwilightLandscape`: deterministic terrain/decor; independent from village RNG.
- `TwilightRealm`: world construction, local encounters, threshold/reset, shortcut and victory.
- `RealmInteractable`: nearby direct tap/E routes with current-world guards.
- `PetDuel`: presentation-free manual rules; `WildPetChallenge`: protected world staging and screen controls.
- `GameState`: all durable progression and one-time token-guarded reward transactions.

`tools/twilight_checks.gd` runs both inside the canonical isolated gameplay suite and via `tools/twilight_test.tscn`. The focused scene accepts `-- --capture` under an isolated actual renderer and writes screenshots to `TIDESWORN_TEST_ROOT`. Tests must use the same environment isolation as the canonical wrapper. See the newest Twilight section in `ACCEPTANCE_TESTS.md` for recorded evidence; older reports are historical.

Windows review: use the canonical isolated wrapper with -Twilight, optionally -Capture -Resolution 832x480 or 1280x720. It prints the external evidence directory and rejects incomplete/error-bearing runs.
