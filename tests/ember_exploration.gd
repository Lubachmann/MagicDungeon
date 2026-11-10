extends SceneTree
var game
var checks=0
var failures: Array[String]=[]
const PATH="res://tests/.ember-save.json"
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok and failures.size()<25:failures.append(message)
func cleanup() -> void:
	for suffix in ["",".tmp",".run",".run.bak",".run.tmp",".settings",".settings.bak",".settings.tmp"]:
		if FileAccess.file_exists(PATH+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH+suffix))
func make_game():
	var node=load("res://main.gd").new();node.save_path=PATH;root.add_child(node);preload("res://tools/historical_run.gd").start(node,1,6);node.set_process(false);node.muted=true
	return node
func locate(kind: String) -> Array:
	for coord in game.rooms:
		for tile in game.rooms[coord].entities:
			if game.rooms[coord].entities[tile].kind==kind:return [coord,tile]
	return []
func _initialize():call_deferred("run")
func run() -> void:
	cleanup();game=make_game()
	check(game.icons.speed.get_width()==16,"Attack timing has a genuine 16px icon")
	check(game.hp==48 and game.attack==9 and game.armor==1 and game.crit_chance==0.05,"Unarmed starting baseline")
	check(game.loadout=="wanderer" and game.inventory.is_empty() and game.equipped.is_empty() and game.elements=={"fire":0,"ice":0,"acid":0,"poison":0},"No starting equipment, class or forced element")
	game.session.enabled=true;game.session.preferences.tutorial_done=true;game.bank=50000;game.mode="skills"
	check(not game.ember_tree.buy("runeforge") and game.bank==50000,"Cannot skip prerequisites")
	check(game.ember_tree.buy("kindling") and game.bank==49992,"First upgrade affordable after an early run")
	check(not game.ember_tree.buy("kindling") and game.bank==49992,"No double purchase above cap")
	for id in ["vigor","vigor","vigor","flaskcraft","flask_reserve","second_wind","cartography","runic_sight","recall","might","tinkering","relic_lens","runeforge"]:check(game.ember_tree.buy(id),"Purchase branch "+id)
	var spent=game.ember_tree.spent()
	check(game.bank==50000-spent and game.ember_tree.rank("runeforge",false)==1,"Only banked embers pay for tree")
	check(classic_start(),"Start with snapshotted skills")
	check(game.hp==64 and game.revives_left==1 and game.recall_charges==1 and game.rerolls_left==1,"Skills add survival and options")
	var loaded=make_game();loaded.session.enabled=true;loaded.session.boot()
	check(loaded.skills==game.ember_tree.clean(game.skills) and loaded.bank==game.bank,"Permanent tree survives restart")
	loaded.queue_free()
	# Respec cannot change skills or mint currency inside the saved active run.
	game.session.title();game.action("skills");check(game.ember_tree.reset() and game.bank==50000,"Free full refund preserves autonomy")
	check(game.session.continue_run() and game.max_hp==64 and game.run_skills.get("runeforge",0)==1 and game.skills.get("runeforge",0)==0 and game.bank==50000,"Continue preserves run skills while profile is respecced")
	# Restoring a run must not resurrect spent rerolls, keys or reward rolls.
	game.gain_xp(40);game.resume_play();var old_choices=game.choices.duplicate()
	game.action("relic_reroll");var choices=game.choices.duplicate();var rng_state=game.rng.state
	check(game.rerolls_left==0 and game.mode=="relic" and choices!=old_choices,"Reroll gives alternatives without class bias")
	game.session.continue_run();check(game.choices==choices and game.rerolls_left==0 and game.rng.state==rng_state,"Rerolled choices and charge are durable")
	game.action("relic_reroll");check(game.choices==choices and game.rng.state==rng_state,"Cannot reroll after charge spent")
	game.mode="play";game.recall_charges=1
	game.room=game.boss_room;game.pos=Vector2i(7,5)
	game.dungeon_threads.recall()
	check(game.room==Vector2i.ZERO and game.pos==Vector2i(2,5) and game.recall_charges==0,"Recall returns safely and spends one charge")
	game.room=game.boss_room;game.dungeon_threads.recall()
	check(game.room==game.boss_room,"Spent Recall cannot be reused")
	game.hp=1;game.potions=1;game.action("heal")
	check(game.hp==34 and game.potions==0,"Flaskcraft increases healing to 33")
	var forge_for_iron=locate("salvage");game.room=forge_for_iron[0];game.pos=Vector2i(6,5);game.iron=0
	for x in [7,8]:
		game.mode="play";game.rooms[game.room].walls.erase(Vector2i(x,5));game.rooms[game.room].entities[Vector2i(x,5)]={"kind":"iron"};game.move_player(Vector2i.RIGHT)
	check(game.iron==3 and game.iron_bonus_claimed,"Tinkering adds exactly one iron per floor")
	preload("res://tools/test_equipment.gd").arm(game)
	# Infusion chooses a build and recomputes at the new item level.
	game.mode="play"
	var forge=locate("salvage");game.room=forge[0];game.pos=forge[1];game.selected_item=0;game.iron=2;game.shards=10
	game.open_equipment();game.action("infuse_open");game.action("infuse:fire")
	check(game.inventory[0].infusion=="fire" and game.iron==1 and game.shards==6 and game.Gear.stats(game.inventory[0]).fire_dps==1,"Chosen infusion pays exact cost")
	game.action("iron_selected");check(game.inventory[0].level==2 and game.Gear.stats(game.inventory[0]).fire_dps==1.5,"Iron scales an existing infusion")
	game.session.continue_run();check(game.Gear.stats(game.inventory[0]).fire_dps==1.5,"Infusion survives save and restore")
	game.iron=0;game.mode="equipment";game.action("infuse_open");check(game.mode=="equipment","Cannot infuse without resources")
	# Deterministic spatial dependency checks over 500 actual new-rule floors.
	game.session.enabled=false
	for seed_value in range(100):
		classic_run(seed_value)
		for floor_index in range(1,6):
			var keys=0;var sun=0;var moon=0;var vaults=0
			for coord in game.rooms:
				var data=game.rooms[coord];var reachable=game.dungeon_threads.reachable(data)
				for tile in data.entities:
					var entity=data.entities[tile]
					if entity.kind=="dungeon_key":
						keys+=1;check(reachable.has(tile),"Key accessible without opening any chest or paid vault")
						check(game.dungeon_threads.distances_from(coord)[game.floor_flags.lock_room]>=2,"Key is meaningfully far from its early lock")
					if entity.kind=="brazier":
						if entity.rune=="sun":sun+=1
						else:moon+=1
						check(reachable.has(tile),"Seal switch accessible without its own reward")
					if entity.kind=="reliquary":vaults+=1;check(entity.rewards.size()==3 and not entity.used,"Optional vault has three fixed rewards")
					if entity.kind in ["dungeon_key","brazier","reliquary"]:check(tile.x!=6 and tile.y!=5,"Optional locks and markers avoid mandatory cross")
			check(keys==1 and sun==1 and moon==1 and vaults==1,"One complete set of solvable optional dependencies per floor")
			check(game.dungeon_threads.distances_from(Vector2i.ZERO).has(game.boss_room),"Boss graph never requires permanent skills")
			if floor_index<5:game.mode="floor";game.ascend_floor()
	# Real key pickup and consumption; save after pickup cannot duplicate loot.
	classic_run(31)
	var locked=game.floor_flags.lock_room;var locked_tile=game.rooms[locked].chest
	game.room=locked;check(not game.open_chest(locked_tile),"Copper chest stays locked before key")
	var key=locate("dungeon_key");game.room=key[0];game.dungeon_threads.touch(key[1],game.rooms[key[0]].entities[key[1]])
	check(game.floor_keys.has("copper"),"Pickup grants floor key")
	game.room=locked;game.breaker=true;game.boots=true
	var guardian=game.rooms[locked].entities[locked_tile].guardian
	game.rooms[locked].entities.erase(guardian)
	check(game.open_chest(locked_tile) and not game.floor_keys.has("copper"),"Opening consumes key exactly once")
	check(not game.open_chest(locked_tile),"Locked reward cannot pay twice")
	# Paired seal checks order, not player stats; errors do no damage.
	game.mode="play";var health=game.hp
	game.dungeon_threads.touch(game.pos,{"kind":"brazier","rune":"moon"})
	check(not game.floor_flags.moon and game.hp==health,"Moon before Sun fails safely")
	game.dungeon_threads.touch(game.pos,{"kind":"brazier","rune":"sun"});game.dungeon_threads.touch(game.pos,{"kind":"brazier","rune":"moon"})
	check(game.floor_flags.sun and game.floor_flags.moon,"Correct seal sequence opens treasure")
	# Paid gate cannot be bypassed; glyph progress and rewards stay fixed on reload.
	game.session.enabled=true;game.skills={"kindling":1,"cartography":1,"runic_sight":1};game.session.active=false;classic_start()
	var vault=locate("reliquary");game.room=vault[0]
	var entity=game.rooms[vault[0]].entities[vault[1]]
	game.run_skills={};game.dungeon_threads.touch(vault[1],entity)
	check(game.mode=="play","Reliquary needs the skill in this run")
	game.run_skills=game.skills.duplicate();game.dungeon_threads.touch(vault[1],entity)
	var fixed_rewards=entity.rewards.duplicate(true);var order=entity.order.duplicate()
	game.action("rune:"+order[1]);check(entity.progress==0,"Wrong glyph resets puzzle")
	game.action("rune:"+order[0]);game.session.continue_run()
	entity=game.rooms[game.room].entities[game.puzzle_tile]
	check(entity.progress==1 and entity.rewards==fixed_rewards,"Partial puzzle and pre-rolled treasures restore")
	game.action("rune:"+order[1]);game.action("rune:"+order[2]);check(game.mode=="vault_reward","Riddle solved")
	var item_count=game.inventory.size();game.action("vault_pick:1")
	check(game.inventory.size()==item_count+1 and game.inventory.back()==fixed_rewards[1],"Player chooses a fixed treasure")
	game.session.continue_run();game.mode="vault_reward";game.action("vault_pick:0")
	check(game.inventory.size()==item_count+1,"Cannot claim another vault reward after reload")
	# Second Wind uses the exact same mechanics in forecasts and live combat.
	game.skills={"kindling":1,"vigor":3,"flaskcraft":1,"second_wind":1};classic_start();game.hp=1
	var enemy=game.make_enemy(0,0);enemy.hp=200;enemy.max=200;enemy.speed=2;enemy.roll_seed=2147483646
	game.rooms[game.room].entities[Vector2i(3,5)]=enemy;game.move_player(Vector2i.RIGHT)
	game._process(0.33)
	check(game.mode=="fight" and game.revives_left==0 and game.hp>0,"Fatal strike uses exactly one Second Wind")
	var expected=game.forecast(game.fight);game.session.pause();game.session.title();game.session.continue_run()
	check(game.revives_left==0 and game.battle.revives==0,"Reload cannot replenish a used revival")
	for i in range(3000):
		if game.mode!="fight":break
		game._process(0.03)
	check(game.hp==expected.hp and game.battle.won==expected.won,"Forecast and resumed combat agree after revival")
	# Legacy stat investments are refunded once; an active legacy run keeps its balance.
	var state=game.session.snapshot();state.state.mode="play";state.state.hp=40;state.state.bank=10;state.state.levels=[2,1,0]
	for id in ["skills","run_skills","meta_revision","run_rules","legacy_levels","floor_keys","floor_flags","recall_charges","rerolls_left","revives_left","iron_bonus_claimed","puzzle_tile"]:state.state.erase(id)
	check(game.session.valid(state) and state.state.bank==40 and state.state.run_rules==2 and state.state.legacy_levels==[2,1,0],"Legacy investment refund and grandfathered run")
	game.session.valid(state);check(state.state.bank==40,"Migration is idempotent")
	game.queue_free();await process_frame;cleanup()
	if failures.is_empty():print("PASS: %d ember/exploration checks; 500 generated floors, tree transactions, migration, keys, seals, rune rewards, infusions and revival forecasts."%checks)
	else:
		for failure in failures:push_error(failure)
	quit(0 if failures.is_empty() else 1)

func resolve_tick(delta: float) -> void:
	if game.mode=="fight" and game.battle.get("waiting",false):game.action("fight_continue")
	game._process(delta)

func classic_run(seed_value: int) -> void:
	preload("res://tools/historical_run.gd").start(game,seed_value,6);preload("res://tools/test_equipment.gd").arm(game)
	game.run_rules=3
	game.recalculate_stats();game.hp=game.max_hp
	game.generate_floor()

func classic_start() -> bool:
	var result=game.session.start_run()
	game.inventory.clear();game.equipped.clear()
	game.run_rules=3
	game.recalculate_stats();game.hp=game.max_hp
	game.generate_floor()
	game.session.checkpoint()
	return result
