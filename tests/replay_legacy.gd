extends SceneTree
const Combat=preload("res://combat.gd")
var g
var checks=0
var failures=[]
const PATH="res://tests/.replay05.json"
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok and failures.size()<30:failures.append(message)
func cleanup() -> void:
	var dir=DirAccess.open("res://tests");dir.include_hidden=true
	for name in dir.get_files():
		if name.begins_with(".replay05.json"):dir.remove(name)
func make_game():
	var game=load("res://main.gd").new();game.save_path=PATH;root.add_child(game);preload("res://tools/test_equipment.gd").arm(game);game.set_process(false);game.muted=true;game.session.enabled=true;game.session.preferences.tutorial_done=true;game.session.boot();return game
func dummy(affix: String="") -> Dictionary:return {"kind":"enemy","name":"Target","type":1,"hp":100,"max":100,"attack":10,"armor":4,"speed":1.0,"trait":"none","elite":false,"affix":affix,"roll_seed":991}
func _initialize() -> void:call_deferred("run")
func run() -> void:
	cleanup();g=make_game()
	check(g.ember_tree.NODES.size()==33 and g.bank==0 and g.tree_spent==0,"New hero starts empty with expanded tree")
	var total=0;var ranks=0
	for node in g.ember_tree.NODES.values():
		for cost in node.costs:total+=cost;ranks+=1
	check(total>30000 and ranks>150,"Tree investment spans many runs, not one floor")
	g.mode="skills";g.bank=50000
	check(g.ember_tree.buy("kindling") and g.tree_spent==8 and g.bank==49992,"First purchase records exact payment")
	check(not g.ember_tree.buy("kindling") and g.tree_spent==8,"Max-rank purchase cannot charge twice")
	# Buy all nodes in dependency order, then compare ledger to exact curve total.
	var remaining=true;var attempts=0
	while remaining and attempts<10:
		remaining=false;attempts+=1
		for id in g.ember_tree.NODES:
			while g.ember_tree.price(id)>=0 and g.ember_tree.available(id):
				if not g.ember_tree.buy(id):break
			if g.ember_tree.price(id)>=0:remaining=true
	check(g.tree_spent==total and g.bank==50000-total,"Entire tree has exact cost and affordable parent paths")
	g.replay.reset_draft();g.new_run(22);preload("res://tools/test_equipment.gd").arm(g)
	check(g.max_hp==97 and is_equal_approx(g.attack,21.5) and is_equal_approx(g.armor,5.8),"Health, attack and armor ranks applied")
	check(is_equal_approx(g.speed,1.1) and is_equal_approx(g.crit_chance,0.10) and is_equal_approx(g.crit_mult,1.7),"Tempo and critical ranks applied")
	check(g.potions==4 and g.iron==3 and g.bombs==4 and g.rerolls_left==3,"Supply and utility nodes have real run effects")
	var expected=[[55,38,7],[0,80,20],[0,50,50]]
	for tier in range(3):check(is_equal_approx(g.replay.odds(tier)[0],float(expected[tier][0])) and is_equal_approx(g.replay.odds(tier)[1],float(expected[tier][1])) and is_equal_approx(g.replay.odds(tier)[2],float(expected[tier][2])),"Exact fortune probabilities tier %d"%tier)
	var counts=[0,0,0]
	for i in range(20000):counts[int(g.chest_item(0).rarity)]+=1
	for i in range(3):check(absf(float(counts[i])/20000.0-expected[0][i]/100.0)<0.015,"Observed chest distribution matches odds")
	g.offer_relic();check(g.choices.size()==4 and g.relic_pool().size()>=4,"Insight and Convergence expand actual offerings")
	var build={"fire":1,"ice":1,"acid":1,"poison":1,"tactics":true,"fire_mastery":0.5,"ice_mastery":0.5,"acid_mastery":0.5,"poison_mastery":0.5}
	var state=Combat.begin(dummy(),50,60,1,0,1,[],build);state.e_time=100
	check(Combat.fire_damage(state)==6 and is_equal_approx(Combat.ice_slow(state),0.27) and is_equal_approx(Combat.poison_weak(state),0.27),"Element masteries multiply owned elements")
	Combat.step(state);check(state.acid_stacks==3,"Acid mastery multiplies strip amount")
	state=Combat.begin(dummy(),50,60,1,0,1,[],{"fire_mastery":0.5,"ice_mastery":0.5});check(Combat.fire_damage(state)==0 and Combat.ice_slow(state)==0,"Mastery does not grant every element at spawn")
	# Exact reset, including imported old-price ownership.
	g.mode="skills";check(g.ember_tree.reset() and g.bank==50000 and g.tree_spent==0,"Full reset refunds actual investment")
	g.skills={"kindling":1,"vigor":3,"second_wind":1};g.tree_spent=g.ember_tree.old_spent(g.skills);var old_cost=g.tree_spent;var before=g.bank
	check(old_cost==64 and g.ember_tree.reset() and g.bank==before+64,"Old purchase ledger refunds old prices, not inflated prices")
	# Two independent characters retain bank/tree/career and Continue.
	g.bank=73;g.skills={"kindling":1};g.tree_spent=4;g.career.runs=7;g.save_progress();g.session.start_run();g.session.title()
	var original=FileAccess.get_file_as_bytes(PATH+".run");g.mode="profiles"
	check(g.profiles.create() and g.profiles.current==1 and g.bank==0 and g.skills.values().all(func(value):return int(value)==0) and g.career.runs==0,"New character has zero currency, tree and career")
	check(FileAccess.get_file_as_bytes(PATH+".run")==original,"Creating hero never overwrites original Continue")
	g.bank=20;g.mode="skills";g.ember_tree.buy("kindling");g.session.start_run();g.session.title();g.mode="profiles"
	check(g.profiles.select(0) and g.bank==73 and g.tree_spent==4 and g.career.runs==7 and g.session.has_run(),"Original character retains exact progress and Continue")
	g.mode="profiles";check(g.profiles.select(1) and g.bank==12 and g.tree_spent==8 and g.skills.kindling==1,"Second character retains own purchase")
	var reboot=make_game();check(reboot.profiles.current==1 and reboot.bank==12 and reboot.tree_spent==8,"Active character persists across app restart");reboot.queue_free()
	# Daily is identical regardless of investment; full clear unlocks optional modes.
	g.career.wins=1;g.skills={}
	for id in g.ember_tree.NODES:g.skills[id]=g.ember_tree.NODES[id].costs.size()
	g.replay.draft={"mode":"daily","vows":{"iron":3}};preload("res://tools/historical_run.gd").start_mode(g,3,"daily",6);preload("res://tools/test_equipment.gd").arm(g)
	check(g.max_hp==48 and g.attack==14 and g.armor==1 and g.iron==0 and g.potions==1 and g.run_skills.is_empty() and g.replay.threat()==0,"Daily strips all permanent advantages and Vows")
	var daily_rooms=g.rooms.duplicate(true);var daily_seed=g.run_seed;g.skills={};preload("res://tools/historical_run.gd").start_mode(g,999,"daily",6);preload("res://tools/test_equipment.gd").arm(g)
	check(g.run_seed==daily_seed and g.rooms==daily_rooms and g.run_seed==g.replay.daily_seed(),"Daily generation independent of profile, input seed and bank")
	check(g.replay.daily_seed("2026-11-02")!=g.replay.daily_seed("2026-11-03"),"Daily changes with UTC date")
	g.replay.draft={"mode":"endless","vows":{}};preload("res://tools/historical_run.gd").start_mode(g,44,"endless",6);preload("res://tools/test_equipment.gd").arm(g);g.floor_number=5;g.generate_floor();g.mode="floor";g.ascend_floor()
	check(g.floor_number==6 and g.floor_limit()==0 and g.session.valid(g.session.snapshot()),"Endless ascends beyond five and saves")
	for floor_index in [10,15,25]:g.floor_number=floor_index;g.generate_floor();check(g.rooms.size()==8 and g.session.valid(g.session.snapshot()),"Deep floor generates and validates")
	g.replay.draft={"mode":"standard","vows":{"iron":3,"fury":3,"ambush":1,"hexed":1,"restless":1,"famine":1}};g.new_run(8);preload("res://tools/test_equipment.gd").arm(g)
	check(g.replay.threat()==10 and g.replay.bank_reward(100)==180,"Threat and reward multiplier exact")
	var boss=g.make_enemy(3,4);check(boss.armor==16 and boss.attack==15 and boss.ambush and boss.hexed and boss.mending,"Vows modify actual enemy behavior and stats")
	state=Combat.begin(boss,100,100,1,0,1,[],{"tactics":true});check(Combat.special_for_hit(state,1),"Ambush prepares opening attack")
	# Every new affix and element synergy uses the same deterministic forecast engine.
	for affix in g.replay.AFFIXES:
		var e=dummy(affix)
		if affix=="regenerator":e["mending"]=true
		for duo in ["steamglass","corrosive_flame","black_ice","toxic_spark"]:
			state=Combat.begin(e,100,100,10,4,1.2,[duo],{"tactics":true,"fire":1,"ice":1,"acid":1,"poison":1,"crit_chance":0.3,"crit_mult":1.5})
			var prior=state.duplicate(true);var predicted=Combat.predict(state);check(state==prior,"Forecast leaves affix/duo state unchanged")
			var loops=0
			while not state.done and loops<2000:Combat.step(state);loops+=1
			check(state.done and predicted.hp==state.hp and predicted.won==state.won,"Affix/duo live clock matches forecast")
	state=Combat.begin(dummy("stubborn"),100,100,1000,0,1,[],{"tactics":true});Combat.step(state)
	check(not state.done and state.enemy.hp==20 and state.deathless_used,"Deathless rises exactly once")
	state.e_time=100;Combat.step(state);check(state.won,"Second death is final")
	state=Combat.begin(dummy("venomous"),100,100,1,0,1,[],{"tactics":true,"ability":"interrupt"});state.p_time=100
	check(Combat.needs_decision(state),"Hexfang opening attack gives a decision window");Combat.use_ability(state);Combat.step(state);check(state.wound==0,"Interrupt cancels Hexfang without reflex timing")
	state=Combat.begin(dummy(),50,60,1,0,1,["black_ice"],{"tactics":true,"ice":1,"poison":1});state.e_time=100;state.shield=12
	for i in range(3):Combat.step(state)
	check(state.shield==12,"Black ice never reduces a larger acid shield")
	# Bounties and career rewards cannot be claimed again after reload.
	g.replay.reset_draft();g.skills={};g.new_run(12);preload("res://tools/test_equipment.gd").arm(g);g.session.active=true;g.run_bounties={"slayer":false};g.kills=10;g.replay.observe();var paid=g.shards
	g.replay.observe();check(paid==30 and g.shards==30 and g.career.bounties>0,"Bounty pays once")
	check(g.session.checkpoint() and g.session.continue_run(),"Bounty state saves and restores");g.replay.observe();check(g.shards==paid and g.run_bounties.slayer,"Continue cannot duplicate bounty")
	g.mode="character";check(g.session.checkpoint(),"Journal is a valid saved mode")
	g.mode="equipment";g.inventory=[g.Gear.make("weapon",3,2,["speed","health"])];g.equipped={"weapon":0};g.selected_item=0;g.run_skills={"transmutation":1};g.iron=2;g.shards=8;var forge_room=Vector2i.ZERO
	for coord in g.roles:
		if g.roles[coord]=="Forge":forge_room=coord
	g.room=forge_room
	for tile in g.rooms[g.room].entities:
		if g.rooms[g.room].entities[tile].kind=="salvage":g.pos=tile
	g.action("reforge");check(g.iron==0 and g.shards==0 and g.inventory[0].level==3 and g.inventory[0].rarity==2 and "speed" not in g.inventory[0].affixes,"Reforge costs paid and identity retained")
	var previous_runs=g.career.runs;g.mode="play";g.finish_run(false);g.finish_run(false);check(g.career.runs==previous_runs+1,"Ending cannot duplicate history or currency")
	g.career.wins=0;var deaths_before=g.career.deaths;g.new_run(14);preload("res://tools/test_equipment.gd").arm(g);g.demo_run=true;g.mode="play";g.finish_run(true);check(g.career.wins==0 and g.career.deaths==deaths_before,"One-floor Trial cannot unlock endgame modes")
	# UI scenes render without long descriptions on every node.
	g.mode="title";g.queue_redraw();await process_frame
	for mode in ["profiles","expedition","skills","codex","relic"]:
		g.mode=mode
		if mode=="relic":g.choices=["steamglass","black_ice","wildfire","bulwark"];g.choice_ui.skip_level_intro()
		g.queue_redraw();await process_frame
		check(not g.buttons.is_empty(),"Menu buttons rendered: "+mode)
	g.queue_free();g=null;reboot=null;state.clear();await process_frame;await process_frame;cleanup()
	if failures.is_empty():print("PASS: %d legacy/replay checks; 33-node economy, profiles, odds sampling, Daily fairness, Endless depth, Vows, bounties, collections and 24 affix/duo forecasts."%checks)
	else:
		for message in failures:push_error(message)
	quit(0 if failures.is_empty() else 1)
