# Dimension crash investigation — 2026-10-30

## Report and limits

The reported symptom is an immediately disappearing game window after about
3–5 minutes, observed while fighting a dimension boss. The exact process exit
has not been reproduced. The fixes below address confirmed combat defects; they
are not proof that every cause of an abrupt native exit has been eliminated.

The live Windows logs contained earlier `Trying to cast a freed object` errors
in `TwilightRealm._physics_process` and `RealmEncounterDirector._living`.
The current checkout already checked instance validity before those casts.
The new regression lets a guard actually leave the tree and be freed, then
advances both the director and realm physics. This covers the logged failure
boundary rather than checking only `queue_free()` in its original frame.

Windows also contained a `RADAR_PRE_LEAK_64` event for the Godot executable.
It does not identify a leaking gameplay subsystem or establish the cause of
this incident. The inspected Application/System events supplied no matching
native application-fault or display-driver-reset report. Old script errors
and this generic memory warning must not be presented as a proven native crash.

## Confirmed fixes

1. **Repeated summon after deletion:** `ElementalBoss._execute_skill()` used
   `Array.filter()` with an `Enemy`-typed callback. Godot converts the callback
   argument before entering its body, so an `is_instance_valid()` inside that
   body cannot protect a freed reference. The reproduction emitted an argument
   conversion error followed by a typed-array assignment error. The boss now
   prunes invalid, queued and dead handles directly, then fills the existing
   three-living-minion budget. No summon stats or rewards change.
2. **Incomplete citadel activation:** the first realm enabled `boss.active`
   without calling `_notify_boss_start()`. The inherited special-attack loop
   requires `_boss_notified`, so an apparently active boss could never begin
   its authored powers. Crossing the threshold now starts that lifecycle;
   the new soak test verifies that repeated powers actually execute.

The summon defect belongs to the shared elemental boss code and is exercised
by the Decay boss. The first realm's Chaos boss does not use the summon pattern;
the summon reproduction alone cannot explain a first-realm native process exit.

## Repeatable checks

`tools/test_isolated.ps1 -Godot <console-executable> -Stability` runs 450 seconds
of simulated realm time, including 300 uninterrupted seconds of boss combat,
three guard encounters, real corpse deletion, retreat/re-entry, victory and
peaceful exploration. It then performs twelve realm/village replacement cycles.
The default headless mode uses `--fixed-fps 60` to accelerate simulated time.
`-Stability -Realtime -Resolution 832x480` uses the native renderer and wall-clock
pacing; 1280x720 is also supported. Isolation and failure-marker/exit/summary
requirements are the same as the canonical gameplay wrapper.

The harness records `stability_samples.json`, including engine CPU allocations,
render-reported video memory, node/object/resource counts, orphans and texture
cache size. It checks warmed bounds rather than expecting cold and warm caches
to have identical sizes. The player is protected and held at encounter test
sites; the automatic companion is disabled during the sustained casting phase.
This is a deterministic lifecycle/load test, not ordinary player pacing.

## Evidence on a future abrupt exit

`Game` now owns a small `RuntimeDiagnostics` child. It flushes an independent
record every 30 seconds to `user://logs/runtime_<process-id>.jsonl`, including
the current world, portal, player position, boss HP and memory/object counters.
It records session start and normal scene-tree shutdown. An absent end record
indicates interrupted teardown, which can also result from force-stopping a run;
it does not by itself identify a crash cause.

Each process uses its own file. At 256 KiB the file rotates to one previous
segment. Diagnostics do not change journey saves or device preferences.
Normal Windows logs are under
`%APPDATA%/Godot/app_userdata/Protect Besut/logs/`. Test logs stay inside their
printed isolated temporary directory. Pair the newest runtime record with
Godot's error log and any Windows fault report if the window disappears again.

## Verification completed

Native Windows, Godot `4.7.2.stable.official.ed1daf0bf`, NVIDIA RTX 3050 Laptop,
Compatibility/OpenGL. All tests used isolated user data and preserved the normal
player save and existing project/import edits.

| Check | Result |
| --- | --- |
| Canonical gameplay gate | 5,844 checks, PASS, exit 0; error log empty |
| Rendered Twilight review, 832x480 | 182 checks, PASS, exit 0; error log empty |
| Final accelerated stability test | 32 checks, PASS, exit 0 |
| Final native real-time stability test, 832x480 | 32 checks, PASS, exit 0; error log empty; about 469 s including builds/transitions |
| Additional rendered active combat, 1280x720, accelerated | 360 simulated seconds, 781 accepted player attacks, companion support, 86 boss powers; PASS, exit 0; error log empty |
| Isolated import | Exit 0; existing Android build-tools-directory warning |

The active-combat fixture restored boss HP to keep the real melee/companion/hit
feedback paths running. It peaked at 48 processed tweens and stayed within its
16 MiB warmed CPU-allocation bound. It was a disposable additional investigation
fixture, not a new ordinary gameplay rule or wall-clock-duration claim.

In the final native stability run, boss-phase CPU allocations were about
111.17 MiB both after warm-up and at the end. Render-reported video memory grew
from 18.84 to 26.96 MiB as buffers warmed, then plateaued. On village replacement
cycles 3 through 11, nodes stayed at 1,573, objects at 4,308, orphans at zero and
video memory at 60.98 MiB; CPU allocations changed from 117.43 to 117.44 MiB.
These observations do not show runaway accumulation in the exercised paths;
they do not prove the absence of an intermittent driver/native allocation defect.

The accelerated headless test intermittently reports two ObjectDB instances at
shutdown. A separate verbose diagnostic identified `AudioStreamWAV` and
`AudioStreamPlaybackWAV` retention during audio teardown. The final native soak,
rendered review and canonical gate did not emit that warning. This distinction
is preserved rather than describing every log as warning-free.

Evidence directories under `C:/Users/ayiz/AppData/Local/Temp/`:

- Original failing summon reproduction: `tidesworn-tests-605bb1b9546145ad9cda906bcfff67a9`.
- Final canonical gate: `tidesworn-tests-3558ba4a707148329d144dff39268cef`.
- Final rendered Twilight review: `tidesworn-tests-9bab1224218e451eb473d526ac7596e7`.
- Final accelerated stability: `tidesworn-tests-5cb1f80fada2482db36973b06b206d5e`.
- Final native stability, samples and inspected boss capture: `tidesworn-tests-0dbae9ae1cf34131a9390d944932b508`.
- Additional active-combat scene/script, log and capture: `besut-combat-stress-af621029b7cf4987abc88b7ae9115295`.
- Final isolated import: `tidesworn-tests-3e3de87be6b8439b8f094ffeef23d5d0`.

An earlier 1280x720 native soak also completed without a script/native error,
but its original test assertion incorrectly counted only the last boss skill
index after a deliberate reset; that run is not cited as an acceptance PASS.
The corrected harness accumulates skills across resets and passes at 832x480.
