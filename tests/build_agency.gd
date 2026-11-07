extends SceneTree
const Stats=preload("res://build_stats.gd")
var g
var checks=0
var failures=[]
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok and failures.size()<30:failures.append(label)
func accessible_before_combat(data: Dictionary) -> Dictionary:
	var start=Vector2i(2,5);var seen={start:true};var queue=[start]
	while not queue.is_empty():
		var p=queue.pop_front()
		for direction in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
			var next=p+direction
			if seen.has(next) or not data.bounds.grow(-1).has_point(next) or data.walls.has(next):continue
			if data.entities.get(next,{}).get("kind","") in ["enemy","chest","water","crack","reliquary"]:continue
			seen[next]=true;queue.append(next)
	return seen
func _initialize() -> void:call_deferred("run")
func run() -> void:
	g=load("res://main.tscn").instantiate();g.save_path="res://tests/.agency010.json";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false)
	for seed_value in range(100):
		g.new_run(seed_value);var caches=0;var tables=0
		for coord in g.rooms:
			var seen=preload("res://room_detail.gd").unlocked(g.rooms[coord])
			for tile in g.rooms[coord].entities:
				var e=g.rooms[coord].entities[tile]
				if e.kind=="build_cache":caches+=1
				if e.kind=="salvage":tables+=1;check(seen.has(tile),"Forge remains reachable")
		var data=g.rooms[Vector2i.ZERO];var chest:Vector2i=data.chest;var accessible=accessible_before_combat(data);var adjacent=false
		for direction in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
			if accessible.has(chest+direction):adjacent=true
		check(caches==0 and tables==1 and data.entities[chest].item.slot=="weapon" and adjacent,"Random starter weapon chest is reachable, with one forge and no choice cache")
	g.new_run(42)
	g.inventory=[g.make_gear("weapon",3,2,["fire_dps","vampirism"],"ember"),g.make_gear("amulet",4,2,["vampirism","crit_mult"]),g.make_gear("helmet",3,1,["vampirism"]),g.make_gear("weapon",2,1,["ice_slow"],"dagger")]
	g.inventory[1]["amulet_focus"]="health"
	g.equipped={"weapon":0,"amulet":1,"helmet":2};g.base_elements.fire=2;g.run_skills={"fire_mastery":2,"might":3};g.hp=25;g.recalculate_stats()
	var s=Stats.calculate(g)
	for key in g.build_view.active(s)+["attack","armor","max_hp","interval"]:check(not g.build_view.details(key,s).is_empty(),"Active stat details render with valid formatting: "+key)
	check(is_equal_approx(s.vampirism,minf(0.35,g.gear_stats.vampirism)),"Vampirism sums all equipped pieces and respects cap")
	check(is_equal_approx(s.fire,g.Combat.fire_damage({"build":g.combat_build()})),"Fire total equals live combat, including mastery")
	check(s.attack==g.attack and s.armor==g.armor and s.speed==g.speed and s.max_hp==g.max_hp,"Authoritative totals match actual stats")
	check("poison" not in g.build_view.active(s),"Inactive poison is hidden")
	var before=var_to_bytes([g.inventory,g.equipped,g.hp,g.rng.state,g.gear_stats,g.elements]);var preview=Stats.prospective(g,3)
	check(before==var_to_bytes([g.inventory,g.equipped,g.hp,g.rng.state,g.gear_stats,g.elements]),"Equipment preview does not mutate the run or RNG")
	g.equipped.weapon=3;g.recalculate_stats();check(preview.attack==g.attack and preview.speed==g.speed and preview.fire==Stats.calculate(g).fire,"Preview predicts real equip result")
	g.inventory[3].affixes=["poison_weak"];g.recalculate_stats();check("poison" in g.build_view.active(Stats.calculate(g)) and g.elements.poison==0,"Gear-only poison remains visible even without stacks")
	g.inventory[3].affixes=["vampirism"];g.inventory[3].level=200;g.recalculate_stats();check(Stats.calculate(g).vampirism==0.35,"Vamp cap is applied at extreme levels")
	# Sorting only changes a view of indices; kept gear is protected from destructive actions.
	g.equipment_slot="weapon";g.inventory_tools.sort_mode=0;var ordered=g.inventory_tools.filtered();check(ordered[0]==3 and ordered[1]==0,"Level sorting returns correct indices")
	g.selected_item=0;g.mode="equipment";g.action("keep_selected");check(g.inventory[0].kept,"Keep toggles on an item")
	g.inventory_tools.filter_mode=3;check(g.inventory_tools.filtered()==[0],"Kept filter only includes protected items")
	check(0 not in g.bonus_transfer.candidates(true) and 3 not in g.bonus_transfer.candidates(true),"Donor list excludes kept and equipped gear")
	g.inventory_tools.filter_mode=0
	# Controlled transfer: donor is before recipient in the array, recipient is equipped.
	g.new_run(88);g.inventory=[g.make_gear("helmet",12,2,["vampirism","speed"]),g.make_gear("weapon",2,1,["fire_dps"]),g.make_gear("amulet",2,1,["health"])];g.equipped={"weapon":1,"amulet":2};g.iron=2;g.recalculate_stats()
	var location=[]
	for coord in g.rooms:
		for tile in g.rooms[coord].entities:
			if g.rooms[coord].entities[tile].kind=="salvage":location=[coord,tile]
	g.room=location[0];g.bonus_transfer.open(location[1]);g.action("transfer:donor:0");g.action("transfer:recipient:1");g.action("transfer:source:vampirism");g.action("transfer:replace:fire_dps")
	check(g.bonus_transfer.ready(),"Valid transfer can commit")
	var proposal=g.bonus_transfer.proposed();check(proposal.level==2 and proposal.rarity==1 and proposal.affixes==["vampirism"],"Transfer preserves recipient level and rarity")
	check(g.Gear.stats(proposal).vampirism<g.Gear.stats(g.inventory[0]).vampirism,"Copied identity recalculates at recipient strength, not high-level donor strength")
	g.inventory[0]["kept"]=true;check(not g.bonus_transfer.ready(),"Protecting a donor invalidates the pending transfer")
	g.inventory[0].kept=false;g.iron=0;check(not g.bonus_transfer.ready(),"Transfer cannot spend missing iron");g.iron=2
	var bytes_before=var_to_bytes([g.inventory,g.equipped,g.hp,g.rng.state]);var predicted=Stats.prospective(g,1,{1:proposal});check(bytes_before==var_to_bytes([g.inventory,g.equipped,g.hp,g.rng.state]),"Transfer preview is pure")
	var draft=g.session.snapshot();check(g.session.valid(draft),"Transfer screen is a valid resumable save")
	check(g.session.atomic_write("res://tests/.agency-transfer.json",draft),"Transfer draft can be serialized")
	var saved=g.session.read_file("res://tests/.agency-transfer.json");check(g.session.valid(saved) and saved.state.run_metrics.transfer_draft.source=="vampirism","Transfer choice survives a real save roundtrip")
	g.action("transfer:commit");check(g.inventory.size()==2 and g.iron==1 and g.equipped.weapon==0 and g.equipped.amulet==1,"Donor consumed once; all equipped indices reindexed")
	check(g.mode=="equipment" and g.forge_menu.used("transfer") and predicted.vampirism==Stats.calculate(g).vampirism,"Transferred stats match preview and table is spent")
	g.bonus_transfer.open(location[1]);g.action("transfer:donor:0");check(not g.bonus_transfer.ready(),"Spent table cannot transfer again")
	g.mode="equipment";g.inventory[0]["kept"]=true;g.selected_item=0;g.equipped.erase("weapon");var count=g.inventory.size();g.salvage_selected();check(g.inventory.size()==count,"Kept gear cannot be scrapped")
	g.mode="equipment";g.action("build_open");check(g.session.saved_mode()=="equipment","Build detail save resumes underlying equipment screen");g.controls.back();check(g.mode=="equipment","Escape returns from build to equipment")
	# Isolated recap attribution, including overkill and zero-damage guard hits.
	g.new_run(99);g.fight=g.make_enemy(0,2);g.fight.hp=500;g.fight.max=500;g.fight.armor=20;g.fight["position"]=Vector2i(5,5)
	g.battle=g.Combat.begin(g.fight,100,100,20,5,1,[],{"auto_flow":true,"fire":1,"vampirism":0.1});g.combat_review.begin()
	for i in range(8):
		var hit=g.Combat.step(g.battle);g.combat_review.event(hit)
	check(g.run_metrics.last_fight.physical>0 and g.run_metrics.last_fight.fire>0 and g.run_metrics.last_fight.armor>0,"Recap separates physical, fire and armor mitigation")
	var e=g.fight.duplicate(true);e.hp=1;e.max=1;e.armor=20;var state=g.Combat.begin(e,100,100,200,1,1,[],{"auto_flow":true});var hit=g.Combat.step(state);check(hit.armor_prevented==0 and hit.physical_damage==1,"Overkill does not inflate armor mitigation")
	var leech=e.duplicate(true);leech.type=0;leech.hp=100;leech.max=200;leech["family"]="leech";leech.attack=20
	state=g.Combat.begin(leech,100,100,1,0,1,[],{"auto_flow":true});state.e_time=0;state.p_time=100;hit=g.Combat.step(state);check(hit.enemy_heal>0,"Enemy lifesteal contributes to the recap healing total")
	g.mode="dead";g.action("recap_open");check(g.session.saved_mode()=="dead","Recap saves underlying terminal state");g.controls.back();check(g.mode=="dead","Escape returns to death screen")
	if g.inventory.is_empty():g.inventory.append(g.make_gear("weapon",1,0))
	# Every new screen can render, including large text and persisted draft state.
	g.session.preferences.large_text=true
	for mode in ["equipment","build","recap","loot","character","dead"]:
		g.mode=mode
		if mode=="loot":g.last_loot_index=0
		g.queue_redraw();await process_frame
	print("BUILD AGENCY: %d checks / %d failures"%[checks,failures.size()])
	for failure in failures:print("FAIL: "+failure)
	g.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
