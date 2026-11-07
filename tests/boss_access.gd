extends SceneTree
var game
var checks=0
var failures: Array[String]=[]
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok and failures.size()<12:failures.append(message)
func _initialize() -> void:call_deferred("run")
func reach_boss(data: Dictionary,hammer: bool,block_guard: bool) -> bool:
	var seen={Vector2i(6,5):true}
	var todo=[Vector2i(6,5)]
	while not todo.is_empty():
		var at=todo.pop_front()
		for dir in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
			var tile=at+dir
			if not data.bounds.grow(-1).has_point(tile) or seen.has(tile):continue
			var entity=data.entities.get(tile,{})
			var kind=entity.get("kind","")
			# Match actual collision: locked chests and locked stairs are impassable.
			if kind in ["chest","exit"]:continue
			if block_guard and tile==Vector2i(9,3):continue
			if data.walls.has(tile) and not (hammer and kind=="crack"):continue
			if kind=="water":continue
			if tile==Vector2i(6,3):return true
			seen[tile]=true
			todo.append(tile)
	return false
func run() -> void:
	game=load("res://main.gd").new()
	game.save_path="res://tests/.boss-save.json"
	root.add_child(game);preload("res://tools/test_equipment.gd").arm(game)
	game.muted=true
	game.set_process(false)
	for seed_value in range(100):
		game.new_run(seed_value);preload("res://tools/test_equipment.gd").arm(game)
		for floor_index in range(1,6):
			var data=game.rooms[game.boss_room]
			check(reach_boss(data,true,true),"Hammer route reaches boss while chest/stairs stay locked")
			check(reach_boss(data,false,false),"Champion route reaches boss while chest/stairs stay locked")
			check(not reach_boss(data,false,true),"Vault still requires one intended entrance")
			for tile in [Vector2i(4,3),Vector2i(5,3),Vector2i(7,3),Vector2i(8,3)]:
				check(not data.walls.has(tile) and data.entities.get(tile,{}).get("kind","") not in ["chest","exit"],"Boss corridor clear of locked rewards")
			if floor_index<5:game.mode="floor";game.ascend_floor()
	for west in [true,false]:
		game.new_run(41);preload("res://tools/test_equipment.gd").arm(game)
		game.room=game.boss_room
		game.pos=Vector2i(4,3) if west else Vector2i(8,3)
		var step=Vector2i.RIGHT if west else Vector2i.LEFT
		game.move_player(step)
		check(game.mode=="play","First approach step is free")
		game.move_player(step)
		check(game.mode=="fight" and game.fight.type==3,"Second approach step engages Warden")
	game.new_run(10);preload("res://tools/test_equipment.gd").arm(game)
	game.room=game.boss_room
	game.pos=Vector2i(7,3)
	game.move_player(Vector2i.UP)
	check(game.mode=="play" and game.pos==Vector2i(7,3),"Stairs stay locked before boss")
	var data=game.rooms[game.room]
	check(not game.open_chest(data.chest),"Reward stays locked before boss")
	data.entities.erase(Vector2i(6,3))
	data.cleared=true
	game.move_player(Vector2i.UP)
	check(game.mode=="floor","Victory stairs reachable without opening reward")
	game.mode="play"
	check(game.open_chest(data.chest),"Reward opens after boss")
	check(game.ui_frames.size()==2,"Licensed UI textures loaded")
	for texture in game.ui_frames.values():check(texture is Texture2D and texture.get_width()==40,"Nine-slice source dimensions")
	game.queue_free()
	if failures.is_empty():print("PASS: %d boss-access/UI checks across 500 floors; both approaches work with locked rewards."%checks)
	else:
		for failure in failures:push_error(failure)
	quit(0 if failures.is_empty() else 1)
