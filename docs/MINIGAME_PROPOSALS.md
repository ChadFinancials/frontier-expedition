# Hands-on moments: High Noon duels and skill checks (proposal)

Status: **✅ both built** (High Noon and the curio skill checks; round 3 picks below). Tuning numbers are in config `duel` and `checks`.

Owner's round 3 picks:
- The Lone Wanderer is a duel for pride only: no recruit, no wager.
- Curios can still be passed by. Investigating by hand means playing the check, unless the
  right item or an as-key class is used.
- Rattled lasts until the expedition ends.
- Mad Dog gets a standoff right before his fight; other bosses can get one later.
- Skill checks: clean → almost always good; sloppier → likelier bad; botched → bad. Tune
  after it's built.
- A dev button for testing without an expedition: "DEV: Minigames" (duels and skill checks).

The goal is to give expeditions moments where the player's own hands decide things, built
around the West rather than Darkest Dungeon. Two features:

1. **High Noon:** a two-part duel before certain fights.
2. **Skill checks:** short hands-on tasks at some curios.

## Rules that apply to both (owner, round 2)

- **No skipping.** When a minigame comes up, you play it. The only way around one is the
  right item: a Shovel forces a Strongbox open, Rope gets you down the Well, and so on, as
  supply keys work today.
  - As-key experts (the Preacher "works as Salt" at a grave) also count as the right item.
  - Inside the code the scoring is still plain logic, so the tests and the balance bot
    resolve minigames without a screen.
- **The company changes the difficulty, not the payout.** A ★ expert (class, survival skill
  rank, quirk) makes the game easier; a ✗ makes it harder.
- **Controls:** the mouse or Space for timing; arrow keys or WASD for patterns.
- **Short:** 5-15 seconds each.
- Risk to keep in mind: with no skip, the duel's reaction part must stay fair for slower
  hands. ★ help and a generous base window matter.

## 1. High Noon

### Duels are their own stops, and the consequence comes later

A duel is a stop on the trail, not an opener glued to a fight. Whoever you face rides off,
and their gang is **a fight further down this map**. That fight is marked on the map once
you know about it ("Pike's gang: Pike is bleeding"). Your shot decides how that later fight
starts:

| Your result | The duelist in the later fight |
|---|---|
| **Bullseye** (hard: a 4% zone) | Dead: removed from the fight. His bounty is paid now if he's wanted |
| **Hit** | Starts at 50% HP and bleeding |
| **Graze** | Starts bleeding (3 rounds) |
| **Miss** | Unhurt, and your hero is **Rattled** |
| **Too slow** (he fires first) | Your hero takes a hit (15% HP) and still gets a shot, with narrower zones |
| **Jumped the gun** | No shot at all: your hero is Rattled and takes the hit |

**Rattled:** -10 Accuracy and -5 Dodge until the next camp. It shows as a status on the hero
card, like Shaken. (The duration is the owner's call: next fight only, or until camp.)

If no fight is left ahead on the map, the duelist's gang jumps you at the next stop instead.

### Where duels come from (first region)

| Duel | How it starts | Stakes beyond the later fight |
|---|---|---|
| **The Lone Wanderer** (new event, common pool) | A stranger at a crossroads: "Heard you're quick. Let's find out." You may decline (+Fatigue) or put up chips | Win: double your wager, or the wanderer, beaten fair, asks to join (recruit). Lose: Rattled, the wager gone. No later fight: it's about pride |
| **Outlaw Toll:** "Call out the leader" | The leader steps out | The toll gang becomes the later fight |
| **Wanted Poster:** "Go after him" | You find Snake-Eye Pike at a waterhole | Pike's gang (Crow Lieutenant + outlaw) waits further on; bullseye pays the 200 bounty now |
| **Hanging Tree** | The hangman turns to face you | Bullseye: the rope's shot through and the homesteader joins; the hangman's gang waits ahead |
| **Mad Dog** (boss) | A standoff as you reach the hideout, right before the boss fight | Bosses can't die to it: a bullseye leaves him at 50% HP and bleeding |

### Who draws

You pick the hero. The picker shows ★/✗ names, as at curios:
- ★ Gunslinger, ★ Marshal, ★ Bounty Hunter quirk
- ✗ Butterfingers, ✗ Jumpy, ✗ Drinker (hungover)

### Part 1: The Draw (reaction)

- A dusty street, two silhouettes. A random wait of 1.5-4.0 seconds, then **"DRAW!"** with a
  bell or gunshot. Click or press Space.
- **False cues:** a crow caws or a tumbleweed rolls before the real signal, so the player
  has to wait for "DRAW!" and not jump at the first sound.
- **Jumping the gun** (clicking before DRAW) loses Part 1 at once.
- Your reaction time is compared with theirs:

| Opponent | Draw time |
|---|---|
| Outlaw leader | 0.55 s |
| Pike / lieutenant | 0.45 s |
| Mad Dog | 0.50 s (slow hands, hits hard) |
| Later regions | down to 0.32 s |

- **Your hero's edge** is subtracted from your time:

| Source | Edge |
|---|---|
| Gunslinger | -0.10 s |
| Quick Draw move level | -0.02 s a level |
| Marshal | -0.05 s |
| Each point of Speed above 4 | -0.01 s |
| Jumpy | one extra false cue |
| Hard of Hearing | no sound cue, only the visual |

- **Faster:** you get the aim at full width. **Slower:** they fire first (-15% HP for the
  hero, and the aim zones shrink by a third), and you still get your shot.

### Part 2: The Aim (swinging sight)

A horizontal bar, with a sight swinging back and forth like a football kick meter. One click
to fire. The zones run from the edges to the centre:

| Zone | Width at base | Result |
|---|---|---|
| Miss (edges) | the rest | the miss result above |
| Graze | 30% | bleeding |
| Hit | 14% | 50% HP and bleeding |
| Bullseye (centre) | 4% | dead (bosses: 50% HP and bleeding) |

- The sight speeds up with the opponent's tier.
- Zone widths scale with the hero:
  - Gunslinger +40%, Marshal +20%, Eagle Eye +20%
  - Butterfingers -25%
  - Hungover (Drinker after a night's drinking) makes the sight wobble
  - The hero's accuracy stat adds up to ±10%

### Look

A wide letterbox panel in the paper style: a cut-out street at noon, two figures and a swinging
sign. The DRAW text slams in. Sounds already exist: bell, gunshot, crows.

## 2. Skill checks at curios

"Investigate by hand" on some curios opens a 5-10 second task instead of a dice roll, and it
can't be skipped. The right supply (a Shovel on the Strongbox) is the only way around it, as
are as-key experts.

### Four reusable games

| Game | How it plays | Made easier by ★ | Made harder by ✗ |
|---|---|---|---|
| **Tumblers** (Fallout-style lock) | A needle sweeps a dial; press when it crosses the sweet spot, 3 pins in a row | Wider sweet spot, slower needle | Narrower, faster |
| **Pattern** (memory) | A sequence of 4-7 arrows flashes for about 2 seconds; type it back | Shorter sequence, longer look | One more arrow, shorter look |
| **Quick hands** (press in time) | 3-5 key prompts pop up one at a time; press each before its ring closes | Longer rings | Shorter rings, one more prompt |
| **Steady hand** (hold) | Keep a drifting marker inside a zone for 4 seconds by holding and releasing | Bigger zone, gentler drift | Smaller zone, gusts |

Difficulty runs 1-5:
- Base 3.
- A ★ class -1; a skill expert -1 at rank 2-3; a good quirk -1.
- A ✗ +1 each.
- Clamped to 1-5.

### Results

| Result | Meaning |
|---|---|
| **Clean** (all pins, the whole pattern, etc.) | A good outcome, chosen from the curio's good ones |
| **Close** (one slip) | The usual weighted roll, with the expert odds |
| **Botched** | A bad outcome |

Bonuses, swaps and Gold Fever work as now.

### Which curios (first region)

| Curio | Game | Experts that make it easier |
|---|---|---|
| Stagecoach Strongbox | Tumblers | ★ Gambler, ★ Marshal |
| Railroad Supply Crate | Tumblers | ★ Train Hopper, ★ Rail Driver; ✗ Mountain Mystic |
| Standing Stone | Pattern (carved runes) | ★ Mountain Mystic, ★ Storyteller |
| Lonely Grave | Pattern (the epitaph's order) | ★ Preacher, ★ Storyteller |
| Collapsed Tunnel | Quick hands (shore the beams as rocks fall) | ★ Miner, ★ Prospector, ★ Rail Driver, ★ Woodcutter |
| Abandoned Wagon | Quick hands (the snake in the bedroll) | ★ Wheelwright, ★ Train Hopper; ✗ Spooked by Critters |
| Prairie Well | Steady hand (the rope) | ★ Angler, ★ Medic, ★ Frontier Doctor |
| Miner's Cache | Steady hand (old blasting powder) | ★ Prospector, ★ Miner; ✗ Butterfingers |

The other curios keep the dice roll for now. The four games can be reused for later regions.

## Build plan

1. **High Noon** first:
   - the duel scene and the scoring logic
   - "Who draws?"
   - carrying the duelist into a later fight (map marker included)
   - Rattled
   - the Lone Wanderer, plus the four existing events above
   - tests
2. **Skill checks:** the four games as reusable scenes, the eight curios, and tests.

## Questions for the owner

1. **Rattled:** until the next camp, or the next fight only?
2. **Mad Dog:** keep the boss standoff right before the fight (the one duel that isn't
   separate)?
3. **Skill checks:** should a clean result guarantee a good outcome? That's stronger than the
   ★ odds, which never guarantee one, but it rewards skill.
