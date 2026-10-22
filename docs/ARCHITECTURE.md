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
    └── Save The World title + Qayyim/Farhan/Ayiz cards + Continue
```

`Game` owns world lifetimes, modal input locking, portal timer, emergency
trigger/damage simulation and transitions. It does not duplicate stats.

`Sfx` is a lightweight autoload that synthesizes and caches short PCM tones for
tree impacts, aggro calls, charges, skill use, selection and victory. No external
audio assets are required.

`GameSettings` (added by the visual overhaul) is the third autoload. It owns
device-level preferences in `user://settings.cfg`, independent of the save
file: volumes, mute, fullscreen, UI scale, touch layout mode, screen shake,
`reduce_motion` and `effects_quality` (low/med/high). The Settings panel reads
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
- persistent per-tree forest health,
- sea-cleaning count,
- GUI scale and custom touch-control layout,
- in-game play time and counters.

The world is intentionally locked in **permanent daytime**; there is no phase
clock or night transition.

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
the journal and modal screens.

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

Currency is deducted only after validation and never becomes negative.

## Auto-heal and recovery

- `GameState.damage_player()` applies shield first, then health.
- If health is at/below one of ten segments and a Health Potion exists, an armed
  auto-heal consumes exactly one potion and rearms only after health climbs above
  35%.
- `Lobby` clamps the player inside `RECOVERY_CENTER/RADIUS` while
  `GameState.recovery_active` is true and heals over eight seconds.
- `finish_recovery()` releases the player at full health. Potions bypass waiting
  by restoring health directly.

## Pets

`Pet` follows the player and has no `PointLight2D`. In combat, while any enemy is
within 7 units, it:
- heals the player on a data-driven interval,
- attacks the nearest enemy on a data-driven interval,
- grants a shield on a longer interval.

Pet health is persisted; a downed pet recovers automatically after five seconds.
There is no revival item and no pet light requirement. Player and pet XP bars sit
in the top-left HUD panel and use `GameState.data.xp_next` and
`PetDB.xp_for_level(level + 1)` as their maxima.

## Two battle portals and pet duels

- `Lobby` places two `PortalEntrance` gates side by side; both join the
  `battle_portal` group.
- Monster mode opens `PortalPanel`; pet mode opens `PetBattlePanel`.
- `PetBattlePanel` starts a 1v1 duel with the active pet's real level/stats.
  Both pets have `Attack` and `Defend`.
- Each round opens a 2-second choice window. Player and enemy choices are held,
  then `_resolve_turn()` applies both simultaneously. Defend reduces incoming
  damage by 65%.
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
- `Resident` follows daily waypoints. Non-combat residents flee to shelter on
  `emergency_changed(true, ...)`; combat-capable residents and defenders attack
  nearby raiders. Residents and merchants no longer create floating name labels.
- `SettlementPlaceable` groups the house, shops, fence runs, garden beds and
  decorations. `SettlementEditor` toggles with Build/B, locks movement, draws the
  grid area and supports touch/mouse drag with grid snap and bounds clamping.
  Positions save under `settlement_layout` and survive lobby reloads.
- `SettlementTarget` marks the cottage, shop stalls and resident cottages.
  `ForestTree` marks the 64 protected trees in the eastern woodland. Every tree
  has persistent HP, shakes/flashes, emits leaf/spark VFX and plays `tree_hit`.
  At zero HP it falls and leaves the target group. When all trees are dead,
  `Lobby` calls `GameState.trigger_game_over()`.
- `Lobby` spawns eight persistent `forest_mode` monsters and three extra during
  an emergency. Their attack cadence is 0.62s, so tree impacts stay active.
- `Enemy.forest_mode` targets the nearest tree until `_can_see_player()` passes a
  range + raycast line-of-sight check. On first sight it immediately sets the
  player as target, plays `aggro`, and starts a charge before attacking.
- `Game` triggers an emergency after 14 seconds inside a portal and applies
  damage ticks every 5 seconds until the player returns.
- `Lobby` spawns `settlement_mode` raiders from sea and forest approaches. Each
  raider death calls `register_emergency_kill()` and grants gold. Zero remaining
  clears the emergency and objective.
- The player is never teleported, and the portal world/combat is untouched.

## Permanent daytime and title flow

- The environment remains in daylight at all times. No phase timer, night tint or
  HUD countdown exists.
- `TitleScreen` shows **SAVE THE WORLD**, the creator credit, Continue and the
  three-hero **CHOOSE YOUR ROAD** cards.
- New games start `TutorialGuide` (eight non-blocking steps); Continue skips it.

## Guidance, dashboard and menus

- `Lobby.get_guidance_targets()` returns up to three mission targets: emergency
  raider, Monster gate, Pet gate, Construction Shop or forest/guard fallback.
  `Dungeon.get_guidance_targets()` returns the boss or Shore Gate.
- `GameHUD._update_mission_guide()` refreshes three `MissionArrow` nodes every
  0.2s with direction and distance.
- `PlayerVitalHud` is a child of `Player` with `light_mask = 0`; it draws only HP
  and MP above the player's head.
- `GameHUD.MenuButton` emits `menu_requested`. `MenuPanel` opens Settings or
  returns to title.
- `SettingsPanel` controls `GameState.settings.gui_scale` and
  `settings.control_layout`. `GameHUD` applies GUI scale to its root and absolute
  X/Y/size overrides to the touch controls; Reset restores the original responsive
  anchors.
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
  foam crests and sparkle while respecting the mask alpha.
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
- **Ambient life** - `Lobby._build_ambient_life()` (cloud shadows, pollen,
  butterflies, forest light shafts, eastern grade, chimney smoke) and
  `_update_ambient()` (bender push, falling leaves, ward motes), all gated
  behind `effects_quality >= med` and `reduce_motion == false`.

## Save format

JSON at `user://tidesworn_save.json`, version 6. Loading recursively merges over
a default, sanitizes stats/currency/house/recovery/emergency bounds, keeps the
settlement layout, pet-duel clears, sea-cleaning count, per-tree forest health and
GUI/control settings, removes retired items, restores pets and validates the
hero's equipped weapon.
Autosave runs on important transactions and app pause/focus loss.
