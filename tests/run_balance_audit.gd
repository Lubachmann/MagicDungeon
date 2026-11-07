extends SceneTree
## Approximate progression audit: scripted room traversal, not a human playthrough.
const Stats=preload("res://build_stats.gd")
var g
var records=[]
func _initialize():call_deferred("run")
func score(s:Dictionary,style:String) -> float:
 var damage=float(s.weapon_dps);var hp=float(s.max_hp);var armor=float(s.armor)
 var ele=float(s.fire)+float(s.ice)*4+float(s.poison)*4+float(s.acid)*4
 return damage*3+hp*0.08+armor*0.4+ele*1.2+float(s.vampirism)*60 if style=="focused" else damage*2+hp*0.04
func level_choices(style:String):
 while g.pending_levels>0:
  g.resume_play()
  if g.mode!="relic":continue
  var best=0;var best_score=-INF
  for i in range(g.choices.size()):
   var id=g.choices[i];var future=Stats.upgrade_preview(g,id);var value=score(future,style)
   if style=="focused":
    value+= {"venom":5,"cinder":5,"frost":5,"solvent":5,"heavy_momentum":8,"venom_edge":4,"glacial_crusher":4,"shieldbreaker":4,"haste":3,"leech":4,"bloom":4}.get(id,0)
   else:value+=float((i*13+g.kills*7)%11)*0.25
   if value>best_score:best_score=value;best=i
  g.action("relic"+str(best))
func heal_if_needed():
 while g.potions>0 and g.hp<g.max_hp*0.55:
  var before=g.hp;g.mode="play";g.action("heal")
  if g.hp<=before:break
func fight(tile:Vector2i,e:Dictionary,style:String) -> bool:
 heal_if_needed()
 var battle=g.Combat.begin(e,g.hp,g.max_hp,g.attack,g.armor,g.speed,g.relics,g.combat_build());var steps=0
 while not battle.done and steps<2000:
  if battle.hp<battle.max_hp*0.55 and g.potions>0:
   g.battle=battle;g.mode="fight";g.action("heal")
  g.Combat.step(battle);steps+=1
 g.hp=battle.hp
 if not battle.won:return false
 g.mode="play";g.defeat_enemy(tile,e);level_choices(style);return true
func take_item(item:Dictionary,style:String):
 var before=Stats.calculate(g);var previous=g.equipped.get(item.slot,-1)
 g.inventory.append(item.duplicate(true));var index=g.inventory.size()-1
 var after=Stats.prospective(g,index)
 if previous<0 or score(after,style)>score(before,style):g.equipped[item.slot]=index;g.recalculate_stats()
func run_one(seed:int,weapon:String,style:String) -> Dictionary:
 g.skills={};g.new_run(seed);g.inventory=[g.make_gear("weapon",1,0,[],weapon)];g.inventory[0].plain=true;g.equipped={"weapon":0};g.recalculate_stats();g.hp=g.max_hp
 var floor_reached=1;var won=false;var death=""
 for floor_number in range(1,6):
  floor_reached=floor_number
  for coord in g.rooms.keys():
   if coord==g.boss_room:continue
   g.room=coord;var data=g.rooms[coord]
   for tile in data.entities.keys():
    var e=data.entities.get(tile,{})
    if e.get("kind","")=="enemy":
     if not fight(tile,e,style):death=e.name;return {"floor":floor_reached,"won":false,"death":death}
    elif e.get("kind","")=="potion":g.potions+=1
    elif e.get("kind","")=="fountain":g.hp=mini(g.max_hp,g.hp+30)
    elif e.get("kind","")=="rest_site":g.potions+=1
   var chest=data.entities.get(data.chest,{})
   if chest.get("kind","")=="chest" and chest.get("key_id","")=="" and chest.get("seal","")=="" and not chest.get("cursed",false):take_item(chest.item,style)
  g.room=g.boss_room;var bosses=[]
  for tile in g.rooms[g.room].entities:
   if g.rooms[g.room].entities[tile].get("kind","")=="enemy":bosses.append(tile)
  bosses.sort_custom(func(a,b):return int(g.rooms[g.room].entities[a].type)<int(g.rooms[g.room].entities[b].type))
  for tile in bosses:
   var e=g.rooms[g.room].entities.get(tile,{})
   if not e.is_empty() and not fight(tile,e,style):return {"floor":floor_reached,"won":false,"death":e.name}
  if floor_number<5:g.mode="floor";g.ascend_floor()
  else:won=true
 return {"floor":floor_reached,"won":won,"death":death}
func run():
 g=load("res://main.tscn").instantiate();g.save_path="/private/tmp/magic-build-audit";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.muted=true
 for style in ["focused","unfocused"]:
  for weapon in ["balanced","dagger","axe"]:
   var reached=0;var wins=0;var counts=[0,0,0,0,0];var deaths={}
   for seed in range(16):
    var result=run_one(seed+900,weapon,style);reached+=result.floor;wins+=int(result.won);counts[result.floor-1]+=1;deaths[result.death]=int(deaths.get(result.death,0))+1
   records.append({"style":style,"weapon":weapon,"mean_floor":float(reached)/16.0,"wins":wins,"runs":16,"final_floor_counts":counts,"deaths":deaths})
 print(JSON.stringify({"caveat":"Scripted sequential battles and gear selection; physical routing, bombs, forge upgrades and side passages are not simulated.","results":records}));g.free();quit(0)
