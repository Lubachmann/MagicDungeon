extends SceneTree
var failures=[]
var checks=0
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures.append(label)
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();g.save_path="res://tests/.expedition_rewards";root.add_child(g);await process_frame
 g.session.enabled=false;g.set_process(false);g.career=g.replay.new_career();g.new_run(987)
 for floor_num in range(1,6):
  g.floor_number=floor_num;g.generate_floor();var sites=[]
  for coord in g.rooms:
   for tile in g.rooms[coord].entities:
    var e=g.rooms[coord].entities[tile]
    if e.get("expedition_reward",false):sites.append([coord,tile,e])
  check(sites.size()==1,"Exactly one expedition reward per floor")
  var entry=sites[0];g.room=entry[0];g.puzzle_tile=entry[1];g.mode="decision"
  var e=entry[2];var element=str(e.reward_element);var before=int(g.base_elements[element])
  g.world_choices.handle("expedition_blessing")
  check(g.base_elements[element]==before+1 and e.used,"Blessing immediately changes the build")
  g.mode="decision";g.world_choices.handle("expedition_blessing")
  check(g.base_elements[element]==before+1,"Reward cannot be claimed twice")
 g.new_run(988);check(g.base_elements.fire==0 and g.base_elements.ice==0,"New expedition resets blessings")
 var site=g.world_choices.expedition_site();g.room=Vector2i.ZERO;g.puzzle_tile=Vector2i(3,3);g.rooms[g.room].entities[g.puzzle_tile]=site;g.mode="decision"
 g.session.enabled=true;g.session.active=true
 check(g.session.checkpoint() and g.session.continue_run(),"Pending reward survives checkpoint")
 check(g.rooms[g.room].entities[g.puzzle_tile]==site,"Saved options do not reroll")
 g.world_choices.handle("expedition_skill")
 check(site.reward_skill in g.relics or g.bonus.attack>0,"Skill reward applies immediately")
 check(g.session.checkpoint() and g.session.continue_run() and g.rooms[g.room].entities[g.puzzle_tile].used,"Claimed reward remains spent after loading")
 g.session.enabled=false
 for element in ["fire","ice","acid","poison"]:
  g.floor_flags={};g.branch_paths.create_room(element);var guardian=g.rooms[Vector2i(-1,0)].entities[Vector2i(7,5)]
  var before=int(g.base_elements[element]);g.world_choices.enemy_defeated(guardian);g.world_choices.enemy_defeated(guardian)
  check(g.base_elements[element]==before+1,"Passage grants one matching blessing")
 g.mode="decision";g.room=Vector2i.ZERO;g.puzzle_tile=Vector2i(3,3);g.rooms[g.room].entities[g.puzzle_tile]=g.world_choices.expedition_site()
 g.queue_redraw();await process_frame;await process_frame
 check(g.buttons.any(func(b):return b.id=="expedition_skill") and g.buttons.any(func(b):return b.id=="expedition_blessing"),"Reward choices render")
 g.free()
 for suffix in ["", ".tmp", ".run", ".run.bak", ".run.tmp"]:
  if FileAccess.file_exists("res://tests/.expedition_rewards"+suffix):DirAccess.remove_absolute("res://tests/.expedition_rewards"+suffix)
 print(JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
