# MISSION — Agent C: Tooling, Tests, Build/Export, Docs Truth-Pass

Project root: /home/roku/Documents/games/tournamentgame/GAME_COMP_RPG-Godot
Engine: Godot 4.7.2, 2D pixel-art survival action-RPG. ~14,556 lines of GDScript. NOT a git repo.

Your deliverable (write it, do not just summarize):
  /home/roku/Documents/games/tournamentgame/GAME_COMP_RPG-Godot/.hermes/research/agents-md/agent-c-tooling-tests-docs.md

## HARD RULES
1. FIRST ACTION, before reading anything else: create the deliverable file with every section header and a one-line placeholder. Then fill it in with patch/append as you learn. If you die mid-run, the file must still contain your findings.
2. READ-ONLY on the project: never modify, create, or delete any project file. The only file you write is your report. You MAY run read-only shell commands (find, grep, ls, godot --version) but do NOT launch a GUI, do NOT export, do NOT write into build/.
3. Every claim needs evidence as `path:line`. No guesses. If you cannot verify, mark it `UNVERIFIED:`.
4. Your job is to make the repo safe for a coding agent to work in: what to run, what proves a change is correct, what is stale, what is lying.

## YOUR SLICE (own these)
- tools/ : tide_test.gd (767 lines, the 250-check acceptance suite) + tide_test.tscn, tide_capture_node.gd + tide_capture.tscn, convert.gd (2076 lines), play_test.gd, smoke_test.gd, pixel_test.gd, setup_input.gd, make_icon.gd
- export_presets.cfg (all presets, package ids, keystore/signing fields, permissions), .gitignore, icon.svg/.ico, *.uid files
- docs/ : ARCHITECTURE.md, ACCEPTANCE_TESTS.md, QA_REPORT.md, COMPLETION_REPORT.md, ANDROID_BUILD.md, LEGACY_CONVERSION.md, LEGACY_CONVERSION_NOTES.md, CONVERSION.md, and README.md (verification section + claims)
- Total repo hygiene: what a fresh clone/machine needs (is .godot/ committed? are assets imported? are .uid files tracked? any missing files referenced?), and whether anything is machine-specific or hardcoded to /home/roku

## QUESTIONS TO ANSWER
1. Test harness: how tide_test.tscn works end-to-end — how it instantiates the game, its assertion helper (name + shape + failure reporting), how it counts checks, how it exits and with what code. Is it truly headless-safe? Does it write files (saves!) into the project — i.e. will running it dirty the working tree? Enumerate the ten most important assertion groups and what each proves.
2. Exact verification commands, verified against the actual scene paths and any required CLI flags (e.g. `godot --headless --path . res://tools/tide_test.tscn`). Check whether a `godot` binary exists on this machine (`command -v godot`, `godot --version`) and record the answer honestly — do NOT claim the suite passes if you could not run it; if you run it, report the real tail of the output and the exit code.
3. Other tools: what convert.gd / play_test.gd / smoke_test.gd / pixel_test.gd / setup_input.gd / make_icon.gd each do, whether they are still runnable and current (do they reference scripts/scenes that still exist?), and which are legacy one-shots safe to ignore.
4. Export/build: every preset in export_presets.cfg, target platform, resolution/orientation settings, what is needed to actually export (SDK path, keystore path, templates), and which values are machine-specific placeholders. Does build/ contain stale artifacts? What produces it?
5. Docs truth-pass: for each docs file, state (a) what it claims, (b) whether the code still matches, (c) 1-3 concrete stale claims with file:line on both sides. Rank the docs by how trustworthy/current each one is, and say which one an agent should read first.
6. Repo hygiene: files that should be ignored but are present, files referenced but missing, absolute /home/roku paths baked into tracked files (grep for `/home/roku`), and whether .godot/ cache state could mask a broken import.
7. Risk inventory for automated edits: which files are huge/generated/do-not-hand-edit (convert.gd? pixel_art.gd?), which files are the "hot" ones multiple systems depend on, and which tests would catch a regression in each subsystem.

## FINAL SECTIONS (mandatory)
- `## Verified commands` — exact copy-pasteable commands with the real observed outcome (or `NOT RUN` + why).
- `## Conventions observed` — tooling style, test naming, doc structure. 2-3 quoted examples with file:line.
- `## Gotchas / footguns` — stale docs, tests that mutate state, machine-specific config, headless traps.
- `## AGENTS.md candidate rules` — max 25, imperative, one line each, each justified by what you found.
- `## Open questions` — what you could not determine and what would settle it.
