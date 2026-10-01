# Playtest Notes & Backlog

The owner plays from source after each batch and sends numbered notes. This file holds the
**open backlog** first, then a **history** of each round: what the owner asked for, what was
decided, and what shipped. Update both at the end of every round.

---

## Open backlog

### Bugs
- [ ] **Crashes in combat**: on the killing blow against "Mad Dog" Mulligan (round 7) and
      mid-battle while idle, deciding on a move (round 8). Not reproduced here: the headless
      quest test wins and saves, and a 5-minute idle soak (`shot=combat soak=300`) shows flat
      memory, objects and draw calls with no errors. Points to the graphics driver. Hardened:
      every polyline goes through `Figure.clean_line`; idle figures and HUDs no longer redraw
      every frame. The owner's PC runs Godot's OpenGL renderer (Compatibility) on an RTX 4070
      Ti Super, NVIDIA driver 581.57. Test: `play_vulkan.bat` launches with the Vulkan
      renderer (Forward+; falls back to OpenGL if Vulkan fails). Still wanted: the log of a
      crashed session (the timestamped `godot*.log` from before the crash, in
      `%APPDATA%\Godot\app_userdata\Frontier Expedition\logs\`); one that just stops with
      no backtrace means the driver killed the game.
- [ ] 2D MSAA (smooth edges) is set in the project but unsupported by the OpenGL renderer
      (the startup warning); it would work under Vulkan. Ties in with the jagged-edges item.
- [ ] Jagged edges on circles and cut-outs (aliasing). Later.

### Gameplay
- [ ] **Wagon as a "5th member" in battles**: some enemies attack or sabotage it; tie it to
      wear and tear. Rework **enemy ambushes** around it (switched off in round 7 with
      config `hero_ambush: false`, including night-camp ambushes).
- [ ] Find more places for the wagon and resources to matter (materials already take wagon
      space; mishaps and events drain supplies).
- [ ] Money supply may be too high (round 1 note; recheck with the current economy).
- [ ] Gunslinger bullet system: 6 rounds in the cylinder shown overhead, moves spend bullets,
      a Reload move.
- [ ] Class workshop, second half: Prospector 7th/8th move (forced guard plus strapped
      dynamite that goes off when the guarded unit is attacked?), Frontier Doctor 7th/8th,
      the Preacher's full kit, the Bayou Poisoner's 8th.
- [ ] Decide whether utility moves need their own per-level upgrade paths (today every move
      level adds the same accuracy, damage, effect and healing bonuses).
- [ ] Stacked Deck "probably needs tuning" (round 8; owner: save for a later balancing pass). A second deal stacks on the first (two
      Jacks of Clubs = +24 Dodge). Proposed: a new deal replaces that hero's previous card.
- [ ] Watch: Ruby Blackwing is hard and the crow summon strong; probably right (round 7).
- [ ] Second region onward (Red Canyons, Thunder Peaks, Redwater Ford) waits until the first
      region is crisp.

### Visuals
- [ ] **Backdrops**: about ten more images in the owner's prairie style for stops across side
      quests and expeditions (composition rule: keep the lower middle open, see
      `COMFYUI_GUIDE.md` §7). Also the idea of rebuilding favourite drawn scenes in code from
      a painted reference, keeping quirks like the hanging clouds: the Crow's Nest, Dry Gulch
      Mine and its interior, the Old Mill Road, the town.
- [ ] Icons still drawn in code: `skull`; optionally the move-type and stat icons.
- [ ] Town depth: the street is plots side by side; look at DD's Hamlet (layered, angled
      buildings, foreground and background) without overdoing it.
- [ ] A world map between settlements, later.

---

## History

### Round 8
- Owner: painted backdrops look stretched and pixelated; top-bar numbers float away from their
  icons; Stacked Deck shows all cards at once; more than two rows of buffs and debuffs vanish
  under the HUD; a crash mid-battle while idle.
- Shipped: numbers sit right beside their icons (shared `UI.res_item`, top bar and trail);
  Stacked Deck deals one card at a time; status chips are short tags ("ACC +10"), the
  fighters stand 25 px higher so three rows fit, overflow folds into "+N"; idle figures and
  HUDs stop redrawing every frame. Backdrops: not stretched (the aspect is kept), just a
  1344-wide image blown up 1.5-2x; the owner is regenerating them at 1344 x 768 plus a 2x
  model upscale (`COMFYUI_GUIDE.md` §7). New screenshot args: `statuses`, `with=`, `soak=`.

### Round 7 (continuing the owner's save from here on)
- Owner: text on the wood is hard to read; the map looks much better; ambushed in the first
  Crow's Nest fight and it was brutal; white-noise clicks and the hover sound are unpleasant;
  Fan the Hammer hits 3 times but spacing is odd and only 2 sound; stacked numbers still
  overlap; Revival Meeting shows one hero at a time; Prospector should find more in caves.
- Shipped (`e808468`): text areas on wood sit in a dark `Inset` well; **enemy ambushes off**
  (`hero_ambush`); a soft wooden click, no hover sound; multi-hit moves play a sound per hit
  with even spacing; stacked popups spaced 46 px; group moves (Revival Meeting, AoE) show all
  results at once; Prospector `cave_loot_pct` 25.
- Answered: hero levels add HP, damage, accuracy and crit and raise gear and move caps; move
  levels add accuracy, damage, effect chance and healing.
- **v0.7** (`32d857c`): version bump and a refreshed Windows download. The tag push is left to
  the owner (blocked from the cloud container).

### Art pass: icons and backdrops (after round 7)
- The owner now makes art in ComfyUI and hands it over in chat; originals kept in `art-src/`.
- Icons (`1c965ea`, `b59a18f`, `fed0e03`): 17 painted icons for every supply and resource.
  `tools/art/prep_icons.py` cuts them out. The **Crowbar is retired**; its five curios open
  with the Shovel.
- Backdrops (`e7c5c05`): the owner's **prairie** set on the tutorial and every Saloon rumor;
  shared backdrops show outdoors only; combat picks the variant by map progress.

### Round 6
- Owner: the front elbow bends the wrong way; the map click is loud and the sound overall is
  bad; a crash in the tutorial boss fight (not reproduced); the prairie wolf elite is too
  much; the Mountain Man should beat beasts; damage ticks before the animation; the window
  title says (DEBUG); scouting text should show back on the map; stacked text overlaps; caves
  are too easy and the light is moot; no way to reorder the party after a scramble; Cave-In is
  far too strong. Plan first, then ComfyUI work goes to the PC agent.
- Shipped: elbows bend as a `<`; every sound levelled to one loudness
  (`tools/level_audio.py`, `levels.json`); no (DEBUG) title; road news after fights
  (`d91df31`). HUD bars move when each hit lands; popups one at a time (`a0d8b2b`). Hero
  moves +2 accuracy (enemies unchanged); prairie wolf 10 → 8 HP; Mountain Mystic +20% damage
  and +2 accuracy vs beasts; Cave-In hits 2 random heroes; caves 3-4 enemies and light drains
  30 per room with a visible meter (`62f3a7f`). Party reorder on the map and between cave
  rooms (`f3372e9`). Wood-and-rope UI drawn in code and the map redrawn as a parchment trail
  map (`d5019ea`). Painted icon loader (`39cd08b`).

### Characters (between rounds 5 and 6)
- Ink illustration look for every character (owner's pick of five styles); profile faces at
  rest with storybook reactions in action poses; three color outfits per class. See
  `ART_PIPELINE.md`.
- Turn order: Speed plus a small 1-3 roll each round; action diamonds per unit.

### Hero review (after round 5)
- Heroes know their two stock moves plus two random ones and learn the rest at the Drill Hall
  (300 chips). Skills, weapons and armor go to level 5 (building level caps 2 / 4 / 5; gear
  tier needs that hero level; a move at most one level above the hero's).
- Every class reworked to 6-8 moves (`HERO_REVIEW.md`): Marshal; Mountain Man → **Mountain
  Mystic**; Rail Driver, Gunslinger, Wrangler, Gambler (8 moves each; Stacked Deck shows the
  dealt cards; Money Shot pays 50 chips per kill); Sharpshooter → **Bayou Poisoner**;
  Prospector, Frontier Doctor and Preacher retuned.
- Engine: fixed damage ranges per move, Armor Piercing, cure all debuffs, blood-price self
  damage, self-buffs last their full rounds, enemies go for Marked heroes half the time.

### Round 5
- Sounds: gunshots, impacts, blades and the howl back to the generated ones; recorded
  creatures, glass, chips, cards and clicks kept. No double sounds.
- Tutorial: weak tutorial-only enemies and a new boss, **Crowbar Pete**; no ambushes.
  **Mad Dog Mulligan** moved to a Saloon rumor that jumps the queue until beaten.
- Map: "ONWARD" signpost instead of a compass; difficulty ratings on expeditions; at most 2
  caves per trail; fights sometimes leave a curio (30%, elites 50%).
- Town: Hiring Board tracks (More Notices, Word of Mouth, Bunkhouse); company starts with room
  for 6; a recruit with no bunk waits on the board. Saloon bar side effect spelled out.
- Death's Door: the hit that knocks a hero onto it (and the rest of that move) can't kill;
  warnings for heroes starting a fight on it; ally death +15 Fatigue, Death's Door +6.

### Round 4
- Recorded CC0 sound packs (Kenney, OpenGameArt) via `tools/import_sfx.py`.
- Longer trips: main trails 12 stops with two camps, story side adventures 8, rumors 7.
  Slower levelling: XP at 15 / 45 / 90 / 150.
- Enemy workshop (`ENEMY_REVIEW.md`): every Fort Providence enemy and boss tuned; engine
  support for per-move damage ranges, flat damage buffs, pack buffs, multi-summons,
  opener and once moves, low-HP move priority and repositioning.
- Testing focus locked to the first region.

### Round 3
- Enemies may keep nicknames when unique; heroes are single-name. Skipping the tutorial gives
  the post-tutorial setup. The Preacher waits on the Hiring Board; the other starting hero is
  rescued in Dry Gulch Mine.
- Curio tools need the General Store; until then the wagon leaves with a free kit.
- Weekly **Saloon rumors** from `data/quests.json` (Chatter and Loose Lips tracks).
- Side adventures toughened slightly; elite materials tied to wagon space; "Resisted Stun"
  says what was resisted; the Crow's Nest pays the Blackwing Feather, not a hero.
- Art: the **paper-theater** look everywhere (combat, trail, events, curios, camp, cave,
  town, menu); a "DEV: Win" button in combat; ComfyUI explored for painted art.

### Round 2
- Targeting arrow drops top-down; new victory sting; throatier animal sounds; tooltips with
  real numbers.
- Tutorial with 2 heroes (Marshal and Gunslinger), unscouted fork, XP capped at 3.
- Silas Crane, King of the Crows (crow minions, Carrion Omen). Keepsakes renamed **trinkets**
  in the UI.
- Camp skills reworked (one action at rank 1, the second at rank 2; some use supplies).
- Town: building slots you click to assign heroes; rebuilding priced so nothing can be built
  right after the tutorial; 2 recruits a week.
- Side adventures from Fort Providence: Dry Gulch Mine and The Crow's Nest.
- Scouting toned down; curio stops hold one curio; trading posts mark up 2.2×; Trinket Peddler
  event; a 12-slot wagon inventory with stacking.

### Round 1
- Keep: the Slay the Spire-style branching map.
- Shipped in batch 1: **chips** and the Great Casino, map intel and scouting, the wagon bar,
  wear and mishaps, supply-draining events, crit relief labelled, trinkets on the trail,
  slower and clearer combat, balance tuning.
- Batch 2: burned-out Fort Providence (Hiring Board plus three ruins), the Old Mill Road
  tutorial that rebuilds the Saloon, Silas Crane's scripted first meeting (Crane's Gambit)
  and a wounded Silas afterwards, a clear SELECTED move, move-type and stat icons.
