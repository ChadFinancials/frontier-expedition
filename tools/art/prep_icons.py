"""Turn a generated icon (any size, on a plain light background) into a game icon.

    python tools/art/prep_icons.py <image> <key> [<image> <key> ...]
    python tools/art/prep_icons.py --dir art-src/icons       # every <key>.png/.webp/.jpg there

Writes assets/art/icons/<key>.png: 256 x 256, transparent background, trimmed and centred
with a small margin. The game shows it in place of the drawn icon for <key> (keys are listed
in docs/COMFYUI_GUIDE.md section 5). Needs Pillow and numpy: pip install pillow numpy

How the background goes: its colour is read from the image border; everything of that colour
connected to the border is removed (a loose match, so soft ground shadows go too, stopped by
the dark outline; coloured shadows listed in SHADOW_COLS go the same way). For keys in POCKET_KEYS (see-through shapes like the wheel) enclosed
pockets of the background colour are removed too. Edge pixels fade out so there is no halo.
"""
import os
import sys
from collections import deque

import numpy as np
from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
OUT = os.path.join(ROOT, "assets", "art", "icons")
WORK = 512          # processing size
FINAL = 256         # saved size
LOOSE = 62          # colour distance still counted as background when touching the border
TIGHT = 18          # colour distance for enclosed background pockets
POCKET = 120        # smallest enclosed pocket (pixels at WORK size) removed
MARGIN = 0.07       # clear margin around the trimmed icon
# Icons with see-through gaps inside (a wheel's spokes): enclosed pockets of background colour
# are cut out too. Off for everything else, because a paper, canvas or label inside the
# outline is often the same cream as the background.
POCKET_KEYS = {"wheel"}
# Coloured ground shadows the grey-shadow rule misses, per key: the shadow's colour. Pixels near
# it that join the background go too (the dark outline stops the flood at the object).
SHADOW_COLS = {"bottle": [(197, 106, 50)]}
SHADOW_TOL = 40


def _flood(ok: np.ndarray, seeds) -> np.ndarray:
    h, w = ok.shape
    seen = np.zeros_like(ok)
    q = deque()
    for y, x in seeds:
        if ok[y, x] and not seen[y, x]:
            seen[y, x] = True
            q.append((y, x))
    while q:
        y, x = q.popleft()
        for ny, nx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
            if 0 <= ny < h and 0 <= nx < w and ok[ny, nx] and not seen[ny, nx]:
                seen[ny, nx] = True
                q.append((ny, nx))
    return seen


def prep(src: str, key: str, pockets: bool | None = None) -> str:
    if pockets is None:
        pockets = key in POCKET_KEYS
    img = Image.open(src).convert("RGBA")
    img.thumbnail((WORK, WORK), Image.LANCZOS)
    a = np.asarray(img).astype(np.float32)
    rgb = a[:, :, :3]
    h, w = rgb.shape[:2]
    border = np.concatenate([rgb[0], rgb[-1], rgb[:, 0], rgb[:, -1]])
    bg = np.median(border, axis=0)
    dist = np.sqrt(((rgb - bg) ** 2).sum(axis=2))
    seeds = [(0, x) for x in range(w)] + [(h - 1, x) for x in range(w)] + [(y, 0) for y in range(h)] + [(y, w - 1) for y in range(h)]
    # Soft ground shadows: light, greyish pixels joined to the background go with it.
    lum = rgb.mean(axis=2)
    sat = rgb.max(axis=2) - rgb.min(axis=2)
    shadow = (lum > 150) & (sat < 45)
    for c in SHADOW_COLS.get(key, []):
        # Distance to the blend from background to shadow colour, so the soft rim goes too.
        seg = np.array(c, np.float32) - bg
        t = np.clip(((rgb - bg) * seg).sum(axis=2) / max(float((seg * seg).sum()), 1.0), 0.0, 1.0)
        shadow |= np.sqrt(((rgb - (bg + t[:, :, None] * seg)) ** 2).sum(axis=2)) < SHADOW_TOL
    is_bg = _flood((dist < LOOSE) | shadow, seeds)
    # Enclosed pockets of plain background.
    near = ((dist < TIGHT) & ~is_bg) if pockets else np.zeros_like(is_bg)
    done = np.zeros_like(near)
    for y in range(h):
        for x in range(w):
            if near[y, x] and not done[y, x]:
                comp = _flood(near & ~done, [(y, x)])
                done |= comp
                if comp.sum() >= POCKET:
                    is_bg |= comp
    alpha = np.where(is_bg, 0.0, 255.0)
    # Soften the rim: object pixels next to the background fade with their likeness to it.
    edge = ~is_bg & (np.roll(is_bg, 1, 0) | np.roll(is_bg, -1, 0) | np.roll(is_bg, 1, 1) | np.roll(is_bg, -1, 1))
    ramp = np.clip((dist - 30.0) / 90.0, 0.0, 1.0) * 255.0
    alpha = np.where(edge, np.minimum(alpha, ramp), alpha)
    out = np.dstack([rgb, alpha]).astype(np.uint8)
    icon = Image.fromarray(out, "RGBA")
    box = icon.getbbox()
    if box is None:
        raise SystemExit(f"{src}: nothing left after removing the background")
    icon = icon.crop(box)
    side = int(max(icon.size) * (1.0 + 2 * MARGIN))
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    canvas.paste(icon, ((side - icon.size[0]) // 2, (side - icon.size[1]) // 2))
    canvas = canvas.resize((FINAL, FINAL), Image.LANCZOS)
    os.makedirs(OUT, exist_ok=True)
    dest = os.path.join(OUT, key + ".png")
    canvas.save(dest)
    return dest


def main() -> None:
    args = sys.argv[1:]
    pairs = []
    if args[:1] == ["--dir"]:
        d = args[1]
        for f in sorted(os.listdir(d)):
            base, ext = os.path.splitext(f)
            if ext.lower() in (".png", ".webp", ".jpg", ".jpeg"):
                pairs.append((os.path.join(d, f), base))
    else:
        if len(args) < 2 or len(args) % 2:
            raise SystemExit(__doc__)
        pairs = list(zip(args[0::2], args[1::2]))
    for src, key in pairs:
        print("wrote", prep(src, key))


if __name__ == "__main__":
    main()
