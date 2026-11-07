extends SceneTree
const Combat=preload("res://combat.gd")
const Elements=preload("res://element_rules.gd")
const Stats=preload("res://build_stats.gd")
var checks=0
var failures=[]
func check(ok: bool,label: String):
	checks+=1
	if not ok:failures.append(label)
func foe():return {"kind":"enemy","type":0,"name":"Probe","hp":10000,"max":10000,"attack":12,"armor":12.0,"speed":0.5,"trait":"none","elite":false,"roll_seed":12345}
func state(extra: Dictionary={}):
	var build={"elemental_v2":true,"auto_flow":true,"paced":true,"weapon":"plain","crit_chance":0.0,"vampirism":0.35}
	build.merge(extra,true);return Combat.begin(foe(),500,500,20,0,0.5,[],build)
func _initialize():call_deferred("run")
func run():
	var s=state({"poison":2});s.hp=250;var hit={};var landed=0;var poison_events=0
	while landed<3 or poison_events<3:
		hit=Combat.step(s)
		if hit.get("poison_tick",false):
			poison_events+=1;check(is_equal_approx(hit.damage,s.poison_counters*0.5),"Poison: 0.5 damage / counter every 0.5s")
			check(hit.get("vamp_heal",0)==0 and hit.heal==0,"Poison does not trigger vampirism")
		elif hit.player:landed+=1;check(s.poison_counters==2*landed,"Poison accumulates on each landed hit")
	check(Combat.poison_weak(s)==0,"Poison does not weaken enemy attack")
	var fresh=state({"poison":2});check(fresh.poison_counters==0 and fresh.poison_time==INF,"Counters start fresh for every encounter")
	s=state({"fire":2});var result={};s.time=1;Elements.on_hit(s,20,result);check(Elements.burn_damage(s)==4,"Burn scales with pre-armor hit power")
	s.time=2;Elements.on_hit(s,60,result);check(Elements.burn_damage(s)==12,"Stronger hits create stronger burns")
	s.time=3;Elements.on_hit(s,10,result);check(Elements.burn_damage(s)==12,"Burns do not add together")
	s.time=5.1;check(Elements.burn_damage(s)==2,"A weaker hit does not extend a stronger burn")
	s=state({"ice":10});s.time=1;Elements.on_hit(s,20,result);check(result.get("effect","")=="FREEZE" and s.freeze_ready==9 and s.frost_counters==5,"Frost threshold freezes with a cooldown")
	result={};s.time=2;Elements.on_hit(s,20,result);check(not result.get("interrupt",false) and Combat.ice_slow(s)<=0.5,"Frost cannot repeatedly freeze during cooldown")
	s=state({"acid":8});s.time=1;Elements.on_hit(s,20,{});check(s.acid_stacks==8,"Acid applies its combined potency")
	s.time=3;Elements.on_hit(s,20,{});check(Elements.exposure(s)>0 and maxf(0,s.enemy.armor-s.acid_stacks)==0,"Excess acid exposes fully corroded enemies")
	s=state({"fire":2,"ice":2,"acid":2,"poison":2,"crit_chance":0.25});s.enemy.hp=300;s.enemy.max=300
	var original=var_to_bytes(s);var predicted=Combat.predict(s)
	check(original==var_to_bytes(s),"Element forecasts do not mutate timers, counters, burns or private RNG")
	var roundtrip=bytes_to_var(var_to_bytes(s));var resumed=Combat.predict(roundtrip)
	check(predicted==resumed,"Saved elemental battles resume deterministically")
	while not s.done:Combat.step(s)
	check(predicted.won==s.won and predicted.hp==s.hp,"Element forecasts match actual combat")
	var g=load("res://main.tscn").instantiate();g.save_path="res://tests/.elements015.json";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.skills={}
	for seed_value in range(20):
		g.new_run(seed_value);var forges=0
		for coord in g.rooms:
			for e in g.rooms[coord].entities.values():
				if e.kind=="salvage":forges+=1
		var starter=g.rooms[Vector2i.ZERO].entities[g.rooms[Vector2i.ZERO].chest].item
		check(starter.slot=="weapon" and forges>0,"Random starting weapon and forge exist")
		for item in [starter]:
			check(item.rarity==0 and item.level==1 and item.affixes.is_empty() and item.get("plain",false),"No-tree starters are plain common weapons")
			var values=g.Gear.stats(item);check(values.keys().all(func(key):return key in ["attack","speed"]),"Starters have only damage and interval stats")
			g.inventory=[item];g.equipped={"weapon":0};g.recalculate_stats();check(g.combat_build().weapon=="plain","Starter weapon procs are disabled")
	g.new_run(42)
	for element in ["fire","ice","acid","poison"]:
		var old={"fire":"fire_dps","ice":"ice_slow","acid":"acid_strip","poison":"poison_weak"}[element]
		var item=g.make_gear("weapon",1,1,[old]);var key=Elements.KEYS[element]
		check(g.Gear.stats(item).get(key,0)==1,"Elemental equipment adds application potency: "+element)
		g.inventory=[item];g.equipped={"weapon":0};g.recalculate_stats();var now=Stats.calculate(g);check(now.element_totals[element]==1,"Build totals include equipment application")
		var next=Stats.upgrade_preview(g,element,true);check(next.element_totals[element]==2,"Level-up previews combine gear and upgrades")
		var upgraded=item.duplicate(true);upgraded.level=5;check(g.Gear.stats(upgraded)[key]>g.Gear.stats(item)[key],"Iron increases elemental potency at its level threshold")
	g.inventory=[g.make_gear("weapon",1,0)];g.selected_item=0;g.equipped={"weapon":0};g.iron=0;g.shards=0;g.run_skills={};g.rooms[g.room].entities[g.pos+Vector2i.RIGHT]={"kind":"salvage"};g.mode="equipment"
	check(g.dungeon_threads.can_infuse("poison"),"First elemental imprint requires neither tree nor currency")
	g.dungeon_threads.handle("infuse_open");g.dungeon_threads.handle("infuse:poison")
	check(g.floor_flags.get("free_imprint_used",false) and g.inventory[0].infusion=="poison" and g.iron==0 and g.shards==0,"Free imprint is applied and consumed exactly once")
	check(not g.dungeon_threads.can_infuse("fire"),"Second free imprint is blocked")
	g.floor_number=2;g.generate_floor();check(not g.floor_flags.get("free_imprint_used",false),"Free imprint resets on each floor")
	g.run_skills={"poison_mastery":10};check("+1.5" in g.choice_ui.summary("venom"),"Upgrade headline includes mastery in the actual gain")
	g.skills={"smithcraft":1};g.new_run(42)
	var upgraded_starter=g.rooms[g.room].entities[g.rooms[g.room].chest].item
	var rare=upgraded_starter.rarity==1 and not upgraded_starter.get("plain",false)
	check(rare,"Quartermaster upgrades starting gear")
	for variant in ["winterblade","caustic"]:
		var item=g.make_gear("weapon",1,1,[],"dagger" if variant=="winterblade" else "ember");item["variant"]=variant
		check(("Frost power" if variant=="winterblade" else "Acid power") in g.choice_ui.weapon_description(item),"Elemental weapon variant descriptions use base power units")
	g.run_rules=8;var old_state=Combat.begin(foe(),100,100,20,0,0.5,["venom"],{"poison":1});check(Combat.poison_weak(old_state)>0 and not old_state.has("poison_counters"),"Continued older runs keep their elemental rules")
	g.free();print(JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
