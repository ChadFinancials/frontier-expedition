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
| Tier | Building slots | Max building level | Townsfolk housed | To grow here | Cost |
|---|---|---|---|---|---|
| Outpost | 3 | 1 | 4 | | Founding: 1 Charter, 600 chips, 15 Timber, 8 Iron, 4 Hides |
| Town | 6 | 2 | 8 | 4 townsfolk | 3 Charters, 2000 chips, 40 Timber, 25 Iron, 12 Hides |
| City | 9 | 3 | 12 | 8 townsfolk | 6 Charters, 5000 chips, 90 Timber, 60 Iron, 30 Hides |

- **Clearing a plot** `[clear_plot_cost, extra_plots]`: once every plot is in use, a
  settlement can clear another for 250 chips, then 500. Each is ready next week, one at a
  time. Up to 2 in a Town (8 plots) and 1 in an Outpost; a City has 9 of its own.
- **Founding** needs that region's boss beaten. A new outpost starts with a free Stage Line.
- **Fort Providence** starts as a Town that Silas Crane burned: only the **Hiring Board**
  stands; the Saloon, General Store and Smithy are **ruins** that keep their plots and rebuild
  at `[ruin_rebuild_pct]` (100%) of the level-1 cost.
- Company size: `[roster_per_tier]` (Outpost 4, Town 6, City 9), plus the Hiring Board's
  Bunkhouse track; hard cap `[roster_cap]`.

### Buildings (`data/buildings.json`)
| Building | Does | Scales with level |
|---|---|---|
| **Saloon** | Fatigue relief (Belly Up to the Bar, may add the Drinker quirk; Card Table, may win or lose chips). Rolls the week's **rumors** (side quests) | Tracks: Chatter (1-3 rumors a week; its first upgrade also brings the Lone Wanderer's challenges), Loose Lips (better rumor rewards) |
| **Chapel** | Fatigue relief (Quiet Prayer; Hymn Singing, may add a positive quirk) | Slots, relief |
| **Doctor's Office** | Remove a negative quirk; cure a Breaking Point | Slots, cost |
| **Smithy** | Weapon and armor tiers | Max tier 2 / 4 / 5 |
| **Drill Hall** | Learn new moves (`[learn_cost]` 300) and train move levels | Max move level 2 / 4 / 5 |
| **General Store** | Sells supplies (curio keys from level 2); trinkets once its Glass Case is bought | Discount; track: Glass Case (trinkets 2 / 3 / 4, rarer with each level) |
| **Hiring Board** | New recruits each week | Tracks: More Notices (count), Word of Mouth (level and quirks), Bunkhouse (company size) |
| **Stage Line** | Sends heroes between settlements, one week per stop | Seats |
| **Boot Hill** | Remembers the dead; visiting heroes shed Fatigue | Slots |
| **Lumber Yard** | Cuts Timber every week | 2 / 3 / 4 a week, plus its staff |
| **Iron Mine** | Digs Iron every week | 1 / 2 / 3 a week, plus its staff |
| **Trapping Post** | Brings in Hides every week | 1 / 2 / 3 a week, plus its staff |
| **Wheelwright** | Expeditions from here carry more cargo | +2 / 4 / 6 wagon slots, plus its staff |

**Unlocks** (round 19, `unlock` in `buildings.json`). Built buildings and ruins are never
locked; the build list shows what each locked one needs.

| Opens | Buildings |
|---|---|
| From the start | Hiring Board, Saloon, General Store, Smithy (the burned ones rebuild as before), Lumber Yard |
| A townsperson of the trade living there | Chapel (Parson), Boot Hill (Undertaker), Trapping Post (Trapper), Wheelwright (Wheelwright). Settlers of a trade that would open a building are 3× as likely |
| The plans, from a Saloon rumor on the board from week N | Doctor's Office ("The Travelling Surgeon", week 3), Drill Hall ("The Old Army Post", week 4), Iron Mine ("The Assay Papers", week 5) |
| A second settlement | Stage Line (new outposts still get one free) |

- A hero treated at the Saloon, Chapel, Doctor or Boot Hill sits out the next expedition.
- Heroes come home at full HP, with Shaken cleared. Fatigue, quirks and Breaking Points come
  home with them.
- Without a General Store the wagon leaves with a free kit `[free_kit]` and nothing is sold.
- If chips fall below `[grubstake_floor]` (150) at the week's end, a Casino agent tops them up.

### Townsfolk (`data/townsfolk.json`)
The people who run the town: a roster like the heroes', and **a separate pool**. Heroes never
become townsfolk and townsfolk never ride out.
- **A townsperson:** a name, a **trade**, a level (Greenhorn, Hand, Master) and one **trait**
  (★ good or ✗ bad, their own pool, nothing shared with hero quirks). They live in one
  settlement and draw a wage.
- **Where they come from:** only expeditions and side quests. Trail events (Sick Traveler,
  Railroad Surveyors, Claim Dispute, the Trapper's Cabin, Tapping Underground, the Cattle
  Drive, the Homestead; the passengers saved at the Stagecoach) and a chance on Saloon quest
  rewards (`chances.settler` 20/25/30% by Loose Lips). They ride home with the company and
  settle in the town it left from; a full town turns them away. The Hiring Board stays heroes
  only. A new game, and the owner's save, start with nobody.
- **Staff seats:** none at building level 1, one at level 2, two at level 3 `[staff_seats]`
  (none at the Hiring Board or Stage Line). An empty seat changes nothing: buildings work as
  they always have, and staff only add.

| Trade | Building | Greenhorn / Hand / Master add | A Master also |
|---|---|---|---|
| Barkeep | Saloon | +5 / 10 / 15 Fatigue relief | +1 side quest a week |
| Parson | Chapel | +5 / 10 / 15 relief | |
| Sawbones | Doctor's Office | -10 / 20 / 30% treatment cost | +1 bed |
| Blacksmith | Smithy | -10 / 15 / 20% gear chips | |
| Drillmaster | Drill Hall | -10 / 15 / 20% training chips | |
| Storekeeper | General Store | +5 / 10 / 15% discount | +1 trinket on the shelf (with a Glass Case) |
| Undertaker | Boot Hill | +5 / 10 / 15 relief | |
| Logger | Lumber Yard | +2 / 3 / 4 Timber a week | |
| Mucker | Iron Mine | +1 / 2 / 3 Iron a week | |
| Trapper | Trapping Post | +1 / 2 / 3 Hides a week | |
| Wheelwright | Wheelwright | +1 / 2 / 2 wagon slots | |
| Laborer | anywhere | half a Greenhorn's help, then a full Greenhorn's from Hand | |

- **Wrong trade:** anyone else in a seat gives half a Greenhorn's help. Staff discounts cap at
  40% `[discount_cap]`.
- **Learning:** 2 progress a week on the job `[xp_per_week]`; Hand at 8, Master at 24
  `[level_xp]` (four weeks, then eight more).
- **Wages** `[wages]`: 10 / 20 / 30 chips a week by level, paid at the week's start, before the
  Casino's grubstake. Idle folk are paid too. Unpaid two weeks running `[unpaid_leave_weeks]`,
  they leave.
- **Traits:** ★ Hard Worker (works a level up), Thrifty (half wage), Apt Pupil (learns twice as
  fast), Handy (a full Greenhorn's help anywhere), Well Liked (coworkers in town learn faster),
  Loyal (never leaves); ✗ Lazybones (works a level down), Grasping (wage +50%), Set in Their
  Ways (stops at Hand), Tippler (20% a week off work), Grumbler (coworkers learn slower),
  Restless (idle two weeks or more: 10% a week to move on).
- **Growth:** a Town houses 8 and a City 12; growing to a City needs 8 townsfolk living there.
- Moving townsfolk (and heroes) between settlements comes later, with the multi-town work.

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
  claim jumpers, a snake gulch, Crane's scouts. Until the company has run one, the board
  offers an easy starter job (difficulty 2 or less, no boss, no Mad Dog), posted the moment
  the Saloon reopens. Each has a chance of a boss, a trinket and a
  recruit that rises with Loose Lips (`chances`). They borrow the western region's scenery,
  events and curios, add a few theme events of their own, and scale to its tier. They are the main early source of chips, Timber
  and Iron, and the place to train.

### The Lone Wanderer's challenges
- The Saloon's first **Chatter** upgrade puts the Wanderer's challenge on the rumor board,
  on top of the usual chatter, one chapter at a time until it's won (`extra` templates in
  `quests.json`).
- Each is a short rumor trip (more events and homesteads, fewer fights) that ends in a
  **showdown**: High Noon with no gang and no fight.
  - Bullseye, hit or graze win the rumor's reward; a bullseye adds half its chips again.
  - A miss, or jumping the gun, ends the trip with nothing more (Driven Back), and the
    challenge comes back.
- **Chapters:**
  1. A Stranger's Challenge: draw 0.44 s.
  2. The Wanderer's Trail: draw 0.40 s, faster sight.
  3. High Noon at ...: draw 0.36 s. Pays **the Wanderer's Silver Dollar** (+5 Accuracy, +3%
     crit, and High Noon draws 0.05 s faster).

### Scripted boss meetings
- A boss can carry a `first_script`: the first fight stops when a round is reached, a hero
  goes down to Last Legs, or the boss drops below a health share. A cutscene plays and the run
  ends as **Driven Back** (loot and XP kept). Next time the boss starts **wounded** with a new
  intro. Silas Crane uses it (*Crane's Gambit*: round 3, a hero on Last Legs, or Silas
  under 60%; he returns at 85%).

---

## 4. Heroes

- **Class**: stats, 6-8 moves, preferred ranks. A new hero knows the class's two stock moves
  plus two random others `[starting_moves, stock_moves]`, learns the rest at the Drill Hall,
  and equips 4.
- **Look**: each class has three color **outfits**; a hero rolls one, plus skin and hair.
- **Level** 1-5 from XP at `[xp_levels]` 24 / 80 / 160 / 260. XP: 1 per stop, 2 per elite,
  5 per boss. Each level above 1: +12% max HP, +5% damage, +3 accuracy, +1% crit
  `[level_*]`. Level caps gear and move levels.
- **Gear**: weapon and armor tiers 1-5 (Smithy; a tier needs that hero level). Weapon +12%
  damage per tier; armor +8% max HP and +2 dodge per tier. Weapon tiers cost Iron, armor tiers
  Hides (2/5/9/14) `[gear_costs]`.
- **Move level** 1-5 (Drill Hall; at most one above the hero's level): +4 accuracy, +8%
  damage, +6% effect chance, +15% healing and damage over time per level `[skill_level_*]`.
- **Survival skills**: two per hero, rank 1-3, ranking up with use. Each gives a party
  passive and camp actions (one at rank 1, a second at rank 2).
- **Quirks**: up to 4 positive and 4 negative. **Trinkets** (data: keepsakes): two slots.
- **Fatigue** 0-200, possibly with a **Breaking Point** or **True Grit**.
- Class matchups: a class can carry `vs_tags` (the Mountain Mystic gets +20% damage and +2
  accuracy against beasts) or `cave_loot_pct` (the Prospector finds +25% loot in caves).

### The 11 classes
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
| Train Hopper | Burster | 1-4 | Boxcar Leap, Stowaway, Chart the Hills, Catch Out; **End of the Line** (mega) |

**Momentum (Train Hopper):** a 0-100 gauge, reset every fight. Each of her moves adds its
own amount (+20 or +30; every one moves her); +10 when someone else moves her; -10 for a
turn that ends where it began; -25 for a turn lost to a stun. At 50+ she's at **Full
Steam** (+3 Speed, +5 Dodge). At 100 an extra button lights: **End of the Line**, any rank
at one enemy in ranks 1-4, 10-18 damage, +50% vs Marked, ignores half Protection; she lands
in rank 1 and the gauge empties; a kill gives back 20. Tunable in config (`momentum_*`,
`full_steam_*`).

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
  data exactly as they play, so those two dials sit at 1.0; enemies' is 1.0 too (round 9; was
  0.9).
- **Effect chance** = effect base + move level bonus − target resistance, clamped 0-95%.
  A failed effect shows "Resisted Stun" (or whichever).
- **Vulnerable** (`vulnerable` stat): the unit takes +X% damage from everything, damage over
  time included. **Mark** is different: enemies focus the marked hero, and some moves deal
  big bonus damage to marked targets. Vulnerable is the small across-the-board amp, Mark the
  big single-target one. A move doesn't do both (no double dip). Vulnerable 10% is on Hogtie,
  Pickaxe, Righteous Smite, Point Blank, Sledge Toss and Axe Cleave (1 round), plus a few enemy
  moves (crows, gila monster, the Cyclops' sweep). Marked payoffs (`vs_marked`): Called Shot
  +60%, Sic 'Em and Lightspeed Whip +50%, Iron Justice, Money Shot and Book of Judgment +40%,
  Hammerfell +30%. Markers: Serve a Warrant, Quarrel, Assign the Joker, Lasso.
- **Bones**: a fallen enemy leaves its bones (2 HP) in its rank, so the enemies behind don't
  step up. Bones can be targeted and are hit by area and random moves; destroy them and the
  line slides forward. They never act and ignore every effect. The last enemy standing
  leaves none: the fight ends.
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

- **Multi-hit moves land every hit:** a random volley (Fan the Hammer, Poison Darts, enemy
  volleys) or a repeated shot (Twin Shots) whose target has already fallen moves to another
  valid target, bones included.

### Last Legs
- A hero at 0 HP is on **Last Legs** (code: `deaths_door`). Further damage (bleed and poison
  too) rolls to **Cheat Death** (code: `deathblow`): 67% to survive, capped at 87%
  `[deathblow_base, deathblow_cap]`. The hit that knocks a hero onto Last Legs, and the rest of
  that same move, can't kill.
- Healing lifts them out with **Shaken** (−10% damage, −5 accuracy, −2 speed) for the rest of
  the expedition, unless a Medic's Set the Bone treats it. Last Legs carries between fights
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
| An ally goes down to Last Legs | +6 to the rest of the party |
| An ally dies | +15 to the rest of the party |
| A move with too little food | +10 and 10% HP `[hunger_*]` |
| A move with a broken wagon | +6 |
| A cave room | +1 to +6 by lamplight |
| Landing a crit | −4 self, −2 the others |
| Camp, events, the Preacher and some moves | relief |

- **At 100** a hero takes a **Gut Check**: 25% (+2% per level, plus quirks and trinkets) for
  **True Grit** (Fatigue drops to 45), otherwise a **Breaking Point**. It only fires when
  Fatigue crosses 100 and the hero has no state yet. (In code and data True Grit is still
  `second_wind`, and the chance is the `resolve` stat.)
- **Breaking Points** change stats, and each turn there's a 30-40% chance the hero **acts
  out**. Clears at 25 Fatigue or with treatment in town.

| Breaking Point | Stats | Acts out | Hook |
|---|---|---|---|
| Heartsick | −15% Dmg, −2 Spd | pass ×2, bark, back away (30%) | |
| Reckless | +15% Dmg, −15 Dodge, Vulnerable 10% | random move ×2, charge, bark (35%) | |
| Ornery | +10% Dmg, −10 Acc | bark ×2, **taunt**, random move (40%) | Taunt draws enemy fire until their next turn; doesn't cost the turn |
| Cowardly | +10 Dodge, −10% Dmg, −5 Acc, Vulnerable 15% in ranks 1-2 | back away ×2, pass, bark (35%) | |
| Greedy | +5% Crit, −5 Prot, −10 Grit Chance, +15% Loot | bark ×2, random move, pass (30%); refuses help | Marked (3 rounds) at the start of each fight |
| Paranoid | +10 Dodge, −10 Acc, −25% Healing Received, +4 Spd in round 1 | bark, back away, pass, random move (30%); refuses help | |

- **True Grit** lasts until the expedition ends. Each state boosts stats and may fire a boon
  at the start of the hero's turn.

| True Grit | Stats | Each turn | Hook |
|---|---|---|---|
| Steadfast | +5 Prot, +5 Cheat Death, +10 Stun Res | 35%: −4 Fatigue to the company | When it lands, the most wounded hero gets +15 Prot for the rest of that fight (or the next one, if it landed on the trail) |
| Inspired | +2 Spd, +5 Acc | 45%: −6 Fatigue to the company | |
| Dead-Eye | +12 Acc, +10% Crit, +10% Dmg vs Marked | 30%: Marks an enemy (2 rounds) | |
| Mule-Headed | +25 Bleed/Poison Res, +20 Stun Res, +10% HP, +15 Cheat Death on Last Legs | 40%: heals 12% HP | |
| Fired Up | +20% Dmg, +1 Spd, +10% Crit vs Vulnerable | 35%: +12% Dmg to an ally | |
| Cool-Headed | +20% Healing Received, +20 Debuff Res | 35%: clears every Bleed or every Poison (whichever is worse) from the worst-off hero | |

- **At 200**: **Collapse**. The hero drops to Last Legs (or dies if already there);
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

Timber, Iron and Hides found on the trail are cargo and take wagon slots too. (The Crowbar was
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
- **Curio experts**: you pick who investigates, and it matters. A hero whose class or survival
  skill knows the curio makes the bad outcomes less likely (class 50%; skill 20/35/50% by
  rank; capped at 75%), may add a bonus (+1 Iron, +1 Hide, scouting), may swap a bad outcome
  (the Marshal collects the Dead Horse rider's bounty), or works as the key (Preacher = Salt
  at a grave, Prospector = Shovel at an ore vein, Train Hopper = Shovel at a railroad crate,
  Doctor = Antivenom at a glowing pool, Angler = Rope at a well). A class that hates the thing
  makes bad outcomes 50% more likely (Preacher at a whiskey barrel, Mountain Mystic at a
  railroad crate). The Gunslinger and a Tracker strike first when a curio is an ambush. The
  picker shows each by name only, a green ★ or a red ✗ (★ Prospector, ✗ Preacher). A few bad outcomes carry a 15% quirk.
- **Events** are Oregon Trail-style text choices. Options can need an item, chips, Hides, a
  class, a survival skill or a quirk; options needing a class, skill or quirk nobody has are
  hidden (secret options). Outcomes are weighted.
  - **Pools:** an event stop draws from the common pool (`common_events`: wagon trouble,
    peddlers, weather, sickness, strangers; 45%) or the region's own list (55%). Side quests
    add their template's theme list (theme 40 / region 30 / common 30). No repeats until
    every layer is spent.
  - **Event experts**, the curio rules over the whole company: classes, survival skills
    (rank) and **quirks** (35%) improve or worsen an option's odds, add a bonus, swap in a
    better outcome, set up the fight (foes wounded, a lookout dropped, foes Vulnerable, who
    strikes first) or make a supply unnecessary. The best ★ and the worst ✗ both count; a bad
    outcome lands on the ✗ hero. The option shows just the names: ★ Cook, ✗ Overweight.
  - **Compel:** a bad-quirk option (Drinker, Gold Fever, Too Curious, Hothead, Spooked by
    Critters) has a 30% chance `[event_compel_chance]` to be taken before you can choose.
  - **Follow-ups:** some outcomes open a second choice. The Haint Lights lead to a grave (dig,
    or leave a coin?), the homestead pantry hides a padlocked cellar, and the Twister leaves a
    strongbox in the debris.
  - **Hidden options:** an option can be ruled out by who's present (`hide_if`). A Marshal
    won't steal a stray or the company's ore, and the Superstitious won't mock the Knockers.
  - First region: 15 common events, Tallgrass 10, Dry Gulch 6 (mine country: the Powder
    Shack, Tapping Underground, Tommyknockers, the Runaway Burro, an Ore Wagon Wreck, Claim
    Dispute) and Crow's Nest 6 (outlaw country: Smoke Signals, Outlaw Toll, the Abandoned
    Homestead, the Wanted Poster, the Hanging Tree, a Stagecoach in Trouble).

### High Noon (duels)
- A two-part duel (`scripts/core/duel.gd` scores it; `scripts/ui/high_noon.gd` plays it; tuning
  in config `duel`).
  1. **The Draw:** a 1.5-8 s wait, maybe a false cue (a caw, a tumbleweed), then DRAW! and
     the bell. Click or press Space. Too early: jumped the gun.
  2. **The Aim:** a sight swings over a bar from a random start, and its pace wanders
     (0.65-1.45× its speed, changing every 0.25-0.6 s). Zones from the centre: bullseye 3%,
     hit 10%, graze 22% of the bar; the rest misses. Take the shot within 4 s `[aim_time]` or
     it goes wide (a miss).
- **The hero's edge** against the opponent's draw time (0.48 s outlaw leader and hangman,
  0.44 s the Lone Wanderer, 0.45 s Mad Dog, 0.40 s Pike): Gunslinger -0.10 s, Marshal -0.05 s, Quick Draw levels, Speed above 4.
- **Aim zones:** Gunslinger ×1.4, Marshal ×1.2, Eagle Eye ×1.2, Bounty Hunter ×1.1,
  Butterfingers ×0.75, Accuracy ±10%.
- **Quirks:** Jumpy gets an extra false cue, Drinker a wobbly sight, Hard of Hearing no bell.
- **Too slow:** they fire first, the hero loses 15% HP, and the zones shrink by a third.
- **Results:** bullseye → the duelist is dead; hit → 50% HP and bleeding; graze → bleeding;
  miss or jumped → the hero is **Rattled** (-10 Acc, -5 Dodge) until the expedition ends.
- **The duelist's gang** waits at the next fight or elite stop, carrying the result. A
  wanted man's bounty pays at once on a bullseye; otherwise it rides on that fight.
- **Duels:**
  - The Lone Wanderer (common; for pride: Fatigue relief, or Fatigue on a loss)
  - Outlaw Toll "Call out the leader" (anyone)
  - Wanted Poster (Snake-Eye Pike)
  - Hanging Tree (a bullseye or hit frees the homesteader, who joins)
  - Mad Dog's standoff before his boss fight: a boss can't die to it; a bullseye leaves him
    at 50% HP and bleeding
- No Cancel on "Who draws?": a duel has to be answered.
- **Dev tool:** "DEV: Minigames" on the main menu (duels and skill checks).

### Curio skill checks
- Eight first-region curios ask for a hands-on check when investigated by hand. Using the
  right supply, or a hero who works as the key, skips it. Walking past is still allowed.
- **The four games** (`scripts/ui/skill_check.gd`, tuning in config `checks`):

  | Game | How it plays | Curios |
  |---|---|---|
  | Tumblers | Stop a sweeping needle on the notch, 3 pins; Space or a click anywhere. Each pin lights green or red | Strongbox, Railroad Crate |
  | Pattern | Repeat 4-7 flashed arrows | Standing Stone, Lonely Grave |
  | Quick hands | Type each letter (A-Z) before its ring closes: 1.1 / 0.9 / 0.75 / 0.65 / 0.55 s by difficulty | Collapsed Tunnel, Abandoned Wagon |
  | Steady hand | Hold to keep a marker in a band for 5 s. The band moves like a hooked fish: it rests, then glides to a new spot, now and then darting (more often at higher difficulty) | Prairie Well, Miner's Cache |

- **Difficulty 1-5:** base 3. A ★ class or good quirk -1; a skill expert -1 at rank 2+; a ✗
  +1. Game quirks (config `check_quirks`): Butterfingers +1 at locks and steady hands, Keen-Eyed
  -1 at locks, Rock Steady -1 and Drinker +1 steady, Quick Feet and Jumpy -1 and Slowpoke +1
  quick hands, Quick Study -1 and Simple +1 patterns, Spooked by Critters +1 at the wagon.
- **Result:**
  - **Clean** (no slips): a good outcome 90% of the time.
  - **Close** (one slip): the plain roll, leaning bad.
  - **Botched:** a bad outcome.
  - Expert bonuses still apply on a good outcome.

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

- Currency: **chips**. Materials: **Timber** (building), **Iron** (metal: weapons, the Smithy),
  **Hides** (leather: armor, the Saloon, Doctor, Stage Line, Bunkhouse and settlement growth), and
  **Charters** (from region bosses, needed to found and grow settlements).
- Fights pay 10-24 chips per enemy × region tier `[enemy_money]`. Elites add 1-3 Timber and
  1-2 Iron. Region bosses pay 500 chips × tier `[boss_money]`, a Charter and a trinket. Side
  quests pay 160-300 chips (more in harder tiers). Every chip earned passes through the
  `chips_mult` dial (1.0).
  Rumors pay a set reward (chips, Timber, Iron, Hides, maybe a trinket or recruit).
- Hides come from beasts (wolves, coyotes, snakes, gila monsters; buffalo, grizzlies and stone
  rams always), the Hunter and Trapper at camp, hunting and trapping events, the Dead Horse
  and beast-themed side quests.
- Buildings cost roughly 300-450 / 800-1100 / 1800-2400 chips per level plus Timber, Iron and
  Hides (`buildings.json`). Gear, move training and treatment costs are in config.
- Trading posts sell at 2.2× `[trade_markup]`.
- **Storehouse:** supplies left in the wagon come home into a company-wide storehouse (lost
  only if the party is wiped out). The embark screen loads stored goods first, free, and only
  buys the rest; without a General Store they load on top of the free kit. The General Store
  buys stored goods at 30 / 40 / 50% of their price by store level `[sell_pct]`, plus its
  Storekeeper's help.
- Townsfolk cost 10-30 chips a week each; the Lumber Yard, Iron Mine and Trapping Post (and
  their staff) are a steady trickle of materials.

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
