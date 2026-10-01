# Frontier Expedition: working notes

Godot 4.7 / GDScript game inspired by Darkest Dungeon 1 & 2 with an Oregon Trail theme.
These notes are for any agent (or person) picking up work on it.

## Read first

| Doc | For |
|---|---|
| `docs/README.md` | Map of every doc |
| `docs/ARCHITECTURE.md` | How the code is wired: where everything lives, the game loop, combat events, art overrides, tests and tools |
| `docs/DESIGN_BRIEF.md` | Creative direction agreed with the owner. Read before changing design |
| `docs/GDD.md` | The systems as built |
| `docs/ADDING_CONTENT.md` | Every data field, for adding classes, moves, enemies, events, regions |
| `docs/PLAYTEST_NOTES.md` | The open backlog, then the history of what shipped each round |

## Architecture in brief

- **Data-driven.** Content and balance live in `data/*.json`, loaded by the `DB` autoload.
  Prefer adding content there over code. JSON numbers are normalized to ints when integral
  (`DB.normalize`). Keys starting with `_` are comments.
- **Rules are node-free** (`scripts/core/`): `CombatEngine` returns event dictionaries,
  `Company` holds the campaign, `RunState` holds an expedition. Screens only animate
  events and call these APIs. Keep it that way so the headless tests cover the rules.
- **Screens** (`scripts/screens/`) are built in code with the `UI` helpers; `Main` switches
  screens (`Main.inst.goto`) and shows modals (`modal`, `dialog`, `confirm`, `toast`).
- **Art is drawn in code** (`scripts/visual/`), with optional painted overrides: icons in
  `assets/art/icons/`, backdrops in `assets/art/backdrops/`. A missing file falls back to the
  drawing.

## GDScript gotchas (Godot 4.7)

- `var x := <expression involving a Variant>` is a *parse error*. Loop variables over
  untyped arrays and dictionary values are Variants. Use an explicit type: `var x: int = ...`.
- Don't name a member `script`, `name` or other `Object`/`Node` properties: `script` is
  a parse error ("Member redefined").
- Lambdas capture locals **by value**. To reference something assigned later (for example a
  modal wrapper, or a recursive lambda), capture a dictionary holder: `var holder := {"wrap": null}`.
- A parse error in `tests/run_tests.gd` (e.g. a duplicate local name) makes the test run hang
  rather than fail: if it doesn't finish in a minute, run `tools/check.sh`.
- Antialiased polylines with repeated points have crashed the GPU driver: pass every point
  list through `Figure.clean_line`.

## Workflow (owner's rules)

- The owner plays from source with `play.bat` (Godot 4.7.2 installed on their PC), after
  pulling `main`. `play_vulkan.bat` is the same with the Vulkan renderer (a crash test; the
  project default is OpenGL Compatibility, which the cloud container also renders with). Commit and push source changes to `main`; that is how they reach the game.
- Do **not** rebuild or commit `download/FrontierExpedition-windows.zip` for routine
  changes. Only refresh it for a major version, when the owner asks.
- More than one agent pushes to `main`: pull (`git pull --ff-only origin main`) before
  starting work and again before pushing. Never force-push.
- Keep checks quick: `tools/check.sh` plus the unit tests. Skip long autoplay runs unless
  asked; the owner playtests and reports back.

## Working with the owner

- **Playtest rounds.** The owner plays and sends numbered notes. When they ask to plan first,
  lay out the plan and wait. Record decisions and what shipped in `docs/PLAYTEST_NOTES.md`,
  and move open items to its backlog.
- **The owner keeps their save** (since round 7). Changes must load an existing
  `user://save.json`: read new fields with a default (`d.get("x", default)`), and remember
  that Saloon quest regions are stored whole in the save, so new region fields need a
  fallback. Test a save round trip for anything that touches `to_dict` / `from_dict`.
- **Art handoffs.** The owner makes icons and backdrops in ComfyUI and attaches them in chat.
  Save the originals to `art-src/icons/<key>.<ext>` or `art-src/backdrops/<set>_<n>.<ext>`,
  run the prep script, look at the result in game (`tools/shot.sh`), then commit both the
  original and the game-ready file. Details in `docs/COMFYUI_GUIDE.md`.
- **Show, don't describe, visual changes.** Take a screenshot (`tools/shot.sh`) and look at
  it before reporting a visual change as done.
- Heroes use they/them in all text; names are random and don't imply gender.

## Checks to run before committing

```bash
tools/check.sh                                                # import + compile all scripts
$GODOT --headless --path . res://tests/test_runner.tscn -- sim=2   # rules/data tests (~6700)
tools/shot.sh <scenario> /tmp/x.png [args]                    # look at it (xvfb)
# scenarios: menu settlement embark trail combat camp cave event curio results hero building
#   tutorial silas lineup faces outfits (see scripts/debug/shots.gd)
# args: full (party of 4), region=<id>, far (end of map), enemies=a,b, ehp=N, act,
#   statuses (load everyone with effects), with=<class> skill=<id> (watch a move),
#   soak=N (idle N seconds printing memory/object/draw counts, for leak and crash hunts)
$GODOT --headless --path . -- shot=autoplay expeditions=3     # UI smoke test (only when asked)
```
In the cloud dev container: `GODOT=/home/user/tools/godot/Godot_v4.7.2-stable_linux.x86_64`.
New images need an import before the game sees them (`tools/check.sh` does it).

## Releases

- Bump `config/version` in `project.godot`, commit, and tag `vX.Y`. Pushing a `v*` tag runs
  `.github/workflows/build.yml` (tests, Windows export, GitHub release).
- From the cloud container, tag pushes are refused (HTTP 403, policy). Say so and let the
  owner push the tag; don't retry. A large push can print a 403 and still land: check with
  `git fetch origin main` before retrying.

## Environment notes

- On Windows, pass `encoding='utf-8'` explicitly for file I/O in Python tools.
- Audio is generated or imported by scripts: edit `tools/gen_audio.py` or
  `tools/import_sfx.py` and rerun rather than hand-editing clips, then rerun
  `tools/level_audio.py` (needs ffmpeg).
- Dev tools: `Game.settings.dev_tools` (default on) shows a "DEV: Win" button in combat.
