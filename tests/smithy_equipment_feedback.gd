extends SceneTree
var failures=[]
func check(ok: bool, message: String):
 if not ok:failures.append(message)
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();g.save_path="/private/tmp/magic-equipment-feedback";root.add_child(g);await process_frame
 g.session.enabled=false;g.set_process(false);g.career=g.replay.new_career();var p=g.smithy.data()
 p.blueprints.dagger=true;p.blueprints.dagger_keen=true;p.items.dagger=1;p.items.dagger_keen=1;p.elements.fire=true;p.elements.ice=true;p.materials.ore=40;p.materials.monster=40
 check(g.smithy.blueprint_count(p)==3 and g.smithy.blueprint_count(p,"weapon")==3,"Blueprint collection counts discovered recipes by slot")
 var presenter=load("res://equipment_presenter.gd")
 var normal=presenter.numbers(g.smithy.make_item("dagger",1));var keen=presenter.numbers(g.smithy.make_item("dagger_keen",1))
 check(is_equal_approx(float(keen.crit_chance)-float(normal.crit_chance),0.05),"Keen dagger grants 5 percentage points more crit chance")
 check(presenter.comparison_keys(normal,keen)[0]=="crit_chance","Keen difference is the first comparison row")
 g.mode="sanctuary";g.action("smithy_open");g.action("smithy_select:dagger_keen");g.queue_redraw();await process_frame
 g.action("smithy_runes:dagger_keen");g.queue_redraw();await process_frame
 var ore=int(p.materials.ore);var parts=int(p.materials.monster);g.action("smithy_infuse:fire")
 check(p.infusions.get("dagger_keen","")=="fire" and g.smithy.infusion_item=="dagger_keen" and "Applied:" in g.smithy.message,"Successful infusion stays visible with explicit confirmation")
 var fire=presenter.numbers(g.smithy.make_item("dagger_keen",1,"fire"));check(float(fire.get("fire_power",0))>float(keen.get("fire_power",0)),"Rune changes the actual item stats")
 check(p.materials.ore==ore-3 and p.materials.monster==parts-2,"Infusion charges displayed materials once")
 ore=int(p.materials.ore);parts=int(p.materials.monster);g.action("smithy_infuse:fire")
 check(p.materials.ore==ore and p.materials.monster==parts,"Reapplying the same rune never charges again")
 g.queue_redraw();await process_frame;g.action("smithy_back");g.queue_redraw();await process_frame
 g.action("smithy_runes:dagger_keen");g.action("smithy_infuse:ice");check(p.infusions.dagger_keen=="ice","A different discovered rune can replace the old one")
 p.loadout.weapon="dagger_keen";g.new_run(10);check(g.inventory[g.equipped.weapon].infusion=="ice","Selected rune affects the next run")
 g.replay.draft.mode="standard";g.loadout_menu.open("expedition");g.action("loadout_select:dagger");g.queue_redraw();await process_frame
 g.mode="sanctuary";g.action("smithy_open");g.action("smithy_runes:dagger_keen");g.session.enabled=true;g.session.active=false
 g.action("smithy_infuse:fire");g.load_progress();check(g.smithy.data().infusions.get("dagger_keen","")=="fire","Applied rune persists through profile reload")
 g.session.enabled=false
 for suffix in ["", ".tmp", ".run", ".run.bak", ".run.tmp"]:DirAccess.remove_absolute(g.save_path+suffix)
 print(JSON.stringify({"failures":failures}));g.free();quit(0 if failures.is_empty() else 1)
