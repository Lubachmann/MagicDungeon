extends SceneTree
const Stats=preload("res://build_stats.gd")
var g
var checks=0
var failures=[]
var rows=[]
func check(ok: bool,msg: String) -> void:
	checks+=1
	if not ok:failures.append(msg)
func equip(weapon: String,level: int=1,rarity: int=0,affixes: Array=[]) -> void:
	g.inventory=[g.make_gear("weapon",level,rarity,affixes,weapon)];g.equipped={"weapon":0};g.recalculate_stats();g.hp=g.max_hp
func simulate(enemy: Dictionary) -> Dictionary:
	var s=g.Combat.begin(enemy,g.hp,g.max_hp,g.attack,g.armor,g.speed,g.relics,g.combat_build());var i=0
	while not s.done and i<10000:g.Combat.step(s);i+=1
	return s
func _initialize() -> void:call_deferred("run")
func run() -> void:
	g=load("res://main.tscn").instantiate();g.save_path="res://tests/.pacing012.json";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.new_run(42);g.run_skills={}
	check(g.run_rules==18 and g.inventory.is_empty() and is_equal_approx(g.speed,0.5),"Fresh character is unarmed and attacks every 2s")
	equip("balanced");var sword=g.attack;check(is_equal_approx(g.speed,0.5),"Sword starts at 2s")
	equip("dagger");check(is_equal_approx(g.speed,1) and is_equal_approx(g.attack,sword*0.5),"Dagger starts at 1s and half total sword hit power")
	equip("axe");check(is_equal_approx(g.speed,1.0/3.0) and is_equal_approx(g.attack,sword*1.5),"Axe starts at 3s and 150% sword hit power")
	for weapon in ["balanced","dagger","axe","greatblade","ember"]:
		for level in [1,5,10]:
			equip(weapon,level,1,["speed"]);var item=g.inventory[0];var expected=g.Gear.stats(item)
			var upgraded=item.duplicate(true);upgraded.level+=1;var fresh=g.make_gear("weapon",level+1,1,["speed"],weapon)
			check(g.Gear.stats(upgraded)==g.Gear.stats(fresh),"Iron recomputes current formula: "+weapon)
			var before=var_to_bytes([g.inventory,g.equipped,g.hp,g.rng.state]);var preview=Stats.prospective(g,0,{0:upgraded});check(before==var_to_bytes([g.inventory,g.equipped,g.hp,g.rng.state]),"Weapon upgrade previews are pure")
			g.inventory[0]=upgraded;g.recalculate_stats();check(preview.attack==g.attack and preview.speed==g.speed,"Weapon preview includes both cadence and hit power")
	equip("dagger",1);var early_interval=1.0/g.speed;equip("dagger",8,2,["speed"]);check(1.0/g.speed<early_interval*0.75,"Developed dagger gets noticeably faster")
	equip("axe",1);var early_hit=g.attack;equip("axe",8,2,["crit_mult"]);check(g.attack>early_hit*1.6,"Developed axe gains much larger hits")
	g.new_run(42);g.run_skills={}
	for weapon in ["balanced","dagger","axe"]:
		equip(weapon)
		for type in [0,1]:
			if type==1:
				for slot in ["shield","armor","helmet"]:g.inventory.append(g.make_gear(slot,1,0));g.equipped[slot]=g.inventory.size()-1
				g.recalculate_stats();g.hp=g.max_hp
			var sum=0.0;var wins=0
			for seed_value in range(32):
				var enemy=g.make_enemy(type,0 if type==0 else 2,1 if type==0 else 6);enemy.erase("affix");enemy.erase("mending");enemy.roll_seed=100+seed_value*5231;var s=simulate(enemy);sum+=s.time;wins+=int(s.won)
			var mean=sum/32;rows.append({"floor":1,"weapon":weapon,"enemy":"weak" if type==0 else "strong","seconds":snappedf(mean,0.01),"wins":wins})
			check(wins==32,"Prepared opening encounter is winnable: %s / %d"%[weapon,type])
			check(mean>=0.4 and mean<=3.1 if type==0 else mean>=12 and mean<=26,"Opening fight duration is in target range: %s / %d / %.2fs"%[weapon,type,mean])
	g.new_run(42);g.run_skills={};equip("dagger",1,2,["crit_chance"])
	for slot in ["shield","armor","helmet","amulet"]:g.inventory.append(g.make_gear(slot,1,2,["crit_chance","speed"]));g.equipped[slot]=g.inventory.size()-1
	g.relics=["precision"];g.recalculate_stats();check(g.crit_chance<0.45,"Even a complete early Very rare crit set does not reach 60%")
	g.bonus.crit_chance=0.8;g.recalculate_stats();check(g.crit_chance==0.6,"Default crit limit remains 60%")
	var preview=Stats.upgrade_preview(g,"critical_horizon");g.grant_relic("critical_horizon");check(g.crit_chance==0.75 and preview.crit_cap==0.75,"Critical horizon raises the real cap to 75%")
	g.grant_relic("unbound_aim");check(is_equal_approx(g.crit_chance,0.9),"Unbound aim raises the real cap to 90%")
	var foe=g.make_enemy(0,0);foe.hp=10000000;foe.max=foe.hp;var state=g.Combat.begin(foe,10000000,10000000,1,0,1000,[],{"paced":true,"auto_flow":true,"crit_chance":0.85,"crit_cap":0.9});state.e_time=100000;var crits=0
	for i in range(10000):var hit=g.Combat.step(state);crits+=int(hit.crit)
	check(crits>8200 and crits<8800,"Combat RNG actually permits crit chance above 60%")
	g.new_run(42);g.character_level=1;g.bonus.crit_chance=0.5;check("critical_horizon" not in g.relic_pool(),"Cap upgrade is not offered at the start")
	g.character_level=5;g.reward_level=5;g.recalculate_stats();check("critical_horizon" in g.relic_pool(),"Invested crit builds unlock the first cap choice later")
	g.bonus.crit_chance=0.8;g.character_level=5;g.reward_level=5;g.relics=[];g.recalculate_stats();check("critical_horizon" in g.relic_pool(),"Capped builds can find the cap upgrade in the eligible pool")
	check(g.session.valid(g.session.snapshot()),"Current rules and versioned equipment can be saved")
	g.new_run(42)
	for tile in g.rooms[g.room].entities:
		if g.rooms[g.room].entities[tile].kind=="build_cache":
			g.puzzle_tile=tile;g.mode="decision";check(g.rooms[g.room].entities[tile].items.size()==3,"The entrance offers all three main weapon cadences");g.queue_redraw();await process_frame;break
	g.character_level=5;g.bonus.crit_chance=0.8;g.choices=["critical_horizon","ruin","haste"];g.mode="relic";g.queue_redraw();await process_frame
	g.grant_relic("critical_horizon");g.mode="build";g.queue_redraw();await process_frame
	var first=g.make_enemy(0,0);g.floor_number=5;var fifth=g.make_enemy(0,0);check(fifth.hp>first.hp*5 and fifth.attack>first.attack*3,"Fifth-floor enemies scale substantially beyond the first")
	var legacy=g.Gear.make("weapon",2,0);check(g.Gear.stats(legacy).attack==7,"Saved unversioned equipment retains old stats")
	var legacy_state=g.Combat.begin(first,100,100,10,1,1,[],{});check(legacy_state.p_time==0,"Old combat retains immediate first attacks")
	print(JSON.stringify(rows));var path=OS.get_environment("MAGICDUNGEON_PACING_OUTPUT")
	if path!="":var f=FileAccess.open(path,FileAccess.WRITE);f.store_string(JSON.stringify(rows,"\t"))
	print("PACING BALANCE: %d checks / %d failures"%[checks,failures.size()]);for failure in failures:print("FAIL: "+failure)
	g.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
