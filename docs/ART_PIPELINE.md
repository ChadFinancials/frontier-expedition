# Art Pipeline

What the game looks like now, where each piece of art comes from, and the style rules the
owner has settled. The step-by-step for turning an image into game art is in
`COMFYUI_GUIDE.md`; how the loaders work is in `ARCHITECTURE.md`. The September 2026
exploration that led here (SDXL runs, rankings, failed routes) is archived in
`archive/art_experiments_2026-09.md`.

## Where art comes from

| Piece | Source | Where |
|---|---|---|
| Heroes, enemies, creatures | **Drawn in code** from each `look` in the data | `scripts/visual/figure.gd` |
| UI panels, buttons, bars | **Drawn in code**: wood planks, rope, signboards | `scripts/ui/wood_style.gd`, `ui.gd` |
| Expedition map | **Drawn in code**: parchment, inked trails, wooden discs | `scripts/visual/map_view.gd` |
| Town street and buildings | **Painted** for Fort Providence (its painted buildings are the plots, with wooden signs); **drawn** elsewhere | `assets/art/town/`, `town_view.gd` |
| Wagon, campfire, event and curio art | **Drawn in code** | `wagon_art.gd`, `campfire.gd`, `event_art.gd`, `curio_art.gd` |
| Scenery | **Painted** where a set exists, otherwise **drawn** layered paper scenery | `assets/art/backdrops/`, `backdrop.gd` |
| Item and resource icons | **Painted by the owner**, drawn fallback | `assets/art/icons/`, `res_icon.gd` |
| Paper grain, relief, haze, stage light | **Shaders** | `paper.gdshader`, `sky_wash.gdshader`, `vignette.gdshader` |

Nothing is generated at runtime. Painted art is made by the owner in ComfyUI at their desk,
handed over, prepped by a script and committed like any asset. Every painted piece has a
code-drawn fallback, so the game runs with any fraction of the art done.

## The approved looks

### Characters: ink illustration (owner's pick, Sept 30)
- `Figure.body_style = 4`: spline torso with sloped shoulders, tapered limbs with elbows and
  knees, heeled boots, flaring coats; every piece rounded (Chaikin). Rendered piece by piece:
  a small cast shadow, a bold ink outline, a flat fill, cel bands (shadow on the far side, a
  core line, a warm highlight on the lit top-left edge) and sparse hatching in big shadows.
- `Figure.three_quarter = true` (owner, after Darkest Dungeon): bodies turn three-quarter
  toward the facing side. The chest opens forward (coat opening, buckle and badge shift
  front), the near arm holds the weapon from the back shoulder across the body, the far arm
  sits behind the chest and steadies the weapon (rifles: out along the barrel), and the back
  leg is the near one. At rest weapons are held low and ready at the waist. Screenshot arg
  `side` renders the old side-on build for comparison.
- Faces: `Figure.face_look = 6`: a side-view **profile** at rest (idle, dead) that switches to
  **storybook reactions** in action poses: windup (eyes wide, brows up, mouth open), strike
  (scowl, a shout with teeth), aim (squint, gritted mouth), cast (eyes rolled up, a small
  "o"), hurt (pinprick pupil, clenched teeth, a sweat drop). The elbow bends as a `<`.
- **Outfits**: three colorings per class, rolled per hero, colors only (see
  `ADDING_CONTENT.md`).
- Older body styles (0-3, 5) and faces (1-5) stay in the code for side-by-side comparisons:
  `tools/shot.sh body_ab`, `faces [poses] [small]`, `outfits`, `lineup`. `body=N` on any
  scenario renders style N.

### UI: wood and rope (owner's pick: the light pass)
- `StyleBoxWood` draws dark stained planks with low-contrast grain, knots, butt joints, nail
  heads, a frame and iron corner brackets (the `Dark` panel style); `DarkRopeTop` /
  `DarkRopeBottom` add rope along an edge. Every button is a chamfered signboard with two
  nails; Danger and Good are painted boards with worn edges.
- **Text never sits on busy grain.** Text areas on wood use the `Inset` panel (a dark,
  readable well), or parchment.

### The map
- A scorched parchment sheet nailed to the board: sketched terrain per region (`TERRAIN`),
  hand-inked curved trails (dotted until travelled, marching dots on the ways onward), wooden
  stop discs with the stop kind burned in (elites and the boss in red wax), fog over
  unscouted stops, a wagon token that rolls between stops, a legend card and an ONWARD
  signpost. The camp stop is a campfire.

### Scenery
- **Drawn**: the paper-theater look (`PaperFX`): layered paper hills with relief edges, a
  watercolor sky, and the owner's favourite quirks, **paper clouds and a sun hanging on
  strings**. Tinted per region from `palette`, with `props`.
- **Painted**: flat, crisp, storybook colour chunks (see the style rules below). In use: the
  title screen (`title.png`), the Tallgrass trail (`tallgrass_trail_1-6`, older and more
  detailed), and the owner's own **prairie** set (`prairie_1-2`) on the tutorial and all
  Saloon rumors. Plan: the owner generates about ten more in the prairie style for stops
  across side quests and expeditions.

### Icons
- The owner's painted set covers every supply and resource: food, bandage, vial (antivenom),
  bottle (whiskey), oil, rope, shovel, salt, wheel (wagon parts), timber, iron, money (chips),
  charter, week, wagon, xp, eye (scouting).
- Still drawn in code: `skull` (deaths), the move-type icons (`melee`, `ranged`, `heal`,
  `buff`, `debuff`) and the combat stat icons (`dmg`, `crit`, `dodge`, `prot`, `speed`,
  `acc`). Any of them can be replaced by dropping in a PNG with that key.

## Style rules (owner's word)

- **Icons**: the owner's prompt style is the house style: *"single objects, centred,
  three-quarter view, light from the top left, bold thick dark brown outline, flat colour
  shapes, one shadow tone, chunky simple silhouette, plain flat cream background"*. One object,
  readable at 40 px, one clear identifying colour. No words on labels (simple marks like
  "XX" are fine).
- **Backdrops**: flat storybook colour chunks with crisp edges, not painterly or realistic.
  Natural, believable colour with no single colour dominating (blue skies, green and sandy
  ground). 16:9. Sky and mountains in the top third, open ground below; keep the **lower
  middle clear** because the fighters stand across it; landmarks small in the distance or at
  the edges.
- **Area 1 backdrop prompt** (the owner's, verbatim): see `COMFYUI_GUIDE.md` §7. Key parts:
  flat colour shapes, simple shadow tone, chunky silhouettes, animated storybook, handmade,
  papier-mache, map styling; horizon in the upper middle, foreground empty of major objects,
  clear depth layers, a river snaking into the distance, a dirt trail.
- **Never**: tipis, totem poles, dreamcatchers, feather headdresses or war bonnets. Native
  peoples are never cast as enemies, and the art must not imply it.
- Characters stay clean and sculpted (no patchwork collage on figures). Don't prompt for paper
  grain or hatching: the shaders own that.

## What we learned (short version of the archive)

- Base SDXL drifts toward realism; the owner rejected "too realistic and detailed" every
  time. What worked: flat colour, one light source, bold outlines, and saying so plainly.
- A negative prompt alone does not remove objects; exclusions must also go in the positive
  prompt. Asking for a prop inside a wide landscape fails (a wagon became a sailboat); make
  props alone on a plain field and place them in code.
- A seed does not carry a character across prompts, so generated characters could not hold
  identity across poses. That is why characters are drawn in code.
- Cut-outs: a border flood fill works for flat plain-background icons (`prep_icons.py`),
  with pocket removal only for see-through shapes (the wheel) and per-key coloured-shadow
  removal (the whiskey bottle).
- An auto-measured horizon can land on a path or a field edge; check backdrops in game and
  hand-set `horizons.json` when the view looks zoomed into the ground.
- Judge art at game size, and measure pixels rather than trusting a description of a small
  image.

## Tools

| Tool | Does |
|---|---|
| `tools/art/prep_icons.py` | Cuts out an icon from its plain background, trims, pads, saves 256 px |
| `tools/art/prep_backdrops.py` | Measures the horizon of new backdrops into `horizons.json` (keeps existing entries) |
| `tools/art/generate.py`, `prompts.py`, `*.json` workflows | Scripted ComfyUI generation (on the owner's PC; optional) |
| `tools/art/cutout.py`, `inpaint.py` | Earlier experiments: rembg cut-outs and pose inpainting |
| `tools/shot.sh` | Screenshots in the real game, for checking any art change |
