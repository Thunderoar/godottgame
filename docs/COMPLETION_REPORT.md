# Save The World - Completion Report

## Task
Apply the title, tutorial, settlement, permanent-daytime, village, defence and
ten-portal campaign requirements, then add the latest presentation and content
update:

- remove NPC name labels and timed pop-up notifications
- pair a Monster Battle Portal with a Pet Battle Portal
- add five-level 1v1 pet duels
- add player and pet XP bars
- sell Pet Food in the Pet Shop for Gold
- expand and protect the forest
- expand the sea-cleaning loop
- add resident cottages, flowers, gardens, decorations and horses
- retain the five-level house, Android touch controls and Godot 4 architecture
- provide acceptance tests for AI agents

The latest behavioural pass adds:

- invulnerable forest trees with constant monster attacks and VFX/SFX
- more forest monsters and line-of-sight aggro → charge → attack
- three-skill, two-second simultaneous turns for both pets
- guaranteed companion level-up on every pet-duel victory
- a dedicated Construction Shop for Levels 1-5

## Result
All requested systems are integrated. The automated suite reports
**250 checks, PASS** on Windows with Godot 4.7.2.

## Delivered changes

### 1. Cleaner presentation
- Removed floating name labels from residents, shop merchants and the Coastal
  Guard.
- Removed the HUD toast container and disabled toast creation.
- Persistent HUD panels and the journal now carry important state.
- Removed the exact catch notification text; the Gold reward and persistent
  sea-cleaning counter remain.

### 2. Two side-by-side battle portals
- Replaced the two distant campaign gates with a paired gate location on the
  north path.
- **Monster Battle Portal** opens the existing ten-level campaign.
- **Pet Battle Portal** opens a new five-level companion tournament.
- Both use distinct purple/teal portal art and remain visible together.

### 3. 1v1 pet tournament with simultaneous turns
- New `PetBattleDB` with five duel levels: Clover Ring, Bramble Court, Moonlit
  Ring, Storm Terrace and Tideworn Crown.
- Both pets choose from **Attack**, **Guard** and **Recover**.
- The player has a **two-second** choice window; enemy AI chooses from the same
  three skills.
- When the timer expires, both actions execute simultaneously. Guard reduces
  incoming damage by 65%; Recover restores 16% max HP.
- Both health bars, victory/defeat/forfeit states and next-level unlocks work.
- First clears grant Gold and pet XP; repeats grant reduced pet XP only.
- Every victory now guarantees at least one companion level-up.
- Duel clears persist in save data.

### 4. Player and pet XP
- Persistent player XP bar shows current XP and the next-level requirement.
- Persistent pet XP bar shows current pet XP and the next-level requirement.
- Pet Food (`pet_food`) is explicitly sold in Nia's Pet Shop for 15 Gold.
- Feeding consumes one Pet Food and grants 25 pet XP; multi-level gains work.
- Pet Shop owned-companion rows include a **Feed** button.
- Pet XP and player XP update after battles, feeding and monster kills.

### 5. Expanded, invulnerable protected forest
- Added a dense eastern woodland built from 73 `ForestTree` nodes.
- Trees are settlement targets but do not lose structural health, cannot be
  felled and do not damage the settlement when struck.
- Tree hits still shake the canopy, burst leaves/sparks and play synthesized
  impact SFX, so attacks read clearly without damaging the tree.
- Eight forest monsters patrol the woodland; three more join during an
  emergency and attack trees at a faster cadence.
- Forest monsters do not need player proximity to attack trees. On line-of-sight
  detection they immediately switch target, charge and attack the player.
- The journal explicitly asks the player to defend the forest trees.

### 6. Livelier village
- Added four resident cottages beyond the fence.
- Added two horses with dedicated pixel art.
- Added three extra editable gardens for six total.
- Added 50+ flower nodes around homes, gardens and gates.
- Added crates/barrels and other editable decorations for 12 total.
- Added three residents (Amir, Laila, Zara) for twelve total.

### 7. Sea cleaning
- Coastal Guard catch now calls `GameState.register_rubbish_cleaned(1)`.
- Each catch grants exactly +1 Gold and increments a persistent counter.
- Dangerous beached rubbish still becomes a fightable monster with separate Gold.
- No notification UI is created; the guard opens a persistent sea-cleaning report
  modal with totals and rules.

### 8. Dedicated Construction Shop
- Added a fourth shop stall with Bram as the construction keeper.
- The stall uses blueprint/timber/tool goods and is a moveable settlement shop.
- The upgrade panel is now branded **Bram's Construction Shop** and shows a
  five-step Level 1-5 progression row before every diamond upgrade.
- All five house levels, costs and recovery improvements remain intact.

### 9. Retained systems
- New title layout, credits and responsive Choose Your Road menu.
- Eight-step New Journey tutorial.
- Three heroes with sword/hammer/bow.
- Permanent daytime.
- Ten monster portal levels, boss abilities and boss art.
- Android touch joystick/buttons and top-left Pack/Build.
- Settlement editing with drag, snap, bounds and persistence.
- Village defenders and sea/forest raids.
- Death/recovery, auto-heal, pet support, auto-loot and Shore Gate banking.

### 10. Agent acceptance tests and generated SFX
- `tools/tide_test.gd` expanded from 195 to **250 checks**.
- Added `Sfx` procedural audio for tree hits, aggro calls, charges, attacks,
  guards, recovery, selection and victory.
- Added `docs/ACCEPTANCE_TESTS.md` with commands, acceptance rules, regression
  rules and a visual review checklist.
- Capture harness records paired portals, combat-turn pet duel, Construction
  Shop, pet shop and the protected forest.

## Verification
```sh
godot --headless --path . res://tools/tide_test.tscn
```

Latest result: **250 checks, PASS**.

## Remaining work
- Android export, signing and device profiling.
- Music and ambient audio beyond the synthesized gameplay SFX.
- Repair interactions after raids.
- Optional multi-phase boss move sets and bespoke maps for each portal.
- Optional walkable pet-arena scenes instead of the arena panel.
- More resident dialogue and ambient animal species.
