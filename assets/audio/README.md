# Background music

- `besut_village.ogg`: the user's supplied village song, converted from
  `LAGU GAME BESUT.mp4`. Retain the original recording and attribution.
- `besut_ocean.ogg`: an original 40-second stereo instrumental, 96 BPM. Soft
  wooden mallets, sustained chords, bass and light percussion accompany the two
  turtle levels. All sounds and notes are synthesized, with no third-party
  recordings or sampled music. `tools/generate_ocean_music.py` reproduces it
  using Python, NumPy and SoundFile. Circular release/reverb tails join the loop.

Godot import settings enable repeat for both tracks. Game owns their players;
Master volume and mute cover both. The ocean player survives level changes and
retry, pauses for ocean Settings/developer suspension/defeat, and stops at the
island, village or title handoff.
