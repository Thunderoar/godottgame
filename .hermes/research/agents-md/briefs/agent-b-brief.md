# MISSION — Agent B: World, Economy, UI & Content Data

Project root: /home/roku/Documents/games/tournamentgame/GAME_COMP_RPG-Godot
Engine: Godot 4.7.2, 2D pixel-art survival action-RPG. ~14,556 lines of GDScript. NOT a git repo.

Your deliverable (write it, do not just summarize):
  /home/roku/Documents/games/tournamentgame/GAME_COMP_RPG-Godot/.hermes/research/agents-md/agent-b-world-economy-ui.md

## HARD RULES
1. FIRST ACTION, before reading anything else: create the deliverable file with every section header and a one-line placeholder. Then fill it in with patch/append as you learn. If you die mid-run, the file must still contain your findings.
2. READ-ONLY on the project: never modify, create, or delete any project file. The only file you write is your report.
3. Every claim needs evidence as `path:line`. No guesses. If you cannot verify, mark it `UNVERIFIED:`.
4. Report FACTS an engineer needs to change gameplay safely — exact numbers, table shapes, and which file owns each rule.

## YOUR SLICE (own these)
- scripts/world/* : lobby.gd (1211 lines), dungeon.gd, resident.gd, forest_tree.gd, rubbish_system.gd, rubbish_piece.gd, coastal_guard.gd, settlement_editor.gd, settlement_placeable.gd, settlement_target.gd, shop_npc.gd, interactable.gd, loot_drop.gd, portal_entrance.gd, portal_exit.gd, recovery_ward.gd, house_bed.gd, resource_pile.gd
- scripts/ui/* : game_hud.gd (736), pet_battle_panel.gd (470), shop_panel.gd, title_screen.gd, inventory_panel.gd, modal_base.gd, house_panel.gd, portal_panel.gd, sea_cleaning_panel.gd, tutorial_guide.gd, victory_panel.gd, defeat_panel.gd, mission_arrow.gd, segmented_bar.gd, touch_action_button.gd, virtual_joystick.gd
- scripts/data/* : character_db.gd, item_db.gd, pet_db.gd, pet_battle_db.gd, portal_db.gd, house_db.gd
- scenes/game.tscn: only the parts that instance/carry your slice (ignore the global boot wiring — another agent covers that)

## QUESTIONS TO ANSWER
1. Content data model: for each *_db.gd, the exact table shape (dict keys, types, units), a full inventory of entries (characters, items with price/stats, pets, portals/levels, houses), and whether the data is a `const` dict, static funcs, or class instances. Give the canonical example of "add a new item / new portal level / new house tier" — the minimal edit set with file:line for each touch point.
2. Economy rules: every gold/diamond source and sink with exact amounts, where the transaction is enforced, debounce/negative-guard logic, and shop filtering rules per hero. Cite the code that enforces atomicity.
3. Settlement: what objects exist, grid snap/clamp bounds, what is persisted and under which save keys, how the editor enters/exits, what happens to in-flight gameplay while editing.
4. Village defence + forest: raid trigger conditions, spawn counts, defender/resident role behaviour, building damage model, the invulnerable-tree rule, monster aggro/line-of-sight logic, and how the emergency state clears.
5. Sea cleaning: rubbish spawn/catch rates, the +1 gold rule, beached-rubbish-to-monster transformation, counter persistence.
6. HUD/UI architecture: which panels are modals, how modal_base.gd works, input blocking/pause behaviour, touch vs keyboard dual-binding strategy, and the panel <-> GameState data flow (who calls whom).
7. Pet duel system: turn timing (the 2-second window), skill resolution order/simultaneity, damage/guard/recover formulas, level-up guarantee, and where the arena panel lives vs a real scene.
8. Tutorial: the eight steps, how progress is tracked, blocking vs non-blocking, skip handling.
9. Hardcoded magic numbers: list the gameplay-tuning constants (damage, cooldowns, speeds, prices, durations, spawn counts) with file:line, grouped by system. This is the "where do I tune X" index.

## FINAL SECTIONS (mandatory)
- `## Conventions observed` — data-table style, signal usage in UI, how panels refresh, naming. 2-3 quoted examples with file:line.
- `## Gotchas / footguns` — coupling that will break when touched (e.g. HUD reading GameState directly, panel states not reset, editor/gameplay overlap).
- `## AGENTS.md candidate rules` — max 25, imperative, one line each, each justified by what you found.
- `## Open questions` — what you could not determine and what would settle it.
