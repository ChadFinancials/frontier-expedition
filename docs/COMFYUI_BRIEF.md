# ComfyUI brief: item and HUD icons

A handoff for the agent that runs on the owner's PC (where ComfyUI and the GPU are). The
cloud agent cannot reach ComfyUI, so the work is split:

| Who | Does |
|---|---|
| **PC agent (you)** | Prompts, generation, cutout, cleanup, contact sheets for the owner, and committing the chosen PNGs. Only touches `tools/art/` and `assets/art/icons/`. |
| **Cloud agent** | All Godot code: loading the icons, falling back to the drawn ones, sizes, layout. Also the wood-and-rope UI and the map, which are drawn in code. |

Read `docs/ART_PIPELINE.md` first (setup, `generate.py`, the style rules, what does not work).
Repo rules: `git pull --ff-only origin main` before starting and before pushing, never
force-push, do not touch `download/`, `scripts/` or `data/`.

## What the game expects (the contract)

- One PNG per icon at **`assets/art/icons/<key>.png`**, where `<key>` is the key in the tables
  below (it is the `icon` field in `data/items.json`, or the kind name in `scripts/ui/res_icon.gd`).
- **256 x 256, RGBA, transparent background.** The object centred, filling about 84 percent of
  the canvas (roughly 20 px of clear margin on each side). No drop shadow: the game adds its own.
- The game shows them small: **about 40 px** in wagon and inventory slots, **about 22 px** in
  the top bar. Anything that does not read at 40 px is not done.
- A missing file is fine: the game keeps drawing the current icon for that key. Commit icons
  one at a time as they get approved.
- Record each keeper in **`assets/art/icons/icons.json`**:
  `{"food": {"subject": "icon_food", "seed": 123456789, "source": "art-tests/icon_food/00012.png"}}`
  (seeds reproduce exactly, so this is how anything can be regenerated later).
- Commit the PNGs (and the `.png.import` files if Godot made them), plus `icons.json` and any
  changes under `tools/art/`. Do not commit rejected candidates.

## Style (same world as the characters)

The characters are now drawn in an **ink illustration** look: flat chunky colour, a bold dark
brown-black outline around every shape, a warm highlight on the top-left edge and a shadow tone
on the far side. Icons should sit next to them without looking like a different game.

- One single object, seen from a slight three-quarter angle, **light from the top left**.
- **Bold dark outline** (dark brown-black, not pure black), flat colour chunks with one
  shadow tone and one highlight. Crisp edges, no blur, no gradients, no texture noise.
- Warm, muted frontier palette, but each icon needs one clear identifying colour so the set
  is tellable apart at a glance (food: burlap tan, bandages: off-white, antivenom: green,
  whiskey: amber-brown, lamp oil: tin and orange, salt: white, iron: blue-grey, etc).
- Chunky, simple silhouette. Fewer, bigger parts. Think "board-game token", not "still life".
- Background for generation: **one flat uniform cream colour** (`#f3e9d2`), so the cutout is clean.

Add to `tools/art/prompts.py`:

```python
ICON_FRAME = (
    "a single game inventory icon, one object only, centred, three-quarter view, "
    "light from the top left, bold thick dark brown outline around every shape, flat "
    "colour chunks with one shadow tone and one highlight, chunky simple silhouette, "
    "crisp edges. the background is one single flat uniform cream colour, completely "
    "plain and even from edge to edge, no frame, no border, no shadow, nothing else"
)
NEGATIVE_ICON = NEGATIVE + (
    "multiple objects, several items, pile, still life, table, scene, landscape, hands, "
    "person, label text, writing, letters, numbers, brand, drop shadow, cast shadow, "
    "gradient background, vignette, frame, border, tiny detail, photoreal, "
)
```

Each subject below is `icon_<key>` with prompt `STYLE + ", " + <subject text> + ", " +
ICON_FRAME` and negative `NEGATIVE_ICON`. Generate square (1024 x 1024). If `generate.py`
only knows the 16:9 and character workflows, add a square one (copy
`sdxl_character.json`, set width and height to 1024) and a `--workflow` choice.

## Batch 1: wagon supplies (do these first)

| key | item | subject text |
|---|---|---|
| `food` | Food | a small burlap sack tied at the neck with twine, two square hardtack biscuits and a dented tin can of beans leaning against it |
| `bandage` | Bandages | a rolled bundle of off-white linen bandage, partly unrolled, with a small brass safety pin |
| `vial` | Antivenom | a small corked glass vial of bright green liquid with a twine loop around the neck |
| `bottle` | Whiskey | a round brown stoneware jug with a cork and a small finger handle, no label |
| `oil` | Lamp Oil | a small tin oil can with a long thin spout and a handle, a drop of orange oil at the spout tip |
| `rope` | Rope | a neat coil of thick tan hemp rope with one loose end |
| `shovel` | Shovel | a short camp shovel with a wooden handle and a worn iron blade, shown diagonally |
| `crowbar` | Crowbar | an iron crowbar with a curved claw end, shown diagonally, dark iron |
| `salt` | Salt | a small cloth pouch tipped over, spilling a little heap of white salt crystals |
| `wheel` | Wagon Parts | a wooden spoked wagon wheel with an iron rim and a loose iron pin beside it |
| `timber` | Timber | a small bundle of four sawn planks tied with rope, end grain showing |
| `iron` | Iron | a small stack of three dull blue-grey iron ingots with a bent scrap of iron |

Order: make `food` first and get the owner's pick. Then use it as the style reference for the
rest (IPAdapter if installed; otherwise keep the same STYLE and settings) so the set matches.

## Batch 2: top bar and resource icons

| key | shows | subject text |
|---|---|---|
| `money` | Chips (currency) | a single red and cream clay poker chip seen at a slight angle, thick edge stripes |
| `week` | Day and week counter | a torn-off paper calendar page with a red top band, blank, no numbers |
| `wagon` | Wagon health | a small covered wagon seen from the side, white canvas top, two wooden wheels |
| `xp` | Experience | a five-pointed brass star with a raised rim |
| `eye` | Scouting | a brass spyglass, partly extended, shown diagonally |
| `charter` | Land Charters (found and grow settlements) | a rolled paper deed tied with a red ribbon and a red wax seal |
| `skull` | Deaths | a small bleached cattle skull seen from the front |

## Not for ComfyUI (the cloud agent draws these in code)

- The wood-and-rope UI (planks, nails, rope dividers, signboard buttons).
- The expedition map (parchment, terrain sketches, trails, wagon token, fog, stop seals).
- The small combat stat icons (damage, crit, dodge, protection, speed, accuracy, heal, buff,
  debuff, melee, ranged). They are shown at about 14 px, where generated art turns to mush.

## Review loop with the owner

1. For each key, generate 6 to 8 candidates.
2. Cut out (`tools/art/cutout.py`, rembg), trim, centre on 256 x 256 with the margin above.
3. Make one contact sheet per batch showing each candidate at **256 px, 40 px and 22 px**, on
   both a dark wood brown (`#2a1f18`) and the parchment cream (`#f3e9d2`). The small sizes are
   what the owner is really judging.
4. The owner picks; commit only the picks, with seeds in `icons.json`.
5. Commit message: `Icons: <keys>` so the cloud agent knows what landed.

## Known traps (from ART_PIPELINE.md)

- Never ask for text or labels: lettering comes out garbled. Blank labels only.
- Do not prompt for paper grain or pencil hatching; it does not work and the game adds it.
- No tipis, totem poles, dreamcatchers or headdresses, ever.
- Small held props need weighting in the prompt, or the model drops them.
