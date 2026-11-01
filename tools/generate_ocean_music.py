"""Render the original looping ocean instrumental (requires numpy and soundfile).

Run from any directory. No recordings, samples or third-party compositions are used.
"""

from pathlib import Path

import numpy as np
import soundfile as sf


RATE = 44100
BPM = 96
BEAT = 60 / BPM
BARS = 16
SAMPLES = round(BARS * 4 * BEAT * RATE)
OUTPUT = Path(__file__).resolve().parents[1] / "assets/audio/besut_ocean.ogg"


def render():
    mix = np.zeros((SAMPLES, 2), dtype=np.float32)
    rng = np.random.default_rng(731911)

    def place(signal, at, gain=1.0, pan=0.0):
        # Wrap instrument releases into the next phrase for a seamless loop.
        start = round(at * RATE) % SAMPLES
        stereo = signal[:, None] * np.array(
            [np.sqrt((1 - pan) / 2), np.sqrt((1 + pan) / 2)]
        )[None, :] * gain
        first = min(len(signal), SAMPLES - start)
        mix[start:start + first] += stereo[:first]
        if first < len(signal):
            mix[:len(signal) - first] += stereo[first:]

    def note(midi, duration, voice):
        t = np.arange(round(duration * RATE)) / RATE
        hz = 440 * 2 ** ((midi - 69) / 12)
        release = np.clip((duration - t) / 0.18, 0, 1)
        if voice == "pad":
            env = np.minimum(t / 0.55, 1) * np.minimum((duration - t) / 0.7, 1)
            return (np.sin(2 * np.pi * hz * t)
                    + 0.26 * np.sin(2 * np.pi * hz * 2.002 * t)) * env
        if voice == "bass":
            return (np.sin(2 * np.pi * hz * t)
                    + 0.12 * np.sin(4 * np.pi * hz * t)) * (1 - np.exp(-t * 50)) * np.exp(-t * 2) * release
        # Soft wooden mallet with a quiet bell overtone.
        return (np.sin(2 * np.pi * hz * t) * np.exp(-t * 3.5)
                + 0.23 * np.sin(2 * np.pi * hz * 3 * t) * np.exp(-t * 9)) * np.minimum(t / 0.008, 1) * release

    # Dmaj7, Aadd9, Bm7, Gmaj7. An original pentatonic melody floats above it.
    chords = [(50, 57, 61, 66), (45, 57, 59, 64), (47, 54, 57, 62), (43, 54, 57, 62)]
    motifs = [(78, 81, 85, 81, 78, 76), (76, 78, 81, 83, 81, 76),
              (78, 81, 86, 85, 81, 78), (78, 76, 74, 78, 81, 78)]
    steps = [0, 0.75, 1.5, 2.25, 3, 3.5]
    for bar in range(BARS):
        start = bar * 4 * BEAT
        chord = chords[bar % 4]
        for n in chord:
            place(note(n + 12, 4 * BEAT + 0.7, "pad"), start, 0.045, (n % 5 - 2) * 0.2)
        for beat in [0, 2, 3.5]:
            place(note(chord[0] - 12, BEAT * 0.8, "bass"), start + beat * BEAT, 0.19)
        for step, n in zip(steps, motifs[bar % 4]):
            if bar % 8 in [6, 7] and step == 3.5:
                continue
            place(note(n - (12 if bar < 4 else 0), 1.3, "mallet"), start + step * BEAT,
                  0.14 if bar % 8 < 4 else 0.11, -0.2 if step % 1 else 0.2)
        for eighth in range(8):
            t = np.arange(round(0.09 * RATE)) / RATE
            noise = rng.standard_normal(len(t))
            shaker = np.diff(noise, prepend=noise[0]) * np.exp(-t * 70) * np.minimum(t / 0.004, 1)
            place(shaker, start + eighth * BEAT / 2, 0.009 if eighth % 2 else 0.006, 0.45)
        for beat in [0, 2]:
            t = np.arange(round(0.25 * RATE)) / RATE
            kick = np.sin(2 * np.pi * (48 * t + 25 * (1 - np.exp(-t * 24)) / 24))
            place(kick * np.exp(-t * 19) * np.minimum(t / 0.005, 1), start + beat * BEAT, 0.085)

    dry = mix.copy()
    for delay, gain in [(0.3125, 0.18), (0.625, 0.12), (1.25, 0.07)]:
        mix += np.roll(dry[:, ::-1], round(delay * RATE), axis=0) * gain
    mix = np.tanh(mix * 1.2)
    mix *= 0.72 / max(float(np.max(np.abs(mix))), 0.001)
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    # Bounded writes also avoid encoder stack exhaustion on Windows.
    with sf.SoundFile(OUTPUT, "w", samplerate=RATE, channels=2,
                      format="OGG", subtype="VORBIS") as audio:
        for start in range(0, SAMPLES, 4096):
            audio.write(mix[start:start + 4096])
    print(f"Rendered {OUTPUT}: {SAMPLES / RATE:.1f}s stereo, {BPM} BPM, peak {np.max(np.abs(mix)):.3f}")


if __name__ == "__main__":
    render()
