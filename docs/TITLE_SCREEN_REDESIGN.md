# PB title and journey flow

Implemented and verified on 2026-10-24 with Godot 4.7.2 on Linux.

![Boot menu](screenshots/tide_title.png)

The boot screen now gives the village its own introduction: a dusk harbour,
warm cottage lights, a sailing boat, large cream typography and gold journey
actions. The backdrop reuses cached village art, with layered sky, coastline
and restrained water/boat motion. It owns no gameplay nodes, placement RNG or
world clock. Low effects quality and Reduce Motion preserve the complete static
scene and stop its animation immediately.

## Journey flow

| Screen | Action | Result |
| --- | --- | --- |
| Boot menu | Start Game | Open Choose Your Road; keep any save intact |
| Choose Your Road | Click/touch a hero card | Preview that hero and weapon |
| Choose Your Road | Back / Escape | Return to menu; remember the pending choice |
| Choose Your Road, no save | Begin Journey | Start the chosen hero in Kampung Besut |
| Choose Your Road, existing save | Begin Journey | Show saved journey and replacement warning |
| Replacement warning | Keep Saved Journey / Escape | Cancel without changing save bytes |
| Replacement warning | Replace Save & Begin | Start exactly one new journey |
| Boot menu, existing save | Continue Journey | Resume the saved village or expedition directly |
| Boot menu, missing/unreadable save | Continue Journey | Keep the menu usable and show an inline error |

![Hero selection](screenshots/tide_heroes.png)

Hero cards show their existing portraits, names, weapon disciplines and starter
HP/speed from CharacterDB. A separate Begin Journey action makes selection
deliberate. Existing combat, movement, economy, forest associations, tutorials
and save format are unchanged. The existing loading cover still owns world
transitions.

How to Play, Settings and Credits are accessible before a save exists. Title
settings write only GameSettings: master volume, mute, Reduce Motion and effects
quality. More camera/interface settings remain in the world HUD menu. Every
button supports focus and keyboard activation; overlays restrict page focus,
restore it on close and support Escape. Replacement defaults focus to the safe
Keep Saved Journey action. Begin/Continue reject duplicate handoffs.

The compact landscape menu places the introduction beside the actions. Compact
hero cards retain portraits, names, weapons, vitals and selection state; the
longer tactical copy is omitted. Narrow layouts stack cards in a scrolling
region with a persistent Begin Journey strip and Back action.

## Verification

- `./tools/test_isolated.sh`: **920 checks, PASS**, exit 0; no `[FAIL]`,
  `SCRIPT ERROR` or `ERROR:` output. The gate includes 22 title state/save
  regressions and starts its first real journey through Begin Journey.
- `./tools/review_title.sh /absolute/output`: **50 checks, 0 failures**, exit 0.
  Uses actual mouse, screen-touch and keyboard events with the GL renderer,
  plus 13 captures. It verifies fresh/saved startup, all hero choices,
  keyboard overlay focus, live Reduce Motion, replacement cancellation and
  confirmation, direct village/dungeon Continue and an actual failed Continue.
- Inspected full-resolution captures at 1280x720, 832x480 and 600x900. Complete
  cards fit both landscape fixtures; narrow cards scroll with journey actions
  retained. Initial scrollbar/wrapping and compact-card clipping issues were
  corrected before the passing review.
- Final editor import and `git diff --check` pass. Every harness uses verified
  temporary user data. Live progress is never restored from a test fixture.

The native run uses Mesa llvmpipe under Xvfb. Its X input-method and unsupported
VSync warnings are host limitations; there are no script/error markers or
message-queue failures. These fixtures verify desktop rendering and synthetic
touch delivery, not physical Android/Windows devices or hardware performance.

Evidence: [native log](evidence/title-screen/native-review.log),
[acceptance log](evidence/title-screen/acceptance.log),
[compact menu](evidence/title-screen/compact-menu.png),
[compact heroes](evidence/title-screen/compact-heroes.png),
[narrow heroes](evidence/title-screen/narrow-heroes.png),
[settings](evidence/title-screen/settings.png),
[replacement](evidence/title-screen/replace-save.png),
[failed Continue](evidence/title-screen/continue-error.png).

Runtime ownership: `scripts/ui/title_screen.gd` builds the menu, page state and
title overlays; `scripts/ui/title_backdrop.gd` draws its harbour; Game receives
the existing handoff signals. GameState now checks the result of `load_game()`
before continuing and parses damaged JSON without emitting a script error.
It leaves unreadable files untouched.
