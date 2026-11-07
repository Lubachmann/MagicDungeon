extends SceneTree
var failures=[]
func check(ok:bool,msg:String):
 if not ok:failures.append(msg)
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();g.save_path="/private/tmp/magic-inline-forge";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.muted=true;g.skills={}
 for seed in range(30):
  g.new_run(seed+700);var forges=[]
  for coord in g.rooms:
   for tile in g.rooms[coord].entities:
    if g.rooms[coord].entities[tile].kind=="salvage":forges.append([coord,tile])
  check(not forges.is_empty(),"A forge is available")
  if forges.is_empty():continue
  g.room=forges[0][0];g.pos=forges[0][1]
  var dagger=g.make_gear("weapon",1,0,[],"dagger");dagger.plain=true
  var spare=g.make_gear("helmet",1,1,["health"])
  g.inventory=[dagger,spare];g.equipped={"weapon":0};g.selected_item=0;g.iron=5;g.recalculate_stats();g.open_equipment()
  g.queue_redraw();await process_frame;await process_frame
  var ids=[];for button in g.buttons:ids.append(button.id)
  check(ids.has("iron_selected") and ids.has("infuse_open") and ids.has("help:scrap"),"Upgrade, imprint and scrap are visible directly in equipment")
  check(not ids.has("forge_open"),"No separate forge tab is shown")
  check(g.session.valid(g.session.snapshot()),"Equipment screen is saveable")
  var upgraded=dagger.duplicate(true);upgraded.level+=1;var expected=g.Gear.stats(upgraded)
  g.action("iron_selected");check(g.inventory[0].level==2 and g.iron==4 and g.mode=="equipment" and g.Gear.stats(g.inventory[0])==expected,"Upgrade uses one iron and applies the previewed item stats")
  g.action("infuse_open");check(g.mode=="infuse","Imprint opens from equipment")
  g.action("infuse:ice");check(g.mode=="equipment" and g.inventory[0].infusion=="ice" and g.iron==4,"Free imprint applies and returns to equipment")
  g.action("salvage_selected");check(g.inventory.size()==2,"Equipped items cannot be scrapped")
  g.selected_item=1;g.equipment_slot="helmet";g.inventory[1]["kept"]=true;g.action("salvage_selected");check(g.inventory.size()==2,"Protected gear cannot be scrapped")
  g.inventory[1]["kept"]=false;g.action("salvage_selected")
  check(g.inventory.size()==1 and g.iron_fragments==2 and g.salvage_charges==2,"Spare rare gear scraps to fragments")
 # Craft actions cannot be used remotely by calling them directly.
 g.new_run(900);g.inventory=[g.make_gear("weapon",1,0)];g.equipped={"weapon":0};g.selected_item=0;g.iron=4;g.mode="equipment";g.room=Vector2i.ZERO;g.pos=Vector2i(2,5)
 for tile in g.rooms[g.room].entities.keys():
  if g.rooms[g.room].entities[tile].kind=="salvage":g.rooms[g.room].entities.erase(tile)
 g.action("iron_selected");g.action("infuse_open")
 check(g.inventory[0].level==1 and g.iron==4 and g.mode=="equipment","Remote crafting is blocked")
 # Existing saved forge screens migrate to the direct equipment interface.
 g.mode="forge";g.run_metrics["forge_tab"]="infuse";g.session.enabled=true;g.session.active=true
 check(g.session.checkpoint() and g.session.continue_run() and g.mode=="equipment","Old forge-screen save opens in equipment")
 g.session.enabled=false
 for suffix in [".run",".run.bak",".run.tmp"]:DirAccess.remove_absolute(g.save_path+suffix)
 print(JSON.stringify({"failures":failures}));g.free();quit(0 if failures.is_empty() else 1)
