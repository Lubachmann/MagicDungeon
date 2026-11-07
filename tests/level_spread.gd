extends SceneTree
const Gear=preload("res://equipment.gd")
const Roster=preload("res://enemy_roster.gd")
var failures=[]
var checks=0
func check(ok: bool, message: String) -> void:
 checks+=1
 if not ok and failures.size()<30:failures.append(message)
func _initialize() -> void:call_deferred("run")
func reachable_before_combat(data: Dictionary) -> Dictionary:
 var start=Vector2i(2,5);var seen={start:true};var queue=[start]
 while not queue.is_empty():
  var tile=queue.pop_front()
  for d in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
   var next=tile+d
   if seen.has(next) or not data.bounds.grow(-1).has_point(next) or data.walls.has(next):continue
   if data.entities.get(next,{}).get("kind","") in ["enemy","chest","water","crack","reliquary"]:continue
   seen[next]=true;queue.append(next)
 return seen
func run() -> void:
 var g=load("res://main.tscn").instantiate();g.save_path="/private/tmp/magic-level-spread-test";root.add_child(g);await process_frame
 g.session.enabled=false;g.set_process(false);g.muted=true;g.skills={}
 var types={};var seen_levels={};var guard_min=99;var min_xp=999999;var max_xp=0
 for seed_value in range(200):
  g.new_run(seed_value)
  var data=g.rooms[Vector2i.ZERO];var chest=data.entities[data.chest];var item=chest.item
  check(g.inventory.is_empty(),"Player starts unarmed")
  check(chest.kind=="chest" and item.slot=="weapon" and item.level==1 and item.rarity==0 and item.affixes.is_empty() and item.get("plain",false),"Starting chest contains one plain common weapon")
  types[item.archetype]=int(types.get(item.archetype,0))+1
  var reachable=reachable_before_combat(data);var adjacent=false
  for direction in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
   if reachable.has(data.chest+direction):adjacent=true
  check(adjacent,"Starting weapon reachable without fighting: seed %d"%seed_value)
  var guard_count=0;var total_xp=0
  for coord in g.rooms:
   var room=g.rooms[coord]
   for e in room.entities.values():
    check(e.kind!="wardstone","No guardian weakening shrine in new runs")
    check(not (e.kind=="build_cache" and e.get("basic",false)),"No starting choice chest")
    if e.kind=="chest" and e.get("guardian",Vector2i(-1,-1)).x>=0:guard_count+=1
    if e.kind=="enemy":
     var l=Roster.level(e,1);seen_levels[l]=true
     check(l>=1 and l<=6 and e.has("level"),"First-floor level is real and in range")
     var expected=(10+15*(l-1))*(2 if e.type==3 else 1)
     check(g.enemy_xp(e)==expected,"Reward matches the enemy's displayed level")
     total_xp+=g.enemy_xp(e)
  guard_min=mini(guard_min,guard_count);min_xp=mini(min_xp,total_xp);max_xp=maxi(max_xp,total_xp)
  check(guard_count>=3,"Optional guardian rewards are available")
 check(types.size()==5,"All five starting weapons occur")
 for tier in range(1,7):check(seen_levels.has(tier),"First-floor enemy level %d occurs"%tier)
 check(g.xp_required(1)==40 and g.xp_required(2)==100,"Four level 1 enemies reach level 2; ten more level 1 or four level 2 reach level 3")
 var previous_hp=0.0;var previous_attack=0.0
 for floor_number in range(1,6):
  g.floor_number=floor_number
  for tier in range(1,7):
   var enemy=g.make_enemy(0,1,tier);enemy.erase("affix");var lv=6*(floor_number-1)+tier
   check(enemy.level==lv and enemy.hp>previous_hp and enemy.attack>previous_attack,"Ordinary enemy health and attack grow from level to level")
   previous_hp=enemy.hp;previous_attack=enemy.attack
 var shield=g.make_gear("shield",1,0);var shield_two=shield.duplicate(true);shield_two.level=2
 check(Gear.stats(shield).armor==2 and Gear.stats(shield_two).armor==5,"Iron upgrades a common shield from 2 to 5 armor")
 var sword=g.make_gear("weapon",1,0,[],"balanced");var sword_two=sword.duplicate(true);sword_two.level=2
 check(Gear.stats(sword).attack==9 and Gear.stats(sword_two).attack==12,"Weapon levels give larger improvements")
 var legacy=shield.duplicate(true);legacy.balance=6
 check(is_equal_approx(Gear.stats(legacy).armor,1.5),"Old equipment keeps its previous formula")
 for rank in range(4):
  g.skills={"smithcraft":rank};g.new_run(102)
  var starter=g.rooms[Vector2i.ZERO].entities[g.rooms[Vector2i.ZERO].chest].item
  check(starter.slot=="weapon" and starter.level==(2 if rank>=2 else 1) and starter.rarity==(0 if rank==0 else 2 if rank>=3 else 1),"Quartermaster upgrades the random starting weapon at rank %d"%rank)
 g.skills={};g.new_run(103);g.run_rules=14;g.generate_floor()
 var legacy_cache=false
 for e in g.rooms[Vector2i.ZERO].entities.values():
  if e.kind=="build_cache" and e.get("basic",false):legacy_cache=true
 check(legacy_cache,"Saved runs on old rules retain the original opening")
 g.new_run(91);g.hp=40;g.gain_xp(40)
 check(g.character_level==2 and g.max_hp==88 and g.hp==48,"Level up increases max HP and heals the increase")
 g.session.enabled=true;g.session.active=true
 check(g.session.checkpoint() and g.session.continue_run() and g.run_rules==18 and g.character_level==2,"New rules and level survive save and continue")
 g.session.enabled=false
 for suffix in [".run",".run.bak",".run.tmp"]:DirAccess.remove_absolute(g.save_path+suffix)
 print(JSON.stringify({"checks":checks,"failures":failures,"starting_weapons":types,"levels_seen":seen_levels,"minimum_guarded_chests":guard_min,"floor_xp_min":min_xp,"floor_xp_max":max_xp}))
 g.free();quit(0 if failures.is_empty() else 1)
