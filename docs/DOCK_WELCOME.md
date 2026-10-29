# The dock welcome — Pak Rahim

Added 2026-10-30. The eight opening beats now lead into a player-paced conversation on the actual village dock, before the movement tutorial.

Pak Rahim is the water keeper who helped receive Adam on the shore. His first concern is Adam's immediate well-being. Adam asks about Arjun and Mei Ling; Rahim admits he has not seen them. He offers shelter without a debt and a practical first step: meet the neighbours and ask after the missing friends. Adam chooses to help the village rather than being assigned an obligation. Rahim does not know the captors or reveal a rescue destination.

The conversation ends: “You can look for a way home and still have a place here. Both can be true.”

## Runtime and presentation

- `scripts/ui/dock_conversation.gd` owns the 12 dialogue lines, Back/Next, explicit Skip, keyboard E/Enter/Space and Escape. Lines have no automatic timeout. The current speaker is always named; Rahim's portrait remains on the right when Adam replies.
- `scripts/game/game.gd` owns control release, the initial story suspension, HUD restoration and world/journey validity. Later optional conversations use three shorter reminder lines and keep the normal simulation running. World replacement cancels the conversation without saving its completion.
- `scripts/world/dock_host.gd` draws an original small pixel character, matching the portrait's sky-blue headband, mint shirt, cream cloth and water cup. It does not sample an illustrated/realistic NPC atlas. Lobby places him relative to the resolved dock approach; he uses the existing direct-tap and nearby E interaction API.
- `campaign.dock_welcome_seen` has defaults and load sanitisation. Saves made before the feature inherit their raw `intro_seen` value before merging defaults. A new save with an explicit pending welcome resumes at the dock on Continue. Completion/explicit Skip saves once through GameState, and later village returns keep their normal home/recovery arrival.
- The cream and mint dialogue box keeps the real dock visible; the transparent portrait is a separate right-hand element. The local theme removes shadows on light dialogue text without changing the game's shared theme.

Words now appear individually in speech order, each easing from transparent to
fully readable over 0.12 seconds. Speech runs at 1.25 times the original word
pacing. Earlier words remain opaque; later words remain
invisible. Longer words take more speaking time, commas pause briefly, sentence
endings pause longer, and ellipses create a deliberate hesitation. All words
occupy their final layout positions from the beginning, so revealing them cannot
shift the wrapping or box. Next is labelled Reveal while this happens: the first
tap/E/Space/Enter reveals the remaining words immediately, and a subsequent press
advances. Back restarts the prior line; Skip/Leave closes immediately. Reading
never advances a page automatically. Reduce Motion compresses the word sequence
into 0.18 seconds and resolves an in-progress sequence immediately when enabled.

The conversation owns a quiet AudioStreamPlayer for short, rounded vowel murmurs
during each arriving word. Pak Rahim has a lower voice and Adam a lighter one, with three
cached procedural syllables each and small pitch changes. `Sfx.dialogue_voice()`
generates the bounded PCM cache independently of gameplay randomness. Revealing,
finishing or cancelling a line stops its sound immediately. Voice respects live
effects volume, master volume and mute. Voice is triggered by new words rather
than a repeating timer: punctuation pauses stay quiet, and a slow frame speaks
only the current word without replaying missed words. These are talking sound
effects rather than recorded spoken lines.

## Original artwork

Final asset: `assets/authored/characters/pak_rahim.png`, generated with the built-in imagegen tool. It is a new original lighthearted, cute, airy anime-inspired character; no existing resident image was supplied as a reference for this final design. Its PNG alpha is preserved. The small in-world sprite is hand-authored in the game's pixel drawing code.

Final generation prompt:

> Use case: illustration-story. Asset type: original transparent dialogue portrait for the cozy pixel fantasy RPG Protect BESUT. Create an ORIGINAL character named Pak Rahim, a kind Malay village water keeper in his early forties, with a friendly slightly rounded face, warm brown skin, large expressive dark brown eyes, tiny neat moustache and chin beard, short tousled dark hair with just two silver strands, a soft sky-blue tied headband, a loose seafoam-teal short-sleeved linen work shirt, a pale cream scarf draped over one shoulder and tied sash. A small leaf stitched on a cloth pocket. He offers a simple wooden cup of water in one hand and rests the other hand near his sash. His smile is gentle and reassuring, like a good neighbour welcoming a frightened shipwreck survivor. Art direction: lighthearted cute airy anime-ish hand-drawn storybook JRPG character design; softly rounded shapes, clear delicate coloured linework, restrained flat cel shading, pastel mint and sky blue with peach and cream, lots of luminous breathing space; whimsical and sincere. No resemblance to any existing character or supplied game art. Composition: waist-up three-quarter portrait, head turned LEFT and eyes looking toward text to his left, both hands fully visible, head and shoulders fully within canvas, tall portrait silhouette on transparent background, no frame, no scenery, no text, no watermark. Avoid realism, muscular heroic anatomy, heavy painted rendering, glossy mobile-game illustration, dramatic dark lighting, armour, weapons, mature grimdark styling. This is a finished character cutout asset, not a screenshot or UI mockup.

## Verification route

`tools/dock_conversation_checks.gd` is part of StoryChecks and therefore the canonical `tools/tide_test.gd` gate. It checks save migration through actual file load, dialogue ownership, frozen initial clock/positions, every line's layout, real touch/keyboard advance, repeat chats, cancellation and the actual New Journey/Continue handoffs.

On Windows, run `tools/test_isolated.ps1 -Godot <absolute-console-executable> -Dock`. For native rendered captures add `-Capture -Resolution 1280x720` or `-Capture -Resolution 832x480`. The wrapper uses isolated user data and stores captures externally.
