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
func run() -> void:
	game=load("res://main.gd").new()
	game.save_path="res://tests/.dark-save.json"
	root.add_child(game);preload("res://tools/test_equipment.gd").arm(game)
	game.set_process(false)
	game.muted=true
	check(game.ui_theme==0,"Gothic default")
	game.action("toggle_theme")
	check(game.ui_theme==1,"Warm alternative available")
	game.action("toggle_theme")
	check(game.ui_frames.gothic.get_width()>0 and game.ui_frames.warm.get_width()>0,"Both sourced UI frames loaded")
	var sword=Gear.stats(Gear.make("weapon",3,0,[],"balanced"))
	var dagger=Gear.stats(Gear.make("weapon",3,0,[],"dagger"))
	var heavy=Gear.stats(Gear.make("weapon",3,0,[],"greatblade"))
	var ember=Gear.stats(Gear.make("weapon",3,0,[],"ember"))
	check(dagger.attack<sword.attack and dagger.speed>0 and dagger.crit_chance>0,"Dagger trades power for speed and crit")
	check(heavy.attack>sword.attack and heavy.speed<0,"Greatblade trades speed for power")
	check(ember.attack<sword.attack and ember.fire_dps>0,"Ember weapon trades direct power for DOT")
	var boss_kinds: Dictionary={}
	for floor_index in range(1,6):
		game.floor_number=floor_index
		game.generate_floor()
		var boss=game.make_enemy(3,4)
		boss_kinds[boss.boss_kind]=true
		check(game.THEMES[game.theme_index()]!="","Named floor identity")
		if floor_index==1:check(boss.trait=="shield" and boss.armor>=10,"Iron boss armored/shielded")
		if floor_index==2:check(boss.trait=="pierce" and boss.speed==1.4 and game.water_shortcuts.size()>=1,"Tide boss fast and piercing")
		if floor_index==5:
			var state=Combat.begin(boss,500,500,1,100,0.3,[])
			state.enemy.hp-=30
			state.p_time=100.0
			state.e_time=100.0
			var regenerated=0
			for i in range(5):
				var result=Combat.step(state)
				if result.regen:regenerated+=1
			check(regenerated==5 and state.regen_time==INF,"Ash boss regeneration is finite")
	check(boss_kinds.size()==3,"Three distinct bosses")
	# Map remembers visited resources and removes consumed ones.
	game.new_run(5);preload("res://tools/test_equipment.gd").arm(game)
	for coord in game.roles:
		if game.roles[coord]=="Forge":
			game.room=coord
			check("S" in game.map_features(coord) and "I" in game.map_features(coord),"Forge and iron remembered")
			game.pos=game.rooms[coord].special
			break
	game.inventory.append(Gear.make("helmet",1,0))
	game.inventory.append(Gear.make("shield",2,1,["health"]))
	game.equipped.shield=2
	game.recalculate_stats()
	var expected_stats=game.armor
	game.selected_item=1
	game.iron_fragments=2
	game.open_equipment()
	game.selected_item=1
	game.action("salvage_selected")
	check(game.inventory.size()==2 and game.equipped.shield==1,"Salvage repairs equipment indices")
	check(game.iron==1 and game.iron_fragments==0 and game.salvage_charges==2,"Fragments convert to iron")
	check(game.armor==expected_stats,"Salvage preserves other equipped stats")
	game.selected_item=1
	game.action("salvage_selected")
	check(game.inventory.size()==2 and game.salvage_charges==2,"Equipped item protected")
	game.inventory.append(Gear.make("helmet",1,2,["speed","armor"]))
	game.selected_item=2
	game.action("salvage_selected")
	check(game.iron==2 and game.iron_fragments==0 and game.salvage_charges==1,"Very rare salvage yields three fragments")
	game.salvage_charges=0
	game.equipped.erase("shield")
	game.selected_item=1
	game.action("salvage_selected")
	check(game.inventory.size()==2,"Station use limit")
	game.salvage_charges=3
	game.pos=Vector2i(1,1)
	game.action("salvage_selected")
	check(game.inventory.size()==2,"Cannot salvage away from station")
	game.mode="floor"
	game.ascend_floor()
	check(game.salvage_charges==3 and game.iron==2,"Fresh station each floor preserves materials")
	game.new_run(8);preload("res://tools/test_equipment.gd").arm(game)
	check(game.iron_fragments==0,"Fragments reset on death/new run")
	# Forecasts and live fights include all three boss kinds and weapon tradeoffs.
	for floor_index in [1,3,5]:
		for archetype in ["balanced","dagger","greatblade","ember"]:
			for combination in range(16):
				game.new_run(10+combination);preload("res://tools/test_equipment.gd").arm(game)
				game.floor_number=floor_index
				game.inventory[0]=Gear.make("weapon",floor_index+2,2,["fire_dps","ice_slow"],archetype)
				game.recalculate_stats()
				var enemy=game.make_enemy(3,4)
				var predicted=game.forecast(enemy)
				game.rooms[game.room].entities[Vector2i(3,5)]=enemy
				game.move_player(Vector2i.RIGHT)
				for tick in range(3000):
					if game.mode!="fight":break
					resolve_tick(0.05)
				check(game.battle.done and game.hp==predicted.hp,"Boss/archetype forecast matches live combat")
	# Exercise each display mode on the normal frame loop to catch UI errors.
	game.new_run(14);preload("res://tools/test_equipment.gd").arm(game)
	for mode in ["play","equipment","character","settings","floor"]:
		game.mode=mode
		game.queue_redraw()
		await process_frame
	game.queue_free()
	if FileAccess.file_exists("res://tests/.dark-save.json"):DirAccess.remove_absolute(ProjectSettings.globalize_path("res://tests/.dark-save.json"))
	if failures.is_empty():print("PASS: %d overhaul checks; bosses, weapon tradeoffs, salvage, map memory, themes and UI."%checks)
	else:
		for failure in failures:push_error(failure)
	quit(0 if failures.is_empty() else 1)

func resolve_tick(delta: float) -> void:
	if game.mode=="fight" and game.battle.get("waiting",false):game.action("fight_continue")
	game._process(delta)
