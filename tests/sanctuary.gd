extends SceneTree
var checks=0
var failures=[]
func check(ok:bool,msg:String):
 checks+=1
 if not ok:failures.append(msg)
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();g.save_path="/private/tmp/magic-sanctuary-test";root.add_child(g);await process_frame;g.set_process(false);g.muted=true
 g.session.enabled=true;g.session.active=true;g.career=g.replay.new_career();g.replay.draft={"mode":"standard","vows":{}};g.new_run(44)
 check(g.sanctuary.active() and g.run_metrics.sanctuary_start.is_empty(),"Fresh runs start with an empty sanctuary snapshot")
 var found={}
 for coord in g.rooms:
  for tile in g.rooms[coord].entities:
   var entity=g.rooms[coord].entities[tile]
   if entity.kind=="sanctuary_discovery":found[entity.discovery]=[coord,tile]
 check(found.has("smith") and found.has("cartographer") and found.has("fire"),"First floor places people and fire discovery")
 check(not g.sanctuary.unlocked("smith") and "combustion" not in preload("res://skill_offers.gd").pool(g),"Future rewards are not active before discovery")
 for id in found:
  g.room=found[id][0];var tile=found[id][1];g.sanctuary.touch(tile,g.rooms[g.room].entities[tile])
 check(g.run_metrics.sanctuary_found.size()==3 and not g.sanctuary.unlocked("smith") and g.mode=="discovery","Discoveries show a message and are carried until the run ends")
 g.queue_redraw();await process_frame;await process_frame;check(g.buttons.any(func(b):return b.id=="discovery_continue"),"Discovery message has a continue action")
 check(g.session.checkpoint() and g.session.continue_run() and g.run_metrics.sanctuary_found.size()==3,"Carried discoveries survive save and continue")
 g.sanctuary.defeated({"type":3});check("1" in g.run_metrics.flame_found,"The first boss awards a fragment")
 g.mode="play";g.finish_run(false)
 check(g.career.sanctuary.discoveries.has("smith") and g.career.sanctuary.discoveries.has("cartographer") and g.career.sanctuary.fragments.has("1"),"Death returns discoveries and boss fragments")
 var saved=g.replay.clean_career(JSON.parse_string(FileAccess.get_file_as_string(g.save_path)).career)
 check(saved.sanctuary.discoveries.has("fire") and saved.sanctuary.fragments.has("1"),"Permanent discoveries are saved with the character")
 g.new_run(45);g.reward_level=8
 check(g.sanctuary.unlocked("smith") and g.sanctuary.unlocked("cartographer") and "combustion" in preload("res://skill_offers.gd").pool(g),"Returned discoveries unlock future runs")
 g.mode="branch";g.floor_flags.branch_stage="armory";g.action("branch_choose:weapon")
 check(g.mode=="branch" and g.floor_flags.branch_stage=="weapons","Mara lets the player choose a weapon type")
 g.action("branch_weapon:dagger");check(g.rooms[Vector2i(-1,0)].entities[Vector2i(3,5)].item.archetype=="dagger","The selected weapon appears behind the guardian")
 g.new_run(47);g.run_skills["tinkering"]=1;g.mode="branch";g.floor_flags.branch_stage="armory";g.action("branch_choose:armor")
 check(g.floor_flags.branch_stage=="armors","Tinkering and Mara unlock defensive equipment choices")
 g.action("branch_armor:helmet");check(g.rooms[Vector2i(-1,0)].entities[Vector2i(3,5)].item.slot=="helmet","The selected defensive item is behind the guardian")
 var bonus_found=false
 for i in range(500):
  var item=g.chest_item(1)
  if item.get("sanctuary_bonus","")=="fire":
   var low=g.Gear.stats(item).get("fire_power",0);item.level+=4;var high=g.Gear.stats(item).get("fire_power",0)
   check(high>low,"Discovered elemental bonuses grow when item level increases");bonus_found=true;break
 check(bonus_found,"Fire manuscript adds fire-touched gear to future treasure")
 g.mode="sanctuary";g.queue_redraw();await process_frame;await process_frame
 check(g.buttons.any(func(b):return b.id=="sanctuary_expedition"),"Hearth screen offers a route back to the dungeon")
 g.mode="play";g.room=Vector2i.ZERO;g.pos=Vector2i(2,5);g.floor_number=5;g.rooms[g.room].walls.erase(Vector2i(3,5));g.rooms[g.room].entities[Vector2i(3,5)]={"kind":"exit"};g.rooms[g.room].cleared=true
 g.move_player(Vector2i.RIGHT);check(g.mode=="ending","The fifth-floor exit leads to the final choice")
 check(g.session.checkpoint() and g.session.continue_run() and g.mode=="ending","Final choice survives save and continue")
 g.action("ending_choose:release");check(g.mode=="won" and g.career.sanctuary.ending=="release" and g.career.wins==1,"Ending choice records a real win")
 var old=g.replay.clean_career({"wins":1,"runs":3})
 check(old.sanctuary.discoveries.size()==6 and old.sanctuary.fragments.size()==5,"Existing characters retain prior unlocks and completed story milestones")
 g.session.enabled=false;g.career=g.replay.new_career();g.session.active=true
 for seed in range(30):
  g.new_run(1000+seed)
  for floor_number in range(1,5):
   if floor_number>1:g.floor_number=floor_number;g.generate_floor()
   var seen={}
   for coord in g.rooms:
    for tile in g.rooms[coord].entities:
     var e=g.rooms[coord].entities[tile]
     if e.kind=="sanctuary_discovery":
      seen[e.discovery]=true
      check(g.dungeon_threads.reachable(g.rooms[coord]).has(tile),"Discoveries are on accessible floor tiles")
   for id in g.sanctuary.DISCOVERIES:
    if g.sanctuary.DISCOVERIES[id].floor==floor_number:check(seen.has(id),"Each scheduled discovery is placed")
 g.session.enabled=false
 for suffix in ["", ".tmp", ".run", ".run.bak", ".run.tmp"]:DirAccess.remove_absolute(g.save_path+suffix)
 print(JSON.stringify({"checks":checks,"failures":failures}));g.free();quit(0 if failures.is_empty() else 1)
