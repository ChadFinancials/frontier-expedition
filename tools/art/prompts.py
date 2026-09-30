"""Shared prompt blocks for Frontier Expedition art generation.

One style string, reused by every generation, so the whole art set stays coherent.
Edit STYLE here rather than in individual calls. See docs/archive/art_experiments_2026-09.md.

Keep this simple. Owner note Sept 29: "maybe dont try and dictate which colors go where and
just revert back to a more simple prompt". So do NOT list which colour goes where. Describe
the subject, the framing and the medium, and let the model choose believable frontier colour.

    python tools/art/generate.py --subject marshal --count 6
    python tools/art/generate.py --subject tallgrass --count 4
"""

# Short on purpose. Medium and handling only, no colour instructions, no scene exclusions.
STYLE = (
    "storybook artbook illustration in full colour, handcrafted and flat, bold simple shapes with crisp "
    "dark outlines, rough grainy paper with visible fibre texture, fine pencil hatching in "
    "the shadows, slightly cartoonish and stylised and not realistic, warm muted frontier "
    "colours, painted cardstock"
)

# How characters are framed. Isolated on a plain field so cutout.py can key them to alpha
# and the game can place them. Figures face right; Figure.flip handles enemies.
# Learned Sept 29: a plain "isolated on a parchment field" was ignored and SDXL returned
# black-and-white landscape scenes instead. Character shots need a character-sheet framing
# plus landscape and monochrome bans (NEGATIVE_CHAR below).
CHARACTER_FRAME = (
    "one single character, full body from hat to boots, feet at the bottom of the frame, "
    "facing right, standing straight and centred, alone, full colour illustration with a "
    "warm palette, the character fills the frame. the background is one single flat "
    "uniform cream colour, completely plain and even from edge to edge, no frame, no "
    "border, no shadow under the feet, nothing else in the image"
)

# Style drift and content guards. No hue bans: the owner overruled those.
NEGATIVE = (
    "monochrome, greyscale, grayscale, black and white, ink drawing, sepia, duotone, "
    "photorealistic, photograph, painterly, oil painting, digital painting, concept art, "
    "semi-realistic, 3D render, CGI, glossy, plastic, smooth gradients, airbrush, "
    "over-detailed, hyper-detailed, busy detail, cluttered, blurry, soft focus, "
    "patchwork, quilt, torn scraps collage, stitched patches, "
    "tipi, teepee, wigwam, totem pole, dreamcatcher, feather headdress, war bonnet, "
    "text, lettering, signage, watermark, signature, logo, "
    "horses, cattle, herd, "
    "deformed anatomy, extra limbs, extra fingers, extra legs, "
    "low quality, deformed, jpeg artifacts"
)

# Stated in the positive prompt as well, because SDXL ignores a negative prompt on its own.
EXCLUDE = "an empty untouched landscape, no people, no horses, no animals, no buildings"

# Extra bans for character sheets only. SDXL turns a bare "isolated figure" request into a
# landscape, and the word hatching into monochrome. Keep these away from the backdrop
# subjects, where landscape words are exactly what we want.
NEGATIVE_CHAR = NEGATIVE + (
    "landscape, scenery, background scene, environment, sky, clouds, mountains, hills, "
    "ground, horizon, distant view, "
    "interior, room, doorway, doorway opening, indoor, walls, floor, floorboards, "
    "stage, backdrop, "
    "top hat, top hats, victorian, victorian gentleman, formal suit, tailcoat, dress coat, "
    "cravat, monocle, frock suit, "
    "frame, border, decorated border, ornamental border, vignette, torn edge, panel, "
    "parchment texture, aged paper texture, drop shadow, cast shadow, ground shadow, "
    "character sheet, design sheet, reference sheet, turnaround, multiple views, "
    "extra sketches, headshot, close-up, detail studies, annotations, labels, notes, "
    "diagram, multiple figures, crowd, group, two people, "
    "monochrome, greyscale, grayscale, black and white, sepia, sepia tone, brown wash, "
    "ink wash, single colour, duotone, "
    "cropped, out of frame"
)

# The wagon is the game's signature prop (WagonArt on the menu, the trail and at camp).
WAGON_MOTIF = (
    "the company's covered wagon standing small in the middle distance, a canvas-topped "
    "prairie schooner seen from the side, simple flat silhouette"
)

# --- pose set for static character sprites -----------------------------------------
# How poses work today (scripts/visual/figure.gd, scripts/screens/combat_screen.gd):
#   Figure.pose is one of: idle, aim, windup, strike, cast, hurt, dead (figure.gd line 19).
#   combat_screen sets hurt, windup, strike, aim, cast, idle, and once "attack" (line 1073).
#   BUGS: "attack" is set but is not in that list and has no hand positions, so it silently
#   falls back to the idle pose. "dead" is declared but nothing ever sets it.
# The pose also moves the body, not only the arm: strike and aim lean forward 0.14, hurt
# leans back 0.16, cast leans 0.05, plus a 14px lunge on strike/aim and -8 on hurt.
# So the sprite must carry the lean, not just the arms.
POSES = {
    "idle": "standing straight and relaxed, holding the open Bible in both hands in front "
            "of his chest, feet planted",
    "windup": "winding up to strike: the Bible arm drawn back and up behind his head, body "
              "coiled back, weight on the back foot",
    "strike": "striking: the arm swung forward and down, Bible thrust out ahead of him, "
              "leaning forward hard, weight on the front foot",
    "aim": "aiming: one arm extended straight out in front at shoulder height pointing "
           "forward, the other hand braced at his chest",
    "cast": "calling out: one arm raised high overhead with the palm open, the other hand "
            "holding the cross at his chest, head tilted up",
    "hurt": "hurt: recoiling backwards, hunched and off balance, head down, one arm "
            "clutched across his body",
    "dead": "collapsed on the ground, fallen backwards, arms limp at his sides, his hat "
            "fallen off beside him",
}

# The approved Preacher base model: seed 84492238, art-tests/preacher-pick4 P1.
# Keep this block word for word so every pose stays the same character.
PREACHER_ID = (
    "a frontier preacher, a tall gaunt sun weathered man with a full grey white beard and "
    "grey white hair, all black and grey with no bright colour, a long black frock coat "
    "buttoned to the throat over a cream robe, black trousers, brown boots, a white "
    "clerical collar at his throat, a wide flat brimmed low crowned plain black hat, "
    "holding a thick brown Bible with a cross stamped on its cover"
)

SUBJECTS = {
    # --- characters ---------------------------------------------------------------
    "marshal": (
        "a frontier lawman, a weathered marshal in a long duster coat and a wide brimmed "
        "hat, a tin star on the chest, a revolver in one hand, boots, tough and calm"
    ),
    "preacher": (
        "a frontier preacher holding a thick black Bible in one hand, and wearing a plain "
        "wooden (cross:1.4) hanging on a cord at his chest, the cross clearly visible. "
        "a tall gaunt man, all black and grey with no bright colour, in a worn long black "
        "frock coat buttoned to the throat, plain black trousers and black boots, a white "
        "clerical collar at his throat, and a wide flat brimmed low crowned plain black "
        "hat, not a top hat. grey white beard and grey white hair, sun weathered and stern, "
        "western not victorian"
    ),
    # --- isolated props -----------------------------------------------------------
    "wagon_sprite": (
        "a single covered wagon, a canvas-topped prairie schooner, seen from the side at a "
        "slight three quarter angle, positioned in the centre of the frame"
    ),
    # --- backdrops ----------------------------------------------------------------
    "tallgrass": (
        "region 1, the Tallgrass Sea. A vast open tallgrass prairie stretching west under a "
        "wide sky. Rolling grass hills receding in layers, a faint wagon trail rut running "
        "toward the horizon, a lone dead tree, distant low ridges. wide cinematic "
        "composition, open sky in the upper third"
    ),
    "tallgrass_trail": (
        "region 1, the Tallgrass Sea, seen from the wagon trail at eye level. shoulder-high "
        "grass to either side of a rutted dirt track, grass blades in the near foreground, "
        "rolling hills behind, a distant ridge line, wide open sky, late afternoon light"
    ),
    "tallgrass_night": (
        "region 1, the Tallgrass Sea, camped at night. The same prairie under a night sky, "
        "a low moon, scattered stars, silhouetted grass in the foreground, a distant "
        "campfire glow"
    ),
    "red_canyons": (
        "region 2, the Red Canyons. Deep rock walls and mesas receding in layers, a dry "
        "riverbed winding between them, scattered boulders, dust haze in the distance. "
        "wide cinematic composition, open sky in the upper third"
    ),
    "thunder_peaks": (
        "region 3, the Thunder Peaks. Towering storm mountains in layers, heavy cloud "
        "banks, a pass receding into mist, snow on the high ridges, dark pine silhouettes "
        "in the near foreground"
    ),
    "cave": (
        "a cave interior by lamplight. A rough stone passage receding into darkness, rock "
        "strata, a warm pool of lamplight on the floor, deep shadow in the far corners, "
        "scattered rubble and old bones"
    ),
    # Title and loading screen backdrops. Composition is dictated by main_menu.gd: the title
    # sits at y=120-260, the code draws the wagon at (700, 772), buttons at y=820+. So leave
    # calm empty sky in the upper third and a quiet band across the bottom.
    "loading_night": (
        "the title and loading screen view of the Tallgrass Sea at night. A deep night sky "
        "across the upper third, calm and empty and uncluttered so a title can sit there, a "
        "low moon, a scatter of small stars, a distant ridge line near the middle of the "
        "frame, a low quiet band of silhouetted grass across the bottom. "
        "wide 16:9 cinematic composition, no wagon, no buildings, no campfire"
    ),
    "loading_dusk": (
        "the title and loading screen view of the Tallgrass Sea at golden hour. A wide sky "
        "across the upper third, calm and empty and uncluttered so a title can sit there, "
        "the sun low on the horizon with long shadows reaching across the ground, a distant "
        "ridge line near the middle of the frame, a low quiet band of tallgrass across the "
        "bottom. wide 16:9 cinematic composition, no wagon, no buildings"
    ),
    "loading_night_wagon": (
        "the title and loading screen view of the Tallgrass Sea at night. A deep night sky "
        "across the upper third, calm and empty and uncluttered so a title can sit there, a "
        "low moon, a scatter of small stars, a distant ridge line near the middle of the "
        "frame, and a low quiet band of silhouetted grass across the bottom. "
        "wide 16:9 cinematic composition, no buildings, no campfire"
    ),
    "loading_dusk_wagon": (
        "the title and loading screen view of the Tallgrass Sea at golden hour. A wide sky "
        "across the upper third, calm and empty and uncluttered so a title can sit there, "
        "the sun low on the horizon with long shadows reaching across the ground, a distant "
        "ridge line near the middle of the frame, and a low quiet band of tallgrass across "
        "the bottom. wide 16:9 cinematic composition, no buildings"
    ),
    "loading_green": (
        "the title and loading screen view of the Tallgrass Sea on a clear morning. A wide "
        "sky across the upper third, calm and empty and uncluttered so a title can sit "
        "there, a few soft clouds, a distant ridge line near the middle of the frame, a low "
        "quiet band of tallgrass across the bottom. "
        "wide 16:9 cinematic composition, no wagon, no buildings"
    ),
}

# Characters, framed by CHARACTER_FRAME. Isolated so cutout.py can key them.
CHARACTERS = {"marshal", "preacher"}

# One subject per pose for the approved Preacher base. The identity block is byte for byte
# identical across them and only the pose clause changes, so the set stays as consistent as
# prompting alone can make it.
for _pose_name, _pose_desc in POSES.items():
    SUBJECTS[f"preacher_{_pose_name}"] = f"{PREACHER_ID}. {_pose_desc}"
CHARACTERS |= {f"preacher_{_n}" for _n in POSES}

# Isolated props. No EXCLUDE tail and no scene cues.
CUTOUTS = {"wagon_sprite"}

# Backdrops that carry the wagon.
WITH_WAGON = {"loading_night_wagon", "loading_dusk_wagon"}


def build(subject: str) -> tuple:
    """Return (positive, negative) prompt strings for a subject key."""
    if subject not in SUBJECTS:
        raise SystemExit(f"unknown subject '{subject}'. pick from: {', '.join(SUBJECTS)}")
    if subject in CHARACTERS:
        positive = f"{SUBJECTS[subject]}. {CHARACTER_FRAME}. {STYLE}."
        return positive, NEGATIVE_CHAR
    elif subject in CUTOUTS:
        positive = f"{SUBJECTS[subject]}. {STYLE}."
    else:
        motif = f" {WAGON_MOTIF}." if subject in WITH_WAGON else ""
        positive = f"{SUBJECTS[subject]}.{motif} {EXCLUDE}. {STYLE}."
    return positive, NEGATIVE
