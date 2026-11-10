extends SceneTree
# Saved rules 19 contract; current expeditions are covered by the Hearth suites.
var checks=0
var failures=[]
func check(ok:bool,message:String):
 checks+=1
 if not ok:failures.append(message)
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();g.save_path="/private/tmp/magic-equipment-curve-update";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);preload("res://tools/historical_run.gd").start(g,42,19)
 check(g.run_rules==19,"New run uses updated rules")
 for floor_num in range(1,6):
  g.floor_number=floor_num
  for tier in range(1,7):
   var e=g.make_enemy(0,1,tier);var n=float(e.level-1)
   check(e.hp==ceili(12+13*n+n*n),"Health curve level %d"%e.level)
   check(e.attack==ceili(3+n+0.2*n*n),"Attack curve level %d"%e.level)
 check(g.replay.relic_icon("ruin")=="crit_damage","Ruin prism has critical damage icon")
 check(g.UPGRADE_INFO.ferocity[2]=="crit_damage","Ruin edge has critical damage icon")
 var item=g.make_gear("weapon",1,0);check("weapon_dps" not in preload("res://equipment_presenter.gd").affected({},item),"Weapon comparison omits DPS")
 g.inventory=[item];g.selected_item=0;g.open_equipment();g.queue_redraw();await process_frame;await process_frame
 check(g.mode=="equipment","Equipment screen renders")
 print(JSON.stringify({"checks":checks,"failures":failures}));g.free();quit(0 if failures.is_empty() else 1)
