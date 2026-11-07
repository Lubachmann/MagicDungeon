extends SceneTree
var failures=[]
func check(v:bool,msg:String):
 if not v:failures.append(msg)
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();g.save_path="res://tests/.heal_test";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.muted=true;g.skills={};g.new_run(123)
 g.hp=1;var max_hp=g.max_hp;var healed=g.summary.healed;g.mode="floor";g.ascend_floor()
 check(g.hp==mini(max_hp,1+ceili(max_hp*0.6)) and g.summary.healed==healed+mini(max_hp-1,ceili(max_hp*0.6)) and g.floor_number==2,"Ascent restores 60% max health and records recovery")
 check(g.bombs==0 and not g.controls.bindings.has("bomb"),"Bombs and their controls are absent in a new run")
 for room_data in g.rooms.values():
  for entity in room_data.entities.values():check(entity.get("kind","")!="bomb","Generated floors contain no bombs")
 check(g.icons.potion.resource_path.ends_with("/user_icons/healing_flask.png"),"Flask pickup uses the creator icon")
 g.hp=g.max_hp-1;g.mode="floor";g.ascend_floor();check(g.hp==g.max_hp,"Ascent healing is capped at maximum HP")
 var counts={"light":0,"heavy":0};g.rng.seed=19284
 for i in range(1000):
  g.floor_drop_index=posmod(2-g.floor_number,5)
  var item=g.chest_item(0)
  check(item.slot=="armor" and item.has("armor_class"),"Generated chest armor has a class")
  if item.has("armor_class"):counts[item.armor_class]+=1
 check(counts.light>400 and counts.heavy>400,"Both armor classes occur frequently")
 g.skills={"field_medicine":2};g.run_skills=g.skills.duplicate(true);g.hp=1;g.potions=1;g.mode="play";var previous=g.hp;g.action("heal")
 check(g.hp>previous,"Flask remains usable with Rekindle")
 g.free();print(JSON.stringify({"failures":failures,"armor_counts":counts}));quit(0 if failures.is_empty() else 1)
