extends SceneTree
var failures=[]
func check(ok:bool,msg:String):
 if not ok:failures.append(msg)
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();g.save_path="/private/tmp/magic-tracked-goal";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.career=g.replay.new_career();g.new_run(45)
 var p=g.smithy.data();p.blueprints.axe=true;p.materials.ore=1;p.materials.monster=1
 g.mode="sanctuary";g.action("smithy_open");g.action("smithy_track:axe");var goal=g.smithy.goal_info()
 check(goal.title=="Axe" and not goal.ready and goal.sources.size()==2,"Recipe tracks shortages and material sources")
 g.mode="play";var c=g.smithy.cargo();c.ore=2;c.monster=1;check(g.smithy.goal_info(true).ready,"Current run cargo counts towards the goal")
 g.run_settings.mode="daily";check(not g.smithy.goal_info(true).ready,"Daily cargo does not count as retained progress")
 g.run_settings.mode="standard";g.smithy.commit();check(g.smithy.goal_info().ready,"Returned materials count exactly once")
 g.mode="sanctuary";g.action("smithy_open");g.action("smithy_make:axe");check(g.smithy.goal_info().finished,"Crafted goal is completed")
 p.materials.ore=100;p.materials.monster=100;p.materials.boss=5;g.action("smithy_track_slot:weapon");g.action("smithy_upgrade_slot:weapon");check(g.smithy.goal_info().finished,"Tracked slot goal completes at intended level")
 g.session.enabled=true;g.session.active=false;g.action("smithy_track_slot:weapon");g.load_progress();check(g.smithy.goal_info().title=="Weapon slot" and not g.smithy.goal_info().finished,"Tracked goal survives profile reload")
 g.action("smithy_untrack");check(g.smithy.goal_info().is_empty(),"Tracking can be cleared")
 g.session.enabled=false
 for suffix in ["", ".tmp", ".run", ".run.bak", ".run.tmp"]:DirAccess.remove_absolute(g.save_path+suffix)
 print(JSON.stringify({"failures":failures}));g.free();quit(0 if failures.is_empty() else 1)
