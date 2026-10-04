# Townsfolk: the people who run the town (proposal)

Status: **proposal, awaiting the owner's picks.** Nothing is built yet.

Owner's direction (after the wagon and town brainstorm):
- A **townsfolk roster like the heroes'**, built first (before the wagon work).
- Heroes and townsfolk are **always two separate pools.** Heroes never retire into townsfolk,
  and townsfolk never pick up a gun and join the company.
- Keep the **upkeep** (weekly wages) and **growth** (population grows the town) ideas.

The goal: the town stops being a menu of buildings and becomes a place with people in it.
You find them, pay them, and put them to work, and the right person in the right building
makes that building better.

## 1. A townsperson

| Field | Values | Notes |
|---|---|---|
| Name | "Hattie Coombs", "Old Abner" | Drawn from a separate name list, so they don't read like heroes |
| Trade | one of 10 (below) | What they're good at |
| Level | 1 Greenhorn, 2 Hand, 3 Master | Grows with weeks on the job |
| Trait | one, good or bad (below) | Shown as ★ or ✗, the same marks as curios and events |
| Wage | chips per week | Set by level, changed by some traits |
| Home | a settlement | Where they live and can work |
| Post | a building, or idle | Their seat this week |

Townsfolk never leave town, never fight and never die on the trail. They can leave if they
go unpaid (see Upkeep).

## 2. Trades and the buildings they staff

Each building gets **one staff seat**. A building runs exactly as it does today with nobody
in the seat. Staff only add to it, so the owner's save keeps working with no one hired.

| Trade | Building | Greenhorn (1) | Hand (2) | Master (3) |
|---|---|---|---|---|
| **Barkeep** | Saloon | +5 relief on Saloon activities | +10 relief | +15 relief, and +1 side quest on the board each week |
| **Parson** | Chapel | +5 relief | +10 relief | +15 relief; Quiet Prayer also clears Shaken |
| **Sawbones** | Doctor's Office | Treatments -10% | -20% | -30%, and +1 treatment slot |
| **Blacksmith** | Smithy | Gear upgrades -10% chips | -15% chips | -20% chips and -1 Iron per upgrade |
| **Drillmaster** | Drill Hall | Move training -10% | -15% | -20%, and moves can train one level past the hall's cap |
| **Storekeeper** | General Store | Extra 5% off | Extra 10% off | Extra 15% off, and +1 keepsake on the shelf |
| **Clerk** | Hiring Board | +1 recruit on the board | +1 recruit, rerolls a recruit's worst quirk | +2 recruits, one arrives at level 2 |
| **Stage Driver** | Stage Line | +1 seat | +1 seat, and settlers arrive one more each week | +2 seats; travel takes 1 week less (minimum 1) |
| **Undertaker** | Boot Hill | +5 relief | +10 relief | +15 relief; Pay Respects can recover one trinket of the fallen |
| **Laborer** | any building | Half the Greenhorn bonus there | Full Greenhorn bonus | Full Greenhorn bonus; building and repairs anywhere in that settlement -10% Timber |

- **Wrong trade:** anyone can sit in any seat as a pair of hands for **half the Greenhorn
  bonus**. That beats an empty seat but makes the right trade matter.
- Numbers are first drafts. They sit in a new `data/townsfolk.json` so they can be tuned
  without touching code.

## 3. Traits (one each)

| ★ Good | Effect | ✗ Bad | Effect |
|---|---|---|---|
| **Hard Worker** | Counts as one level higher (Master stays Master) | **Lazy** | Counts as one level lower (Greenhorn gives nothing) |
| **Thrifty** | Half wage | **Greedy** | Wage +50% |
| **Quick Study** | Levels up twice as fast | **Set in Their Ways** | Never reaches Master |
| **Jack of All Trades** | No wrong-trade penalty | **Drinker** | Misses one week in five (the seat counts as empty) |
| **Well Liked** | Other staff in the same settlement level 25% faster | **Sticky Fingers** | Pockets 5% of the building's chip discount (shown in the week report) |
| **Loyal** | Never leaves over unpaid wages | **Restless** | 10% a week to move on if idle for 2+ weeks |

## 4. Levels

- Weeks on the job (in any seat, not idle) count toward the next level:
  **4 weeks** to Hand, **8 more** to Master.
- A level-up shows in the week report ("Hattie pours a cleaner whiskey: she's a Hand now").

## 5. Where townsfolk come from

| Source | How it works |
|---|---|
| **Settlers** (main source) | Each week the **Stage Line** brings 1-3 settlers to that settlement (outpost 1, town 2, city 3). They show on a "New in Town" board next to the hiring board's recruits, with trade, level and trait visible. Taking one in costs a **sign-on fee** (50 chips for a Greenhorn, 120 for a Hand). Settlers you don't take in leave at week's end |
| **Trail rescues** | Event outcomes that today give nothing lasting can send someone to town instead. The homesteader cut down at the Hanging Tree, a stranded family at the Broken Axle, a fever-camp survivor. They arrive free, sometimes as a Hand or with a good trait |
| **Quest rewards** | A few Saloon quests can pay with a person ("The rancher's widow wants a fresh start in your town"), as an alternative to the chips |
| **Starting folk** | A new game starts with a Laborer and a Barkeep. The owner's existing save gets the same pair once, with a "Settlers arrive" message |

Never a source: retired, injured or dead heroes. The pools stay separate.

## 6. Upkeep: wages

| Level | Wage per week |
|---|---|
| Greenhorn | 10 chips |
| Hand | 20 chips |
| Master | 30 chips |

- Wages are paid in the week report, before the Casino's grubstake check, so wages can't drop
  the company below the grubstake floor by themselves.
- Idle townsfolk still draw a wage. That's the pressure not to hoard people.
- **Can't pay:** whoever isn't paid works that week but gains no level progress. After
  **2 unpaid weeks in a row** they leave (Loyal folk stay).
- For scale: a quest pays 160-300 chips, and a full staff of 9 Hands costs 180 a week.

## 7. Growth: population

- **Population** = the townsfolk living in a settlement.
- **Housing:** outpost 4, town 8, city 12. A full settlement can't take in more settlers.
- **Tier upgrades need people:** Town needs **population 4** and City needs **population 8**,
  on top of today's cost.
  - The owner's existing towns keep their tier. The gate applies only to new upgrades.
- Optional, later: the town street shows a few more figures and lit windows as it grows.

## 8. Screens

- **Townsfolk roster:** a "Townsfolk" button in the town top bar opens it. It works like the
  hero roster:
  - one card each: a drawn silhouette, name, trade, level pips, trait (★/✗), wage, post
  - placeholders until the image pass
- **Staff seat:** each building's panel gets a seat at the top. Click it to pick from that
  settlement's townsfolk (the same picker as heroes); the right trade is marked ★. The
  current bonus is shown on the seat ("Hattie, Hand: +10 relief").
- **New in Town board:** this week's settlers, with a sign-on button each.
- **Week report** lines: wages paid, level-ups, settlers arrived or departed, unpaid warnings.

## 9. Save compatibility

- New Company field `townsfolk: []`, and a per-settlement `staff: {}`, both defaulting empty.
  An old save loads with nobody hired, and every building works exactly as before.
- On the first load of an old save, the starting pair arrives once (flagged in
  `story_flags`, so it never repeats).
- Existing tiers stay as they are; the population gate is checked only on new upgrades.
- Saloon quest regions are stored whole, so a quest that pays with a person needs a fallback
  of the normal chips when the field is missing.

## 10. Build plan

1. Data (`data/townsfolk.json`): trades, traits, names, wages, housing and level weeks.
2. Core (`Townsperson` class plus Company):
   - the roster, seats, bonus lookups wired into the existing building code
   - wages, levels and departures in `advance_week`
   - settlers through the Stage Line
   - the population gate on tier upgrades
   - tests
3. UI: the roster screen, staff seats on building panels, the New in Town board, and the
   week report lines. Then a screenshot and a brief bug test.
4. Content: three or four trail rescues and a couple of person-paying quests.

## Questions for the owner

1. **Empty buildings:** keep them working as today, with staff only adding bonuses
   (recommended, and it keeps the save safe)? Or make an unstaffed building run at reduced
   effect, so staffing matters more?
2. **Seats:** one staff seat per building, or a second seat at building level 3?
3. **Settlers:** arrive through the Stage Line (needs one built), or show up on their own
   every week?
4. **Wages and the population gate:** do 10/20/30 chips a week and populations of 4 and 8
   feel right as a start?
5. **Producers:** later, should some trades (Woodcutter, Miner, Trapper) work the land
   around town for a trickle of Timber, Iron and Hides each week? That would give upkeep a
   payoff beyond discounts. It needs new buildings, such as a lumber yard and a mine.
6. **Moving folk:** can a townsperson move to another settlement by the Stage Line (one week
   away, like heroes), or do they stay where they settled?
