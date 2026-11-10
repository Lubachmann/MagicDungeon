extends SceneTree
var failures=[]
func check(ok:bool,msg:String):
 if not ok:failures.append(msg)
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();g.save_path="/private/tmp/blueprint-progression";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.career=g.replay.new_career();g.new_run(131)
 check(g.smithy.RECIPES.size()==40 and g.smithy.VARIANTS.size()==30,"Catalogue contains all base and variant blueprints")
 var sword=g.make_gear("weapon",1,2,[],"balanced");g.floor_number=1
 g.smithy.reward(sword);check(g.smithy.cargo().blueprints.is_empty(),"Floor 1 cannot roll later-floor variants")
 for f in [2,3,4]:
  g.floor_number=f;g.smithy.reward(sword)
  var wanted=["sword_keen","sword_swift","sword_bloodbound"][f-2]
  check(g.smithy.cargo().blueprints.has(wanted),"Correct floor makes variant available: "+wanted)
 g.smithy.commit();var p=g.smithy.data();p.materials.ore=100;p.materials.monster=100;p.materials.boss=5
 g.mode="sanctuary";g.action("smithy_open");g.action("smithy_make:sword_keen");check(not p.items.has("sword_keen"),"Crafting requires its specific material")
 p.materials.alloy=1;g.action("smithy_make:sword_keen");check(p.items.get("sword_keen",0)==1 and p.materials.alloy==0,"Rare crafting consumes correct material")
 g.action("smithy_equip:sword_keen");g.new_run(333);check(g.inventory[g.equipped.weapon].name=="Keen sword" and float(g.Gear.stats(g.inventory[g.equipped.weapon]).get("crit_chance",0))>0,"Crafted variant gives its promised bonus")
 g.career.workshop.materials.erase("essence");check(g.smithy.data().materials.essence==0,"Older workshop save gets new material fields")
 for entry in [[1,2,"alloy"],[2,3,"essence"],[0,4,"relic"]]:
  g.floor_number=entry[1];var enemy=g.make_enemy(entry[0],1,1);var tile=Vector2i(3,3);g.rooms[g.room].entities[tile]=enemy
  var before=int(g.smithy.cargo()[entry[2]]);g.defeat_enemy(tile,enemy);check(int(g.smithy.cargo()[entry[2]])==before+1,"Enemy drops "+entry[2])
 g.mode="sanctuary";g.action("smithy_open");g.action("smithy_tab:armor")
 check(g.smithy.tab=="armor" and g.smithy.category_ids("armor").size()==8,"Armor tab exposes its blueprint catalogue")
 g.queue_redraw();await process_frame
 print(JSON.stringify({"failures":failures}));g.free();quit(0 if failures.is_empty() else 1)
