# Agent C — Tooling, Tests, Build/Export, Docs Truth-Pass

Status: **COMPLETE**. Every command below was run on this machine unless marked `NOT RUN`.
Project root: `/home/roku/Documents/games/tournamentgame/GAME_COMP_RPG-Godot`
Engine on host: `/usr/bin/godot` → `4.7.2.stable.arch_linux.ed1daf0bf`
Date: 2026-10-22

## 0. Executive summary

1. **The acceptance suite is RED right now, reproducibly.** `godot --headless --path . res://tools/tide_test.tscn`
   → `250 checks, 1 FAILURE(S)`, exit **1**, twice, on a clean tree. The failing assertion is
   `forest trees are invulnerable to structural damage` (`tools/tide_test.gd:147`), caused by
   `scripts/world/forest_tree.gd:39` actually subtracting health. Every doc that says "250 checks, PASS"
   is false today (README:189, QA_REPORT:7, COMPLETION_REPORT:29, ACCEPTANCE_TESTS:14).
2. **The suite does not dirty the working tree** (567-file manifest byte-identical before/after) but it
   **deletes the player's real save** `user://tidesworn_save.json` at start and end
   (`tools/tide_test.gd:13`, `:109`). Verified: the save was gone after my run; I restored it from a
   backup taken before testing (sha256 `999ed80c…` before and after).
3. **A fresh checkout cannot run the suite at all.** With no `.godot/`, `tide_test.gd` fails to parse
   (global `class_name`s unknown), **zero** checks run, and the process **hangs forever** (my run was
   killed by `timeout` at 300 s, exit 124). `godot --headless --path . --import` fixes it and the run
   then matches the warm result. This bootstrap step is not stated anywhere as mandatory.
4. **The documented "parse/import and report warnings as failures" command does not do that.**
   `godot --headless --path . --editor --quit` exits **0** even with a `SCRIPT ERROR: Parse Error` in a
   `class_name` script (proved on a throwaway copy), and prints **nothing at all** for a broken script
   that has no `class_name` and is not referenced by a scene. Exit code is not evidence; stdout must be
   grepped.
5. **Export is impossible on this host as-is**: `~/.local/share/godot/export_templates/` is empty.
   Android SDK is present at `/home/roku/Android/Sdk`, but the configured debug keystore
   `/home/roku/.local/share/godot/keystores/debug.keystore` does not exist.
6. **`build/` is stale** (APK 2026-10-21 05:44, EXE 05:27) versus source edits at 08:19–08:37 the same
   day and `project.godot` on 2026-10-22 14:19.
7. **Not a git repo** (no `.git`), and `.gitignore:4` ignores `export_presets.cfg` — a `git init && git add -A`
   would silently drop the only copy of the export configuration.
8. **No `/home/roku` path is baked into any tracked file** (grep clean). The one hardcoded absolute path
   is `tools/convert.gd:35` → `C:/Users/LUQMAN/...` (a Windows Unity source that does not exist here).

## 1. Test harness: `tools/tide_test.tscn` end-to-end

### 1.1 Scene wiring — how the game is instantiated

- `tools/tide_test.tscn:5-6` is a single `Node` named `TideTest` with `tools/tide_test.gd` attached.
  No game scene is pre-placed in the test scene.
- `tools/tide_test.gd:1` `extends Node`; `:12` `_ready()` is the whole driver.
- `:13` `GameState.delete_save()` — wipes `user://tidesworn_save.json` (`scripts/autoload/game_state.gd:20`, `:1204-1206`).
- `:14-15` `game = load("res://scenes/game.tscn").instantiate()` then `add_child(game)` — the real game is
  parented under the test node, so the whole `Game` lifecycle (`scenes/game.tscn:5-6`, `scripts/game/game.gd`) runs for real.
- `:16-17` two `await get_tree().process_frame` to let the title screen build.
- `:29` `game.call("_on_character_selected", "qayyim")` — bypasses the card UI and drives the *private*
  handler directly; every later state is reached the same way (`game.call("open_shop", …)` at `:249`,
  `game.call("toggle_build_mode")` at `:671`).
- `:32` `hud = game.get("hud")` — the suite then reads **private members** of the HUD
  (`hud.get("_health_bar")` `:40`, `hud.get("_toast_box")` `:57`, `hud.get("_build_mode_panel")` `:675`).
- Autoloads exist because the harness is **run as a scene**, not via `--script`; `GameState` and `Sfx` are
  declared at `project.godot:21-22`. This is deliberate: `--script` requires a `SceneTree`/`MainLoop`
  script — proved when `godot --headless --path . --script tools/pixel_test.gd` failed with
  `Can't load the script "tools/pixel_test.gd" as it doesn't inherit from SceneTree or MainLoop` (exit 1).
- Ordering: the top-level `_ready` runs 44 inline checks, then calls 17 `_test_*` coroutines
  (`:92-107`), then finalises at `:109-111`.

### 1.2 Assertion helper — name, shape, failure reporting

```gdscript
# tools/tide_test.gd:763-767
func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		fails += 1
	print("[%s] %s" % ["OK" if condition else "FAIL", label])
```

- Signature: `_check(condition: bool, label: String) -> void`. Two file-scope counters at `:8-9`.
- Failure reporting is **stdout only**: one line `[FAIL] <label>`. There is **no** `push_error`, no
  `assert()`, no expected/actual values, no source line, no stack trace, and **no early abort** — the suite
  keeps running after a failure (that is how I got 249 OK + 1 FAIL in one pass).
- Timeout safety: none. If `_ready` errors before `:111`, the process never quits — this is exactly what
  happened on the fresh-clone run (0 checks, hung >300 s).
- Contrast with the two older harnesses: `tools/play_test.gd:220-222` `_check` returns `bool` and callers
  `and` them together (`:54-57`), so failures reach the exit code; `tools/smoke_test.gd:64-80` only
  **prints** `[MISSING]` and never touches the exit path.

### 1.3 Check counting and exit code

- The count is **runtime**, not static: 212 literal `_check(` call sites, reported **250** because loops
  multiply checks — 10 portals × 3 checks (`:78-83`), 5 pet duels (`:190-192`), 2 character styles (`:699-700`).
  Therefore "250 checks" is data-driven and **will drift** whenever catalogue data changes; hardcoding it
  in docs is a self-inflicted staleness bug.
- `:110` prints `--- tide test: %d checks, %s ---`; `:111` `get_tree().quit(0 if fails == 0 else 1)`.
- Observed on the real project: `--- tide test: 250 checks, 1 FAILURE(S) ---`, exit **1**, and Godot appends
  `WARNING: 4 ObjectDB instances were leaked at exit` after the summary — noise that an agent must not
  mistake for the verdict, and it means the true last line is not the summary.

### 1.4 Headless safety and filesystem side effects

- **Headless-safe: yes.** No viewport capture, no window, no mouse injection; movement is driven with
  `Input.action_press("move_right")` (`:117-119`). All 250 checks ran under `--headless`.
- **Repo side effects: none.** I diffed a `find -printf '%p|%s|%T@'` manifest of 567 project files
  (excluding `.godot/` and `.hermes/`) before and after a full run: **IDENTICAL**. `grep` for
  `FileAccess.open|DirAccess|save_png` in `tide_test.gd` returns nothing.
- **User-data side effects: destructive.** `:13` and `:109` delete `user://tidesworn_save.json`
  (`scripts/autoload/game_state.gd:1204-1206`). Verified twice: after each run the file was absent.
  This directory is *inside* `~/.local/share/godot/app_userdata/Save The World/`, so it does **not** dirty
  the tree — but it **destroys a real playthrough**, and the test itself writes tree health into that save
  mid-run (`scripts/world/forest_tree.gd:41`). Note that any copy of the project resolves to the **same**
  `user://` folder, because it is keyed on `config/name` (`project.godot:13`), not on the project path.
- Only `.godot/` cache is touched (ignored, regenerable).

### 1.5 Ten most important assertion groups

Counts are static `_check` sites in that function; the runtime total is higher where loops exist.

| # | Group (function, line) | Checks | What it proves |
|---|---|---|---|
| 1 | Boot / identity / HUD — `_ready` `:18-63` | 44 | Title scene exists; `GameState.has_existing_save == false`; title text `SAVE THE WORLD`; credit line; `CHOOSE YOUR ROAD`; exactly three heroes `qayyim/farhan/ayiz` with sword/hammer/bow; `pet_revival` removed; lobby loads; starter sword equipped; starter pet `ember` alive; HUD bars 10/5 segments; **no minimap**, **no toast box and `show_toast()` is a no-op** (`:57-59`); touch buttons map to real actions; permanent `DAYTIME`; 8-step tutorial; XP bar maxima match next-level thresholds. |
| 2 | World composition — `_test_settlement_expansion` `:126-194` | 22 | Two `battle_portal` gates only, one `monster` + one `pet`, side by side; **73 forest trees**; trees do not fall and still count hits (`:147-149` — the red check); ≥8 forest monsters charge on line of sight (`:161-165`); ≥4 resident houses, ≥2 horses, ≥50 flowers, ≥6 gardens, ≥12 decorations; **zero NPC `Label`s** (`:186`); 5 pet-duel levels with ordered unlocks. |
| 3 | Portal campaign data — `_ready` `:75-84` | 30 (10×3) | ≥10 portals; each defines ≥10 regular monsters, a non-empty `boss_ability`, and boss art that actually generates via `PixelArt.enemy_texture(..., true)`; abilities cover ≥4 distinct kinds. |
| 4 | Pet duel turn engine — `_test_pet_battle_portal` `:329-377` | 14 | Gate opens the panel; exactly 3 skills; 2.0 s window (`:354`); enemy choice drawn from the same 3; **both pets resolve simultaneously** (`:362`); victory records clear, unlocks next duel, grants gold, and levels the pet ≥1. |
| 5 | Shops / economy atomics — `_test_shops` `:215-253` | 14 | Price debit exactly 25; insufficient funds rejected with balance untouched; **debounced repeat tap buys only one** (`:232-233`); feeding grants pet XP; equipment equip updates slot; style filter excludes other heroes' weapons. |
| 6 | House / Construction Shop — `_test_house_and_sleep` `:256-292` | 11 | Dedicated `shop_house` + `house` keeper; panel branded "Construction"; **gold-only upgrade rejected**; 4 diamond upgrades reach level 5; level-5 recovery == 2.0 s; bed restores full health. |
| 7 | Emergency / village defence — `_test_emergency_attack` `:494-557` | 17 | Emergency starts inside a portal; HUD not toast; **player is not teleported and the fight is not interrupted**; portals blocked while under attack; raiders from **sea and forest**; residents flee; defenders damage raiders; clearing restores safety; gold awarded. |
| 8 | Defeat / recovery — `_test_defeat_and_recovery` `:558-589` | 14 | Unbanked loot discarded; pet not permanently killed; recovery active; defeat panel; respawn at cottage at critical health; ward **holds the player** until healed; HUD hides on release. |
| 9 | Dungeon combat / auto-loot — `_test_portal_combat_and_auto_loot` `:422-493` | 13 | Dungeon loads with ≥10 monsters + exactly 1 boss; no pet-light dependency; sword attack damages; **loot auto-collects on touch with no collect button**; pet heals/attacks/shields in combat. |
| 10 | Persistence — `_test_save_load` `:646-666` + `_test_build_editor` `:668-696` | 7 + 10 | Gold, house level, portal clear, pet level, pet-duel clear, `sea_cleaned` survive a real save/load; dragged building position is written to `GameState` and survives a lobby reload. |

Remaining groups (not in the top ten but real coverage): movement `:114` (1), gathering/selling `:197` (4),
auto-heal + shield `:295` (4), pet support curve `:313` (6), rubbish/sea-cleaning `:379` (11),
boss progression `:590` (9), second portal `:620` (7), character styles `:698-724` (8).

## 2. Verification commands (observed truth)

| Command | Observed |
|---|---|
| `godot --version` | `4.7.2.stable.arch_linux.ed1daf0bf` |
| `godot --headless --path . res://tools/tide_test.tscn` | exit **1**, `250 checks, 1 FAILURE(S)`, 249 `[OK]`, 1 `[FAIL] forest trees are invulnerable to structural damage`, then `WARNING: 4 ObjectDB instances were leaked at exit`. **Two identical runs.** |
| `godot --headless --path . --editor --quit` | exit **0**, no `SCRIPT ERROR`/`WARNING` lines, **567-file manifest unchanged**. It does *not* "report warnings as failures". |
| `godot --headless --path . --import` | exit **0**; created `.godot/global_script_class_cache.cfg` on a fresh copy; makes the project runnable. |
| `godot --headless --path . --script tools/pixel_test.gd` | exit **1**: `Can't load the script … as it doesn't inherit from SceneTree or MainLoop`. |
| `godot --headless --path . res://tools/pixel_test.tscn` | exit **0**, prints `house 1..5 -> 224x176`, `done`. |
| `godot --headless --path . --script tools/smoke_test.gd` | exit **0**, legacy scene loads, 5 `[OK]`, `--- result: PASS ---`; viewport reports `size=(64, 64)` (dummy headless). |
| `godot --headless --path . --script tools/play_test.gd` | exit **1**, `--- play test: 1 FAILURE(S) ---`; the only failure is `character moved towards the click` (start x=5.82 → ended x=7.63, i.e. moved the wrong way). |
| `godot --path . res://tools/tide_capture.tscn -- --shots <dir>` | **NOT RUN** — opens a window (forbidden by my brief) and writes PNGs. |
| Any export | **NOT RUN** — brief forbids exporting; and templates are absent (see §4.2). |

## 3. Other tools: what each does, still runnable?

| File | Lines | Purpose | Side effects | Status |
|---|---|---|---|---|
| `tools/tide_test.gd` + `.tscn` | 767 | The acceptance suite (this project's real gate). | Deletes `user://tidesworn_save.json` (`:13`, `:109`); no `res://` writes. | **Current & runnable**; currently 1 failure. |
| `tools/tide_capture_node.gd` + `.tscn` | 133 | Screenshot tour of title/tutorial/lobby/build/shop/house/inventory/pet duel/forest/shore/portal/boss/emergency/recovery. | Needs a real window; `:15-16` defaults output to **`res://shots`** (inside the project, not gitignored); `:17` and `:122` delete the save. | Runnable only with GUI — **do not run in CI**. |
| `tools/convert.gd` | 2076 | Unity→Godot one-shot converter (two passes). | Writes `assets/textures/` (`:581-598`), `assets/sprites/*.tres` (`:611-641`), `assets/tilesets/*.tres` (`:1716-1893`), **`scenes/main.tscn`** (`:1943-1958`), **`CONVERSION.md`** (`:2064-2076`). | **Dead here**: `:35` hardcodes `C:/Users/LUQMAN/Documents/tournamentgame/GAME_COMP_RPG-2026-10-09_22-39-09`, which is absent; no sibling Unity source exists (`../` contains only `GAME_COMP_RPG-Godot`, two PNGs, `shots/`). |
| `tools/play_test.gd` | 239 | Behaviour test of the **legacy** converted scene (`:10` `res://scenes/main.tscn`): click-to-move, keyboard, chest+popup, stairs. | None by default (`_shot` returns early when `--shots` empty, `:210-211`). | Runnable, but **1/16 fails headless**; the click maths assumes a real viewport (`screen=(553.6, 684.6)` on a 64×64 dummy viewport). |
| `tools/smoke_test.gd` | 108 | Legacy scene structural check + optional `--shot`. | Writes a PNG only with `--shot` (`:44-50`). | Runs, prints PASS, **but always exits 0** (`:53`) — its verdict cannot fail a CI job. |
| `tools/pixel_test.gd` + `.tscn` | 9 | Prints the five house textures' sizes. | None. | Works **only as a scene** (`res://tools/pixel_test.tscn`); `--script` fails. |
| `tools/setup_input.gd` | 29 | Re-writes the five movement/interact input actions into `project.godot`. | **`ProjectSettings.save()` at `:27` rewrites `project.godot`.** | **Do not run** unless you intend to rewrite the project file; the actions it defines already exist (`project.godot:39-95`). |
| `tools/make_icon.gd` | 56 | Rasterises `icon.svg` into a multi-size `icon.ico`. | **Writes `res://icon.ico`** (`:32`). | Runnable but mutates a tracked binary; only run deliberately when the icon changes. |

## 4. Export / build

### 4.1 Presets

`export_presets.cfg:1-4` declares two runnable presets.

| | Windows Desktop (`preset.0`, `:8-75`) | Android (`preset.1`, `:79-302`) |
|---|---|---|
| Output | `build/SaveTheWorld.exe` (`:15`) | `build/SaveTheWorld.apk` (`:86`) |
| Filter | `export_filter="all_resources"`, `exclude_filter="tools/*, docs/*"` (`:12-14`) | same (`:83-85`) |
| Notes | `binary_format/embed_pck=true` (`:34`), `x86_64` only (`:38`), `codesign/enable=false` (`:39`), icon `res://icon.ico` (`:46`), no company/copyright/version strings (`:49-54`) | `arm64-v8a` only (`:115`), `package/signed=true` (`:122`), `package/unique_name="com.luqman.savetheworld"` (`:120`), version `1.0.0`/code 1 (`:118-119`), `use_gradle_build=false` (`:106`), min/target SDK blank (`:111-112`), all launcher icon fields blank (`:129-132`), `permissions/custom_permissions` empty and every standard permission `false` (`:150-302`) |

I verified the exclusion globs with the engine itself: `"docs/screenshots/x.png".match("docs/*") == true`
and `"tools/tide_test.gd".match("tools/*") == true`, so `tools/` and `docs/` (including the 6.8 MB of
screenshots) really are excluded from exports. **No bloat bug there.**

### 4.2 What an actual export needs — and what is missing

| Requirement | State on this host |
|---|---|
| Export templates for 4.7.2 | **MISSING** — `~/.local/share/godot/export_templates/` exists but is **empty**. Both presets leave `custom_template/*=""` (`:31-32`, `:102-103`), so installed templates are mandatory. **This alone blocks every export.** |
| Android SDK | Present: `/home/roku/Android/Sdk` (`build-tools/35.0.0`, `platforms`, `platform-tools`, `cmdline-tools`); `adb`, `java`, `keytool` on PATH. |
| Android debug keystore | **Configured but absent**: editor settings point at `/home/roku/.local/share/godot/keystores/debug.keystore`; that directory does not exist. |
| Release keystore | Not present and correctly not committed — `export_presets.cfg` carries **no** keystore path; `.godot/export_credentials.cfg` is all empty strings (`:3-22`). `docs/ANDROID_BUILD.md:42` is accurate here. |
| Machine-specific values | `package/unique_name="com.luqman.savetheworld"` (`:120`) is a personal id, not a placeholder; `ssh_remote_deploy/host="user@host_ip"` (`:60`) is a stock template default; Windows metadata strings are empty (fine); Android SDK/keystore live **outside the repo** in editor settings, so they are not portable. |

`docs/ANDROID_BUILD.md:39` tells the reader to "Add an Android preset" — but the preset already exists
(`export_presets.cfg:77-86`). That instruction is stale.

### 4.3 `build/` contents and provenance

- `build/` is 134 MB, gitignored (`.gitignore:7`):
  - `SaveTheWorld.apk` 29,311,485 B, mtime **2026-10-21 05:44**
  - `SaveTheWorld.apk.idsig` 234,931 B (v4 signature sidecar, produced by `apksigner`), same mtime
  - `SaveTheWorld.exe` 110,094,448 B, mtime **2026-10-21 05:27**
- The APK is genuine and matches the preset: `aapt2 dump badging` → `package: name='com.luqman.savetheworld'
  versionCode='1' versionName='1.0.0'`, `minSdkVersion:'24'`, `targetSdkVersion:'36'`. It also warns that
  `res/mipmap-anydpi-v26/themed_icon.xml` is referenced but missing — consistent with the blank launcher
  icons in the preset (`:129-132`).
- **Stale**: the newest scripts are 2026-10-21 08:19–08:37 (`forest_tree.gd`, `lobby.gd`, `game_hud.gd`) and
  `project.godot` is 2026-10-22 14:19 — all **after** both binaries. Nothing in the repo regenerates
  `build/` (no Makefile, no CI, no export script); it was produced by manual Godot exports. Treat both
  artifacts as historical.

## 5. Docs truth-pass

Ranking, most trustworthy first:

| Rank | File | Verdict |
|---|---|---|
| 1 | `docs/ARCHITECTURE.md` | Best document in the repo; matches the code almost everywhere (signal list, economy methods, pet-duel rules, 0.62 s cadence at `lobby.gd:503`, recover 16 % at `pet_battle_panel.gd:226-227`). Two stale facts, both the same root cause as the red test. **Read this first for how the game works.** |
| 2 | `docs/ACCEPTANCE_TESTS.md` | The acceptance *rules* are precise and still correct in substance; its two operational claims are wrong (PASS status, and "warnings as failures"). **Read second, as the edit contract.** |
| 3 | `README.md` | Accurate feature overview and controls; only the verification claim is false. Read for orientation. |
| 4 | `docs/QA_REPORT.md` | Historically detailed, but reports a PASS that no longer holds and names a Windows test host. |
| 5 | `docs/COMPLETION_REPORT.md` | Changelog of a past pass; useful history, false "current result". |
| 6 | `docs/ANDROID_BUILD.md` | Quoted config block does not exist in `project.godot`; tells you to add a preset that is already there. Setup steps are otherwise sane. |
| 7 | `docs/LEGACY_CONVERSION.md` | Good narrative of the Unity port, but wrong main scene and a false exit-code promise. Only relevant to `scenes/main.tscn`. |
| 8 | `CONVERSION.md` and `docs/LEGACY_CONVERSION_NOTES.md` | **Byte-identical generated output** of `convert.gd:2064-2076` (verified with `diff`). They are converter logs, not documentation. |

Concrete stale claims, both sides:

1. **"PASS"** — `README.md:189` "Latest result: **250 checks, PASS**"; `docs/QA_REPORT.md:7`
   "**Result:** **250 checks, PASS**"; `docs/COMPLETION_REPORT.md:29` and `:128`; `docs/ACCEPTANCE_TESTS.md:14`
   "Expect: 250 checks, PASS".
   Reality: `tools/tide_test.gd:111` exits 1 when `fails > 0`; observed `--- tide test: 250 checks, 1 FAILURE(S) ---`.
   Timeline explains it: `tide_test.gd` mtime 04:36 and all docs 04:50–05:11, then `forest_tree.gd` 08:19,
   `lobby.gd` 08:23, `game_hud.gd` 08:37 — the docs were true when written and the last code edits broke them.
2. **"Trees are invulnerable"** — `README.md:86`, `docs/ACCEPTANCE_TESTS.md:67-68` ("`take_attack_damage()`
   must leave health unchanged"), `docs/ARCHITECTURE.md:181-184`, `docs/QA_REPORT.md:69-70`,
   `docs/COMPLETION_REPORT.md:71-72`.
   Reality: `scripts/world/forest_tree.gd:39` `health = maxi(0, health - maxi(1, amount))`, and `:48-49`
   fells at 0. The test at `tools/tide_test.gd:147` is the one that catches it.
3. **Save format version** — `docs/ARCHITECTURE.md:207` "version 5".
   Reality: `scripts/autoload/game_state.gd:21` `const SAVE_VERSION := 6`.
4. **Main scene** — `docs/LEGACY_CONVERSION.md:7-8` "press **F5**. The main scene is `scenes/main.tscn`".
   Reality: `project.godot:15` `run/main_scene="res://scenes/game.tscn"`; `README.md:18` agrees.
5. **Exit codes** — `docs/LEGACY_CONVERSION.md:101` "Both exit non-zero if a check fails."
   Reality: `tools/smoke_test.gd:53` `quit(0)` unconditionally; `_expect` only prints (`:64-80`). Only
   `play_test.gd:48` honours failures.
6. **Android orientation key** — `docs/ANDROID_BUILD.md:14` quotes `window/handheld/orientation=0` inside
   `project.godot`. Reality: `grep -n "handheld\|orientation" project.godot` → **no match**; the block at
   `project.godot:24-29` has only size/stretch/aspect. (Landscape is the engine default, so behaviour is
   right by accident; the quoted config is not.)
7. **"Add an Android preset"** — `docs/ANDROID_BUILD.md:39`. Reality: `export_presets.cfg:77-86`.
8. **QA host** — `docs/QA_REPORT.md:4` "Test host: Windows desktop". This host is Linux/Godot 4.7.2 and the
   suite runs; the line is not false about the past, but it misleads about the present.

## 6. Repo hygiene

- **No `.git`** (`ls -d .git` → absent). There is no history, no diff, no revert. Every agent edit is
  irreversible except by copies. This is the single biggest process risk in the repo.
- `.gitignore` (7 lines):
  - `:2` `.godot/` — correct.
  - `:3` `export.cfg` — Godot 3 legacy, file does not exist; harmless dead line.
  - `:4` **`export_presets.cfg`** — **wrong and dangerous**: it is the only record of the two presets, contains
    no secrets (keystore values live in `.godot/export_credentials.cfg`, which *is* ignored), and is required
    to reproduce any build. A `git init` would drop it.
  - `:7` `build/` — correct (134 MB).
  - Missing: no ignore for `shots/` even though `tools/tide_capture_node.gd:15` writes `res://shots`.
- **No `/home/roku` anywhere** in the repo (grep excluding `.godot/`/`.hermes/` → empty). Good portability.
- **One hardcoded foreign absolute path**: `tools/convert.gd:35` → `C:/Users/LUQMAN/…`.
- **No dangling `res://` references**: I scanned 538 `path="res://…"` references across `.tscn/.tres/.cfg/.import/.gd`
  and **0** targets were missing.
- **One orphan import**: `docs/screenshots/tide_night.png.import` exists (`.import:13`
  `source_file="res://docs/screenshots/tide_night.png"`) but the PNG was deleted — 20 PNGs vs 21 `.import` files.
  Leftover from the removed night cycle.
- **Assets are complete**: 9 PNG + 9 `.import`, 346 `.tres` (AtlasTextures/TileSets, no import needed).
- **`.uid` coverage**: all 69 `.gd` files have a `.gd.uid`; the 5 `.tscn` files have none, which is normal for
  files last saved before 4.4-style UIDs — not a defect, and not something to "fix" by hand.
- **`.godot/` is 15 MB of cache and it *can* hide breakage — proved**: in a scratch copy with a warm `.godot/`,
  I deleted the source `assets/textures/TX Tileset Grass.png` and `smoke_test.gd` still reported
  `--- result: PASS ---`. The imported `.ctex` in `.godot/imported/` is what gets loaded, so a missing or
  broken source asset stays invisible until the cache is wiped or an editor reimport runs.
- `.godot/export_credentials.cfg` exists but is all empty values — no secrets leaked.
- **Duplicate generated file**: `CONVERSION.md` is byte-identical to `docs/LEGACY_CONVERSION_NOTES.md`.
- `.hermes/` (agent research) lives inside the project and is not gitignored.

## 7. Risk inventory for automated edits

| File | Size | Edit risk | Why | What catches a regression |
|---|---|---|---|---|
| `tools/convert.gd` | 2076 lines, 73 KB | **Do not hand-edit.** Dead one-shot migration. | Hardcoded Windows source (`:35`); regenerates `main.tscn`, all `.tres`, `CONVERSION.md`. Any edit is unverifiable here because it cannot run. | Nothing. No test covers it. |
| `scenes/main.tscn` | 195 KB | **Generated — do not hand-edit.** | Output of `convert.gd:1957`. | `tools/smoke_test.gd` (structure only, exit always 0), `tools/play_test.gd` (behaviour, 1 known headless failure). |
| `scripts/core/pixel_art.gd` | 1106 lines, 45 KB | High — every visual depends on it. | Procedural art for pets, monsters, bosses, cottage, props, portals, ship, UI icons. | `tide_test.gd:82` (boss art for 10 portals), `:170` (horse art), `pixel_test.gd` (house sizes). |
| `scripts/world/lobby.gd` | 1211 lines, 44 KB | **Hottest file.** | Builds the entire hub: shops, 12 residents, 73 trees, gates, editor, emergencies. | Group 2 (22 checks, `:126-194`) + group 7 (17 checks, `:494-557`). |
| `scripts/autoload/game_state.gd` | 1287 lines, 39 KB | Highest blast radius. | Owns economy, saves (`SAVE_VERSION` `:21`), recovery, emergency, layout; autoload for every scene. | Every economy check (`:215-292`), save/load (`:646-666`), and the initial `has_existing_save` check (`:19`). |
| `scripts/ui/game_hud.gd` | 736 lines, 25 KB | Medium-high. | The tests assert **private** members: `_health_bar`, `_pet_bar`, `_toast_box`, `_build_mode_panel`, `_joystick`, `_attack_button`. | Groups 1, 4, 10 all read these by name; renaming one breaks several checks at once. |
| `scripts/ui/pet_battle_panel.gd` | 470 lines, 18 KB | Medium. | Duel maths; test pokes `_player_hp`, `_opponent_hp`, `_turn_timer`, `_enemy_choice`, `_process()` directly (`:350-368`). | Group 4. |
| `tools/tide_test.gd` | 767 lines, 37 KB | Medium — it is the oracle. | 250 runtime checks; hardcoded expected numbers (25 gold potion `:220`, +2 wood `:209`, +8 gold `:212`, 2 s recovery `:280`). | Itself; a weakened assertion silently removes coverage. |
| `scenes/game.tscn` / `scripts/game/game.gd` | 6 lines / large | Low/medium. | Entry point; tests call `_on_character_selected`, `open_shop`, `toggle_build_mode`, `_load_lobby` by name. | Group 1 + 10. |

Coupling warning: the suite reaches into private state (`hud.get("_…")`, `panel.set("_turn_timer", 0.0)`,
`game.call("_load_lobby", false)`, `forest_monster.call("_can_see_player")`). Private renames are **breaking
changes** here even though GDScript will not complain.

## Verified commands

All run from `/home/roku/Documents/games/tournamentgame/GAME_COMP_RPG-Godot`.

```sh
# 1. Toolchain — OK
$ godot --version
4.7.2.stable.arch_linux.ed1daf0bf

# 2. The real gate — RED, exits 1 (reproduced twice)
$ godot --headless --path . res://tools/tide_test.tscn ; echo "EXIT=$?"
...
[FAIL] forest trees are invulnerable to structural damage
...
--- tide test: 250 checks, 1 FAILURE(S) ---
WARNING: 4 ObjectDB instances were leaked at exit (run with `--verbose` for details).
EXIT=1
# 249 [OK] + 1 [FAIL] = 250; project tree unchanged; user://tidesworn_save.json DELETED.

# 3. Import/parse sweep — exits 0 and proves nothing by exit code
$ godot --headless --path . --editor --quit ; echo "EXIT=$?"
(no SCRIPT ERROR, no warnings)
EXIT=0

# 4. Fresh-checkout bootstrap — REQUIRED before step 2 on a clean copy
$ godot --headless --path . --import ; echo "EXIT=$?"
EXIT=0            # creates .godot/global_script_class_cache.cfg

# 5. Legacy structural check — PASS, but always exits 0
$ godot --headless --path . --script tools/smoke_test.gd ; echo "EXIT=$?"
--- checks ---
  [OK] player (CharacterBody2D) -> 1
  [OK] camera (Camera2D) -> 1
  [OK] chest (Area2D) -> 1
  [OK] popup (ColorRect) -> 1
  [OK] stairs triggers (Area2D) -> 7
--- result: PASS ---
EXIT=0

# 6. Legacy behaviour check — 1 failure headless
$ godot --headless --path . --script tools/play_test.gd ; echo "EXIT=$?"
[FAIL] character moved towards the click
--- play test: 1 FAILURE(S) ---
EXIT=1

# 7. Art smoke — only works as a scene
$ godot --headless --path . res://tools/pixel_test.tscn ; echo "EXIT=$?"
building house 1
  -> 224x176
... (5 levels)
done
EXIT=0

# 8. Wrong invocation for pixel_test — documented here so nobody repeats it
$ godot --headless --path . --script tools/pixel_test.gd ; echo "EXIT=$?"
ERROR: Can't load the script "tools/pixel_test.gd" as it doesn't inherit from SceneTree or MainLoop.
EXIT=1
```

`NOT RUN` (with reason): any `--export-*` (brief forbids exporting; templates missing anyway);
`godot --path . res://tools/tide_capture.tscn` (opens a window); `tools/convert.gd` (source project absent);
`tools/setup_input.gd` and `tools/make_icon.gd` (they rewrite `project.godot` / `icon.ico`).

## Conventions observed

- **Every tool carries its invocation in the header doc-comment**, including flags and the reason it is a
  scene rather than a script:
  `tools/tide_test.gd:2-4` — `## Run as a scene so project autoloads are initialised:` /
  `##   godot --headless --path . res://tools/tide_test.tscn`. Same pattern at `tools/smoke_test.gd:2-7`
  and `tools/tide_capture_node.gd:2-3`.
- **Assertions are `_check(condition, "present-tense claim")`**, and the label reads as the property being
  guaranteed, not as the action performed: `tools/tide_test.gd:763` +
  `tools/tide_test.gd:147` `"forest trees are invulnerable to structural damage"`. Older harnesses keep the
  same label style with a `bool` return: `tools/play_test.gd:220-222`.
- **Large scripts separate subsystems with `# ---- name ----` banners**: `scripts/autoload/game_state.gd:834`
  `# --------------------------------------------------------------- portals`.
- **Docs are structured as `##` sections with tables for catalogues** (`docs/ARCHITECTURE.md:68-77`), and each
  acceptance rule is a bullet that names the exact API it constrains
  (`docs/ACCEPTANCE_TESTS.md:67` "`take_attack_damage()` must leave health unchanged").

## Gotchas / footguns

1. **Exit 0 does not mean healthy.** `--editor --quit` exits 0 with parse errors; `smoke_test.gd` exits 0 with
   MISSING nodes. Grep stdout for `SCRIPT ERROR|ERROR:|\[FAIL\]|MISSING` or you will ship broken code.
2. **`tide_test` deletes the player's save.** Back up
   `~/.local/share/godot/app_userdata/Save The World/tidesworn_save.json` before running, or accept losing it.
   This is true even for a **copy** of the project: the `user://` directory is keyed on `config/name`
   (`project.godot:13` "Save The World"), not on the project path, so my scratch-copy runs deleted the same
   real save. I restored it from a pre-run copy each time (final sha256 `999ed80c…`, 2956 B).
3. **A fresh clone hangs, it does not fail.** No `.godot/` → parse errors → `_ready` never reaches `quit()` →
   infinite run. Always `--import` first, and always wrap test runs in `timeout`.
4. **`.godot/` masks missing assets.** A deleted source PNG still "passes" from the cached `.ctex`.
   When an asset change is in doubt, delete `.godot/` (or reimport) before trusting a green run.
5. **`--script` ≠ scene.** Scripts extending `Node` (`pixel_test.gd`) must be run as `res://…tscn`;
   `SceneTree` scripts must be run with `--script`. Both mistakes look like unrelated errors.
6. **The suite is coupled to private members.** `hud.get("_toast_box")`, `panel.set("_turn_timer", 0.0)`,
   `game.call("_load_lobby", false)` — renaming a private var is a breaking change.
7. **"250 checks" is dynamic.** 212 static call sites expand to 250 at runtime because of loops; never treat
   the number as a constant in docs or assertions.
8. **`build/` will fool you.** The APK/EXE predate the current source by hours; nothing rebuilds them.
9. **`convert.gd` is a loaded gun.** One run rewrites `scenes/main.tscn`, 355 asset resources and `CONVERSION.md`.
   It cannot even find its input here, but do not "fix" it casually.
10. **`export_presets.cfg` is gitignored.** Any VCS initialisation silently drops the build configuration.
11. **`tide_capture` writes into `res://shots` by default** — the one tool that dirties the working tree.
12. **Docs lie in a specific direction**: they claim invulnerable trees and a Pass that stopped being true at
    2026-10-21 08:19. Trust the code and the suite output over every `.md` here.

## AGENTS.md candidate rules

1. Run `godot --headless --path . --import` once after any fresh checkout; without it the project cannot even parse.
2. Wrap every headless run in `timeout` — a broken script makes the game loop hang instead of exiting.
3. Treat `godot --headless --path . res://tools/tide_test.tscn` as the only real gate; require `0 FAILURE(S)` and exit 0.
4. Verify results by grepping stdout for `[FAIL]`, `SCRIPT ERROR`, `ERROR:`; never trust an exit code alone.
5. Back up `user://tidesworn_save.json` before running the suite — it deletes the save twice.
6. Re-run `--import` (or delete `.godot/`) after touching assets; the cache hides missing sources.
7. Never edit `scenes/main.tscn` by hand; it is generated by `tools/convert.gd`.
8. Never run `tools/convert.gd`; its input path is a dead Windows path (`tools/convert.gd:35`).
9. Never run `tools/setup_input.gd`; it rewrites `project.godot` (`:26-27`).
10. Do not run `tools/tide_capture.tscn` in automation; it needs a window and writes `res://shots`.
11. Do not trust `tools/smoke_test.gd` as a gate; it always exits 0 (`:53`).
12. Run `tools/play_test.gd` only with a real display; its headless click maths is wrong by construction.
13. Keep `export_presets.cfg` in version control (remove it from `.gitignore:4`) before any `git init`.
14. Do not hardcode check counts (`250`) in docs or code; the tally is data-driven.
15. Do not rename private members of `game_hud.gd`, `pet_battle_panel.gd`, `game.gd`, `forest_tree.gd` — the suite calls them by name.
16. Update `tools/tide_test.gd` and `docs/ACCEPTANCE_TESTS.md` together whenever a rule changes (`docs/ACCEPTANCE_TESTS.md:111-112`).
17. When the suite and a doc disagree, believe the suite and fix the doc in the same change.
18. Keep all state mutation inside `GameState`; never touch `data.*` fields directly outside it.
19. Do not add `/home/...` or `C:/...` absolute paths to tracked files; they already break `convert.gd`.
20. Do not run an export in this checkout; templates are absent and the debug keystore path is dead.
21. Treat `build/` as stale by definition; rebuild deliberately and record the command.
22. Remove or ignore `res://shots` output before committing anything.
23. Keep `.uid` files paired with their `.gd` files; never delete them to "clean up".
24. Prefer scene-based harnesses (`extends Node` + `.tscn`) for anything that needs autoloads.
25. There is no git history here — copy files before large edits rather than assuming you can revert.

## Open questions

- **Were the trees meant to become damageable?** `forest_tree.gd:3-4` describes them as "protected village
  trees. Raiders target these", and `:35-49` implements real damage plus felling, which matches the raid
  design — but every doc and one assertion say invulnerable. Settle it by product intent, then either
  revert `:39` or rewrite `tools/tide_test.gd:147` and the five doc passages. **This single decision is the
  difference between a green and red suite.**
- **Was the "250 checks, PASS" ever true for this exact tree?** Timestamps say yes (docs 04:50–05:11,
  `forest_tree.gd` 08:19), but there is no VCS to prove it. Settle by asking the author or by recovering an
  older copy.
- **Is Android on-device testing still pending?** `docs/QA_REPORT.md:8` and README:210 say yes; nothing in
  the repo records a device run.
- **Who builds `build/`?** No script, Makefile or CI exists; the `.idsig` suggests an external `apksigner`
  step. Settle by asking, or treat `build/` as disposable.
- **Are `play_test.gd` / `smoke_test.gd` / `pixel_test.gd` still wanted?** They only cover the legacy
  `main.tscn` demo and are not referenced by README's verify block (`README.md:184-187`). They could be
  archived to reduce agent confusion.
- **Does the visible HUD still satisfy the "readable at 832×480" claim?** `docs/QA_REPORT.md:24` and
  `docs/ACCEPTANCE_TESTS.md:104-105` assert it; that needs a real-window visual check I could not run
  (`UNVERIFIED`).
