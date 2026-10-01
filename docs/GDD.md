# Frontier Expedition: Game Design Document

The systems as built. Creative direction lives in `DESIGN_BRIEF.md`, how the code is wired in
`ARCHITECTURE.md`, how to add content in `ADDING_CONTENT.md`. Tunable numbers live in
`data/config.json` (named in brackets, e.g. `[surprise_base]`) or in the content tables; when
this document and the data disagree, the data wins.

---

## 1. Premise

It's the age of the westward trail. You lead a pioneer company out of **Fort Providence**,
the last real town on the edge of the known map, burned by Silas Crane's gang. West of it the
land gets older and stranger: first outlaws, wolves and crows, then canyon things that
shouldn't exist, then mountains where giants walk. Each region is held by something dangerous.
Beat it and you can raise a settlement on its ground, and the frontier moves west.

The goal is the **Great Casino**, the paradise city at the end of the trail whose **chips**
are the frontier's currency. The game continues after you reach it.

Current focus: the first region (Fort Providence, the tutorial, the Tallgrass Sea, its side
adventures and Saloon rumors) is being playtested and tuned. The Red Canyons and Thunder Peaks
exist but wait until the start is crisp.

---

## 2. The two loops

```
┌───────────── SETTLEMENT (weeks) ─────────────┐        ┌──────── EXPEDITION (days) ────────┐
│ recruit · recover · train · build · supply   │ ─────▶ │ trail map → fights, events,       │
│ move heroes along the stage line             │ ◀───── │ curios, camps, caves → boss       │
└──────────────────────────────────────────────┘        └───────────────────────────────────┘
```

- One expedition = one **week**. Buildings, stage-line travel, recruits and rumors run on weeks.
- An expedition departs from a settlement with up to four heroes stationed there, into the
  region to its **west**, one of its side adventures, or one of this week's Saloon rumors.

---

## 3. Settlements

### Geography
| # | Settlement (founded at) | Region to its west | Region boss |
|---|---|---|---|
| 0 | Fort Providence (start, a burned Town) | The Tallgrass Sea | Silas Crane and the Crows |
| 1 | Redwater Ford (the Tallgrass Sea) | The Red Canyons | The Cyclops of Deadeye Mesa |
| 2 | Cloudbreak (the Red Canyons) | The Thunder Peaks | The Titan of the Pass |
| 3 | The Great Casino (the Thunder Peaks) | *(the end of the trail)* | — |

### Tiers `[tiers, found_cost]`
| Tier | Building slots | Max building level | Cost |
|---|---|---|---|
| Outpost | 3 | 1 | Founding: 1 Charter, 600 chips, 15 Timber, 8 Iron |
| Town | 6 | 2 | 3 Charters, 2000 chips, 40 Timber, 25 Iron |
| City | 9 | 3 | 6 Charters, 5000 chips, 90 Timber, 60 Iron |

- **Founding** needs that region's boss beaten. A new outpost starts with a free Stage Line.
- **Fort Providence** starts as a Town that Silas Crane burned: only the **Hiring Board**
  stands; the Saloon, General Store and Smithy are **ruins** that keep their plots and rebuild
  at `[ruin_rebuild_pct]` (100%) of the level-1 cost.
- Company size: `[roster_per_tier]` (Outpost 4, Town 6, City 9), plus the Hiring Board's
  Bunkhouse track; hard cap `[roster_cap]`.

### Buildings (`data/buildings.json`)
| Building | Does | Scales with level |
|---|---|---|
| **Saloon** | Fatigue relief (Belly Up to the Bar, may add the Drinker quirk; Card Table, may win or lose chips). Rolls the week's **rumors** (side quests) | Tracks: Chatter (1-3 rumors a week), Loose Lips (better rumor rewards) |
| **Chapel** | Fatigue relief (Quiet Prayer; Hymn Singing, may add a positive quirk) | Slots, relief |
| **Doctor's Office** | Remove a negative quirk; cure a Breaking Point | Slots, cost |
| **Smithy** | Weapon and armor tiers | Max tier 2 / 4 / 5 |
| **Drill Hall** | Learn new moves (`[learn_cost]` 300) and train move levels | Max move level 2 / 4 / 5 |
| **General Store** | Sells supplies (curio keys from level 2) and a few trinkets | Discount, trinket stock |
| **Hiring Board** | New recruits each week | Tracks: More Notices (count), Word of Mouth (level and quirks), Bunkhouse (company size) |
| **Stage Line** | Sends heroes between settlements, one week per stop | Seats |
| **Boot Hill** | Remembers the dead; visiting heroes shed Fatigue | Slots |

- A hero treated at the Saloon, Chapel, Doctor or Boot Hill sits out the next expedition.
- Heroes come home at full HP, with Shaken cleared. Fatigue, quirks and Breaking Points come
  home with them.
- Without a General Store the wagon leaves with a free kit `[free_kit]` and nothing is sold.
- If chips fall below `[grubstake_floor]` (150) at the week's end, a Casino agent tops them up.

### The start `[start_*]`
- 750 chips, 4 Timber, 1 Iron. The company is the Marshal and the Gunslinger. The Preacher
  waits on the Hiring Board (`start_promised`); a Bayou Poisoner is missing
  (`start_missing`) and is rescued in the Dry Gulch Mine story adventure.

### The tutorial: the Old Mill Road
- A new game offers the tutorial (or skips straight to the same post-tutorial setup). The
  Marshal and Gunslinger ride it alone on a hand-authored map (`fixed_map`): a fight, a choice
  of event or curios, a camp, then the mini-boss **Crowbar Pete** (Mulligan's second) at the
  old mill. Each stop shows a story beat with one tip. Tutorial-only weak enemies, no
  mishaps, no ambushes, XP capped at 3 (`xp_cap`).
- Winning rebuilds the **Saloon** for free and opens the Tallgrass Sea.

### Side adventures and rumors
- **Story side adventures** from Fort Providence (`side_regions`): **Dry Gulch Mine** (caves,
  tommyknockers, mini-boss Old Jeb; the first clear rescues the missing hero) and **The Crow's
  Nest** (many fights, mini-boss Ruby Blackwing; pays the Blackwing Feather). 8 columns, a
  mini-boss every time, done once.
- **Saloon rumors** (`data/quests.json`): each week the Saloon offers random short quests
  (7 columns) from a template pool: Mad Dog's Hideout (always ends at "Mad Dog" Mulligan, jumps
  the queue until beaten, pays Brass Knuckles), rustlers, a wolf den, a haunted homestead,
  claim jumpers, a snake gulch, Crane's scouts. Each has a chance of a boss, a trinket and a
  recruit that rises with Loose Lips (`chances`). They borrow the western region's scenery,
  events and curios and scale to its tier. They are the main early source of chips, Timber
  and Iron, and the place to train.

### Scripted boss meetings
- A boss can carry a `first_script`: the first fight stops when a round is reached, a hero
  hits Death's Door, or the boss drops below a health share. A cutscene plays and the run
  ends as **Driven Back** (loot and XP kept). Next time the boss starts **wounded** with a new
  intro. Silas Crane uses it (*Crane's Gambit*: round 3, a hero on Death's Door, or Silas
  under 60%; he returns at 85%).

---

## 4. Heroes

- **Class**: stats, 6-8 moves, preferred ranks. A new hero knows the class's two stock moves
  plus two random others `[starting_moves, stock_moves]`, learns the rest at the Drill Hall,
  and equips 4.
- **Look**: each class has three color **outfits**; a hero rolls one, plus skin and hair.
- **Level** 1-5 from XP at `[xp_levels]` 15 / 45 / 90 / 150. XP: 1 per stop, 2 per elite,
  5 per boss. Each level above 1: +12% max HP, +5% damage, +3 accuracy, +1% crit
  `[level_*]`. Level caps gear and move levels.
- **Gear**: weapon and armor tiers 1-5 (Smithy; a tier needs that hero level). Weapon +12%
  damage per tier; armor +8% max HP and +2 dodge per tier.
- **Move level** 1-5 (Drill Hall; at most one above the hero's level): +4 accuracy, +8%
  damage, +6% effect chance, +15% healing and damage over time per level `[skill_level_*]`.
- **Survival skills**: two per hero, rank 1-3, ranking up with use. Each gives a party
  passive and camp actions (one at rank 1, a second at rank 2).
- **Quirks**: up to 4 positive and 4 negative. **Trinkets** (data: keepsakes): two slots.
- **Fatigue** 0-200, possibly with a **Breaking Point** or **Second Wind**.
- Class matchups: a class can carry `vs_tags` (the Mountain Mystic gets +20% damage and +2
  accuracy against beasts) or `cave_loot_pct` (the Prospector finds +25% loot in caves).

### The 10 classes
| Class | Role | Ranks | Signature moves |
|---|---|---|---|
| Marshal | Protector | 1-2 | Hold the Line, Flash the Badge, Serve a Warrant, Weighted Shot |
| Mountain Mystic | Mystic bruiser | 1-2 | Gnarl at the Flesh, Take a Piece of Me (blood price), Bear Trap; strong against beasts |
| Rail Driver | Displacer | 1-2 | Hammerfell, Line Breaker, Sledge Toss, Hammered Rhythm |
| Gunslinger | Striker | 1-3 | Quick Draw, Fan the Hammer, Twin Shots, Called Shot |
| Wrangler | Controller | 2-3 | Sic 'Em (Biscuit the dog), Lasso, Hogtie, Round 'Em Up |
| Gambler | Wildcard | 2-3 | ALL IN, Stacked Deck, Money Shot, Lotto Ticket |
| Prospector | Demolitions | 2-4 | Dynamite Toss, Flash Powder, Raise the Lamp, Depth Charge; better cave loot |
| Bayou Poisoner | Poisoner | 3-4 | Poison Darts, Gas Cloud, Blighted Sacrament, Sticky Frog |
| Frontier Doctor | Medic / poisoner | 3-4 | Battlefield Surgery, Smelling Salts, Flask of Vileness, Chloroform Rag |
| Preacher | Healer | 3-4 | Laying On of Hands, Revival Meeting, Sermon on the Trail, Righteous Smite |

Every move with its numbers: `HERO_REVIEW.md` (generated from the data).

---

## 5. Combat

### Rules
- Four ranks per side. Every move lists the ranks it is **used from** and the ranks it can
  **target**. An AoE move hits every listed rank; some hit several random targets.
- **Turn order**: Speed plus a roll of 1-3 `[initiative_roll]` each round, highest first;
  ties are a coin flip. One action per unit per round (some enemies get more via `actions`,
  taken after everyone's first). A gold diamond beside a unit's bars marks each action left.
- **Hit chance** = move accuracy + attacker accuracy − target dodge, clamped to 5-95% and
  always shown. Ally moves always hit.
- **Crit chance** = attacker crit + move crit. Crits deal ×1.5 `[crit_mult]` and relieve the
  crit-er's Fatigue (below).
- **Damage** = roll(weapon range, or the move's own range) × (1 + move modifier + buffs +
  matchups) × (crit) × (1 − protection), minimum 1. Bleed and poison ignore protection.
  Armor Piercing ignores some protection.
- **Tuning dials** (config): `hero_dmg_mult` scales all hero damage, `heal_mult` all
  ranged heals, `enemy_dmg_mult` enemy weapon damage. Hero damage and heals are written in the
  data exactly as they play, so those two dials sit at 1.0; enemies' sits at 0.9.
- **Effect chance** = effect base + move level bonus − target resistance, clamped 0-95%.
  A failed effect shows "Resisted Stun" (or whichever).
- **Vulnerable** (`vulnerable` stat): the unit takes +X% damage from everything, damage over
  time included. **Mark** is different: enemies focus the marked hero, and some moves deal
  big bonus damage to marked targets. Vulnerable is the small across-the-board amp, Mark the
  big single-target one. A move doesn't do both (no double dip). At 10% on Hogtie and a few
  enemy moves (crows, gila monster, the Cyclops' sweep).
- **Statuses**: bleed and poison (damage per round), stun (skip a turn, then +50% stun
  resist for a round), mark, guard, taunt, buffs and debuffs (accuracy, dodge, protection,
  damage, crit, speed, resistances), knockback and pull, summons. Durations show on units.
- **Actions**: a move, **Swap** with an adjacent ally, or **Pass**. **Retreat** from any
  non-boss fight: +12 Fatigue each `[retreat_fatigue]`, no loot.
- **Surprise** `[surprise_base]` 10%: the party can catch enemies off guard (they act last in
  round 1). Enemies surprising the party is **switched off** for now `[hero_ambush: false]`
  (owner, round 7); it may return tied to the wagon.
- Enemy tiers scale HP, damage, accuracy, dodge, resistances and effect chance per region
  tier `[tier_*]`. Bosses are not scaled.

### Death's Door
- A hero at 0 HP enters **Death's Door**. Further damage (bleed and poison too) triggers a
  **Deathblow check**: 67% to survive, capped at 87% `[deathblow_base, deathblow_cap]`. The
  hit that knocks a hero onto Death's Door, and the rest of that same move, can't kill.
- Healing lifts them out with **Shaken** (−10% damage, −5 accuracy, −2 speed) for the rest of
  the expedition, unless a Medic's Set the Bone treats it. Death's Door carries between fights
  until healed, with a warning.
- Enemies die at 0 HP and the survivors step forward.

### Enemy AI
- Each enemy move has a weight and a target preference (`random`, `lowest_hp`, `marked`,
  `back`, `front`, `deaths_door`). Taunt forces the target; guard redirects it. Enemies
  favour Marked heroes. Some moves are openers, once-per-fight, or low-HP priorities, and
  out-of-position enemies reposition.

---

## 6. Fatigue

| Event | Fatigue |
|---|---|
| Enemy fatigue attacks | +5 to +15 |
| Receiving a crit | +8 `[crit_taken_fatigue]` |
| An ally hits Death's Door | +6 to the rest of the party |
| An ally dies | +15 to the rest of the party |
| A move with too little food | +10 and 10% HP `[hunger_*]` |
| A move with a broken wagon | +6 |
| A cave room | +1 to +6 by lamplight |
| Landing a crit | −4 self, −2 the others |
| Camp, events, the Preacher and some moves | relief |

- **At 100** a hero takes a **Resolve Test**: 25% (+2% per level, plus quirks) for a **Second
  Wind** (Fatigue drops to 45), otherwise a **Breaking Point**.
- **Breaking Points** (Homesick, Reckless, Short-Tempered, Cowardly, Greedy, Paranoid) change
  stats, and each turn there's a 30% chance the hero **acts out** (passes, uses a random move,
  moves, barks at an ally, refuses a heal). Clears at 25 Fatigue or with treatment in town.
- **Second Winds** (Steadfast, Inspired, Sharp-Eyed, Grit, Fired Up) boost stats and may heal,
  relieve or buff at the start of the hero's turn. They last until the expedition ends.
- **At 200**: **Collapse**. The hero drops to Death's Door (or dies if already there);
  Fatigue resets to 150.

---

## 7. Expeditions

### Map (`MapGen`)
- A branching node graph running east to west: **12 columns** on a main trail, 8 on a story
  side adventure, 7 on a rumor. Each node links to 1-2 nodes in the next column.
- The last column is the **boss** (a **Crossing** elite once the boss is beaten; a rumor's
  own final fight when it rolled no boss). On a main trail the column before it is a **Camp**
  and another camp sits mid-trail. At most `[max_caves]` 2 caves per map.
- **Stops**: Fight, Elite, Event, Curio, Cave, Trading Post, Homestead, Camp, Boss. After a
  fight there's a 30% chance (elites 50%) of a curio to search `[fight_curio_chance]`.
- **Intel**: a stop is unknown (?), roughly read (red ? trouble, green ? quiet, or a cave),
  known by type, or known in detail. Camps and the boss are always visible. After each leg
  the company looks ahead; the Scout skill, quirks and gear improve the odds (the Tracker also
  reads who's waiting). Some fights look quiet from afar.
- **Mishaps** `[mishap_chance]` 18% per move: rats in the flour, a cracked wheel, bad water,
  a snake in the crate and so on. The right supply or survival skill prevents or softens each.

### Supplies (General Store; the wagon has 12 slots `[wagon_slots]`, items stack)
| Item | Use |
|---|---|
| Food | Eaten on the move (2 per stop `[food_per_move]`) and at camp meals |
| Lamp Oil | Relights the lamps in a cave |
| Bandages | Heal and cure bleed; curio key for wounded or snagged things |
| Antivenom | Cure poison; curio key for snakes and venom |
| Whiskey | Fatigue relief; curio key for strangers and trade |
| Rope | Curio key for wells, cliffs and crossings (store level 2) |
| Shovel | Curio key for graves, rubble, burrows, crates and strongboxes (store level 2) |
| Salt | Curio key for strange, mythic things; stops spoilage (store level 2) |
| Wagon Parts | Repair the wagon |

Timber and Iron found on the trail are cargo and take wagon slots too. (The Crowbar was
retired in round 7; the Shovel took its curios.)

### Wagon
- Condition 0-100 `[wagon_max]`. Rough ground `[wagon_wear]`, mishaps and events damage it.
  At 0 it's **broken**: +6 Fatigue per move until repaired.

### Camp
1. **Meal** `[meals]`: Go Hungry (+15 Fatigue), Half Rations (2 food), Square Meal (4 food,
   heal 10%) or Feast (8 food, heal 25%, −15 Fatigue).
2. **Survival actions**: 12 hours `[camp_hours]` to spend; each action costs 2-4 hours, some
   cost supplies, and each hero can use each of their actions once.
3. **Night**: ambushes are switched off with `[hero_ambush]` (normally `[camp_ambush_chance]`
   20%, reduced by Night Watch and Cover Tracks).

### Caves
- A side stop: 3-4 rooms, each a fight, a curio, or both, then a treasure room.
- **Lamplight** starts at 100 and drops `[light_per_room]` 30 per room; Lamp Oil restores it.
  The light meter shows the current level and its effects `[light_levels]`:

| Level | From | Hero crit | Enemy damage | Fatigue per room | Loot |
|---|---|---|---|---|---|
| Bright | 75 | +0 | +0% | 1 | +0% |
| Dim | 50 | +2 | +5% | 2 | +10% |
| Shadowy | 25 | +4 | +10% | 4 | +20% |
| Pitch Black | 0 | +7 | +20% | 6 | +35% |

### Curios and events
- **Curios** have a *by hand* outcome table and **key items** that give a guaranteed good
  result; keys are remembered once found. Quirk compulsions can make a hero grab one (a
  Drinker and a whiskey barrel).
- **Events** are Oregon Trail-style text choices. Options can need an item, chips, a class, a
  survival skill or a quirk; a party skill unlocks special options. Outcomes are weighted.

### Ending an expedition
- **Victory** (boss, crossing or final fight won): loot, XP, quirk rolls (45%, positive 60%
  on a win and 40% otherwise), and founding if it was a region boss.
- **Turn Back** from the map: keep loot, +20 Fatigue each `[turn_back_fatigue]`.
- **Driven Back** (a scripted boss meeting): loot and XP kept.
- **Wipe**: everyone died; loot lost.

---

## 8. Quirks and trinkets

- **Quirk** effects are data: stat modifiers with conditions (`always`, `in_cave`,
  `on_trail`, `front` (ranks 1-2), `back` (ranks 3-4), `vs:<tag>`, `low_hp`), Fatigue and
  healing multipliers, food, scouting, surprise and loot modifiers, and **compulsions**.
- **Trinkets** (`keepsakes.json`) use the same modifier format with rarities. They come from
  elites (35% `[elite_keepsake_chance]`), bosses, caves, quests and the General Store.

---

## 9. Economy

- Currency: **chips**. Materials: **Timber** and **Iron** (gate building and gear), and
  **Charters** (from region bosses, needed to found and grow settlements).
- Fights pay 5-12 chips per enemy × region tier `[enemy_money]`. Elites add 1-3 Timber and
  0-2 Iron. Region bosses pay 250 chips × tier `[boss_money]`, a Charter and a trinket.
  Rumors pay a set reward (chips, Timber, Iron, maybe a trinket or recruit).
- Buildings cost roughly 300-450 / 800-1100 / 1800-2400 chips per level plus Timber and Iron
  (`buildings.json`). Gear, move training and treatment costs are in config.
- Trading posts sell at 2.2× `[trade_markup]`.

---

## 10. Enemies

Enemies carry tags (`outlaw`, `human`, `beast`, `mythic`, `reptile`, `cave`...) that quirks,
trinkets and class matchups reference. Full list with numbers: `ENEMY_REVIEW.md`.

- **Tutorial**: looter, greenhorn gunman, a bat; **Crowbar Pete**.
- **Tallgrass Sea (tier 1)**: outlaw brawler, gunhand, knifeman, rifleman; prairie wolf,
  coyote, rattlesnake, buffalo bull, carrion crows, murder of crows, prairie haint; Crane's
  lieutenant; **Silas Crane and the Crows**. Side adventures add Old Jeb, Ruby Blackwing and
  the dynamiter and claim jumper; rumors add **"Mad Dog" Mulligan**.
- **Red Canyons (tier 2)**: claim jumper, railroad enforcer, dynamiter, hired gun; canyon
  siren, dust devil, gila monster, stone ram; **the Cyclops of Deadeye Mesa**.
- **Thunder Peaks (tier 3)**: mountain bandit, grizzly, storm hawk, stone giant youth, frost
  wight; **the Titan of the Pass**.
- **Caves (any tier)**: giant bats, tommyknockers, pale crawlers.

---

## 11. Presentation

- 1920×1080 base resolution with scaling; mouse controls.
- **Characters** are drawn in code in an ink-illustration style: bold outlines, flat color
  with cel shading, profile faces at rest and storybook reactions (wide eyes, open mouths) in
  action poses. Rolled outfits vary heroes of one class.
- **Scenery**: painted backdrops where they exist (the title, the Tallgrass trail, the
  tutorial and rumors), otherwise layered paper-theater scenery drawn in code (hanging paper
  clouds and sun, parallax hills) tinted per region.
- **UI**: dark wooden planks with rope trim and iron brackets, signboard buttons, parchment
  panels; painted item and resource icons. The expedition map is a scorched parchment sheet
  with inked trails, wooden stop discs and a wagon token.
- **Combat action**: the screen dims, attacker and target slide in and scale up, the attacker
  strikes a pose, then damage numbers and a hit flash; health bars move as each hit lands.
- **Audio**: generated weapon and impact sounds and music, CC0 recordings for creatures and
  objects, all levelled to one loudness.
- **Autosave** to `user://save.json` after every settled action.
