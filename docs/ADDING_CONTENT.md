# Adding Content

Almost everything in Frontier Expedition is data in `data/*.json`. You can add a class, a
move, an enemy, an event, a curio, a quirk or a whole region without touching code. After
editing, run the tests (below): they cross-check every reference between files.

> Tip: keys starting with `_` (like `"_comment"`) are ignored. Use them for notes.

---

## Add a hero class

1. **`data/classes.json`**: add an entry:

```json
"snake_oil": {
  "name": "Snake Oil Salesman",
  "role": "Support",
  "desc": "Sells miracle tonics, and a few of them even work.",
  "hp": 23, "dodge": 10, "prot": 0, "speed": 4, "acc": 0, "crit": 6, "dmg": [4, 8],
  "res": {"stun": 30, "bleed": 30, "poison": 50, "move": 30, "debuff": 40, "deathblow": 67},
  "ranks": [2, 3],
  "skills": ["so_tonic", "so_pitch", "so_bottle", "so_smoke", "so_cure_all", "so_fast_talk"],
  "default_equipped": ["so_tonic", "so_pitch", "so_bottle", "so_smoke"],
  "look": {"body": "human", "build": "slim", "hat": "top", "coat": "frock", "weapon": "bag",
    "extra": "mustache", "colors": {"coat": "#6b2f4a", "pants": "#2b2b2b", "hat": "#1b1b1b", "accent": "#e2c044"}}
}
```

2. **`data/skills.json`**: add its six skills (see below).
3. Done. New recruits roll the class automatically at the Hiring Board.

**Stats.** `prot` is a percent. `dmg` is the weapon's damage range. `res` values are
percent resistances; `deathblow` is the Death's Door survival chance (default 67).

**Look options.** `build`: slim, normal, broad, heavy, tiny.
- `hat`: cowboy, cowboy_wide, stetson, stetson_black, coonskin, bowler, top, preacher,
  flat_cap, slouch, kepi, miner, none.
- `coat`: duster, long, frock, vest, shirt, buckskin, overalls, chaps.
- `weapon`: pistol, pistols, rifle, shotgun, axe, hammer, pickaxe, club, knife, cards,
  bible, lasso, bag, dynamite, fists.
- `extra`: badge, bandana, bandana_mask, mustache, spectacles, collar, lantern, dog.
- `beard`: true/false. `colors`: coat, pants, hat, accent, and optionally skin.

## Add or change a combat skill

In `data/skills.json`:

```json
"so_bottle": {
  "name": "Busted Bottle", "class": "snake_oil",
  "desc": "Smashes a tonic bottle over a head. Poisons.",
  "use_ranks": [1, 2, 3], "target": "enemy", "target_ranks": [1, 2],
  "acc": 88, "dmg": -0.3, "crit": 0,
  "anim": "throw", "sfx": "glass",
  "effects": [{"type": "poison", "amount": 3, "rounds": 3, "chance": 100}]
}
```

| Field | Meaning |
|---|---|
| `use_ranks` | Ranks the user must stand in (1 = front) |
| `target` | `enemy`, `ally`, `self`, or `party` (all allies) |
| `target_ranks` | Enemy (or ally) ranks it can reach |
| `aoe` | `true` hits every valid target |
| `hits` / `random_hits` | Several hits on one target / on random targets |
| `acc` | Base accuracy; hit chance = acc + attacker acc − target dodge (5–95%) |
| `dmg` | Damage modifier: `-0.5` means half weapon damage, `0.2` means +20% |
| `no_damage` | Pure utility (marks, debuffs...) |
| `vs_marked` / `low_hp_bonus` | Bonus damage vs Marked targets / when the user is below 50% HP |
| `vs_tags` | e.g. `{"mythic": 0.5}`: +50% damage vs mythic creatures |
| `gamble` | Double-or-nothing damage |
| `anim` | melee, shoot, throw, cast, buff, heal, dog |
| `sfx` | any file name in `assets/audio/` (without `.wav`) |

**Effects** (in `effects`, applied to targets on hit; `self_effects` apply to the user):
- `bleed` / `poison` `{amount, rounds, chance}`
- `stun {chance}`, `mark {rounds}`
- `debuff {stat, value, rounds, chance}`, `buff {stat, value, rounds}`
- `random_buff {pool: [{stat, value}], rounds}`
- `heal {min, max}`, `heal_pct {value}`, `fatigue {amount}` (negative relieves)
- `knockback {amount, chance}`, `pull {amount, chance}`
- `guard {rounds}`, `taunt {rounds}`
- `cure {kinds: ["bleed", "poison", "stun"]}`, `clear_shaken`
- Self-only: `move {amount}` (+ forward, − back), `summon {enemy}`, `light {amount}`

Stats usable in buffs and debuffs: `acc`, `dodge`, `prot`, `speed`, `crit`, `dmg_pct`,
`stun_res`, `bleed_res`, `poison_res`, `move_res`, `debuff_res`.

## Add an enemy

In `data/enemies.json`: stats as for classes, plus `tags` (used by quirks, keepsakes and
`vs_tags`), `skills` (ids in skills.json) and a `look`. Stats are the tier-1 baseline;
higher-tier regions scale them automatically. Set `"boss": true` to skip scaling.

Enemy skills use the same format, plus AI hints:
`"ai": {"weight": 3, "pref": "lowest_hp"}`. `pref` can be random, lowest_hp, marked,
back, front, or deaths_door.

Non-human looks: `body` can be wolf, bull, bear, ram, snake, lizard, flock, bird, bat,
harpy, ghost, swirl, crawler, or giant (with `eye`: one / two / glow, and `crown`).
Colors: `fur`, `belly`, `eye`. `scale` enlarges bosses.

Then add it to a region's `fights`, `elites` or `cave_fights` in `data/regions.json`.

## Add a trail event

In `data/events.json`, then list its id in a region's `events` (or `homestead_events`):

```json
"lost_oxen": {
  "title": "Lost Oxen", "art": "tracks",
  "text": "In the morning two of the oxen are gone. {hero} finds hoofprints leading north.",
  "options": [
    {"text": "Track them down.", "requires": {"skill": "tracker"}, "outcomes": [
      {"weight": 1, "good": true, "text": "{hero} brings them home by noon.", "effects": []}]},
    {"text": "Buy new oxen ($60).", "requires": {"money": 60}, "consume": {"money": 60}, "outcomes": [
      {"weight": 1, "text": "Expensive, but you're moving again.", "effects": []}]},
    {"text": "Push on shorthanded.", "outcomes": [
      {"weight": 1, "text": "The wagon crawls.", "effects": [{"type": "fatigue", "amount": 8, "target": "party"}]}]}
  ]
}
```

- `requires`: `item`, `money`, `skill` (a survival skill), `class`, `quirk`. Options whose
  skill, class or quirk nobody has are hidden. Item and money options appear greyed out.
- `consume`: `{"item": n}` or `{"money": n}`.
- `{hero}` becomes the hero who meets the requirement, or a random party member.

**Effects** (events, curios and camp): `fatigue`, `heal_pct`, `damage_pct`, `food`,
`money` (`amount`, or `min`/`max`), `money_pct`, `timber`, `iron`, `charters`,
`item {item, amount}`, `keepsake`, `quirk {quirk}` (an id, or random / random_positive /
random_negative), `remove_quirk`, `wagon`, `recruit {class}`,
`fight {enemies, surprise, reward}`, `buff {stat, value}` (next fight), `reveal {amount}`,
`light`, `clear_shaken`.
- `target`: party (default), actor, random.
- Any effect can have `chance`.

## Add a curio

In `data/curios.json`, then add its id to a region's `curios` or `cave_curios`:
- `hand`: weighted random outcomes when investigated by hand.
- `keys`: `{item_id: outcome}` gives a guaranteed result when that supply is used.
- `tags`: `whiskey`, `treasure` or `strange`, which trigger quirk compulsions.
- `art`: wagon, barrel, grave, strongbox, well, scarecrow, bush, skull, horse, stone, crate,
  pack, bones, pool, rubble, wall, vein, cairn.

## Add a quirk or keepsake

`data/quirks.json` / `data/keepsakes.json`: a list of `mods`:
`{"stat": "dmg_pct", "value": 15, "cond": "vs:beast"}`.
- Conditions: always, in_cave, on_trail, front, back, low_hp, vs:<tag>.
- Extra stats: `max_hp_pct`, `deathblow`, `fatigue_pct` (Fatigue taken), `heal_pct`
  (healing received), `resolve` (Second Wind chance), `scout`, `surprise`, `food_pct`,
  `loot_pct`.
- A quirk can add `"compulsion": {"tag": "whiskey", "chance": 50, "text": "..."}`.

## Add a survival skill

`data/survival.json`: a `passive` (types: food_pct, hunt_bonus, forage, scout, surprise,
wagon_guard, heal_pct, fatigue_pct, loot_pct, river_bonus, timber_bonus, iron_bonus) and
two camp `actions`.
- Each action has `hours`, a `target` (self / ally / party) and `effects`. Effects use
  `base` + `per_rank`.
- Camp-only effect types: `next_fight_buff`, `no_ambush`, `craft_parts`, `fatigue_self`.

## Add a region

`data/regions.json` sets the tier, palette, props, fights, elites, cave fights, boss,
crossing, events and curios. Then add a settlement site in `data/settlements.json` whose
`founded_at` is the region *before* it, and point the previous site's `region_west` at
the new region.

Optional region fields:
- `fixed_map`: a hand-authored map instead of a random one (see `old_mill_road`). It is a list
  of columns; each node has `type` plus its content (`enemies`, `event` or `curios`), and
  optionally `title`, `story` (a dialog shown on arrival) and `lane_y` (0–1). Each node
  links to every node in the next column. Mark it `"tutorial": true` to turn off mishaps.
- `boss_rewards`: overrides the boss payout (`money`, `charters`, `timber`, `iron`).
- `boss.first_script`: a scripted first meeting. Fields: `id` (story flag), `unit` (enemy
  id), `round`, `hp_pct`, `deaths_door` (triggers), `wound_pct` (the boss's starting health
  next time), `title` and `text` (the cutscene). Add `boss.intro_again` for the rematch.

- `side: true` makes a side adventure (listed by a settlement's `side_regions`); its boss is
  fought every time. `columns` sets the map length (default 9). `node_weights` overrides how
  often each stop type appears (`fight`, `elite`, `event`, `curio`, `cave`, `homestead`,
  `trading_post`). `side_reward` is paid on the first clear: `hero {class, level, name}`,
  `timber`, `iron`, `text`.
- `xp_cap`: the most XP a hero can earn from one run here (the tutorial uses 3).

Settlement fields for a start town: `start_buildings`, `start_ruins` (burned buildings
rebuilt at a discount), `tutorial` (region of the first expedition) and
`tutorial_rebuilds` (the ruin that winning it restores). Any settlement can list
`side_regions`.

Buildings can have upgrade `tracks` instead of plain levels (see the Hiring Board): each
track has `name`, `desc`, `values` (per track level) and `costs`. Code reads a track with
`Company.track_value(i, bid, track)`.

Survival (camp) actions take `unlock` (the skill rank that unlocks them) and `cost`
(supplies used, `{item: count}`). Items take `stack` (how many share one wagon slot); the
wagon has `wagon_slots` slots (config.json).

---

## Checking your work

```bash
tools/check.sh                                     # compile every script
godot --headless --path . res://tests/test_runner.tscn   # rules + data cross-checks
godot --headless --path . res://tests/test_runner.tscn -- balance=40 weeks=6   # balance sim
tools/shot.sh combat /tmp/c.png enemies=outlaw_brawler,prairie_wolf   # screenshot
```
