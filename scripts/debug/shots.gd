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
			Game.company.start_run(0, uids3, {"food": 10})
			await main.goto("combat", {"enemies": DB.regions.tallgrass.boss.enemies, "kind": "boss", "return": "trail"}, true)
		"tutorial":
			Game.company.start_tutorial()
			await main.goto("trail", {}, true)
			if args.has("node"):
				main.close_all_modals()
				Game.company.run.travel_to(int(args.node))
				await main.goto("trail", {}, true)
		"embark":
			Game.company.complete_tutorial()
			await main.goto("embark", {"index": 0, "dest": args.get("dest", "tallgrass")}, true)
		"trail", "combat", "camp", "cave", "event", "curio":
			var co: Company = Game.company
			co.complete_tutorial()
			var uids: Array = []
			for h in co.heroes.slice(0, 4):
				uids.append(h.uid)
			co.start_run(0, uids, {"food": 16, "bandages": 2, "lamp_oil": 2, "shovel": 1, "salt": 1})
			match scenario:
				"trail":
					await main.goto("trail", {}, true)
				"combat":
					var enemies: Array = args.get("enemies", "outlaw_brawler,outlaw_gunhand,prairie_wolf,outlaw_rifleman").split(",")
					await main.goto("combat", {"enemies": enemies, "kind": args.get("kind", "fight"), "return": "trail"}, true)
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
			co2.start_run(0, uids2, {"food": 16})
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
