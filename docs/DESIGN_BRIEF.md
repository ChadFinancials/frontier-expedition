# Frontier Expedition — Design Brief

Living summary of the creative direction agreed before the build. Heavily inspired by
Darkest Dungeon 1 & 2 mechanics, but **not a copy**: the theme is an Oregon Trail–style
push west into a frontier that grows stranger the farther you go.

## Engine & platform
- Godot 4, GDScript. Windows desktop target, mouse-driven, 1920x1080 base resolution.
- All content is **data-driven** (classes, combat moves, survival skills, enemies, curios,
  events, quirks, buildings) so new entries can be added without touching engine code.

## Core loop
- **Settlement chain (persistent meta layer).** A line of settlements stretching west.
  - Tiers: **Outpost → Town → City**. Upgrading is expensive and slow; you can't found a
    big town every run.
  - The easternmost (oldest) settlements are the most developed; new outposts are
    founded occasionally as you push the frontier west, not after every win.
  - Heroes can be **sent back east** to better-developed settlements to heal, recover,
    and train. Distance costs time: they're out of the roster for a while.
- **Runs (roguelite layer).** Pick four heroes and supplies, then travel west along a main
  trail with branching side spots: caves, abandoned towns, homesteads, trading posts,
  river crossings. Not strictly linear.

## Heroes
- **Permadeath**, with Darkest Dungeon–style **Death's Door**: at 0 HP a hero doesn't die
  outright; each further hit makes a death check they may survive.
- **Classes** set the combat move pool and preferred ranks. Loosely inspired by DD
  classes, each with its own frontier flavor. Target: **10 classes** for v1.
- **Survival skills** give heroes of the same class different identities: one Gunslinger
  is a cook, another a forager or scout. They replace DD's camping skills and are used on
  the trail and at camp. They have their own move pool and rank up.
- Positive/negative traits (DD's quirks, reflavored).

## Stress equivalent (name TBD, e.g. "Strain")
- Works like DD stress: it builds up from hardship, and at the threshold a hero either
  **breaks** (a bad state that sometimes acts on its own) or gets a **second wind**
  (a heroic state). The tone is lighter than DD.

## Combat
- Four party positions vs four enemy positions; moves are limited by the user's rank and
  the target's rank (front-line vs back-line, shuffling, knockback/pull).
- **Explicit hit chance**: DD1-style accuracy/dodge/crit, always showing "X% to hit".
- Status effects: bleed, poison, stun, mark, guard, buffs/debuffs.
- Presentation: heroes on the left, enemies on the right; on an action, the attacker and
  target zoom and lunge in, with a simple attack pose and a hit flash.

## Survival layer (Oregon Trail)
- Resources used up while traveling (food, medicine, wagon parts, ammo, …).
- Trail events: river crossings, broken axles, sickness, hunting, weather.

## Exploration
- **Curios** ("finds"): interactable objects with random outcomes; using the right
  supply item on them improves the result.

## Enemies & setting
- Main theme is the frontier: outlaws, wildlife, claim jumpers, a crooked railroad
  company, the land itself.
- A **mythic layer** in the spirit of the Iliad/Odyssey: giants and other legendary
  creatures, more common the farther west you go. Original creatures, not borrowed
  sacred figures; Native peoples are not portrayed as enemies.

## Art
- Stylized paper-cutout / woodcut-silhouette figures, layered parallax frontier
  backgrounds, drawn in code so real art can replace it later. Simple, but it should
  look good.
