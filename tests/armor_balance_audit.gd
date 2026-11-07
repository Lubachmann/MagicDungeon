extends SceneTree
var g
var rows=[]
func _initialize():call_deferred("run")
func run():
	g=load("res://main.tscn").instantiate();g.save_path="res://tests/.armor-audit014.json";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false)
	for floor_value in [1,3,5,10]:
		for style in ["offense","balanced","armor","offense_support","balanced_support","armor_support"]:
			g.new_run(42);g.floor_number=floor_value;g.character_level=1+2*(floor_value-1);g.run_skills={"might":4,"armor_training":4,"vigor":4} if floor_value>=3 else {}
			var strategy=style.trim_suffix("_support");var upgrades=2*(floor_value-1)
			var count=mini(4,upgrades) if style.ends_with("_support") else 0
			g.relics=["frost","venom","solvent","leech"].slice(0,count);upgrades-=count
			g.bonus.attack=3*upgrades*(1.0 if strategy=="offense" else 0.5 if strategy=="balanced" else 0.0)
			g.bonus.armor=2*upgrades*(1.0 if strategy=="armor" else 0.5 if strategy=="balanced" else 0.0)
			var rarity=2 if floor_value>=3 else 1
			g.inventory=[];g.equipped={}
			for slot in ["weapon","shield","armor","helmet","amulet"]:
				var affix="armor" if strategy=="armor" and slot!="weapon" else "crit_mult" if slot=="weapon" else "health"
				g.inventory.append(g.make_gear(slot,floor_value,rarity,[affix]));g.equipped[slot]=g.inventory.size()-1
			g.recalculate_stats();g.hp=g.max_hp
			for type in [0,1,3]:
				var wins=0;var hp_loss=0.0;var time=0.0
				for seed_value in range(32):
					var foe=g.make_enemy(type,4 if type==3 else 2 if type==1 else 0);foe.erase("affix");foe.erase("mending");foe.roll_seed=500+seed_value*7919
					var state=g.Combat.begin(foe,g.hp,g.max_hp,g.attack,g.armor,g.speed,g.relics,g.combat_build());var n=0
					while not state.done and n<10000:g.Combat.step(state);n+=1
					wins+=int(state.won);hp_loss+=g.max_hp-state.hp;time+=state.time
				rows.append({"floor":floor_value,"build":style,"enemy":["weak","strong","imp","boss"][type],"armor":g.armor,"reduction":g.Combat.armor_reduction(g.armor),"hp":g.max_hp,"attack":g.attack,"wins":wins,"samples":32,"mean_hp_lost":snappedf(hp_loss/32,0.1),"mean_seconds":snappedf(time/32,0.01)})
	var path=OS.get_environment("MAGICDUNGEON_ARMOR_AUDIT")
	if path!="":var file=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(rows,"\t"))
	print("ARMOR AUDIT: %d encounters"%(rows.size()*32));g.free();quit()
