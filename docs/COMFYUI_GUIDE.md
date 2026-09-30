# Running ComfyUI yourself (icons)

A hands-on guide for the owner. ComfyUI is already installed on the PC
(`C:/Users/btd08/Documents/comfy/ComfyUI`, RTX 4070 Ti Super). The game side is done:
any PNG saved as `assets/art/icons/<key>.png` replaces that drawn icon automatically
(keys and subjects are listed in `docs/COMFYUI_BRIEF.md`).

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

Positive (swap the middle part per item):

> storybook game inventory icon, **a small burlap sack tied with twine and a tin can of beans**,
> single object, centred, three-quarter view, light from the top left, bold thick dark brown
> outline, flat colour shapes, one shadow tone, chunky simple silhouette, plain flat cream
> background

Tips that matter more than extra adjectives:
- **One object.** "sack and a can" is already two; if the model muddles it, drop to one.
- **Say the outline and flat colour.** That is what makes it match the ink-style characters.
- **Never ask for words** (labels, "XXX" on a jug): the model can't spell.
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

1. Cut out the background: `python tools/art/cutout.py <image>` (rembg), or any background
   remover.
2. Crop square with a little margin and resize to **256 x 256** PNG.
3. Save as `assets/art/icons/<key>.png` (e.g. `food.png`, `bandage.png`).
4. Run `play.bat`: the import step picks it up and the icon shows in the wagon and store.
   Delete the file to get the drawn icon back.
5. Commit and push it (GitHub Desktop is fine). Note the seed somewhere
   (`assets/art/icons/icons.json`) so it can be regenerated.

## 6. The scripted route (optional)

`tools/art/generate.py` sends prompts from `tools/art/prompts.py` to the running ComfyUI and
saves numbered results with their seeds, handy for batches of 8-16 once a recipe works:

    python tools/art/generate.py --subject <key> --count 8 --workflow <workflow.json>

The browser editor is the better place to find the recipe; the script is for repeating it.
