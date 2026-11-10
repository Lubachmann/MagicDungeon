extends SceneTree
var failures=[]
func check(ok:bool,msg:String):
 if not ok:failures.append(msg)
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();g.save_path="/private/tmp/magic-crafting-conversion";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.career=g.replay.new_career();g.new_run(73)
 g.branch_paths.create_room("ice")
 var room=g.rooms[Vector2i(-1,0)];var chest=room.entities[room.chest]
 check(chest.item.get("blueprint_element","")=="ice","Elemental passage offers its selected rune")
 g.room=Vector2i(-1,0);room.entities.erase(chest.guardian);check(g.open_chest(room.chest),"Elemental chest opens")
 check(g.smithy.cargo().elements.has("ice"),"Opening the chest records the selected rune")
 g.smithy.reward(chest.item);check(g.smithy.cargo().ore>0,"Repeated rune gives ore")
 var before=g.smithy.cargo().ore;var tile=Vector2i(3,5);g.room=Vector2i.ZERO;g.pos=Vector2i(2,5);g.mode="play";g.rooms[g.room].walls.erase(tile);g.rooms[g.room].entities[tile]={"kind":"ore_deposit"};g.move_player(Vector2i.RIGHT)
 check(g.smithy.cargo().ore>before,"Mining adds cargo")
 g.smithy.commit();g.mode="sanctuary";g.action("smithy_open");g.smithy.data().materials.ore=10;g.smithy.data().materials.monster=10
 g.action("smithy_runes:sword");g.action("smithy_infuse:ice");g.new_run(15)
 check(g.inventory[g.equipped.weapon].get("infusion","")=="ice","Selected rune is on the next loadout")
 check(float(g.Gear.stats(g.inventory[g.equipped.weapon]).get("frost_apply",0))>0,"Infusion actually grants frost power")
 var p=g.smithy.data();p.items["amulet"]=1;p.blueprints["amulet"]=true;p.loadout["amulet"]="amulet"
 g.new_run(1);var first=g.inventory[g.equipped.amulet].duplicate(true);g.new_run(2);var second=g.inventory[g.equipped.amulet]
 check(g.Gear.stats(first)==g.Gear.stats(second) and not first.has("amulet_focus"),"Crafted amulet stats remain stable between expeditions")
 g.mode="sanctuary";g.action("smithy_open");g.action("smithy_details:amulet");g.queue_redraw();await process_frame;check(g.smithy.detail_item=="amulet","Known blueprint details open")
 g.action("smithy_back");check(g.mode=="smithy" and g.smithy.detail_item=="","Details return to smithy")
 print(JSON.stringify({"failures":failures}));g.free();quit(0 if failures.is_empty() else 1)
