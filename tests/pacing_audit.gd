extends SceneTree
var g
var rows=[]
func _initialize():call_deferred("run")
func run():
	g=load("res://main.tscn").instantiate();g.save_path="res://tests/.audit012";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false)
	for floor_value in range(1,6):
		for weapon in ["balanced","dagger","axe","ember"]:
			g.new_run(42);g.floor_number=floor_value;g.character_level=1+2*(floor_value-1)
			g.run_skills={"kindling":1,"vigor":6,"might":4,"armor_training":4,"tempo":4,"fire_mastery":2,"ice_mastery":2,"poison_mastery":2,"acid_mastery":2} if floor_value>=3 else {}
			g.inventory=[g.make_gear("weapon",floor_value,1,["speed" if weapon=="dagger" else "fire_dps" if weapon=="ember" else "crit_mult"],weapon),g.make_gear("shield",floor_value,1,["acid_strip"]),g.make_gear("armor",floor_value,1,["poison_weak"]),g.make_gear("helmet",floor_value,1,["ice_slow"]),g.make_gear("amulet",floor_value,1,["vampirism"])]
			g.equipped={"weapon":0,"shield":1,"armor":2,"helmet":3,"amulet":4}
			var relics=["cinder","frost","shatter","venom","contagion","solvent","haste","leech"]
			g.relics=relics.slice(0,g.character_level-1);g.recalculate_stats();g.hp=g.max_hp
			for type in [0,1,3]:
				var sum=0.0;var loss=0.0;var wins=0;var won_time=0.0;var foe={}
				for seed_value in range(32):
					foe=g.make_enemy(type,4 if type==3 else 2 if type==1 else 0);foe.erase("affix");foe.erase("mending");foe.roll_seed=500+seed_value*7919
					var state=g.Combat.begin(foe,g.hp,g.max_hp,g.attack,g.armor,g.speed,g.relics,g.combat_build());var count=0
					while not state.done and count<10000:g.Combat.step(state);count+=1
					sum+=state.time;loss+=g.max_hp-state.hp;wins+=int(state.won)
					if state.won:won_time+=state.time
				rows.append({"floor":floor_value,"weapon":weapon,"enemy":["weak","strong","bat","boss"][type],"wins":wins,"samples":32,"mean_seconds":snappedf(sum/32,0.01),"mean_win_seconds":snappedf(won_time/wins,0.01) if wins>0 else null,"mean_hp_lost":snappedf(loss/32,0.1),"player_hit":snappedf(g.attack,0.1),"interval":snappedf(1/g.speed,0.01),"enemy_hp":foe.max,"enemy_attack":foe.attack,"tree":g.run_skills.duplicate()})
	var path=OS.get_environment("MAGICDUNGEON_PACING_AUDIT")
	if path!="":var file=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(rows,"\t"))
	for row in rows:
		if row.floor in [1,5]:print(JSON.stringify(row))
	print("PACING AUDIT: %d controlled encounters"%(rows.size()*32));g.queue_free();await process_frame;quit()
