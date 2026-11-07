extends SceneTree
const Combat=preload("res://combat.gd")
const Stats=preload("res://build_stats.gd")
var checks=0
var failures=[]
func check(ok: bool,label: String):
	checks+=1
	if not ok:failures.append(label)
func _initialize():call_deferred("run")
func run():
	for pair in [[0,0.0],[6,1.0/3],[12,0.5],[18,0.6],[36,0.75],[60,5.0/6]]:
		check(is_equal_approx(Combat.armor_reduction(pair[0]),pair[1]),"Reduction at armor %d"%pair[0])
	check(Combat.damage(120,18)==48 and Combat.damage(120,36)==30 and Combat.damage(120,60)==20,"Armor beyond 18 keeps protecting")
	check(Combat.damage(20,24)==7 and Combat.damage(20,36)==5,"Physical damage rounds up after mitigation")
	check(Combat.damage(20,-5)==20 and Combat.damage(20,1000000)==1,"Negative armor and minimum-damage rules")
	for armor in range(1,151):
		check(Combat.armor_reduction(armor)>Combat.armor_reduction(armor-1),"No hard armor plateau")
		check(Combat.armor_reduction(armor)-Combat.armor_reduction(armor-1)<Combat.armor_reduction(armor-1)-Combat.armor_reduction(armor-2) if armor>1 else true,"Reduction has diminishing returns")
		if armor<=18:check(Combat.damage(53.7,armor)==maxi(1,ceili(53.7*maxf(0.4,12.0/(12+armor)))),"Early armor pacing is unchanged")
	var g=load("res://main.tscn").instantiate();g.save_path="res://tests/.armor014.json";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.new_run(42);g.run_skills={}
	g.bonus.armor=36;g.recalculate_stats();var before=Stats.calculate(g)
	check(before.armor==36 and is_equal_approx(before.armor_reduction,0.75),"Build overview exposes effective armor reduction")
	g.inventory=[g.make_gear("shield",5,0)];var preview=Stats.prospective(g,0);var snapshot=var_to_bytes([g.inventory,g.equipped,g.hp,g.rng.state])
	check(preview.armor_reduction>before.armor_reduction,"Gear comparison values armor upgrades beyond the former cap")
	check("armor_reduction" not in preload("res://equipment_presenter.gd").affected({},g.inventory[0]),"Derived physical reduction stays in armor details, outside item comparisons")
	check(snapshot==var_to_bytes([g.inventory,g.equipped,g.hp,g.rng.state]),"Preview does not mutate the run")
	var e={"kind":"enemy","type":0,"name":"Probe","hp":10000,"max":10000,"attack":60,"armor":0,"speed":0.5,"trait":"none","elite":false,"roll_seed":123}
	for armor in [18.0,36.0]:
		var s=Combat.begin(e,500,500,10,armor,0.5,[],{"paced":true,"auto_flow":true});var event={}
		while not s.done:
			event=Combat.step(s)
			if not event.get("player",true):break
		check(event.damage==Combat.damage(60,armor),"Live enemy attacks use the uncapped curve")
	var burn=[]
	for armor in [0,1000]:
		var foe=e.duplicate(true);foe.armor=armor
		var s=Combat.begin(foe,500,500,10,0,0.5,[],{"paced":true,"auto_flow":true,"fire":1,"fire_stack_damage":2.0});var event={}
		while not s.done:
			event=Combat.step(s)
			if event.get("burn",false):burn.append(event.damage);break
	check(burn.size()==2 and burn[0]==burn[1],"Fire still bypasses armor")
	check(Combat.damage(60,36*0.5)>Combat.damage(60,36) and Combat.damage(60,36-12)>Combat.damage(60,36),"Piercing and acid still counter high armor")
	g.free();print(JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
