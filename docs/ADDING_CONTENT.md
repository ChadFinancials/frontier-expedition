# Adding Content

Almost everything in Frontier Expedition is data in `data/*.json`. You can add a class, a
move, an enemy, an event, a curio, a quirk, a region or a rumor without touching code. After
editing, run the tests (bottom of this page): they cross-check every reference between files.

> Keys starting with `_` (like `"_comment"`) are ignored. Use them for notes.
> Percent values are whole numbers (10 = 10%) unless a field says it's a fraction.

Contents: [classes](#add-a-hero-class) · [moves](#add-or-change-a-move) ·
[enemies](#add-an-enemy) · [events](#add-a-trail-event) · [curios](#add-a-curio) ·
[quirks and trinkets](#add-a-quirk-or-trinket) · [survival skills](#add-a-survival-skill) ·
[regions](#add-a-region) · [settlements](#settlements) · [rumors](#add-a-saloon-rumor-template) ·
[items](#items) · [buildings](#buildings) · [config](#config) · [art and sound](#art-and-sound)

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
  "look": {"body": "human", "build": "slim", "hat": "top", "coat": "frock", "weapon": "bag",
    "extra": "mustache", "colors": {"coat": "#6b2f4a", "pants": "#2b2b2b", "hat": "#1b1b1b", "accent": "#e2c044"},
    "outfits": [{"name": "Plum"}, {"name": "Bottle Green", "coat": "#2f4a33"}, {"name": "Soot", "coat": "#3a3634", "hat": "#2a2624"}]}
}
```

2. **`data/skills.json`**: add its moves (6 to 8; see below).
3. Done. New recruits roll the class automatically at the Hiring Board. Then regenerate the
   review sheet: `python3 tools/hero_sheet.py`.

**Stats.** `hp`, `dodge`, `speed`, `acc`, `crit` are flat; `prot` is a percent; `dmg` is the
weapon's damage range. `res` values are percent resistances; `deathblow` is the Death's Door
survival chance (default 67). `ranks` are the preferred ranks (shown to the player).

**Moves.** `skills` lists every move the class can learn. The first two are the **stock**
moves every new hero knows (config `stock_moves`); the hero also knows random others up to
`starting_moves` and learns the rest at the Drill Hall. `default_equipped` (optional) names the
moves equipped on a fresh hero.

**Matchups (optional).**
- `vs_tags`: `{"beast": {"dmg": 0.2, "acc": 2}}` gives +20% damage and +2 accuracy against
  enemies with that tag (the Mountain Mystic).
- `cave_loot_pct`: extra loot in caves while this class is in the party (the Prospector, 25).

**Look options** (`Figure`, `scripts/visual/figure.gd`):
- `build`: slim, normal, broad, heavy, tiny.
- `hat`: cowboy, cowboy_wide, stetson, stetson_black, coonskin, bowler, top, preacher,
  flat_cap, slouch, kepi, miner, none.
- `coat`: duster, long, frock, vest, shirt, buckskin, overalls, chaps.
- `weapon`: pistol, pistols, rifle, shotgun, axe, hammer, pickaxe, club, knife, cards,
  bible, lasso, bag, dynamite, fists.
- `extra`: badge, bandana, bandana_mask, mustache, spectacles, collar, lantern, dog.
- `beard`: true/false.
- `colors`: coat, pants, hat, accent, and optionally skin, `shirt` (shows under vests,
  overalls and open coats) and `band` (hat band; falls back to accent, so an outfit can change
  the band without recoloring the Marshal's badge).
- `outfits`: alternate colorings, colors only, no shape changes. A list of dicts, each with a
  `name` plus any of coat, pants, hat, shirt, accent, band laid over `colors`. The first is the
  class's own colors (`{"name": "..."}`). Each hero rolls one from its look seed; skin and
  hair roll separately. Keep them believable (a deep red Preacher, not a yellow one), and
  leave fixed details (badge, cross) alone. `tools/shot.sh outfits /tmp/o.png` shows them all.

## Add or change a move

In `data/skills.json` (hero and enemy moves share the file; enemy ids start with `e_`):

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
| `no_self` | An ally move that can't target the user |
| `aoe` | `true` hits every valid target |
| `aoe_groups` | With `aoe`: `[[1, 2], [3, 4]]` hits only the clicked target's group (Flash Powder) |
| `hits` / `random_hits` | Several hits on one target / on random targets |
| `random_targets` | Hits that many *different* random targets in `target_ranks` (Old Jeb's Cave-In: 2) |
| `acc` | Base accuracy; hit chance = acc + attacker acc − target dodge (5–95%). Hero moves carry +2 over the enemy baseline |
| `dmg` | Damage modifier on the weapon range: `-0.5` means half, `0.2` means +20% |
| `dmg_range` | `[lo, hi]`: the move's own damage instead of the weapon's |
| `no_damage` | Pure utility (marks, debuffs...) |
| `crit` | Crit modifier added to the user's crit |
| `vs_marked` / `low_hp_bonus` | Bonus damage vs Marked targets / when the user is below 50% HP |
| `vs_tags` | e.g. `{"mythic": 0.5}`: +50% damage vs mythic creatures |
| `self_poisoned_bonus` | Extra damage (fraction) while the user is poisoned (Bayou Poisoner) |
| `gamble` | Double-or-nothing damage |
| `on_kill` | Effects when it kills: `{"type": "money", "amount": 50}` pays a bounty; others apply to the user |
| `once_per_fight` | Usable once per battle |
| `momentum` | Momentum this move adds for a class with `"momentum": true` (Train Hopper) |
| `mega`, `spend_momentum` | The class's mega move (named by the class's `"mega"` field, not in its `skills`): usable only on a full gauge, which it empties |
| `ignore_prot_pct` | Ignores this % of the target's Protection (End of the Line: 50) |
| `transfuse_pct` | Heals the user's most wounded ally (lowest HP share, the user included) for this % of the damage dealt (Transfusion: 150) |
| `anim` | melee, shoot, throw, cast, buff, heal, dog |
| `sfx` | A clip name in `assets/audio/` without extension (`gunshot` plays `gunshot.wav` or a random `gunshot_N.ogg`) |

**Effects** (`effects` apply to each target on hit; `self_effects` apply to the user):
- `bleed` / `poison` `{amount, rounds, chance}`; poison can add `amount_if_self_poisoned`.
- `stun {chance}`, `mark {rounds}`, `clear_mark`
- `debuff {stat, value, rounds, chance}`, `buff {stat, value, rounds}`
- `random_buff {pool: [{stat, value}], rounds}`
- `heal {min, max}`, `heal_pct {value}`, `fatigue {amount}` (negative relieves)
- `knockback {amount, chance}`, `pull {amount, chance}`
- `guard {rounds}`, `taunt {rounds}`
- `cure {kinds: ["bleed", "poison", "stun", "debuff"]}`, `clear_shaken`
- `extend {rounds}`: the target's poisons, bleeds and debuffs last longer
- `dispel`: washes away every boon (helpful buff) on the target
- Any effect: `if_tag` (only lands on targets with that tag, e.g. `"mythic"`), `chance_vs`
  (`{tag: chance}` replaces the base chance against those targets). Debuffs: `refresh: true`
  makes a recast replace that move's earlier debuff instead of stacking.
- Self-only: `move {amount}` (+ forward, − back), `summon {enemy, count}`, `light {amount}`,
  `heal_self {amount}`, `heal_self_pct {value}`, `self_damage {amount}` (a blood price, never
  below 1 HP), `buff_kin {mods: [{stat, value}], rounds, stack}` (buffs living allies of the
  same enemy type, e.g. a wolf pack)

**Stats** usable in buffs, debuffs and all modifiers: `acc`, `dodge`, `prot`, `speed`, `crit`,
`dmg_pct`, `dmg_flat` (per hit), `pierce` (ignores that much protection), `max_hp_pct`,
`stun_res`, `bleed_res`, `poison_res`, `move_res`, `debuff_res`, `deathblow`, `vulnerable`
(+% damage taken from every source, damage over time included; apply it with `debuff` and a
positive value, e.g. `{"type": "debuff", "stat": "vulnerable", "value": 10, "rounds": 3}`).

## Add an enemy

In `data/enemies.json`: `name`, stats as for classes (`hp`, `dodge`, `prot`, `speed`, `acc`,
`crit`, `dmg`, `res`), `tags` (used by quirks, trinkets and matchups: `outlaw`, `human`,
`beast`, `mythic`, `reptile`, `cave`...), `skills` (ids in skills.json) and a `look`.
Optional: `title` (a nickname line for uniques and bosses), `elite: true`, `boss: true`
(skips tier scaling), `actions` (actions per round, default 1). Stats are the tier-1
baseline; higher-tier regions scale them (config `tier_*`).

Enemy moves use the same format, plus AI hints in `ai`:

| Field | Meaning |
|---|---|
| `weight` | How often it picks this move relative to its others |
| `pref` | Target preference: random, lowest_hp, marked, back, front, deaths_door |
| `pref_chance` | Percent of the time the preference applies (else random) |
| `once` | Only once per fight |
| `opener` | Always its first move, if usable |
| `low_hp_weight` / `low_hp` | Use this weight instead when the enemy is below `low_hp` (fraction, default 0.5) |

Non-human looks: `body` can be wolf, bull, bear, ram, snake, lizard, flock, bird, bat, harpy,
ghost, swirl, crawler, or giant (with `eye`: one / two / glow, and `crown`). Colors: `fur`,
`belly`, `eye`. `scale` enlarges bosses.

Then add it to a region's `fights`, `elites` or `cave_fights` (or a rumor template), and
regenerate the sheet: `python3 tools/enemy_sheet.py`.

## Add a trail event

In `data/events.json`, then list its id in a region's `events` (or `homestead_events`):

```json
"lost_oxen": {
  "title": "Lost Oxen", "art": "tracks",
  "text": "In the morning two of the oxen are gone. {hero} finds hoofprints leading north.",
  "options": [
    {"text": "Track them down.", "requires": {"skill": "tracker"}, "outcomes": [
      {"weight": 1, "good": true, "text": "{hero} brings them home by noon.", "effects": []}]},
    {"text": "Buy new oxen (60 chips).", "requires": {"money": 60}, "consume": {"money": 60}, "outcomes": [
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
- `art` picks the illustration drawn by `scripts/visual/event_art.gd`.

**Effects** (events, curios and camp; applied by `scripts/core/effects.gd`): `fatigue`,
`heal_pct`, `damage_pct`, `food`, `money` (`amount`, or `min`/`max`), `money_pct`, `timber`,
`iron`, `charters`, `item {item, amount}`, `keepsake` (optional `rarity` list),
`quirk {quirk}` (an id, or random / random_positive / random_negative), `remove_quirk`,
`wagon`, `recruit {class}`, `fight {enemies, surprise, reward}`, `buff {stat, value}` (next
fight), `reveal {amount}`, `light`, `clear_shaken`.
- `target`: party (default), actor, random.
- Any effect can have `chance`.

## Add a curio

In `data/curios.json`, then add its id to a region's `curios` or `cave_curios`:
- `hand`: weighted random outcomes when investigated by hand.
- `keys`: `{item_id: outcome}` gives a guaranteed result when that supply is used.
- `tags`: `whiskey`, `treasure` or `strange`, which trigger quirk compulsions.
- `art`: wagon, barrel, grave, strongbox, well, scarecrow, bush, skull, horse, stone, crate,
  pack, bones, pool, rubble, wall, vein, cairn (drawn by `scripts/visual/curio_art.gd`).

## Add a quirk or trinket

`data/quirks.json` / `data/keepsakes.json` (trinkets are called keepsakes in the data): a list
of `mods`: `{"stat": "dmg_pct", "value": 15, "cond": "vs:beast"}`.
- Conditions: always, in_cave, on_trail, front, back, low_hp, vs:<tag>, marked, vs_marked,
  vs_vulnerable, deaths_door, round1, guarding (Guarding or Taunting), poisoned.
- Extra stats beyond the combat ones: `fatigue_pct` (Fatigue taken), `heal_pct` (healing
  received), `heal_out_pct` (healing given), `resolve` (Second Wind chance), `scout`,
  `surprise`, `food_pct`, `loot_pct`, `xp_pct`, `vulnerable`, `stun_chance`, `poison_dot`,
  `momentum_start`, `momentum_bonus`, `card_pct` (Stacked Deck boons).
- A quirk can add `"compulsion": {"tag": "whiskey", "chance": 50, "text": "...", "steals":
  true}`, `bar_lock` (% chance of a week at the saloon after an expedition) and
  `after_battle_fatigue`.
- Trinkets take a `rarity` (common, uncommon, rare) and a `price`. A class trinket adds
  `"class": "<class id>"` (only that class can wear it; it drops at its rarity like any
  other trinket) and may add `"skill_mods": {"<move id>": {"dmg_pct": 15}}` with keys
  `dmg_pct`, `acc`, `crit`, `effect_chance`, `mark_rounds`, `dot`, `heal`, `heal_pct`, `move`.

## Add a survival skill

`data/survival.json`: a `passive` (types: food_pct, hunt_bonus, forage, scout, surprise,
wagon_guard, heal_pct, fatigue_pct, loot_pct, river_bonus, timber_bonus, iron_bonus) and camp
`actions`.
- Each action has `hours`, a `target` (self / ally / party) and `effects`. Effects use
  `base` + `per_rank`.
- `unlock`: the skill rank needed (a new hero has one action per skill; the second unlocks at
  rank 2). `cost`: supplies used (`{item: count}`).
- Camp-only effect types: `next_fight_buff`, `no_ambush`, `craft_parts`, `fatigue_self`.

## Add a region

`data/regions.json`. Core fields:

| Field | Meaning |
|---|---|
| `name`, `desc` | Shown on the expedition picker |
| `tier` | Enemy scaling and payouts (1-3) |
| `rec_level`, `difficulty` | Recommended hero level; difficulty 1-5 (Gentle to Deadly) for the hover text |
| `fights`, `elites`, `cave_fights` | Weighted enemy groups, front rank first |
| `boss` | `name`, `landmark`, `intro`, `victory`, `enemies` |
| `crossing` | The elite fight at the map's end once the boss is beaten |
| `events`, `homestead_events`, `curios`, `cave_curios` | Content pools |
| `palette`, `props` | Colors and props for the code-drawn scenery |
| `cave_name` | What its caves are called |
| `backdrop` | Use this painted backdrop set outdoors (see Art and sound) |
| `max_caves` | Overrides config `max_caves` |

Then add a settlement whose `founded_at` is the region *before* it, and point the previous
settlement's `region_west` at the new region.

Optional:
- `fixed_map`: a hand-authored map instead of a random one (see `old_mill_road`). A list of
  columns; each node has `type` plus its content (`enemies`, `event` or `curios`), and
  optionally `title`, `story` (a dialog on arrival) and `lane_y` (0–1). Each node links to
  every node in the next column. Mark the region `"tutorial": true` to turn off mishaps.
- `no_ambush`: no surprise either way.
- `boss_rewards`: overrides the boss payout (`money`, `charters`, `timber`, `iron`).
- `boss.first_script`: a scripted first meeting: `id` (story flag), `unit` (enemy id),
  `round`, `hp_pct`, `deaths_door` (triggers), `wound_pct` (the boss's health next time),
  `title` and `text` (the cutscene). Add `boss.intro_again` for the rematch.
- `side: true` makes a side adventure (listed by a settlement's `side_regions`); its boss is
  fought every time. `story: true` makes it a one-time story adventure. `columns` sets the map
  length (default 12). `node_weights` overrides how often each stop type appears (`fight`,
  `elite`, `event`, `curio`, `cave`, `homestead`, `trading_post`). `side_reward` is paid on the
  first clear: `hero {class, level, name}`, `timber`, `iron`, `text`, or `"rescue": true` for
  the missing company member (config `start_missing`; `{name}` in the text).
- `xp_cap`: the most XP a hero can earn from one run here (the tutorial uses 3).

## Settlements

`data/settlements.json`: `index` (position on the chain, east to west), `name`, `desc`,
`founded_at` (the region whose boss unlocks it), `region_west`, and optionally `side_regions`
and `victory` (the end-of-trail text). `town_art` gives the settlement a town painting whose
painted buildings serve as its plots: `image` (a file in `assets/art/town/`, no extension),
`spots` (one `[x, y, w, h]` box per painted building, in the image's pixels, most prominent
first; empty lots take the first free ones) and `prefer` (`{building id: spot index}` for the
spot that suits each building). Without it, or until the image exists, the town is drawn. The start town also takes `start_tier`,
`start_buildings`, `start_ruins` (burned buildings to rebuild), `tutorial` (region of the first
expedition) and `tutorial_rebuilds` (the ruin that winning it restores).

## Add a Saloon rumor template

`data/quests.json` holds the Saloon's rumor pool. Each template has `name` and `desc`
(`{place}` is filled in from `places`), `node_weights`, `fights`, `elites`, `final` (the last
fight when there's no boss), `boss` (`name`, `intro`, `victory`, `enemies`), and optionally
`always_boss`, `difficulty`, `done_flag` (a story flag set when won; the rumor stops
appearing) and `boss_keepsake`. `chances` sets the odds of a boss, a trinket and a recruit per
Loose Lips level. Rumors borrow scenery, events and curios from the settlement's western
region, scale to its tier, and use the painted set in config `quest_backdrop`.

## Items

`data/items.json`: `name`, `desc`, `price`, `icon` (the icon key, see Art and sound), `stack`
(how many share one wagon slot), `store_level` (the General Store level that sells it; 99 =
never sold), `use` (what using it on the trail or in combat does), `cargo: true` for building
materials that take wagon space, `retired: true` for an item kept only so old saves load (the
Crowbar). The wagon has `wagon_slots` slots.

## Buildings

`data/buildings.json`: `name`, `desc`, `art`, `order`, per-level `costs`, and per-level lists
such as `slots`, `seats` (Stage Line), `max_tier` (Smithy), `max_skill` (Drill Hall),
`discount` and `keepsake_stock` (General Store). `activities` (`cost`, `relief`,
`side_effects`) are what heroes do in a slot. A building can have upgrade `tracks` instead of
plain levels (the Hiring Board, the Saloon): each track has `name`, `desc`, `values` (per
track level) and `costs`. Code reads a track with `Company.track_value(i, bid, track)`.

## Config

`data/config.json` holds every global number (see `_note` there and the bracketed names in
`GDD.md`): starting resources and heroes, levelling, damage multipliers, Fatigue, food and
camp, surprise and caves (`light_levels`), quirk odds, loot, settlement tiers, costs, mishaps.
Switches: `hero_ambush` (enemies can surprise the party; off for now), `quest_backdrop`.
Tuning dials (see `_dials` there): `hero_dmg_mult` (all hero damage), `heal_mult` (heals with a
min-max range), `enemy_dmg_mult` (enemy weapon damage). Hero numbers in the data are the
numbers that play, so their dials sit at 1.0; turn a dial to scale a whole group at once.

## Art and sound

- **Icons**: an item's `icon` key (or a resource key in `scripts/ui/res_icon.gd`) is drawn in
  code unless `assets/art/icons/<key>.png` exists. See `COMFYUI_GUIDE.md` §5.
- **Backdrops**: a region is drawn from its `palette` and `props` unless a painted set exists
  (`backdrop` field, or `<region>_<mode>.png`). See `COMFYUI_GUIDE.md` §7 and
  `ARCHITECTURE.md`.
- **Sounds**: a move's `sfx` names a clip in `assets/audio/`. New clips come from
  `tools/gen_audio.py` or `tools/import_sfx.py`; then run `tools/level_audio.py`.

---

## Checking your work

```bash
tools/check.sh                                            # compile every script
godot --headless --path . res://tests/test_runner.tscn    # rules + data cross-checks
godot --headless --path . res://tests/test_runner.tscn -- balance=40 weeks=6   # balance sim
tools/shot.sh combat /tmp/c.png enemies=outlaw_brawler,prairie_wolf full       # screenshot
python3 tools/hero_sheet.py && python3 tools/enemy_sheet.py                   # review sheets
```
