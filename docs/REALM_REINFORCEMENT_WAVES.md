# Citadel reinforcement waves — 2026-11-01

## Player flow

Arrival → crossing's 2/4/6 Imps → crossing light → watchpost's 2/4/6
Imp/Watcher mix → winch/light → ashen 2/4/6 Imp/Keeper mix → lantern rest and
preparation → Enter/Not yet → introduction → boss → existing rescue.
Sectors can still be completed out of order. Optional lore, pets and purchases
remain optional. No completed wave alone opens its sector's light or the boss.

There are 36 guards in nine waves, separate from Shadow & Chaos Fiend. Six initial
patrollers are built; subsequent waves appear only in the active sector after its
last living guard falls. At most six guards are in the active wave. A stable gold
circle/cross marks each arrival post for at least 1.4 seconds. Standing within one
unit of any marked post delays the wave and asks Adam to step clear. Warnings have
no collision or damage. Essential marks remain on low effects and Reduce Motion.
Active-sector hints report wave number, size and the existing profile counterplay.
All guards retain the shared numeric overhead health presentation. Neighboring
dormant sectors hide overhead labels while another sector owns combat.

## Readability and lifecycle

Only one sector owns aggression and only one guard owns the shared committed
attack/effect slot. Existing Imp rush, Watcher fan and Keeper cross warnings,
collision, one-hit casts and refuge clipping remain. Local crowd steering reduces
stacking without changing player movement or enemy collision masks. Arrival posts
are physically clear, spaced and outside protected readings, habitats and lantern.

Retreat or sector change cancels pending arrival marks, casts and effects. Returning
to an unfinished sector starts a fresh full warning. A deleted cue cannot permit
an invisible immediate arrival. Accepted pet challenges cancel the cue before
suspending the world. Disabled, retired or wrong-journey worlds cannot spawn a wave.
Peaceful cleared realms remain peaceful, and ordinary menus remain non-pausing.

## Persistence and rewards

GameState alone writes `realm_progress.citadel_path.waves_cleared`, a map of known
sector IDs to completed counts 0..3. Defaults and sanitization support old saves;
malformed, fractional, string and unknown records cannot create victories.
The legacy `cleared_pairs` IDs now denote completed sectors. Existing completed
IDs migrate to count 3 without replay; count 3 also reconciles the stable ID.
An unfinished wave reconstructs in full on Continue, but its earned predecessor
waves never respawn. No actor HP, warning timer or active cast is saved.

An actual lethal current-wave member claim commits kill count, XP and wave/sector
progress together before notification. A failed save rolls back those mutations
and the claim; the living actor can accept a retry after save recovery. Duplicate
or stale callbacks cannot repeat kill credit. Physical drops use the existing hook.
Per-actor HP/damage/speed remain the original sector tuning. Wave one's two actors
pay 4 base XP each; waves two/three pay 2 each. All sectors total 84 base / 252 actual
player XP, preserving earlier level progression. Ordinary Gold/diamond drops are
per kill, so more enemies provide more collectible loot. Existing unbanked-loss
rules apply; unfinished-wave reconstruction is not a new per-guard anti-farm rule.

## Verification routes

`tools/realm_wave_checks.gd` runs inside focused Twilight and the canonical tide
gate. Standalone: `godot --headless --path . res://tools/realm_wave_test.tscn`.
Set BOTH `XDG_DATA_HOME` and `TIDESWORN_TEST_ROOT` to disposable external directories
before any Godot process, including imports. Never run acceptance against live saves.
With an actual renderer add `-- --capture`; `--reduced` selects low effects and
Reduce Motion. Captures cover arrival marks, four guards and six guards. Actual
commands/results belong in `ACCEPTANCE_TESTS.md`; no player pacing, Windows or
Android certification follows from Linux headless/llvmpipe tests.
