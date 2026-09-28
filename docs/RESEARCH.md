# Darkest Dungeon 1 & 2 — Mechanics Research

Reference notes on how Darkest Dungeon (DD1, 2016) and Darkest Dungeon II (DD2, 2023)
work, and what Frontier Expedition takes, changes, or drops. Numbers are DD1 unless noted.

---

## 1. Combat

### Formation
- Four hero ranks vs four enemy ranks. Rank 1 is the front.
- Every skill lists the **ranks it can be used from** and the **ranks it can target**.
  A hero who has been shuffled out of position may have no useful skills.
- Displacement is a weapon: **knockback**, **pull**, and **shuffle** break the enemy's
  formation. Heroes can also spend a turn swapping with a neighbour.
- When an enemy dies in DD1, its corpse keeps the rank occupied. DD2 drops corpses.

### Turn order
- Each round, every unit rolls **Speed + 1d8**; highest acts first. The dice decide most
  of the order; big Speed gaps (e.g. 9 vs 0) always go first.

### To-hit
- Hit chance = **skill base accuracy + attacker accuracy modifiers − target Dodge**.
- There is a hidden +5 that makes a displayed 95% a certain hit, and every skill keeps at
  least a 5% chance. Consecutive misses add a hidden +4 accuracy.
- Crit chance = attacker crit + skill crit modifier. Crits deal 150% damage, stun and
  debuff harder, and change Stress for the party.

### Damage
- Weapon damage range × skill damage modifier, then reduced by the target's **Protection**
  (a percentage). DoT effects ignore Protection.

### Status effects
- **Bleed / Blight**: damage over time; each application stacks separately, typically
  3 rounds. Each rolls against a matching resistance.
- **Stun**: lose the next turn. Afterwards the unit gains stun resistance so it can't be
  stun-locked.
- **Mark**: some skills deal bonus damage to marked targets; some enemies target them.
- **Guard**: redirect attacks aimed at an ally to the guarding unit.
- **Buffs/debuffs**: timed modifiers to accuracy, damage, dodge, protection, speed, crit.
- **Move resistance** resists knockback/pull.

### Death's Door
- At 0 HP a hero enters **Death's Door**. Each further hit forces a **Deathblow check**:
  base **67%** to survive, capped at 87%.
- On Death's Door the hero gains small bonuses (accuracy, damage, speed, resistances).
- When healed off Death's Door they carry a **Death's Door Recovery** debuff for the rest
  of the dungeon.
- Enemies die at 0 HP. This is why DD feels tense rather than cheap: a hero is never
  killed from full HP by one roll, but pushing on while wounded is gambling.

### DD2 changes
- **Tokens** replace hidden numbers: Block, Dodge, Strength, Weakness, Blind, Taunt etc.
  are visible stacks that fire once. Clear, but loses DD1's "X% to hit" readability.
- Each turn has a free action (combat item) plus a main action.
- Stress is 0–10, and maxing it causes a Meltdown.
- **Our choice:** keep DD1's explicit percentages (the player prefers them), borrow DD2's
  clarity by always showing chances and active effects on-screen.

---

## 2. Stress → our **Fatigue**

### DD1
- Range 0–200. Stress comes from enemy stress attacks, crits taken, allies falling, low
  light, hunger, curios, and events.
- At **100**: a **Resolve Check**. Base **25%** chance of a **Virtue**; otherwise an
  **Affliction**.
  - Afflictions: Fearful, Paranoid, Selfish, Masochistic, Abusive, Hopeless, Irrational.
  - Virtues: Stalwart, Courageous, Focused, Powerful, Vigorous.
- Afflicted heroes get stat penalties and sometimes **act out** at the start of their
  turn: pass, pick a random skill or target, move themselves, refuse healing, or stress
  allies with barks.
- Virtuous heroes get stat bonuses and randomly heal themselves, buff allies, or reduce
  party stress.
- At **200**: a **Heart Attack**, which drops the hero to Death's Door (or kills them if
  already there).
- Stress is relieved in town (Tavern, Abbey), by camp skills, some skills, crits, and
  some curios.

### DD2
- Meltdowns and **relationships**: party members build affinity or hostility, which
  unlocks cooperative or hostile acts.

### Our adaptation — Fatigue
- Same shape: 0–200, a test at 100, **Breaking Point** (bad) or **Second Wind** (good),
  and **Collapse** at 200 (straight to Death's Door).
- Reflavored for the trail: Homesick, Reckless, Short-Tempered, Cowardly, Greedy, Paranoid
  vs Steadfast, Inspired, Sharp-Eyed, Grit, Fired Up.
- Sources are trail-driven: hunger, storms, river crossings, frightening creatures,
  wounds, dark caves.

---

## 3. Exploration & resources

### DD1 dungeons
- Rooms connected by corridors; a **Torch/Light meter** (0–100) that burns down.
  Thresholds at 75/50/25/0. Lower light means more stress, more enemy damage, and more
  surprise risk, but more hero crits and more loot.
- **Scouting** reveals rooms ahead. Parties can be **surprised** (enemies reorder heroes and
  act first), or surprise the enemy themselves.
- **Provisions** are bought before each expedition: food, torches, shovels, keys,
  bandages, antivenom, holy water, herbs, laudanum.
- **Curios** are interactable objects. Investigate by hand for a random result, or use the
  right provision to get a guaranteed good result. Recurring pattern per area (e.g.
  shovels on rubble, holy water on altars). Once found, the correct pairing is
  remembered.
- Quirks such as Kleptomaniac or Dipsomania force a hero to interact with certain curios
  on their own.

### DD2 road
- A stagecoach travels a **branching road** through regions toward a final destination.
  Nodes include battles, hospitals, oddities, shrines, lairs and **inns**.
- The stagecoach has durability; obstacles and road events damage it.
- Each region ends with an inn: rest, items, and relationship events.

### Our adaptation
- **The Trail**: a DD2-style branching node map per region, east to west. Nodes are
  fights, Oregon Trail events, curio stops, camps, trading posts, homesteads, elites,
  side **caves**, and a boss.
- **Caves** are a small DD1-style room-by-room dungeon with a **Lamplight** meter
  (lamp oil) and scouting and surprise rules.
- **Wagon** durability (DD2 stagecoach) with Wagon Parts to repair.
- **Food** is eaten on a schedule, as in Oregon Trail. Starving hurts HP and Fatigue.
- **Curios**: frontier objects (abandoned wagons, whiskey barrels, prospector's cache,
  strange standing stones), each with random results and a matching supply item for a
  guaranteed good result. Correct pairings are remembered.

---

## 4. Camping → our **Survival skills**

### DD1
- Camp using firewood. A meal phase (starve / half meal / full meal heals 10% / feast
  heals 25% and 10 stress), then **12 respite points** spent on camp skills (heal, stress
  relief, buffs, scouting). Then night, with a chance of ambush (Guard/"Night watch"
  skills prevent it).
- Each class has its own camp skills.

### Our adaptation
- Camp skills belong to **survival skills**, not classes. Each hero rolls two from a
  shared pool (Cook, Hunter, Forager, Scout, Tracker, Wheelwright, Medic, Storyteller,
  Trapper, Angler, Woodcutter, Miner). Two heroes of the same class play differently.
- Survival skills also have trail passives (the Scout reveals nodes, the Wheelwright
  saves the wagon) and unlock extra options in events.
- Some produce **Timber and Iron**, the materials that build and upgrade settlements. That
  ties camping to the settlement loop, as the player wanted.
- They rank up with use (1 → 3).

---

## 5. Town (Hamlet) → our **Settlements**

### DD1 Hamlet buildings
- **Stagecoach**: new recruits weekly; upgrades add more recruits and higher levels.
- **Guild**: upgrades combat skills. **Blacksmith**: weapons and armor.
- **Tavern**: Bar / Gambling / Brothel remove stress, with side effects (e.g. gambling
  away gold, picking up quirks, going missing).
- **Abbey**: Meditation / Prayer / Flagellation remove stress.
- **Sanitarium**: treat negative quirks, lock positive quirks (up to 3), cure diseases.
- **Survivalist**: learn camp skills. **Nomad Wagon**: trinkets.
- **Memorial**: the graveyard.
- A hero using a building is busy for the **next week** (one expedition).
- Buildings upgrade with heirlooms (busts, portraits, deeds, crests) dropped in dungeons.

### DD2
- No hamlet; meta-progression lives in the **Altar of Hope**, bought with Candles earned
  per run.

### Our adaptation
- A **chain of settlements** (Outpost → Town → City) replaces the single Hamlet.
  Settlements are only founded at conquered boss landmarks.
- Buildings: **Saloon** and **Chapel** (Fatigue), **Doctor's Office** (quirks),
  **Smithy** (gear), **Drill Hall** (combat skills), **General Store** (supplies and
  keepsakes), **Hiring Board** (recruits), **Stage Line** (move heroes between
  settlements), **Boot Hill** (memorial).
- Buildings are built and upgraded with **Money, Timber, Iron**. Founding and tier
  upgrades need **Land Charters**, which come from bosses and elites.
- Distance matters: heroes out west must ride the Stage Line back east to reach the best
  facilities, which costs weeks.

---

## 6. Quirks & Trinkets

- DD1 heroes carry up to 5 positive and 5 negative quirks, gained from expeditions and
  curios. Effects include stat changes, bonuses vs enemy types, bonuses in certain
  dungeons, and compulsions. Negative quirks can become locked in over time.
- Trinkets are equippable items (2 slots) with pros and cons.
- **Our adaptation:** quirks with the same shape, reflavored (Sharpshooter's Eye, Beast
  Hunter, Teetotaler, Night Owl / Drinker, Afraid of Snakes, Gold Fever, Homebody, …).
  **Keepsakes** stand in for trinkets.

---

## 7. What makes DD work (design principles we keep)

1. **Risk you can read.** Every number is visible; the tension comes from choosing to
   push on while understanding the odds.
2. **Attrition across fights.** HP, Fatigue, supplies and light persist through an
   expedition, so every small fight matters.
3. **Heroes are resources, not protagonists.** Permadeath plus an easy recruit pipeline:
   loss hurts but isn't game over.
4. **Position is a resource.** Formation, displacement and rank-locked skills make the
   same four heroes play differently in each order.
5. **Town time is a second game.** Deciding who recovers, who trains and who goes out
   this week is as important as combat.
