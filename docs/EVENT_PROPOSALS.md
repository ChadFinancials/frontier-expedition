# Event proposals (round 9)

Status: **awaiting the owner's picks.** Nothing here is built yet.

## How events work today

- 36 events. Each region has its own pool; map nodes draw from it without repeats. Homesteads
  draw from a separate pool.
- Each option may need an item, chips, a survival skill, a class or a quirk. **An option that
  needs a skill, class or quirk is hidden** unless someone in the company qualifies. The
  qualifying hero becomes `{hero}`.
- Outcomes are weighted. Angler/Wheelwright river passives and Hunter passives add weight to
  `good` outcomes at the river and hunting events.
- An outcome can be any shared effect: Fatigue, HP, food, chips, materials, items, a trinket,
  a quirk, a recruit, a scouting reveal, a buff or debuff for the next fight, or a fight.
  A fight takes enemies, who strikes first, and a reward.

**What's thin:**
- **Classes:** only Marshal (4 events), Preacher (2) and Gambler (2) have options. The other
  8 classes have none.
- **Quirks:** quirk-gated options are supported but used 0 times. Three events can *give* a
  quirk.
- **Combat:** 13 outcomes start a fight, but only "who strikes first" and one reward carry
  over. Nothing wounds the enemy, Marks it or leaves the company shaky. "Next fight" buffs and
  debuffs work but are used once.
- **Skills:** the Cook skill is never used, and Miner and Angler once each.
- **Supplies:** Lamp Oil is never used; Salt and Antivenom once each.
- **Dead options:** five options do nothing at all (Stuck in the Mud ×2, Swollen Creek rope,
  Torn Canvas rope, Fever Medic). Avoiding a bad outcome is the reward, which is fine, but a
  few could give a small bonus.
- **Bug:** Prairie Fire's Whiskey option says "Soak blankets with the water barrel".

## Every event now

Regions: Mill = Old Mill Road, Tall = Tallgrass Sea, Gulch = Dry Gulch Mine, Crow = Crow's
Nest, Red = Red Canyons, Peaks = Thunder Peaks. **Bold** = class option. "Hero" means the
hero who acts; "one" means a random hero.

| Event | Regions | Options → outcomes |
|---|---|---|
| River Crossing | Tall, Red | Ford it: drive the wagon straight across → 56%: -8 Wagon / 33%: -20 Wagon, -4 Food, +8 Fatigue all / 11%: -20% HP hero, +12 Fatigue hero<br>[Wheelwright] Caulk the wagon and float it across → -4 Fatigue all<br>[Angler] Look for the shallow ford → +4 Food<br>[40 chips] Pay the ferryman (40 chips) → -5 Fatigue all |
| Broken Axle | Mill, Gulch, Tall, Red, Peaks | [1 Wagon Parts] Use spare Wagon Parts → nothing<br>[Wheelwright] Rig a repair from what's on hand → +5 Wagon<br>Lash it together and hope → 40%: -15 Wagon / 40%: -10 Wagon, +8 Fatigue all / 20%: -25 Wagon, -2 Food |
| Prairie Fire | Tall | Run for it! → 60%: +8 Fatigue all / 40%: -15 Wagon, -10% HP all<br>[Scout] Set a backfire: burn a patch to shelter in → +4 Fatigue all<br>[1 Whiskey] Soak blankets with the water barrel and hunker down → -5% HP all |
| Stranger on the Road | Crow, Tall, Red, Peaks | Welcome them to the fire → 50%: reveal 2 / 33%: recruit / 17%: -15% chips<br>[1 Whiskey] Share a bottle and ask questions → reveal 4, -4 Fatigue all<br>**[Marshal]** Recognize a wanted face → 120-200 chips, -6 Fatigue hero<br>Keep your hand on your iron and ride on → nothing |
| Buffalo Herd | Tall | Wait for them to pass → -3 Food, +4 Fatigue all<br>[Hunter] Hunt one for meat → +10 Food, +2 Hides<br>Push through the herd → 67%: -10 Wagon / 33%: **fight** |
| Sick Traveler | Tall | [1 Bandages] Give Bandages and your time → trinket, -8 Fatigue all<br>[Medic] Tend them properly → -10 Fatigue all, quirk random_positive 50%<br>[4 Food] Give them some food → -5 Fatigue all<br>Keep moving. You can't risk the sickness → +8 Fatigue all |
| Rattler in the Bedroll | Gulch, Tall, Red | Freeze, and let someone else deal with it → 60%: +5 Fatigue hero / 40%: -20% HP hero, quirk afraid_of_snakes 40%<br>[Trapper] Grab it behind the head → +2 Food<br>[1 Antivenom] Keep Antivenom handy and swat it → +4 Fatigue hero |
| Thunderstorm | Tall, Red, Peaks | Shelter under the wagon → 75%: +8 Fatigue all / 25%: -15 Wagon, +6 Fatigue all<br>[Storyteller] Tell stories to pass the time → -6 Fatigue all<br>[1 Whiskey] Break out the whiskey → -3 Fatigue all |
| Lost the Trail | Gulch, Tall, Red, Peaks | Pick a direction and hope → 50%: -2 Food / 50%: -4 Food, +8 Fatigue all<br>[Tracker] Read the land → reveal 2<br>[Scout] Ride ahead and look → reveal 4 |
| Wolf Tracks | Crow, Tall, Peaks | [Trapper] Set a trap line → +2 Hides, 80-140 chips<br>Hunt them down before they hunt you → **fight** (we strike first)<br>Keep a big fire going and move on → 67%: +6 Fatigue all / 33%: **fight** |
| Abandoned Homestead | Crow, Tall | Search the house → 50%: +5 Food / 33%: **fight** / 17%: +8 Fatigue all<br>Tear down the barn for lumber → +4 Timber, +4 Fatigue all<br>Leave it be → nothing |
| Haint Lights | Gulch, Tall | Follow the lights → 50%: 120-240 chips / 50%: +10 Fatigue all, **fight**<br>[1 Salt] Ring the camp with salt → -4 Fatigue all<br>**[Preacher]** Pray them away → -8 Fatigue all |
| Traveling Peddler | Gulch, Crow, Tall, Red, Peaks | [150 chips] Buy a lucky charm (150 chips) → 75%: trinket / 25%: nothing<br>[70 chips] Buy supplies (70 chips) → +2 Bandages, +1 Whiskey<br>**[Gambler]** Out-hustle the hustler → +2 Bandages, +1 Salt, 40-100 chips<br>No thank you → nothing |
| The Trinket Peddler | Gulch, Crow, Tall, Red, Peaks | [90 chips] Buy something from the top pocket (90 chips) → trinket<br>[260 chips] Ask about the inside pocket (260 chips) → 75%: trinket / 25%: nothing<br>**[Gambler]** Read her palm instead → trinket<br>Keep your chips → nothing |
| Stuck in the Mud | Gulch, Tall, Red, Peaks | Everybody push! → 75%: +8 Fatigue all / 25%: +6 Fatigue all, -10% HP one<br>[1 Rope] Rig a pulley with rope → nothing<br>[Woodcutter] Lay down timber for traction → nothing |
| Row of Graves | Gulch, Tall, Red, Peaks | Pay respects → +5 Fatigue all, -8 Fatigue one<br>**[Preacher]** Say a proper service → -8 Fatigue all<br>Hurry past → +3 Fatigue all |
| Good Hunting | Crow, Tall, Peaks | Go hunting → 60%: +5 Food, +1 Hides / 40%: +4 Fatigue all<br>[Hunter] Let the expert handle it → +10 Food, +2 Hides<br>[Forager] Set snares and forage → +6 Food, +1 Bandages |
| Smoke Signals | Crow, Tall, Red | Ride hard and hit them first → **fight** (we strike first)<br>[Tracker] Circle around them → 60-120 chips<br>Take the long way round → -4 Food, +4 Fatigue all |
| Fork in the Trail | Crow, Tall, Red, Peaks | Take the shortcut → 50%: -5 Fatigue all, +2 Food / 50%: -15 Wagon<br>Stay on the main trail → -2 Food |
| Flash Flood | Red | Scramble for high ground! → 67%: -20 Wagon, +8 Fatigue all / 33%: -25% HP hero, -10 Wagon<br>[1 Rope] Haul the wagon up with rope → +5 Fatigue all<br>[Scout] The Scout saw it coming → nothing |
| Railroad Surveyors | Red | Mind your own business → +5 Fatigue all<br>Run the surveyors off → **fight**<br>**[Marshal]** Invoke the law → +5 Food, -8 Fatigue all |
| A Song in the Canyon | Red | Stuff your ears with wax and push on → 67%: +5 Fatigue all / 33%: **fight**<br>[1 Rope] Tie everyone to the wagon, like the old story → 120-240 chips, +8 Fatigue all<br>[Storyteller] Answer the song with a louder one → -5 Fatigue all |
| Heat Wave | Red | Travel by night → +5 Fatigue all, -2 Food<br>Push through the heat → +10 Fatigue all, -8% HP all<br>[Forager] Find a spring → +10% HP all |
| Claim Dispute | Red | **[Marshal]** Settle it fairly → 100-180 chips<br>[Miner] Assess the ore yourself → +3 Iron, -4 Fatigue all<br>Stay out of it → 67%: +4 Fatigue all / 33%: **fight** |
| Avalanche! | Peaks | Run! → 67%: -20 Wagon, +10 Fatigue all / 33%: -25% HP hero, +10 Fatigue hero<br>[Scout] The Scout picked the safe line → +4 Fatigue all |
| Blizzard | Peaks | Hole up and wait → -6 Food, +8 Fatigue all<br>[Woodcutter] Build a big fire → -3 Food<br>Push through → -12% HP all, +10 Fatigue all |
| Frozen Traveler | Peaks | Warm them up and bring them along → 67%: recruit, -2 Food / 33%: +10 Fatigue all<br>Take their supplies → +3 Food, 40-80 chips, +10 Fatigue all |
| Giant Footprints | Peaks | Follow them → 50%: **fight** / 50%: 160-300 chips, +3 Iron<br>[Tracker] Study them → reveal 3, next fight +10% dmg_pct<br>Go the other way. Quickly → +5 Fatigue all |
| Homestead | Mill, Crow, Tall, Red | Stay for supper → +20% HP all, -12 Fatigue all<br>[30 chips] Trade for supplies (30 chips) → +10 Food<br>Help with chores in exchange for lumber → +5 Timber, +6 Fatigue all |
| Widow's Claim | Crow, Tall, Red | Help her clear the wolf den → **fight** +reward<br>Rest and trade stories → -5 Fatigue all, +5% HP all<br>Offer her a place in the company → 67%: recruit / 33%: nothing |
| Drifter's Camp | Gulch, Tall, Red, Peaks | Welcome them aboard → recruit<br>Share a meal and move on → -6 Fatigue all, +8% HP all |
| Trapper's Cabin | Peaks | Rest by the fire → +20% HP all, -12 Fatigue all<br>[50 chips] Buy furs and provisions (50 chips) → +8 Food, reveal 2, +2 Hides<br>Ask the trapper to join you → recruit mountain_man |
| Swollen Creek | Tall, Peaks | [1 Rope] Rope the wagon to a tree and ease it across → nothing<br>Wait for the water to drop → -4 Food, +3 Fatigue all<br>Chance it → 50%: -18 Wagon / 25%: -5 Food, -1 Bandages / 25%: +4 Fatigue all |
| Fever in the Camp | Gulch, Tall, Red, Peaks | [2 Bandages] Treat them with bandages and cool water → +3 Fatigue all<br>[Medic] Let the Medic take charge → nothing<br>Push on and hope it passes → 67%: -12% HP all, +8 Fatigue all / 33%: -20% HP hero, quirk sickly |
| Outlaw Toll | Crow, Tall, Red | [40 chips] Pay the toll (40 chips) → +4 Fatigue all<br>**[Marshal]** Flash the badge → 67%: -4 Fatigue all / 33%: **fight**<br>Refuse → **fight** |
| Torn Canvas | Gulch, Crow, Tall, Red, Peaks | [1 Rope] Lash it down with rope → nothing<br>[1 Wagon Parts] Rebuild the bows with spare parts → +10 Wagon<br>Leave it → -3 Food, -8 Wagon |

## A. Class options for the 8 classes with none

Each class gets **3 events**. At least 2 of them are in the first region (Tallgrass, Dry
Gulch, Crow's Nest), so you'll see them early. Like now, an option shows only when that class
is in the company.

| Class | Event | Option | Outcomes |
|---|---|---|---|
| **Mountain Mystic** | Haint Lights | "Speak with them." | 2/3: the lights show the way: reveal 3, -6 Fatigue all · 1/3: "They don't want to talk": fight vs 2 Haints, who start Vulnerable 15% |
| | Wolf Tracks | "Go out and meet the pack." | 3/4: the wolves sit and let you pass: -6 Fatigue all, +1 Hides (a gift) · 1/4: one young wolf doesn't listen: fight vs 1 wolf, we strike first |
| | Giant Footprints *(Peaks)* | "Leave an offering of iron." | -1 Iron: the giant leaves a gift (trinket, rare) |
| **Rail Driver** | Broken Axle | "Drive a new pin with the hammer." | +5 Wagon, +6 Fatigue hero (hard work, but no supplies used) |
| | Stuck in the Mud | "Get under it and lift." | Out at once: -4 Fatigue all (everyone's impressed), +8 Fatigue hero |
| | Railroad Surveyors *(Red)* | "Talk to the work gang." | 120-200 chips (they pay you to look the other way) **or** they down tools: -8 Fatigue all |
| **Gunslinger** | Outlaw Toll | "Call out the leader." | 1/2: the leader backs down: -6 Fatigue all, +40-80 chips (their toll money) · 1/2: draw: fight, we strike first, the leader starts at 50% HP |
| | Smoke Signals | "Pick off the lookout." | fight vs 2 instead of 3 (rifleman removed), we strike first |
| | Stranger on the Road | "Size them up." | Spots trouble before it starts: 2/3 recruit, 1/3 reveal 2 (no chance of being robbed) |
| **Wrangler** | Buffalo Herd | "Cut one out of the herd." | +8 Food, +1 Hides, and the herd parts: no wagon damage |
| | River Crossing | "Swim the oxen across." | 4/5: across clean, -4 Fatigue all · 1/5: -8 Wagon |
| | Thunderstorm | "Settle the oxen." | No ditch: +4 Fatigue all only (instead of 8) |
| **Prospector** | Abandoned Homestead | "Blast open the root cellar." | 2/3: 80-160 chips, +2 Iron · 1/3: the squatters come running: fight, they start at 70% HP (stunned by the blast) |
| | Smoke Signals | "Dynamite the ridge." | fight where every enemy starts at 60% HP, we strike first |
| | Claim Dispute *(Red)* | "Blast a test hole." | +4 Iron, both parties pay 40-80 chips for the answer |
| **Bayou Poisoner** | Rattler in the Bedroll | "Milk the venom." | +1 Antivenom, and the hero's next fight gets +2 Poison per turn on their poisons |
| | Wolf Tracks | "Leave poisoned bait." | +2 Hides, no fight · -1 Food (the bait) |
| | Swollen Creek | "Read the water, bayou style." | Across safely and +3 Food (crawfish) |
| **Frontier Doctor** | Sick Traveler | "Treat him, and charge for it." | 100-160 chips, -6 Fatigue all |
| | Fever in the Camp | "Quinine and quarantine." | No harm, and -4 Fatigue all (no Bandages used) |
| | Frozen Traveler *(Peaks)* | "Treat the frostbite properly." | Recruit always lives (no 1/3 death) |
| **Train Hopper** | Fork in the Trail | "Read the hobo sign on the post." | Always the good shortcut: -5 Fatigue all, +2 Food |
| | Drifter's Camp | "Swap hobo code." | Recruit **and** reveal 3 (they know the trail) |
| | Railroad Surveyors *(Red)* | "Hop their supply car." | +2 Bandages, +1 Whiskey, +1 Wagon Parts |

**Marshal** (4), **Preacher** (2) and **Gambler** (2) keep theirs. Two more each, both in the
first region:

| Class | Event | Option | Outcomes |
|---|---|---|---|
| Preacher | Sick Traveler | "Sit with the family." | -8 Fatigue all; 1/3 the father lives (trinket) |
| | Frozen Traveler *(Peaks)* | "Last rites." | No Fatigue for the death; the company takes heart (-6 Fatigue all) |
| Gambler | Outlaw Toll | "Double or nothing on a hand of cards." | 1/2: they ride off with nothing: +40 chips · 1/2: pay 80 chips, or fight if short |
| | Fork in the Trail | "Flip for it." | 3/4 the good shortcut, 1/4 the bad one |

## B. Quirk options

The option shows only if someone has the quirk.

**Good quirks** (a better way through):

| Quirk | Event | Option | Outcomes |
|---|---|---|---|
| Unbeliever | Haint Lights | "Walk right through them." | 2/3: the cache, 120-240 chips · 1/3: fight vs 2 Haints who start Vulnerable 15% |
| Beast Hunter | Wolf Tracks | "Track the pack leader." | fight vs 1 big wolf, we strike first, +3 Hides |
| Bounty Hunter | Outlaw Toll | "Recognize them: there's paper on all three." | fight, with a 200-chip bounty if you win |
| Trailwise | Lost the Trail | "Trust your gut." | reveal 3 |
| Iron Stomach | Fever in the Camp | "Nurse the sick; nothing makes {hero} ill." | No harm to anyone |
| Hard of Hearing *(bad quirk, good here)* | A Song in the Canyon *(Red)* | "{hero} can't hear a thing." | Walks up and takes the treasure: 120-240 chips |

**Bad quirks** (a temptation). These take a new field, `compel`: when the event opens, a
hero with the quirk has that % chance to grab the option before you can choose. It works
like the Drinker and Gold Fever compulsions at curios.

| Quirk | Event | Option | Compel | Outcomes |
|---|---|---|---|---|
| Drinker | Stranger on the Road | "{hero} pulls out a bottle." | 40% | 1/2: they share the map: reveal 3 · 1/2: wakes up robbed: -20% chips, next fight -5 Acc for the hero (hungover) |
| Gold Fever | Haint Lights | "Chase the lights. There's gold out there." | 40% | 1/2: 160-300 chips · 1/2: fight vs 3 Haints, +10 Fatigue hero |
| Too Curious | Abandoned Homestead | "Open the door nobody wants to open." | 30% | 1/2: trinket · 1/2: fight vs 2 Haints |
| Hothead | Outlaw Toll | "{hero} has already drawn." | 50% | fight, we strike first, but the hero is Vulnerable 10% next fight |
| Spooked by Critters | Rattler in the Bedroll | "{hero} bolts." | 50% | Into the night: +10 Fatigue hero, but they're not bitten |

## C. Combat hooks

New fields on a `fight` effect (small engine work):
- `wounded`: enemies start at a % of their HP (Prospector's dynamite, the Gunslinger's draw).
- `drop`: remove an enemy by id (the Gunslinger shoots the lookout).
- `foe_mods`: round-1 modifiers on the enemy (Vulnerable for the Mystic and Unbeliever, Marked).

"Next fight" debuffs already work, with negative values. Proposed uses on existing bad
outcomes:
- River Crossing "tips": wet powder, -5 Acc next fight.
- Heat Wave "push through": -2 Spd next fight.
- Thunderstorm "shelter" (75%): wet powder, -5 Acc next fight.
- Blizzard "push through": numb hands, -5% Dmg next fight.

Event fights that pay nothing extra could add a small reward:
- Abandoned Homestead squatters: 40-80 chips.
- Claim Dispute claim jumpers: +2 Iron.
- Outlaw Toll "Refuse": 40 chips (their toll).

## D. Supplies and skills that go unused

| Supply or skill | Event | Option |
|---|---|---|
| **Cook** | Buffalo Herd | "Jerk the meat." Needs a Hunter or Cook; +6 Food on top |
| **Cook** | Homestead | "Cook for the family." +12 Food, -8 Fatigue all |
| **Lamp Oil** | Abandoned Homestead | "Light a lamp and search properly." The squatter fight can't happen; +5 Food, 1/3 trinket |
| **Lamp Oil** | Haint Lights | "Light your own lamp and follow." 2/3 the cache; the fight drops to 1/3 |
| **Salt** | Buffalo Herd (Hunter) | "Salt the meat." +5 Food |
| **Antivenom** | Sick Traveler | "It's snakebite, not fever." -10 Fatigue all, trinket |
| Angler | Swollen Creek | "Find the riffle." Across safely, +3 Food |
| Miner | Abandoned Homestead | "Check the well shaft." +3 Iron |

## E. Fixes and small edits

- **Prairie Fire:** fix the Whiskey option text ("Soak the blankets in whiskey and hunker
  down").
- **Do-nothing options:**
  - Stuck in the Mud (Rope) and (Woodcutter): -2 Fatigue all, "quick work".
  - Torn Canvas (Rope): +2 Wagon.
  - Fever (Medic): -4 Fatigue all.
  - Swollen Creek (Rope) stays as it is: avoiding the risk is the reward.
- **Old Mill Road** has just Broken Axle and Homestead. It's the tutorial, so leave it.

## Engine work (small)

- `compel` on quirk options; the event screen shows "{hero} can't help themselves!".
- Fight fields `wounded`, `drop`, `foe_mods`.
- Tests: every option's requirements are valid, a class option is hidden without the class,
  compel fires, and wounded, drop and foe_mods reach the fight.

## Questions for the owner

1. All of A, or a subset? That's 28 new class options, covering all 11 classes.
2. Quirk options: is `compel` for the bad quirks OK, or should they just be optional choices?
3. Should C's "next fight" debuffs go in? They make the bad outcomes bite a little harder.
4. New events? The first region's pools are Tallgrass 23, Dry Gulch 10, Crow's Nest 10.
   Dry Gulch and Crow's Nest could use 2-3 each, e.g. a Cattle Drive, a Medicine Show, a Hobo
   Jungle or a Dynamite Shack.
