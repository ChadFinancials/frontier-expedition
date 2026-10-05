# Quirk proposals (round 9) — ✅ shipped with the owner's edits

> Archived (round 20): fully built. The rules as they stand are in `docs/GDD.md`; open follow-ups are in `docs/BACKLOG.md`.

**Shipped (owner's numbers):** Quick Feet +1 Speed; Eagle Eye +4 Acc, +2% Crit back;
Tough as Nails +10% HP; Night Owl +5/+5 in caves; Trailwise 15 Scouting; Lucky +2% Crit only;
Thick-Skinned +5 Prot; Hard to Rattle (was Trail-Hardened); Spooked by Critters -10% Dmg vs
beasts; Drinker also 40% to spend a week at the saloon after an expedition; Gold Fever pockets
money and valuables from treasure curios; Homebody +10% Fatigue; Overweight (was Clumsy);
Hothead Vulnerable 10%; Homesick (was Nearsighted) +1 Fatigue after every fight; Maternal
Instinct (was Yellow Streak) -5% Dmg, +2 Prot; new Manhunter, Opportunist +6% Crit, Final
Gambit (+50% Dmg, +8 Dodge on Death's Door), Early Riser (+4 Spd, +4 Acc), Lightning Rod
(+10/+10), Quick Study +10% XP, Glass Jaw, Fainthearted, Slow Starter (-4/-4) and Simple
(-10% XP). Price on Their Head cut. Ids are unchanged, so saved heroes keep their quirks.
The tables below are the original proposal.

## Positive (20)

| Quirk | Now | Proposed |
|---|---|---|
| Quick Hands | +2 Speed | keep |
| Eagle Eye | +6 Acc, +3% Crit in ranks 3-4 | keep |
| Tough as Nails | +12% Max HP | keep |
| Beast Hunter | +15% Dmg, +5 Acc vs beasts | keep |
| Bounty Hunter | +15% Dmg, +5 Acc vs outlaws | keep |
| Unbeliever | +15% Dmg, -15% Fatigue vs mythics | keep |
| Steady Nerves | -15% Fatigue taken | keep |
| Night Owl | +6 Acc, +6 Dodge in caves | keep |
| Trailwise | +20 Scouting, +10 Surprise | keep |
| Lucky | +3% Crit, +5 Dodge | keep |
| Hard to Kill | +8 Deathblow Resist | keep |
| Iron Stomach | +25 Poison Res, -10% food eaten | keep |
| Thick-Skinned | +25 Bleed Res | ✅ add +5 Prot (bleed resist alone is too narrow) |
| Rock Steady | +20 Stun Res, +20 Move Res | keep |
| Barroom Brawler | +12% Dmg in ranks 1-2 | keep |
| Last Stand | +20% Dmg, +5 Dodge below half HP | keep |
| Quick Healer | +20% healing received | keep |
| Good Humor | +12% Second Wind chance | keep |
| Trail-Hardened | -10% Fatigue, +3 Dodge on the trail | ✅ change: +15 Debuff Res, +10 Move Res ("hard to rattle"); today it's Steady Nerves again, since nearly every fight is on the trail |
| Keen-Eyed | +15% loot | keep |

## Negative (20)

| Quirk | Now | Proposed |
|---|---|---|
| Afraid of Snakes | -15% Dmg, +25% Fatigue vs reptiles | ✅ rename **Spooked by Critters**, vs beasts instead (only 2 enemies are reptiles; 10 are beasts) |
| Superstitious | +20% Fatigue, -5 Acc vs mythics | keep |
| Drinker | -4 Acc; grabs whiskey at curios | keep |
| Gold Fever | -5% Second Wind; grabs treasure | keep |
| Too Curious | pokes strange curios | keep |
| Homebody | +15% Fatigue on the trail | keep |
| Slowpoke | -2 Speed | keep |
| Frail | -10% Max HP | keep |
| Clumsy | -5 Acc, -3 Dodge | keep |
| Claustrophobic | +25% Fatigue, -10% Dmg in caves | keep |
| Glutton | +25% food eaten | keep |
| Sickly | -20 Poison Res, -10% healing received | keep |
| Bleeder | -20 Bleed Res | keep |
| Hothead | +5% Dmg, -10 Dodge | ✅ change: +8% Dmg, **Vulnerable 8%** (charges in without cover) |
| Jumpy | +10% Fatigue, -10 Surprise | keep |
| Nearsighted | -8 Acc in ranks 3-4 | keep |
| Yellow Streak | -12% Dmg, +10% Fatigue in ranks 1-2 | keep |
| Gloomy | -12% Second Wind chance | keep |
| Butterfingers | -3% Crit, -10% loot | keep |
| Hard of Hearing | -15 Scouting, -10 Stun Res | keep |

## New (10)

| Quirk | Kind | Effect | |
|---|---|---|---|
| **Manhunter** | + | +15% Dmg, +5 Acc vs Marked targets | 🛠 |
| **Opportunist** | + | +10% Crit vs Vulnerable targets | 🛠 |
| **Ornery** | + | On Death's Door: +20% Dmg, +10 Dodge (too mean to die) | 🛠 |
| **Early Riser** | + | First round of a fight: +4 Speed, +8 Acc | 🛠 |
| **Lightning Rod** | + | While Marked: +15 Dodge, +10 Prot (made to be shot at) | 🛠 |
| **Quick Study** | + | +15% XP | 🛠 |
| **Glass Jaw** | − | Always Vulnerable 10% | ✅ |
| **Price on Their Head** | − | Starts every fight Marked for 2 rounds | 🛠 |
| **Fainthearted** | − | On Death's Door: -15 Acc, -4 Speed, +25% Fatigue | 🛠 |
| **Slow Starter** | − | First round of a fight: -4 Speed, -10 Acc | 🛠 |

Totals after: 26 positive, 24 negative.

## Engine hooks the 🛠 rows need
- New conditions in `Stats.cond_ok`: `marked` (the hero is Marked), `vs_marked` and
  `vs_vulnerable` (the target is), `deaths_door`, `round1`. The combat engine passes those
  facts in the context it already builds for every stat check.
- A stat `xp_pct` (Quick Study), read where XP is granted.
- A quirk field `start_marked` (Price on Their Head), applied at fight setup.
