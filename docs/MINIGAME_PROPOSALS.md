# Hands-on moments: High Noon duels and skill checks (proposal)

Status: **awaiting the owner's picks.** Nothing here is built yet.

The goal is to give expeditions moments where the player's own hands decide things, built
around the West rather than Darkest Dungeon. Two features:

1. **High Noon:** a two-part duel before certain fights.
2. **Skill checks:** short hands-on tasks at some curios.

## Rules that apply to both

- **Always skippable.** Every minigame screen has a "Roll for it" button. It resolves with
  the same odds the ★/✗ experts give today, so the player never has to play one.
- A settings toggle, **Minigames: Play / Always roll**, sets the default.
- **The company changes the difficulty, not the payout.** A ★ expert (class, survival skill
  rank, quirk) makes the game easier; a ✗ makes it harder. Playing well beats the odds.
- **Controls:** the mouse or Space for timing; arrow keys or WASD for patterns.
- **Short:** 5-15 seconds each.
- **Testable:** the scoring is plain logic with no screen. The tests and the balance bot use
  "Roll for it".

## 1. High Noon

### Where it happens (first region)

| Where | Who you face | Win big (bullseye) | Lose (miss) |
|---|---|---|---|
| Outlaw Toll: "Call out the leader" (Gunslinger), and a new "Call him out" option for anyone | The leader | The others ride off: no fight, their toll purse (40-80 chips) | Fight; they strike first |
| Wanted Poster: "Go after him" | Snake-Eye Pike | Pike drops before the fight, bounty paid; his partner still fights | Fight; Pike strikes first |
| Hanging Tree: "Cut him down" | The hangman | You shoot the rope: the homesteader joins and the outlaws fight leaderless (Vulnerable) | Fight; they strike first |
| Mad Dog Mulligan (boss intro) | Mulligan | Mulligan starts at 50% HP | Fight; he strikes first |
| Crow's Nest elite (Crow Lieutenant) | The lieutenant | The lieutenant starts at 40% HP | Fight; they strike first |

### Who draws

The "Who draws?" picker shows ★/✗ names, as at curios:
- ★ Gunslinger, ★ Marshal, ★ Bounty Hunter quirk
- ✗ Butterfingers, ✗ Jumpy, ✗ Drinker (hungover)

Any hero can step up.

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
| Miss (edges) | the rest | the duel is lost (table above) |
| Graze | 30% | the target starts at 75% HP; normal turn order |
| Hit | 14% | the target starts at 40% HP, and the company strikes first |
| Bullseye (centre) | 4% | the "win big" result above |

- The sight speeds up with the opponent's tier.
- Zone widths scale with the hero:
  - Gunslinger +40%, Marshal +20%, Eagle Eye +20%
  - Butterfingers -25%
  - Hungover (Drinker after a night's drinking) makes the sight wobble
  - The hero's accuracy stat adds up to ±10%
- **Roll for it** uses about: bullseye 8%, hit 30%, graze 35%, miss 27%. ★ shifts that toward
  hits and ✗ toward misses, as the curio odds do.

### Look

A wide letterbox panel in the paper style: a cut-out street at noon, two figures and a swinging
sign. The DRAW text slams in. Sounds already exist: bell, gunshot, crows.

## 2. Skill checks at curios

"Investigate by hand" on some curios opens a 5-10 second task instead of a dice roll.
Supply keys are still the sure thing, and as-key experts still skip the task.

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
   - the five places above
   - the settings toggle
   - tests on the scoring and the roll odds
2. **Skill checks:** the four games as reusable scenes, the eight curios, and tests.

## Questions for the owner

1. **Duel places:** are the five above right? Should any outlaw fight with a Gunslinger in the
   company also offer "Call one out"? That would be optional and once per fight.
2. **Bosses:** a bullseye leaves Mad Dog at 50% HP rather than ending the fight. OK?
3. **Skill checks:** should a clean result guarantee a good outcome? That's stronger than the
   ★ odds, which never guarantee one, but it rewards skill.
4. **Default setting:** Play or Always roll?
