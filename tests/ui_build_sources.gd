extends SceneTree
var failures=[]
func check(ok: bool,message: String):
 if not ok:failures.append(message)
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();g.save_path="/private/tmp/magic-ui-summary";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.career=g.replay.new_career();g.new_run(93)
 var p=g.smithy.data();p.blueprints.shield=true;p.items.shield=1;p.loadout.shield="shield";p.elements.fire=true;p.infusions.sword="fire"
 g.replay.draft.mode="standard";g.loadout_menu.open("expedition")
 var before=var_to_bytes([g.inventory,g.equipped,g.rng.state,p]);var summary=g.loadout_menu.summary_data()
 check(summary.items.size()==2 and summary.items.weapon.infusion=="fire" and summary.totals.armor>0,"Summary combines crafted items and their runes")
 check(before==var_to_bytes([g.inventory,g.equipped,g.rng.state,p]),"Build summary does not change the saved loadout or run")
 g.action("loadout_summary");check(g.loadout_menu.summary_open,"Summary opens from loadout");g.queue_redraw();await process_frame
 g.action("loadout_back");check(not g.loadout_menu.summary_open and g.mode=="loadout","Back closes summary without leaving preparation")
 g.replay.draft.mode="daily";summary=g.loadout_menu.summary_data();check(summary.items.size()==1 and summary.items.weapon.level==1 and not summary.items.weapon.has("infusion"),"Daily summary shows only the fixed sword")
 g.replay.draft.mode="standard";g.skills={"kindling":1,"vigor":2,"might":1};var forecast=g.loadout_menu.summary_data().stats
 g.new_run(94);check(g.max_hp==forecast.max_hp and is_equal_approx(g.attack,forecast.attack) and is_equal_approx(g.armor,forecast.armor),"Starting-stat forecast matches the actual next expedition")
 g.mode="sanctuary";g.action("smithy_open");g.action("smithy_track:dagger_keen");var goal=g.smithy.goal_info();check(goal.sources.size()>=3,"Unmet blueprint and multiple material sources remain available")
 g.mode="expedition";g.action("expedition_goal_source");check(g.replay.goal_source_page==1,"Expedition can cycle sources");g.queue_redraw();await process_frame
 g.mode="character";g.action("journal_goal_source");check(g.journal_source_page==1,"Journal can cycle sources");g.queue_redraw();await process_frame
 print(JSON.stringify({"failures":failures}));g.free();quit(0 if failures.is_empty() else 1)
