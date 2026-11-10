extends SceneTree
var failures=[]
func check(ok: bool,message: String):
 if not ok:failures.append(message)
func _initialize():call_deferred("run")
func redraw(g):
 g.queue_redraw();await process_frame
func run():
 var g=load("res://main.tscn").instantiate();g.save_path="/private/tmp/magic-ui-flow";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.career=g.replay.new_career();g.new_run(80)
 var p=g.smithy.data();p.blueprints.dagger=true;p.items.dagger=1;p.materials.ore=20;p.materials.monster=20
 g.mode="sanctuary";g.action("smithy_open");g.action("smithy_filter");check(g.smithy.FILTERS[g.smithy.filter_index]=="Craftable","Smithy filter cycles to craftable")
 check(not g.smithy.filtered_ids("weapon").has("sword"),"Craftable filter excludes owned equipment")
 g.action("smithy_filter");check(g.smithy.filtered_ids("weapon").has("dagger"),"Owned filter finds crafted item")
 await redraw(g);g.action("smithy_back");g.replay.draft.mode="standard";g.loadout_menu.open("expedition");g.action("loadout_slot:shield");await redraw(g)
 g.action("smithy_open");check(g.mode=="smithy" and g.smithy.return_mode=="loadout","Loadout opens smithy and preserves return destination")
 g.action("smithy_back");check(g.mode=="loadout","Smithy returns to preparation")
 g.mode="skills";g.bank=100;g.tree_spent=8;g.skills={"kindling":1};g.action("skills_reset")
 check(g.ember_tree.reset_pending and g.bank==100,"Reset asks for confirmation before refund")
 await redraw(g);g.action("skills_reset_cancel");check(not g.ember_tree.reset_pending and g.tree_spent==8,"Cancel preserves tree")
 g.action("skills_reset");g.action("skills_reset_confirm");check(g.bank==108 and g.skills.is_empty(),"Confirmed reset refunds the actual ledger")
 g.mode="character";g.relics=["precision","ruin"];await redraw(g);g.action("journal_relic:precision");check(g.journal_relic=="precision","Journal relics are selectable")
 g.mode="codex";g.replay.codex_page=0;g.action("codex_filter");check(g.replay.codex_found_only,"Chronicle can filter discoveries");await redraw(g)
 g.mode="expedition";await redraw(g);g.mode="settings";await redraw(g)
 g.mode="dead";await redraw(g);g.action("smithy_open");check(g.mode=="smithy" and g.smithy.return_mode=="dead","Return screen links to smithy")
 print(JSON.stringify({"failures":failures}));g.free();quit(0 if failures.is_empty() else 1)
