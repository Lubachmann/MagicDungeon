extends SceneTree
var failures=[]
func check(value: bool,message: String):
 if not value:failures.append(message)
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();g.save_path="res://tests/.rarity_test";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.muted=true;g.skills={}
 for seed in range(40):
  preload("res://tools/historical_run.gd").start(g,seed+300,18);var found=[]
  for coord in g.rooms:
   for tile in g.rooms[coord].entities:
    if g.rooms[coord].entities[tile].kind=="salvage":found.append([coord,tile])
  check(found.size()==1,"Exactly one forge seed %d"%seed)
  if found.is_empty():continue
  g.room=found[0][0];g.puzzle_tile=found[0][1];g.mode="decision"
  var item=g.make_gear("weapon",1,0,[],"dagger");item.plain=true;g.inventory=[item];g.equipped={"weapon":0};g.iron=3;g.recalculate_stats()
  var altar=g.rarity_altar;altar.handle("rarity_item:0");var choices=altar.options(0)
  check(choices.size()==3 and choices==altar.options(0),"Three stable options")
  check(choices.any(func(x):return x in ["speed","crit_chance","crit_mult"]),"Weapon-relevant choice")
  var choice=choices[0];altar.handle("rarity_bonus:"+choice);var before=g.inventory[0].duplicate(true);var preview=altar.proposed(0,choice);var expected=g.Gear.stats(preview)
  check(g.session.valid(g.session.snapshot()),"Session can save altar decision")
  altar.handle("rarity_commit")
  check(g.mode=="equipment" and g.iron==2 and g.inventory[0].rarity==1 and g.inventory[0].level==before.level and g.inventory[0].plain and g.inventory[0].affixes==[choice],"Upgrade spends iron and preserves dagger")
  check(g.Gear.stats(g.inventory[0])==expected,"Item stats match preview")
  check(g.forge_menu.used("rarity"),"Rarity upgrade consumed exactly once")
 var presenter=preload("res://equipment_presenter.gd")
 check(presenter.value("armor",{"armor":2.65})=="+2.6" or presenter.value("armor",{"armor":2.65})=="+2.7","Armor displays one decimal")
 check(presenter.value("base_interval",{"base_interval":0.87})=="0.87s","Attack intervals preserve useful precision")
 g.free();print(JSON.stringify({"failures":failures}));quit(0 if failures.is_empty() else 1)
