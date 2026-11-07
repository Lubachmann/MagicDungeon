extends SceneTree
const Combat=preload("res://combat.gd")
var failures=[]
func check(v:bool,msg:String):
 if not v:failures.append(msg)
func enemy():return {"kind":"enemy","name":"Target","type":0,"hp":1000.0,"max":1000,"attack":1,"armor":10.0,"speed":0.5,"trait":"none","elite":false,"roll_seed":123}
func state(power:float,rate:float,guard:bool=false,weapon:String="plain"):
 var e=enemy();e.trait="shield" if guard else "none";var build={"auto_flow":true,"elemental_v2":true,"paced":true,"fair_physical":true,"weapon":weapon,"crit_chance":0.0};var s=Combat.begin(e,100,100,power,0,rate,[],build);s.e_time=1000;return s
func _initialize():call_deferred("run")
func run():
 var dagger=state(7.8,1.0);var sword=state(15.6,0.5)
 for i in range(2):Combat.step(dagger)
 Combat.step(sword)
 check(is_equal_approx(1000-dagger.enemy.hp,1000-sword.enemy.hp),"Equivalent weapon power causes equal damage without per-hit rounding")
 var d=state(4,1,true);var a=state(8,0.5,true);d.enemy.armor=0;a.enemy.armor=0
 var first=Combat.step(d);check(first.damage==0 and is_equal_approx(d.guard_hp,4) and d.weapon_guard==1,"Guard absorbs a partial hit and remains")
 var second=Combat.step(d);var heavy=Combat.step(a);check(second.damage==0 and heavy.damage==0 and d.weapon_guard==0 and a.weapon_guard==0,"Equal damage breaks the same 8-point guard")
 Combat.step(d);Combat.step(d);Combat.step(a);check(is_equal_approx(d.enemy.hp,a.enemy.hp),"Equal power after guard yields equal damage")
 var partial=state(12,0.5,true);partial.enemy.armor=0;var hit=Combat.step(partial);check(is_equal_approx(hit.damage,4) and hit.guard_break and partial.weapon_guard==0,"Damage beyond guard passes through")
 var blade=state(12,0.5,true,"greatblade");blade.enemy.armor=0;hit=Combat.step(blade);check(is_equal_approx(hit.damage,12) and hit.guard_break,"Greatblade bypasses the whole guard")
 var s=state(20,1,true);s.enemy.armor=0;s.fire_time=0;s.burns=[{"until":3,"power":5.0}];s.p_time=100;hit=Combat.step(s);check(is_equal_approx(hit.damage,5) and s.guard_hp==8,"Fire ignores the guard")
 s=state(20,1,false);s.enemy.type=3;s.enemy.signature="castellan";s.enemy.hp=501;s.enemy.max=1000;s.enemy.armor=0;Combat.step(s);check(s.weapon_guard==1 and s.guard_hp==8 and s.bastion_used,"Boss renews guard below half health")
 s=state(7.8,1,true);var before=var_to_bytes(s);var forecast=Combat.predict(s);check(before==var_to_bytes(s),"Forecast does not mutate guard or fraction state")
 var restored=bytes_to_var(var_to_bytes(s));check(forecast==Combat.predict(restored),"Guard and fractional damage survive save roundtrip")
 var legacy=state(7.8,1,true);legacy.build.erase("fair_physical");legacy.weapon_guard=1;var previous=Combat.step(legacy);check(previous.damage==0 and legacy.weapon_guard==0,"Legacy battles retain one-hit guard")
 var g=load("res://main.tscn").instantiate();g.save_path="/private/tmp/fair_bomb_test";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.muted=true;g.skills={};g.new_run(42)
 var tile=g.pos+Vector2i.RIGHT;g.rooms[g.room].walls.erase(tile);var target=g.make_enemy(0,0);target.hp=0.4;g.rooms[g.room].entities[tile]=target;g.mode="bomb";g.bombs=1
 check(g.forecast(target).won,"Bomb forecast recognizes fractional health")
 g.game_throw_bomb(tile);check(not g.rooms[g.room].entities.has(tile) and g.bombs==0,"Bomb kills an enemy with fractional health")
 g.new_run(84);g.session.enabled=true;g.session.active=true;g.mode="fight";g.fight=g.make_enemy(3,3);g.fight.position=g.pos+Vector2i.RIGHT;g.battle=Combat.begin(g.fight,g.hp,g.max_hp,g.attack,g.armor,g.speed,g.relics,g.combat_build());g.battle.guard_hp=2.25;g.battle.enemy.hp=123.45
 check(g.session.checkpoint() and g.session.continue_run(),"Active modern combat saves and resumes")
 check(is_equal_approx(g.battle.guard_hp,2.25) and is_equal_approx(g.battle.enemy.hp,123.45) and g.battle.build.fair_physical,"Guard and fractional health preserved on resume")
 g.battle.build.erase("fair_physical");g.battle.erase("guard_hp");check(g.session.checkpoint() and g.session.continue_run() and not g.battle.build.has("fair_physical"),"Already-running legacy fight keeps its original guard rules")
 for suffix in [".run",".run.bak",".run.tmp"]:DirAccess.remove_absolute(g.save_path+suffix)
 g.free();print(JSON.stringify({"failures":failures}));quit(0 if failures.is_empty() else 1)
