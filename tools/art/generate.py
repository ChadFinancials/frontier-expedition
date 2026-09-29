"""Generate Frontier Expedition art through a running ComfyUI server.

Stdlib only. Submits the given API-format workflow N times with fresh seeds,
injects the prompt pair for the subject, and downloads every output PNG.

    python tools/art/generate.py --subject tallgrass --count 4
    python tools/art/generate.py --subject tallgrass --count 8 --steps 40
    python tools/art/generate.py --subject cave --seed 1234 --out art-tests/cave-pick

Requires ComfyUI running (comfy launch --background) on --host.
See docs/ART_PIPELINE.md. Edit the style in tools/art/prompts.py.
"""

import argparse
import json
import pathlib
import random
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import prompts  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parents[2]
POS_NODE = "6"
NEG_NODE = "7"
SEED_NODE = "3"


def sanitize(workflow: dict) -> dict:
    """Drop anything that is not a node.

    ComfyUI treats every top-level key as a node, so a `_comment` string makes
    validate_prompt die with 'str object has no attribute get'.
    """
    return {k: v for k, v in workflow.items() if isinstance(v, dict) and "class_type" in v}


def post_json(host, path, payload):
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        f"{host}{path}", data=data, headers={"Content-Type": "application/json"}
    )
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read().decode("utf-8"))


def get_json(host, path):
    with urllib.request.urlopen(f"{host}{path}", timeout=60) as r:
        return json.loads(r.read().decode("utf-8"))


def download(host, item, dest):
    query = urllib.parse.urlencode(
        {
            "filename": item["filename"],
            "subfolder": item.get("subfolder", ""),
            "type": item.get("type", "output"),
        }
    )
    with urllib.request.urlopen(f"{host}/view?{query}", timeout=300) as r:
        blob = r.read()
    dest.write_bytes(blob)
    return len(blob)


def upload_image(host, path):
    """POST a local PNG to /upload/image. Returns the server-side filename."""
    boundary = "----fxartboundary"
    head = (
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="image"; filename="{path.name}"\r\n'
        "Content-Type: image/png\r\n\r\n"
    ).encode("utf-8")
    tail = (
        f"\r\n--{boundary}\r\n"
        'Content-Disposition: form-data; name="overwrite"\r\n\r\ntrue\r\n'
        f"--{boundary}--\r\n"
    ).encode("utf-8")
    body = head + path.read_bytes() + tail
    req = urllib.request.Request(
        f"{host}/upload/image",
        data=body,
        headers={"Content-Type": f"multipart/form-data; boundary={boundary}"},
    )
    with urllib.request.urlopen(req, timeout=180) as r:
        return json.loads(r.read().decode("utf-8"))["name"]


def upscale(host, src, out_dir, workflow_path):
    """Run one image through the upscale workflow. Returns the saved path."""
    wf = sanitize(json.loads(workflow_path.read_text(encoding="utf-8")))
    wf["1"]["inputs"]["image"] = upload_image(host, src)
    out_dir.mkdir(parents=True, exist_ok=True)
    saved = run_one(host, wf, None, out_dir, 0)
    return saved[0][0] if saved else None


def run_one(host, workflow, image, out_dir, index):
    prompt_id = post_json(
        host, "/prompt", {"prompt": workflow, "client_id": "frontier-art"}
    )["prompt_id"]
    deadline = time.time() + 900
    while time.time() < deadline:
        history = get_json(host, f"/history/{prompt_id}")
        if prompt_id in history:
            entry = history[prompt_id]
            status = entry.get("status", {})
            if status.get("status_str") == "error":
                raise SystemExit(
                    "ComfyUI reported an error:\n"
                    + json.dumps(status.get("messages", []), indent=1)
                )
            saved = []
            for node_out in entry.get("outputs", {}).values():
                for item in node_out.get("images", []):
                    dest = out_dir / f"{out_dir.name}_{index:02d}_{item['filename']}"
                    size = download(host, item, dest)
                    saved.append((dest, size))
            if saved:
                return saved
        time.sleep(2)
    raise SystemExit(f"timed out waiting for prompt {prompt_id}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--subject", required=True, help="a key in tools/art/prompts.py")
    ap.add_argument("--count", type=int, default=4)
    ap.add_argument(
        "--workflow", default=str(ROOT / "tools/art/sdxl_backdrop_16x9.json")
    )
    ap.add_argument("--out", default=None, help="output dir (default art-tests/<subject>)")
    ap.add_argument("--host", default="http://127.0.0.1:8188")
    ap.add_argument("--steps", type=int, default=None)
    ap.add_argument("--seed", type=int, default=None, help="fixed seed for one image")
    ap.add_argument(
        "--seeds",
        default=None,
        help="comma-separated seeds, one image each (use to re-run known winners)",
    )
    ap.add_argument(
        "--upscale",
        action="store_true",
        help="also run each image through upscale_to_1080.json into <out>/final",
    )
    ap.add_argument("--show", action="store_true", help="print the prompts and exit")
    args = ap.parse_args()

    positive, negative = prompts.build(args.subject)
    if args.show:
        print("POSITIVE:\n" + positive + "\n\nNEGATIVE:\n" + negative)
        return

    base = sanitize(json.loads(pathlib.Path(args.workflow).read_text(encoding="utf-8")))
    out_dir = pathlib.Path(args.out) if args.out else ROOT / "art-tests" / args.subject
    out_dir.mkdir(parents=True, exist_ok=True)

    # Fail early if the server is not up.
    try:
        stats = get_json(args.host, "/system_stats")
        print(f"ComfyUI {stats['system']['comfyui_version']} on {stats['system']['os']}")
    except urllib.error.URLError as e:
        raise SystemExit(f"ComfyUI not reachable at {args.host}: {e}. Run: comfy launch --background")

    rng = random.Random()
    made = []
    rows = [("file", "seed", "subject", "steps")]
    fixed = [int(s) for s in args.seeds.split(",")] if args.seeds else []
    total = len(fixed) if fixed else args.count
    for i in range(total):
        wf = json.loads(json.dumps(base))
        wf[POS_NODE]["inputs"]["text"] = positive
        wf[NEG_NODE]["inputs"]["text"] = negative
        if args.steps:
            wf[SEED_NODE]["inputs"]["steps"] = args.steps
        if fixed:
            seed = fixed[i]
        else:
            seed = args.seed if args.seed is not None else rng.randint(1, 2**31 - 1)
        wf[SEED_NODE]["inputs"]["seed"] = seed
        started = time.time()
        saved = run_one(args.host, wf, None, out_dir, i)
        took = time.time() - started
        for dest, size in saved:
            print(f"  [{i + 1}/{total}] seed {seed}  {took:.0f}s  {size // 1024} KB  {dest}")
            made.append(dest)
            rows.append((dest.name, seed, args.subject, wf[SEED_NODE]["inputs"]["steps"]))
            if args.upscale:
                final = upscale(
                    args.host, dest, out_dir / "final", ROOT / "tools/art/upscale_to_1080.json"
                )
                if final:
                    print(f"        -> {final.name} (1920x1080)")
    # Seed manifest, so any kept image can be regenerated byte for byte later.
    # Merge with any existing manifest: the same --out is often reused for several runs.
    import csv

    manifest = out_dir / "manifest.csv"
    known = {}
    if manifest.exists():
        with open(manifest, encoding="utf-8", newline="") as fh:
            for row in list(csv.reader(fh))[1:]:
                if len(row) == 4:
                    known[row[0]] = row
    for row in rows[1:]:
        known[row[0]] = row
    with open(manifest, "w", encoding="utf-8", newline="") as fh:
        writer = csv.writer(fh)
        writer.writerow(rows[0])
        writer.writerows(known.values())
    print(f"\n{len(made)} image(s) in {out_dir}")
    print(f"seeds written to {manifest.name} ({len(known)} total)")


if __name__ == "__main__":
    main()
