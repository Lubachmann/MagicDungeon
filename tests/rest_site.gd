extends SceneTree
var g
var failures=[]
var checks=0
func check(ok:bool,why:String):
 checks+=1
 if not ok and failures.size()<20:failures.append(why)
func _initialize():call_deferred("run")
func site() -> Array:
 for coord in g.rooms:
  for tile in g.rooms[coord].entities:
   if g.rooms[coord].entities[tile].kind=="rest_site":return [coord,tile]
 return []
func interact(location:Array):
 g.room=location[0];g.mode="play"
 g.world_choices.touch(location[1],g.rooms[g.room].entities[location[1]])
func run():
 g=load("res://main.tscn").instantiate();g.save_path="/private/tmp/magic-rest-test";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.muted=true;g.skills={}
 var rooms_seen={}
 for seed in range(100):
  preload("res://tools/historical_run.gd").start(g,seed,18)
  for floor_number in range(1,6):
   var count=0
   for data in g.rooms.values():
    for e in data.entities.values():
     if e.kind=="rest_site":count+=1
   var location=site();check(count==1 and location.size()==2,"Exactly one rest site is placed per floor")
   if location.size()==2:
    var coord:Vector2i=location[0];var tile:Vector2i=location[1]
    check(coord!=Vector2i.ZERO and coord!=g.boss_room,"Rest site is outside the entrance and boss room")
    check(g.dungeon_threads.distances_from(Vector2i.ZERO).has(coord) and g.dungeon_threads.reachable(g.rooms[coord]).has(tile),"Rest site is reachable in its room without traversal tools")
    check(g.floor_flags.rest_room==coord,"Rest room is recorded for the floor");rooms_seen[coord]=true
   if floor_number<5:g.mode="floor";g.ascend_floor()
 check(rooms_seen.size()>=4,"Rest sites vary across rooms and seeds")
 preload("res://tools/historical_run.gd").start(g,42,18);var location=site();g.room=location[0];var tile:Vector2i=location[1];g.hp=20
 check("Rest" in g.map_features(g.room),"Map identifies the available rest site")
 var open=g.dungeon_threads.reachable(g.rooms[g.room]);var from=Vector2i(-1,-1)
 for direction in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
  if open.has(tile+direction) and not g.rooms[g.room].entities.has(tile+direction):from=tile+direction;break
 check(from.x>=0,"There is a free adjacent tile")
 g.pos=from;g.move_player(tile-from)
 check(g.mode=="decision" and g.pos==tile and g.session.valid(g.session.snapshot()),"Walking onto the site opens a saveable choice")
 g.action("decision_leave");check(g.mode=="play" and not g.rooms[g.room].entities[tile].used,"Leaving preserves the choice")
 interact(location);g.queue_redraw();await process_frame;await process_frame
 var ids=[];for button in g.buttons:ids.append(button.id)
 check(ids.has("rest_heal") and ids.has("rest_flask") and ids.has("rest_train") and ids.has("decision_leave"),"All three choices and leave are visible")
 var before=g.hp;var max_hp=g.max_hp;g.action("rest_heal")
 check(g.hp==mini(max_hp,before+ceili(max_hp*0.4)) and g.rooms[g.room].entities[tile].used and g.mode=="play","Rest heals 40% max HP and consumes the site")
 check("Rest" not in g.map_features(g.room),"Used rest site no longer appears as available")
 before=g.hp;interact(location);check(g.mode=="play" and g.hp==before,"Used site cannot heal twice")
 g.session.enabled=true;g.session.active=true
 check(g.session.checkpoint() and g.session.continue_run() and g.rooms[g.room].entities[tile].used,"Used site survives save and continue")
 g.session.enabled=false
 preload("res://tools/historical_run.gd").start(g,43,18);location=site();tile=location[1];g.hp=g.max_hp;interact(location);g.action("rest_heal")
 check(not g.rooms[g.room].entities[tile].used and g.mode=="decision","A full-health rest cannot accidentally consume the site")
 var old_flasks=g.potions;g.action("rest_flask")
 check(g.potions==old_flasks+1 and g.rooms[g.room].entities[tile].used,"Prepare gives one flask")
 preload("res://tools/historical_run.gd").start(g,44,18);location=site();tile=location[1];interact(location);var old_attack=g.bonus.attack;g.action("rest_train")
 check(g.bonus.attack==old_attack+2 and g.rooms[g.room].entities[tile].used,"Train gives two character power")
 preload("res://tools/historical_run.gd").start(g,45,18);location=site();tile=location[1];interact(location);g.session.enabled=true;g.session.active=true
 check(g.session.checkpoint() and g.session.continue_run() and g.mode=="decision" and not g.rooms[g.room].entities[tile].used,"Unchosen rest site survives saving in the choice screen")
 g.session.enabled=false
 g.action("decision_leave");g.run_rules=14;g.generate_floor();check(site().is_empty(),"Old rule sets keep their original floor generation")
 for suffix in [".run",".run.bak",".run.tmp"]:DirAccess.remove_absolute(g.save_path+suffix)
 print(JSON.stringify({"checks":checks,"rooms":rooms_seen.size(),"failures":failures}));g.free();quit(0 if failures.is_empty() else 1)
