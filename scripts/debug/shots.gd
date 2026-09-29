class_name Shots
extends RefCounted
## Screenshot scenarios for visual QA (run with a display, e.g. under xvfb):
##   godot --path . -- shot=combat out=/tmp/combat.png


static func run(main: Main, args: Dictionary) -> void:
	var tree := main.get_tree()
	var scenario: String = args.get("shot", "menu")
	var out: String = args.get("out", "user://shot.png")
	var wait := int(args.get("wait", "40"))
	if scenario == "autoplay":
		Game.delete_save()
		var ap = load("res://tests/autopilot.gd").new()
		ap.expeditions_target = int(args.get("expeditions", "3"))
		main.add_child(ap)
		await main.goto("menu", {}, true)
		return
	if args.has("nopaper"):
		PaperFX.enabled = false
	Game.company = Company.new()
	Game.company.new_game(int(args.get("seed", "12")))
	match scenario:
		"menu":
			await main.goto("menu", {}, true)
		"lineup":
			await main.goto("menu", {}, true)
			main.screen.queue_free()
			var root := Control.new()
			root.set_anchors_preset(Control.PRESET_FULL_RECT)
			main.add_child(root)
			var bg := Backdrop.new()
			bg.paper = args.has("paper")
			bg.setup(args.get("region", "tallgrass"), "trail", 3)
			root.add_child(bg)
			var ids: Array = DB.classes.keys() if args.get("set", "heroes") == "heroes" else DB.enemies.keys()
			var start := int(args.get("from", "0"))
			ids = ids.slice(start, start + 10)
			for i in ids.size():
				var f := Figure.new()
				var look: Dictionary = DB.classes[ids[i]].look if DB.classes.has(ids[i]) else DB.enemies[ids[i]].look
				f.setup(look, 50 + i, 1 if DB.classes.has(ids[i]) else -1)
				var row := i / 5
				f.position = Vector2(200 + (i % 5) * 360, 480 + row * 440)
				f.scale *= float(args.get("zoom", "0.9"))
				if args.has("paper"):
					f.crafted = true
					var pg := PaperFX.group({"shadow_offset": Vector2(10, 7), "shadow_alpha": 0.3, "bevel_strength": 1.1}, 30.0)
					pg.add_child(f)
					root.add_child(pg)
				else:
					root.add_child(f)
				var l := UI.lbl(ids[i], 20, "Bold")
				l.position = f.position + Vector2(-80, 20)
				root.add_child(l)
		"settlement":
			await main.goto("settlement", {"index": 0}, true)
		"silas":
			# Silas's gambit, triggered at once (in-memory tweak for the screenshot only).
			Game.company.complete_tutorial()
			DB.regions.tallgrass.boss.first_script.round = 1
			var uids3: Array = []
			for h in Game.company.heroes.slice(0, 4):
				uids3.append(h.uid)
			Game.company.start_run(0, uids3, Game.company.free_kit())
			await main.goto("combat", {"enemies": DB.regions.tallgrass.boss.enemies, "kind": "boss", "return": "trail"}, true)
		"tutorial":
			Game.company.start_tutorial()
			await main.goto("trail", {}, true)
			if args.has("node"):
				main.close_all_modals()
				Game.company.run.travel_to(int(args.node))
				await main.goto("trail", {}, true)
			if args.has("act"):
				# The tutorial's first fight, entered the way the trail does it.
				main.close_all_modals()
				var tr = main.screen
				var n1: Dictionary = Game.company.run.current_node()
				n1.data["story_seen"] = true
				tr._resolve_node()
				await tree.create_timer(2.0).timeout
				await _act(main, args)
		"embark":
			Game.company.complete_tutorial()
			Game.company.advance_week()
			await main.goto("embark", {"index": 0, "dest": args.get("dest", "tallgrass")}, true)
		"trail", "combat", "camp", "cave", "event", "curio":
			var co: Company = Game.company
			co.complete_tutorial()
			var uids: Array = []
			for h in co.heroes.slice(0, 4):
				uids.append(h.uid)
			# The first settlement has no store yet: start with the free kit, then pack extras.
			co.start_run(0, uids, co.free_kit())
			co.run.supplies.merge({"bandages": 2, "lamp_oil": 2, "shovel": 1, "salt": 1}, true)
			match scenario:
				"trail":
					await main.goto("trail", {}, true)
					if args.has("hover"):
						# Hover the first stop you can travel to, to check the map tooltip.
						var mv: MapView = main.screen.map
						var id: int = mv.run.choices()[0]
						Input.warp_mouse(mv.get_global_transform_with_canvas() * mv.node_pos(mv.run.node(id)))
						await main.get_tree().create_timer(2.0).timeout
				"combat":
					var enemies: Array = args.get("enemies", "outlaw_brawler,outlaw_gunhand,prairie_wolf,outlaw_rifleman").split(",")
					await main.goto("combat", {"enemies": enemies, "kind": args.get("kind", "fight"), "return": "trail"}, true)
					if args.has("act"):
						await _act(main, args)
				"camp":
					await main.goto("camp", {}, true)
				"cave":
					co.run.cave_enter()
					await main.goto("cave", {}, true)
				"event":
					await main.goto("trail", {}, true)
					main.screen.show_event(args.get("id", "river_crossing"))
				"curio":
					await main.goto("trail", {}, true)
					main.screen.show_curios([{"id": "abandoned_wagon", "done": false}, {"id": "whiskey_barrel", "done": false}, {"id": "standing_stone", "done": false}])
		"results":
			var co2: Company = Game.company
			var uids2: Array = []
			for h in co2.heroes.slice(0, 4):
				uids2.append(h.uid)
			co2.start_run(0, uids2, co2.free_kit())
			co2.run.loot = {"money": 320, "timber": 6, "iron": 3, "charters": 2, "keepsakes": ["lucky_horseshoe"]}
			co2.run.xp = 12
			co2.run.boss_won = true
			co2.beaten.append("tallgrass")
			var summary := co2.finish_run("victory")
			await main.goto("results", {"summary": summary}, true)
		"hero":
			await main.goto("settlement", {"index": 0}, true)
			main.screen.open_hero(Game.company.heroes[0])
		"building":
			var cb: Company = Game.company
			cb.complete_tutorial()
			cb.money += 500
			for h in cb.heroes:
				h.fatigue = 55
			var acts: Array = DB.buildings.saloon.activities
			cb.do_activity(0, "saloon", acts[0].id, cb.heroes[0])
			await main.goto("settlement", {"index": 0}, true)
			main.screen.open_building(args.get("id", "saloon"))
	for i in wait:
		await tree.process_frame
	var img := main.get_viewport().get_texture().get_image()
	img.save_png(out)
	print("saved ", out)
	tree.quit()


## Plays hero turns in the open combat with each hero's first move (or skill=...), printing
## what happens, so runtime errors show up in the log.
static func _act(main: Main, args: Dictionary) -> void:
	var tree := main.get_tree()
	var cs = main.screen
	for turn in int(args.get("act", "1")):
		for k in 900:
			if cs.get("engine") != null and cs.engine.awaiting_input():
				break
			await tree.process_frame
		if cs.get("engine") == null or not cs.engine.awaiting_input():
			print("ACT: no hero turn (", main.screen.name, ")")
			break
		var hc: Combatant = cs.engine.current
		var sid: String = args.get("skill", hc.skills[0])
		if sid == "random":
			var us: Array = cs.engine.usable_skills(hc)
			sid = us[randi() % us.size()] if not us.is_empty() else hc.skills[0]
		var vt: Array = cs.engine.valid_targets(hc, sid)
		if args.get("skill", "") == "random" and not vt.is_empty():
			vt.shuffle()
		print("ACT ", hc.display_name, " ", sid, " -> ", vt)
		if vt.is_empty():
			cs.chosen.emit("pass", null, null)
		else:
			cs.chosen.emit("skill", sid, vt[0])
		await tree.create_timer(float(args.get("gap", "4.0"))).timeout
		if cs.engine.is_over():
			print("ACT: fight over (", cs.engine.state, ")")
			break
