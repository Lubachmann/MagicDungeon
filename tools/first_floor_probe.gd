extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();g.save_path="res://tests/.boss-probe016";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.muted=true;var rows=[]
 for weapon in ["balanced","dagger","axe"]:
  for element in ["physical","fire","ice","acid","poison"]:
   g.skills={};g.new_run(42);g.character_level=3;g.relics=["ward"]
   var item=g.make_gear("weapon",2,0,[],weapon);item["plain"]=true
   if element!="physical":item["infusion"]=element;g.relics.append({"fire":"cinder","ice":"frost","acid":"solvent","poison":"venom"}[element])
   else:g.bonus.attack=3
   g.inventory=[item];g.equipped={"weapon":0}
   for slot in ["shield","armor","helmet"]:g.inventory.append(g.make_gear(slot,2,0));g.equipped[slot]=g.inventory.size()-1
   g.recalculate_stats();g.hp=g.max_hp
   for bomb in [false,true]:
    var wins=0;var seconds=0.0;var hp=0.0
    for sample in range(32):
     var enemy=g.make_enemy(3,4);enemy.roll_seed=100+sample*5231
     if bomb:enemy.hp-=20
     var s=g.Combat.begin(enemy,g.hp,g.max_hp,g.attack,g.armor,g.speed,g.relics,g.combat_build());var n=0
     while not s.done and n<10000:g.Combat.step(s);n+=1
     wins+=int(s.won);seconds+=s.time;hp+=s.hp
    rows.append({"weapon":weapon,"element":element,"bomb":bomb,"wins":wins,"samples":32,"mean_seconds":snappedf(seconds/32,0.01),"mean_hp_left":snappedf(hp/32,0.1),"player_hp":g.max_hp,"armor":g.armor,"level":3})
 var path=OS.get_environment("MAGICDUNGEON_BOSS_PROBE")
 if path!="":var f=FileAccess.open(path,FileAccess.WRITE);f.store_string(JSON.stringify(rows,"\t"))
 print(JSON.stringify(rows));g.free();quit()
