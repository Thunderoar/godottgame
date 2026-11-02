# Background music

- `besut_twilight.mp3`: the user's supplied Twilight Dimension background track,
  copied byte-for-byte from `WhatsApp Audio 2026-11-01 at 19.50.10.mpeg`.
  The source contains MP3 audio; the project extension enables Godot's MP3 importer.
  Loops during Twilight Wilds exploration and ordinary dialogue/menus, pauses for
  battle music, wild pet challenges, films and developer suspension, and stops
  when leaving the realm. Uses the existing Master volume and mute controls.
- `besut_village.ogg`: the user's supplied village song, converted from
  `LAGU GAME BESUT.mp4`. Retain the original recording and attribution.
- `besut_ocean.ogg`: an original 40-second stereo instrumental, 96 BPM. Soft
  wooden mallets, sustained chords, bass and light percussion accompany the two
  turtle levels. All sounds and notes are synthesized, with no third-party
  recordings or sampled music. `tools/generate_ocean_music.py` reproduces it
  using Python, NumPy and SoundFile. Circular release/reverb tails join the loop.

Godot import settings enable repeat for all tracks. Game owns their players;
Master volume and mute cover all three. The ocean player survives level changes and
retry, pauses for ocean Settings/developer suspension/defeat, and stops at the
island, village or title handoff.
