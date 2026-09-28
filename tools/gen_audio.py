#!/usr/bin/env python3
"""Generates every sound effect and music loop for Frontier Expedition.

Pure Python (no dependencies): noise, oscillators, envelopes, simple filters and a
Karplus-Strong plucked string. Output: assets/audio/*.wav (22.05 kHz, 16-bit mono).

    python3 tools/gen_audio.py            # everything
    python3 tools/gen_audio.py gunshot    # just one sound
"""
import math
import glob
import os
import random
import struct
import sys
import wave

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
rnd = random.Random(7)


# --- Building blocks -------------------------------------------------------------------

def silence(sec):
    return [0.0] * int(sec * SR)


def noise(sec):
    return [rnd.uniform(-1, 1) for _ in range(int(sec * SR))]


def env(n, attack=0.005, decay=0.2, sustain=0.0, hold=0.0, curve=4.0):
    """Attack, optional hold, exponential decay to `sustain` (as fractions of seconds)."""
    out = []
    a = max(1, int(attack * SR))
    h = int(hold * SR)
    for i in range(n):
        if i < a:
            out.append(i / a)
        elif i < a + h:
            out.append(1.0)
        else:
            t = (i - a - h) / max(1.0, decay * SR)
            out.append(sustain + (1 - sustain) * math.exp(-curve * t))
    return out


def mul(a, b):
    return [x * y for x, y in zip(a, b)]


def gain(a, g):
    return [x * g for x in a]


def mix(*tracks):
    n = max(len(t) for t in tracks)
    out = [0.0] * n
    for t in tracks:
        for i, v in enumerate(t):
            out[i] += v
    return out


def place(base, sound, at_sec, g=1.0):
    start = int(at_sec * SR)
    need = start + len(sound)
    if need > len(base):
        base.extend([0.0] * (need - len(base)))
    for i, v in enumerate(sound):
        base[start + i] += v * g
    return base


def lowpass(x, cutoff):
    rc = 1.0 / (2 * math.pi * cutoff)
    alpha = (1.0 / SR) / (rc + 1.0 / SR)
    out, y = [], 0.0
    for v in x:
        y += alpha * (v - y)
        out.append(y)
    return out


def highpass(x, cutoff):
    rc = 1.0 / (2 * math.pi * cutoff)
    alpha = rc / (rc + 1.0 / SR)
    out, y, prev = [], 0.0, 0.0
    for v in x:
        y = alpha * (y + v - prev)
        prev = v
        out.append(y)
    return out


def bandpass(x, lo, hi):
    return lowpass(highpass(x, lo), hi)


def sweep_lowpass(x, c0, c1):
    out, y = [], 0.0
    n = len(x)
    for i, v in enumerate(x):
        c = c0 + (c1 - c0) * i / max(1, n - 1)
        rc = 1.0 / (2 * math.pi * max(20.0, c))
        alpha = (1.0 / SR) / (rc + 1.0 / SR)
        y += alpha * (v - y)
        out.append(y)
    return out


def osc(freq_fn, sec, shape="sine", vib=0.0, vib_rate=5.0):
    """freq_fn: constant or function of t (seconds)."""
    n = int(sec * SR)
    out, ph = [], 0.0
    for i in range(n):
        t = i / SR
        f = freq_fn(t) if callable(freq_fn) else freq_fn
        if vib:
            f *= 1 + vib * math.sin(2 * math.pi * vib_rate * t)
        ph += f / SR
        p = ph % 1.0
        if shape == "sine":
            v = math.sin(2 * math.pi * p)
        elif shape == "square":
            v = 1.0 if p < 0.5 else -1.0
        elif shape == "saw":
            v = 2 * p - 1
        elif shape == "tri":
            v = 4 * abs(p - 0.5) - 1
        else:
            v = 0.0
        out.append(v)
    return out


def pluck(freq, sec, bright=0.5, decay=0.996):
    """Karplus-Strong plucked string."""
    period = max(2, int(SR / freq))
    buf = [rnd.uniform(-1, 1) for _ in range(period)]
    buf = lowpass(buf, 1500 + 6000 * bright)
    out = []
    n = int(sec * SR)
    idx = 0
    for _ in range(n):
        v = buf[idx]
        nxt = buf[(idx + 1) % period]
        buf[idx] = decay * 0.5 * (v + nxt)
        out.append(v)
        idx = (idx + 1) % period
    return out


def fm(carrier, mod_ratio, index, sec, decay=0.6):
    n = int(sec * SR)
    out = []
    for i in range(n):
        t = i / SR
        e = math.exp(-t / decay)
        m = math.sin(2 * math.pi * carrier * mod_ratio * t) * index * e
        out.append(math.sin(2 * math.pi * carrier * t + m))
    return out


def normalize(x, peak=0.9):
    m = max((abs(v) for v in x), default=0.0)
    if m < 1e-9:
        return x
    return [v * peak / m for v in x]


def fade(x, fin=0.003, fout=0.02):
    n = len(x)
    a, b = int(fin * SR), int(fout * SR)
    x = list(x)
    for i in range(min(a, n)):
        x[i] *= i / a
    for i in range(min(b, n)):
        x[n - 1 - i] *= i / b
    return x


def write(name, x, peak=0.9):
    os.makedirs(OUT, exist_ok=True)
    if glob.glob(os.path.join(OUT, name + "_[0-9]*.ogg")):
        print("  skipped", name, "(recorded sound from tools/import_sfx.py)")
        return
    x = fade(normalize(x, peak))
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, v)) * 32767)) for v in x))
    print("  wrote", name, "%.2fs" % (len(x) / SR))


def note_freq(name):
    names = {"C": -9, "C#": -8, "D": -7, "D#": -6, "E": -5, "F": -4, "F#": -3, "G": -2, "G#": -1, "A": 0, "A#": 1, "B": 2}
    pitch, octave = name[:-1], int(name[-1])
    return 440.0 * 2 ** ((names[pitch] + (octave - 4) * 12) / 12)


# --- Sound effects ---------------------------------------------------------------------

def s_gunshot():
    crack = mul(highpass(noise(0.35), 900), env(int(0.35 * SR), 0.001, 0.05))
    boom = mul(lowpass(noise(0.5), 300), env(int(0.5 * SR), 0.002, 0.18))
    thump = mul(osc(lambda t: 90 * math.exp(-t * 12) + 40, 0.3), env(int(0.3 * SR), 0.001, 0.1))
    tail = mul(bandpass(noise(0.8), 200, 1200), env(int(0.8 * SR), 0.01, 0.35, curve=5))
    return mix(gain(crack, 0.9), gain(boom, 1.2), gain(thump, 0.6), gain(tail, 0.25))


def s_rifle():
    x = s_gunshot()
    echo = gain(lowpass(x, 1200), 0.35)
    return place(list(x) + silence(0.4), echo, 0.22)


def s_shotgun():
    boom = mul(lowpass(noise(0.7), 700), env(int(0.7 * SR), 0.002, 0.25))
    crack = mul(highpass(noise(0.3), 1500), env(int(0.3 * SR), 0.001, 0.07))
    thump = mul(osc(lambda t: 70 * math.exp(-t * 8) + 35, 0.4), env(int(0.4 * SR), 0.001, 0.15))
    return mix(gain(boom, 1.3), crack, gain(thump, 0.8))


def s_slash():
    n = int(0.3 * SR)
    swish = mul(sweep_lowpass(noise(0.3), 800, 5000), env(n, 0.08, 0.1, curve=6))
    ring = mul(fm(2400, 1.41, 2, 0.25, 0.08), env(int(0.25 * SR), 0.001, 0.08))
    return place(swish, gain(ring, 0.15), 0.08)


def s_blunt():
    thud = mul(osc(lambda t: 120 * math.exp(-t * 20) + 50, 0.25), env(int(0.25 * SR), 0.001, 0.07))
    crunch = mul(lowpass(noise(0.2), 900), env(int(0.2 * SR), 0.001, 0.04))
    return mix(thud, gain(crunch, 0.7))


def s_punch():
    return mix(s_blunt(), gain(mul(highpass(noise(0.1), 2000), env(int(0.1 * SR), 0.001, 0.02)), 0.3))


def s_clang():
    x = mix(fm(620, 2.76, 3, 1.0, 0.35), gain(fm(1240, 1.83, 2, 1.0, 0.25), 0.5), gain(fm(1860, 3.1, 1.5, 1.0, 0.2), 0.3))
    return mul(x, env(len(x), 0.001, 0.45))


def s_hammer():
    return mix(s_clang(), gain(s_blunt(), 0.8))


def s_whip():
    n = int(0.35 * SR)
    swish = mul(sweep_lowpass(noise(0.35), 400, 6000), env(n, 0.15, 0.05, curve=8))
    crack = mul(highpass(noise(0.08), 2500), env(int(0.08 * SR), 0.0005, 0.015))
    return place(swish, gain(crack, 1.3), 0.17)


def s_explosion():
    rumble = mul(lowpass(noise(1.6), 250), env(int(1.6 * SR), 0.005, 0.6, curve=3))
    blast = mul(lowpass(noise(0.6), 1500), env(int(0.6 * SR), 0.001, 0.15))
    thump = mul(osc(lambda t: 60 * math.exp(-t * 4) + 25, 0.8), env(int(0.8 * SR), 0.001, 0.3))
    debris = silence(1.6)
    for i in range(20):
        place(debris, mul(highpass(noise(0.03), 3000), env(int(0.03 * SR), 0.001, 0.01)), 0.2 + rnd.random() * 1.0, rnd.uniform(0.1, 0.3))
    return mix(gain(rumble, 1.5), blast, thump, debris)


def s_dog():
    out = silence(0.6)
    for k, at in enumerate([0.0, 0.22]):
        f0 = 520 if k == 0 else 480
        bark = osc(lambda t, f0=f0: f0 * (1.4 - 0.9 * min(1, t / 0.12)), 0.16, "saw")
        bark = bandpass(bark, 300, 2200)
        bark = mul(bark, env(len(bark), 0.005, 0.06, curve=3))
        grit = mul(bandpass(noise(0.16), 500, 2500), env(int(0.16 * SR), 0.005, 0.05))
        place(out, mix(bark, gain(grit, 0.4)), at)
    return out


def s_heal():
    out = silence(1.0)
    for i, f in enumerate([523.25, 659.25, 783.99, 1046.5]):
        tone = mul(osc(f, 0.7, "sine"), env(int(0.7 * SR), 0.01, 0.35))
        shimmer = mul(osc(f * 2, 0.7, "sine"), env(int(0.7 * SR), 0.01, 0.2))
        place(out, mix(tone, gain(shimmer, 0.2)), i * 0.07, 0.5)
    return out


def s_buff():
    x = osc(lambda t: 300 + 700 * t, 0.45, "tri")
    return mul(x, env(len(x), 0.02, 0.2))


def s_bell():
    x = mix(fm(880, 3.5, 2.5, 1.6, 0.6), gain(fm(1320, 2.0, 1.5, 1.6, 0.4), 0.4))
    return mul(x, env(len(x), 0.002, 0.8, curve=3))


def s_card():
    x = mul(bandpass(noise(0.12), 1500, 6000), env(int(0.12 * SR), 0.001, 0.03))
    return place(x + silence(0.1), x, 0.07)


def s_dart():
    x = mul(sweep_lowpass(noise(0.2), 6000, 900), env(int(0.2 * SR), 0.005, 0.06))
    thk = mul(osc(700, 0.05), env(int(0.05 * SR), 0.001, 0.01))
    return place(x, thk, 0.17)


def s_glass():
    tink = mix(fm(2600, 1.5, 1, 0.6, 0.15), gain(fm(3900, 2.1, 1, 0.6, 0.1), 0.6))
    shards = silence(0.6)
    for i in range(8):
        place(shards, mul(fm(rnd.uniform(3000, 6000), 1.3, 1, 0.08, 0.03), env(int(0.08 * SR), 0.001, 0.03)), 0.02 + rnd.random() * 0.25, 0.3)
    return mix(mul(tink, env(len(tink), 0.001, 0.12)), shards)


def s_cloth():
    return mul(bandpass(noise(0.35), 300, 2500), env(int(0.35 * SR), 0.08, 0.1))


def s_badge():
    x = mix(fm(1800, 2.4, 1.2, 0.4, 0.12), gain(fm(2700, 1.7, 1, 0.4, 0.1), 0.5))
    return mul(x, env(len(x), 0.001, 0.12))


def s_whoosh():
    n = int(0.35 * SR)
    return mul(sweep_lowpass(noise(0.35), 300, 3000), env(n, 0.15, 0.1, curve=5))


def _formants(x, peaks):
    """Sum of band-passed copies: a crude vocal tract, so beasts sound throaty, not buzzy."""
    return mix(*[gain(bandpass(x, f * 0.8, f * 1.25), g) for f, g in peaks])


def s_roar():
    # A big animal roar: breathy noise through throat formants, a rough voice under it,
    # swelling and falling. Low end is cut so it doesn't turn into a buzz.
    sec = 1.3
    n = int(sec * SR)
    pitch = lambda t: 150 + 70 * math.sin(min(1.0, t / sec) * math.pi) + 6 * math.sin(t * 60)
    voice = osc(pitch, sec, "saw")
    breath = noise(sec)
    rough = [0.55 + 0.45 * abs(math.sin(i / SR * 2 * math.pi * 23)) for i in range(n)]
    x = mix(gain(voice, 0.5), gain(breath, 0.9))
    x = mul(_formants(x, [(420, 1.0), (900, 0.8), (2100, 0.35)]), rough)
    x = highpass(x, 180)
    return mul(x, env(n, 0.12, 0.7, 0.0, 0.35, curve=2.5))


def s_howl():
    f = lambda t: 380 + 260 * math.sin(min(1, t / 1.4) * math.pi) + 20 * math.sin(t * 30)
    x = osc(f, 1.8, "tri")
    x = mix(x, gain(osc(lambda t: f(t) * 2, 1.8), 0.2))
    return mul(bandpass(x, 200, 3000), env(len(x), 0.25, 0.5, 0.0, 0.8, curve=3))


def s_hiss():
    return mul(highpass(noise(0.7), 3000), env(int(0.7 * SR), 0.05, 0.35, 0.0, 0.2))


def s_rattle():
    n = int(0.9 * SR)
    x = highpass(noise(0.9), 3500)
    am = [0.5 + 0.5 * math.sin(2 * math.pi * 55 * i / SR) for i in range(n)]
    return mul(mul(x, am), env(n, 0.02, 0.4, 0.0, 0.4))


def s_caw():
    out = silence(0.9)
    for at in [0.0, 0.35]:
        c = osc(lambda t: 950 - 500 * t, 0.25, "saw")
        c = bandpass(c, 600, 2800)
        c = mix(c, gain(bandpass(noise(0.25), 1000, 3000), 0.5))
        place(out, mul(c, env(len(c), 0.01, 0.12, curve=2)), at)
    return out


def s_growl():
    # A snarl: a rolling "rrr" of breathy noise and a mid voice through two formants.
    sec = 0.7
    n = int(sec * SR)
    voice = osc(lambda t: 190 + 25 * math.sin(t * 9) + rnd.uniform(-4, 4), sec, "saw")
    breath = noise(sec)
    roll = [0.35 + 0.65 * abs(math.sin(i / SR * 2 * math.pi * 28)) for i in range(n)]
    x = mul(mix(gain(voice, 0.45), gain(breath, 1.0)), roll)
    x = highpass(_formants(x, [(650, 1.0), (1500, 0.7), (2800, 0.25)]), 250)
    return mul(x, env(n, 0.03, 0.35, 0.0, 0.2, curve=2.5))


def s_bite():
    # A short snarl, then jaws snapping shut.
    out = silence(0.55)
    sn = s_growl()[: int(0.28 * SR)]
    place(out, mul(sn, env(len(sn), 0.01, 0.2, curve=2)), 0.0, 0.7)
    snap = mix(mul(highpass(noise(0.05), 2500), env(int(0.05 * SR), 0.0005, 0.015)),
               gain(mul(osc(lambda t: 900 * math.exp(-t * 60) + 300, 0.05), env(int(0.05 * SR), 0.0005, 0.02)), 0.6))
    place(out, snap, 0.22, 1.0)
    place(out, gain(snap, 0.5), 0.27, 1.0)
    return out


def s_stomp():
    boom = mul(osc(lambda t: 55 * math.exp(-t * 3) + 30, 0.8), env(int(0.8 * SR), 0.001, 0.3))
    dust = mul(lowpass(noise(0.8), 400), env(int(0.8 * SR), 0.005, 0.3))
    return mix(gain(boom, 1.4), dust)


def s_eerie():
    a = osc(lambda t: 220 + 8 * math.sin(t * 3), 2.2, "sine", 0.01, 6)
    b = osc(lambda t: 233 + 6 * math.sin(t * 2.3), 2.2, "sine", 0.01, 5)
    c = osc(lambda t: 330 + 12 * math.sin(t * 1.7), 2.2, "tri")
    breath = bandpass(noise(2.2), 400, 1500)
    x = mix(a, b, gain(c, 0.4), gain(breath, 0.25))
    return mul(x, env(len(x), 0.5, 0.8, 0.0, 0.6, curve=3))


def s_laugh():
    out = silence(1.1)
    for i in range(5):
        h = osc(lambda t, i=i: 180 - i * 8 + 40 * math.exp(-t * 20), 0.14, "saw")
        h = bandpass(h, 200, 1800)
        place(out, mul(h, env(len(h), 0.01, 0.07)), i * 0.17)
    return out


def s_paper():
    x = mul(bandpass(noise(0.4), 1200, 5000), [abs(math.sin(i / SR * 30)) for i in range(int(0.4 * SR))])
    return mul(x, env(len(x), 0.02, 0.2))


def s_page():
    return gain(s_paper(), 0.7)


def s_puff():
    return mul(lowpass(noise(0.4), 1800), env(int(0.4 * SR), 0.01, 0.15))


def s_lantern():
    return mix(gain(s_badge(), 0.5), gain(mul(lowpass(noise(0.5), 1200), env(int(0.5 * SR), 0.05, 0.2)), 0.6))


def s_coin():
    out = silence(0.5)
    for i, f in enumerate([2093, 2637]):
        c = mul(fm(f, 1.5, 0.8, 0.35, 0.12), env(int(0.35 * SR), 0.001, 0.12))
        place(out, c, i * 0.06, 0.6)
    return out


def s_whistle():
    f = lambda t: 1400 + 500 * math.sin(min(1, t / 0.5) * math.pi / 2) - (700 * max(0, t - 0.5) / 0.3)
    x = osc(f, 0.8, "sine", 0.01, 7)
    return mul(mix(x, gain(highpass(noise(0.8), 3000), 0.05)), env(len(x), 0.03, 0.2, 0.0, 0.45))


def s_thunder():
    x = mul(lowpass(noise(2.0), 180), env(int(2.0 * SR), 0.02, 0.9, curve=3))
    crack = mul(highpass(noise(0.2), 2000), env(int(0.2 * SR), 0.001, 0.05))
    return mix(gain(x, 1.6), gain(crack, 0.5))


def s_wind():
    n = int(2.0 * SR)
    x = bandpass(noise(2.0), 200, 1200)
    am = [0.5 + 0.5 * math.sin(i / SR * 2.1) * math.sin(i / SR * 0.7) for i in range(n)]
    return mul(mul(x, am), env(n, 0.4, 0.8, 0.0, 0.8))


def s_knock():
    out = silence(0.8)
    for at in [0.0, 0.18, 0.5]:
        k = mix(mul(osc(lambda t: 300 * math.exp(-t * 30) + 150, 0.08), env(int(0.08 * SR), 0.001, 0.03)),
                gain(mul(bandpass(noise(0.05), 500, 2000), env(int(0.05 * SR), 0.001, 0.01)), 0.6))
        place(out, k, at)
    return out


def s_screech():
    x = osc(lambda t: 3200 + 800 * math.sin(t * 40), 0.4, "saw")
    x = bandpass(x, 1500, 6000)
    return mul(x, env(len(x), 0.01, 0.2))


def s_click():
    return mul(bandpass(noise(0.04), 1500, 5000), env(int(0.04 * SR), 0.0005, 0.008))


def s_hover():
    x = osc(1600, 0.05, "sine")
    return mul(x, env(len(x), 0.002, 0.015))


def s_hit():
    return mix(s_blunt(), gain(mul(bandpass(noise(0.15), 800, 3000), env(int(0.15 * SR), 0.001, 0.04)), 0.5))


def s_crit():
    x = mix(gain(s_hit(), 1.0), gain(mul(fm(180, 0.5, 4, 0.5, 0.2), env(int(0.5 * SR), 0.001, 0.2)), 0.6))
    return x


def s_death():
    x = osc(lambda t: 160 * math.exp(-t * 2.5) + 40, 0.9, "saw")
    x = lowpass(x, 700)
    return mix(mul(x, env(len(x), 0.01, 0.4)), gain(mul(lowpass(noise(0.9), 500), env(int(0.9 * SR), 0.01, 0.3)), 0.5))


def s_death_hero():
    out = silence(2.4)
    for i, f in enumerate([392.0, 369.99, 329.63, 246.94]):
        t = mul(osc(f, 0.9, "tri", 0.006, 5), env(int(0.9 * SR), 0.05, 0.4, 0.0, 0.3))
        place(out, t, i * 0.42, 0.6)
    return out


def s_heartbeat():
    out = silence(1.2)
    for at in [0.0, 0.18, 0.7, 0.88]:
        b = mul(osc(lambda t: 60 * math.exp(-t * 10) + 35, 0.2), env(int(0.2 * SR), 0.002, 0.06))
        place(out, b, at, 1.0 if at in (0.0, 0.7) else 0.7)
    return out


def s_breaking():
    a = osc(lambda t: 311 - 60 * t, 1.4, "saw")
    b = osc(lambda t: 329 - 64 * t, 1.4, "saw")
    x = lowpass(mix(a, b), 1400)
    return mul(x, env(len(x), 0.02, 0.8, 0.0, 0.3))


def s_fanfare():
    # Victory: a quick picked run up the chord on a steel-string guitar, then two warm
    # strums (C then G) and a ringing high note. No square waves.
    out = silence(2.6)
    run = ["G3", "B3", "D4", "G4"]
    for i, n in enumerate(run):
        place(out, pluck(note_freq(n), 1.2, 0.45, 0.996), i * 0.09, 0.55)
    place(out, strum("C", 0.8, 0.018, 1.2, 0.35), 0.40, 0.8)
    place(out, strum("G", 0.9, 0.022, 2.0, 0.35), 0.78, 0.9)
    place(out, bass_note("G2", 1.6), 0.78, 0.7)
    place(out, pluck(note_freq("B4"), 1.6, 0.55, 0.997), 0.80, 0.35)
    place(out, pluck(note_freq("D5"), 1.8, 0.55, 0.997), 0.86, 0.3)
    return lowpass(out, 5000)


def s_eat():
    out = silence(0.8)
    for i in range(4):
        place(out, mul(bandpass(noise(0.07), 300, 1500), env(int(0.07 * SR), 0.005, 0.03)), i * 0.17, 0.8)
    return out


def s_fire():
    n = int(3.0 * SR)
    base = mul(lowpass(noise(3.0), 500), [0.4] * n)
    for i in range(70):
        place(base, mul(highpass(noise(0.02), 1500), env(int(0.02 * SR), 0.001, 0.005)), rnd.random() * 2.9, rnd.uniform(0.2, 0.9))
    return base


def s_wagon():
    n = int(1.8 * SR)
    rumble = mul(lowpass(noise(1.8), 220), [0.6 + 0.4 * math.sin(i / SR * 11) for i in range(n)])
    creak = mul(osc(lambda t: 420 + 60 * math.sin(t * 6), 1.8, "saw"), [max(0, math.sin(i / SR * 3.3)) ** 6 for i in range(n)])
    hooves = silence(1.8)
    for i in range(8):
        place(hooves, mul(bandpass(noise(0.05), 300, 1200), env(int(0.05 * SR), 0.001, 0.02)), i * 0.22, 0.8)
    x = mix(gain(rumble, 1.0), gain(bandpass(creak, 300, 2000), 0.12), gain(hooves, 0.7))
    return mul(x, env(n, 0.2, 0.6, 0.0, 1.0))


def s_footsteps():
    out = silence(1.0)
    for i in range(4):
        place(out, mul(bandpass(noise(0.08), 200, 1500), env(int(0.08 * SR), 0.002, 0.03)), i * 0.24, 0.9)
    return out


SFX = {k[2:]: v for k, v in globals().items() if k.startswith("s_")}


# --- Music -----------------------------------------------------------------------------

CHORDS = {
    "G": ["G2", "B2", "D3", "G3", "B3"], "C": ["C3", "E3", "G3", "C4", "E4"], "D": ["D3", "F#3", "A3", "D4", "F#4"],
    "Em": ["E2", "B2", "E3", "G3", "B3"], "Am": ["A2", "E3", "A3", "C4", "E4"], "Dm": ["D3", "A3", "D4", "F4", "A4"],
    "E": ["E2", "B2", "E3", "G#3", "B3"], "F": ["F2", "C3", "F3", "A3", "C4"], "Bb": ["A#2", "F3", "A#3", "D4", "F4"],
    "A": ["A2", "E3", "A3", "C#4", "E4"],
}


def strum(chord, g=0.6, spread=0.012, dur=1.2, bright=0.4):
    out = silence(dur + 0.2)
    for i, n in enumerate(CHORDS[chord]):
        place(out, pluck(note_freq(n), dur, bright, 0.995), i * spread, g / len(CHORDS[chord]) * 2)
    return out


def bass_note(n, dur=0.6):
    return mul(pluck(note_freq(n), dur, 0.1, 0.997), env(int(dur * SR), 0.002, dur * 0.6, curve=2))


def harmonica(freq, dur):
    x = mix(osc(freq, dur, "square", 0.004, 5.5), gain(osc(freq * 2, dur, "saw", 0.004, 5.5), 0.3), gain(bandpass(noise(dur), 800, 3000), 0.08))
    x = lowpass(x, 2200)
    return mul(x, env(len(x), 0.04, dur, 0.6, dur * 0.5, curve=2))


def kick():
    return mul(osc(lambda t: 110 * math.exp(-t * 18) + 45, 0.3), env(int(0.3 * SR), 0.001, 0.12))


def snare():
    return mix(mul(bandpass(noise(0.2), 1000, 6000), env(int(0.2 * SR), 0.001, 0.07)), gain(mul(osc(190, 0.15), env(int(0.15 * SR), 0.001, 0.05)), 0.5))


def shaker():
    return mul(highpass(noise(0.06), 5000), env(int(0.06 * SR), 0.01, 0.02))


def m_trail():
    bpm, beats = 104, 64
    b = 60.0 / bpm
    out = silence(beats * b + 1)
    prog = ["G", "G", "C", "G", "D", "C", "G", "D"] * 2
    for bar, ch in enumerate(prog):
        t0 = bar * 4 * b
        root = CHORDS[ch][0]
        fifth = CHORDS[ch][2]
        place(out, bass_note(root), t0, 0.9)
        place(out, strum(ch, 0.5), t0 + b, 0.7)
        place(out, bass_note(fifth.replace("3", "2") if "3" in fifth else fifth), t0 + 2 * b, 0.7)
        place(out, strum(ch, 0.5), t0 + 3 * b, 0.7)
        for k in range(8):
            place(out, shaker(), t0 + k * b / 2, 0.15)
    melody = [("D5", 1), ("B4", 1), ("G4", 2), ("A4", 1), ("B4", 1), ("A4", 2), ("G4", 1), ("E4", 1), ("D4", 2), ("E4", 1), ("G4", 1), ("A4", 2),
              ("B4", 2), ("D5", 2), ("C5", 1), ("B4", 1), ("A4", 2), ("G4", 3), ("B4", 1), ("A4", 2), ("F#4", 2), ("G4", 4)]
    t = 16 * 4 * b / 2
    for n, d in melody:
        if t > beats * b - 1:
            break
        place(out, harmonica(note_freq(n), d * b * 0.95), t, 0.22)
        t += d * b
    return out[: int(beats * b * SR)]


def m_town():
    bpm = 88
    b = 60.0 / bpm
    prog = ["C", "C", "F", "C", "G", "G", "C", "G", "F", "C", "G", "C"]
    out = silence(len(prog) * 3 * b + 1)
    for bar, ch in enumerate(prog):
        t0 = bar * 3 * b
        chord = {"C": "C", "F": "F", "G": "G"}[ch]
        place(out, bass_note(CHORDS[chord][0]), t0, 0.9)
        place(out, strum(chord, 0.35, 0.006, 0.8, 0.7), t0 + b, 0.6)
        place(out, strum(chord, 0.35, 0.006, 0.8, 0.7), t0 + 2 * b, 0.55)
    mel = ["E4", "G4", "C5", "B4", "A4", "G4", "F4", "A4", "C5", "G4", "E4", "C4", "D4", "G4", "B4", "D5", "C5", "B4", "C5", "G4", "E4", "D4", "E4", "C4"]
    for i, n in enumerate(mel):
        place(out, gain(pluck(note_freq(n), 0.9, 0.8, 0.994), 0.5), i * 1.5 * b, 0.4)
    return out[: int(len(prog) * 3 * b * SR)]


def m_combat():
    bpm = 138
    b = 60.0 / bpm
    prog = ["Am", "Am", "F", "E", "Am", "Am", "Dm", "E"] * 2
    out = silence(len(prog) * 4 * b + 1)
    for bar, ch in enumerate(prog):
        t0 = bar * 4 * b
        for k in range(8):
            place(out, strum(ch, 0.35, 0.006, 0.25, 0.6), t0 + k * b / 2, 0.55 if k % 2 == 0 else 0.35)
        for k in range(4):
            place(out, kick(), t0 + k * b, 0.9 if k % 2 == 0 else 0.6)
            if k % 2 == 1:
                place(out, snare(), t0 + k * b, 0.5)
        place(out, bass_note(CHORDS[ch][0], 0.4), t0, 1.0)
        place(out, bass_note(CHORDS[ch][0], 0.4), t0 + 2.5 * b, 0.8)
    stabs = [("E5", 0), ("C5", 2), ("A4", 4), ("B4", 6)]
    for rep in range(4):
        for n, beat in stabs:
            place(out, harmonica(note_freq(n), b * 1.6), rep * 16 * b + beat * b + 32 * b * (rep % 2), 0.13)
    return out[: int(len(prog) * 4 * b * SR)]


def m_boss():
    bpm = 120
    b = 60.0 / bpm
    prog = ["Dm", "Dm", "Bb", "A", "Dm", "Dm", "Bb", "A"] * 2
    out = silence(len(prog) * 4 * b + 1)
    drone = mul(osc(note_freq("D2"), len(prog) * 4 * b + 1, "saw"), [0.25] * int((len(prog) * 4 * b + 1) * SR))
    place(out, lowpass(drone, 300), 0, 0.5)
    for bar, ch in enumerate(prog):
        t0 = bar * 4 * b
        for k in range(4):
            place(out, kick(), t0 + k * b, 1.0)
            place(out, kick(), t0 + k * b + b * 0.5, 0.5)
        place(out, snare(), t0 + 1 * b, 0.6)
        place(out, snare(), t0 + 3 * b, 0.6)
        place(out, strum(ch, 0.5, 0.004, 1.5, 0.3), t0, 0.7)
        place(out, strum(ch, 0.4, 0.004, 1.0, 0.3), t0 + 2 * b, 0.6)
    for rep in range(4):
        place(out, harmonica(note_freq("A4"), b * 3.5), rep * 16 * b + 4 * b, 0.12)
        place(out, harmonica(note_freq("G#4"), b * 3.5), rep * 16 * b + 12 * b, 0.12)
    return out[: int(len(prog) * 4 * b * SR)]


def m_camp():
    bpm = 72
    b = 60.0 / bpm
    prog = ["G", "Em", "C", "D", "G", "Em", "C", "G"]
    out = silence(len(prog) * 4 * b + 1)
    for bar, ch in enumerate(prog):
        t0 = bar * 4 * b
        notes = CHORDS[ch]
        pattern = [0, 2, 3, 4, 1, 3, 2, 4]
        for k, idx in enumerate(pattern):
            place(out, pluck(note_freq(notes[idx]), 1.4, 0.35, 0.996), t0 + k * b / 2, 0.35)
    mel = [("B4", 2), ("A4", 2), ("G4", 4), ("E4", 2), ("G4", 2), ("A4", 4), ("B4", 2), ("D5", 2), ("C5", 2), ("B4", 2), ("A4", 4), ("G4", 4)]
    t = 4 * b
    for n, d in mel:
        place(out, harmonica(note_freq(n), d * b * 0.9), t, 0.12)
        t += d * b
    return out[: int(len(prog) * 4 * b * SR)]


def m_cave():
    dur = 36.0
    n = int(dur * SR)
    out = silence(dur)
    d1 = osc(lambda t: note_freq("A1") * (1 + 0.003 * math.sin(t * 0.5)), dur, "saw")
    d2 = osc(lambda t: note_freq("E2") * (1 + 0.004 * math.sin(t * 0.37)), dur, "tri")
    drone = lowpass(mix(gain(d1, 0.5), gain(d2, 0.4)), 400)
    swell = [0.6 + 0.4 * math.sin(2 * math.pi * i / n * 3) for i in range(n)]
    place(out, mul(drone, swell), 0, 0.5)
    for i in range(22):
        drip = mul(osc(lambda t: 1800 * math.exp(-t * 30) + 900, 0.25), env(int(0.25 * SR), 0.001, 0.05))
        place(out, drip, rnd.uniform(0.5, dur - 1), rnd.uniform(0.15, 0.4))
    for i in range(5):
        place(out, gain(s_eerie(), 0.35), rnd.uniform(1, dur - 3), 1.0)
    return out[:n]


MUSIC = {"music_trail": m_trail, "music_town": m_town, "music_combat": m_combat, "music_boss": m_boss, "music_camp": m_camp, "music_cave": m_cave}


def main():
    only = sys.argv[1:]
    for name, fn in SFX.items():
        if only and name not in only:
            continue
        write(name, fn())
    for name, fn in MUSIC.items():
        if only and name not in only:
            continue
        write(name, fn(), 0.75)


if __name__ == "__main__":
    main()
