# Architecture

How Frontier Expedition is put together: what lives where, how a frame of play flows through
the code, and where to make a given kind of change. Read this before touching code. For the
design itself see `GDD.md`; for adding content see `ADDING_CONTENT.md`.

## The shape of it

```
data/*.json ──► DB (autoload) ──► core rules (node-free) ──► screens (build UI, animate events)
                                   Company, RunState,          Main.goto("trail"), modals
                                   CombatEngine, Hero...        visual/ (Figure, Backdrop...)
                                         ▲                      ui/ (theme, widgets)
                  Game (autoload) ───────┘ save/load, settings
                  Audio (autoload): play("gunshot")
```

Three rules hold the codebase together:

1. **Content and numbers are data.** Classes, moves, enemies, regions, events, curios, quirks,
   trinkets, items, buildings, quests and every balance constant live in `data/*.json`. Code
   reads them through `DB`. Adding content should not need code (see `ADDING_CONTENT.md`).
2. **Rules are node-free.** Everything in `scripts/core/` is a `RefCounted` class with no
   scene tree, drawing or timers. It takes calls and returns results (combat returns a list of
   event dictionaries). That is what lets `tests/run_tests.gd` play whole campaigns headless.
   Screens never decide outcomes; they call core APIs and animate what comes back.
3. **Art falls back to code.** Characters, the map, the town, the wood UI and most scenery are
   drawn in code. Painted images (icons, backdrops) are optional overrides: when a file is
   missing, the drawn version shows. The game runs with any fraction of the art done.

## Directory map

| Path | What |
|---|---|
| `project.godot` | Engine settings, version (`config/version`), the three autoloads, main scene. Renderer: Vulkan (Forward+) with 2D MSAA, falling back to OpenGL (Compatibility) |
| `scenes/main.tscn` | The only scene: a `Main` node. Every screen is built in code |
| `data/` | All content and balance (17 JSON tables, listed below) |
| `scripts/autoload/` | `DB` (data), `Game` (company, save, settings), `Audio` (sound) |
| `scripts/core/` | The rules: combat, campaign, expedition, heroes, fatigue, map generation |
| `scripts/main.gd` | Root node: screen switching, modals, dialogs, toasts, pause and help menus |
| `scripts/screens/` | One script per screen, plus the building and hero-sheet modals |
| `scripts/ui/` | The theme (`UI`), the drawn wood StyleBox, and small widgets |
| `scripts/visual/` | Code-drawn art: characters, backdrops, map, town, wagon, event and curio art, shaders |
| `scripts/debug/shots.gd` | Screenshot scenarios for visual checks (`tools/shot.sh`) |
| `tests/` | Unit and data tests, the balance simulator, the rules bot, the UI autopilot |
| `tools/` | Checks, screenshots, audio generation and levelling, review sheets |
| `tools/art/` | Icon and backdrop prep scripts, plus the ComfyUI generation scripts |
| `assets/art/icons/` | Game-ready painted icons (256 px PNG), one per icon key |
| `assets/art/backdrops/` | Game-ready painted backdrops (1920 wide) and `horizons.json` |
| `assets/audio/` | Sound effects and music, `levels.json` (loudness offsets), `CREDITS.md` |
| `assets/fonts/` | Rye (headings) and Alegreya (text), SIL OFL |
| `art-src/` | The owner's original art (icons, backdrops) before prep. Ignored by Godot (`.gdignore`) |
| `download/` | The Windows build zip. Only refreshed for a major version, when the owner asks |
| `.github/workflows/build.yml` | On a `v*` tag: run tests, export Windows, publish a release |
| `play.bat` | The owner's launcher: pull `main`, import, run from source (`play_opengl.bat` forces OpenGL) |
| `docs/` | Design, architecture, content guide, art, backlog (see `docs/README.md`) |

## Autoloads

- **`DB`** (`scripts/autoload/db.gd`) loads every table in `TABLES` from `data/<name>.json` at
  startup. Keys starting with `_` are dropped (use them for comments); every entry gets an
  `id` field equal to its key. `DB.normalize` turns integral floats into ints (JSON has only
  floats). `DB.cfg(key, default)` reads `config.json`. `DB.validate()` cross-checks references
  between tables and is run by the tests. Tables: `config, classes, skills, enemies, regions,
  settlements, buildings, survival, quirks, keepsakes, items, curios, events, fatigue_states,
  names, quests, townsfolk` (`names`, `quests` and `townsfolk` are whole documents, not
  tables of entries, so they get no `id`s).
- **`Game`** (`scripts/autoload/game.gd`) owns `Game.company` (the `Company`), saving to
  `user://save.json` (`save_game`, `load_game`) and settings in `user://settings.json` (sfx,
  music, fullscreen, combat speed, paper look). F11 toggles fullscreen. On Windows `user://` is
  `%APPDATA%\Godot\app_userdata\Frontier Expedition` (logs are in its `logs\` folder).
- **`Audio`** (`scripts/autoload/audio.gd`) loads every clip in `assets/audio/`.
  `Audio.play("gunshot")` plays `gunshot.wav` or a random variant `gunshot_N.ogg`. Per-clip
  loudness offsets come from `assets/audio/levels.json`. Music loops through `play_music`.

## Core rules (`scripts/core/`)

| Class | Holds | Notes |
|---|---|---|
| `Company` | The campaign: chips, Timber, Iron, Hides, Charters, heroes, settlements and buildings, the week, story flags, saloon quests, the current `run` | All town services (build, upgrade, treat, train, hire, stage line) are methods here. `start_run` / `finish_run` open and settle an expedition. `advance_week` runs the weekly clock. `to_dict` / `from_dict` is the save format |
| `RunState` | One expedition: the map (`nodes`, `current`), party, supplies, wagon, loot, log, cave state | Travel, scouting, camp, curios, events (experts, compel, follow-ups in `followup`), caves and trading posts. `after_combat` settles a fight. `combat_options` builds a fight's modifiers |
| `CombatEngine` | One battle | See "Combat" below |
| `Combatant` | A unit inside a battle | Wraps a `Hero` or an enemy definition; stats, statuses, buffs |
| `Hero` | A company member | Class, level and XP, gear tiers, known and equipped skills, survival skills, quirks, trinkets, Fatigue |
| `Fatigue` | Static helpers | Adding Fatigue, Gut Checks, Breaking Points and True Grit (`second_wind` in code), Collapse. Returns events |
| `Townsfolk` | Static helpers | A townsperson is a plain dictionary in `Company.townsfolk` (a separate pool from heroes). Helpers: work level, wage, the help they give in a building (`value_in`), titles and trait text. `Company` owns the rest: seats (`staff_seats`, `post_townsperson`), the bonuses read by each service (`staff_value`, `staff_mult`, `staff_masters`), `production`, and `_townsfolk_week` in the weekly clock. `TownsfolkPanel` (screens) is the roster; `TownsfolkCard` (ui) the card and picker |
| `Effects` | Static `apply` | Out-of-combat effects from events, curios and camp actions (format in `ADDING_CONTENT.md`) |
| `Duel` | Static helpers | High Noon scoring: the hero's edge, aim zones, results and a screenless `roll` for tests and the bot. `HighNoon` (scripts/ui) is the screen; `RunState.resolve_duel` applies a result and parks the duelist's gang for the next fight (`duel_gang`) |
| `SkillCheck` | Control (scripts/ui) | The four curio check games. `SkillCheck.investigate` plays a curio's check (`RunState.curio_check` sets the difficulty) and passes the result to `interact_curio` |
| `MapGen` | Static `generate` | Builds an expedition's branching map. Every node's contents are rolled up front, so a mid-run save reloads identically. Also node intel (what the player can see). `pick_event` draws event stops from the common, region and quest-theme pools |
| `Inventory` | Static helpers | Wagon slots and stacking over the plain `supplies` dictionary |
| `Stats` | Static helpers | The shared modifier format `{stat, value, cond}` used by quirks, trinkets, Fatigue states and buffs; weighted picks |

Randomness goes through a `RandomNumberGenerator` owned by the company, run or engine, so
tests can seed it.

### The campaign loop

```
Main menu ─► settlement screen ─► embark screen ─► Company.start_run() ─► trail screen
   ▲              (town, week)      (party, supplies)   creates RunState       │ pick a stop
   │                                                                          ▼
results screen ◄─ Company.finish_run() ◄─ boss / crossing won, turn back, wipe ◄─ resolve stop:
                                                                   fight/elite/boss ─► combat screen
                                                                   camp ─► camp screen
                                                                   cave ─► cave screen
                                                                   event, curio, trading post,
                                                                   homestead ─► modal on the trail
```

- `Main.goto(name, params)` frees the current screen, builds the new one from `Main.SCREENS`
  and calls its `setup(params)`. Screens: `menu, settlement, embark, trail, combat, camp,
  cave, results`.
- Combat is entered with `{"enemies": [...], "kind": "fight"|"elite"|"boss"|"crossing",
  "return": "trail"|"cave"}`; on the way out it calls `run.after_combat(engine, kind)` and
  goes back to `return` (or to `results` when the expedition ends).
- **Autosave:** screens call `Game.save_game()` after every settled action (arriving at a
  stop, a fight's end, a camp step, a town action). A save made mid-expedition resumes on the
  trail.
- **Weekly clock:** one expedition is one week. `Company.advance_week` first runs the
  townsfolk week (producers deliver, staff learn, wages are paid, the unpaid and restless
  leave, Tipplers roll for a week off), then counts down treatments
  and stage-line trips, tops chips up to `grubstake_floor`, then refreshes every settlement:
  building slots clear, the Saloon rolls new quests, the Hiring Board new recruits and the
  General Store new trinket stock.
- **Saloon quests** are generated regions: `Company._make_quest` builds a region dictionary
  from a `quests.json` template plus the western region's content, stores it in
  `quest_regions` (saved) and registers it in `DB.regions` so the rest of the code treats it
  like any region.
- **Story hooks:** the tutorial (`old_mill_road`, a `fixed_map`), side adventures (`side:
  true` regions listed by a settlement), and boss `first_script` cutscenes (Silas Crane's
  first meeting). Story state lives in `Company.story_flags` and `beaten`.

### Combat

```
engine.setup(heroes, enemy_ids, options)       # options from run.combat_options(kind)
while not engine.is_over():
    events = engine.step()                     # AI turns run on their own; stops at a hero
    if engine.awaiting_input():
        events = engine.hero_skill(skill_id, target_id)   # or hero_swap / hero_pass / retreat
```

- Every call returns an **array of event dictionaries**, keyed by `"t"`: `round`, `turn`,
  `action`, `hit`, `miss`, `crit_relief`, `dot`, `heal`, `buff`, `debuff`, `status`, `resist`,
  `moved`, `positions`, `swap`, `summon`, `deaths_door`, `deathblow_resist`, `death`,
  `fatigue`, `act_out`, `collapse`, `stun_skip`, `surprise`, `scripted`, `end` and more.
  Tests assert on them; `combat_screen.gd` animates them.
- Formulas (hit, crit, damage, effect chance) are `hit_chance`, `crit_chance`, `dmg_mult`,
  `effect_chance` in the engine, fed by `Combatant.stat` (class stats, level, gear, quirks,
  trinkets, buffs) and constants in `config.json`. Class matchups (`vs_tags` on a class, e.g.
  the Mountain Mystic against beasts) go through `_class_vs`.
- **Momentum** (Train Hopper, classes with `"momentum": true`): `Combatant.momentum`, reset
  each fight. Gains: a move's `momentum` field (in `use_skill`), `_moved_by_others` (+10 when
  shoved or swapped by anyone but the mover, via `_actor`); losses in `_end_turn` (turn ends
  at `turn_rank`) and on a stun skip. `Combatant.full_steam()` adds Speed/Dodge in `stat()`.
  The class's `mega` move is gated by `mega_skill()` in `valid_targets`; the combat screen
  shows it as an extra action-row button; `momentum` events drive the HUD gauge
  (`UnitView.shown.momentum`) and popups. `swap_places` (Catch Out) trades two ranks.
- **Bones** (Darkest Dungeon's corpses): `_cleanup` swaps a fallen enemy for a
  `Combatant.bones()` unit (`corpse = true`, `bones_hp` HP, 0 turns it off) in the same rank,
  so the line behind doesn't step up until the bones are destroyed. Bones never act, take
  no effects, aren't kills (no `killed` entry, no on-kill payoffs) and don't count for
  victory; area, random and targeted hits all land on them. A summoner on a full line
  sweeps the rearmost bones aside. Events: `bones` (new unit) and `death` with `bones: true`.
- **Enemy AI** picks a move by the skill's `ai.weight` and a target by `ai.pref`
  (`random, lowest_hp, marked, back, front, deaths_door`), honouring taunt and guard.
- **Layout**: units stand on `GROUND` (745); the HUD panel starts at 835. Each unit's HUD
  (`UnitView._Hud`) draws HP, Fatigue, action diamonds and up to three rows of short status
  chips (`Stats.mod_short`), folding any overflow into a "+N" chip; the hover tooltip lists
  everything in full.
- **Presentation** (`combat_screen.gd`): the engine resolves a whole action instantly, so the
  screen freezes each unit's HUD (`UnitView.shown`, `_freeze`) and moves it only as each hit
  lands (`shift_hp`, `shift_fatigue`, `sync_status`). Popups stack per unit (`_popup_stack`);
  multi-hit moves play a sound per hit; area and party moves show all results at once,
  except dealt cards (Stacked Deck), which come one at a time.
- **Fading a unit**: call `UnitView.unpaper()` first. Its figure sits in a paper
  CanvasGroup, which draws as a grey box under Vulkan when faded through a parent's modulate.
- **Redraw cost**: figures breathe through their node scale and redraw only when their shapes
  change (pose, flash, animated creatures); HUDs redraw only when what they show changes.

## Screens and UI

- Screens (`scripts/screens/*.gd`) are `Control`s that build their whole layout in code in
  `setup()` using the `UI` helpers. There are no `.tscn` layouts to keep in sync.
- `Main` provides `modal(content)`, `dialog(title, text, buttons)`, `confirm`, `message` and
  `toast`. Right-click or Esc closes a closable modal.
- **Theme** (`scripts/ui/ui.gd`, `UI.theme()`): parchment panels, Rye headings, Alegreya
  text. Type variations: labels `Ink`, `Header`, `InkHeader`, `Bold`, `InkBold`, `InkRich`;
  panels `Dark` (wood planks), `DarkRopeTop`, `DarkRopeBottom`, `Inset` (a dark readable
  well for text on wood), `Card`, `Clear`; buttons `Big`, `Small`, `Tab`, `Danger`, `Good`
  (all drawn as wooden signboards).
- **`StyleBoxWood`** (`scripts/ui/wood_style.gd`) is a custom `StyleBox` that draws planks,
  grain, nails, iron brackets, rope and signboards with `RenderingServer` calls.
- Widgets: `HeroCard`, `FigureBox` (portrait), `StatBar`, `RankDots`, `SlotBox` (building
  slot), `InventoryGrid` (wagon slots), `HeroPicker`, `TopBar` (resources strip), `ResIcon`
  (resource, move-type and stat icons; see below). `UI.party_cards` draws the party with swap
  buttons for reordering between fights.
- Tooltips and number text come from `UI` too (`skill_tooltip`, `effect_text`,
  `hero_tooltip`...), so the numbers a player sees are computed from the same data the engine
  uses.

## Visuals (`scripts/visual/`)

- **`Figure`** draws every character and creature from a `look` dictionary (in
  `classes.json` and `enemies.json`): body, build, hat, coat, weapon, extras, colors, and for
  heroes a rolled outfit (`outfits`), skin and hair from the hero's look seed. Poses: `idle,
  windup, strike, aim, cast, hurt, dead`. Statics pick the approved look: `body_style = 4`
  (ink illustration) and `face_look = 6` (profile at rest, storybook reactions in action).
  Older styles stay in the code for side-by-side comparisons. Always pass polylines through
  `Figure.clean_line` (degenerate points crashed the GPU driver).
- **`Backdrop`** draws layered parallax scenery per region and mode (`trail, cave, camp,
  town`) from the region's `palette` and `props`, or shows a painted image instead (see
  below). `UnitView` is one combatant on the field (figure, HUD, target glow).
- **`MapView`** draws the expedition map as a parchment sheet: terrain sketches per region,
  curved trails, stop discs, fog over unscouted stops, the wagon token, legend and signpost.
- **`TownView`** draws the settlement street, one clickable building per plot. `WagonArt`,
  `Campfire`, `EventArt` (by an event's `art` field) and `CurioArt` (by a curio's `art`).
- **Paper look:** `PaperFX` wraps drawn nodes in a `CanvasGroup` with `paper.gdshader`
  (grain, fibres, relief edge, cast shadow, depth haze). On everywhere by default
  (`PaperFX.enabled`, the `paper` setting). `sky_wash.gdshader` and `vignette.gdshader` add
  the watercolour sky and the stage lighting.

### Painted art overrides

| What | File | Loaded by | Falls back to |
|---|---|---|---|
| Icons | `assets/art/icons/<key>.png` (256 px, transparent) | `ResIcon.art(key, px)`: cached, shrunk once per size | The drawn icon for that key |
| Backdrops | `assets/art/backdrops/<key>.png` or a numbered set `<key>_1.png`, `_2.png`... | `Backdrop._load_backdrop_image` | Drawn scenery |
| Town painting | `assets/art/town/<image>.png`, plus `town_art` spots in `settlements.json` | `TownView.set_art`: painted buildings become the plots, marked with name, CLOSED and VACANT boards | The drawn street |

- Icon keys are an item's `icon` field in `items.json` or a resource kind in `res_icon.gd`
  (`money, timber, iron, hides, charter, week, wagon, xp, eye, skull...`).
- Backdrop key order: an explicit `bg_key` (the title screen uses `title`), then the region's
  `backdrop` field, or `quest_backdrop` from config for a Saloon quest (outdoor scenes only),
  then `<region>_<mode>`. A numbered set is stepped through by map progress
  (`Backdrop.set_progress(run.map_progress())`) on the trail and in combat.
- `assets/art/backdrops/horizons.json` gives each image's skyline as a fraction down the image;
  `Backdrop.set_bg_horizon(y)` puts it at screen y (trail 300, combat and menu 430) so figures
  stand on ground and the UI does not hide the scenery.
- Originals go in `art-src/`; `tools/art/prep_icons.py` and `prep_backdrops.py` make the
  game-ready files. The workflow is in `COMFYUI_GUIDE.md`, the style rules in
  `ART_PIPELINE.md`.

## Audio

- Clips live flat in `assets/audio/`: generated `.wav` files from `tools/gen_audio.py` (weapons,
  impacts, tones, music, the UI click) and recorded CC0 `.ogg` variants built by
  `tools/import_sfx.py` (creatures, glass, chips, cards, cloth, paper). Sources and licences
  are in `assets/audio/CREDITS.md`.
- A skill's `sfx` field names a clip without its extension. Variants `name_1`, `name_2`... are
  picked at random.
- `tools/level_audio.py` (needs ffmpeg) measures every clip and writes `levels.json`, the
  per-clip gain the game applies so packs and generated sounds sit at one loudness (UI sounds
  quieter). Rerun it after adding sounds.

## Tests and tools

| Command | What |
|---|---|
| `tools/check.sh` | Imports the project and compiles every script; prints errors |
| `$G --headless --path . res://tests/test_runner.tscn` | The test suite (about 6700 checks: data cross-references, combat rules, every hero and enemy move, fatigue, maps, camp, caves, curios, quests, save round trips) plus a short simulated campaign. `-- sim=2` shortens the campaign |
| `... test_runner.tscn -- balance=40 weeks=6` | Balance report over many simulated campaigns (`tests/bot.gd` plays them) |
| `... test_runner.tscn -- simtut=50` | Plays the tutorial many times and reports win rate and health left |
| `$G --headless --path . -- shot=autoplay expeditions=3` | UI smoke test: `tests/autopilot.gd` clicks through the real screens |
| `tools/shot.sh <scenario> out.png [args]` | Screenshot under xvfb. Scenarios in `scripts/debug/shots.gd`: `menu, settlement, embark, trail, combat, camp, cave, event, curio, results, hero, building, tutorial, silas, lineup, faces, outfits`, plus A/B comparisons. Useful args: `full` (party of 4), `region=<id>`, `far` (end of map), `enemies=a,b`, `ehp=N`, `bones=N` (first N enemies fall, leaving bones), `act` (with `frames=N` to save frames while the move plays), `statuses`, `with=<class> skill=<id>`, `soak=N` (idle and print memory, objects and draw calls) |
| `python3 tools/fmt_events.py` | Re-formats `data/events.json` in its usual layout (one outcome per line, follow-ups indented); import `dump` from it when editing events by script |
| `python3 tools/hero_sheet.py` | Regenerates `docs/HERO_REVIEW.md` from the data |
| `python3 tools/enemy_sheet.py` | Regenerates `docs/ENEMY_REVIEW.md` |
| `python3 tools/hero_power.py` | Rough power model: every hero move scored against the average tier-1 enemy (balance aid) |
| `python3 tools/gen_audio.py [name]` | Regenerates generated sounds and music |
| `python3 tools/level_audio.py` | Re-measures loudness into `levels.json` |
| `python3 tools/art/prep_icons.py --dir art-src/icons` | Cuts out and sizes painted icons |
| `python3 tools/art/prep_backdrops.py` | Measures horizons for new backdrops (keeps hand-set ones) |

In the cloud container `G=/home/user/tools/godot/Godot_v4.7.2-stable_linux.x86_64`
(`tools/*.sh` default to it; override with `GODOT=`).

## Where to change what

| To change | Look in |
|---|---|
| A number (damage, costs, XP, odds) | `data/config.json`, or the entry in its table |
| A class, move, enemy, event, curio, quirk, trinket, item | `data/*.json` (`ADDING_CONTENT.md`) |
| A combat rule | `CombatEngine` (+ a test in `tests/run_tests.gd`) |
| Travel, camp, caves, curios, events | `RunState` |
| Town services, economy, the week | `Company` |
| How combat looks and paces | `combat_screen.gd`, `unit_view.gd` |
| A character's drawing | `figure.gd` and the `look` in the data |
| Panel, button or text style | `ui.gd` (theme) and `wood_style.gd` |
| The expedition map's look | `map_view.gd` |
| Scenery | `backdrop.gd`, `regions.json` palette and props, or a painted set |
| An icon | a painted PNG (`COMFYUI_GUIDE.md`) or the drawing in `res_icon.gd` |
| A sound | `tools/gen_audio.py` or `tools/import_sfx.py`, then `level_audio.py` |

## Gotchas

- GDScript: `var x := <Variant expression>` is a parse error; type it (`var x: int = ...`).
  Loop variables over untyped arrays are Variants. Don't name members after `Object`/`Node`
  properties (`script`, `name`). Lambdas capture locals by value: use a dictionary holder
  for anything assigned later.
- New art files need a Godot import before `ResourceLoader.exists` sees them: `tools/check.sh`
  or `$G --headless --path . --import` (the owner's `play.bat` imports on every launch).
  `.import` files are not committed.
- A save holds whole region dictionaries for Saloon quests, so a new region field does not
  reach quests already in a save; read such fields with a fallback (as `quest_backdrop` does).
- `run.current` and map lookups are node **indices** into `run.nodes`.
