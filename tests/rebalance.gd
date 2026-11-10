extends SceneTree
const Combat = preload("res://combat.gd")
var game
var checks = 0
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok and failures.size() < 20: failures.append(message)
func _initialize() -> void: call_deferred("run")
func flood(data: Dictionary, block_gate: bool = false, abilities: bool = true) -> Dictionary:
	var todo = [Vector2i(6,5)]
	var seen = {Vector2i(6,5):true}
	var bounds: Rect2i = data.bounds
	while not todo.is_empty():
		var at = todo.pop_front()
		for dir in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
			var p = at+dir
			if p.x <= bounds.position.x or p.x >= bounds.end.x-1 or p.y <= bounds.position.y or p.y >= bounds.end.y-1 or seen.has(p): continue
			var kind = data.entities.get(p,{}).get("kind","")
			if data.walls.has(p) and not (abilities and kind=="crack"): continue
			if not abilities and kind=="water": continue
			if block_gate and p==data.gate: continue
			seen[p]=true
			todo.append(p)
	return seen
func run() -> void:
	game=load("res://main.gd").new()
	game.save_path="res://tests/.rebalance-save.json"
	root.add_child(game);preload("res://tools/test_equipment.gd").arm(game)
	game.muted=true
	game.set_process(false)
	var sizes: Dictionary={}
	var layouts: Dictionary={}
	var guarded_count=0
	for seed_value in range(300):
		game.new_run(seed_value);preload("res://tools/test_equipment.gd").arm(game)
		var blockers=0
		var blessings=0
		var gear_rewards=0
		var iron_rewards=0
		var relic_rewards=0
		for coord in game.rooms:
			var data=game.rooms[coord]
			var bounds: Rect2i=data.bounds
			sizes[bounds.size]=true
			layouts[data.layout]=true
			var reachable=flood(data)
			for p in data.entities:
				check(reachable.has(p),"Unreachable entity seed %d at %s/%s"%[seed_value,coord,p])
				check(not data.walls.has(p) or data.entities[p].kind=="crack","Entity embedded in wall")
				if data.entities[p].kind=="upgrade": blessings+=1
				if data.entities[p].kind=="chest":gear_rewards+=1
				if data.entities[p].kind=="iron":iron_rewards+=1
				if data.entities[p].kind=="relic": relic_rewards+=1
			for dir in game.links[coord]:
				var delta=dir-coord
				var landing=Vector2i(bounds.position.x+1,5) if delta==Vector2i.LEFT else (Vector2i(bounds.end.x-2,5) if delta==Vector2i.RIGHT else (Vector2i(6,bounds.position.y+1) if delta==Vector2i.UP else Vector2i(6,bounds.end.y-2)))
				check(reachable.has(landing),"Door reachable")
				check(not data.entities.has(landing),"Door landing must be empty")
			if data.gate.x>=0:
				guarded_count+=1
				if (data.horizontal_gate and coord+Vector2i.UP in game.links[coord]) or (not data.horizontal_gate and coord+Vector2i.RIGHT in game.links[coord]): blockers+=1
				check(data.entities.has(data.gate) and data.entities[data.gate].get("gatekeeper",false),"Gate sentinel exists")
				var blocked=flood(data,true)
				var far_exit=Vector2i(6,bounds.position.y+1) if data.horizontal_gate else Vector2i(bounds.end.x-2,5)
				check(not blocked.has(far_exit),"Cannot walk around passage guard")
				check(reachable.has(far_exit),"Defeating guard opens passage")
		check(blockers>=1,"At least one guarded connected exit per dungeon")
		check(blessings==0 and gear_rewards==8 and iron_rewards==3,"Eight chests and three iron including the forge deposit")
		check(relic_rewards==0,"Relics removed from rooms")
		# Travel through every open graph edge in both directions with real bounds.
		for coord in game.links:
			for next in game.links[coord]:
				game.room=coord
				game.boots=true
				var b: Rect2i=game.rooms[coord].bounds
				var d=next-coord
				game.pos=Vector2i(b.position.x+1,5) if d==Vector2i.LEFT else (Vector2i(b.end.x-2,5) if d==Vector2i.RIGHT else (Vector2i(6,b.position.y+1) if d==Vector2i.UP else Vector2i(6,b.end.y-2)))
				game.move_player(d)
				check(game.room==next,"Variable-size room transition")
				check(game.rooms[next].bounds.grow(-1).has_point(game.pos) and not game.rooms[next].walls.has(game.pos),"Safe arrival tile")
	check(sizes.size()==9 and layouts.size()==6,"Nine footprints and six layouts")
	check(guarded_count>300,"Guarded passages frequently generated")
	game.new_run(2);preload("res://tools/test_equipment.gd").arm(game)
	for repeat in range(100):
		game.offer_blessing()
		check(game.blessings.size()==3,"Three choices")
		var build_count=0
		for id in game.blessings:
			if id not in ["attack","guard"]: build_count+=1
		check(build_count==2,"Each blessing offers two build options")
	var before=game.attack
	game.apply_blessing("attack")
	check(game.attack==before+5,"Larger attack blessing")
	var old_armor=game.armor
	game.apply_blessing("guard")
	check(game.armor==old_armor+3 and game.speed==1.15,"Larger guard blessing")
	game.apply_blessing("focus")
	game.apply_blessing("ferocity")
	check(is_equal_approx(game.crit_chance,0.25) and game.crit_mult==2.0,"Larger critical upgrades")
	for id in ["cinder","frost","solvent","venom","precision","ruin"]:
		game.new_run(10);preload("res://tools/test_equipment.gd").arm(game)
		game.choices=[id]
		game.mode="relic"
		game.action("relic0")
		check(id in game.relics and game.mode=="play","Build relic selection")
		if id in ["cinder","frost","solvent","venom"]:
			check(game.elements[{"cinder":"fire","frost":"ice","solvent":"acid","venom":"poison"}[id]]==1,"Element relic grants rank")
		elif id=="precision":check(is_equal_approx(game.crit_chance,0.25),"Precision relic crit chance")
		elif id=="ruin":check(game.crit_mult==2.0,"Ruin relic crit damage")
	var enemy={"kind":"enemy","name":"Dummy","type":0,"hp":500,"max":500,"attack":10,"armor":20,"speed":1.0,"trait":"none","elite":false,"roll_seed":1}
	var cinder=Combat.begin(enemy,100,100,10,0,1,["cinder"],{"fire":1})
	Combat.step(cinder)
	check(cinder.fire_until==5.0,"Cinder extends burn")
	var venom=Combat.begin(enemy,100,100,10,0,1,["venom"],{"poison":1})
	check(venom.poisoned,"Venom applies before opener")
	var solvent=Combat.begin(enemy,100,100,10,0,1,["solvent"],{"acid":1})
	Combat.step(solvent)
	check(solvent.acid_stacks==3,"Solvent increases armor stripping")
	var frost=Combat.begin(enemy,100,100,10,0,1,["frost"],{"ice":1})
	var first=Combat.step(frost).damage
	frost.e_time=100.0
	check(Combat.step(frost).damage>first,"Frost increases damage on chilled foes")
	var weak=game.make_enemy(0,0)
	check(weak.hp>15 and weak.attack>6 and weak.speed>0.8,"Enemies stronger than previous version")
	# Prepared in-run builds still have viable boss fights without permanent upgrades.
	var viable=0
	var sample=0
	for build in [["ice","ice","ice","attack"],["poison","poison","poison","attack"],["fire","fire","ice","guard"],["attack","attack","focus","ferocity"]]:
		game.new_run(22);preload("res://tools/test_equipment.gd").arm(game)
		for id in build:game.apply_blessing(id)
		game.character_level=4
		for slot in game.Gear.SLOTS:
			game.inventory.append(game.Gear.make(slot,2,0))
			game.equipped[slot]=game.inventory.size()-1
		game.recalculate_stats()
		game.hp=game.max_hp
		for id in [["frost","ward"],["venom","ward"],["cinder","frost"],["precision","ruin"]][sample]:
			game.choices=[id]
			game.mode="relic"
			game.action("relic0")
		sample+=1
		var warden=game.make_enemy(3,4)
		warden.hp-=20 # A fully prepared run reserves one bomb for the boss.
		if game.forecast(warden).won:viable+=1
	check(viable>=2,"Several prepared gear/level builds can defeat the stronger Warden")
	game.queue_free()
	if failures.is_empty():print("PASS: %d rebalance checks; 300 seeds, variable doors, guarded passages, sparse rewards and build relics. Viable sample builds: %d/4."%[checks,viable])
	else:
		for failure in failures:push_error(failure)
	quit(0 if failures.is_empty() else 1)
