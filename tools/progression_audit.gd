extends RefCounted
## Reproducible scripted policy using real movement, combat, rewards and workshop actions.
const Stats=preload("res://build_stats.gd")
const Offers=preload("res://skill_offers.gd")
var g
var policy="cautious"
var profile_name="fresh"
var target_weapon="sword"
var invariant_failures=[]
var blocked=[]
var fixed_inventory:PackedByteArray
var walking_steps=0
var encounter_count=0
var trail=[]
func _init(game):g=game
func setup(profile:String,weapon:String) -> void:
 target_weapon=weapon;profile_name=profile;invariant_failures=[];blocked=[]
 g.session.enabled=false;g.session.active=false;g.session.cached={};g.skills={};g.bank=0;g.career=g.replay.new_career();g.career.journey={"skipped":true};g.replay.draft={"mode":"standard","vows":{}};g.new_run(700)
 if profile=="fresh":return
 var p=g.smithy.data();p.materials={"ore":1000,"monster":1000,"boss":100,"alloy":100,"essence":100,"relic":100}
 for id in g.smithy.RECIPES:
  if profile=="established" or id in [weapon,"shield","heavy_armor","helmet","amulet"]:p.blueprints[id]=true
 var established=profile=="established"
 var chosen=weapon
 if established:chosen=weapon+({"sword":"_bloodbound","dagger":"_swift","axe":"_keen","greatblade":"_keen","ember":"_swift"}[weapon])
 for id in [chosen,"shield","heavy_armor","helmet","amulet"]:
  g.mode="smithy";g.action("smithy_make:"+id)
 p.loadout={"weapon":chosen,"shield":"shield","armor":"heavy_armor","helmet":"helmet","amulet":"amulet"}
 for slot in g.Gear.SLOTS:
  while int(p.slot_levels[slot])<(5 if established else 2):g.mode="smithy";g.action("smithy_upgrade_slot:"+slot)
 if established:
  for element in ["fire","ice","acid","poison"]:p.elements[element]=true;g.career.sanctuary.discoveries[element]=true
  p.infusions={chosen:"poison","shield":"ice","heavy_armor":"acid","helmet":"ice","amulet":"fire"}
  g.career.sanctuary.discoveries.smith=true;g.career.sanctuary.discoveries.cartographer=true
 g.bank=10000;g.mode="skills"
 var ranks={"kindling":1,"vigor":2,"armor_training":1,"might":2,"tempo":1}
 if established:ranks={"kindling":1,"vigor":8,"armor_training":6,"might":8,"tempo":5,"precision_training":4,"ruin_training":4,"flaskcraft":2,"flask_reserve":1,"wellkeeper":1,"field_medicine":2,"recovery":1,"cartography":1,"treasure_hunter":2,"runic_sight":1,"embercraft":1,"supply_cache":2,"fire_mastery":3,"ice_mastery":3,"acid_mastery":3,"poison_mastery":3}
 for id in ranks:
  for rank in range(ranks[id]):
   if not g.ember_tree.buy(id):invariant_failures.append("Profile skill purchase failed: "+id)
 g.bank=0;p.materials={"ore":0,"monster":0,"boss":0,"alloy":0,"essence":0,"relic":0};p.metrics={"seeded_profile":profile};p.unseen_items={};p.unseen_blueprints={}
func utility(id:String,blessing:bool=false) -> float:
 var before=Stats.calculate(g);var after=Stats.upgrade_preview(g,id,blessing)
 var value=(after.weapon_dps-before.weapon_dps)*2.5+(after.armor-before.armor)*(1.4 if policy=="cautious" else 0.7)
 for element in ["fire","ice","acid","poison"]:value+=(after.element_totals[element]-before.element_totals[element])*(3.5 if element in ["ice","poison"] else 2.0)
 value+=(after.vampirism-before.vampirism)*100
 value+={"bloom":10.0,"leech":9.0,"frost":5.0,"venom":4.0,"solvent":3.0,"quickdraw":3.0,"ward":4.0,"heavy_momentum":6.0,"glacial_crusher":4.0,"venom_edge":4.0,"warded_blade":3.0,"blood_harvest":3.0,"toxic_glacier":5.0,"combustion":4.0,"frost_shatter":5.0}.get(id,0.0)
 value-=Offers.build_requirements(g,id,before).size()*3
 return value
func choose(ids:Array,blessing:bool=false) -> int:
 var best=0;var value=-INF
 for i in range(ids.size()):
  var candidate=utility(str(ids[i]),blessing)
  if candidate>value:value=candidate;best=i
 return best
func terminal() -> bool:return g.mode in ["dead","won"]
func settle() -> bool:
 var iterations=0
 while g.mode!="play" and not terminal() and iterations<4000:
  iterations+=1
  match g.mode:
   "fight":
    if g.battle.hp<g.battle.max_hp*0.55 and g.potions>0:g.action("heal")
    g._process(0.25)
   "relic":g.choice_ui.skip_level_intro();g.action("relic"+str(choose(g.choices)))
   "upgrade":g.action("upgrade"+str(choose(g.blessings,true)))
   "decision":
    var e=g.rooms[g.room].entities.get(g.puzzle_tile,{})
    if e.kind=="boss_preparation":g.action("prepare_weaken")
    elif e.get("expedition_reward",false):
     if g.potions==0 and g.hp<g.max_hp*0.6:g.action("rest_flask")
     elif utility(str(e.reward_element),true)>utility(str(e.reward_skill)):g.action("expedition_blessing")
     else:g.action("expedition_skill")
    elif e.kind=="rest_site":g.action("rest_flask")
    elif e.kind=="build_cache":g.action("cache_pick:0")
    elif e.kind=="wardstone":g.action("ward_disable")
    else:g.action("decision_leave")
   "discovery":g.action("discovery_continue")
   "shrine":g.action("shrine_temper" if policy=="focused" and g.hp>g.max_hp*0.8 else "shrine_embers")
   "curse":g.action("curse_embers" if g.shards>=4 else "curse_blood" if g.hp>24 else "curse_leave")
   "runes":
    var vault=g.rooms[g.room].entities[g.puzzle_tile];g.action("rune:"+str(vault.order[vault.progress]))
   "vault_reward":g.action("vault_pick:0")
   "ending":g.action("ending_choose:rekindle")
   "floor":return true
   _:blocked.append("Unhandled mode: "+str(g.mode));return false
 if iterations>=4000:blocked.append("Combat/action step limit");return false
 return not terminal()
func can_enter(tile:Vector2i,goal:Vector2i,enemies:bool) -> bool:
 var data=g.rooms[g.room]
 if not data.bounds.grow(-1).has_point(tile):return false
 var e=data.entities.get(tile,{});var kind=str(e.get("kind",""))
 if data.walls.has(tile) and not (kind=="crack" and g.breaker):return false
 if kind=="water" and not g.boots:return false
 if kind=="enemy" and not enemies:return false
 if kind in ["chest","exit"] and tile!=goal:return false
 if kind=="reliquary" and not e.get("used",false) and tile!=goal:return false
 return true
func path(goal:Vector2i,enemies:bool) -> Array:
 var previous={g.pos:g.pos};var queue=[g.pos]
 while not queue.is_empty():
  var at:Vector2i=queue.pop_front()
  if at==goal:
   var result=[]
   while at!=g.pos:result.push_front(at);at=previous[at]
   return result
  for direction in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
   var next=at+direction
   if previous.has(next) or not can_enter(next,goal,enemies):continue
   previous[next]=at;queue.append(next)
 return []
func dangerous(e:Dictionary) -> bool:
 return policy=="cautious" and g.fight_preview.estimate(e).label=="Deadly"
func walk(goal:Vector2i,allow_fights:bool=true) -> bool:
 for attempt in range(5):
  if g.pos==goal:return true
  var route=path(goal,false)
  if route.is_empty() and allow_fights:route=path(goal,true)
  if route.is_empty():return false
  var moved=false
  for tile in route:
   var e=g.rooms[g.room].entities.get(tile,{})
   if e.get("kind","")=="enemy" and dangerous(e):return false
   var before=g.pos
   if g.movement:g.movement.kill()
   g.game_move_player(tile-g.pos);walking_steps+=1
   if not settle():return false
   if g.mode=="floor":return true
   if g.pos==before and g.rooms[g.room].entities.get(tile,{}).get("kind","")!="enemy":return false
   moved=true
  if not moved:return false
 return g.pos==goal
func go_room(target:Vector2i,allow_fights:bool=true) -> bool:
 if g.room==target:return true
 var previous={g.room:g.room};var queue=[g.room]
 while not queue.is_empty():
  var coord:Vector2i=queue.pop_front()
  if coord==target:break
  for next in g.links[coord]:
   if previous.has(next) or (next==g.boss_room and next!=target) or (g.is_water_link(coord,next) and not g.boots):continue
   previous[next]=coord;queue.append(next)
 if not previous.has(target):return false
 var route=[];var at=target
 while at!=g.room:route.push_front(at);at=previous[at]
 for next in route:
  var direction:Vector2i=next-g.room;var bounds:Rect2i=g.rooms[g.room].bounds
  var landing=Vector2i(bounds.position.x+1,5) if direction==Vector2i.LEFT else Vector2i(bounds.end.x-2,5) if direction==Vector2i.RIGHT else Vector2i(6,bounds.position.y+1) if direction==Vector2i.UP else Vector2i(6,bounds.end.y-2)
  if not walk(landing,allow_fights):return false
  if g.movement:g.movement.kill()
  var departed=g.room
  g.game_move_player(direction);walking_steps+=1
  if not settle():return false
  if g.room!=next:return false
  trail.append({"from":departed,"to":g.room,"entry":g.pos})
 return true
func collect_room(allow_fights:bool) -> void:
 var priorities=["potion","boss_preparation","rest_site","hammer","boots","sanctuary_discovery","dungeon_key","brazier","salvage","ore_deposit","iron","fountain","equipment","chest","reliquary","shrine"]
 for kind in priorities:
  var tiles=g.rooms[g.room].entities.keys()
  for tile in tiles:
   if terminal():return
   var e=g.rooms[g.room].entities.get(tile,{})
   if e.get("kind","")!=kind or e.get("used",false):continue
   if kind=="fountain" and g.hp>g.max_hp*0.65:continue
   if kind=="chest" and g.chest_access(e) not in ["nearby stash","side chamber","breakable-wall alcove","cross water","guardian defeated","winding side passage","sentinel defeated","Warden defeated"]:continue
   walk(tile,allow_fights)
func clear_room() -> void:
 collect_room(false)
 var enemies=[]
 for tile in g.rooms[g.room].entities:
  var e=g.rooms[g.room].entities[tile]
  if e.kind=="enemy":enemies.append(tile)
 enemies.sort_custom(func(a,b):return int(g.rooms[g.room].entities[a].get("level",1))<int(g.rooms[g.room].entities[b].get("level",1)))
 for tile in enemies:
  if terminal():return
  if g.rooms[g.room].entities.get(tile,{}).get("kind","")!="enemy":continue
  walk(tile)
  collect_room(false)
 collect_room(true)
func branch() -> void:
 if g.floor_flags.has("branch_choice") or not go_room(Vector2i.ZERO):return
 var bounds:Rect2i=g.rooms[g.room].bounds
 if not walk(Vector2i(bounds.position.x+1,5),false):return
 g.game_move_player(Vector2i.LEFT)
 if g.mode!="branch":return
 var element=str(g.tactics.preparation().element)
 g.action("branch_choose:"+element)
 trail.append({"from":Vector2i.ZERO,"to":g.room,"entry":g.pos})
 clear_room()
 if not terminal():go_room(Vector2i.ZERO)
func retreat() -> bool:
 # Retrace traversed doorways instead of assuming the shortest room-graph path is safe.
 while g.room!=Vector2i.ZERO and not trail.is_empty():
  var edge=trail.pop_back()
  if edge.to!=g.room:continue
  if not walk(edge.entry,false):return false
  g.game_move_player(edge.from-edge.to);walking_steps+=1
  if not settle() or g.room!=edge.from:return false
 return g.room==Vector2i.ZERO
func invariant() -> void:
 if var_to_bytes([g.inventory,g.equipped])!=fixed_inventory and "Equipment changed during an expedition" not in invariant_failures:invariant_failures.append("Equipment changed during an expedition")
func expedition(seed:int) -> Dictionary:
 walking_steps=0;blocked=[];trail=[];g.session.active=true;g.new_run(seed);preload("res://early_journey.gd").begin_run(g)
 fixed_inventory=var_to_bytes([g.inventory,g.equipped]);var starting=g.smithy.data().duplicate(true);var bank_before=g.bank
 var completed=false
 for floor_num in range(1,6):
  var coords=g.dungeon_threads.distances_from(Vector2i.ZERO).keys()
  coords.sort_custom(func(a,b):return int(g.distances.get(a,0))<int(g.distances.get(b,0)))
  for coord in coords:
   if terminal():break
   if coord==g.boss_room:continue
   if go_room(coord):clear_room()
  if terminal():break
  branch()
  if terminal():break
  # Revisit locked rewards after acquiring traversal tools, keys and candles.
  for coord in coords:
   if terminal():break
   if coord!=g.boss_room and go_room(coord):collect_room(false)
  if terminal():break
  if not go_room(g.boss_room):break
  var bosses=[]
  for tile in g.rooms[g.room].entities:
   if g.rooms[g.room].entities[tile].kind=="enemy" and int(g.rooms[g.room].entities[tile].type)==3:bosses.append(tile)
  if bosses.is_empty():blocked.append("No boss found");break
  if not walk(bosses[0]) or terminal():break
  collect_room(false);invariant()
  var stairs=Vector2i(-1,-1)
  for tile in g.rooms[g.room].entities:
   if g.rooms[g.room].entities[tile].kind=="exit":stairs=tile
  if stairs.x<0 or not walk(stairs):break
  if terminal():completed=g.mode=="won";break
  if g.mode!="floor":blocked.append("Stairs did not advance the floor");break
  g.action("ascend");trail=[]
 invariant()
 if not terminal():
  if retreat():g.mode="play";g.action("extract_prompt");g.action("extract_confirm")
  else:blocked.append("Could not route home")
 var data=g.playtest.validation();var cargo=g.smithy.cargo().duplicate(true)
 var result={"seed":g.run_seed,"rules":g.run_rules,"outcome":"victory" if g.mode=="won" else "returned" if g.run_metrics.get("extracted",false) else "death" if g.mode=="dead" else "blocked","floor":g.floor_number,"level":g.character_level,"kills":g.kills,"walking_steps":walking_steps,"banked_embers":g.bank-bank_before,"cargo":cargo,"starting_workshop":starting,"ending_workshop":g.smithy.data().duplicate(true),"validation":data.duplicate(true),"death_reason":g.death_reason,"blocked":blocked.duplicate(),"invariant_failures":invariant_failures.duplicate()}
 g.session.active=false;g.session.cached={}
 return result
func shop() -> Dictionary:
 var p=g.smithy.data();var before=p.duplicate(true);var bank_before=g.bank;g.mode="smithy"
 var wanted=[target_weapon,"dagger","shield","helmet","heavy_armor","amulet",target_weapon+"_keen",target_weapon+"_swift",target_weapon+"_bloodbound"]
 for id in wanted:
  if p.blueprints.has(id) and not p.items.has(id):g.action("smithy_make:"+id)
 for slot in ["weapon","shield","armor","helmet","amulet"]:
  if p.loadout.has(slot) or slot=="weapon":g.action("smithy_upgrade_slot:"+slot)
 for slot in g.Gear.SLOTS:
  var id=target_weapon if slot=="weapon" else "heavy_armor" if slot=="armor" else slot
  if slot=="weapon":
   if profile_name=="fresh" and id=="sword" and p.items.has("dagger"):id="dagger"
   else:
    var current=str(p.loadout.get("weapon",""))
    if g.smithy.RECIPES.has(current) and g.smithy.RECIPES[current][2]==g.smithy.RECIPES[id][2]:id=current
  if p.items.has(id):
   g.loadout_menu.open("expedition");g.action("loadout_slot:"+slot);g.action("loadout_select:"+id);g.action("loadout_equip")
 g.mode="smithy"
 if p.goal.is_empty():g.action("smithy_track:shield" if not p.items.has("shield") else "smithy_track_slot:weapon")
 # Use discovered runes through the actual paid infusion action.
 for id in p.loadout.values():
  if p.infusions.has(id):continue
  for element in ["ice","poison","acid","fire"]:
   if p.elements.has(element):g.action("smithy_runes:"+str(id));g.action("smithy_infuse:"+element);break
 g.mode="skills"
 for id in ["kindling","vigor","might","armor_training","flaskcraft","tempo","precision_training","ruin_training","wellkeeper","field_medicine","supply_cache","recovery","flask_reserve"]:
  g.ember_tree.buy(id)
 return {"before":before,"after":g.smithy.data().duplicate(true),"embers_spent":bank_before-g.bank,"tree":g.skills.duplicate(true)}
