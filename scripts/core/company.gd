class_name Company
extends RefCounted
## The persistent campaign: money, materials, heroes, settlements and the weekly clock.
## All settlement services live here so they can be tested without the UI.

var week: int = 1
var money: int = 0
var timber: int = 0
var iron: int = 0
var charters: int = 0
var heroes: Array = []          # Hero (alive only)
var dead: Array = []            # {name, class_id, level, note, week}
var settlements: Array = []     # {index, site, tier, buildings{id:lvl}, recruits[], stock[], used{}}
var stash: Array = []           # keepsake ids not equipped
var known_keys: Dictionary = {} # curio id -> [item ids found to work]
var beaten: Array = []          # region ids whose boss has fallen
var run: RunState = null
var next_uid: int = 1
var victory_seen: bool = false
var missing: Array = []         # hero dicts of company members lost somewhere, waiting for rescue
var quest_regions: Dictionary = {} # generated side-quest regions (id -> region), registered into DB.regions
var tutorial_done: bool = true
var story_flags: Dictionary = {} # scripted story beats that have played (id -> true)
var stats: Dictionary = {"expeditions": 0, "victories": 0, "deaths": 0, "kills": 0}
var rng := RandomNumberGenerator.new()


# --- New game -------------------------------------------------------------------------

func new_game(seed_value: int = -1) -> void:
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	money = DB.cfg("start_money", 750)
	timber = DB.cfg("start_timber", 10)
	iron = DB.cfg("start_iron", 5)
	var start_site := site_by_index(0)
	var st := {"index": 0, "site": start_site.id, "tier": start_site.get("start_tier", "outpost"),
		"buildings": start_site.get("start_buildings", {}).duplicate(), "ruins": start_site.get("start_ruins", []).duplicate(),
		"recruits": [], "stock": [], "used": {}}
	tutorial_done = start_site.get("tutorial", "") == ""
	settlements.append(st)
	for cid in DB.cfg("start_heroes", []):
		var h := make_hero(cid, 1)
		heroes.append(h)
	# One of the two who rode ahead waits at the hiring board; the other went missing.
	st["promised"] = []
	for cid in DB.cfg("start_promised", []):
		var ph := make_hero(cid, 1)
		ph.location = 0
		st.promised.append(ph.to_dict())
	for cid in DB.cfg("start_missing", []):
		var mh := make_hero(cid, 1)
		mh.location = 0
		missing.append(mh.to_dict())
	_refresh_week()


## How many heroes the company can keep: each settlement houses some, more as it grows,
## plus the Hiring Board's Bunkhouse track.
func roster_cap() -> int:
	var per: Dictionary = DB.cfg("roster_per_tier", {"outpost": 4, "town": 6, "city": 9})
	var n := 0
	for s in settlements:
		n += int(per.get(s.tier, 4))
		if building_level(int(s.index), "hiring_board") > 0:
			n += int(track_value(int(s.index), "hiring_board", "bunks"))
	return maxi(1, n)


func promised_name(i: int = 0) -> String:
	var pr: Array = settlement(i).get("promised", [])
	return str(pr[0].hero_name) if not pr.is_empty() else ""


func missing_name() -> String:
	return str(missing[0].hero_name) if not missing.is_empty() else ""


func site_by_index(i: int) -> Dictionary:
	for id in DB.settlements:
		if int(DB.settlements[id].get("index", -1)) == i:
			return DB.settlements[id]
	return {}


func site_count() -> int:
	return DB.settlements.size()


func settlement(i: int) -> Dictionary:
	for s in settlements:
		if int(s.index) == i:
			return s
	return {}


func settlement_name(i: int) -> String:
	return site_by_index(i).get("name", "?")


func founded(i: int) -> bool:
	return not settlement(i).is_empty()


func frontier_index() -> int:
	var m := 0
	for s in settlements:
		m = maxi(m, int(s.index))
	return m


# --- Heroes ---------------------------------------------------------------------------

func make_hero(class_id: String, lvl: int = 1) -> Hero:
	var h := Hero.new()
	h.uid = next_uid
	next_uid += 1
	h.class_id = class_id
	h.hero_name = random_name()
	h.level = 1
	var table: Array = DB.cfg("xp_levels", [0, 10, 25, 45, 70])
	if lvl > 1:
		h.add_xp(int(table[mini(lvl - 1, table.size() - 1)]))
	h.known = starting_moves(class_id)
	h.equipped = h.known.duplicate()
	var sk_pool: Array = Stats.shuffled(rng, DB.survival.keys())
	for i in 2:
		h.survival[sk_pool[i]] = {"rank": 1, "xp": 0}
	add_random_quirk(h, true)
	add_random_quirk(h, false)
	h.look_seed = rng.randi()
	h.hp = h.max_hp()
	return h


## A single first name, not already used by a living hero or a recruit on offer.
func random_name() -> String:
	var pool: Array = DB.names.get("first", ["Sam"])
	var used := {}
	for h in heroes:
		used[h.hero_name] = true
	for st in settlements:
		for rd in st.get("recruits", []):
			used[str(rd.get("hero_name", ""))] = true
	var free := pool.filter(func(x): return not used.has(x))
	return Stats.pick(rng, free if not free.is_empty() else pool)


func hero(uid: int) -> Hero:
	for h in heroes:
		if h.uid == uid:
			return h
	return null


func heroes_at(i: int) -> Array:
	return heroes.filter(func(h): return h.location == i and h.transit_to < 0)


## Returns the quirk id added, or "".
func add_random_quirk(h: Hero, positive: bool, avoid: Array = []) -> String:
	var pool: Array = []
	for q in DB.quirks:
		if DB.quirks[q].get("positive", false) == positive and not q in h.quirks and not q in avoid:
			pool.append(q)
	if pool.is_empty():
		return ""
	var q: String = Stats.pick(rng, pool)
	return add_quirk(h, q)


## Adds a quirk, replacing a random one of the same kind when full. Returns the id.
func add_quirk(h: Hero, q: String) -> String:
	if q == "random_positive":
		return add_random_quirk(h, true)
	if q == "random_negative":
		return add_random_quirk(h, false)
	if q == "random":
		return add_random_quirk(h, rng.randf() < 0.5)
	if q in h.quirks or not DB.quirks.has(q):
		return ""
	var positive: bool = DB.quirks[q].get("positive", false)
	var same := h.positive_quirks() if positive else h.negative_quirks()
	var cap: int = DB.cfg("max_positive_quirks", 4) if positive else DB.cfg("max_negative_quirks", 4)
	if same.size() >= cap:
		h.quirks.erase(Stats.pick(rng, same))
	h.quirks.append(q)
	return q


func kill_hero(h: Hero, note: String = "") -> void:
	if h == null:
		return
	h.alive = false
	dead.append({"name": h.hero_name, "class_id": h.class_id, "level": h.level,
		"note": note if note != "" else h.death_note, "week": week})
	heroes.erase(h)
	stats.deaths += 1


# --- Costs ----------------------------------------------------------------------------

func can_afford(cost: Dictionary) -> bool:
	return money >= int(cost.get("money", 0)) and timber >= int(cost.get("timber", 0)) \
		and iron >= int(cost.get("iron", 0)) and charters >= int(cost.get("charters", 0))


func pay(cost: Dictionary) -> bool:
	if not can_afford(cost):
		return false
	money -= int(cost.get("money", 0))
	timber -= int(cost.get("timber", 0))
	iron -= int(cost.get("iron", 0))
	charters -= int(cost.get("charters", 0))
	return true


static func cost_text(cost: Dictionary) -> String:
	var parts: Array = []
	if int(cost.get("money", 0)) > 0:
		parts.append("%d chips" % int(cost.money))
	if int(cost.get("timber", 0)) > 0:
		parts.append("%d Timber" % int(cost.timber))
	if int(cost.get("iron", 0)) > 0:
		parts.append("%d Iron" % int(cost.iron))
	if int(cost.get("charters", 0)) > 0:
		parts.append("%d Charter%s" % [int(cost.charters), "" if int(cost.charters) == 1 else "s"])
	return ", ".join(parts) if not parts.is_empty() else "Free"


# --- Settlements & buildings ----------------------------------------------------------

func tier_info(tier_id: String) -> Dictionary:
	for t in DB.cfg("tiers", []):
		if t.id == tier_id:
			return t
	return {}


func next_tier(tier_id: String) -> Dictionary:
	var tiers: Array = DB.cfg("tiers", [])
	for i in tiers.size():
		if tiers[i].id == tier_id and i + 1 < tiers.size():
			return tiers[i + 1]
	return {}


func building_level(i: int, bid: String) -> int:
	return int(settlement(i).get("buildings", {}).get(bid, 0))


## The first settlement east of (or at) i that has the building, or -1.
func nearest_with(i: int, bid: String) -> int:
	for j in range(i, -1, -1):
		if building_level(j, bid) > 0:
			return j
	return -1


func building_cost(i: int, bid: String) -> Dictionary:
	var lvl := building_level(i, bid)
	var costs: Array = DB.buildings.get(bid, {}).get("costs", [])
	if lvl >= costs.size():
		return {}
	if lvl == 0 and is_ruin(i, bid):
		var pct := int(DB.cfg("ruin_rebuild_pct", 50))
		var c := {}
		for k in costs[0]:
			c[k] = int(ceil(int(costs[0][k]) * pct / 100.0))
		return c
	return costs[lvl]


## A burned building: it holds its plot and can be rebuilt at a discount.
func is_ruin(i: int, bid: String) -> bool:
	return bid in settlement(i).get("ruins", [])


func plots_used(i: int) -> int:
	var st := settlement(i)
	return st.get("buildings", {}).size() + st.get("ruins", []).size()


## "" if allowed, otherwise the reason.
func can_build(i: int, bid: String) -> String:
	var st := settlement(i)
	if st.is_empty():
		return "Not founded"
	var lvl := building_level(i, bid)
	var tier := tier_info(st.tier)
	if lvl == 0 and not is_ruin(i, bid) and plots_used(i) >= int(tier.get("slots", 3)):
		return "No free building plots (upgrade the %s)" % tier.get("name", "settlement")
	if lvl >= int(tier.get("max_level", 1)):
		return "A %s can't support a bigger %s" % [tier.get("name", ""), DB.buildings[bid].name]
	var cost := building_cost(i, bid)
	if cost.is_empty():
		return "Fully upgraded"
	if not can_afford(cost):
		return "Can't afford: " + cost_text(cost)
	return ""


# Upgrade tracks: some buildings improve along separate lines (the Hiring Board's number
# of recruits and their quality). A track can rise as far as the settlement tier's
# max building level.

func track_level(i: int, bid: String, tid: String) -> int:
	return int(settlement(i).get("tracks", {}).get(bid, {}).get(tid, 0))


func track_value(i: int, bid: String, tid: String) -> Variant:
	var vals: Array = DB.buildings.get(bid, {}).get("tracks", {}).get(tid, {}).get("values", [0])
	return vals[clampi(track_level(i, bid, tid), 0, vals.size() - 1)]


func track_cost(i: int, bid: String, tid: String) -> Dictionary:
	var costs: Array = DB.buildings.get(bid, {}).get("tracks", {}).get(tid, {}).get("costs", [])
	var lvl := track_level(i, bid, tid)
	return costs[lvl] if lvl < costs.size() else {}


func can_upgrade_track(i: int, bid: String, tid: String) -> String:
	if building_level(i, bid) <= 0:
		return "Build it first"
	var cost := track_cost(i, bid, tid)
	if cost.is_empty():
		return "Fully upgraded"
	var tier := tier_info(settlement(i).tier)
	if track_level(i, bid, tid) >= int(tier.get("max_level", 1)):
		return "A %s can't support more (grow the settlement)" % tier.get("name", "")
	if not can_afford(cost):
		return "Can't afford: " + cost_text(cost)
	return ""


func upgrade_track(i: int, bid: String, tid: String) -> bool:
	if can_upgrade_track(i, bid, tid) != "":
		return false
	pay(track_cost(i, bid, tid))
	var st := settlement(i)
	if not st.has("tracks"):
		st["tracks"] = {}
	if not st.tracks.has(bid):
		st.tracks[bid] = {}
	st.tracks[bid][tid] = track_level(i, bid, tid) + 1
	return true


func build(i: int, bid: String) -> bool:
	if can_build(i, bid) != "":
		return false
	pay(building_cost(i, bid))
	settlement(i).buildings[bid] = building_level(i, bid) + 1
	settlement(i).get("ruins", []).erase(bid)
	return true


func can_upgrade_tier(i: int) -> String:
	var st := settlement(i)
	var nt := next_tier(st.get("tier", ""))
	if nt.is_empty():
		return "Already a City"
	if not can_afford(nt.get("cost", {})):
		return "Can't afford: " + cost_text(nt.get("cost", {}))
	return ""


func upgrade_tier(i: int) -> bool:
	if can_upgrade_tier(i) != "":
		return false
	var st := settlement(i)
	var nt := next_tier(st.tier)
	pay(nt.cost)
	st.tier = nt.id
	return true


## Site index founded by beating this region's boss, or -1.
func site_for_region(region_id: String) -> int:
	for id in DB.settlements:
		if DB.settlements[id].get("founded_at", "") == region_id:
			return int(DB.settlements[id].index)
	return -1


func can_found(i: int) -> String:
	var site := site_by_index(i)
	if site.is_empty():
		return "No such place"
	if founded(i):
		return "Already founded"
	if not site.get("founded_at", "") in beaten:
		return "Defeat the boss of %s first" % DB.regions.get(site.get("founded_at", ""), {}).get("name", "?")
	var cost: Dictionary = DB.cfg("found_cost", {})
	if not can_afford(cost):
		return "Can't afford: " + cost_text(cost)
	return ""


func found(i: int) -> bool:
	if can_found(i) != "":
		return false
	pay(DB.cfg("found_cost", {}))
	settlements.append({"index": i, "site": site_by_index(i).id, "tier": "outpost",
		"buildings": {"stage_line": 1}, "recruits": [], "stock": [], "used": {}})
	settlements.sort_custom(func(a, b): return a.index < b.index)
	_refresh_settlement(settlement(i))
	return true


## Slots a building offers per week. Activity buildings (Saloon, Chapel, Boot Hill) have
## this many slots for *each* activity; `key` is "bid/activity" for those, else the bid.
func slot_cap(i: int, bid: String) -> int:
	var lvl := building_level(i, bid)
	if lvl <= 0:
		return 0
	var b: Dictionary = DB.buildings.get(bid, {})
	if b.has("slots"):
		return int(b.slots[mini(lvl, b.slots.size()) - 1])
	if b.has("seats"):
		return int(b.seats[mini(lvl, b.seats.size()) - 1])
	return 99


func slots_left(i: int, bid: String, key: String = "") -> int:
	return slot_cap(i, bid) - int(settlement(i).get("used", {}).get(key if key != "" else bid, 0))


## Heroes placed in a building's slots this week (uids), for showing them in the slots.
func slot_heroes(i: int, key: String) -> Array:
	return settlement(i).get("assigned", {}).get(key, [])


func _use_slot(i: int, bid: String, key: String = "", uid: int = -1) -> void:
	var st := settlement(i)
	var k := key if key != "" else bid
	st.used[k] = int(st.used.get(k, 0)) + 1
	if uid >= 0:
		if not st.has("assigned"):
			st["assigned"] = {}
		if not st.assigned.has(k):
			st.assigned[k] = []
		st.assigned[k].append(uid)


## Heroes at settlement i who could use a building right now.
func service_candidates(i: int) -> Array:
	return heroes_at(i).filter(func(h): return h.available())


# Saloon / Chapel / Boot Hill -----------------------------------------------------------

func activity(bid: String, act_id: String) -> Dictionary:
	for a in DB.buildings.get(bid, {}).get("activities", []):
		if a.id == act_id:
			return a
	return {}


func activity_cost(i: int, bid: String, act_id: String) -> int:
	var lvl := maxi(1, building_level(i, bid))
	return int(activity(bid, act_id).get("cost", [0])[mini(lvl, 3) - 1])


func activity_relief(i: int, bid: String, act_id: String) -> int:
	var lvl := maxi(1, building_level(i, bid))
	return int(activity(bid, act_id).get("relief", [0])[mini(lvl, 3) - 1])


func can_do_activity(i: int, bid: String, act_id: String, h: Hero) -> String:
	if building_level(i, bid) <= 0:
		return "No %s here" % DB.buildings[bid].name
	if h == null or not h.available() or h.location != i:
		return "Hero not available"
	if slots_left(i, bid, bid + "/" + act_id) <= 0:
		return "No room this week"
	if money < activity_cost(i, bid, act_id):
		return "Not enough money"
	return ""


## Returns a list of message strings.
func do_activity(i: int, bid: String, act_id: String, h: Hero) -> Array:
	var msgs: Array = []
	if can_do_activity(i, bid, act_id, h) != "":
		return msgs
	var act := activity(bid, act_id)
	money -= activity_cost(i, bid, act_id)
	_use_slot(i, bid, bid + "/" + act_id, h.uid)
	var relief := activity_relief(i, bid, act_id)
	var amt := rng.randi_range(int(relief * 0.8), relief)
	var before := h.fatigue
	h.fatigue = maxi(0, h.fatigue - amt)
	msgs.append("%s sheds %d Fatigue at the %s." % [h.hero_name, before - h.fatigue, DB.buildings[bid].name])
	if h.is_breaking():
		msgs.append("%s is no longer %s." % [h.hero_name, DB.fatigue_states[h.fatigue_state].name])
		h.fatigue_state = ""
	for se in act.get("side_effects", []):
		if rng.randf() * 100.0 < float(se.get("chance", 0)):
			match se.get("type", ""):
				"quirk":
					var q := add_quirk(h, se.quirk)
					if q != "":
						msgs.append(str(se.text) % h.hero_name + " (%s)" % DB.quirks[q].name)
				"money":
					money = maxi(0, money + int(se.amount))
					msgs.append(str(se.text) % h.hero_name)
	h.busy_weeks = 1
	h.busy_reason = "At the %s" % DB.buildings[bid].name
	return msgs


# Doctor --------------------------------------------------------------------------------

func doctor_cost(i: int, h: Hero) -> int:
	var lvl := maxi(1, building_level(i, "doctor"))
	var mult: float = DB.buildings.doctor.cost_mult[lvl - 1]
	return int(round((DB.cfg("doctor_quirk_cost", 250) + DB.cfg("doctor_quirk_cost_per_level", 50) * (h.level - 1)) * mult))


func can_treat_quirk(i: int, h: Hero, q: String) -> String:
	if building_level(i, "doctor") <= 0:
		return "No Doctor's Office here"
	if h == null or not h.available() or h.location != i:
		return "Hero not available"
	if not q in h.negative_quirks():
		return "Nothing to treat"
	if slots_left(i, "doctor") <= 0:
		return "The doctor is booked this week"
	if money < doctor_cost(i, h):
		return "Not enough money"
	return ""


func treat_quirk(i: int, h: Hero, q: String) -> bool:
	if can_treat_quirk(i, h, q) != "":
		return false
	money -= doctor_cost(i, h)
	_use_slot(i, "doctor", "", h.uid)
	h.quirks.erase(q)
	h.busy_weeks = 1
	h.busy_reason = "At the Doctor"
	return true


# Smithy & Drill Hall -------------------------------------------------------------------

func gear_cost(i: int, kind: String, next_tier_value: int) -> Dictionary:
	var gc: Dictionary = DB.cfg("gear_costs", {})
	var lvl := maxi(1, building_level(i, "smithy"))
	var mult: float = DB.buildings.smithy.cost_mult[lvl - 1]
	var idx := next_tier_value - 1
	return {"money": int(round(int(gc.get(kind, [0, 0, 0, 0])[idx]) * mult)), "iron": int(gc.get("iron", [0, 0, 0, 0])[idx])}


func can_upgrade_gear(i: int, h: Hero, kind: String) -> String:
	var lvl := building_level(i, "smithy")
	if lvl <= 0:
		return "No Smithy here"
	if h == null or h.location != i or h.transit_to >= 0:
		return "Hero not here"
	var cur: int = h.weapon_tier if kind == "weapon" else h.armor_tier
	var nt := cur + 1
	if nt > DB.cfg("max_tier", 4):
		return "Already the best"
	if nt > int(DB.buildings.smithy.max_tier[lvl - 1]):
		return "Needs a better Smithy"
	if nt > h.level:
		return "Needs hero level %d" % nt
	if not can_afford(gear_cost(i, kind, nt)):
		return "Can't afford: " + cost_text(gear_cost(i, kind, nt))
	return ""


func upgrade_gear(i: int, h: Hero, kind: String) -> bool:
	if can_upgrade_gear(i, h, kind) != "":
		return false
	var nt: int = (h.weapon_tier if kind == "weapon" else h.armor_tier) + 1
	pay(gear_cost(i, kind, nt))
	var old_max := h.max_hp()
	if kind == "weapon":
		h.weapon_tier = nt
	else:
		h.armor_tier = nt
		h.hp += h.max_hp() - old_max
	return true


## A new hero knows their class's first two (stock) moves plus two more at random.
func starting_moves(class_id: String) -> Array:
	var all: Array = DB.cls(class_id).get("skills", [])
	var n := int(DB.cfg("starting_moves", 4))
	var out: Array = all.slice(0, mini(int(DB.cfg("stock_moves", 2)), all.size()))
	for s in Stats.shuffled(rng, all):
		if out.size() >= n:
			break
		if not s in out:
			out.append(s)
	# Keep the class's own listing order, so move lists read the same on every hero.
	return all.filter(func(s): return s in out)


func learn_cost(i: int) -> int:
	var lvl := maxi(1, building_level(i, "drill_hall"))
	var mult: float = DB.buildings.drill_hall.cost_mult[lvl - 1]
	return int(round(int(DB.cfg("learn_cost", 300)) * mult))


func can_learn_skill(i: int, h: Hero, sid: String) -> String:
	if building_level(i, "drill_hall") <= 0:
		return "No Drill Hall here"
	if h == null or h.location != i or h.transit_to >= 0:
		return "Hero not here"
	if h.knows(sid):
		return "Already known"
	if money < learn_cost(i):
		return "Not enough money"
	return ""


func learn_skill(i: int, h: Hero, sid: String) -> bool:
	if can_learn_skill(i, h, sid) != "":
		return false
	money -= learn_cost(i)
	h.known.append(sid)
	h.known = h.cls().skills.filter(func(s): return s in h.known)
	if h.equipped.size() < 4:
		h.equipped.append(sid)
	return true


func skill_cost(i: int, next_level: int) -> int:
	var lvl := maxi(1, building_level(i, "drill_hall"))
	var mult: float = DB.buildings.drill_hall.cost_mult[lvl - 1]
	return int(round(int(DB.cfg("skill_costs", [0, 150, 400, 800])[next_level - 1]) * mult))


func can_upgrade_skill(i: int, h: Hero, sid: String) -> String:
	var lvl := building_level(i, "drill_hall")
	if lvl <= 0:
		return "No Drill Hall here"
	if h == null or h.location != i or h.transit_to >= 0:
		return "Hero not here"
	if not h.knows(sid):
		return "Not learned yet"
	var nl := h.skill_level(sid) + 1
	if nl > DB.cfg("max_skill_level", 5):
		return "Mastered"
	if nl > int(DB.buildings.drill_hall.max_skill[lvl - 1]):
		return "Needs a better Drill Hall"
	if nl > h.level + 1:
		return "Needs hero level %d" % (nl - 1)
	if money < skill_cost(i, nl):
		return "Not enough money"
	return ""


func upgrade_skill(i: int, h: Hero, sid: String) -> bool:
	if can_upgrade_skill(i, h, sid) != "":
		return false
	var nl := h.skill_level(sid) + 1
	money -= skill_cost(i, nl)
	h.skill_levels[sid] = nl
	return true


# General store -------------------------------------------------------------------------

func store_discount(i: int) -> int:
	var lvl := building_level(i, "general_store")
	if lvl <= 0:
		return 0
	return int(DB.buildings.general_store.discount[lvl - 1])


func item_price(i: int, item_id: String) -> int:
	var base := int(DB.items.get(item_id, {}).get("price", 0))
	return maxi(1, int(round(base * (100 - store_discount(i)) / 100.0)))


func keepsake_price(i: int, kid: String) -> int:
	var base := int(DB.keepsakes.get(kid, {}).get("price", 0))
	return int(round(base * (100 - store_discount(i)) / 100.0))


func buy_keepsake(i: int, kid: String) -> bool:
	var st := settlement(i)
	if not kid in st.get("stock", []) or money < keepsake_price(i, kid):
		return false
	money -= keepsake_price(i, kid)
	st.stock.erase(kid)
	stash.append(kid)
	return true


## "" if the hero can wear this trinket, else why not (class trinkets are one class only).
func keepsake_block(h: Hero, kid: String) -> String:
	var need: String = DB.keepsakes.get(kid, {}).get("class", "")
	if need != "" and h.class_id != need:
		return "%s only" % DB.classes.get(need, {}).get("name", need)
	return ""


func equip_keepsake(h: Hero, kid: String) -> bool:
	if not kid in stash or h.keepsakes.size() >= 2 or keepsake_block(h, kid) != "":
		return false
	stash.erase(kid)
	h.keepsakes.append(kid)
	return true


func unequip_keepsake(h: Hero, kid: String) -> bool:
	if not kid in h.keepsakes:
		return false
	h.keepsakes.erase(kid)
	stash.append(kid)
	return true


func random_keepsake(rarities: Array = ["common", "uncommon", "rare"]) -> String:
	var pool: Array = []
	for k in DB.keepsakes:
		var r: String = DB.keepsakes[k].get("rarity", "common")
		if r in rarities:
			var w := 6 if r == "common" else (3 if r == "uncommon" else 1)
			# Class trinkets turn up twice as often for classes on the roster.
			var kc: String = DB.keepsakes[k].get("class", "")
			if kc != "" and heroes.any(func(h): return h.class_id == kc):
				w *= 2
			pool.append({"id": k, "weight": w})
	var pick = Stats.pick_weighted(rng, pool)
	return pick.id if pick != null else ""


# Hiring board --------------------------------------------------------------------------

func hire(i: int, index_in_list: int) -> Hero:
	var st := settlement(i)
	if index_in_list < 0 or index_in_list >= st.get("recruits", []).size():
		return null
	if heroes.size() >= roster_cap():
		return null
	var h := Hero.from_dict(st.recruits[index_in_list])
	st.recruits.remove_at(index_in_list)
	var pr: Array = st.get("promised", [])
	for k in range(pr.size() - 1, -1, -1):
		if int(pr[k].uid) == h.uid:
			pr.remove_at(k)
	h.location = i
	heroes.append(h)
	return h


func dismiss(h: Hero) -> void:
	for k in h.keepsakes:
		stash.append(k)
	heroes.erase(h)


# Stage line ----------------------------------------------------------------------------

## The stage runs from whichever end of the route has a Stage Line.
func stage_for(from_i: int, to_i: int) -> int:
	if building_level(from_i, "stage_line") > 0:
		return from_i
	if founded(to_i) and building_level(to_i, "stage_line") > 0:
		return to_i
	return -1


func can_send(from_i: int, to_i: int, h: Hero) -> String:
	if not founded(to_i) or to_i == from_i:
		return "No destination"
	var sl := stage_for(from_i, to_i)
	if sl < 0:
		return "No Stage Line at either end"
	if h == null or not h.available() or h.location != from_i:
		return "Hero not available"
	if slots_left(sl, "stage_line") <= 0:
		return "No seats left this week"
	return ""


func send_hero(from_i: int, to_i: int, h: Hero) -> bool:
	if can_send(from_i, to_i, h) != "":
		return false
	_use_slot(stage_for(from_i, to_i), "stage_line", "", h.uid)
	h.transit_to = to_i
	h.transit_weeks = absi(to_i - from_i)
	return true


# Weekly clock --------------------------------------------------------------------------

func advance_week() -> Array:
	var msgs: Array = []
	week += 1
	var floor_money: int = DB.cfg("grubstake_floor", 150)
	if money < floor_money:
		msgs.append("A Casino agent stakes the company %d chips. (\"The house always wants you back at the table.\")" % (floor_money - money))
		money = floor_money
	for h in heroes:
		if h.busy_weeks > 0:
			h.busy_weeks -= 1
			if h.busy_weeks == 0:
				h.busy_reason = ""
		if h.transit_to >= 0:
			h.transit_weeks -= 1
			if h.transit_weeks <= 0:
				h.location = h.transit_to
				h.transit_to = -1
				h.transit_weeks = 0
				msgs.append("%s arrives at %s." % [h.hero_name, settlement_name(h.location)])
	_refresh_week()
	return msgs


func _refresh_week() -> void:
	for st in settlements:
		_refresh_settlement(st)


func _refresh_settlement(st: Dictionary) -> void:
	st.used = {}
	st["assigned"] = {}
	_roll_quests(st)
	st.recruits = st.get("promised", []).duplicate(true)
	var i := int(st.index)
	if building_level(i, "hiring_board") > 0:
		var count := int(track_value(i, "hiring_board", "notices"))
		var rep := int(track_value(i, "hiring_board", "reputation"))
		for n in count:
			var lvl := 1
			var roll := rng.randf()
			if rep >= 2 and roll < 0.2:
				lvl = 3
			elif rep >= 1 and roll < (0.5 if rep >= 2 else 0.4):
				lvl = 2
			var h := make_hero(Stats.pick(rng, DB.classes.keys()), lvl)
			# Word of mouth brings steadier folk: fewer bad habits, more good ones.
			if rep >= 1 and (rep >= 2 or rng.randf() < 0.5):
				for q in h.negative_quirks():
					h.quirks.erase(q)
			if rep >= 2:
				add_random_quirk(h, true)
			h.location = i
			st.recruits.append(h.to_dict())
	st.stock = []
	var gs := building_level(i, "general_store")
	if gs > 0:
		for n in int(DB.buildings.general_store.keepsake_stock[gs - 1]):
			var k := random_keepsake()
			if k != "" and not k in st.stock:
				st.stock.append(k)


# --- Expeditions ---------------------------------------------------------------------

## Without a General Store the wagon goes out with a free basic kit and nothing is sold.
func has_store(i: int) -> bool:
	return building_level(i, "general_store") > 0


func free_kit() -> Dictionary:
	return DB.cfg("free_kit", {"food": 12, "bandages": 1, "wagon_parts": 1}).duplicate()


## "" if the store here sells the item, otherwise why not.
func item_for_sale(i: int, item: String) -> String:
	var need := int(DB.items.get(item, {}).get("store_level", 1))
	var lvl := building_level(i, "general_store")
	if lvl <= 0:
		return "No General Store here yet"
	if lvl < need:
		return "Needs a level %d General Store" % need
	return ""


func supply_cost(i: int, supplies: Dictionary) -> int:
	if not has_store(i):
		return 0
	var total := 0
	for it in supplies:
		total += item_price(i, it) * int(supplies[it])
	return total


## Every destination from settlement i: the tutorial while it's pending, otherwise the
## trail west plus the settlement's side adventures.
func expedition_options(i: int) -> Array:
	var site := site_by_index(i)
	if tutorial_pending(i):
		return [site.tutorial]
	var out: Array = []
	if site.get("region_west", "") != "":
		out.append(site.region_west)
	for r in site.get("side_regions", []):
		# Story side adventures happen once; after that the weekly chatter takes over.
		if DB.regions.has(r) and not (DB.regions[r].get("story", false) and r in beaten):
			out.append(r)
	for q in settlement(i).get("quests", []):
		if DB.regions.has(q):
			out.append(q)
	return out


# --- Weekly side quests ("chatter" at the Saloon) -------------------------------------

## Rolls this week's side quests for a settlement from data/quests.json. The Saloon's
## chatter track sets how many, its tips track how good the rewards can be.
func _roll_quests(st: Dictionary) -> void:
	var i := int(st.index)
	st["quests"] = []
	_prune_quests()
	if building_level(i, "saloon") <= 0 or DB.quests.is_empty():
		return
	var west: String = site_by_index(i).get("region_west", "")
	if west == "":
		return
	var count := int(track_value(i, "saloon", "chatter"))
	var tier_l := int(track_value(i, "saloon", "tips"))
	var templates: Array = DB.quests.get("templates", {}).keys().filter(func(k): return not story_flags.has(DB.quests.templates[k].get("done_flag", "-")))
	var picks := Stats.shuffled(rng, templates)
	# Story rumors (like Mulligan's hideout) jump the queue most weeks until they're done.
	for k in templates:
		if rng.randf() * 100.0 < float(DB.quests.templates[k].get("priority", 0)):
			picks.erase(k)
			picks.push_front(k)
	for n in mini(count, picks.size()):
		var qid := "q_%d_%d_%d" % [i, week, n]
		var reg := _make_quest(picks[n], west, tier_l)
		quest_regions[qid] = reg
		DB.regions[qid] = reg
		st.quests.append(qid)


## Keeps only the quests still on offer somewhere or being played right now.
func _prune_quests() -> void:
	var keep := {}
	for s in settlements:
		for q in s.get("quests", []):
			keep[q] = true
	if run != null:
		keep[run.region_id] = true
	for q in quest_regions.keys():
		if not keep.has(q):
			quest_regions.erase(q)


func _make_quest(tid: String, west: String, tier_l: int) -> Dictionary:
	var t: Dictionary = DB.quests.templates[tid]
	var base: Dictionary = DB.regions[west]
	var place: String = Stats.pick(rng, DB.quests.get("places", ["the hills"]))
	var ch: Dictionary = DB.quests.get("chances", {})
	var tl := clampi(tier_l, 0, 2)
	var has_boss: bool = t.get("always_boss", false) or rng.randf() * 100.0 < float(ch.get("boss", [25, 40, 55])[tl])
	var tier := int(base.get("tier", 1))
	var mult := (1.0 + tl * 0.5) * tier
	var reward := {
		"money": int(rng.randi_range(80, 150) * mult),
		"timber": rng.randi_range(1, 3) + tl,
		"iron": rng.randi_range(1, 3) + tl,
		"trinket": "",
		"recruit": 0,
	}
	if rng.randf() * 100.0 < float(ch.get("trinket", [10, 22, 35])[tl]):
		reward.trinket = "rare" if tl >= 1 else "uncommon"
	if rng.randf() * 100.0 < float(ch.get("recruit", [8, 14, 20])[tl]):
		reward.recruit = 1 + tl
	var b: Dictionary = t.get("boss", {})
	var reg := {
		"name": str(t.name).replace("{place}", place), "tier": tier, "rec_level": base.get("rec_level", "1"),
		"side": true, "quest": true, "template": tid, "columns": 7,
		"desc": str(t.desc).replace("{place}", place),
		"palette": base.get("palette", {}), "props": base.get("props", []), "cave_name": base.get("cave_name", "Cave"),
		"node_weights": t.get("node_weights", {}),
		"fights": t.fights, "elites": t.get("elites", base.get("elites", [])), "cave_fights": base.get("cave_fights", []),
		"events": base.get("events", []), "homestead_events": base.get("homestead_events", []),
		"curios": base.get("curios", []), "cave_curios": base.get("cave_curios", []),
		"final": "boss" if has_boss else "crossing",
		"boss": {"name": str(b.get("name", "The Boss")), "landmark": place,
			"intro": str(b.get("intro", "")).replace("{place}", place),
			"victory": str(b.get("victory", "")).replace("{place}", place),
			"enemies": b.get("enemies", t.get("final", []))},
		"crossing": {"name": str(t.name).replace("{place}", place), "enemies": t.get("final", [])},
		"quest_reward": reward,
		"done_flag": t.get("done_flag", ""), "boss_keepsake": t.get("boss_keepsake", ""),
		"difficulty": int(t.get("difficulty", 2)) + (1 if has_boss and not t.get("always_boss", false) else 0) + tl,
	}
	return reg


const DIFFICULTY := ["", "Gentle", "Fair", "Tough", "Hard", "Deadly"]
const DIFFICULTY_TEXT := ["", "A good first outing.", "A fair test for a fresh company.",
	"Expect hard fights: bring a healer and full bellies.", "A real ordeal: seasoned heroes and plenty of supplies.",
	"Only the best-prepared come back."]


## "Difficulty: Tough (3/5). Expect hard fights..." for a region's hover text.
static func difficulty_text(reg: Dictionary) -> String:
	var d := clampi(int(reg.get("difficulty", 2)), 1, 5)
	return "Difficulty: %s (%d/5). %s" % [DIFFICULTY[d], d, DIFFICULTY_TEXT[d]]


## A short list of what a quest promises, for tooltips and the Saloon.
static func quest_hints(reg: Dictionary) -> String:
	var r: Dictionary = reg.get("quest_reward", {})
	var parts: Array = ["%d chips" % int(r.get("money", 0))]
	if int(r.get("timber", 0)) > 0:
		parts.append("%d Timber" % int(r.timber))
	if int(r.get("iron", 0)) > 0:
		parts.append("%d Iron" % int(r.iron))
	if str(r.get("trinket", "")) != "":
		parts.append("a %s trinket" % r.trinket)
	if int(r.get("recruit", 0)) > 0:
		parts.append("a hand who wants to join")
	var s := "Rumored reward: " + ", ".join(parts) + "."
	if reg.get("final", "") == "boss":
		s += " Word is there's a boss: " + str(reg.boss.name) + "."
	return s


func register_quest_regions() -> void:
	for q in quest_regions:
		DB.regions[q] = quest_regions[q]


## Where an expedition from settlement i goes by default: its tutorial first, if it has one.
func expedition_region(i: int) -> String:
	var site := site_by_index(i)
	if not tutorial_done and site.get("tutorial", "") != "":
		return site.tutorial
	return site.get("region_west", "")


func tutorial_pending(i: int = 0) -> bool:
	return not tutorial_done and site_by_index(i).get("tutorial", "") != ""


## The tutorial party sets out with the first four heroes and free supplies.
func start_tutorial() -> RunState:
	var uids: Array = []
	for cid in DB.cfg("tutorial_party", ["marshal", "gunslinger"]):
		for h in heroes_at(0):
			if h.class_id == cid and h.available() and not h.uid in uids:
				uids.append(h.uid)
				break
	# If one of them has fallen, any rested hero takes their place.
	var size: int = DB.cfg("tutorial_party", []).size()
	for h in heroes_at(0):
		if uids.size() >= maxi(2, size):
			break
		if h.available() and not h.uid in uids:
			uids.append(h.uid)
	if uids.is_empty():
		return null
	run = RunState.create(self, expedition_region(0), 0, uids, DB.cfg("tutorial_supplies", {"food": 10, "bandages": 2}))
	stats.expeditions += 1
	return run


## Marks the tutorial won (or skipped) and rebuilds the ruin it restores. Returns story text.
## skipped: the player skipped the tutorial, so hand out what winning it would have given.
func complete_tutorial(skipped: bool = false) -> String:
	if tutorial_done:
		return ""
	tutorial_done = true
	if skipped:
		var reg: Dictionary = DB.regions.get(site_by_index(0).get("tutorial", ""), {})
		var br: Dictionary = reg.get("boss_rewards", {})
		money += int(br.get("money", 0))
		timber += int(br.get("timber", 0))
		iron += int(br.get("iron", 0))
		var k: String = reg.get("boss", {}).get("keepsake", "")
		if k != "":
			stash.append(k)
		var tid: String = site_by_index(0).get("tutorial", "")
		if tid != "" and not tid in beaten:
			beaten.append(tid)
		for h in heroes:
			h.add_xp(int(reg.get("xp_cap", 0)))
	var site := site_by_index(0)
	var bid: String = site.get("tutorial_rebuilds", "")
	var st := settlement(0)
	if bid != "" and building_level(0, bid) == 0:
		st.get("ruins", []).erase(bid)
		st.buildings[bid] = 1
		return "Ma Delaney has the %s standing again by the end of the week: new planks, old piano, same watered whiskey. Heroes can shed Fatigue there now." % DB.buildings[bid].name
	return ""


## "" if the party can set out, otherwise why not.
func can_embark(i: int, party_uids: Array, supplies: Dictionary, region: String = "") -> String:
	var dest := region if region != "" else expedition_region(i)
	if dest == "" or not dest in expedition_options(i):
		return "There is nowhere further west to go."
	if party_uids.is_empty():
		return "Choose at least one hero."
	if party_uids.size() > 4:
		return "At most four heroes."
	for uid in party_uids:
		var h := hero(uid)
		if h == null or not h.available() or h.location != i:
			return "A chosen hero isn't available."
	if not has_store(i):
		var kit := free_kit()
		for it in supplies:
			if int(supplies[it]) > int(kit.get(it, 0)):
				return "Without a General Store you only have the basic kit."
	else:
		for it in supplies:
			if int(supplies[it]) > 0 and item_for_sale(i, it) != "":
				return "%s: %s." % [DB.items[it].name, item_for_sale(i, it)]
	if supply_cost(i, supplies) > money:
		return "Can't afford those supplies."
	if Inventory.slots_used(supplies) > Inventory.capacity():
		return "The wagon can't carry that much (%d of %d slots)." % [Inventory.slots_used(supplies), Inventory.capacity()]
	return ""


func start_run(i: int, party_uids: Array, supplies: Dictionary, region: String = "") -> RunState:
	if can_embark(i, party_uids, supplies, region) != "":
		return null
	money -= supply_cost(i, supplies)
	var dest := region if region != "" else expedition_region(i)
	# Taking a job from the chatter board takes it off the board.
	settlement(i).get("quests", []).erase(dest)
	run = RunState.create(self, dest, i, party_uids, supplies)
	stats.expeditions += 1
	return run


## Settle the finished expedition. status: victory / abandoned / defeat.
func finish_run(status: String) -> Dictionary:
	var r := run
	var summary := {"status": status, "region": r.region_id, "origin": r.origin, "heroes": [], "loot": r.loot.duplicate(true),
		"recruits": [], "boss_won": r.boss_won, "found_site": -1, "week_msgs": []}
	var survivors := r.party_heroes()
	var won := status == "victory"
	summary["story"] = ""
	if status == "abandoned":
		for h in survivors:
			Fatigue.add(h, DB.cfg("turn_back_fatigue", 20), rng)
	survivors = r.party_heroes()
	if status == "defeat" or survivors.is_empty():
		summary.status = "defeat"
		summary.loot = {"money": 0, "timber": 0, "iron": 0, "charters": 0, "keepsakes": []}
	else:
		money += int(r.loot.money)
		timber += int(r.loot.timber)
		iron += int(r.loot.iron)
		charters += int(r.loot.charters)
		for k in r.loot.keepsakes:
			if k != "":
				stash.append(k)
		for rd in r.recruits:
			var nh := Hero.from_dict(rd)
			nh.location = r.origin
			if heroes.size() < roster_cap():
				heroes.append(nh)
				summary.recruits.append("%s (%s)" % [nh.hero_name, nh.class_name_text()])
			else:
				# No bunk free: they wait on the Hiring Board (free to hire) instead of leaving.
				var st := settlement(r.origin)
				st["recruits"] = st.get("recruits", [])
				st.recruits.push_front(nh.to_dict())
				st["promised"] = st.get("promised", [])
				st.promised.append(nh.to_dict())
				summary.recruits.append("%s (%s): no room, waiting at the Hiring Board" % [nh.hero_name, nh.class_name_text()])
	if won:
		stats.victories += 1
	var xp_gain := r.xp
	var region_data: Dictionary = DB.regions.get(r.region_id, {})
	if region_data.has("xp_cap"):
		xp_gain = mini(xp_gain, int(region_data.xp_cap))
	for h in survivors:
		var entry := {"uid": h.uid, "name": h.hero_name, "class": h.class_name_text(), "level_before": h.level,
			"xp": xp_gain, "quirks": []}
		h.add_xp(int(round(xp_gain * (1.0 + h.stat("xp_pct") / 100.0))))
		entry["level_after"] = h.level
		h.expeditions += 1
		h.deaths_door = false
		h.shaken = false
		h.hp = h.max_hp()
		h.location = r.origin
		if h.is_second_wind():
			h.fatigue_state = ""
		if rng.randf() * 100.0 < DB.cfg("quirk_roll_chance", 45):
			var pos_chance: int = DB.cfg("quirk_positive_on_win", 60) if won else DB.cfg("quirk_positive_on_loss", 40)
			var q := add_random_quirk(h, rng.randf() * 100.0 < pos_chance)
			if q != "":
				entry.quirks.append(q)
		summary.heroes.append(entry)
	if r.boss_won and DB.regions.get(r.region_id, {}).get("tutorial", false) and summary.status != "defeat":
		summary.story = complete_tutorial()
		summary["tutorial"] = true
	if r.boss_won:
		var site := site_for_region(r.region_id)
		if site >= 0 and not founded(site):
			summary.found_site = site
	# Drinker: some come home and don't leave the saloon for another week.
	var drunk: Array = []
	for h in survivors:
		for q in h.quirks:
			var bar := int(DB.quirks.get(q, {}).get("bar_lock", 0))
			if bar > 0 and h.alive and rng.randf() * 100.0 < bar:
				h.busy_weeks = maxi(h.busy_weeks, 0) + 2
				h.busy_reason = "Drinking at the saloon"
				drunk.append(h.hero_name)
	run = null
	summary.week_msgs = advance_week()
	for n in drunk:
		summary.week_msgs.append("%s heads straight for the saloon and won't come out for a week." % n)
	return summary


# --- Save / load ----------------------------------------------------------------------

func to_dict() -> Dictionary:
	var hs: Array = []
	for h in heroes:
		hs.append(h.to_dict())
	return {"version": 1, "week": week, "money": money, "timber": timber, "iron": iron, "charters": charters,
		"heroes": hs, "dead": dead.duplicate(true), "settlements": settlements.duplicate(true),
		"stash": stash.duplicate(), "known_keys": known_keys.duplicate(true), "beaten": beaten.duplicate(),
		"next_uid": next_uid, "victory_seen": victory_seen,
		"tutorial_done": tutorial_done, "story_flags": story_flags.duplicate(), "missing": missing.duplicate(true), "quest_regions": quest_regions.duplicate(true), "stats": stats.duplicate(),
		"rng_state": str(rng.state), "run": run.to_dict() if run != null else null}


static func from_dict(d: Dictionary) -> Company:
	var c := Company.new()
	c.week = int(d.get("week", 1))
	c.money = int(d.get("money", 0))
	c.timber = int(d.get("timber", 0))
	c.iron = int(d.get("iron", 0))
	c.charters = int(d.get("charters", 0))
	for hd in d.get("heroes", []):
		c.heroes.append(Hero.from_dict(hd))
	c.dead = d.get("dead", []).duplicate(true)
	c.settlements = d.get("settlements", []).duplicate(true)
	c.stash = d.get("stash", []).duplicate()
	c.known_keys = d.get("known_keys", {}).duplicate(true)
	c.beaten = d.get("beaten", []).duplicate()
	c.next_uid = int(d.get("next_uid", 1))
	c.victory_seen = d.get("victory_seen", false)
	c.tutorial_done = d.get("tutorial_done", true)
	c.story_flags = d.get("story_flags", {}).duplicate()
	c.missing = d.get("missing", []).duplicate(true)
	c.quest_regions = d.get("quest_regions", {}).duplicate(true)
	c.register_quest_regions()
	c.stats = d.get("stats", c.stats).duplicate()
	c.rng.randomize()
	if d.has("rng_state"):
		c.rng.state = str(d.rng_state).to_int()
	if d.get("run", null) is Dictionary:
		c.run = RunState.from_dict(d.run, c)
	return c
