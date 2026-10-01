# Running ComfyUI yourself (icons and backdrops)

A hands-on guide for the owner. ComfyUI is installed on the PC
(`C:/Users/btd08/Documents/comfy/ComfyUI`, RTX 4070 Ti Super). The game side is done: any
PNG saved as `assets/art/icons/<key>.png` replaces that drawn icon, and a backdrop set
replaces the drawn scenery for the regions pointed at it. Style rules are in
`ART_PIPELINE.md`.

**The usual route:** generate, pick, and attach the images in the chat with Claude, saying
which key or set each is for (up to 5 per message). Claude saves the originals to `art-src/`,
runs the prep, checks them in a screenshot and commits. Sections 5 and 7 describe what
happens, for doing it by hand.

## 1. Start it and open the editor

1. Open a terminal and run `comfy launch --background` (or start ComfyUI however you
   normally do).
2. Open http://127.0.0.1:8188 in a browser. You see a graph of boxes ("nodes") wired
   together. The default graph is a complete text-to-image setup.
3. `Ctrl+Enter` (or **Queue**) runs it. Results appear in the Save Image box and are saved to
   `ComfyUI/output/`.

## 2. The six boxes that matter

| Box | What to set for icons |
|---|---|
| **Load Checkpoint** | The model. `sd_xl_base_1.0` is what we have; it is a general model and a big reason icons come out muddy (see step 4). |
| **CLIP Text Encode** (top, positive) | What you want. One object, plainly described (see the prompts below). |
| **CLIP Text Encode** (bottom, negative) | What you don't: `text, letters, label, watermark, multiple objects, pile, scene, table, hands, background, shadow, photo, blurry` |
| **Empty Latent Image** | `1024 x 1024`, **batch_size 4** so each run gives four to pick from. |
| **KSampler** | `steps 28-32`, `cfg 5-7` (higher = follows the prompt harder but gets harsh), `sampler dpmpp_2m`, `scheduler karras`. **control_after_generate: randomize** while exploring, **fixed** once you like one. |
| **Save Image** | Set `filename_prefix` to the icon key, e.g. `icon_food`. |

The seed is the image's recipe: same seed + same settings = the same picture. When one comes
out close, fix the seed and change one thing at a time (a word in the prompt, cfg) so you can
see what each change does.

## 3. A prompt that works for icons

**The owner's vetted style (use this):** the object, then
`single objects, centred, three-quarter view, light from the top left, bold thick dark brown
outline, flat colour shapes, one shadow tone, chunky simple silhouette, plain flat cream
background`. The approved originals are kept in `art-src/icons/` as the reference set.

Tips that matter more than extra adjectives:
- **One object.** "sack and a can" is already two; if the model muddles it, drop to one.
- **Say the outline and flat colour.** That is what makes it match the ink-style characters.
- **Avoid words** on labels: the model can't spell. Simple marks (the whiskey's "XX") are fine.
- **Plain background** makes the cutout clean.

## 4. The biggest improvements, in order

1. **Judge at game size.** Shrink the result to 40 px (the size of a wagon slot) before
   deciding. Detail that looks great at 1024 disappears; bold shapes survive.
2. **A better model.** Base SDXL is weak at clean, flat illustration. A stylised SDXL
   fine-tune (downloaded into `ComfyUI/models/checkpoints/`, then picked in Load
   Checkpoint) usually beats any amount of prompt tweaking. Adding a game-icon or
   flat-illustration **LoRA** (into `models/loras/`, wired in with a **Load LoRA** box
   between Load Checkpoint and the rest, strength 0.6-0.9) helps even more. Check each
   model's licence allows use in a commercial game.
3. **Start from a sketch (image-to-image).** Draw the silhouette you want, even crudely
   (MS Paint is fine: dark outline, flat fills, 1024 px square), then:
   - add a **Load Image** box (your sketch) and a **VAE Encode** box (pixels from Load Image,
     vae from Load Checkpoint);
   - wire VAE Encode's output into the KSampler's **latent_image** instead of Empty Latent;
   - set KSampler **denoise** to about **0.55-0.7**: lower keeps your drawing, higher lets
     the model repaint more.
   This fixes composition problems (wrong object, too many objects, odd angle) almost
   completely, because you decide the shape.
4. **Style reference (IPAdapter)**: once one icon is right, feed it as a reference image so
   the rest of the set matches. Needs the IPAdapter custom nodes (ComfyUI Manager → install).

## 5. From image to game

Generate at any size (1024 is fine; don't generate small, the model does worse). Keep the
plain light background: the prep script removes it.

1. Save the picture you like as **`art-src/icons/<key>.png`** (or .webp/.jpg), named by its
   key. Done: `food`, `bandage`, `vial` (antivenom), `bottle` (whiskey), `oil`, `rope`,
   `shovel`, `salt`, `wheel` (wagon parts), `timber`, `iron`, `money` (chips), `week`,
   `wagon`, `xp`, `eye` (scouting), `charter`. Still drawn: `skull` (deaths), the move types
   `melee`, `ranged`, `heal`, `buff`, `debuff`, and the combat stats `dmg`, `crit`, `dodge`,
   `prot`, `speed`, `acc`.
2. Either run `python tools/art/prep_icons.py --dir art-src/icons` (needs
   `pip install pillow numpy`), which writes the game-ready `assets/art/icons/<key>.png`
   (256 px, transparent, trimmed), or just commit and push the `art-src` file and ask Claude
   to run it. The script removes the plain background by flood fill from the border, plus
   soft grey ground shadows. Two per-key settings at its top: `POCKET_KEYS` (see-through
   gaps inside the outline, like the wheel's spokes) and `SHADOW_COLS` (a coloured ground
   shadow, like the whiskey bottle's orange one).
3. Run `play.bat`: the icon replaces the drawn one. Delete the `assets/art/icons` file to
   get the drawn icon back.
4. Commit and push both files (GitHub Desktop is fine). The original stays in `art-src` so
   it can be reprocessed later.

## 6. The scripted route (optional)

`tools/art/generate.py` sends prompts from `tools/art/prompts.py` to the running ComfyUI and
saves numbered results with their seeds, handy for batches of 8-16 once a recipe works:

    python tools/art/generate.py --subject <key> --count 8 --workflow <workflow.json>

The browser editor is the better place to find the recipe; the script is for repeating it.

## 7. Backdrops

Scenery images live in `art-src/backdrops/` (originals) and `assets/art/backdrops/`
(resized to 1920 wide, PNG, game-ready). Current sets: `prairie` (the owner's, on the tutorial
and all rumors), `tallgrass_trail` (the Tallgrass Sea), `title` (the menu). A set is numbered, `<key>_1.png`, `<key>_2.png` and so on; the
trail and combat screens step through the set as the company crosses the map (first image
at the start, last at the end). A region uses a set through its `"backdrop"` field in
`data/regions.json`; saloon quests use `quest_backdrop` in `data/config.json`. The set
shows outdoors only (trail and fights): caves and the night camp keep their own scenery.

`assets/art/backdrops/horizons.json` says how far down each image the foot of the mountains
(the skyline) sits, e.g. `0.36`. The game lines that up with the top of the combat stage, so
the whole sky and range stay in view and the figures stand on the ground. New images get a
measured guess; check it in-game and hand-set it if the view looks zoomed into the ground.

**Size.** Generate at **1344 x 768** (SDXL's native 16:9 size; asking SDXL for 1920 or more
straight away gives muddled compositions), then **upscale 2x with a model upscaler** before
saving: add an **Upscale Image (using Model)** box with `RealESRGAN_x4plus` (in
`models/upscale_models`), then **Upscale Image By** 0.5, for 2688 x 1536. Save as **PNG**.
The game draws the scenery about 2070 px wide on a 1080p screen and about 2760 px on 1440p, so
a 1344-wide image gets blown up 1.5-2x and looks soft and blocky; the upscaled one doesn't.
The chat delivers large images shrunk to about 1872 x 1056 and converted to WebP. That is
already a clear step up and fine for now; for full quality, commit the PNG to
`art-src/backdrops/` with GitHub Desktop and tell Claude its name. Replaced originals move to
`art-src/backdrops/alt/`.

Composition that works (16:9): sky and range in the top third, rolling
ground below, and the **lower middle kept open**, since eight figures stand across it from
about 10% to 90% of the width. A landmark (cabin, windmill, rocks) belongs small in the
middle distance or at the far left or right edge, not low in the frame, or it ends up behind
the fighters.
