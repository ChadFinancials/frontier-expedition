# Frontier Expedition — Game Design Document (v1)

The systems and numbers the build implements. Creative direction lives in
`DESIGN_BRIEF.md`, Darkest Dungeon background in `RESEARCH.md`, and how to add content
in `ADDING_CONTENT.md`. All tunable numbers live in `data/*.json`; this document explains
what they mean.

---

## 1. Premise

It's the age of the westward trail. You lead a pioneer company out of **Fort
Providence**, the last real town on the edge of the known map. West of it the land gets
older and stranger: first outlaws and wolves, then canyon things that shouldn't exist,
then mountains where giants walk. Each region is held by something dangerous. Beat it and
you can raise a settlement on its ground, and the frontier moves west.

**v1 goal:** conquer the three regions and reach the Great Casino, a gambler's paradise city at the end of the western trail. The game continues
afterwards.

---

## 2. The two loops

```
┌───────────── SETTLEMENT (weeks) ─────────────┐        ┌──────── EXPEDITION (days) ────────┐
│ recruit · recover · train · build · supply   │ ─────▶ │ trail map → fights, events,       │
│ move heroes along the stage line             │ ◀───── │ curios, camps, caves → boss       │
└──────────────────────────────────────────────┘        └───────────────────────────────────┘
```

- One expedition = one **week**. Buildings, stage-line travel and recruits run on weeks.
- An expedition departs from a settlement into the region directly **west** of it, with
  four heroes stationed at that settlement.

---

## 3. Settlements

### Geography (v1)
| # | Settlement (founded at) | Region to its west | Region boss |
|---|---|---|---|
| 0 | Fort Providence (start, Town) | The Tallgrass Sea | Silas Crane's Gang |
| 1 | Redwater Ford (Crane's Crossing) | The Red Canyons | The Cyclops of Deadeye Mesa |
| 2 | Cloudbreak (Titan's Pass) | The Thunder Peaks | The Titan of the Pass |
| — | The Great Casino | *(victory)* | — |

### Tiers
| Tier | Building slots | Max building level | Upgrade cost |
|---|---|---|---|
| Outpost | 3 | 1 | Founding: 1 Charter, 600, chips 15 Timber, 8 Iron |
| Town | 6 | 2 | 3 Charters, 2000, chips 40 Timber, 25 Iron |
| City | 9 (all) | 3 | 6 Charters, 5000, chips 90 Timber, 60 Iron |

- **Founding** needs that region's boss to be beaten. The victorious party can found it
  on the spot if the company can pay, or later from any settlement.
- A new outpost starts with a free **Stage Line**. Fort Providence starts as a Town with
  six level-1 buildings.

### Buildings
| Building | Does | Scales with level |
|---|---|---|
| **Saloon** | Fatigue relief: *Belly Up to the Bar* (big relief, may pick up Drinker), *Card Table* (relief, may win or lose chips) | slots, relief amount |
| **Chapel** | Fatigue relief: *Quiet Prayer* (steady), *Hymn Singing* (relief, may gain a positive quirk) | slots, relief amount |
| **Doctor's Office** | Remove a negative quirk; cure a Breaking Point | slots, lower cost |
| **Smithy** | Upgrade weapon and armor tier | max tier |
| **Drill Hall** | Upgrade combat skill levels; pick equipped skills | max skill level |
| **General Store** | Buy supplies; sells a rotating set of keepsakes | stock and discount |
| **Hiring Board** | New recruits each week | recruit count and level |
| **Stage Line** | Send heroes to other settlements (1 week per step) | seats per week |
| **Boot Hill** | Memorial for fallen heroes | — |

- A hero treated at Saloon, Chapel or Doctor sits out the **next expedition**, as in DD.
- Heroes return from an expedition at full HP. Fatigue, quirks and Breaking Points come
  home with them.

---

## 4. Heroes

- **Class**: combat stats, a pool of 6 combat skills (4 equipped), preferred ranks.
- **Level** 1–5 from XP. Each level above 1 gives +8% max HP, +2 accuracy and +1% crit,
  and raises the caps on gear and skill levels.
- **Gear**: weapon tier 1–4 (+12% damage per tier) and armor tier 1–4 (+8% max HP and
  +2 dodge per tier). Capped by hero level and Smithy level.
- **Skill level** 1–4: +4 accuracy, +8% damage, +6% effect chance and +15% healing per
  level above 1. Capped by hero level and Drill Hall level.
- **Survival skills**: two, rank 1–3. They rank up with use (3 and 8 uses).
- **Quirks**: up to 4 positive and 4 negative.
- **Keepsakes**: two slots.
- **Fatigue** 0–200, possibly with a **Breaking Point** or **Second Wind**.

### The 10 classes
| Class | Role | Ranks | Signature |
|---|---|---|---|
| Marshal | Tank / protector | 1–2 | Guards allies, stuns, taunts |
| Mountain Man | Bruiser | 1–2 | Cleaves; hits harder when wounded; bear traps |
| Rail Driver | Displacer | 1–2 | Hammer knockback, stuns, self-buff rhythm |
| Gunslinger | Flexible damage | 1–3 | Quick draw, fan the hammer, point blank |
| Wrangler | Control | 2–3 | Cattle dog attacks, lasso pulls, hogtie stun |
| Gambler | Luck / support | 2–3 | Double-or-nothing shots, random party buffs |
| Prospector | Area damage | 2–4 | Dynamite, flash powder, lamp tricks |
| Sharpshooter | Back-line damage | 3–4 | Marks and executes, suppressing fire |
| Frontier Doctor | Poison and healing | 3–4 | Poison darts, surgery, smelling salts |
| Preacher | Healer / Fatigue relief | 3–4 | Laying on hands, sermons, blinding light |

Full skill lists are in `data/classes.json` and `data/skills.json`.

---

## 5. Combat

### Rules
- Four ranks per side. Every skill lists the ranks it can be **used from** and the ranks
  it can **target**. A skill that hits every listed rank is marked AoE.
- **Turn order**: each round every unit rolls `speed + 1d8`; highest goes first.
- **Hit chance** = `skill accuracy + attacker accuracy − target dodge`, clamped to
  **5–95%** and always shown. Ally-targeted skills always hit.
- **Crit chance** = `attacker crit + skill crit modifier`. Crits deal ×1.5 damage and
  affect Fatigue (below).
- **Damage** = `roll(weapon min..max) × (1 + skill modifier + damage buffs) ×
  (crit 1.5) × (1 − protection)`, minimum 1. Bleed and poison ignore protection.
- **Effect chance** = `effect base + skill level bonus − target resistance`, clamped to
  0–95% and shown on the target.
- **Status effects**: bleed, poison (per-stack damage per round, usually 3 rounds);
  stun (skip a turn, then +50% stun resist for a round); mark; guard; taunt; buffs and
  debuffs to accuracy, dodge, protection, damage, crit and speed; knockback and pull.
- **Actions**: a skill, **Swap** (trade places with an adjacent ally), or **Pass**.
- **Retreat** from any non-boss fight: +12 Fatigue to each hero, no loot.
- **Surprise**: 10% base each way. When the heroes are surprised, their order is
  shuffled and enemies act first in round 1, and vice versa.

### Death's Door
- A hero reaching 0 HP enters **Death's Door**. Any further damage, including bleed and
  poison, triggers a **Deathblow check**: 67% to survive by default, capped at 87%.
- Healing lifts them out, but they carry **Shaken** (−10% damage, −5 accuracy, −2 speed)
  for the rest of the expedition, unless a Medic treats it at camp.
- Enemies die at 0 HP and the survivors step forward.

### Enemy AI
- Each enemy skill has a weight and a target preference (`random`, `lowest_hp`,
  `marked`, `back`, `front`). A taunt forces the target; a guard redirects it.

---

## 6. Fatigue

| Event | Fatigue |
|---|---|
| Enemy fatigue attacks | +5 to +15 |
| Receiving a crit | +8 |
| An ally hits Death's Door | +6 to the rest of the party |
| An ally dies | +15 to the rest of the party |
| A move with too little food | +10 |
| A move with a broken wagon | +6 |
| A cave room in low light | +2 to +6 |
| Landing a crit | −4 self, −2 others |
| Camp, events, Preacher and some skills | − |

- **At 100** a hero takes a **Resolve Test**: 25% chance (+2% per level, plus quirks) of a
  **Second Wind**, which drops Fatigue to 45. Otherwise they hit a **Breaking Point**.
- **Breaking Points** (Homesick, Reckless, Short-Tempered, Cowardly, Greedy, Paranoid)
  change stats. Each turn there is a 30% chance the hero **acts out**: passes, uses a
  random skill, moves, barks at an ally (+Fatigue to them) or refuses a heal. It clears
  when Fatigue drops to 25 or below, or with treatment in town.
- **Second Winds** (Steadfast, Inspired, Sharp-Eyed, Grit, Fired Up) boost stats and
  sometimes heal the hero, relieve party Fatigue or buff allies at the start of their
  turn. They last until the expedition ends.
- **At 200**: **Collapse**. HP drops to 0 and the hero is on Death's Door; if they
  already were, they die. Fatigue then resets to 150.

---

## 7. Expeditions (the Trail)

### Map
- A procedurally generated node graph, **9 columns** east → west, 3–4 lanes. Each node
  connects to 1–2 nodes in the next column.
- Column 0 is the departure point and column 8 is the **boss** (or, once the boss is
  beaten, a **Crossing** elite fight). Column 7 is always a **Camp**, and a camp appears
  around column 4.
- **Node types**: Fight, Elite, Event, Curio Stop, Cave, Trading Post, Homestead, Camp,
  Boss. Some nodes are **hidden (?)** until scouted; a party Scout reveals the next
  column automatically.

### Supplies (bought at the General Store)
| Item | Use |
|---|---|
| Food | Eaten on the move (2 per node traveled) and at camp meals |
| Lamp Oil | +25 Lamplight in caves |
| Bandages | Heal 15% and cure bleed; curio key for wounded or snagged things |
| Antivenom | Cure poison; curio key for snakes and venom |
| Whiskey | −10 Fatigue; curio key for strangers and trade |
| Rope | Curio key for wells, cliffs and crossings |
| Shovel | Curio key for graves, rubble and burrows |
| Crowbar | Curio key for crates, strongboxes and locked things |
| Salt | Curio key for strange, mythic things |
| Wagon Parts | Repair the wagon (+30) |

### Wagon
- Condition 0–100. River crossings, rough ground and events damage it. At 0 it's
  **broken**: +6 Fatigue per move until repaired.

### Camp
1. **Meal**: skip (+15 Fatigue), half (2 food), full (4 food, heal 10%), or feast
   (8 food, heal 25%, −15 Fatigue).
2. **Survival skills**: 12 hours to spend. Each hero can use each of their survival
   actions once, and each action costs 2–4 hours.
3. **Night**: 20% ambush chance, reduced by *Night Watch* and *Cover Tracks*.

### Caves
- A side location: a straight run of 3–4 rooms, each a fight or a curio (sometimes both),
  with a treasure room at the end.
- **Lamplight** 0–100 starts at 100 and drops 20 per room. Low light means more Fatigue
  per room, more enemy damage and surprise risk, but more hero crit and better loot.

### Curios
- Each curio has a *by hand* outcome table and one or more **key items** that give a
  guaranteed good result. Keys are remembered once discovered.
- Quirk compulsions can force a hero to grab a curio themselves (e.g. a Drinker and
  whiskey barrels).

### Events
- Oregon Trail-style text events with options. Options can require an item, chips, a
  class, a survival skill or a quirk, and a party skill unlocks special options (the
  Angler knows the ford, the Wheelwright caulks the wagon). Outcomes are weighted and
  apply generic effects.

### Ending an expedition
- **Victory** (boss or crossing beaten): full loot, XP, quirk rolls, and the option to
  found a settlement.
- **Turn Back** from the map: keep loot, +20 Fatigue to each hero.
- **Wipe**: everyone died; loot lost.

---

## 8. Quirks & Keepsakes

- **Quirk** effects are data: stat modifiers with conditions (`always`, `in_cave`,
  `on_trail`, `front` (ranks 1–2), `back` (ranks 3–4), `vs:<tag>`, `low_hp`), fatigue
  gain multipliers, food and scouting modifiers, and **compulsions**
  (`{tag, chance}`).
- End of an expedition: each surviving hero has a 45% chance of a new quirk (60%
  positive after a victory, 40% otherwise).
- **Keepsakes** use the same modifier format and have rarities. They come from elites,
  bosses, caves and the store.

---

## 9. Economy (starting values, to be tuned)

- Start with 750, chips 10 Timber, 5 Iron, and 6 heroes at Fort Providence.
- Fights pay 8 chips–20 per enemy × region tier. Elites also drop Timber, Iron and a 35%
  keepsake chance. Bosses drop a **Charter**, a keepsake and 400 chips × tier.
- Buildings cost roughly 400 chips / 1000 chips / 2200 chips plus Timber and Iron, rising by level.

---

## 10. Enemies

Enemies carry tags (`outlaw`, `beast`, `mythic`, `reptile`, `cave`), which quirks and
keepsakes reference.

- **Tallgrass Sea (tier 1)**: outlaw brawler, gunhand, rifleman; prairie wolf,
  rattlesnake, carrion crows, coyote; **Silas Crane** with two lieutenants.
- **Red Canyons (tier 2)**: claim jumper, railroad enforcer, dynamiter; canyon siren,
  dust devil, gila monster; **the Cyclops** (a giant shepherd with stone rams).
- **Thunder Peaks (tier 3)**: mountain bandit, grizzly, storm hawk, stone giant youth,
  frost wight; **the Titan of the Pass**.
- **Caves (any tier)**: giant bats, tommyknockers, pale crawlers.

---

## 11. Presentation

- 1920×1080 base resolution with scaling; mouse controls.
- **Paper-cutout art**: flat silhouette figures with a cream paper edge and a drop
  shadow, class-colored accents, idle breathing. Layered parallax backgrounds (sky
  gradient, far ridges, mid hills, near grass) tinted per region.
- **Combat action**: the screen dims, attacker and target slide toward the center and
  scale up, the attacker strikes a pose (muzzle flash, swing arc), then damage numbers
  and a hit flash, and everyone slides back.
- **Audio**: generated gunshots, slashes, impacts, animal calls, eerie stingers, UI
  clicks, plus a simple plucked-guitar trail loop.
- Autosave to `user://save.json` after every node and settlement action.
