# Docs

| Doc | What it's for | Kept current by |
|---|---|---|
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | How the code is wired: directory map, autoloads, core rules, the campaign loop, combat events, screens and theme, drawn art and painted overrides, audio, tests and tools, where to change what | Update when structure changes |
| [`DESIGN_BRIEF.md`](DESIGN_BRIEF.md) | The creative direction agreed with the owner before the build | Owner decisions only |
| [`GDD.md`](GDD.md) | The game's systems as built, with the key numbers and the config keys that hold them | Update with rule changes |
| [`ADDING_CONTENT.md`](ADDING_CONTENT.md) | Every data field: classes, moves, enemies, events, curios, quirks, regions, quests, items | Update with new fields |
| [`PLAYTEST_NOTES.md`](PLAYTEST_NOTES.md) | The open backlog, then each playtest round's notes and what shipped | Every round |
| [`ART_PIPELINE.md`](ART_PIPELINE.md) | The approved look (drawn and painted), style rules, what works and what doesn't | Owner art decisions |
| [`COMFYUI_GUIDE.md`](COMFYUI_GUIDE.md) | The owner's hands-on ComfyUI guide, and the path from an image to the game (icons, backdrops) | With the art workflow |
| [`CONTENT_AUDIT.md`](CONTENT_AUDIT.md) | Which systems have had real passes and which are still first-draft (quirks, trinkets, curios, events...), with a recommended order | Before a content pass |
| [`QUIRK_PROPOSALS.md`](QUIRK_PROPOSALS.md) | Every quirk with a proposed edit, plus 10 new ones, awaiting the owner's picks | Until picked and built |
| [`TRINKET_PROPOSALS.md`](TRINKET_PROPOSALS.md) | Two class trinkets per class plus the general trinkets with edits, awaiting the owner's picks | Until picked and built |
| [`CURIO_PROPOSALS.md`](CURIO_PROPOSALS.md) | Every curio with its odds and its class and survival-skill experts; the first region's are built | Until the later regions' curios are built |
| [`MINIGAME_PROPOSALS.md`](MINIGAME_PROPOSALS.md) | Hands-on moments: the two-part High Noon duel (reaction, then a swinging aim bar) and four skill-check games for curios, made easier or harder by ★/✗. Awaiting the owner's picks | Until picked and built |
| [`EVENT_PROPOSALS.md`](EVENT_PROPOSALS.md) | Event pools (common, region, side-quest theme), ★/✗ experts on event options, quirk compels, follow-ups, every first-region event reworked plus 12 new; built in two passes. The pre-pass events are in an appendix | Until the later regions' events are done |
| [`FATIGUE_PROPOSALS.md`](FATIGUE_PROPOSALS.md) | Breaking Points and True Grit: the renames away from Darkest Dungeon's terms and a mechanic hook for each; built with the owner's edits | Can be archived |
| [`HERO_PROPOSALS.md`](HERO_PROPOSALS.md) | Options awaiting the owner's picks: new moves for the classes under 8, and two new hero designs | Until picked and built |
| [`HERO_REVIEW.md`](HERO_REVIEW.md) | Every class and move with real numbers. **Generated**: `python3 tools/hero_sheet.py` | Regenerate after hero changes |
| [`ENEMY_REVIEW.md`](ENEMY_REVIEW.md) | Every enemy and move with real numbers. **Generated**: `python3 tools/enemy_sheet.py` | Regenerate after enemy changes |
| [`RESEARCH.md`](RESEARCH.md) | How Darkest Dungeon 1 and 2 work, and what this game takes from them | Reference, rarely changes |
| [`archive/`](archive/) | Superseded notes kept for their lessons (the September ComfyUI experiments) | Not maintained |

Elsewhere: [`../CLAUDE.md`](../CLAUDE.md) (working rules for agents),
[`../README.md`](../README.md) (overview and how to play),
[`../assets/audio/CREDITS.md`](../assets/audio/CREDITS.md) (sound sources and licences).
