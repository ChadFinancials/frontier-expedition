# Playtest Notes & Backlog

The owner plays from source after each batch and sends numbered notes. This file holds the
**open backlog** first, then a **history** of each round: what the owner asked for, what was
decided, and what shipped. Update both at the end of every round.

---

## Open backlog

### Bugs
- [ ] **Crashes in combat** (round 7 Mad Dog killing blow, round 8 idle mid-battle). Not a
      game bug: both crashed sessions' logs stop after startup with no error or backtrace, so
      the NVIDIA OpenGL driver killed the game. Round 8 switched the default renderer to
      **Vulkan** (Forward+); the owner reports it noticeably smoother. Watch for any further
      crash; `play_opengl.bat` is the fallback. Idle figures and HUDs also no longer redraw
      every frame.
- [ ] Jagged edges on circles and cut-outs: the project's 2D MSAA now takes effect under
      Vulkan (OpenGL ignored it). Check whether that is enough.

### Gameplay
- [ ] **The Lone Wanderer storyline (owner, later):** meet the wanderer again over time, as a
      recurring event that builds into a small quest line. The MVP duel is in.
- [ ] **Townsfolk: playtest the first build** (round 15). Watch how fast settlers arrive (eight
      events, about 1 in 5 quests), whether wages bite, and whether the producers are worth a
      plot. Later: moving townsfolk and heroes between settlements.
- [ ] **Wagon (owner, after the townsfolk):**
  - Some enemies and battles target the wagon, which sits behind the party: it loses
    condition and/or cargo. Rework **enemy ambushes** around this (switched off in round 7
    with config `hero_ambush: false`, including night-camp ambushes).
  - The wagon has **no** combat role beyond being a target: no cover, no wagon actions.
  - A **wagon upgrade track** (a building in town), with **expanded cargo** the big one.
  - More places for the wagon and resources to matter (materials already take wagon space;
    mishaps and events drain supplies).
- [ ] **More to do before the Tallgrass Sea (round 17, owner's ideas, awaiting picks):**
  - more Saloon rumor templates
  - short trips with a campfire halfway where you can head home early (supplies low, the
    wagon struggling) without the turn-back penalty
- [ ] **Small heals** (round 17-18): Flash the Badge is done. Still open: the Gambler or the
      Gunslinger, and a party Questionable Mushroom.
- [ ] Money: round 9 doubled every chip source (owner was running short: one quest paid about
      200, one bar visit and one move). Recheck after a few weeks of play; `chips_mult` in
      config scales all of it at once.
- [ ] Gunslinger bullet system: 6 rounds in the cylinder shown overhead, moves spend bullets,
      a Reload move.
- [ ] Class workshop, second half (`docs/HERO_PROPOSALS.md`): Preacher and Doctor done.
      Open: the Bayou Poisoner's 8th (Mosquito Swarm too close to Poison Darts; keep
      workshopping), the Prospector (on hold) and the Shotgun Guard. (Train Hopper shipped.)
- [ ] Decide whether utility moves need their own per-level upgrade paths (today every move
      level adds the same accuracy, damage, effect and healing bonuses).
- [ ] Stacked Deck "probably needs tuning" (round 8; owner: save for a later balancing pass). A second deal stacks on the first (two
      Jacks of Clubs = +24 Dodge). Proposed: a new deal replaces that hero's previous card.
- [ ] Hero balance: round 8 changes applied (see History); re-rank with
      `python3 tools/hero_power.py` after the next playtest. Pre-change ranking: Gambler 9,
      Bayou Poisoner 8, Rail Driver 7, Mountain Mystic 7, Gunslinger 7, Prospector 6,
      Wrangler 6, Marshal 6, Frontier Doctor 5, Preacher 4.
- [ ] Watch: Ruby Blackwing is hard and the crow summon strong; probably right (round 7).
- [ ] Second region onward (Red Canyons, Thunder Peaks, Redwater Ford) waits until the first
      region is crisp.

### Quality of life
- [ ] **Move animation pass** (owner, round 9: "End of the Line's animation is fantastic"):
      give the moves that matter a proper animation, like End of the Line's (wind-up, travel,
      impact, flash, shake, own sounds) instead of the shared small arm swing and one sound.
      Start with each class's signature moves and the bosses' big moves.
- [ ] **Trinket inventory screen**, like DD's (owner, round 9): a "Trinkets" button in the top
      bar opens an equip menu showing the stash and every hero's two slots side by side, to
      drag or click trinkets on and off. Needs an icon per trinket (49 today: 24 general,
      22 class, 3 boss) from the owner's icon pipeline (`prep_icons.py`) before it's worth
      building.

### Visuals
- [ ] **Big image pass (owner, later)** with the owner's image generator. It covers curio and
      event art, trinket icons, more backdrops and the like. Until then, the drawn
      placeholders are fine; don't spend effort polishing them.
- [ ] **Backdrops**: about ten more images in the owner's prairie style for stops across side
      quests and expeditions (composition rule: keep the lower middle open, see
      `COMFYUI_GUIDE.md` §7). Also the idea of rebuilding favourite drawn scenes in code from
      a painted reference, keeping quirks like the hanging clouds: the Crow's Nest, Dry Gulch
      Mine and its interior, the Old Mill Road, the town.
- [ ] Icons still drawn in code: `skull`; optionally the move-type and stat icons.
- [ ] Town depth: the street is plots side by side; look at DD's Hamlet (layered, angled
      buildings, foreground and background) without overdoing it.
- [ ] A world map between settlements, later.

### Economy
- [x] ~~A third town material~~: **Hides** shipped in round 9.
- [ ] Hides icon: the pelt is drawn in code; paint one through the icon pipeline.

---

## History

### Round 18: picks from round 17
- Flash the Badge now heals 2-3.
- **The Lone Wanderer's challenges:**
  - A new one-level Saloon upgrade, the Stranger's Table (300 chips, 6 Timber, 2 Hides), puts
    the challenge on the board on top of the chatter.
  - Three chapters, each a short trip ending in a showdown duel: no gang and no fight. The
    Wanderer draws 0.44, then 0.40, then 0.36 s.
  - Win on a bullseye, hit or graze; a bullseye pays half again. A loss sends you home and the
    challenge returns.
  - The last chapter pays the Wanderer's Silver Dollar, which draws 0.05 s faster in High
    Noon.
- **Still open:**
  - a heal for the Gambler or the Gunslinger (or neither)
  - a party version of Questionable Mushroom

### Round 17 (week 5 with the main company)
- **Skill checks:** at most difficulty 2 in the first region. Config `check_base` [2, 3, 3] and
  `check_cap` [2, 4, 5] by region tier.
- **The Lone Wanderer:** losing now costs +3 Fatigue (was +6, to the whole party). The owner
  saw +12; I could only find the +6.
- **Slower levels:** the Preacher hit level 3 in week 5. XP thresholds go from 19 / 56 / 113 /
  188 to 24 / 80 / 160 / 260, aiming for level 2 around week 3, level 3 around week 7 (after
  the Tallgrass Sea), level 4 around week 12 and level 5 around week 20. Levels already
  reached are kept.
- **Explainer text trimmed:**
  - The combat hint bar is gone: the move tooltips, enemy hit chances and the round and turn
    order line already cover it.
  - The Bones tooltip no longer says to attack them.
  - "Click ..." instructions are gone from the building panels, staff seats, Saloon chatter,
    Hiring Board, embark screen, wagon bar and hero sheet.
  - The "click a glowing stop" toast only shows in the tutorial.
- Noted:
  - Gila monsters: strong but fun.
  - The steady hand is better but still a bit clunky.
  - The reward felt good.
- **Waiting on the owner:**
  - small heals for the classes without one (`HERO_PROPOSALS.md`, round 17)
  - more to do between the story trips and the Tallgrass Sea (see the backlog)

### Round 16: High Noon and skill checks in the dev lab (owner)
- **High Noon:**
  - Smaller good zones: bullseye 4→3%, hit 14→10%, graze 30→22%.
  - The sight's pace now wanders instead of swinging smoothly, and it starts at a random
    point.
  - 4 s to take the shot, or it goes wide. A countdown shows under the bar.
  - The owner reacts in about 0.26 s, so opponents draw a little quicker: leader and hangman
    0.55→0.48, Pike 0.45→0.40, Mad Dog 0.50→0.45, the Lone Wanderer 0.50→0.44, the lab's
    fast gun 0.32→0.30.
  - The wait before DRAW is now 1.5-8 s (was 1.5-4).
- **Tumblers:**
  - A missed pin's light turns red.
  - The needle flashes green on a hit and red on a miss.
  - A click anywhere counts.
  - Difficulty 4 and 5 eased: notch 17→20° and 12→17°, sweeps 1.0→0.95 and 1.2→1.05.
- **Pattern:** felt right; no change.
- **Quick hands:**
  - Letters A-Z instead of arrows.
  - The ring closes faster: 1.4/1.2/1.0/0.85/0.7 → 1.1/0.9/0.75/0.65/0.55 s.
- **Steady hand:** reworked like Stardew's fishing.
  - The band rests for 0.8 s, then glides to new spots, easing in and out.
  - It sometimes darts (0-40% of moves by difficulty).
  - Top speed is 0.16-0.36 bar heights a second by difficulty, and the check lasts 5 s.

### Round 15: the wagon and the town (owner's direction)
- Brainstorm on the wagon and the town. The owner's picks:
  - **Wagon:** some enemies and battles target the wagon in the back (condition or cargo
    lost), plus an upgrade track with expanded cargo. No cover or wagon combat actions.
  - **Townsfolk first:** a roster like the heroes', with upkeep and growth. Heroes and
    townsfolk are always separate pools (no retiring into townsfolk).
- Drafted `docs/TOWNSFOLK_PROPOSALS.md`, then built it with the owner's answers:
  - Traits are their own pool, not hero quirks.
  - Empty buildings work as before.
  - Townsfolk come only from expeditions and quests: eight trail events, plus a settler on
    about 1 in 5 Saloon quests. Nobody is given at the start, and the Hiring Board stays heroes
    only.
  - Staff seats: 0 / 1 / 2 by building level.
  - Wages: 10 / 20 / 30 chips a week.
  - Producers: the Lumber Yard, Iron Mine and Trapping Post, with Loggers, Muckers and
    Trappers.
  - Moving between towns: later.
  - Screens: a Townsfolk roster, staff seats on building panels, and settler lines on the
    results screen.
  - Growing to a City now needs 8 townsfolk.

### Round 14: High Noon (owner's design)
- **The duel:**
  - Two parts: react to DRAW! (false cues first; too early is jumping the gun), then stop a
    swinging sight on bullseye, hit or graze.
  - Results carry into the duelist's gang fight at the next fight stop: dead, 50% HP and
    bleeding, or bleeding.
  - A miss Rattles the hero (-10 Acc, -5 Dodge) for the expedition.
- **Where:** the Lone Wanderer (new, for pride), the Outlaw Toll, the Wanted Poster, the
  Hanging Tree, and Mad Dog's standoff before his fight.
- **Curio skill checks:**
  - Tumblers (Strongbox, Railroad Crate), Pattern (Standing Stone, Lonely Grave), Quick hands
    (Collapsed Tunnel, Abandoned Wagon), Steady hand (Prairie Well, Miner's Cache).
  - Difficulty 1-5 from the hero's ★/✗ and quirks.
  - Clean → good 90%; close → leans bad; botched → bad. Supplies and as-key heroes skip it.
- **Dev:** "DEV: Minigames" on the main menu lets you try any class, quirks and opponent, with
  the timing numbers shown.

### Round 13 (week 4: the Crow's Nest)
- Party: Preacher, Gunslinger, Wrangler, Rail Driver. It felt very strong and most fights
  were trivial. The Rail Driver rolled very good starting moves.
- A couple of fights were just a Cutthroat and a Rifleman: easy, though both are fast.
- Ruby Blackwing was moderate; Fan of Knives missed its bleeds a lot.
- **Ruby's fight** (owner): Carrion Crows added in rank 4, in both the boss fight and the
  Stockade repeat.
- The loot (491 chips, 12 Timber, 2 Iron, 3 Hides, Blackwing Feather) felt fair.
- Built the Drill Hall; Laying On of Hands and Quick Draw to level 2.
- The weapon upgrade that felt steep (5 Iron) was tier 2→3 (600 chips, 5 Iron), not the
  first one. Owner: no change needed.

### Round 12 (week 3: Rustlers at Miller's Draw)
- **Rustlers:**
  - Every ordinary fight was 3-4 outlaws, and 3 in 8 were the full four, the same group as the
    final. Now: brawler, gunhand and rifleman (3); a new light pair, brawler and gunhand (2);
    two gunhands and a coyote (2); the full four (2).
  - Fewer fight stops: fight 48 → 42, event 16 → 20, curio 12 → 14.
  - Quests already on the board keep their old groups until they roll over.
- **Noted:** the Gunhand's Double Tap (2 random hits of 3-6) stands out against two or more
  gunhands, since their speed lets them open with it. No change for now.
- The haul (275 chips, 3 Timber, 3 Iron, 3 Hides) paid for the Bunkhouse.
- **Hero sheet kill tally:** it was never counted. It now counts killing blows, including bleed
  and poison ticks from that hero. It starts from 0 for existing heroes.

### Round 11 (weeks 2-3: Mad Dog's hideout)
- **Iron Justice** (owner): +15% damage vs outlaws, +5% per move level, stacking with +40% vs
  Marked (a Marked outlaw: +55% at level 1).
- **Money Shot:** a kill pays 30 chips +10 per skill level (was a flat 50). A shot that
  doesn't kill, misses included, loses a 10-chip stake.
- **Mad Dog's crew:** he now has a rifleman in rank 3 as well as his gunhand.
- **Story bosses with their own trinket** (Mad Dog's Brass Knuckles) no longer add a random
  quest trinket on top.
- **Answered:**
  - The Marshal has no built-in bonus against outlaws.
  - The free kit (16 Food, 1 Bandages, 1 Wagon Parts) covers an 8-column side region, about
    14 Food for four heroes. The 12-column Tallgrass needs about 22, so the warning steers new
    companies to side quests first. Owner to decide whether that's wanted.
- **Noted:**
  - The quest gave 2 Hides, short of the 3 for the Bunkhouse. Quest Hides are 0-2 plus the
    tips level, plus template bonuses (Wolves +3, Rustlers +2, Snakes +1).
  - The chip economy feels fine (1600 at the start of week 3, with some Money Shot farming).

### Round 10 (fresh party, weeks 1-2)
- **Starter Saloon quest:**
  - Skipping the tutorial never rolled the Saloon's first quest, so week 1 offered only Dry
    Gulch and the Crow's Nest. Rebuilding the Saloon now rolls its board at once.
  - Until the company has run a side quest, the board offers easy jobs only: difficulty 2 or
    less, no boss, and Mad Dog's rumor doesn't jump the queue.
- **Curio window:** as wide as the curios on offer (one on map stops), so it sits small in the
  middle.
- **Curio picker:** names only, like event options ("★ Marshal  ★ Gunslinger").
- **Revival Meeting:** 1-4 → 1-3 per hero (about 8 across a party of four at level 1, was
  about 10-12).
- **Old Jeb's Cave-In:** stun 40 → 60%. Against hero stun resist (30-50) it was 10% at best,
  and 0% against the Marshal and Preacher. Now about 30% / 20% / 10%.
- **General Store rebuild:** 300 chips, 10 Timber, 2 Iron → 500 chips, 14 Timber, 4 Iron and
  2 Hides. The Hides push it past an early hunt.
- **Answered:**
  - The Standing Stone's experts are the Mountain Mystic and Storyteller; the Miner's Cache's
    are the Prospector and Miner. That company had none, hence no marks.
  - The Dead Horse ambush is 1 in 9: the Marshal turns it into a bounty, and the Gunslinger
    strikes first.
  - Old Jeb's first defeat always gives the Miner's Lamp and frees one hero missing since the
    fort burned. Repeat clears give a random rare or uncommon trinket.
- **Noted:** a company without area attacks (Marshal, Train Hopper, Gunslinger, Preacher) feels
  the bosses; two Tommyknocker stuns in round 1 hurt.

### Round 9
- **Event pass 2:**
  - 12 new events.
    - Common: Campfire Card Game, Medicine Show.
    - Tallgrass: Twister, Cattle Drive.
    - Dry Gulch: Powder Shack, Tapping Underground, Tommyknockers, Runaway Burro, Ore Wagon
      Wreck.
    - Crow's Nest: Wanted Poster, Hanging Tree, Stagecoach in Trouble.
  - 7 new illustrations.
  - Follow-up choices: the haint grave, the padlocked cellar, the twister's strongbox.
  - `hide_if` for options: a Marshal won't steal.
  - Side-quest theme lists filled out.
  - Dry Gulch and Crow's Nest maps now draw from 21 possible events each, up from 10.
- **Event pass 1** (owner: common + region pools, ★/✗ names only, 30% compel, two passes):
  - Event stops draw from a common pool (13 trail-life events, 45%) or the region's own list
    (55%); side quests add a theme list (40/30/30).
  - Event options take experts, using the curio rules over the whole company, now with
    quirks: odds, bonuses, swaps, extra outcomes, free supplies and fight setup (foes
    wounded, a lookout dropped, foes Vulnerable, who strikes first). The option shows
    "★ Wrangler  ✗ Overweight".
  - Bad-quirk options compel at 30%: Drinker ×2, Gold Fever ×2, Too Curious, Hothead ×2,
    Spooked by Critters.
  - 26 new secret options for classes and quirks across the existing events.
  - Wet powder (-5 Acc next fight) after the river tips and the storm.
  - Prairie Fire's Whiskey text fixed.
  - The four do-nothing options now give a little.
- **Breaking Points and True Grit** (owner's pass): renamed away from Darkest Dungeon's terms
  (Second Wind → True Grit, Resolve Test → Gut Check, Death's Door → Last Legs, Deathblow
  Resist → Cheat Death; Breaking Point stays; ids unchanged). Heartsick (was Homesick, which
  clashed with the quirk); Reckless Vulnerable 10% instead of -10 Prot; Ornery (was
  Short-Tempered) taunts on its own; Cowardly -10% Dmg, Vulnerable 15% in ranks 1-2; Greedy
  starts each fight Marked, +15% Loot; Paranoid +4 Spd in round 1. Steadfast gives the most
  wounded hero +15 Prot when it lands, then a smaller lingering buff; Dead-Eye (was
  Sharp-Eyed) Marks enemies, +10% Dmg vs Marked; Mule-Headed (was Grit) +15 Cheat Death on
  Last Legs; Fired Up +10% Crit vs Vulnerable; new Cool-Headed (+20% Healing Received, +20
  Debuff Res, clears Bleed or Poison).
- **Curio experts** (owner: make the class and skill pick matter; first region first, ★/✗
  shown): the 16 curios of the Fort Providence area list experts by class or survival skill
  (better odds, bonuses, swaps, 5 work-as-key pairs, 2 averse classes); Gunslinger and Tracker
  quick draw on curio ambushes; the hero picker shows the lines. New 15% quirks: Spooked by
  Critters (wagon snake), Claustrophobic (tunnel rockfall), Unbeliever (scarecrow straw), Iron
  Stomach (wrong berries). See CURIO_PROPOSALS.md; later regions' curios still to do.
- **Hides, a third town material** (owner's pick): the hunting and leather economy beside
  Timber (building) and Iron (metal). They're cargo, come home in the wagon, and show in the
  top bar, trail HUD and results.
  - *Found:* beasts drop them (wolves and coyotes 50% for 1, rattlesnakes 30%, gila monsters
    40%, buffalo and grizzlies always 2-3, stone rams 1-2: enemy field `hides`); the Hunter's
    Go Hunting (35% for 1) and the Trapper's Set Snares (30%); Tan Pelts now makes Hides
    (1 + 1 per rank) and fewer chips (20 + 20 per rank); the Dead Horse's saddle leather; the
    Buffalo Herd, Good Hunting, Wolf Tracks and Trapper's Cabin events; side quests 0-2 (+tier;
    Wolves +3, Rustlers +2, Snakes +1: template `bonus_hides`); Crow's Nest boss 3.
  - *Spent:* armor upgrades take Hides instead of Iron (2/5/9/14; weapons keep Iron); level 1
    of the Saloon (2), Doctor (2) and Stage Line (4), all three levels growing from there;
    levels 2-3 of the General Store, Smithy and Drill Hall; both Bunkhouse upgrades (3, 8);
    growing to a Town (12) or City (30); founding an outpost (4). New games start with 0.
- Owner's Dry Gulch run (all level 2: Marshal, Prospector, Preacher, Train Hopper): the
  hardest region so far; Marshal on Death's Door, Preacher at 160 Fatigue; caves heavy on
  Fatigue (bats and tommyknockers); End of the Line animation great; income better; three
  heroes hit level 3 too fast.
- Shipped: XP thresholds +25% (19 / 56 / 113 / 188, was 15 / 45 / 90 / 150); Giant Bat Dodge
  20 (was 30: four bats were near unhittable); Knock, Knock comes up half as often (weight 1,
  was 2; the Oversized Pick stays 2); **Sit a Spell on the Porch** on the Hiring Board: free,
  one seat a week, up to 15 Fatigue (activities can now set their own `slots`); Bunkhouse
  +4 then +6 bunks (was +2 then +4), so the first upgrade takes a town to 10.
- **Enemy damage dial back to 1.0** (owner; was 0.9): enemy weapon damage up about 11%. That's
  41 of the 61 enemy attacks; the 20 with their own damage range were never dialed.
- **Saloon prices halved** (owner): Belly Up to the Bar 75 chips (was 150), Card Table 50
  (was 100); Fatigue relief unchanged.
- **Chips doubled** (owner: running low; a saloon quest paid about 200, barely one bar visit
  and one new move): enemies 10-24 per kill (was 5-12), bosses 500 × tier (was 250), region
  boss rewards ×2, side quests 160-300 (was 80-150), curio and event chips ×2, Trapper and
  Miner camp chips ×2. New dial `chips_mult` (1.0) scales every chip earned. The `econ=N`
  probe now reports chips per run home (bot: ~315; it usually turns back early).
- **Trinket pass** (owner's picks, TRINKET_PROPOSALS.md): 22 class trinkets (2 per class,
  class-locked, dropping at their rarity like any trinket; the owner turned down a roster bias), 4 general trinkets
  reworked off their quirk copies, 5 new general ones; 49 in all. Hooks: `class`,
  `skill_mods`, conditions `guarding` and `poisoned`, stats `heal_out_pct`, `stun_chance`,
  `poison_dot`, `momentum_start`, `momentum_bonus`, `card_pct`.
- **Iron** (owner: 23 timber but under 8 iron after 2 expeditions, so no Smithy): Tallgrass's
  trail curios almost never gave iron, and every recurring source paid less iron than timber.
  Smithy level 1 is now 10 timber + 5 iron (was 8 + 8); elites always give 1-2 iron (was 0-2);
  side-quest rewards 1-3 iron (+tier; was 0-2); the Miner's Prospect 2 + 1 per rank (was 1 +
  1); the Railroad Supply Crate (iron) can turn up in Tallgrass and Crow's Nest. Probe:
  `res://tests/test_runner.tscn -- econ=N` (bot expeditions, materials per run; the bot loses
  often, so read it as relative).
- **End of the Line**: whistle, run-up, charge with speed streaks, heavy impact; a kill gives
  back 20 Momentum (was 50).
- **Quirk pass** (owner's edits, see QUIRK_PROPOSALS.md): 50 quirks (26 good, 24 bad). New
  conditions `marked`, `vs_marked`, `vs_vulnerable`, `deaths_door`, `round1`; stat `xp_pct`;
  quirk fields `bar_lock`, `after_battle_fatigue`, compulsion `steals`.
- Owner playtest (Mad Dog, all level 1: Doctor 4, Preacher 3, Prospector 2, Mountain Mystic
  1): healing very strong, damage decent, back-line access short until the bones in ranks 1-2
  were cleared; not too hard.
- Shipped: Battlefield Surgery stuns the patient again (95%, the cap) on top of -5 Protection,
  so it's no longer strictly better than Laying On of Hands. The owner's wagon art is the
  trail, menu and camp wagon (`assets/art/props/wagon.png`, cut out with `prep_icons.py
  --prop`), oxen still drawn in code. The Fort Providence painting runs under the roster
  panel's edge (no strip of screen between them).

### Round 8
- Owner: painted backdrops look stretched and pixelated; top-bar numbers float away from their
  icons; Stacked Deck shows all cards at once; more than two rows of buffs and debuffs vanish
  under the HUD; a crash mid-battle while idle.
- Shipped: numbers sit right beside their icons (shared `UI.res_item`, top bar and trail);
  Stacked Deck deals one card at a time; status chips are short tags ("ACC +10"), the
  fighters stand 25 px higher so three rows fit, overflow folds into "+N"; idle figures and
  HUDs stop redrawing every frame. Backdrops: not stretched (the aspect is kept), just a
  1344-wide image blown up 1.5-2x; the owner is regenerating them at 1344 x 768 plus a 2x
  model upscale (`COMFYUI_GUIDE.md` §7); the first larger pair replaced the prairie set.
  New screenshot args: `statuses`, `with=`, `soak=`.
- Crash logs showed no backtrace (a driver kill under OpenGL). `play_vulkan.bat` tested the
  Vulkan renderer; the owner found it much smoother, so **Vulkan is now the default**, with
  OpenGL as the automatic fallback and `play_opengl.bat` to force it.
- **Balance** (owner's picks from the hero ranking; heal ranges are as shown in game, after
  the 0.8 heal multiplier). Expected value per cast vs the average tier-1 enemy, before -> after:
  - Deal 'Em: bleed 2 -> 1 a round (3 rounds), accuracy 87 -> 85: ~22.8 -> ~15.7 damage.
  - Bola Shot: stun chance 80 -> 70%: 0.70 -> 0.55 expected stuns.
  - Preacher: Laying On of Hands 4-7 -> 6-10 (5.6 -> 8.0); Revival Meeting 1-3 -> 1-4 (it was
    stored 1-4 but the multiplier rounded the top to 3; 8.0 -> 9.6 for the party); speed 1 -> 2.
  - Frontier Doctor: Battlefield Surgery no longer stuns the patient and leaves them at -5
    Protection for 2 rounds (the +25 Protection is gone); its heal stays 8-12 as shown. HP 16 -> 18.
- **Dials**: `hero_dmg_mult` (0.9) and `heal_mult` (0.8), added in batch 1 to turn early
  damage and healing down, were folded into the data and set to 1.0, so hero weapon ranges
  and heal ranges read in the data exactly as they play (gameplay unchanged). The hero dial
  now also covers moves with their own damage range. `enemy_dmg_mult` stays 0.9. The review
  sheets now round like Godot (halves up), fixing a few ranges they had shown one too low.
- **Vulnerable** (new): +10% damage taken from every source, damage over time included, as a
  debuff on Serve a Warrant, Quarrel, Hogtie, Assign the Joker, Peck at the Eyes, Locking Bite
  and Tree-Trunk Club. Recasts refresh rather than stack. Cures remove it.
  - Tuning pass (owner): Vulnerable came off the marking moves (Warrant, Quarrel, Joker) so
    no move both marks and amps; Peck at the Eyes bleed is 2 rounds; Hellfire is -5 Accuracy
    and -10% Damage; Scalpel Toss hits ranks 1-3 with +2% crit.
  - Depth pass (owner's picks): Vulnerable 10% for 2 rounds on Pickaxe, Righteous Smite,
    Point Blank and Sledge Toss, and for 1 round on Axe Cleave. Marked payoffs on Iron Justice
    (+40%), Money Shot (+40%, bounty stays 50), Hammerfell (+30%) and Book of Judgment (+40%),
    so every marking hero can cash in their own mark. Move tooltips now show "+N% vs Marked".
- **Three-quarter bodies** (owner, from a Darkest Dungeon screenshot): heroes and human
  enemies now turn toward their facing side: chest open forward, weapon arm from the back
  shoulder across the body, far arm steadying the weapon, weapons held low and ready.
  `Figure.three_quarter` (false: the old side-on build); shot arg `side` for before/after; `shot=faces poses small classes=a,b,c,d` checks every pose.
- **Train Hopper** (new class, owner's kit; design in HERO_PROPOSALS revision 4): a
  single-target burster. Momentum gauge (moves +20/+30, moved by others +10, idle turn -10,
  stunned -25; Full Steam at 50: +3 Speed, +5 Dodge) and the mega **End of the Line** at 100
  (10-18, +50% vs Marked, ignores half Protection, lands in rank 1, a kill gives back 20; was 50).
  Moves: Boxcar Leap, Stowaway, Chart the Hills, Railspike Toss, Emergency Brake, The Dancing
  Man, Ride the Rods (+4% crit), Catch Out (swap with any ally, ally +10 Prot, flat +20).
  Look: flat cap, long coat, a railspike and a polka-dot bindle; three outfits. In the bot
  sims she reaches End of the Line in about 7 of 12 fights.
- **Bones** (owner, Darkest Dungeon's corpses): a fallen enemy leaves 2-HP bones in its rank;
  the line only slides up once they're destroyed. Back-liners stay harder to reach, AoE and
  random hits can clear them, they never act or take effects, smashing them isn't a kill,
  and summoners sweep them aside on a full line. `bones_hp` in config (0 turns it off).
- **New moves** (owner's picks): Preacher **Hellfire Sermon** and **Baptism in the River**
  (dispels boons, Soaked, stuns mythic foes); Frontier Doctor **Transfusion** (heals the most
  wounded ally for 150% of damage dealt) and **Scalpel Toss** (in place of Adrenaline Shot, to
  keep the Doctor from being all heals). Both classes now have 8 moves. Engine: `dispel`,
  `if_tag`, `chance_vs`, `refresh`, `transfuse_pct`.
- **Town painting** for Fort Providence (owner's): its painted buildings are the plots.
  Each building has a spot that suits it (the two-storey yellow one is the Saloon, the big
  barn the Smithy, the front house with a porch the Hiring Board...); empty lots take the most
  prominent free spots; spots beyond the town's plot count stay scenery. Wooden boards mark
  them: the name on the roofline, a red CLOSED board on a post for buildings to rebuild (the
  owner's idea, instead of burned ruins), VACANT for empty lots. Hover glows the ground.
- Under Vulkan, dying enemies showed a grey box: the figure's paper group (a CanvasGroup)
  faded through its parent. Units now leave the paper group before a death, a summon's
  fade-in or a scripted retreat (`UnitView.unpaper` / `repaper`). Owner confirmed fixed.

### Round 7 (continuing the owner's save from here on)
- Owner: text on the wood is hard to read; the map looks much better; ambushed in the first
  Crow's Nest fight and it was brutal; white-noise clicks and the hover sound are unpleasant;
  Fan the Hammer hits 3 times but spacing is odd and only 2 sound; stacked numbers still
  overlap; Revival Meeting shows one hero at a time; Prospector should find more in caves.
- Shipped (`e808468`): text areas on wood sit in a dark `Inset` well; **enemy ambushes off**
  (`hero_ambush`); a soft wooden click, no hover sound; multi-hit moves play a sound per hit
  with even spacing; stacked popups spaced 46 px; group moves (Revival Meeting, AoE) show all
  results at once; Prospector `cave_loot_pct` 25.
- Answered: hero levels add HP, damage, accuracy and crit and raise gear and move caps; move
  levels add accuracy, damage, effect chance and healing.
- **v0.7** (`32d857c`): version bump and a refreshed Windows download. The tag push is left to
  the owner (blocked from the cloud container).

### Art pass: icons and backdrops (after round 7)
- The owner now makes art in ComfyUI and hands it over in chat; originals kept in `art-src/`.
- Icons (`1c965ea`, `b59a18f`, `fed0e03`): 17 painted icons for every supply and resource.
  `tools/art/prep_icons.py` cuts them out. The **Crowbar is retired**; its five curios open
  with the Shovel.
- Backdrops (`e7c5c05`): the owner's **prairie** set on the tutorial and every Saloon rumor;
  shared backdrops show outdoors only; combat picks the variant by map progress.

### Round 6
- Owner: the front elbow bends the wrong way; the map click is loud and the sound overall is
  bad; a crash in the tutorial boss fight (not reproduced); the prairie wolf elite is too
  much; the Mountain Man should beat beasts; damage ticks before the animation; the window
  title says (DEBUG); scouting text should show back on the map; stacked text overlaps; caves
  are too easy and the light is moot; no way to reorder the party after a scramble; Cave-In is
  far too strong. Plan first, then ComfyUI work goes to the PC agent.
- Shipped: elbows bend as a `<`; every sound levelled to one loudness
  (`tools/level_audio.py`, `levels.json`); no (DEBUG) title; road news after fights
  (`d91df31`). HUD bars move when each hit lands; popups one at a time (`a0d8b2b`). Hero
  moves +2 accuracy (enemies unchanged); prairie wolf 10 → 8 HP; Mountain Mystic +20% damage
  and +2 accuracy vs beasts; Cave-In hits 2 random heroes; caves 3-4 enemies and light drains
  30 per room with a visible meter (`62f3a7f`). Party reorder on the map and between cave
  rooms (`f3372e9`). Wood-and-rope UI drawn in code and the map redrawn as a parchment trail
  map (`d5019ea`). Painted icon loader (`39cd08b`).

### Characters (between rounds 5 and 6)
- Ink illustration look for every character (owner's pick of five styles); profile faces at
  rest with storybook reactions in action poses; three color outfits per class. See
  `ART_PIPELINE.md`.
- Turn order: Speed plus a small 1-3 roll each round; action diamonds per unit.

### Hero review (after round 5)
- Heroes know their two stock moves plus two random ones and learn the rest at the Drill Hall
  (300 chips). Skills, weapons and armor go to level 5 (building level caps 2 / 4 / 5; gear
  tier needs that hero level; a move at most one level above the hero's).
- Every class reworked to 6-8 moves (`HERO_REVIEW.md`): Marshal; Mountain Man → **Mountain
  Mystic**; Rail Driver, Gunslinger, Wrangler, Gambler (8 moves each; Stacked Deck shows the
  dealt cards; Money Shot pays 50 chips per kill); Sharpshooter → **Bayou Poisoner**;
  Prospector, Frontier Doctor and Preacher retuned.
- Engine: fixed damage ranges per move, Armor Piercing, cure all debuffs, blood-price self
  damage, self-buffs last their full rounds, enemies go for Marked heroes half the time.

### Round 5
- Sounds: gunshots, impacts, blades and the howl back to the generated ones; recorded
  creatures, glass, chips, cards and clicks kept. No double sounds.
- Tutorial: weak tutorial-only enemies and a new boss, **Crowbar Pete**; no ambushes.
  **Mad Dog Mulligan** moved to a Saloon rumor that jumps the queue until beaten.
- Map: "ONWARD" signpost instead of a compass; difficulty ratings on expeditions; at most 2
  caves per trail; fights sometimes leave a curio (30%, elites 50%).
- Town: Hiring Board tracks (More Notices, Word of Mouth, Bunkhouse); company starts with room
  for 6; a recruit with no bunk waits on the board. Saloon bar side effect spelled out.
- Death's Door: the hit that knocks a hero onto it (and the rest of that move) can't kill;
  warnings for heroes starting a fight on it; ally death +15 Fatigue, Death's Door +6.

### Round 4
- Recorded CC0 sound packs (Kenney, OpenGameArt) via `tools/import_sfx.py`.
- Longer trips: main trails 12 stops with two camps, story side adventures 8, rumors 7.
  Slower levelling: XP at 15 / 45 / 90 / 150.
- Enemy workshop (`ENEMY_REVIEW.md`): every Fort Providence enemy and boss tuned; engine
  support for per-move damage ranges, flat damage buffs, pack buffs, multi-summons,
  opener and once moves, low-HP move priority and repositioning.
- Testing focus locked to the first region.

### Round 3
- Enemies may keep nicknames when unique; heroes are single-name. Skipping the tutorial gives
  the post-tutorial setup. The Preacher waits on the Hiring Board; the other starting hero is
  rescued in Dry Gulch Mine.
- Curio tools need the General Store; until then the wagon leaves with a free kit.
- Weekly **Saloon rumors** from `data/quests.json` (Chatter and Loose Lips tracks).
- Side adventures toughened slightly; elite materials tied to wagon space; "Resisted Stun"
  says what was resisted; the Crow's Nest pays the Blackwing Feather, not a hero.
- Art: the **paper-theater** look everywhere (combat, trail, events, curios, camp, cave,
  town, menu); a "DEV: Win" button in combat; ComfyUI explored for painted art.

### Round 2
- Targeting arrow drops top-down; new victory sting; throatier animal sounds; tooltips with
  real numbers.
- Tutorial with 2 heroes (Marshal and Gunslinger), unscouted fork, XP capped at 3.
- Silas Crane, King of the Crows (crow minions, Carrion Omen). Keepsakes renamed **trinkets**
  in the UI.
- Camp skills reworked (one action at rank 1, the second at rank 2; some use supplies).
- Town: building slots you click to assign heroes; rebuilding priced so nothing can be built
  right after the tutorial; 2 recruits a week.
- Side adventures from Fort Providence: Dry Gulch Mine and The Crow's Nest.
- Scouting toned down; curio stops hold one curio; trading posts mark up 2.2×; Trinket Peddler
  event; a 12-slot wagon inventory with stacking.

### Round 1
- Keep: the Slay the Spire-style branching map.
- Shipped in batch 1: **chips** and the Great Casino, map intel and scouting, the wagon bar,
  wear and mishaps, supply-draining events, crit relief labelled, trinkets on the trail,
  slower and clearer combat, balance tuning.
- Batch 2: burned-out Fort Providence (Hiring Board plus three ruins), the Old Mill Road
  tutorial that rebuilds the Saloon, Silas Crane's scripted first meeting (Crane's Gambit)
  and a wounded Silas afterwards, a clear SELECTED move, move-type and stat icons.
