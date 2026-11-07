extends SceneTree
const Gear=preload("res://equipment.gd")
var game
var checks=0
var failures: Array[String]=[]
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok and failures.size()<20:failures.append(message)
func _initialize() -> void:call_deferred("run")
func walk(data: Dictionary,hammer: bool=true,boots: bool=true,blocked: Vector2i=Vector2i(-1,-1)) -> Dictionary:
	var seen={Vector2i(6,5):true}
	var todo=[Vector2i(6,5)]
	while not todo.is_empty():
		var at=todo.pop_front()
		for direction in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
			var tile=at+direction
			if not data.bounds.grow(-1).has_point(tile) or seen.has(tile) or tile==blocked:continue
			var kind=data.entities.get(tile,{}).get("kind","")
			if data.walls.has(tile) and not (hammer and kind=="crack"):continue
			if not boots and kind=="water":continue
			seen[tile]=true
			todo.append(tile)
	return seen
func run() -> void:
	game=load("res://main.gd").new()
	game.save_path="res://tests/.chest-save.json"
	root.add_child(game);preload("res://tools/test_equipment.gd").arm(game)
	game.muted=true
	game.set_process(false)
	var styles: Dictionary={}
	var corners: Dictionary={}
	for seed_value in range(100):
		game.new_run(seed_value);preload("res://tools/test_equipment.gd").arm(game)
		for floor_index in range(1,6):
			var count=0
			var slots: Dictionary={}
			for coord in game.rooms:
				var data=game.rooms[coord]
				var reachable=walk(data)
				for tile in data.entities:
					var entity=data.entities[tile]
					check(entity.kind!="equipment","No loose equipment")
					check(reachable.has(tile),"Unreachable seed %d floor %d role %s bounds %s tile %s kind %s"%[seed_value,floor_index,game.roles[coord],data.bounds,tile,entity.kind])
					if entity.kind!="chest":continue
					count+=1
					styles[entity.style]=true
					slots[entity.item.slot]=true
					check(entity.item.level in [floor_index,floor_index+1],"Floor scaled chest item")
					check(entity.item.affixes.size()==entity.item.rarity,"Item affixes match rarity")
					if entity.tier==2:check(entity.item.rarity>=1,"Ornate guarantees at least Rare")
					if entity.style in ["wall","water","guardian","winding"]:corners[tile]=true
					if entity.style=="wall":check(not walk(data,false,true).has(tile),"Hammer access required")
					if entity.style=="water":check(not walk(data,true,false).has(tile),"Boots access required")
					if entity.style in ["guardian","sentinel"]:check(not walk(data,true,true,entity.guardian).has(tile),"Monster physically blocks chest access")
				var b: Rect2i=data.bounds
				for landing in [Vector2i(b.position.x+1,5),Vector2i(b.end.x-2,5),Vector2i(6,b.position.y+1),Vector2i(6,b.end.y-2)]:
					check(reachable.has(landing) and not data.walls.has(landing) and not data.entities.has(landing),"Safe room doorway")
			check(count==8 and slots.size()==5,"Eight chests cover all equipment slots")
			if floor_index<5:game.mode="floor";game.ascend_floor()
	check(styles.size()==8 and corners.size()>=4,"Varied chest approaches and four rotated corners")
	game.new_run(5);preload("res://tools/test_equipment.gd").arm(game)
	game.room=game.boss_room
	var boss_data=game.rooms[game.room]
	var boss_chest: Vector2i=boss_data.chest
	var item_before=boss_data.entities[boss_chest].item.duplicate(true)
	check(not game.open_chest(boss_chest) and game.inventory.size()==1,"Living Warden seals reward")
	boss_data.entities.erase(Vector2i(6,3))
	check(game.open_chest(boss_chest),"Dead Warden unlocks chest")
	check(game.mode=="loot" and game.inventory.back()==item_before,"Chest reveals its pre-rolled item")
	check(not game.open_chest(boss_chest) and game.inventory.size()==2,"Chest cannot be looted twice")
	game.action("loot_keep")
	check(game.mode=="play" and game.equipped.weapon==0,"Keep does not auto-equip")
	game.room=Vector2i.ZERO
	var stash: Vector2i=game.rooms[game.room].chest
	game.open_chest(stash)
	var index=game.last_loot_index
	game.action("loot_inventory");game.action("equip_selected");game.action("close_equipment")
	check(game.equipped[game.inventory[index].slot]==index,"Equip from chest reward")
	check(game.rooms[game.room].entities[stash].kind=="opened_chest" and not game.room_has_chest(game.room),"Opened chest persists and map marker clears")
	game.room=game.hammer_room
	game.floor_keys["copper"]=true
	game.floor_flags.sun=true;game.floor_flags.moon=true
	game.open_chest(game.rooms[game.room].chest)
	game.action("loot_inventory")
	check(game.mode=="equipment" and game.selected_item==game.last_loot_index,"Compare opens new gear in inventory")
	for tier in range(3):
		var counts=[0,0,0]
		for i in range(10000):counts[game.chest_item(tier).rarity]+=1
		for rarity in range(3):check(absf(counts[rarity]/100.0-game.CHEST_ODDS[tier][rarity])<2.0,"Rarity rolls match stated chest odds")
	for slot in Gear.SLOTS:check(game.gear_icons[slot] is Texture2D and game.gear_icons[slot].get_width()>0,"Equipment icon loads")
	game.queue_free()
	if failures.is_empty():print("PASS: %d treasure checks; 500 floors, physical guardian access, chest odds, loot UI flow and icons."%checks)
	else:
		for failure in failures:push_error(failure)
	quit(0 if failures.is_empty() else 1)
