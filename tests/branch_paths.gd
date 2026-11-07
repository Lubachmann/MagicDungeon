extends SceneTree
var g
var failures=[]
var checks=0
func check(ok:bool,msg:String):
 checks+=1
 if not ok and failures.size()<30:failures.append(msg)
func _initialize():call_deferred("run")
func run():
 g=load("res://main.tscn").instantiate();g.save_path="/private/tmp/magic-branch-test";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false)
 var route_ids=["weapon","armor","fire","ice","acid","poison","vault","rest"]
 for seed in range(25):
  for choice in route_ids:
   g.new_run(seed);g.room=Vector2i.ZERO;g.pos=Vector2i(1,5);g.game_move_player(Vector2i.LEFT)
   check(g.mode=="branch" and not g.rooms.has(Vector2i(-1,0)),"Threshold opens an uncommitted choice")
   check(g.session.valid(g.session.snapshot()),"Pending route choice is saveable")
   g.queue_redraw();await process_frame
   g.action("branch_leave");check(g.mode=="play" and not g.floor_flags.has("branch_choice"),"Leaving permits a later decision")
   g.game_move_player(Vector2i.LEFT);g.action("branch_choose:"+choice)
   var coord=Vector2i(-1,0);var data=g.rooms[coord]
   check(g.room==coord and g.mode=="play" and g.floor_flags.branch_choice==choice,"Choosing enters the chosen passage")
   check(g.session.valid(g.session.snapshot()),"Chosen passage is saveable")
   check(g.boss_room in g.dungeon_threads.distances_from(Vector2i.ZERO),"The boss route remains accessible")
   if choice=="rest":
    check(data.entities.get(Vector2i(4,5),{}).get("kind","")=="rest_site" and not data.entities.has(Vector2i(9,3)),"Rest path has its promised rewards")
   else:
    var chest=data.entities.get(data.chest,{})
    check(chest.get("kind","")=="chest" and data.entities.get(chest.get("guardian",Vector2i.ZERO),{}).get("kind","")=="enemy","Guardian blocks reward")
    if choice=="weapon":check(chest.item.slot=="weapon","Weapon route yields a weapon")
    if choice=="armor":check(chest.item.slot in ["armor","helmet","shield"],"Armor route yields defensive gear")
    if choice in ["fire","ice","acid","poison"]:check(g.branch_paths.AFFIX[choice] in chest.item.affixes,"Elemental route gives the chosen element")
    if choice=="vault":check(chest.tier==2 and chest.item.rarity>=1 and data.entities[chest.guardian].elite,"Vault rewards a tougher guardian with high tier loot")
   g.queue_redraw();await process_frame
   g.pos=Vector2i(11,5);g.game_move_player(Vector2i.RIGHT)
   check(g.room==Vector2i.ZERO,"Player can return to the main floor")
   g.pos=Vector2i(1,5);g.game_move_player(Vector2i.LEFT)
   check(g.room==coord and g.floor_flags.branch_choice==choice,"Returning preserves the same route")
   if seed==0:
    var snap=g.session.snapshot().duplicate(true);check(g.session.valid(snap),"Passage snapshot validates")
 for floor in range(1,6):
  g.new_run(300+floor)
  for previous in range(1,floor):g.mode="floor";g.ascend_floor()
  g.pos=Vector2i(1,5);g.game_move_player(Vector2i.LEFT);g.action("branch_choose:fire")
  var route_chest=g.rooms[Vector2i(-1,0)].entities[Vector2i(3,5)]
  check(g.floor_number==floor and route_chest.item.level>=g.loot_level(floor),"Route rewards scale with the current floor")
  if floor<5:
   g.mode="floor";g.ascend_floor()
   check(not g.floor_flags.has("branch_choice") and not g.rooms.has(Vector2i(-1,0)),"A new floor resets the passage choice")
 g.new_run(122);g.session.enabled=true;g.session.active=true;g.pos=Vector2i(1,5);g.game_move_player(Vector2i.LEFT);g.action("branch_elements")
 check(g.session.checkpoint(),"Uncommitted route selection is saved")
 g.mode="play";check(g.session.continue_run() and g.mode=="branch" and g.floor_flags.branch_stage=="elements","Continue restores the route selection")
 g.action("branch_choose:ice");var chosen_item=g.rooms[Vector2i(-1,0)].entities[Vector2i(3,5)].item.duplicate(true)
 check(g.session.checkpoint(),"Chosen route is saved")
 g.rooms.clear();check(g.session.continue_run() and g.room==Vector2i(-1,0) and g.floor_flags.branch_choice=="ice" and g.rooms[g.room].entities[Vector2i(3,5)].item==chosen_item,"Continue preserves route and treasure")
 g.session.enabled=false
 for suffix in ["", ".tmp", ".run", ".run.bak", ".run.tmp"]:DirAccess.remove_absolute(g.save_path+suffix)
 print(JSON.stringify({"checks":checks,"failures":failures}));g.free();quit(0 if failures.is_empty() else 1)
