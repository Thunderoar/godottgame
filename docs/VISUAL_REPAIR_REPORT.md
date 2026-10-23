# Tidesworn visual and movement repair

**Follow-up:** the deep audit found additional defects after this initial repair.
Use [DEEP_AUDIT_REPORT.md](DEEP_AUDIT_REPORT.md) for the superseding 408-check
acceptance result, 63-check graphical audit, fixes and remaining limits.

Verified 2026-10-23 on `visual-overhaul-merge-2`, Godot
`4.7.2.stable.arch_linux.ed1daf0bf`, actual GL Compatibility renderer on Intel UHD 630.
The branch was switched from a clean checkout to the requested remote tracking
branch. `main` remains at `4f1d6e1cd401799221d26040a0a04962fd2b8e15`.
Implementation and verification preceded the user's request for a local commit;
no push or merge was requested.

## Result

**375 checks, PASS, exit 0**, up from the incoming **314 checks, PASS**.
The final gate, import, graphical review, movie and restart verification contain
no relevant SCRIPT ERROR, ERROR or WARNING lines. Existing gameplay assertions
were retained. The two obsolete checks for removed VITALS bars were replaced by
checks for the preserved PlayerVitalHud and absence of the unwanted panel.

## Root causes and implemented fixes

| Request | Confirmed cause / investigation | Implementation and verification |
| --- | --- | --- |
| Missing trees | Shadow, sprites and Body were parented to Lobby at local origin rather than ForestTree. Persisted fallen trees became ready before a body existed. | Assemble all children before adding the tree; maintain local offsets, owned collision, hit/fall feedback and y ordering. Tree generation RNG/order/IDs are unchanged. Ownership, coordinates, independent damage, persistence and fallen collision are tested; eastern forest rendered and inspected. |
| Oversized effects | Portal particle scale/velocity used art-pixel magnitudes in world coordinates; dust used a 128px glow with excessive expansion; several lamps retained large texture scales; zoom 64 magnified everything. | Tune each category independently: small motes, low-alpha local pools, smaller dust/sparks/numbers/shields, fewer bursts, clamped shake. Keep pooling and critical combat telegraphs. Actual portal/combat frames and quality matrix inspected. |
| Random stars | Ambient pollen/butterflies, interaction markers, water sparkle, pet downed/growth auras and fake leaf textures all used generic stars. | Remove decorative sources; use small chevrons for interactions, actual net/leaf art and a curled downed pet. Keep meaningful impact sparks. No environmental replacements were added for omitted pollen/butterflies. Idle coast/village/forest and all quality combinations inspected. |
| Sea glitches | Full-map half-resolution mask filled water far beyond the ocean's painted x limit. Shader depth used map UV instead of shore distance; the painted ocean itself ended in a vertical rectangle. | Full-resolution mask samples the same two-pixel columns as paint, transparent outside real sea, shore-relative depth in mask red. Subtle shader has no sparkles. Close the final coast below the map and sample the same boundary for collision. Baked sand/wet sand/shallow/deep water provide stable low/reduced-motion fallback. Whole mask tested; coast west/middle/east inspected. |
| GUI scale | Center-pivot scaling of the full-screen root displaced edge anchors; GameState and GameSettings stored competing scale values; every slider tick saved. | GameSettings owns GUI scale; legacy API delegates and old saves migrate only if config lacks a value. Scale individual anchored HUD elements, keep root/modals/fades responsive, fit center panels, clamp controls, preserve physical touch minimum and spacing. Live preview commits on release/focus/close. All scales rendered at both requested sizes. |
| Zoom | Fixed zoom 64 with no user setting; camera manually rounded each update to 1/32 world units. | Separate labeled slider 28–64, default 38, percentage feedback, smooth equal-axis transitions, bounds and config persistence. Physics camera follow plus interpolation, nearest filtering retained. Bounds/default/persistence tested and zoom 28/38/64 rendered; restart and world round-trip probe passes. |
| VITALS | Dedicated top-right builder and unconditional refresh accesses. | Remove builder, call, exclusive members and refresh references. Keep PlayerVitalHud, XP, currency, menu, guidance, potions, touch controls and underlying player/pet stats. Gameplay suite passes. |
| Turtle | No suitable turtle art or grounded coast object existed. | Cached outlined olive turtle, ground shadow and small breathing animation. Place at x=14, coast(x) minus 1.3 world units on sand, above water. Placement tested and rendered. |
| BESUT | Existing road-sign texture could not display readable place lettering. | New shaded wooden board with exact BESUT lettering baked as pixel glyphs; no font layout ambiguity or glow. Roadside placement near spawn, consistent depth. Metadata tested and actual lettering inspected at zoom extremes. |
| NPC shopping | Residents only had daily routes/flee/defense; no ambient shopping state or counter ownership. | Explicit ROUTINE/WALK_TO_SHOP/BROWSE/PURCHASE/LEAVE states; varied private RNG, obstacle paths, acceleration/arrival tolerance, weak reservations, timeouts, emergency/unload cleanup, visible coin-to-goods handoff and keeper nod. Repeated visits and busy counters tested; all visit states rendered; player gold/inventory remain unchanged. |
| Continuous movement | Player was already a free-moving acceleration controller, not a tile controller. Actual jumps came from pet leash/feet projection and camera rounding; residents bypassed collision; chase velocity changed instantly; rubbish lateral drift lacked delta; loot retained perpetual gravity residue; portal entry nudged position. | Preserve player acceleration/friction/turning and normalized input, remove positional damage nudge, use actual velocity for animation. Pets/residents use CharacterBody2D with bounded continuous movement; obstacle planning never assigns cell coordinates. Smooth chase, correct coordinate conversions, delta drift and finite loot arc. Intentional spawn/respawn/world transitions remain. Sampled player/pet/enemy/resident/projectile/loot movement plus consecutive movie frames. |

Also fixed a missing `MultiMesh.mesh` assignment that caused actual GL renderer
errors and invisible grass, and the same misplaced-holder regression in cottages,
ruins, rubble and smoke. These were confirmed in source/runtime during this repair.

## Exact changed/new files

The table includes the preserved concurrent formatting edit so the complete
working tree is accounted for. UID files are generated Godot resource metadata.

| File | Reason |
| --- | --- |
| `AGENTS.md` | Correct repository/branch guidance, resolved tree rule and safe gate/current verification. |
| `README.md` | Describe repaired visuals, free movement, shopping, independent scale and safe verification. |
| `docs/ACCEPTANCE_TESTS.md` | Document expanded regression contracts, isolated commands and visual matrix. |
| `docs/ARCHITECTURE.md` | Document ownership, physics interpolation, settings authority and shopping/navigation. |
| `docs/COMPLETION_REPORT.md` | Append current verification and supersede historical visual claims. |
| `docs/QA_REPORT.md` | Append current verification and evidence reference. |
| `docs/VISUAL_OVERHAUL.md` | Replace superseded camera/ambient design and unsafe capture guidance. |
| `docs/VISUAL_REPAIR_REPORT.md` | This implementation and verification report. |
| `project.godot` | Enable physics interpolation; disable transform/vertex snapping while retaining nearest filtering. |
| `scripts/autoload/game_state.gd` | Delegate legacy GUI APIs to the authoritative device setting without writing the save on slider ticks. |
| `scripts/combat/boss_projectile.gd` | Size the orb glow to its collision/contact footprint. |
| `scripts/combat/enemy.gd` | Accelerate ordinary chase, share actor depth, correct reward/death coordinate space. |
| `scripts/core/follow_camera.gd` | Physics follow, smooth independent zoom, no art-grid position rounding, bounded accessible shake. |
| `scripts/core/game_settings.gd` | Sanitized persistent zoom; one-time legacy GUI-scale migration. |
| `scripts/core/pixel_art.gd` | Cached turtle, BESUT board with baked pixel lettering, leaf, mote, net and chevron art. |
| `scripts/core/shaders.gd` | Subtle alpha-bounded water, shore-relative depth and no random sparkle term. |
| `scripts/core/ui_theme.gd` | Formatting-only edit observed from the concurrent editor session; preserved, not rewritten by this repair. |
| `scripts/core/vfx_pool.gd` | Purpose-specific sizes/counts/alpha for pooled dust, sparks, rings, numbers and real leaves. |
| `scripts/game/game.gd` | Remove the instantaneous portal pull position nudge; retain portal presentation and world transitions. |
| `scripts/pets/pet.gd` | Collision-aware continuous catch-up and detours; remove leash/feet snaps and stars; smaller shields; additive pose animation. |
| `scripts/player/player.gd` | Preserve acceleration/turning; velocity-only damage recoil, consistent depth/spawn coordinates and motion-driven walk animation. |
| `scripts/ui/game_hud.gd` | Remove VITALS construction/refresh; anchor each scaled element, preserve full-screen roots, enforce physical touch minimum and spacing. |
| `scripts/ui/settings_panel.gd` | Separate live GUI/world sliders with feedback and commit-on-release/focus/close. |
| `scripts/world/beach_turtle.gd` | New grounded scenery with shadow and restrained breathing. |
| `scripts/world/beach_turtle.gd.uid` | Godot resource identifier for the turtle script. |
| `scripts/world/coastal_guard.gd` | Replace decorative star placeholder with appropriate net art. |
| `scripts/world/dungeon.gd` | Small ambient motes, restrained torch flicker and live Reduce Motion/quality gates. |
| `scripts/world/forest_tree.gd` | Animate actual registered child sprites; small leaf feedback; disable owned collider on live/loaded fall. |
| `scripts/world/interactable.gd` | Replace universal floating star with a restrained, motion-aware interaction chevron. |
| `scripts/world/lobby.gd` | Repair tree/cottage/ruin/smoke parenting, depth and lights; bound and close coast; fix grass mesh; place scenery; expose shared routes and live quality controls. |
| `scripts/world/loot_drop.gd` | Stop the launch arc after a short interval instead of adding endless residual downward velocity. |
| `scripts/world/portal_entrance.gd` | World-sized motes/lighting/aura and quality/motion-aware swirl. |
| `scripts/world/portal_exit.gd` | Honor Reduce Motion for exit swirl. |
| `scripts/world/resident.gd` | Collision-aware physics routes and explicit shopping with arrival/braking, timeouts and reservation cleanup. |
| `scripts/world/resident_routes.gd` | New shared obstacle-sampling path planner; planning cells never snap actor positions. |
| `scripts/world/resident_routes.gd.uid` | Godot resource identifier for the route planner. |
| `scripts/world/rubbish_piece.gd` | Delta-scaled lateral drift and correct initial coordinate conversion. |
| `scripts/world/rubbish_system.gd` | Place beached monsters correctly relative to their world parent. |
| `scripts/world/settlement_editor.gd` | Invalidate obstacle routes after editing while preserving intentional editor grid placement. |
| `scripts/world/shop_npc.gd` | Weak per-counter reservations and local ambient purchase acknowledgment, independent of player transactions. |
| `tools/motion_review.gd` | New deterministic graphical movement/zoom recording and per-tick samples. |
| `tools/motion_review.gd.uid` | Godot resource identifier for the motion harness. |
| `tools/motion_review.tscn` | Scene entrypoint for full-frame movie review. |
| `tools/test_isolated.sh` | New Linux gate with fresh user data, verified location, timeout and log inspection. |
| `tools/tide_test.gd` | 61 additional net checks over incoming baseline; replace obsolete VITALS checks with preserved world-vitals checks; verify isolation before destructive operations. |
| `tools/visual_review.gd` | Fresh visual matrix, actual shopping and motion samples; temporary output; explicit world cleanup. |

## Commands and evidence

All agent Godot runs that could open the project used explicit temporary
XDG_DATA_HOME. Evidence root: `/tmp/tidesworn-repair-_xmdo_0t/`.

| Command / operation | Result |
| --- | --- |
| `git status --short`, `git branch -a`, `git remote -v` | Clean incoming checkout; requested remote branch located. |
| `git switch --track origin/visual-overhaul-merge-2` | Requested local tracking branch created; main not edited. |
| `git diff --stat main`, source/docs reads and `rg` movement/effects/GUI audits | Specific regressions identified without replacing overhaul features. |
| `godot --version` | Exact requested 4.7.2 engine. |
| Temporary `verify_user.gd` under explicit XDG_DATA_HOME | Reported `/tmp/tidesworn-repair-_xmdo_0t/userdata/godot/app_userdata/Save The World` before baseline suite. |
| `XDG_DATA_HOME=... timeout 120 godot --headless --path . --editor --quit` | Initial baseline imports clean. Final equivalent `timeout 90` imports clean; `complete-import.log`. |
| `XDG_DATA_HOME=... timeout 600 godot --headless --path . res://tools/tide_test.tscn` | Incoming baseline 314 PASS; intermediate repair failures were investigated and corrected. Final gate below is authoritative. |
| `./tools/test_isolated.sh` | Final 375 PASS, exit 0; verified user dir `/tmp/tidesworn-tests-mjGryTzi/userdata/godot/app_userdata/Save The World`; log `/tmp/tidesworn-tests-mjGryTzi/test.log`, copied console output `gate-final.log`. |
| `XDG_DATA_HOME=... timeout 180 godot --path . res://tools/visual_review.tscn -- --shots /tmp/tidesworn-repair-_xmdo_0t/release2-review` | Actual graphical game, 52 fresh PNGs plus numeric movement samples; all screenshots visually inspected via six labeled contact sheets and detailed full-size frames. `release2-review.log` has no script/shader/runtime errors. |
| `XDG_DATA_HOME=... timeout 180 godot --path . --write-movie /tmp/tidesworn-repair-_xmdo_0t/motion.avi --fixed-fps 60 res://tools/motion_review.tscn -- --samples /tmp/tidesworn-repair-_xmdo_0t/motion-physics.json` | 569 rendered frames at 60 FPS; 566 physics samples. Movie runs actual player/pet/enemy/resident movement and zoom. `motion.log` clean. |
| `ffmpeg -i .../motion.avi -vf 'select=between(n\,310\,317)' -fps_mode vfr .../movie-frames/frame-%02d.png` | Eight consecutive actual rendered frames extracted and visually inspected, including player/pet/enemy/camera; `movie-consecutive-frames.png`. |
| Two separate `XDG_DATA_HOME=... timeout 15 godot --headless --path . --script .../settings-restart.gd -- write/read` processes | Settings written in one process and applied in another at 125% GUI / zoom 52. Lobby → dungeon → lobby passes after waiting for fade completion; `restart2-write.log`, `restart2-read-final.log`. |
| `rg` on final logs for `[FAIL]`, `SCRIPT ERROR`, `ERROR:`, `WARNING` | No matches. Earlier failed iteration logs remain for traceability. |
| `git diff --check` | Clean. |

Intermediate checks caught parse/type errors, a missing grass mesh, a degenerate
coast polygon, a shopping-fixture RNG mismatch and headless window-size handling.
Those errors are fixed; no old failing output is represented as a final pass.

## Visual and movement review

Inspected actual title, home, portals, market, shops, inventory, construction,
dungeon, combat windup/impact/recovery, eastern forest, turtle/coast west-to-east,
BESUT, all four shopping states, Settings and HUD. Matrix: GUI 75/100/130% at
1280×720 and 832×480; zoom 28/38/64; low/med/high effects with Reduce Motion off/on.
No top-right VITALS or random ambient star field appears in the new frames.

Movie covers cardinal and diagonal movement, starts/stops, sharp reversals,
prolonged movement, pet distance recovery, nearby enemies/residents and smooth
zoom. Consecutive frames 310–317 show continuous movement rather than tile jumps.
Across 566 recorded physics samples, maximum per-tick displacement was:

- Player: 0.07333 world units.
- Pet catch-up: 0.15000 world units (bounded 9 units/s at 60 Hz).
- Camera: 0.11096 world units.

Almost every sampled position is fractional relative to the art grid. Rendered
motion was inspected separately; these numeric results are supporting evidence,
not a substitute for the movie review.

## Save and unrelated-work protection

Pre-test real data was copied to `real-userdata-backup/` before the baseline.
Every agent test/import/capture/restart run used isolated user data; the safe gate
also verifies its actual path before any save deletion. Existing repository
screenshots were not overwritten, and no generated captures were put in the repo.

A separate live `/usr/bin/godot --editor` and its game process were observed
running against real user data during the task. That session changed the real
`tidesworn_save.json`; settings.cfg still matched the original backup. The live
save was **not restored or overwritten**, since that would discard ongoing user
progress. Its current snapshot is preserved in `live-session-snapshot/`, alongside
the pre-test backup. The concurrent formatting-only ui_theme.gd edit was retained.

## Limits

- Desktop GL Compatibility is verified here. No Android export, physical-device
  performance/touch test, or every GPU/refresh-rate combination was run.
- Nearest sampling at non-integer zoom naturally changes pixel coverage; the
  tested logical motion is continuous and no ordinary movement teleport remains
  in the reviewed sequences. This is not a promise of zero raster shimmer on all
  displays and zoom values.
- Very unusual user-edited settlements can make a destination unreachable.
  Customers time out and release reservations rather than teleporting or changing
  player economy. Arbitrary layouts were not exhaustively enumerated.
- Original screenshots remain historical. Use the fresh evidence paths above.
- No requested implementation item is left intentionally incomplete. These limits
  distinguish tested desktop behavior from untested platforms/layouts.
