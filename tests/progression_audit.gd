extends SceneTree
const Stats=preload("res://build_stats.gd")
const PROFILES={"Fresh":{},"Early":{"kindling":1,"vigor":3,"might":2,"armor_training":1},"Developed":{"kindling":1,"vigor":8,"armor_training":5,"might":6,"tempo":3,"fire_mastery":3,"ice_mastery":3,"poison_mastery":3,"flaskcraft":1}}
var g
var rows=[]
func _initialize() -> void:call_deferred("run")
func build(floor_value: int,lucky: bool) -> void:
	g.character_level=1+2*floor_value;g.base_elements={"fire":mini(3,floor_value),"ice":0,"acid":0,"poison":0};g.bonus={"attack":0.0,"armor":0.0,"speed":0.0,"crit_chance":0.0,"crit_mult":0.0};g.relics=[]
	g.inventory=[g.Gear.make("weapon",floor_value+1,1,["fire_dps"],"ember"),g.Gear.make("shield",floor_value,0),g.Gear.make("armor",floor_value,0),g.Gear.make("helmet",floor_value,1,["ice_slow"]),g.Gear.make("amulet",floor_value,1,["poison_weak"])]
	if lucky:g.inventory[0]=g.Gear.make("weapon",floor_value+3,2,["speed","crit_chance"],"greatblade")
	g.equipped={"weapon":0,"shield":1,"armor":2,"helmet":3,"amulet":4};g.recalculate_stats();g.hp=g.max_hp
func run() -> void:
	g=load("res://main.tscn").instantiate();g.save_path="res://tests/.audit010.json";root.add_child(g);await process_frame;g.set_process(false);g.session.enabled=false
	for profile in PROFILES:
		var paid=0
		for id in PROFILES[profile]:
			for rank in range(PROFILES[profile][id]):paid+=g.ember_tree.NODES[id].costs[rank]
		for floor_value in range(1,6):
			for lucky in [false,true]:
				var wins=0;var loss=0.0;var time=0.0
				for seed_value in range(32):
					g.skills=PROFILES[profile].duplicate();g.replay.draft={"mode":"standard","vows":{}};g.new_run(1000+seed_value);g.floor_number=floor_value;g.generate_floor();build(floor_value,lucky)
					var enemy=g.rooms[g.boss_room].entities[Vector2i(6,3)].duplicate(true)
					var state=g.Combat.begin(enemy,g.hp,g.max_hp,g.attack,g.armor,g.speed,g.relics,g.combat_build())
					var count=0
					while not state.done and count<5000:g.Combat.step(state);count+=1
					wins+=int(state.won);loss+=g.max_hp-state.hp;time+=state.time
				rows.append({"profile":profile,"embers":paid,"floor":floor_value,"weapon":"Lucky greatblade" if lucky else "Chosen fire build","wins":wins,"samples":32,"hp_loss":snappedf(loss/32,0.1),"seconds":snappedf(time/32,0.1)})
	var path=OS.get_environment("MAGICDUNGEON_AUDIT_OUTPUT")
	if path!="":var file=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(rows,"\t"))
	var errors=0
	for i in range(10):
		if rows[i].wins>rows[10+i].wins or rows[10+i].wins>rows[20+i].wins:errors+=1
	print("PROGRESSION AUDIT: %d controlled boss fights / %d progression regressions"%[rows.size()*32,errors])
	g.queue_free();await process_frame;quit(0 if errors==0 else 1)
