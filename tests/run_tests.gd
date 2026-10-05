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
	test_fatigue_states()
	test_event_pass()
	test_starter_quest()
	test_money_shot()
	test_iron_justice()
	test_high_noon()
	test_skill_checks()
	test_minigame_tuning()
	test_townsfolk()
	test_wanderer_quests()
	test_building_locks()
	test_storehouse()
	test_glass_case()
	test_clear_plots()
	test_random_hits_repick()
	test_look_ahead()
	test_frontliners()
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
	check(is_equal_approx(emm.dmg_mult(mmc, "mm_axe_cleave", wolf) - emm.dmg_mult(mmc, "mm_axe_cleave", man), 0.2), "Mountain Mystic +20% damage vs beasts")
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
	# Locked buildings (round 19): the Chapel needs a Parson, the Doctor's Office its plans.
	check(co.can_build(0, "chapel").contains("Parson"), "the Chapel waits for a Parson (%s)" % co.can_build(0, "chapel"))
	check(co.can_build(0, "doctor").contains("plans"), "the Doctor's Office waits for its plans")
	check(co.can_build(0, "stage_line").contains("second settlement"), "the Stage Line waits for a second settlement")
	check(co.can_build(0, "lumber_yard") == "", "the Lumber Yard is open from the start")
	co.welcome_townsperson(co.make_townsperson("parson", 1, "loyal"), 0)
	co.story_flags["plans_doctor"] = true
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
	for pair in [["pc_hands", 6, 10], ["pc_revival", 1, 3], ["dr_surgery", 8, 12]]:
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
	check(run.curio_hint("ore_vein", mk.call("prospector")) == "★ Prospector", "picker marks show the name only (★ Prospector)")
	check(run.curio_hint("scarecrow", mk.call("gunslinger")).contains("★ Gunslinger"), "quick draw shows at ambush curios")
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
func test_fatigue_states() -> void:
	var kinds := {"breaking": 0, "second_wind": 0}
	for id in DB.fatigue_states:
		if DB.fatigue_states[id] is Dictionary:
			kinds[DB.fatigue_states[id].kind] += 1
	check(kinds.breaking == 6 and kinds.second_wind == 6, "6 Breaking Points and 6 True Grit states")
	check(DB.fatigue_states.homesick.name == "Heartsick" and DB.fatigue_states.short_tempered.name == "Ornery" and DB.fatigue_states.sharp_eyed.name == "Dead-Eye" and DB.fatigue_states.grit.name == "Mule-Headed", "renamed states keep their ids")
	check(Stats.STAT_NAMES.deathblow == "Cheat Death" and Stats.STAT_NAMES.resolve == "True Grit Chance", "Cheat Death / True Grit stat names")
	var co := Company.new()
	co.new_game(23)
	var a := co.make_hero("marshal", 1)
	var b := co.make_hero("gunslinger", 1)
	for h in [a, b]:
		h.quirks.clear()
		h.keepsakes = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	# Landing a state flags it fresh.
	a.fatigue = 95
	Fatigue.add(a, 10, rng)
	check(a.fatigue_state != "" and a.state_fresh, "a Gut Check flags the new state fresh")
	# Greedy: Marked on the fight's first turn, not again.
	a.fatigue_state = "greedy"
	a.state_fresh = false
	var e := CombatEngine.new()
	e.setup([a, b], ["outlaw_brawler", "outlaw_gunhand"], {"rng": rng})
	var ca: Combatant = e.heroes[0]
	var cb: Combatant = e.heroes[1]
	e._state_hooks([])
	check(ca.mark > 0, "Greedy starts the fight Marked")
	ca.mark = 0
	e._state_hooks([])
	check(ca.mark == 0, "Greedy's fight_start fires once per fight")
	# Steadfast lands: the most wounded hero gets +15 Prot for the fight.
	a.fatigue_state = "steadfast"
	a.state_fresh = true
	cb.hp = 3
	var p0 := cb.stat("prot")
	e._state_hooks([])
	check(cb.stat("prot") == p0 + 15 and not a.state_fresh, "Steadfast: most wounded hero +15 Prot, once")
	e._state_hooks([])
	check(cb.stat("prot") == p0 + 15, "Steadfast's landing buff doesn't repeat")
	# Dead-Eye marks a foe; Cool-Headed clears a Bleed.
	a.fatigue_state = "sharp_eyed"
	e._apply_boon(ca, {"type": "mark_enemy", "rounds": 2})
	check(e.enemies.any(func(x): return x.mark > 0), "Dead-Eye calls a target (Marks a foe)")
	a.fatigue_state = "cool_headed"
	cb.dots = [{"kind": "bleed", "amount": 3, "rounds": 3}, {"kind": "poison", "amount": 1, "rounds": 2}]
	e._apply_boon(ca, {"type": "cleanse_ally"})
	check(not cb.dots.any(func(d): return d.kind == "bleed") and cb.dots.size() == 1, "Cool-Headed clears the worse of Bleed or Poison")
	# Ornery taunts without losing the turn.
	a.fatigue_state = "short_tempered"
	var st: Dictionary = DB.fatigue_states.short_tempered
	var old_acts: Array = st.acts
	var old_chance: int = st.act_chance
	st.acts = ["taunt"]
	st.act_chance = 100
	var ev: Array = []
	var lost := e._maybe_act_out(ca, ev)
	st.acts = old_acts
	st.act_chance = old_chance
	check(not lost and ca.taunt > 0, "Ornery taunts and keeps the turn")
	# Cowardly: Vulnerable 15% up front only; Reckless always Vulnerable 10%.
	a.fatigue_state = "cowardly"
	check(ca.rank == 1 and ca.stat("vulnerable") == 15, "Cowardly Vulnerable in rank 1")
	e._shift(ca, -2, [])
	check(ca.rank == 2 and ca.stat("vulnerable") == 15, "Cowardly Vulnerable in rank 2")
	a.fatigue_state = "reckless"
	check(ca.stat("vulnerable") == 10, "Reckless Vulnerable 10%")
	# Paranoid: +4 Speed in round 1.
	a.fatigue_state = "paranoid"
	ca.round_num = 2
	var s2 := ca.stat("speed")
	ca.round_num = 1
	check(ca.stat("speed") == s2 + 4, "Paranoid +4 Speed in round 1")
	# Mule-Headed: +15 Cheat Death on Last Legs.
	a.fatigue_state = "grit"
	var cd0 := ca.stat("deathblow")
	a.deaths_door = true
	check(ca.stat("deathblow") == minf(cd0 + 15, DB.cfg("deathblow_cap", 87)) and ca.stat("deathblow") > cd0, "Mule-Headed: +15 Cheat Death on Last Legs")
	a.deaths_door = false
	# The fresh flag survives a save.
	a.fatigue_state = "cool_headed"
	a.state_fresh = true
	check(Hero.from_dict(a.to_dict()).state_fresh, "fresh flag saves")


func test_event_pass() -> void:
	# Data: requirements, experts, compels and fights point at real things; every event is in a pool.
	var common: Array = DB.cfg("common_events", [])
	var in_pool := {}
	for e in common:
		check(DB.events.has(e), "common event %s exists" % e)
		in_pool[e] = true
	for rid in DB.regions:
		var r: Dictionary = DB.regions[rid]
		for e in r.get("events", []) + r.get("homestead_events", []):
			check(DB.events.has(e), "%s: event %s exists" % [rid, e])
			in_pool[e] = true
		for e in r.get("events", []) if not r.has("fixed_map") else []:
			check(not e in common, "%s: %s isn't also in the common pool" % [rid, e])
	for tid in DB.quests.templates:
		for e in DB.quests.templates[tid].get("events", []):
			check(DB.events.has(e), "quest %s: theme event %s exists" % [tid, e])
			in_pool[e] = true
	for eid in DB.events:
		check(in_pool.has(eid), "event %s is in some pool" % eid)
		_check_event_options(eid, DB.events[eid].options)
	# Pools: no repeats until every layer is used up; a quest's theme layer is drawn from.
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	var crow: Dictionary = DB.regions.crows_nest
	var used: Array = []
	var picks := {}
	var total: int = crow.events.size() + common.size()
	for i in total:
		picks[MapGen.pick_event(crow, rng, used)] = true
	check(picks.size() == total, "event pools don't repeat until spent (%d/%d)" % [picks.size(), total])
	check(MapGen.pick_event(crow, rng, used) != "", "a spent pool falls back to a repeat")
	var quest := {"events": DB.regions.tallgrass.events, "theme_events": ["haint_lights"]}
	var themed := 0
	for i in 400:
		if MapGen.pick_event(quest, rng, []) == "haint_lights":
			themed += 1
	check(themed > 120 and themed < 210, "a quest's theme layer is drawn ~40%% (got %d/400)" % themed)
	# Experts over the whole company.
	var co := Company.new()
	co.new_game(43)
	var run := RunState.create(co, "tallgrass", 0, [co.heroes[0].uid], {"food": 20})
	co.run = run
	var mk := func(cls: String, skills: Dictionary = {}, quirks: Array = []) -> Hero:
		var h: Hero = co.make_hero(cls, 1)
		h.survival = {}
		for sk in skills:
			h.survival[sk] = {"rank": skills[sk], "xp": 0}
		h.quirks = quirks.duplicate()
		co.heroes.append(h)
		return h
	var set_party := func(hs: Array) -> void:
		run.party = hs.map(func(h): return h.uid)
	var plain: Hero = mk.call("marshal")
	var wr: Hero = mk.call("wrangler")
	var fat: Hero = mk.call("gunslinger", {}, ["clumsy"])
	var good_rate := func(eid: String, idx: int, n: int) -> float:
		var good_texts: Array = DB.events[eid].options[idx].outcomes.filter(func(o): return o.get("good", false)).map(func(o): return str(o.text))
		var g := 0
		for i in n:
			for h in run.party_heroes():
				h.fatigue = 0
				h.hp = h.max_hp()
			var res := run.choose_event_option(eid, idx)
			if good_texts.any(func(t): return res.text.begins_with(t)):
				g += 1
		return g / float(n)
	set_party.call([plain])
	var base: float = good_rate.call("river_crossing", 0, 600)
	set_party.call([plain, wr])
	var with_wr: float = good_rate.call("river_crossing", 0, 600)
	set_party.call([plain, fat])
	var with_fat: float = good_rate.call("river_crossing", 0, 600)
	check(with_wr > base + 0.08, "★ Wrangler fords better (%.2f vs %.2f)" % [with_wr, base])
	check(with_fat < base - 0.05, "✗ Overweight fords worse (%.2f vs %.2f)" % [with_fat, base])
	set_party.call([plain, wr, fat])
	var marks: Array = run.event_options("river_crossing")[0].experts
	check(marks.any(func(m): return m.mark == "★" and m.name == "Wrangler") and marks.any(func(m): return m.mark == "✗" and m.name == "Overweight"), "option lists ★ Wrangler and ✗ Overweight by name")
	# A swap, a bonus, and a bad outcome landing on the ✗ hero.
	var rd: Hero = mk.call("rail_driver")
	set_party.call([plain, rd])
	var lifted := false
	for i in 40:
		if "lifts the wagon" in run.choose_event_option("wagon_stuck", 0).text:
			lifted = true
			break
	check(lifted, "★ Rail Driver swaps in the lift")
	var ww: Hero = mk.call("marshal", {"wheelwright": 2})
	set_party.call([ww])
	var bonus_seen := false
	for i in 40:
		ww.fatigue = 0
		var r2 := run.choose_event_option("broken_axle", 2)
		if r2.msgs.any(func(m): return str(m).begins_with("★ Wheelwright")):
			bonus_seen = true
			break
	check(bonus_seen, "★ Wheelwright's bonus applies on a good outcome")
	var sup: Hero = mk.call("marshal", {}, ["superstitious"])
	set_party.call([plain, sup])
	sup.fatigue = 0
	var r3 := run.choose_event_option("gravesite", 0)
	check(r3.text.ends_with("(✗ Superstitious)") and sup.fatigue >= 10, "a bad outcome lands on the ✗ hero, with their bonus")
	# free: the Frontier Doctor needs no Antivenom; Hides are spent from the cargo.
	var doc: Hero = mk.call("frontier_doctor")
	set_party.call([plain, doc])
	run.supplies["antivenom"] = 0
	var av: Dictionary = run.event_options("rattler_in_bedroll").filter(func(o): return o.text.begins_with("Keep Antivenom"))[0]
	check(av.available, "★ Frontier Doctor: the Antivenom option needs no Antivenom")
	set_party.call([plain])
	run.loot.hides = 1
	var patch: int = run.event_options("torn_canvas").filter(func(o): return o.text.begins_with("Patch it"))[0].index
	run.choose_event_option("torn_canvas", patch)
	check(int(run.loot.hides) == 0, "patching the canvas spends a Hide")
	# Secret quirk options are hidden without the quirk; compel fires about 30%.
	check(run.event_options("stranger_on_road").filter(func(o): return o.text.begins_with("There's paper")).all(func(o): return o.hidden), "Bounty Hunter's option hidden without the quirk")
	var dr: Hero = mk.call("marshal", {}, ["drinker"])
	set_party.call([plain, dr])
	var compelled := 0
	for i in 400:
		var c := run.event_compel("stranger_on_road")
		if not c.is_empty():
			compelled += 1
			check(c.hero == dr, "the Drinker is the one compelled")
	check(compelled > 90 and compelled < 160, "compel ~30%% (got %d/400)" % compelled)
	set_party.call([plain])
	check(run.event_compel("stranger_on_road").is_empty(), "no compel without the quirk")
	# Fight setup: dropped lookout, wounded foes, expert fight changes, foe mods in the engine.
	var gs: Hero = mk.call("gunslinger")
	set_party.call([plain, gs])
	var pick_idx: int = run.event_options("outlaw_ambush_warning").filter(func(o): return o.text.begins_with("Pick off"))[0].index
	var r4 := run.choose_event_option("outlaw_ambush_warning", pick_idx)
	check(r4.fight != null and r4.fight.drop == ["outlaw_rifleman"] and r4.fight.surprise == "enemies", "Gunslinger drops the lookout, strikes first")
	var mm: Hero = mk.call("mountain_man")
	set_party.call([plain, mm])
	var one_haint := false
	for i in 60:
		plain.fatigue = 0
		mm.fatigue = 0
		var r5 := run.choose_event_option("haint_lights", 0)
		if r5.fight != null:
			one_haint = r5.fight.enemies == ["prairie_haint"]
			break
	check(one_haint, "★ Mountain Mystic: the haint fight drops to one")
	var e := CombatEngine.new()
	e.setup([plain], ["outlaw_brawler", "outlaw_gunhand"], {"wounded": {"*": 60}, "foe_mods": [{"stat": "vulnerable", "value": 15, "rounds": 2}], "foe_mark": {"outlaw_gunhand": 2}})
	check(e.enemies.all(func(x): return x.hp == maxi(1, int(round(x.max_hp * 0.6)))), "wounded * puts every foe at 60%")
	check(e.enemies.all(func(x): return x.stat("vulnerable") == 15), "foe_mods: foes start Vulnerable")
	check(e.enemies[1].mark == 2 and e.enemies[0].mark == 0, "foe_mark marks the named foe")
	# Pass 2: the 12 new events sit in the first region's pools.
	for nid in ["card_game", "medicine_show"]:
		check(nid in common, "%s is a common event" % nid)
	for pair in [["tallgrass", ["twister", "cattle_drive"]], ["dry_gulch_mine", ["powder_shack", "tapping_underground", "tommyknockers", "runaway_burro", "ore_wagon_wreck"]],
			["crows_nest", ["wanted_poster", "hanging_tree", "stagecoach"]]]:
		for nid in pair[1]:
			check(nid in DB.regions[pair[0]].events, "%s is in %s's pool" % [nid, pair[0]])
	# hide_if: a Marshal won't steal.
	set_party.call([plain])
	var steal: Dictionary = run.event_options("cattle_drive").filter(func(o): return o.text.begins_with("Cut out"))[0]
	check(steal.hidden and not steal.available, "a Marshal in the company hides 'Cut out a stray'")
	set_party.call([gs])
	steal = run.event_options("cattle_drive").filter(func(o): return o.text.begins_with("Cut out"))[0]
	check(not steal.hidden and steal.available, "without a Marshal the stray can be cut out")
	# Follow-ups: the haint lights lead to a grave, and the grave's choice resolves.
	set_party.call([gs])
	var reached := false
	for i in 80:
		gs.fatigue = 0
		gs.hp = gs.max_hp()
		var r6 := run.choose_event_option("haint_lights", 0)
		if r6.get("then", false):
			reached = true
			check(not run.followup.is_empty() and run.followup_options().size() == 3, "the grave offers three choices")
			run.company.money = 50
			var coin: int = run.followup_options().filter(func(o): return o.text.begins_with("Leave a coin"))[0].index
			var r7 := run.choose_followup(coin)
			check(r7.text.begins_with("One by one") and run.followup.is_empty() and run.company.money + int(run.loot.money) <= 50, "leaving a coin resolves the follow-up and costs 10")
			break
		run.followup = {}
	check(reached, "Follow the lights can lead to the grave")
	check(run.choose_event_option("wolf_tracks", 0).get("then", false) == false and run.followup.is_empty(), "an outcome without 'then' leaves no follow-up")


## Event data checks, recursing into follow-up choices ("then").
func _check_event_options(eid: String, options: Array) -> void:
	for opt in options:
		var req: Dictionary = opt.get("requires", {})
		for k in req:
			check(k in ["item", "money", "hides", "skill", "class", "quirk"], "%s: requirement %s is known" % [eid, k])
		if req.has("skill"):
			check(DB.survival.has(req.skill), "%s: skill %s exists" % [eid, req.skill])
		if req.has("class"):
			check(DB.classes.has(req["class"]), "%s: class %s exists" % [eid, req["class"]])
		if req.has("quirk"):
			check(DB.quirks.has(req.quirk), "%s: quirk %s exists" % [eid, req.quirk])
		if req.has("item"):
			check(DB.items.has(req.item), "%s: item %s exists" % [eid, req.item])
		if opt.get("compel", false):
			check(req.has("quirk"), "%s: a compel option needs a quirk" % eid)
		for id in opt.get("hide_if", []):
			check(DB.classes.has(id) or DB.quirks.has(id), "%s: hide_if %s is a class or quirk" % [eid, id])
		var ex: Dictionary = opt.get("experts", {})
		for id in ex:
			check(DB.classes.has(id) or DB.survival.has(id) or DB.quirks.has(id), "%s: expert %s is a class, skill or quirk" % [eid, id])
			for idx in ex[id].get("swap", {}):
				check(int(idx) < opt.outcomes.size(), "%s: %s swaps a real outcome" % [eid, id])
		var shifts := ex.values().any(func(x): return not x.get("averse", false) and int(x.get("odds", 1)) != 0)
		if shifts:
			var goods: Array = opt.outcomes.filter(func(o): return o.get("good", false))
			var swaps := ex.values().any(func(x): return not x.get("swap", {}).is_empty())
			check(swaps or (not goods.is_empty() and goods.size() < opt.outcomes.size()), "%s: '%s' has good and bad outcomes for its experts' odds" % [eid, opt.text])
		check(not opt.get("outcomes", []).is_empty(), "%s: '%s' has outcomes" % [eid, opt.text])
		for o in opt.outcomes:
			for ef in o.get("effects", []):
				if ef.get("type", "") == "fight":
					for en in ef.enemies:
						check(DB.enemies.has(en), "%s: enemy %s exists" % [eid, en])
				if ef.get("type", "") == "recruit" and ef.get("class", "random") != "random":
					check(DB.classes.has(ef["class"]), "%s: recruit class %s exists" % [eid, ef["class"]])
			if o.has("then"):
				check(not str(o.then.get("text", "")).is_empty(), "%s: a follow-up has text" % eid)
				_check_event_options(eid, o.then.get("options", []))


func test_starter_quest() -> void:
	# Skipping the tutorial puts a starter job on the Saloon board straight away, and the
	# starter job is easy (no story rumor, no boss) until a side quest has been run.
	for sd in [3, 11, 29]:
		var co := Company.new()
		co.new_game(sd)
		co.complete_tutorial(true)
		var qs: Array = co.settlement(0).get("quests", [])
		check(qs.size() == 1, "a starter quest is offered right after the tutorial (seed %d)" % sd)
		for q in qs:
			var reg: Dictionary = DB.regions[q]
			check(reg.final == "crossing" and int(reg.difficulty) <= 2 and reg.template != "mad_dog", "the starter quest is easy (seed %d: %s)" % [sd, reg.template])
	var co2 := Company.new()
	co2.new_game(5)
	co2.complete_tutorial(true)
	co2.story_flags["quest_run"] = true
	var mad := false
	for w in 30:
		co2.advance_week()
		for q in co2.settlement(0).get("quests", []):
			mad = mad or DB.regions[q].template == "mad_dog"
	check(mad, "after a side quest, Mad Dog's rumor comes back to the board")


func test_money_shot() -> void:
	# A kill pays 30 (+10 a level); a shot that doesn't kill loses the 10-chip stake.
	var co := Company.new()
	co.new_game(31)
	var g: Hero = co.make_hero("gambler", 1)
	g.quirks.clear()
	if not "gb_money_shot" in g.equipped:
		g.equipped[0] = "gb_money_shot"
	var e := CombatEngine.new()
	e.setup([co.make_hero("marshal", 1), g], ["outlaw_brawler", "outlaw_gunhand", "outlaw_rifleman"], {})
	var gc: Combatant = e.heroes[1]
	var foe: Combatant = e.enemies[1]
	foe.hp = 999
	foe.max_hp = 999
	e.use_skill(gc, "gb_money_shot", foe.id)
	check(e.bounty == -10, "Money Shot without a kill loses 10 chips (bounty %d)" % e.bounty)
	foe.hp = 1
	var kills := 0
	for i in 20:
		if foe.dead:
			break
		e.bounty = 0
		e.use_skill(gc, "gb_money_shot", foe.id)
		if foe.dead:
			kills += 1
			check(e.bounty == 30, "a Money Shot kill pays 30 at level 1 (got %d)" % e.bounty)
	check(kills == 1, "the 1-HP foe falls to a Money Shot")
	check(g.kills == 1, "a killing blow counts on the hero's kill tally")


func test_iron_justice() -> void:
	# Iron Justice: +15% against outlaws (+5% a level), stacking with +40% against Marked targets.
	var co := Company.new()
	co.new_game(37)
	var m: Hero = co.make_hero("marshal", 1)
	m.quirks.clear()
	var e := CombatEngine.new()
	e.setup([m], ["outlaw_brawler", "prairie_wolf"], {})
	var mc: Combatant = e.heroes[0]
	var outlaw: Combatant = e.enemies[0]
	var wolf: Combatant = e.enemies[1]
	var base := e.dmg_mult(mc, "marshal_iron_justice", wolf)
	check(is_equal_approx(e.dmg_mult(mc, "marshal_iron_justice", outlaw) - base, 0.15), "Iron Justice +15% vs outlaws at level 1")
	outlaw.mark = 2
	check(is_equal_approx(e.dmg_mult(mc, "marshal_iron_justice", outlaw) - base, 0.55), "Iron Justice +55% vs a Marked outlaw")
	outlaw.mark = 0
	m.skill_levels["marshal_iron_justice"] = 3
	var base3 := e.dmg_mult(mc, "marshal_iron_justice", wolf)
	check(is_equal_approx(e.dmg_mult(mc, "marshal_iron_justice", outlaw) - base3, 0.25), "Iron Justice +25% vs outlaws at level 3")


func test_high_noon() -> void:
	var co := Company.new()
	co.new_game(53)
	var mk := func(cls: String, quirks: Array = []) -> Hero:
		var h: Hero = co.make_hero(cls, 1)
		h.quirks = quirks.duplicate()
		h.keepsakes = []
		co.heroes.append(h)
		return h
	var gs: Hero = mk.call("gunslinger")
	var pr: Hero = mk.call("preacher")
	var bf: Hero = mk.call("preacher", ["butterfingers"])
	# Scoring.
	var z := Duel.zones(pr, false)
	check(Duel.aim_tier(0.5, z) == "bullseye" and Duel.aim_tier(0.0, z) == "miss" and Duel.aim_tier(1.0, z) == "miss", "dead centre is a bullseye, the edges miss")
	check(Duel.aim_tier(0.5 + z.hit / 2.0 - 0.001, z) == "hit" and Duel.aim_tier(0.5 + z.graze / 2.0 - 0.001, z) == "graze", "the bands sit inside each other")
	check(Duel.zones(gs, false).hit > z.hit and Duel.zones(bf, false).hit < z.hit, "Gunslinger widens the zones, Butterfingers narrows them")
	check(Duel.zones(pr, true).hit < z.hit, "too slow shrinks the zones")
	check(Duel.edge(gs) > Duel.edge(pr), "the Gunslinger draws faster")
	check(Duel.beat_draw(pr, 0.30, 0.55) and not Duel.beat_draw(pr, 0.70, 0.55), "reaction vs their draw")
	check(Duel.hint(gs).contains("★ Gunslinger") and Duel.hint(bf).contains("✗ Butterfingers"), "Who draws? shows the names")
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var tiers := {}
	for i in 400:
		var r := Duel.roll(pr, 0.55, rng)
		tiers[r.tier] = tiers.get(r.tier, 0) + 1
	check(tiers.get("bullseye", 0) < 40 and tiers.get("miss", 0) > 100, "rolled duels: bullseyes are rare (%s)" % str(tiers))
	# A gang duel: the gang waits at the next fight, carrying the result.
	var run := RunState.create(co, "tallgrass", 0, [gs.uid, pr.uid], {"food": 20})
	co.run = run
	var duel := {"kind": "gang", "name": "Snake-Eye Pike", "opponent": "crane_lieutenant", "draw": 0.45, "gang": ["crane_lieutenant", "outlaw_gunhand"], "gang_name": "Pike's gang", "bounty": 200}
	var before := int(run.loot.money)
	run.resolve_duel(duel, gs, {"tier": "bullseye", "slow": false})
	check(int(run.loot.money) > before, "a bullseye pays a wanted man's bounty at once")
	var g := run.gang_fight({"type": "fight"})
	check(g.setup.get("drop", []) == ["crane_lieutenant"] and run.duel_gang.is_empty(), "bullseye: the duelist is dropped from the gang's fight")
	run.resolve_duel(duel, gs, {"tier": "hit", "slow": false})
	check(run.gang_fight({"type": "event"}).is_empty() and not run.duel_gang.is_empty(), "the gang waits for a fight stop")
	g = run.gang_fight({"type": "elite"})
	check(g.setup.duelist.hp_pct == 50 and g.setup.duelist.bleed_pct > 0 and int(g.reward.money) == 200, "hit: 50% HP and bleeding; the bounty rides on the later fight")
	run.resolve_duel(duel, gs, {"tier": "graze", "slow": false})
	g = run.gang_fight({"type": "fight"})
	check(not g.setup.duelist.has("hp_pct") and g.setup.duelist.bleed_pct > 0, "graze: bleeding only")
	# Missing (or jumping the gun) Rattles the hero for the expedition; too slow costs HP.
	pr.hp = pr.max_hp()
	var acc0 := pr.stat("acc")
	run.resolve_duel(duel, pr, {"tier": "jumped", "slow": false})
	check(pr.rattled and pr.stat("acc") == acc0 - 10 and pr.hp < pr.max_hp(), "jumped: Rattled (-10 Acc) and hit")
	check(Hero.from_dict(pr.to_dict()).rattled, "Rattled saves")
	# Boss duels set up the fight at once; a boss can't die to one.
	var bs := run.resolve_duel({"kind": "boss", "name": "Mulligan", "opponent": "mad_dog_mulligan"}, gs, {"tier": "bullseye", "slow": false})
	check(bs.setup.duelist.hp_pct == 50 and not bs.setup.has("drop"), "boss bullseye: 50% HP and bleeding, not dead")
	# The engine applies it to the first enemy with that id only.
	var e := CombatEngine.new()
	e.setup([gs], ["outlaw_gunhand", "outlaw_gunhand"], {"duelist": {"id": "outlaw_gunhand", "hp_pct": 50, "bleed_pct": 8, "rounds": 3}})
	check(e.enemies[0].hp < e.enemies[0].max_hp and not e.enemies[0].dots.is_empty() and e.enemies[1].hp == e.enemies[1].max_hp, "the duelist alone starts wounded and bleeding")
	# Events and the Mad Dog standoff carry duels.
	check("lone_wanderer" in DB.cfg("common_events", []), "the Lone Wanderer is a common event")
	for pair in [["outlaw_toll", "Call out the leader."], ["wanted_poster", "Go after him."], ["hanging_tree", "Cut him down."], ["lone_wanderer", "Accept."]]:
		var opts: Array = DB.events[pair[0]].options.filter(func(o): return o.text == pair[1])
		check(opts.size() == 1 and opts[0].outcomes[0].effects[0].type == "duel", "%s: '%s' is a duel" % pair)
	var toll_i: int = run.event_options("outlaw_toll").filter(func(o): return o.text == "Call out the leader.")[0].index
	check(not run.choose_event_option("outlaw_toll", toll_i).duel.is_empty(), "choosing a duel option hands back the duel")
	check(not DB.quests.templates.mad_dog.boss.get("duel", {}).is_empty(), "Mad Dog faces you in the street first")


func test_skill_checks() -> void:
	var games: Dictionary = DB.cfg("checks", {})
	for cid in DB.curios:
		var ck: Dictionary = DB.curios[cid].get("check", {})
		if not ck.is_empty():
			check(games.has(str(ck.game)), "%s: check game %s exists" % [cid, ck.game])
			check(DB.curios[cid].hand.any(func(o): return o.get("good", false)) and DB.curios[cid].hand.any(func(o): return not o.get("good", false)), "%s: a check has good and bad outcomes to land on" % cid)
	var co := Company.new()
	co.new_game(61)
	var mk := func(cls: String, quirks: Array = [], skills: Dictionary = {}) -> Hero:
		var h: Hero = co.make_hero(cls, 1)
		h.quirks = quirks.duplicate()
		h.survival = {}
		for sk in skills:
			h.survival[sk] = {"rank": skills[sk], "xp": 0}
		co.heroes.append(h)
		return h
	# A tier 2 region (base 3, ceiling 4); the first region is checked below.
	var run := RunState.create(co, "red_canyons", 0, [co.heroes[0].uid], {"food": 10})
	co.run = run
	var pr: Hero = mk.call("preacher")
	var gb: Hero = mk.call("gambler")
	var bf: Hero = mk.call("preacher", ["butterfingers"])
	var mm: Hero = mk.call("mountain_man")
	var mn: Hero = mk.call("preacher", [], {"miner": 3})
	check(run.curio_check("strongbox", pr).difficulty == 3, "no expert: difficulty 3")
	check(run.curio_check("strongbox", gb).difficulty == 2, "★ Gambler at the strongbox: difficulty 2")
	check(run.curio_check("strongbox", bf).difficulty == 4, "Butterfingers at a lock: difficulty 4")
	check(run.curio_check("railroad_crate", mm).difficulty == 4, "✗ Mountain Mystic at the railroad crate: difficulty 4")
	check(run.curio_check("miners_cache", mn).difficulty == 2, "Miner rank 3 at the cache: difficulty 2")
	var run1 := RunState.create(co, "tallgrass", 0, [co.heroes[0].uid], {"food": 10})
	check(run1.curio_check("strongbox", pr).difficulty == 2 and run1.curio_check("strongbox", bf).difficulty == 2 and run1.curio_check("strongbox", gb).difficulty == 1, "the first region: base 2, never above 2")
	check(run.curio_check("strongbox", pr, "shovel").is_empty(), "a supply skips the check")
	check(run.curio_check("old_grave", pr).is_empty(), "an as-key expert (Preacher at a grave) skips the check")
	check(run.curio_check("scarecrow", pr).is_empty(), "curios without a check roll as before")
	# Results drive the outcome.
	var good_share := func(cid: String, tier: String, n: int) -> float:
		var goods: Array = DB.curios[cid].hand.filter(func(o): return o.get("good", false)).map(func(o): return str(o.text).replace("{hero}", pr.hero_name))
		var g := 0
		for i in n:
			pr.hp = pr.max_hp()
			pr.fatigue = 0
			pr.quirks = []
			var res := run.interact_curio(cid, pr, "", tier)
			if goods.any(func(t): return res.text.ends_with(t)):
				g += 1
		return g / float(n)
	var clean: float = good_share.call("strongbox", "clean", 300)
	var close: float = good_share.call("strongbox", "close", 300)
	var plain: float = good_share.call("strongbox", "", 300)
	var botched: float = good_share.call("strongbox", "botched", 200)
	check(clean > 0.85, "a clean check is almost always good (%.2f)" % clean)
	check(close < plain, "a close check leans bad (%.2f vs %.2f)" % [close, plain])
	check(botched == 0.0, "a botched check is always bad")


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
	check(int(DB.cfg("xp_levels", [])[1]) == 24 and int(DB.cfg("xp_levels", [])[2]) == 80, "XP thresholds: level 2 at 24, level 3 at 80 (round 17: slower)")
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
	# Half the time (round 20): over many searches some money gets through, but less than
	# without the quirk.
	for k in 40:
		run.interact_curio("strongbox", gs)
	var with_fever := int(run.loot.money) - cash0
	gs.quirks = []
	var cash1 := int(run.loot.money)
	for k in 40:
		run.interact_curio("strongbox", gs)
	var without := int(run.loot.money) - cash1
	check(with_fever > 0 and with_fever < without, "Gold Fever pockets some of the strongbox money (%d vs %d)" % [with_fever, without])
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


func test_townsfolk() -> void:
	# Data: a separate pool from heroes (no shared names with hero quirks or Breaking Points /
	# True Grit), every trade belongs somewhere real, every producer has its trade.
	var hero_names := {}
	for q in DB.quirks:
		hero_names[str(DB.quirks[q].name)] = true
	for f in DB.fatigue_states:
		hero_names[str(DB.fatigue_states[f].name)] = true
	var tf: Dictionary = DB.townsfolk
	for t in tf.traits:
		check(not hero_names.has(str(tf.traits[t].name)), "townsfolk trait %s doesn't share a hero quirk's name" % t)
	for t in tf.trades:
		var b := str(tf.trades[t].get("building", ""))
		check(b == "" or DB.buildings.has(b), "trade %s belongs at a real building" % t)
	for b in ["lumber_yard", "mine", "trapping_post"]:
		check(DB.buildings.has(b) and Townsfolk.trade_for(b) != "", "%s exists and has its trade" % b)

	var co := Company.new()
	co.new_game(41)
	co.complete_tutorial()
	co.money += 20000
	co.timber += 300
	co.iron += 200
	co.hides += 100
	check(co.townsfolk.is_empty() and co.population(0) == 0, "a new game starts with no townsfolk")
	var relief0 := co.activity_relief(0, "saloon", "bar")
	check(relief0 == 45, "an unstaffed Saloon works as before (%d)" % relief0)
	# Seats: none at level 1, one at 2, two at 3; never on the Stage Line or Hiring Board.
	check(co.staff_seats(0, "saloon") == 0, "no staff seats at level 1")
	co.build(0, "saloon")
	check(co.staff_seats(0, "saloon") == 1, "one seat at level 2")
	check(co.staff_seats(0, "hiring_board") == 0 and co.staff_seats_max("hiring_board") == 0 and co.staff_seats_max("stage_line") == 0, "no seats at the Hiring Board or Stage Line")
	check(co.staff_seats_max("saloon") == 2, "two seats at most")
	# A Hand Barkeep at the Saloon: +10 relief.
	var bk := co.make_townsperson("barkeep", 2, "loyal")
	check(bk.level == 2 and bk.trade == "barkeep" and bk.trait == "loyal" and str(bk.name).contains(" "), "make a Hand Barkeep (%s)" % bk.name)
	co.welcome_townsperson(bk, 0)
	check(co.population(0) == 1, "they settle in town")
	check(co.post_townsperson(bk, "saloon"), "put the barkeep to work")
	check(co.activity_relief(0, "saloon", "bar") == co.activity_relief(0, "saloon", "bar") and co.staff_value(0, "saloon") == 10.0, "a Hand Barkeep adds 10 relief")
	var other := co.make_townsperson("parson", 1, "loyal")
	co.welcome_townsperson(other, 0)
	check(co.can_post(other, "saloon") == "No free seat", "the one seat is taken")
	co.settlement(0).buildings.saloon = 3   # (a Town caps buildings at level 2; as if a City)
	check(co.staff_seats(0, "saloon") == 2, "two seats at level 3")
	check(co.post_townsperson(other, "saloon") and is_equal_approx(co.staff_value(0, "saloon"), 12.5), "a Parson at the Saloon gives half a Greenhorn's help (%.1f)" % co.staff_value(0, "saloon"))
	# Laborers, Hard Workers, Lazybones, Handy.
	var lab := co.make_townsperson("laborer", 1, "thrifty")
	check(is_equal_approx(Townsfolk.value_in(lab, "chapel"), 2.5), "a Greenhorn Laborer: half a Greenhorn's help")
	lab.level = 2
	check(is_equal_approx(Townsfolk.value_in(lab, "chapel"), 5.0), "a Hand Laborer: a full Greenhorn's")
	var hw := co.make_townsperson("sawbones", 1, "hard_worker")
	check(Townsfolk.work_level(hw) == 2 and Townsfolk.value_in(hw, "doctor") == 20.0, "a Hard Worker works a level up")
	var lz := co.make_townsperson("sawbones", 1, "lazybones")
	check(Townsfolk.value_in(lz, "doctor") == 0.0, "a Greenhorn Lazybones does nothing")
	var hd := co.make_townsperson("logger", 1, "handy")
	check(Townsfolk.value_in(hd, "chapel") == 5.0, "Handy: a full Greenhorn's help anywhere")
	var sw := co.make_townsperson("sawbones", 3, "set_in_ways")
	check(sw.level == 2, "Set in Their Ways never gets past Hand")
	# Discounts: a Sawbones at the Doctor's Office; a Master adds a bed.
	co.story_flags["plans_doctor"] = true
	co.build(0, "doctor")
	co.build(0, "doctor")
	var h: Hero = co.heroes[0]
	var dc0 := co.doctor_cost(0, h)
	var beds0 := co.slot_cap(0, "doctor")
	var saw := co.make_townsperson("sawbones", 3, "loyal")
	co.welcome_townsperson(saw, 0)
	co.post_townsperson(saw, "doctor")
	check(co.doctor_cost(0, h) == int(round(dc0 * 0.7)) or absi(co.doctor_cost(0, h) - int(round(dc0 * 0.7))) <= 1, "a Master Sawbones takes 30%% off (%d -> %d)" % [dc0, co.doctor_cost(0, h)])
	check(co.slot_cap(0, "doctor") == beds0 + 1, "a Master Sawbones adds a bed")
	# Tippler: sleeping it off is no help at all.
	saw.off = true
	check(co.staff_value(0, "doctor") == 0.0 and co.slot_cap(0, "doctor") == beds0, "nobody's help while sleeping one off")
	saw.off = false
	# A Master Barkeep brings one more side quest.
	bk.level = 3
	var q0: int = co.settlement(0).quests.size()
	co._refresh_settlement(co.settlement(0))
	check(co.settlement(0).quests.size() == q0 + 1, "a Master Barkeep adds a side quest (%d -> %d)" % [q0, co.settlement(0).quests.size()])
	bk.level = 2
	# Producers: the yard's own cut plus a Logger's.
	check(co.build(0, "lumber_yard"), "build a Lumber Yard")
	check(int(co.production(0, "lumber_yard").get("timber", 0)) == 2, "a level 1 Lumber Yard cuts 2 Timber a week")
	co.build(0, "lumber_yard")
	var lg := co.make_townsperson("logger", 1, "loyal")
	co.welcome_townsperson(lg, 0)
	co.post_townsperson(lg, "lumber_yard")
	check(int(co.production(0, "lumber_yard").timber) == 5, "level 2 plus a Greenhorn Logger: 3 + 2 Timber")
	# The week: Timber comes in, wages go out, the job is learned.
	var t0 := co.timber
	var m0 := co.money
	var wages := co.townsfolk_wages()
	co.advance_week()
	check(co.timber == t0 + 5, "the yard delivers at the week's start (%d -> %d)" % [t0, co.timber])
	check(co.money == m0 - wages, "wages are paid (%d a week)" % wages)
	check(Townsfolk.wage(lab) == 10 and Townsfolk.wage(co.make_townsperson("logger", 1, "grasping")) == 15, "Thrifty and Grasping wages")
	for n in 3:
		co.advance_week()
	check(int(lg.level) == 2, "a Greenhorn becomes a Hand after four weeks on the job (xp %d)" % int(lg.xp))
	check(int(co.production(0, "lumber_yard").timber) == 6, "a Hand Logger cuts 3")
	# Unpaid: two weeks and they leave; Loyal folk stay.
	var gr := co.make_townsperson("trapper", 1, "grasping")
	co.welcome_townsperson(gr, 0)
	co.money = 0
	co.advance_week()
	check(int(gr.unpaid) == 1 and co.townsfolk.has(gr), "one unpaid week: a warning")
	co.money = 0
	co.advance_week()
	check(not co.townsfolk.has(gr), "two unpaid weeks: they leave")
	check(co.townsfolk.has(bk), "Loyal folk stay unpaid")
	# Growth: a City needs eight townsfolk; housing caps the town.
	co.charters = 10
	co.money = 20000
	check(co.can_upgrade_tier(0).contains("townsfolk"), "a City needs townsfolk (%s)" % co.can_upgrade_tier(0))
	while co.population(0) < co.housing(0):
		co.welcome_townsperson(co.make_townsperson("laborer", 1, "loyal"), 0)
	check(co.population(0) == 8, "a Town houses eight")
	check(co.welcome_townsperson(co.make_townsperson(), 0).contains("moves on"), "no room: the settler moves on")
	check(co.can_upgrade_tier(0) == "", "eight townsfolk: a City is allowed")
	# On the trail: an event sends someone home; they arrive with the company.
	var co2 := Company.new()
	co2.new_game(42)
	co2.complete_tutorial()
	var uids: Array = []
	for hh in co2.heroes:
		uids.append(hh.uid)
	var run := RunState.create(co2, "tallgrass", 0, uids, {"food": 4})
	co2.run = run
	var out := Effects.apply([{"type": "townsfolk", "trade": ["mucker", "trapper"]}], run, co2.heroes[0])
	check(run.townsfolk.size() == 1 and str(run.townsfolk[0].trade) in ["mucker", "trapper"] and str(out.msgs[0]).contains("settle"), "an event's settler waits in the wagon")
	var saved := RunState.from_dict(DB.normalize(JSON.parse_string(JSON.stringify(run.to_dict()))), co2)
	check(saved.townsfolk.size() == 1, "the settler survives a mid-expedition save")
	var sm := co2.finish_run("abandoned")
	check(co2.population(0) == 1 and sm.settlers.size() == 1, "they settle when the company comes home")
	# Events and quests: settler outcomes exist; quest hints mention them.
	var settler_events := 0
	for eid in DB.events:
		for o in DB.events[eid].options:
			for oc in o.get("outcomes", []):
				for ef in oc.get("effects", []):
					if ef.get("type", "") == "townsfolk" or ef.get("reward", {}).has("settler"):
						settler_events += 1
	check(settler_events >= 6, "trail events can send settlers home (%d)" % settler_events)
	check(Company.quest_hints({"quest_reward": {"money": 100, "settler": 1}}).contains("settler"), "a quest's settler shows in its hints")
	# Save: kept; an old save without townsfolk loads with nobody.
	var co3 := Company.from_dict(DB.normalize(JSON.parse_string(JSON.stringify(co.to_dict()))))
	check(co3.townsfolk.size() == co.townsfolk.size() and co3.staff_value(0, "saloon") == co.staff_value(0, "saloon"), "townsfolk and their posts save and load")
	var old := co.to_dict()
	old.erase("townsfolk")
	var co4 := Company.from_dict(DB.normalize(JSON.parse_string(JSON.stringify(old))))
	check(co4.townsfolk.is_empty() and co4.activity_relief(0, "saloon", "bar") == co.activity_relief(0, "saloon", "bar") - int(round(co.staff_value(0, "saloon"))), "an old save loads with no townsfolk and plain buildings")


func test_minigame_tuning() -> void:
	# Round 16 playtest: High Noon numbers.
	var dc: Dictionary = DB.cfg("duel", {})
	check(float(dc.wait[0]) == 1.5 and float(dc.wait[1]) == 8.0 and float(dc.get("aim_time", 0)) == 4.0, "the draw waits 1.5-8 s; 4 s to take the shot")
	var z: Dictionary = dc.zones
	check(float(z.bullseye) < float(z.hit) and float(z.hit) < float(z.graze) and float(z.graze) <= 0.22, "aim zones nest and are tighter (%s)" % z)
	# Steady hand: the band rests, then glides; it never leaves the bar or jumps.
	var sc := SkillCheck.new()
	sc.game = "steady"
	sc.d = 3
	sc.rng.seed = 5
	sc.zone_h = 0.25
	sc.drift = 0.25
	sc.zone_wait = 0.8
	var lo := 1.0
	var hi := 0.0
	var fastest := 0.0
	var moved_early := false
	var prev := sc.zone_c
	for i in 300:
		sc._move_zone(1.0 / 60.0)
		lo = minf(lo, sc.zone_c)
		hi = maxf(hi, sc.zone_c)
		fastest = maxf(fastest, absf(sc.zone_c - prev) * 60.0)
		if i < 40 and absf(sc.zone_c - 0.5) > 0.001:
			moved_early = true
		prev = sc.zone_c
	check(not moved_early, "the band rests at the start")
	check(lo >= 0.125 - 0.0001 and hi <= 0.875 + 0.0001, "the band stays on the bar (%.2f-%.2f)" % [lo, hi])
	check(hi - lo > 0.15, "the band wanders (%.2f)" % (hi - lo))
	check(fastest < 0.7, "the band glides, never jumps (%.2f bar/s at most)" % fastest)
	# Tumblers: a miss is recorded, so its pin shows red.
	sc.game = "tumblers"
	sc.pins = 3
	sc.notch = 0.0
	sc.notch_w = 20.0
	sc.needle = 50.0
	sc._tumbler_press()
	sc.notch = 0.0
	sc.needle = 2.0
	sc._tumbler_press()
	check(sc.pin_ok == [false, true] and sc.slips == 1, "tumbler pins remember misses and hits")
	# Quick hands: letters.
	sc.game = "quick"
	sc.phase = "play"
	sc.prompts = 4
	sc.prompt_i = 0
	sc.slips = 0
	sc._next_prompt()
	check(sc.prompt_letter.length() == 1 and sc.prompt_letter >= "A" and sc.prompt_letter <= "Z", "quick hands shows a letter (%s)" % sc.prompt_letter)
	sc._letter_pressed(sc.prompt_letter)
	check(sc.slips == 0 and sc.prompt_i == 1, "the right letter counts")
	sc.gap = 0.0
	sc._next_prompt()
	sc._letter_pressed("A" if sc.prompt_letter != "A" else "B")
	check(sc.slips == 1, "a wrong letter is a slip")
	sc.free()


func test_wanderer_quests() -> void:
	# Questionable Mushroom: one of the company, the Poisoner included (round 18).
	var qm: Dictionary = DB.skill("ss_mushroom")
	check(qm.target == "ally" and not qm.get("no_self", false) and not qm.get("aoe", false), "Questionable Mushroom targets any one of the party, self included")
	check(qm.effects.any(func(e): return e.type == "heal") and qm.effects.any(func(e): return e.type == "poison" and int(e.get("chance", 100)) == 25), "it heals, with a 25% chance of a light poison")
	var mco := Company.new()
	mco.new_game(52)
	var front: Hero = mco.make_hero("marshal", 1)
	var bp: Hero = mco.make_hero("sharpshooter", 1)
	bp.known = ["ss_mushroom"]
	bp.equipped = ["ss_mushroom"]
	var me := CombatEngine.new()
	me.setup([front, bp], ["prairie_wolf"], {})
	var bpc: Combatant = me.heroes.filter(func(x): return x.hero == bp)[0]
	var tg: Array = me.valid_targets(bpc, "ss_mushroom")
	check(tg.size() == 2, "the Poisoner can feed it to either hero, self included (%d targets)" % tg.size())
	var pe: Dictionary = DB.skill("ss_mushroom").effects.filter(func(x): return x.type == "poison")[0]
	var fc: Combatant = me.heroes.filter(func(x): return x.hero == front)[0]
	check(me.effect_chance(bpc, "ss_mushroom", pe, fc) == 25, "an ally's resist doesn't apply: the poison is a flat 25%% (%d)" % me.effect_chance(bpc, "ss_mushroom", pe, fc))
	bp.skill_levels["ss_mushroom"] = 5
	check(me.effect_chance(bpc, "ss_mushroom", pe, fc) == 25, "the mushroom's poison stays 25%% at every level")
	# Flash the Badge patches an ally up a little (round 17).
	var fb: Array = DB.skill("marshal_flash_badge").effects.filter(func(e): return e.type == "heal")
	check(fb.size() == 1 and int(fb[0].min) == 2 and int(fb[0].max) == 3, "Flash the Badge heals 2-3")
	var co := Company.new()
	co.new_game(51)
	co.complete_tutorial()
	co.story_flags["quest_run"] = true
	co.money += 5000
	co.timber += 50
	co.hides += 20
	co.iron += 20
	var has_wanderer := func() -> String:
		for q in co.settlement(0).quests:
			if str(DB.regions[q].get("template", "")).begins_with("wanderer"):
				return str(DB.regions[q].template)
		return ""
	co._refresh_settlement(co.settlement(0))
	check(has_wanderer.call() == "", "no Wanderer rumor before the first Chatter upgrade")
	check(co.upgrade_track(0, "saloon", "chatter"), "upgrade Chatter once")
	co._refresh_settlement(co.settlement(0))
	check(has_wanderer.call() == "wanderer_1" and co.settlement(0).quests.size() == int(co.track_value(0, "saloon", "chatter")) + 1, "chapter 1 appears on top of the usual chatter")
	var qid: String = co.settlement(0).quests.filter(func(q): return str(DB.regions[q].template) == "wanderer_1")[0]
	var reg: Dictionary = DB.regions[qid]
	check(reg.final == "boss" and reg.boss.showdown and reg.boss.enemies.is_empty() and str(reg.boss.duel.kind) == "showdown", "it ends in a showdown, not a fight")
	check(Company.quest_hints(reg).contains("showdown"), "the rumor says it ends in a showdown")
	# Lose: driven back with nothing more; the rumor comes back.
	var uids: Array = []
	for h in co.heroes:
		uids.append(h.uid)
	var run := co.start_run(0, uids, {"food": 6}, qid)
	check(run != null, "take the Wanderer's job")
	run.current = run.nodes.size() - 1
	var m0 := int(run.loot.money)
	var lost := run.finish_showdown("miss")
	check(not lost.won and run.driven_back and int(run.loot.money) == m0, "a miss loses the showdown: no reward")
	var sm := co.finish_run("driven_back")
	check(not co.story_flags.has("wanderer_1"), "chapter 1 isn't done after a loss")
	co._refresh_settlement(co.settlement(0))
	check(has_wanderer.call() == "wanderer_1", "the challenge comes back")
	# Win with a bullseye: the reward plus half its chips again; chapter 2 opens.
	qid = co.settlement(0).quests.filter(func(q): return str(DB.regions[q].template) == "wanderer_1")[0]
	for h in co.heroes:
		h.busy_weeks = 0
	run = co.start_run(0, uids, {"food": 6}, qid)
	run.current = run.nodes.size() - 1
	var pay := int(DB.regions[qid].quest_reward.money)
	var won := run.finish_showdown("bullseye")
	check(won.won and run.boss_won and int(won.money) >= pay + int(pay * 0.5), "a bullseye wins with a bonus (%d for a %d purse)" % [int(won.money), pay])
	co.finish_run("victory")
	check(co.story_flags.has("wanderer_1"), "chapter 1 done")
	co._refresh_settlement(co.settlement(0))
	check(has_wanderer.call() == "wanderer_2", "chapter 2 follows")
	# The last chapter pays the Silver Dollar, which quickens the draw.
	check(str(DB.quests.templates.wanderer_3.get("boss_keepsake", "")) == "wanderers_dollar", "chapter 3 pays the Wanderer's Silver Dollar")
	var gs: Hero = co.make_hero("gunslinger", 1)
	var e0 := Duel.edge(gs)
	gs.keepsakes.append("wanderers_dollar")
	check(is_equal_approx(Duel.edge(gs) - e0, 0.05), "the Silver Dollar draws 0.05 s faster")
	check(UI.keepsake_effects("wanderers_dollar").any(func(t): return str(t).contains("High Noon")), "its tooltip says so")


func test_building_locks() -> void:
	var co := Company.new()
	co.new_game(61)
	co.complete_tutorial()
	co.story_flags["quest_run"] = true
	co.money += 9000
	co.timber += 200
	co.iron += 100
	co.hides += 60
	for bid in ["chapel", "boot_hill", "trapping_post", "wheelwright", "doctor", "drill_hall", "mine", "stage_line"]:
		check(co.building_lock(0, bid) != "", "%s is locked at the start" % bid)
	for bid in ["hiring_board", "saloon", "general_store", "smithy", "lumber_yard"]:
		check(co.building_lock(0, bid) == "", "%s is open at the start" % bid)
	# A built building is never locked (old saves keep theirs).
	co.settlement(0).buildings["chapel"] = 1
	check(co.building_lock(0, "chapel") == "", "a built Chapel isn't locked")
	co.settlement(0).buildings.erase("chapel")
	# Townsfolk unlock: a Wheelwright, and the wagon grows.
	co.welcome_townsperson(co.make_townsperson("wheelwright", 1, "loyal"), 0)
	check(co.building_lock(0, "wheelwright") == "", "a Wheelwright in town opens the Wheelwright")
	check(co.build(0, "wheelwright"), "build the Wheelwright")
	co.set_wagon_for(0)
	check(Inventory.capacity() == int(DB.cfg("wagon_slots", 12)) + 2, "a level 1 Wheelwright adds 2 wagon slots")
	co.build(0, "wheelwright")
	var ww: Dictionary = co.townsfolk_at(0).filter(func(p): return p.trade == "wheelwright")[0]
	co.post_townsperson(ww, "wheelwright")
	co.set_wagon_for(0)
	check(Inventory.capacity() == int(DB.cfg("wagon_slots", 12)) + 5, "level 2 plus a Greenhorn Wheelwright: +5 slots (%d)" % Inventory.capacity())
	Inventory.extra_slots = 0
	# Settlers lean toward a trade that would open a building.
	var parsons := 0
	for n in 300:
		if co._pick_settler_trade(["parson", "storekeeper"]) == "parson":
			parsons += 1
	check(parsons > 190, "a trade that opens a building is likelier (%d of 300)" % parsons)
	# Schematic rumors: the Doctor's plans from week 3, the Drill Hall's from 4, the Mine's from 5.
	var plan_quests := func() -> Array:
		var out: Array = []
		for q in co.settlement(0).quests:
			var pl := str(DB.regions[q].get("plans", ""))
			if pl != "":
				out.append(pl)
		return out
	co.week = 2
	co._refresh_settlement(co.settlement(0))
	check(plan_quests.call().is_empty(), "no plans on the board in week 2")
	co.week = 3
	co._refresh_settlement(co.settlement(0))
	check(plan_quests.call() == ["doctor"], "week 3: the Travelling Surgeon (%s)" % [plan_quests.call()])
	co.week = 5
	co._refresh_settlement(co.settlement(0))
	check(plan_quests.call().size() == 3, "week 5: all three sets of plans (%s)" % [plan_quests.call()])
	var dq: String = co.settlement(0).quests.filter(func(q): return str(DB.regions[q].get("plans", "")) == "drill_hall")[0]
	check(Company.quest_hints(DB.regions[dq]).contains("plans for a Drill Hall"), "the rumor names the plans")
	# Winning the rumor's boss opens the building.
	var uids: Array = []
	for h in co.heroes:
		uids.append(h.uid)
	var run := co.start_run(0, uids, {"food": 6}, dq)
	run.current = run.nodes.size() - 1
	var e := CombatEngine.new()
	e.state = "victory"
	run.after_combat(e, "boss")
	co.finish_run("victory")
	check(co.building_lock(0, "drill_hall") == "", "the Drill Hall opens once its plans are won")
	co._refresh_settlement(co.settlement(0))
	check(not "drill_hall" in plan_quests.call(), "and its rumor is gone")


func test_glass_case() -> void:
	var co := Company.new()
	co.new_game(73)
	co.complete_tutorial()
	co.money += 9000
	co.timber += 120
	co.iron += 60
	co.hides += 30
	co.build(0, "general_store")
	co.restock_trinkets(0)
	check(co.settlement(0).stock.is_empty(), "a General Store sells no trinkets until its Glass Case is bought")
	check(co.upgrade_track(0, "general_store", "trinkets"), "buy the Glass Case")
	check(co.settlement(0).stock.size() in [1, 2], "the case stocks up at once (%d)" % co.settlement(0).stock.size())
	co.settlement(0).tier = "outpost"
	check(co.can_upgrade_track(0, "general_store", "trinkets") != "", "an Outpost can't take the case further")
	# Level 1 never shows a rare; level 3 often does, and shelves more.
	var rare1 := 0
	for n in 200:
		co.restock_trinkets(0)
		for k in co.settlement(0).stock:
			if DB.keepsakes[k].get("rarity", "") == "rare":
				rare1 += 1
	check(rare1 == 0, "no rares at the first case level (%d)" % rare1)
	co.settlement(0).tier = "city"
	co.upgrade_track(0, "general_store", "trinkets")
	check(co.upgrade_track(0, "general_store", "trinkets"), "a City takes the case to level 3")
	var rare3 := 0
	var shelved := 0
	for n in 200:
		co.restock_trinkets(0)
		shelved += co.settlement(0).stock.size()
		for k in co.settlement(0).stock:
			if DB.keepsakes[k].get("rarity", "") == "rare":
				rare3 += 1
	check(rare3 > 40, "rares turn up at level 3 (%d)" % rare3)
	check(shelved > 600, "more on the shelf at level 3 (%d over 200 weeks)" % shelved)


func test_storehouse() -> void:
	var co := Company.new()
	co.new_game(71)
	co.complete_tutorial()
	co.money += 3000
	co.timber += 60
	co.iron += 30
	co.hides += 20
	var uids: Array = []
	for h in co.heroes:
		uids.append(h.uid)
	# Leftover supplies come home into the storehouse.
	var run := co.start_run(0, uids, {"food": 8}, "tallgrass")
	check(run != null, "set out")
	run.supplies["whiskey"] = 3
	run.supplies["food"] = 2
	co.finish_run("abandoned")
	check(int(co.storehouse.get("whiskey", 0)) == 3 and int(co.storehouse.get("food", 0)) == 2, "leftovers go to the storehouse (%s)" % co.storehouse)
	# No General Store yet: stored goods still load, on top of the free kit, and nothing sells.
	check(co.can_embark(0, uids, {"food": 8, "whiskey": 3}, "tallgrass") == "", "stored whiskey loads without a store")
	check(co.can_embark(0, uids, {"whiskey": 4}, "tallgrass") != "", "but no more than is stored")
	check(co.sell_price(0, "whiskey") == 0, "no General Store, no buyer")
	co.build(0, "general_store")
	# Stored goods load first and are free; only the rest is bought.
	var price := co.item_price(0, "whiskey")
	check(co.supply_cost(0, {"whiskey": 3}) == 0, "stored whiskey is free to load")
	check(co.supply_cost(0, {"whiskey": 4}) == price, "the fourth is bought")
	for h in co.heroes:
		h.busy_weeks = 0
		h.fatigue = 0
	var m0 := co.money
	var run2 := co.start_run(0, uids, {"whiskey": 4, "food": 6}, "tallgrass")
	check(run2 != null and co.money == m0 - price - co.item_price(0, "food") * 4, "only what wasn't stored is paid for")
	check(not co.storehouse.has("whiskey") and not co.storehouse.has("food"), "loading empties the storehouse")
	co.finish_run("defeat")
	check(co.storehouse.is_empty(), "a wiped-out company brings nothing home")
	# Selling at the General Store: a share of the price by store level.
	co.storehouse["bandages"] = 2
	var each := co.sell_price(0, "bandages")
	check(each == int(floor(int(DB.items.bandages.price) * 30 / 100.0)), "a level 1 store pays 30%% (%d)" % each)
	var m1 := co.money
	check(co.sell_item(0, "bandages", 5) == each * 2 and co.money == m1 + each * 2 and not co.storehouse.has("bandages"), "sell what's there, no more")
	# Save and load.
	co.storehouse["rope"] = 1
	var co2 := Company.from_dict(DB.normalize(JSON.parse_string(JSON.stringify(co.to_dict()))))
	check(int(co2.storehouse.get("rope", 0)) == 1, "the storehouse saves")
	# Gold Fever: grabs treasure 25% of the time and pockets it half the time.
	var gf: Dictionary = DB.quirks.gold_fever.compulsion
	check(int(gf.chance) == 25 and int(gf.steal_chance) == 50, "Gold Fever: 25% grab, 50% pocket")


func test_clear_plots() -> void:
	var co := Company.new()
	co.new_game(81)
	co.complete_tutorial()
	co.money += 5000
	check(co.plot_cap(0) == 6, "a Town starts with 6 plots")
	var m0 := co.money
	check(co.clear_plot(0) and co.money == m0 - 250, "clear a plot for 250 chips")
	check(co.plot_cap(0) == 6 and co.can_clear_plot(0).contains("next week"), "it's ready next week, one at a time")
	var msgs := co.advance_week()
	check(co.plot_cap(0) == 7 and msgs.any(func(m): return str(m).contains("plot is cleared")), "a week later: 7 plots")
	check(co.clear_plot(0) and co.money == m0 - 250 - 500, "the second costs 500")
	co.advance_week()
	check(co.plot_cap(0) == 8 and co.clear_plot_cost(0).is_empty() and co.can_clear_plot(0) != "", "a Town tops out at 8")
	co.settlement(0).tier = "city"
	check(co.plot_cap(0) == 9, "a City has its own 9")
	var co2 := Company.from_dict(DB.normalize(JSON.parse_string(JSON.stringify(co.to_dict()))))
	co2.settlement(0).tier = "town"
	check(co2.plot_cap(0) == 8, "cleared plots save")
	# The plans rumors' fights are 3-4 strong (round 21).
	for tid in ["plans_doctor", "plans_drill_hall", "plans_mine"]:
		check(DB.quests.templates[tid].fights.all(func(f): return f.enemies.size() >= 3), "%s: no two-enemy fights" % tid)


func test_random_hits_repick() -> void:
	# Round 21: Fan the Hammer's later shots used to vanish when an earlier one killed their
	# pick (bones cleared). Now every shot finds a target while any stands.
	var co := Company.new()
	co.new_game(91)
	var gs: Hero = co.make_hero("gunslinger", 1)
	gs.known = ["gs_fan"]
	gs.equipped = ["gs_fan"]
	var full := 0
	var tries := 0
	for k in 60:
		var e := CombatEngine.new()
		var r := RandomNumberGenerator.new()
		r.seed = 1000 + k
		e.setup([gs], ["outlaw_brawler", "outlaw_gunhand"], {"rng": r})
		var weak: Combatant = e.enemies[0]
		weak.hp = 1
		var tough: Combatant = e.enemies[1]
		tough.hp = 999
		var c: Combatant = e.heroes[0]
		c.rank = 2
		var ev := e.use_skill(c, "gs_fan", tough.id)
		var swings := ev.filter(func(x): return x.t in ["hit", "miss"] and int(x.get("actor", -1)) == c.id and int(x.get("target", -1)) != c.id).size()
		tries += 1
		if swings >= 3:
			full += 1
	check(full == tries, "Fan the Hammer always fires all three shots (%d of %d volleys)" % [full, tries])
	# Twin Shots: when its target falls to the first shot, the second finds another.
	gs.known = ["gs_twin"]
	gs.equipped = ["gs_twin"]
	var both := 0
	for k in 30:
		var e2 := CombatEngine.new()
		var r2 := RandomNumberGenerator.new()
		r2.seed = 2000 + k
		e2.setup([gs], ["outlaw_brawler", "outlaw_gunhand", "outlaw_rifleman"], {"rng": r2})
		var c2: Combatant = e2.heroes[0]
		var pile: Combatant = e2.enemies.filter(func(x): return x.rank == 2)[0]
		pile.corpse = true   # bones in rank 2: the first shot clears them
		pile.hp = 1
		for x in e2.enemies:
			if x != pile:
				x.hp = 999
		var ev2 := e2.use_skill(c2, "gs_twin", pile.id)
		if ev2.filter(func(x): return x.t in ["hit", "miss"] and int(x.get("actor", -1)) == c2.id and int(x.get("target", -1)) != c2.id).size() >= 2:
			both += 1
	check(both == 30, "Twin Shots always fires both shots (%d of 30)" % both)
	gs.hp = gs.max_hp()


func test_look_ahead() -> void:
	# Round 21: without scouts, the next stops are often a mystery and rarely clear.
	var co := Company.new()
	co.new_game(95)
	co.complete_tutorial()
	var uids: Array = []
	for h in co.heroes:
		h.survival = {}
		h.quirks = []
		h.keepsakes = []
		uids.append(h.uid)
	var seen := 0
	var rough := 0
	var clear := 0
	for k in 40:
		co.rng.seed = 500 + k
		var run := RunState.create(co, "tallgrass", 0, uids, {"food": 8})
		check(run.scout_score() == 0.0, "no scouting in this party")
		for id in run.choices():
			var n: Dictionary = run.node(id)
			seen += 1
			if MapGen.intel(n) >= 1:
				rough += 1
			if MapGen.intel(n) >= 2:
				clear += 1
	var rp := rough * 100.0 / seen
	var cp := clear * 100.0 / seen
	check(rp > 35.0 and rp < 65.0, "about half the next stops get a rough look (%.0f%%)" % rp)
	check(cp > 3.0 and cp < 20.0, "about 1 in 10 is seen clearly (%.0f%%)" % cp)
	check(int(DB.survival.scout.passive.base) == 20 and int(DB.survival.scout.passive.per_rank) == 10, "the Scout skill: 20 / 30 / 40")


func test_frontliners() -> void:
	# Round 22: Grizzly Chop hits beasts harder (growing with level); Brace Yourselves braces
	# the ally beside the Rail Driver.
	var gc: Dictionary = DB.skill("mm_grizzly_chop")
	check(is_equal_approx(float(gc.vs_tags.beast), 0.15) and is_equal_approx(float(gc.vs_tags_per_level.beast), 0.05), "Grizzly Chop: +15% vs beasts, +5% a level")
	var co := Company.new()
	co.new_game(97)
	var mm: Hero = co.make_hero("mountain_man", 1)
	var e := CombatEngine.new()
	e.setup([mm], ["prairie_wolf", "outlaw_brawler"], {})
	var mc: Combatant = e.heroes[0]
	var wolf: Combatant = e.enemies.filter(func(x): return x.enemy_id == "prairie_wolf")[0]
	var thug: Combatant = e.enemies.filter(func(x): return x.enemy_id == "outlaw_brawler")[0]
	check(e.dmg_mult(mc, "mm_grizzly_chop", wolf) > e.dmg_mult(mc, "mm_grizzly_chop", thug) + 0.3, "Grizzly Chop hits a wolf harder than an outlaw (%.2f vs %.2f)" % [e.dmg_mult(mc, "mm_grizzly_chop", wolf), e.dmg_mult(mc, "mm_grizzly_chop", thug)])
	# Brace Yourselves from rank 1: the ally in rank 2.
	var rd: Hero = co.make_hero("rail_driver", 1)
	var a2: Hero = co.make_hero("gunslinger", 1)
	var a3: Hero = co.make_hero("preacher", 1)
	rd.known = ["rd_brace"]
	rd.equipped = ["rd_brace"]
	var prot_of := func(c: Combatant) -> int:
		var n := 0
		for b in c.buffs:
			if b.stat == "prot":
				n += int(b.value)
		return n
	var e2 := CombatEngine.new()
	e2.setup([rd, a2, a3], ["outlaw_brawler"], {})
	var rc: Combatant = e2.heroes.filter(func(x): return x.hero == rd)[0]
	var c2: Combatant = e2.heroes.filter(func(x): return x.hero == a2)[0]
	var c3: Combatant = e2.heroes.filter(func(x): return x.hero == a3)[0]
	rc.rank = 1
	c2.rank = 2
	c3.rank = 3
	e2.use_skill(rc, "rd_brace", rc.id)
	check(prot_of.call(c2) == 10 and prot_of.call(c3) == 0, "from rank 1, the ally in rank 2 gets +10 Protection")
	# From rank 2: the more hurt of ranks 1 and 3.
	var e3 := CombatEngine.new()
	e3.setup([a2, rd, a3], ["outlaw_brawler"], {})
	rc = e3.heroes.filter(func(x): return x.hero == rd)[0]
	c2 = e3.heroes.filter(func(x): return x.hero == a2)[0]
	c3 = e3.heroes.filter(func(x): return x.hero == a3)[0]
	c2.rank = 1
	rc.rank = 2
	c3.rank = 3
	c3.hp = 1
	e3.use_skill(rc, "rd_brace", rc.id)
	check(prot_of.call(c3) == 10 and prot_of.call(c2) == 0, "from rank 2, the more hurt neighbour (rank 3) gets it")
