extends SceneTree
var failures=[]
func check(ok: bool, message: String):
 if not ok: failures.append(message)
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();g.save_path="/private/tmp/magic-material-routes";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.career=g.replay.new_career();g.new_run(671)
 for material in g.smithy.MATERIALS:
  check(g.smithy.MATERIAL_ICONS.has(material) and g.icons.has(g.smithy.MATERIAL_ICONS[material]),"Material has a valid icon: "+material)
 g.smithy.data().blueprints.axe=true;g.mode="sanctuary";g.action("smithy_open");g.action("smithy_track:axe")
 var goal=g.smithy.goal_info();check(goal.entries.size()==2 and goal.entries[0].id=="ore" and goal.entries[1].id=="monster","Tracked recipe exposes material icons and counts")
 g.queue_redraw();await process_frame
 g.mode="branch";g.floor_flags["branch_stage"]="main";g.branch_paths.handle("branch_choose:mine")
 var room=g.rooms[g.branch_paths.ROOM];var deposits=0;var guardians=0
 for entity in room.entities.values():
  if entity.kind=="ore_deposit":deposits+=1
  if entity.kind=="enemy" and entity.get("gatekeeper",false):guardians+=1
 check(deposits==2 and guardians==1,"Mine has a guardian and two ore deposits")
 print(JSON.stringify({"failures":failures}));g.free();quit(0 if failures.is_empty() else 1)
