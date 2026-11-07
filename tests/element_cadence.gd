extends SceneTree
const Stats=preload("res://build_stats.gd")
const Elements=preload("res://element_rules.gd")
var failures=[]
func check(ok:bool,msg:String):
 if not ok:failures.append(msg)
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();g.save_path="res://tests/.cadence_test";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.muted=true;g.skills={};g.new_run(42)
 for weapon in ["dagger","balanced","axe"]:
  var item=g.make_gear("weapon",1,0,[],weapon);item.plain=true;g.inventory=[item];g.equipped={"weapon":0};g.base_elements={"fire":2,"ice":2,"acid":2,"poison":2};g.recalculate_stats()
  var stats=Stats.calculate(g);var build=g.combat_build();var expected={"dagger":1.0,"balanced":2.0,"axe":3.0}[weapon]
  for el in ["ice","acid","poison"]:
   check(is_equal_approx(Elements.potency(build,el),expected),weapon+" "+el+" per hit")
   check(is_equal_approx(stats.element_totals[el],expected),weapon+" "+el+" build preview")
   var next=Stats.upgrade_preview(g,el,true);check(is_equal_approx(next.element_totals[el]-stats.element_totals[el],expected/2),weapon+" "+el+" level preview")
  check(Elements.potency(build,"fire")==2,"Fire potency unaffected")
  var enemy=g.make_enemy(0,1);enemy.hp=100000;enemy.max=100000;enemy.armor=100;var battle=g.Combat.begin(enemy,500,500,g.attack,0,g.speed,[],build)
  Elements.on_hit(battle,g.attack,{});check(is_equal_approx(battle.poison_counters,expected) and is_equal_approx(battle.frost_counters,expected) and is_equal_approx(battle.acid_stacks,expected),weapon+" combat hit matches preview")
  var initial=Elements.potency(build,"poison");var baseline_rate=initial*g.speed;g.bonus.speed=0.5;g.recalculate_stats();check(is_equal_approx(Elements.potency(g.combat_build(),"poison"),initial),weapon+" attack speed does not change counters per hit");check(initial*g.speed>baseline_rate,weapon+" attack speed raises application per second");g.bonus.speed=0;g.recalculate_stats()
  check(is_equal_approx(initial*g.speed,1.0),weapon+" same baseline poison per second")
 g.inventory=[g.make_gear("weapon",1,0,[],"dagger"),g.make_gear("weapon",1,0,[],"axe")];g.equipped={"weapon":0};g.recalculate_stats();var after=Stats.prospective(g,1)
 check(is_equal_approx(after.poison,3.0) and is_equal_approx(g.combat_build().element_interval_scale,0.5),"Weapon comparison uses candidate base interval")
 var legacy={"ice":2,"acid":2,"poison":2};check(Elements.potency(legacy,"poison")==2,"Saved battles without multiplier retain original values")
 g.free();print(JSON.stringify({"failures":failures}));quit(0 if failures.is_empty() else 1)
