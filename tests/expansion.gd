extends SceneTree
const Combat = preload("res://combat.gd")
var checks = 0
var failures: Array[String] = []
var game
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok and failures.size() < 20: failures.append(message)
func _initialize() -> void: call_deferred("run")
func dummy() -> Dictionary:
	return {"kind":"enemy", "type":0, "name":"Dummy", "hp":100, "max":100, "attack":10, "armor":0, "speed":1.0, "trait":"none", "elite":false, "roll_seed":1}
func accessible(data: Dictionary, hammer: bool, guard_blocked: bool) -> Dictionary:
	var todo = [Vector2i(6,5)]
	var seen = {Vector2i(6,5):true}
	while not todo.is_empty():
		var current = todo.pop_front()
		for direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var p = current + direction
			if p.x < 1 or p.x > 11 or p.y < 1 or p.y > 9 or seen.has(p): continue
			if data.entities.get(p,{}).get("kind","") in ["chest","exit"]:continue
			if data.walls.has(p) and not (hammer and data.entities.get(p,{}).get("kind","") == "crack"): continue
			if guard_blocked and p == Vector2i(9,3): continue
			seen[p] = true
			todo.append(p)
	return seen
func run() -> void:
	game = load("res://main.gd").new()
	game.save_path = "res://tests/.expansion-save.json"
	root.add_child(game);preload("res://tools/test_equipment.gd").arm(game)
	game.set_process(false)
	game.muted = true
	var layouts: Dictionary = {}
	for seed_value in range(200):
		game.new_run(seed_value);preload("res://tools/test_equipment.gd").arm(game)
		var data = game.rooms[game.boss_room]
		check(not accessible(data,false,true).has(Vector2i(6,3)), "Vault sealed without ability or champion fight")
		check(accessible(data,true,true).has(Vector2i(6,3)), "Hammer route reaches Warden")
		check(accessible(data,false,false).has(Vector2i(6,3)), "Combat route reaches Warden without Hammer")
		check(data.entities[Vector2i(9,3)].elite, "Champion guards combat entrance")
		for coord in game.rooms: layouts[game.rooms[coord].layout] = true
	check(layouts.size() == 6, "Six authored layouts generated")
	game.skills={"kindling":1,"vigor":3}
	# All elemental rank combinations, every enemy, multiple crit configurations.
	for ranks in range(256):
		for type in range(4):
			game.new_run(50 + ranks);preload("res://tools/test_equipment.gd").arm(game)
			game.elements = {"fire":ranks % 4, "ice":(ranks / 4) % 4, "acid":(ranks / 16) % 4, "poison":(ranks / 64) % 4}
			for id in game.elements: game.elements[id] = int(game.elements[id])
			game.crit_chance = (ranks % 7) * 0.1
			game.crit_mult = 1.5 + (ranks % 7) * 0.25
			game.hp = game.max_hp
			game.relics = ["bloom", "leech"] if ranks % 2 == 0 else ["spark", "needle"]
			var enemy = game.make_enemy(type, 3)
			var before = enemy.duplicate(true)
			var expected = game.forecast(enemy)
			check(enemy == before and game.forecast(enemy) == expected, "Forecast is stable and read-only")
			game.rooms[game.room].entities[Vector2i(3,5)] = enemy
			game.move_player(Vector2i.RIGHT)
			for tick in range(2000):
				if game.mode != "fight": break
				resolve_tick(0.05)
			check(game.battle.done and game.hp == expected.hp and (game.mode in ["play","relic"]) == expected.won, "Element/crit forecast equals live result")
	# Explicit mechanical expectations.
	var enemy = dummy()
	enemy.hp = 3
	var fire = Combat.begin(enemy,50,80,1,0,0.1,[],{"fire":1})
	Combat.step(fire)
	var burn = Combat.step(fire) # Enemy and burn tie at 1; enemy strikes first.
	if not burn.burn: burn = Combat.step(fire)
	check(burn.burn and fire.won and burn.damage == 4, "Burn ticks independently and can kill")
	var ice = Combat.begin(dummy(),50,80,1,0,1,[],{"ice":3})
	Combat.step(ice)
	check(is_equal_approx(ice.e_time,1.0/0.46), "Ice rescales pending enemy interval")
	var acid_enemy = dummy()
	acid_enemy.armor = 12
	var acid = Combat.begin(acid_enemy,500,500,12,0,1,[],{"acid":3})
	var first_damage = Combat.step(acid).damage
	acid.e_time = 100.0
	var next_damage = Combat.step(acid).damage
	for i in range(8):
		if not acid.done: Combat.step(acid)
	check(next_damage > first_damage and acid.acid_stacks == 12, "Acid strips armor with rank cap")
	var poison = Combat.begin(dummy(),50,80,1,0,1,[],{"poison":3})
	Combat.step(poison)
	poison.p_time = 100.0
	check(Combat.step(poison).damage == 5, "Poison reduces power by 54%")
	var shield_enemy = dummy()
	shield_enemy.trait = "shield"
	var shield = Combat.begin(shield_enemy,50,80,10,0,1,[],{"fire":3,"ice":3,"acid":3,"poison":3})
	Combat.step(shield)
	check(shield.fire_time == INF and not shield.iced and not shield.poisoned and shield.acid_stacks == 0, "Blocked hits do not apply elements")
	var critical = Combat.begin(dummy(),50,80,10,0,1,[],{"crit_chance":0.6,"crit_mult":3})
	var crit = Combat.step(critical)
	check(crit.crit and crit.damage == 30, "Critical damage multiplies direct power")
	var boss = dummy()
	boss.type = 3
	boss.trait = "heavy"
	boss.hp = 55
	var phase = Combat.begin(boss,80,80,10,0,1,[])
	var phase_hit = Combat.step(phase)
	check(phase_hit.phase and phase.rage and is_equal_approx(phase.e_time,0.8), "Warden phase changes at half health")
	phase.p_time = 100.0
	check(Combat.step(phase).damage == 13, "Enrage increases damage by 25%")
	boss.hp = 40
	var pre_phase = Combat.begin(boss,80,80,10,0,1,[])
	check(pre_phase.rage, "Bomb-damaged boss begins enraged below half")
	# Blessing options, caps and run resets.
	game.new_run(15);preload("res://tools/test_equipment.gd").arm(game)
	for i in range(20):
		for id in ["fire","ice","acid","poison","focus","ferocity"]: game.apply_blessing(id)
	check(game.elements == {"fire":3,"ice":3,"acid":3,"poison":3} and game.crit_chance == 0.6 and game.crit_mult == 3.0, "Upgrade caps")
	game.offer_blessing()
	check(game.blessings.size() == 2 and "attack" in game.blessings and "guard" in game.blessings, "Capped upgrades excluded")
	game.new_run(10);preload("res://tools/test_equipment.gd").arm(game)
	game.offer_blessing()
	check(game.blessings.size() == 3, "Three distinct blessing choices")
	var selected = game.blessings[2]
	game.action("upgrade2")
	check(game.mode == "play", "Third upgrade selectable")
	# Bomb range, LOS, permanent enemy damage, forecast and kills.
	game.new_run(1);preload("res://tools/test_equipment.gd").arm(game)
	game.rooms[game.room].walls.clear()
	game.rooms[game.room].entities.clear()
	game.rooms[game.room].entities[Vector2i(5,5)] = dummy()
	game.mode = "bomb"
	game.bombs = 2
	check(game.valid_bomb_target(Vector2i(5,5)), "Bomb reaches three tiles")
	var preview_enemy = dummy()
	var prediction = game.forecast(preview_enemy)
	game.throw_bomb(Vector2i(5,5))
	check(game.bombs == 1 and game.rooms[game.room].entities[Vector2i(5,5)].hp == 80 and game.summary.bombs == 1, "Bomb consumes once and damages persistent enemy")
	check(game.forecast(game.rooms[game.room].entities[Vector2i(5,5)]) == prediction, "Bomb preview matches post-bomb combat")
	game.rooms[game.room].walls[Vector2i(4,5)] = true
	check(not game.valid_bomb_target(Vector2i(5,5)), "Walls block bombs")
	game.mode = "bomb"
	game.throw_bomb(Vector2i(5,5))
	check(game.bombs == 1, "Invalid throws are free")
	game.rooms[game.room].walls.clear()
	var weak = dummy()
	weak.hp = 10
	game.rooms[game.room].entities[Vector2i(5,5)] = weak
	game.throw_bomb(Vector2i(5,5))
	check(not game.rooms[game.room].entities.has(Vector2i(5,5)) and game.kills == 1 and game.summary.dealt == 30, "Bomb kill rewards and damage summary")
	game.new_run(2);preload("res://tools/test_equipment.gd").arm(game)
	check(game.elements.fire == 0 and game.crit_chance == 0.05 and game.crit_mult == 1.5 and game.bombs == 1 and game.summary.taken == 0, "Run powers and summary reset")
	game.queue_free()
	if FileAccess.file_exists("res://tests/.expansion-save.json"): DirAccess.remove_absolute(ProjectSettings.globalize_path("res://tests/.expansion-save.json"))
	if failures.is_empty(): print("PASS: %d expansion checks; 200 vault layouts; 1,024 elemental/crit fights." % checks)
	else:
		for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)

func resolve_tick(delta: float) -> void:
	if game.mode=="fight" and game.battle.get("waiting",false):game.action("fight_continue")
	game._process(delta)
