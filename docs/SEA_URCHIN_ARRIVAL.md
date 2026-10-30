# Sea urchin arrivals and pixel poses

Implemented 2026-10-30. The randomized night-profile schedule remains a proposal
in `NIGHT_ENCOUNTER_PLAN.md`. This feature connects the animatic to the existing
dusk wave; it does not introduce quiet-night probabilities, change enemy stats,
or remove the later-dungeon emergency rule.

## Presentation

The first safe shore-only arrival after the dock welcome can play an eight-second
in-world introduction. When fire monsters also need their first introduction,
one 14.5-second sequence joins the shore chapter to the forest portal chapter,
with one Skip and one return to Adam. See `FIRE_MONSTER_ARRIVAL.md`.
A small shoreline camera move reveals spines in the foam, the lead
urchin's emergence and wobble, a small can rattle, its inland glance, and the
actual allocated followers. The camera returns before the real enemies take over
at the validated preview landing positions. Skip/Space/Enter/Escape use the same
handoff. Preview actors never enter combat groups, collide, attack or pay rewards.

Game owns the temporary story flag, input release, HUD hide, world-process
suspension and restoration. The authoritative world clock stops during this
first introduction. It is ineligible during a modal, existing story, interior,
travel, recovery, game over, emergency, existing enemies or burning trees.
Ineligible arrivals continue through the short normal-warning path, leaving the
first-introduction flag available for a later safe arrival.

Lighting follows the existing world clock: a reveal exactly at dusk retains the
warm dusk grade; no artificial night tint or second lighting clock is introduced.
The existing coast and village remain the actual world throughout the shot.

Later arrivals use an eight-world-second foam/spine warning and a small direction
caption. The camera and player remain under normal ownership. Ordinary menus
continue simulation; story/habitat suspension follows their existing rules.
The caption yields to modals and interiors. The normal 0.35-second spawn settle
still applies; a fully revealed first-introduction actor starts opaque to avoid
a duplicate fade after the preview disappears.

## Art and combat

`UrchinArt` draws a bounded, cached original 32-by-32 pixel pose set using the
existing violet body, pale eyes, spines and small lodged fragments. It does not
load an illustrated reference asset. Real distance drives the movement cycle;
blocked actors stop their walking pose. Windup compresses the body, the active
pose extends the silhouette, recovery gives the fragment a secondary wobble and
death uses a relaxed shell and cool motes.

The existing Enemy FSM still owns acceleration, collision, targets, cooldowns,
windup (0.42 seconds), active phase (0.14 seconds), recovery (0.5 seconds), damage,
interrupts and rewards. Urchins do not gain a projectile, dash, contact-damage aura
or player-body collision. Ordinary 30-HP / 6-damage / 1.35-speed and emergency
60-HP / 9-damage / 1.75-speed variants are unchanged.

Reduce Motion substitutes still poses and direct camera framing for wobble/pans,
with the same encounter timing. Low effects retains spines, eyes, shadow and
combat cues. Foley is owned by the presenter and observes live effects/master
volume and mute; cancellation stops it without touching unrelated combat audio.

## Persistence and geography

GameState owns defaulted/sanitized `campaign.urchin_intro_seen` and `home_arrival`.
The pending record stores its stable batch identity, absolute night, validated
numeric shore and fire positions, and warning start time. Both species remain
undelivered during the warning and are committed together at the final handoff.
Separate emergency fire additions use `home_fire_arrival`. Restoring saved
survivors never replays either entrance.

Warning reconstruction uses its saved start time; it does not restart eight
seconds or reroll positions. Completion captures live monsters, clears pending
arrival data, acknowledges the home wave and marks a successfully introduced
group in one GameState save boundary. Cancelled previews do not mark completion.
Stale world/journey/night callbacks are rejected. Dawn preserves live survivors;
an unfinished cue cannot materialize new enemies after sunrise. Expired/old-night
pending records are ignored and sanitized away on load.

Entry points avoid the jetty, turtle and nearby player, query the actual collision
shape and authored water/collision cells, and require a route inland. They are
checked again before handoff. A blocked point is skipped rather than replaced by
an unchecked `safe_spawn()` fallback. Preview motion can cross the visual foam;
real Enemy bodies start on valid land, with the shared coast collision intact.

## Source and review route

- `scripts/core/urchin_art.gd`: cached pixel poses.
- `scripts/world/urchin_arrival.gd`: cosmetic timeline, camera, cue and owned audio.
- `scripts/game/game.gd`: safe first-introduction ownership and cancellation.
- `scripts/world/lobby.gd`: entry validation, warning reconstruction and delivery.
- `scripts/autoload/game_state.gd`: saved pending data and completion transaction.
- `scripts/combat/enemy.gd`: species-specific visual poses over the existing FSM.
- `tools/urchin_arrival_checks.gd`: focused checks also in the canonical gate.

Windows review: `tools/test_isolated.ps1 -Godot <console-executable> -Urchin`,
optionally `-Capture -Resolution 1280x720` or `832x480`. The wrapper creates and
prints isolated evidence paths. Captures include eight storyboard timestamps,
low/Reduce Motion and actual windup/active/recovery poses. See the newest
acceptance entry for completed runs, warnings and evidence limits.
