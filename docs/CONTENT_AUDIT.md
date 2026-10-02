# Content audit (October 1, round 9)

Where every system stands: what has had real passes since the first build, and what is still
first-draft. "Revisions" counts the commits that changed the data file after it was created
(91 commits in the repo in total).

## Systems that have had solid passes

| System | Data | Revisions | State |
|---|---|---|---|
| Classes and moves | 11 classes, 167 skills (`classes.json`, `skills.json`) | 12 / 20 | Reworked, balanced against `tools/hero_power.py`, two new classes' worth of mechanics (Momentum, stances proposed). Owner-tuned move by move. |
| Combat rules | `combat_engine.gd` | many | Vulnerable, Mark payoffs, bones (corpses), Momentum, dispel, transfusion, refresh debuffs, guard/taunt, Death's Door, surprise. |
| Enemies | 37 (`enemies.json`) | 12 | Balanced per region; Vulnerable on a few. |
| Regions and map | 6 regions (`regions.json`) | 12 | Map gen, backdrops, caves, crossings, bosses, side quests. |
| Town | 4 settlements, 9 buildings | 5 / 6 | Painted Fort Providence, plots, tracks, hiring board. |
| Presentation | figures, HUD, art pipeline | many | Ink style, three-quarter bodies, paper theater, painted backdrops and props. |

## Systems that are still first-draft

### Quirks — 40 (20 good, 20 bad) · **never revised**
- All but three are flat stat modifiers, often with a condition (front/back, in cave, vs a tag,
  low HP). Every stat and condition is wired in the engine; nothing is broken.
- Only three have behaviour: Drinker, Gold Fever and Too Curious compel the hero at curios.
- None touch the systems built since day one: Mark, Vulnerable, bones, Momentum, Death's Door,
  guard, the Breaking Points.
- Many duplicate trinkets (Beast Hunter = Wolf-Tooth Necklace, Bounty Hunter = Wanted Poster,
  Unbeliever = Salt-Charm Pouch, Night Owl ≈ Miner's Lamp).
- Gained: 45% chance per hero after each expedition (60% good on a win, 40% on a loss), plus a
  few events. Lost: the Doctor building (250 + 50/level) or a full slot (4 of each) pushing
  one out at random. No locking, no curio or event sources beyond a handful.
- Ideas parked in `HERO_PROPOSALS.md`: Glass Jaw (always Vulnerable 10%).

### Breaking Points and Second Winds — 6 + 5 · **never revised**
- Stat modifiers plus acts (pass, bark, move back, random skill) and turn-start boons.
- Untouched since the engine pass, so no tie to the newer mechanics (Reckless + Vulnerable was
  proposed; Steadfast could guard; a Breaking Point could Mark the hero).

### Trinkets (keepsakes) — 19 + 3 boss · **2 revisions, both on day one**
- Two slots per hero. Rarity common/uncommon/rare/boss, prices 200-700.
- Almost all are 1-2 flat stat modifiers with a small trade-off; half copy a quirk.
- No class trinkets, no sets, no triggers (on kill, on crit, on Death's Door, first turn), no
  interaction with Mark / Vulnerable / bones / Momentum / camp.
- Sources: curio shovel results, 6 events, the trinket peddler, region bosses.

### Curios — 21 · **3 revisions (one only retired the crowbar)**
- Each: 2-4 "hand" outcomes plus 0-2 item keys.
- Keys are lopsided: Shovel opens 11, Salt 7, Antivenom 2, Rope 1. Bandages, Whiskey, Lamp
  Oil, Food and Wagon Parts open none.
- No class or quirk interactions (a Prospector at an Ore Vein, a Preacher at a grave), beyond
  the three compulsion quirks.
- The tutorial road has 3 curios; Tallgrass, Red Canyons and Thunder Peaks have about 10 each,
  heavily shared (Abandoned Wagon and Whiskey Barrel appear in every region).

### Events — 36 · **4 revisions**
- Healthy shape: 27 have 3 options, 5 have 4, 4 have 2. Options are gated by survival skill
  (~25), item (~15) or money (8).
- Class options exist for only 3 of 11 classes: Marshal (4), Preacher (2), Gambler (2).
- Quirk-gated options are supported by the code and used **0** times.
- Effects lean on fatigue (66) and food (26); few reach combat (13 fights, 1 buff).

### Supplies — 10 active (crowbar retired)
- Rope, Shovel and Salt only open curios/events; Lamp Oil only matters in caves.
- Antivenom heals 5% and cures poison; nothing uses a supply as a combat tool or trade good.

### Camp skills — 12 survival skills, 2 actions each · **3 revisions, all day one**
- Passives and actions are wired (food, hunting, scouting, wagon, healing, loot, materials).
- Not revisited since round 2; no ties to class or the new combat mechanics.

### Side quests — 7 templates · **2 revisions**
- Mad Dog, rustlers, wolves, haint, claim jumpers, snakes, Crane's scouts.

## Recommended order

1. ✅ **Quirks** (round 9, QUIRK_PROPOSALS.md): 50 quirks, tied to Mark, Vulnerable, Death's
   Door, first round; behaviour quirks (Drinker's bar lock, Gold Fever, Homesick).
   ⬜ **Breaking Points and Second Winds** were part of this step and are still untouched.
2. ✅ **Trinkets** (round 9, TRINKET_PROPOSALS.md): 22 class trinkets, general edits, 5 new.
3. 🟨 **Curios** (round 9, CURIO_PROPOSALS.md): class and skill experts, ★/✗ in the picker and
   quirk chances, done for the Fort Providence area's 16. Still to do: Red Canyons (Painted
   Canyon Wall) and Thunder Peaks (Stone Cairn, Giant's Bones, Frozen Pack, Hot Spring), and
   keys for the supplies that open nothing (Bandages, Whiskey, Lamp Oil, Wagon Parts).
4. ⬜ **Events.** Class options for all 11 classes (only Marshal, Preacher and Gambler have
   any), quirk-gated options (supported, used 0 times), more combat hooks.
5. ⬜ **Town buildings and upgrades** (owner, round 9): what each building and level is worth,
   its costs in chips, Timber, Iron and Hides, the hiring board and bunkhouse tracks.
6. ⬜ **Supplies, camp skills, side quests.** Smaller passes once the above settle.
