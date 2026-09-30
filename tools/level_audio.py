"""Measure every sound effect and write per-file gain offsets to assets/audio/levels.json.

The clips come from different packs and generators, so some are far louder than others.
Rather than rewriting the files, the game applies these offsets at play time (Audio.play).
Loudness is the loudest EBU R128 momentary value (400 ms window, clips padded with silence),
which is close to how loud a short effect sounds. Interface sounds get a quieter target.

Usage: python tools/level_audio.py   (needs ffmpeg on PATH). Rerun after adding sounds.
"""
import json
import os
import re
import subprocess

AUDIO = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
TARGET = -20.0          # LUFS, most effects
TARGET_UI = -30.0       # clicks, pages, coins, cloth: heard constantly, keep them soft
UI = {"click", "hover", "page", "paper", "cloth", "coin", "card", "footsteps", "lantern"}
MAX_BOOST = 6.0
MAX_CUT = -24.0


def measure(path):
    out = subprocess.run(["ffmpeg", "-hide_banner", "-nostats", "-i", path, "-af",
                          "apad=pad_dur=0.5,ebur128=peak=sample", "-f", "null", "-"],
                         capture_output=True, text=True, encoding="utf-8").stderr
    moms = [float(m) for m in re.findall(r"\bM:\s*(-?[\d.]+)", out)]
    peak = re.search(r"Sample peak:\s*\n\s*Peak:\s*(-?[\d.]+|-inf)", out)
    peak_db = float(peak.group(1)) if peak and peak.group(1) != "-inf" else -60.0
    return (max(moms) if moms else -70.0), peak_db


def main():
    levels = {}
    for f in sorted(os.listdir(AUDIO)):
        base, ext = os.path.splitext(f)
        if ext not in (".wav", ".ogg") or base.startswith("music_"):
            continue
        key = re.sub(r"_\d+$", "", base)
        loud, peak = measure(os.path.join(AUDIO, f))
        target = TARGET_UI if key in UI else TARGET
        gain = target - loud
        gain = min(gain, MAX_BOOST, -1.0 - peak)  # never push the peak past -1 dBFS
        gain = max(gain, MAX_CUT)
        levels[base] = round(gain, 1)
        print(f"{base:16s} loud {loud:6.1f}  peak {peak:6.1f}  gain {gain:+5.1f}")
    with open(os.path.join(AUDIO, "levels.json"), "w", encoding="utf-8") as fh:
        json.dump(levels, fh, indent=1, sort_keys=True)
        fh.write("\n")


if __name__ == "__main__":
    main()
