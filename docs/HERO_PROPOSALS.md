# Hero proposals (round 8)

Options for the owner to pick from. Nothing here is in the game yet. **Revision 2** (the
owner's picks and revised specs) comes first; the original option lists follow for
reference.

- **Part 1:** moves to round out the four classes with fewer than 8.
- **Part 2:** two new hero designs in lanes no class covers yet.

**Numbers.** Damage and odds are level-1 values, judged against the average tier-1 enemy
(`tools/hero_power.py`: 14.5 HP, 12 dodge, 33% stun resist). For scale, a good single-target
attack expects about 6-7 damage per turn and a good stun about 0.4-0.5 expected stuns.

**Engine support.**
- ✅ means the engine already supports the move; it is data only.
- 🛠 means the move needs a new mechanic. Each 🛠 lists the work it needs.

---

## Revision 2: the owner's picks and revised specs

**Decisions.**
- **Prospector:** none of the options; hold for now.
- **Frontier Doctor:** Bloodletting, renamed **Transfusion**, and **Adrenaline Shot**, with
  a heal that scales with how hurt the ally is.
- **Preacher:** **Baptism in the River**, reworked to target an enemy with a small extra
  effect; **Hellfire Sermon**, tuned so its all-enemies effect isn't overpowered.
- **Bayou Poisoner:** a fever move in the style of his random targeting.
- **New heroes:** both approved. The Shotgun Guard gets two stances plus the counter-attack.
  The Pony Express Rider becomes the **Train Hopper**, with a Momentum gauge that charges a
  mega attack.
- **Vulnerable** should appear in more places (see the end of this section).

### Bayou Poisoner: Mosquito Swarm (Swamp Fever)
From 3-4 → **3 random hits across ranks 1-4**, acc 90, 1-2 damage each.
- Each hit applies Poison 1 for 3 rounds.
- A hit on an **already poisoned** target applies Poison 2 instead: the fever spreads
  where it has taken hold.
- Expected: about 3.6 poison damage on a fresh line, about 6 once Darts and Sacrament have
  poisoned it. The payoff for his existing kit, rather than a new trick.
- 🛠 small: an `amount_if_target_poisoned` field, the mirror of the existing
  `amount_if_self_poisoned`.
- Alternative (closer to the first Swamp Fever): 2 random targets; each poisoned one also
  passes a copy of its poison to a random other enemy. 🛠 poison spreading.

### Frontier Doctor: Transfusion
From 3-4 → one enemy in 1-3, acc 90, 3-5 damage.
- The **most wounded ally** (by HP %, the Doctor included) is healed for **150% of the
  damage dealt**. A miss heals nothing; a crit heals more.
- Expected per cast: about 3.1 damage plus 4.7 healing, about 7.8 total value. That's level
  with a good single move, below Laying On of Hands' 8 healing, but it also damages.
- The heal scales with move level, like other heals.
- 🛠: a heal-from-damage effect that targets the most wounded ally.

### Frontier Doctor: Adrenaline Shot
From 3-4 → one ally. +3 Speed for 2 rounds. The heal grows the worse off the ally is:

| Ally's HP | Heal |
|---|---|
| above 50% | 2-4 |
| 25-50% | 4-7 |
| under 25% | 6-10 |
| on Death's Door | 10-14, and clears Shaken |

- Always worth casting, and a big save if you manage to land it at the brink.
- 🛠 small: `heal_tiers` on a heal (HP-percentage bands).

### Preacher: Baptism in the River (enemy)
From 2-4 → one enemy in 1-3, acc 95, no damage.
- **Washes away every boon on the target** (a dispel: pack buffs, Silas's crows, boss
  buffs).
- Leaves it **Soaked** for 2 rounds: -2 Speed and -10 Dodge.
- Against mythic creatures, also a 40% stun.
- Nobody can dispel today, so it's a strong answer to buffed bosses without raw damage.
- 🛠: a dispel effect.

### Preacher: Hellfire Sermon (tuned)
From 3-4 → all enemies in 1-4.
- **Shipped (owner's tune):** -5 Accuracy and -10% Damage for 2 rounds, base chance 75%.
  About 47% sticks after the average 28% debuff resist. (First draft: -10 Accuracy.)
- Mythic targets: base 100%, so about 72% sticks.
- Costs the Preacher 4 Fatigue.
- **Expected value:** about 1.9 enemies affected, preventing roughly 3 HP of damage over the
  2 rounds. That's on par with Bellow, below a heal, and worth it mainly against mythic
  packs. It can't snowball: debuffs from it don't stack, a recast refreshes them.
- ✅ data only (the mythic bonus can use a second effect entry).

### The Shotgun Guard: two stances
A **stance** is a lasting state that holds until he switches. Switching uses his turn, and
each stance has its own moves that hit harder in it.

| | **Ride Shotgun** (offence) | **Hold the Strongbox** (defence) |
|---|---|---|
| Passive | **Counter-attack**: any enemy that hits him is fired on for 50% damage | +20 Protection, +40 Stun and Move Resist |
| Also | +10% damage, -5 Protection | The ally behind him gets +10 Protection |
| Shines with | Both Barrels (+25% in this stance), Buckshot Spread | Rock Salt (debuff +50% longer), Dig In (heals 20% instead of 15%) |

- **Starting stance:** Strongbox. His stock moves are the two stance switches plus Both
  Barrels.
- **Counter-attack** uses his weapon damage at 50%, once per hit taken, and can't crit. He
  doesn't counter a counter.
- 🛠: stances (a lasting state, stance-dependent move bonuses) and the counter-attack.

### The Train Hopper (was the Pony Express Rider): Momentum gauge
A rail-riding drifter who leaps between moving cars.
- **The Momentum gauge** is a bar under her HUD, 0-100. It gains:
  - +25 whenever she moves (her own moves all move her);
  - +15 when she swaps with an ally;
  - +10 when she lands a hit from a rank she wasn't in last turn.
- **At 100** her mega attack unlocks: **Runaway Train**. She charges through the whole enemy
  line:
  - 6-10 damage to every rank;
  - shoves rank 1 to the back (the line reshuffles);
  - Vulnerable on everyone for 2 rounds;
  - the gauge empties.
- About 3-4 turns to charge.
- Her other moves follow the earlier design: Saddle Shot, Ride Through, Change of Cars
  (swap with any ally), Express Delivery (swap two enemies), Coal Dust (Mail Bag reflavoured),
  Neither Rain nor Snow.
- 🛠: the gauge (stored per combatant, drawn on the HUD), the mega attack's unlock, enemy
  swap, swap with any ally, Vulnerable.

### The Train Hopper: workshop (revision 3)

A rail-riding drifter who leaps between moving cars. She wants to move every turn, and her
Momentum gauge rewards it.

**Stats:** HP 18 · Dodge 14 · Speed 7 · Crit 7% · damage 4-8 · ranks 1-4 (prefers 2-3) ·
move resist 30. Low on purpose: being shoved around feeds her gauge.

**The Momentum gauge** (0-100): a steam-gold bar under her HP and Fatigue bars, with a
tooltip.

| Source | Momentum |
|---|---|
| Each rank she moves, by her own move or a swap she starts | +20 |
| Being moved by anyone else (an ally's swap, an enemy's knockback) | +10 (she rolls with it) |
| Landing a hit on the turn she moved | +10 ("hopping on") |
| Ending her turn **without moving** | -15 ("losing steam") |
| Being stunned | -25 |

**Thresholds:**
- **50+ "Full Steam":** +3 Speed and +5 Dodge while the gauge stays above half.
- **100: Runaway Train unlocks** as an extra button. It doesn't take one of her 4 move slots.
- The gauge resets to 0 each fight, so a fight is about building to the mega attack.

**Runaway Train (mega):** usable from any rank at 100.
- She charges through the whole enemy line: 5-9 damage to all 4 ranks, the front enemy is
  thrown to the back, and every enemy hit is Vulnerable 15% for 2 rounds.
- She ends in rank 1 and the gauge empties.
- Expected: about 22 damage plus the Vulnerable window, once every 3-4 turns. That's about
  9 a turn averaged, a carry's output, paid for with her fragility.

**Moves (8)**, every one of which moves her or the line:

| Move | From → hits | Damage | Effect | Momentum |
|---|---|---|---|---|
| ★ **Hop the Car** | 2-4 → one of 1-3 | 3-6 | Hits, then moves back 1 | +20, +10 for the hit |
| ★ **Boxcar Leap** | 3-4 → one of 1-2 | 4-7, +10% crit | Moves forward 2, then strikes | +40, +10 |
| **Coupling Pin** | 1-2 → one of 1-2 | 3-5 | Uncouples it: the target swaps with the enemy behind it | +10 if she moved this turn |
| **Coal Dust** | 2-4 → all of 3-4 | - | -8 Acc and -2 Speed for 2 rounds, then she moves back 1 | +20 |
| **Switch Tracks** | 1-4 → any ally | - | Swaps with any ally (not just a neighbour); both +2 Speed for 2 rounds | +15 |
| **Railspike Toss** | 3-4 → 2 random of 1-4 | 2-4 each | Vulnerable 10% for 2 rounds; she plants her feet (no move) | none (a setup turn) |
| **Stoke the Boiler** | 1-4 → self | - | +2 Speed for 2 rounds; she doesn't move but loses no steam this turn | +25 |
| **Duck the Tunnel** | 1-4 → self | - | +20 Dodge for 1 round, moves back 1 | +20 |

**Synergies:**
- She's fed by the Rail Driver's knockbacks and anyone who swaps with her.
- The Wrangler's speed buffs help her act first.
- Vulnerable from her Railspikes and the Runaway Train amplifies the whole party.
- Coupling Pin can drag a back-line sniper into the Shotgun Guard's reach.

**Engine work:**
- a per-combatant Momentum value, with the triggers above;
- the HUD gauge and its tooltip;
- an extra mega button gated on a full gauge;
- the enemy swap (Coupling Pin) and swap-with-any-ally (Switch Tracks);
- Vulnerable is already done.

**Art:** a new character look (a drifter in a long coat and flat cap, a bindle, coal-smudged),
three outfits, and a steam-gold palette for the gauge.

### The Train Hopper: revision 4 (owner's kit, single-target burster)

**Identity:** a drifter who rides the rails. She builds Momentum by moving and spends it on
one huge single-target hit. The rhythm is forward from the back, back from the front, then
**End of the Line**. She can Mark for the party (Chart the Hills) and add Vulnerable
(Railspike Toss). Runaway Train (all enemies) is dropped.

**Momentum:** every move lists its own gain (below). Passive: moved by someone else +10;
stunned -25; ending a turn without moving -10. Reset to 0 each fight. **Full Steam** at 50+:
+3 Speed, +5 Dodge.

**End of the Line (mega, extra button at 100):** any rank → one of 1-4, **10-18** damage,
+50% vs Marked, ignores half the target's Protection. She lands in rank 1 and the gauge
empties; **if it kills, she keeps 50**. Against a Marked and Vulnerable target: about 23.

| Move | From → hits | Damage | Effect | Momentum |
|---|---|---|---|---|
| ★ **Boxcar Leap** | 3-4 → one of 1-2 | 4-8 | moves forward 1, then strikes | +30 |
| ★ **Stowaway** | 1-2 → self | - | moves back 1; heals 2-3; cures Bleed | +30 |
| ★ **Chart the Hills** | 1-4 → one of 1-4 | - | Marks the target for 3 rounds; she moves forward 1 | +20 |
| **Railspike Toss** | 2-4 → one of 2-4 | 3-5 | Vulnerable 10% for 2 rounds; she moves forward 1 | +20 |
| **Emergency Brake** | 1-2 → self | - | moves back 2; +10 Dodge for 2 rounds; clears all debuffs | +30 (proposed) |
| **The Dancing Man** | 3-4 → self | - | Marks herself for 2 rounds (draws fire); +12 Dodge for 2 rounds; moves forward 1 | +20 (proposed) |
| *proposed* **Ride the Rods** | 1-2 → one of 2-3 | 4-8, +8% crit | dives under the front line to strike behind it, then moves back 1 | +30 |
| *proposed* **Catch Out** | 1-4 → any ally | - | swaps with any ally (not just a neighbour); both +2 Speed for 2 rounds | +20 per rank she travels |

**Engine work:** per-combatant Momentum and its triggers, a per-move `momentum` field, the
HUD gauge, the mega button, a kill refund, swap-with-any-ally (Catch Out), and a self-Mark.

### Vulnerable: where else it fits
Vulnerable (+X% damage taken from all sources) is different from **Mark** (enemies target
the marked hero, and some moves deal bonus damage to marked targets). Keep both.

**Hero moves whose flavour already says "exposed"** (swap their current debuff for, or add,
Vulnerable 10-15%). *Owner's call after shipping: the three marking moves (Quarrel, Joker,
Warrant) dropped it again, as marking plus Vulnerable double-dips. Hogtie keeps it.*
- Rail Driver **Quarrel** ("cracks its guard": -15 Prot today).
- Wrangler **Hogtie** (tied up, can't brace).
- Gambler **Assign the Joker** (off their game).
- Marshal **Serve a Warrant** (the whole posse piles on).

**System rules** (small, game-wide):
- **Stunned → Vulnerable 10% for the stun's turn** ("caught flat-footed"). Makes every stun
  in the game worth a little more.
- **Surprise rounds:** the side caught off guard is Vulnerable 15% in round 1.

**Fatigue:**
- The **Reckless** Breaking Point adds Vulnerable 10% (charging in without cover).
- The **Fired Up** Second Wind could ignore it.

**Quirks and trinkets:**
- Negative quirk **Glass Jaw**: Vulnerable 10% always.
- Positive quirk **Thick-Skinned**: -10% damage taken.
- High-risk trinkets: e.g. **Gambler's Last Coat**, +15% damage but Vulnerable 10%.

**Enemies:**
- Crows' **Peck the Eyes**.
- The Cyclops' **Ground Shake** (the whole party Vulnerable 1 round).
- Gila monster venom.
- Bosses with a "rage" phase that are themselves Vulnerable (a window to burst them down).

**Caves:** in Pitch Black, heroes are Vulnerable 10% (in place of part of the current
enemy-damage bonus).

---

## Part 1: filling out movepools

### Prospector (6 moves, needs 2): demolitions, caves, the lamp

| # | Move | From → hits | Effect | Why | Engine |
|---|---|---|---|---|---|
| P1 | **Strapped Charge** | 2-4 → one of 1-3 | Straps a lit bundle to the target. At the end of its next turn (or when it is next hit) it blows: 6-9 damage to it and 3-4 to each neighbour, 40% stun. | Your backlog idea: a delayed bomb you set up, then let the party trigger. Nobody else has delayed damage. | 🛠 a fused charge that detonates on a trigger |
| P2 | **Shore Up the Tunnel** | 2-3 → whole party | Party +8 Protection for 2 rounds. In a cave, also +10 Lamplight and -3 Fatigue. | A miner's defensive call that makes him wanted in caves. Protects the party without guarding or taunting (the Marshal's tools). | ✅ |
| P3 | **Canary in a Cage** | 2-4 → whole party | Cures Poison on everyone; party +20 Poison Resist for 3 rounds. In a cave, the party can't be surprised in the next room. | Old miner's lore. A direct answer to snakes, gila monsters and poison-heavy fights. | ✅ in combat; 🛠 the cave no-surprise part |
| P4 | **Controlled Cave-In** | 3-4 → 2 random enemies in 1-4 | 5-8 damage to each, 35% stun. Costs the Prospector 2 HP (falling rock). | Uses Old Jeb's random-target mechanic. A riskier, harder-hitting option than Dynamite Toss. | ✅ (random_targets, self_damage) |
| P5 | **Gold Strike** | 1-2 → one of 1-2 | Pickaxe swing for 5-9. On a kill: +30 chips and -5 Fatigue. | The forty-niner's dream. Gives the front-rank Pickaxe build a payoff. | ✅ (on_kill) |

**Suggested pick: P1 + P2.** That gives the Prospector a signature trick and a cave-support role.

### Bayou Poisoner (7 moves, needs 1): poison stacking, resist shred, self-poison synergy

| # | Move | From → hits | Effect | Why | Engine |
|---|---|---|---|---|---|
| B1 | **Swamp Fever** | 3-4 → one of 1-4 | The target's Poison spreads: each neighbour gets a copy of its current Poison. 2-3 damage. | A payoff for stacking poison on one target. Unique: nobody spreads status. | 🛠 spread existing damage-over-time to neighbours |
| B2 | **Gator Bait** | 2-3 → one of 3-4 | Hauls a back-liner forward 1 into the gator's jaws: 3-5 damage, Bleed 2 for 3 rounds. | Bleed and poison on the same target, plus the class's only movement. | ✅ (pull, bleed) |
| B3 | **Spanish Moss** | 2-4 → self | Dodge +20 and moves back 1. If poisoned: also +10% damage for 2 rounds. | A self-defence turn that fits the class's self-poison style. | ✅ (self_poisoned_bonus is a damage field; the buff version is 🛠 small) |
| B4 | **Snakeroot Tonic** | 2-4 → self | Ends the Poisoner's own Poison and heals 2 per poison point removed (about 4-8). | Turns Questionable Mushroom's cost into sustain. | 🛠 heal per cured stack |

**Suggested pick: B1.** It's the most distinctive; B2 if you want data-only.

### Frontier Doctor (6 moves, needs 2): medicine with a cost, poison, stuns

| # | Move | From → hits | Effect | Why | Engine |
|---|---|---|---|---|---|
| D1 | **Bloodletting** | 3-4 → one of 1-3 | Lances an enemy for 3-5 and heals the most wounded ally for the damage dealt. | Turns attacks into healing, so the Doctor isn't stuck choosing between damage and heals. | 🛠 heal-from-damage to an ally |
| D2 | **Inoculation** | 3-4 → one ally | +30 Bleed and Poison Resist for 3 rounds, and immune to Shaken this fight. | Prevention instead of cure; the doctor who saw it coming. | ✅ resists; 🛠 the Shaken immunity (or drop it) |
| D3 | **Adrenaline Shot** | 3-4 → one ally | Heals 3-5, or 8-12 if the ally is on Death's Door. Speed +3 for 2 rounds. | A clutch save that only shines in emergencies. Distinct from the Preacher's steady heals. | 🛠 heal bonus on Death's Door |
| D4 | **Bone Saw** | 2-3 → one of 1-2 | 3-6 damage, Bleed 3 for 3 rounds; 20% chance the Doctor gains +5 Fatigue (grim work). | Gives the Doctor a front-ish attack, and pairs with the poison flask. | ✅ |
| D5 | **Quarantine** | 3-4 → one of 1-4 | Marks the target; it takes +25% from Poison and Bleed and heals 50% less, for 3 rounds. | An anti-healer debuff (useful against haints and bosses that mend). | 🛠 damage-over-time amplifier and healing-received debuff on enemies |

**Suggested pick: D1 + D3.** That makes the Doctor the risky-but-clutch medic, beside the Preacher's steady one.

### Preacher (6 moves, needs 2): healing, party spirit, scourge of the unnatural

| # | Move | From → hits | Effect | Why | Engine |
|---|---|---|---|---|---|
| R1 | **Baptism in the River** | 2-4 → one ally | Cures every debuff, Bleed, Poison and Stun; heals 2-4; clears Shaken. | A full cleanse. The Marshal's badge clears debuffs and stun, but not damage-over-time or Shaken. | ✅ (cure kinds, clear_shaken) |
| R2 | **Last Rites** | 3-4 → one ally | +20 Deathblow Resist and +10 Protection for 3 rounds. | Protects someone about to fall; matters with permadeath. | 🛠 small: the Death's Door check reads the hero's base stats, so it must also count combat buffs |
| R3 | **Pass the Plate** | 3-4 → one of 1-4 | Strips all the target's boons. 1-3 damage. | The first answer to buffed bosses and pack buffs (wolves, Silas). | 🛠 remove enemy buffs |
| R4 | **Hellfire Sermon** | 3-4 → all of 1-4 | Enemies -8 Accuracy and -2 Speed for 2 rounds; +6 against mythic creatures. Costs the Preacher 4 Fatigue. | An area defence-by-fear move, and a reason to bring the Preacher to the mythic regions. | ✅ |
| R5 | **Hymn of the Trail** | 2-4 → whole party | Party +2 Speed for 2 rounds and -2 Fatigue. | A tempo hymn; small but stacks with Sermon on the Trail. | ✅ |

**Suggested pick: R1 + R3.** Cleanse and dispel are the two jobs no one does.

---

## Part 2: new heroes

The existing lanes, so the new heroes stay out of them:
- **Marshal:** guard/redirect, taunt, cleanse.
- **Mountain Mystic:** blood price.
- **Rail Driver:** knockback and self-rhythm.
- **Gunslinger:** fast multi-hit.
- **Wrangler:** pull plus mark, party buffs.
- **Gambler:** chance and random party boons.
- **Prospector:** area blasts and stuns.
- **Bayou Poisoner:** poison stacking.
- **Frontier Doctor:** cost-heals.
- **Preacher:** heals and fatigue relief.

Nobody yet does any of these:
- **counter-attacks** (punishing attackers);
- **damage sharing or soaking for neighbours**;
- **reordering the enemy line** (only straight knockback and pull exist);
- **a damage-taken amplifier** ("Vulnerable");
- **momentum** (getting stronger by moving).

### A. The Shotgun Guard: tank, retaliation and holding the line (ranks 1-2)

> Rode shotgun on the Overland Stage for nine years and never lost a strongbox. Doesn't
> shield anyone: makes attacking the coach a very bad idea.

HP 28 · Prot 15 · Dodge 0 · Speed 1 · Crit 3% · damage 5-9 · stun resist 55, move resist 70.

**The lane:** where the Marshal *redirects* hits, the Guard *punishes* them. Enemies that
attack the Guard or the ally beside him get shot back, so they either waste turns on the
toughest hero or pay for every swing. He hardens the front line instead of taunting. He's
also the obvious candidate to defend the **wagon** if it becomes a fifth combatant.

| Move | From → hits | Effect | Engine |
|---|---|---|---|
| ★ **Ride Shotgun** | 1-2 → self | **Riposte** for 3 rounds: every enemy that hits him takes a 50% buckshot counter. +10 Protection. | 🛠 riposte |
| ★ **Both Barrels** | 1-2 → one of 1-2 | 7-11 damage, then he must spend a turn to **Reload** before using it again. | 🛠 reload lock (or once per fight to keep it data-only) |
| **Buckshot Spread** | 1-2 → all of 1-2 | 3-5 each; -10 Dodge for 2 rounds. | ✅ |
| **Slug Round** | 1-2 → one of 1-3 | 5-8 damage that ignores 40% of Protection (an armour breaker for brutes and bosses). | ✅ as a pierce self-buff for a few rounds; 🛠 small for a per-shot version |
| **Shoulder to Shoulder** | 1-2 → self and the ally behind | Both gain +15 Protection for 2 rounds; Riposte extends to cover that ally. | 🛠 adjacent-ally targeting, riposte for an ally |
| **Hold the Strongbox** | 1-2 → self | +25 Protection and +40 Stun/Move Resist for 2 rounds; can't be moved. | ✅ (the "can't be moved" part is very high move resist) |
| **Rock Salt** | 1-2 → one of 1-3 | 2-4 damage, the target is Rattled: -15% damage and -5 Accuracy for 2 rounds. | ✅ |
| **Dig In** | 1-2 → self | Heals 15% of max HP and clears his own debuffs; if below half HP, also Riposte 2 rounds. | ✅ heal and cure; 🛠 the conditional riposte |

**Power check:** effective HP about 39, the highest in the game. Single-target damage about
6, on par with the Marshal. His value is counter-damage: with Riposte up and two enemies
swinging at him at about 80% to hit, that's roughly 2 × 0.8 × 3.5 ≈ 5.6 extra damage a
round, at no cost to his turn.

**New engine work:** riposte (counter on being hit, optionally for an ally), a reload lock,
and adjacent-ally targeting. Riposte is the core; the other two can be faked with data at
first.

### B. The Pony Express Rider: hit-and-run, enemy reordering and Vulnerable (ranks 1-4)

> Seventy-five miles a day, a fresh horse every ten, and the mail always gets through. In a
> fight she never stops moving, and she rides straight through whoever's in the way.

HP 18 · Prot 0 · Dodge 14 · Speed 7 (the fastest hero) · Crit 7% · damage 4-8 ·
move resist 60.

**The lane:**
- **Every attack moves her.** The party's formation shifts every turn, which pairs with
  heroes who like the ranks she leaves.
- **Momentum.** Each move she makes grants a stack: +6% damage, up to 4. Her finisher spends
  them all.
- **She rearranges the enemy line.** She doesn't push it straight back or pull it straight
  forward: she swaps enemies, dragging a back-line sniper forward or shoving a tank back.
- **She brings Vulnerable,** a new debuff: the target takes +20% damage from everyone. That
  makes her a force multiplier rather than a pure damage dealer.

| Move | From → hits | Effect | Engine |
|---|---|---|---|
| ★ **Saddle Shot** | 2-4 → one of 1-4 | 4-7 damage, then moves back 1. | ✅ |
| ★ **Ride Through** | 3-4 → one of 1-2 | 5-8 damage, moves forward 2, the target is **Vulnerable** (+20% damage taken) for 2 rounds. | 🛠 Vulnerable |
| **Change of Horses** | 1-4 → any ally | Swaps places with any ally, not just a neighbour; both gain +2 Speed for 2 rounds. | 🛠 swap with any rank |
| **Express Delivery** | 1-3 → one of 1-4 | 2-4 damage; the target **swaps with the enemy behind it** (or in front, if it's last). | 🛠 enemy swap |
| **Mail Bag** | 2-4 → all of 3-4 | 1-3 each; -3 Speed and -6 Accuracy for 2 rounds (blinded by flying letters). | ✅ |
| **Spur Hard** | 1-4 → self | +2 Momentum and +3 Speed for 2 rounds; moves forward 1. | 🛠 momentum |
| **Last Leg** | 1-2 → one of 1-2 | 5-8 damage, +25% per Momentum spent (up to 4: 2× damage); ends Momentum. | 🛠 momentum |
| **Neither Rain nor Snow** | 1-4 → self | Clears her stun and debuffs; +30 Stun Resist for 2 rounds; moves back 1. | ✅ |

**Power check:** Saddle Shot expects about 4.7; Last Leg at 4 Momentum about 10-11. The
real value is Vulnerable: +20% on everything the party lands on that target for 2 rounds,
roughly +2.5 damage per party attack, about 8-10 a round with three attackers. She's fragile
(effective HP about 23, Gambler territory), but speed 7 means she usually acts first.

**New engine work:** the Vulnerable stat (a damage-taken multiplier), Momentum (stacks
gained on moving, spent by a finisher), swapping two enemies, and swapping with any ally.
Vulnerable is also useful beyond her, for enemy designs and trinkets.

### Alternates (one line each, if neither lands)

- **Tank: the Blacksmith (Farrier).** Hardens allies with Protection, sunders enemy armour,
  and reforges broken gear mid-fight. A "Protection economy" tank. Less new tech, less
  distinct.
- **Damage: the Wildcatter.** Spills oil that makes enemies slip (move resist down) and then
  ignites it as a new **Burn** status. Very combo-heavy, close to the Prospector's
  explosives.
