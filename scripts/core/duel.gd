class_name Duel
extends RefCounted
## High Noon: a two-part duel, scored here (no screen; the HighNoon scene plays it).
##
## 1. The Draw: after a random wait (and maybe a false cue or two) "DRAW!" shows. The
##    hero's reaction time, minus their edge, races the opponent's draw time. Clicking
##    before DRAW is jumping the gun. Slower: they fire first (the hero takes a hit) and the
##    aim zones shrink.
## 2. The Aim: a sight swings across a bar; one click. Zones from the centre out: bullseye,
##    hit, graze, miss.
##
## Results: "bullseye", "hit", "graze", "miss", or "jumped" (no shot at all); plus "slow".
## Tuning lives in config ("duel").

const TIERS := ["bullseye", "hit", "graze", "miss"]


static func cfg() -> Dictionary:
	return DB.cfg("duel", {})


## Seconds taken off the hero's reaction time: class, the Gunslinger's Quick Draw level,
## and Speed above 4.
static func edge(h: Hero) -> float:
	var c := cfg()
	var e := float(c.get("class_edge", {}).get(h.class_id, 0.0))
	if h.class_id == "gunslinger":
		e += float(c.get("quick_draw_per_level", 0.02)) * (h.skill_level("gs_quick_draw") - 1)
	e += minf(float(c.get("speed_edge_cap", 0.05)), float(c.get("speed_edge", 0.01)) * maxf(0.0, h.stat("speed") - 4.0))
	# Trinkets that quicken the draw (the Wanderer's Silver Dollar).
	for k in h.keepsakes:
		e += float(DB.keepsakes.get(k, {}).get("duel_edge", 0.0))
	return e


## How much wider (or narrower) the hero's aim zones are: class and quirks multiply, and
## each point of Accuracy adds 1% (capped at +/-10%).
static func zone_mult(h: Hero) -> float:
	var c := cfg()
	var m := float(c.get("class_zone", {}).get(h.class_id, 1.0))
	var qz: Dictionary = c.get("quirk_zone", {})
	for q in h.quirks:
		m *= float(qz.get(q, 1.0))
	m *= 1.0 + clampf(h.stat("acc") / 100.0, -0.1, 0.1)
	return m


## Zone widths as fractions of the bar (each band includes the ones inside it).
static func zones(h: Hero, slow: bool) -> Dictionary:
	var c := cfg()
	var w: Dictionary = c.get("zones", {"bullseye": 0.04, "hit": 0.14, "graze": 0.30})
	var m := zone_mult(h) * (float(c.get("slow_zone_mult", 0.67)) if slow else 1.0)
	return {"bullseye": minf(float(c.get("bullseye_cap", 0.08)), float(w.bullseye) * m),
		"hit": minf(0.5, float(w.hit) * m), "graze": minf(0.9, float(w.graze) * m)}


## The tier for a shot at pos (0..1 along the bar, 0.5 is dead centre).
static func aim_tier(pos: float, z: Dictionary) -> String:
	var d := absf(pos - 0.5) * 2.0   # 0 at the centre, 1 at either edge; compare to band widths
	if d <= float(z.bullseye):
		return "bullseye"
	if d <= float(z.hit):
		return "hit"
	if d <= float(z.graze):
		return "graze"
	return "miss"


## How fast the sight swings (full sweeps per second): faster against tougher foes; a
## Drinker's hand is unsteady.
static func sight_speed(h: Hero, tier: int) -> float:
	var c := cfg()
	var s := float(c.get("sight_speed", 0.85)) + float(c.get("sight_speed_per_tier", 0.15)) * (tier - 1)
	if "drinker" in h.quirks:
		s *= float(c.get("drinker_sight", 1.2))
	return s


## False cues (a crow caws, a tumbleweed rolls) before the real DRAW. Jumpy heroes get one more.
static func false_cues(h: Hero, rng: RandomNumberGenerator) -> int:
	return rng.randi_range(0, 1) + (1 if "jumpy" in h.quirks else 0)


## Hard of Hearing: no sound on the DRAW, only the sign.
static func deaf(h: Hero) -> bool:
	return "hard_of_hearing" in h.quirks


## Did the hero beat the draw? reaction in seconds after DRAW showed.
static func beat_draw(h: Hero, reaction: float, opp_draw: float) -> bool:
	return reaction - edge(h) <= opp_draw


## A duel resolved without a screen (tests, the balance bot): a typical player's reaction and
## a random aim. Returns {"tier", "slow"}.
static func roll(h: Hero, opp_draw: float, rng: RandomNumberGenerator) -> Dictionary:
	if rng.randf() < 0.08:
		return {"tier": "jumped", "slow": false}
	var slow := not beat_draw(h, rng.randf_range(0.28, 0.65), opp_draw)
	return {"tier": aim_tier(rng.randf(), zones(h, slow)), "slow": slow}


## The "Who draws?" picker's marks for a hero ("★ Gunslinger   ✗ Jumpy").
static func hint(h: Hero) -> String:
	var c := cfg()
	var parts := []
	if c.get("class_edge", {}).has(h.class_id) or c.get("class_zone", {}).has(h.class_id):
		parts.append("★ " + h.class_name_text())
	for q in h.quirks:
		if q in c.get("good_quirks", []):
			parts.append("★ " + DB.quirks[q].name)
		elif q in c.get("bad_quirks", []):
			parts.append("✗ " + DB.quirks[q].name)
	return "   ".join(parts)
