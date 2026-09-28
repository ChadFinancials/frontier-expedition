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
		"buildings": start_site.get("start_buildings", {}).duplicate(), "recruits": [], "stock": [], "used": {}}
	settlements.append(st)
	for cid in DB.cfg("start_heroes", []):
		var h := make_hero(cid, 1)
		heroes.append(h)
	_refresh_week()


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
	var c := DB.cls(class_id)
	h.equipped = c.get("default_equipped", []).duplicate()
	var sk_pool: Array = Stats.shuffled(rng, DB.survival.keys())
	for i in 2:
		h.survival[sk_pool[i]] = {"rank": 1, "xp": 0}
	add_random_quirk(h, true)
	add_random_quirk(h, false)
	h.look_seed = rng.randi()
	h.hp = h.max_hp()
	return h


func random_name() -> String:
	var n: Dictionary = DB.names
	var first: String = Stats.pick(rng, n.get("first", ["Sam"]))
	var last: String = Stats.pick(rng, n.get("last", ["Smith"]))
	if rng.randf() < 0.15:
		return "%s \"%s\" %s" % [first, Stats.pick(rng, n.get("nick", ["Kid"])), last]
	return "%s %s" % [first, last]


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
		parts.append("$%d" % int(cost.money))
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
	return costs[lvl]


## "" if allowed, otherwise the reason.
func can_build(i: int, bid: String) -> String:
	var st := settlement(i)
	if st.is_empty():
		return "Not founded"
	var lvl := building_level(i, bid)
	var tier := tier_info(st.tier)
	if lvl == 0 and st.buildings.size() >= int(tier.get("slots", 3)):
		return "No free building plots (upgrade the %s)" % tier.get("name", "settlement")
	if lvl >= int(tier.get("max_level", 1)):
		return "A %s can't support a bigger %s" % [tier.get("name", ""), DB.buildings[bid].name]
	var cost := building_cost(i, bid)
	if cost.is_empty():
		return "Fully upgraded"
	if not can_afford(cost):
		return "Can't afford: " + cost_text(cost)
	return ""


func build(i: int, bid: String) -> bool:
	if can_build(i, bid) != "":
		return false
	pay(building_cost(i, bid))
	settlement(i).buildings[bid] = building_level(i, bid) + 1
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


func slots_left(i: int, bid: String) -> int:
	var lvl := building_level(i, bid)
	if lvl <= 0:
		return 0
	var b: Dictionary = DB.buildings.get(bid, {})
	var cap := 99
	if b.has("slots"):
		cap = int(b.slots[lvl - 1])
	elif b.has("seats"):
		cap = int(b.seats[lvl - 1])
	return cap - int(settlement(i).get("used", {}).get(bid, 0))


func _use_slot(i: int, bid: String) -> void:
	var st := settlement(i)
	st.used[bid] = int(st.used.get(bid, 0)) + 1


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
	if slots_left(i, bid) <= 0:
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
	_use_slot(i, bid)
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
	_use_slot(i, "doctor")
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
	var nl := h.skill_level(sid) + 1
	if nl > DB.cfg("max_skill_level", 4):
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


func equip_keepsake(h: Hero, kid: String) -> bool:
	if not kid in stash or h.keepsakes.size() >= 2:
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
			pool.append({"id": k, "weight": w})
	var pick = Stats.pick_weighted(rng, pool)
	return pick.id if pick != null else ""


# Hiring board --------------------------------------------------------------------------

func hire(i: int, index_in_list: int) -> Hero:
	var st := settlement(i)
	if index_in_list < 0 or index_in_list >= st.get("recruits", []).size():
		return null
	if heroes.size() >= DB.cfg("roster_cap", 24):
		return null
	var h := Hero.from_dict(st.recruits[index_in_list])
	st.recruits.remove_at(index_in_list)
	h.location = i
	heroes.append(h)
	return h


func dismiss(h: Hero) -> void:
	for k in h.keepsakes:
		stash.append(k)
	heroes.erase(h)


# Stage line ----------------------------------------------------------------------------

func can_send(from_i: int, to_i: int, h: Hero) -> String:
	if building_level(from_i, "stage_line") <= 0:
		return "No Stage Line here"
	if not founded(to_i) or to_i == from_i:
		return "No destination"
	if h == null or not h.available() or h.location != from_i:
		return "Hero not available"
	if slots_left(from_i, "stage_line") <= 0:
		return "No seats left this week"
	return ""


func send_hero(from_i: int, to_i: int, h: Hero) -> bool:
	if can_send(from_i, to_i, h) != "":
		return false
	_use_slot(from_i, "stage_line")
	h.transit_to = to_i
	h.transit_weeks = absi(to_i - from_i)
	return true


# Weekly clock --------------------------------------------------------------------------

func advance_week() -> Array:
	var msgs: Array = []
	week += 1
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
	st.recruits = []
	var i := int(st.index)
	var hb := building_level(i, "hiring_board")
	if hb > 0:
		var count := int(DB.buildings.hiring_board.recruits[hb - 1])
		var max_lvl := int(DB.buildings.hiring_board.recruit_level[hb - 1])
		for n in count:
			var lvl := 1
			if max_lvl > 1 and rng.randf() < 0.35:
				lvl = rng.randi_range(2, max_lvl)
			var h := make_hero(Stats.pick(rng, DB.classes.keys()), lvl)
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

func supply_cost(i: int, supplies: Dictionary) -> int:
	var total := 0
	for it in supplies:
		total += item_price(i, it) * int(supplies[it])
	return total


## "" if the party can set out, otherwise why not.
func can_embark(i: int, party_uids: Array, supplies: Dictionary) -> String:
	var site := site_by_index(i)
	if site.get("region_west", "") == "":
		return "There is nowhere further west to go."
	if party_uids.is_empty():
		return "Choose at least one hero."
	if party_uids.size() > 4:
		return "At most four heroes."
	for uid in party_uids:
		var h := hero(uid)
		if h == null or not h.available() or h.location != i:
			return "A chosen hero isn't available."
	if supply_cost(i, supplies) > money:
		return "Can't afford those supplies."
	return ""


func start_run(i: int, party_uids: Array, supplies: Dictionary) -> RunState:
	if can_embark(i, party_uids, supplies) != "":
		return null
	money -= supply_cost(i, supplies)
	var region: String = site_by_index(i).region_west
	run = RunState.create(self, region, i, party_uids, supplies)
	stats.expeditions += 1
	return run


## Settle the finished expedition. status: victory / abandoned / defeat.
func finish_run(status: String) -> Dictionary:
	var r := run
	var summary := {"status": status, "region": r.region_id, "heroes": [], "loot": r.loot.duplicate(true),
		"recruits": [], "boss_won": r.boss_won, "found_site": -1, "week_msgs": []}
	var survivors := r.party_heroes()
	var won := status == "victory"
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
			if heroes.size() < DB.cfg("roster_cap", 24):
				var nh := Hero.from_dict(rd)
				nh.location = r.origin
				heroes.append(nh)
				summary.recruits.append("%s (%s)" % [nh.hero_name, nh.class_name_text()])
	if won:
		stats.victories += 1
	for h in survivors:
		var entry := {"uid": h.uid, "name": h.hero_name, "class": h.class_name_text(), "level_before": h.level,
			"xp": r.xp, "quirks": []}
		h.add_xp(r.xp)
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
	if r.boss_won:
		var site := site_for_region(r.region_id)
		if site >= 0 and not founded(site):
			summary.found_site = site
	run = null
	summary.week_msgs = advance_week()
	return summary


# --- Save / load ----------------------------------------------------------------------

func to_dict() -> Dictionary:
	var hs: Array = []
	for h in heroes:
		hs.append(h.to_dict())
	return {"version": 1, "week": week, "money": money, "timber": timber, "iron": iron, "charters": charters,
		"heroes": hs, "dead": dead.duplicate(true), "settlements": settlements.duplicate(true),
		"stash": stash.duplicate(), "known_keys": known_keys.duplicate(true), "beaten": beaten.duplicate(),
		"next_uid": next_uid, "victory_seen": victory_seen, "stats": stats.duplicate(),
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
	c.stats = d.get("stats", c.stats).duplicate()
	c.rng.randomize()
	if d.has("rng_state"):
		c.rng.state = str(d.rng_state).to_int()
	if d.get("run", null) is Dictionary:
		c.run = RunState.from_dict(d.run, c)
	return c
