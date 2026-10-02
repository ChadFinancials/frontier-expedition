# Curio proposals (round 9) — ✅ first region shipped

**Shipped:** the expert system and the 16 curios of the Fort Providence area (Old Mill Road,
Tallgrass Sea, Dry Gulch Mine, Crow's Nest), as proposed below. Shared curios carry their
experts into later regions. The ★/✗ lines show in the hero picker (owner: a better chance,
never a sure thing). New: four 15% quirk chances (two good, two bad):

| Curio | Outcome | Quirk |
|---|---|---|
| Abandoned Wagon | snake in the flour barrel | Spooked by Critters (bad) |
| Collapsed Tunnel | rocks fall | Claustrophobic (bad) |
| Scarecrow | just straw and coins | Unbeliever (good) |
| Chokecherry Thicket | wrong berries | Iron Stomach (good) |

**Waiting for their regions:** Painted Canyon Wall (Red Canyons); Stone Cairn, Giant's Bones,
Frozen Pack, Hot Spring (Thunder Peaks). The optional base tweaks are not applied.

21 curios today. When you investigate one, you pick the hero ("Who investigates?"), but today
the pick changes nothing except for the three compulsion quirks. This pass makes the pick the
decision: the right class or survival skill shifts the odds toward the good outcomes, adds a
bonus, or even works as the key. The wrong one makes things worse.

## How it would work

- Each hand outcome is marked good or bad (events already use `"good": true`).
- A curio lists its **experts**: class ids or survival skill ids.
  - **Odds**: bad outcomes become less likely. A class expert cuts their weight by 50%. A
    survival skill cuts it by 20% at rank 1, 35% at rank 2 and 50% at rank 3.
    A hero who is both adds the two together, capped at 75%, so a curio is never fully safe by hand.
  - **Bonus**: extra effects on any good outcome (e.g. +1 Iron).
  - **As key**: the expert gets a key's result without using the supply (4 signature pairs only).
  - **Swap**: one bad outcome becomes a different one for that expert (e.g. the Marshal turns
    an ambush into a bounty).
  - **Averse** (negative odds): bad outcomes 50% *more* likely for a class that hates the thing.
- **Quick draw**: the Gunslinger class and the Tracker skill turn every curio ambush into a fight
  where the company strikes first (surprise).
- The hero picker shows it: a green "★ Prospector: knows ore" or a red "✗ Preacher: won't
  drink", and the result names the source ("Prospector's know-how: +1 Iron").

Example: a Strongbox by hand is 43% good. With a Gambler it's 60% (the two bad outcomes drop
from 57% to 40%). A Preacher at a Whiskey Barrel goes from 40% bad to 50% bad.

## The 21 curios: now and proposed

Odds are by hand. Fatigue is shown as Fat. HP damage and healing are % of max HP.

### Everywhere

**Abandoned Wagon** (treasure) — every region
- Now: food +4 (40%) · 2 Timber, 1 Iron (30%) · snake: -10% HP, +8 Fat (20%) · rag doll: +10 Fat (10%).
  Shovel: 120-220 chips + trinket.
- **Wheelwright** (skill): odds; bonus +1 Timber, wagon +10.
- **Woodcutter** (skill): odds; bonus +2 Timber.
- **Train Hopper**: odds; bonus +2 Food (a drifter knows where folks hide the good stuff).

**Whiskey Barrel** (whiskey) — every region but Dry Gulch
- Now: long pull: -12 Fat (40%) · rotgut: -8% HP, +6 Fat (30%) · 2 whiskey (20%) · keeps drinking:
  Drinker quirk, -20 Fat (10%). Shovel: 80-160 chips + 3 whiskey.
- **Gambler**: odds; can't get Drinker here ("holds their liquor").
- **Cook** (skill): bonus +1 whiskey.
- ✗ **Preacher**: averse (temperance; no head for it).

**Stagecoach Strongbox** (treasure) — every region, and their caves
- Now: 60-140 chips (43%) · bloody knuckles: -6% HP, +5 Fat (43%) · booby trap: -15% HP (14%).
  Shovel: 200-360 chips + 35% trinket.
- **Gambler**: odds; bonus +40-80 chips (card-sharp fingers pick the lock).
- **Marshal**: odds; bonus +60 chips (the Wells Fargo reward for a returned box).

**Dead Horse** (treasure) — every region but the tutorial
- Now: jerky and coins: +2 food, 30-80 chips (44%) · the smell: +8 Fat, 20-40 chips (22%) · saddle
  leather: +1 Hide (22%) · rider's friends: ambush (11%). Shovel: 70% trinket, party -5 Fat.
- **Wrangler**: odds; bonus +1 Hide (knows good tack).
- **Hunter**, **Trapper** (skills): bonus +1 Hide.
- **Marshal**: swap the ambush for "recognizes the poster": 80-140 chips bounty.

### Plains and graves

**Lonely Grave** (treasure, strange) — Crow's Nest, Tallgrass, Red Canyons, Thunder Peaks
- Now: a few words: party -6 Fat (38%) · digs by hand: +12 Fat (38%) · watch and coins: 60-120
  chips, 30% Superstitious (25%). Shovel: 140-240 chips + 50% trinket. Salt: party -12 Fat, 30%
  good quirk.
- **Preacher**: works as **Salt**.
- **Storyteller** (skill): odds; bonus party -6 Fat.

**Prairie Well** — Tallgrass
- Now: sweet water: party heal 8% (43%) · alkali: -8% HP, +6 Fat (29%) · nearly falls: +10 Fat
  (29%). Rope: 120-200 chips, party heal 8%.
- **Frontier Doctor**: odds (tests the water first).
- **Angler** (skill): works as **Rope** (fishes the tin box out on a line).
- **Medic** (skill): bonus party heal +8%.

**Scarecrow** (strange) — Crow's Nest, Tallgrass
- Now: 30-70 chips (43%) · it turns its head: +15 Fat (43%) · haint ambush (14%). Salt: 60% trinket,
  party -8 Fat.
- **Preacher**: odds; bonus party -5 Fat.
- **Bayou Poisoner**: odds (knows a haint when she sees one).
- Quick draw applies.

**Chokecherry Thicket** — Old Mill Road, Crow's Nest, Tallgrass
- Now: +3 food (62%) · snake bite: -10% HP (25%) · wrong berries: +12 Fat (12%). Antivenom: +6 food.
- **Forager** (skill): odds; bonus +2 food, 30% bandages.
- **Bayou Poisoner**: odds; bonus +1 antivenom (brews it from the leaves).
- **Cook** (skill): bonus +2 food.

**Bleached Cattle Skull** (strange) — Dry Gulch, Tallgrass, Red Canyons
- Now: trail marker: reveal 1, party -4 Fat (43%) · watched: party +6 Fat (43%) · outlaw ambush
  (14%). Salt: party -10 Fat, +5 Acc next fight.
- **Wrangler**: odds; bonus reveal +1 (reads the brand).
- **Scout** (skill): odds; bonus reveal +1.
- Quick draw applies.

**Railroad Supply Crate** (treasure) — Crow's Nest, Tallgrass, Red Canyons
- Now: +3 Iron (43%) · alarm: Company ambush (29%) · payroll ledger: +6 Fat, 40-80 chips (29%).
  Shovel: 240-400 chips + 2 Iron.
- **Train Hopper**: works as **Shovel** (knows the yard locks; opens it quietly).
- **Rail Driver**: odds; bonus +1 Iron (still has a key from the old job).
- ✗ **Mountain Mystic**: averse (hates the railroad and it shows).
- Quick draw applies.

### Strange stones

**Standing Stone** (strange) — Dry Gulch, Tallgrass, Red Canyons, Thunder Peaks
- Now: old strength: +15% Dmg next fight, heal 10% (43%) · humming: +14 Fat (43%) · changed:
  random quirk (14%). Salt: party +12% Dmg next fight, 40% good quirk.
- **Mountain Mystic**: odds; the quirk outcome is always a good quirk; bonus party +5% Dmg.
- **Storyteller** (skill): odds (knows the old stories).

**Painted Canyon Wall** (strange) — Red Canyons
- Now: learns how they fall: party +10% Dmg next fight (50%) · dread: party +10 Fat (50%). Salt:
  party -10 Fat, reveal 2.
- **Mountain Mystic**: odds; bonus reveal +1.
- **Scout** (skill): odds; bonus reveal +1.
- **Storyteller** (skill): odds; bonus party -5 Fat.

**Stone Cairn** (strange) — Thunder Peaks
- Now: adds a stone: party -8 Fat (57%) · takes a stone: 50% Superstitious (29%) · trapper's map:
  reveal 3 (14%).
- **Scout** (skill): odds; bonus reveal +1.
- ✗ **Gambler**: averse (can't resist taking one).

**Giant's Bones** (strange, treasure) — Thunder Peaks
- Now: weapons in the ribs: +3 Iron, 60-120 chips (50%) · feels small: +14 Fat (50%). Salt:
  trinket, party -6 Fat.
- **Rail Driver**: odds; bonus +1 Iron (pries the old blades loose).
- **Preacher**: odds; bonus party -6 Fat.

### Caves and mines

**Miner's Cache** (treasure) — Dry Gulch, Red Canyons; every cave
- Now: lamp oil, +2 food (50%) · +2 Iron (38%) · old blasting powder: -18% HP (12%). Shovel:
  160-280 chips + 2 Iron.
- **Prospector**: odds 75% (knows old powder); bonus +1 Iron.
- **Miner** (skill): odds; bonus +1 Iron.

**Ore Vein** (treasure) — Dry Gulch, Red Canyons, Thunder Peaks caves
- Now: +2 Iron (67%) · splinter: -8% HP, +1 Iron (33%). Shovel: 5 Iron + 80-180 chips.
- **Prospector**: works as **Shovel**.
- **Miner** (skill): odds; bonus +1 Iron.

**Collapsed Tunnel** (treasure) — Dry Gulch, Tallgrass, Red Canyons, Thunder Peaks caves
- Now: lunch pail: 40-100 chips (43%) · rocks fall: -12% HP (43%) · nothing: party +8 Fat (14%).
  Shovel: 3 Iron + 80-160 chips.
- **Rail Driver**: odds; bonus +1 Iron (moves rock for a living).
- **Prospector**: odds (a small, careful charge).
- **Miner**, **Woodcutter** (skills): odds (shores it with timber).

**Pile of Bones** (strange, treasure) — caves in every region but the tutorial
- Now: prospector's pouch: 60-120 chips (43%) · the stench: +10 Fat (43%) · the owner comes home:
  ambush (14%). Shovel: 80-160 chips + 40% trinket.
- **Hunter** (skill): odds (reads the den; knows it's out).
- **Trapper** (skill): bonus +1 Hide.
- Quick draw applies.

**Glowing Pool** (strange) — Dry Gulch, Tallgrass, Red Canyons, Thunder Peaks caves
- Now: wounds close: heal 20% (50%) · burns: -12% HP (33%) · the reflection: +15 Fat, 50% random
  quirk (17%). Salt: party heal 20%. Antivenom: party heal 15%.
- **Frontier Doctor**: works as **Antivenom**.
- **Bayou Poisoner**: odds.
- **Medic** (skill): bonus heal +10%.

### Mountains

**Frozen Pack** (treasure) — Thunder Peaks and its caves
- Now: +4 food (50%) · numb fingers: -10% HP, +6 Fat (33%) · a letter home: +8 Fat, 50% good
  quirk (17%). Shovel: 4 food, whiskey, 50% trinket.
- **Mountain Mystic**: odds; bonus +2 food (twenty winters in the snow).
- **Cook** (skill): bonus +2 food.

**Hot Spring** — Thunder Peaks
- Now: soak: party heal 12%, -10 Fat (80%) · scalded: -12% HP (20%). No keys.
- **Medic** (skill): bonus party heal +6%.
- **Angler** (skill): odds (finds the cool side of the pool).

## Coverage

| Class | Expert at | Averse at |
|---|---|---|
| Marshal | Strongbox, Dead Horse (bounty) | |
| Mountain Mystic | Standing Stone, Painted Wall, Frozen Pack | Railroad Crate |
| Rail Driver | Railroad Crate, Collapsed Tunnel, Giant's Bones | |
| Gunslinger | Quick draw (every ambush curio) | |
| Wrangler | Dead Horse, Cattle Skull | |
| Gambler | Whiskey Barrel, Strongbox | Stone Cairn |
| Prospector | Ore Vein (Shovel), Miner's Cache, Collapsed Tunnel | |
| Bayou Poisoner | Chokecherry, Scarecrow, Glowing Pool | |
| Frontier Doctor | Prairie Well, Glowing Pool (Antivenom) | |
| Preacher | Lonely Grave (Salt), Scarecrow, Giant's Bones | Whiskey Barrel |
| Train Hopper | Railroad Crate (Shovel), Abandoned Wagon | |

| Survival skill | Expert at |
|---|---|
| Cook | Whiskey Barrel, Chokecherry, Frozen Pack |
| Hunter | Dead Horse, Pile of Bones |
| Forager | Chokecherry |
| Scout | Cattle Skull, Painted Wall, Stone Cairn |
| Tracker | Quick draw (every ambush curio) |
| Wheelwright | Abandoned Wagon |
| Medic | Prairie Well, Glowing Pool, Hot Spring |
| Storyteller | Lonely Grave, Standing Stone, Painted Wall |
| Trapper | Dead Horse, Pile of Bones |
| Angler | Prairie Well (Rope), Hot Spring |
| Woodcutter | Abandoned Wagon, Collapsed Tunnel |
| Miner | Miner's Cache, Ore Vein, Collapsed Tunnel |

## Small base tweaks (optional)

- Chokecherry Thicket: berries +4 food (was 3), the weakest good outcome in the game.
- Scarecrow: coins 40-90 (was 30-70); it's the only "strange" curio paying chips by hand.
- Prairie Well: "nearly falls in" weight 1 (was 2); it's 57% bad and Tallgrass-only.

## Engine hooks

- `"good": true` on curio hand outcomes (data).
- `"experts": {"<class or skill id>": {"odds": 50, "bonus": [effects], "as_key": "<item>",
  "swap": {"<outcome index>": {"text", "effects"}}, "no_quirk": "drinker"}}` on a curio; skills
  use `odds` + `per_rank`. Read in `RunState.interact_curio` before the weighted pick.
- Config `curio_quickdraw: ["gunslinger", "tracker"]`: curio `fight` effects get `surprise`.
- Hero picker: an expert/averse line per hero; the result text names the source.
