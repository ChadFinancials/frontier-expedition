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
	if args.has("econ"):
		econ_probe(int(args.econ))
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
	print("> test_enemy_moves()")
	test_enemy_moves()
	print("> test_hero_moves()")
	test_hero_moves()
	print("> test_turn_order()")
	test_turn_order()
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
	print("> test_quest_boss()")
	test_quest_boss()
	print("> test_round8_balance()")
	test_round8_balance()
	print("> test_vulnerable_and_new_moves()")
	test_vulnerable_and_new_moves()
	print("> test_bones()")
	test_bones()
	print("> test_train_hopper()")
	test_train_hopper()
	print("> test_quirk_pass()")
	test_quirk_pass()
	print("> test_trinket_pass()")
	test_trinket_pass()
	print("> test_round9_town()")
	test_round9_town()
	print("> test_hides()")
	test_hides()
	print("> test_curio_experts()")
	test_curio_experts()
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
	check(DB.classes.size() == 11, "11 classes (got %d)" % DB.classes.size())
	for cid in DB.classes:
		check(DB.classes[cid].skills.size() >= 6 and DB.classes[cid].skills.size() <= 8, "%s has 6-8 moves" % cid)
		# Outfits: three colorings per class, colors only, all valid colors.
		var outfits: Array = DB.classes[cid].look.get("outfits", [])
		check(outfits.size() == 3, "%s has 3 outfits" % cid)
		for o in outfits:
			for k in o:
				check(k in ["name", "coat", "pants", "hat", "shirt", "accent", "band"], "%s outfit key %s is a color" % [cid, k])
				if k != "name":
					check(Color.html_is_valid(str(o[k])), "%s outfit %s color %s" % [cid, k, o[k]])
	# Every outfit gets rolled across seeds.
	var seen := {}
	for sd in range(1, 200):
		var f := Figure.new()
		f.setup(DB.classes["preacher"].look, sd, 1)
		seen[f.col("hat").to_html(false)] = true
		f.free()
	check(seen.size() == 3, "all 3 preacher outfits roll (got %d)" % seen.size())
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
	check(hc == 89, "hit chance 92 acc + 2 Marshal acc - 5 dodge = 89 (got %d)" % hc)
	# Class edge: the Mountain Mystic hits beasts harder and more surely (classes.json vs_tags).
	var mm_party: Array = _party(co, ["mountain_man"])
	for mh in mm_party:
		mh.quirks.clear()
	var emm := CombatEngine.new()
	emm.setup(mm_party, ["prairie_wolf", "outlaw_brawler"], {"rng": rng})
	var mmc: Combatant = emm.heroes[0]
	var wolf: Combatant = emm.enemies[0]
	var man: Combatant = emm.enemies[1]
	check(is_equal_approx(emm.dmg_mult(mmc, "mm_grizzly_chop", wolf) - emm.dmg_mult(mmc, "mm_grizzly_chop", man), 0.2), "Mountain Mystic +20% damage vs beasts")
	check(emm.hit_chance(mmc, "mm_grizzly_chop", wolf) - emm.hit_chance(mmc, "mm_grizzly_chop", man) == 2 + int(man.stat("dodge", mmc) - wolf.stat("dodge", mmc)), "Mountain Mystic +2 accuracy vs beasts")
	check(wolf.max_hp == 8, "prairie wolf has 8 HP (got %d)" % wolf.max_hp)
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


func test_enemy_moves() -> void:
	var co := Company.new()
	co.rng.seed = 12
	var party := _party(co, ["marshal", "gunslinger", "sharpshooter", "preacher"])
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var e := CombatEngine.new()
	e.setup(party, ["prairie_wolf", "prairie_wolf", "outlaw_rifleman", "outlaw_knifeman"], {"rng": rng})
	var w1: Combatant = e.enemies[0]
	var w2: Combatant = e.enemies[1]
	var rifle: Combatant = e.enemies[2]
	# Fixed per-move damage ranges (tier 1).
	var dr := e.skill_dmg_range(w1, "e_wolf_bite")
	check(dr[0] == 3 and dr[1] == 5, "wolf bite uses its own 3-5 range (got %s)" % str(dr))
	# Howl for the Pack buffs the other wolf, not itself or the rifleman.
	var ev := e.use_skill(w1, "e_wolf_howl", e.heroes[0].id)
	check(w2.buff_total("acc") == 5 and w2.buff_total("speed") == 1, "howl buffs the other wolf")
	check(w1.buff_total("acc") == 0 and rifle.buff_total("acc") == 0, "howl skips itself and non-wolves")
	e.use_skill(w1, "e_wolf_howl", e.heroes[0].id)
	check(w2.buff_total("acc") == 10, "repeated howls stack")
	# Rusty Shank always goes for the most wounded hero it can reach.
	e.heroes[1].set_hp(1)
	var picks := {}
	for i in 20:
		picks[e._pick_target([e.heroes[0].id, e.heroes[1].id, e.heroes[2].id], "lowest_hp", 100)] = true
	check(picks.size() == 1 and picks.has(e.heroes[1].id), "pref_chance 100 always picks lowest HP")
	# A rifleman shoved into rank 1 punches, and with no usable move it steps back into position.
	e._shift(rifle, 2, ev)
	check(rifle.rank == 1, "rifleman moved to rank 1")
	check(e.usable_skills(rifle) == ["e_rifle_haymaker"], "rifleman can only punch from rank 1")
	var lone := CombatEngine.new()
	lone.setup(party, ["outlaw_brawler", "outlaw_gunhand", "outlaw_rifleman"], {"rng": rng})
	var r2: Combatant = lone.enemies[2]
	r2.skills = ["e_rifle_snipe"]
	lone._shift(r2, 2, ev)
	var out := lone._ai_out_of_position(r2)
	check(r2.rank == 3 and out[0].t == "swap", "out-of-position enemy steps to a usable rank")
	lone.enemies = [r2]
	lone._reindex()
	out = lone._ai_out_of_position(r2)
	check(out.any(func(x): return x.t == "action" and x.skill == "e_fallback_swing"), "no usable rank: fallback swing")
	# Silas opens with Crowstorm (three Murders of Crows), and never casts it again.
	var sb := CombatEngine.new()
	sb.setup(party, ["silas_crane"], {"rng": rng, "boss": true})
	var silas: Combatant = sb.enemies[0]
	sb._ai_turn(silas)
	check(sb.enemies.size() == 4 and sb.enemies.slice(1).all(func(x): return x.enemy_id == "murder_of_crows"), "Crowstorm fills ranks 2-4 with crows")
	sb.enemies = [silas]
	sb._reindex()
	check(not "e_crane_storm" in sb.usable_skills(silas), "Crowstorm is once per fight")
	# The Oversized Pick stuns its own wielder; knocks weaken hits with a flat damage debuff.
	var kb := CombatEngine.new()
	kb.setup(party, ["tommyknocker"], {"rng": rng})
	var tk: Combatant = kb.enemies[0]
	kb.use_skill(tk, "e_knocker_pick", kb.heroes[0].id)
	check(tk.stunned, "Oversized Pick stuns the tommyknocker")
	var before := kb.dmg_preview(kb.heroes[0], "marshal_iron_justice", tk)
	kb.heroes[0].buffs.append({"stat": "dmg_flat", "value": -2, "rounds": 2, "name": "test"})
	var after := kb.dmg_preview(kb.heroes[0], "marshal_iron_justice", tk)
	check(after[1] < before[1], "flat damage debuff lowers hits (%s -> %s)" % [str(before), str(after)])
	# A volley that knocks a hero onto Death's Door can't finish them with its later shots.
	var dd := CombatEngine.new()
	dd.setup(party, ["silas_crane"], {"rng": rng, "boss": true})
	var victim: Combatant = dd.heroes[0]
	victim.set_hp(1)
	victim.hero.deaths_door = false
	for i in 30:
		dd._fresh_dd.clear()
		var evs: Array = []
		dd._apply_damage(victim, 5, dd.enemies[0], evs, false)
		dd._apply_damage(victim, 5, dd.enemies[0], evs, false)
		check(not victim.dead and victim.hero.deaths_door, "the knock-down hit and its follow-ups never kill")
		victim.hero.deaths_door = false
		victim.set_hp(1)


func test_hero_moves() -> void:
	var co := Company.new()
	co.new_game(21)
	# New heroes know their two stock moves plus two random others, all equipped.
	var seen := {}
	for i in 30:
		var h := co.make_hero("mountain_man")
		check(h.known.size() == 4 and h.equipped == h.known, "new hero knows and equips 4 moves")
		check(h.known.slice(0, 2) == h.cls().skills.slice(0, 2), "the first two class moves are always known")
		for s in h.known.slice(2):
			seen[s] = true
	check(seen.size() >= 4, "the other two starting moves vary (%d seen)" % seen.size())
	# Learning the rest at a Drill Hall.
	var hm := co.make_hero("marshal")
	hm.location = 0
	var unknown: Array = hm.cls().skills.filter(func(s): return not hm.knows(s))
	check(co.can_learn_skill(0, hm, unknown[0]) == "No Drill Hall here", "learning needs a Drill Hall")
	co.settlement(0).buildings["drill_hall"] = 1
	co.money = 5000
	check(co.can_upgrade_skill(0, hm, unknown[0]) == "Not learned yet", "can't train a move before learning it")
	check(co.learn_skill(0, hm, unknown[0]) and hm.knows(unknown[0]) and co.money == 5000 - co.learn_cost(0), "learn a move for chips")
	# Old saves: moves the class no longer has are dropped, and known moves are filled in.
	var d := hm.to_dict()
	d.erase("known")
	d.equipped = ["mm_knife_toss", "marshal_iron_justice"]
	var h2 := Hero.from_dict(d)
	check(h2.equipped == ["marshal_iron_justice"] and h2.known == ["marshal_iron_justice"], "old save moves sanitized")
	# New move effects.
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var party := [co.make_hero("marshal"), co.make_hero("mountain_man"), co.make_hero("gunslinger"), co.make_hero("preacher")]
	for h in party:
		h.known = h.cls().skills.duplicate()
	var e := CombatEngine.new()
	e.setup(party, ["buffalo_bull", "outlaw_brawler"], {"rng": rng})
	var marshal: Combatant = e.heroes[0]
	var mystic: Combatant = e.heroes[1]
	var bull: Combatant = e.enemies[0]
	var before := e.dmg_preview(marshal, "marshal_iron_justice", bull)
	e.use_skill(marshal, "marshal_ap_ammo", marshal.id)
	var after := e.dmg_preview(marshal, "marshal_iron_justice", bull)
	check(after[1] > before[1], "armor-piercing rounds get through the bull's hide (%s -> %s)" % [str(before), str(after)])
	e._end_turn(marshal, [])
	check(marshal.buff_total("pierce") == 20, "a self-buff isn't used up on the turn it's cast")
	var gs: Combatant = e.heroes[2]
	gs.stunned = true
	gs.buffs.append({"stat": "acc", "value": -10, "rounds": 2, "name": "test"})
	e.use_skill(marshal, "marshal_flash_badge", gs.id)
	check(not gs.stunned and gs.buff_total("acc") == 0 and gs.buff_total("speed") == 2, "Flash the Badge clears stun and debuffs, adds speed")
	var hp0 := mystic.hp
	var hurt: Combatant = e.heroes[3]
	hurt.set_hp(3)
	e._shift(mystic, -2, [])
	e.use_skill(mystic, "mm_piece_of_me", hurt.id)
	check(mystic.hp == hp0 - 4 and hurt.hp > 3 and hurt.buff_total("bleed_res") == 10, "Take a Piece of Me: 4 of the Mystic's HP heals an ally")
	mystic.set_hp(2)
	e.use_skill(mystic, "mm_piece_of_me", hurt.id)
	check(mystic.hp == 1, "blood price never drops below 1 HP")
	# Poisoner and Prospector mechanics.
	var p2 := [co.make_hero("sharpshooter"), co.make_hero("prospector"), co.make_hero("frontier_doctor"), co.make_hero("preacher")]
	for h in p2:
		h.known = h.cls().skills.duplicate()
	var e2 := CombatEngine.new()
	e2.setup(p2, ["outlaw_brawler", "outlaw_gunhand", "outlaw_rifleman", "outlaw_knifeman"], {"rng": rng})
	var poisoner: Combatant = e2.heroes[0]
	var pros: Combatant = e2.heroes[1]
	e2._shift(poisoner, -2, [])
	var foe: Combatant = e2.enemies[0]
	var plain := e2.dmg_mult(poisoner, "ss_sacrament", foe)
	poisoner.dots.append({"kind": "poison", "amount": 1, "rounds": 3})
	check(e2.dmg_mult(poisoner, "ss_sacrament", foe) > plain + 0.7, "Blighted Sacrament hits harder while the user is poisoned")
	foe.dots.append({"kind": "poison", "amount": 2, "rounds": 1})
	foe.buffs.append({"stat": "acc", "value": -5, "rounds": 1, "name": "x"})
	e2._apply_effect(poisoner, "ss_sight", {"type": "extend", "rounds": 1}, foe, [], false)
	check(foe.dots[0].rounds == 2 and foe.buffs[0].rounds == 2, "Gas Cloud makes poisons and debuffs linger")
	var back: Combatant = e2.enemies[3]
	e2._shift(pros, -2, [])
	var ev2 := e2.use_skill(pros, "pr_flash", back.id)
	var hit_ids: Array = ev2.filter(func(x): return x.t == "action")[0].targets
	check(hit_ids.size() == 2 and hit_ids.all(func(id): return e2.unit(id).rank >= 3), "Flash Powder hits the back pair when a back-liner is picked")
	e2.use_skill(pros, "pr_rock_hammer", e2.enemies[0].id)
	check(e2.valid_targets(pros, "pr_rock_hammer").is_empty(), "Depth Charge is once per fight")


func test_turn_order() -> void:
	var co := Company.new()
	co.new_game(31)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var party := [co.make_hero("gunslinger"), co.make_hero("marshal")]
	# No quirks: some (Early Riser, Slow Starter) change Speed in round 1 only.
	for h in party:
		h.quirks.clear()
	var e := CombatEngine.new()
	e.setup(party, ["outlaw_brawler", "prairie_wolf"], {"rng": rng})
	e._start_round()
	# By Speed plus this round's small roll: every unit once, highest first.
	var speeds: Array = e.queue.map(func(c): return int(c.stat("speed")) + c.speed_roll)
	var sorted_speeds := speeds.duplicate()
	sorted_speeds.sort()
	sorted_speeds.reverse()
	check(speeds == sorted_speeds and e.queue.size() == 4, "turn order follows Speed + roll, highest first (%s)" % str(speeds))
	check(e.queue.all(func(c): return c.speed_roll >= 1 and c.speed_roll <= int(DB.cfg("initiative_roll", 3))), "initiative roll is 1 to 3")
	check(e.queue.all(func(c): return c.actions_left == 1), "everyone starts the round with one action")
	# A mid-round Speed buff counts at once.
	var slow: Combatant = e.queue[e.queue.size() - 1]
	slow.buffs.append({"stat": "speed", "value": 50, "rounds": 2, "name": "test"})
	check(e._next_actor() == slow, "a Speed buff moves a unit up immediately")
	slow.buffs.clear()
	# Ties are a coin flip.
	var a: Combatant = e.heroes[0]
	var b: Combatant = e.heroes[1]
	var tie := int(a.stat("speed")) - int(b.stat("speed"))
	b.buffs.append({"stat": "speed", "value": tie, "rounds": 99, "name": "tie"})
	var a_first := 0
	for i in 400:
		e._start_round()
		var order := e._turn_order()
		if order.find(a) < order.find(b):
			a_first += 1
	check(a_first > 150 and a_first < 250, "equal Speed goes either way about half the time (%d/400)" % a_first)
	# A boss with two actions takes its second after everyone's first.
	var boss: Combatant = e.enemies[0]
	boss.data = boss.data.duplicate()
	boss.data["actions"] = 2
	e._start_round()
	var order2 := e._turn_order()
	check(order2.count(boss) == 2 and order2[order2.size() - 1] == boss, "second boss action comes after everyone's first")
	# Taking a turn spends the marker.
	var ev := e.step()
	var turn_ev: Array = ev.filter(func(x): return x.t == "turn")
	var who: Combatant = e.unit(turn_ev[0].actor)
	check(who.actions_left == who.actions_per_round() - 1, "taking a turn spends that unit's action marker")


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
		e._fresh_dd.clear()  # each blow is a separate move
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
			if not DB.regions[rid].has("fixed_map"):
				var caves := nodes.filter(func(x): return x.type == "cave").size()
				check(caves <= int(DB.regions[rid].get("max_caves", DB.cfg("max_caves", 2))), "%s has at most two caves (got %d)" % [rid, caves])
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
	check(co.settlements.size() == 1 and co.heroes.size() == 2 and co.roster_cap() == 6, "new game setup: two heroes, room for six")
	check(co.missing.size() == 1 and Hero.from_dict(co.missing[0]).class_id == "sharpshooter", "the sharpshooter is missing")
	check(co.can_do_activity(0, "saloon", "bar", co.heroes[0]) != "", "saloon is a ruin until the tutorial")
	co.complete_tutorial()
	co.money += 3000
	co.timber += 60
	co.iron += 40
	co.hides += 40
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
	co.hides += 30
	check(co.upgrade_track(0, "hiring_board", "notices"), "second notices upgrade in a town")
	check(co.can_upgrade_track(0, "hiring_board", "notices") != "", "track is capped")
	# Stage line needs a second settlement.
	check(co.can_send(0, 1, co.heroes[1]) != "", "can't send to unfounded site")
	co.beaten.append("tallgrass")
	co.money += 5000
	co.charters += 1
	co.timber += 50
	co.iron += 50
	co.hides += 50
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
	check(r.node(r.nodes.size() - 1).type == "boss" and "tut_pete" in r.node(r.nodes.size() - 1).data.enemies, "tutorial ends at Crowbar Pete")
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
	var md := co._make_quest("mad_dog", "tallgrass", 0)
	check(md.final == "boss" and "mad_dog_mulligan" in md.boss.enemies and md.done_flag == "mad_dog_beaten", "Mulligan waits at the end of his own rumor")
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
	co.hides += 50
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


## A saloon quest's boss (Mad Dog's hideout): win the fight and settle the expedition, as the
## combat screen does, including the text it shows (owner saw a crash on the killing blow).
func test_quest_boss() -> void:
	var co := Company.new()
	co.new_game(21)
	co.complete_tutorial()
	for cid in ["mountain_man", "preacher"]:
		co.heroes.append(co.make_hero(cid, 1))
	var west: String = co.site_by_index(0).get("region_west", "")
	check(west != "", "first settlement has a region to the west")
	var reg: Dictionary = co._make_quest("mad_dog", west, 1)
	co.quest_regions["q_test"] = reg
	DB.regions["q_test"] = reg
	var uids: Array = []
	for h in co.heroes.slice(0, 4):
		uids.append(h.uid)
	co.run = RunState.create(co, "q_test", 0, uids, {})
	check(co.run.party_heroes().size() >= 2, "quest party assembled (got %d of %d)" % [co.run.party_heroes().size(), uids.size()])
	var e := CombatEngine.new()
	e.setup(co.run.party_heroes(), reg.boss.enemies, co.run.combat_options("boss"))
	e.dev_win()
	check(e.state == "victory", "quest boss fight won (got %s)" % e.state)
	var res: Dictionary = co.run.after_combat(e, "boss")
	check("brass_knuckles" in res.keepsakes, "Mulligan drops the brass knuckles")
	check(co.story_flags.has("mad_dog_beaten"), "Mad Dog quest marked done")
	for k in res.keepsakes:
		check(k == "" or DB.keepsakes.has(k), "quest reward trinket %s exists" % k)
	check(str(DB.regions[co.run.region_id].boss.victory) != "", "quest boss has victory text")
	# Painted scenery: quests take the shared quest backdrop outdoors, never in a cave.
	var qb := str(DB.cfg("quest_backdrop", ""))
	var bd := Backdrop.new()
	bd.region_id = "q_test"
	bd.mode = "trail"
	check(qb == "" or bd._bg_candidates().has(qb), "quest uses the quest backdrop on the trail")
	bd.mode = "cave"
	check(not bd._bg_candidates().has(qb), "quest keeps its cave art in caves")
	bd.free()
	var summary := co.finish_run("victory")
	check(summary.status == "victory", "quest expedition settles")
	var d := JSON.parse_string(JSON.stringify(co.to_dict()))
	check(Company.from_dict(DB.normalize(d)) != null, "company saves after the quest")
	DB.regions.erase("q_test")


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



## Round 8 balance: Battlefield Surgery heals, then stuns and weakens the patient (round 9:
## the stun is back, owner); heals land in the ranges the owner set (heal_mult multiplies on top; 1.0 now).
func test_round8_balance() -> void:
	var co := Company.new()
	co.new_game(31)
	var doc := co.make_hero("frontier_doctor", 1)
	var pal := co.make_hero("marshal", 1)
	check(doc.max_hp() >= 18, "Frontier Doctor has 18 HP (got %d)" % doc.max_hp())
	check(int(DB.classes.preacher.speed) == 2, "Preacher speed 2")
	var e := CombatEngine.new()
	# Surgery is used from ranks 3-4, so the Doctor stands third.
	e.setup([pal, co.make_hero("gunslinger", 1), doc], ["outlaw_brawler"], {})
	var pc: Combatant = null
	var dc: Combatant = null
	for hc in e.heroes:
		if hc.hero == pal:
			pc = hc
		elif hc.hero == doc:
			dc = hc
	pc.hp = 3
	e.use_skill(dc, "dr_surgery", pc.id)
	var stuns := 0
	for k in 10:
		pc.stunned = false
		pc.stun_guard = 0
		e.use_skill(dc, "dr_surgery", pc.id)
		stuns += 1 if pc.stunned else 0
	check(stuns >= 7, "Surgery stuns the patient almost every time (%d of 10)" % stuns)
	pc.hp = 3
	pc.buffs.clear()
	e.use_skill(dc, "dr_surgery", pc.id)
	check(pc.buffs.any(func(b): return b.stat == "prot" and float(b.value) == -5.0), "Surgery leaves the patient at -5 Protection")
	check(pc.hp >= 3 + 8, "Surgery heals at least 8 (got %d)" % (pc.hp - 3))
	var hm: float = DB.cfg("heal_mult", 1.0)
	for pair in [["pc_hands", 6, 10], ["pc_revival", 1, 4], ["dr_surgery", 8, 12]]:
		var h: Dictionary = DB.skill(pair[0]).effects[0]
		var lo := int(round(int(h.min) * hm))
		var hi := int(round(int(h.max) * hm))
		check(lo == pair[1] and hi == pair[2], "%s heals %d-%d in game (got %d-%d)" % [pair[0], pair[1], pair[2], lo, hi])
	var deal: Dictionary = DB.skill("gb_card_toss")
	check(int(deal.acc) == 85 and int(deal.effects[0].amount) == 1, "Deal 'Em: acc 85, bleed 1")
	check(int(DB.skill("ss_kill_shot").effects[0].chance) == 70, "Bola Shot stun 70%")


## Vulnerable (+% damage taken, all sources), dispel, tag-conditioned effects, refresh and
## Transfusion (owner's round 8 picks).
## Hides, the third town material: skinned from beasts, spent on leatherwork.
func test_hides() -> void:
	var co := Company.new()
	co.new_game(37)
	check(co.hides == 0, "the company starts with no Hides")
	# Armor upgrades take Hides, weapons take Iron.
	var ac := co.gear_cost(0, "armor", 2)
	var wc := co.gear_cost(0, "weapon", 2)
	check(int(ac.get("hides", 0)) == 2 and not ac.has("iron") and int(wc.get("iron", 0)) == 2 and not wc.has("hides"), "armor costs Hides, weapons Iron (%s / %s)" % [ac, wc])
	check(Company.cost_text({"money": 10, "hides": 3}).contains("3 Hides"), "costs list Hides")
	check(not co.can_afford({"hides": 1}), "can't pay Hides you don't have")
	# A won fight against beasts drops Hides into the wagon.
	var uids: Array = []
	for h in co.heroes:
		uids.append(h.uid)
	var run := RunState.create(co, "tallgrass", 0, uids, {"food": 4})
	co.run = run
	var got := 0
	for k in 10:
		var e := CombatEngine.new()
		e.setup(co.heroes, ["buffalo_bull"], {})
		e.killed = ["buffalo_bull"]
		e.state = "victory"
		var res := run.after_combat(e, "fight")
		got += int(res.hides)
	check(got >= 20 and int(run.loot.hides) == mini(got, 25), "a buffalo always gives 2-3 Hides (%d over 10, %d carried)" % [got, int(run.loot.hides)])
	check(int(run.cargo().get("hides", 0)) == int(run.loot.hides), "Hides ride in the wagon")
	# Home: Hides join the company stock, and survive a save.
	var carried := int(run.loot.hides)
	co.finish_run("abandoned")
	check(co.hides == carried, "Hides come home (%d)" % co.hides)
	var co2 := Company.from_dict(DB.normalize(JSON.parse_string(JSON.stringify(co.to_dict()))))
	check(co2.hides == co.hides, "Hides save and load")


## Curio experts: class and survival skill shift the odds, add bonuses, work as keys.
func test_curio_experts() -> void:
	# Data: every expert is a class or survival skill, keys and swaps point at real things.
	for cid in DB.curios:
		var cu: Dictionary = DB.curios[cid]
		var ex: Dictionary = cu.get("experts", {})
		if ex.is_empty():
			continue
		check(cu.hand.any(func(o): return o.get("good", false)), "%s has a good outcome" % cid)
		for id in ex:
			check(DB.classes.has(id) or DB.survival.has(id), "%s expert %s is a class or skill" % [cid, id])
			if ex[id].has("as_key"):
				check(cu.get("keys", {}).has(ex[id].as_key), "%s: %s works as a real key" % [cid, id])
			for idx in ex[id].get("swap", {}):
				check(int(idx) < cu.hand.size(), "%s: %s swaps a real outcome" % [cid, id])
	var co := Company.new()
	co.new_game(41)
	var uids: Array = []
	for h in co.heroes:
		uids.append(h.uid)
	var run := RunState.create(co, "tallgrass", 0, uids, {"food": 4, "salt": 1})
	co.run = run
	var mk := func(cls: String, skills: Dictionary = {}) -> Hero:
		var h: Hero = co.make_hero(cls, 1)
		h.survival = {}
		for s in skills:
			h.survival[s] = {"rank": skills[s], "xp": 0}
		h.quirks = []
		return h
	# Odds: bad outcomes rarer for an expert, commoner for an averse class.
	var bad_rate := func(cid: String, h: Hero, n: int) -> float:
		var bad := 0
		for i in n:
			h.hp = h.max_hp()
			h.quirks = []
			var cu: Dictionary = DB.curios[cid]
			var res := run.interact_curio(cid, h)
			var good := false
			for o in cu.hand + cu.get("experts", {}).values().map(func(x): return x.get("swap", {}).values()).reduce(func(a, b): return a + b, []):
				if o.get("good", false) and res.text.ends_with(str(o.text).replace("{hero}", h.hero_name)):
					good = true
			if not good:
				bad += 1
		return float(bad) / n
	var plain: float = bad_rate.call("miners_cache", mk.call("marshal"), 600)
	var pro: float = bad_rate.call("miners_cache", mk.call("prospector"), 600)
	check(plain > 0.07 and pro < plain * 0.5, "a Prospector rarely sets off old powder (%.2f vs %.2f)" % [pro, plain])
	var miner1: float = bad_rate.call("ore_vein", mk.call("marshal", {"miner": 1}), 600)
	var miner3: float = bad_rate.call("ore_vein", mk.call("marshal", {"miner": 3}), 600)
	check(miner3 < miner1, "a rank-3 Miner beats a rank-1 Miner (%.2f vs %.2f)" % [miner3, miner1])
	var base_w: float = bad_rate.call("whiskey_barrel", mk.call("marshal"), 600)
	var pre_w: float = bad_rate.call("whiskey_barrel", mk.call("preacher"), 600)
	check(pre_w > base_w, "a Preacher fares worse at the whiskey barrel (%.2f vs %.2f)" % [pre_w, base_w])
	# A Gambler never picks up Drinker at the barrel.
	var gam: Hero = mk.call("gambler")
	var drank := false
	for i in 200:
		gam.quirks = []
		run.interact_curio("whiskey_barrel", gam)
		drank = drank or "drinker" in gam.quirks
	check(not drank, "a Gambler holds their liquor")
	# As key: a Preacher salts the grave without using Salt.
	var res := run.interact_curio("old_grave", mk.call("preacher"))
	check(res.key_worked and int(run.supplies.get("salt", 0)) == 1, "a Preacher works as Salt at a grave, no Salt used")
	# Bonus on a good outcome, labelled.
	var got_bonus := false
	var miner: Hero = mk.call("marshal", {"miner": 2})
	for i in 30:
		var r := run.interact_curio("ore_vein", miner)
		got_bonus = got_bonus or r.msgs.any(func(m): return str(m).begins_with("★ Miner 2"))
	check(got_bonus, "a Miner's bonus shows with a ★")
	# Swap: the Marshal never meets the rider's friends; collects instead.
	var mar: Hero = mk.call("marshal")
	var ambushed := false
	for i in 200:
		ambushed = ambushed or run.interact_curio("dead_horse", mar).fight != null
	check(not ambushed, "the Marshal turns the Dead Horse ambush into a bounty")
	# Quick draw: a Gunslinger's curio ambush strikes first.
	var gun: Hero = mk.call("gunslinger")
	var fight: Variant = null
	for i in 300:
		gun.hp = gun.max_hp()
		var r := run.interact_curio("scarecrow", gun)
		if r.fight != null:
			fight = r.fight
			break
	check(fight != null and fight.surprise == "enemies", "a Gunslinger strikes first at a curio ambush")
	# Picker hints.
	check(run.curio_hint("railroad_crate", mk.call("mountain_man")).begins_with("✗"), "averse heroes show a ✗")
	check(run.curio_hint("ore_vein", mk.call("prospector")).contains("works as Shovel"), "as-key experts say so")
	check(run.curio_hint("scarecrow", mk.call("gunslinger")).contains("strikes first"), "quick draw shows at ambush curios")
	check(run.curio_hint("ore_vein", mk.call("marshal")) == "", "no hint for a hero with nothing to offer")
	# Quirk interactions: two good, two bad, 15% each.
	var qs := {}
	for cid in DB.curios:
		for o in DB.curios[cid].get("hand", []):
			for e in o.get("effects", []):
				if e.get("type", "") == "quirk" and int(e.get("chance", 100)) == 15:
					qs[e.quirk] = true
	check(qs.has("afraid_of_snakes") and qs.has("claustrophobic") and qs.has("myth_buster") and qs.has("iron_stomach"), "curio quirk chances are in (%s)" % [qs.keys()])


## Round 9 town: the free porch seat on the Hiring Board, the bigger first Bunkhouse.
func test_round9_town() -> void:
	var co := Company.new()
	co.new_game(29)
	var a: Hero = co.heroes[0]
	var b: Hero = co.heroes[1]
	a.fatigue = 60
	b.fatigue = 60
	co.money = 0
	check(co.can_do_activity(0, "hiring_board", "porch", a) == "", "the porch is free (no chips needed)")
	co.do_activity(0, "hiring_board", "porch", a)
	check(a.fatigue >= 45 and a.fatigue < 60, "the porch takes off up to 15 Fatigue (now %d)" % a.fatigue)
	check(co.can_do_activity(0, "hiring_board", "porch", b) != "", "the porch has one seat a week")
	check(int(DB.cfg("xp_levels", [])[1]) == 19, "XP thresholds +25% (level 2 at 19)")
	var base := co.roster_cap()
	co.settlement(0)["tracks"] = {"hiring_board": {"bunks": 1}}
	check(co.roster_cap() == base + 4, "first Bunkhouse: +4 bunks (%d -> %d)" % [base, co.roster_cap()])


## Round 9 trinket pass: class trinkets (class lock, move bonuses) and the new hooks.
func test_trinket_pass() -> void:
	var n_class := 0
	for k in DB.keepsakes:
		var d = DB.keepsakes[k]
		if not d is Dictionary:
			continue
		var kc: String = d.get("class", "")
		if kc != "":
			n_class += 1
			check(DB.classes.has(kc), "%s: class %s exists" % [k, kc])
		for sid in d.get("skill_mods", {}):
			check(DB.skills.has(sid) and (kc == "" or sid in DB.classes[kc].skills or DB.classes[kc].get("mega", "") == sid), "%s: move %s belongs to its class" % [k, sid])
	check(n_class == 22, "22 class trinkets (got %d)" % n_class)
	var co := Company.new()
	co.new_game(23)
	var mar := co.make_hero("marshal", 1)
	var wr := co.make_hero("wrangler", 1)
	var rd := co.make_hero("rail_driver", 1)
	var doc := co.make_hero("frontier_doctor", 1)
	for h in [mar, wr, rd, doc]:
		h.quirks.clear()
	co.heroes = [mar, wr, rd, doc]
	# Class lock.
	co.stash = ["tin_star", "tin_star"]
	check(co.keepsake_block(wr, "tin_star") == "Marshal only" and not co.equip_keepsake(wr, "tin_star"), "a Wrangler can't wear the Tin Star")
	check(co.equip_keepsake(mar, "tin_star"), "the Marshal can")
	var e := CombatEngine.new()
	e.setup([mar, wr, rd, doc], ["outlaw_brawler", "outlaw_gunhand", "outlaw_rifleman", "outlaw_knifeman"], {})
	var m: Combatant = e.heroes[0]
	var w: Combatant = e.heroes[1]
	var r: Combatant = e.heroes[2]
	var dc: Combatant = e.heroes[3]
	var foe: Combatant = e.enemies[0]
	# No resisting in these checks (effect chances cap at 95%).
	for en in e.enemies:
		for rs in ["move_res", "bleed_res", "poison_res"]:
			en.buffs.append({"stat": rs, "value": -500, "rounds": 99, "name": "test"})
	# Tin Star: +15 Prot while Guarding or Taunting.
	var p0 := m.stat("prot")
	m.taunt = 2
	check(m.stat("prot") == minf(80.0, p0 + 15), "Tin Star: +15 Prot while Taunting")
	m.taunt = 0
	# Bench Warrant Book: Warrant marks a round longer; Iron Justice +15% damage.
	mar.keepsakes = ["warrant_book"]
	e._apply_effect(m, "marshal_warrant", {"type": "mark", "rounds": 3}, foe, [], false)
	check(foe.mark == 4, "Warrant Book: the Warrant marks 4 rounds (got %d)" % foe.mark)
	foe.mark = 0
	mar.keepsakes = []
	var ij0 := e.dmg_mult(m, "marshal_iron_justice", foe)
	mar.keepsakes = ["warrant_book"]
	check(is_equal_approx(e.dmg_mult(m, "marshal_iron_justice", foe) - ij0, 0.15), "Warrant Book: Iron Justice +15%")
	# Golden Spike: Hammerfell knocks back one more rank.
	rd.keepsakes = ["golden_spike"]
	for tries in 20:
		e._apply_effect(r, "rd_hammer_blow", {"type": "knockback", "amount": 1, "chance": 1000}, foe, [], false)
		if foe.rank != 1:
			break
	check(foe.rank == 3, "Golden Spike: knocked back 2 ranks (rank %d)" % foe.rank)
	e._shift(foe, 2, [])
	# Collar: Sic 'Em bleeds 1 more.
	wr.keepsakes = ["biscuit_collar"]
	foe.dots.clear()
	for tries in 20:
		e._apply_effect(w, "wr_sic_em", {"type": "bleed", "amount": 2, "rounds": 3, "chance": 1000}, foe, [], false)
		if not foe.dots.is_empty():
			break
	check(not foe.dots.is_empty() and int(foe.dots[0].amount) == 3, "Collar: Sic 'Em bleeds 3")
	# Riata: Lasso pulls one more rank.
	wr.keepsakes = ["rawhide_riata"]
	var back: Combatant = e.enemies[3]
	for tries in 20:
		e._apply_effect(w, "wr_lasso", {"type": "pull", "amount": 2, "chance": 1000}, back, [], false)
		if back.rank != 4:
			break
	check(back.rank == 1, "Riata: Lasso pulls 3 ranks (rank %d)" % back.rank)
	# Surgical Kit: heals given +20%.
	doc.keepsakes = []
	r.set_hp(1)
	var evh: Array = []
	e._heal(dc, r, 10, false, evh)
	var h0 := r.hp - 1
	doc.keepsakes = ["surgical_kit"]
	r.set_hp(1)
	e._heal(dc, r, 10, false, evh)
	check(r.hp - 1 == int(round(h0 * 1.2)), "Surgical Kit: heals 20%% more (%d -> %d)" % [h0, r.hp - 1])
	# Prospector caps, Poisoner dart case, Gris-Gris, Hopper lantern and watch, Gambler deck.
	var pr := co.make_hero("prospector", 1)
	var bp := co.make_hero("sharpshooter", 1)
	var th := co.make_hero("train_hopper", 1)
	var gb := co.make_hero("gambler", 1)
	for h in [pr, bp, th, gb]:
		h.quirks.clear()
	var e2 := CombatEngine.new()
	th.keepsakes = ["brakemans_lantern", "pocket_watch"]
	e2.setup([pr, bp, th, gb], ["outlaw_brawler", "outlaw_gunhand"], {})
	var pc: Combatant = e2.heroes[0]
	var bc: Combatant = e2.heroes[1]
	var tc: Combatant = e2.heroes[2]
	var gc: Combatant = e2.heroes[3]
	var f2: Combatant = e2.enemies[0]
	f2.buffs.append({"stat": "poison_res", "value": -500, "rounds": 99, "name": "test"})
	check(tc.momentum == 20, "Brakeman's Lantern: starts at 20 Momentum (got %d)" % tc.momentum)
	e2._momentum(tc, 20, "", [])
	check(tc.momentum == 45, "Pocket Watch: a 20 gain gives 25 (got %d)" % tc.momentum)
	var st := {"type": "stun", "chance": 50}
	var s0 := e2.effect_chance(pc, "pr_blasting_cap", st, f2)
	pr.keepsakes = ["blasting_caps"]
	check(e2.effect_chance(pc, "pr_blasting_cap", st, f2) == s0 + 15, "Blasting Caps: +15% stun")
	bp.keepsakes = ["gator_darts"]
	f2.dots.clear()
	for tries in 20:
		e2._apply_effect(bc, "ss_sacrament", {"type": "poison", "amount": 3, "rounds": 3, "chance": 1000}, f2, [], false)
		if not f2.dots.is_empty():
			break
	check(int(f2.dots[0].amount) == 4, "Gator-Tooth Darts: poison +1")
	bp.keepsakes = ["gris_gris"]
	var gd0 := e2.dmg_mult(bc, "ss_suppress", f2)
	bc.dots.append({"kind": "poison", "amount": 1, "rounds": 2})
	check(is_equal_approx(e2.dmg_mult(bc, "ss_suppress", f2) - gd0, 0.2), "Gris-Gris: +20% while poisoned")
	gb.keepsakes = ["marked_deck"]
	gc.buffs.clear()
	e2._apply_effect(gc, "gb_stacked", {"type": "random_buff", "pool": [{"stat": "acc", "value": 10}], "rounds": 3}, gc, [], false)
	check(gc.buffs.any(func(b): return b.stat == "acc" and int(b.value) == 15), "Marked Deck: a +10 card deals +15")


## Round 9 quirk pass (owner's numbers): conditional quirks and the behaviour ones.
func test_quirk_pass() -> void:
	var co := Company.new()
	co.new_game(17)
	check(DB.quirks.size() - (1 if DB.quirks.has("_comment") else 0) == 50, "50 quirks")
	check(DB.quirks.values().filter(func(q): return q is Dictionary and q.get("positive", false)).size() == 26, "26 positive quirks")
	check(DB.quirks.quick_hands.name == "Quick Feet" and DB.quirks.nearsighted.name == "Homesick", "renames keep their ids")
	var gs := co.make_hero("gunslinger", 1)
	var mar := co.make_hero("marshal", 1)
	for h in [gs, mar]:
		h.quirks.clear()
	var e := CombatEngine.new()
	e.setup([mar, gs], ["outlaw_brawler", "outlaw_gunhand"], {})
	var g: Combatant = e.heroes[1]
	var m: Combatant = e.heroes[0]
	var foe: Combatant = e.enemies[0]
	# Manhunter: more damage and accuracy against a Marked target.
	gs.quirks = ["manhunter"]
	var d0 := e.dmg_mult(g, "gs_quick_draw", foe)
	var a0 := e.hit_chance(g, "gs_quick_draw", foe)
	foe.mark = 2
	check(is_equal_approx(e.dmg_mult(g, "gs_quick_draw", foe) - d0, 0.15) and e.hit_chance(g, "gs_quick_draw", foe) > a0, "Manhunter: +15% damage, +5 acc vs Marked")
	foe.mark = 0
	# Opportunist: crit vs a Vulnerable target.
	gs.quirks = ["opportunist"]
	var c0 := e.crit_chance(g, "gs_quick_draw", foe)
	foe.buffs.append({"stat": "vulnerable", "value": 10, "rounds": 2, "name": "t"})
	check(e.crit_chance(g, "gs_quick_draw", foe) == c0 + 6, "Opportunist: +6% crit vs Vulnerable")
	foe.buffs.clear()
	# Final Gambit: +50% damage, +8 dodge on Death's Door.
	gs.quirks = ["final_gambit"]
	var dd0 := e.dmg_mult(g, "gs_quick_draw", foe)
	var dg0 := g.stat("dodge", foe)
	gs.deaths_door = true
	check(is_equal_approx(e.dmg_mult(g, "gs_quick_draw", foe) - dd0, 0.5) and g.stat("dodge", foe) == dg0 + 8, "Final Gambit on Death's Door")
	gs.deaths_door = false
	# Early Riser / Slow Starter: round 1 only.
	gs.quirks = ["early_riser"]
	g.round_num = 1
	var s1 := g.stat("speed")
	g.round_num = 2
	check(s1 == g.stat("speed") + 4, "Early Riser: +4 Speed in round 1 only")
	gs.quirks = ["slow_starter"]
	g.round_num = 1
	s1 = g.stat("speed")
	g.round_num = 2
	check(s1 == g.stat("speed") - 4, "Slow Starter: -4 Speed in round 1 only")
	# Lightning Rod: while Marked.
	mar.quirks = ["lightning_rod"]
	var p0 := m.stat("prot")
	m.mark = 2
	check(m.stat("prot") == minf(80.0, p0 + 10), "Lightning Rod: +10 Prot while Marked")
	m.mark = 0
	# Glass Jaw and Hothead: Vulnerable.
	gs.quirks = ["glass_jaw"]
	check(is_equal_approx(g.vuln_mult(), 1.1), "Glass Jaw: Vulnerable 10%")
	# Quick Study / Simple: XP.
	gs.quirks = ["quick_study"]
	check(gs.stat("xp_pct") == 10, "Quick Study: +10% XP")
	gs.quirks = ["simple"]
	check(gs.stat("xp_pct") == -10, "Simple: -10% XP")
	# Homesick: Fatigue after every fight.
	co.heroes = [gs, mar]
	gs.quirks = ["nearsighted"]
	var run := RunState.create(co, "tallgrass", 0, [gs.uid, mar.uid], {})
	co.run = run
	var f0 := gs.fatigue
	var won := CombatEngine.new()
	won.setup([gs, mar], ["outlaw_brawler"], {})
	won.state = "victory"
	run.after_combat(won, "fight")
	check(gs.fatigue == f0 + 1, "Homesick: +1 Fatigue after a fight (%d -> %d)" % [f0, gs.fatigue])
	# Gold Fever: pockets the money from a treasure curio searched by hand.
	gs.quirks = ["gold_fever"]
	var cash0 := int(run.loot.money)
	for k in 12:
		run.interact_curio("strongbox", gs)
	check(int(run.loot.money) == cash0, "Gold Fever keeps the strongbox money (loot %d -> %d)" % [cash0, int(run.loot.money)])
	# Drinker: forced to 100% here, they spend the week after the expedition at the saloon.
	var saved := int(DB.quirks.drinker.bar_lock)
	DB.quirks.drinker.bar_lock = 100
	mar.quirks = ["drinker"]
	var sm := co.finish_run("victory")
	DB.quirks.drinker.bar_lock = saved
	check(mar.busy_weeks == 1 and mar.busy_reason.contains("saloon") and sm.week_msgs.any(func(x): return str(x).contains(mar.hero_name)), "Drinker stays at the saloon a week (busy %d)" % mar.busy_weeks)


## The Train Hopper: a Momentum gauge filled by moving, spent on End of the Line.
func test_train_hopper() -> void:
	var co := Company.new()
	co.rng.seed = 33
	var th_h := co.make_hero("train_hopper", 1)
	var mar_h := co.make_hero("marshal", 1)
	var gs_h := co.make_hero("gunslinger", 1)
	var doc_h := co.make_hero("frontier_doctor", 1)
	for h in [th_h, mar_h, gs_h, doc_h]:
		h.quirks.clear()
	check(th_h.known.slice(0, 2) == ["th_boxcar_leap", "th_stowaway"], "Boxcar Leap and Stowaway are her stock moves")
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	var e := CombatEngine.new()
	# Party order: Marshal, Gunslinger, Doctor, Hopper (rank 4).
	e.setup([mar_h, gs_h, doc_h, th_h], ["outlaw_brawler", "outlaw_gunhand", "outlaw_rifleman"], {"rng": rng})
	var th: Combatant = e.heroes[3]
	var doc: Combatant = e.heroes[2]
	check(th.uses_momentum() and th.momentum == 0 and not doc.uses_momentum(), "only the Hopper has a gauge, and it starts empty")
	# Boxcar Leap from rank 4: +30 and she moves forward 1.
	e.current = th
	e.use_skill(th, "th_boxcar_leap", e.enemies[0].id)
	check(th.momentum == 30 and th.rank == 3, "Boxcar Leap: +30 Momentum, forward 1 (got %d, rank %d)" % [th.momentum, th.rank])
	check(doc.momentum == 0, "the ally she displaced has no gauge")
	# Moved by someone else: +10. The Doctor swaps her back.
	e.current = doc
	var ev: Array = []
	e._shift(doc, 1, ev)
	check(th.momentum == 40 and ev.any(func(x): return x.t == "momentum" and x.why == "moved"), "shoved by an ally: +10 (got %d)" % th.momentum)
	# Losing steam: a turn that ends where it began costs 10.
	th.turn_rank = th.rank
	e._end_turn(th, ev)
	check(th.momentum == 30, "ending a turn without moving: -10 (got %d)" % th.momentum)
	# Full Steam at 50+: +3 Speed, +5 Dodge.
	var spd := th.stat("speed")
	var ddg := th.stat("dodge")
	th.momentum = 50
	check(th.stat("speed") == spd + 3 and th.stat("dodge") == ddg + 5, "Full Steam: +3 Speed, +5 Dodge")
	# Catch Out: swaps with any ally (not just a neighbour), who gains +10 Protection; +20.
	th.momentum = 0
	var mar: Combatant = e.heroes[0]
	var r_th := th.rank
	var prot0 := mar.stat("prot")
	e.current = th
	e.use_skill(th, "th_catch_out", mar.id)
	check(th.rank == 1 and mar.rank == r_th and mar.stat("prot") == prot0 + 10 and th.momentum == 20, "Catch Out swaps with a far ally, +10 Prot, +20 Momentum")
	# End of the Line only exists on a full gauge.
	check(e.mega_skill(th) == "" and e.valid_targets(th, "th_end_of_line").is_empty(), "no mega below 100")
	th.momentum = 100
	check(e.mega_skill(th) == "th_end_of_line" and e.valid_targets(th, "th_end_of_line").size() == 3, "End of the Line at 100, any rank")
	# Half Protection, and +50% vs Marked.
	var tgt: Combatant = e.enemies[2]
	tgt.buffs.append({"stat": "prot", "value": 40, "rounds": 3, "name": "Test"})
	check(is_equal_approx(e._prot_taken(th, DB.skill("th_end_of_line"), tgt), 0.2), "End of the Line ignores half of 40 Protection")
	var unm: Array = e.dmg_preview(th, "th_end_of_line", tgt)
	tgt.mark = 2
	var mk: Array = e.dmg_preview(th, "th_end_of_line", tgt)
	check(mk[1] > unm[1], "End of the Line hits a Marked target harder (%s -> %s)" % [unm, mk])
	tgt.buffs.clear()
	# Spending it: the gauge empties, she lands in rank 1; a kill gives back 20.
	tgt.hp = 1
	_swap_to(e, th, 3)
	e.current = th
	th.turn_rank = th.rank
	ev = e.use_skill(th, "th_end_of_line", tgt.id)
	var killed := tgt.dead or ev.any(func(x): return x.t == "death" and x.target == tgt.id)
	check(th.rank == 1, "she lands in rank 1 (rank %d)" % th.rank)
	check(th.momentum == (20 if killed else 0), "gauge empties, gets 20 back on a kill (killed %s, got %d)" % [killed, th.momentum])
	e._end_turn(th, ev)
	check(th.momentum == (20 if killed else 0), "no steam lost on the turn she spent it")
	# Stunned: -25.
	th.momentum = 40
	th.stunned = true
	e.current = null
	var guard := 0
	while e.current != th and guard < 20:
		guard += 1
		e.state = "running"
		th.actions_left = 1
		for o in e.heroes + e.enemies:
			if o != th:
				o.actions_left = 0
		e.step()
	check(th.momentum == 15, "a lost turn to a stun: -25 (got %d)" % th.momentum)
	# A bot fight with her in the party still finishes, and she gets her mega off sometimes.
	var bot := Bot.new(6)
	var party: Array = [co.make_hero("rail_driver", 2), co.make_hero("train_hopper", 2), co.make_hero("gunslinger", 2), co.make_hero("preacher", 2)]
	var e2 := bot.fight(party, ["outlaw_brawler", "outlaw_gunhand", "outlaw_rifleman", "outlaw_knifeman"], {"rng": rng})
	check(e2.is_over(), "bot fight with a Train Hopper finishes (%s)" % e2.state)
	var megas := 0
	var fights := 0
	for k in 12:
		var p2: Array = [co.make_hero("rail_driver", 2), co.make_hero("train_hopper", 2), co.make_hero("gunslinger", 2), co.make_hero("preacher", 2)]
		var ek := bot.fight(p2, ["outlaw_brawler", "outlaw_gunhand", "outlaw_rifleman", "outlaw_knifeman"], {"rng": rng})
		fights += 1
		for hc in ek.heroes:
			if hc.uses_momentum() and "th_end_of_line" in hc.used_skills:
				megas += 1
	print("    Train Hopper reached End of the Line in %d of %d bot fights" % [megas, fights])
	check(megas > 0, "the bot fills the gauge and fires End of the Line")


func _swap_to(e: CombatEngine, c: Combatant, rank: int) -> void:
	var line := e.side_of(c)
	line.erase(c)
	line.insert(rank - 1, c)
	e._reindex()


## Owner's DD rule: a fallen enemy leaves 2-HP bones in its rank; the line only slides up
## once they're destroyed.
func test_bones() -> void:
	var co := Company.new()
	co.rng.seed = 21
	var party := _party(co, ["marshal", "gunslinger", "frontier_doctor", "preacher"])
	var rng := RandomNumberGenerator.new()
	rng.seed = 8
	var e := CombatEngine.new()
	e.setup(party, ["outlaw_brawler", "outlaw_gunhand", "outlaw_rifleman"], {"rng": rng})
	var mar: Combatant = e.heroes[0]
	var gunhand: Combatant = e.enemies[1]
	var ev: Array = []
	e._apply_damage(e.enemies[0], 999, mar, ev, false)
	e._cleanup(ev)
	var bones: Combatant = e.enemies[0]
	check(e.enemies.size() == 3 and bones.corpse and bones.hp == 2 and bones.rank == 1, "a fallen enemy leaves 2-HP bones in its rank")
	check(gunhand.rank == 2, "the enemy behind the bones doesn't step up (rank %d)" % gunhand.rank)
	check(ev.any(func(x): return x.t == "bones" and x.unit == bones.id), "bones event for the screen")
	check(e.killed.count("outlaw_brawler") == 1 and e.state == "running", "the kill counts once; the fight goes on")
	check(bones.id in e.valid_targets(mar, "marshal_iron_justice"), "bones can be targeted")
	check(not e._turn_order().has(bones), "bones never take a turn")
	# Bones shrug off effects: a Warrant never marks them.
	for k in 8:
		e._resolve_attack(mar, "marshal_warrant", DB.skill("marshal_warrant"), bones, [])
	check(bones.mark == 0 and bones.buffs.is_empty(), "bones take no effects")
	# Smash them: now the line slides forward, and it isn't a kill.
	ev = []
	e._apply_damage(bones, 3, mar, ev, false)
	e._cleanup(ev)
	check(e.enemies.size() == 2 and gunhand.rank == 1, "destroyed bones let the line slide up")
	check(e.killed.size() == 1 and ev.any(func(x): return x.t == "death" and x.get("bones", false)), "smashed bones aren't a kill")
	# The last foe standing leaves no bones: victory, even with bones still on the field.
	ev = []
	e._apply_damage(gunhand, 999, mar, ev, false)
	e._cleanup(ev)
	check(e.enemies[0].corpse and e.state == "running", "bones where the gunhand fell")
	ev = []
	e._apply_damage(e.enemies[1], 999, mar, ev, false)
	e._cleanup(ev)
	check(e.state == "victory" and not ev.any(func(x): return x.t == "bones"), "the last kill wins, bones or not")
	# A summoner on a full line kicks aside bones to make room.
	var sb := CombatEngine.new()
	sb.setup(party, ["silas_crane", "outlaw_brawler", "outlaw_gunhand", "outlaw_rifleman"], {"rng": rng, "boss": true})
	ev = []
	sb._apply_damage(sb.enemies[1], 999, sb.heroes[0], ev, false)
	sb._cleanup(ev)
	check(sb.enemies[1].corpse and "e_crane_storm" in sb.usable_skills(sb.enemies[0]), "Crowstorm has room: bones can be swept aside")
	sb.use_skill(sb.enemies[0], "e_crane_storm", sb.heroes[0].id)
	check(sb.enemies.size() == 4 and not sb.enemies.any(func(x): return x.corpse) and sb.enemies[1].enemy_id == "murder_of_crows", "a crow takes the bones' rank")
	# A whole bot fight still ends.
	var bot := Bot.new(4)
	var e2 := bot.fight(_party(co, ["rail_driver", "wrangler", "prospector", "frontier_doctor"]), ["prairie_wolf", "coyote", "carrion_crows", "prairie_wolf"], {"rng": rng})
	check(e2.is_over(), "bot fight with bones finishes (%s)" % e2.state)


func test_vulnerable_and_new_moves() -> void:
	var co := Company.new()
	co.new_game(41)
	var mar := co.make_hero("marshal", 1)
	var gs := co.make_hero("gunslinger", 1)
	var doc := co.make_hero("frontier_doctor", 1)
	var pre := co.make_hero("preacher", 1)
	var e := CombatEngine.new()
	e.setup([mar, gs, doc, pre], ["outlaw_brawler", "prairie_haint"], {})
	var by := {}
	for hc in e.heroes:
		by[hc.hero.cls().name] = hc
	var brawler: Combatant = e.enemies[0]
	var haint: Combatant = e.enemies[1]
	# Vulnerable raises hit damage (preview and real) and damage over time.
	var before: Array = e.dmg_preview(by["Gunslinger"], "gs_quick_draw", brawler)
	brawler.buffs.append({"stat": "vulnerable", "value": 50, "rounds": 2, "name": "Test"})
	var after: Array = e.dmg_preview(by["Gunslinger"], "gs_quick_draw", brawler)
	check(after[1] > before[1], "Vulnerable raises damage (%s -> %s)" % [before, after])
	brawler.dots = [{"kind": "bleed", "amount": 4, "rounds": 1}]
	var hp0 := brawler.hp
	e._start_turn(brawler)
	check(hp0 - brawler.hp == 6, "Vulnerable 50%% makes a 4 bleed tick hit for 6 (got %d)" % (hp0 - brawler.hp))
	check(not Stats.mod_is_good({"stat": "vulnerable", "value": 10}), "Vulnerable counts as a debuff")
	# A debuff cure clears it.
	e._apply_effect(by["Marshal"], "marshal_flash_badge", {"type": "cure", "kinds": ["debuff"]}, brawler, [], false)
	check(not brawler.buffs.any(func(b): return b.stat == "vulnerable"), "cure debuff removes Vulnerable")
	# Dispel washes away boons and leaves debuffs.
	haint.buffs = [{"stat": "dodge", "value": 20, "rounds": 3, "name": "Boon"}, {"stat": "acc", "value": -5, "rounds": 3, "name": "Bane"}]
	e._apply_effect(by["Preacher"], "pc_baptism", {"type": "dispel"}, haint, [], false)
	check(haint.buffs.size() == 1 and float(haint.buffs[0].value) < 0, "dispel strips boons, keeps debuffs")
	# chance_vs: Hellfire is base 100% vs mythic, 75% otherwise (minus resistance).
	var hf: Dictionary = DB.skill("pc_hellfire").effects[0]
	check(e.effect_chance(by["Preacher"], "pc_hellfire", hf, haint) > e.effect_chance(by["Preacher"], "pc_hellfire", hf, brawler), "Hellfire sticks better on mythic foes")
	# if_tag: Baptism's stun only ever lands on mythic targets.
	var stunned_plain := false
	for k in 30:
		brawler.stunned = false
		var ev: Array = []
		for ef in DB.skill("pc_baptism").effects:
			if ef.has("if_tag") and not str(ef.if_tag) in brawler.tags:
				continue
			e._apply_effect(by["Preacher"], "pc_baptism", ef, brawler, ev, false)
		stunned_plain = stunned_plain or brawler.stunned
	check(not stunned_plain, "Baptism never stuns a non-mythic foe")
	# refresh: a recast doesn't stack the same move's debuff.
	brawler.buffs.clear()
	for k in 12:
		e._apply_effect(by["Marshal"], "wr_hogtie", DB.skill("wr_hogtie").effects.back(), brawler, [], false)
	var vul := brawler.buffs.filter(func(b): return b.stat == "vulnerable").size()
	check(vul == 1, "Hogtie's Vulnerable lands, and refreshes instead of stacking (got %d)" % vul)
	# Owner's picks: Vulnerable on five plain attacks, and a Marked payoff for each marker.
	for sid in ["pr_pickaxe", "pc_smite", "gs_point_blank", "rd_sledge_toss", "mm_axe_cleave"]:
		check(DB.skill(sid).effects.any(func(ef): return ef.get("stat", "") == "vulnerable"), "%s applies Vulnerable" % sid)
	brawler.buffs.clear()
	for sid in ["marshal_iron_justice", "gb_money_shot", "rd_hammer_blow", "pc_judgment"]:
		check(float(DB.skill(sid).get("vs_marked", 0)) > 0 and not DB.skill(sid).get("effects", []).any(func(ef): return ef.get("stat", "") == "vulnerable"), "%s pays off on Marked, without Vulnerable" % sid)
	brawler.mark = 0
	var unmarked: Array = e.dmg_preview(by["Marshal"], "marshal_iron_justice", brawler)
	brawler.mark = 2
	var marked: Array = e.dmg_preview(by["Marshal"], "marshal_iron_justice", brawler)
	check(marked[1] > unmarked[1], "Iron Justice hits harder on a Marked target (%s -> %s)" % [unmarked, marked])
	brawler.mark = 0
	# Marking moves don't also apply Vulnerable (owner: no double dip).
	for sid in ["marshal_warrant", "rd_quarrel", "gb_joker"]:
		check(not DB.skill(sid).effects.any(func(ef): return ef.get("stat", "") == "vulnerable"), "%s marks without Vulnerable" % sid)
	# Transfusion heals the most wounded ally.
	var gsc: Combatant = by["Gunslinger"]
	gsc.set_hp(3)
	var gs_hp: int = gsc.hp
	var dc: Combatant = by["Frontier Doctor"]
	var healed := false
	for k in 12:
		var ev2: Array = []
		brawler.hp = brawler.max_hp
		e._transfuse(dc, "dr_transfusion", 6.0, ev2)
		healed = healed or gsc.hp > gs_hp
	check(healed, "Transfusion heals the most wounded ally")
	check(DB.classes.preacher.skills.size() == 8 and DB.classes.frontier_doctor.skills.size() == 8, "Preacher and Doctor have 8 moves")


## Economy probe (econ=N): N fresh companies each run 3 expeditions from Fort Providence
## (the tutorial done), and the average timber and iron each expedition brings home.
func econ_probe(n: int) -> void:
	var tim := 0
	var irn := 0
	var chips := 0
	var won := 0
	var by_status := {}
	var runs := 0
	var by_region := {}
	for s in n:
		var co := Company.new()
		co.new_game(100 + s)
		var bot := Bot.new(100 + s)
		bot.cautious = true
		co.complete_tutorial()
		for k in 3:
			while co.heroes_at(0).filter(func(x): return x.available()).size() < 4 and not co.settlement(0).recruits.is_empty():
				if co.hire(0, 0) == null:
					break
			var t0 := co.timber
			var i0 := co.iron
			var m0 := co.money - co.supply_cost(0, {})
			var reg := ""
			var r: Dictionary = bot.play_expedition(co, 0)
			reg = str(r.get("region", ""))
			if r.get("status", "") in ["no_run"]:
				continue
			runs += 1
			by_status[r.get("status", "")] = by_status.get(r.get("status", ""), 0) + 1
			if r.get("status", "") != "defeat":
				won += 1
				chips += int(r.get("loot", {}).get("money", 0))
			tim += co.timber - t0
			irn += co.iron - i0
			if not by_region.has(reg):
				by_region[reg] = [0, 0, 0]
			by_region[reg][0] += 1
			by_region[reg][1] += co.timber - t0
			by_region[reg][2] += co.iron - i0
	print("ECON %d expeditions: timber %.1f, iron %.1f per expedition; %d came home, %.0f chips each; %s" % [runs, tim / maxf(1, runs), irn / maxf(1, runs), won, chips / maxf(1, won), by_status])
	for reg in by_region:
		var v: Array = by_region[reg]
		print("  %s: %d runs, timber %.1f, iron %.1f" % [reg, v[0], v[1] / maxf(1, v[0]), v[2] / maxf(1, v[0])])
