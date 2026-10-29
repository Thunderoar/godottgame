# Mei Ling: wreck to occupied shore

The new fourth beat bridges the missing cause, rather than interrupting the
Kraken's hook -> anger -> impact sequence or crowding the captivity montage.
The seven-page order is fishing, awakening, wreck, landfall, capture, turtle
rescue, Adam's promise to BESUT. Every page retains its six-second reading clock.

- 0.00–3.30 s: the current carries Mei Ling and the same yellow bow fragment
  toward a ruined landing. Two sentries are already posted above the waterfront.
- 3.30–4.40 s: the bow stays grounded while Mei Ling steps onto the landing.
- 4.50–5.30 s: the sentries notice the survivor and move down from their posts.
- 5.30–6.00 s: hold the occupied shore, living survivor and her grounded wreckage.
  These positions match the following capture montage exactly.

The following caption supplies a restrained motive: their ruler wants answers
from the outsider. It does not give Mei Ling secret powers, reveal the dimension
twist, identify every monster as a soldier, or make the Kraken a puppet. The
ruined arch is architecture, not an invented on-screen teleportation event.

`OpeningLandfallRenderer` uses the established procedural pixel-art family,
shared guarded-shore backdrop, copied bow art and existing dedicated friend/guard
poses. Only the presentation sampler changes positions. No gameplay RNG,
independent timers, saves or deferred capture callbacks participate. Reduce Motion
holds the completed tableau; low quality removes only optional water marks.

Current verification and copy/patch/rollback evidence: sibling VERIFICATION.txt
in the external delivery folder. No old test tally is presented as a current run.

Current final verification (Linux, Godot 4.7.2): canonical isolated gate
**3,129 checks, PASS, exit 0**. Native Xvfb/software-rendered landfall review:
**651 PASS** at both 1280×720 and 832×480; capture review: **675 PASS** at both
sizes, all exit 0 with no `[FAIL]`, `SCRIPT ERROR` or `ERROR:` markers.
XIM and unsupported V-Sync warnings remain in native logs. Phase images were
visually inspected; a first-pass floating-foot/guard-post issue was corrected
and 242 visible-ground support assertions added before these final runs.
No native Windows/Android or physical-phone validation is claimed.
