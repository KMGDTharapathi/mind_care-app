"""Generates the short sound effects used by the games in lib/features/games.

Run from the repository root:

    python generate_game_audio.py

All clips are mono 16-bit PCM at 22.05 kHz — plenty for one-shot game SFX and
roughly half the bundle size of 44.1 kHz. Every clip is normalised to a
consistent peak so no single effect jumps out of the mix.
"""

import math
import os
import random
import struct
import wave

SAMPLE_RATE = 22050
OUT_DIR = os.path.join('assets', 'audio')


# ── primitives ────────────────────────────────────────────────────────────────

def write_wav(filename, samples):
    peak = max((abs(s) for s in samples), default=0.0)
    if peak > 0.0:
        # Normalise to 92% of full scale so nothing ever clips.
        gain = 0.92 / peak
        samples = [s * gain for s in samples]
    os.makedirs(OUT_DIR, exist_ok=True)
    with wave.open(os.path.join(OUT_DIR, filename), 'wb') as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(
            b''.join(struct.pack('<h', int(max(-1.0, min(1.0, s)) * 32767)) for s in samples)
        )
    return len(samples) / SAMPLE_RATE


def env_exp(i, n, decay=5.0):
    """Exponential decay envelope, 1.0 at the start, ~0 at the end."""
    t = i / n
    return math.exp(-decay * t)


def env_adsr(i, n, attack=0.005, decay=6.0):
    """Short attack (avoids clicks) followed by an exponential decay."""
    t = i / SAMPLE_RATE
    total = n / SAMPLE_RATE
    if t < attack:
        return t / attack
    return math.exp(-decay * (t - attack) / max(total - attack, 1e-6))


def tone(freq, dur, vol=0.3, decay=6.0, harm=0.0, attack=0.004, glide_to=None):
    """A sine tone, optionally with a second harmonic and a pitch glide."""
    n = int(SAMPLE_RATE * dur)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        f = freq if glide_to is None else freq + (glide_to - freq) * (i / max(n - 1, 1))
        phase += 2 * math.pi * f / SAMPLE_RATE
        s = math.sin(phase) + (harm * math.sin(phase * 2) if harm else 0.0)
        out.append(vol * s * env_adsr(i, n, attack, decay))
    return out


def noise(dur, vol=0.3, decay=12.0, smooth=0.35, seed=1):
    """Low-passed white noise — used for clicks, pops and impacts."""
    rnd = random.Random(seed)
    n = int(SAMPLE_RATE * dur)
    out = []
    prev = 0.0
    for i in range(n):
        raw = rnd.uniform(-1.0, 1.0)
        prev += (raw - prev) * smooth
        out.append(vol * prev * env_exp(i, n, decay))
    return out


def mix(*layers):
    n = max(len(l) for l in layers)
    out = [0.0] * n
    for layer in layers:
        for i, s in enumerate(layer):
            out[i] += s
    return out


def seq(*parts):
    out = []
    for p in parts:
        out.extend(p)
    return out


def gap(dur):
    return [0.0] * int(SAMPLE_RATE * dur)


# ── game sound effects ────────────────────────────────────────────────────────

def game_tap():
    """Soft UI tick — selections, button presses."""
    return mix(
        tone(920, 0.055, vol=0.22, decay=14.0),
        tone(1380, 0.045, vol=0.10, decay=18.0),
    )


def game_shoot():
    """Bubble Blaster: the launcher firing."""
    return mix(
        tone(420, 0.14, vol=0.28, decay=9.0, glide_to=1500),
        noise(0.04, vol=0.10, decay=30.0, seed=7),
    )


def game_stick():
    """Bubble Blaster: a bubble locking into the grid."""
    return mix(
        tone(520, 0.10, vol=0.24, decay=13.0),
        tone(780, 0.08, vol=0.12, decay=16.0),
    )


def game_pop():
    """Bubble Blaster: bubbles bursting."""
    return mix(
        noise(0.07, vol=0.34, decay=26.0, smooth=0.5, seed=3),
        tone(1250, 0.09, vol=0.22, decay=14.0, glide_to=620),
    )


def game_eat():
    """Snake: picking up food."""
    return seq(
        tone(659, 0.07, vol=0.26, decay=12.0),
        tone(988, 0.13, vol=0.24, decay=9.0),
    )


def game_crash():
    """Snake: hitting a wall or itself."""
    return mix(
        noise(0.32, vol=0.30, decay=9.0, smooth=0.22, seed=11),
        tone(210, 0.32, vol=0.26, decay=8.0, glide_to=70),
    )


def game_swap():
    """Candy Crush: two candies trading places."""
    return mix(
        tone(700, 0.09, vol=0.20, decay=14.0, glide_to=1150),
        noise(0.03, vol=0.08, decay=34.0, smooth=0.6, seed=5),
    )


def game_match():
    """Candy Crush: a group clears. Pitch is raised per combo at playback."""
    return mix(
        tone(880, 0.17, vol=0.28, decay=8.0, glide_to=1560, harm=0.25),
        noise(0.05, vol=0.12, decay=28.0, smooth=0.5, seed=13),
    )


def game_blast():
    """Candy Crush: a striped / wrapped / colour bomb detonating."""
    return mix(
        noise(0.26, vol=0.30, decay=10.0, smooth=0.30, seed=17),
        tone(300, 0.26, vol=0.24, decay=8.0, glide_to=1900, harm=0.2),
    )


def game_drop():
    """Candy Crush: candies falling into the gaps."""
    return mix(
        noise(0.13, vol=0.16, decay=16.0, smooth=0.25, seed=23),
        tone(240, 0.12, vol=0.14, decay=14.0, glide_to=520),
    )


def game_slide():
    """Puzzle: a tile sliding into the empty cell."""
    return mix(
        tone(230, 0.075, vol=0.24, decay=16.0),
        noise(0.03, vol=0.12, decay=30.0, smooth=0.4, seed=29),
    )


def game_bump():
    """Puzzle / Candy Crush: an illegal move — soft, never harsh."""
    return mix(
        tone(155, 0.10, vol=0.20, decay=12.0),
        tone(148, 0.10, vol=0.16, decay=12.0),
    )


def game_correct():
    """Word Puzzle: the word was spelled correctly."""
    return seq(
        tone(659, 0.075, vol=0.24, decay=9.0),
        tone(831, 0.075, vol=0.24, decay=9.0),
        tone(1046, 0.075, vol=0.24, decay=9.0),
        mix(
            tone(1318, 0.26, vol=0.24, decay=7.0),
            tone(1046, 0.26, vol=0.14, decay=7.0),
        ),
    )


def game_wrong():
    """Word Puzzle: the word was wrong — gentle, never a buzzer."""
    return seq(
        tone(392, 0.10, vol=0.20, decay=10.0),
        tone(311, 0.16, vol=0.18, decay=8.0),
    )


def game_levelup():
    """Advancing to the next level."""
    return seq(
        tone(523, 0.065, vol=0.24, decay=10.0),
        tone(659, 0.065, vol=0.24, decay=10.0),
        tone(784, 0.065, vol=0.24, decay=10.0),
        mix(
            tone(1046, 0.28, vol=0.26, decay=7.0),
            tone(784, 0.28, vol=0.14, decay=7.0),
        ),
    )


def game_win():
    """A level or stage cleared."""
    return seq(
        tone(523, 0.075, vol=0.24, decay=9.0),
        tone(659, 0.075, vol=0.24, decay=9.0),
        tone(784, 0.075, vol=0.24, decay=9.0),
        tone(1046, 0.09, vol=0.24, decay=8.0),
        mix(
            tone(1318, 0.52, vol=0.26, decay=5.0),
            tone(1046, 0.52, vol=0.16, decay=5.0),
            tone(1568, 0.52, vol=0.12, decay=5.0),
        ),
    )


def game_lose():
    """Out of moves / out of shots / out of lives."""
    return seq(
        tone(440, 0.11, vol=0.22, decay=8.0),
        tone(370, 0.11, vol=0.20, decay=8.0),
        tone(294, 0.11, vol=0.20, decay=8.0),
        mix(
            tone(220, 0.42, vol=0.24, decay=6.0),
            tone(196, 0.42, vol=0.12, decay=6.0),
        ),
    )


SOUNDS = {
    'game_tap.wav': game_tap,
    'game_shoot.wav': game_shoot,
    'game_stick.wav': game_stick,
    'game_pop.wav': game_pop,
    'game_eat.wav': game_eat,
    'game_crash.wav': game_crash,
    'game_swap.wav': game_swap,
    'game_match.wav': game_match,
    'game_blast.wav': game_blast,
    'game_drop.wav': game_drop,
    'game_slide.wav': game_slide,
    'game_bump.wav': game_bump,
    'game_correct.wav': game_correct,
    'game_wrong.wav': game_wrong,
    'game_levelup.wav': game_levelup,
    'game_win.wav': game_win,
    'game_lose.wav': game_lose,
}


if __name__ == '__main__':
    for name, fn in SOUNDS.items():
        dur = write_wav(name, fn())
        size = os.path.getsize(os.path.join(OUT_DIR, name))
        print('{:<20} {:.2f}s  {:>6.1f} KB'.format(name, dur, size / 1024))
