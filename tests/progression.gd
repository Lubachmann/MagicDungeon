extends SceneTree
const Gear=preload("res://equipment.gd")
const Combat=preload("res://combat.gd")
var game
var checks=0
var failures: Array[String]=[]
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok and failures.size()<20:failures.append(message)
func _initialize() -> void:call_deferred("run")
func reachable(data: Dictionary) -> Dictionary:
	var seen={Vector2i(6,5):true}
	var todo=[Vector2i(6,5)]
	while not todo.is_empty():
		var p=todo.pop_front()
		for dir in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
			var n=p+dir
			if not data.bounds.grow(-1).has_point(n) or seen.has(n):continue
			if data.walls.has(n) and data.entities.get(n,{}).get("kind","")!="crack":continue
			seen[n]=true
			todo.append(n)
	return seen
func run() -> void:
	game=load("res://main.gd").new()
	game.save_path="res://tests/.progression-save.json"
	root.add_child(game);preload("res://tools/test_equipment.gd").arm(game)
	game.set_process(false)
	game.muted=true
	check(Gear.stats(Gear.make("weapon",1,0)).attack==5,"Common L1 sword +5")
	check(Gear.stats(Gear.make("weapon",2,0)).attack==7,"Common L2 sword +7")
	var rare=Gear.stats(Gear.make("weapon",1,1,["crit_chance"]))
	check(rare.attack==5 and rare.crit_chance==0.05,"Rare L1 sword +5 and 5% crit")
	var rare_speed=Gear.stats(Gear.make("weapon",1,1,["speed"]))
	check(rare_speed.attack==5 and rare_speed.speed==0.1,"Rare speed sword")
	var epic=Gear.make("weapon",1,2,["speed","fire_dps"])
	var epic_stats=Gear.stats(epic)
	check(epic_stats.attack==7 and epic_stats.speed==0.2 and epic_stats.fire_dps==2,"Very rare example")
	for slot in Gear.SLOTS:
		for rarity in range(3):
			var item=Gear.make(slot,1,rarity,["speed","fire_dps"].slice(0,rarity))
			for level in range(1,21):
				item.level=level
				check(Gear.stats(item)==Gear.stats(Gear.make(slot,level,rarity,item.affixes)),"Upgraded stats equal fresh same-level stats")
	check(game.xp_required(1)==40 and game.xp_required(2)==65 and game.xp_required(3)==100,"XP curve")
	game.new_run(22);preload("res://tools/test_equipment.gd").arm(game)
	game.gain_xp(39)
	check(game.character_level==1 and game.experience==39,"XP below threshold")
	game.gain_xp(1)
	check(game.character_level==2 and game.experience==0 and game.pending_levels==1,"Exact level threshold")
	game.resume_play()
	check(game.mode=="relic" and game.choices.size()==3,"Level-up offers three relic choices")
	game.action("relic0")
	check(game.mode=="play" and game.relics.size()==1,"Level-up choice resolves")
	game.gain_xp(165)
	check(game.character_level==4 and game.experience==0 and game.pending_levels==2,"XP overflow across two levels")
	game.resume_play()
	game.action("relic0")
	check(game.mode=="relic","Second level reward is queued")
	game.action("relic0")
	check(game.mode=="play" and game.relics.size()==3,"All queued rewards resolve")
	# Every floor has gear and iron, with no direct buff or relic pickups.
	for seed_value in range(100):
		game.new_run(seed_value);preload("res://tools/test_equipment.gd").arm(game)
		for floor_index in range(1,6):
			var slots: Dictionary={}
			var gear_count=0
			var iron_count=0
			for coord in game.rooms:
				var data=game.rooms[coord]
				var accessible=reachable(data)
				for tile in data.entities:
					var entity=data.entities[tile]
					check(accessible.has(tile),"All floor entities reachable after gates")
					check(entity.kind not in ["relic","upgrade","shrine"],"No ground buffs/relics")
					if entity.kind=="chest":
						gear_count+=1
						slots[entity.item.slot]=true
						check(entity.item.level in [floor_index,floor_index+1],"Floor-scaled item levels")
						check(entity.item.affixes.size()==entity.item.rarity,"Rarity controls affix count")
					if entity.kind=="iron":iron_count+=1
			check(slots.size()==5,"All five equipment slots represented per floor")
			check(gear_count==8,"Eight gear chests per floor")
			check(iron_count==3,"Three iron pickups including the forge deposit")
			if floor_index<5:
				game.mode="floor"
				game.ascend_floor()
				check(game.floor_number==floor_index+1,"Ascending increases floor")
	# Genuine pickups and inventory interactions.
	game.new_run(4);preload("res://tools/test_equipment.gd").arm(game)
	game.rooms[game.room].entities[Vector2i(3,5)]={"kind":"chest","tier":2,"style":"stash","guardian":Vector2i(-1,-1),"item":epic.duplicate(true)}
	game.move_player(Vector2i.RIGHT)
	check(game.inventory.size()==2 and game.attack==14,"Pickup adds gear without auto-equipping")
	game.action("loot_inventory")
	game.action("select:1")
	game.action("equip_selected")
	check(game.attack==16 and is_equal_approx(game.speed,1.2) and game.combat_build().fire_dps==2,"Equipping updates all stats")
	var original=game.inventory[1].duplicate(true)
	game.iron=2
	game.action("iron_selected")
	game.action("iron_selected")
	check(game.inventory[1].level==3 and game.iron==0 and game.inventory[1].affixes==original.affixes,"Iron preserves rarity and affixes")
	check(game.attack==22 and is_equal_approx(game.speed,1.28) and game.combat_build().fire_dps==4,"Level-three very rare stats recomputed")
	game.action("iron_selected")
	check(game.inventory[1].level==3,"No upgrade without iron")
	game.action("unequip_selected")
	check(game.attack==9 and game.speed==1 and game.combat_build().fire_dps==0,"Unequipping removes all effects")
	game.action("equip_selected")
	check(game.attack==22,"Reequip has no double stacking")
	game.inventory.append(Gear.make("armor",1,0))
	game.action("select:2")
	game.hp=20
	game.action("equip_selected")
	check(game.max_hp==56 and game.hp==20,"Health gear grants capacity without healing")
	game.equipment_slot="armor"
	game.action("unequip_selected")
	game.action("equip_selected")
	check(game.hp==20,"Repeated swaps cannot heal")
	game.action("close_equipment")
	# Partial HP, equipment, level XP, relics and abilities carry through stairs.
	game.gain_xp(45)
	game.resume_play()
	game.action("relic0")
	game.breaker=true
	game.boots=true
	var held=game.inventory.duplicate(true)
	var xp_before=game.experience
	var level_before=game.character_level
	var equipped_before=game.equipped.duplicate()
	game.room=game.boss_room
	game.pos=Vector2i(7,3)
	game.move_player(Vector2i.UP)
	check(game.mode=="play","Stairs locked before Warden")
	game.rooms[game.room].cleared=true
	game.move_player(Vector2i.UP)
	check(game.mode=="floor","Floor clear opens ascent prompt")
	var expected_ascent_hp=mini(game.max_hp,game.hp+ceili(game.max_hp*0.6))
	game.action("ascend")
	check(game.floor_number==2 and game.hp==expected_ascent_hp and game.inventory==held and game.equipped==equipped_before,"Ascent restores 60% max HP and preserves equipment")
	check(game.experience==xp_before and game.character_level==level_before and game.breaker and game.boots,"Ascent preserves character progression")
	var stronger=game.make_enemy(0,0)
	game.floor_number=1
	var weaker=game.make_enemy(0,0)
	check(stronger.hp>weaker.hp and stronger.attack>weaker.attack,"Enemy floor scaling")
	game.floor_number=5
	game.room=game.boss_room
	game.pos=Vector2i(7,3)
	game.rooms[game.room].cleared=true
	game.move_player(Vector2i.UP)
	check(game.mode=="won","Final floor wins the run")
	game.new_run(20);preload("res://tools/test_equipment.gd").arm(game)
	game.gain_xp(500)
	game.inventory.append(epic)
	game.iron=9
	game.floor_number=4
	game.finish_run(false)
	game.action("restart")
	check(game.floor_number==1 and game.character_level==1 and game.experience==0 and game.pending_levels==0,"Death resets floor and levels")
	check(game.inventory.size()==1 and game.inventory[0].name=="Sword" and game.equipped.weapon==0 and game.iron==0 and game.relics.is_empty(),"Restart uses the crafted starter and discards expedition gear and relics")
	# Combat forecast integration: all gear affix types, floor scaling and on-kill XP.
	for seed_value in range(100):
		game.new_run(seed_value);preload("res://tools/test_equipment.gd").arm(game)
		var item=Gear.make("weapon",seed_value%8+1,2,[Gear.AFFIXES[seed_value%Gear.AFFIXES.size()],"speed"])
		game.inventory.append(item)
		game.equipped.weapon=1
		game.recalculate_stats()
		game.hp=game.max_hp
		var enemy=game.make_enemy(seed_value%4,3)
		var expected=game.forecast(enemy)
		game.rooms[game.room].entities[Vector2i(3,5)]=enemy
		game.move_player(Vector2i.RIGHT)
		for tick in range(2000):
			if game.mode!="fight":break
			resolve_tick(0.05)
		check(game.battle.done and game.hp==expected.hp,"Gear forecast matches actual combat")
		if expected.won:check(game.experience>0 or game.character_level>1,"Victories grant XP")
	# Bomb kills grant XP and schedule level choices too.
	game.new_run(3);preload("res://tools/test_equipment.gd").arm(game)
	game.experience=39
	var weak=game.make_enemy(0,0)
	weak.hp=5
	game.rooms[game.room].entities[Vector2i(3,5)]=weak
	game.mode="bomb"
	game.throw_bomb(Vector2i(3,5))
	check(game.character_level==2 and game.mode=="relic","Bomb XP triggers level-up reward")
	game.queue_free()
	if FileAccess.file_exists("res://tests/.progression-save.json"):DirAccess.remove_absolute(ProjectSettings.globalize_path("res://tests/.progression-save.json"))
	if failures.is_empty():print("PASS: %d progression/equipment checks; 500 generated floors and 100 equipped combat builds."%checks)
	else:
		for failure in failures:push_error(failure)
	quit(0 if failures.is_empty() else 1)

func resolve_tick(delta: float) -> void:
	if game.mode=="fight" and game.battle.get("waiting",false):game.action("fight_continue")
	game._process(delta)
