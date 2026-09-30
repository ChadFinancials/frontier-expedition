"""Prepare backdrop horizon data, then make Backdrop anchor on it.

Problem: the bottom UI panel is opaque and covers part of the screen. On the trail screen the
map panel starts at y=430, so an image scaled to cover the full 1080 puts its ground plane
around y=555, behind the panel. The visible strip shows only sky, and the wagon at y=404 has
no ground under it, so it reads as floating.

A single bottom anchor cannot fix it either: the measured horizon of the six trail variants
runs from 21% to 61% down the image. So the horizon is measured here, stored next to the art,
and the game positions each image so its horizon lands at a chosen screen y. Sky above,
ground below, consistently, whichever variant is showing.

Run from the repo root. Idempotent.
"""

import json
import pathlib
import re

from PIL import Image
import numpy as np

BG = pathlib.Path('assets/art/backdrops')
HORIZONS = BG / 'horizons.json'
NL = '\r\n'


def measure(path):
    """Row of the strongest horizontal edge in the middle of the frame = the horizon."""
    im = np.asarray(Image.open(path).convert('RGB'), dtype=np.int16)
    rows = np.abs(np.diff(im, axis=0)).mean(axis=(1, 2))
    lo, hi = int(0.20 * len(rows)), int(0.85 * len(rows))
    row = lo + int(np.argmax(rows[lo:hi]))
    return round(row / im.shape[0], 4)


def write_horizons():
    data = {}
    if HORIZONS.exists():
        data = json.loads(HORIZONS.read_text(encoding='utf-8'))
    # Only new images are measured: an entry already in the file may be hand-set (the
    # measure picks the strongest edge, which on flat-colour art can be a path, not the skyline).
    for p in sorted(BG.glob('*.png')):
        if p.name not in data:
            data[p.name] = measure(p)
    HORIZONS.write_text(json.dumps(data, indent=1, sort_keys=True) + '\n', encoding='utf-8')
    for k, v in sorted(data.items()):
        print(f'  {k:26s} horizon at {100 * v:.0f}% down')
    return data


def patch_backdrop():
    p = pathlib.Path('scripts/visual/backdrop.gd')
    s = p.read_bytes().decode('utf-8')

    if 'bg_horizon_y' not in s:
        anchor = 'var bg_bottom: float = -1.0'
        assert anchor in s, 'bg_bottom missing; run _edit_backdrop_anchor.py first'
        line_end = s.index(NL, s.index(anchor))
        add = NL.join([
            '',
            'var bg_horizon_y: float = -1.0  # screen y to place the image horizon at; -1 disables',
            'var _horizons: Dictionary = {}',
            'var _horizons_loaded := false',
        ])
        s = s[:line_end] + add + s[line_end:]

    if 'func _horizon_frac' not in s:
        anchor = 'func _apply_bg(index: int) -> void:'
        assert s.count(anchor) == 1
        helper = NL.join([
            '## Fraction down the image where its horizon sits, from assets/art/backdrops/',
            '## horizons.json. Written by tools/art/prep_backdrops.py, which measures the images.',
            'func _horizon_frac(path: String) -> float:',
            '\tif not _horizons_loaded:',
            '\t\t_horizons_loaded = true',
            '\t\tvar f := FileAccess.open("res://assets/art/backdrops/horizons.json", FileAccess.READ)',
            '\t\tif f != null:',
            '\t\t\tvar parsed: Variant = JSON.parse_string(f.get_as_text())',
            '\t\t\tif parsed is Dictionary:',
            '\t\t\t\t_horizons = parsed',
            '\treturn float(_horizons.get(path.get_file(), -1.0))',
            '',
            '',
        ])
        s = s.replace(anchor, helper + anchor, 1)

    old = NL.join([
        '\tvar bottom: float = bg_bottom if bg_bottom > 0.0 else H',
        '\tvar cover: float = maxf(W * 1.08 / float(tex.get_width()), bottom / float(tex.get_height()))',
        '\tbg.scale = Vector2(cover, cover)',
        '\t# Centred sprite: its centre must sit half an image height above the anchor.',
        '\tbg.position = Vector2(W * 0.5, bottom - float(tex.get_height()) * cover * 0.5)',
    ])
    new = NL.join([
        '\tvar h := float(tex.get_height())',
        '\tvar frac: float = _horizon_frac(_bg_paths[i])',
        '\tvar cover: float',
        '\tvar cy: float',
        '\tif bg_horizon_y > 0.0 and frac > 0.0:',
        '\t\t# Anchor on the horizon: sky above it, ground below, whatever the variant.',
        '\t\t# cover must also reach the top edge, so the frame is never left blank.',
        '\t\tcover = maxf(W * 1.08 / float(tex.get_width()), bg_horizon_y / (frac * h))',
        '\t\tcy = bg_horizon_y - h * cover * (frac - 0.5)',
        '\telse:',
        '\t\t# No horizon data: anchor the image bottom, which may run behind an opaque panel.',
        '\t\tvar bottom: float = bg_bottom if bg_bottom > 0.0 else H',
        '\t\tcover = maxf(W * 1.08 / float(tex.get_width()), bottom / h)',
        '\t\tcy = bottom - h * cover * 0.5',
        '\tbg.scale = Vector2(cover, cover)',
        '\tbg.position = Vector2(W * 0.5, cy)',
    ])
    if old in s:
        s = s.replace(old, new, 1)
    elif 'Anchor on the horizon' not in s:
        raise SystemExit('position block not found and not already applied')

    if 'func set_bg_horizon' not in s:
        anchor = '## Screen y for the image bottom edge.'
        assert s.count(anchor) == 1
        setter = NL.join([
            '## Screen y where the image horizon should sit. Sky above, ground below. This is the',
            '## knob that stops figures looking like they float over an opaque panel.',
            'func set_bg_horizon(y: float) -> void:',
            '\tbg_horizon_y = y',
            '\tvar keep: int = _bg_index',
            '\t_bg_index = -1',
            '\t_apply_bg(keep if keep >= 0 else 0)',
            '',
            '',
        ])
        s = s.replace(anchor, setter + anchor, 1)

    p.write_bytes(s.encode('utf-8'))
    print('backdrop.gd: horizon anchoring applied')


def patch_screen(path, horizon_y, note):
    p = pathlib.Path(path)
    s = p.read_bytes().decode('utf-8')
    if 'set_bg_horizon' in s:
        print(f'{path}: already set')
        return
    if path.endswith('trail_screen.gd'):
        anchor = '\tbackdrop.setup(run.region_id, "trail", 30 + run.day)'
    elif path.endswith('main_menu.gd'):
        anchor = '\tbackdrop.setup("tallgrass", "trail", 4)'
    else:
        anchor = '\t\tbackdrop.setup(run.region_id if run != null else "tallgrass", backdrop.mode, 77)'
    assert s.count(anchor) == 1, f'anchor not found in {path}'
    indent = anchor[:len(anchor) - len(anchor.lstrip())]
    add = NL.join([
        '',
        f'{indent}# {note}',
        f'{indent}backdrop.set_bg_horizon({horizon_y})',
    ])
    s = s.replace(anchor, anchor + add, 1)
    p.write_bytes(s.encode('utf-8'))
    print(f'{path}: horizon y = {horizon_y}')


write_horizons()
patch_backdrop()
patch_screen('scripts/screens/trail_screen.gd', 300.0,
             'Ground under the wagon: the map panel starts at y=430, so the horizon sits at 300.')
patch_screen('scripts/screens/main_menu.gd', 430.0,
             'Wagon at y=772, so put the horizon well above it. No opaque panel on this screen.')
patch_screen('scripts/screens/combat_screen.gd', 430.0,
             'Heroes stand at GROUND 770 and the HUD starts at 835, so keep the horizon high.')