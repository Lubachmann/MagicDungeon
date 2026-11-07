extends SceneTree
var checks=0
var failures: Array[String]=[]
var game
const PATH="res://tests/.release-save.json"
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures.append(message)
func clean() -> void:
	for suffix in ["",".run",".run.bak",".run.tmp",".settings",".settings.bak",".settings.tmp"]:
		if FileAccess.file_exists(PATH+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH+suffix))
func make_game():
	var node=load("res://main.gd").new()
	node.save_path=PATH
	root.add_child(node)
	node.set_process(false)
	node.session.enabled=true
	node.muted=true
	return node
func key(code: int) -> InputEventKey:
	var event=InputEventKey.new();event.keycode=code;event.pressed=true
	return event
func _initialize():call_deferred("run")
func run() -> void:
	clean()
	game=make_game()
	game.session.preferences.tutorial_done=true
	check(game.session.start_run(),"Start class-free run")
	check(game.loadout=="wanderer" and game.inventory.is_empty() and game.equipped.is_empty() and game.base_elements=={"fire":0,"ice":0,"acid":0,"poison":0},"Unarmed with no class effects")
	preload("res://tools/test_equipment.gd").arm(game)
	# Save an unopened/then opened chest and its pending equip decision.
	var chest_tile=game.rooms[game.room].chest
	var contents=game.rooms[game.room].entities[chest_tile].item.duplicate(true)
	check(game.open_chest(chest_tile),"Open starting chest")
	check(game.session.checkpoint(),"Save loot screen")
	var state=game.rng.state
	game.inventory.clear();game.mode="play";game.rng.randi()
	check(game.session.continue_run(),"Restore loot screen")
	check(game.mode=="loot" and game.inventory[game.last_loot_index]==contents,"Pending gear choice retained")
	check(game.rooms[game.room].entities[chest_tile].kind=="opened_chest" and game.rng.state==state,"Loot and RNG cannot reroll")
	check(not game.open_chest(chest_tile),"Opened chest cannot pay twice")
	game.action("loot_keep")
	game.gain_xp(1000);game.resume_play()
	var choices=game.choices.duplicate()
	var pending=game.pending_levels
	game.session.checkpoint()
	game.choices.clear();game.pending_levels=0
	game.session.continue_run()
	check(game.choices==choices and game.pending_levels==pending and game.mode=="relic","Queued levels and fixed reward choices survive")
	# Pause and resume a real encounter with exact clocks and crit state.
	game.session.start_run()
	game.pos=Vector2i(6,5);game.render_pos=Vector2(game.pos)
	game.move_player(Vector2i.RIGHT)
	check(game.mode=="fight","Encounter starts")
	game._process(0.2)
	var prediction=game.forecast(game.fight)
	var battle=game.battle.duplicate(true)
	var clock=game.clock
	game.session.pause()
	game._process(5.0)
	check(game.clock==clock and game.battle==battle,"Pause freezes combat")
	check(game.session.title(),"Save and title from paused encounter")
	check(game.session.cached.state.mode=="fight","Save stores underlying fight rather than pause overlay")
	check(game.session.continue_run() and game.mode=="fight","Continue fight")
	check(game.battle==battle and game.clock==clock,"Combat state and next event clocks restored exactly")
	for i in range(2000):
		if game.mode!="fight":break
		game._process(0.02)
	check(game.hp==prediction.hp,"Resumed live fight matches original forecast")
	# Interactive tutorial progress is saved per character; the text guide remains optional.
	game.career.guided_done=false;game.career.runs=0
	game.session.start_run();game.run_metrics.guide_step=1;game.session.checkpoint()
	game.mode="play";game.session.continue_run()
	check(game.guided.active() and game.run_metrics.guide_step==1,"Interactive tutorial resumes at the saved step")
	game.action("guide_skip")
	check(game.mode=="play" and game.career.guided_done and not game.guided.active(),"Interactive tutorial can be skipped")
	preload("res://tools/test_equipment.gd").arm(game)
	# Per-floor shrine has a lasting, one-time cost, and survives reload.
	for coord in game.rooms:
		for tile in game.rooms[coord].entities:
			if game.rooms[coord].entities[tile].kind=="shrine":
				game.room=coord;game.pos=tile;game.mode="shrine"
				break
	var health=game.hp;var maximum=game.max_hp;var level=game.inventory[game.equipped.weapon].level
	game.action("shrine_temper")
	check(game.hp==health-8 and game.max_hp==maximum-8 and game.inventory[game.equipped.weapon].level==level+1,"Shrine trade has exact persistent costs")
	game.session.continue_run()
	game.mode="shrine";game.action("shrine_temper")
	check(game.inventory[game.equipped.weapon].level==level+1,"Shrine cannot be reused")
	# Settings and custom keys persist without sharing the run's random stream.
	game.mode="play"
	var rng_state=game.rng.state
	check(game.controls.bind("heal",KEY_K),"Rebind heal")
	check(not game.controls.bind("heal",KEY_F11),"Reserved keys protected")
	game.session.preferences.large_text=true;game.session.preferences.reduced_flashes=true
	game.session.save_preferences();game.session.checkpoint()
	check(game.rng.state==rng_state,"Settings never consume dungeon RNG")
	var other=make_game();other.session.boot()
	check(other.mode=="title" and other.session.has_run(),"Boot offers Continue")
	check(other.controls.bindings.heal==KEY_K and other.session.preferences.large_text and other.session.preferences.reduced_flashes,"Preferences persist")
	check(other.session.continue_run() and other.vitality_tax==8,"Run restores independently of preferences")
	# Backup recovery rejects a damaged checksum instead of parsing corrupt data.
	other.session.checkpoint();other.session.checkpoint()
	var expected=other.rng.state
	var file=FileAccess.open(PATH+".run",FileAccess.WRITE);file.store_string("damaged");file.close()
	check(other.session.continue_run() and other.rng.state==expected,"Corrupt primary recovers last backup with full RNG state")
	# Terminal checkpoint banks rewards once and disables Continue.
	other.mode="play";other.shards=17
	var bank=other.bank
	other.finish_run(false)
	other.session.boot()
	check(not other.session.has_run() and other.bank==bank+17,"Death banks once and closes run")
	check(not other.session.continue_run(),"Cannot resume a dead run")
	other.mode="dead";other.finish_run(false)
	check(other.bank==bank+17,"Death cannot bank twice")
	# Keyboard and controller work without hover, and menu focus wraps.
	game.mode="play";game.pos=Vector2i(2,5);game.controls.command("inspect")
	var inspected=game.inspected_tile
	game.controls.step(Vector2i.RIGHT)
	check(game.mode=="inspect" and game.inspected_tile==inspected+Vector2i.RIGHT,"Keyboard inspection cursor")
	game.controls.back();check(game.mode=="play","Exit inspection")
	game.mode="title";game.buttons.clear();game.buttons.append({"rect":Rect2(0,0,1,1),"id":"new_game"});game.buttons.append({"rect":Rect2(0,0,1,1),"id":"settings"})
	game.session.focused=0;game.controls.navigate(-1)
	check(game.session.focused==1,"Menu focus wraps")
	var event=InputEventJoypadButton.new();event.button_index=JOY_BUTTON_A;event.pressed=true
	game.controls.handle(event)
	check(game.mode=="settings","Controller confirms selected menu")
	game.controls.handle(key(KEY_ESCAPE));check(game.mode=="title","Escape returns to originating title")
	# Demo completion ends after floor one; full runs retain five floors.
	game.session.start_run(true);game.mode="play";game.room=game.boss_room;game.pos=Vector2i(7,3);game.rooms[game.room].cleared=true
	game.move_player(Vector2i.UP)
	check(game.mode=="won" and game.demo_run and game.floor_number==1,"First-floor demo has a proper ending")
	game.session.start_run(false);game.room=game.boss_room;game.pos=Vector2i(7,3);game.rooms[game.room].cleared=true
	game.move_player(Vector2i.UP)
	check(game.mode=="floor" and not game.demo_run,"Full game still ascends")
	# Burn specialization changes behavior; it is not just a larger attack number.
	var target=game.make_enemy(0,0);target.hp=1000;target.max=1000
	var fire=game.Combat.begin(target,1000,1000,1,100,0.2,["cinder"],{"fire":1})
	var burns=[]
	for tick in range(100):
		var hit=game.Combat.step(fire)
		if hit.burn:burns.append(hit.damage)
		if burns.size()==3:break
	check(burns==[4.0,4.0,6.0],"Cinder has a third-tick damage rhythm")
	# Shrines never replace door landings and their approach is physically open.
	for seed_value in range(50):
		game.rng.seed=seed_value;game.session.start_run()
		for coord in game.rooms:
			var data=game.rooms[coord]
			var seen={Vector2i(6,5):true};var queue=[Vector2i(6,5)]
			while not queue.is_empty():
				var current=queue.pop_front()
				for direction in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
					var tile=current+direction
					if tile.x<=0 or tile.x>=12 or tile.y<=0 or tile.y>=10 or data.walls.has(tile) or seen.has(tile):continue
					if data.entities.get(tile,{}).get("kind","") in ["water","crack"]:continue
					seen[tile]=true;queue.append(tile)
			for tile in data.entities:
				if data.entities[tile].kind=="shrine":
					check(seen.has(tile),"Shrine reachable after combat")
					check(tile not in [Vector2i(1,5),Vector2i(11,5),Vector2i(6,1),Vector2i(6,9)],"Shrine avoids doorway landings")
	# Saving failures keep the current run in memory instead of claiming success.
	game.session.pause();game.save_path="res://tests/missing-directory/profile"
	check(not game.session.title() and game.mode=="pause" and game.session.error!="","Failed save prevents leaving the run")
	game.save_path=PATH
	game.queue_free();other.queue_free()
	await process_frame
	clean()
	if failures.is_empty():print("PASS: %d release-foundation checks: save/restore, corruption recovery, pause, rewards, death banking, tutorial, builds, shrines and controls."%checks)
	else:
		for problem in failures:push_error(problem)
	quit(0 if failures.is_empty() else 1)
