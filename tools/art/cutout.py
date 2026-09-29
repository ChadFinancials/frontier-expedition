"""Cut an isolated generated prop to a clean transparent PNG, and composite it.

Owner note Sept 29: the composite "takes stuff from the background and isn't a clean
transparent png to overlay on stuff". A colour threshold and a border flood fill both leave
field residue, because generated fields are a soft vignette plus paper grain. So the default
method is now rembg (a segmentation model), which cuts a clean edge and returns a fully
transparent field.

    # cut one sprite (rembg needs the art venv, see --method below)
    ~/.venvs/art/Scripts/python.exe tools/art/cutout.py \
        --sprite art-tests/wagon/wagon_02.png --out art-tests/wagon/wagon_cut.png

    # composite the cut sprite over a backdrop at the point it stands on
    python tools/art/cutout.py --sprite wagon_cut.png --backdrop title.png \
        --out mockup.png --at 700,772 --height 230

Methods:
  rembg    segmentation model. Cleanest. Needs the art venv (rembg, onnxruntime).
  flood    border flood fill. No dependencies. Leaves some residue on a vignetted field.
  auto     rembg if importable, else flood. Default.
"""

import argparse
import io
import pathlib
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = pathlib.Path(__file__).resolve().parents[2]


def _rembg(path):
    """Segmentation cut. Returns RGBA, or None when rembg is not installed.

    The fallback every time the venv is missing is what makes `python tools/art/cutout.py`
    still work, just with a worse edge.
    """
    try:
        from rembg import remove
    except ImportError:
        return None
    cut = remove(path.read_bytes())
    return Image.open(io.BytesIO(cut)).convert("RGBA")


def _floodfill(img, tol, feather):
    """Border flood fill. Follows a vignette gradient and stops at the prop outline."""
    w, h = img.size
    magic = (255, 0, 255)  # never appears in a sepia illustration
    work = img.copy()
    seeds = [
        (2, 2), (w - 3, 2), (2, h - 3), (w - 3, h - 3),
        (w // 2, 2), (w // 2, h - 3), (2, h // 2), (w - 3, h // 2),
    ]
    for seed in seeds:
        ImageDraw.floodfill(work, seed, magic, thresh=tol)
    field = Image.new("RGB", (w, h), magic)
    alpha = ImageChops.difference(work, field).convert("L").point(lambda v: 0 if v == 0 else 255)
    if feather:
        alpha = alpha.filter(ImageFilter.GaussianBlur(0.7))
    out = img.convert("RGBA")
    out.putalpha(alpha)
    return out


def key_out(path, tol=60, feather=True, method="auto"):
    """Return a trimmed RGBA cutout of the prop in `path`."""
    path = pathlib.Path(path)
    img = Image.open(path).convert("RGB")
    cut = None
    if method in ("auto", "rembg"):
        cut = _rembg(path)
    if cut is None:
        if method == "rembg":
            raise SystemExit(
                "rembg is not importable. Run with the art venv:\n"
                "  ~/.venvs/art/Scripts/python.exe tools/art/cutout.py ...\n"
                "or pass --method flood."
            )
        cut = _floodfill(img, tol, feather)
    box = cut.getchannel("A").point(lambda v: 255 if v > 200 else 0).getbbox()
    if box:
        cut = cut.crop(box)
    return cut


def alpha_report(cut):
    """Transparent share plus the alpha of the four corners, for verification."""
    w, h = cut.size
    a = cut.getchannel("A")
    hist = a.histogram()
    total = w * h
    corners = [a.getpixel(p) for p in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1))]
    return {
        "size": (w, h),
        "transparent_pct": round(100 * hist[0] / total, 1),
        "opaque_pct": round(100 * hist[255] / total, 1),
        "corners": corners,
        "clean": all(c == 0 for c in corners),
    }


def compose(backdrop, sprite, at, height, out_path):
    """Scale the sprite to `height` px tall and put its bottom centre at `at`."""
    bd = Image.open(backdrop).convert("RGBA")
    sp = sprite
    if height:
        scale = height / sp.height
        sp = sp.resize((max(1, int(sp.width * scale)), height), Image.LANCZOS)
    x = int(at[0] - sp.width / 2)
    y = int(at[1] - sp.height)  # `at` is the ground point the prop stands on
    bd.alpha_composite(sp, (x, y))
    bd.save(out_path)
    return out_path


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sprite", required=True, help="generated prop on a plain field")
    ap.add_argument("--backdrop", help="place the sprite on this image")
    ap.add_argument("--out", required=True)
    ap.add_argument("--at", default="700,772", help="ground point x,y on the backdrop")
    ap.add_argument("--height", type=int, default=210, help="sprite height in px")
    ap.add_argument("--tol", type=int, default=60, help="flood fill tolerance")
    ap.add_argument("--method", default="auto", choices=["auto", "rembg", "flood"])
    ap.add_argument("--raw", help="cut this file instead of --sprite (for compositing)")
    args = ap.parse_args()

    src = pathlib.Path(args.raw or args.sprite)
    if not src.is_absolute():
        src = ROOT / src

    cut = key_out(src, tol=args.tol, method=args.method)
    info = alpha_report(cut)
    print(
        f"cut {src.name} -> {info['size'][0]}x{info['size'][1]}, "
        f"transparent {info['transparent_pct']}%, corners {info['corners']}, "
        f"clean={'yes' if info['clean'] else 'NO'}"
    )

    out = pathlib.Path(args.out)
    if not out.is_absolute():
        out = ROOT / out

    if not args.backdrop:
        cut.save(out)
        print(f"saved {out}")
        return

    bd = pathlib.Path(args.backdrop)
    if not bd.is_absolute():
        bd = ROOT / bd
    at = tuple(int(v) for v in args.at.split(","))
    out.parent.mkdir(parents=True, exist_ok=True)
    compose(bd, cut, at, args.height, out)
    print(f"composited {src.name} onto {bd.name} at {at} -> {out}")


if __name__ == "__main__":
    sys.exit(main())
