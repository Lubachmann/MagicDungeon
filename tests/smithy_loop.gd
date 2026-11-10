extends SceneTree
var failures=[]
func check(ok:bool,msg:String):
 if not ok:failures.append(msg)
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();g.save_path="/private/tmp/magic-smithy-loop";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.career=g.replay.new_career();g.new_run(42)
 check(g.run_rules==20 and g.equipped.has("weapon"),"New expedition starts with a sword")
 var c=g.smithy.cargo();c.ore=9;c.monster=8
 var item=g.make_gear("weapon",1,0,[],"axe");g.smithy.reward(item)
 check(not g.smithy.data().blueprints.has("axe"),"Blueprint stays in run cargo before returning")
 g.mode="play";g.room=Vector2i.ZERO;g.action("extract_prompt");check(g.mode=="extract","Extraction opens a dedicated confirmation");g.action("extract_cancel");check(g.mode=="play","Extraction can be cancelled");g.action("extract_prompt");g.action("extract_confirm")
 check(g.smithy.data().blueprints.has("axe"),"Extracted blueprint is kept")
 check(g.smithy.data().materials.ore==9,"Extracted ore is kept")
 check(g.career.deaths==0,"Extraction is not recorded as death")
 g.smithy.commit();check(g.smithy.data().materials.ore==9,"Cargo is committed once")
 g.mode="sanctuary";g.action("smithy_open");g.action("smithy_make:axe");g.action("smithy_equip:axe")
 check(g.smithy.data().items.get("axe",0)==1,"Axe crafted")
 check(g.smithy.data().loadout.weapon=="axe","Axe equipped in smithy")
 g.new_run(7);check(g.inventory[g.equipped.weapon].archetype=="axe","Next expedition uses crafted loadout")
 var before=g.equipped.duplicate();g.equipment_action("unequip_selected");check(g.equipped==before,"Loadout fixed during run")
 var rune_item=g.make_gear("weapon",1,0);rune_item["blueprint_element"]="fire"
 g.smithy.reward(rune_item);g.smithy.cargo().monster=3;g.finish_run(false);check(g.smithy.data().materials.monster==9,"Death keeps materials")
 check(g.smithy.data().elements.has("fire"),"Elemental blueprint survives death")
 g.mode="sanctuary";g.action("smithy_open");g.action("smithy_runes:axe");g.action("smithy_infuse:fire")
 check(g.smithy.data().infusions.get("axe","")=="fire","Discovered rune infuses crafted equipment")
 g.new_run(8);check(g.inventory[g.equipped.weapon].get("infusion","")=="fire","Infusion carries into next expedition")
 g.session.enabled=true;g.session.active=true;g.new_run(99);g.smithy.cargo().ore=7
 check(g.session.checkpoint(),"Run cargo can be checkpointed")
 g.smithy.cargo().ore=0;check(g.session.continue_run() and g.smithy.cargo().ore==7,"Run cargo survives continue")
 g.finish_run(false);var kept=int(g.smithy.data().materials.ore);g.load_progress();check(g.smithy.data().materials.ore==kept,"Permanent materials survive profile reload")
 g.session.enabled=false
 for suffix in ["", ".run", ".run.bak", ".run.tmp", ".tmp"]:DirAccess.remove_absolute(g.save_path+suffix)
 print(JSON.stringify({"failures":failures}));g.free();quit(0 if failures.is_empty() else 1)
