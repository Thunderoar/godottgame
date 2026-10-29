# Gameplay objective tracker

The left-side tracker sits below the live status strip. Its header toggles between
up to three contextual goals and a single-line current-goal summary. Collapsing
never pauses simulation, locks movement, or releases held actions. Progress updates
never expand it automatically. The boolean `objectives_collapsed` preference lives
in GameSettings (`settings.cfg`), defaults to false, and accepts older settings files
without a journey-save migration.

## Ownership and selection

- `scripts/ui/objective_tracker_data.gd`: read-only objective selection. Current
  world type takes priority over village training; no writes or rewards occur.
- `scripts/ui/objective_tracker.gd`: presentation, scrolling, input, expansion and
  live card updates. Stable goal IDs retain cards while construction progresses.
- `scripts/ui/game_hud.gd`: world ownership, modal/travel/story visibility, refresh
  cadence and placement relative to status, controls and first-clear guidance.

Village guidance prioritizes recovery, local attackers, burning trees or an emergency, then the
actual phase-aware lesson. Completing one phase offers preparation for the next;
clearing the first portal retires training through the existing GameState rule.
After training, eligible unfinished workshop work and remaining rescue goals use
existing saved flags. Construction percentage reads actual remaining work. Finished
projects/rescues disappear; a fully settled journey offers village-care guidance.

Twilight guidance starts with exploration and the return rift. Discovered approach
landmarks permit lantern/citadel guidance; the actual boss threshold activates the
boss objective. A restored realm stays peaceful. Only discovered, unbonded habitats
offer optional challenges. No new waypoint or undiscovered boss marker is added.
Later dungeons use their own ruler and current clear state. Kraken victory changes
the objective to freeing Arjun; the rescue flag independently retires prison guidance.
OceanJourney retains its own HUD and controls.

## Layout and input

The tracker uses the existing teal/gold theme, wrapped text and a narrow vertical
scrollbar. At least 12 physical pixels are reserved for body text and 44 for the
header touch target. Layout finds a free vertical interval among left-side controls,
including relocated controls. Limited height uses the concise summary without
changing the player's saved expansion preference. The first-clear reminder fits
beside the tracker at the supported landscape sizes.

Mouse and keyboard use the standard button. Raw touch handling also accepts a
second finger while the joystick is held. Releasing outside the header, hiding the
tracker or losing window focus cancels the gesture. Emulated mouse events cannot
double-toggle it. The tracker handles only its displayed rectangle; it is not a modal.
Expansion is immediate and adds no motion, including with Reduce Motion enabled.

## Verification

`tools/objective_tracker_checks.gd` runs in the canonical isolated gameplay gate.
The focused route on Windows is:

```powershell
.\tools\test_isolated.ps1 -Godot <absolute-console-executable> -Objectives
.\tools\test_isolated.ps1 -Godot <absolute-console-executable> -Objectives -Capture
```

The capture run uses the native renderer and checks both 1280x720 and 832x480, with
75%, 100% and 130% UI scales. Captures and user data stay in the printed external
test directory. Headless checks alone do not establish visual quality or physical
phone behavior. The canonical full gate remains required alongside focused checks.
