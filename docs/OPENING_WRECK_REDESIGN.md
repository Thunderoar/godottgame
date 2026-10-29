# Opening beat three: the ship breaks, the friends separate

Implemented 2026-10-29. Target: `StorySequence`, `kind == "intro" and page == 2`.
This continues the confirmed classic-pixel beat-two state, including its pending
uncommitted files. It does not replace them with an older Git snapshot.

## The visual problem

The previous beat-three image used three drifting yellow rectangles, armed walking
sprites and an unrelated fishing line. It described separation in its caption but
did not show a ship actually being struck, how the pieces belonged to the same
UNISZA boat, or what it meant for the three friends.

The new performance follows **anticipation → contact → fracture → separation →
emotional hold**. The consequence stays readable even without the caption, while
the six-second story contract and all original story words remain unchanged.

## Six-second staging

| Time | Action | Purpose |
| --- | --- | --- |
| 0.00–0.55 | Hold the preceding beat's final fury shot | Maintain the same camera, boat, palette, sea king and line geometry |
| 0.55–1.25 | The Kraken raises a thick sucker-lined arm | Give a readable warning before the destructive motion |
| 1.25–1.45 | Fast downward sweep into the wooden hull | Show the cause, not an unexplained cut to broken rectangles |
| 1.45–2.25 | Local water burst and exposed timber; three pieces begin separating | Put force at the contact point without a fullscreen flash |
| 2.25–4.20 | Stern, mast/nameplate section and bow ride different currents | Make the three-piece count and each friend's ownership unmistakable |
| 3.00–4.80 | Friends reach back toward one another | Turn destruction into the story's emotional separation |
| 4.80–6.00 | Hold the three distinct groups; arm settles into the water | Allow caption reading and prepare the next capture/rescue beat |

There is no camera shake, violent spin, weapon animation, gore or extra dialogue.
The turtle and later capture events are not prematurely introduced here.

## One boat becomes three, not three replacement props

The original deck, rigging and yellow hull images are duplicated and masked by a
single jagged partition at approximately source x=145 and x=290. Every source
column belongs to one piece. Exposed pale timber marks the fracture edges; the
centre retains its mast and UNISZA nameplate. Shared source images are never edited.

Each piece has a stable ID, its own pivot and a bounded tilt. Adam owns the stern,
Arjun the mast section and Mei Ling the bow. Actor feet derive from the same pivot
and rotation as their fragment; they do not walk, float independently or fall
through the art. Finite unarmed clinging/reaching poses preserve the established
character palettes and turn toward the gap between friends.

The striking arm is a finite cached low-resolution pixel ribbon with a tapered
silhouette and visible suckers. It sweeps into the wood, then retracts below the
king's eyes and the friends' faces. Local foam, small wood chips and short current
trails support the impact and direction; they never replace the three real pieces.

## Ownership and unchanged contracts

- `OpeningWreckArt`: copied ship partitions, finite strike/foam frames, reaction
  poses and a shared strike-tip function. Namespaced `opening/wreck/.../v1` keys.
- `OpeningWreckRenderer`: deterministic sampler, bounded rotations, shared
  fragment/actor transforms and uniform 480x224 composition above caption bounds.
- `OpeningKrakenRenderer`: optional drawing switches used only by the wreck shot.
  Their default values preserve the preceding awakening image.
- `StoryCanvas.prepare_page()`: warms wreck textures on entering page two, outside
  `_draw()`, without adding work before the title's loading curtain. No gameplay
  nodes, random calls, animation timers or asynchronous callbacks are introduced.
- `OpeningWreckChecks`: integrated through `StoryChecks` in the canonical safe gate.
- `opening_wreck_test.tscn`: native timed captures, live presentation settings and
  real Next/Skip touch events.

Reduce Motion holds a complete stable aftermath with three separated friends and
no flying chips or impact loop. Low quality reduces optional chips/current marks,
not the ship pieces, actor locations, strike anchor or narrative ordering. Changing
either setting never restarts the page timer. Early Next and Skip have no delayed
strike to fire in another page/world. Captions, six-second auto advance, campaign
flags, PB loading handoff and the Classic Pixel default remain unchanged.

## Safe reproduction

From the confirmed repository root, refresh global classes with isolated user data,
then run `./tools/test_isolated.sh`. Never run the destructive acceptance scene
against normal user data. Focused native review:

```sh
review=$(mktemp -d /tmp/tidesworn-opening-wreck-XXXXXXXX)
XDG_DATA_HOME="$review/userdata" TIDESWORN_TEST_ROOT="$review" \
  timeout 120 xvfb-run -a -s '-screen 0 1920x1080x24' \
  env LIBGL_ALWAYS_SOFTWARE=1 godot --audio-driver Dummy --path . \
  --resolution 832x480 res://tools/opening_wreck_test.tscn \
  >"$review/stdout.txt" 2>"$review/stderr.txt"
cat "$review/stdout.txt" "$review/stderr.txt"
if rg -n '\[FAIL\]|SCRIPT ERROR|ERROR:' "$review/stdout.txt" "$review/stderr.txt"; then exit 1; fi
rg '^--- opening wreck: [0-9]+ checks, PASS ---$' "$review/stdout.txt"
```

Repeat at 1280x720 and 1600x720; inspect wind-up, contact, separation, final hold,
Reduce Motion and low-quality images. Exit zero is not a visual review. Final
observed counts and limitations are appended to `docs/ACCEPTANCE_TESTS.md`.

## Transaction continuity

The same external MODIFIED_FILE, DIFF_FILE, VERIFICATION and executable ROLLBACK
roles are reused. Their prior versions live under `history/pre-third-beat/`.
The new patch applies to the confirmed **beat-two working state**, not directly to
Git commit 668b481 without the preceding beat-two patch. Original overwritten
files and the pending-file hash index are retained under `third-beat/baseline/`.
Rollback on a disposable project restores that exact state, preserving all pending
beat-two work, the pixel default and loading/title improvements. Single-file mode
restores only a copy of the previous StorySequence. The final implementation is
reapplied after baseline/modified/rollback observation.

## Observed result — 2026-10-29

- Fresh isolated gameplay: **1,837 checks PASS**, exit 0.
- Native wreck review: **108 PASS each** at 1280x720, 832x480 and 1600x720.
- Preserved compact loading/first-beat and awakening regressions: **138 / 87 PASS**.
- All **12 other story panels** are pixel-identical. The normal beat-two final art
  and beat-three opening art are exactly identical before the wind-up begins.
- Baseline / modified / rollback: legacy rectangles / staged pixel shipwreck /
  legacy rectangles, with exit 0, six-second advance and one completion each.
- Six sampled rollback images and all original file states restore exactly,
  including **every pending beat-two file**. The new patch is reapplied afterward.
- Preview: 162 native frames, 1280x720, 6.75 seconds at 24 sampled/encoded fps,
  verified encode/decode. This is not a hardware frame-rate claim.

The initial art indentation error and a supplemental helper's missing bool type
are retained in the ledger as failed attempts, not passing evidence. Final runs
have no script/error/failure markers. Xvfb input-method/V-Sync warnings remain.
Validation uses Linux llvmpipe and isolated data, not physical Android/Windows or a
release export. No commit/push was requested; all work remains in the checkout.
