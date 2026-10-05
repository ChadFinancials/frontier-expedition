# Breaking Points and Second Winds: proposals (round 9)

> Archived (round 20): fully built. The rules as they stand are in `docs/GDD.md`; open follow-ups are in `docs/BACKLOG.md`.

Status: **✅ built with the owner's edits (round 9).** The final tables are in `GDD.md` §6.

Owner's picks:
- **Names:** keep Breaking Point. Second Wind → **True Grit**, Resolve Test → **Gut Check**,
  Death's Door → **Last Legs**, Deathblow Resist → **Cheat Death**. Ids and code names are
  unchanged.
- **Breaking Points:** all as proposed, except Yellow-Bellied goes back to **Cowardly** with
  -10% Dmg (was -20%). It keeps Vulnerable 15% in ranks 1-2.
- **Steadfast:** no Guard, since it could land on a frail hero. When it lands, the most
  wounded hero gets +15 Prot for the rest of the fight (or the next one, if it landed on the
  trail). The holder keeps a small lingering buff (+5 Prot, +5 Cheat Death, +10 Stun Res) and
  the -4 company Fatigue boon until the expedition ends.
- **Cool-Headed:** +20% Healing Received, +20 Debuff Res, 35% each turn to clear Bleed or
  Poison. No Fatigue relief.
- Quirk weighting (question 2) wasn't picked up.

The proposal as first written follows.

## How it works today

- Fatigue runs 0-200. At 100 a hero takes a **Resolve Test**. They pass with their Second Wind
  chance (25% + 2% per level above 1, plus quirks and trinkets).
- A pass gives a random **Second Wind**: Fatigue drops to 45, the hero gets stat boosts, and
  each turn there is a chance of a boon.
- A fail gives a random **Breaking Point**: stat penalties, a chance each turn to act on their
  own (bark, pass, back away, charge, use a random move), and sometimes refusing help.
- A Breaking Point clears when Fatigue drops to 25 or less, or at the Doctor (200 chips).
- At 200 Fatigue the hero collapses to Death's Door, or dies if already there.

## Terminology

| Our term | Darkest Dungeon's term | Notes |
|---|---|---|
| Fatigue | Stress | Already ours |
| Breaking Point | Affliction | Not DD's word, but generic |
| Second Wind | Virtue | Not DD's word; a plain English phrase |
| **Resolve Test** | Resolve is tested | **Lifted straight from DD** |
| **Death's Door** | Death's Door | **Lifted straight from DD** |
| **Deathblow Resist** | Deathblow Resist | **Lifted straight from DD** |
| **Mark** | Mark | Lifted, but it's also a plain word |
| Curio, Quirk, Trinket | same | Plain words, but the trio reads as DD |

Proposed renames. These change the text only; the ids stay the same, so saves keep working.

| Now | Proposed | Alternatives | In a banner |
|---|---|---|---|
| Breaking Point | **Snapped** | Frayed, Gone Sour, Lost Their Nerve | "Wade has SNAPPED: Heartsick!" |
| Second Wind | **True Grit** (shown as "Grit") | keep Second Wind, Dug In, Steeled | "Wade shows GRIT: Steadfast!" |
| Resolve Test | **Gut Check** | Reckoning, Moment of Truth | "Gut Check: 31% for Grit" |
| Second Wind Chance stat | **Grit Chance** | | |
| Death's Door | **Last Legs** | Hanging by a Thread, Boots On | "On Last Legs" |
| Deathblow Resist | **Cheat Death** | Tough to Kill | "+10% Cheat Death" |

If "Grit" becomes the umbrella name, the current **Grit** state needs a new name. This doc
calls it **Mule-Headed**.

The **Homesick** Breaking Point has the same name as the Homesick quirk. It becomes
**Heartsick** either way.

Curio, Quirk and Trinket can stay for now. They're the cheapest to change later if we want.

## Snapped (Breaking Points): 6

The sixth one already exists. Each one now ties into one newer mechanic: Vulnerable, Mark,
Taunt, or rank.

| Now | Proposed | Stats | Acts on their own | New hook |
|---|---|---|---|---|
| Homesick | **Heartsick** | -15% Dmg, -2 Spd *(same)* | pass, pass, bark, back away (30%) | none, renamed only |
| Reckless | **Reckless** | +15% Dmg, -15 Dodge, ~~-10 Prot~~ → **Vulnerable 10%** | random move ×2, charge, bark (35%) | Vulnerable: no cover |
| Short-Tempered | **Ornery** | +10% Dmg, -10 Acc *(same)* | bark ×2, **taunt**, random move (40%) | **New act: Taunt.** "Come on then!" draws enemy fire for a round |
| Cowardly | **Yellow-Bellied** | +10 Dodge, -20% Dmg, -5 Acc, **+ Vulnerable 15% in ranks 1-2** | back away ×2, pass, bark (35%) | Rank: useless up front, dangerous if pushed forward |
| Greedy | **Greedy** | +5% Crit, -5 Prot, -10 Grit Chance, **+15% Loot Found** | bark ×2, random move, pass (30%); refuses help | **Starts each fight Marked.** Jingling saddlebags catch every outlaw's eye |
| Paranoid | **Paranoid** | +10 Dodge, -10 Acc, -25% Healing Received *(same)*, **+4 Spd in round 1** | bark, back away, pass, random move (30%); refuses help, including Guards | **Jumpy:** first to flinch when a fight starts. Already refuses Guards, since a Guard counts as help |

## Grit (Second Winds): 5 → 6

| Now | Proposed | Stats | Each turn | New hook |
|---|---|---|---|---|
| Steadfast | **Steadfast** | +15 Prot, +10 Cheat Death, +20 Stun Res *(same)* | 35%: -4 Fatigue to the company. **New, 30%: Guards the most wounded ally for a round** | Guard |
| Inspired | **Inspired** | +2 Spd, +5 Acc *(same)* | 45%: -6 Fatigue to the company | none, the morale one |
| Sharp-Eyed | **Dead-Eye** | +12 Acc, +10% Crit, **+10% Dmg vs Marked** | ~~30%: +8 Acc to an ally~~ → **30%: Marks an enemy** ("Third one from the left") | Mark |
| Grit | **Mule-Headed** | +25 Bleed/Poison Res, +20 Stun Res, +10% HP, **+15 Cheat Death on Last Legs** | 40%: heals 12% HP | Death's Door / Last Legs |
| Fired Up | **Fired Up** | +20% Dmg, +1 Spd, **+10% Crit vs Vulnerable** | 35%: +12% Dmg to an ally | Vulnerable |
| *(new)* | **Cool-Headed** | +20% Healing Given, +15 Debuff Res, +10 Stun Res | 35%: clears Bleed or Poison from an ally and sheds 5 of that ally's Fatigue | Support: the only state that helps one ally recover |

The current five are all fighters. Cool-Headed gives the healer and support classes one that
suits them. The pick is still random, though; it doesn't depend on class.

## Engine work (small)

- Renames: change the display strings in the data and about 10 UI and log lines. Ids stay.
- New act `taunt`. It uses the existing Taunt status from the guard code.
- New boons: `guard_ally`, `mark_enemy`, `cleanse_ally`. These go in `_apply_boon`, which
  already handles three boon types.
- New field `fight_start` on a state, e.g. `[{"type": "mark_self"}]` for Greedy.
- The conditional mods (`front`, `round1`, `deaths_door`, `vs_marked`, `vs_vulnerable`) are
  all wired already.
- Tests: each new act and boon fires, and Greedy starts Marked.

## Questions for the owner

1. Which names: Snapped / Grit / Gut Check / Last Legs / Cheat Death, an alternative, or keep some?
2. Should the pick depend on anything besides chance? For example, quirks could weight it:
   Hothead → Ornery more often, Gold Fever → Greedy.
3. Cool-Headed as the sixth Grit, or a different idea?
