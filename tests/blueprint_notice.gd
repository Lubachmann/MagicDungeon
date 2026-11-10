extends SceneTree
var failures=[]
func check(ok:bool,msg:String):
 if not ok:failures.append(msg)
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();g.save_path="/private/tmp/blueprint-notice";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.career=g.replay.new_career();g.new_run(42)
 var axe=g.make_gear("weapon",1,0,[],"axe");g.smithy.reward(axe)
 check(g.smithy.notices.size()==1 and g.smithy.notices[0].id=="axe" and g.mode=="play","New equipment triggers a nonblocking notice")
 g.smithy.reward(axe);check(g.smithy.notices.size()==1,"Duplicate does not trigger a new blueprint notice")
 var rune=axe.duplicate();rune.blueprint_element="fire";g.smithy.reward(rune)
 check(g.smithy.notices.size()==2 and g.smithy.notices[1].kind=="rune","Rune notice is queued")
 g.queue_redraw();await process_frame
 g.smithy.tick_notices(3.6);check(g.smithy.notices.size()==1 and g.smithy.notices[0].id=="fire","Next notice displays after first expires")
 g.mode="pause";g.smithy.tick_notices(5);check(g.smithy.notices.size()==1,"Notice waits while gameplay is paused")
 g.mode="play";g.smithy.tick_notices(3.6);check(g.smithy.notices.is_empty(),"Notice disappears automatically")
 g.new_run(43);check(g.smithy.notices.is_empty(),"New expedition clears stale notices")
 print(JSON.stringify({"failures":failures}));g.free();quit(0 if failures.is_empty() else 1)
