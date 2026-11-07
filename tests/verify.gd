extends SceneTree
const Combat = preload("res://combat.gd")
var game
var checks = 0
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		if failures.size() < 20: failures.append(message)

func _initialize() -> void:
	call_deferred("run")

func walk(data: Dictionary, hammer: bool, boots: bool, block_elite: bool = false) -> Dictionary:
	var seen = {Vector2i(6, 5): true}
	var todo = [Vector2i(6, 5)]
	while not todo.is_empty():
		var p = todo.pop_front()
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n = p + d
			if not data.bounds.grow(-1).has_point(n) or seen.has(n): continue
			var kind = data.entities.get(n, {}).get("kind", "")
			if data.walls.has(n) and not (hammer and kind == "crack"): continue
			if kind == "water" and not boots: continue
			if block_elite and data.entities.get(n, {}).get("gatekeeper", false): continue
			seen[n] = true
			todo.append(n)
	return seen

func run() -> void:
	game = load("res://main.gd").new()
	game.save_path = "res://tests/.test-progress.json"
	root.add_child(game);preload("res://tools/test_equipment.gd").arm(game)
	game.set_process(false)
	game.muted = true
	var signatures: Dictionary = {}
	for seed_value in range(200):
		game.new_run(seed_value);preload("res://tools/test_equipment.gd").arm(game)
		check(game.rooms.size() == 8, "Eight rooms")
		var seen = {Vector2i.ZERO: true}
		var todo = [Vector2i.ZERO]
		var signature = ""
		while not todo.is_empty():
			var current = todo.pop_front()
			for next in game.links[current]:
				check(current in game.links[next], "Symmetric graph")
				if game.is_water_link(current, next): continue
				if not seen.has(next): seen[next] = true; todo.append(next)
		check(seen.size() == 8, "All roles reachable without abilities")
		for coord in game.links: signature += str(coord) + str(game.links[coord])
		signatures[signature] = true
		check(game.water_shortcuts.size() == 1, "Boots shortcut exists")
		check(game.hammer_room != game.boots_room and game.boss_room != game.boots_room, "Distinct ability locations")
		for coord in game.rooms:
			var data = game.rooms[coord]
			var open = walk(data, true, true)
			for door in [Vector2i(data.bounds.position.x+1,5),Vector2i(data.bounds.end.x-2,5),Vector2i(6,data.bounds.position.y+1),Vector2i(6,data.bounds.end.y-2)]:
				check(open.has(door), "Room exits reachable")
			for p in data.entities: check(open.has(p), "Reachable %s at %s seed %d" % [data.entities[p].kind, p, seed_value])
			check(data.cache.x < 0 or not walk(data, false, true).has(data.cache), "Hammer gates treasure")
			check(data.water_cache.x < 0 or not walk(data, true, false).has(data.water_cache), "Boots gate water treasure")
			if game.roles[coord] == "Elite": check(not walk(data, true, true, true).has(data.chest), "Elite guards chest")
		check(walk(game.rooms[game.hammer_room], false, false).has(game.rooms[game.hammer_room].special), "Hammer accessible")
		check(walk(game.rooms[game.boots_room], false, false).has(game.rooms[game.boots_room].special), "Boots accessible")
	check(signatures.size() > 20, "Graph varies across runs")
	# All 64 relic combinations, all enemies, multiple builds, shields and heals.
	for mask in range(64):
		var relics: Array = []
		var ids = game.RELICS.keys()
		for i in range(6):
			if mask & (1 << i): relics.append(ids[i])
		for type in range(4):
			for build in range(3):
				game.new_run(5);preload("res://tools/test_equipment.gd").arm(game)
				game.hp = 45
				game.max_hp = 80
				game.attack = 10 + build * 3
				game.armor = 2 + build * 5
				game.speed = 1.0 + build * 0.1 + (0.25 if relics.has("haste") else 0.0)
				game.relics = relics.duplicate()
				var enemy = game.make_enemy(type, 3)
				var expected = game.forecast(enemy)
				game.rooms[game.room].entities[Vector2i(3, 5)] = enemy
				game.move_player(Vector2i.RIGHT)
				for tick in range(2000):
					if game.mode != "fight": break
					resolve_tick(0.05)
				check(game.hp == expected.hp and (game.mode in ["play","relic"]) == expected.won, "Forecast/live mismatch mask %d type %d build %d" % [mask, type, build])
				check(game.battle.done, "Combat finishes")
	# Explicit expected effects, independent of forecast/live equivalence.
	var shield = Combat.begin(game.make_enemy(1, 0), 50, 80, 10, 2, 1.0, [])
	check(Combat.step(shield).damage == 0, "Shield blocks first strike")
	check(Combat.step(shield).damage > 0, "Shield breaks after first strike")
	var normal = Combat.begin(game.make_enemy(0, 0), 50, 80, 10, 6, 1.0, [])
	var spark = Combat.begin(game.make_enemy(0, 0), 50, 80, 10, 6, 1.0, ["spark"])
	check(Combat.step(spark).damage > Combat.step(normal).damage, "Spark strengthens opener")
	var bloom = Combat.begin(game.make_enemy(0, 0), 50, 80, 100, 6, 1.0, ["bloom"])
	Combat.step(bloom)
	check(bloom.won and bloom.hp == 54, "Bloom heals on victory")
	var armored_target = game.make_enemy(0, 0)
	armored_target.armor=20
	var needle = Combat.begin(armored_target, 50, 80, 10, 6, 1.0, ["needle"])
	var plain = Combat.begin(armored_target, 50, 80, 10, 6, 1.0, [])
	check(Combat.step(needle).damage > Combat.step(plain).damage, "Needle pierces armor")
	var ward = Combat.begin(game.make_enemy(0, 0), 50, 80, 1, 6, 1.0, ["ward"])
	ward.p_time = 100.0
	check(Combat.step(ward).damage == ceili(Combat.damage(9, 6) * 0.5), "Ward halves first enemy hit")
	var leech = Combat.begin(game.make_enemy(3, 0), 50, 80, 1, 6, 1.0, ["leech"])
	leech.e_time = 100.0
	Combat.step(leech)
	Combat.step(leech)
	check(Combat.step(leech).heal == 2 and leech.hp == 52, "Leech heals on third strike")
	var heavy = Combat.begin(game.make_enemy(3, 0), 80, 80, 1, 2, 1.0, [])
	heavy.enemy.trait = "heavy"
	heavy.p_time = 100.0
	var first = Combat.step(heavy).damage
	Combat.step(heavy)
	check(Combat.step(heavy).damage > first, "Heavy third hit")
	var pierce = Combat.begin(game.make_enemy(2, 0), 80, 80, 1, 10, 1.0, [])
	pierce.p_time = 100.0
	check(Combat.step(pierce).damage == Combat.damage(8, 5), "Enemy piercing halves armor")
	for power in range(1, 30):
		var last = power
		for defense in range(100):
			var damage = Combat.damage(power, defense)
			check(damage <= last and damage >= 1, "Armor diminishing returns and minimum damage")
			last = damage
	game.new_run(42);preload("res://tools/test_equipment.gd").arm(game)
	game.room = game.boots_room
	game.pos = game.rooms[game.room].special + Vector2i.DOWN
	game.move_player(Vector2i.UP)
	check(game.boots, "Boots pickup")
	var water_data=game.rooms[game.room]
	var water_entry: Vector2i=water_data.chest_path[1]
	var water_approach: Vector2i=water_data.chest_path[2]
	game.pos=water_approach
	game.boots=false
	game.move_player(water_entry-water_approach)
	check(game.pos==water_approach,"Pool blocks without boots")
	game.boots=true
	game.move_player(water_entry-water_approach)
	check(game.pos==water_entry and water_data.entities[water_entry].kind=="water","Pool remains water")
	game.room=game.hammer_room
	game.pos=game.rooms[game.room].special+Vector2i.DOWN
	game.move_player(Vector2i.UP)
	check(game.breaker,"Hammer pickup")
	var wall_data=game.rooms[game.room]
	var wall_entry: Vector2i=wall_data.chest_path[1]
	var wall_approach: Vector2i=wall_data.chest_path[2]
	game.pos=wall_approach
	game.move_player(wall_entry-wall_approach)
	check(not wall_data.walls.has(wall_entry),"Hammer opens wall")
	# Flooded connection is optional and genuinely ability-gated.
	var edge = game.water_shortcuts[0]
	game.room = edge[0]
	var direction = edge[1] - edge[0]
	var bounds: Rect2i = game.rooms[game.room].bounds
	var threshold = Vector2i(bounds.end.x-2,5) if direction==Vector2i.RIGHT else (Vector2i(bounds.position.x+1,5) if direction==Vector2i.LEFT else (Vector2i(6,bounds.position.y+1) if direction==Vector2i.UP else Vector2i(6,bounds.end.y-2)))
	game.pos = threshold
	game.boots = false
	game.move_player(direction)
	check(game.room == edge[0], "Flooded link blocked")
	game.boots = true
	game.move_player(direction)
	check(game.room == edge[1], "Boots unlock shortcut")
	for coord in game.roles:
		if game.roles[coord] == "Forge":
			game.room=coord
			game.mode="play"
			game.pos=game.rooms[coord].special+Vector2i.DOWN
			game.move_player(Vector2i.UP)
			check(game.iron==0 and game.mode=="play" and game.near_forge(),"Forge is passable and usable nearby")
			game.action("equipment")
			check(game.mode=="equipment", "Equipment opens on request near the forge")
			game.action("close_equipment")
		if game.roles[coord] == "Fountain":
			game.room=coord
			game.mode="play"
			game.pos=game.rooms[coord].special+Vector2i.DOWN
			game.hp=20
			game.move_player(Vector2i.UP)
			check(game.hp==mini(50,game.max_hp),"Fountain single use")
	game.relics = game.RELICS.keys()
	game.offer_relic()
	check(game.mode == "play", "Relic exhaustion fallback")
	game.bank = 23
	game.skills={"kindling":1}
	game.save_progress()
	game.bank = 0
	game.levels = [0, 0, 0]
	game.load_progress()
	check(game.bank == 23 and game.levels == [0,0,0] and game.skills.kindling==1, "Save reload")
	# Original version save remains compatible.
	var file = FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string('{"bank": 40, "levels": [2, 5, 5]}')
	file.close()
	game.load_progress()
	game.new_run(12);preload("res://tools/test_equipment.gd").arm(game)
	check(game.bank == 262 and game.max_hp == 48 and game.attack == 14 and game.armor == 1, "Old stat investments refunded into the new tree")
	game.shards = 9
	game.finish_run(false)
	game.finish_run(false)
	check(game.bank == 271, "Death banks only once")
	game.action("restart")
	check(game.relics.is_empty() and not game.boots and not game.breaker, "Run powers reset")
	game.room = game.boss_room
	game.pos = Vector2i(7, 3)
	game.move_player(Vector2i.UP)
	check(game.mode == "play", "Exit locked before Warden")
	game.floor_number=game.FLOOR_COUNT
	game.rooms[game.room].cleared = true
	game.move_player(Vector2i.UP)
	check(game.mode == "won", "Beacon victory")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	game.queue_free()
	if failures.is_empty(): print("PASS: %d checks; 200 dungeon seeds; 768 combat builds; traversal, relics, balance, save migration and victory." % checks)
	else:
		for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)

func resolve_tick(delta: float) -> void:
	if game.mode=="fight" and game.battle.get("waiting",false):game.action("fight_continue")
	game._process(delta)
