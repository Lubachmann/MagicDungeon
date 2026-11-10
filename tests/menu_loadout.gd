extends SceneTree
var failures=[]
func check(ok:bool,msg:String):
 if not ok:failures.append(msg)
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();g.save_path="/private/tmp/magic-menu-loadout";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.career=g.replay.new_career();g.mode="title"
 g.queue_redraw();await process_frame;check(g.buttons.any(func(b):return b.id=="smithy_open"),"Smithy is accessible from main menu")
 g.action("smithy_open");check(g.mode=="smithy" and g.smithy.return_mode=="title","Smithy opens directly from menu")
 g.queue_redraw();await process_frame
 for slot in g.Gear.SLOTS:check(g.buttons.any(func(b):return b.id=="smithy_tab:"+slot),"Smithy has "+slot+" tab")
 check(not g.buttons.any(func(b):return b.id.begins_with("smithy_equip:")),"Smithy does not equip items")
 g.action("smithy_back");g.action("expedition");g.action("expedition_start");check(g.mode=="loadout","Starting an expedition requires equipment preparation")
 g.queue_redraw();await process_frame
 for slot in g.Gear.SLOTS:check(g.buttons.any(func(b):return b.id=="loadout_slot:"+slot),"Loadout has "+slot+" slot")
 var p=g.smithy.data();p.blueprints.axe=true;p.items.axe=1
 g.action("loadout_select:axe");g.action("loadout_equip");check(p.loadout.weapon=="axe","Crafted weapon can be selected for the run")
 g.action("loadout_slot:shield");g.action("loadout_select:axe");g.action("loadout_equip");check(not p.loadout.has("shield"),"Items cannot be equipped in the wrong slot")
 g.action("loadout_back");g.replay.draft.mode="daily";g.action("expedition_start");check(g.mode=="loadout" and g.loadout_menu.is_daily(),"Daily runs show the fixed loadout screen")
 g.action("loadout_select:axe");g.action("loadout_equip");check(p.loadout.weapon=="axe","Daily equipment does not alter saved loadout")
 g.action("loadout_start");check(g.mode=="play" and g.inventory[g.equipped.weapon].archetype=="balanced","Daily expedition starts with fixed sword")
 g.mode="dead";g.session.enabled=true;g.session.active=false;g.action("restart");check(g.mode=="loadout","Again also requires equipment preparation")
 g.session.enabled=false
 for suffix in ["", ".tmp", ".run", ".run.bak", ".run.tmp"]:DirAccess.remove_absolute(g.save_path+suffix)
 print(JSON.stringify({"failures":failures}));g.free();quit(0 if failures.is_empty() else 1)
