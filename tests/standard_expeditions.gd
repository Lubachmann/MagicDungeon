extends SceneTree
var failures=[]
var checks=0
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures.append(label)
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();g.save_path="res://tests/.standard_expeditions";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.career=g.replay.new_career()
 for wins in [0,1]:
  g.career.wins=wins;g.mode="expedition";g.queue_redraw();await process_frame
  check(not g.buttons.any(func(b):return b.id in ["run_mode:daily","run_mode:endless"]),"Removed modes have no selector")
  for mode in ["daily","endless"]:
   g.action("run_mode:"+mode);check(g.replay.draft.mode=="standard","Old mode action remains Standard")
   g.replay.draft.mode=mode;g.action("expedition_start")
   check(g.replay.draft.mode=="standard" and not g.loadout_menu.is_daily(),"Stale selection opens Standard loadout")
   g.replay.draft.mode=mode;g.new_run(642)
   check(g.run_settings.mode=="standard" and g.run_seed==642 and g.floor_limit()==5,"New run is five-floor Standard with requested seed")
   g.mode="expedition"
 for mode in ["daily","endless"]:
  preload("res://tools/historical_run.gd").start_mode(g,83,mode)
  g.session.enabled=true;g.session.active=true;g.mode="play"
  check(g.session.checkpoint(),"Historical mode saves")
  g.run_settings.mode="standard"
  check(g.session.continue_run() and g.run_settings.mode==mode,"Historical active mode continues")
  check(g.floor_limit()==(0 if mode=="endless" else 5),"Historical floor limit survives")
  g.session.enabled=false
 print(JSON.stringify({"checks":checks,"failures":failures}));g.free();quit(0 if failures.is_empty() else 1)
