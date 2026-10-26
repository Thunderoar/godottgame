# PB (Protect BESUT)

A playable 2D pixel-art survival action-RPG vertical slice for **Godot 4.7.2**.

**Created by Qayyim, Farhan and Ayiz.**

Three heroes share one seaside story: keep the cottage, feed and level a
companion, clean the coast, shape the settlement, protect the forest, duel rival
pets and defend the village while raiding ten monster portal levels for gold,
diamonds and boss trophies.

![Title screen](docs/screenshots/tide_title.png)
![Seaside settlement](docs/screenshots/tide_lobby.png)

## Monsoon Afterglow

The shipped village now has an original jade-and-mint tropical forest, seaglass
water, timber kampung-inspired homes, woven market stalls and clock-driven
golden-hour/lantern lighting. Low effects and Reduce Motion retain the complete
static artwork. [Art direction](docs/ART_DIRECTION.md),
[before/after evidence and verification](docs/MONSOON_AFTERGLOW_REPORT.md), and
[editable source artwork](assets/authored/monsoon/) document the overhaul.

## Run

1. Open `project.godot` in **Godot 4.7.2**.
2. Press **F5**. The main scene is `res://scenes/game.tscn`.
3. Click **Start Game**, select Adam, Arjun or Mei Ling in **Choose Your Road**,
   then click **Begin Journey**. **Continue Journey** resumes your saved hero
   directly. Starting over asks before replacing existing progress.

The original converted Cainos demo remains at `res://scenes/main.tscn`; its
notes are in [`docs/LEGACY_CONVERSION.md`](docs/LEGACY_CONVERSION.md).

## Controls

| Action | Keyboard | Touch |
| --- | --- | --- |
| Move | WASD / Arrow keys | Bottom-left joystick |
| Basic attack | F | Large **Attack** button |
| Interact / enter home / gather | E | Bottom-right **Use** |
| Backpack / potions | I | **Pack** beside joystick |
| Settlement editor | B | Menu → **Build settlement** / **Finish building** |
| Close modal | Esc | **Close** |

Pack sits beside the movement joystick; Build is inside Menu. Health potions are used from Pack. Tap the top-right minimap to open a larger picture map. Shop, portal, house, jetty and ship pictures replace letter markers and the explanatory legend; player and flashing attack indicators remain. Gold and diamond balances appear at the top left and update after earnings and purchases. The clock sits at the bottom. Dungeon loot is collected automatically by touch. Floating NPC name labels and timed pop-up notifications
have been removed; persistent HUD panels and the purple mission guide carry that information.

## New Journey tutorial

New games teach seven daytime lessons (movement, gathering, shopping, Pack, workers, housing and feeding a pet) and three nighttime lessons (fire monsters, portals and a boss). Lessons advance through their actions. Clearing Portal 1 (Tidebound Grotto) completes and hides the tutorial, even if the battle crosses into daytime. Portals 2-10 continue the rescue story; they are not tutorial requirements. Previously cleared Portal 1 saves need no repeat battle. At night the tutorial retains its pointer without adding a dim overlay. A time change switches to that phase’s unfinished lessons; returning to daylight resumes daytime progress. Skip hides the tips, and Menu can reopen them.

![Tutorial](docs/screenshots/tide_tutorial.png)

## Characters and combat

- **Adam** — Malay swordsman with swift sword strikes.
- **Arjun** — Indian scythe wielder with wide melee sweeps. Locked until the sea routes, Kraken King and prison rescue are completed.
- **Mei Ling** — Chinese female archer with precise ranged shots. Locked until Malakar is defeated in the final Drowned Throne portal.

New journeys begin as Adam. Rescue Arjun at sea and Mei Ling in the final portal; both return as village defenders and unlock the reunion ending. Each hero uses basic attacks only. Player skills and mana have been removed. The equipment shop filters to the active
hero's weapon discipline while sharing armour and shields.

## Settlement systems

### Day and night
A journey starts with a peaceful 180-second day, followed by a 180-second night. The HUD counts down each phase. Fire monsters and sea urchins spawn only at night. Survivors keep fighting after sunrise, including after returning home or loading a save.

### Lively residential village
The village contains five service shops, six garden beds, twelve residents,
an animal yard, two stable horses and seven neighbouring cottages. Shared
western household lanes, a market carpenter, fishing workspaces and paired
portal courts are authored in one spatial resource. Routines include fishing,
gardening, carpentry, wood hauling, animal keeping, farming, trading, stable work
and two village defenders. Four residents can join the defence.

### Custom settlement editing
Press **B** or Menu → **Build settlement** to open the settlement editor.
A marked building area appears. Drag the house, shop groups, fence runs, garden
beds and decorations with mouse or touch; positions are grid-snapped, clamped to
the area and saved. Choose Menu → **Finish building** to resume play.

![Settlement editor](docs/screenshots/tide_build.png)

### Village defence and protected forest
While the player is in a portal, raiders may attack from **both the sea and the
forest**. The persistent emergency HUD marks the danger. The player is never
teleported and portal combat is never forcibly interrupted. Returning through
the Shore Gate spawns sea urchins, residents seek intact houses for shelter,
and buildings and resident cottages take
visible damage. The **73 forest trees have persistent HP**: forest monsters
ignite mature trees with visible flames and ongoing fire damage. Damaged trees
show an HP bar and disappear at zero health. One blue-clothed water keeper starts in the village. They attack fire monsters with water and heal burning trees by 5 HP every 1.25 seconds. Green planters handle replanting. The Worker Shop hires extra specialists or replaces fallen workers. Fire monsters attack mature trees, nearby players and exposed residents.
Saplings grow for 30 seconds and cannot be attacked until mature. Losing all
mature trees with no planted saplings triggers a dry-orange terrain animation,
dark green sea and stranded dead sea life before the locked game-over screen.
Night replenishes the woodland to twenty-four fire monsters and the beach to six sea urchins. Raids can raise the fire population to thirty. Existing survivors remain active throughout the day.

Sea urchins attack players, mature trees, fences, houses and exposed residents.
Beached rubbish stays on the sand for manual collection. Houses and fence runs have persistent individual HP. During
danger, residents walk into an intact house and become protected; loss of all
shelters leaves them vulnerable to permanent death for that journey. One orange builder initially repairs damaged houses and fences in daylight. Each job takes ten seconds of work after arrival; nighttime pauses unfinished work. Extra builders can be hired from the Worker Shop. Damage, recruitment and resident deaths survive saves.

Every merchant stands inside a named shop. Click or touch the stall to open it directly; the keyboard interaction also remains available. New
players receive one of ten action-based missions at a time. Dotted arrows on
the ground follow paths around obstacles; the old bottom arrow notification bar
is removed. A tutorial spotlight dims the rest of the screen and points at the exact action to take. Mission progress resumes after Continue; tips can be reopened in Menu.

Fire monsters can attack the player and exposed residents as well as mature trees. Black swordsmen fight sea urchins. In a dungeon, regular monsters pursue the player immediately; approaching or damaging the boss calls all living monsters to defend it. Every defeated raider grants gold; clearing all raiders
restores the safe state.

![Protected forest](docs/screenshots/tide_forest.png)

### Sea cleaning
The Coastal Guard automatically nets drifting rubbish in the shallows. Every
catch awards exactly **+1 Gold** and increases the persistent sea-cleaning
counter. Rubbish that reaches the sand remains there until the player walks close
and presses **Pick Up**, awarding **+1 Gold** exactly once. Talk to the
guard to open a persistent sea-cleaning report instead of a timed notification.

### Turtle ocean journey
Walk to the jetty and use **Board Ship** beside the yellow **UNISZA** ship.
The ship sails automatically to the map
boundary, fades out and loads the underwater journey. The player dives, a turtle
arrives and the player mounts it automatically. Use **Pick Up (E)** for rubbish
and **Eat (F)** for food or pink hearts in the action ring. Start at **2.5x speed with 3 lives** and steer up/down using the joystick or W/S. Correct rubbish pays 1 Gold. Food does not heal; only eating a pink heart restores a life. Dodge moving bombs: collisions explode, cost a life and briefly make the turtle blink. At zero lives the turtle flips and sinks before retry appears. Three 45-second routes lead to Kraken Island, where defeating the sea king and opening the prison rescues Arjun. The player returns aboard the ship, docks beside the jetty and only then
steps onto the deck. Controls return after disembarking. Cleanup gold is saved;
the run itself is temporary.

Tall scenery fades while it hides the player. A full northern rock wall blocks
the map boundary. The two portals stand independently on the northern court. Inside the main house, walking onto the doorway exits
automatically once recovery permits it. Fire-monster tree impacts and burning
are silent. Fire-monster alerts, windups, melee impacts, defeat and rooftop-gun
shots at fire monsters are also silent. Physical impacts on unburned trees retain
their normal sound; burning trees stay silent throughout.

## Economy and shops

- Gold and diamonds with atomic, non-negative transactions.
- Potion shop, equipment shop, pet shop, inventory, equipment and selling.
- Purchase debounce, insufficient-funds rejection, data-driven prices.
- House upgrades accept **diamonds only** at Bram's dedicated **Construction
  Shop**, with a visible five-step Level 1-5 progression.
- Five main-house levels and indoor recovery at **10 / 8 / 6 / 4 / 2 seconds**.
- Coastal Guard rubbish catches award exactly **+1 Gold** without a pop-up.
- Beach rubbish pays **+1 Gold** on manual Pick Up.
- Driftwood gathering and selling provides a safe gold source.
- **Pet Food** costs 15 Gold at Nia's Pet Shop and grants 25 pet XP when fed.
- Persistent player and pet XP bars show the exact next-level requirement.
- Bram's Construction Shop presents the full Level 1-5 cottage path before each
  diamond upgrade.

![Nia's Pet Shop](docs/screenshots/tide_pet_shop.png)
![Construction Shop](docs/screenshots/tide_house.png)

## Companions and healing

The central home contains a chest, wardrobe, weapon rack and pet bed. New journeys grant one builder, water keeper, planter and swordsman; further workers are purchased from the Worker Shop. Existing Continue saves keep their workers; a higher house level raises the baseline.

- Starter **Ember** fox is granted automatically.
- Companions provide gradual healing, automatic attacks and periodic shields;
  levels strengthen all three abilities.
- Pets never die permanently, no Pet Revival Potion exists, and pets no longer
  provide portal lighting.
- At one health bar, a Health Potion is automatically used if available.
- Death returns the player to the cottage recovery ward. The player is held
  inside until fully healed; potions only accelerate recovery.

## Two battle portals

Two standalone gates sit at the far northern edge of the map:

- **Monster Battle Portal** — opens the ten-level campaign, each with at least
  ten regular monsters and one boss. Boss ability sets include punches,
  projectiles, charges, area slams and a combined projectile-charge pattern.
- **Pet Battle Portal** — opens a five-level 1v1 companion tournament. Both pets
  have **Serang**, **Perisai** and **Kuasa Khas**, with separate 2/5/8-second cooldowns for each pet. The player acts first, followed by one enemy reply, then the next player turn waits for input. Each arena uses one full background without combatant cards. A victory grants Gold,
  pet XP, unlocks the next duel and always raises the companion's level.

![Earlier portal presentation (cave removed in the current build)](docs/screenshots/tide_lobby_portal.png)
![Pet Battle Portal](docs/screenshots/tide_pet_battles.png)
![Pet duel](docs/screenshots/tide_pet_duel.png)

Monster portals use the reusable dark dungeon scene, with loot, expedition
banking, defeat/reset and safe Shore Gate returns.

## Visual & feel overhaul

The `visual-overhaul-merge-2` branch repairs and extends a presentation layer on top of the same
rules (see `docs/VISUAL_OVERHAUL.md` for the design decisions):

- **Shops with people.** Every shop opens onto an illustrated storefront band
  with an animated shopkeeper (Mara stirs, Garrick hammers, Nia tends, Bram
  unrolls blueprints), contextual dialogue lines, browsing silhouettes, stock
  cards with before/after stat compare and in-panel buy feedback (coin arc,
  currency tick, keeper reaction). Scrolling survives background gold drips.
- **Movement & combat feel.** The hero eases in and out of movement with a
  4-frame walk cycle, footstep dust and hurt/death poses. Attacks are
  data-driven anticipation -> active -> recovery chains (sword 3-hit combo,
  hammer shockwave slam, bow draw-and-release); damage lands on the active
  frame and cooldowns preserve the original pacing. Hits flash, spark, count
  and micro-shake; enemies telegraph every attack with a ground decal before
  it lands.
- **Portals as the centrepiece.** Both gates animate (8-frame swirls, motes,
  rune glow, approach wake) with ten distinct PortalDB-driven themes, sealed
  frames while locked, golden auras once cleared, and a pull-in transition on
  entry. Dungeon floors are coherent stone with real wall faces, themed
  dressing, flickering torches and a boss-arena emblem.
- **A clear seaside village.** Trees, cottages and ruins own their correctly
  placed visuals and collision bodies. Grass uses working MultiMesh fields;
  masked water follows the painted shore, including its rounded eastern end.
  A turtle rests on sand and a wooden BESUT sign marks the village path.
  Ambient star placeholders, water sparkles and broad light washes are removed.
- **Residents go shopping.** Customers reserve a counter, walk around obstacles,
  browse, exchange a coin for goods, leave and resume their routes. These ambient
  transactions never touch the player's economy.
- **Continuous movement.** Physics bodies move through floating-point positions;
  pets catch up smoothly and can route around obstacles. Physics interpolation
  and an unsnapped camera retain nearest-filtered art without grid movement.
- **Independent interface and world scale.** Menu → Settings has separate GUI
  and camera zoom sliders. Zoom spans 28–64 (38 default), with smooth changes
  and device-level persistence. The anchored HUD scales without moving controls
  off-screen; touch targets retain at least 44 physical pixels. The top-right
  VITALS panel is removed. Player HP/XP and level appear overhead; the pet has overhead HP/XP. Gold and diamonds appear at the top left, Menu and the minimap at the top right, and the phase clock at the bottom. Shops also show current balances.
- **Comfort settings.** Settings gains Effects quality (low/med/high) and
  Reduce motion. Touch buttons show keycap hints on keyboard layouts, a
  cooldown sweep on Attack and a context-sensitive
  Use icon.

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
  tide_test.tscn            end-to-end acceptance test (dynamic check count)
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
# Linux: isolated user://, timeout, failure/error-log checks.
./tools/test_isolated.sh

# Graphical review: always isolate user data; captures never go into res://shots.
review_dir=$(mktemp -d /tmp/tidesworn-review-XXXXXXXX)
XDG_DATA_HOME="$review_dir/userdata" TIDESWORN_TEST_ROOT="$review_dir" godot --path . res://tools/visual_review.tscn -- --shots "$review_dir/shots"
```

The raw acceptance scene deletes its save. Never run it against real user data.
The suite must report PASS, exit 0 and have no SCRIPT ERROR / ERROR output; the
count is data-driven. The Monsoon Afterglow delivery passes 562 acceptance
checks, 63 native graphical checks, plus 27 editor checks and a separate runtime
restart. The protected incoming main baseline passed 524 acceptance checks.
The earlier deep audit passed 408 acceptance checks and 63 native graphical
checks. See [the audit report](docs/DEEP_AUDIT_REPORT.md) for
actual results, root causes, files and visual evidence, and
[acceptance guidance](docs/ACCEPTANCE_TESTS.md) for the contracts.

## Android

Configured for 1280×720 landscape, canvas-items stretch, expand aspect, nearest
textures, physics interpolation and GL Compatibility. Touch controls are implemented.
Export/signing and physical-device performance testing remain machine-specific;
see [`docs/ANDROID_BUILD.md`](docs/ANDROID_BUILD.md).

## Known gaps

- Music and ambient audio are not implemented; gameplay cues use generated SFX.
- Android signing and device profiling still need to be run.
- Orange builders repair damaged houses and fences by day, taking ten seconds after arrival.
- Boss abilities are implemented as one primary pattern per boss rather than
  full multi-phase move sets.
- Pet duels are resolved in an animated arena panel rather than a separate
  walkable world scene.
- Additional resident dialogue and ambient animal species can follow.
# godottgame

## Creative Studio

Open the **Tidesworn** main workspace in Godot 4.7.2 for Asset Library, Map Studio,
Pixel & Animation and World Palette. The coastal revamp retains the real runtime
and player save format while adding authored asset/map resources.

See [delivery](docs/CREATIVE_REVAMP_COMPLETION.md),
[asset workflow](docs/ASSET_WORKFLOW.md), [map guide](docs/MAP_EDITOR_GUIDE.md),
[pixel guide](docs/PIXEL_EDITOR_GUIDE.md) and [QA evidence](docs/CREATIVE_REVAMP_QA.md).
Run `./tools/test_isolated.sh` for gameplay and `./tools/test_creative_editor.sh`
for the isolated editor/import/save/restart workflow.


### Coordinated village world

The village now uses a shared authored layout for its districts, functional
anchors, connected roads, building approaches and contextual workspaces. Map
Studio supports spatial overlays and undoable layout edits; player settlement
positions and all original forest associations retain precedence/identity.
See [world design and measured evidence](docs/WORLD_OVERHAUL_REPORT.md) and the
[layout/authoring guide](docs/WORLD_LAYOUT.md). Reproduce the actual-renderer tour
with `./tools/review_world.sh /absolute/output`; gameplay and authoring checks
remain `./tools/test_isolated.sh` and `./tools/test_creative_editor.sh`.

## Kampung world structure

The Besut-inspired composition, layout-owned routines, local workspaces, Map
Studio controls, paired runtime evidence and measured limits are documented in
[the kampung implementation report](docs/KAMPUNG_REDESIGN.md). The subsequent
[district spacing pass](docs/DISTRICT_SPACING_REPORT.md) groups five households
around a western lane, all five merchants in one market, and six crop beds beside
the southeast animal yard. Active building plots now keep at least 1.8 units of
clearance (ruin pairs use 1.0), with curated accessories instead of scattered flowers. The verified
combined gate passes 898 checks. The upgraded Map Studio passes 84 native editor
checks and two independent runtime restart checks. See the
[map editing guide](docs/MAP_STUDIO_GUIDE.md) for direct building/road/district
editing, district moves, workpoints, asset placement and soft terrain edges.

The Construction Shop upgrades the main house through five levels. Its level controls every village house, purchased rooftop machine gun and fence, and guarantees at least that many workers of each specialist role. Additional workers can still be purchased. Wooden fences gain a stone base at Level 2, become stone at Level 3 and gain fortified towers and battlements at Levels 4-5. Rooftop machine guns must be bought at the Equipment/Weapons Shop per intact house for Gold (180 + 60 per level above Level 1). They fire every 0.6 / 0.5 / 0.4 / 0.3 / 0.2 seconds and stop while their house is destroyed. All five supplied pet battle backgrounds are installed, including a PNG first frame of the supplied GIF. Each duel waits for one of three powers each round. Winning recruits that rival into your pet roster and the village guard; replaying never duplicates it.

## Loading and picture guide

New Journey, Continue, entering/leaving home, portal travel and returning to title use a loading cover with a fade. Opening shops, menus, the book and pet arenas uses a short entry fade. Inputs remain locked during world transitions.

Menu → **BESUT Field Guide** opens a picture guide for NPCs, monsters and all ten named bosses. Each page identifies the character by name and explains its actions using game sprites, arrows, health symbols, daylight/night symbols and timers rather than explanatory sentences. Page controls and Close work with touch. Build remains inside Menu.

The [GDT2 integration report](docs/GDT2_INTEGRATION.md) records the combined
gameplay import, preserved source snapshot, compatibility resolutions and current
evidence: 898 gameplay checks, 86 PB checks, 84 editor checks plus both restarts,
and native upgrade/home/guide, HUD/battle and five-background reviews.


## BESUT rescue story update

The new illustrated opening follows Adam, Arjun and Mei Ling from their fishing accident into another dimension. Sea routes lead to Arjun’s prison and the final Monster Portal leads to Mei Ling. Both become defenders after returning to BESUT. [Campaign rules and verification](docs/BESUT_STORY_CAMPAIGN.md) cover the saved ending, new turtle mechanics, tap-to-inspect NPCs, illustrated book, tutorial updates and drag-and-resize controls in Settings. Current isolated gameplay gate: **1,114 checks, PASS, exit 0**.
