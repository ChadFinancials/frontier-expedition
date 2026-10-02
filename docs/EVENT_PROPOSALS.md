# Event proposals (round 9, take 2)

Status: **pass 1 of 2 built** (owner's picks: ★/✗ show names only, e.g. "★ Cook"; all 12 new
events; 30% compel for every bad quirk; two passes).
- **Pass 1, built:** pools, event experts, compel, fight setup, and the existing events
  reworked as in sections 3-6. Claim Dispute moves into Dry Gulch.
- **Pass 2, to do:** the 12 new events, follow-up choices (the Haint Lights grave, the
  homestead cellar, the Twister's strongbox), "hidden while a class is present" (the Marshal
  won't steal), and filling out the quest themes.
- Small changes in the build:
  - Beast Hunter at Wolf Tracks and the widow's den sets the foes Vulnerable rather than
    adding Hides.
  - Gold Fever and Drinker compels use the same 30% as the rest.
  - Salt at the Buffalo Herd is its own option.

This replaced the first draft. Scope: the first region only (Tallgrass Sea, Dry Gulch Mine, Crow's Nest and the
Saloon side quests). Red Canyons and the Thunder Peaks come later; their events stay as they
are for now.

## 1. Pools

**Today:** each region has one hand-written list, and a Saloon side quest borrows the list of
the region west of its town (Fort Providence → Tallgrass Sea). There's no shared pool.

**Proposed:** every event stop draws from one of three layers.

| Layer | What's in it | Weight |
|---|---|---|
| **Common** | Trail life that could happen anywhere: wagon trouble, peddlers, weather, sickness, strangers, graves, card games | 45% |
| **Region** | The region's flavour: open prairie (Tallgrass), mine country (Dry Gulch), outlaw country (Crow's Nest) | 55% |
| **Quest theme** (side quests only) | 2-3 events that match the quest: Rustlers get the Cattle Drive, the Haint quest gets Haint Lights and the graves | Side quests: theme 40%, region 30%, common 30% |

No repeats within one expedition. When a layer runs dry, the pick falls through to the next.
The weights live in config, and Red Canyons and the Peaks will only need their region list.

## 2. What makes an event interesting

1. **★ / ✗ experts on ordinary options**, using the same system and dials as the curios.
   - An option lists who's good or bad at it: a class, a survival skill (rank matters), or now
     also a **quirk**.
   - The best expert in the company acts: ★ better odds, a bonus on success, or a different,
     better outcome. A ✗ hero acting means worse odds or a worse outcome.
   - The picker shows the lines under each option ("★ Ezra (Tracker 2): better odds"), so it
     reads like the curio picker.
   - Odds shift but never guarantee success (cap 75%), as with curios.
2. **Secret options** stay. These are options only someone with that class, skill or quirk can
   see, like today's [Marshal] options. They're the signature move: often a safe, clever way
   through.
3. **Bad quirks compel.** A hero with Drinker, Gold Fever, Too Curious, Hothead or Spooked by
   Critters may grab an option before you choose ("{hero} can't help themselves!"). It's a
   `compel` chance, as at curios.
4. **Follow-ups.** Some good outcomes open a second choice. For example, the Haint Lights lead
   to a grave: dig it up, or leave a coin? That's where the best and worst payoffs live.
5. **Payoffs that last:**
   - quirks, good and bad, at a low % where thematic
   - trinkets and recruits
   - "next fight" buffs and debuffs (wet powder, hungover, charged up)
   - fights that start in your favour (foes wounded, a lookout already shot, foes Vulnerable)
     or against you (surprised)
6. **Every event has a gamble.** At least one option can go clearly well or clearly badly,
   next to the safe-but-dull option.

Notation below: `5/3/1` are outcome weights. ★ and ✗ are experts on that option. [Bracketed]
options are secret, or need a supply. **New** marks a new event or option.

## 3. Common pool (15)

**Broken Axle**
- [Wagon Parts] Swap in the spare. → fixed.
- **Lash it together and hope.** 2 holds (-15 Wagon) / 2 hot work (-10 Wagon, +8 Fatigue all) /
  1 fails (-25 Wagon, -2 Food).
  - ★ Wheelwright (rank odds; +5 Wagon on success)
  - ★ Rail Driver ("drives a new pin": better odds, +6 Fatigue to the hero)
  - ✗ Butterfingers ("drops the axle on their foot": worse odds, -10% HP hero)

**Stuck in the Mud**
- **Everybody push!** 3 free (+8 Fatigue all) / 1 wrenched back (+6 Fatigue all, -10% HP one).
  - ★ Rail Driver ("gets under it and lifts": the good outcome is -4 Fatigue all instead)
  - ★ Woodcutter (rank odds: corduroy road)
  - ★ Wrangler (better odds: settles the oxen)
  - ✗ Overweight ("sinks to the knees": worse odds)
- [Rope] Pulley. → free, -2 Fatigue all.

**Torn Canvas**
- [Rope] Lash it. → +2 Wagon.
- [Wagon Parts] Rebuild the bows. → +10 Wagon.
- **New:** [1 Hides] Patch it with a hide. → +6 Wagon. ★ Trapper: no Hides used.
- Leave it. → -3 Food, -8 Wagon.

**Traveling Peddler**
- Buy a lucky charm (150). 3 trinket / 1 painted rock.
  - ★ Gambler, ★ Keen-Eyed ("spots the fakes": no painted rock)
- Buy supplies (70). → 2 Bandages, 1 Whiskey.
- [Gambler] Out-hustle the hustler (as now).
- **New** [Frontier Doctor] "Test his tonics." → 1/2: genuine (+2 Bandages, +1 Antivenom) ·
  1/2: snake oil, and he pays 60-100 chips to keep you quiet.
- **New, compel 30%:** [Drinker] buys his whole case of rotgut. → -60 chips, +3 Whiskey; the
  hero sheds 10 Fatigue now, but is -5 Acc next fight (hungover).

**The Trinket Peddler**
- Top pocket (90) / inside pocket (260) as now; [Gambler] read her palm.
  - Inside pocket: ★ Superstitious ("knows real charms": always real) · ✗ Unbeliever (she
    takes offence and leaves: chips refunded, nothing bought)

**Stranger on the Road**
- **Welcome them to the fire.** 3 trail tips (reveal 2) / 2 joins / 1 robbed (-15% chips).
  - ★ Gunslinger, ★ Scout (rank) ("sizes them up": the robbery can't happen)
  - ✗ Jumpy ("spooks them": no recruit)
- [Whiskey] Share a bottle. → reveal 4, -4 Fatigue all.
- [Marshal] Recognise a wanted face (as now).
- **New** [Bounty Hunter] "There's paper on this one." → fight vs 1 hired gun, we strike
  first, 150-chip bounty.
- **New, compel 40%:** [Drinker] drinks with the stranger till dawn. → 1/2: they draw you a
  map (reveal 4) · 1/2: robbed blind (-25% chips) and hungover.

**Lost the Trail**
- **Pick a direction and hope.** 2 found it (-2 Food) / 2 wasted day (-4 Food, +8 Fatigue all).
  - ★ Trailwise
  - ★ Train Hopper ("follows the telegraph poles")
  - ✗ Homesick ("keeps steering east": worse odds)
- [Tracker] Read the land / [Scout] Ride ahead (as now).

**Fever in the Camp**
- [2 Bandages] Treat them. / [Medic] Take charge. → -4 Fatigue all.
- **Push on and hope.** 2 slow (-12% HP all, +8 Fatigue all) / 1 worst of it (-20% HP,
  Sickly quirk).
  - ★ Frontier Doctor ("quinine and quarantine": always good, no harm)
  - ★ Cook (rank: broth; better odds)
  - ★ Iron Stomach (better odds)
  - ✗ Sickly (that hero takes the bad outcome, at better odds of happening)
- Good outcome added: "It passes overnight" (+4 Fatigue all).

**Rattler in the Bedroll**
- **Freeze and let someone deal with it.** 3 fine (+5 Fatigue hero) / 2 bitten (-20% HP, 40%
  Spooked by Critters).
  - ★ Trapper (rank)
  - ★ Bayou Poisoner (swap: "milks the venom": +1 Antivenom, and their next fight's poisons do
    +2)
  - ✗ Spooked by Critters (compel 50%: "bolts into the dark", +10 Fatigue, never bitten)
- [Antivenom] Swat it. ★ Frontier Doctor: no Antivenom used.
- [Trapper] Grab it behind the head (as now).

**Thunderstorm**
- **Shelter under the wagon.** 3 soaking (+8 Fatigue all, wet powder -5 Acc next fight) /
  1 oxen bolt (-15 Wagon).
  - ★ Wrangler (no bolt)
  - ★ Good Humor (-4 Fatigue all on any outcome)
  - ✗ Lightning Rod (**new** outcome, 1 in 6: the hero is struck: -15% HP, but +15% Dmg next
    fight, "charged up")
- [Storyteller] Ghost stories / [Whiskey] (as now).

**Row of Graves**
- **Pay respects.** → +5 Fatigue all, -8 one.
  - ★ Preacher (-8 all instead)
  - ✗ Superstitious, ✗ Gloomy (that hero +10)
- Hurry past (as now).
- **New, compel 30%:** [Gold Fever] Dig one up. → 1/2: grave goods (trinket) · 1/2: cholera
  (-20% HP, 30% Sickly) and +10 Fatigue all for the rest.

**Fork in the Trail**
- **Take the shortcut.** 2 shorter / 2 rough (-15 Wagon).
  - ★ Train Hopper (hobo sign: always good)
  - ★ Scout, ★ Tracker (rank)
- Main trail (as now).
- **New** [Gambler] "Flip for it." → 3 good / 1 rough.

**Swollen Creek**
- [Rope] Rope across. / Wait for it to drop. (as now)
- **Chance it.** 2 cracked wheel / 1 supplies lost / 1 across.
  - ★ Angler (rank; +3 Food on success)
  - ★ Bayou Poisoner ("reads the water")
  - ★ Wrangler
  - ✗ Overweight

**New: Campfire Card Game.** Three cowhands at a fire wave you over for a hand of faro.
- **Sit in (50 chips).** 1 win 100 / 1 lose.
  - ★ Gambler (much better odds; on a win also a trinket off a sore loser)
  - ★ Lucky
  - ✗ Hothead (a bad outcome turns into a fight vs 3 outlaws)
- Just share the fire. → -6 Fatigue all, +5% HP all.
- Compel 30%: [Drinker] "One more round." → -40 chips, hungover; 1/3 also wins 120.

**New: Medicine Show.** "Doctor Ezekiel's Miracle Elixir: cures fever, gout, heartbreak and
snakebite!"
- **Buy a bottle (40).** 1/2 genuinely bracing (-10 Fatigue hero) / 1/2 makes them sick (-10%
  HP, 20% Sickly).
  - ★ Frontier Doctor (always good; and exposes the rest as fakes: +60 chips from the crowd)
  - ★ Unbeliever
  - ✗ Superstitious
- [Preacher] Preach against the snake oil. → the crowd's grateful: +80 chips, -6 Fatigue all.
- Move on.

## 4. Tallgrass Sea (open prairie, 10)

**River Crossing**
- **Ford it.** 5 across (-8 Wagon) / 3 tips (-20 Wagon, -4 Food, +8 Fatigue, wet powder) /
  1 swept away (-20% HP).
  - ★ Wrangler ("swims the oxen across")
  - ★ Angler, ★ Wheelwright (rank)
  - ✗ Overweight (the swept outcome is likelier and lands on them)
- [Wheelwright] Caulk it / [Angler] Find the ford / [40] Ferryman (as now).

**Prairie Fire**
- **Run for it!** 3 outrun / 2 canvas catches.
  - ★ Wrangler ("lets the oxen run": better odds)
  - ★ Scout (rank)
  - ✗ Slowpoke
- [Scout] Backfire (as now).
- [Whiskey] fixed text: "Soak the blankets in whiskey and hunker down."
- **New** [Prospector] "Blast a firebreak." → safe, -4 Fatigue all.

**Buffalo Herd**
- Wait (as now).
- **Push through.** 2 parts / 1 bull fight.
  - ★ Wrangler (swap: "cuts one out and parts the herd": no bull, +6 Food)
  - ✗ Hothead (bull every time, and it charges first)
- [Hunter] Hunt one.
  - ★ Beast Hunter (+2 Hides)
  - ★ Cook ("jerks the meat": +4 Food)
  - **New:** [Salt] "Salt the meat" adds +5 Food

**Sick Traveler**
- Bandages / Medic / Food / Keep moving (as now).
  - On Bandages: ★ Frontier Doctor ("and charges for it": +100-160 chips)
  - ✗ Sickly (on the Medic option: 30% the hero catches it)
- **New** [Preacher] "Sit with the family." → -8 Fatigue all; 1/3 the father lives (trinket).
- **New** [Frontier Doctor + 1 Antivenom] "It's snakebite, not fever." → -10 Fatigue all, a
  trinket, 30% positive quirk.

**Haint Lights** (follow-up)
- **Follow the lights.** 2 they lead somewhere / 2 circles, then attack (+10 Fatigue, fight
  2 Haints).
  - ★ Mountain Mystic ("speaks with them": better odds; the fight drops to 1 Haint)
  - ★ Unbeliever (better odds; Haints start Vulnerable 15%)
  - ✗ Superstitious (worse odds, +10 Fatigue hero)
  - On "lead somewhere", **follow-up:** the lights hover over a lone grave.
    - Dig. → 1/2: buried savings, 160-300 chips · 1/2: the haint rises: fight 2 Haints.
    - Leave a coin (10). → -8 Fatigue all, and 25% a good quirk for the hero ("they feel
      watched over").
- [Salt] Ring the camp / [Preacher] Pray them away (as now).
- **New:** [Lamp Oil] "Light your own lamp and follow." The attack drops to 1 in 4.
- **New, compel 40%:** [Gold Fever] Chase the lights alone. → straight to the grave, without
  the coin option.

**Wolf Tracks**
- [Trapper] Trap line (as now).
- **Hunt them down.**
  - ★ Beast Hunter (+3 Hides)
  - ★ Hunter (rank: the pack starts at 80% HP)
- **Keep a big fire going.** 2 no sleep / 1 attack.
  - ★ Woodcutter (no attack)
- **New** [Mountain Mystic] "Go out and meet the pack." → 3 they let you pass (-6 Fatigue,
  +1 Hides) / 1 a young wolf won't listen (fight 1 wolf, we strike first).
- **New** [Bayou Poisoner] "Poisoned bait." → +2 Hides, no fight, -1 Food.

**Good Hunting**
- **Go hunting.** 3 pronghorn / 2 sore feet.
  - ★ Hunter (rank)
  - ★ Eagle Eye, ★ Beast Hunter
  - ★ Cook (+3 Food on success)
  - ✗ Butterfingers, ✗ Hard of Hearing ("spooks the herd")
- [Hunter] / [Forager] (as now).

**Abandoned Homestead** (follow-up)
- **Search the house.** 3 canned goods / 2 squatters (fight; **new:** +40-80 chips) / 1 wrong
  feeling.
  - ★ Scout (no ambush)
  - ★ Keen-Eyed (+loot)
  - On canned goods, **follow-up:** a cellar door with a fresh padlock.
    - Force it. → 1/2: a trinket · 1/2: the squatters' stash, and they come back (fight).
    - Leave it.
- Tear down the barn (as now).
- **New** [Prospector] "Blast the root cellar." → 2: 80-160 chips, +2 Iron · 1: squatters
  come running, already at 70% HP.
- **New** [Lamp Oil] "Light a lamp and search properly." → +5 Food, 1/3 trinket, no ambush.
- **New, compel 30%:** [Too Curious] "Opens the door nobody wants to open." → 1/2: trinket ·
  1/2: fight 2 Haints.

**New: Twister.** A black funnel walks across the prairie, straight for you.
- **Run for the gully.** 3 safe (+8 Fatigue all) / 1 the wagon is caught (-25 Wagon, -5 Food).
  - ★ Scout
  - ★ Wrangler
  - ★ Mountain Mystic ("reads the sky")
- [Rope] "Tie down the wagon and lie flat." → -8 Wagon. Afterwards **follow-up:** a farm's
  strongbox lies in the debris.
  - Keep it. → 120-200 chips.
  - Find the owner (★ Tracker). → -8 Fatigue all, and 2/3 they give you a trinket.

**New: Cattle Drive.** A short-handed trail boss with 300 longhorns asks for a hand.
- **Ride drag for a day.** 3 paid 80-140 chips (+6 Fatigue all) / 1 stampede (-15% HP one,
  -10 Wagon).
  - ★ Wrangler (better odds; +60 chips bonus)
  - ✗ Overweight
- **Cut out a stray for supper.** → +10 Food; 1/3 the drovers catch you (fight 3 outlaws).
  - ✗ Marshal ("won't steal": the option is hidden if a Marshal is present)
- Wave and ride on.

Homestead stops keep their own Tallgrass list (Homestead, Widow's Claim, Drifter's Camp):
- **Homestead** supper: ★ Cook (+8 Food to take with you).
- **Widow's Claim** wolf den: ★ Beast Hunter (foes start Vulnerable). New: [Gunslinger]
  "Teach her to shoot." → she joins for sure.
- **Drifter's Camp:** new [Train Hopper] "Swap hobo code." → recruit, and reveal 3.

## 5. Dry Gulch Mine (mine country, 6)

**Claim Dispute** (moved from Red Canyons, where it stays as well)
- [Marshal] Settle it / [Miner] Assess the ore (as now).
- **New** [Prospector] "Blast a test hole." → +4 Iron, and both pay 40-80 chips.
- **New** [Gunslinger] "Fire a warning shot." → they both back off: -6 Fatigue all.
- **Stay out of it.** 2 gunshots behind you / 1 they turn on you (fight 2 Claim Jumpers).
  - ✗ Hothead (fight every time)

**New: The Powder Shack.** A shack of sweating dynamite crates, the door hanging open.
- **Carry some out, gently.** 3 got it (+15% Dmg for everyone next fight, "a few sticks to
  throw") / 1 BOOM (-25% HP hero, +10 Fatigue all, 30% Hard of Hearing).
  - ★ Prospector (always safe; also +2 Iron from the blasting caps)
  - ★ Miner (rank)
  - ✗ Butterfingers, ✗ Jumpy, ✗ Hothead
- Leave it. Quickly.

**New: Tapping Underground.** Faint tapping from under a collapsed adit. Someone's alive down
there.
- **Dig them out.** 2 a miner, grateful (recruit a Prospector, or 100-160 chips) / 1 the roof
  comes down (-20% HP hero, 30% Claustrophobic).
  - ★ Miner, ★ Woodcutter (rank: shoring)
  - ★ Rail Driver ("moves the beam alone")
  - ✗ Claustrophobic (worse odds, +10 Fatigue hero)
- Mark the spot and move on. → +8 Fatigue all.

**New: Tommyknockers.** Knocking from the dark mine mouth. The old miners leave the Knockers a
bite of their supper for luck.
- **[2 Food] Leave them a pasty.** → the company's luck turns: -6 Fatigue all, +2 Iron
  "left by the door".
  - ★ Superstitious (bad quirk, good here: also +10 Light in the next cave)
  - ★ Mountain Mystic ("speaks their language": also +10 Light, and 1/3 a trinket left by the door)
- **Mock them.** → 2 nothing / 1 rockfall (-15% HP one) and a fight vs 2 Tommyknockers.
  - ★ Unbeliever (better odds)
  - ✗ Superstitious (refuses; the option is hidden if they're present)
- Walk on. → +4 Fatigue all.

**New: Runaway Burro.** A burro packed with a prospector's kit wanders up to the wagon.
- **Keep it.** → +1 Wagon Parts, +2 Food; 1/3 its owner turns up angry (fight 2 Claim
  Jumpers).
- **Follow its tracks back.** ★ Tracker (rank) / ★ Wrangler.
  - 2: the owner's dead in a wash: his poke (80-140 chips) and his map (reveal 3).
  - 1: he's alive, with a broken leg: rescue him (-6 Fatigue all, recruit a Prospector, 30%).

**New: Ore Wagon Wreck.** A company ore wagon on its side, the driver dead in the traces.
- **Take the ore.** → +4 Iron; 1/3 company guards ride up (fight 2 Railroad Enforcers).
  - ✗ Marshal (hidden while a Marshal is present)
- **Bury the driver.** ★ Preacher (-8 Fatigue all). Otherwise -3.
- [Marshal] "Report it at the next post." → 100-160 chips reward later (paid on return).

The common pool brings Rattler, Fever, the peddlers, Broken Axle, Stuck in the Mud and the
rest. Gulch's old Haint Lights moves to Tallgrass, with the Tommyknockers as the Gulch's own
spooky event.

## 6. Crow's Nest (outlaw country, 6)

**Smoke Signals**
- Ride hard (fight, we strike first) / [Tracker] Circle around / Long way (as now).
- **New** [Gunslinger] "Pick off the lookout." → fight vs 2 (the rifleman is gone), we strike
  first.
- **New** [Prospector] "Dynamite the ridge." → fight, foes at 60% HP, we strike first.
- **New, compel 50%:** [Hothead] charges in before the plan is made. → fight, *they* strike
  first.

**Outlaw Toll**
- Pay (40) / Refuse (fight; **new:** +40 chips if you win) (as now).
- [Marshal] Flash the badge.
  - ★ Bounty Hunter (+1/3 to back down)
- **New** [Gunslinger] "Call out the leader." → 1/2 they ride off (+40-80 chips) · 1/2 fight
  with the leader at 50% HP, we strike first.
- **New** [Gambler] "Double or nothing on a hand." → 1/2 free passage (+40 chips) · 1/2 pay 80,
  or fight if you can't.
- **New, compel 50%:** [Hothead] "Already drawn." → fight; we strike first, but the hothead is
  Vulnerable 10% next fight.

**New: Wanted Poster.** A fresh poster on a fencepost: "SNAKE-EYE PIKE. 200 CHIPS. LAST SEEN
HEREABOUTS."
- **Go after him.** → fight vs Pike (a hired gun, elite) and 1 outlaw; 200 chips.
  - ★ Tracker, ★ Scout (rank: we strike first)
  - ★ Marshal, ★ Bounty Hunter, ★ Manhunter (Pike starts Marked)
- Not our business.
- 1 in 10 posters is a lookalike: "Hey... that looks like {hero}." → +6 Fatigue to that hero;
  ★ Good Humor: -6 for everyone instead.

**New: The Hanging Tree.** Three of Crane's men are about to hang a homesteader.
- **Cut him down.** → fight (3 outlaws), then he joins (recruit) or pays 100 chips.
  - ★ Gunslinger ("shoots the rope": they're surprised, we strike first, the first outlaw at
    50% HP)
- [Marshal] "This hanging ain't lawful." → 2 they back off, he joins / 1 fight.
- **Ride on.** → +10 Fatigue all.
  - ✗ Gloomy, ✗ Maternal Instinct (that hero +10 more)

**New: Stagecoach in Trouble.** Gunfire ahead: a stage is pinned down behind its own horses.
- **Ride to the rescue.** → fight 3 outlaws; reward 120-200 chips and 1/3 a trinket from a
  grateful passenger.
- **Wait, then pick over what's left.** → 80-160 chips, +8 Fatigue all.
  - ★ Gold Fever (+50% chips)
  - ✗ Preacher, ✗ Marshal (that hero +12 Fatigue)

**Abandoned Homestead** is shared with Tallgrass (an event can sit in two region pools).
Crow's Nest's old Wolf Tracks, Good Hunting and Fork move to Tallgrass and the common pool.

## 7. Saloon side-quest themes

| Quest | Theme events (40%) | Notes |
|---|---|---|
| Mad Dog's Hideout | Smoke Signals, Outlaw Toll, Hanging Tree | |
| Rustlers at {place} | Cattle Drive, Buffalo Herd, Wanted Poster | |
| The Wolves of {place} | Wolf Tracks, Good Hunting, Widow's Claim *(homestead)* | |
| The Haint at {place} | Haint Lights, Row of Graves, Abandoned Homestead | |
| Claim Jumpers at {place} | Claim Dispute, Powder Shack, Runaway Burro | |
| Snakes in {place} | Rattler in the Bedroll, Medicine Show, Sick Traveler | Sick Traveler becomes the snakebite case |
| Crane's Scouts near {place} | Smoke Signals, Wanted Poster, Stagecoach | |

The rest of a quest's events come from its base region (Tallgrass for Fort Providence) and
the common pool.

## 8. Tally

- **Events in the first region:** 15 common + 10 Tallgrass + 6 Dry Gulch + 6 Crow's Nest.
  - 12 of these are new: Card Game, Medicine Show, Twister, Cattle Drive, Powder Shack,
    Tapping Underground, Tommyknockers, Runaway Burro, Ore Wagon Wreck, Wanted Poster,
    Hanging Tree, Stagecoach. *(Claim Dispute moves in from Red.)*
  - A Dry Gulch map now sees 21 possible events instead of 10, and Crow's Nest 21 instead of
    10.
- **Every class has a role:**

  | Class | Events where it's an expert or has a secret option |
  |---|---|
  | Marshal | 8 |
  | Preacher | 6 |
  | Gambler | 5 |
  | Gunslinger | 6 |
  | Wrangler | 9 |
  | Rail Driver | 3 |
  | Prospector | 5 |
  | Bayou Poisoner | 3 |
  | Frontier Doctor | 5 |
  | Train Hopper | 3 |
  | Mountain Mystic | 4 |

- **Survival skills:** all 12 appear. Cook now shows up 5 times.
- **Quirks:** 27 quirks matter somewhere.
  - Good: Unbeliever, Trailwise, Keen-Eyed, Lucky, Good Humor, Beast Hunter, Bounty Hunter,
    Manhunter, Eagle Eye, Iron Stomach.
  - Bad: Drinker, Gold Fever, Too Curious, Hothead, Spooked by Critters, Superstitious,
    Sickly, Butterfingers, Overweight, Jumpy, Hard of Hearing, Claustrophobic, Gloomy,
    Homesick, Slowpoke, Maternal Instinct.
  - Lightning Rod has a funny one.
- **Quirks given at low %:** Spooked by Critters, Sickly (×3), Hard of Hearing, Claustrophobic,
  plus a random good quirk (×2).

## 9. Engine work

1. **Pools:** a `common` list in `events.json` (or a pool tag per event), region lists stay,
   and a quest template `events` list. Weights go in config. The map picks a layer, then an
   event, without repeats.
2. **Event experts:** reuse the curio expert code, add quirks as an expert key, and allow ★/✗
   on any option. The best expert acts, and the event screen lists the lines under each option.
3. **`compel`** on quirk options.
4. **Follow-ups:** an outcome with `then: [options]` shows a second choice in the same window.
5. **Fight setup:** `wounded`, `drop`, `foe_mods`, `foe_marked` on a fight effect.
6. **Hide an option** when a given class or quirk is present (Marshal won't steal).
7. Smaller items:
   - "next fight" debuffs (wet powder, hungover) already work.
   - `light` for the next cave already exists.
   - A "paid on return" reward goes into the expedition loot, which already exists.
8. **Tests:** every requirement is valid, pools never repeat, experts move the odds, compel
   fires, follow-ups resolve, and fight setup reaches the fight.

## 10. Questions for the owner

1. Are the pool weights right (45 common / 55 region; quests 40 theme / 30 / 30)?
2. Should the ★/✗ lines show on the event options, as at curios? (Recommended.)
3. Which new events to keep? All 12, or a shortlist?
4. Is a 30-50% compel right for the bad quirks?
5. Build it in two passes? (1) pools, experts, compel, fixes and the existing events;
   (2) the new events and follow-ups.

---

## Appendix: every event as it is today

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
