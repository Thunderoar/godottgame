# Agent B — World, Economy, UI & Content Data

Project root: `/home/roku/Documents/games/tournamentgame/GAME_COMP_RPG-Godot`
Engine: Godot 4.7.2 · Status: **COMPLETE** — all nine questions answered from source, read-only.
Integrity checked after writing: all **369** `file:line` references resolve to an
existing file, all **578** individual line numbers are in range, and **71**
hand-picked citations were re-read and confirmed to contain the claimed code.
Two claims I drafted first and then disproved by re-grepping were corrected
(`_emergency_fire` *is* assigned; `equip_item` *does* enforce the hero-style lock).

**Slice covered:** `scripts/world/*` (18 files), `scripts/ui/*` (16 files),
`scripts/data/*` (6 files). Cross-read for wiring only (not modified, not owned):
`scripts/autoload/game_state.gd`, `scripts/game/game.gd`, `scripts/combat/enemy.gd`.

**`scenes/game.tscn` finding, up front:** the file is **6 lines** — a single
`Node2D` root with `scripts/game/game.gd` (`scenes/game.tscn:5-6`). *Nothing* from
this slice is instanced there or in any other `.tscn`. `Lobby`, `Dungeon`,
`GameHUD` and all eight panels are constructed in GDScript at runtime
(`game.gd:28-30`, `:125`, `:149`; `game_hud.gd:477-493`). There are no node paths
or exported scene properties to wire; every layout number is a literal in code.

## 1. Content data model (`scripts/data/*.db.gd`)

All six DBs follow the same shape: `class_name XDB` + `extends RefCounted`, one
`const` table (Dictionary or Array) at the top, and **only** `static func`
accessors below it. No instances are ever created, no `_init`, no signals, no
autoload registration. Callers use `CharacterDB.get_character(...)` /
`ItemDB.ITEMS` directly — e.g. `scripts/data/item_db.gd:1-9`,
`scripts/data/portal_db.gd:1-6`, `scripts/data/house_db.gd:1-5`.

Every getter returns `.duplicate(true)` (deep copy) so callers cannot mutate the
canonical table: `scripts/data/item_db.gd:224-225`,
`scripts/data/character_db.gd:69-73`, `scripts/data/portal_db.gd:230-231`,
`scripts/data/pet_db.gd:62-63`, `scripts/data/house_db.gd:49-50`,
`scripts/data/pet_battle_db.gd:85-86`. Note `character_db.gd:73` falls back to
`CHARACTERS[0]` (Qayyim) for an unknown id instead of returning `{}` — the other
DBs return `{}`.

### 1.1 `item_db.gd` — 18 items, `const ITEMS := Dictionary[id -> record]`

Record keys actually present across the table (`scripts/data/item_db.gd:9-221`):

| key | type | unit / meaning | present on |
|---|---|---|---|
| `name` | String | display name | all 18 |
| `kind` | String enum | `weapon`\|`armor`\|`shield`\|`consumable`\|`material` | all 18 |
| `slot` | String | `weapon`\|`armor`\|`shield` — equip target | 14 equipment items |
| `style` | String | `sword`\|`hammer`\|`bow` — hero-lock filter | 9 weapons |
| `price` | int | gold, 0 = not purchasable | all 18 |
| `currency` | String | always `"gold"` in the current table | all 18 |
| `stack` | int | max stack size | all 18 |
| `attack` | int | flat ATK added on equip | 9 weapons |
| `defense` | int | flat DEF added on equip | 5 armor/shield |
| `effect` | Dictionary | `{"heal":N}` / `{"mana":N}` / `{"pet_xp":N}` | 3 consumables |
| `description` | String | flavour + stat hint | all 18 |
| `shop` | String | shop bucket: `equipment`\|`potion`\|`pet`\|`""` | all 18 |
| `sellable` | bool | **absent = false** (unsellable); `true` only on `wood` | all 18 (4 explicit `false`, 1 `true`) |
| `lost_on_defeat` | bool | `false` on potions/pet food | 3 consumables |

Full inventory with the numbers that matter (price / stat / stack). **Every line
ref in this list is `scripts/data/item_db.gd`:**

- **Swords** (`style:"sword"`): `rusty_sword` 0g ATK6 (starter, `sellable:false`) `:10`; `iron_sword` 90g ATK14 `:23`; `tideblade` 240g ATK26 `:35`
- **Hammers** (`style:"hammer"`): `smith_hammer` 0g ATK9 (starter) `:47`; `iron_hammer` 100g ATK18 `:60`; `tide_hammer` 260g ATK32 `:72`
- **Bows** (`style:"bow"`): `reed_bow` 0g ATK7 (starter) `:84`; `yew_bow` 92g ATK14 `:97`; `tide_bow` 245g ATK25 `:109`
- **Armor**: `cloth_tunic` 0g DEF2 (starter) `:121`; `leather_vest` 75g DEF6 `:133`; `shell_plate` 210g DEF12 `:144`
- **Shields**: `drift_shield` 60g DEF4 `:155`; `tower_shield` 180g DEF9 `:166`
- **Consumables**: `health_potion` 25g `heal:45` stack 9 `:177`; `mana_potion` 20g `mana:35` stack 9 `:188`; `pet_food` 15g `pet_xp:25` stack 20 `:200`
- **Material**: `wood` 4g stack 99, `shop:""` (never sold), `sellable:true` `:211`

9 weapons = exactly 3 tiers × 3 styles. Price ladder per style is
90/240, 100/260, 92/245 — deliberately not uniform. `magic` is read by
`stat_line()` (`scripts/data/item_db.gd:269-270`) but **no item defines it**, so
the `MAG +N` branch is dead code.

Static helpers (`scripts/data/item_db.gd:224-281`): `get_item`, `exists`,
`name_of`, `stock_for(shop_id)`, `equipment_stock`, `equipment_for_style(style)`,
`is_equipment`, `stat_line`. `stock_for` is the shop filter — it is a pure
`shop` field equality match (`:236-241`), so an item with `shop:"equipment"` is
automatically in every equipment vendor's list.

### 1.2 `character_db.gd` — 3 heroes, `const CHARACTERS := Array[Dictionary]` (ordered)

| id | name | hp | mana | atk | def | speed | cooldown | range | mult | starter weapon |
|---|---|---|---|---|---|---|---|---|---|---|
| `qayyim` | Qayyim | 105 | 45 | 1 | 0 | 4.4 | 0.38 | 2.05 | 1.0 | `rusty_sword` |
| `farhan` | Farhan | 135 | 28 | 0 | 3 | 3.9 | 0.64 | 2.55 | 1.35 | `smith_hammer` |
| `ayiz` | Ayiz | 92 | 65 | 1 | -1 | 4.6 | 0.55 | 8.0 | 0.95 | `reed_bow` |

`scripts/data/character_db.gd:5-66`; field-by-field `:6-25` (qayyim), `:26-45`
(farhan), `:46-65` (ayiz). Note `attack` is the *bonus* (1/0/1) on top of weapon
ATK, and `defense` can be **negative** (`ayiz`, `:53`). Also carries cosmetic
`tint`/`hair`/`accent` Colors used to build the player sprite, and `weapon_style`
which is the join key into `ItemDB.equipment_for_style()`.

Accessors: `get_character`, `ids`, `weapon_style` (`:69-84`).

### 1.3 `portal_db.gd` — 10 portals, `const PORTALS := Dictionary[id -> record]`

Ordering is **not** the Dictionary order — it is a hardcoded array in
`ordered_ids()` (`scripts/data/portal_db.gd:234-246`). Progress order:

| # | id | lvl req | monster | count | boss_hp | boss dmg | speed | ability | cooldown | unlocks | first reward (g/d/xp) | repeat (g/d/xp) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | `tidebound_grotto` | 1 | bogling L1 | 12 | 420 | 18 | 1.7 | `punch` | 3.6 | sunken_crypt | 160/8/90 + pet `luma` | 100/3/40 |
| 2 | `sunken_crypt` | 3 | drowned L3 | 14 | 760 | 26 | 1.9 | `slam` | 4.2 | reef_hollow | 360/14/180 | 220/6/80 |
| 3 | `reef_hollow` | 5 | bogling L5 | 11 | 980 | 30 | 2.1 | `charge` | 3.8 | brine_cavern | 520/18/260 | 300/8/100 |
| 4 | `brine_cavern` | 7 | drowned L7 | 12 | 1120 | 32 | 1.8 | `projectile` | 2.9 | kelp_maze | 650/20/320 | 360/9/120 |
| 5 | `kelp_maze` | 9 | bogling L9 | 13 | 1350 | 36 | 1.65 | `area` | 4.6 | bone_gallery | 800/24/380 | 420/10/140 |
| 6 | `bone_gallery` | 12 | drowned L12 | 11 | 1580 | 40 | 2.0 | `charge` | 3.4 | storm_shrine | 980/28/460 | 500/12/170 |
| 7 | `storm_shrine` | 15 | bogling L15 | 12 | 1840 | 44 | 1.8 | `projectile` | 2.6 | coral_throne | 1200/32/540 | 600/14/200 |
| 8 | `coral_throne` | 18 | drowned L18 | 13 | 2100 | 48 | 1.9 | `punch` | 3.2 | abyss_gate | 1450/38/650 | 720/16/240 |
| 9 | `abyss_gate` | 21 | bogling L21 | 14 | 2400 | 52 | 2.0 | `area` | 4.0 | drowned_throne | 1700/44/760 | 860/18/280 |
| 10 | `drowned_throne` | 25 | drowned L25 | 15 | 2800 | 58 | 2.1 | `projectile_charge` | 2.8 | `""` (end) | 2200/55/950 | 1100/24/360 |

Source: rows at `scripts/data/portal_db.gd:7`, `:29`, `:51`, `:73`, `:95`,
`:117`, `:139`, `:161`, `:183`, `:205`. Reward dicts are nested
`{"gold","diamonds","xp"[,"pet"]}` — `pet` appears **only** on portal 1
(`:25`). `boss_projectile_damage` is a separate field from `boss_damage`
(`:22`, `:44`, …) and is only used by projectile-family abilities.
`monster_kind` only ever takes two values: `bogling` or `drowned` (`:12` vs
`:34`) — the visual/stat variant selector for regular mobs.

### 1.4 `pet_db.gd` — 3 pets, `const PETS := Dictionary`, `const MAX_LEVEL := 5`

| id | species | cost | hp | focus | heal/interval | atk/interval | shield/interval | starter |
|---|---|---|---|---|---|---|---|---|
| `ember` | Ember Fox | 0 | 55 | Healing | 3 / 2.4s | 5 / 3.0s | 6 / 12.0s | `true` |
| `moss` | Marsh Cat | 140 | 70 | Attacking | 2 / 3.0s | 9 / 2.2s | 4 / 15.0s | — |
| `luma` | Tide Moth | 0 | 62 | Shielding | 2 / 2.6s | 7 / 2.7s | 10 / 10.0s | — (portal-1 drop) |

`scripts/data/pet_db.gd:6-56`. `cost` is **gold** (`moss` 140g, `:27`);
`luma.cost` is 0 because it is a boss drop, not a purchase.

Level curves are all **linear in level**, not in the table (`:70-108`):
`max_health = hp + (lvl-1)*12`, `heal = heal + (lvl-1)`,
`heal_interval = max(1.0, base - (lvl-1)*0.12)`,
`attack = attack + (lvl-1)*3`, `attack_interval = max(1.0, base-(lvl-1)*0.1)`,
`shield = shield + (lvl-1)*2`, `shield_interval = max(6.0, base-(lvl-1)*0.8)`.
XP thresholds `LEVEL_XP := [0, 50, 130, 250, 420]` (`:59`) are indexed by
`level-1` via `xp_for_level` (`:105-108`), i.e. the cost to *reach* level N is
`LEVEL_XP[N-1]`. `shop_stock()` returns only `["moss"]` (`:111-112`).

### 1.5 `house_db.gd` — 5 tiers, `const LEVELS: Array[Dictionary]` (ordered, `level` 1..5)

| level | name | cost (diamonds) | recovery seconds |
|---|---|---|---|
| 1 | The Wreck | 0 | 10.0 |
| 2 | Patched Roof | 8 | 8.0 |
| 3 | Seaboard Cottage | 18 | 6.0 |
| 4 | Warden's Rest | 32 | 4.0 |
| 5 | The Lantern House | 54 | 2.0 |

`scripts/data/house_db.gd:5-46`. `cost` is the price **to reach that level**
(`next_level()` returns `LEVELS[level]`, i.e. index = current level, `:57-60`)
and is denominated in **diamonds** — stated in the file header comment
(`:3`) and enforced in `house_panel.gd` (§3). `recovery` is the respawn heal
duration in seconds, not a heal rate.

### 1.6 `pet_battle_db.gd` — 5 duels, `const LEVELS := Dictionary` + `const ORDER := Array`

| id | order | name | pet_level gate | opponent | hp | damage | interval | gold | xp |
|---|---|---|---|---|---|---|---|---|---|
| `pet_duel_1` | 1 | Clover Ring | 1 | Sparring Ember | 42 | 5 | 1.55 | 25 | 35 |
| `pet_duel_2` | 2 | Bramble Court | 2 | Bramble Cat | 58 | 7 | 1.42 | 45 | 55 |
| `pet_duel_3` | 3 | Moonlit Ring | 3 | Dusk Moth | 76 | 9 | 1.30 | 70 | 80 |
| `pet_duel_4` | 4 | Storm Terrace | 4 | Storm Fox | 96 | 11 | 1.18 | 100 | 110 |
| `pet_duel_5` | 5 | Tideworn Crown | 5 | Tidecat Sovereign | 124 | 14 | 1.05 | 150 | 150 |

`scripts/data/pet_battle_db.gd:6-82`; ordering via `ORDER` at `:89-91` and
`ordered_ids()` at `:94-99`. `pet_level` is the *required* pet level to enter,
`interval` is the opponent's attack period in seconds.

### 1.7 Canonical edit recipes

**Add a new item** — 1 file, 1 insertion:
1. Add a record to `const ITEMS` in `scripts/data/item_db.gd:9-221`. Minimum
   viable fields: `name, kind, price, currency, stack, description, shop`.
2. If it must be *sold*, set `shop:"equipment"|"potion"|"pet"` — that single
   field is the entire shop filter (`item_db.gd:236-241`). Nothing else to touch.
3. If it is a weapon, `style` must match a hero's `weapon_style`
   (`character_db.gd:16/36/56`) or `equipment_for_style()` will hide it from that
   hero (`item_db.gd:248-256`).
4. Add an icon/visual only if the UI keys off `kind` — verify in
   `scripts/ui/shop_panel.gd` / `inventory_panel.gd` (§2, §6).

**Add a new portal level** — 2 files, 2 insertions (order matters):
1. Add the record to `const PORTALS` (`scripts/data/portal_db.gd:6-227`).
2. **Append the id to `ordered_ids()`** (`portal_db.gd:234-246`). This array is
   hand-maintained and is the only source of campaign order — forgetting it
   silently hides the portal from the map/list even though the data exists.
3. Chain it: set the previous portal's `unlocks` to the new id, and the new
   portal's `unlocks` to `""` if it is terminal (`:222`).

**Add a new house tier** — 1 file, and it must stay index-aligned:
1. Append to `const LEVELS` in `scripts/data/house_db.gd:5-46` with
   `level = LEVELS.size()+1`, `cost`, `recovery`.
2. `get_level()` indexes `LEVELS[level-1]` (`:49-50`) and `next_level()` indexes
   `LEVELS[level]` (`:57-60`), so the array index and the `level` field must agree
   or upgrades will read the wrong tier. No other file enumerates tiers —
   `house_panel.gd` reads `HouseDB.max_level()`.


## 2. Economy rules

Two currencies: `gold` and `diamonds`, both living in `GameState.data` as plain
ints (`scripts/autoload/game_state.gd:90-91`, defaults 120 gold / 12 diamonds).
Every mutation goes through `GameState`; no scene writes `data.gold` directly
outside the autoload (verified: `grep "data.gold *="` matches only
`game_state.gd:178,217,250,542,571,930,975,1222`).

### 2.1 Transaction primitives

| func | file:line | guard |
|---|---|---|
| `add_gold(amount)` | `game_state.gd:175-179` | `amount == 0` early-out; `data.gold = maxi(0, gold()+amount)` — **clamped at 0**, no upper clamp, no debounce |
| `add_diamonds(amount)` | `game_state.gd:182-186` | same shape, `maxi(0, …)` |
| `buy_item(item_id, qty=1)` | `game_state.gd:190-227` | 280 ms per-item debounce, price/currency check, `can_add_item`, deduct-then-add ordering |
| `sell_item(item_id, qty)` | `game_state.gd:239-254` | requires `sellable == true`, `count >= qty`, value>0, remove-then-credit |
| `equip_item(item_id)` | `game_state.gd:337-355` | equipment-only, owned, has `slot`, `style` must match hero |
| `purchase_pet(pet_id)` | `game_state.gd:532-558` | gold check, not-already-owned check |
| `upgrade_pet(pet_id)` | `game_state.gd:561-580` | gold check, `MAX_LEVEL` check |
| `upgrade_house()` | `game_state.gd:814-827` | **diamond** check (`:819`), max-level check |
| `bank_expedition_loot()` | `game_state.gd:903-920` | additive, no clamp needed |

**Atomicity.** `buy_item` is the only function with an explicit
ordering comment and it is genuinely ordered: all validation happens before any
mutation, then currency is deducted at `:215-219`, then — with the comment
"Only after the deduction is confirmed do we mutate inventory." — inventory is
added at `:220-221`. The weak point: `add_item(...)`'s **bool return is
discarded** at `:221`; if `add_item` fails after the `can_add_item` pre-check
passed, the gold is gone and nothing is added. The pre-check at `:212` makes that
unlikely (same predicate) but the function is not re-entrant-safe against a
concurrent caller mutating inventory between `:212` and `:221`.

**Debounce.** `buy_item` only: `Time.get_ticks_msec()` compared against
`_last_purchase[item_id]`, 280 ms window, returns
`{"ok": false, "message": "Just a moment..."}` (`game_state.gd:195-199`).
`_last_purchase` is a plain Dictionary that is **never pruned** (`:33`) — it grows
one entry per distinct item ever bought, which is bounded by the 18-item table,
so harmless today. There is **no** debounce on `sell_item`, `upgrade_pet`,
`upgrade_house`, or `purchase_pet` — those are protected only by
`disabled` buttons in the UI plus the affordability check.

**Debounce is refused, not queued** — the UI does not retry; the toast is
surfaced by the caller (`shop_panel.gd:117-118`).

### 2.2 Gold sources

| source | amount | file:line |
|---|---|---|
| New game | 120 | `game_state.gd:90` |
| Portal completion, first clear | `rewards_first.gold` per portal 160→2200 | `game_state.gd:975-976` + `portal_db.gd:25,47,…` |
| Portal completion, repeat | `rewards_repeat.gold` 100→1100 | same |
| Regular monster kill | `7 + level*3` gold, spawned as LootDrop | `dungeon.gd:281`, `enemy.gd:403` |
| Settlement/emergency monster kill | `gold_reward` = 12 | `lobby.gd:1136`, `enemy.gd:367-370` |
| Coastal/sea monster kill | `gold_reward` = 6 | `lobby.gd:508` |
| Rubbish monster kill | `gold_reward` = 7 | `rubbish_system.gd:83`, `enemy.gd:373-375` |
| LootDrop pickup (`kind=="gold"`) | `@export amount` default 10 | `loot_drop.gd:7,59-60` |
| Sea cleaning, per rubbish | **+1 gold per rubbish** (`add_gold(amount)`) | `game_state.gd:706-712` |
| Pet duel first clear | `gold` 25/45/70/100/150 | `pet_battle_db.gd:19,34,49,64,79`; `game_state.gd:674-677` |
| Sell wood | `price * qty` = 4g each | `item_db.gd:214`, `game_state.gd:245-250` |
| Expedition loot banked | sum of `expedition.gold` | `game_state.gd:930` |

`enemy.gd:403` computes the drop: `maxi(1, gold_reward + rng.randi_range(-2, 4))`
— i.e. ±2/‑+4 variance, never below 1. Bosses get `gold_reward = 0`
(`dungeon.gd:301`) because the portal-completion reward replaces it.

### 2.3 Diamond sources

| source | amount | file:line |
|---|---|---|
| New game | 12 | `game_state.gd:91` |
| Portal completion first/repeat | 8→55 / 3→24 | `portal_db.gd:25,26,…`, `game_state.gd:976` |
| Monster random drop | `diamond_chance = 0.09 + level*0.01` per kill | `dungeon.gd:282` |
| LootDrop (`kind=="diamond"`) | `amount` | `loot_drop.gd:61-62` |

Bosses get `diamond_chance = 0.0` (`dungeon.gd:302`). There is **no**
diamond purchase and no diamond sell — the only sink is the house.

### 2.4 Gold sinks

| sink | amount | file:line |
|---|---|---|
| `buy_item` | `item.price` (90/240/100/260/92/245/75/210/60/180/25/20/15) | `game_state.gd:207-219` |
| `purchase_pet("moss")` | 140 | `pet_db.gd:27`, `game_state.gd:538-542` |
| `upgrade_pet` | **`45 + level*35`** → 80,115,150,185 (levels 1→4) | `game_state.gd:568` |

### 2.5 Diamond sinks

Only `upgrade_house()`: `HouseDB.upgrade_cost(level)` = 8, 18, 32, 54 diamonds to
reach levels 2-5 (`house_db.gd:18,25,33,41`; enforced `game_state.gd:818-821`).
Total to max the house: **112 diamonds**.

### 2.6 Shop filtering per hero

The equipment counter is filtered by the *active hero's weapon style*, and the
filter runs in the UI, not in the DB:

- `shop_panel.gd:44` — `for item_id in ItemDB.equipment_for_style(GameState.character_weapon_style())`
- `item_db.gd:248-256` — keeps items whose `style` is empty or equal; so armour
  (`style` absent) and shields are shown to **every** hero, weapons only to their
  style.
- `shop_panel.gd:45-46` — hides a 0-price starter the player already owns, so the
  "Buy" button never appears for `rusty_sword`/`smith_hammer`/`reed_bow`.
- `shop_panel.gd:111-128` — equipment rows show **Buy** if unowned, **Equipped**
  if in the slot, **Equip** otherwise. There is no "sell equipment" path.
- Only `wood` is sellable and only at the equipment counter (`shop_panel.gd:49-50`,
  hardcoded); `GameState.sell_item` would accept any `sellable:true` item but no
  other item has it (`item_db.gd:219` is the only `"sellable": true`).

**Equip transaction.** `GameState.equip_item` enforces the same discipline rules as
the shop, so the UI filter is a convenience, not the security boundary
(`game_state.gd:337-355`): rejects non-equipment (`:338`), unowned (`:340`),
missing `slot` (`:344`), and — the important one — a `style` that does not match
the active hero's `weapon_style` (`:346-348`). It then writes `equipped[slot]` and
emits `data_changed` (`:349-353`). There is **no** `unequip` transaction anywhere;
`remove_item` silently clears any slot holding the removed item
(`game_state.gd:282-287`), which is the only way a slot becomes empty.

`shop_type` is a plain String matched in a `match` block against
`"potion"`/`"equipment"`/`"pet"` (`shop_panel.gd:35-61`), set by
`open_shop(kind, keeper)` (`:20-28`) which also picks the title. Adding a fourth
shop means a new `match` arm plus a new `shop` value in `ItemDB`.

**Key asymmetry to know:** `sellable` defaults to **false** in the sale guard
(`game_state.gd:241`: `not bool(item.get("sellable", false))`), while its
counterpart `lost_on_defeat` is read only in the defeat path. So an item is
unsellable unless it explicitly declares `"sellable": true`.

## 3. Settlement system

### 3.1 What exists

The settlement is the `Lobby` node, built entirely in code — there is **no**
`lobby.tscn`; `Game._load_lobby()` does `Lobby.new()` (`scripts/game/game.gd:125-128`).
Map is `MAP_RECT := Rect2(0, 0, 64, 40)` in world units (`lobby.gd:6`), one unit =
32 px (`PixelArt.PX` scaling at `lobby.gd:90`).

**Editable objects** — every one is a `SettlementPlaceable` (group `"placeable"`,
`settlement_placeable.gd:13`) registered with the editor:

| object | `placeable_id` | `category` | `selection_size` | file:line |
|---|---|---|---|---|
| Cottage | `house` | `house` | 10.2 × 7.2 | `lobby.gd:302-309` |
| Potion stall | `shop_potion` | `shop` | 4.3 × 4.7 | `lobby.gd:387-391` |
| Equipment stall | `shop_equipment` | `shop` | 4.3 × 4.7 | same |
| Pet stall | `shop_pet` | `shop` | 4.3 × 4.7 | same |
| House/builder stall | `shop_house` | `shop` | 4.3 × 4.7 | `lobby.gd:383` |
| Gardens ×6 | `garden_1`…`garden_6` | `decoration` | 2.4 × 1.4 | `lobby.gd:929-938` |
| Fences ×4 | `fence_south/north/west/east` | `fence` | run length × 1.5 | `lobby.gd:952-955, 960-967` |
| Barrels/crates/signpost | `barrel_1`, `barrel_2`, `barrel_3`, `crate_1`, `crate_2`, `signpost` | `decoration` | 1.2×1.3 … 1.4×1.5 | `lobby.gd:751-753, 861-863` |

**Non-editable settlement content** (deliberately *not* placeables): resident
houses ×4 (`lobby.gd:841-844` — `Node2D` in group `"resident_house"`, only a
`SettlementTarget` child), animals ×7 (`lobby.gd:853-859`, group `"animals"`/`"horses"`),
12 `Resident` NPCs (`lobby.gd:877-888`), and all bush/grass/flower decor
(`_add_decor_sprite`, `lobby.gd:756-770`). Adding a *new* movable prop requires
`SettlementPlaceable` + `_placeables.append` + the editor registration loop
(`lobby.gd:1177-1178`).

### 3.2 Snap / clamp bounds

Two different rectangles exist and **the exported default is dead**:

- `settlement_editor.gd:5` — `@export var building_area := Rect2(18.8, 13.8, 26.8, 16.2)`
- `lobby.gd:1175` — `building_area = Rect2(18.2, 13.0, 27.4, 17.4)` ← the one actually used

So the live drag area is x ∈ [18.2, 45.6], y ∈ [13.0, 30.4].

Clamp rule (`settlement_editor.gd:106-120`):
```
target = world_pos - grab_offset
half   = selection_size * 0.5
min_x  = area.position.x + half.x ;  max_x = area.end.x - half.x
min_y  = area.position.y + half.y ;  max_y = area.end.y - half.y
target.x = snappedf(clampf(target.x, min_x, max_x), 0.25)
target.y = snappedf(clampf(target.y, min_y, max_y), 0.25)
```
Grid snap is **0.25 world units** (`:118-119`) — i.e. 8 px at 32 px/unit. If the
object is wider than the area the code collapses min/max to the area centre
(`:112-117`) rather than failing. Clamp keeps the *whole* selection box inside the
area, so a 10.2-wide cottage can only travel x ∈ [23.3, 40.5].

Hit-testing is reverse-order over `placeables` (`:135-140`), so the most recently
registered object wins when boxes overlap; `contains_world` is an axis-aligned
box test in local space (`settlement_placeable.gd:36-38`) — no rotation support.

### 3.3 Persistence

Saved under the single key `settlement_layout` (`game_state.gd:126`), a
Dictionary `placeable_id -> [x, y]` (Array, not Vector2 — JSON-safe):

- read: `placeable_position(id, fallback)` — falls back if the key is missing or
  the value is not a 2-element Array (`game_state.gd:1063-1070`)
- write: `set_placeable_position(id, pos)` → `layout[id] = [pos.x, pos.y]`, then
  `_save_if_needed()` + `data_changed` (`game_state.gd:1073-1078`)
- written **only on drag release**, via `_finish_drag()` → 
  `GameState.set_placeable_position(...)` (`settlement_editor.gd:127-132`).
  A drag abandoned by scene change or alt-F4 is not saved.
- type-guard on load: `if not (data.get("settlement_layout", {}) is Dictionary): data.settlement_layout = {}`
  (`game_state.gd:1237-1238`)

Every placeable's spawn position is `GameState.placeable_position(id, default)`,
e.g. `lobby.gd:307` (house), `:392` (shops), `:935` (gardens), `:965`/`:993`
(fences), `:782` (decor) — so persistence is uniform and automatic for new props
if you follow the same pattern.

House position also drives the player spawn and recovery centre:
`_player_spawn = _house_position + Vector2(0, 2.9)` (`lobby.gd:312`),
`_recovery_center = _house_position + Vector2(0, 2.3)` (`:313`) — moving the
cottage moves the respawn point and the healing ward with it.

### 3.4 Enter / exit

- Entry: HUD build button → `hud.build_mode_requested` → `Game.toggle_build_mode()`
  (`game.gd:61`, `:278-286`).
- Gates, in order (`game.gd:279-284`): must be in `Lobby`; then refuse if
  `_input_locked` **or** `hud.any_modal_open()` **or** `GameState.recovery_active()`
  **or** `GameState.emergency_active()`.
- `Lobby.toggle_build_mode()` → `editor.toggle()` → `active = not active`
  (`lobby.gd:1181-1184`, `settlement_editor.gd:29-35`).
- `_enter()` (`:38-44`): sets `player.controls_locked = true`, toasts the
  instruction, `set_process(true)` (draws the area).
- `_exit()` (`:47-53`): finishes any in-flight drag, then unlocks the player
  **only if `not player.dead`**, `set_process(false)`.

### 3.5 What happens to in-flight gameplay while editing

Only the **player's controls** are locked — the tree is never paused:

- no `get_tree().paused`, no `Engine.time_scale`, no `process_mode` change
  (verified: `settlement_editor.gd:38-53` touches only `controls_locked` and
  `set_process`).
- enemies keep pathing and attacking, the rubbish system keeps spawning
  (`rubbish_system.gd:47-56` runs on `_process`), residents keep walking, the
  emergency damage tick keeps running (`game.gd:37-48`), and the recovery heal
  keeps ticking (`lobby.gd:1071-1073`).
- the editor swallows mouse/touch in `_unhandled_input` and calls
  `set_input_as_handled()` (`:61-85`), so clicks cannot reach the world beneath.
- because `Game.toggle_build_mode` refuses to *enter* during an emergency, the
  editor cannot be opened mid-raid; but an emergency *starting* while the editor
  is open is not blocked — nothing closes the editor, and the player stays
  control-locked while raiders attack.

## 4. Village defence + forest

### 4.1 Raid trigger

The raid is driven entirely by `Game._process` and fires **only while the player
is inside a dungeon**:

```
if world is Dungeon and GameState.expedition_active():
    if not _emergency_triggered:
        _portal_elapsed += delta
        if _portal_elapsed >= EMERGENCY_DELAY:   # 14.0 s
            _emergency_triggered = true
            GameState.start_emergency(3)
    if GameState.emergency_active():
        _settlement_damage_accum += delta
        if _settlement_damage_accum >= SETTLEMENT_DAMAGE_TICK:  # 5.0 s
            _settlement_damage_accum = 0.0
            GameState.damage_settlement(5)
```
`game.gd:37-48`, constants at `game.gd:19-20`. So: **14 s after entering a
portal**, a 3-monster raid begins at home, and the settlement takes **+5 damage
every 5 s** for as long as the player stays in the dungeon. `_portal_elapsed`,
`_emergency_triggered` and the accumulator are reset in `enter_portal()`
(`game.gd:170-173`) and `return_to_lobby()` (`:179-182`).

`GameState.start_emergency(monster_count=3)` sets `emergency_active=true`,
`emergency_monsters=max(1,count)`, `emergency_damage=0`, saves, and emits
`emergency_changed(true, count, 0)` plus a "EMERGENCY!" toast
(`game_state.gd:1093-1102`). It is a no-op if one is already active (`:1094-1095`).

### 4.2 Spawn counts and placement

`Lobby._on_emergency_changed(active, remaining, damage)` → `_spawn_emergency_monsters(remaining)`
(`lobby.gd:1105-1107`). Spawner (`lobby.gd:1116-1149`):

- **guard**: returns immediately if `_emergency_monsters.size() > 0` (`:1117-1118`)
  — no stacking across re-entries.
- **count** = `maxi(1, count)` = whatever `emergency_monsters` holds (3 from the
  Game trigger).
- **6 fixed spots**, cycled: `(12.2,25.8)` sea, `(16.2,29.0)` beach,
  `(46.8,25.2)` forest, `(45.8,18.0)` forest trail, `(24.0,24.2)`, `(41.5,23.4)`,
  each with ±0.7 x-jitter, no y-jitter (`:1119-1139`).
- **raider stats** (`:1129-1138`): `kind="raider"`, `settlement_mode=true`,
  `max_hp=60`, `damage=9`, `speed=1.75`, `xp_reward=10`, `gold_reward=12`,
  `diamond_chance=0.0`, `body_radius=0.42`.
- **forest top-up** (`:1142-1149`): a raid also reinforces the woodland — if the
  live forest-monster count is under 11, spawn `min(3, 11 - live)` more. Comment at
  `:1142-1143` states these attack trees and do **not** count toward the emergency
  kill quota.

### 4.3 Defender / resident behaviour

`Resident` (`resident.gd`) has an exported combat block: `combat_enabled=false`,
`combat_damage=8`, `combat_range=4.2`, `combat_interval=1.15` (`:12-15`).
Per-frame (`:53-65`): `if emergency_active() and combat_enabled: _fight()` else
`_move_route()`. So passive residents never fight; they flee.

- `_fight` (`:68-92`): acquires `_nearest_raider(10.0)` — only nodes in group
  `"enemies"` with `settlement_mode == true` (`:115-125`). Out of range: closes at
  `delta * 2.4` per second. In range and `_attack_timer <= 0`: sets
  `_attack_timer = combat_interval`, deals `combat_damage` via
  `enemy.take_damage(...)` (`:78-80`).
- `_move_route` (`:95-112`): target is `shelter` when frightened, else the current
  waypoint; flee speed `3.2` vs patrol `speed` (default 0.9). From `:3-4`: "During
  an emergency the resident drops their routine and runs for shelter."
- `take_attack_damage(amount)` (`:162-168`): **ignores the amount entirely** —
  residents cannot die; it only flips `_frightened` and toasts "X joins the village
  defence!" (combat) or "X is in danger!" (passive).
- Townsfolk are `add_to_group("settlement_target")` (`:28`), so raiders can and do
  pick them as targets.

The 12 residents are placed in `lobby.gd:877-888`. Four are combat-enabled:
`Rami` (carpenter, default 8 dmg / 4.2 range, `:879`), `Daud` (woodcutter, 8/4.2,
`:880`), `Tomas` (defender, **11 / 4.8**, `:884`), `Sora` (defender, **11 / 4.8**,
`:885`). The `_add_resident` signature is
`(name, role, activity, start, points, shelter, combat=false, damage=8, distance=4.2)`
(`:1030`).

### 4.4 Building damage model

Two **separate, unrelated** damage channels:

1. **Abstract settlement damage counter** — `SettlementTarget.take_attack_damage(amount)`
   (`settlement_target.gd:17-21`) requires an active emergency, computes
   `damage = maxi(1, round(amount * damage_scale))` with `damage_scale` default
   **0.35** (`:7`), and calls `GameState.damage_settlement(damage)`.
   `damage_settlement` accumulates into `emergency_damage`, clamped **0…100**
   (`game_state.gd:1105-1110`). Targets and their scales: the cottage
   `damage_scale = 0.5` (`lobby.gd:341-344`), all four shop stalls at the default
   `0.35` (`lobby.gd:404-408`), all four resident houses at `0.25`
   (`lobby.gd:911-916`).
2. **Per-tree health** — `ForestTree.take_attack_damage` (`forest_tree.gd:35-49`)
   subtracts `maxi(1, amount)` from its own `health`, persists to
   `GameState.forest_health[tree_id]`, and `_fell()`s at 0. It never touches
   `emergency_damage`.

`emergency_damage` is **purely cosmetic**: `Lobby._apply_emergency_damage`
(`lobby.gd:1159-1169`) converts it to `severity = clamp(damage/100, 0, 0.55)`,
darkens the cottage sprite and shop stalls toward red, and toggles the cottage
fire marker. Nothing is destroyed, no building is removed, no gameplay value is
lost, and the counter can never reach a fail state. The fire marker is a real
node — a spark icon parented to the cottage, created hidden
(`lobby.gd:345-352`) and shown while `damage > 0 and emergency_active()`
(`:1166-1167`). Damage resets to 0 only on the next `start_emergency`
(`game_state.gd:1098`) — `register_emergency_kill` does **not** clear it.

Because damage never gates anything, `emergency_damage` is effectively a raid
scoreboard: 3 raiders hitting the cottage for 9 each apply
`round(9*0.5)=5` per hit, so the 0…100 clamp is reached in 20 cottage hits.

### 4.5 The invulnerable-tree rule

Only nodes created by `Lobby._add_tree()` (`lobby.gd:653-704`) are damageable.
They are `ForestTree` instances, added to groups `"settlement_target"` **and**
`"forest_tree"` (`forest_tree.gd:21-22`), and enemies only ever look at the
`forest_tree` group (`enemy.gd:308`).

Every other "tree"/plant in the world is a bare `Sprite2D` from
`_add_decor_sprite()` (`lobby.gd:756-770`) — bushes, grass tufts, flowers
(`lobby.gd:724-749`). Those carry no group and no `take_attack_damage`, so they
are permanently invulnerable and cannot be felled. `_add_decor_placeable` props
(`:773-792`) are likewise indestructible even though they are editable.

Tree stats: `max_health = 100 + (_tree_serial % 3) * 15` → **100 / 115 / 130**
(`lobby.gd:657`), so the values cycle with creation order. `health` is persisted
per `tree_id = "forest_%d" % _tree_serial` (`:656`), restored in
`ForestTree._ready()` from `GameState.forest_tree_health(...)` (`forest_tree.gd:23`),
and re-saved on every hit (`:40-41`). A tree already at 0 health on load starts
pre-felled (`forest_tree.gd:25-26, 111-121`).

### 4.6 Monster aggro / line of sight

`Enemy._physics_process` picks a target by mode (`enemy.gd:129-134`):
`forest_mode → _update_forest_target()`, `settlement_mode → _choose_settlement_target()`,
else the player.

Aggro radius (`enemy.gd:141`): `14.0` if settlement, `8.5` if boss, else `6.2`.
Outside that radius the enemy decelerates; there is **no** de-aggro timer.

- **Forest targeting** (`:272-290`): if `_can_see_player()` → target player, and
  the **first** sighting plays `aggro` SFX and starts a charge (`:278-282`). Once
  seen, the enemy keeps the player as target while
  `distance <= sight_range + 5.0` (`:286-288`). Otherwise it drops to
  `_nearest_forest_tree()`.
- **Line of sight is real, and only in forest mode** — `_can_see_player()`
  (`:293-302`) does a `PhysicsRayQueryParameters2D` raycast on collision mask
  **3** (layers 1+2), excluding self, from `y-0.55` to `y-0.55`, and requires the
  hit to be empty or the player. Combined with `sight_range = 11.5`
  (`lobby.gd:502`) this is the only LOS check in the codebase.
- **Settlement targeting** (`:318-332`) has **no** LOS and **no** range cap: the
  player wins if within `6.0`, otherwise the nearest node in `"settlement_target"`
  (best-distance starts at `9999.0`). Re-evaluated every physics frame.
- Other enemies (dungeon mobs, bosses) use **distance only** — the dungeon
  comment "Pillars break up line of sight" (`dungeon.gd:163`) is aspirational;
  pillars are physical colliders, not vision blockers.
- `_nearest_forest_tree()` caps its search at **22.0** units (`:307`).

### 4.7 Attack resolution and how the emergency clears

Attack dispatch (`enemy.gd:149-161`): when within `body_radius + 0.55`, wait for
`_attack_timer`, then reset it to `1.15` (boss) or the exported `attack_interval`,
and call `take_damage` if the target has it, **else** `take_attack_damage`
(`:157-160`). That is the whole polymorphism: players/pets implement
`take_damage`; trees/buildings/residents implement `take_attack_damage`.

Clearing: every settlement raider death calls `GameState.register_emergency_kill()`
(`enemy.gd:369`, inside the `settlement_mode` branch which also pays
`gold_reward` and toasts). `register_emergency_kill` (`game_state.gd:1113-1127`)
decrements `emergency_monsters`; at 0 it sets `emergency_active = false`, emits
`emergency_changed(false, 0, damage)` and toasts "The settlement is safe."
`Lobby._on_emergency_changed` then calls `_clear_emergency_monsters()`, which
`queue_free()`s every raider in `_emergency_monsters` and clears the array
(`lobby.gd:1152-1156`). Note the killed raiders were already fading out on their
own tween (`enemy.gd:389-392`), so a kill-driven clear and a quota-driven clear
race only cosmetically.

The alternate clear path is **game over**: if every `ForestTree` is felled,
`Lobby._check_forest_game_over()` calls
`GameState.trigger_game_over("All forest trees have fallen. The village is lost.")`
(`lobby.gd:465-473`, invoked from `_on_forest_tree_felled` at `:460-462` and
deferred once in `_ready` at `:67`).

## 5. Sea cleaning

### 5.1 Spawn

`RubbishSystem` (`rubbish_system.gd`): `@export spawn_interval := 8.5`,
`@export initial_delay := 3.0` (`:6-7`). `_ready` sets
`_timer = spawn_interval - initial_delay` (`:44`), so the **first piece appears
5.5 s** after the lobby loads, then one every **8.5 s**. Spawning is suppressed
while an emergency is active (`:50-51`) and while `guard` is null/invalid
(`:48-49`).

Lanes are 4 hardcoded `{"start","target","speed"}` dicts (`:17-38`), cycled
round-robin via `_lane_index % LANES.size()` (`:55`), starting at lane 0:

| lane | start | target | speed (units/s) |
|---|---|---|---|
| 0 | (4.0, 28.6) | (15.4, 26.1) | 0.72 |
| 1 | (4.6, 30.8) | (22.0, 33.0) | 0.62 |
| 2 | (4.2, 29.7) | (18.8, 29.0) | 0.80 |
| 3 | (4.6, 30.2) | (20.4, 31.2) | 0.68 |

`_rng.seed = 55123` (`:43`) is set but never used in this file — the lane cadence
is fully deterministic.

### 5.2 Catch vs beached — the race

`RubbishPiece._process` (`rubbish_piece.gd:33-46`) drifts toward `target` at
`speed` plus a `sin(_t*2.0)*0.06` lateral wobble, and tests in this order:

1. **beach** if `to_target.length() <= 0.22` → `_reach_beach()` (`:41-43`)
2. **caught** if `distance_to(guard) <= guard.catch_radius` → `_caught()` (`:45-46`)

`resolved` (`:10`) plus early returns (`:50-52`, `:60-62`) guarantee **exactly one**
outcome — the file header states "never both" (`:3-4`). But the beach check runs
first in the same frame, so a piece that arrives while inside the catch radius is
counted as beached, not caught.

Catch radius is `CoastalGuard.catch_radius := 2.4` (`coastal_guard.gd:6`); the
guard stands at `(11.2, 27.0)` (`lobby.gd:1053`).

### 5.3 The +1 gold rule

`on_rubbish_caught` (`rubbish_system.gd:67-71`): `caught_count += 1` then
`GameState.register_rubbish_cleaned(1)`.

`register_rubbish_cleaned(amount)` (`game_state.gd:706-712`):
```
data.sea_cleaned = int(data.get("sea_cleaned", 0)) + amount
add_gold(amount)
data_changed.emit(); _save_if_needed()
```
So the +1 gold is literally **the same integer as the rubbish count** — one gold
per piece, and `add_gold` clamps at 0 only. `sea_cleaned` is the persisted counter
(`game_state.gd:128`, default 0), guarded on load by
`data.sea_cleaned = maxi(0, int(...))` (`:1241`). `caught_count` /
`beached_count` on the system are **runtime-only** and reset with the scene.

### 5.4 Beached rubbish → monster

`on_rubbish_beached` (`rubbish_system.gd:74-87`) spawns an `Enemy` at
`piece.target`:

`kind="rubbish"`, `max_hp=30`, `damage=6`, `speed=1.35`, `xp_reward=5`,
`gold_reward=7`, `diamond_chance=0.0`, `body_radius=0.4` (`:77-86`), parented to
`get_parent()` (the Lobby) rather than the system node (`:87`).

This monster is **not** `settlement_mode` and **not** `forest_mode`, so per
`enemy.gd:129-134` it targets the player, with normal `6.2` aggro. On death
`enemy.gd:373-375` pays `gold_reward` (7) **again** via a dedicated
`if kind == "rubbish"` branch and toasts "Rubbish monster defeated". Because the
non-settlement branch at `:376` also runs `_spawn_reward()` for non-boss enemies,
a beached-rubbish kill pays both the direct 7 gold and a loot drop.

## 6. HUD/UI architecture

### 6.1 The scene is empty — every panel is code

`scenes/game.tscn` is 6 lines: one `Node2D` named `Game` carrying
`scripts/game/game.gd` (`scenes/game.tscn:5-6`). **Nothing from this slice is
instanced in any .tscn** — `Lobby`, `Dungeon`, `GameHUD` and all eight panels are
`new()`-ed at runtime. `GameHUD` is created in `Game._ready()`
(`game.gd:28-31`), the panels inside `GameHUD._build_modals()`
(`game_hud.gd:477-493`), and the world via `Lobby.new()` / `Dungeon.new()`
(`game.gd:125`, `:149`). Consequence: you cannot rearrange the UI in the editor —
every offset is a literal in GDScript.

### 6.2 Which panels are modals

All eight are `extends ModalBase`: `ShopPanel`, `InventoryPanel`, `PortalPanel`,
`PetBattlePanel`, `SeaCleaningPanel`, `HousePanel`, `VictoryPanel`, `DefeatPanel`
(`game_hud.gd:478-493`, each class header `extends ModalBase`). They are parented
to `HUDRoot` (`game_hud.gd:479-493`), not to a separate layer — so they share the
HUD's `CanvasLayer` at `layer = 10` (`game_hud.gd:67`).

Non-modal HUD widgets: `TutorialGuide` (a `PanelContainer`, `extends
PanelContainer`, `tutorial_guide.gd:2`), `MissionArrow`, `SegmentedBar`,
`TouchJoystick`, `TouchActionButton` — these are always-on HUD chrome.

### 6.3 `modal_base.gd` contract

`extends Control`, full-rect, `mouse_filter = MOUSE_FILTER_STOP` and
`visible = false` at `_ready` (`modal_base.gd:17-21`). Shell built once:
dim `ColorRect` (also `MOUSE_FILTER_STOP`, `:25-29`), centred `PanelContainer`
sized to `_panel_size` clamped to the viewport minus 32 px with floors of
320×300 (`:33-42`), header with title + a `Close` button wired to `close_panel`
(`:49-58`), a `divider`, then a `ScrollContainer` → `content: VBoxContainer`
(`:60-68`).

Lifecycle:
- `open_panel(title)` → set title, `visible = true`, `move_to_front()`,
  **`await get_tree().process_frame`**, then `_rebuild()` (`:71-81`). The await is
  required: `_rebuild()` measures layout. Subclasses override `_rebuild()` and
  usually call `_clear_content()` first.
- `close_panel()` → `visible = false`, `_clear_content()` (queue_free all
  children), `closed.emit()` (`:84-87`).
- `ui_cancel` (Esc) closes the topmost visible modal and marks input handled
  (`:113-118`).
- `_clear_content` uses `queue_free()`, **not** immediate free, so children from
  the previous rebuild are still in the tree for the rest of the frame — a
  rebuild twice in one frame can briefly hold two generations of rows.

Each subclass overrides `_panel_size` **before** `super._ready()` (e.g.
`pet_battle_panel.gd:49-50` = 920×640, `house_panel.gd:7-8` = 900×660,
`inventory_panel.gd:6-7` = 900×650); the base default is 860×590
(`modal_base.gd:13`).

### 6.4 Input blocking and "pause"

There is **no pause anywhere in the UI layer**. Blocking works by three
independent mechanisms:

1. `ModalBase.mouse_filter = MOUSE_FILTER_STOP` + the full-screen dim rect —
   swallows mouse/touch.
2. `Game._input_locked = true` then `_apply_input_lock()` sets
   `player.controls_locked` (`game.gd:222-226`). Every `open_*()` in `Game` does
   this (`:230-275`).
3. `Game._on_modal_closed()` — connected to every panel's `closed` signal
   (`game.gd:52-59`) — re-checks `hud.any_modal_open()` and only then unlocks
   (`:215-219`), so closing one of two stacked modals does not release the
   player.

The world keeps simulating behind every modal: enemies path and attack, the
emergency timer ticks, the rubbish system spawns. Confirming this: `Game._process`
has no early-out for modals (`game.gd:37-48`), and no panel sets
`process_mode`. Opening a shop while a raid is running means the player is
control-locked and being attacked.

`Game.toggle_build_mode` is the single place that refuses to open when
`_input_locked or hud.any_modal_open() or GameState.recovery_active() or
GameState.emergency_active()` (`game.gd:282-284`). The other `open_*` helpers have
no such guard — only `if world is Dungeon: return` (`:231-232`, `:239-240`,
`:247-248`, `:255-256`, `:263-264`). `open_inventory` additionally refuses if
`_input_locked` unless the inventory is already visible (`:271-272`).

### 6.5 Touch vs keyboard dual-binding

The strategy is **one InputMap, two producers**. Gameplay never checks for touch
events; it only polls `Input` actions.

- `TouchJoystick` computes a vector then calls
  `Input.action_press("move_left"/"move_right"/"move_up"/"move_down", strength)`
  (`virtual_joystick.gd:87-91`), and `Input.action_release(...)` for all four on
  `_end()` (`:94-96`). Header comment: "writes into the same InputMap actions as
  WASD" (`:3`).
- `TouchActionButton` presses exactly one action on touch-down and releases it on
  touch-up (`touch_action_button.gd:57-69`), with `action` exported (`:6`).
- `GameHUD._process` polls `Input.is_action_just_pressed("open_inventory" |
  "toggle_build" | "use_health_potion" | "use_mana_potion")`
  (`game_hud.gd:535-542`), which the corresponding touch buttons satisfy by
  synthesising the press (`game_hud.gd:341-397`).
- Both widgets take `MOUSE_FILTER_STOP` + `FOCUS_NONE` and consume the event
  (`accept_event()` / `set_input_as_handled()`), and each has both an
  `_gui_input` path and an `_input` path — the `_input` fallback exists because a
  drag that leaves the control stops delivering `_gui_input`.
- Deadzone on the stick is `0.14` (`virtual_joystick.gd:8`) after normalisation,
  radius clamped to `min(radius, size.x*0.5 - 8)` (`:64`).

The trap: `Input.action_press` is **global state**. Any code path that frees or
hides a `TouchActionButton` mid-press without going through `_release()` leaves
that action stuck down — hence `cancel()` (`touch_action_button.gd:79-81`) and the
blanket `_release_actions()` (`virtual_joystick.gd:94-96`).

Button geometry is hardcoded in `_build_controls` (`game_hud.gd:313-397`): joystick
190×190 bottom-left (`:314-321`), Strike d=102 at bottom-right (`:323-330`),
Use d=82 stacked above it (`:332-339`), Pack/Build d=64 at (24,160)/(96,160)
(`:341-357`), HP d=58 (`:359-366`), MP d=58 (`:379-386`), plus `_hp_count` /
`_mp_count` labels at hand-tuned offsets (`:367-377`, `:387-397`).

### 6.6 Panel ↔ GameState data flow (who calls whom)

Strict one-way ownership: **UI reads GameState, GameState never knows about UI**.
The wiring is:

- Panels subscribe in `_ready` to `GameState.data_changed` (and/or `pet_changed`,
  `house_changed`) and call `_rebuild()` **only if `visible`**:
  `shop_panel.gd:12-17`, `portal_panel.gd:11-13`, `house_panel.gd:9-14`,
  `inventory_panel.gd:8-10`, `pet_battle_panel.gd:51-53` (with an extra
  `and not _battle_active and not _result_visible` guard so a mid-duel data change
  does not wipe the battle screen).
- `GameHUD` subscribes once for the always-on chrome:
  `data_changed → refresh_all`, `pet_changed → _refresh_pet`,
  `boss_health_changed → _on_boss_health`, `expedition_changed → _refresh_loot`,
  `emergency_changed → _on_emergency_changed` (`game_hud.gd:83-87`).
- Mutations go **UI → GameState** by direct call, always returning
  `{"ok": bool, "message": String}` and the UI toasting on failure:
  `GameState.buy_item(item_id)` (`shop_panel.gd:116`), `equip_item` (`:125`),
  `sell_item` (`:158`), `purchase_pet` (`:205`), `upgrade_pet` (`:242`),
  `feed_pet` (`:236`), `upgrade_house` (`house_panel.gd:62`),
  `complete_pet_battle` (`pet_battle_panel.gd:420`).
- World → panel is via **Game as router**: `ShopNPC.interact` →
  `game.open_shop(type, name)` (`shop_npc.gd:40-41`), `PortalEntrance.interact` →
  `game.open_portals(portal_id)` (`portal_entrance.gd:87-88`),
  `CoastalGuard.interact` → `game.open_sea_cleaning()` (`coastal_guard.gd:32-35`),
  `ShopNPC.interact` with `shop_type=="house"` → `game.open_house()`
  (`shop_npc.gd:36-39`). The world never touches a panel directly; it looks up
  `get_tree().get_first_node_in_group("game")` and `call()`s by name string.
- Panels → world: only three reverse calls exist — `open_portals` /
  `open_shop`'s counterpart `game.enter_portal(portal_id)` from
  `portal_panel.gd:78-82`, and `game.return_to_lobby(true)` from
  `victory_panel.gd:59-63` and `defeat_panel.gd:32-36`.

Because the world→panel direction is string-based `has_method`/`call`, a renamed
Game method fails **silently** (the `if game.has_method(...)` guard just skips).

### 6.7 Refresh patterns

- Full rebuild on any `data_changed`: `_clear_content()` + regenerate every row
  (§6.3). Cheap because panels are small, but it destroys scroll position and
  any in-progress focus on every gold change — including the 1-gold sea-cleaning
  drip, which fires `data_changed` ~every 8.5 s while a shop is open.
- Two throttled pollers in `GameHUD._process`: loot label every **0.25 s**
  (`game_hud.gd:523-526`), mission arrows every **0.2 s** (`:527-530`).
- `_refresh_objectives` diffs the joined string before rebuilding to avoid
  churn: `if joined == _last_objectives: return` (`:625-630`).
- `_update_prompt` only touches the label when the prompt text actually changes
  (`:552-555`).
- `SegmentedBar.set_values(v, max)` is the universal bar API; `MissionArrow.aim(from,to)`
  the universal compass API.

### 6.8 Dead UI surface (verified)

- `GameHUD.show_toast()` is a **no-op** (`game_hud.gd:692-695`) and is never
  called. `GameState.toast_requested` has **45 `.emit()` sites and zero
  `.connect()` sites** across `scripts/` — every notification in the game is
  silently discarded.
- `GameHUD._update_mission_guide` needs `world.get_guidance_targets()`
  (`game_hud.gd:243-244`), which **no class defines** — so `_mission_panel` is
  permanently hidden and the three `MissionArrow`s never render.
- `Lobby.get_map_rect` / `minimap_base_color` / `minimap_markers`
  (`lobby.gd:1189-1203`) and the identical `Dungeon` trio (`dungeon.gd:365-375`)
  are defined but called from nowhere — there is no minimap in the HUD.
- `VictoryPanel.show_victory` computes `var def := PortalDB.get_portal(portal_id)`
  and never uses it (`victory_panel.gd:17`), then recomputes it in `_rebuild`
  (`:23`).

## 7. Pet duel system

### 7.1 Where it lives

It is a **panel, not a scene**: `PetBattlePanel extends ModalBase`
(`pet_battle_panel.gd:1-2`), `_panel_size = Vector2(920, 640)`
(`:49`), opened from the `PetBattlePortal` gate by
`PortalEntrance.interact` → `game.open_pet_battles()` → 
`hud.pet_battle_panel.open_pet_battles()` (`portal_entrance.gd:83-86`,
`game.gd:254-259`). No `Node2D` arena, no physics, no pet scene involvement — the
duel is pure state + labels inside the modal.

`open_pet_battles()` resets `_battle_active`, `_battle_resolved`,
`_result_visible`, `_last_result`, `selected` (`:56-62`) before opening, and
`close_panel()` resets them again plus `_turn_active`/`_awaiting_next`
(`:464-470`) — a deliberate belt-and-braces reset so a duel cannot resume after
closing.

### 7.2 Turn timing — the 2-second window

```
_begin_turn():  _player_choice = ""; _enemy_choice = _choose_enemy_skill()
                _turn_timer = 2.0; _turn_active = true; re-enable skill buttons
_process()   :  _turn_timer -= delta; when <= 0 → _resolve_turn()
```
`pet_battle_panel.gd:179-195`, `:162-176`, timer value at `:184`.

- The **enemy commits first**, at the top of the turn (`:183`), before the player
  has chosen.
- The player may lock a choice any time in the window via `choose_skill`
  (`:198-211`), which disables all three buttons and refuses a second choice
  (`:201-202`). Waiting out the window without choosing defaults the player to
  `attack` (`:218`).
- After resolution the next round starts after a fixed **0.9 s** pause
  (`_awaiting_next`/`_next_turn_timer`, `:250-257`).
- `_process` is a no-op unless the panel is visible, the battle is active and not
  resolved (`:163-164`) — so a hidden panel freezes the duel rather than letting
  it run in the background.

### 7.3 Skill resolution — true simultaneity

`_resolve_turn` (`:214-257`) computes **both** deltas from the pre-turn HP, then
applies both, which is what makes the exchange simultaneous rather than ordered:

```
player_action = _player_choice if _player_choice != "" else "attack"
enemy_action  = _enemy_choice  if _enemy_choice  != "" else _choose_enemy_skill()
player_damage = _player_damage if action=="attack" else 0
enemy_damage  = _enemy_damage  if action=="attack" else 0
if player_action == "guard": enemy_damage  = ceil(enemy_damage  * 0.35)
if enemy_action  == "guard": player_damage = ceil(player_damage * 0.35)
player_heal = max(8, round(_player_max  * 0.16)) if recover else 0
enemy_heal  = max(8, round(_opponent_max * 0.16)) if recover else 0
_opponent_hp = clampi(_opponent_hp - player_damage + enemy_heal, 0, _opponent_max)
_player_hp   = clampi(_player_hp   - enemy_damage  + player_heal, 0, _player_max)
```
There is no priority order, no speed stat, no dodge. Guard applies **before** the
heal is added, and a guard turn deals 0 damage because damage is already 0 for
any non-attack action.

### 7.4 The formulas

| quantity | formula | file:line |
|---|---|---|
| player max HP | `PetDB.max_health(pet_id, level)` = `hp + (lvl-1)*12` | `pet_battle_panel.gd:149` |
| player damage | `PetDB.attack_damage(...) + 3` — **+3 is a panel-only buff** | `:153` |
| enemy max HP | `def.hp` (42/58/76/96/124) | `:151` |
| enemy damage | `def.damage` (5/7/9/11/14) | `:154` |
| guard | incoming damage × **0.35** then `ceil` (65 % reduction) | `:222-225` |
| recover | `max(8, round(max_hp × 0.16))` (16 %, floor 8) | `:226-227` |
| turn window | **2.0 s** | `:184` |
| inter-turn pause | **0.9 s** | `:255` |

The enemy AI (`_choose_enemy_skill`, `:260-271`) is a fixed cascade:
`hp<=30% → recover with p=0.58`; else `hp<=55% → guard with p=0.45`; else
`roll<0.58 attack, <0.84 guard, else recover`. `_rng.seed = 4471 + level_id.hash()`
(`:156`) makes each duel's enemy choices deterministic across runs.

### 7.5 Level-up guarantee

`_finish_battle(won)` calls `GameState.complete_pet_battle(_battle_level)` on a
win (`:420`). That function (`game_state.gd:668-703`) pays `gold` only on the
first clear (`:674`) and grants `xp` at 25 % on repeats (`:675`), then
**force-levels** the pet one level if XP alone did not level it:

```
levels = _give_pet_xp(pet, xp_reward)
if levels == 0 and int(pet.get("level",1)) < PetDB.MAX_LEVEL:
    pet.level += 1; pet.hp_max = PetDB.max_health(...); pet.hp = hp_max; pet.xp = 0
```
`game_state.gd:679-690` — the comment at `:682` states the rule: "A duel victory
always gives at least one companion level." At `MAX_LEVEL` the guarantee is
skipped (`:683`), and the panel then says "wins the duel at maximum level"
(`pet_battle_panel.gd:435`).

Losing or forfeiting costs nothing: `_forfeit` sets a local result dict only
(`:399-407`), and a loss produces `{"ok": false, "message": "Your companion
yields..."}` (`:422`). The real pet's HP is untouched because the duel starts at
`_player_hp = _player_max` (`:150`) and writes nothing back.

**Gate to enter** is `GameState.pet_battle_clear_reason(level_id)` (checked twice:
in the card at `:120` and again in `start_battle` at `:134-136`), which requires
`pet.level >= def.pet_level` and an alive pet (`game_state.gd:660-665`).

## 8. Tutorial

**Eight steps**, in this order, defined as a `const STEPS: Array[Dictionary]`
with `{title, text}` per entry (`tutorial_guide.gd:12-45`):

1. `Move` — joystick or WASD (`:13-16`)
2. `Combat` — Strike / F, per-hero weapon behaviour (`:17-20`)
3. `Automatic collection` — walk over loot, no collect button (`:21-24`)
4. `Shops` — merchant + Use / E (`:25-28`)
5. `House upgrades` — Bram, diamonds only (`:29-32`)
6. `Companions` — feed and upgrade, never dies permanently (`:33-36`)
7. `Portals` — 10 boss levels + 5 pet duels (`:37-40`)
8. `Village defence` — raiders while you are inside a portal (`:41-44`)

**Progress tracking: none.** There is no event subscription, no "did the player
actually move/shop/fight" detection, and no persistence. `_step` is a plain int
(`:6`) advanced only by the Next button (`_advance`, `:97-103`). The only state
that survives a restart is `data.tutorial_seen` — and it is set by *Lobby*, not by
the tutorial: `Lobby._ready` sets `GameState.data.tutorial_seen = true` and saves
the moment the lobby loads (`lobby.gd:77-80`), i.e. at the same time the tutorial
is being displayed. So `tutorial_seen` means "the player reached the lobby once",
not "the player finished the tutorial".

**When it starts:** only on a brand-new game — `Game._on_character_selected` →
`hud.start_tutorial()` (`game.gd:83`) → `tutorial_guide.start()`
(`game_hud.gd:698-700`), which resets `_step = 0` and shows the panel (`:91-94`).
`_on_continue_requested` does **not** call it (`game.gd:86-95`), so a continued
save never sees the tutorial again.

**Blocking vs non-blocking:** deliberately non-blocking, per the class header
("intentionally non-blocking: the player can still move and fight while reading",
`:3-4`). It does not set `controls_locked`, does not pause, and does not join
`any_modal_open()`. It does set `mouse_filter = MOUSE_FILTER_STOP` on itself
(`:57`), so it eats pointer input inside its own 316×258 rect at the top-right
(`offset_left=-338, offset_right=-22, offset_top=184, offset_bottom=442`, `:53-56`)
— which is exactly where the touch Pack/Build buttons are **not**, but it does
overlap the vitals panel region below it.

**Skip:** a `Skip` button (`:83-85`) calls `_skip()` (`:106-108`), which just hides
the panel and emits a toast (which nobody receives — §6.8). Skip and Finish are
behaviourally identical apart from the message: both set `visible = false`, and
neither writes any save flag. Finishing emits "Tutorial complete..." (`:99-102`).

**Per-step rendering** (`_render`, `:111-116`) sets title, body, the `n/8` counter
and flips the Next caption to "Finish" on the last step. There is no Back button,
so the only ways back are restarting the tutorial (new game) or skipping.

## 9. Hardcoded magic numbers index

Grouped by system. Everything here is a literal in GDScript, not a resource or
config — this is the "where do I tune X" table.

### Player / hero (data, not code)
`character_db.gd` — HP 105/135/92, mana 45/28/65, atk +1/0/+1, def 0/+3/−1,
speed 4.4/3.9/4.6, attack_cooldown **0.38/0.64/0.55 s**, attack_range
**2.05/2.55/8.0**, attack_mult **1.0/1.35/0.95** (`character_db.gd:10-20`,
`:30-40`, `:50-60`).

### Enemies — dungeon
| number | value | file:line |
|---|---|---|
| monster count floor | `maxi(10, monster_count)` | `dungeon.gd:261` |
| monster HP | `38 + level*12 + i*2` | `dungeon.gd:277` |
| monster damage | `7 + level*2` | `dungeon.gd:278` |
| monster speed | `1.65 + level*0.12` | `dungeon.gd:279` |
| monster XP | `14 + level*5` | `dungeon.gd:280` |
| monster gold | `7 + level*3` | `dungeon.gd:281` |
| diamond chance | `0.09 + level*0.01` | `dungeon.gd:282` |
| boss monster_level | `level + 2` | `dungeon.gd:291` |
| boss attack interval | `1.15` (hardcoded, overrides export) | `enemy.gd:156` |
| aggro — boss / normal | `8.5` / `6.2` | `enemy.gd:141` |
| loot variance | `gold_reward + randi_range(-2, 4)`, floor 1 | `enemy.gd:403` |
| touch radius for melee | `body_radius + 0.55` | `enemy.gd:149` |

### Enemies — settlement / forest
| number | value | file:line |
|---|---|---|
| forest monster count | `8` initially | `lobby.gd:485` |
| forest monster level | `2` | `lobby.gd:500` |
| forest sight range | `11.5` | `lobby.gd:502` |
| forest attack interval | `0.62` | `lobby.gd:503` |
| forest HP / dmg / speed | `54` / `6` / `1.62` | `lobby.gd:504-506` |
| forest xp / gold / diamond | `9` / `6` / `0.0` | `lobby.gd:507-509` |
| forest body radius | `0.4` | `lobby.gd:510` |
| forest top-up ceiling | `11` live, `min(3, 11-live)` added | `lobby.gd:1148-1149` |
| raider HP / dmg / speed | `60` / `9` / `1.75` | `lobby.gd:1132-1134` |
| raider xp / gold | `10` / `12` | `lobby.gd:1135-1136` |
| raider body radius | `0.42` | `lobby.gd:1138` |
| settlement aggro | `14.0` | `enemy.gd:141` |
| player-priority radius | `6.0` | `enemy.gd:323` |
| tree search radius | `22.0` | `enemy.gd:307` |
| chase memory | `sight_range + 5.0` | `enemy.gd:286` |

### Village defence timing
| number | value | file:line |
|---|---|---|
| raid delay after entering a portal | `14.0 s` | `game.gd:19` |
| settlement damage tick | `5.0 s` | `game.gd:20` |
| damage per tick | `5` | `game.gd:48` |
| raiders per raid | `3` | `game.gd:43` |
| settlement damage cap | `0…100` | `game_state.gd:1108` |
| building damage scale | `0.5` cottage, `0.35` stalls, `0.25` resident houses | `lobby.gd:343`, `settlement_target.gd:7`, `lobby.gd:914` |
| cosmetic severity cap | `clamp(damage/100, 0, 0.55)` | `lobby.gd:1160` |
| tree HP | `100 + (serial%3)*15` | `lobby.gd:657` |

### Residents
patrol speed `0.9`, flee speed `3.2`, combat damage `8`, combat range `4.2`,
combat interval `1.15 s`, raider acquisition radius `10.0`, chase speed
`delta*2.4`, waypoint dwell `3.0 s` (`resident.gd:9-15`, `:69`, `:75`, `:101`,
`:110`). Defenders Tomas/Sora use `11` dmg / `4.8` range (`lobby.gd:884-885`).

### Recovery / sleep
| number | value | file:line |
|---|---|---|
| ward radius | `4.3` (const) → assigned to `RecoveryWard.radius` | `lobby.gd:43, 1067` |
| ward heal duration | **`8.0 s`** regardless of house tier | `lobby.gd:44, 1094` |
| `RecoveryWard.radius` default | `4.4` (overwritten) | `recovery_ward.gd:6` |
| sleep duration | `HouseDB.recovery_time(level)` = 10/8/6/4/2 s | `house_db.gd:10-42`, `house_bed.gd:34` |
| sleep prompt refresh | on `house_changed` | `house_bed.gd:24-26` |

### Sea cleaning
| number | value | file:line |
|---|---|---|
| spawn interval | `8.5 s` | `rubbish_system.gd:6` |
| initial delay | `3.0 s` (first piece at 5.5 s) | `rubbish_system.gd:7, 44` |
| lane speeds | `0.72 / 0.62 / 0.80 / 0.68` | `rubbish_system.gd:21,26,31,36` |
| catch radius | `2.4` | `coastal_guard.gd:6` |
| beach arrival threshold | `0.22` units | `rubbish_piece.gd:41` |
| gold per catch | `+1` (== count) | `game_state.gd:710` |
| beached monster HP/dmg/speed | `30 / 6 / 1.35` | `rubbish_system.gd:79-81` |
| beached monster xp/gold | `5 / 7` | `rubbish_system.gd:82-83` |

### Resource gathering
`ResourcePile`: `item_id="wood"`, `amount=2`, `cooldown=14.0 s`, interact radius
`1.7` (`resource_pile.gd:6-8, 17`). Three piles in the lobby at
`(5.0,21.4)`, `(12.0,26.4)`, `(18.2,31.1)` (`lobby.gd:517`) → up to 6 driftwood /
14 s → 24 gold when sold at 4 g each.

### Interactables
`Interactable.interact_radius` default `1.9` (`interactable.gd:7`); overridden
per type: portal gate `2.1` (`portal_entrance.gd:23`), portal exit `2.0`
(`portal_exit.gd:11`), coastal guard `2.2` (`coastal_guard.gd:12`), driftwood pile
`1.7` (`resource_pile.gd:16`), loot drop `0.9` with its own hardcoded pickup
distance `0.9` (`loot_drop.gd:17, 44`).

### Settlement editor
Drag area `Rect2(18.2, 13.0, 27.4, 17.4)` (`lobby.gd:1175`); dead export default
`Rect2(18.8, 13.8, 26.8, 16.2)` (`settlement_editor.gd:5`); snap step **0.25**
(`settlement_editor.gd:118-119`); editor `z_index = 900`, selection outline
`z_index = 950` (`settlement_editor.gd:18`, `settlement_placeable.gd:19`).

### Map coordinates
`MAP_RECT = Rect2(0,0,64,40)` (`lobby.gd:6`); lobby `SPAWN (34,24.3)`,
`HOUSE_BASE (34,21.4)`, `MONSTER_GATE (30.8,11.3)`, `PET_GATE (37.2,11.3)`
(`lobby.gd:7-10`); `RECOVERY_CENTER (34,23.7)` (`lobby.gd:42`); dungeon
`SPAWN (24,28)`, `map_rect Rect2(0,0,48,32)`, boss at `(24,7)`, exit at
`(24,30.1)` (`dungeon.gd:8, 12, 303, 312`).

### UI timing / sizing
Panel sizes 860×590 base (`modal_base.gd:13`), 920×640 pet duel
(`pet_battle_panel.gd:49`), 900×660 house (`house_panel.gd:7`), 900×650 inventory
(`inventory_panel.gd:6`); viewport margin 32 px (`modal_base.gd:35-36`); HUD loot
poll `0.25 s`, mission poll `0.2 s` (`game_hud.gd:524, 528`); fade in/out
`0.25 / 0.3` s lobby, `0.3 / 0.35` s dungeon (`game.gd:122, 136, 146, 159`);
joystick radius `72`, knob `30`, deadzone `0.14` (`virtual_joystick.gd:6-8`);
action button diameters `102 / 82 / 64 / 58` (`game_hud.gd:328, 337, 346, 355,
364, 384`).

### Economy tuning
`buy_item` debounce **280 ms** (`game_state.gd:197`); `upgrade_pet` cost
`45 + level*35` (**duplicated** at `game_state.gd:568` and `shop_panel.gd:238`);
inventory stack default `9` (`game_state.gd:22`); auto-heal ratios `0.10` /
`0.35` (`game_state.gd:24-25`); starting gold/diamonds `120` / `12`
(`game_state.gd:90-91`).

## Conventions observed

**1. Data tables are `const` + `static func` accessors, always deep-copied out.**
```gdscript
const ITEMS := { "rusty_sword": { ... }, ... }
static func get_item(item_id: String) -> Dictionary:
	return (ITEMS.get(item_id, {}) as Dictionary).duplicate(true)
```
`item_db.gd:9`, `item_db.gd:224-225`. The same shape at `portal_db.gd:6`/`:230`,
`pet_db.gd:6`/`:62`, `house_db.gd:5`/`:49`, `pet_battle_db.gd:6`/`:85`,
`character_db.gd:5`/`:69`. Never instantiate a DB; never mutate what a getter
returned.

**2. Panels refresh by full rebuild, triggered by a GameState signal, guarded by
`visible`.**
```gdscript
GameState.data_changed.connect(func() -> void:
	if visible:
		_rebuild())
```
`portal_panel.gd:11-13`; identical at `inventory_panel.gd:8-10`,
`house_panel.gd:9-11`, `shop_panel.gd:12-14`. `_rebuild()` always starts with
`_clear_content()` then re-adds rows.

**3. GameState is the single source of truth; UI and world only read it and call
its transactional methods.** Every mutation returns
`{"ok": bool, "message": String}` and the caller surfaces failure:
```gdscript
var result := GameState.buy_item(item_id)
if not result.ok:
	GameState.toast_requested.emit(str(result.message), "bad")
```
`shop_panel.gd:116-118`. Same at `:125-127`, `:158-160`, `:242-244`,
`house_panel.gd:62-64`, `inventory_panel.gd:74-76`.

**Naming.** `_snake_case` private members with a leading underscore; `@export var`
defaults carry the real value so a scene override is optional; `_build_*` prefix
for construction methods (`_build_house`, `_build_shops`, `_build_portals`,
`_build_forest`, `_build_controls`, `_build_modals`); `_on_<signal>` for handlers;
`_add_*` for helpers that append one child (`_add_shop`, `_add_tree`,
`_add_resident`, `_add_item_row`). Class-level docstring on line 2-5 of nearly
every file.

**Signal style.** GameState declares all cross-system signals and UI connects in
`_ready`; world objects emit nothing to UI directly — they `call()` Game as a
router (`shop_npc.gd:32-41`). UI-local signals are only `closed` (ModalBase),
`character_selected`/`continue_requested` (TitleScreen) and
`inventory_requested`/`build_mode_requested` (GameHUD).

## Gotchas / footguns

1. **The whole toast system is dead.** 45 `GameState.toast_requested.emit(...)`
   calls, **zero** `.connect()`, and `GameHUD.show_toast()` is an empty function
   (`game_hud.gd:692-695`). Purchases, "settlement is safe", "tutorial skipped",
   "3 more driftwood" — none of it reaches the player. Any feedback you add via
   toast will silently vanish.
2. **There is no pause.** Modals and the settlement editor lock
   `player.controls_locked` only. Enemies keep attacking, the raid damage tick
   keeps draining, the sea keeps spawning (`game.gd:37-48` has no modal guard).
   Opening a shop mid-raid is a control-locked death.
3. **`RECOVERY_SECONDS = 8.0` ignores the house tier.** `lobby.gd:1094` heals at
   `health_max / 8.0` per second, while `HousePanel` advertises 10→2 s and
   `house_bed.gd` uses `HouseDB.recovery_time` (`game_state.gd:830-831`). Two
   different recovery clocks; upgrading the cottage does nothing for the ward.
4. **`upgrade_pet` cost is duplicated.** `45 + level*35` in `game_state.gd:568`
   *and* `shop_panel.gd:238`. Change one and the button either lies or refuses a
   purchase the transaction would accept.
5. **`emergency_damage` is cosmetic and self-clearing only on the next raid.**
   `_apply_emergency_damage` only tints sprites and toggles the cottage fire
   marker (`lobby.gd:1159-1169`); nothing is destroyed and the counter can never
   fail the run. `register_emergency_kill` never resets it — it resets to 0 only
   in the next `start_emergency` (`game_state.gd:1098`), so a fresh raid starts at
   0 but the HUD keeps the previous raid's percentage until then.
6. **Tree health keys are positional.** `tree_id = "forest_%d" % _tree_serial`
   (`lobby.gd:656`) is assigned in creation order, and `_build_forest` consumes
   `_rng` on every placement (`:579-626`). Insert or remove a tree, or add one
   `_rng` call earlier, and every saved `forest_health` entry rebinds to a
   different tree — silently healing or felling the wrong ones.
7. **The exported `building_area` is dead.** `settlement_editor.gd:5` says
   `Rect2(18.8, 13.8, 26.8, 16.2)`; `lobby.gd:1175` overwrites it with
   `Rect2(18.2, 13.0, 27.4, 17.4)`. Editing the export changes nothing.
8. **Dictionary dot-access is unforgiving.** `def.name`, `def.lore`,
   `def.rewards_first` (`portal_panel.gd:54-63`), `next.benefit`, `next.cost`
   (`house_panel.gd:44-55`), `character.hp` (`title_screen.gd:110`). A missing key
   is a runtime error, not `null`. Every new DB record must carry the full key set
   every consumer touches — there is no schema.
9. **`item_db.stat_line` reads `item.effect[...]` on the item copy inside a loop
   over `item.get("effect", {})`** (`item_db.gd:273-280`) — fine today, but it
   means an item with `effect` but no matching branch renders nothing; and the
   `MAG` branch is unreachable because no item defines `magic`.
10. **`sellable` defaults to false, not true.** `game_state.gd:241` reads
    `item.get("sellable", false)`. Only `wood` declares `true` (`item_db.gd:219`),
    so newly added items are unsellable until you opt in.
11. **Shop filtering and equipping are two separate gates on the same rule.** The
    equipment counter only *renders* items whose `style` matches the active hero
    (`item_db.gd:248-256` + `shop_panel.gd:44`), and `GameState.equip_item` rejects
    a mismatched `style` again (`game_state.gd:346-348`). Two consequences: a
    weapon whose `style` matches no hero is invisible everywhere with no error,
    and a weapon missing `style` entirely passes both checks and is equipable by
    all three heroes (`:253` treats `""` as "any").
12. **`_icon_kind()` is copy-pasted.** `shop_panel.gd:254-272` and
    `inventory_panel.gd:119-136` are byte-identical. A new `kind` needs both
    edited or icons diverge between shop and bag.
13. **Two `data.gold` mutation styles coexist.** `add_gold` clamps to 0
    (`game_state.gd:178`) but `sell_item`, `purchase_pet`, `upgrade_pet` and
    `bank_expedition_loot` assign `data.gold = gold() ± x` directly
    (`:250`, `:542`, `:571`, `:930`). Only the affordability check prevents a
    negative balance; a caller that skips the check can go below zero.
14. **Rubbish monsters can pay twice.** `on_rubbish_beached` spawns an enemy that
    is neither `settlement_mode` nor `forest_mode`, so `enemy.gd:373-375` pays
    `gold_reward` directly **and** `:376-377` runs `_spawn_reward()` for a loot
    drop.
15. **`world.call("...")` with `has_method` guards fails silently.** Renaming
    `Game.open_shop` / `open_portals` / `open_house` / `open_sea_cleaning` /
    `enter_portal` / `return_to_lobby` (or `Lobby.toggle_build_mode`) breaks the
    feature with no error — e.g. `shop_npc.gd:40-41`, `portal_entrance.gd:87-88`,
    `victory_panel.gd:60-63`.
16. **`Lobby._ready` marks `tutorial_seen` immediately** (`lobby.gd:77-80`), before
    the player reads step 1 — so the flag means "reached the lobby", and the
    tutorial cannot be resumed after a restart.
17. **Panel rebuilds destroy scroll and hover state** on *any* `data_changed`,
    including the 1-gold sea-cleaning drip every ~8.5 s while a shop is open
    (`shop_panel.gd:12-14` + `rubbish_system.gd:69`).
18. **`_clear_content` uses `queue_free`**, so a rebuild with two `data_changed`
    emissions in one frame leaves the old rows alive until end of frame
    (`modal_base.gd:94-98`) — visually fine, but `get_children()` counts will
    lie during that frame.
19. **`CharacterDB.get_character` falls back to Qayyim for an unknown id**
    (`character_db.gd:73`) instead of returning `{}` — a typo'd character id
    silently loads the sword hero rather than failing.
20. **`main.tscn` is not the game.** `run/main_scene` is `scenes/game.tscn`
    (`project.godot:15`); `scenes/main.tscn` (4298 lines of props) is only
    referenced by `tools/convert.gd:38`, `tools/play_test.gd:10`,
    `tools/smoke_test.gd:9`.

## AGENTS.md candidate rules

1. Never write to `GameState.data` from a scene; call the transactional method and check its `{"ok"}`.
2. Add new content by appending to the `const` table in `scripts/data/*.db.gd`; never hardcode prices or stats in a panel.
3. Give every new `PortalDB` entry a matching id in `PortalDB.ordered_ids()` or it will never appear.
4. Keep `house_db.LEVELS` index-aligned with its `level` field — `get_level` and `next_level` index the array differently.
5. Return `{"ok": bool, "message": String}` from any new GameState transaction and surface failures at the call site.
6. Do not rely on `GameState.toast_requested` for player feedback until it is connected; it currently reaches nobody.
7. Do not add `get_tree().paused` to a modal or the settlement editor — the project has no pause concept and the raid tick assumes it.
8. Lock the player with `player.controls_locked` (plus `Game._input_locked`) when opening UI, and unlock only through `_on_modal_closed`.
9. Route world→UI interaction through `Game` with `has_method`/`call`, matching the existing `ShopNPC`/`PortalEntrance` pattern.
10. Prefer `Input.action_press`/`action_release` in touch widgets over direct method calls, so keyboard and touch share one code path.
11. Always release synthesised InputMap actions in `_release()`/`_end()`; a stuck action survives scene changes.
12. Call `super._ready()` first and set `_panel_size` *before* it in any `ModalBase` subclass.
13. Start every `_rebuild()` with `_clear_content()` and rebuild from GameState — never cache row state in the panel.
14. Use `.get(key, default)` on Dictionary records in UI; dot access errors the frame when a key is missing.
15. Declare `"sellable": true` explicitly on any item that should be vendorable; the default is unsellable.
16. Keep `_icon_kind()` in `shop_panel.gd` and `inventory_panel.gd` in sync when adding an item `kind`.
17. Never persist a node reference — persist ids/positions (`settlement_layout`, `forest_health`, `sea_cleaned`).
18. Assign stable, non-positional ids to anything persisted per-instance (see `forest_%d` drift).
19. Put tuning numbers in the relevant `const`/`@export` at the top of the owning file; do not bury literals in `_process`.
20. When a number is duplicated (pet upgrade cost), change both sites in the same commit or derive one from the other.
21. Use `HouseDB.recovery_time()` for anything that claims to scale with the cottage, and do not add a second hardcoded recovery duration.
22. New placeables must go through `SettlementPlaceable` + `_placeables.append` so the editor registers them and persistence works automatically.
23. Do not add `SettlementTarget` to decor — only buildings/residents are meant to soak emergency damage.
24. Treat `emergency_damage` as a display value, not a health pool; nothing is destroyed by it today.
25. Keep `scenes/game.tscn` minimal — all world and UI nodes are constructed in code and there are no scene hooks to wire.

## Open questions

1. **Is `main.tscn` still loadable?** It is only referenced by three tools
   (`tools/convert.gd:38`, `play_test.gd:10`, `smoke_test.gd:9`) and is not the
   run scene (`project.godot:15`). Whether it still builds against current
   `PixelArt` is unverified — would settle by running `godot --headless` on it.
2. **Does any external code connect `toast_requested`?** A repo-wide grep over
   `scripts/` finds none, but plugins/addons outside `scripts/` were not scanned.
   Settle by grepping the whole project root.
3. **Is the forest top-up intended to be capped at 11 total?** `lobby.gd:1148`
   counts only `_forest_monsters` (the array), not all live `forest_mode` enemies,
   so monsters spawned directly elsewhere would not be counted. Settle by
   instrumenting `get_nodes_in_group("enemies")` at raid time.
4. **What consumes `Lobby.get_map_rect()` / `minimap_markers()`?** Nothing in
   `scripts/`. Possibly a planned minimap; if so the HUD has no code for it.
   Settle by checking whether an older `GameHUD` revision drew a minimap.
5. **Is `sea_cleaned` surfaced anywhere besides `SeaCleaningPanel`?** Only
   `game_state.gd:709` writes and `sea_cleaning_panel.gd:13` reads it in this
   slice; no achievement or progression system reads it.
6. **Does the `house` shop stall's `SettlementTarget` serve a purpose?** It is
   added at `lobby.gd:404-408` for every stall, including `shop_house`, but the
   builder NPC's only action is opening `HousePanel` — worth confirming that
   stalls are meant to take raid damage at all.
7. **`_purchase_serial`** is incremented (`game_state.gd:222`) but never read
   anywhere in `scripts/` — dead counter or intended for a save-diff check?
8. **`AUTO_HEAL_RATIO` / `AUTO_HEAL_REARM_RATIO`** (`game_state.gd:24-25`) belong
   to the player/combat slice; not traced here beyond noting they exist in the
   economy-adjacent save block.
9. **Does the ward lock really hold?** `_tick_recovery` teleports the player back
   inside `RECOVERY_RADIUS` each frame (`lobby.gd:1088-1090`), but it only runs
   while `GameState.recovery_active()`. If a modal is open, the player cannot
   move anyway; if a raid starts, raiders can still reach them. Untested
   interaction — settle by reproducing a raid during recovery.

