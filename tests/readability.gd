extends SceneTree
const UI=preload("res://choice_ui.gd")
const Fill=preload("res://room_detail.gd")
var checks=0
var failed=[]
func check(ok: bool,msg: String) -> void:
	checks+=1
	if not ok and failed.size()<15:failed.append(msg)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var g=load("res://main.tscn").instantiate();g.save_path="res://tests/.readability.json";root.add_child(g);preload("res://tools/test_equipment.gd").arm(g);await process_frame
	g.session.enabled=false
	check(is_equal_approx(UI.interval(1.25),0.8),"1.25 attacks/s displays every 0.8s")
	check(UI.timing(2)=="Every 0.50s","Interval text has explicit seconds")
	check(g.format_delta("vampirism",0.05)=="+5.0%","Vamp comparison uses percentages")
	check(g.choice_ui.display_stats(g.Gear.make("weapon",1,0)).has("speed"),"Even ordinary swords show their equipped interval")
	var total_walls=0;var total_urns=0
	for seed_value in range(100):
		g.new_run(seed_value);preload("res://tools/test_equipment.gd").arm(g);g.run_rules=5;g.generate_floor()
		var before={};var future_before={}
		for coord in g.rooms:before[coord]=g.dungeon_threads.reachable(g.rooms[coord]);future_before[coord]=Fill.unlocked(g.rooms[coord])
		g.run_rules=6;Fill.fill(g)
		for coord in g.rooms:
			var d=g.rooms[coord];var after=g.dungeon_threads.reachable(d)
			var future_after=Fill.unlocked(d)
			for tile in future_before[coord]:
				if not d.walls.has(tile):check(future_after.has(tile),"Cover preserves future routes after opening gates")
			if coord!=g.boss_room:check(d.walls.size()>0 and d.get("formation","")!="","Authored non-boss rooms have cover and a named formation")
			total_walls+=int(d.get("added_walls",0))
			for tile in before[coord]:
				if not d.walls.has(tile):check(after.has(tile),"Cover preserves every previously reachable remaining tile")
			for tile in d.entities:
				var e=d.entities[tile]
				if e.kind=="urn":total_urns+=1;check(after.has(tile),"Urns are reachable")
				if e.get("room_extra",false):
					check(coord not in [Vector2i.ZERO,g.boss_room],"Extra combat stays away from the opening and boss rooms")
					var plain=e.duplicate();plain.erase("room_extra");check(g.enemy_xp(e)*2<=g.enemy_xp(plain),"Extra enemies have reduced XP rewards")
	g.mode="play";g.room=Vector2i.ZERO;g.pos=Vector2i(2,5);g.hp=g.max_hp-4;var before_hp=g.hp
	g.rooms[g.room].entities[Vector2i(3,5)]={"kind":"urn","contents":0};g.rooms[g.room].walls.erase(Vector2i(3,5));g.move_player(Vector2i.RIGHT)
	check(g.hp==before_hp+2 and not g.rooms[g.room].entities.has(Vector2i(3,5)),"Urn interaction heals and consumes exactly once")
	g.mode="relic";g.choices=["cinder","haste","steamglass","bloom"];g.menu_keyboard=true;g.session.focused=0;g.queue_redraw();await process_frame
	g.mode="equipment";g.inventory.append(g.Gear.make("weapon",2,2,["speed","vampirism"],"dagger"));g.selected_item=g.inventory.size()-1;g.queue_redraw();await process_frame
	g.session.enabled=false;g.queue_free();await process_frame
	if failed.is_empty():print("PASS: %d readability checks; 100 dense floors, %d extra walls, %d reachable urns, interval math and UI states."%[checks,total_walls,total_urns]);quit(0)
	else:
		for error in failed:push_error(error)
		quit(1)
