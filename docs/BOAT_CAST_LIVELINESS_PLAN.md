# Boat cast — character-business and dialogue acting pass

## Why this pass

The first committed opening establishes names and boat geography, but most acting is one held alternate pose. A camera push cannot substitute for performance. This pass gives each friend a small, readable intention **before, during and after** speaking, and makes the other two people listen. It does not add dialogue, extend the opening, add combat weapons or change the rescue story.

The target is the opening in game2/godottgame, based on commit `5d20d72`. Keep Adam-only selection, all eleven story pages, existing six-second shot durations, skip/next/pause, focus-loss behaviour, reduced motion and the later Kraken/rescue/ending ownership.

## Acting direction

**Adam — comfortable because he is useful.** He gathers loose rope into a coil while enjoying the quiet. His hands keep working through the beginning of the line, rather than switching from an idle pose into a generic “talk” loop. His glance reaches Arjun *before* the next cut: the conversation draws his attention out of the task.

**Arjun — confidence expressed through his hands.** He watches his float and works the reel while promising a catch. His right wrist carries the rod; the other hand makes the small reel-working cycle. A brief confident hold punctuates the boast. When Mei Ling answers, he acknowledges the joke with a short grip adjustment and attention change, not another speaking animation or an exaggerated full-body bounce.

**Mei Ling — observant and dryly amused.** She studies and traces a small folded chart on her lap while the others talk. She lowers it and smiles *before* her reply. One palm-up gesture supplies the punchline; she does not repeatedly wave or abandon the chart for the entire scene. The chart has no new quest, destination or lore implication: it is ordinary boat business.

## Score: one ensemble timeline, not three independent idle loops

Times begin after the existing title/loading reveal. Shot boundaries remain 6, 12 and 18 seconds. Mouth shapes are stylised silent-dialogue acting, **not synchronised recorded speech**; no new voice-over or audio is supplied.

| Time | Speaker / foreground task | Listener work and edit purpose |
| --- | --- | --- |
| 0–0.55 s | Adam starts gathering rope before the mouth begins. | Arjun attends to Adam; Mei Ling already has the chart. The shot begins in the middle of life, not with everyone awaiting a cue. |
| 0.55–2.4 s | Adam forms two small loops while speaking. His lowered task glance and one-pixel head change support the hand work. | Keep the listeners quiet. A blink is offset from the others, never a synchronized group blink. |
| 2.4–4 s | Adam lowers and settles the coil, finishing the thought. | A short closed-mouth gap separates the speech bursts. The rope stays attached to the authored hand poses. |
| 4–6 s | Adam holds the coil and looks toward Arjun. | Anticipatory eyeline motivates the cut; no extra explanatory text is needed. |
| 6–6.25 s | Arjun holds the rod; the next task starts with a short anticipation. | Adam is already looking at him. Mei Ling continues reading instead of instantly joining a synchronized reaction. |
| 6.25–9.8 s | Arjun works the reel with a finite hand-pose sequence while boasting. | The rod and line derive from the same right-wrist anchor. Adam quietly resettles his coil near the end. |
| 9.8–10.4 s | Brief confident rod hold. | Let the boast land before the answer. |
| 10.5–12 s | Arjun settles without continuing to mouth words. | Mei Ling lowers the chart, turns toward him and gives a small anticipatory smile; attention begins to shift to her. This reaction starts before her close-up. |
| 12–12.7 s | Mei Ling begins the reply with chart lowered. | Her existing left-facing reaction keeps Arjun as a visible recipient. |
| 12.7–13.6 s | **One** palm-up teasing gesture while the other hand retains the chart. | Arjun listens; his mouth does not cycle. |
| 13.6–14.5 s | Her hand settles and a restrained smile carries the end of the tease. | Arjun briefly adjusts his grip in response at 14.1–14.7 s; Adam smiles at 14.3–15.5 s. The responses overlap, but do not all fire on one frame. |
| 14.5–16.6 s | She returns attention to the chart. | The existing pullback reveals the same three people continuing their actions, not reset sprites. |
| 16.6–18 s | Crew settles toward the horizon. | The pullback lands on the exact crew, prop, foot and rod states used at the beginning of the wide shot. |
| 18–21 s | Full boat: quiet group life, including one short reel adjustment. | Give the viewer the whole relationship and geography before danger. No more speech mouths after the introductions. |
| 21–22.6 s | Mei Ling folds/lowers the chart; Adam lowers and stows his coil. | Finish the little jobs visibly so the props are not left floating or silently teleported out of their hands at the Kraken cut. |
| 22.6–24 s | Neutral, empty-handed rest for Adam and Mei Ling; Arjun retains the connected rod. | Preserve the existing hook/awakening/wreck sequence. No new story page or longer running time. |

## Expression and animation rules

- Mouths alternate narrow/open/closed within three separated phrase windows (local 0.55–1.50, 1.85–2.70 and 3.05–4.05 seconds). The two listeners never use speech-mouth frames. Smiles are distinct from speech.
- Blinks have short authored windows and different offsets for each person. Avoid constant looping, rapid eye flutter and “everyone blinks together.”
- Distinguish task gaze, attention toward friends and the horizon. A small head dip belongs to rope/chart work, not to every syllable.
- Feet remain on the same authored deck anchors. Do not scale or bounce the entire person to simulate talking. Hands/props/face pixels supply the liveliness.
- Preserve the existing camera edits. Shared ensemble state is continuous at 6 and 12 seconds; only the motivated camera cut changes. The 18-second pullback-to-wide boundary preserves every shared set field.
- A user-advanced Next intentionally jumps to the next authored part of the score. No tween, callback or unfinished prop task survives into gameplay.

## Engineering ownership and constraints

- `OpeningCastPerformance.sample()` supplies a deterministic ensemble score using one 0–24 second clock. It owns hand poses, tasks, gaze, blinks, speech and listener attention. It never modifies GameState, uses gameplay RNG or spawns actors.
- `OpeningCastArt.frame()` builds cutscene-only finite variants from the existing character identities, using original pixel drawing code. Original shared fishing/combat images remain unchanged. Rope/chart shapes are original code-native pixels.
- There are exactly **432** prewarmed combinations (three actors × six body/task poses × four mouth expressions × two blink states × three gaze states). Their bounded private cache does not evict the shared world-art cache. Drawing and sampling create no new images.
- `OpeningFishingRenderer` uses those frames for both introductions and group shot. The reel wrist and the rod share one anchor. `OpeningCastRenderer` retains camera ownership and existing shot/page routing.
- All motion, including mouth/blink/task acting, samples story time. Existing Pause and focus-loss holds therefore freeze it without additional background timers or audio ownership.
- Reduce Motion presents static, readable rope/chart/rod tableaux with closed mouths and no blink/task loop. The final reduced-motion introduction still shows the whole group. Low effects retains all essential acting and removes only optional water detail.

## Acceptance and actual validation

The dedicated tests check actual changed sprite pixels (not just descriptive state), bounded caches, speech exclusivity, blink presence, at least three task poses per speaker, wrist-to-rod anchors, listener anticipation/reaction, both close-up cut boundaries, full-boat continuity, prop stowing, settings and progression non-mutation. Existing opening/story/control checks remain in use.

Render and inspect task, speech and reaction moments at 1280×720; retain fitting/navigation checks at 832×480 and 360×780. The silent 24-second preview uses the actual runtime renderer, captions and normal timing. It is not a promise of recorded voice acting or a substitute for physical-device/native Windows testing.

The same four project artifact roles are retained. The earlier patch/rollback/manifests are preserved under the supplemental `liveliness/prior_roles/` record. The current transaction’s baseline is the already committed Adam-only / eleven-beat opening at `5d20d72`; rolling back this pass must preserve that opening, not undo it to the older three-card menu. `VERIFICATION.txt` records literal commands, outputs, hashes, corrections, live deployment and observed rollback results.
