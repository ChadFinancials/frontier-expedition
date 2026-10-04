# Townsfolk: the people who run the town

Status: **✅ built** with the owner's round 2 picks (below). The rules as built are in
`GDD.md` ("Townsfolk"); the data fields are in `ADDING_CONTENT.md` ("Townsfolk"). Tuning
lives in `data/townsfolk.json`.

## The owner's picks

Round 1 (after the wagon and town brainstorm):
- A **townsfolk roster like the heroes'**, built before the wagon work.
- Heroes and townsfolk are **always two separate pools**. Heroes never retire into townsfolk,
  and townsfolk never join the company.
- Keep **upkeep** (weekly wages) and **growth** (population grows the town).

Round 2 (answers to the proposal's questions):
- **Traits are their own pool.** No townsfolk trait shares anything with hero quirks.
- **Empty buildings work as today.** Staff only add to them.
- **Grow into it slowly.** You shouldn't be flooded with townsfolk in week 1:
  - They come **only from expeditions and quests**.
  - No settlers turn up in town on their own, and the Hiring Board stays heroes only.
  - Nobody is given away at the start, so a new game and the owner's save both start with
    no townsfolk.
- **Seats: 0 at building level 1, 1 at level 2, 2 at level 3**, so staff come a bit later
  than the first upgrades.
- **Wages** of 10 / 20 / 30 chips a week are right.
- **Producers: yes.** Woodcutters, miners and trappers work new buildings that bring in
  Timber, Iron and Hides each week.
- **Moving between towns comes later**, for townsfolk and heroes alike, once there are
  several towns to move between.

## What was built

- **The roster:**
  - Each townsperson has a name ("Hattie Coombs", "Old Abner"), a trade, a level (Greenhorn,
    Hand, Master) and one trait.
  - Click **Townsfolk** in town to see who lives there, what they're learning and what they
    cost.
  - From there you can put someone to work, take them off a job, or send them away.
- **11 trades:**
  - one for each staffed building: Barkeep, Parson, Sawbones, Blacksmith, Drillmaster,
    Storekeeper, Undertaker
  - three producers: Logger, Mucker, Trapper
  - the Laborer, who can work in any building
- **12 traits:**
  - ★ Hard Worker, Thrifty, Apt Pupil, Handy, Well Liked, Loyal
  - ✗ Lazybones, Grasping, Set in Their Ways, Tippler, Grumbler, Restless
- **Three new buildings:**
  - **Lumber Yard:** 2 / 3 / 4 Timber a week by level, plus its staff.
  - **Iron Mine:** 1 / 2 / 3 Iron a week.
  - **Trapping Post:** 1 / 2 / 3 Hides a week.
  - They compete for building plots with everything else.
- **Staff seats** show on each building's panel. The right trade is marked ★, and the panel
  shows what each person adds.
- **Where townsfolk come from:**
  - Eight trail events (see `GDD.md`).
  - About a fifth of Saloon quests offer "a settler for your town" (`chances.settler`).
  - They ride home with the company and settle when it gets back.
- **Growth:**
  - A Town houses 8 people and a City 12.
  - Growing to a City needs 8 townsfolk living there.
  - Fort Providence starts as a Town, so its buildings top out at level 2 and one seat each
    until it becomes a City.

## Later

- **Moving between settlements** by the Stage Line, for heroes and townsfolk alike.
- **More sources:** cave rescues, region bosses' prisoners, and Lone Wanderer story beats.
- **Look:** portraits in the image pass. The town street could show more figures and lit
  windows as the population grows.
