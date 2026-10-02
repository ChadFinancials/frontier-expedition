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
var loot: Dictionary = {"money": 0, "timber": 0, "iron": 0, "hides": 0, "charters": 0, "keepsakes": []}
var followup: Dictionary = {}      # a follow-up choice an event outcome opened ("then"): {event, text, options}
var xp: int = 0
var kills: int = 0
var pending_buffs: Array = []    # {stat, value, uid (0 = everyone)}
var recruits: Array = []         # hero dicts that join at the end
var log: Array = []
var status: String = "active"    # active, victory, defeat, abandoned
var boss_won: bool = false
var driven_back: bool = false    # a boss's scripted first meeting sent the company home
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
	r.look_ahead()
	for h in r.party_heroes():
		h.deaths_door = false
		h.shaken = false
	if r.region().get("tutorial", false):
		r.log.append("The company rides %s toward %s." % [r.region().name, c.settlement_name(origin_index)])
	else:
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


## How far along the map the company is: 0 at the first column, 1 at the last.
func map_progress() -> float:
	var max_col: int = 1
	for n: Dictionary in nodes:
		max_col = maxi(max_col, int(n.get("col", 0)))
	return float(int(current_node().get("col", 0))) / float(max_col)


## Swap two heroes' places in the marching order (party index = rank - 1), outside combat.
func swap_party(i: int, j: int) -> void:
	var alive: Array = party.filter(func(u): return company.hero(u) != null and company.hero(u).alive)
	if i < 0 or j < 0 or i >= alive.size() or j >= alive.size() or i == j:
		return
	var a: int = party.find(alive[i])
	var b: int = party.find(alive[j])
	var t = party[a]
	party[a] = party[b]
	party[b] = t


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
		v += _light_row().get("loot_pct", 0) + cave_class_loot()
	return v


## Class edges in caves (classes.json "cave_loot_pct", the Prospector's nose for ore).
func cave_class_loot() -> float:
	var v := 0.0
	for h in party_heroes():
		v += float(h.cls().get("cave_loot_pct", 0))
	return v


func _light_row() -> Dictionary:
	var light := int(cave.get("light", 100))
	for r in DB.cfg("light_levels", []):
		if light >= int(r.get("min", 0)):
			return r
	return {}


func light_name() -> String:
	return _light_row().get("name", "")


## What the current lamplight does, in one line for the cave HUD.
func light_effects() -> String:
	var r := _light_row()
	var parts: Array = []
	if int(r.get("enemy_dmg", 0)) != 0:
		parts.append("Enemies +%d%% damage" % int(r.enemy_dmg))
	if DB.cfg("hero_ambush", true) and int(r.get("surprise_heroes", 0)) != 0:
		parts.append("Ambush %+d%%" % int(r.surprise_heroes))
	if int(r.get("hero_crit", 0)) != 0:
		parts.append("Heroes +%d%% crit" % int(r.hero_crit))
	var loot := int(r.get("loot_pct", 0)) + int(cave_class_loot())
	if loot != 0:
		parts.append("Loot +%d%%" % loot)
	parts.append("%d Fatigue per room" % int(r.get("fatigue", 2)))
	return ", ".join(parts)


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
	if amount > 0 and before >= DB.cfg("wagon_max", 100):
		msgs.append("The wagon is already in good repair.")
	if wagon != before:
		msgs.append("Wagon %s%d (now %d)." % ["+" if amount > 0 else "", wagon - before, wagon])
	if wagon == 0 and before > 0:
		msgs.append("The wagon is BROKEN. Every stop will be exhausting until it's repaired.")


# --- Map & travel ---------------------------------------------------------------------

func choices() -> Array:
	return current_node().get("next", [])


## Scout up to `count` stops ahead to `level` (2 = type, 3 = details), nearest first:
## stops you can ride to next, then the ones beyond. Returns how many became clearer.
func reveal_ahead(count: int, level: int = 3) -> int:
	var c0 := int(current_node().get("col", 0))
	var y0 := float(current_node().get("y", 0.5))
	var reach := choices()
	var cands: Array = nodes.filter(func(n): return int(n.col) > c0 and MapGen.intel(n) < level)
	cands.sort_custom(func(a, b):
		var ka := [0 if a.id in reach else 1, int(a.col), absf(float(a.y) - y0)]
		var kb := [0 if b.id in reach else 1, int(b.col), absf(float(b.y) - y0)]
		return ka < kb)
	var n_rev := 0
	for n in cands.slice(0, maxi(0, count)):
		n.intel = level
		n_rev += 1
	return n_rev


## The party's eye for the trail: quirks, keepsakes and survival skills.
func scout_score() -> float:
	return party_stat_sum("scout") + party_passive("scout")


## Called on arrival: the next stops come into view, more clearly with good scouts.
func look_ahead() -> Array:
	var msgs: Array = []
	var c0 := int(current_node().get("col", 0))
	var score := scout_score()
	var tracker := party_passive("surprise") > 0
	var spotted := 0
	for n in nodes:
		var d := int(n.col) - c0
		if d == 1:
			n.intel = maxi(MapGen.intel(n), 1)
			if MapGen.intel(n) < 2 and company.rng.randf() * 100.0 < 20.0 + score:
				n.intel = 2
				spotted += 1
			if MapGen.intel(n) == 2 and tracker and n.type in ["fight", "elite"]:
				n.intel = 3
		elif d == 2 and MapGen.intel(n) < 1 and not region().has("fixed_map") and company.rng.randf() * 100.0 < score / 2.0:
			n.intel = 1
	if spotted > 0 and score >= 30:
		msgs.append("Your scouts get a good look at what lies ahead.")
	return msgs


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
	var surprised_by_decoy: bool = n.get("decoy", false) and MapGen.intel(n) < 2
	n.visited = true
	n.intel = 3
	if surprised_by_decoy:
		msgs.append("It looked quiet from a distance. It wasn't.")
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
		f = add_supply("food", f)
		if f > 0:
			msgs.append("Your forager gathers %d food along the way." % f)
	# Wear and tear on the wagon.
	var wear := company.rng.randi_range(int(DB.cfg("wagon_wear", [2, 5])[0]), int(DB.cfg("wagon_wear", [2, 5])[1]))
	wear = int(round(wear * (1.0 - party_passive("wagon_guard") / 100.0)))
	if wear > 0 and wagon > 0:
		var wmsgs: Array = []
		change_wagon(-wear, wmsgs)
		if wagon < 40:
			msgs.append_array(wmsgs)
		else:
			log.append("Rough trail: the wagon takes %d wear." % wear)
	# Mishaps on the road.
	if not region().get("tutorial", false) and company.rng.randf() * 100.0 < DB.cfg("mishap_chance", 15):
		msgs.append_array(_mishap())
	msgs.append_array(look_ahead())
	add_log(msgs)
	return msgs


## Everything in the wagon: supplies plus the Timber and Iron found on the trail.
func cargo() -> Dictionary:
	var c := supplies.duplicate()
	c["timber"] = int(loot.get("timber", 0))
	c["iron"] = int(loot.get("iron", 0))
	c["hides"] = int(loot.get("hides", 0))
	return c


## Loads Timber or Iron into the wagon, as much as fits. Returns how much was taken.
func add_material(kind: String, n: int) -> int:
	var got := mini(n, Inventory.room_for(cargo(), kind))
	if got > 0:
		loot[kind] = int(loot.get(kind, 0)) + got
	return got


## Adds supplies up to what the wagon can hold. Returns how many were added.
func add_supply(item: String, n: int) -> int:
	var add := mini(n, Inventory.room_for(cargo(), item))
	if add > 0:
		supplies[item] = int(supplies.get(item, 0)) + add
	return add


## Small misfortunes of the road. A hero with the right skill or class prevents them;
## otherwise the listed supply is used up if you have it, or the company pays the price.
func _mishap() -> Array:
	var m: Dictionary = Stats.pick_weighted(company.rng, DB.cfg("mishaps", []))
	if m == null or m.is_empty():
		return []
	var msgs: Array = []
	var prevent: Dictionary = m.get("prevent", {})
	var saver: Hero = null
	if prevent.has("skill") or prevent.has("class"):
		saver = event_actor(prevent)
	if saver != null:
		msgs.append(str(m.get("saved", "")).replace("{hero}", saver.hero_name))
		return msgs
	var item: String = m.get("item", "")
	if item != "" and int(supplies.get(item, 0)) > 0:
		supplies[item] = int(supplies[item]) - 1
		msgs.append(str(m.get("used_item", "")).replace("{item}", DB.items[item].name))
		return msgs
	var victim: Hero = Stats.pick(company.rng, party_heroes())
	msgs.append(str(m.text).replace("{hero}", victim.hero_name if victim != null else "someone"))
	var res := Effects.apply(m.get("effects", []), self, victim)
	msgs.append_array(res.msgs)
	return msgs


func complete_current() -> void:
	current_node().done = true


func is_final_node() -> bool:
	return current_node().get("type", "") in ["boss", "crossing"]


# --- Combat ---------------------------------------------------------------------------

func surprise_roll(extra_hero_surprise: int = 0) -> String:
	if region().get("no_ambush", false):
		return ""
	var base := float(DB.cfg("surprise_base", 10))
	var party_bonus := party_stat_sum("surprise") / maxf(1.0, party_heroes().size()) + party_passive("surprise")
	for b in pending_buffs:
		if b.stat == "surprise":
			party_bonus += float(b.value)
	var heroes_surprised := base - party_bonus + extra_hero_surprise
	if in_cave():
		heroes_surprised += _light_row().get("surprise_heroes", 0)
	# Enemies catching the party off guard is switched off for now (owner, round 6); it may
	# come back tied to the wagon. The party can still catch enemies napping.
	if not DB.cfg("hero_ambush", true):
		heroes_surprised = 0.0
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
	if surprise == "heroes" and not DB.cfg("hero_ambush", true):
		surprise = ""
	if surprise == "" and kind != "boss" and kind != "crossing":
		surprise = surprise_roll()
	var opts := {"rng": company.rng, "in_cave": in_cave(), "light": int(cave.get("light", 100)), "tier": tier(),
		"boss": kind == "boss", "surprise": surprise, "start_buffs": buffs}
	# A boss's scripted first meeting, and the wound it carries into the next one.
	var script: Dictionary = region().get("boss", {}).get("first_script", {})
	if kind == "boss" and not script.is_empty() and not region_id in company.beaten:
		if company.story_flags.has(script.id):
			opts["wounded"] = {script.unit: int(script.get("wound_pct", 100))}
		else:
			opts["script"] = script
	return opts


## The boss intro text, which changes after a scripted first meeting.
func boss_intro() -> String:
	var b: Dictionary = region().get("boss", {})
	var script: Dictionary = b.get("first_script", {})
	if not script.is_empty() and company.story_flags.has(script.id) and b.has("intro_again"):
		return b.intro_again
	return b.get("intro", "")


## Called when a fight ends (any result). Updates party order, deaths, loot and XP.
func after_combat(engine: CombatEngine, kind: String, reward: Dictionary = {}) -> Dictionary:
	var res := {"result": engine.state, "money": 0, "timber": 0, "iron": 0, "hides": 0, "charters": 0, "keepsakes": [], "msgs": []}
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
	if engine.state == "scripted":
		company.story_flags[engine.story_script.id] = true
		driven_back = true
		xp += int(DB.cfg("xp_boss", 6) / 2.0)
		return res
	# Quirks that cost something after every fight (Homesick).
	if engine.state in ["victory", "fled"]:
		for h in party_heroes():
			for q in h.quirks:
				var af := int(DB.quirks.get(q, {}).get("after_battle_fatigue", 0))
				if af != 0:
					Fatigue.add(h, af, company.rng)
	if engine.state != "victory":
		return res
	# Loot.
	var rng := company.rng
	var mult := 1.0 + party_loot_pct() / 100.0
	var em: Array = DB.cfg("enemy_money", [8, 20])
	var money := engine.bounty
	for eid in engine.killed:
		money += rng.randi_range(int(em[0]), int(em[1])) * tier()
		# Beasts can be skinned: "hides": [chance %, min, max] on the enemy.
		var hd: Array = DB.enemy(eid).get("hides", [])
		if hd.size() == 3 and rng.randf() * 100.0 < float(hd[0]):
			res.hides += rng.randi_range(int(hd[1]), int(hd[2]))
	money = int(round(money * mult * float(DB.cfg("chips_mult", 1.0))))
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
	var quest: bool = region().get("quest", false)
	if quest and kind in ["boss", "crossing"]:
		# A chatter quest: its rumored rewards, paid once the last fight is won.
		xp += DB.cfg("xp_elite", 2) + (3 if kind == "boss" else 1)
		var qr: Dictionary = region().get("quest_reward", {})
		money += int(qr.get("money", 0))
		res.timber += int(qr.get("timber", 0))
		res.iron += int(qr.get("iron", 0))
		res.hides += int(qr.get("hides", 0))
		if str(qr.get("trinket", "")) != "":
			res.keepsakes.append(company.random_keepsake([qr.trinket]))
		if int(qr.get("recruit", 0)) > 0:
			var nh := company.make_hero(Stats.pick(company.rng, DB.classes.keys()), int(qr.recruit))
			nh.location = origin
			recruits.append(nh.to_dict())
			res.msgs.append("%s the %s asks to ride with you, and will join when you return." % [nh.hero_name, nh.class_name_text()])
		boss_won = true
		if kind == "boss":
			var flag: String = region().get("done_flag", "")
			if flag != "":
				company.story_flags[flag] = true
			if str(region().get("boss_keepsake", "")) != "":
				res.keepsakes.append(region().boss_keepsake)
	elif kind == "boss":
		xp += DB.cfg("xp_boss", 6)
		var br: Dictionary = region().get("boss_rewards", {})
		money += int(br.get("money", DB.cfg("boss_money", 400) * tier()) * float(DB.cfg("chips_mult", 1.0)))
		var first := not region_id in company.beaten
		res.charters = int(br.get("charters", 2 if first else 1))
		res.timber += int(br.get("timber", 0))
		res.iron += int(br.get("iron", 0))
		res.hides += int(br.get("hides", 0))
		var bk: String = region().get("boss", {}).get("keepsake", "")
		res.keepsakes.append(bk if first and bk != "" else company.random_keepsake(["rare", "uncommon"]))
		boss_won = true
		if first:
			company.beaten.append(region_id)
			# A side adventure's first clear: a new hand joins, plus its materials.
			var sr: Dictionary = region().get("side_reward", {})
			if not sr.is_empty():
				if sr.get("rescue", false) and not company.missing.is_empty():
					var md: Dictionary = company.missing.pop_front()
					md.location = origin
					recruits.append(md)
					res.msgs.append(str(sr.get("text", "")).replace("{name}", str(md.hero_name)))
					res.msgs.append("%s rejoins the company." % md.hero_name)
				if sr.has("hero"):
					var hd: Dictionary = sr.hero
					var nh := company.make_hero(hd.get("class", "marshal"), int(hd.get("level", 1)))
					if hd.has("name"):
						nh.hero_name = hd.name
					company.add_random_quirk(nh, true)
					nh.location = origin
					recruits.append(nh.to_dict())
					res.msgs.append(str(sr.get("text", "")))
					res.msgs.append("%s the %s will join the company when you return." % [nh.hero_name, nh.class_name_text()])
				res.timber += int(sr.get("timber", 0))
				res.iron += int(sr.get("iron", 0))
				res.hides += int(sr.get("hides", 0))
	if kind == "crossing" and not quest:
		xp += DB.cfg("xp_elite", 2) + 2
		money += int(DB.cfg("boss_money", 400) * tier() / 3.0 * float(DB.cfg("chips_mult", 1.0)))
		res.charters = 1
		res.keepsakes.append(company.random_keepsake(["uncommon", "rare"]))
		boss_won = true
	if reward.has("money"):
		money += int(int(reward.money) * float(DB.cfg("chips_mult", 1.0)))
	if reward.get("keepsake", false):
		res.keepsakes.append(company.random_keepsake())
	res.money = maxi(0, money)
	loot.money = maxi(0, int(loot.money) + money)
	for mat in ["timber", "iron", "hides"]:
		var want := int(res[mat])
		var got := add_material(mat, want)
		res[mat] = got
		if got < want:
			res.msgs.append("No room in the wagon for %d more %s; it's left behind." % [want - got, mat.capitalize()])
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

## Loot a Gold Fever hero keeps for themself.
const STOLEN := ["money", "money_pct", "keepsake", "timber", "iron", "hides", "charters"]


func _steals(h: Hero, cu: Dictionary) -> bool:
	for q in h.quirks:
		var comp: Dictionary = DB.quirks.get(q, {}).get("compulsion", {})
		if comp.get("steals", false) and comp.get("tag", "") in cu.get("tags", []):
			return true
	return false


## A hero whose quirk forces them to grab this curio, or null.
func compulsion_for(curio_id: String) -> Dictionary:
	var tags: Array = DB.curios.get(curio_id, {}).get("tags", [])
	for h in party_heroes():
		for q in h.quirks:
			var comp: Dictionary = DB.quirks.get(q, {}).get("compulsion", {})
			if not comp.is_empty() and comp.tag in tags and company.rng.randf() * 100.0 < float(comp.chance):
				return {"hero": h, "text": "%s %s!" % [h.hero_name, comp.text]}
	return {}


## The curio experts that apply to this hero: their class and any survival skill the curio
## lists. Each is {"id", "name", "odds", "e"}: odds > 0 makes the bad outcomes that much (%)
## less likely, odds < 0 (averse) more likely.
func curio_experts(curio_id: String, h: Hero) -> Array:
	var out := []
	var ex: Dictionary = DB.curios.get(curio_id, {}).get("experts", {})
	for id in ex:
		var e: Dictionary = ex[id]
		var odds := 0
		var label := ""
		if id == h.class_id:
			label = DB.classes[id].name
			odds = int(e.get("odds", DB.cfg("curio_class_odds", 50)))
		elif h.survival.has(id):
			var rank := h.survival_rank(id)
			label = "%s %d" % [DB.survival[id].name, rank]
			var table: Array = DB.cfg("curio_skill_odds", [20, 35, 50])
			odds = int(e.get("odds", table[clampi(rank - 1, 0, table.size() - 1)]))
		else:
			continue
		if e.get("averse", false):
			odds = -int(DB.cfg("curio_averse_odds", 50))
		out.append({"id": id, "name": label, "odds": odds, "e": e})
	return out


## Quick draw (config curio_quickdraw: classes and survival skills): a curio ambush becomes a
## fight where the company strikes first. Returns the name of what grants it, or "".
func curio_quickdraw(h: Hero) -> String:
	for id in DB.cfg("curio_quickdraw", []):
		if id == h.class_id:
			return DB.classes[id].name
		if h.survival.has(id):
			return DB.survival[id].name
	return ""


## The "Who investigates?" picker's marks for a hero: just what they bring, ★ for an expert,
## ✗ for averse ("★ Prospector   ✗ Preacher"), as on event options.
func curio_hint(curio_id: String, h: Hero) -> String:
	var parts := []
	for x in curio_experts(curio_id, h):
		parts.append("%s %s" % ["✗" if x.odds < 0 else "★", DB.survival[x.id].name if DB.survival.has(x.id) else x.name])
	var qd := curio_quickdraw(h)
	if qd != "" and _has_ambush(DB.curios.get(curio_id, {})) and not parts.has("★ " + qd):
		parts.append("★ %s" % qd)
	return "   ".join(parts)


func _has_ambush(cu: Dictionary) -> bool:
	for o in cu.get("hand", []):
		for e in o.get("effects", []):
			if e.get("type", "") == "fight":
				return true
	return false


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
	var experts := curio_experts(curio_id, h) if item_id == "" else []
	var intro := ""
	var bonus := []
	if item_id == "":
		# An expert with "as_key" gets the key's result without using the supply.
		for x in experts:
			if x.e.has("as_key") and cu.get("keys", {}).has(x.e.as_key):
				outcome = cu.keys[x.e.as_key]
				out.key_worked = true
				intro = "★ %s knows the trick: no %s needed.\n\n" % [x.name, DB.items[x.e.as_key].name]
				break
	if item_id == "" and outcome.is_empty():
		var hand: Array = cu.get("hand", []).duplicate(true)
		var odds := 0
		for x in experts:
			odds += int(x.odds)
			for idx in x.e.get("swap", {}):
				hand[int(idx)] = x.e.swap[idx]
		odds = clampi(odds, -int(DB.cfg("curio_averse_odds", 50)), int(DB.cfg("curio_odds_cap", 75)))
		if odds != 0:
			for o in hand:
				if not o.get("good", false):
					o.weight = float(o.get("weight", 1)) * (1.0 - odds / 100.0)
		outcome = Stats.pick_weighted(company.rng, hand)
		for x in experts:
			if outcome.get("good", false) and x.odds >= 0 and x.e.has("bonus"):
				bonus.append(x)
			elif not outcome.get("good", false) and x.odds < 0:
				intro = "✗ %s: %s\n\n" % [x.name, x.e.get("hint", "out of their element")]
	out.text = intro + str(outcome.get("text", "")).replace("{hero}", h.hero_name)
	var effects: Array = outcome.get("effects", [])
	# Gold Fever: a hero who handles treasure by hand pockets the valuables.
	var steals := item_id == "" and _steals(h, cu)
	if steals:
		var kept := effects.filter(func(e): return not str(e.get("type", "")) in STOLEN)
		if kept.size() < effects.size():
			out.text += "\n\n%s pockets the valuables before anyone sees. (Gold Fever)" % h.hero_name
		effects = kept
	var res := Effects.apply(effects, self, h)
	out.msgs = res.msgs
	out.fight = res.fight
	for x in bonus:
		var b: Array = x.e.bonus
		if steals:
			b = b.filter(func(e): return not str(e.get("type", "")) in STOLEN)
		var bres := Effects.apply(b, self, h)
		if not bres.msgs.is_empty():
			out.msgs.append("★ %s: %s" % [x.name, " ".join(bres.msgs)])
	var qd := curio_quickdraw(h)
	if out.fight != null and qd != "" and str(out.fight.get("surprise", "")) == "":
		out.fight.surprise = "enemies"
		out.msgs.append("★ %s: %s is ready for them. The company strikes first!" % [qd, h.hero_name])
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


## Event experts (★/✗): the curio rules, plus quirks, over the whole company. For each
## class, survival skill or quirk an option lists, the hero who brings it (highest odds).
## [{"id", "name", "odds", "e", "hero"}]; odds < 0 is averse (✗).
func event_experts(opt: Dictionary) -> Array:
	var out := []
	var ex: Dictionary = opt.get("experts", {})
	var table: Array = DB.cfg("curio_skill_odds", [20, 35, 50])
	for id in ex:
		var e: Dictionary = ex[id]
		var best: Hero = null
		var odds := 0
		var label := ""
		for h in party_heroes():
			var o := 0
			if id == h.class_id:
				o = int(e.get("odds", DB.cfg("curio_class_odds", 50)))
				label = DB.classes[id].name
			elif DB.survival.has(id) and h.survival.has(id):
				o = int(e.get("odds", table[clampi(h.survival_rank(id) - 1, 0, table.size() - 1)]))
				label = DB.survival[id].name
			elif DB.quirks.has(id) and id in h.quirks:
				o = int(e.get("odds", DB.cfg("event_quirk_odds", 35)))
				label = DB.quirks[id].name
			else:
				continue
			if best == null or o > odds:
				best = h
				odds = o
		if best == null:
			continue
		if e.get("averse", false):
			odds = -int(DB.cfg("curio_averse_odds", 50))
		out.append({"id": id, "name": label, "odds": odds, "e": e, "hero": best})
	return out


## Options with availability for the UI. "experts" lists the ★/✗ marks the company brings.
func event_options(event_id: String) -> Array:
	return option_views(DB.events.get(event_id, {}).get("options", []))


func followup_options() -> Array:
	return option_views(followup.get("options", []))


func choose_followup(idx: int) -> Dictionary:
	var f := followup
	followup = {}
	return _choose_option(str(f.get("event", "")), f.options[idx])


func option_views(options: Array) -> Array:
	var out: Array = []
	var i := 0
	for opt in options:
		var req: Dictionary = opt.get("requires", {})
		# hide_if: classes or quirks in the company that rule the option out (a Marshal won't steal).
		var ruled_out := false
		for h in party_heroes():
			for id in opt.get("hide_if", []):
				if id == h.class_id or id in h.quirks:
					ruled_out = true
		var experts := event_experts(opt)
		var free := experts.any(func(x): return x.odds >= 0 and x.e.get("free", false))
		var ok := true
		var tag := ""
		if req.has("item"):
			var need := int(opt.get("consume", {}).get("item", 1))
			ok = ok and (free or int(supplies.get(req.item, 0)) >= need)
			tag = "[%s]" % DB.items.get(req.item, {}).get("name", req.item)
		if req.has("hides"):
			ok = ok and (free or int(loot.get("hides", 0)) >= int(req.hides))
			tag = "[%d Hides]" % int(req.hides)
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
		var marks := []
		for x in experts:
			marks.append({"mark": "✗" if x.odds < 0 else "★", "name": x.name})
		out.append({"index": i, "text": opt.text, "tag": tag, "available": ok and not ruled_out, "experts": marks,
			"hidden": ruled_out or (not ok and (req.has("skill") or req.has("class") or req.has("quirk")))})
		i += 1
	return out


## Bad quirks compel: a hero with one may take its option before the company chooses
## (30%, config event_compel_chance). Returns {"index", "hero", "text"} or {}.
func event_compel(event_id: String) -> Dictionary:
	var opts := event_options(event_id)
	var ev: Dictionary = DB.events.get(event_id, {})
	for i in ev.get("options", []).size():
		var opt: Dictionary = ev.options[i]
		if not opt.get("compel", false) or not opts[i].available:
			continue
		var h := event_actor(opt.get("requires", {}))
		if h != null and company.rng.randf() * 100.0 < float(DB.cfg("event_compel_chance", 30)):
			var q: String = opt.requires.get("quirk", "")
			return {"index": i, "hero": h, "text": "%s can't help themselves! (%s)" % [h.hero_name, DB.quirks.get(q, {}).get("name", q)]}
	return {}


## Returns {"text", "msgs", "fight", "then"}; "then" means a follow-up choice is waiting
## (followup_options / choose_followup).
func choose_event_option(event_id: String, idx: int) -> Dictionary:
	followup = {}
	return _choose_option(event_id, DB.events.get(event_id, {}).options[idx])


func _choose_option(event_id: String, opt: Dictionary) -> Dictionary:
	var req: Dictionary = opt.get("requires", {})
	var experts := event_experts(opt)
	# Who acts: the hero who meets the option's requirement, else the best ★ expert.
	var actor: Hero = null
	if req.has("skill") or req.has("class") or req.has("quirk"):
		actor = event_actor(req)
	if actor == null:
		var top: Dictionary = {}
		for x in experts:
			if x.odds >= 0 and (top.is_empty() or x.odds > top.odds):
				top = x
		actor = top.hero if not top.is_empty() else Stats.pick(company.rng, party_heroes())
	var free := experts.any(func(x): return x.odds >= 0 and x.e.get("free", false))
	var consume: Dictionary = opt.get("consume", {})
	if not free:
		if consume.has("item") and req.has("item"):
			supplies[req.item] = maxi(0, int(supplies.get(req.item, 0)) - int(consume.item))
		if consume.has("hides"):
			loot.hides = maxi(0, int(loot.get("hides", 0)) - int(consume.hides))
	if consume.has("money"):
		var m := int(consume.money)
		var from_loot := mini(m, int(loot.money))
		loot.money = int(loot.money) - from_loot
		company.money = maxi(0, company.money - (m - from_loot))
	# Experts add or swap outcomes, then shift the odds: the best ★ and the worst ✗ both count.
	var table: Array = opt.get("outcomes", []).duplicate(true)
	var up := 0
	var down := 0
	for x in experts:
		for o in x.e.get("add", []):
			table.append(o.duplicate(true))
		for k in x.e.get("swap", {}):
			table[int(k)] = x.e.swap[k].duplicate(true)
		up = maxi(up, int(x.odds))
		down = mini(down, int(x.odds))
	var odds := clampi(up + down, -int(DB.cfg("curio_averse_odds", 50)), int(DB.cfg("curio_odds_cap", 75)))
	# Survival passives also favour good outcomes.
	var bonus := party_passive("river_bonus") if event_id in ["river_crossing", "flash_flood"] else 0.0
	if event_id in ["hunting_grounds", "buffalo_herd"]:
		bonus += party_passive("hunt_bonus")
	var outcomes: Array = []
	for oc in table:
		var w := float(oc.get("weight", 1))
		if oc.get("good", false):
			w += bonus
		elif odds != 0:
			w *= 1.0 - odds / 100.0
		outcomes.append({"oc": oc, "weight": w})
	var picked: Dictionary = Stats.pick_weighted(company.rng, outcomes).oc
	var good: bool = picked.get("good", false)
	# A bad outcome lands on the ✗ hero, if there is one.
	var blame := ""
	if not good:
		for x in experts:
			if x.odds < 0:
				actor = x.hero
				blame = x.name
				break
	var text := str(picked.get("text", "")).replace("{hero}", actor.hero_name if actor != null else "Someone")
	if blame != "":
		text += "  (✗ %s)" % blame
	var res := Effects.apply(picked.get("effects", []), self, actor)
	var msgs: Array = res.msgs
	# Bonuses: a ★ expert's on a good outcome, a ✗ expert's on a bad one ("always": either).
	for x in experts:
		if not x.e.has("bonus"):
			continue
		var fits: bool = x.e.get("always", false) or (good and x.odds >= 0) or (not good and x.odds < 0)
		if fits:
			var bres := Effects.apply(x.e.bonus, self, x.hero)
			if not bres.msgs.is_empty():
				msgs.append("%s %s: %s" % ["✗" if x.odds < 0 else "★", x.name, " ".join(bres.msgs)])
	# Experts can set up the fight: who strikes first, wounded foes, a foe dropped, foe mods.
	if res.fight != null:
		for x in experts:
			var f: Dictionary = x.e.get("fight", {})
			for k in f:
				match k:
					"surprise":
						res.fight.surprise = f.surprise
					"wounded", "foe_mark":
						var d: Dictionary = res.fight.get(k, {})
						d.merge(f[k], true)
						res.fight[k] = d
					"foe_mods", "drop":
						var arr: Array = res.fight.get(k, [])
						res.fight[k] = arr + f[k]
					"enemies":
						res.fight.enemies = f.enemies.duplicate()
			if not f.is_empty():
				msgs.append("%s %s" % ["✗" if x.odds < 0 else "★", x.name])
	add_log([text] + msgs)
	var then: Dictionary = picked.get("then", {})
	if not then.is_empty() and res.fight == null:
		followup = {"event": event_id, "text": str(then.get("text", "")).replace("{hero}", actor.hero_name if actor != null else "Someone"),
			"options": then.get("options", [])}
	return {"text": text, "msgs": msgs, "fight": res.fight, "then": not followup.is_empty()}


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


## Every camp action of the party: {uid, skill, action, hours, rank, available, used, locked,
## affordable}. An action unlocks at its survival rank; some use up supplies.
func camp_actions() -> Array:
	var out: Array = []
	for h in party_heroes():
		for sid in h.survival:
			var sk: Dictionary = DB.survival.get(sid, {})
			for a in sk.get("actions", []):
				var used: bool = a.id in camp.used.get(str(h.uid), [])
				var rank := int(h.survival[sid].rank)
				var locked := rank < int(a.get("unlock", 1))
				var affordable := can_pay_camp_cost(a)
				# Scouting when every stop ahead is already known does nothing.
				var pointless: bool = a.get("effects", []).any(func(e): return e.type == "reveal") and unscouted_ahead() == 0 \
					and not a.get("effects", []).any(func(e): return e.type != "reveal")
				out.append({"uid": h.uid, "skill": sid, "action": a, "hours": int(a.hours), "rank": rank,
					"available": not used and not locked and affordable and not pointless and int(a.hours) <= int(camp.hours),
					"used": used, "locked": locked, "affordable": affordable, "pointless": pointless})
	return out


## Stops ahead that aren't fully scouted yet.
func unscouted_ahead() -> int:
	var c0 := int(current_node().get("col", 0))
	return nodes.filter(func(n): return int(n.col) > c0 and MapGen.intel(n) < 3).size()


func can_pay_camp_cost(action: Dictionary) -> bool:
	var cost: Dictionary = action.get("cost", {})
	for it in cost:
		if int(supplies.get(it, 0)) < int(cost[it]):
			return false
	return true


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
	if int(h.survival[sid].rank) < int(action.get("unlock", 1)) or not can_pay_camp_cost(action):
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
	var cost: Dictionary = action.get("cost", {})
	for it in cost:
		supplies[it] = int(supplies.get(it, 0)) - int(cost[it])
		msgs.append("(-%d %s)" % [int(cost[it]), DB.items.get(it, {}).get("name", it)])
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
	if DB.cfg("hero_ambush", true) and not camp.get("no_ambush", false) and not region().get("no_ambush", false):
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
	msgs.append("+%d chips." % m)
	var ir := rng.randi_range(1, 3)
	var ig := add_material("iron", ir)
	msgs.append("+%d Iron." % ig if ig == ir else "+%d Iron (no room in the wagon for %d more)." % [ig, ir - ig])
	if rng.randf() < 0.6:
		var k := company.random_keepsake()
		loot.keepsakes.append(k)
		msgs.append("Found a trinket: %s! (Click a hero's card to equip it.)" % DB.keepsakes[k].name)
	add_log(msgs)
	return msgs


func cave_exit() -> void:
	add_log("The company climbs back into daylight.")
	cave = {}


# --- Trading post ---------------------------------------------------------------------

func trade_price(item_id: String) -> int:
	return int(ceil(int(DB.items[item_id].price) * float(current_node().data.get("markup", DB.cfg("trade_markup", 2.2)))))


func trade_buy(item_id: String) -> bool:
	var stock: Dictionary = current_node().data.get("stock", {})
	if int(stock.get(item_id, 0)) <= 0:
		return false
	var price := trade_price(item_id)
	if int(loot.money) + company.money < price or Inventory.room_for(cargo(), item_id) < 1:
		return false
	var from_loot := mini(price, int(loot.money))
	loot.money = int(loot.money) - from_loot
	company.money -= price - from_loot
	stock[item_id] = int(stock[item_id]) - 1
	add_supply(item_id, 1)
	return true


# --- Save / load ----------------------------------------------------------------------

const FIELDS := ["region_id", "origin", "party", "nodes", "current", "day", "supplies", "wagon", "loot",
	"xp", "kills", "pending_buffs", "recruits", "log", "status", "boss_won", "driven_back", "cave", "camp", "pending_fight"]


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
