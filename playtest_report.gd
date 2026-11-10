extends RefCounted
const BUILD="0.17.0"
var g
var last_path=""
func _init(game):g=game
func validation() -> Dictionary:
	if not g.run_metrics.get("validation") is Dictionary:g.run_metrics["validation"]={"schema":1,"encounters":[],"offers":[],"floors":[],"unusable_offers":0}
	return g.run_metrics.validation
func begin_run() -> void:
	if g.run_rules<20:return
	g.run_metrics.erase("validation");var data=validation()
	data["starting_workshop"]=g.smithy.data().duplicate(true)
	data["starting_tree"]=g.run_skills.duplicate(true)
	data["starting_loadout"]=g.replay.equipment_report()
	floor_entered()
func floor_entered() -> void:
	if g.run_rules<20:return
	var data=validation()
	if data.floors.size()>=32:return
	if not data.floors.is_empty() and int(data.floors[-1].floor)==g.floor_number:return
	data.floors.append({"floor":g.floor_number,"level":g.character_level,"hp":g.hp,"max_hp":g.max_hp,"attack":g.attack,"armor":g.armor,"interval":1.0/maxf(0.1,g.speed),"flasks":g.potions})
func offer(ids: Array) -> void:
	if g.run_rules<20:return
	var data=validation();var totals=preload("res://build_stats.gd").calculate(g);var unusable=[]
	for id in ids:
		if not preload("res://skill_offers.gd").eligible(g,id,totals):unusable.append(id)
	data.unusable_offers+=unusable.size()
	if data.offers.size()<128:data.offers.append({"floor":g.floor_number,"level":g.reward_level,"choices":ids.duplicate(),"unusable":unusable})
func selected(id: String) -> void:
	if g.run_rules<20:return
	var data=validation()
	if not data.offers.is_empty():data.offers[-1]["chosen"]=id
func fight_started() -> void:
	if g.run_rules<20:return
	validation()["current"]={"enemy":g.fight.name,"floor":g.floor_number,"enemy_level":g.fight.get("level",1),"family":g.fight.get("family",""),"boss":g.fight.type==3,"enemy_hp":g.fight.hp,"enemy_attack":g.fight.attack,"enemy_armor":g.fight.armor,"prepared":g.fight.get("floor_prepared",""),"starting_hp":g.hp,"healed_before":g.summary.healed,"flasks_before":g.potions}
func fight_finished() -> void:
	if g.run_rules<20:return
	var data=validation()
	if not data.has("current"):return
	var encounter=data.current;data.erase("current")
	encounter["seconds"]=g.battle.time;encounter["ending_hp"]=g.battle.hp;encounter["won"]=g.battle.won
	encounter["healing"]=maxf(0,float(g.summary.healed)-float(encounter.healed_before));encounter["flasks_used"]=maxi(0,int(encounter.flasks_before)-g.potions)
	encounter["recap"]=g.run_metrics.get("last_fight",{}).duplicate(true)
	if data.encounters.size()<256:data.encounters.append(encounter)
func crafted(p: Dictionary,id: String) -> void:
	if not p.get("metrics") is Dictionary:p["metrics"]={}
	p.metrics["crafts"]=int(p.metrics.get("crafts",0))+1
	if not p.metrics.has("first_craft"):
		p.metrics["first_craft"]={"item":id,"completed_expeditions":int(g.career.runs),"recorded_play_seconds":g.career.history.reduce(func(total,row):return total+int(row.get("time",0)),0)}
func export_report(directory: String="user://playtests") -> bool:
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))!=OK:return false
	var data={"build":BUILD,"report_schema":2,"workshop":g.smithy.data().duplicate(true),"journey":g.career.get("journey",{}).duplicate(true),"run_history":g.career.history.duplicate(true),"mastery":g.career.get("mastery",{}).duplicate(true),"exact_forecasts":bool(g.session.preferences.exact_forecasts)}
	if g.session.active:data["active_run"]={"rules":g.run_rules,"seed":g.run_seed,"floor":g.floor_number,"level":g.character_level,"kills":g.kills,"tree_ranks":g.run_skills.duplicate(true),"metrics":g.run_metrics.duplicate(true),"equipment":g.replay.equipment_report(),"relics":g.relics.duplicate(),"elements":g.elements.duplicate(),"vows":g.run_settings.get("vows",{}).duplicate(),"totals":preload("res://build_stats.gd").calculate(g)}
	last_path=directory.path_join("MagicDungeon-playtest-%d.json"%Time.get_unix_time_from_system())
	var file=FileAccess.open(last_path,FileAccess.WRITE)
	if not file:return false
	file.store_string(JSON.stringify(data,"  "));file.close();return true
func handle(id: String) -> bool:
	if id=="export_playtest":
		if export_report():g.ui_help.show("playtest_export")
		else:g.log_line("Could not save the report. Check that the game can write to its data folder.")
		return true
	if id=="report:open":OS.shell_open(ProjectSettings.globalize_path(last_path.get_base_dir()));return true
	return false
