extends SceneTree
const Stats=preload("res://build_stats.gd")
const Pace=preload("res://combat_pacing.gd")
const Offers=preload("res://skill_offers.gd")
var failures=[]
var checks=0
func check(ok:bool,why:String):
 checks+=1
 if not ok:failures.append(why)
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();g.save_path="/private/tmp/magic-commitment-test";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.new_run(72)
 check(g.run_rules==18,"New runs use the commitment balance")
 g.inventory=[g.make_gear("weapon",1,0,[],"dagger")];g.equipped={"weapon":0};g.character_level=1;g.recalculate_stats()
 var d0=Stats.calculate(g);var d1=Stats.upgrade_preview(g,"haste")
 check(is_equal_approx(d0.interval-d1.interval,0.15),"Quick hands subtracts 0.15 seconds from a dagger")
 g.relics=["haste"];g.recalculate_stats();check(is_equal_approx(Pace.preview_interval(g,g.inventory[0]),1.0/g.speed),"Weapon preview matches actual speed with Quick hands")
 g.relics=[];g.inventory[0]=g.make_gear("weapon",1,0,[],"axe");g.recalculate_stats()
 var a0=Stats.calculate(g);var a1=Stats.upgrade_preview(g,"haste")
 check(is_equal_approx(a0.interval-a1.interval,0.15) and d0.interval/d1.interval>a0.interval/a1.interval,"Interval reduction favors the dagger")
 var heavy=Stats.upgrade_preview(g,"heavy_momentum")
 check(is_equal_approx(heavy.attack/a0.attack,1.45) and is_equal_approx(heavy.speed/a0.speed,0.8),"Heavy momentum trades speed for physical damage")
 check(is_equal_approx(heavy.fire,a0.fire),"Heavy momentum does not multiply fire damage")
 g.inventory[0]=g.make_gear("weapon",1,0,[],"dagger");g.recalculate_stats();var plain=Stats.calculate(g);var wrong=Stats.upgrade_preview(g,"heavy_momentum")
 check(is_equal_approx(plain.attack,wrong.attack) and is_equal_approx(plain.speed,wrong.speed),"Heavy momentum does not affect daggers")
 g.character_level=11;g.recalculate_stats();var lv=Stats.calculate(g);g.character_level=1;g.recalculate_stats();var start=Stats.calculate(g)
 check(is_equal_approx(lv.armor-start.armor,2.1) and is_equal_approx(lv.attack-start.attack,3.075),"Automatic growth slows after the first three level-ups")
 g.reward_level=8;g.rng.seed=91
 var future=Offers.pool(g);check("glacial_crusher" in future and "toxic_harvest" in future,"Future build skills can appear without their conditions")
 for i in range(100):
  var pick=Offers.choose(g);check(pick.any(func(id):return id in ["precision","ruin","leech","ward","bloom","spark"]),"One modest fallback remains while available")
 var e1=g.make_enemy(1,2);g.floor_number=5;var e5=g.make_enemy(1,2)
 check(e5.attack>e1.attack and e5.armor>e1.armor,"Late floor opponents scale their offense and armor")
 g.run_rules=17;g.floor_number=1;g.character_level=11;g.relics=[];g.recalculate_stats();var old=Stats.calculate(g)
 check(old.attack>lv.attack and old.armor>lv.armor,"Version 17 runs retain their growth")
 print(JSON.stringify({"checks":checks,"failures":failures}));g.free();quit(0 if failures.is_empty() else 1)
