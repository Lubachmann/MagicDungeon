extends SceneTree
var checks=0
var failures=[]
func check(ok:bool,message:String):
 checks+=1
 if not ok and failures.size()<25:failures.append(message)
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();g.save_path="/private/tmp/magic-enemy-curve";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.muted=true;g.skills={};g.new_run(42)
 check(g.run_rules==19,"New runs use updated scaling")
 g.run_rules=17 # The exact quadratic assertions below cover saved rules 17.
 var rows=[]
 for f in range(1,6):
  g.floor_number=f
  for tier in range(1,7):
   var level=6*(f-1)+tier;var n=float(level-1);var e=g.make_enemy(0,1,tier)
   check(e.level==level,"Enemy level is correct")
   check(e.hp==ceili(12+13*n+0.5*n*n),"Enemy health follows requested curve at level %d"%level)
   check(e.attack==ceili(3+n+0.1*n*n),"Enemy attack follows requested curve at level %d"%level)
   check(is_equal_approx(e.armor,0.5*n),"Enemy armor follows requested curve at level %d"%level)
   check(g.enemy_xp(e)==10+15*(level-1),"Enemy XP remains unchanged at level %d"%level)
   if tier in [1,6]:rows.append({"floor":f,"level":level,"hp":e.hp,"attack":e.attack,"armor":e.armor,"xp":g.enemy_xp(e)})
  var n=float(6*f-1);var boss=g.make_enemy(3,4);var high=g.make_enemy(1,1,6)
  check(boss.hp==ceili(220+190*(f-1)+45*(f-1)*(f-1)),"Boss health follows new floor curve")
  check(boss.hp>high.hp*1.8,"Boss has considerably more HP than high-level regular")
  check(boss.attack==ceili(maxf(11,1.2*(3+n+0.1*n*n)-2)),"Boss attack scales with the strongest ordinary tier")
  if f>1:check(boss.attack>high.attack,"Later boss deals more attack than the strongest standard enemy")
  check(is_equal_approx(boss.armor,0.5*n+0.5*(f-1)+(3 if boss.get("boss_kind","")=="iron" else 0)),"Boss armor scales with floor and boss type")
  check(g.enemy_xp(boss)==2*(10+15*int(n)),"Boss XP stays double its level reward")
  rows.append({"floor":f,"boss":true,"hp":boss.hp,"attack":boss.attack,"armor":boss.armor})
 g.floor_number=5;g.run_rules=15
 var legacy=g.make_enemy(0,1,6);var old_boss=g.make_enemy(3,4)
 check(legacy.hp==558 and legacy.attack==47 and is_equal_approx(legacy.armor,11.6),"Previous saved runs retain their ordinary enemy curve")
 check(old_boss.hp==900 and old_boss.attack==41,"Previous saved runs retain their boss curve")
 g.new_run(71);g.session.enabled=true;g.session.active=true
 check(g.session.checkpoint() and g.session.continue_run() and g.run_rules==19,"Updated rules survive save and continue")
 g.session.enabled=false
 for suffix in [".run",".run.bak",".run.tmp"]:DirAccess.remove_absolute(g.save_path+suffix)
 print(JSON.stringify({"checks":checks,"failures":failures,"examples":rows}));g.free();quit(0 if failures.is_empty() else 1)
