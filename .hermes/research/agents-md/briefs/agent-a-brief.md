# MISSION — Agent A: Runtime Architecture & Core Systems

Project root: /home/roku/Documents/games/tournamentgame/GAME_COMP_RPG-Godot
Engine: Godot 4.7.2, 2D pixel-art survival action-RPG. ~14,556 lines of GDScript across ~80 scripts. NOT a git repo.

Your deliverable (write it, do not just summarize):
  /home/roku/Documents/games/tournamentgame/GAME_COMP_RPG-Godot/.hermes/research/agents-md/agent-a-architecture.md

## HARD RULES
1. FIRST ACTION, before reading anything else: create the deliverable file with every section header and a one-line placeholder. Then fill it in with patch/append as you learn. If you die mid-run, the file must still contain your findings.
2. READ-ONLY on the project: never modify, create, or delete any project file. The only file you write is your report.
3. Every claim needs evidence as `path:line` (e.g. `scripts/autoload/game_state.gd:412`). No guesses. If you cannot verify, mark it `UNVERIFIED:`.
4. Report FACTS an engineer needs to change code safely, not a rewrite of the README.

## YOUR SLICE (own these; another agent reads the rest)
- project.godot (autoload list, main scene, input map, display/render settings, config version)
- scenes/game.tscn + scenes/main.tscn (node trees, script attachments, instanced subscenes)
- scripts/game/game.gd (main flow/scene orchestration)
- scripts/autoload/game_state.gd  (1287 lines — read ALL of it: state, economy, saves, emergencies, recovery, XP/levels, signals)
- scripts/autoload/sfx.gd
- scripts/core/* (pixel_art.gd 1106 lines, ui_theme.gd, follow_camera.gd)
- scripts/player/* (player.gd, player_sprite.gd, arrow.gd)
- scripts/pets/pet.gd
- scripts/combat/* (enemy.gd, boss_projectile.gd)
- Root-level loose scripts: scripts/camera_follow.gd, chest_interact.gd, control_mode.gd, player_visual.gd, point_and_click_controller.gd, props_altar.gd, sprite_color_animation.gd, stairs_layer_trigger.gd, welcome_popup.gd — determine whether each is LIVE (referenced by a scene/script) or DEAD/orphan code, with the referencing file:line.

## QUESTIONS TO ANSWER
1. Boot path: what runs first, which autoloads exist and in what order, what scene is main, how does title -> character select -> lobby -> dungeon -> back flow work? Sequence with node/script names.
2. Autoload singletons: for GameState and SFX, list every public variable, signal, and function group with line numbers. What is the authoritative source of truth for player stats, gold/diamonds, pets, inventory, house level, emergency state, portal progress?
3. Signal map: who emits what, who connects to it, and where connections are made (code vs .tscn). Flag any signal defined but never emitted, or emitted but never connected.
4. Persistence: exact save file path/keys, what is serialized, when save/load happens, migration/versioning, what is NOT saved. Settlement layout persistence.
5. Combat/entity contract: how enemy.gd, player.gd, pet.gd, arrow.gd, boss_projectile.gd interact (groups? signals? direct method calls? collision layers/masks?). Include collision layer/mask values if defined in scenes.
6. Lifecycle/ownership: who instantiates and frees nodes, scene switching mechanism (`change_scene_to_file` vs manual add/remove), pause/modal interplay (does a modal pause the tree? how?).
7. Frame/tick model: `_process` vs `_physics_process` usage, timer patterns, any per-frame allocations that matter.
8. Dead code / duplication: list duplicated or superseded scripts (e.g. camera_follow.gd vs core/follow_camera.gd) and say which one is live.

## FINAL SECTIONS (mandatory)
- `## Conventions observed` — naming, file layout, typing style (typed vs untyped vars), how nodes are found (`$Path` vs `get_node` vs `%UniqueName`), error handling, comment style. Quote 2-3 short examples with file:line.
- `## Gotchas / footguns` — things that will bite someone editing this project (e.g. hardcoded node paths, magic numbers, save-format coupling, ordering dependencies between autoloads and scenes).
- `## AGENTS.md candidate rules` — max 25, imperative, one line each, each justified by what you found. These get merged into the project AGENTS.md.
- `## Open questions` — what you could not determine and what would settle it.
