# Three-second animated startup splash

## Player-facing contract

Normal app launch now runs `res://scenes/startup.tscn` before the existing `res://scenes/game.tscn`. The startup scene plays the edited three-second Protect Besut movie **once and in full**. Fast game loading never skips or abbreviates it. Slow loading never loops it: the complete final logo remains visible with a quiet Loading indication until resources are ready.

Game is instantiated only after both playback completion and at least three active seconds. The final logo also covers main-thread Game setup and its first rendered frame, then dissolves into the existing title over 0.22 seconds. The title handoff is additional to the three-second movie, not subtracted from it. Start/Continue, boat introductions, saves, world clock, village/ocean transitions and endings keep their existing Game ownership.

The engine's earlier native splash is **black with its static image disabled**, preventing an old fully visible logo from flashing before the video. Engine and autoload initialization necessarily occur before the startup scene can render; that phase stays black. The video is not claimed to play before Godot has initialized.

## Media edit

Input: user-supplied `gemini_generated_video_1672e84a.mp4`, original container duration 10.026667 seconds, 1280×720 at 24 fps. Original bytes remain unchanged.

- Remove the generated visible → dark → visible false entrance.
- Retain source animation from 0.8 through 3.3 seconds at normal speed; do not accelerate the whole ten-second movie.
- First 0.125 seconds are completely black. Fade the entire composition in from 0.125 to 0.75 seconds.
- Dissolve lingering glints/particles to the clean final source logo from output 2.0 to 2.5 seconds, then hold it through 3.0 seconds.
- Retain the corresponding original audio excerpt at reduced gain, with short fade-in/out and a silent final hold; no new music/voice was generated.
- Deliverable MP4: exactly 72 frames / 3.000 seconds. Game stream: native Ogg Theora + Vorbis / 3.000 seconds. Theora may represent identical frames with duplicate packets rather than separately coded frames; presentation timing remains 24 fps.
- A PNG decoded from the final Theora frame supplies the held/fallback logo. Its extraction decodes to the end rather than seeking to a possibly omitted duplicate frame packet.

Assets: `res://assets/video/protect_besut_splash.ogv` and `res://assets/video/protect_besut_splash_hold.png`. The convenient edited MP4 is retained in the external transaction's `startup-splash/Protect_Besut_Splash_3s.mp4`; no unsupported MP4 decoder/plugin is required by the game. Existing export settings include all resources, including these assets. No existing APK was rebuilt or replaced by this task.

## Loading and lifecycle ownership

`StartupSplash` is deliberately independent of Game/HUD construction. It uses `ResourceLoader.load_threaded_request()` and polls status on separate frames. `load_threaded_get()` is called only after LOADED, avoiding a synchronous wait while the video is running.

The handoff condition is:

```
movie completed AND active elapsed >= 3 seconds AND PackedScene ready
AND window focused AND no handoff already claimed
```

The movie's real `finished` signal owns completion; no early resource-ready event stops it. Clicks, taps and keys cannot skip startup or activate a not-yet-created title. The loader is one-shot. Focus loss pauses the decoder, elapsed accounting and any in-progress reveal; focus return resumes the remaining presentation. Device master/mute and effects volume remain respected.

If the game resource fails, finish the movie first, then present Retry loading over the final logo. Retrying the load does not replay the completed film. A missing/failed video uses a black-to-logo poster presentation with the same minimum duration instead of stranding startup. Closing/freeing startup stops playback and cannot cause a late handoff. The new scene installs the ordinary Game as `current_scene`; returning to title later does not replay startup.

## Verification

- `tools/test_startup_launch.ps1 -Godot <console-executable>` refreshes imports, then launches the configured main scene in a fresh process without test-side Game preloads. Add `-Native -Resolution 832x480` (or `1280x720`) for a rendered menu capture. The check requires the splash to disappear, exactly one Game with a usable Start Game button, the full minimum duration, and successful navigation to the hero page. The wrapper rejects script/resource errors even if Godot exits 0.
- `tools/startup_splash_checks.gd`: fast gate truth table, native black engine boot, stream/poster types and exactly-once guard; included in the canonical gameplay suite.
- `tools/startup_splash_review.tscn`: actual decoder and threaded-load review. Covers ready-before-film-end, delayed readiness with held final frame, keyboard input, focus pause/resume, missing-video fallback, failed-load retry, cancellation, real Game handoff, and uniform fitting at 1280×720 / 832×480 / 360×780.
- Media QA checks the first three presented frames are exactly black, confirms rising fade samples, three-second durations and near-static final half-second, and records audio levels plus hashes.
- All tests use isolated user data. Linux Xvfb/Mesa llvmpipe validation is distinct from unperformed Windows-native, Android hardware or export testing.

### Local startup stuck at the logo after updating source

On 2026-11-03, the Windows player log showed missing global classes (`CombatVisuals`, `CombatBodyMotion`, `CombatPoseArt`, `CombatHit`, `CombatImpact`, `OpeningCastRenderer`) and a missing imported splash poster. These compilation failures cascaded into incomplete HUD/title construction. Refreshing imports with `tools/test_isolated.ps1 -Godot <console-executable> -ImportOnly` rebuilt the class cache and poster, and fresh launches reached the menu. Restart an already running failed player after importing; its failed script instances cannot recover from the on-disk cache refresh. No journey reset or save deletion is required.

Verification on Windows / Godot 4.7.2: fresh headless and native 1280x720 launches reached the complete menu; the final native 832x480 launch check also exercised Start Game navigation. Both menu captures were inspected. The decoder/lifecycle review passed 39 checks and the canonical gameplay gate passed 8,691 checks, each with exit 0 and no failure/error markers. Existing save-warning entries occurred in the gameplay fixtures; import retained the Android build-tools-directory warning. Evidence is under `%TEMP%/pb-startup-0e068382fb654cdaa7bdab2074fdfd9d`, `%TEMP%/pb-splash-review-62631e27de5e45f7a336b42a557efcf2`, and `%TEMP%/tidesworn-tests-ffa74a8b0d7a4e4c97b1dccd2ec4225a`. The failed normal player was restarted with refreshed imports; no release export or phone validation was performed.

The existing four artifact role paths are reused. Current rollback restores commit `d9e6fc3` (static splash/direct Game startup), preserving both committed boat-introduction passes and the newer combat-visuals commit. Previous role versions remain under the supplemental `startup-splash/prior_roles/` record. Literal commands, outputs, corrections and current results are appended to `VERIFICATION.txt`.

## Implementation references

- [Godot VideoStreamPlayer: native Theora playback and finished signal](https://docs.godotengine.org/en/stable/classes/class_videostreamplayer.html)
- [Godot ResourceLoader: threaded request/status/get](https://docs.godotengine.org/en/stable/classes/class_resourceloader.html)
- [Godot ProjectSettings: boot_splash/show_image](https://docs.godotengine.org/en/stable/classes/class_projectsettings.html)
