extends SceneTree
const Combat=preload("res://combat.gd")
var checks=0
var failures=[]
var g
const PATH="res://tests/.flow06.json"
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok and failures.size()<30:failures.append(message)
func foe() -> Dictionary:return {"kind":"enemy","type":1,"name":"Target","hp":200,"max":200,"attack":10,"armor":0,"speed":1.0,"trait":"none","elite":false,"roll_seed":1}
func state(weapon: String="balanced",extra: Dictionary={}) -> Dictionary:
	var build={"auto_flow":true,"tactics":true,"weapon":weapon,"weapon_level":1}
	build.merge(extra,true)
	return Combat.begin(foe(),10,100,20,0,1,[],build)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var s=state("unarmed",{"vampirism":0.1});s.e_time=100;var hit=Combat.step(s)
	check(hit.actual_damage==20 and hit.vamp_heal==2 and s.hp==12,"20 actual damage at 10% vampirism heals 2")
	s=state("unarmed",{"vampirism":0.1});s.attack=5;s.e_time=100
	for i in range(4):Combat.step(s)
	check(s.hp==12 and is_zero_approx(s.life_fraction),"Fractional lifesteal accumulates without rounding inflation")
	s=state("unarmed",{"vampirism":0.1});s.enemy.hp=3;s.e_time=100;hit=Combat.step(s)
	check(s.hp==10 and hit.actual_damage==3,"Overkill cannot generate extra healing")
	s=state("unarmed",{"vampirism":0.1});s.enemy.trait="shield";s.weapon_guard=1;s.e_time=100;hit=Combat.step(s)
	check(hit.actual_damage==0 and hit.heal==0,"Blocked strikes provide no lifesteal")
	s=state("unarmed",{"vampirism":0.1,"crit_chance":0.6,"crit_mult":2.0});s.e_time=100;hit=Combat.step(s)
	check(hit.crit and hit.actual_damage==40 and hit.vamp_heal==4,"Critical health damage feeds vampirism")
	s=state("unarmed",{"vampirism":9.0});s.e_time=100;hit=Combat.step(s);check(hit.vamp_heal==7,"Vampirism capped at 35%")
	s=state("unarmed",{"vampirism":0.35});s.hp=99;s.e_time=100;Combat.step(s);check(s.hp==100 and s.life_fraction==0,"Healing capped, excess cannot be banked")
	s=state("dagger",{"evade":0.5});s.p_time=100;s.evade_roll=1;s.combo=2;s.shield=8;s.enemy.type=2;s.e_hits=1;s.enemy["hexed"]=true;s.enemy["affix"]="venomous";hit=Combat.step(s)
	check(hit.evaded and s.hp==10 and s.shield==8 and s.wound==0 and s.combo==2,"Dodge prevents damage/debuffs and preserves shield/combo")
	check(not Combat.needs_decision(s) and not Combat.use_ability(s),"Passive encounters never require active prompts")
	var rng=RandomNumberGenerator.new();rng.seed=991;var dodges=0
	for i in range(10000):
		s=state("unarmed",{"evade":9.0});s.p_time=100;s.evade_roll=rng.randi_range(1,2147483646)
		if Combat.step(s).get("evaded",false):dodges+=1
	check(dodges>4700 and dodges<5300,"Evasion capped at 50%, sampled over 10,000 strikes")
	s=state("dagger");s.e_time=100;s.attack=10;Combat.step(s);Combat.step(s);hit=Combat.step(s)
	check(hit.finisher and hit.damage==15 and s.combo==0,"Dagger's third consecutive hit gains 50% power")
	s=state("dagger");s.combo=2;s.p_time=100;Combat.step(s);check(s.combo==0,"Health damage resets dagger combo")
	s=state("greatblade");s.weapon_guard=1;s.e_time=100;hit=Combat.step(s)
	check(hit.guard_break and hit.damage>0,"Greatblade breaks opening weapon guard")
	s=state("greatblade");s.e_time=100;s.enemy.armor=8;Combat.step(s);Combat.step(s);hit=Combat.step(s)
	check(hit.sunder and hit.interrupt and is_equal_approx(s.enemy.armor,5.75),"Greatblade third strike strips armor and interrupts")
	s=state("balanced");s.e_time=100
	for i in range(4):Combat.step(s)
	check(s.shield==3,"Sword fourth successful hit grants shield")
	s=state("ember",{"fire_dps":2.0,"vampirism":0.1});s.e_time=100
	while s.p_hits<3:hit=Combat.step(s)
	check(hit.element_damage==3 and hit.vamp_heal==2,"Ember flare is magic damage, not extra vampirism")
	# Every weapon, enemy and passive combination follows the same private forecast rolls.
	var precise=state("balanced",{"vampirism":0.15});precise.life_fraction=0.09999999
	var credit_hit={"heal":0};Combat.Flow.after_player(precise,credit_hit,6.0);Combat.Flow.after_player(precise,credit_hit,6.0)
	check(precise.hp==11 and precise.life_fraction<0.901,"Fractional precision never duplicates healing credit")
	var fast=state("greatblade");fast.speed=30;fast.attack=1;fast.hp=10000;fast.max_hp=10000;fast.enemy.hp=10000;fast.enemy.max=10000
	for i in range(300):Combat.step(fast)
	check(fast.e_hits>=3,"Fast greatblades cannot indefinitely delay the next enemy strike")
	var identities=["","pikeman","leech","wisp","construct","shade","castellan","tide","abbot","furnace","eclipse"]
	for identity in identities:
		for weapon in ["balanced","dagger","greatblade","ember"]:
			for passive in range(9):
				var enemy=foe();enemy.roll_seed=554+passive*39;enemy.hp=150;enemy.max=150;enemy.armor=5;enemy.attack=12
				if identity in Combat.Flow.FAMILIES:enemy["family"]=identity
				if identity in Combat.Flow.BOSSES:enemy.type=3;enemy["signature"]=identity;enemy["regen"]=4
				var build={"auto_flow":true,"tactics":true,"weapon":weapon,"weapon_level":2,"evade":float(passive%3)*0.25,"vampirism":float(int(passive/3))*0.15,"fire_dps":2.0,"ice":1,"acid":1,"poison":1,"crit_chance":0.15,"crit_mult":1.5}
				s=Combat.begin(enemy,50,70,14,4,1.2,[],build);var before=s.duplicate(true);var expected=Combat.predict(s)
				check(s==before and Combat.predict(s)==expected,"Forecast remains stable and read-only")
				var events=0
				while not s.done and events<3000:Combat.step(s);events+=1
				check(s.done and expected.hp==s.hp and expected.won==s.won,"Weapon/family/boss/passive forecast matches simulation")
	# Independent floor/boss mechanics.
	s=state();s.enemy["signature"]="castellan";s.enemy.hp=105;s.e_time=100;s.enemy.type=3;Combat.step(s);check(s.weapon_guard==1 and s.bastion_used,"Castellan fortifies once below half health")
	s=state();s.enemy["signature"]="tide";s.e_hits=2;s.p_time=100;s.enemy.type=3;Combat.step(s);check(s.tide_followup and is_equal_approx(s.e_time,s.time+0.25),"Regent queues fast independent follow-up")
	s=state();s.enemy["signature"]="abbot";s.enemy.type=3;s.flow_ready=false;Combat.Flow.prepare(s);s.enemy.hp=100;s.fire_until=10;s.fire_time=20;s.p_time=100;s.e_time=100;s.regen_time=1;hit=Combat.step(s);check(hit.enemy_heal==2,"Burn halves Soulmend")
	var channel=s.regen_time;Combat.Flow.interrupt(s,0.5,{});check(s.regen_time==channel+0.5,"Interrupt delays Soulmend")
	s=state();s.enemy["signature"]="furnace";s.heat=4;s.p_time=100;hit=Combat.step(s);check(hit.damage==16 and s.heat==0,"Furnace vents accumulated heat")
	s=state("unarmed");s.enemy["signature"]="eclipse";s.e_time=100;hit=Combat.step(s);check(hit.damage==15,"Solar seal reduces weapon damage")
	s=state("unarmed",{"crit_chance":0.6,"crit_mult":2.0});s.enemy["signature"]="eclipse";s.e_time=100;hit=Combat.step(s);check(s.seal_broken and hit.damage==40,"Critical hit breaks eclipse seal")
	g=load("res://main.gd").new();g.save_path=PATH;root.add_child(g);preload("res://tools/test_equipment.gd").arm(g);g.set_process(false);g.session.enabled=false;g.muted=true
	for seed_value in range(50):
		g.new_run(seed_value);preload("res://tools/test_equipment.gd").arm(g)
		for floor_index in range(1,6):
			var count=0;var expected_family=Combat.Flow.FAMILY_ORDER[floor_index-1]
			for data in g.rooms.values():
				for e in data.entities.values():
					if e.has("family"):check(e.family==expected_family,"Exclusive enemies stay on their floor");count+=1
			check(count>=2,"Each floor guarantees two exclusive enemies")
			var boss=g.rooms[g.boss_room].entities[Vector2i(6,3)];check(boss.signature==Combat.Flow.BOSSES.keys()[floor_index-1],"Each floor assigns its signature boss")
			if floor_index<5:g.mode="floor";g.ascend_floor()
	# Real uninterrupted frames, and save restoration of a legacy pending decision.
	g.new_run(12);preload("res://tools/test_equipment.gd").arm(g);g.inventory[0]=g.Gear.make("weapon",2,1,["vampirism"],"dagger");g.recalculate_stats();g.hp=g.max_hp
	var enemy=foe();enemy.hp=160;enemy.max=160;g.rooms[g.room].entities[Vector2i(3,5)]=enemy;g.move_player(Vector2i.RIGHT)
	for i in range(100):
		if g.mode!="fight":break
		g._process(0.05);check(not g.battle.waiting,"Frame loop never introduces decision pauses")
	g.session.enabled=true;g.session.active=true;g.mode="fight";g.battle=Combat.begin(foe(),20,60,12,4,1.2,[],g.combat_build());g.fight=foe();g.fight["position"]=Vector2i(3,5);g.battle.waiting=true;g.battle.erase("flow_ready")
	check(g.session.checkpoint() and g.session.continue_run() and not g.battle.waiting and g.battle.flow_ready,"Legacy pending pause upgrades to automatic flow")
	g.battle.build["toxic_echo"]=0.1;g.toxic_echo=0.0
	var predicted=Combat.predict(g.battle);check(g.session.checkpoint() and g.session.continue_run() and Combat.predict(g.battle)==predicted,"Dodge RNG, combo and life fractions survive Continue")
	check(g.battle.build.toxic_echo==0.1,"Consumed Contagion survives combat checkpoint")
	check(g.Gear.stats(g.Gear.make("weapon",1,1,["evade"],"dagger")).evade>0.03,"Dagger and affix evasion stack")
	check(g.Gear.stats(g.Gear.make("amulet",1,1,["vampirism"])).vampirism>0.05,"Amulet supplies accessible vampirism")
	g.session.enabled=false;g.queue_free();g=null;await process_frame
	for suffix in ["",".tmp",".run",".run.bak",".run.tmp"]:
		if FileAccess.file_exists(PATH+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH+suffix))
	if failures.is_empty():print("PASS: %d flow checks; 396 weapon/enemy/passive forecasts, 10,000 dodge samples, 250 themed floors, automatic flow and save migration."%checks)
	else:
		for message in failures:push_error(message)
	quit(0 if failures.is_empty() else 1)
