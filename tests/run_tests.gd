extends Node
## Headless test suite. Run with:
##   godot --headless --path . res://tests/test_runner.tscn
## Optional user args after "--": sim=N (campaign weeks to simulate), seed=N

var failures: Array = []
var passes := 0


func _ready() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var t0 := Time.get_ticks_msec()
	if args.has("campaign"):
		full_campaign(int(args.campaign), int(args.get("weeks", "40")))
		get_tree().quit(0)
		return
	if args.has("simtut"):
		sim_tutorial(int(args.simtut))
		get_tree().quit(0)
		return
	if args.has("balance"):
		balance(int(args.balance), int(args.get("weeks", "6")))
		get_tree().quit(0)
		return
	print("> test_data_valid()")
	test_data_valid()
	print("> test_heroes()")
	test_heroes()
	print("> test_combat_basics()")
	test_combat_basics()
	print("> test_deaths_door()")
	test_deaths_door()
	print("> test_fatigue()")
	test_fatigue()
	print("> test_map_gen()")
	test_map_gen()
	print("> test_region_fights()")
	test_region_fights()
	print("> test_settlement_services()")
	test_settlement_services()
	print("> test_save_roundtrip()")
	test_save_roundtrip()
	print("> test_tutorial_and_story()")
	test_tutorial_and_story()
	test_campaign(int(args.get("sim", "12")), int(args.get("seed", "7")))
	print("\n=== %d passed, %d failed (%.1fs) ===" % [passes, failures.size(), (Time.get_ticks_msec() - t0) / 1000.0])
	for f in failures:
		print("FAIL: ", f)
	get_tree().quit(1 if failures.size() > 0 else 0)


func check(cond: bool, msg: String) -> void:
	if cond:
		passes += 1
	else:
		failures.append(msg)


# ---------------------------------------------------------------------------------------

func test_data_valid() -> void:
	var errs := DB.validate()
	for e in errs:
		print("  data: ", e)
	check(errs.is_empty(), "data validation (%d problems)" % errs.size())
	check(DB.classes.size() == 10, "10 classes (got %d)" % DB.classes.size())
	for cid in DB.classes:
		check(DB.classes[cid].skills.size() == 6, "%s has 6 skills" % cid)
		check(DB.classes[cid].default_equipped.size() == 4, "%s equips 4" % cid)
	for eid in DB.events:
		for opt in DB.events[eid].options:
			check(not opt.get("outcomes", []).is_empty(), "event %s option has outcomes" % eid)


func test_heroes() -> void:
	var co := Company.new()
	co.rng.seed = 3
	for cid in DB.classes:
		var h := co.make_hero(cid, 1)
		check(h.max_hp() > 10 and h.hp == h.max_hp(), "%s hp" % cid)
		check(h.survival.size() == 2, "%s has 2 survival skills" % cid)
		check(h.quirks.size() == 2, "%s starts with 2 quirks" % cid)
		var d := JSON.parse_string(JSON.stringify(h.to_dict()))
		var h2 := Hero.from_dict(DB.normalize(d))
		check(h2.hero_name == h.hero_name and h2.max_hp() == h.max_hp() and h2.equipped == h.equipped, "%s serializes" % cid)
	var h3 := co.make_hero("marshal", 3)
	check(h3.level == 3, "recruit level 3 (got %d)" % h3.level)


func _party(co: Company, classes: Array) -> Array:
	var out: Array = []
	for cid in classes:
		out.append(co.make_hero(cid, 1))
	return out


func test_combat_basics() -> void:
	var co := Company.new()
	co.rng.seed = 11
	var party := _party(co, ["marshal", "gunslinger", "sharpshooter", "preacher"])
	for h in party:
		h.quirks.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var e := CombatEngine.new()
	e.setup(party, ["outlaw_brawler", "outlaw_gunhand", "outlaw_rifleman"], {"rng": rng})
	check(e.heroes.size() == 4 and e.enemies.size() == 3, "combat setup")
	var marshal: Combatant = e.heroes[0]
	var brawler: Combatant = e.enemies[0]
	var rifle: Combatant = e.enemies[2]
	check(e.valid_targets(marshal, "marshal_iron_justice").size() == 2, "iron justice hits ranks 1-2")
	check(not rifle.id in e.valid_targets(marshal, "marshal_iron_justice"), "rank 3 out of melee reach")
	var hc := e.hit_chance(marshal, "marshal_iron_justice", brawler)
	check(hc == 80, "hit chance 85 acc - 5 dodge = 80 (got %d)" % hc)
	var prev := e.dmg_preview(marshal, "marshal_iron_justice", brawler)
	check(prev.size() == 2 and prev[0] >= 1 and prev[1] >= prev[0], "damage preview")
	# Sharpshooter can't use Long Shot from rank 1.
	var ss: Combatant = e.heroes[2]
	check(e.valid_targets(e.heroes[0], "ss_long_shot").is_empty(), "rank restriction")
	check(not e.valid_targets(ss, "ss_long_shot").is_empty(), "sharpshooter can shoot from rank 3")
	# Knockback moves the target back.
	e.enemies[0].hp = 999
	e.enemies[0].max_hp = 999
	var ev := []
	e._shift(e.enemies[0], -1, ev)
	check(e.enemies[1].data.id == "outlaw_brawler", "knockback shifts rank")
	# Play a whole fight with the bot.
	var bot := Bot.new(9)
	var party2 := _party(co, ["rail_driver", "wrangler", "prospector", "frontier_doctor"])
	var e2 := bot.fight(party2, ["prairie_wolf", "coyote", "carrion_crows"], {"rng": rng})
	check(e2.is_over(), "bot fight finishes")


func test_deaths_door() -> void:
	var co := Company.new()
	co.rng.seed = 21
	var party := _party(co, ["gambler"])
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	var e := CombatEngine.new()
	e.setup(party, ["outlaw_brawler"], {"rng": rng})
	var hc: Combatant = e.heroes[0]
	var ev: Array = []
	e._apply_damage(hc, 999, e.enemies[0], ev, false)
	check(hc.hero.deaths_door and hc.hp == 0 and not hc.dead, "big hit puts hero on Death's Door, not dead")
	var died := false
	for i in 60:
		e._apply_damage(hc, 1, e.enemies[0], ev, false)
		if hc.dead:
			died = true
			break
	check(died, "repeated deathblows eventually kill")
	# Healing off Death's Door leaves the hero Shaken.
	var party2 := _party(co, ["preacher", "marshal"])
	var e2 := CombatEngine.new()
	e2.setup(party2, ["outlaw_brawler"], {"rng": rng})
	var m: Combatant = e2.heroes[1]
	e2._apply_damage(m, 999, null, ev, false)
	e2._heal(e2.heroes[0], m, 5, false, ev)
	check(not m.hero.deaths_door and m.hero.shaken and m.hp == 5, "heal off Death's Door -> Shaken")


func test_fatigue() -> void:
	var co := Company.new()
	co.rng.seed = 31
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var breaks := 0
	var winds := 0
	for i in 400:
		var h := co.make_hero("gunslinger", 1)
		h.quirks.clear()
		h.fatigue = 95
		Fatigue.add(h, 10, rng)
		if h.is_breaking():
			breaks += 1
		elif h.is_second_wind():
			winds += 1
			check(h.fatigue == 45, "second wind resets fatigue to 45")
	check(breaks + winds == 400, "every hero crossing 100 is tested")
	check(winds > 60 and winds < 150, "second wind rate ~25%% (got %d/400)" % winds)
	var h2 := co.make_hero("marshal", 1)
	h2.quirks.clear()
	h2.fatigue = 190
	h2.fatigue_state = "homesick"
	Fatigue.add(h2, 20, rng)
	check(h2.deaths_door and h2.hp == 0 and h2.alive, "collapse -> Death's Door")
	h2.fatigue = 195
	Fatigue.add(h2, 20, rng)
	check(not h2.alive, "collapse on Death's Door is fatal")
	var h3 := co.make_hero("marshal", 1)
	h3.quirks.clear()
	h3.fatigue = 60
	h3.fatigue_state = "reckless"
	Fatigue.add(h3, -40, rng)
	check(h3.fatigue_state == "", "breaking point clears at low fatigue")


func test_map_gen() -> void:
	var rng := RandomNumberGenerator.new()
	for rid in DB.regions:
		for s in 30:
			rng.seed = s * 13 + 1
			var nodes := MapGen.generate(rid, rng, s % 2 == 0)
			var reach := {0: true}
			var frontier := [0]
			while not frontier.is_empty():
				var id: int = frontier.pop_back()
				for nx in nodes[id].next:
					if not reach.has(nx):
						reach[nx] = true
						frontier.append(nx)
			check(reach.size() == nodes.size(), "%s map fully reachable (seed %d)" % [rid, s])
			var last: Dictionary = nodes[nodes.size() - 1]
			check(last.type in ["boss", "crossing"], "%s map ends at boss/crossing" % rid)
			for n in nodes:
				if n.col < MapGen.column_count(nodes) - 1:
					check(not n.next.is_empty(), "%s node %d has an exit" % [rid, n.id])
				if n.type in ["fight", "elite", "boss", "crossing"]:
					check(not n.data.enemies.is_empty(), "%s fight node has enemies" % rid)


func test_region_fights() -> void:
	# Every enemy group in the game can be fought to completion.
	var co := Company.new()
	co.rng.seed = 41
	var bot := Bot.new(41)
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	var comps := [["marshal", "mountain_man", "sharpshooter", "preacher"], ["rail_driver", "gunslinger", "prospector", "frontier_doctor"],
		["mountain_man", "wrangler", "gambler", "preacher"]]
	var groups: Array = []
	for rid in DB.regions:
		var r: Dictionary = DB.regions[rid]
		for key in ["fights", "elites", "cave_fights"]:
			for g in r[key]:
				groups.append([rid, g.enemies, int(r.tier)])
		groups.append([rid, r.boss.enemies, int(r.tier)])
	for g in groups:
		for comp in comps:
			var party := []
			for cid in comp:
				party.append(co.make_hero(cid, clampi(g[2] * 2 - 1, 1, 5)))
			var e := bot.fight(party, g[1], {"rng": rng, "tier": g[2]})
			check(e.is_over(), "fight %s %s finishes" % [g[0], g[1]])
	print("  fights: %d  wins: %d  losses: %d  avg rounds: %.1f  max rounds: %d" % [bot.stats.fights, bot.stats.wins,
		bot.stats.losses, float(bot.stats.rounds) / maxf(1, bot.stats.fights), bot.stats.max_rounds])
	check(bot.stats.errors.is_empty(), "no combat errors: %s" % [bot.stats.errors])


func test_settlement_services() -> void:
	var co := Company.new()
	co.new_game(5)
	check(co.settlements.size() == 1 and co.heroes.size() == 2 and co.roster_cap() == 5, "new game setup: two heroes, room for five")
	check(co.missing.size() == 1 and Hero.from_dict(co.missing[0]).class_id == "sharpshooter", "the sharpshooter is missing")
	check(co.can_do_activity(0, "saloon", "bar", co.heroes[0]) != "", "saloon is a ruin until the tutorial")
	co.complete_tutorial()
	co.money += 3000
	co.timber += 60
	co.iron += 40
	check(co.settlement(0).recruits.size() == 3 and Hero.from_dict(co.settlement(0).recruits[0]).class_id == "preacher", "hiring board: the promised preacher plus two recruits")
	var h: Hero = co.heroes[0]
	h.fatigue = 80
	var money0 := co.money
	var msgs := co.do_activity(0, "saloon", "bar", h)
	check(not msgs.is_empty() and h.fatigue < 80 and co.money < money0 and not h.available(), "saloon relieves fatigue and occupies hero")
	check(co.can_do_activity(0, "chapel", "prayer", co.heroes[1]) != "", "no chapel at start")
	check(co.can_build(0, "chapel") == "", "can build chapel in free slot")
	check(co.build(0, "chapel"), "build chapel")
	check(co.build(0, "smithy") and not co.is_ruin(0, "smithy"), "rebuild the burned smithy")
	check(co.build(0, "doctor"), "build doctor in the last free plot")
	check(co.can_build(0, "drill_hall") != "", "town is full after 6 plots")
	check(co.can_build(0, "general_store") == "", "a ruin can still be rebuilt when the town is full")
	co.advance_week()
	check(h.available(), "hero free after a week")
	var hired := co.hire(0, 0)
	check(hired != null and hired.location == 0, "hire recruit")
	check(co.upgrade_track(0, "hiring_board", "notices") and co.track_level(0, "hiring_board", "notices") == 1, "upgrade the More Notices track")
	co.advance_week()
	check(co.settlement(0).recruits.size() == 3, "more notices means more recruits")
	co.money += 3000
	co.timber += 60
	co.iron += 30
	check(co.upgrade_track(0, "hiring_board", "notices"), "second notices upgrade in a town")
	check(co.can_upgrade_track(0, "hiring_board", "notices") != "", "track is capped")
	# Stage line needs a second settlement.
	check(co.can_send(0, 1, co.heroes[1]) != "", "can't send to unfounded site")
	co.beaten.append("tallgrass")
	co.money += 5000
	co.charters += 1
	co.timber += 50
	co.iron += 50
	check(co.found(1), "found Redwater Ford")
	check(co.can_send(0, 1, co.heroes[1]) == "", "can send along stage line")
	var traveler: Hero = co.heroes[1]
	co.send_hero(0, 1, traveler)
	check(not traveler.available(), "hero in transit")
	co.advance_week()
	check(traveler.location == 1 and traveler.available(), "hero arrives next week")
	# Gear needs levels.
	var g: Hero = co.heroes[2]
	check(co.can_upgrade_gear(0, g, "weapon").begins_with("Needs hero level"), "gear gated by level")
	g.add_xp(int(DB.cfg("xp_levels")[1]))
	check(co.upgrade_gear(0, g, "weapon") and g.weapon_tier == 2, "upgrade weapon at level 2")


func test_tutorial_and_story() -> void:
	var co := Company.new()
	co.new_game(21)
	check(co.tutorial_pending(0) and co.expedition_region(0) == "old_mill_road", "new game starts with the tutorial")
	check(co.is_ruin(0, "saloon") and co.building_level(0, "saloon") == 0, "Fort Providence starts burned")
	var full: Dictionary = DB.buildings.smithy.costs[0]
	check(int(co.building_cost(0, "smithy").money) == int(ceil(int(full.money) * DB.cfg("ruin_rebuild_pct", 100) / 100.0)), "ruins rebuild at the configured price")
	check(co.can_build(0, "general_store") != "" and co.can_build(0, "smithy") != "", "nothing can be rebuilt at the start")
	var money0 := co.money
	var r := co.start_tutorial()
	check(r != null and r.party.size() == 2 and co.money == money0, "tutorial sets out free with two heroes")
	check(r.party_heroes().map(func(h): return h.class_id) == DB.cfg("tutorial_party"), "tutorial party is the Marshal and Gunslinger")
	check(MapGen.column_count(r.nodes) == 5 and r.nodes.size() == 6, "tutorial map: start, 3 stops, boss")
	check(r.choices() == [1] and r.node(1).type == "fight", "tutorial opens with a fight")
	check(r.nodes.filter(func(n): return n.col == 2).all(func(n): return MapGen.intel(n) == 0), "tutorial fork is unscouted")
	check(r.node(r.nodes.size() - 1).type == "boss" and "mad_dog_mulligan" in r.node(r.nodes.size() - 1).data.enemies, "tutorial ends at Mulligan")
	r.boss_won = true
	r.xp = 40
	var sm := co.finish_run("victory")
	check(co.heroes_at(0).all(func(h): return h.level == 1), "the tutorial can't level anyone up")
	check(co.tutorial_done and co.building_level(0, "saloon") == 1 and not co.is_ruin(0, "saloon"), "winning the tutorial rebuilds the saloon")
	check(sm.get("tutorial", false) and str(sm.story) != "", "tutorial summary tells the story")
	check(co.expedition_region(0) == "tallgrass", "then the real trail opens")
	# Silas Crane's first meeting ends on a script.
	var bot := Bot.new(5)
	var party: Array = []
	for cid in ["marshal", "gunslinger", "preacher", "sharpshooter"]:
		party.append(co.make_hero(cid, 2))
	var sc: Dictionary = DB.regions.tallgrass.boss.first_script
	var e := bot.fight(party, DB.regions.tallgrass.boss.enemies, {"rng": co.rng, "tier": 1, "boss": true, "script": sc})
	check(e.state == "scripted" and e.round_num <= int(sc.round), "Silas's first fight ends in his gambit (%s, round %d)" % [e.state, e.round_num])
	var uids: Array = []
	for h in co.heroes_at(0).slice(0, 4):
		h.hp = h.max_hp()
		uids.append(h.uid)
	co.start_run(0, uids, {"food": 10})
	check(co.run.combat_options("boss").has("script"), "first Silas fight carries the script")
	co.story_flags[sc.id] = true
	var opts := co.run.combat_options("boss")
	check(not opts.has("script") and int(opts.wounded.silas_crane) == int(sc.wound_pct), "second meeting: Silas is wounded")
	check(co.run.boss_intro() == DB.regions.tallgrass.boss.intro_again, "second meeting has its own intro")
	var e2 := CombatEngine.new()
	e2.setup(party, DB.regions.tallgrass.boss.enemies, opts)
	var silas: Combatant = e2.enemies.filter(func(x): return x.data.id == "silas_crane")[0]
	check(silas.hp < silas.max_hp, "wounded Silas starts below full health")
	e2.dev_win()
	check(e2.state == "victory" and e2.killed.size() == DB.regions.tallgrass.boss.enemies.size(), "dev win clears the fight")
	var txt := JSON.stringify(co.to_dict())
	var co2 := Company.from_dict(DB.normalize(JSON.parse_string(txt)))
	check(co2.tutorial_done and co2.story_flags.has(sc.id), "tutorial and story flags survive save/load")
	# Side adventures.
	co.run = null
	var opts2 := co.expedition_options(0)
	check(opts2.slice(0, 3) == ["tallgrass", "dry_gulch_mine", "crows_nest"] and opts2.size() == 4 and DB.regions[opts2[3]].get("quest", false),
		"Fort Providence offers the trail, two story adventures and this week's saloon rumor")
	var qreg: Dictionary = DB.regions[opts2[3]]
	check(qreg.final in ["boss", "crossing"] and not qreg.crossing.enemies.is_empty() and Company.quest_hints(qreg).begins_with("Rumored"), "a rumor is a playable quest")
	var missing_name := co.missing_name()
	var hs: Array = co.heroes_at(0).slice(0, 2)
	var r2 := co.start_run(0, hs.map(func(h): return h.uid), {"food": 12}, "dry_gulch_mine")
	check(r2 != null and MapGen.column_count(r2.nodes) == int(DB.regions.dry_gulch_mine.columns) and r2.nodes[r2.nodes.size() - 1].type == "boss", "side adventure: short map ending at its mini-boss")
	var e3 := CombatEngine.new()
	e3.setup(r2.party_heroes(), [], {})
	e3.state = "victory"
	var res3 := r2.after_combat(e3, "boss")
	check(r2.recruits.size() == 1 and Hero.from_dict(r2.recruits[0]).hero_name == missing_name and co.missing.is_empty(), "Dry Gulch Mine: the missing sharpshooter is rescued")
	check("miners_lamp" in res3.keepsakes and int(res3.charters) == 0, "first clear: the rare trinket, no charters")
	co.run = null
	var r3 := co.start_run(0, hs.map(func(h): return h.uid), {"food": 12}, opts2[3])
	check(r3 != null and not opts2[3] in co.expedition_options(0), "taking a rumor takes it off the board")
	var e4 := CombatEngine.new()
	e4.setup(r3.party_heroes(), [], {})
	e4.state = "victory"
	var money_before := int(r3.loot.money)
	r3.after_combat(e4, qreg.final)
	check(r3.boss_won and int(r3.loot.money) >= money_before + int(qreg.quest_reward.money), "finishing a rumor pays its reward")
	co.run = null
	co.money += 5000
	co.timber += 50
	co.iron += 50
	check(co.upgrade_track(0, "saloon", "chatter"), "upgrade the saloon's chatter")
	co.advance_week()
	check(co.settlement(0).get("quests", []).size() == 2, "more chatter, more rumors each week")
	check(Inventory.slots_used({"food": 13, "bandages": 1}) == 3 and Inventory.room_for({"food": 12}, "food", 1) == 0, "wagon slots and stacks")


## Plays the tutorial N times with fresh companies and reports how it goes.
func sim_tutorial(n: int) -> void:
	var res := {}
	var boss_hp_left := 0.0
	var levels := {}
	for i in n:
		var co := Company.new()
		co.new_game(1000 + i)
		var bot := Bot.new(1000 + i)
		var r := co.start_tutorial()
		var party := r.party_heroes()
		var s := bot.play_run(co, r)
		res[s.status] = res.get(s.status, 0) + 1
		boss_hp_left += bot.last_hp_ratio
		for k in bot.stats:
			if str(k).begins_with("deaths_") or str(k).begins_with("fights_"):
				res[k] = res.get(k, 0) + int(bot.stats[k])
		for h in party:
			if h.alive:
				levels[h.level] = levels.get(h.level, 0) + 1
		if i == 0:
			print("  sample xp: ", s.heroes.map(func(e): return e.xp))
	print("TUTORIAL %d runs: %s  avg party hp at the end %.2f  levels %s" % [n, res, boss_hp_left / n, levels])


func test_save_roundtrip() -> void:
	var co := Company.new()
	co.new_game(77)
	co.complete_tutorial()
	var uids := []
	for h in co.heroes.slice(0, 4):
		uids.append(h.uid)
	check(co.can_embark(0, uids, {"food": 16, "bandages": 2}) != "", "no store: only the free kit")
	co.start_run(0, uids, co.free_kit())
	check(co.run != null and co.run.nodes.size() > 10, "run created")
	var txt := JSON.stringify(co.to_dict())
	var co2 := Company.from_dict(DB.normalize(JSON.parse_string(txt)))
	check(co2.run != null and co2.run.nodes.size() == co.run.nodes.size(), "run survives save/load")
	check(co2.heroes.size() == co.heroes.size() and co2.money == co.money, "company survives save/load")
	check(co2.run.choices() == co.run.choices(), "map links survive save/load")
	check(JSON.stringify(co2.to_dict()) == txt, "save is stable across a roundtrip")


func test_campaign(weeks: int, seed_value: int) -> void:
	var co := Company.new()
	co.new_game(seed_value)
	var bot := Bot.new(seed_value)
	bot.cautious = true
	var results := {}
	for w in weeks:
		# Keep the roster topped up and rested, like a sensible player.
		while co.heroes_at(0).filter(func(x): return x.available()).size() < 4 and not co.settlement(0).recruits.is_empty():
			if co.hire(0, 0) == null:
				break
		for h in co.heroes_at(0):
			if h.fatigue > 60 and h.available() and co.can_do_activity(0, "saloon", "bar", h) == "":
				co.do_activity(0, "saloon", "bar", h)
		var s := bot.play_expedition(co, 0)
		results[s.status] = results.get(s.status, 0) + 1
		# Roundtrip the save every week.
		var co2 := Company.from_dict(DB.normalize(JSON.parse_string(JSON.stringify(co.to_dict()))))
		check(co2.heroes.size() == co.heroes.size(), "weekly save roundtrip")
	print("  campaign %d weeks: %s  money $%d  heroes %d  dead %d  beaten %s" % [weeks, results, co.money,
		co.heroes.size(), co.dead.size(), co.beaten])
	print("  bot: ", bot.stats)
	check(bot.stats.errors.is_empty(), "campaign ran without errors: %s" % [bot.stats.errors])


## Balance report: many short campaigns with a fresh company each.
func balance(campaigns: int, weeks: int) -> void:
	var agg := {"exp": 0, "victory": 0, "abandoned": 0, "defeat": 0, "deaths": 0, "boss_week": [], "fatigue": 0, "fatigue_n": 0,
		"first_run_deaths": 0, "first_run_victory": 0}
	var bstats := {"fights": 0, "wins": 0, "losses": 0, "fled": 0, "boss_fights": 0, "boss_wins": 0}
	for c in campaigns:
		var co := Company.new()
		co.new_game(1000 + c)
		var bot := Bot.new(1000 + c)
		for w in weeks:
			while co.heroes_at(0).filter(func(x): return x.available()).size() < 4 and not co.settlement(0).recruits.is_empty():
				if co.hire(0, 0) == null:
					break
			for h in co.heroes_at(0):
				if h.fatigue > 60 and h.available() and co.can_do_activity(0, "saloon", "bar", h) == "":
					co.do_activity(0, "saloon", "bar", h)
			var dead_before := co.dead.size()
			var s := bot.play_expedition(co, 0)
			if s.status == "no_run":
				break
			agg.exp += 1
			agg[s.status] = agg.get(s.status, 0) + 1
			agg.deaths += co.dead.size() - dead_before
			if w == 0:
				agg.first_run_deaths += co.dead.size() - dead_before
				if s.status == "victory":
					agg.first_run_victory += 1
			if s.boss_won and co.beaten.size() == 1 and agg.boss_week.size() <= c:
				agg.boss_week.append(w + 1)
			for h in co.heroes:
				agg.fatigue += h.fatigue
				agg.fatigue_n += 1
		for k in bstats:
			bstats[k] += bot.stats.get(k, 0)
		if agg.boss_week.size() <= c:
			agg.boss_week.append(0)
	print("BALANCE %d campaigns x %d weeks" % [campaigns, weeks])
	print("  expeditions %d  victory %d  abandoned %d  defeat %d" % [agg.exp, agg.victory, agg.abandoned, agg.defeat])
	print("  deaths/expedition %.2f   first run: deaths %.2f, victory %.0f%%" % [float(agg.deaths) / maxf(1, agg.exp),
		float(agg.first_run_deaths) / campaigns, 100.0 * agg.first_run_victory / campaigns])
	print("  avg fatigue %.1f   fights %s" % [float(agg.fatigue) / maxf(1, agg.fatigue_n), bstats])
	print("  boss first beaten on week: %s" % [agg.boss_week])


## Long simulated campaigns: the bot manages the company like a steady player: hires,
## rests, trains, buys gear, founds outposts and pushes west.
func full_campaign(runs: int, weeks: int) -> void:
	var results: Array = []
	for n in runs:
		var co := Company.new()
		co.new_game(500 + n)
		var bot := Bot.new(500 + n)
		bot.cautious = true
		var beaten_week := {}
		var statuses := {}
		for w in weeks:
			var front := co.frontier_index()
			# Found any settlement we can.
			for i in co.site_count():
				if co.can_found(i) == "":
					co.found(i)
			front = co.frontier_index()
			if co.site_by_index(front).get("region_west", "") == "":
				break
			# Move seasoned heroes west, one stop at a time (the stage line takes weeks).
			for i in range(front):
				var need_level := int(DB.regions[co.site_by_index(i + 1).region_west].tier) * 2 - 1 if co.site_by_index(i + 1).get("region_west", "") != "" else 5
				for h in co.heroes_at(i).filter(func(x): return x.available() and x.level >= need_level):
					if co.founded(i + 1) and co.heroes_at(i + 1).size() < 8 and co.can_send(i, i + 1, h) == "":
						co.send_hero(i, i + 1, h)
			# Staff up and look after heroes wherever they are.
			for st in co.settlements:
				var i: int = st.index
				while co.heroes_at(i).filter(func(x): return x.available()).size() < 4 and not st.recruits.is_empty() and co.heroes.size() < 20:
					if co.hire(i, 0) == null:
						break
				for h in co.heroes_at(i):
					if h.fatigue > 55 and h.available():
						for b in ["saloon", "chapel", "boot_hill"]:
							if co.can_do_activity(i, b, "bar" if b == "saloon" else ("prayer" if b == "chapel" else "remember"), h) == "":
								co.do_activity(i, b, "bar" if b == "saloon" else ("prayer" if b == "chapel" else "remember"), h)
								break
					if co.money > 900:
						for kind in ["weapon", "armor"]:
							if co.can_upgrade_gear(i, h, kind) == "":
								co.upgrade_gear(i, h, kind)
						for sid in h.equipped:
							if co.money > 700 and co.can_upgrade_skill(i, h, sid) == "":
								co.upgrade_skill(i, h, sid)
					for k in co.stash.duplicate():
						if h.keepsakes.size() < 2:
							co.equip_keepsake(h, k)
				# Build useful buildings when rich.
				for b in ["chapel", "drill_hall", "doctor", "saloon", "smithy", "general_store", "hiring_board"]:
					if co.money > 1500 and co.can_build(i, b) == "":
						co.build(i, b)
				if co.can_upgrade_tier(i) == "":
					co.upgrade_tier(i)
			# Expedition from the westernmost settlement with a ready party.
			var from := -1
			for st2 in co.settlements:
				if co.heroes_at(st2.index).filter(func(x): return x.available()).size() >= 3 and co.site_by_index(st2.index).get("region_west", "") != "":
					from = st2.index
			if from < 0:
				co.advance_week()
				continue
			var s := bot.play_expedition(co, from)
			statuses[s.status] = statuses.get(s.status, 0) + 1
			if s.status == "no_run":
				co.advance_week()
			for r in co.beaten:
				if not beaten_week.has(r):
					beaten_week[r] = w + 1
		var lv := 0.0
		for h in co.heroes:
			lv += h.level
		var deaths := {}
		for k in bot.stats:
			if str(k).begins_with("deaths_") or str(k).begins_with("fights_"):
				deaths[k] = bot.stats[k]
		results.append({"kills": deaths, "beaten": beaten_week, "week": co.week, "dead": co.dead.size(), "alive": co.heroes.size(),
			"avg_level": lv / maxf(1, co.heroes.size()), "money": co.money, "settlements": co.settlements.size(), "statuses": statuses})
	for r in results:
		print("CAMPAIGN ", r)
