class_name Fatigue
extends RefCounted
## Fatigue: the frontier's answer to Stress. 0-200; a Resolve Test at 100 gives a
## Second Wind or a Breaking Point; Collapse at 200.
## Every function returns a list of event dictionaries for the UI and message log.

const MAX := 200
const TEST_AT := 100


## Apply a fatigue change. Positive amounts are scaled by the hero's fatigue_pct.
static func add(hero: Hero, amount: int, rng: RandomNumberGenerator, ctx: Dictionary = {}) -> Array:
	var ev: Array = []
	if not hero.alive or amount == 0:
		return ev
	var amt := float(amount)
	if amt > 0:
		amt *= maxf(0.0, 1.0 + hero.stat("fatigue_pct", ctx) / 100.0)
	var delta := int(round(amt))
	if delta == 0:
		return ev
	var old := hero.fatigue
	hero.fatigue = clampi(old + delta, 0, MAX)
	ev.append({"t": "fatigue", "hero": hero.uid, "amount": hero.fatigue - old})

	if delta > 0 and old < TEST_AT and hero.fatigue >= TEST_AT and hero.fatigue_state == "":
		ev.append_array(resolve_test(hero, rng))

	if hero.fatigue >= MAX:
		ev.append_array(collapse(hero))

	if delta < 0 and hero.is_breaking() and hero.fatigue <= DB.cfg("breaking_clear_at", 25):
		var st := hero.fatigue_state
		hero.fatigue_state = ""
		ev.append({"t": "recovered", "hero": hero.uid, "state": st})
	return ev


static func resolve_test(hero: Hero, rng: RandomNumberGenerator) -> Array:
	var chance := hero.stat("resolve")
	var roll := rng.randf() * 100.0
	var kind := "second_wind" if roll < chance else "breaking"
	var pool: Array = []
	for id in DB.fatigue_states:
		if DB.fatigue_states[id].get("kind", "") == kind:
			pool.append(id)
	var st: String = Stats.pick(rng, pool)
	hero.fatigue_state = st
	if kind == "second_wind":
		hero.fatigue = DB.cfg("second_wind_fatigue", 45)
	return [{"t": kind, "hero": hero.uid, "state": st, "chance": chance}]


## Fatigue maxed out: drop to Death's Door, or die if already there.
static func collapse(hero: Hero) -> Array:
	var ev: Array = []
	if hero.deaths_door:
		hero.alive = false
		hero.hp = 0
		hero.death_note = "Collapsed from exhaustion"
		ev.append({"t": "collapse", "hero": hero.uid, "fatal": true})
		ev.append({"t": "death", "hero": hero.uid})
	else:
		hero.hp = 0
		hero.deaths_door = true
		hero.fatigue = DB.cfg("collapse_reset", 150)
		ev.append({"t": "collapse", "hero": hero.uid, "fatal": false})
	return ev


## Party-wide helper.
static func add_party(heroes: Array, amount: int, rng: RandomNumberGenerator, ctx: Dictionary = {}) -> Array:
	var ev: Array = []
	for h in heroes:
		if h.alive:
			ev.append_array(add(h, amount, rng, ctx))
	return ev


## Text for a fatigue-related event (shared by the combat log and trail messages).
static func describe(e: Dictionary, hero_name: String) -> String:
	match e.get("t", ""):
		"fatigue":
			var a: int = e.get("amount", 0)
			return "%s %s %d Fatigue" % [hero_name, "gains" if a > 0 else "sheds", absi(a)]
		"second_wind":
			return "%s finds a SECOND WIND: %s!" % [hero_name, DB.fatigue_states.get(e.state, {}).get("name", e.state)]
		"breaking":
			return "%s hits a BREAKING POINT: %s!" % [hero_name, DB.fatigue_states.get(e.state, {}).get("name", e.state)]
		"recovered":
			return "%s pulls themselves together." % hero_name
		"collapse":
			return "%s collapses from exhaustion%s" % [hero_name, " and does not get up." if e.get("fatal", false) else "!"]
		"death":
			return "%s has died." % hero_name
	return ""
