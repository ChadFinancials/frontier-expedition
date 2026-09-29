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

## Round 3

### Story & setup
- [x] Enemies may keep nicknames when they're uniques or bosses (heroes stay single-name).
- [x] Skipping the tutorial should start in town with exactly the post-tutorial setup.
- [x] Don't auto-add the Preacher and Sharpshooter after the tutorial. Put one on the hiring
      board, and make the other a mysterious party member rescued in Dry Gulch Mine.
- [x] Starting company size cap is 5, not 24.

### Store & supplies
- [x] Curio tools (rope, shovel, crowbar, etc.) can't be bought until the General Store is
      built and upgraded.
- [x] Until then, the wagon starts pre-packed with food, bandages and a little wagon parts.
      More must be found or bought.

### Balance
- [x] Sermon on the Trail is too strong: halve its Fatigue relief and Accuracy buff.
- [x] Sharpshooter damage feels very strong early.
- [x] Question: does the Sermon's +5 Accuracy carry into the next fight? (Answer: no; see
      the reply. Consider showing buff durations on units.)

### Side adventures & camp
- [x] Maybe side adventures have no campsite (a one-day trip). This leaves room for camp
      skills to grow and fits scarce early resources. Undecided.
- [x] Scout Ahead at the campsite right before the boss is useless: nothing left to scout.

### Art direction (to explore first)
- [x] The drawn-polygon look lacks wow factor. Explore AI image generation (ComfyUI or
      similar) with consistent style prompting for characters, backgrounds, buildings and
      items. Keep the storybook / paper-cutout / papier-mâché feel.

### Round 3, part 2 (both side adventures)
- [x] Side adventures felt pretty easy. Give enemies a slight buff or more 4-enemy fights, but
      early side quests should stay fairly easy.
- [x] Elite fights paid 5 Timber and 3 Iron (random 2-5 / 1-3), which feels like a lot.
      Materials should depend on what the wagon can carry (tie into the inventory).
- [ ] Find more places for the wagon to matter.
- [ ] Ruby Blackwing needs cooler, better moves (enemy deep dive).
- [x] "Resisted" is unclear. It means a status (stun, bleed, poison, knockback, debuff)
      failed to stick against the target's resistance; damage is unaffected. Show which one,
      e.g. "Resisted Stun".
- [x] The Crow's Nest shouldn't give a hero, only the Blackwing Feather, as the first
      uncommon/rare trinket you can get.

### Plan
- Art: a "paper theater" pilot on one combat scene first, then roll out if approved. Kept
  separate from gameplay changes. ComfyUI (local, RTX 4070 Ti Super) stays an option for
  backgrounds later.

### Art & tools (done)
- [x] Paper-theater look rolled out everywhere: combat, trail and map (parchment), events
      (new illustrations), curios, camp (paper moon and stars), cave (lamplight pool), town
      (layered street, palisade, props), menu, and a light paper grain over the whole UI.
- [x] Dev "DEV: Win" button in combat for fast testing (remove later).
- [x] Replace generated sound effects with a free (CC0) pack (see Round 4). The network policy
      blocks the usual sites; either allow them or drop a pack into assets/audio.

## Round 3, part 3
- [x] Level-1 heroes start with 5 less HP.
- [x] Weekly side quests from Saloon "chatter": random quests from a pool (data/quests.json),
      each with a chance of a boss, a rare trinket or a recruit. The Saloon has two upgrade
      tracks: Chatter (1 → 2 → 3 quests a week) and Loose Lips (better rewards).
- [x] Company size starts at 5 and grows with settlements (town 5, city 8, each outpost +2).
- [ ] Find more places for the wagon to matter (materials now take wagon space).
- [ ] Ruby Blackwing and the rumor mini-bosses need their own moves (enemy deep dive).

## Round 4
- [x] Sound effects: recorded CC0 sounds (Kenney packs, OpenGameArt) replace the generated
      ones for gunshots, impacts, blades, glass, coins/chips, cards, paper, footsteps and all
      the animals (crows, dogs, growls, roars, bats, bites, howl, ghosts). Built by
      tools/import_sfx.py; sources in assets/audio/CREDITS.md. Music is unchanged.
- [x] Map hover text looked odd: the paper layer broke the UI theme, so the map fell back to
      Godot's default grey tooltip. Fixed for everything inside a paper layer.
- [x] Longer trips: main trails 9 → 12 stops (two camps), story side adventures 6 → 8,
      Saloon quests 5 → 7. Free kit food 12 → 16, recommended food 18 → 24.
- [x] Slower levelling: XP per stop 2 → 1, boss 6 → 5; levels at 15 / 45 / 90 / 150
      (was 12 / 32 / 60 / 100). Roughly: a side quest ≈ 13 XP, a main trail ≈ 20.
- [ ] Jagged edges on circles and cutouts (aliasing). Later.
- [ ] Cave lamplight is too easy to ignore. Expand later.
- [x] Enemy deep dive: docs/ENEMY_REVIEW.md (tools/enemy_sheet.py) lists every enemy and move.
      Tuned every Fort Providence enemy and boss (outlaws, wolves, snakes, crows, coyote, haint,
      lieutenant, bull, Silas, Mulligan, claim jumper, bat, tommyknockers, Jeb, Ruby, crawler).
      New engine support: per-move damage ranges, flat damage buffs, stacking pack buffs,
      multi-summons, opener/once moves, low-HP move priority, out-of-position repositioning.
- Focus: testing is locked to the first region (Tallgrass) and its side adventures and quests.
  Red Canyon / Thunder Peaks enemies and the second settlement wait until the start is crisp.

## Round 5
- [x] Sounds: gunshots, rifles, shotguns, punches, blunt hits, slashes, clangs, stomps, bells,
      explosions and the howl are back to the old generated ones. Kept the recorded bat bite,
      crows, growls, roars, dogs, ghosts, glass, chips, cards and UI clicks. Coyote yipping keeps the
      recorded howl ("yip"). Laying On of Hands rings the bell. Knock Knock is two slow, loud raps.
      Moves with their own sound now play the generic impact quietly (it doubled up before).
- [x] Tutorial: Looter and Greenhorn Gunman (weak, tutorial-only) replace the outlaws; the Old Mill
      boss is now Crowbar Pete, Mulligan's second. No ambushes in the tutorial.
- [x] Mad Dog Mulligan moved to a Saloon rumor ("Mad Dog's Hideout"): always ends at Mulligan,
      jumps the rumor queue most weeks until he's beaten, pays Brass Knuckles.
- [x] Trail map: compass rose removed, "WEST" arrow now reads "ONWARD". World map later.
- [x] Expedition hover text shows difficulty (Gentle / Fair / Tough / Hard / Deadly).
- [x] Hiring Board: More Notices costs chips only (500, then 1200). New Bunkhouse track (+2 / +4
      company size). Company starts with room for 6. A recruit with no free bunk now waits on
      the Hiring Board instead of vanishing.
- [x] Saloon bar side effect spelled out: "12% chance each visit: the hero picks up the bad Drinker
      quirk (-4 Accuracy, may compulsively grab whiskey on the trail)".
- [x] At most 2 caves per trail (Dry Gulch cave weight lowered). Fights sometimes (30%, elites
      50%) leave a curiosity to search afterwards, like DD.
- [x] Saloon rumor money +25%. Widow's wolf den pays 150 chips (was 80); "trade stories" rest is
      smaller (-5 Fatigue, 5% heal).
- [x] Dark Commune heals a flat 6 HP (was 25%).
- [x] Death's Door: the hit that knocks a hero onto it, and the rest of that same move (multi-shot
      volleys like Fan of Knives or the Fusillade), can't kill. Heroes who start a fight still on
      Death's Door (it carries over until healed) get a warning. A hero dying costs every ally
      +15 Fatigue; an ally hitting Death's Door costs +6.
- [ ] Next: hero-by-hero move review.

## Hero review, part 1 (Marshal, Mountain Mystic)
- [x] Heroes start knowing 4 random moves of their class (always at least two attacks) and learn
      the rest at the Drill Hall (300 chips, cheaper with a better hall), which also trains them.
      Unlearned moves show greyed out on the hero sheet. Old saves keep what they had equipped.
- [x] Skills, weapons and armor now go to level 5 (Drill Hall / Smithy: 2 / 4 / 5 by building
      level; gear tier needs that hero level, a skill at most one level above the hero's).
- [x] Marshal reworked: Weighted Shot (knockback 2), Flash the Badge, Armor-Piercing Rounds.
- [x] Mountain Man is now the Mountain Mystic: Gnarl at the Flesh, Take a Piece of Me,
      From the Shadows, Edible Meat; back-line Bear Trap and Bellow.
- [x] Engine: hero moves can have fixed damage ranges; Armor Piercing stat; cure all debuffs;
      blood-price self damage (never below 1 HP); a self-buff now lasts its full rounds (it no
      longer ticks down on the turn it's cast).
- [ ] Remaining heroes: Rail Driver, Gunslinger, Wrangler, Gambler, Prospector, Sharpshooter,
      Frontier Doctor, Preacher (6 moves each until reworked; they start with 4 of the 6).
- [ ] Decide how skill / weapon / armor levels 1-5 scale together.

## Hero review, part 2 (Rail Driver, Gunslinger, Wrangler, Gambler)
- [x] All four reworked to 8 moves (see docs/HERO_REVIEW.md). Stacked Deck now shows the dealt
      playing cards. Money Shot pays 50 chips per kill. Enemies go for Marked heroes half the time.
- [ ] Future: Gunslinger bullet system (6 rounds in the cylinder shown overhead, moves spend
      bullets, a Reload move).
- [x] Sharpshooter is now the Bayou Poisoner (7 moves, poison synergy, blowgun). Prospector (6),
      Frontier Doctor (6) and Preacher (6, stats only) retuned.
- [ ] Workshop later: Prospector 7th/8th move (forced guard + strapped dynamite that goes off when
      the guarded unit is attacked?), Doctor 7th/8th, Preacher's full kit, Poisoner's 8th.
- [ ] Next: ComfyUI character tests.
