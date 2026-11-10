extends SceneTree
# Saved rules 18 contract; current expeditions are covered by the Hearth suites.
const Combat=preload("res://combat.gd")
const Elements=preload("res://element_rules.gd")
const Offers=preload("res://skill_offers.gd")
var checks=0
var failures=[]
func check(ok:bool,why:String):
 checks+=1
 if not ok and failures.size()<30:failures.append(why)
func _initialize():call_deferred("run")
func foe():return {"kind":"enemy","type":0,"name":"Target","hp":10000.0,"max":10000.0,"attack":1,"armor":4.0,"speed":0.5,"trait":"none","elite":false,"roll_seed":123}
func state(build:Dictionary,relics:Array=[]):
 var cfg={"elemental_v2":true,"elemental_specialization":true,"element_interval_scale":1.0,"fair_physical":true,"paced":true,"weapon_archetype":"balanced","crit_chance":0.0}
 cfg.merge(build,true)
 return Combat.begin(foe(),100,100,20,0,0.5,relics,cfg)
func benchmark(weapon:String,allocation:Dictionary,armor:float) -> Dictionary:
 var cfg={"elemental_v2":true,"elemental_specialization":true,"fire":0,"ice":0,"acid":0,"poison":0,"fair_physical":true,"element_interval_scale":{"dagger":0.5,"balanced":1.0,"axe":1.5}[weapon],"weapon_archetype":weapon,"paced":true,"crit_chance":0.0}
 cfg.merge(allocation,true)
 var enemy=foe();enemy.hp=500.0;enemy.max=500.0;enemy.armor=armor;enemy.attack=8
 var interval={"dagger":1.0,"balanced":2.0,"axe":3.0}[weapon];var attack={"dagger":10.0,"balanced":20.0,"axe":30.0}[weapon]
 var b=Combat.begin(enemy,10000,10000,attack,0,1.0/interval,[],cfg)
 while not b.done:Combat.step(b)
 return {"time":b.time,"loss":10000-b.hp}
func run():
 var frost=state({"ice":2});var event={}
 for i in range(9):frost.time=i;Elements.on_hit(frost,20,event)
 check(is_equal_approx(frost.frost_counters,18.0) and not event.has("interrupt") and is_equal_approx(Elements.slow(frost),0.45),"Two Frost takes ten hits to freeze and slows 2.5% per counter")
 frost.time=9;event={};Elements.on_hit(frost,20,event)
 check(event.get("effect","")=="FREEZE" and frost.frost_counters==10 and frost.frozen_until==10 and frost.freeze_ready==17,"20 Frost freezes for one second, resets to ten, and has eight-second cooldown")
 var legacy=state({"ice":10,"elemental_specialization":false});event={};Elements.on_hit(legacy,20,event)
 check(event.get("effect","")=="FREEZE" and legacy.frost_counters==5,"Legacy fights keep their 10-counter freeze")
 var fire=state({"fire":8});var base=Elements.burn_power(fire.build,20)
 for i in range(5):fire.time=i*0.4;Elements.on_hit(fire,20,{})
 check(fire.fire_heat==4 and is_equal_approx(Elements.burn_damage(fire),base*1.4),"Fire specialization increases burn with repeated hits")
 var mixed_fire=state({"fire":2});Elements.on_hit(mixed_fire,20,{});Elements.on_hit(mixed_fire,20,{})
 check(mixed_fire.fire_heat==0,"Low Fire power does not gain specialization Heat")
 var heavy=state({"fire":4,"element_interval_scale":1.5,"weapon_archetype":"axe"},["combustion"])
 Elements.on_hit(heavy,20,{});Elements.on_hit(heavy,20,{});Elements.on_hit(heavy,20,{})
 check(heavy.fire_heat==4,"Heavy weapons build two Heat on each repeat hit")
 var expected_burst=Elements.burn_damage(heavy)*2;heavy.p_time=0.5;heavy.e_time=100;var hit=Combat.step(heavy)
 check(hit.get("effect","")=="COMBUSTION" and is_equal_approx(hit.get("element_damage",0),expected_burst) and heavy.fire_heat==0,"Combustion consumes Heat for Fire burst")
 var poison=state({"poison":4});var hp=poison.enemy.hp;event={}
 for i in range(3):Elements.on_hit(poison,20,event)
 check(is_equal_approx(hp-poison.enemy.hp,8.0) and poison.poison_next_burst==20 and event.get("effect","")=="POISON BURST","Poison power 4 bursts for 8 at ten counters")
 var harvest=state({"poison":4},["toxic_harvest"]);hp=harvest.enemy.hp
 for i in range(3):Elements.on_hit(harvest,20,{})
 check(is_equal_approx(hp-harvest.enemy.hp,16.0),"Toxic harvest doubles poison bursts")
 var high_poison=state({"poison":25});hp=high_poison.enemy.hp;Elements.on_hit(high_poison,20,{})
 check(is_equal_approx(hp-high_poison.enemy.hp,100.0) and high_poison.poison_next_burst==30,"A hit crossing two poison thresholds awards two bursts")
 var acid=state({"acid":8})
 for i in range(8):Elements.on_hit(acid,20,{})
 check(acid.acid_stacks==64 and is_equal_approx(Elements.exposure(acid),0.6),"Eight Acid power can build up to 80% physical damage after armor")
 var low_acid=state({"acid":2});low_acid.acid_stacks=999
 check(is_equal_approx(Elements.exposure(low_acid),0.2),"Low Acid power retains 20% limit")
 var shatter=state({"ice":4,"weapon_archetype":"axe"},["frost_shatter"]);shatter.frost_counters=10;shatter.iced=true;shatter.frozen_until=1.0;shatter.frost_shatter_ready=true;shatter.e_time=10;shatter.p_time=0.5
 hit=Combat.step(shatter)
 check(hit.get("frost_shatter",false) and shatter.frozen_until==0 and shatter.frost_counters==4,"Heavy hit shatters freeze, spends counters and applies fresh Frost")
 var armor_broken=state({},["exposed_core"]);armor_broken.acid_stacks=4;armor_broken.e_time=100;armor_broken.p_time=0.5;hit=Combat.step(armor_broken)
 check(is_equal_approx(hit.physical_damage,25),"Exposed core grants 25% physical damage after armor is removed")
 var caustic=state({"fire":1,"acid":8},["corrosive_flame"]);caustic.acid_stacks=20;caustic.burns=[{"power":2.0,"until":10.0}];caustic.fire_time=1.0;caustic.fire_until=10.0;caustic.p_time=100;caustic.e_time=100
 Combat.step(caustic);check(caustic.acid_stacks==21,"Fire-and-Acid synergy preserves accumulated corrosion")
 var glacier=state({"poison":2,"ice":2},["toxic_glacier"]);glacier.poison_counters=2;glacier.poison_time=0.5;glacier.p_time=100;glacier.e_time=100
 Combat.step(glacier);check(is_equal_approx(glacier.frost_counters,0.5),"Toxic Glacier connects poison ticks to Frost in the new rules")
 var dot=state({"poison":4});dot.poison_counters=4;dot.poison_time=0.5;dot.p_time=100;dot.e_time=100;hit=Combat.step(dot)
 check(is_equal_approx(hit.damage,1.0),"New poison ticks deal 0.25 per counter every 0.5 seconds")
 var frozen_hit=state({"ice":20,"weapon_archetype":"axe","element_interval_scale":1.5},["frost_shatter"]);frozen_hit.e_time=100;Elements.on_hit(frozen_hit,20,{})
 frozen_hit.p_time=3;hit=Combat.step(frozen_hit)
 check(hit.get("frost_shatter",false),"Slow weapons can shatter on their next hit even after the one-second freeze ends")
 var saved=bytes_to_var(var_to_bytes(frozen_hit));check(Combat.predict(frozen_hit)==Combat.predict(saved),"Specialization counters survive serialization and deterministic prediction")
 for weapon in ["dagger","balanced","axe"]:
  var mixed=benchmark(weapon,{"fire":2,"ice":2,"acid":2,"poison":2},20)
  var fire_build=benchmark(weapon,{"fire":8},20);var ice_build=benchmark(weapon,{"ice":8},20)
  var acid_build=benchmark(weapon,{"acid":8},20);var poison_build=benchmark(weapon,{"poison":8},20)
  check(fire_build.time<mixed.time,"Focused Fire has a faster-kill payoff: "+weapon)
  check(ice_build.loss<mixed.loss,"Focused Frost offers more protection: "+weapon)
  check(acid_build.time<mixed.time,"Focused Acid breaks armored enemies faster: "+weapon)
  check(poison_build.time<mixed.time,"Focused Poison has a faster-kill payoff: "+weapon)
 var g=load("res://main.tscn").instantiate();g.save_path="/private/tmp/magic-element-special";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.skills={};preload("res://tools/historical_run.gd").start(g,42,18)
 var item=g.make_gear("weapon",1,0,[],"axe");item.plain=true;g.inventory=[item];g.equipped={"weapon":0};g.base_elements={"fire":4,"ice":0,"acid":4,"poison":4};g.reward_level=7;g.recalculate_stats()
 var pool=Offers.pool(g)
 check("combustion" in pool and "toxic_harvest" in pool and "exposed_core" in pool,"Specialization skills enter the eligible random pool")
 check(Offers.choose(g).size()==3,"Skill selection still offers three choices")
 check(g.combat_build().elemental_specialization and preload("res://build_stats.gd").calculate(g).build.elemental_specialization,"Combat and build preview use matching rules")
 check("20" in g.stat_ui.info("ice")[2] and "40%" in g.stat_ui.info("acid")[2],"Stat tooltips describe updated frost and acid rules")
 g.base_elements.ice=3;g.recalculate_stats();g.mode="relic";g.choices=["frost","venom","solvent"];g.queue_redraw();await process_frame;await process_frame
 check(g.buttons.any(func(b):return b.id=="relic0"),"A level-up that crosses an elemental milestone renders")
 g.mode="relic";g.choices=["combustion","toxic_harvest","exposed_core"];g.queue_redraw();await process_frame;await process_frame
 check(g.buttons.any(func(b):return b.id=="relic2") and g.choice_ui.summary("toxic_harvest").contains("×2"),"New skill cards render and remain selectable")
 g.action("relic0");check("combustion" in g.relics,"Selecting the new skill adds it to the build")
 g.fight=g.make_enemy(0,1,3);g.fight.position=g.pos+Vector2i.RIGHT;g.battle=Combat.begin(g.fight,g.hp,g.max_hp,g.attack,g.armor,g.speed,g.relics,g.combat_build())
 Elements.on_hit(g.battle,g.attack,{});Elements.on_hit(g.battle,g.attack,{});var stored_heat=g.battle.fire_heat
 g.mode="fight";g.session.enabled=true;g.session.active=true
 check(g.session.checkpoint() and g.session.continue_run() and g.run_rules==18 and g.battle.fire_heat==stored_heat and "combustion" in g.relics,"Active specialization fight survives save and continue")
 g.session.enabled=false
 g.battle=Combat.begin(g.fight,g.hp,g.max_hp,g.attack,g.armor,g.speed,g.relics,g.combat_build());g.battle.poison_counters=9;g.battle.p_time=0.5;g.battle.e_time=100;g.battle.build.acid=0;g.battle.build.acid_apply=0;g.battle.enemy.hp=1000;g.battle.enemy.max=1000
 var feedback_event=Combat.step(g.battle);var before_motes=g.motes.size();g.feedback.hit(feedback_event,g.battle)
 check(feedback_event.get("combo_element","")=="poison" and g.motes.size()>before_motes,"Poison bursts produce combat feedback")
 g.queue_redraw();await process_frame;await process_frame
 for suffix in [".run",".run.bak",".run.tmp"]:DirAccess.remove_absolute(g.save_path+suffix)
 g.run_rules=16;pool=Offers.pool(g);check("toxic_harvest" not in pool and not g.combat_build().elemental_specialization,"Older runs retain old elemental rules and offers")
 g.free();print(JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
