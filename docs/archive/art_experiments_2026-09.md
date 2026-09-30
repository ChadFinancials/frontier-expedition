# Art experiments log (September 2026)

> **Archived.** The working log of the September 2026 art exploration (ComfyUI and SDXL runs on
> the owner's PC, the paper-theater pilot, drawn-character passes). Kept for its lessons. It is
> not maintained, and file paths, defaults and plans in it may be out of date. The current state
> is in `docs/ART_PIPELINE.md`.


How art gets made for Frontier Expedition. Agreed with the owner September 29, 2026.

## The core decision

**Art is stock, not generated.** Images are made offline with ComfyUI at the desk, reviewed
by the owner, and committed to `assets/art/` like the sound files. The game loads them as
textures. **Nothing generates at runtime.** No player needs a GPU, the build stays small,
the look is locked, and every asset is revertible through git.

## Style direction

The target is the approved **paper-theater** look already in the game: papier-mache relief,
paper grain and fiber, sculpted shading, pencil hatchmark. Storybook, handmade, matte.

- **Characters get no patchwork.** The owner rejected the torn-scrap collage treatment on
  figures. Keep them clean, sculpted and hatched, matching `PaperFX` and `Figure.crafted`.
- **Backgrounds may keep a trace of collage**, roughly 20 percent. Torn edges and
  mismatched scraps read as landscape texture there without looking cheap.
- Prompt words alone do not remove the generic AI feel. The real levers are an **IPAdapter
  style reference** built from our own approved art, then a **LoRA** trained on it once we
  have 30 or so images we like.

Palette reference lives in `data/regions.json`. Paper cream is `#f3e9d2` (`Figure.PAPER`).

## Order of work

1. **Backgrounds first.** Trail and cave backdrops. They carry the biggest visual load, they
   need no rigging, and the finished set becomes the style reference for everything after.
2. **The town.** See below. Same set doubles as the reference for building art.
3. **UI pass.** Icons, arrows, overlays, logos, frames. Replaces the drawn boxes.
4. **Characters last.** They need pose rigging and per-class variants, and they should be
   generated against a style that is already settled.

## The town: plates, not pictures

Do **not** generate the town as one composed image. The town is interactive: a ruin becomes a
building, a new build appears in an empty plot, and every plot changes with its level. One
generated scene cannot do that, and two generated scenes never line up.

Instead:

- One **ground plate**: the empty street, dirt, palisade, sky, shadows. Generated once.
- One **sheet per building type per level**, as a separate cutout with an alpha channel.
- Code places each sheet at the plot position it already knows from `building_panel.gd`.
  `TownView` keeps drawing the paper street and the props; only the building shapes change.

Swapping a ruin sheet for a built sheet is then a texture swap. Everything else is identical
by construction, so consistency is not something the model has to solve.

Signage stays in code. Generated lettering comes out garbled and mirrored, and the game
already draws signs it can highlight per state. Prompt for **blank signboards**.

## Integration rule: always keep the fallback

Each art consumer gains a texture path, and falls back to the current code drawing when the
file is missing:

| Node | Reads | Falls back to |
|---|---|---|
| `Backdrop` | `assets/art/backdrops/<region>_<mode>.png` | `_build_layers` / `_ridge` |
| `TownView` | ground plate plus `assets/art/town/<building>_<level>.png` | layered street and drawn blocks |
| `Figure` | `assets/art/figures/<look_id>_<variant>.png` | polygon puppet |

The game must run correctly with **any fraction** of the art done. This lets us drop in one
background and look at it in the real game before committing to a full set.

## Technical notes

- Machine: RTX 4070 Ti Super, 16 GB VRAM, 32 GB RAM. ComfyUI runs locally.
- Installed at `C:/Users/btd08/Documents/comfy/ComfyUI`. Launch with `comfy launch --background`, UI at http://127.0.0.1:8188. Torch 2.14.0+cu130.
- Generation: `python tools/art/generate.py --subject <key> --count N`. Add `--upscale` to
  also emit a 1920x1080 version into `<out>/final`. About 10 seconds per image at 1344x768.
- **Seeds reproduce exactly.** The same seed returns a byte-identical file, so any approved
  image can be regenerated later. Record the seed next to anything we keep.
- The upscale step is `upscale_to_1080.json`: RealESRGAN 4x then a lanczos fit to exactly
  1920x1080. Model at `models/upscale_models/RealESRGAN_x4plus.pth`.
- Prompts live in `tools/art/prompts.py`. One `STYLE` block is shared by every subject, so a
  style change reaches the whole set at once.
- Workflow JSON gotcha: ComfyUI treats **every top-level key as a node**, so a `_comment`
  string at the top level makes validation die with `str object has no attribute get`.
  `generate.py` strips non-node keys.
- Nodes that matter next: IPAdapter (style reference), ControlNet (pose and composition),
  `rembg` (alpha channel for cutouts).
- Figures need per-class **variants**, because `Figure` picks skin, hair and coat hue from
  `look_seed` and two Gunslingers should not look identical. Plan on 3 to 4 per class.
- A generated image is a starting point, not the deliverable. Cut it out, place it on a
  consistent canvas with the feet on a known baseline, and export the size the game wants.

## Style findings (Sept 29, first ranking round)

The owner ranked 20 title-screen candidates. **Winners: A2, A9, B2, B7. Losers: B8, B9, A4, A6**,
all rejected for looking "too realistic and detailed".

| | Winners | Losers |
|---|---|---|
| Shapes | flat solid color blocks, hard simple edges | painterly, soft, volumetric |
| Sky | flat field, uniform star dots, perfectly flat moon | smooth gradient with atmospheric depth |
| Light | none, or one simple source | rim light, glowing edges, specular highlights |
| Ground | broad flat washes, no fine detail | directional brush strokes suggesting grass |
| Forms | silhouettes with no interior detail | muscle definition, fabric folds, real anatomy |
| Feel | poster or screen print | concept art, illustrative realism |

**Cause, including our own fault:** the old `STYLE` block asked for `warm rim light`, `soft
diffused glow`, `visible sculpted paper relief` and `airy atmospheric haze`. Those phrases
push straight toward the 3D-render look the owner rejected. Fixed, and the same seeds now
come back flat and graphic. The banned terms are recorded in the comment above `NEGATIVE`
in `tools/art/prompts.py`.

**Keepers (seed reproduces the file byte for byte):**

| Label | Subject | Seed |
|---|---|---|
| A2 | loading_night | 536040906 |
| A9 | loading_dusk | 1497937011 |
| B2 | loading_night | 1173449234 |
| B7 | loading_dusk | 1662819211 |

Method that works: hold the seed constant and change only the prompt. That isolates style
from composition, which is how the fix above was proven rather than guessed.
`generate.py --seeds 536040906,1173449234` re-runs known winners.

## Hard rules learned (Sept 29)

**1. A negative prompt alone does not remove anything from SDXL.** Horses kept appearing on
the title backdrops after an explicit, unweighted `no horses`. What works:

- State the exclusion in the **positive** prompt too. `EXCLUDE` in `prompts.py` appends
  `an empty untouched wilderness landscape, no horses, no riders, no people, no animals, no
  buildings`, and that is what actually cleaned the backdrops. Verified: the same seed with
  the positive exclusion came back with no horses, riders or buildings.
- Weight the negative as well: `(horse:1.7), (rider:1.6), (cowboy:1.4)`.
- Do not rely on the model to omit an object because the subject text says "no X".

**2. The wagon cannot be composed into a wide landscape.** Asking for a wagon in a title
backdrop produced grazing horses and, once, a **sailboat**. Asking for a wagon at a distance
produced nothing. What works: generate the prop **alone on a plain field** and composite it
in code, the same pattern as the town buildings.

```bash
python tools/art/generate.py --subject wagon_sprite --count 4 --out art-tests/wagon
python tools/art/cutout.py --sprite art-tests/wagon/wagon_02_*.png \
    --backdrop art-tests/r4-test/r4-test_00_*.png \
    --out art-tests/mockups/title_night_wagon.png --at 700,772 --height 230
```

`cutout.py` keys the field to alpha with a **border flood fill, not a colour threshold**.
Generated fields are a soft vignette plus paper grain, so a global threshold leaves a brown
wash behind (it only removed 10 percent of the field). The flood fill follows the gradient
and stops at the prop outline (it removed 57 percent). Output then reads as cleanly cut.

Owner note on this round: "tone down the horses, there are not a lot of horse references in
game, maybe we can replace with wagon or caravan". Confirmed in the content: `wagon` appears
19 times in `events.json`, and `WagonArt` is drawn on the menu, the trail and at camp.
`horse` appears once, as a curio art key.

**3. A flood fill is not a clean cut.** The owner rejected the first composite: it "takes
stuff from the background and isn't a clean transparent png to overlay on stuff". A colour
threshold and a border flood fill both leave field residue, because generated fields are a
soft vignette plus grain. Use **rembg** (segmentation) for anything that will be overlaid.

```bash
# rembg lives in its own venv; the plain python falls back to the flood fill
uv venv "C:/Users/btd08/.venvs/art" --python 3.11
uv pip install --python "C:/Users/btd08/.venvs/art/Scripts/python.exe" "rembg[cpu]" pillow
"C:/Users/btd08/.venvs/art/Scripts/python.exe" tools/art/cutout.py \
    --sprite art-tests/wagon/wagon_02.png --out art-tests/wagon/wagon_clean.png --method rembg
```

`cutout.py` prints the alpha of the four corners. `corners [0, 0, 0, 0] clean=yes` is the
check that the field is genuinely transparent. Verified after switching: 37.8 percent
transparent, all four corners zero, and the owner-visible box was gone.

Env gotcha: `uv venv "$HOME/..."` under MSYS put the venv at `C:\c\Users\...`. Pass a native
`C:/...` path to `uv venv` on this machine.

## Ranking round 3 and the palette turn (Sept 29)

Owner ranked the wagon-paired set. **Best: E10, then E6, E5. Worst: E7, E3, E9.**

The signal: **all three best carry the wagon.** For seed `314159265` the wagon version (E6)
won while the plain version of the same seed (E3) came last. So the wagon belongs in the
title composition. The owner also said he could "use E10 for the opening screen".

Palette note from the same message: "the colors are getting a bit weird, lets try to use some
more greens and blues instead of the dusty purple sunsetty reds we were currently doing a
lot of". Applied: every title subject is now green and blue forward, the dusk ones keep gold
only as a low horizon accent, and `NEGATIVE` bans dusty purple, mauve, sunset red, salmon and
rose. Verified on a regenerated backdrop: "overwhelmingly green and blue, no dusty purple,
sunset red, salmon or rose, no horses or people".

First attempt overshot and produced a **mint green sky**. The fix, now in `STYLE` and in
`loading_green`: state that the sky is blue and never green, and that green belongs to the
ground and the grass.

## Final style direction (Sept 29, owner's last word)

- **Flat storybook artbook chunks.** Bold flat chunks of colour, hard crisp edges, a dark
  outline per shape. Pull back from loose or figurative brushwork.
- **Crisp, not blurry.** Verified: "the edges are crisp, no blurring or soft focus anywhere".
- **Colour: natural and believable, and no single colour dominating.** The owner overruled the
  hue bans: "there can certainly be those colours just not one colour dominate". Blues and
  dark blues in the sky, yellows and oranges in a sunset, greens, browns and sandy earth in
  the ground, and bright colour where it makes sense. The purple, mauve, rose, salmon and
  pink bans were **removed** from `STYLE` and `NEGATIVE`.
- **No tipis, ever.** Also banned: totem poles, dreamcatchers, feather headdresses and war
  bonnets. An unbidden tipi appeared once from the word "frontier". The design brief already
  says Native peoples are never cast as enemies; the art must not imply it either.

## Two things NOT to prompt for (they do not work)

**1. Paper grain and pencil hatching.** Three attempts failed. SDXL returns "clean and
digital ... no visible paper grain, pencil hatching or crosshatching". **The game already owns
this effect**: `scripts/visual/paper.gdshader` supplies grain, fibres, papier-mache relief,
cut-paper shadow, blur and haze, and `PaperFX` wraps drawn nodes in it. Apply and tune the
shader over the backdrop image instead of asking the model. It is more controllable and free.

| uniform | value |
|---|---|
| `grain_strength` / `grain_scale` | 0.14 / 300.0 |
| `fiber_strength` | 0.07 |
| `bevel_radius` / `bevel_strength` | 3.0 / 0.9 |
| `shadow_offset` / `shadow_alpha` | (9, 11) / 0.35 |

**2. A wagon painted into a wide landscape.** It reads as "a tunnel entrance, a culvert, or a
stylized dark tent". Use the isolated `wagon_sprite` plus `cutout.py` and place it in code.

## Titles the owner actually liked

| File | Subject | Seed |
|---|---|---|
| r6-fix `00081` | loading_night_wagon | 314159265 |
| r6-fix `00082` | loading_night_wagon | 1290515059 |

Earlier winners, for reference: A2 `536040906`, A9 `1497937011`, B2 `1173449234`,
B7 `1662819211`, and the round-three set E10 / E6 / E5, all with the wagon.

## Character models (Sept 29)

Characters are standalone assets for the battle and travel screens: one clean figure, no
environment, no props, transparent-ready for `cutout.py`. They are NOT scenes. Four things
had to be fixed in sequence, and all four are now in `prompts.py`:

| Problem | Cause | Fix |
|---|---|---|
| Came back as landscape scenes | Generated on the **landscape** canvas (1344x768) | Use `tools/art/sdxl_character.json`, portrait **768x1344** |
| Came back monochrome or sepia | "pencil hatching" pulls toward ink drawing | `monochrome, sepia, ink wash, duotone` in `NEGATIVE_CHAR` |
| Scene bled in behind the figure | A bare "isolated on a plain field" is ignored | Landscape words in `NEGATIVE_CHAR` |
| Came back as annotated design sheets with headshots, boot studies and gibberish text | Writing "character design sheet" or "character reference sheet" makes the model draw a literal sheet | Say **"one single character ... nothing else in the image"**, and ban `character sheet, design sheet, turnaround, multiple views, headshot, annotations, text` |

```bash
python tools/art/generate.py --subject marshal \
    --workflow tools/art/sdxl_character.json --count 6 --out art-tests/marshal-03
```

`CHARACTERS` in `prompts.py` marks the subjects that use `CHARACTER_FRAME` and
`NEGATIVE_CHAR`. Keep the landscape bans OUT of the backdrop subjects, where landscape words
are exactly what is wanted.

Owner direction for characters: "lean a slight bit more cartoonish vs realistic and really
drive that storybook/artbook crafted textured hatching style".

### More character fixes (second pass)

| Problem | Fix |
|---|---|
| Victorian gentlemen in **top hats** instead of frontier preachers | Say what the hat IS (**"wide flat brimmed low crowned plain black hat, not a top hat"**) and ban `top hat, victorian, formal suit, tailcoat, cravat`. Note the game's own `preacher` hat is a flat brim with a low crown, so describe that shape, not a style word |
| Figure came back in an interior room or doorway, which then survived the key | Ban `interior, room, doorway, indoor, walls, floor, stage, backdrop` |
| Decorative border frame and a cast shadow under the feet, both of which come through the alpha | Demand **"one single flat uniform cream colour, completely plain and even from edge to edge, no frame, no border, no shadow under the feet"**, and ban `frame, border, vignette, drop shadow, cast shadow` |

### QA: the magenta contact sheet

"Do we have a perfect cutout" is testable, so test it. Composite every cutout over bright
magenta and look for a pale patch or band. Any leftover field is obvious against magenta and
invisible against a cream backdrop.

```bash
# corners must all read 0; cutout.py prints this
~/.venvs/art/Scripts/python.exe tools/art/cutout.py --sprite X.png --out cut_X.png --method rembg
```

Verified on the preacher runs: 5 of 6 clean on the first pass (one kept a full doorway
scene), and 5 of 6 on the second (P4 kept pale background in the top corners). So **key every
batch and check the corners before offering images for a ranking**, not after.

### Small held props need weighting

SDXL drops small hand-held objects. Asking for "a Bible and a cross" gave 0 of 6 crosses and 1
of 6 Bibles. Fix that worked:

- **Lead the prompt with the props**, before the clothing. Early tokens carry more weight.
- **Weight them**: `a plain wooden (cross:1.4)`, `a thick black (Bible:1.3)`.
- Repeat the key one: "the cross clearly visible".

That took cross imagery from 0 of 6 to **5 of 6**. The Bible still landed only once, so for a
guaranteed prop the reliable route is a separate small sprite (like `wagon_sprite`) attached
in code, or drawn in code: `Figure` already has a `bible` weapon shape.

Also note: `top hat, victorian` in `NEGATIVE_CHAR` did NOT fully hold. Top hats returned on
2 of 6 even after the ban plus an explicit "not a top hat". Expect to re-roll a couple per
batch for that, and be ready to inpaint the hat rather than re-rolling the whole figure.

## Poses: how it works now, and what is needed

`Figure.pose` (figure.gd line 19) declares **idle, aim, windup, strike, cast, hurt, dead**.
`combat_screen.gd` sets hurt, windup, strike, aim, cast, idle, and once `attack` (line 1073).

| Pose | Set by | What the code does |
|---|---|---|
| `idle` | combat_screen 899, 902 | default arms, no lean, breathing animation |
| `windup` | combat_screen 870 | front hand up and back (-6,-34), weapon cocked |
| `strike` | combat_screen 872, 879 | front hand forward and low (38,18), lean 0.14, lunge 14px |
| `aim` | combat_screen 874 | front hand out level (40,4), lean 0.14, lunge 14px |
| `cast` | combat_screen 878 | front hand high (16,-46), lean -0.05 |
| `hurt` | combat_screen 677 | front hand low (10,30), lean -0.16, lunge -8px |
| `attack` | combat_screen 1073 | **BROKEN**: not in the pose list and has no hand positions, so it silently renders as idle |
| `dead` | nothing | **UNUSED**: declared, never set by any caller |

Two code decisions to make: give `attack` its own art or fold it into `strike`, and either use
`dead` or delete it.

### Prompting alone cannot hold a character across poses

Tried: same seed (`84492238`), a byte-identical identity block, only the pose clause changing,
7 poses. **It failed.** The set came back as three different characters (cream robe / white
robe with black scarf / brown coat with grey cap), one pose grew a wizard hat, and only 2 of 7
were full body (the rest cropped at the shins or waist). SDXL has no memory, and a seed does
not carry identity across different prompts. Do not retry this route.

Routes that can actually hold identity, best first:

1. **Inpaint the approved base.** Take the accepted P1 cutout and repaint only the arms and
   torso lean, leaving head, hat, coat and colours pixel-identical. The game's pose
   differences are mostly arms plus a lean, so this fits perfectly and is the cheapest win.
2. **ControlNet (OpenPose) plus the base as reference**, to drive a specific skeleton.
3. **IPAdapter** with the approved cutout as a face and style reference, so identity carries.
4. **Draw the extra poses in code.** `Figure` already animates arms by pose, one base sprite
   plus programmatic arms is perfectly consistent, and it costs nothing per asset.

Every pose must be full body with the feet on the same baseline, or the sprites cannot share
a ground line in combat.

## Painted backdrops in the game (Sept 29)

`Backdrop` looks for `assets/art/backdrops/` files and falls back to the code-drawn scenery
when none is found, so the game runs correctly with any fraction of the art done.

Key resolution order:

1. `Backdrop.bg_key` when set explicitly. The menu sets `"title"`.
2. The region's **`backdrop` field** in `data/regions.json`. This is how one region reuses
   another's art: `old_mill_road` (the tutorial) carries `"backdrop": "tallgrass_trail"`, so
   the tutorial and region-1 expeditions share the same set.
3. `"<region>_<mode>"`, where mode is `trail`, `cave`, `town` or `camp`.

Variants: `<key>.png` is a single backdrop. `<key>_1.png` through `<key>_24.png` are a
**cycling set**. `Backdrop.set_progress(0..1)` picks among them, and `trail_screen.gd` feeds
progress from the map column, so the scenery changes as the company pushes west. The index is
`round(progress * (variants - 1))`, so 0 maps to the first and 1 to the last.

Installed so far:

| File | Serves |
|---|---|
| `title.png` | the title and load screen (owner pick B7, seed 1662819211) |
| `tallgrass_trail_1.png` .. `_6.png` | Tallgrass expeditions and the tutorial |

Verified in game: the menu shows the painted title backdrop with the title legible, and the
trail shows a painted backdrop with the drawn wagon, oxen and heroes on top and no clash.

**Not yet verified:** the backdrop actually swapping mid-expedition. The index maths is
checked, the in-game transition is not. Confirm it by travelling a full map.

Note on repo size: those 7 PNGs are about 18 MB. Decide whether they belong in git, or are
downscaled, or generated on demand, before committing.

## Backdrop anchoring: why figures looked like they floated (Sept 29)

Owner report: "the UI at the bottom blocks the bottom of the background, it looks like the
characters are floating in air".

Cause: an image scaled to cover the full 1080 puts its ground plane low in the frame. On the
trail screen the map panel starts at **y=430**, so the ground (around y=555 downward) was
entirely **behind the panel**. The visible strip showed only sky and distant hills, and the
wagon at y=404 had no ground beneath it.

A single bottom anchor cannot fix it: the measured horizon of the six trail variants runs from
**21% to 61%** down the image. So the horizon is measured and stored.

- `tools/art/prep_backdrops.py` measures each image's horizon, the row with the strongest
  horizontal edge in the middle of the frame, and writes `assets/art/backdrops/horizons.json`.
- `Backdrop.set_bg_horizon(y)` positions the image so its horizon lands at screen y, with sky
  above and ground below, for whichever variant is showing. `cover` is chosen to also reach
  the top edge, so the frame is never blank.
- Values in use: **trail 300** (panel at 430, wagon at 404), **menu 430** (wagon at 772),
  **combat 430** (heroes at GROUND 770, HUD at 835).
- Rerun `prep_backdrops.py` after adding backdrop images, so the new ones get horizon data.

If the horizon is unknown, `Backdrop` falls back to `bg_bottom` (image bottom edge), which may
run behind an opaque panel.

## Drawn characters: the art pass and the faces (Sept 29)

Owner ask: improve the code-drawn characters, more detail, keep the flat patchwork polygons
with light texture, hatching and shading. And: "there is a fairly large white border around the
characters that makes it look a little odd".

### The border

`figure.gd` draws the paper edge as a polyline of **width 8px** centred on every shape outline,
so about **4px of cream shows outside** each piece. On a small figure that reads as a halo.
`Figure.style` now controls the pass. **Style 3 is approved and is the default.**

| Style | Edge | Hatch step | Sculpt depth | Extra |
|---|---|---|---|---|
| 0 | 4.0 | 6.0 | 0.16 | the original look, kept for A/B |
| 1 | 1.6 | 5.0 | 0.13 | none |
| 2 | 1.4 | 4.0 | 0.16 | inset contour |
| **3** | **1.8** | **3.4** | **0.21** | inset contour plus cross-hatch |

This is a **render pass only**. No geometry, no `look` data, no new shapes in `_build()`. The
inset contour is a copy of each shape's own outline pulled 14% toward its centre, so it adds
detail on every class, enemy and animal automatically. Style 0 reproduces the old numbers, so a
before/after is still possible with `shot=figure_ab`.

### Faces

`Figure.face_style = 2` is approved and is the default. `face_shift` (default 4.0) controls how
far forward of the head the face sits; 9 read as poking off the front.

Two failed attempts are worth recording:

1. A 3px forward offset plus a hand-drawn shadow still read as paint on the skin. The fix was
   to **stop hand-rolling it and use the engine's own three-pass pipeline**: any shape drawn
   **without** the `no_edge` flag automatically gets the cast shadow and the cream paper edge.
   Then the only remaining job is pushing the face far enough forward to break the head
   silhouette.
2. Mask plates over the face were rejected outright: "1 and 3 are awful and have like a white
   blob taking up the space". Do not put a plate over the face.

Eyes are a **wide black oval with no white**, `eye_style = 3`. History: a black disc with a
white speck read as a hole, so it became a white oval with a black pupil, and the owner then
chose to drop the white entirely. The alternatives are still in `_face` for later:
0 white oval with a pupil, 1 plain dot, 2 tall oval, 4 dot with a lid line, 5 an L bracket.
**Style 5 reads as a closed or winking eye**, so it suits a squint state such as `hurt` better
than a base eye, and it is not wired up yet.

Sizes are deliberately small, about 3.4px at scale 1. Note that the vision check judged the
white oval as reading more clearly as an eye than any black-only shape, so the black-only
choice is a style decision rather than a legibility win.

`_face_expr()` changes brows, eye openness and mouth shape per pose, so one face carries every
pose:

| Pose | Brows | Eyes | Mouth |
|---|---|---|---|
| idle | slightly raised | open | small smile |
| windup | raised, inner ends up | wider | small open |
| strike | down, angled in | narrowed | shouting |
| aim | flat, slight tilt | slightly squinted | flat |
| cast | raised | nearly closed | small open |
| hurt | down, inner ends up | squinted | frown |
| dead | flat | closed lines | flat |

Scenarios: `shot=figure_ab` (the style A/B), `shot=face_shift` (forward offset A/B),
`shot=face_pose` (expressions across poses). All need `paper=1` for the crafted look on the
lineup.

**Verification note:** a vision check on a small render reported the eyes as black discs when
they were in fact white ovals. Judge at 8x zoom, not at game scale, and prefer measuring pixels
over trusting a small-image description.

## Look variety: why characters look alike (open)

The `look` data is fine. The **drawing collapses most keys into a shared shape with a number
changed**, which is why Marshal, Gunslinger and Wrangler share a hat and recruits look like
siblings:

| Field | Keys | Reality |
|---|---|---|
| `hat` | cowboy, stetson, stetson_black, cowboy_wide | **one branch** at figure.gd line 700, differing only in brim width 32/34/40 and crown height 20/26 |
| `coat` | duster, long, frock | one branch, only the tail constant differs (-34/-44/-54) |
| `coat` | vest, overalls | one branch |
| `build` | slim, normal, broad, heavy, tiny | width 38/44/52/56, and only `heavy` gets extra treatment |

Plan, in order: split the hat branch into four real silhouettes, then the coat branch, then add
per-hero variance from `look_seed` so two heroes of one class differ.

## Open questions

- How much of the parallax survives if a backdrop becomes a flat image. `Backdrop` scrolls
  three layers today. Options: keep drawn layers over a generated sky, or slice a generated
  sky plate into layers.
- Do we train a LoRA on the approved set, or hold at IPAdapter references.
- Reference captures: we need screenshots of the current approved look as IPAdapter input.
  Take them from the shipped build, or install Godot 4.7.2 and use `tools/shot.sh`.

## Ink illustration look (Sept 30, owner's pick)

Owner ask: the drawn characters looked like "8 boxes clobbered together". Five body styles
were tried against the old look on the Marshal (`shot=body_ab`, `grid` for close-ups):
tailored curves, costume detail, paper puppet, ink illustration, painted volume. The owner
picked **ink illustration (`Figure.body_style = 4`)**, now the default for every figure, with
"a touch more highlights and shadowing", applied to every part.

- **Geometry** (`_body_v`, humans): spline torso with sloped shoulders, chest and waist; tapered
  limbs with elbows and knees; heeled boots; a flaring coat with an open front. Every piece,
  hats and animals included, gets its corners rounded (`_round_corners`, Chaikin: once on
  people, twice on animals and creatures). Face features (`no_edge`) stay crisp.
- **Render** (`_draw_layered`, piece by piece): a small cast shadow onto the pieces behind, a
  bold ink outline (so the lines between overlapping parts show), a flat fill, then cel bands
  from `_add_ink_bands`: a shadow tone on the far side, a darker core line at the far edge, a
  warm highlight along the lit (top-left) edge, and sparse ink hatching in bigger shadows.
- Styles 0-3 and 5 stay in the code for A/B. `body=N` on any shot scenario renders it in style N.

## Faces: profile with storybook reactions (Sept 30, owner's pick)

Five faces were tried against the old one (`shot=faces`, `cast` for combat size): profile,
ligne claire, rugged, storybook, brim shadow. The owner loved the **profile** look but missed
the cartoon reactions, so the default is **face 6 (`Figure.face_look`)**: the side-view profile
head at rest (idle, dead), switching to storybook reactions in action poses (`_toon_expr`,
`_face_toon`): a big eye with white, iris and catchlight, and a jaw that drops open.

- windup: eyes wide, brows up, mouth open. strike: scowl (the lid cuts the eye), a shout
  with teeth and tongue. aim: squint, gritted mouth. cast: eyes rolled up, a small "o".
  hurt: wide eye with a pinprick pupil, clenched teeth, a sweat drop.
- The windup and cast arms were moved so they no longer cross the face.
- `shot=faces poses` shows every pose, face 1 above face 6 (`zoom=`, `cls=`); `poses small`
  shows four classes at combat size. Faces 1-5 stay in the code for A/B.

## UI: wood and rope, drawn in code (Sept 30, owner's pick: light pass first)

- `StyleBoxWood` (`scripts/ui/wood_style.gd`) is a drawn StyleBox. `plank`: dark stained
  planks with low-contrast grain, knots, butt joints, nail heads, a frame and iron corner
  brackets; the `Dark` panel style. `DarkRopeTop` / `DarkRopeBottom` add a rope along that
  edge (bottom HUDs / top bars). `sign_board`: every button is a small signboard with
  chamfered corners and two nails; Danger and Good are painted boards with worn edges.
- Text sits on the dark planks or on parchment, never on busy grain.
- The expedition map (`MapView`) is a scorched parchment sheet nailed to a board: sketched
  terrain per region (`TERRAIN`), hand-inked curved trails (dotted until travelled, marching
  dots on the ways onward), wooden stop discs with the kind burned in (elites and the boss in
  red wax), a wash of fog over unscouted stops, a wagon piece that rolls between stops, a
  nailed legend card and an ONWARD signpost. The camp stop is a campfire (no tent).
- If this reads flat, the plan is a ComfyUI pass for the wood texture (see COMFYUI_BRIEF.md).
