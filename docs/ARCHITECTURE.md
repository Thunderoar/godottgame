# Tidesworn Architecture

## Runtime flow

```text
Game (game.tscn)
├── WorldHolder
│   ├── Lobby (seaside hub, residents, rubbish watch, recovery, emergencies)
│   └── Dungeon (reusable portal instance)
├── GameHUD (CanvasLayer)
│   ├── permanent HUD / mission arrows / player dashboard / touch controls
│   ├── MenuPanel / SettingsPanel / DialoguePanel / GameOverPanel
│   ├── ShopPanel / InventoryPanel / PortalPanel / PetBattlePanel / SeaCleaningPanel
│   ├── HousePanel / VictoryPanel / DefeatPanel
│   └── fade overlay (no toast layer)
└── TitleLayer
    └── PB main menu → Start Game → Choose Your Road → Begin Journey
        (Continue Journey resumes the saved world directly)
```

`Game` owns world lifetimes, modal input locking, portal timer, emergency
trigger/damage simulation and transitions. It does not duplicate stats.

`Sfx` is a lightweight autoload that synthesizes and caches short PCM tones for
tree impacts, aggro calls, charges, skill use, selection and victory. No external
audio assets are required.

`GameSettings` (added by the visual overhaul) is the third autoload. It owns
device-level preferences in `user://settings.cfg`, independent of the save
file: volumes, mute, fullscreen, UI scale, touch layout mode, screen shake,
`camera_zoom` (28–64, default 38), `reduce_motion` and `effects_quality` (low/med/high). The Settings panel reads
and writes it; visual systems call `GameSettings.effects_at_least()` /
`reduce_motion()` before spawning ambient layers.

## Authoritative data

`GameState` owns:

- selected hero, level and XP,
- current/max health, mana and shield,
- gold and diamonds,
- inventory and equipped slots,
- owned/active pets, levels/XP/health and support state,
- house level,
- permanent monster-portal unlock/clear state,
- five-level pet-duel clear state,
- unbanked expedition contents,
- recovery state,
- emergency state (active, remaining monsters, building damage),
- settlement layout (saved editable-object positions),
- persistent per-tree forest health and remaining sapling growth time,
- sea-cleaning count,
- custom touch-control layout (GUI scale delegates to GameSettings),
- in-game play time and counters.

Game advances the saved `world_time` only while a world exists. GameState alternates 180-second day/night phases and emits `day_phase_changed` at boundaries; title screens do not advance it.

Signals:

```gdscript
data_changed
pet_changed
house_changed(level)
portal_completed(portal_id)
player_defeated
expedition_changed
boss_health_changed(active, name, value, maximum)
recovery_changed(active, progress)
emergency_changed(active, remaining, damage)
game_over_triggered(reason)
toast_requested(text, tone)  # internal only; no toast UI exists
```

The HUD reads these signals/values; it does not keep duplicate health,
currency, inventory, pet or portal progression state. Pop-up notifications and
floating NPC names were deliberately removed in favour of persistent HUD panels,
the purple mission guide and modal screens.

## Data catalogues

| File | Contents |
| --- | --- |
| `scripts/data/character_db.gd` | Qayyim/Farhan/Ayiz stats, starter weapon, cooldown/range/style |
| `scripts/data/item_db.gd` | items, prices, stacks, effects, weapon style, shop stock |
| `scripts/data/pet_db.gd` | healing/attack/shield values and level curves |
| `scripts/data/pet_battle_db.gd` | five 1v1 duels, opponents, stats, pet-level gates and rewards |
| `scripts/data/portal_db.gd` | ten monster portal levels, boss stats/abilities, rewards and unlock chain |
| `scripts/data/house_db.gd` | five levels, diamond costs, sleep recovery |

## Combat styles

- `Player.try_attack()` reads `CharacterDB` and branches:
  - `sword` — short forward cone,
  - `hammer` — wider, slower, higher multiplier, camera shake,
  - `bow` — spawns `Arrow` toward the nearest target in a forward cone.
- `GameState.equip_item()` rejects a weapon from another hero's discipline.
- Equipment shops filter to the active hero's weapon line plus shared armour and
  shields.
- `Enemy` handles regular and boss AI; `settlement_mode` makes emergency raiders
  choose the player within 6 units or the nearest node in the
  `settlement_target` group (buildings, resident cottages, residents and 73
  protected forest trees).
- Bosses read `boss_ability` from their portal record and can punch, slam an
  area, charge, fire `BossProjectile` orbs, or alternate projectile-charge.

## Economy

`GameState` owns all transactions:

- `buy_item()` validates stock, price, style, balance and stack, then debits once.
- `sell_item()` validates saleability and quantity.
- `consume_item()` validates full health/mana and available items.
- `equip_item()` validates ownership, slot and weapon discipline.
- `upgrade_house()` accepts diamonds only. Bram's dedicated Construction Shop
  (`shop_house`) is a normal settlement placeable and opens the five-level panel.
- `upgrade_pet()`/`purchase_pet()` validate level, gold and ownership.
- `feed_pet()` consumes one Pet Food and grants 25 pet XP.
- `start_expedition()` validates unlock, level, emergency and recovery gates.
- `complete_portal()` banks loot, grants first/repeat rewards and unlock.
- `complete_pet_battle()` grants first-clear Gold/pet XP and unlocks the next duel.
- `register_rubbish_cleaned()` adds exactly +1 Gold and increments sea-cleaning.
- `defeat_in_portal()` discards unbanked loot, activates recovery and restores
  the pet; it never permanently kills the pet.
- `defeat_at_home()` starts the same critical-health recovery without losing
  inventory, currencies or progression. `Game` rebuilds the home after the death
  animation and guards duplicate signals; forest game over still takes priority.

Currency is deducted only after validation and never becomes negative.

## Auto-heal and recovery

- `GameState.damage_player()` applies shield first, then health.
- If health is at/below one of ten segments and a Health Potion exists, an armed
  auto-heal consumes exactly one potion and rearms only after health climbs above
  35%.
- `Lobby` clamps the player inside `RECOVERY_CENTER/RADIUS` while
  `GameState.recovery_active` is true and heals over
  `GameState.sleep_recovery_seconds()` - the HouseDB rate for the current
  cottage level (10 s at Level 1 down to 2 s at Level 5), the same clock the
  home interior and Construction Shop panel use.
- `finish_recovery()` releases the player at full health. Potions bypass waiting
  by restoring health directly.

## Pets

`Pet` is a collision-aware CharacterBody2D with bounded acceleration and catch-up,
using obstacle paths when the direct follow line is blocked. It never teleports
at a distance threshold and has no `PointLight2D`. In combat, while any enemy is
within 7 units, it:
- heals the player on a data-driven interval,
- attacks the nearest enemy on a data-driven interval,
- grants a shield on a longer interval.

Pet health is persisted; a downed pet recovers automatically after five seconds.
There is no revival item and no pet light requirement. Player and pet XP bars appear
over their respective heads and use `GameState.data.xp_next` and
`PetDB.xp_for_level(level + 1)` as their maxima.

## Two battle portals and pet duels

- `Lobby` places two `PortalEntrance` gates side by side; both join the
  `battle_portal` group. Their positions are (30.8, 5.7) and (37.2, 5.7); the shared hill reaches the far northern edge.
- Monster mode opens `PortalPanel`; pet mode opens `PetBattlePanel`.
- `PetBattlePanel` starts a 1v1 duel with the active pet's real level/stats.
  Both pets have attack, defend and burst, with independent 2/5/8-second cooldown dictionaries.
- Each round waits indefinitely for an available player power. `_resolve_turn` applies the player action, schedules one enemy reply after 0.7 seconds, then returns control to the player. An enemy with all powers cooling down waits until one becomes ready. Defend reduces the next incoming damage by 65%; burst deals double damage.
- A viewport-sized backdrop and shared transparent stage replace combatant cards. Health, cooldown labels and three touch buttons sit over the image.
- `PetHitEffect` adds scratch/punch impacts on damage and a shield shell when a
  pet defends.
- `PetBattleDB` supplies five opponents. The first duel is open; each clear
  unlocks the next. Wins call `GameState.complete_pet_battle()`, which guarantees
  at least one companion level; losses/forfeits grant no clear.
- The duel is an animated modal arena, not a walkable world scene.

## Coastal rubbish

- `RubbishSystem` spawns `RubbishPiece` nodes in four water lanes.
- Each piece tracks `resolved` and has exactly two terminal paths:
  - `_caught()` → `register_rubbish_cleaned()` → +1 Gold and +1 sea-cleaned;
  - `_reach_beach()` → spawn one `Enemy(kind="rubbish")`.
- `Enemy` grants rubbish-monster gold directly on death and does not spawn a
  second pickup.
- The guard is a `CoastalGuard` interaction point at the jetty. No catch toast is
  created; the persistent counter and Gold total carry the result. Talking to the
  guard opens `SeaCleaningPanel` with total catches, current gold and the safe
  catch/dangerous beaching rules.

## Residential life, editing and emergencies

- `Lobby` builds fences, twelve `Resident` nodes, six gardens, 50+ flowers,
  chickens/goats, two horses, seven resident cottages, abandoned/damaged/destroyed
  ruin houses, the coastal guard/rubbish system, the yellow Unisza student and a
  dense forest.
- `Resident` follows daily waypoints. During sea-urchin danger or an emergency,
  residents seek an intact house and become protected only after entering it.
  Residents and merchants do not create floating personal-name labels.
- `SettlementPlaceable` groups the house, shops, fence runs, garden beds and
  decorations. `SettlementEditor` toggles with Build/B, locks movement, draws the
  grid area and supports touch/mouse drag with grid snap and bounds clamping.
  Positions save under `settlement_layout` and survive lobby reloads.
- `SettlementTarget` marks the cottage, shop stalls and resident cottages.
  `ForestTree` marks the protected trees throughout the woodland. Every tree
  has persistent HP, shakes/flashes, emits small leaf VFX and plays `tree_hit`.
  Fire attacks ignite mature trees, causing ongoing damage with visible flames.
  At zero HP a tree falls, disappears and leaves the target group. Blue
  `Resident.water_power` keepers claim separate jobs, walk to fires and water
  trees to restore 5 HP per 1.25 seconds and extinguish them at full health.
  `VillageServicesPanel` recruits up to five keepers with saved ownership.
  Green planters walk to
  fallen trees and plant replacements after two seconds of work. Replacements
  grow for 30 seconds of active lobby time, tracked in `forest_growth`; they
  have no trunk collision and cannot be targeted or damaged until mature.
  When no mature trees or planted saplings remain, `Lobby` triggers game over.
  A four-second devastation sequence grades the terrain orange, fades in a
  dark green sea and stranded dead fish/crabs, then shows the locked panel.
- `Lobby` spawns 24 fire monsters, with a raid cap of 30. They only attack mature
  trees and never target or damage players. They remain active after sunrise;
  each night replenishes living fire monsters to 24 and sea urchins to 6. Dawn only changes lighting and never removes or disables surviving enemies.
- Sea rubbish and emergency waves spawn `urchin` enemies. They choose trees,
  fences, houses or exposed residents, and follow obstacle-aware village routes.
  Their tree damage does not ignite fires. Kill rewards never duplicate catches.
- Houses and fences register stable structure IDs in GameState. `SettlementTarget`
  applies per-structure HP, collapse, collision release and restoration. Residents
  walk to intact homes during danger and hide/protect themselves only after arrival.
  Destruction exposes occupants; resident HP and deaths persist by resident name.
- VillageServicesPanel hires the four worker roles. Orange builders claim separate damaged structures and call GameState timed-work transactions only in daylight. StructureRepairPoint requests work without charging Gold; completion takes ten seconds of active builder work after arrival.
- `Game` triggers an emergency after at least 14 seconds inside a portal, once it is night, and applies
  damage ticks every 5 seconds until the player returns.
- `Lobby` spawns `settlement_mode` raiders from sea and forest approaches. Each
  raider death calls `register_emergency_kill()` and grants gold. Zero remaining
  clears the emergency and objective.
- The player is never teleported, and the portal world/combat is untouched.

## Day/night cycle and title flow

- Day and night each last 180 seconds. The HUD shows the phase/countdown and Lobby blends a readable night tint over three seconds (instant with Reduce Motion). Only night can create new fire monsters or sea urchins, including emergency and rubbish paths.
- Living home enemies are captured as primitive kind/position/HP/raid records in `home_monsters` before saves and world transitions. Lobby restores these even during daylight. Saved `home_wave` prevents duplicate night refills. New journeys reset both clock and enemies.
- `TitleScreen` boots to the **PB (Protect BESUT)** main menu with Start Game,
  Continue Journey, How to Play, Settings and Credits. Start Game opens the
  separate **CHOOSE YOUR ROAD** page. Cards preview a hero; Begin Journey emits
  the selected hero only after a separate confirmation if a save exists.
  Browsing and Back do not save or construct a world. Continue loads the saved
  village/expedition directly, and a failed load leaves inline feedback on the
  usable menu without changing the file. Both handoffs reject repeat activation.
- `TitleBackdrop` draws a presentation-only dusk harbour using cached village
  art. It consumes no gameplay RNG and owns no world clock. Low quality or
  Reduce Motion stops water/boat animation; the complete static scene remains.
  Title settings use `GameSettings` before a journey exists. Title overlays own
  their focus and Escape/back paths; the world HUD settings panel stays separate.
- `MissionDB.DAY_STEPS` selects seven civilian lessons and `NIGHT_STEPS` selects three combat lessons. `GameState.completed_missions` stores completed event IDs, and `mission_step()` computes the next unfinished lesson for the active phase. Legacy numeric progress is migrated on load. Only the current lesson’s real event advances progress; Continue resumes
  the saved lesson. `TutorialSpotlight` darkens the rest of the screen and draws an arrow around the current control, stall, or modal action. It does not intercept input. Tips can be hidden/reopened from Menu.

## Guidance, dashboard and menus

- `Lobby.get_guidance_targets()` returns the current lesson's single destination,
  using actual shop positions after editing. After lessons, it selects one objective.
  `Dungeon.get_guidance_targets()` returns the boss or Shore Gate.
- `MissionPath` draws dashed arrows along routes around world collision. Lobby
  shares its resident route planner; Dungeon has a separate planner. The old HUD
  arrow strip is no longer constructed; compatibility methods remain inert.
- `PlayerVitalHud` is a child of `Player` with `light_mask = 0`; it draws HP, MP, XP and level above the player’s head. `WorldHealthBar` draws pet HP/XP and boss HP. The top HUD contains the clock and Menu; shops own currency readouts. Pack contains potion controls.
- `GameHUD.MenuButton` emits `menu_requested`. `MenuPanel` opens Settings, toggles Build settlement / Finish building, or returns to title. No separate Build or potion touch buttons are constructed.
- `SettingsPanel` controls device-level `GameSettings.ui_scale` and `camera_zoom`,
  and per-save `GameState.settings.control_layout`. GameState's GUI methods are
  compatibility delegates; legacy scale migrates only when settings.cfg has none.
  GUI sliders preview without saving each tick and commit on release/focus/close.
  HUDRoot stays unscaled. Individual controls scale around their own anchors,
  with responsive fitting and a 44-physical-pixel touch minimum. Full-screen
  modals and fades keep their responsive viewport geometry. VITALS is removed.
- `FollowCamera` follows in physics updates with exponential smoothing; Godot
  interpolates physics rendering. Nearest filtering remains on; manual art-grid
  camera rounding and both canvas pixel-snapping flags are off. Logical actor
  positions are never rounded. Camera limits stay world-specific.
- `GameOverPanel` is a locked modal. `GameState.trigger_game_over()` disables
  autosave, `Game` deletes the failed save and the panel can only return to title.

## Visual & feel systems (visual-overhaul branch)

- **`scripts/core/icon_art.gd`** - native 32 px icon set (1 px auto-outline,
  3-tone shading). `PixelArt.icon(kind, size >= 24)` routes here; the 16 px
  art is untouched.
- **`scripts/core/vfx.gd` + `vfx_pool.gd`** - one pre-allocated pool per world
  (sparks, rings, dust, damage numbers, icon pops). No per-hit allocation;
  steals are safe because spawns reset every tweened property.
- **`scripts/core/shaders.gd`** - shared canvas_item materials built in code.
  The wind shader bends vertices from the sprite base with a phase derived
  from `MODEL_MATRIX` plus a per-instance `INSTANCE_CUSTOM` seed (MultiMesh
  safe), and bends grass away from up to four "benders" pushed through
  shader globals. The water shader renders the sea mask with moving bands,
  subtle crests while respecting the full-resolution, ocean-bounded mask alpha.
- **`scripts/data/attack_db.gd`** - weapon attack chains
  (anticipation/active/recovery per step). Damage is applied on the active
  frame; `attack_cooldown` restarts at each hit frame, preserving DPS.
- **`scripts/combat/hit_feedback.gd`** - the shared hit pipeline (flash,
  sparks, numbers, hit-stop, micro-shake). Enemies implement
  `apply_hit_stop()`; hit-stop is skipped under reduce-motion/low quality.
- **Enemy FSM** - `SPAWN/WANDER/ALERT/CHASE/WINDUP/ATTACK/RECOVER/STAGGER/DEAD`
  with a >=0.42 s telegraph (ground decal + wind-up pose), separation steering
  (cached group list) and per-kind movement personalities.
- **Shops** - `ShopScene` (storefront band, animated keeper bust, dialogue
  from `ShopLinesDB`), `ItemCard` (reusable card) and an in-place refresh in
  `ShopPanel`: cards update without rebuilding, so scroll and hover survive
  `data_changed`; the card set signature triggers a full rebuild only when
  the stock or owned-pet set changes. `GameState.pet_upgrade_cost()` is the
  single source of the companion upgrade price.
- **Portals** - `PixelArt.portal_theme_palette/frame/swirl/emblem` generate
  per-theme art from `PortalDB` (ten themes plus the pet arena look; no
  portal-id special cases). `PortalEntrance` composites frame + animated
  swirl + motes + light pool, wakes when the player approaches, seals when
  locked and wears a golden aura when cleared. Enter/exit pull the player in
  before the existing world-load flow.
- **Light sizing rule** - light textures are 128 px and 1 world unit = 1 px,
  so a `texture_scale` of ~0.05 gives a ~3-unit light pool. Every pre-existing
  light was ~13x oversized and washed the whole map; they are now local pools.
- **Grass** - `Lobby._build_grass_fields()` renders 300-520 clustered tufts
  through four `MultiMeshInstance2D` fields (one draw call per texture
  variant) with per-instance colour jitter and phase seeds, using a dedicated
  seeded RNG so the tree-id sequence never changes. Flowers stay individual
  sprites (the `flowers` group is an acceptance contract).
- **Ambient life** - optional small chimney/ruin smoke at high quality; no star
  pollen, butterfly placeholders, growth-aura sparkles or random leaf rain.
  `_update_ambient()` pushes wind benders and restrained recovery ward cues.
  Settings update water fallback, wind, smoke, animal motion and extra lights live.
- **World ownership** - each ForestTree owns its shadow, two registered sprites
  and trunk Body before ready, so persisted fallen trees disable their collider.
  The existing generation RNG and tree ID order are preserved. Cottages, ruins,
  rubble and smoke likewise use their intended holder-local coordinates.
- **Shopping** - Resident is a CharacterBody2D with ROUTINE → WALK_TO_SHOP →
  BROWSE → PURCHASE → LEAVE states. ShopNPC holds one weak customer reservation;
  exchanges animate locally without calling player transactions. Missing/unreachable
  shops and visit timeouts release reservations. Emergency/unload cancels visits.
  ResidentRoutes samples collision layer 1 into an AStarGrid2D planning graph;
  actual movement uses acceleration, arrival tolerances and move_and_slide through
  floating-point coordinates, not cell assignments. Editor completion invalidates
  the shared planner. Pets can reuse the same planner.

## Save format

JSON at `user://tidesworn_save.json`, version 6. Loading recursively merges over
a default, sanitizes stats/currency/house/recovery/emergency bounds, keeps the
settlement layout, pet-duel clears, sea-cleaning count, per-tree forest health and
GUI/control settings, removes retired items, restores pets and validates the
hero's equipped weapon.
Autosave runs on important transactions and app pause/focus loss.

## Creative revamp resource and editor layer

The active game construction flow and three autoloads are unchanged. See
`docs/CREATIVE_REVAMP_COMPLETION.md` for the exact source inventory.

`WorldPalette` is a resource with separate semantic world/UI dictionaries.
`WorldTerrain` shares procedural village generation with the editor preview.
`AssetCatalog` stores stable IDs, imported texture paths and frame metadata;
`AssetRegistry` resolves overrides ahead of PixelArt's bounded fallback cache.
`AuthoredSprite` preloads animation clips without per-frame file reads.

`AuthoredMap` version 1 stores sparse terrain layers, object definitions and
editor visibility/locking state. `AuthoredMapRenderer` creates native TileMapLayer
batches, merged collision runs, interactive props, merchants, route/spawn markers
and stable tree objects. Base references move existing nodes instead of duplicating
them; player settlement layout retains precedence. The original tree generation
order and player save format remain unchanged. Original cottage/shop service
movement continues through SettlementEditor.

`MicroAction` supplies bounded, priority-based presentation states; editable
PersonalityProfile data describes heroes and occupations. It does not own combat
timers, transactions or persistence. Motion drives walking cadence; logical actor
positions and camera interpolation remain continuous.

The native Tidesworn workspace is entirely under `addons/tidesworn_creative_tools`.
Map undo integrates with EditorUndoRedoManager; pixels use bounded image snapshots.
The plugin reports unsaved work and keeps recovery drafts across disable/reload.
It is excluded from runtime packaging. Exported resource-pack smoke testing boots
the actual game and imported art without the editor code.

HousePanel keeps a local selected preview level. Every Level button can show that design and recovery rate without changing GameState or charging diamonds; Confirm Upgrade still purchases only the next level. ShopNPC handles unhandled mouse/touch hits against the full stall footprint, guarded by current world, modal lock and editor state.

## Coordinated village geography

AuthoredMap version 2 references an optional WorldLayout. The shipped source is
`data/maps/village_layout.tres`. It owns anchors, footprints/approaches, route
edges, polygonal districts and contextual scenery; Lobby builds the existing
functional owner nodes at those resolved positions. Player settlement positions
win over developer overrides, which win over canonical defaults. Runtime copies
never write developer resources. Historical forest exclusions/RNG prefix remain
frozen independently, preserving every ID/position/HP association.

WorldTerrain and Map Studio render the same route graph and polygonal geography.
The imported default terrain bake is used only for matching geometry/palette
hashes; live edits fall back to data-driven generation with a four-version cache.
WorldComposition supplies independent seeded, reservation-aware foliage and
building-local workspaces. ResidentRoutes still plans against actual physics;
customized layouts can repair road centreline routing once after synchronization.
Sea collision follows the shared shore sampler, with an explicit exception only
for the visible timber deck. Authored water always blocks, and land paint cannot
hide water collision. Details and workflow: [WORLD_LAYOUT.md](WORLD_LAYOUT.md).

PetBattleDB assigns a separate installed background resource to each duel. All five supplied files are preserved; the supplied GIF also has a PNG first frame for Godot. Native review captures each backdrop.


## PB village systems

GameState owns worker_counts, resident health, the central house level and repair_remaining. Resident.worker_role selects builder, water, planter or fighter AI. Builders claim a SettlementTarget.builder, navigate to the structure and spend ten seconds repairing during daylight. Blue workers water burning trees or launch VillageBolt water projectiles at fire monsters; green workers alone plant trees; black workers engage sea urchins with a sword. Ordinary residents retain their shelter/routine behavior. New journeys start with one specialist per role. worker_count() is the greater of purchased ownership and main-house level, within role limits; upgrading raises the baseline while hiring can add further workers.

Every house has a HouseDefense archer hut with an NPC/bow sprite. Its central-house tier selects range, arrow damage and intervals (2.1/1.7/1.3/1.0/0.7 seconds). VillageBolt.arrow draws a directional arrow. structure_level() returns the central house tier for all structures; upgrades synchronize stored tiers and raise the worker baseline. Existing worker purchases and deaths remain saved. HousePanel previews the house, hut, fence and worker baseline before charging once for the next main-house level. SettlementTarget refreshes fence sprites from the cached five-tier PixelArt.fence_texture(level). Ruins retain independent health/repairs.

HomeEntrance handles direct input on the central house. Game.enter_home keeps Lobby alive while adding HomeInterior outside the outdoor map, moves player and pet inside and fits the camera to the room. HomeInterior applies HouseDB recovery and offers an exit; no HouseBed is constructed. Cached PixelArt sprites furnish a chest, wardrobe, weapon rack and pet bed. Leaving restores outdoor positions and camera preferences.

MissionNPC is purple with a question mark and routes to MissionPanel. GameHUD no longer constructs Journal or a screen boss bar. WorldHealthBar follows pets/bosses above their heads.

WorldHealthBar also displays the unique PortalDB boss name. Only completing the first portal records the tutorial boss event, and PortalPanel limits active portal-training lessons to that first dungeon. TutorialSpotlight.dim_strength() is zero at night while its outline/pointer remain.

Dungeon.alert_intruders sets persistent enemy chase flags. Regular monsters start chasing on entry; touching/damaging a boss also activates the boss and all survivors. A shared route planner steers them around dungeon obstacles.

## Loading and illustrated field guide

LoadingScreen is a CanvasLayer above title and HUD. Game awaits its opaque cover before world/home rebuilds, locks both current and newly created players, then fades it away before releasing input. Continue activates unfinished tutorials across both phases. ModalBase owns a short cancellable entry fade; PetBattlePanel reuses it when entering its arena.

FieldGuideDB supplies NPC, monster and ten boss entries. FieldGuidePanel, reached through Menu, pages through GuideIllustration drawings. The storyboard uses sprites and pictograms rather than prose: actor on the left, two action/result rows on paper on the right. It uses the normal modal input-lock and close paths and fits small landscape viewports.
