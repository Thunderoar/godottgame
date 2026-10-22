# Save The World — Tidesworn

A playable 2D pixel-art survival action-RPG vertical slice for **Godot 4.7.2**.

**Created by Qayyim, Farhan and Ayiz.**

Three heroes share one seaside story: keep the cottage, feed and level a
companion, clean the coast, shape the settlement, protect the forest, duel rival
pets and defend the village while raiding ten monster portal levels for gold,
diamonds and boss trophies.

![Title screen](docs/screenshots/tide_title.png)
![Seaside settlement](docs/screenshots/tide_lobby.png)

## Run

1. Open `project.godot` in **Godot 4.7.2**.
2. Press **F5**. The main scene is `res://scenes/game.tscn`.
3. Choose Qayyim, Farhan or Ayiz from **Choose Your Road**.

The original converted Cainos demo remains at `res://scenes/main.tscn`; its
notes are in [`docs/LEGACY_CONVERSION.md`](docs/LEGACY_CONVERSION.md).

## Controls

| Action | Keyboard | Touch |
| --- | --- | --- |
| Move | WASD / Arrow keys | Bottom-left joystick |
| Attack | F | Bottom-right **Strike** |
| Interact / talk / enter / sleep / gather | E | Bottom-right **Use** |
| Backpack | I | **Pack** at top-left |
| Settlement editor | B | **Build** at top-left |
| Health potion | Q | **HP** |
| Mana potion | R | **MP** |
| Close modal | Esc | **Close** |

The backpack and Build buttons are deliberately away from the movement joystick
and combat buttons. There is no minimap and no collect button: loot is collected
automatically by touch. Floating NPC name labels and timed pop-up notifications
have been removed; persistent HUD panels and the journal carry that information.

## New Journey tutorial

Every new game starts an eight-step, non-blocking tutorial covering:
movement, combat, automatic item collection, shops, house upgrades, companions,
portals and village defence. **Next** advances; **Skip** dismisses it.

![Tutorial](docs/screenshots/tide_tutorial.png)

## Characters and combat

- **Qayyim** — sword; quick forward arc.
- **Farhan** — blacksmith's hammer; slower wide hits, higher damage and camera
  shake.
- **Ayiz** — bow; fires arrows at the nearest enemy in front of him.

Each starts with their own weapon. The equipment shop filters to the active
hero's weapon discipline while sharing armour and shields.

## Settlement systems

### Permanent daytime
The world is locked in permanent daytime. There is no day/night cycle or timer.

### Lively residential village
The fenced settlement contains three shops, Bram's cottage service, six garden
beds, dense flower borders, twelve residents, an animal corner, two horses and
four neighbouring resident cottages beyond the fence. Routines include fishing,
gardening, carpentry, wood hauling, animal keeping, farming, trading, stable work
and two village defenders. Four residents can join the defence.

### Custom settlement editing
Press **B** or the top-left **Build** button to open the settlement editor.
A marked building area appears. Drag the house, shop groups, fence runs, garden
beds and decorations with mouse or touch; positions are grid-snapped, clamped to
the area and saved. Press **Done** to resume play.

![Settlement editor](docs/screenshots/tide_build.png)

### Village defence and protected forest
While the player is in a portal, raiders may attack from **both the sea and the
forest**. The persistent emergency HUD marks the danger. The player is never
teleported and portal combat is never forcibly interrupted. Returning through
the Shore Gate spawns the raiders, residents flee or fight according to their
role, defenders automatically attack, and buildings and resident cottages take
visible damage. The **73 forest trees are invulnerable**: forest monsters strike
them constantly with leaf/shake VFX and synthesized impact SFX, but the trees
never lose structural health or fall. Eight forest monsters patrol the woodland
outside raids, with three more joining during an emergency.

Forest monsters attack trees without waiting for the player. As soon as the
player enters a monster's line of sight, it immediately targets the player,
charges and attacks. Every defeated raider grants gold; clearing all raiders
restores the safe state.

![Protected forest](docs/screenshots/tide_forest.png)

### Sea cleaning
The Coastal Guard automatically nets drifting rubbish in the shallows. Every
catch awards exactly **+1 Gold** and increases the persistent sea-cleaning
counter. Dangerous rubbish that slips past the net transforms into a monster on
the sand, which the player can defeat for a separate gold reward. Talk to the
guard to open a persistent sea-cleaning report instead of a timed notification.

## Economy and shops

- Gold and diamonds with atomic, non-negative transactions.
- Potion shop, equipment shop, pet shop, inventory, equipment and selling.
- Purchase debounce, insufficient-funds rejection, data-driven prices.
- House upgrades accept **diamonds only** at Bram's dedicated **Construction
  Shop**, with a visible five-step Level 1-5 progression.
- Five cottage levels and sleep recovery at **10 / 8 / 6 / 4 / 2 seconds**.
- Coastal Guard rubbish catches award exactly **+1 Gold** without a pop-up.
- Beached rubbish transforms into a gold-rewarding monster instead.
- Driftwood gathering and selling provides a safe gold source.
- **Pet Food** costs 15 Gold at Nia's Pet Shop and grants 25 pet XP when fed.
- Persistent player and pet XP bars show the exact next-level requirement.
- Bram's Construction Shop presents the full Level 1-5 cottage path before each
  diamond upgrade.

![Nia's Pet Shop](docs/screenshots/tide_pet_shop.png)
![Construction Shop](docs/screenshots/tide_house.png)

## Companions and healing

- Starter **Ember** fox is granted automatically.
- Companions provide gradual healing, automatic attacks and periodic shields;
  levels strengthen all three abilities.
- Pets never die permanently, no Pet Revival Potion exists, and pets no longer
  provide portal lighting.
- At one health bar, a Health Potion is automatically used if available.
- Death returns the player to the cottage recovery ward. The player is held
  inside until fully healed; potions only accelerate recovery.

## Two battle portals

Two gates stand side by side on the north path:

- **Monster Battle Portal** — opens the ten-level campaign, each with at least
  ten regular monsters and one boss. Boss ability sets include punches,
  projectiles, charges, area slams and a combined projectile-charge pattern.
- **Pet Battle Portal** — opens a five-level 1v1 companion tournament. Both pets
  choose from **Attack, Guard and Recover** during a two-second window; when the
  timer ends, both chosen skills execute simultaneously. A victory grants Gold,
  pet XP, unlocks the next duel and always raises the companion's level.

![Paired battle portals](docs/screenshots/tide_lobby_portal.png)
![Pet Battle Portal](docs/screenshots/tide_pet_battles.png)
![Pet duel](docs/screenshots/tide_pet_duel.png)

Monster portals use the reusable dark dungeon scene, with loot, expedition
banking, defeat/reset and safe Shore Gate returns.

## Project structure

```text
scenes/
  game.tscn                 main flow scene
  main.tscn                 preserved converted demo
scripts/
  autoload/game_state.gd    state, economy, saves, emergencies, recovery
  autoload/sfx.gd           synthesized impact/aggro/skill/victory SFX
  core/                     procedural art, theme, camera
  data/                     characters, items, pets, portals, pet duels, houses
  player/                   player controller, sprite, arrows
  pets/                     follower and support abilities
  combat/                   monsters, bosses, projectiles
  world/                    lobby, dungeon, residents, rubbish, editor, defence
  ui/                       HUD, joystick, touch buttons, tutorial, modals
tools/
  tide_test.tscn            end-to-end acceptance test (250 checks)
  tide_capture.tscn         screenshot harness
docs/
  ACCEPTANCE_TESTS.md
  COMPLETION_REPORT.md
  QA_REPORT.md
  ARCHITECTURE.md
  ANDROID_BUILD.md
  LEGACY_CONVERSION.md
```

## Verify

```sh
godot --headless --path . res://tools/tide_test.tscn
godot --path . res://tools/tide_capture.tscn
```

Latest result: **250 checks, PASS**. The suite covers title/credits, tutorial,
three weapons, permanent daytime, no NPC labels or pop-ups, XP bars, Pet Food,
three-skill simultaneous pet turns, guaranteed victory level-up, paired battle
portals, invulnerable forest trees, forest-monster line-of-sight charges, SFX/VFX,
the dedicated Construction Shop, resident cottages, horses,
flowers/gardens/decorations, sea-cleaning progress, auto-heal, pet support,
auto-loot, emergency persistence, sea/forest attacks, defender participation,
death/recovery, ten monster portals, boss abilities, save/load and settlement
editing persistence. Agent-facing acceptance guidance is in
[`docs/ACCEPTANCE_TESTS.md`](docs/ACCEPTANCE_TESTS.md).

## Android

Configured for 1280×720 landscape, canvas-items stretch, expand aspect, nearest
textures, pixel snapping and GL Compatibility. Touch controls are implemented.
Export/signing and physical-device performance testing remain machine-specific;
see [`docs/ANDROID_BUILD.md`](docs/ANDROID_BUILD.md).

## Known gaps

- Music and ambient audio are not implemented; gameplay cues use generated SFX.
- Android signing and device profiling still need to be run.
- Building damage is visible after an emergency but has no repair interaction yet.
- Boss abilities are implemented as one primary pattern per boss rather than
  full multi-phase move sets.
- Pet duels are resolved in an animated arena panel rather than a separate
  walkable world scene.
- Additional resident dialogue and ambient animal species can follow.
# godottgame
