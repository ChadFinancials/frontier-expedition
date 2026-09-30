# Frontier Expedition: working notes

Godot 4.7 / GDScript game inspired by Darkest Dungeon 1 & 2 with an Oregon Trail theme.
Read `docs/DESIGN_BRIEF.md` (creative direction agreed with the owner) before changing design.

## Architecture

- **Data-driven.** Content and balance live in `data/*.json`, loaded by the `DB` autoload.
  Prefer adding content there over code. `docs/ADDING_CONTENT.md` documents every field.
  JSON numbers are normalized to ints when integral (`DB.normalize`).
- **Rules are node-free** (`scripts/core/`): `CombatEngine` returns event dictionaries,
  `Company` holds the campaign, `RunState` holds an expedition. Screens only animate
  events and call these APIs. Keep it that way so the headless tests cover the rules.
- **Screens** (`scripts/screens/`) are built in code with the `UI` helpers; `Main` switches
  screens (`Main.inst.goto`) and shows modals (`modal`, `dialog`, `confirm`, `toast`).
- **Art is drawn in code** (`scripts/visual/`): `Figure` renders characters from a `look` dict.

## GDScript gotchas (Godot 4.7)

- `var x := <expression involving a Variant>` is a *parse error*. Loop variables over
  untyped arrays and dictionary values are Variants. Use an explicit type: `var x: int = ...`.
- Don't name a member `script`, `name` or other `Object`/`Node` properties: `script` is
  a parse error ("Member redefined").
- Lambdas capture locals **by value**. To reference something assigned later (for example a
  modal wrapper, or a recursive lambda), capture a dictionary holder: `var holder := {"wrap": null}`.

## Workflow (owner's rules)

- The owner plays from source with `play.bat` (Godot 4.7.2 installed on their PC), after
  pulling `main`. Commit and push source changes to `main`; that is how they reach the game.
- Do **not** rebuild or commit `download/FrontierExpedition-windows.zip` for routine
  changes. Only refresh it for a major version, when the owner asks.
- More than one agent pushes to `main`: pull (`git pull --ff-only origin main`) before
  starting work and again before pushing. Never force-push.
- Keep checks quick: `tools/check.sh` plus the unit tests. Skip long autoplay runs unless
  asked; the owner playtests and reports back.

## Checks to run before committing

```bash
tools/check.sh                                          # compile all scripts
$GODOT --headless --path . res://tests/test_runner.tscn # rules/data tests
$GODOT --headless --path . -- shot=autoplay expeditions=3   # UI smoke test
tools/shot.sh <scene> /tmp/x.png                        # look at it (xvfb)
# scenes: menu settlement embark trail combat camp cave event curio results hero building
#         tutorial silas lineup  (see scripts/debug/shots.gd)
```
In the cloud dev container: `GODOT=/home/user/tools/godot/Godot_v4.7.2-stable_linux.x86_64`.

## Environment notes

- On Windows, pass `encoding='utf-8'` explicitly for file I/O in Python tools.
- Audio is generated: edit `tools/gen_audio.py` and rerun rather than hand-editing WAVs.
- Heroes use they/them in all text; names are random and don't imply gender.

## Art: paper-theater look (pilot)

- `scripts/visual/paper_fx.gd` + `paper.gdshader`: wrap drawn nodes in a CanvasGroup with the
  paper material (grain, fibers, papier-mache relief, cast shadow, depth haze/blur).
- `Backdrop.paper = true` builds layered paper sheets, a watercolor sky and hanging sun/clouds.
- `Figure.crafted = true` adds sculpted shading, hatching and storybook proportions.
- `PaperFX.enabled` turns it on everywhere (approved by the owner). `PaperFX.stage(parent)`
  gives a paper group for drawn nodes; `PaperFX.framed(control, size)` wraps drawn Controls
  (curio and event art) so they can sit in containers. `TownView.paper` draws the layered
  street; `EventArt` draws event illustrations by the event's `art` field.
- Dev tools: `Game.settings.dev_tools` (default on) shows a "DEV: Win" button in combat.
