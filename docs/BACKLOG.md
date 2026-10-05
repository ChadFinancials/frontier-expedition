# Backlog

Everything talked about with the owner that isn't built yet, in one place. What shipped, and
why, is in `PLAYTEST_NOTES.md` (one entry per round). Update this file whenever a round adds,
settles or finishes an item.

**Status:**
- **Decided:** the owner agreed. Ready to build when its turn comes.
- **Owner's call:** proposed, waiting for the owner to pick.
- **Idea:** raised in conversation, not decided.
- **Watch:** check during the next playtest.

The source (round N) points to the round in `PLAYTEST_NOTES.md` where it came up.

---

## Watch on the fresh run (round 20 onward)

The owner is starting a new run to test the round 16-20 changes.

- **Building locks:** whether the plans rumors land at the right moments (Doctor's Office
  week 3, Drill Hall week 4, Iron Mine week 5), and whether the townsfolk unlocks (Chapel,
  Boot Hill, Trapping Post, Wheelwright) arrive too late. (round 19)
- **Levels:** XP thresholds 24 / 80 / 160 / 260, aiming for level 3 around week 7. (round 17)
- **Crits:** -1% on every class, move and crit buff. If crits still feel common, the next
  lever is the +1% crit per level (`level_crit`). (round 20)
- **Skill checks:** first-region checks are capped at difficulty 2. The steady hand is better
  but "still a bit clunky". The owner will send more tuning notes for High Noon and the
  checks. (rounds 16-17)
- **Townsfolk:** how often settlers turn up, whether wages bite, whether a producer is worth
  a plot. (round 15)
- **The Lone Wanderer's three challenges:** their first real play, including the showdown
  finale. (round 18)
- **Half-blind map choices:** the rough look is 50% + scouting, the clear look 10% +
  scouting, the Scout skill 20 / 30 / 40, plus 15% false alarms. (round 21)
- **Smaller checks:**
  - Gold Fever's 25% grab, 50% pocket (round 20)
  - storehouse sell prices of 30 / 40 / 50% (round 20)
  - Transfusion at 1:1 (round 20)
  - the Wrangler's new ranks (round 20)
- **Money:** round 9 doubled every chip source. Recheck after a few weeks; `chips_mult`
  scales all of it at once. (round 9)

## Expeditions and quests

- **Owner's call: head home from a halfway campfire.** For short trips: a campfire halfway
  where the party can turn for home (supplies low, the wagon struggling) without the
  turn-back Fatigue. (round 17)
- **Owner's call: more Saloon rumors.** Three or four new rumor types so the board doesn't
  repeat. (round 17)
- **Idea: more boss standoffs.** Other bosses get a High Noon before their fight, like Mad
  Dog. The owner loved Mad Dog's (round 21). (minigame proposal, round 14)
- **Idea: more of the Lone Wanderer.** The three challenges are built; more meetings could
  follow (the owner first asked for a recurring storyline). (round 14)
- **Decided, later: the second region onward.** Red Canyons, Thunder Peaks and Redwater
  Ford, once the first region is crisp. Their events and curios get the first region's
  treatment: pools, ★/✗ experts, compel and skill checks (see `EVENT_PROPOSALS.md` and
  `CURIO_PROPOSALS.md`).
- **Idea: supply keys.** Uses at curios for the supplies that open nothing today: Bandages,
  Whiskey, Lamp Oil, Wagon Parts. (content audit)
- **Idea: smaller passes** on supplies, camp skills and side quests. (content audit)

## Wagon

- **Decided: enemies that go for the wagon.** Some enemies and battles target the wagon,
  which stands behind the party: it loses condition or cargo. Rework the enemy ambushes
  around this; they've been off since round 7 (`hero_ambush: false`, night camps included).
  The wagon gets **no** other combat role: no cover, no wagon actions. (round 15)
- **Built in part: wagon upgrades.** The Wheelwright adds cargo slots (round 19). **Idea:**
  more upgrades, such as condition or repairs on the road. (round 15)
- **Idea:** more places where the wagon and its cargo matter. (round 7)

## Town and townsfolk

- **Owner's call: trim the building upgrades further** (fewer tracks, or dearer levels), or
  first see how the locks play. (round 19)
- **Decided, later: moving between settlements.** Townsfolk and heroes travel between
  towns, with the multi-town work. A Stage Driver trade could come with it. (round 15)
- **Idea: more townsfolk sources:** cave rescues, a boss's prisoners, Wanderer story beats.
  (round 15)
- **Idea: a town that looks lived in.** More figures and lit windows on the street as the
  population grows. (round 15)
- **Idea: a value pass on town buildings.** What each building and level is worth against
  its chips, Timber, Iron and Hides. (content audit, step 5)
- **Not needed now:** a new town painting to match the plot count. The current one has a spot
  for each of a City's 9 plots. (round 19)

## Heroes and combat

- **Workshop** (`HERO_PROPOSALS.md`):
  - **Shotgun Guard:** approved design (two stances plus a counter-attack), not built.
  - **Bayou Poisoner's 8th move:** Mosquito Swarm was too close to Poison Darts; keep
    workshopping.
  - **Prospector:** none of the options landed; on hold.
- **Idea: Gunslinger bullets.** Six rounds shown overhead, moves spend them, and a Reload
  move. (round 8)
- **Owner's call: Stacked Deck.** A second deal stacks on the first (two Jacks of Clubs =
  +24 Dodge). Proposed: a new deal replaces that hero's previous card. Held for a balancing
  pass. (round 8)
- **Owner's call: utility moves.** Should they get their own per-level upgrades? Today every
  move level adds the same accuracy, damage, effect and healing bonuses. (round 8)
- **Owner's call: front-liners.** The Marshal is close to an automatic rank 1-2 pick. Lift
  the Mountain Mystic and the Rail Driver rather than weaken him (options in round 21's
  reply). (round 21)
- **Watch: hero balance.** Re-rank with `python3 tools/hero_power.py` after the next
  playtest. (round 8)
- **Watch:**
  - Ruby Blackwing is hard and her crow summon strong; probably right. (round 7)
  - The Gunhand's Double Tap stands out against two or more gunhands. (round 12)

## Interface

- **Idea: move animations.** Give the moves that matter a proper animation like End of the
  Line's (wind-up, travel, impact, flash, shake, own sounds). Start with each class's
  signature moves and the bosses' big moves. (round 9)
- **Idea: trinket screen.** A "Trinkets" button opens the stash and every hero's two slots
  side by side, to equip with a click or a drag. It needs an icon per trinket first.
  (round 9)
- **Watch:** leftover how-to text. Round 17 removed most of it; trim any that turns up.

## Art (the owner's image pass)

- **Big image pass (owner, later):** curio and event art, trinket icons, more backdrops,
  townsfolk portraits. The drawn placeholders are fine until then; don't polish them.
- **Backdrops:** about ten more in the prairie style for stops across quests and expeditions
  (keep the lower middle open, `COMFYUI_GUIDE.md` §7). Also: rebuild favourite drawn scenes
  in code from a painted reference (the Crow's Nest, Dry Gulch Mine inside and out, the Old
  Mill Road, the town).
- **Icons still drawn in code:** the skull and the Hides pelt; optionally the move-type and
  stat icons.
- **Town depth:** layered, angled buildings with foreground and background, like Darkest
  Dungeon's Hamlet, without overdoing it.
- **A world map** between settlements.

## Bugs and tech

- **Watch: crashes.** Two crashes in rounds 7-8 were the NVIDIA OpenGL driver. Vulkan has
  been the default since; `play_opengl.bat` is the fallback.
- **Check:** whether 2D MSAA under Vulkan smooths the jagged edges on circles and cut-outs.

## Releases

- The download zip (`download/`) is v0.7. Rebuild it only for a major version, when the owner
  asks. Tag pushes are refused from here (403); the owner pushes tags.

## Decided against

Kept so they aren't proposed again.

- The wagon as a fighter, cover or source of combat actions. It's only ever a target.
  (round 15)
- Heroes retiring into townsfolk. The two are always separate pools. (round 15)
- Settlers at the Hiring Board, or showing up on their own. Townsfolk come only from
  expeditions and quests. (round 15)
- Joining or betting with the Lone Wanderer. The duel is for pride. (round 14)
- Skipping a minigame without the right item or expert. (round 14)
- A separate Saloon upgrade for the Wanderer. The first Chatter upgrade unlocks it.
  (round 18)
- Heals for the Gambler or the Gunslinger, for now. (round 19)
- A party-wide Questionable Mushroom. It's one target, the Poisoner included. (round 18)
