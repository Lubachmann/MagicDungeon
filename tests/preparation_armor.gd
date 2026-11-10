extends SceneTree
var failures=[]
func check(ok:bool,msg:String):
 if not ok:failures.append(msg)
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();g.save_path="res://tests/.prep_test";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.muted=true
 for seed in range(30):
  g.new_run(seed+101);var found=[]
  for coord in g.rooms:
   for tile in g.rooms[coord].entities:
    if g.rooms[coord].entities[tile].kind=="boss_preparation":found.append([coord,tile])
  check(found.size()==1,"One preparation location for seed %d"%seed)
  if found.is_empty():continue
  var entry=found[0];g.room=entry[0];g.puzzle_tile=entry[1];g.mode="decision"
  var boss={}
  for e in g.rooms[g.boss_room].entities.values():
   if e.get("boss_kind","")!="":boss=e
  check(not boss.is_empty(),"Boss exists")
  if boss.is_empty():continue
  var armor=boss.armor;var attack=boss.attack;g.world_choices.handle("prepare_weaken")
  check(boss.armor==maxf(0,armor-4) and boss.attack==attack-1 and g.mode=="play","Preparation changes the actual boss once")
 g.new_run(900);g.room=Vector2i.ZERO;g.pos=Vector2i(2,5);g.mode="play";var tile=g.pos+Vector2i.RIGHT;g.rooms[g.room].walls.erase(tile);g.rooms[g.room].entities[tile]={"kind":"iron"};var ore=g.smithy.cargo().ore;g.game_move_player(Vector2i.RIGHT)
 check(g.mode=="play" and g.smithy.cargo().ore>ore and not g.rooms[g.room].entities.has(tile),"Ore is collected without opening equipment")
 g.pos=Vector2i(2,5);g.rooms[g.room].entities[tile]={"kind":"salvage"};g.game_move_player(Vector2i.RIGHT)
 check(g.mode=="play" and g.near_forge() and g.rooms[g.room].entities.has(tile),"Forge is walk-through and remains usable nearby")
 var base=g.make_gear("armor",2,0);var light=base.duplicate(true);light.armor_class="light";var heavy=base.duplicate(true);heavy.armor_class="heavy"
 var a=g.Gear.stats(base);var l=g.Gear.stats(light);var h=g.Gear.stats(heavy)
 check(l.armor<a.armor and l.health<a.health and l.speed>0,"Light armor trades defenses for speed")
 check(h.armor>a.armor and h.health>a.health and h.speed<0,"Heavy armor trades speed for defenses")
 var upgraded=light.duplicate(true);upgraded.level+=1;check(g.Gear.stats(upgraded).armor>l.armor,"Armor class persists when upgraded")
 g.free();print(JSON.stringify({"failures":failures}));quit(0 if failures.is_empty() else 1)
