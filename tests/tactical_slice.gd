extends SceneTree
const Combat=preload("res://combat.gd")
var g
var checks=0
var failures=[]
const PATH="res://tests/.tactics-save.json"
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok and failures.size()<30:failures.append(message)
func dummy(type: int=1) -> Dictionary:
	return {"kind":"enemy","type":type,"name":"Training foe","hp":200,"max":200,"attack":10,"armor":4,"speed":1.0,"trait":"none","elite":false,"roll_seed":19}
func _initialize() -> void:call_deferred("run")
func run() -> void:
	g=load("res://main.gd").new();g.save_path=PATH;root.add_child(g);preload("res://tools/test_equipment.gd").arm(g);g.set_process(false);g.session.enabled=false;g.muted=true
	check(g.run_rules==6 and g.active_ability=="guard","Fresh runs use the tactical rules and neutral ability")
	var encounter_sets={};var floor_rules={}
	for seed_value in range(100):
		g.skills={};g.new_run(seed_value);preload("res://tools/test_equipment.gd").arm(g)
		for floor_index in range(1,6):
			var selected=g.floor_flags.encounters
			check(selected.size()==2 and selected[0]!=selected[1],"Two distinct optional encounters per floor")
			var signature=selected.duplicate();signature.sort();encounter_sets[str(signature)]=true
			floor_rules[g.tactics.rule()]=true
			var counts={"dungeon_key":0,"brazier":0,"reliquary":0,"curse":0};var slots={}
			for coord in g.rooms:
				var data=g.rooms[coord];var reachable=g.dungeon_threads.reachable(data)
				for tile in data.entities:
					var e=data.entities[tile]
					if e.kind in ["dungeon_key","brazier","reliquary"]:
						counts[e.kind]+=1
						check(tile.x!=6 and tile.y!=5,"Optional marker avoids mandatory corridors")
						if e.kind!="reliquary":check(reachable.has(tile),"Switch/key reachable without opening any chest")
					if e.kind=="dungeon_key":check(g.dungeon_threads.distances_from(coord)[g.floor_flags.lock_room]>=2,"Key at least two open room edges from lock")
					if e.kind=="chest":
						slots[e.item.slot]=true
						if e.get("cursed",false):counts.curse+=1;check(e.tier==2 and not e.get("paid",false),"Cursed chest reward fixed before payment")
				for neighbor_room in g.links[coord]:
					var direction=neighbor_room-coord;var b: Rect2i=data.bounds
					var landing=Vector2i(b.position.x+1,5) if direction==Vector2i.LEFT else (Vector2i(b.end.x-2,5) if direction==Vector2i.RIGHT else (Vector2i(6,b.position.y+1) if direction==Vector2i.UP else Vector2i(6,b.end.y-2)))
					check(reachable.has(landing),"All doors reachable: seed %d floor %d room %s landing %s chest %s"%[seed_value,floor_index,coord,landing,data.chest])
				check(coord!=g.boss_room or not data.entities.has(Vector2i(6,2)) or data.entities[Vector2i(6,2)].kind not in ["chest","reliquary"],"Boss approach unblocked")
			check(counts.dungeon_key==(1 if "key" in selected else 0),"Key only appears with its lock")
			check(counts.brazier==(2 if "seal" in selected else 0),"Seal always has both switches")
			check(counts.reliquary==(1 if "runes" in selected else 0),"Rune encounter matches pool")
			check(counts.curse==(1 if "curse" in selected else 0),"Exactly one optional paid chest when selected")
			check(slots.size()==5,"All five equipment slots remain represented")
			check(g.dungeon_threads.distances_from(Vector2i.ZERO).has(g.boss_room),"Core graph requires no purchased skill")
			if floor_index<5:g.mode="floor";g.ascend_floor()
	check(encounter_sets.size()==6 and floor_rules.size()==5,"All six encounter pairs and five floor rules generated")
	# No-stat-investment, plausible first-floor build can beat the Warden.
	g.new_run(42);preload("res://tools/test_equipment.gd").arm(g);g.character_level=3;g.inventory=[g.Gear.make("weapon",3,0),g.Gear.make("armor",1,0),g.Gear.make("shield",1,0),g.Gear.make("helmet",1,0)];g.equipped={"weapon":0,"armor":1,"shield":2,"helmet":3};g.relics=["frost","venom"];g.recalculate_stats();g.hp=g.max_hp
	var warden=g.make_enemy(3,4);var prepared=Combat.begin(warden,g.hp,g.max_hp,g.attack,g.armor,g.speed,g.relics,g.combat_build())
	prepared.ability="guard"
	var guard_saved=false
	while not prepared.done:
		if Combat.needs_decision(prepared) and not guard_saved:Combat.use_ability(prepared);guard_saved=true
		Combat.step(prepared)
	check(prepared.won and g.skills.is_empty(),"First-floor boss can be defeated with run loot and no permanent upgrades")
	# Independent ability effects and private RNG invariance.
	var state=Combat.begin(dummy(),40,60,1,0,1,[],{"tactics":true,"ability":"guard"})
	state.p_time=100;var roll=state.roll
	check(Combat.use_ability(state) and not Combat.use_ability(state) and state.roll==roll,"One ability use, no random roll consumed")
	check(Combat.step(state).damage==0 and Combat.step(state).damage>0,"Guard blocks exactly one enemy strike")
	state=Combat.begin(dummy(),40,60,1,0,1,[],{"tactics":true,"ability":"interrupt"});state.p_time=100;state.e_hits=1
	var before=state.e_time;check(Combat.needs_decision(state),"Second ordinary-enemy attack is telegraphed")
	Combat.use_ability(state);check(is_equal_approx(state.e_time,before+1.5) and not Combat.needs_decision(state),"Interrupt cancels special warning and delays attack")
	check(Combat.step(state).damage==10,"Interrupted crushing attack loses its multiplier")
	state=Combat.begin(dummy(2),20,60,1,0,1,[],{"tactics":true,"ability":"mend"});state.wound=3;Combat.use_ability(state)
	check(state.hp==32 and state.wound==0,"Mend heals and cleanses hex")
	state.p_time=100;state.e_hits=1;Combat.step(state)
	check(state.wound==0 and not state.hex_guard,"Mend can preempt the announced hex without reflex timing")
	state=Combat.begin(dummy(2),50,60,1,0,1,[],{"tactics":true});state.p_time=100;state.e_hits=1;Combat.step(state)
	check(state.wound==3,"Prepared bat attack applies hex")
	state=Combat.begin(dummy(0),50,60,1,0,1,[],{"tactics":true});state.enemy.hp=100;state.p_time=100;state.e_hits=1;Combat.step(state)
	check(state.enemy.hp==104,"Regrowth bite mends enemy")
	state=Combat.begin(dummy(),40,60,1,0,1,[],{"tactics":true,"ability":"guard"});state.shield=8;state.p_time=100;Combat.use_ability(state);Combat.step(state)
	check(state.shield==8,"Guard preserves acid shield")
	check(not Combat.needs_decision(state),"Spent ability never creates pointless mandatory pauses")
	var saved_bindings=g.controls.bindings.duplicate();saved_bindings.erase("ability");saved_bindings.heal=KEY_F;g.controls.restore(saved_bindings)
	check(g.controls.bindings.heal==KEY_F and not g.controls.bindings.has("ability"),"Removing active ability preserves other customized keys")
	g.controls.restore(g.controls.DEFAULTS)
	# Element behavior is independent of existing percentage bonuses.
	state=Combat.begin(dummy(),60,60,1,0,1,["shatter"],{"tactics":true,"ice":1});state.e_time=100
	for i in range(3):Combat.step(state)
	check(state.ice_triggered and state.disrupted and state.e_time>100,"Third chilling hit interrupts once")
	state=Combat.begin(dummy(),60,60,1,0,1,["bulwark"],{"tactics":true,"acid":1});state.e_time=100
	Combat.step(state);Combat.step(state);check(state.shield==8 and state.acid_triggered,"Acid break grants shield")
	Combat.step(state);check(state.shield==8,"Acid shield cannot be farmed repeatedly")
	g.new_run(5);preload("res://tools/test_equipment.gd").arm(g);g.relics=["wildfire","contagion"];g.recalculate_stats();g.battle={"poisoned":true,"fire_until":5.0,"time":2.0};g.rooms[g.room].entities.clear();var neighbor=dummy();g.rooms[g.room].entities[Vector2i(5,5)]=neighbor
	g.tactics.victory(dummy(),Vector2i(3,5));check(neighbor.hp==188 and g.toxic_echo==0.10,"Burning kill damages nearby foe and poison carries forward")
	state=Combat.begin(dummy(),60,60,1,0,1,[],{"tactics":true,"toxic_echo":0.10,"poison":1});check(state.poisoned and is_equal_approx(Combat.poison_weak(state),0.28),"Carried poison affects opening attack and status math")
	# Runic Sight improves rewards; it never buys permission to solve.
	var vault_location=[];var curse_location=[]
	for seed_value in range(30):
		g.new_run(seed_value);preload("res://tools/test_equipment.gd").arm(g)
		for coord in g.rooms:
			for tile in g.rooms[coord].entities:
				if g.rooms[coord].entities[tile].kind=="reliquary":vault_location=[coord,tile]
		if not vault_location.is_empty():break
	g.room=vault_location[0];var tile=vault_location[1];var vault=g.rooms[g.room].entities[tile];g.dungeon_threads.touch(tile,vault)
	check(g.mode=="runes" and g.run_skills.is_empty(),"Fresh character enters rune puzzle")
	for rune in vault.order:g.action("rune:"+rune)
	check(g.mode=="vault_reward","Fresh character solves complete puzzle")
	g.action("vault_pick:0");var items=g.inventory.size();g.mode="vault_reward";g.action("vault_pick:0");check(g.inventory.size()==items,"Rune reward cannot be claimed twice")
	g.skills={"kindling":1,"cartography":1,"runic_sight":1};g.new_run(g.run_seed);preload("res://tools/test_equipment.gd").arm(g)
	for coord in g.rooms:
		for p in g.rooms[coord].entities:
			var e=g.rooms[coord].entities[p]
			if e.kind=="reliquary":check(e.rewards[2].rarity==2,"Runic Sight improves fixed optional reward")
	for seed2 in range(30):
		g.new_run(seed2);preload("res://tools/test_equipment.gd").arm(g)
		for coord in g.rooms:
			for p in g.rooms[coord].entities:
				if g.rooms[coord].entities[p].get("cursed",false):curse_location=[coord,p]
		if not curse_location.is_empty():break
	g.room=curse_location[0];tile=curse_location[1];var chest=g.rooms[g.room].entities[tile];g.rooms[g.room].entities.erase(chest.guardian);g.hp=8
	g.open_chest(tile);check(g.mode=="curse","Cursed chest explains price before paying")
	g.action("curse_blood");check(g.hp==8 and g.mode=="curse","HP payment cannot kill")
	g.shards=4;var prior_items=g.inventory.size();var reward=chest.item.duplicate(true);g.action("curse_embers")
	check(g.mode=="loot" and g.inventory.size()==prior_items+1 and g.inventory.back()==reward and g.shards==9,"Ember cost paid once, then normal gilded reward")
	# Continuous encounters still support an explicit Escape pause and Continue.
	g.new_run(12);preload("res://tools/test_equipment.gd").arm(g);g.session.enabled=true;g.session.active=true;g.session.preferences.tutorial_done=true;g.hp=g.max_hp
	var enemy=dummy(1);enemy.hp=100;enemy.max=100;g.rooms[g.room].entities[Vector2i(3,5)]=enemy;g.move_player(Vector2i.RIGHT)
	g._process(0.05);check(g.mode=="fight" and not g.battle.waiting,"Encounter flows without an ability prompt")
	g.session.pause();var before_clock=g.clock;g._process(3.0);check(g.clock==before_clock,"Explicit pause freezes combat")
	check(g.session.checkpoint() and g.session.continue_run() and not g.battle.waiting,"Continue restores uninterrupted combat")
	check(g.relic_pool().size()==16,"New runs offer all elemental behavior relics")
	g.run_rules=3
	check(g.relic_pool().size()==12 and "wildfire" not in g.relic_pool(),"Legacy runs only offer relics whose behavior their combat supports")
	g.run_rules=4
	# Legacy 0.3 saves gain default fields without changing the active rule set.
	var snapshot=g.session.snapshot();snapshot.state.run_rules=3;snapshot.state.erase("active_ability");snapshot.state.erase("toxic_echo")
	check(g.session.valid(snapshot) and snapshot.state.run_rules==3 and snapshot.state.active_ability=="guard","Old Continue retains old rules and migrates new fields")
	g.session.enabled=false
	for suffix in ["",".tmp",".run",".run.bak",".run.tmp",".settings",".settings.bak",".settings.tmp"]:
		if FileAccess.file_exists(PATH+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH+suffix))
	g.queue_free()
	if failures.is_empty():print("PASS: %d tactical-slice checks; 500 floors, encounter diversity, skill-free riddles, automatic flow, elemental behaviors, zero-meta boss viability and save migration."%checks)
	else:
		for message in failures:push_error(message)
	quit(0 if failures.is_empty() else 1)
