# Developer mode

Implemented 2026-10-30. The unlock phrase is provided separately to the project owner; it is not written into this document or saved in a journey.

## Using the tools

1. Open Settings from the title screen, the village menu, or the ocean Controls panel.
2. Enter the developer phrase in Developer Access and press Unlock.
3. Choose Open developer tools, then Start test session.
4. Use Travel, Scenes or Progress. Close the workbench to play the selected test.
5. Use the floating Dev tools control to reopen it, including at sea and after a test ending returns to title.
6. End test session restores the normal journey at its world checkpoint. Lock developer mode also ends a running test and removes access.

Unlock is for the current app process. Restarting the app or reloading device settings locks it again. The field is masked and cleared after submission, failed attempts have a short retry delay, and only a SHA-256 digest is stored in the game source.

## Available actions

| Area | Tools |
| --- | --- |
| Travel | BESUT cottage, dock, Twilight Wilds, Chaos Citadel threshold, Tempest Spire, Abyssal Throne, sea levels 1 and 2, full Kraken encounter, unlocked Arjun prison. |
| Scenes | Illustrated opening, Arjun rescue preview, seven-beat Mei Ling rescue preview, Pak Rahim welcome, complete dock reunion and sailing ending. |
| Rescue progress | Mark either friend rescued, reset both rescue routes, prepare both live friends for manual dock Embark. |
| Combat and supplies | Finish the current boss through its real defeat transaction, restore Adam/companion and turtle health, add test Gold/Diamonds/potions. |
| Test conditions | Advance to day/night, protect Adam from land damage, freeze the shared world clock. |

The prison shortcut defeats the Kraken but keeps Arjun's cage as a separate interaction. The citadel jump enters the real boss threshold; Finish current boss commits Mei Ling's rescue and runs her actual story. The dock setup leaves Embark manual, while Full dock ending starts the same Game-owned readiness route automatically after setting up the test.

Nighttime still uses the normal arrival rules, including a first-time arrival introduction when applicable. Scene/arrival ownership must finish before another action can run. Protection covers Adam's ordinary land health, not the forest, residents or turtle lives. Freeze world clock leaves ordinary actor behavior running after closing the workbench.

## Normal journey protection

GameState forks the current in-memory progression to `user://developer_test_save.json`; `user://tidesworn_save.json` remains the normal record. Every production save, load, Continue and delete path asks `GameState.save_path()`. New Journey, game over, boss rewards and ending completion therefore stay on the test record while a fork is active.

Ending a test restores the captured normal progression and its prior save/autosave state. Live world objects are rebuilt by Game at the saved world checkpoint. This does not restore the exact transient frame: dungeon enemies reset as on an ordinary revisit, and a sea journey restarts its current route checkpoint. Closing the app during testing leaves the normal file available on the next ordinary startup; the temporary test file is not automatically resumed.

If another game has updated the normal record while this process was testing, restore reads that newer record instead of overwriting it with the old snapshot. An unreadable or removed replacement returns safely to title with autosaving withheld. A successful Continue after repair, or a deliberate New Journey, restores the previous autosave policy.

Device display/audio preferences remain device settings. Journey control-layout edits made while testing belong to the test journey and are discarded with it.

## Ownership

- `DeveloperAccess` verifies the digest; GameSettings owns volatile unlocked access. No unlock boolean or phrase is part of `DEFAULTS`, `settings.cfg`, or campaign data.
- `DeveloperAccessControl` is shared by all three Settings entry points.
- `DeveloperDB` is a closed catalog of action IDs and display copy. No arbitrary console execution or raw save-field editor exists.
- GameState owns the fork, restore snapshot, dynamic save path, guarded progression changes and session-only protection/time options.
- Game owns world transitions, actor placement, cutscene entry and workbench suspension. The workbench deliberately pauses its current world and shared clock; ordinary menus retain their existing simulation rules.
- DeveloperPanel is created on a Game-owned layer above the separate ocean/title HUDs. GameHUD registers it in modal visibility and hide routing, and its close handler restores the same owning world's process mode.
- Journey serials separate configured test destinations from retiring worlds. Failed fork creation rolls back without invalidating the current normal world's ownership.

## Verification

Windows uses `tools/test_isolated.ps1 -Godot <console-executable> -Developer`, optionally `-Capture -Resolution 832x480` or `1280x720`. The shared developer checks also run inside the canonical tide gate.

For positive code-entry verification, provide the private phrase through the process-only `PB_DEVELOPER_TEST_CODE` environment variable. It is not printed or embedded in tests. Without that variable, the canonical suite still checks rejection/locking and uses an explicit test-only unlocked fixture for the workbench checks.

Coverage includes masked code entry and mouse/touch navigation, code clearing/non-persistence, failed fork rollback, every travel family, real rescues, all story previews, ending/title paths, session restore, options, normal save byte identity across save/load/delete/New Journey/game over, concurrent-record protection and repaired Continue. Native captures inspect locked Settings, workbench travel/progress and the ocean overlay at both supported sizes. Actual dated results and evidence roots are in the newest acceptance section.
