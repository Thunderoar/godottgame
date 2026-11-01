# Potion Shop combat supplies

The Potion Shop sells these alongside the existing Health Potion:

| Item | Gold | Stack | Effect |
|---|---:|---:|---|
| Sprint Potion | 35 | 9 | Automatic sprint while moving for 10 seconds, with no stamina drain. Works even when initially exhausted. |
| Fast Attack Potion | 50 | 9 | 1.5x weapon attack cadence for 10 seconds, including anticipation, active/recovery phases and cooldown. Applies to sword, scythe and bow. |
| Shield Potion | 60 | 9 | Adds 60 points to the existing shield, capped at 60. Damage consumes shield before HP. |
| Boss Revival Potion | 150 | 3 | Automatically consumes one on a fatal hit during an active portal boss or Kraken fight. Restores 50% maximum HP and gives two seconds of protection. |

Use the first three from Pack. Successful use closes Pack; failed uses show their
reason in the panel without spending a bottle. Already-active boosts and a full
shield reject a redundant use. Revival has no manual Use button: carry it into
the fight. It cannot revive pets or the ocean turtle, and does not activate in
the village, during realm exploration before the boss threshold, after the boss
falls, or during a world/story/developer transition. It preserves current boss HP,
expedition loot and actor position instead of starting the defeat/recovery flow.

GameState owns catalog-based transactions, inventory and shield. Its sprint/haste
timers are volatile and use Game's active world clock. Ordinary menus keep time
running; story/developer suspension and world travel freeze it. Remaining boosts
carry across normal world handoffs. New journeys, successful save loading,
defeat and returning to title clear them. Bottles and the existing shield field
keep their normal save behavior. No new saved field or save-version migration is
needed. Developer sessions retain the normal context's remaining timers separately
from their test effects and defer to a newer external checkpoint on restore.

Game owns the active player/boss eligibility check. Player reads the modifiers
without creating synthetic held input, and handles feedback and revival protection.
PlayerVitalHud displays the remaining boost times, shield points and revival cue.
Retiring players cannot damage the active journey or consume its revival stock.

Windows review:

`tools/test_isolated.ps1 -Godot <console-executable> -Potions`

Add `-Capture -Resolution 1280x720` or `832x480` for native shop, active-boost and
real portal/Kraken revival captures. `potion_checks.gd` also runs in the complete
tide scene. Always use the isolated wrapper; the focused fixture manipulates its
test inventory and performs real save/load and lethal-hit checks.
