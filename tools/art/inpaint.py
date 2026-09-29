"""Paint pose variants from an approved base figure by inpainting only the arms.

Why this exists: prompting alone cannot hold a character across poses. Seven prompts from one
seed produced three different characters (see docs/ART_PIPELINE.md). Inpainting keeps the head,
hat, coat and colours **pixel-identical** and repaints only the masked band, so identity is
preserved by construction.

    # one pose, look at it before doing the rest
    python tools/art/inpaint.py --base art-tests/pose-pick/preacher-idle.png \
        --poses strike --out art-tests/inpaint-01

    # the arm poses that stay standing
    python tools/art/inpaint.py --base art-tests/pose-pick/preacher-idle.png \
        --poses windup,strike,aim,cast,hurt --out art-tests/inpaint-01

Notes:
- The base is composited onto flat cream before it is encoded, because a cutout's transparent
  field gives the VAE nothing sensible to blend into.
- ComfyUI's LoadImage returns MASK = 1 - alpha, so the region to repaint is written as
  alpha 0 and everything else alpha 255. If the first test comes back repainting the wrong
  area, flip that and rerun.
- `dead` is not an arm pose: the whole body changes, so it cannot be inpainted. Generate it
  fresh, or drop it (nothing in the game sets `dead` today).
"""

import argparse
import json
import pathlib
import sys
import time

from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import cutout  # noqa: E402
import generate  # noqa: E402
import prompts  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parents[2]
BASE_NODE = "1"
MASK_NODE = "2"
SEED_NODE = "7"
POS_NODE = "5"
NEG_NODE = "6"

# Poses where the arms leave the torso band, so the mask has to reach up beside the head.
ARMS_UP = {"windup", "cast", "strike", "aim"}
# Poses that only change the arms and lean, so inpainting can produce them.
INPAINTABLE = ["idle", "windup", "strike", "aim", "cast", "hurt"]


def build_mask(size, pose):
    """Return an L mask: 0 where the region should be repainted, 255 to keep."""
    w, h = size
    m = Image.new("L", (w, h), 255)
    d = ImageDraw.Draw(m)
    # Torso and arms band. The head sits above 0.22h and the boots below 0.62h.
    d.rectangle([0, int(0.22 * h), w, int(0.62 * h)], fill=0)
    if pose in ARMS_UP:
        # Keep the head and hat safe in the middle, open the sides above the shoulders.
        d.rectangle([0, int(0.04 * h), int(0.32 * w), int(0.22 * h)], fill=0)
        d.rectangle([int(0.68 * w), int(0.04 * h), w, int(0.22 * h)], fill=0)
    return m.filter(ImageFilter.GaussianBlur(3))


def write_mask(path, size, pose):
    m = build_mask(size, pose)
    img = Image.new("RGBA", size, (0, 0, 0, 255))
    img.putalpha(m)
    img.save(path)
    return path


def flatten(base, path, field=(243, 233, 210)):
    """Composite a cutout onto flat cream so the VAE has real pixels outside the figure."""
    im = Image.open(base).convert("RGBA")
    bg = Image.new("RGBA", im.size, field + (255,))
    bg.alpha_composite(im)
    bg.convert("RGB").save(path)
    return path


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", required=True, help="approved figure, cutout or flat PNG")
    ap.add_argument("--poses", default=",".join(INPAINTABLE))
    ap.add_argument("--out", required=True)
    ap.add_argument("--host", default="http://127.0.0.1:8188")
    ap.add_argument("--workflow", default=str(ROOT / "tools/art/inpaint_pose.json"))
    ap.add_argument("--denoise", type=float, default=None)
    ap.add_argument("--seed", type=int, default=None)
    ap.add_argument("--key", action="store_true", help="also cut the result to alpha")
    args = ap.parse_args()

    base = pathlib.Path(args.base)
    if not base.is_absolute():
        base = ROOT / base
    out_dir = pathlib.Path(args.out)
    if not out_dir.is_absolute():
        out_dir = ROOT / out_dir
    out_dir.mkdir(parents=True, exist_ok=True)

    try:
        stats = generate.get_json(args.host, "/system_stats")
        print(f"ComfyUI {stats['system']['comfyui_version']} ready")
    except Exception as e:
        raise SystemExit(f"ComfyUI not reachable at {args.host}: {e}")

    flat = flatten(base, out_dir / f"base_{base.stem}.png")
    wf_base = generate.sanitize(json.loads(pathlib.Path(args.workflow).read_text(encoding="utf-8")))
    size = Image.open(flat).size

    for pose in [p.strip() for p in args.poses.split(",") if p.strip()]:
        if pose not in prompts.POSES:
            raise SystemExit(f"unknown pose '{pose}'. pick from {', '.join(prompts.POSES)}")
        if pose not in INPAINTABLE:
            print(f"  skipping {pose}: not inpainting, the whole body changes")
            continue
        positive, negative = prompts.build(f"preacher_{pose}")
        mask_path = write_mask(out_dir / f"mask_{pose}.png", size, pose)

        wf = json.loads(json.dumps(wf_base))
        wf[BASE_NODE]["inputs"]["image"] = generate.upload_image(args.host, flat)
        wf[MASK_NODE]["inputs"]["image"] = generate.upload_image(args.host, mask_path)
        wf[POS_NODE]["inputs"]["text"] = positive
        wf[NEG_NODE]["inputs"]["text"] = negative
        if args.denoise is not None:
            wf[SEED_NODE]["inputs"]["denoise"] = args.denoise
        seed = args.seed if args.seed is not None else 4242
        wf[SEED_NODE]["inputs"]["seed"] = seed

        started = time.time()
        saved = generate.run_one(args.host, wf, None, out_dir, 0)
        took = time.time() - started
        for dest, nbytes in saved:
            print(f"  {pose:<7} {took:.0f}s  {nbytes // 1024} KB  {dest.name}")
            if args.key:
                cut = cutout.key_out(dest, method="rembg")
                info = cutout.alpha_report(cut)
                cut.save(out_dir / f"cut_{pose}.png")
                print(f"          keyed: {info['size'][0]}x{info['size'][1]}, "
                      f"corners {info['corners']}, clean={'yes' if info['clean'] else 'NO'}")


if __name__ == "__main__":
    main()
