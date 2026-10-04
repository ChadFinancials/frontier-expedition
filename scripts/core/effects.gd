class_name Effects
extends RefCounted
## Applies out-of-combat effects from events, curios and camp actions.
##
## Effect format: {"type": ..., "target": "actor"|"party"|"random"|"ally", ...}
## Types: fatigue{amount}, heal_pct{value}, damage_pct{value}, food{amount}, money{amount|min,max},
## money_pct{value}, timber{amount}, iron{amount}, hides{amount}, charters{amount}, item{item,amount}, keepsake{},
## quirk{quirk}, remove_quirk{}, wagon{amount}, recruit{class}, townsfolk{trade,level,trait} (settles in town),
## fight{enemies,surprise,reward,wounded,drop,foe_mods,foe_mark}, duel{...} (see RunState.resolve_duel),
## buff{stat,value} (next fight), reveal{amount}, light{amount}, clear_shaken{}.
## Any effect may carry "chance" (percent). Camp effects use base/per_rank instead of amount.

## Returns {"msgs": [String], "fight": Dictionary or null}
static func apply(effects: Array, run: RunState, actor: Hero, target: Hero = null, rank: int = 1) -> Dictionary:
	var out := {"msgs": [], "fight": null, "duel": {}}
	var c: Company = run.company
	var rng := c.rng
	for e in effects:
		if e.has("chance") and rng.randf() * 100.0 >= float(e.chance):
			continue
		if e.has("fail") and rng.randf() * 100.0 < float(e.fail):
			out.msgs.append("...but comes back empty-handed.")
			continue
		var amount := _amount(e, rank, rng)
		var who := _targets(e, run, actor, target)
		match e.get("type", ""):
			"fatigue", "fatigue_self":
				var list: Array = who if e.type == "fatigue" else [actor]
				for h in list:
					var evs := Fatigue.add(h, amount, rng, {"in_cave": run.in_cave()})
					out.msgs.append_array(run.describe_events(evs))
			"heal_pct":
				for h in who:
					run.heal_hero(h, amount, out.msgs)
			"damage_pct":
				for h in who:
					if h.alive and h.hp > 0:
						var dmg := maxi(1, int(ceil(h.max_hp() * amount / 100.0)))
						h.hp = maxi(1, h.hp - dmg)
						out.msgs.append("%s takes %d damage." % [h.hero_name, dmg])
			"food":
				if amount > 0:
					var got := run.add_supply("food", amount)
					out.msgs.append("+%d Food." % got if got == amount else "+%d Food (the wagon is full; %d left behind)." % [got, amount - got])
				elif amount < 0:
					var before: int = run.supplies.get("food", 0)
					run.supplies["food"] = maxi(0, before + amount)
					out.msgs.append("%d Food." % (int(run.supplies.food) - before))
			"money":
				var m := amount
				if e.has("min"):
					m = rng.randi_range(int(e.min), int(e.max))
				if m >= 0:
					m = int(round(m * (1.0 + run.party_loot_pct() / 100.0) * float(DB.cfg("chips_mult", 1.0))))
				run.loot.money = maxi(0, int(run.loot.money) + m)
				out.msgs.append("%s%d chips." % ["+" if m >= 0 else "-", absi(m)])
			"money_pct":
				var lost := int(round(c.money * absf(amount) / 100.0))
				c.money = maxi(0, c.money - lost)
				out.msgs.append("Lost %d chips from the company purse." % lost)
			"timber":
				var t := amount + (int(run.party_passive("timber_bonus")) if amount > 0 else 0)
				var tg: int = run.add_material("timber", t) if t > 0 else t
				if t < 0:
					run.loot.timber = maxi(0, int(run.loot.timber) + t)
				out.msgs.append("+%d Timber." % tg if tg == t else "+%d Timber (no room in the wagon for %d more)." % [tg, t - tg])
			"iron":
				var ir := amount + (int(run.party_passive("iron_bonus")) if amount > 0 else 0)
				var ig: int = run.add_material("iron", ir) if ir > 0 else ir
				if ir < 0:
					run.loot.iron = maxi(0, int(run.loot.iron) + ir)
				out.msgs.append("+%d Iron." % ig if ig == ir else "+%d Iron (no room in the wagon for %d more)." % [ig, ir - ig])
			"hides":
				var hg: int = run.add_material("hides", amount) if amount > 0 else amount
				if amount < 0:
					run.loot["hides"] = maxi(0, int(run.loot.get("hides", 0)) + amount)
				out.msgs.append("+%d Hides." % hg if hg == amount else "+%d Hides (no room in the wagon for %d more)." % [hg, amount - hg])
			"charters":
				run.loot.charters = int(run.loot.charters) + amount
				out.msgs.append("+%d Land Charter%s!" % [amount, "" if amount == 1 else "s"])
			"item":
				var it: String = e.get("item", "food")
				var n := int(e.get("amount", 1)) if not e.has("base") else amount
				var got2 := run.add_supply(it, n)
				var iname: String = DB.items.get(it, {}).get("name", it)
				out.msgs.append("+%d %s." % [got2, iname] if got2 == n else "+%d %s (no room in the wagon for %d more)." % [got2, iname, n - got2])
			"item_loss":
				var il: String = e.get("item", "food")
				var have := int(run.supplies.get(il, 0))
				if have > 0:
					run.supplies[il] = maxi(0, have - int(e.get("amount", 1)))
					out.msgs.append("-%d %s." % [have - int(run.supplies[il]), DB.items.get(il, {}).get("name", il)])
			"keepsake":
				var k := c.random_keepsake(e.get("rarity", ["common", "uncommon", "rare"]))
				if k != "":
					run.loot.keepsakes.append(k)
					out.msgs.append("Found a trinket: %s! (Click a hero's card to equip it.)" % DB.keepsakes[k].name)
			"quirk":
				for h in who:
					var q := c.add_quirk(h, str(e.get("quirk", "random")))
					if q != "":
						var pos: bool = DB.quirks[q].positive
						out.msgs.append("%s gains the %s quirk: %s." % [h.hero_name, "good" if pos else "bad", DB.quirks[q].name])
			"remove_quirk":
				for h in who:
					var negs: Array = h.negative_quirks()
					if not negs.is_empty():
						var q: String = Stats.pick(rng, negs)
						h.quirks.erase(q)
						out.msgs.append("%s loses %s." % [h.hero_name, DB.quirks[q].name])
			"wagon":
				var w := amount
				if w < 0:
					w = int(round(w * (1.0 - run.party_passive("wagon_guard") / 100.0)))
				run.change_wagon(w, out.msgs)
			"recruit":
				var cls: String = e.get("class", "random")
				if cls == "random" or not DB.classes.has(cls):
					cls = Stats.pick(rng, DB.classes.keys())
				var lvl := clampi(run.tier(), 1, 3)
				var nh := c.make_hero(cls, lvl)
				nh.location = run.origin
				run.recruits.append(nh.to_dict())
				out.msgs.append("%s the %s will join the company when you return." % [nh.hero_name, DB.classes[cls].name])
			"townsfolk":
				# Someone met on the trail who'd rather settle in your town than ride with you.
				var tp := c.make_townsperson(c.pick_trade(e.get("trade", "random")), int(e.get("level", 1)), str(e.get("trait", "random")))
				run.townsfolk.append(tp)
				out.msgs.append("%s will settle in your town when you return (%s)." % [Townsfolk.title(tp), Townsfolk.trait_text(tp)])
			"duel":
				# High Noon: the screen plays it, then RunState.resolve_duel applies the result.
				out.duel = e.duplicate(true)
			"fight":
				out.fight = {"enemies": e.get("enemies", []).duplicate(), "surprise": e.get("surprise", ""),
					"reward": e.get("reward", {})}
				# Fight setup (events): wounded {eid|"*": hp %}, drop [eid], foe_mods [mod], foe_mark {eid|"*": rounds}.
				for k in ["wounded", "drop", "foe_mods", "foe_mark"]:
					if e.has(k):
						out.fight[k] = e[k].duplicate(true)
			"buff", "next_fight_buff":
				var uid := 0
				if e.get("target", "party") == "actor" and actor != null:
					uid = actor.uid
				run.pending_buffs.append({"stat": e.stat, "value": amount if (e.has("base") or e.has("amount")) else int(e.get("value", 5)), "uid": uid})
				out.msgs.append("%s: %s for the next fight." % ["Everyone" if uid == 0 else actor.hero_name,
					Stats.mod_text({"stat": e.stat, "value": amount if (e.has("base") or e.has("amount")) else int(e.get("value", 5))})])
			"reveal":
				var cols := run.reveal_ahead(amount if amount > 0 else 1)
				out.msgs.append("You get a good look at the trail ahead. (%d stop%s scouted)" % [cols, "" if cols == 1 else "s"])
			"light":
				if run.in_cave():
					run.cave.light = clampi(int(run.cave.light) + amount, 0, 100)
					out.msgs.append("Lamplight +%d." % amount)
			"clear_shaken":
				for h in who:
					if h.shaken:
						h.shaken = false
						out.msgs.append("%s is no longer Shaken." % h.hero_name)
			"no_ambush":
				run.camp.no_ambush = true
				out.msgs.append("The camp is well guarded tonight.")
			"craft_parts":
				var free := rank >= 3
				if free or int(run.loot.timber) >= 2:
					if not free:
						run.loot.timber = int(run.loot.timber) - 2
					run.supplies["wagon_parts"] = int(run.supplies.get("wagon_parts", 0)) + 1
					out.msgs.append("+1 Wagon Parts.")
				else:
					out.msgs.append("Not enough Timber gathered on this trip to make parts.")
	return out


static func _amount(e: Dictionary, rank: int, _rng: RandomNumberGenerator) -> int:
	if e.has("base"):
		return int(e.base) + int(e.get("per_rank", 0)) * (rank - 1)
	if e.has("amount"):
		return int(e.amount)
	if e.has("value"):
		return int(e.value)
	return 0


static func _targets(e: Dictionary, run: RunState, actor: Hero, target: Hero) -> Array:
	var party := run.party_heroes()
	match e.get("target", "party"):
		"actor", "self":
			return [actor] if actor != null else []
		"ally":
			return [target] if target != null else ([actor] if actor != null else [])
		"random":
			var p = Stats.pick(run.company.rng, party)
			return [p] if p != null else []
	return party
