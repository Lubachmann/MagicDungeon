extends SceneTree
var rows=[]
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();g.save_path="res://tests/.element-audit015";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false)
 for weapon in ["balanced","dagger","axe"]:
  for element in ["none","fire","ice","acid","poison"]:
   g.skills={};g.new_run(42);var item=g.make_gear("weapon",1,0,[],weapon);item["plain"]=true
   if element!="none":item["infusion"]=element
   g.inventory=[item];g.equipped={"weapon":0}
   for slot in ["shield","armor","helmet"]:g.inventory.append(g.make_gear(slot,1,0));g.equipped[slot]=g.inventory.size()-1
   g.recalculate_stats();g.hp=g.max_hp
   for type in [0,1]:
    var seconds=0.0;var loss=0.0;var wins=0
    for sample in range(32):
     var enemy=g.make_enemy(type,0 if type==0 else 2);enemy.erase("affix");enemy.erase("mending");preload("res://combat_pacing.gd").enemy(enemy,1,0 if type==0 else 2);enemy.roll_seed=100+sample*5231
     var s=g.Combat.begin(enemy,g.hp,g.max_hp,g.attack,g.armor,g.speed,g.relics,g.combat_build());var steps=0
     while not s.done and steps<10000:g.Combat.step(s);steps+=1
     seconds+=s.time;loss+=g.max_hp-s.hp;wins+=int(s.won)
    rows.append({"weapon":weapon,"element":element,"enemy":"weak" if type==0 else "strong","mean_seconds":snappedf(seconds/32,0.01),"mean_hp_lost":snappedf(loss/32,0.1),"wins":wins,"samples":32})
 var path=OS.get_environment("MAGICDUNGEON_ELEMENT_AUDIT")
 if path!="":var f=FileAccess.open(path,FileAccess.WRITE);f.store_string(JSON.stringify(rows,"\t"))
 print("ELEMENT AUDIT: %d fixed-seed encounters"%(rows.size()*32));g.free();quit()
