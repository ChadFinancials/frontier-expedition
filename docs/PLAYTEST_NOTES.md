# Playtest Notes & Backlog

## Round 1 (owner's first playthrough)

### Keep
- The Slay the Spire–style branching map, where taking one path locks out others. Works great.
- Core gameplay and mechanics are decent for a first build.

### Clarity / UI
- [x] Map nodes are 100% accurate about what's there. Add uncertainty (fog, "probably a fight",
      unknown stops) and a real **scouting** layer. Some heroes, survival skills and quirks
      should be better at it than others.
- [x] Fatigue relief on hero crits isn't explained (Fan the Hammer looked like it reduced
      Fatigue; it was the crits). Make the cause visible.
- [x] Keepsakes: there's no obvious place to see or equip them, especially on the trail.
- [x] Wagon: no feedback on its condition. Did "Mend the Wagon" do anything? Show wagon
      condition clearly, and what repaired or damaged it.
- [x] Combat readability: more time to register actions, and clearer attacker → target
      (who is hitting whom). More animations and light QoL feedback when moves are used.

### Economy / resources
- [ ] Money supply feels too high.
- [ ] Resources (supplies and materials) rarely matter. Add more encounters and random
      events that force using them (broken wheel, rats in the food, spoilage...).
- [x] Currency → **chips**. Lore: the company heads west toward **the Great Casino**, a
      utopian gambling-market paradise city.

### Balance
- [x] Silas Crane at 165 HP is effectively impossible. Tune him down, or force a retreat the
      first time.
- [x] Early-game damage and healing both feel a bit high.

### New content
- [ ] Side expeditions from each town: 2–3 short "sub-quest" regions per town, tangential to
      the main westward trail. Used to train up, gain levels, items and upgrades before the
      main-line expedition (like DD's multiple dungeon areas).

### Workshops (to do together)
- [ ] Enemy workshop: in-depth pass on enemies, move sets and enemy groupings. They
      currently feel bland.
- [ ] Class workshop: deep dive on each class and its moves for more interest and variety.

## Round 1, part 2

### Decisions
- **Chips replace money now.** Sub-currencies for special items or shops can come later.
- **Silas Crane:** the first meeting is a **scripted turnaround cutscene**: he drives the
  company off, and you come back later to beat him.

### Visuals
- [ ] Lean harder into the **storybook paper-cutout / papier-mâché** look (the owner likes it).
- [ ] Forms are very basic; add more 3D feel and depth of field. The town is just 5
      buildings side by side. Look at DD's Hamlet screens: layered, angled buildings,
      foreground and background, depth. Don't go overboard.

### Onboarding
- [x] **Tutorial adventure** that starts automatically: a short map with 3 stops, then a
      mini-boss, with some storyline.
- [x] The town should **start barebones**. Starting with a Saloon, Smithy and General Store
      feels wrong. The tutorial's win unlocks or rebuilds the first building.

### Wagon
- [ ] Wagon as a **"5th member" in battles**: some enemies attack or sabotage it directly.
      Also wear and tear from travel.

## Round 1, part 3

- [x] The tutorial is a small three-stop road that leads *to* Fort Providence, lightly
      explaining the core mechanics along the way.
- [x] One move was always highlighted green with no explanation (it was the auto-selected
      move). Now a gold "SELECTED" frame plus a hint line says what to click.
- [x] More UI clarity and icons: move-type icons (melee, ranged, heal, buff, debuff), stat
      icons with tooltips in combat, a hint line for whose turn it is.

## What shipped for these notes

- **Batch 1:** chips, the Great Casino, map intel and scouting, wagon bar, wear and mishaps,
  supply-draining events, crit relief labeled, keepsakes on the trail, slower and clearer
  combat, balance tuning.
- **Batch 2:** burned-out Fort Providence (Hiring Board plus three ruins to rebuild at half
  price), the Old Mill Road tutorial with "Mad Dog" Mulligan that rebuilds the Saloon,
  Silas Crane's scripted first meeting (Crane's Gambit) and a wounded Silas afterward,
  selected-move clarity and icons.
- **Next (batch 3):** wagon as a fifth combatant, visual depth pass. Then side expeditions and
  the enemy and class workshops.

## Round 2 (tutorial + first Tallgrass expedition)

### Keep
- The red targeting arrow. The opening town scene looks much better. The expedition map is good.
- Saloon cost after the tutorial feels right (just shy of level 2).

### Combat & presentation
- [x] Targeting arrow should come **top-down** onto the target instead of arcing over the middle.
- [x] Victory fanfare ("do do do do") is tinny and awful. Replace it.
- [x] Some animal attack sounds sound like farts. Rework them.
- [x] Descriptions like "heals well" should show actual number ranges.

### Tutorial
- [x] The fork (Broken Axle vs. curiosities) is an obvious choice. Hide what's ahead there too.
- [x] Start with **2 heroes** (Marshal + Gunslinger), not 4. Tune the fights so the mini-boss
      is fairly easy but not trivial.
- [x] No one should reach level 2 from the tutorial: about 1/4 of the way at most.

### Heroes & naming
- [x] Single names only, no "nickname" quotes.
- [x] Silas Crane: crows as minions, an overall bird/crow theme.
- [x] Rename keepsakes to **trinkets**.

### Camp
- [x] Camp skills need a pass. Some don't make sense (does Hearty Stew use ingredients?).
- [x] At level 1 a hero should only have 1–2 camp actions, not 4.

### Town
- [x] Hiring board: 2 recruits per week to start. Two upgrade tracks: more recruits per week,
      and better recruits (higher level or better quirks).
- [x] Building activities: click a slot (Belly Up to the Bar, Card Table...) to open a hero
      list and assign. Same for every similar mechanic in town.
- [x] Rebuilding the burned Smithy and Store is too cheap. After the tutorial you shouldn't be
      able to upgrade or rebuild anything; watch the scaling.
- [x] Side adventures from town: 2 short side paths (e.g. explore the mine, chase down a
      bandit camp) with a theme and a mini-boss. Rewards: a new hero, a rarer trinket.

### Trail
- [x] Scouting revealed 6 stops at level 1; tone down to about 2.
- [x] Curio stops: one curio to interact with, not a choice of several.
- [x] Trading post and traveling merchant prices should be higher.
- [x] A trinket-seller merchant as an event.
- [x] Supplies should be a configurable **inventory screen** (like DD) with slots, upgradable
      later with wagon slots.

### What shipped for round 2
- Arrow drops top-down onto the target. New guitar-strum victory sting; throatier growls and
  roars; a new bite sound for wolves, coyotes, gila monsters and crawlers.
- Tutorial: Marshal + Gunslinger only, fork stops unscouted, XP capped at 3 (a quarter of
  level 2), Mulligan with one gunhand and softer stats (bot wins ~96%, ends at ~40% health).
- Single first names (unique in the roster). Keepsakes are called trinkets everywhere you
  see them (data files still say keepsakes).
- Silas Crane, King of the Crows: crow on his shoulder, feather in his hat, summons a Murder
  of Crows, "Carrion Omen". His lieutenant and Mulligan wear crow feathers.
- Combat tooltips list every effect with real numbers; camp actions show numbers per rank.
  Each survival skill starts with one camp action; the second unlocks at rank 2. Hearty
  Stew and Trail Coffee use Food; Field Dressing uses a Bandage; Read the Sign now scouts.
- Hiring Board: 2 recruits a week; two upgrade tracks (More Notices, Word of Mouth).
- Buildings: click an empty slot to assign a hero (Saloon, Chapel, Boot Hill, Doctor, Stage
  Line); Smithy and Drill Hall use a workbench slot.
- Economy: start with 750 chips but only 4 Timber and 1 Iron; ruins cost full price; the
  tutorial pays 120 chips, 3 Timber, 1 Iron. Nothing can be built right after it.
- Side adventures from Fort Providence: Dry Gulch Mine (caves, tommyknockers, mini-boss Old
  Jeb) and The Crow's Nest (lots of fights, mini-boss Ruby Blackwing). Six columns long.
  First clear: a new level-2 hero, a rare trinket, Timber/Iron. Repeatable for training.
- Scouting reveals individual stops (Scout Ahead: 2 at rank 1). Curio stops hold one curio.
  Trading posts mark up 2.2x; peddler prices up; new Trinket Peddler event.
- Inventory: the wagon has 12 slots; items stack (Food 12, Bandages 6...). Embark is a store
  plus a wagon grid; the trail shows the wagon grid (click a slot to use it).

## Round 3 (not started: waiting on the art-direction discussion)

### Story & setup
- [ ] Enemies may keep nicknames when they're uniques or bosses (heroes stay single-name).
- [ ] Skipping the tutorial should start in town with exactly the post-tutorial setup.
- [ ] Don't auto-add the Preacher and Sharpshooter after the tutorial. Put one on the hiring
      board, and make the other a mysterious party member rescued in Dry Gulch Mine.
- [ ] Starting company size cap is 5, not 24.

### Store & supplies
- [ ] Curio tools (rope, shovel, crowbar, etc.) can't be bought until the General Store is
      built and upgraded.
- [ ] Until then, the wagon starts pre-packed with food, bandages and a little wagon parts.
      More must be found or bought.

### Balance
- [ ] Sermon on the Trail is too strong: halve its Fatigue relief and Accuracy buff.
- [ ] Sharpshooter damage feels very strong early.
- [ ] Question: does the Sermon's +5 Accuracy carry into the next fight? (Answer: no; see
      the reply. Consider showing buff durations on units.)

### Side adventures & camp
- [ ] Maybe side adventures have no campsite (a one-day trip). This leaves room for camp
      skills to grow and fits scarce early resources. Undecided.
- [ ] Scout Ahead at the campsite right before the boss is useless: nothing left to scout.

### Art direction (to explore first)
- [ ] The drawn-polygon look lacks wow factor. Explore AI image generation (ComfyUI or
      similar) with consistent style prompting for characters, backgrounds, buildings and
      items. Keep the storybook / paper-cutout / papier-mâché feel.
