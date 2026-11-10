extends SceneTree
var failures=[]
func check(ok:bool,msg:String):
 if not ok:failures.append(msg)
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();g.save_path="/private/tmp/magic-slot-progression";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.career=g.replay.new_career()
 var p=g.career.workshop;p.erase("slot_levels");p.items={"sword":3,"axe":5,"shield":2};p.blueprints.axe=true;p.loadout.weapon="sword"
 p=g.smithy.data();check(p.slot_levels.weapon==5 and p.slot_levels.shield==2 and p.slot_levels.armor==1,"Migration keeps highest existing item level in each slot")
 g.new_run(1);check(g.inventory[g.equipped.weapon].level==5,"Migrated level applies to existing equipment")
 g.mode="loadout";g.loadout_menu.slot="weapon";g.action("loadout_select:axe");g.action("loadout_equip");g.new_run(2)
 check(g.inventory[g.equipped.weapon].archetype=="axe" and g.inventory[g.equipped.weapon].level==5,"Switching weapons keeps shared slot level")
 g.career=g.replay.new_career();g.new_run(3);p=g.smithy.data();p.materials.ore=100;p.materials.monster=100;p.materials.boss=5;p.blueprints.axe=true
 g.mode="sanctuary";g.action("smithy_open");g.action("smithy_make:axe");var ore=int(p.materials.ore);g.action("smithy_make:axe");check(p.materials.ore==ore,"An owned item cannot be crafted twice")
 g.action("smithy_upgrade_slot:weapon");check(p.slot_levels.weapon==2,"Weapon slot can be upgraded")
 check(g.inventory[g.equipped.weapon].level==1,"Upgrading outside a run does not alter its equipment snapshot")
 p.loadout.weapon="axe";g.new_run(4);check(g.inventory[g.equipped.weapon].level==2,"New equipment inherits slot upgrades")
 g.replay.draft.mode="daily";g.new_run(5);check(g.inventory[g.equipped.weapon].level==1,"Daily fixed loadout ignores slot progression")
 print(JSON.stringify({"failures":failures}));g.free();quit(0 if failures.is_empty() else 1)
