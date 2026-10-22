# Tidesworn QA Report

**Engine:** Godot 4.7.2.stable.official.ed1daf0bf  
**Test host:** Windows desktop (headless logic run + OpenGL screenshot run)  
**Main scene:** `res://scenes/game.tscn`  
**Automated test:** `res://tools/tide_test.tscn`  
**Result:** **269 checks, PASS**  
**Android device/emulator:** not available in this environment; pending.

## Reproduce

```sh
godot --headless --path . res://tools/tide_test.tscn
```

The harness removes its development save at the start and end. Agent-facing
acceptance guidance lives in [`ACCEPTANCE_TESTS.md`](ACCEPTANCE_TESTS.md).

## Passed coverage

### Title, credits and HUD
- Title reads **SAVE THE WORLD**.
- Credit line reads **Created by Qayyim, Farhan and Ayiz**.
- **CHOOSE YOUR ROAD** card menu is responsive at 832×480 and 1280×720.
- Three heroes exist with sword/hammer/bow disciplines.
- New game starts an eight-step tutorial; skip works.
- World is locked in permanent daytime (`DAYTIME`).
- No minimap node exists.
- Backpack and Build buttons sit at top-left, away from movement/combat.
- **No floating NPC name labels** on residents, merchants or the Coastal Guard.
- **No toast/pop-up notification container** exists; `show_toast()` is a no-op.
- Player and pet XP bars exist and show next-level requirements.
- Player health 10 segments; pet health 5 segments.
- Floating Health and Mana bars follow above the player's head.
- Three mission-guidance arrows point to the current portals/build/emergency.
- Top-right **Menu** opens Resume, Settings and Return to Title.
- Settings adjusts GUI scale and each touch control's X/Y/size.
- Settings persist through new runs and save/load.
- Yellow Unisza NPC opens a persistent dialogue box.
- Dialogue contains the exact welcome and student lines.

### Two battle portals
- Exactly two `battle_portal` gates stand side by side on the north path.
- One is the **Monster Battle Portal**; one is the **Pet Battle Portal**.
- The pet gate opens the five-level tournament panel.
- The monster gate opens the ten-level campaign panel.

### Pet tournament and progression
- Five pet duel levels are defined with opponent stats and rewards.
- Only the first duel is unlocked; each clear unlocks the next.
- Duel uses the active companion's level and generates both combatants.
- Combat has only two mechanics: **Attack** and **Defend**.
- Each turn gives the player a two-second choice window; the enemy also selects
  Attack or Defend.
- When the timer expires, both chosen actions execute simultaneously.
- Attack impacts spawn scratch/punch effects; Defend raises a shield effect.
- Both health bars render; win/loss/forfeit resolve correctly.
- Victory grants Gold + pet XP, records the clear, unlocks the next level and
  **always raises the companion's level by at least one**.
- **Pet Food** is sold in the Pet Shop for 15 Gold.
- Feeding consumes one Pet Food and grants 25 pet XP.
- Pet and player XP bars update.
- Pet duel progress and sea-cleaning progress survive save/load.

### Settlement and village life
- Twelve residents populate the village; four are combat-capable.
- Seven neighbouring resident cottages exist.
- Abandoned, damaged and destroyed houses decorate the outskirts.
- Six editable garden beds, 50+ flowers and 12+ decoration placeables exist.
- Two horses exist and horse art generates.
- Build mode toggles on, locks movement, shows the editor HUD and allows the
  cottage to be dragged.
- Dragged positions save to GameState and survive a lobby reload.
- Build mode toggles off and restores movement.

### Protected forest and game over
- 64 `ForestTree` nodes form the eastern woodland.
- Each tree has independent HP, a visible HP bar and persistent health.
- Tree hits shake the canopy, emit leaf/spark VFX and play synthesized impact SFX.
- Twelve forest monsters patrol the woods; four more join during an emergency.
- Forest monsters attack trees at a faster cadence without needing player
  proximity, and immediately target + charge the player on line-of-sight
  detection.
- When every tree reaches zero HP, the locked Game Over screen appears.
- Game Over deletes the failed run and returns to the title screen.

### Sea cleaning
- Coastal Guard catches drifting rubbish.
- Each catch grants exactly **+1 Gold**.
- The persistent `sea_cleaned` counter increments.
- Beached rubbish grants no catch reward and becomes a monster.
- Defeating the rubbish monster grants separate Gold.
- No pop-up notification is created.
- The Coastal Guard opens a persistent sea-cleaning report modal.

### Portal campaign and combat
- Ten monster portal levels are defined.
- Every portal has at least ten regular monsters.
- Every portal defines one boss with an ability.
- Boss art generates for all ten bosses.
- Boss abilities cover punches, projectiles, charges, area attacks and a
  combined projectile-charge pattern.
- First portal has 12 regular monsters + Grotto Warden.
- Second portal has 14 regular monsters + Drowned King.
- Under-levelled entry is blocked; first clear unlocks the next portal.
- Auto-loot, dungeon lighting and Shore Gate banking work.

### Economy, house and healing
- Gold/diamond transactions and insufficient-funds rejection.
- Purchase debounce.
- Equipment purchase/filter/equip updates attack power.
- Driftwood gather/sell works.
- Dedicated Construction Shop stall and builder NPC exist.
- The Construction Shop opens the five-step Level 1-5 house progression panel.
- Gold cannot pay for house upgrades; diamond-funded upgrades reach level 5.
- Level-5 sleep recovery is two seconds and restores health.
- Auto-heal, pet healing, pet attacks and shields work.
- Pet Revival Potion is absent; pets are never permanently lost.
- Death discards unbanked loot and starts the recovery ward.
- Recovery holds the player until healed.

### Emergency, defence and persistence
- Emergency triggers while exploring a portal.
- Persistent HUD banner appears; player is not teleported.
- Portal combat continues and entry is blocked during an emergency.
- Raiders appear from both sea and forest.
- Residents flee; defenders and capable residents damage raiders.
- Raiders and village damage resolve; clearing restores safety.
- Gold, house level, monster portal progress, pet level, pet duel progress,
  sea-cleaning progress and settlement layout persist.

## Visual review

Screenshots in [`screenshots/`](screenshots/):

- `tide_title.png`, `tide_tutorial.png`
- `tide_lobby.png`, `tide_menu.png`, `tide_settings.png`, `tide_dialogue.png`
- `tide_lobby_portal.png`, `tide_build.png`, `tide_forest.png`, `tide_ruins.png`
- `tide_shore.png`, `tide_pet_battles.png`
- `tide_pet_duel.png`, `tide_pet_resolution.png`, `tide_pet_shop.png`
- `tide_shop.png`, `tide_house.png`, `tide_inventory.png`
- `tide_portals.png`, `tide_dungeon.png`, `tide_boss.png`
- `tide_emergency.png`, `tide_settlement_attack.png`, `tide_recovery.png`
- `tide_game_over.png`

Reviewed at 1280×720: title/credits/menu, mission arrows, floating player HP/MP,
top-left Pack/Build, paired portals, Attack/Defend pet duel with impact/shield
effects, dense forest and tree HP, ruin houses, settlement editor, settlement
defence and recovery ward. No NPC name labels or toast notifications appear.

## Known risks

1. Android export, signing and real-device performance are untested.
2. Music and ambient audio are absent; gameplay SFX are synthesized at runtime.
3. Building damage has no repair interaction; trees have HP but no replanting.
4. Bosses use one primary special pattern; no full multi-phase move sets.
5. Pet duels use an animated arena panel rather than a walkable scene.
6. The reusable monster dungeon scene is differentiated by data/palette/boss set
   rather than bespoke geometry.
