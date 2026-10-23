# Tidesworn deep audit — 2026-10-23

Audited the actual runtime on `visual-overhaul-merge-2`, Godot
`4.7.2.stable.arch_linux.ed1daf0bf`, including desktop GL Compatibility on
Intel UHD 630. This follow-up supersedes the 375-check result in
`VISUAL_REPAIR_REPORT.md`. Verification completed before the user requested
the local repair commit; no push or merge was requested.

**Final acceptance: 408 checks, PASS, exit 0. Native graphical audit: 63 checks,
0 failures, exit 0. Final import: exit 0, no script/parse errors.**

The old 375-check suite passed while the first new edge-case probes failed
14 assertions. Additional probes exposed simulation, migration, outline and
home-defeat problems. Passing the previous suite was insufficient evidence.

## Findings and fixes

| Priority | Confirmed problem | Implemented correction and verification |
|---|---|---|
| P1 | Joystick presses were transformed twice: `_gui_input` already supplies local coordinates. Center presses produced movement, especially after GUI scaling. | Use local press coordinates and inverse-transform viewport drag coordinates once. Checks cover center/right/drag at 75/100/130%, plus real `Window.push_input` dispatch at three resolutions. |
| P1 | Lethal damage at home left the player permanently dead. This predated the visual repair. | Route home defeat through the existing recovery ward after the collapse animation. Count one death, restore critical HP/half mana and companion, preserve inventory/currencies/progression. Guard duplicate defeat signals, transitions and forest game over. Tests perform real lethal damage and verify the new living player and exactly one completed recovery transition. |
| P2 | Optional hit-stop stopped enemy physics, cooldowns and travel. Reduce Motion therefore changed gameplay timing. | Freeze the visual clock only. Compare attack-clock progression and distance traveled with Reduce Motion enabled/disabled. Both originally failed and now pass. |
| P2 | Residents kept paths through moved obstacles; blocked movement checked collision-zeroed velocity and could never trigger replanning. | Track route revisions, invalidate on committed building drags and falling trees, compare intended versus actual movement, and follow collision-clear corners. A resident reroutes around an inserted wall; a pet completes a 300-tick detour without crossing it or jumping. |
| P2 | Customers accepted a nearby fallback cell when a shop counter was obstructed, allowing a remote purchase. Direct attacks also left shopping reservations occupied. | Require an accessible counter endpoint for shopping, release the reservation immediately on fear/attack, retain finite visit timeouts. Test both a blocked counter and an attacked customer. |
| P2 | Resetting a custom enlarged touch control left its old physical size. Pure window resizing could leave touch targets below the physical minimum. | Reset minimum size before actual size; update layout on window-size changes; preserve Pack/Build separation when another control is customized. Check every control and Menu against 44 physical pixels at 1280×720, 832×468 and 832×480, across three GUI scales. |
| P2 | Hidden or freed controls could retain synthetic pressed input. | Cancel joystick/action input on hide, focus loss and removal, and accept mouse release outside the joystick. Lifecycle tests verify movement/actions are released. |
| P2 | Merchant sprites rendered at effective z=14 while player sprites used z=6. | Keep merchant/guard/tool children on their actor's shared sorted layer. Verify effective merchant/player layer equality and inspect fresh market images. |
| P2 | Low→High effects changes did not create dungeon ambience when entered at Low. Existing particles could linger under Reduce Motion. | Lazily create the emitter once, then update visibility/emission live. Tests cover creation, immediate hiding and reuse without allocation churn. |
| P2 | Deferred world deletion could return a VFX pool inside a queued world. | Reject queued pools and every queued ancestor in both pool lookup and creation. Test overlapping old/new worlds before deferred deletion finishes. |
| P2 | Legacy GUI scale migration was loaded but never persisted, so a subsequent journey could reset it. | Save the migrated device preference once when the config is absent or lacks UI scale. Reload after changing the legacy journey value to prove independence. |
| P2 | Recovery/build outlines used art-pixel widths as world units. A 2-unit selection border became 76 screen pixels at default zoom. | Express widths with `PixelArt.PX`; preserve gameplay radius/selection bounds. Before/after actual-game images confirm the repair. Reduce Motion now also stops optional ward rotation/pulse. |
| P2 | Capture scenes could modify normal user data; an engine exit of zero without running acceptance could appear green. | Shared `TestEnvironment` refuses unverified user-data paths before creating/deleting a journey. The isolated runner also requires a PASS summary. Negative probes verify isolation refusal and rejection of a fake zero-exit engine. |
| P2, test | The auto-loot test touched only the first drop, then required an empty floor. A random additional gem caused a false failure. | Touch every remaining drop before asserting floor clearance; retain the actual auto-collection and expedition-gold assertions. This was found by the final full gate, rather than suppressed by rerunning an unchanged flaky check. |

## Verification and evidence

Evidence root: `/tmp/tidesworn-audit-a5lwhhkt/`. Temporary files are local review
artifacts and may be removed by the operating system later.

| Evidence | Result |
|---|---|
| `probes-before.log` | Prior 375 checks passed; the new probes produced 14 failures. |
| `gameplay-probe-before.log`, `migration-before.log`, `home-defeat-before.log` | Reproduce effects-dependent simulation, nonpersistent migration, and home death respectively. |
| `audit-final-gate2.log` | `./tools/test_isolated.sh`: **408 PASS**, exit 0. Actual isolated directory `/tmp/tidesworn-tests-Gl50AU7R`; full `test.log` remains there. No `[FAIL]`, `SCRIPT ERROR` or `ERROR:`. |
| `audit-final-graphical.log` | Real desktop window, **63 checks, 0 failures**, exit 0. Includes actual resize and GUI input dispatch, collision detours, effects changes and lethal home damage. |
| `audit-final-import.log` | Isolated `--headless --editor --quit`, exit 0; no script/parse errors or warning lines. |
| `isolation-refusal.log` | Deliberately mismatched test root refuses to start, exit 1, before journey creation. |
| `false-green-refusal.log` | Fake engine exits zero without acceptance; safe runner returns 1 with `Acceptance summary missing or incomplete`. |
| `shots/` | 52 fresh game captures inspected through six labeled contact pages, covering title, village, shops, panels, dungeon, combat, coast, turtle, BESUT, shopping states, all quality/motion combinations, zoom and GUI scales. |
| `world-lines-before/`, `world-lines-after/` | Full-size build-mode and ward screenshots inspected before/after the world-width fix. |
| `motion.avi`, `motion.json` | 569 rendered frames at 60 FPS and 566 physics samples. Actual movement includes cardinal/diagonal travel, turns, stopping/restarting, extended pet follow, enemy chase, resident motion and zoom changes. |
| `movie-frames/consecutive-310-317.png` | Eight consecutive rendered frames inspected at native crop resolution, showing intermediate player/pet/enemy/camera positions. No ordinary-motion teleport in this reviewed sequence. |
| `git diff --check` | Clean after edits. |

The graphical driver prints an NVIDIA DRI probe failure before successfully
using Intel OpenGL. It produced no Godot script, shader or runtime error in the
successful graphical run. It is not evidence of NVIDIA device validation.

At 60 Hz the movie's largest sampled per-tick displacements are 0.073334 world
units for the player, 0.150000 for pet catch-up and 0.110973 for the camera.
565 of 566 sampled positions per actor/camera are fractional relative to the
art grid. These measurements support, rather than replace, visual inspection.
Nearest sampling remains enabled; noninteger zoom can still vary pixel coverage.

The movie and 52-scene tour were captured before the final home-defeat and
outline corrections. Those corrections were subsequently verified by the full
gate, the 63-check graphical run, and the dedicated before/after images. They
did not alter the reviewed movement implementation.

## Reproduction

From the repository root:

```sh
./tools/test_isolated.sh

review_dir=$(mktemp -d /tmp/tidesworn-review-XXXXXXXX)
export TIDESWORN_TEST_ROOT="$review_dir"
export XDG_DATA_HOME="$review_dir/userdata"
timeout 120 godot --path . res://tools/deep_audit_test.tscn
timeout 180 godot --path . res://tools/visual_review.tscn -- --shots "$review_dir/shots"
timeout 180 godot --path . --write-movie "$review_dir/motion.avi" --fixed-fps 60 res://tools/motion_review.tscn -- --samples "$review_dir/motion.json"
```

Inspect logs and actual images; exit code alone is insufficient. Graphical
commands require a display. All harnesses write ordinary journey/settings data
and therefore require the explicit isolation above.

## Preservation and limits

`main` remains `4f1d6e1cd401799221d26040a0a04962fd2b8e15`. Incoming changes
were recorded in `before.patch`; the concurrent `ui_theme.gd` formatting edit
was preserved. Existing repository screenshots/builds were not regenerated.

Real data was backed up in `real-data-backup/` before this audit. Every test,
import and capture used separate XDG data; harnesses printed their verified
actual user-data paths. Real `settings.cfg` still matches its backup. The real
journey changed during the audit while the separate live game/editor session
was in use; both its initial and final snapshots are retained. The real journey
was never restored or overwritten by this audit.

This is a desktop runtime and repair audit, not a claim of exhaustive testing
on every platform or user-created settlement. Physical Android touch,
export/install, frame pacing on other GPUs/refresh rates, every arbitrary
building layout and long-duration soak behavior remain unverified. Existing
orphaned pause UI and broader content/design limitations were not expanded into
new features. The game intentionally continues simulation behind modals.
