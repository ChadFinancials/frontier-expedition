class_name RunState
extends RefCounted
## One expedition along the trail. Holds the map, the wagon, supplies and loot, and all
## the rules for travel, camp, curios, events, caves and trading posts.

var company: Company
var region_id: String = ""
var origin: int = 0
var party: Array = []            # hero uids, rank order
var nodes: Array = []
var current: int = 0
var day: int = 1
var supplies: Dictionary = {}
var wagon: int = 100
var loot: Dictionary = {"money": 0, "timber": 0, "iron": 0, "charters": 0, "keepsakes": []}
var xp: int = 0
var kills: int = 0
var pending_buffs: Array = []    # {stat, value, uid (0 = everyone)}
var recruits: Array = []         # hero dicts that join at the end
var log: Array = []
var status: String = "active"    # active, victory, defeat, abandoned
var boss_won: bool = false
var cave: Dictionary = {}        # {node, room, light} while inside a cave
var camp: Dictionary = {}        # camp phase state
var pending_fight: Dictionary = {} # fight queued by an event/curio/ambush


func _init(c: Company = null) -> void:
	company = c


static func create(c: Company, region: String, origin_index: int, party_uids: Array, supplies_in: Dictionary) -> RunState:
	var r := RunState.new(c)
	r.region_id = region
	r.origin = origin_index
	r.party = party_uids.duplicate()
	r.supplies = supplies_in.duplicate()
	r.wagon = DB.cfg("wagon_max", 100)
	r.nodes = MapGen.generate(region, c.rng, region in c.beaten)
	r.current = 0
	r.reveal_ahead(1)
	for h in r.party_heroes():
		h.deaths_door = false
		h.shaken = false
	r.log.append("The company sets out from %s into %s." % [c.settlement_name(origin_index), r.region().name])
	return r


func region() -> Dictionary:
	return DB.regions.get(region_id, {})


func tier() -> int:
	return int(region().get("tier", 1))


func node(id: int) -> Dictionary:
	return nodes[id] if id >= 0 and id < nodes.size() else {}


func current_node() -> Dictionary:
	return node(current)


func party_heroes() -> Array:
	var out: Array = []
	for uid in party:
		var h: Hero = company.hero(uid)
		if h != null and h.alive:
			out.append(h)
	return out


func in_cave() -> bool:
	return not cave.is_empty()


func add_log(msgs: Variant) -> void:
	if msgs is Array:
		log.append_array(msgs)
	else:
		log.append(str(msgs))
	while log.size() > 200:
		log.pop_front()


# --- Party-wide values ----------------------------------------------------------------

## Best value of a survival passive among living party members (0 if nobody has it).
func party_passive(ptype: String) -> float:
	var best := 0.0
	var found := false
	for h in party_heroes():
		for sid in h.survival:
			var p: Dictionary = DB.survival.get(sid, {}).get("passive", {})
			if p.get("type", "") == ptype:
				var v := float(p.base) + float(p.get("per_rank", 0)) * (int(h.survival[sid].rank) - 1)
				if not found or absf(v) > absf(best):
					best = v
					found = true
	return best


func party_stat_sum(stat: String) -> float:
	var t := 0.0
	for h in party_heroes():
		t += h.stat(stat, {"in_cave": in_cave()})
	return t


func party_loot_pct() -> float:
	var v := party_stat_sum("loot_pct") + party_passive("loot_pct")
	if in_cave():
		v += _light_row().get("loot_pct", 0)
	return v


func _light_row() -> Dictionary:
	var light := int(cave.get("light", 100))
	for r in DB.cfg("light_levels", []):
		if light >= int(r.get("min", 0)):
			return r
	return {}


func light_name() -> String:
	return _light_row().get("name", "")


func describe_events(evs: Array) -> Array:
	var out: Array = []
	for e in evs:
		var h: Hero = company.hero(int(e.get("hero", -1)))
		var nm := h.hero_name if h != null else "Someone"
		var s := Fatigue.describe(e, nm)
		if s != "":
			out.append(s)
		if e.get("t", "") == "death" and h != null:
			_handle_death(h)
	return out


func _handle_death(h: Hero) -> void:
	if h.uid in party:
		party.erase(h.uid)
	company.kill_hero(h, h.death_note)


func heal_hero(h: Hero, pct: int, msgs: Array) -> void:
	if not h.alive:
		return
	var amt := int(ceil(h.max_hp() * pct / 100.0 * (1.0 + h.stat("heal_pct") / 100.0 + party_passive("heal_pct") / 100.0)))
	var before := h.hp
	h.hp = mini(h.max_hp(), h.hp + amt)
	if h.deaths_door and h.hp > 0:
		h.deaths_door = false
		h.shaken = true
	if h.hp > before:
		msgs.append("%s heals %d." % [h.hero_name, h.hp - before])


func change_wagon(amount: int, msgs: Array) -> void:
	var before := wagon
	wagon = clampi(wagon + amount, 0, DB.cfg("wagon_max", 100))
	if wagon != before:
		msgs.append("Wagon %s%d (now %d)." % ["+" if amount > 0 else "", wagon - before, wagon])
	if wagon == 0 and before > 0:
		msgs.append("The wagon is BROKEN. Every stop will be exhausting until it's repaired.")


# --- Map & travel ---------------------------------------------------------------------

func choices() -> Array:
	return current_node().get("next", [])


## Reveal hidden nodes in the next `cols` columns. Returns how many were revealed.
func reveal_ahead(cols: int) -> int:
	var c0 := int(current_node().get("col", 0))
	var n_rev := 0
	for n in nodes:
		if n.col > c0 and n.col <= c0 + cols and n.hidden:
			n.hidden = false
			n_rev += 1
	return n_rev


func food_need() -> int:
	var hs := party_heroes()
	if hs.is_empty():
		return 0
	var pct := 0.0
	for h in hs:
		pct += h.stat("food_pct")
	pct = pct / hs.size() + party_passive("food_pct")
	var need: float = DB.cfg("food_per_move", 2) * (hs.size() / 4.0) * (1.0 + pct / 100.0)
	return maxi(1, int(round(need)))


## Move along the trail. Returns messages. The UI then resolves the node by type.
func travel_to(id: int) -> Array:
	var msgs: Array = []
	if not id in choices():
		return msgs
	current = id
	day += 1
	var n := current_node()
	n.visited = true
	n.hidden = false
	xp += DB.cfg("xp_per_node", 1)
	# Rations.
	var need := food_need()
	var have := int(supplies.get("food", 0))
	if have >= need:
		supplies.food = have - need
	else:
		supplies.food = 0
		msgs.append("Not enough food! The company goes hungry.")
		for h in party_heroes():
			var dmg := maxi(1, int(ceil(h.max_hp() * DB.cfg("hunger_hp_pct", 10) / 100.0)))
			h.hp = maxi(1, h.hp - dmg) if h.hp > 0 else 0
			msgs.append_array(describe_events(Fatigue.add(h, DB.cfg("hunger_fatigue", 10), company.rng)))
	# Broken wagon.
	if wagon <= 0:
		msgs.append("The broken wagon drags and groans.")
		for h in party_heroes():
			msgs.append_array(describe_events(Fatigue.add(h, DB.cfg("broken_wagon_fatigue", 6), company.rng)))
	# Forager passive.
	var forage := party_passive("forage")
	if forage > 0 and company.rng.randf() * 100.0 < forage:
		var f := company.rng.randi_range(1, 3)
		supplies.food = int(supplies.get("food", 0)) + f
		msgs.append("Your forager gathers %d food along the way." % f)
	# Scout passive.
	if party_passive("scout") > 0 or party_stat_sum("scout") >= 20:
		reveal_ahead(1)
	add_log(msgs)
	return msgs


func complete_current() -> void:
	current_node().done = true


func is_final_node() -> bool:
	return current_node().get("type", "") in ["boss", "crossing"]


# --- Combat ---------------------------------------------------------------------------

func surprise_roll(extra_hero_surprise: int = 0) -> String:
	var base := float(DB.cfg("surprise_base", 10))
	var party_bonus := party_stat_sum("surprise") / maxf(1.0, party_heroes().size()) + party_passive("surprise")
	for b in pending_buffs:
		if b.stat == "surprise":
			party_bonus += float(b.value)
	var heroes_surprised := base - party_bonus + extra_hero_surprise
	if in_cave():
		heroes_surprised += _light_row().get("surprise_heroes", 0)
	var enemies_surprised := base + party_bonus
	var r := company.rng.randf() * 100.0
	if r < heroes_surprised:
		return "heroes"
	if r < heroes_surprised + enemies_surprised:
		return "enemies"
	return ""


func combat_options(kind: String, forced_surprise: String = "") -> Dictionary:
	var buffs := {}
	for b in pending_buffs:
		if b.stat == "surprise":
			continue
		var uid := int(b.get("uid", 0))
		if not buffs.has(uid):
			buffs[uid] = []
		buffs[uid].append({"stat": b.stat, "value": b.value, "name": "Prepared"})
	var surprise := forced_surprise
	if surprise == "" and kind != "boss" and kind != "crossing":
		surprise = surprise_roll()
	return {"rng": company.rng, "in_cave": in_cave(), "light": int(cave.get("light", 100)), "tier": tier(),
		"boss": kind == "boss", "surprise": surprise, "start_buffs": buffs}


## Called when a fight ends (any result). Updates party order, deaths, loot and XP.
func after_combat(engine: CombatEngine, kind: String, reward: Dictionary = {}) -> Dictionary:
	var res := {"result": engine.state, "money": 0, "timber": 0, "iron": 0, "charters": 0, "keepsakes": [], "msgs": []}
	pending_buffs.clear()
	# Party order follows the battle's final formation.
	var order: Array = []
	for c in engine.heroes:
		order.append(c.hero.uid)
	for uid in party:
		if not uid in order:
			var h: Hero = company.hero(uid)
			if h != null and h.alive:
				order.append(uid)
	for uid in engine.fallen:
		var h: Hero = company.hero(uid)
		if h != null:
			res.msgs.append("%s has fallen. (%s)" % [h.hero_name, h.death_note])
			_handle_death(h)
	party = order.filter(func(u): return company.hero(u) != null and company.hero(u).alive)
	if in_cave():
		cave.light = engine.light
	kills += engine.killed.size()
	company.stats.kills += engine.killed.size()
	if engine.state != "victory":
		return res
	# Loot.
	var rng := company.rng
	var mult := 1.0 + party_loot_pct() / 100.0
	var em: Array = DB.cfg("enemy_money", [8, 20])
	var money := 0
	for eid in engine.killed:
		money += rng.randi_range(int(em[0]), int(em[1])) * tier()
	money = int(round(money * mult))
	if kind == "elite":
		xp += DB.cfg("xp_elite", 2)
		var et: Array = DB.cfg("elite_timber", [2, 5])
		var ei: Array = DB.cfg("elite_iron", [1, 3])
		res.timber = rng.randi_range(int(et[0]), int(et[1]))
		res.iron = rng.randi_range(int(ei[0]), int(ei[1]))
		if rng.randf() * 100.0 < DB.cfg("elite_keepsake_chance", 35):
			res.keepsakes.append(company.random_keepsake())
		if rng.randf() < 0.12:
			res.charters = 1
	if kind == "boss":
		xp += DB.cfg("xp_boss", 6)
		money += DB.cfg("boss_money", 400) * tier()
		var first := not region_id in company.beaten
		res.charters = 2 if first else 1
		var bk: String = region().get("boss", {}).get("keepsake", "")
		res.keepsakes.append(bk if first and bk != "" else company.random_keepsake(["rare", "uncommon"]))
		boss_won = true
		if first:
			company.beaten.append(region_id)
	if kind == "crossing":
		xp += DB.cfg("xp_elite", 2) + 2
		money += int(DB.cfg("boss_money", 400) * tier() / 3.0)
		res.charters = 1
		res.keepsakes.append(company.random_keepsake(["uncommon", "rare"]))
		boss_won = true
	if reward.has("money"):
		money += int(reward.money)
	if reward.get("keepsake", false):
		res.keepsakes.append(company.random_keepsake())
	res.money = money
	loot.money = int(loot.money) + money
	loot.timber = int(loot.timber) + res.timber
	loot.iron = int(loot.iron) + res.iron
	loot.charters = int(loot.charters) + res.charters
	for k in res.keepsakes:
		if k != "":
			loot.keepsakes.append(k)
	return res


# --- Items ----------------------------------------------------------------------------

func can_use_item(item_id: String) -> bool:
	var it: Dictionary = DB.items.get(item_id, {})
	return int(supplies.get(item_id, 0)) > 0 and it.get("use", null) != null


## Use a supply outside combat on a hero (or on the wagon/lamp).
func use_item(item_id: String, h: Hero) -> Array:
	var msgs: Array = []
	if not can_use_item(item_id):
		return msgs
	var use: Dictionary = DB.items[item_id].use
	match use.type:
		"heal_pct":
			if h == null:
				return msgs
			heal_hero(h, int(use.value), msgs)
		"fatigue":
			if h == null:
				return msgs
			msgs.append_array(describe_events(Fatigue.add(h, int(use.amount), company.rng)))
		"wagon":
			if wagon >= DB.cfg("wagon_max", 100):
				return ["The wagon doesn't need repairs."]
			change_wagon(int(use.amount), msgs)
		"light":
			if not in_cave():
				return ["Lamp oil is only useful in the dark."]
			cave.light = clampi(int(cave.light) + int(use.amount), 0, 100)
			msgs.append("Lamplight +%d." % int(use.amount))
	supplies[item_id] = int(supplies[item_id]) - 1
	add_log(msgs)
	return msgs


# --- Curios ---------------------------------------------------------------------------

## A hero whose quirk forces them to grab this curio, or null.
func compulsion_for(curio_id: String) -> Dictionary:
	var tags: Array = DB.curios.get(curio_id, {}).get("tags", [])
	for h in party_heroes():
		for q in h.quirks:
			var comp: Dictionary = DB.quirks.get(q, {}).get("compulsion", {})
			if not comp.is_empty() and comp.tag in tags and company.rng.randf() * 100.0 < float(comp.chance):
				return {"hero": h, "text": "%s %s!" % [h.hero_name, comp.text]}
	return {}


## item_id "" = by hand. Returns {"text", "msgs", "fight", "key_worked"}.
func interact_curio(curio_id: String, h: Hero, item_id: String = "") -> Dictionary:
	var cu: Dictionary = DB.curios.get(curio_id, {})
	var out := {"text": "", "msgs": [], "fight": null, "key_worked": false}
	var outcome: Dictionary
	if item_id != "" and cu.get("keys", {}).has(item_id) and int(supplies.get(item_id, 0)) > 0:
		supplies[item_id] = int(supplies[item_id]) - 1
		outcome = cu.keys[item_id]
		out.key_worked = true
		if not company.known_keys.has(curio_id):
			company.known_keys[curio_id] = []
		if not item_id in company.known_keys[curio_id]:
			company.known_keys[curio_id].append(item_id)
	elif item_id != "":
		supplies[item_id] = maxi(0, int(supplies.get(item_id, 0)) - 1)
		out.text = "Using %s on the %s does nothing useful." % [DB.items[item_id].name, cu.name]
		add_log(out.text)
		return out
	else:
		outcome = Stats.pick_weighted(company.rng, cu.get("hand", []))
	out.text = str(outcome.get("text", "")).replace("{hero}", h.hero_name)
	var res := Effects.apply(outcome.get("effects", []), self, h)
	out.msgs = res.msgs
	out.fight = res.fight
	add_log([out.text] + out.msgs)
	return out


# --- Events ---------------------------------------------------------------------------

func event_actor(req: Dictionary) -> Hero:
	var hs := party_heroes()
	if req.has("skill"):
		var best: Hero = null
		for h in hs:
			if h.survival.has(req.skill) and (best == null or h.survival_rank(req.skill) > best.survival_rank(req.skill)):
				best = h
		return best
	if req.has("class"):
		for h in hs:
			if h.class_id == req["class"]:
				return h
		return null
	if req.has("quirk"):
		for h in hs:
			if req.quirk in h.quirks:
				return h
		return null
	return Stats.pick(company.rng, hs)


## Options with availability for the UI.
func event_options(event_id: String) -> Array:
	var ev: Dictionary = DB.events.get(event_id, {})
	var out: Array = []
	var i := 0
	for opt in ev.get("options", []):
		var req: Dictionary = opt.get("requires", {})
		var ok := true
		var tag := ""
		if req.has("item"):
			var need := int(opt.get("consume", {}).get("item", 1))
			ok = ok and int(supplies.get(req.item, 0)) >= need
			tag = "[%s]" % DB.items.get(req.item, {}).get("name", req.item)
		if req.has("money"):
			ok = ok and (company.money + int(loot.money)) >= int(req.money)
		if req.has("skill"):
			ok = ok and event_actor(req) != null
			tag = "[%s]" % DB.survival.get(req.skill, {}).get("name", req.skill)
		if req.has("class"):
			ok = ok and event_actor(req) != null
			tag = "[%s]" % DB.classes.get(req["class"], {}).get("name", req["class"])
		if req.has("quirk"):
			ok = ok and event_actor(req) != null
			tag = "[%s]" % DB.quirks.get(req.quirk, {}).get("name", req.quirk)
		out.append({"index": i, "text": opt.text, "tag": tag, "available": ok,
			"hidden": not ok and (req.has("skill") or req.has("class") or req.has("quirk"))})
		i += 1
	return out


## Returns {"text", "msgs", "fight"}.
func choose_event_option(event_id: String, idx: int) -> Dictionary:
	var ev: Dictionary = DB.events.get(event_id, {})
	var opt: Dictionary = ev.options[idx]
	var req: Dictionary = opt.get("requires", {})
	var actor := event_actor(req)
	if actor == null:
		actor = Stats.pick(company.rng, party_heroes())
	var consume: Dictionary = opt.get("consume", {})
	if consume.has("item") and req.has("item"):
		supplies[req.item] = maxi(0, int(supplies.get(req.item, 0)) - int(consume.item))
	if consume.has("money"):
		var m := int(consume.money)
		var from_loot := mini(m, int(loot.money))
		loot.money = int(loot.money) - from_loot
		company.money = maxi(0, company.money - (m - from_loot))
	# Weighted outcome; survival passives favour good outcomes.
	var outcomes: Array = []
	var bonus := party_passive("river_bonus") if event_id in ["river_crossing", "flash_flood"] else 0.0
	if event_id in ["hunting_grounds", "buffalo_herd"]:
		bonus += party_passive("hunt_bonus")
	for oc in opt.get("outcomes", []):
		var w := float(oc.get("weight", 1))
		if oc.get("good", false):
			w += bonus
		outcomes.append({"oc": oc, "weight": w})
	var picked: Dictionary = Stats.pick_weighted(company.rng, outcomes).oc
	var text := str(picked.get("text", "")).replace("{hero}", actor.hero_name if actor != null else "Someone")
	var res := Effects.apply(picked.get("effects", []), self, actor)
	add_log([text] + res.msgs)
	return {"text": text, "msgs": res.msgs, "fight": res.fight}


func event_text(event_id: String) -> String:
	var ev: Dictionary = DB.events.get(event_id, {})
	var actor: Hero = Stats.pick(company.rng, party_heroes())
	return str(ev.get("text", "")).replace("{hero}", actor.hero_name if actor != null else "Someone")


# --- Camp -----------------------------------------------------------------------------

func camp_start() -> void:
	camp = {"hours": DB.cfg("camp_hours", 12), "used": {}, "meal": "", "no_ambush": false}


func camp_meal(meal_id: String) -> Array:
	var msgs: Array = []
	var meal: Dictionary = {}
	for m in DB.cfg("meals", []):
		if m.id == meal_id:
			meal = m
	if meal.is_empty() or camp.get("meal", "") != "":
		return msgs
	var hs := party_heroes()
	var cost := int(ceil(int(meal.food) * hs.size() / 4.0))
	if int(supplies.get("food", 0)) < cost:
		return ["Not enough food for that."]
	supplies.food = int(supplies.get("food", 0)) - cost
	camp.meal = meal_id
	msgs.append("%s. (%d food)" % [meal.name, cost])
	for h in hs:
		if int(meal.heal_pct) > 0:
			heal_hero(h, int(meal.heal_pct), msgs)
		if int(meal.fatigue) != 0:
			msgs.append_array(describe_events(Fatigue.add(h, int(meal.fatigue), company.rng)))
	add_log(msgs)
	return msgs


## Every camp action the party can still take: {uid, skill, action, hours, rank, available}
func camp_actions() -> Array:
	var out: Array = []
	for h in party_heroes():
		for sid in h.survival:
			var sk: Dictionary = DB.survival.get(sid, {})
			for a in sk.get("actions", []):
				var used: bool = a.id in camp.used.get(str(h.uid), [])
				out.append({"uid": h.uid, "skill": sid, "action": a, "hours": int(a.hours),
					"rank": int(h.survival[sid].rank), "available": not used and int(a.hours) <= int(camp.hours), "used": used})
	return out


func camp_act(uid: int, action_id: String, target_uid: int = -1) -> Array:
	var h: Hero = company.hero(uid)
	if h == null:
		return []
	var action: Dictionary = {}
	var sid := ""
	for s in h.survival:
		for a in DB.survival.get(s, {}).get("actions", []):
			if a.id == action_id:
				action = a
				sid = s
	if action.is_empty() or int(action.hours) > int(camp.hours):
		return []
	var key := str(uid)
	if not camp.used.has(key):
		camp.used[key] = []
	if action_id in camp.used[key]:
		return []
	camp.used[key].append(action_id)
	camp.hours = int(camp.hours) - int(action.hours)
	var target: Hero = company.hero(target_uid) if target_uid >= 0 else h
	var effects: Array = []
	for e in action.get("effects", []):
		var e2: Dictionary = e.duplicate(true)
		if not e2.has("target"):
			match action.get("target", "party"):
				"self":
					e2.target = "actor"
				"ally":
					e2.target = "ally"
				_:
					e2.target = "party"
		effects.append(e2)
	var rank := int(h.survival[sid].rank)
	var msgs: Array = ["%s: %s." % [h.hero_name, action.name]]
	var res := Effects.apply(effects, self, h, target, rank)
	msgs.append_array(res.msgs)
	# Survival skills rank up with use.
	var st: Dictionary = h.survival[sid]
	st.xp = int(st.xp) + 1
	var thresholds := [0, 3, 8]
	if int(st.rank) < 3 and int(st.xp) >= thresholds[int(st.rank)]:
		st.rank = int(st.rank) + 1
		msgs.append("%s's %s skill improves to rank %d!" % [h.hero_name, DB.survival[sid].name, st.rank])
	add_log(msgs)
	return msgs


## Ends the camp. Returns {"ambush": bool}. The ambush fight is queued in pending_fight.
func camp_end() -> Dictionary:
	var ambush := false
	if not camp.get("no_ambush", false):
		ambush = company.rng.randf() * 100.0 < DB.cfg("camp_ambush_chance", 20)
	if ambush:
		pending_fight = {"enemies": MapGen.roll_group(company.rng, region().fights), "surprise": "heroes", "kind": "fight"}
		add_log("Night ambush!")
	camp = {}
	return {"ambush": ambush}


# --- Caves ----------------------------------------------------------------------------

func cave_enter() -> void:
	cave = {"node": current, "room": 0, "light": DB.cfg("light_start", 100)}
	add_log("The company lights the lamps and heads into the %s." % current_node().data.get("name", "cave"))


func cave_rooms() -> Array:
	return node(int(cave.get("node", current))).get("data", {}).get("rooms", [])


func cave_room() -> Dictionary:
	var rooms := cave_rooms()
	var i := int(cave.get("room", 0))
	return rooms[i] if i < rooms.size() else {}


## Walk into the next room: light drops and darkness wears on the party.
func cave_advance() -> Array:
	var msgs: Array = []
	cave.room = int(cave.room) + 1
	cave.light = maxi(0, int(cave.light) - DB.cfg("light_per_room", 20))
	var f := int(_light_row().get("fatigue", 2))
	for h in party_heroes():
		msgs.append_array(describe_events(Fatigue.add(h, f, company.rng, {"in_cave": true})))
	msgs.append("Lamplight: %d (%s)." % [cave.light, light_name()])
	add_log(msgs)
	return msgs


func cave_done() -> bool:
	return int(cave.get("room", 0)) >= cave_rooms().size()


func cave_treasure() -> Array:
	var msgs: Array = ["The deepest chamber holds a forgotten stash!"]
	var rng := company.rng
	var m := int(round(rng.randi_range(60, 120) * tier() * (1.0 + party_loot_pct() / 100.0)))
	loot.money = int(loot.money) + m
	msgs.append("+$%d." % m)
	var ir := rng.randi_range(1, 3)
	loot.iron = int(loot.iron) + ir
	msgs.append("+%d Iron." % ir)
	if rng.randf() < 0.6:
		var k := company.random_keepsake()
		loot.keepsakes.append(k)
		msgs.append("Found a keepsake: %s!" % DB.keepsakes[k].name)
	add_log(msgs)
	return msgs


func cave_exit() -> void:
	add_log("The company climbs back into daylight.")
	cave = {}


# --- Trading post ---------------------------------------------------------------------

func trade_price(item_id: String) -> int:
	return int(ceil(int(DB.items[item_id].price) * float(current_node().data.get("markup", 1.5))))


func trade_buy(item_id: String) -> bool:
	var stock: Dictionary = current_node().data.get("stock", {})
	if int(stock.get(item_id, 0)) <= 0:
		return false
	var price := trade_price(item_id)
	if int(loot.money) + company.money < price:
		return false
	var from_loot := mini(price, int(loot.money))
	loot.money = int(loot.money) - from_loot
	company.money -= price - from_loot
	stock[item_id] = int(stock[item_id]) - 1
	supplies[item_id] = int(supplies.get(item_id, 0)) + 1
	return true


# --- Save / load ----------------------------------------------------------------------

const FIELDS := ["region_id", "origin", "party", "nodes", "current", "day", "supplies", "wagon", "loot",
	"xp", "kills", "pending_buffs", "recruits", "log", "status", "boss_won", "cave", "camp", "pending_fight"]


func to_dict() -> Dictionary:
	var d := {}
	for f in FIELDS:
		var v = get(f)
		d[f] = v.duplicate(true) if (v is Array or v is Dictionary) else v
	return d


static func from_dict(d: Dictionary, c: Company) -> RunState:
	var r := RunState.new(c)
	for f in FIELDS:
		if d.has(f):
			var v = d[f]
			r.set(f, v.duplicate(true) if (v is Array or v is Dictionary) else v)
	return r
