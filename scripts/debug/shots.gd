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
	# side: the old side-on body build instead of the three-quarter turn (before/after).
	if args.has("side"):
		Figure.three_quarter = false
	if args.has("body"):
		Figure.default_body = int(args.body)
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
		"eye_ab":
			# The same Marshal head with six eye treatments: the approved white oval first,
			# then five black-only shapes.
			await main.goto("menu", {}, true)
			main.screen.queue_free()
			var root := Control.new()
			root.set_anchors_preset(Control.PRESET_FULL_RECT)
			main.add_child(root)
			var bgc := ColorRect.new()
			bgc.color = Color("#8a7a5e")
			bgc.set_anchors_preset(Control.PRESET_FULL_RECT)
			root.add_child(bgc)
			var labels: Array = ["0 white oval", "1 black dot", "2 tall oval", "3 wide oval", "4 dot + lid", "5 L bracket"]
			for i in 6:
				var f := Figure.new()
				f.crafted = true
				f.eye_style = i
				f.setup(DB.classes["marshal"].look, 7, 1)
				f.scale *= 2.4
				f.position = Vector2(210 + i * 300, 760)
				root.add_child(f)
				var txt: String = labels[i]
				var l := UI.lbl(txt, 20, "Bold")
				l.position = Vector2(120 + i * 300, 776)
				root.add_child(l)
		"hat_ab":
			# Marshal, Gunslinger and Wrangler: the old shared hat on top, the distinct
			# silhouettes underneath. These three are the classes that looked identical.
			await main.goto("menu", {}, true)
			main.screen.queue_free()
			var root := Control.new()
			root.set_anchors_preset(Control.PRESET_FULL_RECT)
			main.add_child(root)
			var bgc := ColorRect.new()
			bgc.color = Color("#8a7a5e")
			bgc.set_anchors_preset(Control.PRESET_FULL_RECT)
			root.add_child(bgc)
			var ids: Array = ["marshal", "gunslinger", "wrangler"]
			for row in 2:
				var feet: float = 500.0 + row * 450.0
				var tag: String = "BEFORE  shared shape" if row == 0 else "NEW  distinct silhouettes"
				var t := UI.lbl(tag, 22, "Bold")
				t.position = Vector2(20, feet - 420.0)
				root.add_child(t)
				for i in ids.size():
					var cid: String = ids[i]
					var f := Figure.new()
					f.crafted = true
					f.hat_style = row
					f.setup(DB.cls(cid).look, 7, 1)
					f.scale *= 1.6
					f.position = Vector2(420 + i * 520, feet)
					root.add_child(f)
					var l := UI.lbl(cid, 20, "Bold")
					l.position = Vector2(360 + i * 520, feet + 14.0)
					root.add_child(l)
		"face_shift":
			# The approved face at four forward offsets, to pick how far off the head it sits.
			await main.goto("menu", {}, true)
			main.screen.queue_free()
			var root := Control.new()
			root.set_anchors_preset(Control.PRESET_FULL_RECT)
			main.add_child(root)
			var bgc := ColorRect.new()
			bgc.color = Color("#8a7a5e")
			bgc.set_anchors_preset(Control.PRESET_FULL_RECT)
			root.add_child(bgc)
			var shifts: Array = [9.0, 6.0, 4.0, 2.0]
			for i in shifts.size():
				var f := Figure.new()
				f.crafted = true
				f.face_shift = float(shifts[i])
				f.setup(DB.classes["marshal"].look, 7, 1)
				f.scale *= 1.9
				f.position = Vector2(300 + i * 400, 700)
				root.add_child(f)
				var txt: String = "shift %.0f" % float(shifts[i])
				var l := UI.lbl(txt, 22, "Bold")
				l.position = Vector2(250 + i * 400, 716)
				root.add_child(l)
		"face_pose":
			# The approved face across every pose, so the brows and mouth can be judged.
			await main.goto("menu", {}, true)
			main.screen.queue_free()
			var root := Control.new()
			root.set_anchors_preset(Control.PRESET_FULL_RECT)
			main.add_child(root)
			var bgc := ColorRect.new()
			bgc.color = Color("#8a7a5e")
			bgc.set_anchors_preset(Control.PRESET_FULL_RECT)
			root.add_child(bgc)
			var poses: Array = ["idle", "windup", "strike", "aim", "cast", "hurt", "dead"]
			for i in poses.size():
				var f := Figure.new()
				f.crafted = true
				f.setup(DB.classes["marshal"].look, 7, 1)
				f.set_pose(str(poses[i]))
				f.scale *= 1.5
				var col: int = i % 4
				var row: int = i / 4
				f.position = Vector2(280 + col * 420, 520 + row * 520)
				root.add_child(f)
				var l := UI.lbl(str(poses[i]), 22, "Bold")
				l.position = Vector2(220 + col * 420, 536 + row * 520)
				root.add_child(l)
		"face_ab":
			# One Marshal face four ways, top row at lineup scale and bottom row at combat
			# scale, to show whether the hovering cartoon face survives being small.
			await main.goto("menu", {}, true)
			main.screen.queue_free()
			var root := Control.new()
			root.set_anchors_preset(Control.PRESET_FULL_RECT)
			main.add_child(root)
			var bgc := ColorRect.new()
			bgc.color = Color("#8a7a5e")
			bgc.set_anchors_preset(Control.PRESET_FULL_RECT)
			root.add_child(bgc)
			var labels: Array = ["ORIGINAL", "FACE 1 hover", "FACE 2 buttons", "FACE 3 mask"]
			for row in 2:
				var sc: float = 1.9 if row == 0 else 1.15
				var feet: float = 430.0 + row * 430.0
				for i in 4:
					var f := Figure.new()
					f.crafted = true
					f.face_style = i
					f.setup(DB.classes["marshal"].look, 7, 1)
					f.scale *= sc
					f.position = Vector2(300 + i * 400, feet)
					root.add_child(f)
					if row == 0:
						var txt: String = labels[i]
						var l := UI.lbl(txt, 20, "Bold")
						l.position = Vector2(190 + i * 400, feet + 16.0)
						root.add_child(l)
				var tag: String = "lineup scale 1.9" if row == 0 else "combat scale 1.15"
				var t := UI.lbl(tag, 20, "Bold")
				t.position = Vector2(20, feet + 16.0)
				root.add_child(t)
		"figure_ab":
			# One Marshal drawn four ways, left to right: the current look, then the three
			# art variants. Compare the cream border and the shading.
			await main.goto("menu", {}, true)
			main.screen.queue_free()
			var root := Control.new()
			root.set_anchors_preset(Control.PRESET_FULL_RECT)
			main.add_child(root)
			var bgc := ColorRect.new()
			bgc.color = Color("#8a7a5e")
			bgc.set_anchors_preset(Control.PRESET_FULL_RECT)
			root.add_child(bgc)
			var labels: Array = ["BEFORE  style 0", "V1  thin edge", "V2  finer + inset", "V3  cross-hatch"]
			for i in 4:
				var f := Figure.new()
				f.crafted = true
				f.style = i
				f.setup(DB.classes["marshal"].look, 7, 1)
				f.position = Vector2(300 + i * 400, 900)
				f.scale *= 1.7
				root.add_child(f)
				var txt: String = labels[i]
				var l := UI.lbl(txt, 22, "Bold")
				l.position = Vector2(170 + i * 400, 930)
				root.add_child(l)
		"faces":
			# Faces: Figure.face_look 0-5. Default: close-ups of the Marshal, 3 x 2.
			# cast: combat-size columns (faces 0-5) for four classes in four poses.
			await main.goto("menu", {}, true)
			main.screen.queue_free()
			var froot := Control.new()
			froot.set_anchors_preset(Control.PRESET_FULL_RECT)
			main.add_child(froot)
			var fnames: Array = ["0  CURRENT", "1  PROFILE", "2  LIGNE CLAIRE", "3  RUGGED", "4  STORYBOOK", "5  BRIM SHADOW", "6  PROFILE + TOON"]
			if args.has("poses"):
				# Every pose, face 1 (profile) on top and face 6 (profile + storybook reactions)
				# below. small: combat size instead, face 6 for four classes.
				var pl: Array = ["idle", "aim", "windup", "strike", "cast", "hurt", "dead"]
				var small := args.has("small")
				if small:
					var bgd3 := Backdrop.new()
					bgd3.setup("tallgrass", "trail", 3)
					froot.add_child(bgd3)
				var classes: Array = ["marshal", "gunslinger", "mountain_man", "preacher"] if small else [args.get("cls", "marshal"), args.get("cls", "marshal")]
				# classes=a,b,c,d: which four (hero classes or enemy ids) the small grid shows.
				if small and args.has("classes"):
					classes = str(args.classes).split(",")
				for r in classes.size():
					for i in pl.size():
						var cellp := Control.new()
						cellp.clip_contents = true
						cellp.position = Vector2(i * 274, r * (270 if small else 540))
						cellp.size = Vector2(272, 268 if small else 536)
						froot.add_child(cellp)
						if not small:
							var cb := ColorRect.new()
							cb.color = Color("#cdb892") if ((i + r) % 2 == 0) else Color("#c4ad86")
							cb.set_anchors_preset(Control.PRESET_FULL_RECT)
							cellp.add_child(cb)
						var fp := Figure.new()
						fp.face_look = 6 if (small or r == 1) else 1
						var plook: Dictionary = DB.classes[classes[r]].look if DB.classes.has(classes[r]) else DB.enemy(classes[r]).get("look", {})
						fp.setup(plook, 7 + r if small else 7, 1)
						fp.set_pose(pl[i])
						var pz := float(args.get("zoom", "2.6"))
						# Centre the head: the body leans about (0, -10) per pose (see Figure._build_human).
						var lean: float = {"aim": 0.04, "windup": -0.08, "strike": 0.14, "hurt": -0.16, "cast": -0.05}.get(pl[i], 0.0)
						var hd: Vector2 = Vector2(0, -10) + Vector2(8, -170).rotated(lean)
						fp.position = Vector2(120, 250) if small else Vector2(136, 250) - hd * pz
						fp.scale *= (1.05 if small else pz)
						cellp.add_child(fp)
						if r == 0 or not small:
							var lp := UI.lbl(pl[i].to_upper() + ("" if small else ("  (6)" if r == 1 else "  (1)")), 18, "Bold")
							lp.add_theme_constant_override("outline_size", 6)
							lp.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
							lp.position = Vector2(10, 6)
							cellp.add_child(lp)
			elif args.has("cast"):
				var bgd2 := Backdrop.new()
				bgd2.setup("tallgrass", "trail", 3)
				froot.add_child(bgd2)
				var rows: Array = [["marshal", "idle"], ["gunslinger", "aim"], ["mountain_man", "strike"], ["preacher", "hurt"]]
				for r in rows.size():
					for i in 6:
						var fc := Figure.new()
						fc.face_look = i
						fc.setup(DB.classes[rows[r][0]].look, 11 + r, 1)
						fc.set_pose(rows[r][1])
						fc.position = Vector2(160 + i * 318, 290 + r * 258)
						fc.scale *= 1.05
						froot.add_child(fc)
				for i in 6:
					var lc := UI.lbl(fnames[i], 20, "Bold")
					lc.add_theme_constant_override("outline_size", 6)
					lc.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
					lc.position = Vector2(60 + i * 318, 6)
					froot.add_child(lc)
			else:
				var bgc2 := ColorRect.new()
				bgc2.color = Color("#b9a27c")
				bgc2.set_anchors_preset(Control.PRESET_FULL_RECT)
				froot.add_child(bgc2)
				for i in 6:
					var cell := Control.new()
					cell.clip_contents = true
					cell.position = Vector2((i % 3) * 640, (i / 3) * 540)
					cell.size = Vector2(636, 536)
					froot.add_child(cell)
					var cbg := ColorRect.new()
					cbg.color = Color("#cdb892") if (i % 2 == 0) else Color("#c4ad86")
					cbg.set_anchors_preset(Control.PRESET_FULL_RECT)
					cell.add_child(cbg)
					var fz := Figure.new()
					fz.face_look = i
					fz.setup(DB.classes[args.get("cls", "marshal")].look, 7, 1)
					if args.has("pose"):
						fz.set_pose(args.pose)
					fz.position = Vector2(318, 1030)
					fz.scale *= float(args.get("zoom", "4.2"))
					cell.add_child(fz)
					var lz := UI.lbl(fnames[i], 24, "Bold")
					lz.add_theme_constant_override("outline_size", 6)
					lz.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
					lz.position = Vector2(14, 10)
					cell.add_child(lz)
		"outfits":
			# Every class (columns) in each of its outfits (rows), same seed so only colors change.
			await main.goto("menu", {}, true)
			main.screen.queue_free()
			var oroot := Control.new()
			oroot.set_anchors_preset(Control.PRESET_FULL_RECT)
			main.add_child(oroot)
			var obg := Backdrop.new()
			obg.setup("tallgrass", "trail", 3)
			oroot.add_child(obg)
			var ocls: Array = ["marshal", "mountain_man", "rail_driver", "gunslinger", "wrangler", "gambler", "prospector", "sharpshooter", "frontier_doctor", "preacher", "train_hopper"]
			for ci in ocls.size():
				var olook: Dictionary = DB.classes[ocls[ci]].look
				var ol: Array = olook.get("outfits", [{}])
				for oi in ol.size():
					var fo := Figure.new()
					fo.outfit = oi
					fo.setup(olook, 5 + ci, 1)
					fo.position = Vector2(80 + ci * 172, 318 + oi * 352)
					fo.scale *= 1.0
					oroot.add_child(fo)
					var lo := UI.lbl(str(ol[oi].get("name", "")), 16, "Bold")
					lo.add_theme_constant_override("outline_size", 6)
					lo.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
					lo.position = Vector2(8 + ci * 172, 326 + oi * 352)
					oroot.add_child(lo)
		"body_ab":
			# The Marshal in every body style (Figure.body_style 0-5), idle on top, aiming
			# below, over the Tallgrass backdrop. cls=<class id> to try another class.
			await main.goto("menu", {}, true)
			main.screen.queue_free()
			var root := Control.new()
			root.set_anchors_preset(Control.PRESET_FULL_RECT)
			main.add_child(root)
			var bgd := Backdrop.new()
			bgd.setup("tallgrass", "trail", 3)
			root.add_child(bgd)
			var shade := ColorRect.new()
			shade.color = Color(0, 0, 0, 0.18)
			shade.set_anchors_preset(Control.PRESET_FULL_RECT)
			root.add_child(shade)
			var names: Array = ["0  CURRENT", "1  TAILORED CURVES", "2  COSTUME DETAIL", "3  PAPER PUPPET", "4  INK ILLUSTRATION", "5  PAINTED VOLUME"]
			var cid: String = args.get("cls", "marshal")
			if args.has("grid"):
				# Close-up: 3 x 2, idle pose, bigger.
				for i in 6:
					var fg := Figure.new()
					fg.crafted = true
					fg.body_style = i
					fg.setup(DB.classes[cid].look, 7, 1)
					fg.position = Vector2(360 + (i % 3) * 630, 500 + (i / 3) * 530)
					fg.scale *= float(args.get("zoom", "1.9"))
					root.add_child(fg)
					var lg := UI.lbl(names[i], 24, "Bold")
					lg.add_theme_constant_override("outline_size", 6)
					lg.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
					lg.position = Vector2(20 + (i % 3) * 630, 160 + (i / 3) * 530)
					root.add_child(lg)
			for row in (0 if args.has("grid") else 2):
				for i in 6:
					var f := Figure.new()
					f.crafted = true
					f.body_style = i
					f.setup(DB.classes[cid].look, 7, 1)
					if row == 1:
						f.set_pose("aim")
					f.position = Vector2(170 + i * 316, 470 + row * 450)
					f.scale *= float(args.get("zoom", "1.55"))
					root.add_child(f)
				if row == 0:
					for i in 6:
						var l := UI.lbl(names[i], 20, "Bold")
						l.add_theme_constant_override("outline_size", 6)
						l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
						l.position = Vector2(60 + i * 316, 500)
						root.add_child(l)
		"settlement":
			await main.goto("settlement", {"index": 0}, true)
			# hover=N: show plot N highlighted, as under the mouse.
			if args.has("hover"):
				main.screen.town.hover = int(args.hover)
				main.screen.town.queue_redraw()
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
			# full: fill the party to four (the starting company only has two).
			if args.has("full"):
				for cid in ["mountain_man", "preacher"]:
					if co.heroes.size() < 4:
						co.heroes.append(co.make_hero(cid, 1))
			# with=<class>: a hero of that class takes the last party seat, knowing skill=<id>
			# when that's one of its moves (to watch a particular move play out).
			if args.has("with"):
				var wh: Hero = co.make_hero(str(args.with), 1)
				var ws := str(args.get("skill", ""))
				if ws in DB.classes[str(args.with)].skills and not ws in wh.equipped:
					wh.known.append(ws)
					wh.equipped[0] = ws
				co.heroes.insert(mini(3, co.heroes.size()), wh)
			# party=a,b,c,d: replace the company with heroes of these classes.
			if args.has("party"):
				co.heroes = []
				for cid in str(args.party).split(","):
					co.heroes.append(co.make_hero(cid, 1))
			var uids: Array = []
			for h in co.heroes.slice(0, 4):
				uids.append(h.uid)
			# The first settlement has no store yet: start with the free kit, then pack extras.
			co.start_run(0, uids, co.free_kit())
			co.run.supplies.merge({"bandages": 2, "lamp_oil": 2, "shovel": 1, "salt": 1}, true)
			# region=<id>: dress the run as another region (backdrop checks); far: stand at the
			# last column, to see the end-of-map backdrop variant.
			if args.has("region"):
				co.run.region_id = args.region
			if args.has("far"):
				for ni in co.run.nodes.size():
					if int(co.run.nodes[ni].get("col", 0)) > int(co.run.current_node().get("col", 0)):
						co.run.current = ni
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
					# ehp=N: every enemy starts at N HP, to reach a killing blow quickly.
					if args.has("ehp"):
						for ec in main.screen.engine.enemies:
							ec.hp = int(args.ehp)
					# statuses: pile buffs, debuffs and damage over time on everyone (chip layout).
					if args.has("statuses"):
						var eng: CombatEngine = main.screen.engine
						for u in eng.heroes + eng.enemies:
							u.dots.append({"kind": "bleed", "amount": 2, "rounds": 3})
							u.dots.append({"kind": "poison", "amount": 3, "rounds": 3})
							for m in [["acc", 10], ["dodge", -8], ["dmg_pct", 15], ["speed", -2], ["prot", 10]]:
								u.buffs.append({"stat": m[0], "value": m[1], "rounds": 3, "name": "Test"})
							u.mark = 2
					# momentum=N: Momentum heroes (the Train Hopper) start with N in the gauge.
					if args.has("momentum"):
						for hc in main.screen.engine.heroes:
							if hc.uses_momentum():
								hc.momentum = int(args.momentum)
								if main.screen.engine.current == hc:
									main.screen._show_controls()
					# bones=N: the first N enemies fall and leave their bones (DD-style corpses).
					if args.has("bones"):
						var eb: CombatEngine = main.screen.engine
						for k in int(args.bones):
							var bev: Array = []
							var live := eb.enemies.filter(func(x): return not x.corpse)
							eb._apply_damage(live[0], 999, eb.heroes[0], bev, false)
							eb._cleanup(bev)
							await main.screen._play(bev)
						await main.get_tree().create_timer(1.5).timeout
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
					# pick=<curio id>: open "Who investigates?" on it, to see the ★/✗ expert lines.
					if args.has("pick"):
						var cid := str(args.pick)
						HeroPicker.pick(co.run.party_heroes(), "Who investigates?", func(_h): pass,
							func(x: Hero): return co.run.curio_hint(cid, x))
					else:
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
	# soak=N: sit idle for N seconds, printing what grows (leak and crash hunting).
	if args.has("soak"):
		var secs := int(args.soak)
		var t0 := Time.get_ticks_msec()
		var next := 0
		while Time.get_ticks_msec() - t0 < secs * 1000:
			await tree.process_frame
			var el: int = (Time.get_ticks_msec() - t0) / 1000
			if el >= next:
				next += 10
				print("SOAK t=%ds fps=%d objects=%d nodes=%d orphans=%d mem=%.1fMB vmem=%.1fMB canvas_items=%d draws=%d" % [el,
					Performance.get_monitor(Performance.TIME_FPS), Performance.get_monitor(Performance.OBJECT_COUNT),
					Performance.get_monitor(Performance.OBJECT_NODE_COUNT), Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),
					Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
					Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
					Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
					Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)])
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
			if not is_instance_valid(cs) or main.screen != cs:
				break
			if cs.get("engine") != null and cs.engine.awaiting_input():
				break
			await tree.process_frame
		if not is_instance_valid(cs) or main.screen != cs:
			print("ACT: fight over (left combat)")
			break
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
			# frames=N: save N frames 0.15 s apart while the move plays (<out>_f0.png ...).
			if args.has("frames"):
				for f in int(args.frames):
					await tree.create_timer(float(args.get("frame_gap", "0.15"))).timeout
					var fimg := main.get_viewport().get_texture().get_image()
					fimg.save_png(str(args.get("out", "user://shot.png")).trim_suffix(".png") + "_f%d.png" % f)
		await tree.create_timer(float(args.get("gap", "4.0"))).timeout
		if not is_instance_valid(cs) or main.screen != cs:
			print("ACT: fight over (left combat)")
			break
		if cs.engine.is_over():
			print("ACT: fight over (", cs.engine.state, ")")
			break
