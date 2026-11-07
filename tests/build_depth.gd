extends SceneTree
var g
var checks=0
var failures=[]
const SAVE="res://tests/.depth09.json"
func check(ok: bool,msg: String) -> void:
	checks+=1
	if not ok and failures.size()<25:failures.append(msg)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	g=load("res://main.tscn").instantiate();g.save_path=SAVE;root.add_child(g);preload("res://tools/test_equipment.gd").arm(g);await process_frame;g.session.enabled=false;g.set_process(false)
	var formations={};var ward_count=0
	for seed_value in range(80):
		g.new_run(seed_value);preload("res://tools/test_equipment.gd").arm(g)
		for coord in g.rooms:
			var d=g.rooms[coord];var seen=preload("res://room_detail.gd").unlocked(d)
			if coord!=g.boss_room:formations[d.formation]=true
			for tile in d.entities:
				var e=d.entities[tile]
				if e.kind in ["wardstone","provisions"]:check(seen.has(tile),"Preparation choices remain physically reachable")
				if e.kind=="wardstone":
					ward_count+=1;var enemy=g.rooms[e.target_room].entities[e.guardian]
					check(enemy.ward_active and enemy.mending and not enemy.get("gatekeeper",false),"Rune targets optional guardian, not a mandatory passage")
					var before=g.Combat.begin(enemy,100,100,15,5,1,[],g.combat_build())
					check(before.regen_time!=INF and before.regen_amount==enemy.regen,"Rune healing is real combat behavior")
	check(formations.size()==4,"All four authored formations appear")
	check(ward_count>60,"Healing rune encounters appear reliably")
	g.new_run(42);preload("res://tools/test_equipment.gd").arm(g)
	for coord in g.rooms:
		for tile in g.rooms[coord].entities.keys():
			var e=g.rooms[coord].entities[tile]
			if e.kind=="wardstone":
				g.room=coord;var guard=g.rooms[e.target_room].entities[e.guardian];g.world_choices.touch(tile,e);g.action("ward_disable")
				check(not guard.ward_active and guard.mending==guard.ward_base_mending,"Disarming removes only the rune bonus")
				var after=g.Combat.begin(guard,100,100,15,5,1,[],g.combat_build())
				check(guard.ward_base_mending or after.regen_time==INF,"Disarmed guardian does not retain bonus regeneration")
	g.new_run(43);preload("res://tools/test_equipment.gd").arm(g)
	for coord in g.rooms:
		for tile in g.rooms[coord].entities:
			var e=g.rooms[coord].entities[tile]
			if e.get("ward_active",false):
				var chest=g.rooms[e.ward_reward_room].entities[e.ward_chest];var level=chest.item.level;g.world_choices.enemy_defeated(e)
				check(chest.item.rarity==2 and chest.item.level==level+1,"Fighting powered earns the pre-generated stronger item")
	for key_seed in range(44,80):
		g.new_run(key_seed);preload("res://tools/test_equipment.gd").arm(g)
		if g.floor_flags.has("key_room"):break
	check(g.floor_flags.has("key_room"),"Supply test uses a floor with a real Copper key")
	for coord in g.rooms:
		for tile in g.rooms[coord].entities.keys():
			var e=g.rooms[coord].entities[tile]
			if e.kind=="provisions":
				g.room=coord;g.world_choices.touch(tile,e);var potions=g.potions;var iron=g.iron
				g.floor_keys={};g.action("provisions_buy");check(g.mode=="decision" and g.potions==potions,"A missing key cannot buy supplies")
				g.floor_keys={"copper":true};g.session.enabled=true;g.session.active=true
				check(g.session.checkpoint() and g.session.continue_run() and g.mode=="decision","Preparation choice survives Continue")
				g.action("provisions_buy");check(not g.floor_keys.has("copper") and g.potions==potions+1 and g.iron==iron+1,"Supply trade consumes the shared key exactly once")
				g.action("provisions_buy");check(g.potions==potions+1,"Trade cannot be repeated")
	g.session.enabled=false
	for key_seed in range(50,90):
		g.new_run(key_seed);preload("res://tools/test_equipment.gd").arm(g)
		if g.floor_flags.has("key_room"):break
	for coord in g.rooms:
		for tile in g.rooms[coord].entities.keys():
			var e=g.rooms[coord].entities[tile]
			if e.kind=="chest" and e.has("key_id"):
				g.room=coord;g.floor_keys={"copper":true};g.rooms[coord].entities.erase(e.guardian)
				check(g.open_chest(tile) and not g.floor_keys.has("copper"),"Opening the treasure consumes the same key")
				check(g.floor_flags.get("copper_spent","")=="treasure","The trade-off remembers which reward used the key")
	g.replay.draft={"mode":"daily","vows":{}};g.career.mastery=g.mastery.empty_progress();g.new_run(1);preload("res://tools/test_equipment.gd").arm(g);var daily=var_to_bytes(g.rooms)
	g.career.mastery={"vamp_healed":999,"greatblade_kills":999,"fire_bosses":999,"runes_solved":999};g.new_run(999);preload("res://tools/test_equipment.gd").arm(g)
	check(var_to_bytes(g.rooms)==daily,"Daily generation is independent of earned build unlocks")
	g.replay.draft={"mode":"standard","vows":{}};g.new_run(55);preload("res://tools/test_equipment.gd").arm(g)
	g.session.enabled=false;g.career=g.replay.new_career();g.demo_run=false
	g.mastery.add("vamp_healed",59);check(not g.mastery.unlocked("bloodletter"),"Achievement requires its target")
	g.mastery.add("vamp_healed",1);check(g.mastery.unlocked("bloodletter"),"Vampirism achievement unlocks Bloodletter")
	g.mastery.add("greatblade_kills",15);g.mastery.add("fire_bosses",3);g.mastery.add("runes_solved",3)
	for id in ["bloodletter","winterblade","caustic"]:
		var archetype=g.mastery.GOALS[id].archetype;var item=g.Gear.make("weapon",4,1,["evade"],archetype);item["variant"]=id
		var stats=g.Gear.stats(item);item.level+=1;var fresh=g.Gear.make("weapon",5,1,["evade"],archetype);fresh["variant"]=id
		check(g.Gear.stats(item)==g.Gear.stats(fresh),"Variant iron upgrades recompute instead of compounding")
		if id=="bloodletter":check(stats.vampirism>0 and stats.evade>0,"Bloodletter trades innate evade but preserves evade affixes")
	g.new_run(45);preload("res://tools/test_equipment.gd").arm(g);g.floor_number=2;g.generate_floor();var cache_location=[]
	for coord in g.rooms:
		for tile in g.rooms[coord].entities:
			if g.rooms[coord].entities[tile].kind=="build_cache":cache_location=[coord,tile]
	check(not cache_location.is_empty(),"Puzzle mastery unlocks the build-cache room event")
	if not cache_location.is_empty():
		g.room=cache_location[0];var tile=cache_location[1];var e=g.rooms[g.room].entities[tile];var expected=e.items[1].duplicate(true);g.world_choices.touch(tile,e);g.action("cache_pick:1")
		check(g.mode=="loot" and g.inventory.back()==expected and not g.rooms[g.room].entities.has(tile),"Build cache gives exactly the chosen fixed item")
	g.mode="play";var enemy=g.make_enemy(1,2);enemy.hp=100;enemy.max=100;g.gear_stats.evade=0.25;g.gear_stats.vampirism=0.16;var rng_before=g.rng.state;var item_before=g.inventory.duplicate(true);var p=g.fight_preview.estimate(enemy)
	check(p.low_loss<=p.high_loss and p.label in ["Favorable","Dangerous","Deadly"],"Estimated previews give coherent risk and damage ranges")
	check(g.rng.state==rng_before and g.inventory==item_before,"Inspecting does not consume world randomness or mutate gear")
	check(g.fight_preview.estimate(enemy)==p,"Repeated inspection is stable")
	g.mode="settings";g.session.preferences.exact_forecasts=true;g.action("exact_forecasts");check(not g.session.preferences.exact_forecasts,"Exact forecast action remains disabled")
	g.session.active=true;check(g.playtest.export_report("res://tests/.depthreports"),"Playtest reports export locally")
	var report=JSON.parse_string(FileAccess.get_file_as_string(g.playtest.last_path));check(report.build=="0.16.0" and report.active_run.has("equipment") and not report.has("character_name"),"Reports contain build decisions without character identity")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(g.playtest.last_path));DirAccess.remove_absolute(ProjectSettings.globalize_path("res://tests/.depthreports"))
	g.session.enabled=true;g.session.active=true;g.mode="play";check(g.session.checkpoint() and g.session.continue_run() and g.mastery.unlocked("bloodletter"),"Achievement progress survives active-run save restoration")
	g.mode="codex";g.replay.codex_page=3;g.queue_redraw();await process_frame;await process_frame
	var has_unlock_navigation=false
	for b in g.buttons:
		if b.id=="codex_next":has_unlock_navigation=true
	check(has_unlock_navigation,"Build unlock screen renders and remains navigable")
	g.mode="play";g.room=Vector2i.ZERO;g.rooms[g.room].entities[Vector2i(3,5)]={"kind":"build_cache","items":[g.Gear.make("weapon",2,1,["fire_dps"],"ember"),g.Gear.make("amulet",2,1,["ice_slow"])]};g.puzzle_tile=Vector2i(3,5);g.mode="decision";g.queue_redraw();await process_frame;await process_frame
	check(g.buttons.size()==3,"Build cache shows two rewards and a leave action")
	g.mode="settings";g.queue_redraw();await process_frame;await process_frame
	var settings_ids=[]
	for b in g.buttons:settings_ids.append(b.id)
	check("exact_forecasts" not in settings_ids and "export_playtest" in settings_ids,"Exact forecast toggle is absent and report controls remain")
	g.session.enabled=false;g.queue_free();g=null;await process_frame
	for suffix in ["",".tmp",".run",".run.bak",".run.tmp",".settings",".settings.bak"]:
		if FileAccess.file_exists(SAVE+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE+suffix))
	if failures.is_empty():print("PASS: %d build-depth checks; authored rooms, live rune counters, key trade, mastery, variant upgrades, choices/save migration, risk previews and report export."%checks);quit(0)
	else:
		for message in failures:push_error(message)
		quit(1)
