extends RefCounted
## Versioned, checksummed Variant saves preserve Vector2i keys and 64-bit RNG state.
const VERSION=1
const FIELDS=["rooms","room","pos","hp","max_hp","attack","armor","speed","breaker","boots","potions","shards","bank","levels","visited","mode","logs","fight","clock","kills","run_seed","links","water_shortcuts","roles","distances","boss_room","hammer_room","passage_room","boots_room","relics","choices","battle","elements","crit_chance","crit_mult","blessings","floor_number","character_level","experience","pending_levels","reward_level","inventory","equipped","iron","gear_stats","bonus","base_elements","equipment_slot","selected_item","inventory_page","floor_drop_index","last_loot_index","last_chest_tier","completed_rooms","bombs","facing","summary","iron_fragments","salvage_charges","loadout","demo_run","vitality_tax","death_reason","tutorial_step","tutorial_return","skills","run_skills","meta_revision","run_rules","legacy_levels","floor_keys","floor_flags","recall_charges","rerolls_left","revives_left","iron_bonus_claimed","puzzle_tile","active_ability","toxic_echo","tree_epoch","tree_spent","career","run_settings","run_bounties","run_metrics","run_recorded"]
var g
var enabled=true
var active=false
var cached: Dictionary={}
var preferences={"version":1,"tutorial_done":false,"theme":0,"effects":0.7,"ambience":0.25,"music":0.35,"muted":false,"large_text":false,"reduced_flashes":false,"bindings":{},"fullscreen":true,"exact_forecasts":false}
var paused_from="play"
var settings_from="title"
var focused=0
var save_timer=0.0
var last_mode=""
var error=""
var last_saved=""
func _init(game):g=game
func digest(bytes: PackedByteArray) -> PackedByteArray:
	var hash=HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(bytes)
	return hash.finish()
func path() -> String:return g.save_path+".run"
func settings_path() -> String:return (g.profiles.base_path if g.profiles else g.save_path)+".settings"
func read_file(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):return {}
	var data=FileAccess.get_file_as_bytes(file_path)
	if data.size()<36 or data.size()>8000000 or data.slice(0,4).get_string_from_ascii()!="MDG1":return {}
	var bytes=data.slice(36)
	if digest(bytes)!=data.slice(4,36):return {}
	var value=bytes_to_var(bytes)
	if not value is Dictionary or value.get("version",0)!=VERSION:return {}
	return value
func read_checkpoint() -> Dictionary:
	for name in [path(),path()+".bak"]:
		var data=read_file(name)
		if valid(data):return data
	return {}
func valid(data: Dictionary) -> bool:
	if not data.get("state") is Dictionary or not data.get("rng") is int:return false
	var state: Dictionary=data.state
	if not state.has("meta_revision"):
		var previous=state.get("levels",[0,0,0])
		state.bank+=g.ember_tree.legacy_refund(previous)
		state["legacy_levels"]=previous.duplicate()
		state["levels"]=[0,0,0]
		state["skills"]={};state["run_skills"]={};state["meta_revision"]=1;state["run_rules"]=2
		state["floor_keys"]={};state["floor_flags"]={};state["recall_charges"]=0;state["rerolls_left"]=0;state["revives_left"]=0;state["iron_bonus_claimed"]=false;state["puzzle_tile"]=Vector2i(-1,-1)
		state.loadout="wanderer"
	if not state.has("active_ability"):state["active_ability"]="guard";state["toxic_echo"]=0.0
	if not state.has("tree_epoch"):
		state["tree_epoch"]=2;state["tree_spent"]=g.ember_tree.old_spent(state.skills);state["career"]=g.replay.new_career()
		if state.mode=="won" and not state.get("demo_run",false) and state.floor_number>=5:state.career.wins=1;state.career.runs=1;state.career.best_floor=5
		state["run_settings"]={"mode":"standard","vows":{}};state["run_bounties"]={};state["run_metrics"]={"bosses":0,"runes":0,"breaks":0};state["run_recorded"]=state.mode in ["dead","won"]
	for key in FIELDS:
		if not state.has(key):return false
	if not state.rooms is Dictionary or not state.inventory is Array or not state.equipped is Dictionary:return false
	if state.rooms.size() not in [8,9] or (state.rooms.size()==9 and not state.rooms.has(Vector2i(-1,0))) or not state.rooms.has(state.room) or not state.pos is Vector2i:return false
	if state.floor_number<1 or (state.floor_number>5 and state.run_settings.get("mode","")!="endless") or state.character_level<1:return false
	if state.mode not in ["play","fight","bomb","inspect","extract","character","equipment","loot","relic","upgrade","floor","tutorial","shrine","runes","vault_reward","infuse","curse","decision","branch","ending","discovery","imprint","forge","dead","won"]:return false
	if state.mode=="decision" and state.rooms[state.room].entities.get(state.puzzle_tile,{}).get("kind","") not in ["provisions","build_cache","wardstone","boss_preparation","rarity_altar","salvage","rest_site"]:return false
	if state.mode=="imprint" and state.rooms[state.room].entities.get(state.puzzle_tile,{}).get("kind","") not in ["runesmith","salvage"]:return false
	if state.mode=="fight" and (state.battle.is_empty() or not state.fight.has("position")):return false
	if state.mode=="loot" and (state.last_loot_index<0 or state.last_loot_index>=state.inventory.size()):return false
	for slot in state.equipped:
		var index=state.equipped[slot]
		if not index is int or index<0 or index>=state.inventory.size() or state.inventory[index].slot!=slot:return false
	return true
func atomic_write(file_path: String,data: Dictionary) -> bool:
	var bytes=var_to_bytes(data)
	var file=FileAccess.open(file_path+".tmp",FileAccess.WRITE)
	if not file:error="Cannot write save: "+error_string(FileAccess.get_open_error());return false
	file.store_buffer("MDG1".to_ascii_buffer())
	file.store_buffer(digest(bytes))
	file.store_buffer(bytes)
	file.flush()
	var status=file.get_error()
	file.close()
	if status!=OK:error="Could not finish writing save.";return false
	if not read_file(file_path).is_empty():
		if DirAccess.copy_absolute(file_path,file_path+".bak")!=OK:error="Could not write save backup.";return false
	if DirAccess.rename_absolute(file_path+".tmp",file_path)!=OK:error="Could not replace save.";return false
	error=""
	return true
func boot() -> void:
	var settings=read_file(settings_path())
	if settings.is_empty():settings=read_file(settings_path()+".bak")
	if settings.get("preferences") is Dictionary:
		for key in preferences:
			if settings.preferences.has(key):preferences[key]=settings.preferences[key]
	preferences.exact_forecasts=false
	cached=read_checkpoint()
	if not cached.is_empty():
		g.bank=cached.state.bank
		g.levels=cached.state.levels.duplicate()
		g.skills=g.ember_tree.clean(cached.state.skills)
		g.tree_spent=int(cached.state.tree_spent);g.tree_epoch=2;g.career=g.replay.clean_career(cached.state.career)
	g.ui_theme=int(preferences.theme)%2
	g.muted=bool(preferences.muted)
	g.sound.volume=clampf(float(preferences.effects),0,1)
	g.sound.ambience_volume=clampf(float(preferences.ambience),0,1)
	g.sound.music_volume=clampf(float(preferences.music),0,1)
	g.sound.set_muted(g.muted)
	g.controls.restore(preferences.bindings)
	if DisplayServer.get_name()!="headless":DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if preferences.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	g.mode="title"
	active=false
func has_run() -> bool:
	return not cached.is_empty() and cached.state.mode not in ["dead","won"] and cached.state.hp>0
func saved_mode() -> String:
	if g.mode=="sanctuary":return g.sanctuary.return_mode
	if g.mode=="smithy":return g.sanctuary.return_mode if g.smithy.return_mode=="sanctuary" else "title"
	if g.mode=="build":return g.run_metrics.get("build_return","equipment")
	if g.mode=="recap":return g.run_metrics.get("recap_return","dead")
	if g.mode=="pause":return paused_from
	if g.mode in ["settings","controls","credits"]:
		return paused_from if settings_from=="pause" else "play"
	return g.mode
func snapshot() -> Dictionary:
	var state={}
	for key in FIELDS:state[key]=g.get(key)
	state.mode=saved_mode()
	return {"version":VERSION,"state":state,"rng":g.rng.state,"saved_at":Time.get_datetime_string_from_system(),"ui":{"paused_from":paused_from,"settings_from":settings_from}}
func checkpoint() -> bool:
	if not enabled or not active or g.mode in ["title","confirm_new","skills","profiles","expedition","loadout","codex"]:return true
	var data=snapshot()
	if not valid(data):error="Invalid run state; last good save retained.";return false
	if not atomic_write(path(),data):return false
	cached=data.duplicate(true)
	last_saved=data.saved_at
	save_timer=0
	return true
func save_preferences() -> bool:
	if not enabled:return true
	preferences.theme=g.ui_theme
	preferences.effects=g.sound.volume
	preferences.ambience=g.sound.ambience_volume
	preferences.music=g.sound.music_volume
	preferences.muted=g.muted
	preferences.bindings=g.controls.bindings.duplicate()
	preferences.fullscreen=DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN
	return atomic_write(settings_path(),{"version":VERSION,"preferences":preferences})
func continue_run() -> bool:
	var data=read_checkpoint()
	if data.is_empty() or data.state.mode in ["dead","won"]:error="No valid active run was found.";return false
	if g.movement:g.movement.kill()
	for key in FIELDS:g.set(key,data.state[key])
	# Remove obsolete bomb pickups from previously saved floors.
	g.bombs=0
	if g.mode=="bomb":g.mode="play"
	for saved_room in g.rooms.values():
		for tile in saved_room.get("entities",{}):
			if saved_room.entities[tile].get("kind","")=="bomb":saved_room.entities[tile]={"kind":"iron"}
	if g.mode=="forge":g.mode="equipment";g.run_metrics.erase("forge_tab")
	if g.mode=="decision" and g.rooms[g.room].entities.get(g.puzzle_tile,{}).get("kind","")=="salvage":g.mode="equipment";g.run_metrics.erase("forge_tab")
	g.career=g.replay.clean_career(g.career)
	g.rng.state=data.rng
	paused_from=data.get("ui",{}).get("paused_from","play")
	settings_from=data.get("ui",{}).get("settings_from","play")
	g.render_pos=Vector2(g.pos)
	g.map_pinned=false
	g.map_hover_open=false
	g.motes.clear()
	g.flashes.clear()
	g.recalculate_stats()
	if g.mode=="fight":
		var build=g.combat_build();build["toxic_echo"]=g.battle.build.get("toxic_echo",0.0)
		for rule in ["fair_physical","element_interval_scale"]:
			if g.battle.build.has(rule):build[rule]=g.battle.build[rule]
			else:build.erase(rule)
		g.battle.waiting=false;g.battle.build.merge(build,true);g.Combat.Flow.prepare(g.battle)
	if g.feedback:g.feedback.clear();g.feedback.state=g.battle if g.mode=="fight" else {}
	active=true
	cached=data
	focused=0
	g.log_line("Run restored. Loot and encounter rolls are unchanged.")
	return true
func start_run(demo: bool=false) -> bool:
	if active and not checkpoint():return false
	active=true
	g.replay.demo_next=demo
	g.new_run()
	g.demo_run=demo
	g.hp=g.max_hp
	if int(g.career.get("runs",0))==0 and not g.career.get("guided_done",false):g.guided.start()
	focused=0
	return checkpoint()
func commit_profile() -> bool:
	# Commit bank and tree together without mutating an existing run's skill snapshot.
	if not enabled:return g.save_progress()
	if not cached.is_empty():
		var data=cached.duplicate(true)
		data.state.bank=g.bank;data.state.skills=g.skills.duplicate(true);data.state.meta_revision=1;data.state.levels=[0,0,0]
		data.state.tree_epoch=2;data.state.tree_spent=g.tree_spent;data.state.career=g.career.duplicate(true)
		if not atomic_write(path(),data):return false
		cached=data
		g.save_progress()
		return true
	if not g.save_progress():error="Cannot save permanent progress. Purchase was cancelled.";return false
	return true
func pause() -> void:
	if g.mode in ["title","confirm_new","skills","profiles","expedition","codex","pause","settings","controls","credits","dead","won"]:return
	paused_from=g.mode
	g.mode="pause"
	focused=0
	checkpoint()
func title() -> bool:
	if not checkpoint():return false
	save_preferences()
	active=false
	g.mode="title"
	focused=0
	return true
func tick(delta: float) -> void:
	if not enabled or not active:return
	save_timer+=delta
	if g.mode!=last_mode or (g.mode=="fight" and save_timer>=1.0) or save_timer>=10.0:
		checkpoint()
	last_mode=g.mode
